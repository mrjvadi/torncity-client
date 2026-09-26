extends Node
## The client's visual asset library. Game content never lives in the client:
## the server names an asset key per content entry (content catalogue
## `asset: {model: "company:factory", icon: "item:pistol"}`) and this library
## turns the key into a scene or an icon.
##
## Resolution for "<category>:<name>" (assets/library.json):
##   1. the exact key,
##   2. the category's fallback ("company:*"),
##   3. the global fallback ("*").
## So content the server adds tomorrow still renders, with a generic look for
## its category, without a client release.

const LIBRARY := "res://assets/library.json"

var models := {}
var roads := {}
var road_open := {}
var icons := {}
var actions := {}
var glyph_dir := "res://assets/icons/game-icons/"
var _scene_cache := {}
var _tex_cache := {}
var _bounds_cache := {}


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(LIBRARY))
	if d is Dictionary:
		models = d.get("models", {})
		roads = d.get("roads", {})
		road_open = d.get("road_open", {})
		icons = d.get("icons", {})
		actions = d.get("actions", {})
		glyph_dir = str(d.get("glyph_dir", glyph_dir))


## The library entry for a key, with category and global fallbacks.
static func resolve(table: Dictionary, key: String):
	if key != "" and table.has(key):
		return table[key]
	var cat := key.split(":")[0] if key.contains(":") else key
	if table.has(cat + ":*"):
		return table[cat + ":*"]
	return table.get("*")


## The model entry for an asset key: {parts: [{scene, at: [x, z], rotate, scale}]}
## in plot space (a 2 x 2-tile plot centred on the origin). A bare path or
## {scene, scale, rotate} is accepted as a one-part model.
func model(key: String) -> Dictionary:
	var e = resolve(models, key)
	if e is String:
		e = {"scene": e}
	if e is Dictionary and not e.has("parts") and e.has("scene"):
		e = {"parts": [{"scene": e["scene"], "at": [0, 0], "rotate": e.get("rotate", 0), "scale": e.get("scale", 1.0)}]}
	return e if e is Dictionary else {}


func scene(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _scene_cache[path]


## A scene's bounds (measured once): used to fit and centre model parts.
func scene_bounds(path: String) -> AABB:
	if _bounds_cache.has(path):
		return _bounds_cache[path]
	var ps := scene(path)
	var box := AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)
	if ps:
		var n := ps.instantiate()
		var acc: Array = [null]
		_measure(n, Transform3D.IDENTITY, acc)
		if acc[0] != null:
			box = acc[0]
		n.free()
	_bounds_cache[path] = box
	return box


func _measure(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		_measure(c, t, acc)


## Build the model for an asset key: a Node3D holding its parts. Null only if
## the library has nothing at all (not even "*").
func instantiate(key: String) -> Node3D:
	var e := model(key)
	var parts: Array = e.get("parts", [])
	if parts.is_empty():
		return null
	var root := Node3D.new()
	root.name = key.validate_node_name()
	for p in parts:
		var ps := scene(str(p.get("scene", "")))
		if ps == null:
			continue
		var n := ps.instantiate() as Node3D
		if n == null:
			continue
		var at: Array = p.get("at", [0, 0])
		var box := scene_bounds(str(p.get("scene", "")))
		# "size": the footprint wanted, in plot units (a plot is 2 across);
		# the model is scaled to it and centred on "at", whatever its origin.
		var sc := float(p.get("scale", 1.0))
		if p.has("size"):
			sc = float(p["size"]) / maxf(0.01, maxf(box.size.x, box.size.z))
		var c := box.get_center()
		var holder := Node3D.new()
		holder.position = Vector3(float(at[0]), 0.0, float(at[1]))
		holder.rotation_degrees.y = float(p.get("rotate", 0))
		n.scale = Vector3(sc, sc, sc)
		n.position = Vector3(-c.x * sc, -box.position.y * sc, -c.z * sc)
		holder.add_child(n)
		root.add_child(holder)
	return root if root.get_child_count() > 0 else null


## The badge icon for an asset key: {texture, tint}. Resolution: the exact
## key, then "<table>.<category>:*" when a category is given (item category,
## place kind...), then "<table>:*", then "*".
func glyph(key: String, category := "") -> Dictionary:
	var e = null
	if icons.has(key):
		e = icons[key]
	elif category != "" and key.contains(":"):
		e = icons.get("%s.%s:*" % [key.split(":")[0], category])
	if e == null:
		e = resolve(icons, key)
	if not (e is Dictionary):
		e = {"glyph": str(e) if e != null else "cardboard-box", "tint": "blue"}
	var path := glyph_dir + str(e.get("glyph", "cardboard-box")) + ".svg"
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return {"texture": _tex_cache[path], "tint": AppTheme.col(str(e.get("tint", "blue")))}


## The badge icon of a catalogue entry (uses its asset key and category).
func glyph_for(table: String, code: String) -> Dictionary:
	var e := Content.entry(table, code)
	return glyph(Content.asset(table, code, "icon"), str(e.get("category", e.get("kind", ""))))


func icon(key: String) -> Texture2D:
	return glyph(key).get("texture")


## The line icon for a server action, by its command's domain
## ("bank.show" -> "bank"); unknown domains get a generic icon.
func action_icon(command: String) -> String:
	var domain := command.split(".")[0]
	return str(actions.get(command, actions.get(domain, actions.get("*", "ln_menu"))))


## The badge icon for a server action, by its command's domain.
func action_glyph(command: String) -> Dictionary:
	return glyph("action:" + command.split(".")[0])
