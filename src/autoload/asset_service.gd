extends Node
## Runtime art from the CDN. Nothing but a tiny core is bundled: this service
## fetches <cdn>/manifest.json, downloads assets on demand, verifies their
## SHA-256, caches them content-addressed in user://assets/<sha256>, and
## decodes them at runtime:
##   glb  -> GLTFDocument.append_from_buffer + generate_scene (a PackedScene)
##   svg  -> Image.load_svg_from_buffer        (ImageTexture)
##   webp -> Image.load_webp_from_buffer, png -> load_png_from_buffer
##   ttf/otf -> FontFile.data,  ogg -> AudioStreamOggVorbis.load_from_buffer
##   json -> parsed Variant
##
## Callers never wait: get(key) returns the decoded asset or null, and asks
## for it; `loaded(key)` fires when it arrives. Until then the caller draws a
## fallback (the category's look) or a shimmer. Priority: VISIBLE first, then
## PREFETCH. At most MAX_PARALLEL downloads; failures retry with backoff.
##
## Manifest: {version, base_url, generated, assets: {key: {path, type, sha256,
## bytes, fallback?}}} (tools/build_assets/build.py).

signal manifest_ready
signal loaded(key: String)
signal failed(key: String)

enum { VISIBLE = 0, PREFETCH = 1 }

const MAX_PARALLEL := 4
const RETRIES := [1.0, 3.0, 9.0]
const CACHE_DIR := "user://assets"
const MANIFEST_CACHE := "user://assets/manifest.json"

var manifest := {}
var version := ""
var _base := ""
var _decoded := {}        # key -> Variant (PackedScene, Texture2D, Font, ...)
var _queue: Array = []    # [{key, pri, tries}]
var _active := {}         # key -> HTTPRequest
var _wanted := {}         # key -> priority (queued or active)
var _failed := {}         # key -> true (gave up this session)
var _has_manifest := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	# the last manifest we saw: art works offline and paints before the network answers
	if FileAccess.file_exists(MANIFEST_CACHE):
		var m = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_CACHE))
		if m is Dictionary:
			_use_manifest(m, false)
	if Config.cdn_url != "":
		refresh_manifest()


func has(key: String) -> bool:
	return manifest.get("assets", {}).has(key)


func entry(key: String) -> Dictionary:
	return manifest.get("assets", {}).get(key, {})


func refresh_manifest() -> void:
	var r := await _fetch(Config.cdn_url + "/manifest.json", 20.0)
	if r.ok:
		var m = JSON.parse_string(r.body.get_string_from_utf8())
		if m is Dictionary and m.has("assets"):
			_use_manifest(m, true)


func _use_manifest(m: Dictionary, save: bool) -> void:
	var changed := str(m.get("version", "")) != version
	manifest = m
	version = str(m.get("version", ""))
	var b := str(m.get("base_url", ""))
	_base = (b if b != "" else Config.cdn_url).trim_suffix("/")
	if save:
		var f := FileAccess.open(MANIFEST_CACHE, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(m))
	_has_manifest = true
	if changed:
		manifest_ready.emit()


## The decoded asset, or null (and it is requested). Never blocks.
func get_asset(key: String, priority := VISIBLE):
	if _decoded.has(key):
		return _decoded[key]
	request(key, priority)
	# a disk-cache hit decodes synchronously inside request()
	return _decoded.get(key)


func request(key: String, priority := VISIBLE) -> void:
	if _decoded.has(key) or _failed.has(key) or not has(key):
		return
	if _wanted.has(key):
		if priority < int(_wanted[key]):
			_wanted[key] = priority
			for q in _queue:
				if q.key == key:
					q.pri = priority
		return
	# cached on disk? decode now, no network
	var e := entry(key)
	var cached := _cache_path(str(e.get("sha256", "")))
	if FileAccess.file_exists(cached):
		var bytes := FileAccess.get_file_as_bytes(cached)
		if bytes.size() == int(e.get("bytes", -1)) and _decode(key, e, bytes):
			return
	_wanted[key] = priority
	_queue.append({"key": key, "pri": priority, "tries": 0})
	_pump()


func prefetch(keys: Array) -> void:
	for k in keys:
		request(str(k), PREFETCH)


func _pump() -> void:
	while _active.size() < MAX_PARALLEL and not _queue.is_empty():
		_queue.sort_custom(func(a, b): return a.pri < b.pri)
		var job: Dictionary = _queue.pop_front()
		_download(job)


func _download(job: Dictionary) -> void:
	var key: String = job.key
	var e := entry(key)
	_active[key] = true
	var r := await _fetch(_base + "/" + str(e.get("path", "")), 60.0)
	_active.erase(key)
	var ok := false
	if r.ok:
		var bytes: PackedByteArray = r.body
		if _sha256(bytes) == str(e.get("sha256", "")):
			var f := FileAccess.open(_cache_path(str(e["sha256"])), FileAccess.WRITE)
			if f:
				f.store_buffer(bytes)
				f.close()
			ok = _decode(key, e, bytes)
		else:
			push_warning("asset %s: checksum mismatch" % key)
	if not ok:
		job.tries += 1
		if job.tries <= RETRIES.size() and is_inside_tree():
			get_tree().create_timer(RETRIES[job.tries - 1]).timeout.connect(func():
				_queue.append(job)
				_pump())
		else:
			_wanted.erase(key)
			_failed[key] = true
			failed.emit(key)
	_pump()


func _fetch(url: String, timeout: float) -> Dictionary:
	var h := HTTPRequest.new()
	h.timeout = timeout
	h.accept_gzip = true
	add_child(h)
	var err := h.request(url)
	if err != OK:
		h.queue_free()
		return {"ok": false, "body": PackedByteArray()}
	var res: Array = await h.request_completed
	h.queue_free()
	return {"ok": res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200, "body": res[3]}


func _decode(key: String, e: Dictionary, bytes: PackedByteArray) -> bool:
	var v = null
	match str(e.get("type", "")):
		"glb":
			var doc := GLTFDocument.new()
			var st := GLTFState.new()
			if doc.append_from_buffer(bytes, "", st) == OK:
				var root := doc.generate_scene(st)
				if root:
					var ps := PackedScene.new()
					_own(root, root)
					if ps.pack(root) == OK:
						v = ps
					root.free()
		"svg":
			var img := Image.new()
			# glyphs are 512 px; 0.25 gives 128 px, sharp up to ~96 px badges
			if img.load_svg_from_buffer(bytes, float(e.get("scale", 0.25))) == OK:
				img.generate_mipmaps()
				v = ImageTexture.create_from_image(img)
		"webp", "png":
			var img := Image.new()
			var err := img.load_webp_from_buffer(bytes) if e.type == "webp" else img.load_png_from_buffer(bytes)
			if err == OK:
				img.generate_mipmaps()
				v = ImageTexture.create_from_image(img)
		"ttf", "otf":
			var f := FontFile.new()
			f.data = bytes
			v = f
		"ogg":
			v = AudioStreamOggVorbis.load_from_buffer(bytes)
		"json":
			v = JSON.parse_string(bytes.get_string_from_utf8())
	if v == null:
		return false
	_decoded[key] = v
	_wanted.erase(key)
	loaded.emit(key)
	return true


## PackedScene.pack only saves nodes owned by the root.
func _own(n: Node, root: Node) -> void:
	for c in n.get_children():
		c.owner = root
		_own(c, root)


func _cache_path(sha: String) -> String:
	return "%s/%s" % [CACHE_DIR, sha]


static func _sha256(bytes: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()


## Nothing queued or downloading.
func idle() -> bool:
	return _active.is_empty() and _queue.is_empty()


## For tests and the settings screen: how much is cached.
func cache_bytes() -> int:
	var total := 0
	var d := DirAccess.open(CACHE_DIR)
	if d:
		for f in d.get_files():
			var fa := FileAccess.open(CACHE_DIR + "/" + f, FileAccess.READ)
			if fa:
				total += fa.get_length()
	return total
