extends Node
## The client's visual asset library. Game content never lives in the client:
## the server names an asset key per content entry (content catalogue
## `asset: {model: "company:factory", icon: "item:pistol"}`) and this library
## turns the key into a model or an icon. The art itself comes from the CDN
## (AssetService); the library (which parts, which glyph, which tint) comes
## from the CDN too (asset "data:library"), with a bundled copy for first
## paint (res://assets/core/library.json).
##
## Resolution for "<category>:<name>":
##   1. a CDN asset published under that exact key (a drop-in model or icon),
##   2. the library's entry for the key,
##   3. the category's entry ("company:*"), then "*".
## While a download is on its way (or failed), models are procedural
## stand-ins and icons are the category's bundled glyph, so nothing is ever
## missing, and content the server adds tomorrow renders without a release.

signal changed   # the library itself was replaced (from the CDN)

const CORE_LIBRARY := "res://assets/core/library.json"
const CORE_GLYPHS := "res://assets/core/glyphs/"

var models := {}
var icons := {}
var actions := {}
var roads := {}
var road_open := {}
var dressing := {}
var credits := {}
var _bounds_cache := {}
var _core_tex := {}


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(CORE_LIBRARY))
	if d is Dictionary:
		_use(d)
	AssetService.loaded.connect(_on_loaded)
	AssetService.manifest_ready.connect(func(): AssetService.request("data:library"))
	if AssetService.has("data:library"):
		AssetService.request("data:library")


func _use(d: Dictionary) -> void:
	models = d.get("models", {})
	icons = d.get("icons", {})
	actions = d.get("actions", {})
	roads = d.get("roads", {})
	road_open = d.get("road_open", {})
	dressing = d.get("dressing", {})
	credits = d.get("credits", {})


func _on_loaded(key: String) -> void:
	if key == "data:library":
		var d = AssetService.get_asset(key)
		if d is Dictionary:
			_use(d)
			_bounds_cache.clear()
			changed.emit()


## The library entry for a key, with category and global fallbacks.
static func resolve(table: Dictionary, key: String):
	if key != "" and table.has(key):
		return table[key]
	var cat := key.split(":")[0] if key.contains(":") else key
	if table.has(cat + ":*"):
		return table[cat + ":*"]
	return table.get("*")


# -- models ---------------------------------------------------------------------------------------
## {parts: [{asset, at: [x, z], rotate, size}]} in plot space (a 2 x 2-tile
## plot centred on the origin). A drop-in GLB under the key wins.
func model(key: String) -> Dictionary:
	var direct: Dictionary = AssetService.entry(key)
	if str(direct.get("type", "")) == "glb":
		return {"parts": [{"asset": key, "at": [0, 0], "rotate": 0, "size": 1.6}]}
	var e = resolve(models, key)
	if not (e is Dictionary):
		return {}
	var out: Dictionary = e.duplicate(true)
	for p in out.get("parts", []):
		if p.has("mesh"):
			p["asset"] = "mesh:" + str(p["mesh"])
	return out


## Build the model for a key: a Node3D of its parts. Parts still downloading
## are procedural stand-ins; their asset keys are in root.get_meta("pending").
func instantiate(key: String, priority: int = 0) -> Node3D:
	var e := model(key)
	var root := Node3D.new()
	root.name = key.validate_node_name()
	var pending: Array = []
	for p in e.get("parts", []):
		var akey := str(p.get("asset", ""))
		var ps = AssetService.get_asset(akey, priority)
		var holder := Node3D.new()
		var at: Array = p.get("at", [0, 0])
		holder.position = Vector3(float(at[0]), 0.0, float(at[1]))
		holder.rotation_degrees.y = float(p.get("rotate", 0))
		root.add_child(holder)
		if ps is PackedScene:
			var n := (ps as PackedScene).instantiate() as Node3D
			var box := _bounds_of(akey, n)
			var sc := float(p.get("scale", 1.0))
			if p.has("size"):
				sc = float(p["size"]) / maxf(0.01, maxf(box.size.x, box.size.z))
			var c := box.get_center()
			n.scale = Vector3(sc, sc, sc)
			n.position = Vector3(-c.x * sc, -box.position.y * sc, -c.z * sc)
			holder.add_child(n)
		else:
			if akey != "" and AssetService.has(akey):
				pending.append(akey)
			holder.add_child(_stand_in(key, float(p.get("size", 1.0))))
	if root.get_child_count() == 0:
		root.add_child(_stand_in(key, 1.4))
	root.set_meta("pending", pending)
	return root


## A procedural stand-in: a simple block, shaped by the key's category.
func _stand_in(key: String, size: float) -> Node3D:
	var cat := key.split(":")[0]
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var h := size * 0.55
	var col := Color("#C9CFD8")
	match cat:
		"home":
			h = size * 0.45
			col = Color("#D8D2C4")
		"vehicle":
			bm.size = Vector3(size * 0.45, size * 0.3, size)
			col = Color("#5B8FD8")
		"decor":
			col = Color("#4E8F4A")
		"company":
			h = size * 0.7
			col = Color("#BFC9D8")
	if bm.size == Vector3.ONE:
		bm.size = Vector3(size * 0.8, h, size * 0.8)
	mi.mesh = bm
	mi.position.y = bm.size.y / 2.0
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	mi.material_override = m
	mi.set_meta("stand_in", true)
	return mi


func _bounds_of(akey: String, n: Node) -> AABB:
	if _bounds_cache.has(akey):
		return _bounds_cache[akey]
	var acc: Array = [null]
	_measure(n, Transform3D.IDENTITY, acc, true)
	var box: AABB = acc[0] if acc[0] != null else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)
	_bounds_cache[akey] = box
	return box


func _measure(n: Node, xf: Transform3D, acc: Array, is_root := false) -> void:
	var t := xf
	if n is Node3D and not is_root:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		_measure(c, t, acc)


## A plain mesh asset (roads, dressing) or null while it downloads.
func mesh_scene(mesh: String) -> PackedScene:
	var ps = AssetService.get_asset("mesh:" + mesh)
	return ps if ps is PackedScene else null


# -- icons ----------------------------------------------------------------------------------------
## The badge icon for a key: {texture, tint, pending}. The exact key, then
## "<table>.<category>:*" (item category...), then "<table>:*", then "*". A
## drop-in "icon:<key>" asset on the CDN wins. While the glyph downloads the
## texture is the category's bundled glyph and `pending` is true.
func glyph(key: String, category := "") -> Dictionary:
	var e = null
	if icons.has(key):
		e = icons[key]
	elif category != "" and key.contains(":"):
		e = icons.get("%s.%s:*" % [key.split(":")[0], category])
	if e == null:
		e = resolve(icons, key)
	if not (e is Dictionary):
		e = {"glyph": "cardboard-box", "tint": "blue"}
	var tint := AppTheme.col(str(e.get("tint", "blue")))
	var direct: String = "icon:" + key
	var tex = AssetService.get_asset(direct) if AssetService.has(direct) else AssetService.get_asset("glyph:" + str(e.get("glyph", "")))
	if tex is Texture2D:
		return {"texture": tex, "tint": tint, "pending": false}
	return {"texture": _core_glyph(key), "tint": tint, "pending": AssetService.has("glyph:" + str(e.get("glyph", ""))),
		"key": "glyph:" + str(e.get("glyph", ""))}


## The badge icon of a catalogue entry (uses its asset key and category).
func glyph_for(table: String, code: String) -> Dictionary:
	var e := Content.entry(table, code)
	return glyph(Content.asset(table, code, "icon"), str(e.get("category", e.get("kind", ""))))


func icon(key: String) -> Texture2D:
	return glyph(key).get("texture")


## Bundled glyphs: one per category plus the HUD's own (first paint, offline).
func _core_glyph(key: String) -> Texture2D:
	var cat := key.split(":")[0].split(".")[0]
	var name: String = {"stat": "heart-beats", "res": "cash", "item": "swap-bag", "place": "modern-city",
		"company": "briefcase", "vehicle": "city-car", "crime": "ninja-mask", "action": "gears", "service": "modern-city",
		"mode": "city-car"}.get(cat, "cardboard-box")
	var named := str(resolve(icons, key).get("glyph", "")) if resolve(icons, key) is Dictionary else ""
	if named != "" and ResourceLoader.exists(CORE_GLYPHS + named + ".svg"):
		name = named
	if not _core_tex.has(name):
		_core_tex[name] = load(CORE_GLYPHS + name + ".svg") if ResourceLoader.exists(CORE_GLYPHS + name + ".svg") else null
	return _core_tex[name]


## The line icon for a server action, by its command's domain
## ("bank.show" -> "bank"); unknown domains get a generic icon.
func action_icon(command: String) -> String:
	var domain := command.split(".")[0]
	return str(actions.get(command, actions.get(domain, actions.get("*", "ln_menu"))))


## The badge icon for a server action: its own `icon` key when the server
## sent one, else by its command's domain.
func action_glyph(command: String, icon_key := "") -> Dictionary:
	if icon_key != "":
		return glyph(icon_key)
	return glyph("action:" + command.split(".")[0])
