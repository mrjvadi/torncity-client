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
var icons := {}
var actions := {}
var _scene_cache := {}


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(LIBRARY))
	if d is Dictionary:
		models = d.get("models", {})
		icons = d.get("icons", {})
		actions = d.get("actions", {})


## The library entry for a key, with category and global fallbacks.
static func resolve(table: Dictionary, key: String):
	if key != "" and table.has(key):
		return table[key]
	var cat := key.split(":")[0] if key.contains(":") else key
	if table.has(cat + ":*"):
		return table[cat + ":*"]
	return table.get("*")


## A model scene for an asset key: {scene, scale, rotate, lift}. Never null
## while the library has a "*" entry.
func model(key: String) -> Dictionary:
	var e = resolve(models, key)
	if e is String:
		e = {"scene": e}
	return e if e is Dictionary else {}


func instantiate(key: String) -> Node3D:
	var e := model(key)
	var path := str(e.get("scene", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	var ps: PackedScene = _scene_cache[path]
	var n := ps.instantiate() as Node3D
	if n == null:
		return null
	var s := float(e.get("scale", 1.0))
	n.scale = Vector3(s, s, s)
	n.rotation_degrees.y = float(e.get("rotate", 0.0))
	n.position.y = float(e.get("lift", 0.0))
	return n


## An icon texture for an asset key ("item:pistol"), with fallbacks.
func icon(key: String) -> Texture2D:
	var e = resolve(icons, key)
	if e is String:
		if e.begins_with("res://"):
			return load(e) if ResourceLoader.exists(e) else null
		return AppTheme.icon(e)
	return AppTheme.icon("item")


## The line icon for a server action, by its command's domain
## ("bank.show" -> "bank"); unknown domains get a generic icon.
func action_icon(command: String) -> String:
	var domain := command.split(".")[0]
	return str(actions.get(command, actions.get(domain, actions.get("*", "ln_menu"))))
