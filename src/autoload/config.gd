extends Node
## Client configuration, layered (later wins):
##   res://config/client.cfg          shipped defaults
##   res://config/client.local.cfg    developer overrides (git-ignored)
##   user://client.cfg                what the Settings screen saved
##   command line  (-- --live --mock --api=URL --ws=URL --lang=fa --tg-mock)
##   web page query (?api=URL&ws=URL&mock=0|1&lang=en&tgmock=1)

signal changed

const VERSION := "0.1.0"

var api_url := "http://127.0.0.1:8080"
var realtime_url := "ws://127.0.0.1:8000/connection/websocket"
## Where the art lives: <cdn_url>/manifest.json (tools/build_assets). Empty: no
## downloads, bundled fallbacks only.
var cdn_url := "http://127.0.0.1:8090"
var mock := true
var mock_telegram := false
var lang := "fa"
## Set by the screenshot/test harnesses: no animations that wait on real time.
var headless_capture := false


func _ready() -> void:
	_load("res://config/client.cfg")
	_load("res://config/client.local.cfg")
	_load("user://client.cfg")
	_apply_args(OS.get_cmdline_user_args())
	if OS.has_feature("web"):
		_apply_web_query()
	if api_url == "" and OS.has_feature("web"):
		api_url = str(JavaScriptBridge.eval("window.location.origin", true))


func _load(path: String) -> void:
	var cf := ConfigFile.new()
	if cf.load(path) != OK:
		return
	api_url = str(cf.get_value("server", "api_url", api_url)).trim_suffix("/")
	cdn_url = str(cf.get_value("server", "cdn_url", cdn_url)).trim_suffix("/")
	realtime_url = str(cf.get_value("server", "realtime_url", realtime_url))
	mock = bool(cf.get_value("mode", "mock", mock))
	mock_telegram = bool(cf.get_value("mode", "mock_telegram", mock_telegram))
	lang = str(cf.get_value("ui", "lang", lang))


func _apply_args(args: PackedStringArray) -> void:
	for a in args:
		if a == "--mock":
			mock = true
		elif a == "--live":
			mock = false
		elif a == "--tg-mock":
			mock_telegram = true
		elif a.begins_with("--cdn="):
			cdn_url = a.substr(6).trim_suffix("/")
		elif a.begins_with("--api="):
			api_url = a.substr(6).trim_suffix("/")
		elif a.begins_with("--ws="):
			realtime_url = a.substr(5)
		elif a.begins_with("--lang="):
			lang = a.substr(7)


func _apply_web_query() -> void:
	var q = JavaScriptBridge.eval("window.location.search", true)
	if not (q is String) or q == "":
		return
	for pair in (q as String).trim_prefix("?").split("&", false):
		var kv := pair.split("=", true, 1)
		var k := kv[0]
		var v := kv[1].uri_decode() if kv.size() > 1 else ""
		match k:
			"api": api_url = v.trim_suffix("/")
			"cdn": cdn_url = v.trim_suffix("/")
			"ws": realtime_url = v
			"mock": mock = v != "0"
			"lang": lang = v
			"tgmock": mock_telegram = v != "0"


## Persist the connection settings chosen on the Settings screen.
func save_user() -> void:
	var cf := ConfigFile.new()
	cf.load("user://client.cfg")
	cf.set_value("server", "api_url", api_url)
	cf.set_value("server", "realtime_url", realtime_url)
	cf.set_value("mode", "mock", mock)
	cf.set_value("mode", "mock_telegram", mock_telegram)
	cf.set_value("ui", "lang", lang)
	cf.save("user://client.cfg")
	changed.emit()


func api(path: String) -> String:
	return api_url + path
