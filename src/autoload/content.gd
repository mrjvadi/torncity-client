extends Node
## The server's content catalogue (GET /api/v1/content?since=<version>):
## every city, place, item, company type... with its localised name and asset
## keys. The client holds no game content of its own; it caches this, keyed by
## version, and refetches when the version changes (on start, and on a
## realtime {type:"content", version} message).
##
## Shape (see docs/architecture.md, "Content catalogue"):
##   {version, langs, entries: {<table>: [{code, name: {fa, en}, asset: {model?, icon?}, ...}]},
##    ui?: {tabs: [{key, label: {fa, en}, command, icon}]}}
## An up-to-date client gets {version, unchanged: true}.

signal changed

const CACHE := "user://content.json"

var version := ""
var data := {}
var _index := {}   # table -> code -> entry


func _ready() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(CACHE)) if FileAccess.file_exists(CACHE) else null
	if d is Dictionary:
		_apply(d, false)


## Fetch the catalogue if the server has a newer one. Safe to call often.
func sync() -> void:
	var path := "/api/v1/content"
	if version != "":
		path += "?since=" + version.uri_encode()
	var r: Dictionary = await Api.get_json(path)
	if r.get("status", 0) != 200 or not (r.get("data") is Dictionary):
		return
	var d: Dictionary = r["data"]
	if d.get("unchanged", false) and str(d.get("version", "")) == version:
		return
	_apply(d, true)


func _apply(d: Dictionary, save: bool) -> void:
	data = d
	version = str(d.get("version", ""))
	_index.clear()
	var entries = d.get("entries", {})
	if entries is Dictionary:
		for table in entries:
			var m := {}
			for e in entries[table]:
				if e is Dictionary and e.has("code"):
					m[str(e["code"])] = e
			_index[table] = m
	if save:
		var f := FileAccess.open(CACHE, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(d))
	changed.emit()


func entry(table: String, code: String) -> Dictionary:
	return _index.get(table, {}).get(code, {})


func entries(table: String) -> Array:
	return _index.get(table, {}).values()


## The localised name: catalogue first, then whatever the caller already had,
## then the bare code (never empty, never a crash).
func name_of(table: String, code: String, fallback := "") -> String:
	var n = entry(table, code).get("name")
	if n is Dictionary:
		var s := str(n.get(I18n.lang, n.get("en", "")))
		if s != "":
			return s
	elif n is String and n != "":
		return n
	return fallback if fallback != "" else code.replace("_", " ")


## The asset key for an entry: catalogue's, else "<table>:<code>" so the
## library can still match it or fall back to the table's generic look.
func asset(table: String, code: String, kind := "icon") -> String:
	var a = entry(table, code).get("asset")
	if a is Dictionary and str(a.get(kind, "")) != "":
		return str(a[kind])
	return "%s:%s" % [table, code]


func tabs() -> Array:
	var ui = data.get("ui", {})
	return ui.get("tabs", []) if ui is Dictionary else []
