extends Node
## The game loop from the client's side: log in, bootstrap, send commands,
## hand every answer to the shell, and route realtime events.

signal response(resp: Dictionary, request: Dictionary)
signal ask_input(action: Dictionary)
signal login_needed
signal playing

var last_request := {}
var last_response := {}
var _stack: Array = []      # previous requests, for "back"


func _ready() -> void:
	Realtime.notice.connect(_on_notice)
	Realtime.announce.connect(_on_announce)
	Session.logged_out.connect(func():
		Realtime.stop()
		login_needed.emit())


## Decide how this start-up logs in and try it. Returns true when playing.
func boot() -> bool:
	var method := AuthFlow.decide(TelegramApp.init_data if TelegramApp.available else "", Session.refresh_token)
	if TelegramApp.available and TelegramApp.language_code != "" and not FileAccess.file_exists("user://client.cfg"):
		# First run inside Telegram: speak the user's Telegram language.
		I18n.set_lang("fa" if TelegramApp.language_code.begins_with("fa") else "en", false)
	match method:
		AuthFlow.Method.TELEGRAM:
			var r := await Api.auth_telegram(TelegramApp.init_data)
			if r.status == 200:
				return await start_playing()
			if AuthFlow.after_failure(method, r.status) == AuthFlow.Method.TELEGRAM:
				return false
		AuthFlow.Method.REFRESH:
			if await Api.refresh():
				return await start_playing()
			if TelegramApp.available and AuthFlow.is_plausible_init_data(TelegramApp.init_data):
				var r2 := await Api.auth_telegram(TelegramApp.init_data)
				if r2.status == 200:
					return await start_playing()
	return false


func login_with_code(code: String) -> Dictionary:
	var r := await Api.auth_link(code)
	if r.status == 200:
		await start_playing()
	return r


func start_playing() -> bool:
	var b := await Api.bootstrap()
	if b.status != 200:
		return false
	var plang := str(Session.player.get("lang", ""))
	if plang != "" and I18n.LANGS.has(plang) and plang != I18n.lang and not FileAccess.file_exists("user://client.cfg"):
		I18n.set_lang(plang, false)
	Realtime.set_city(Session.city_code)
	Realtime.start()
	playing.emit()
	return true


## Send a command and show its answer.
func run(cmd: String, args := {}, remember := true) -> Dictionary:
	var req := {"command": cmd, "args": args}
	var resp := await Api.command(cmd, args)
	if not resp.get("ok", false) and str(resp.get("error", {}).get("code", "")) == "auth":
		Session.clear()
		return resp
	if remember and not last_request.is_empty() and last_request != req:
		_stack.push_back(last_request)
		if _stack.size() > 20:
			_stack.pop_front()
	last_request = req
	last_response = resp
	if Session.city_code != "":
		Realtime.set_city(Session.city_code)
	response.emit(resp, req)
	return resp


## Press one of the server's action buttons.
func run_action(action: Dictionary) -> void:
	if action.get("input") is Dictionary:
		ask_input.emit(action)
		return
	var cmd := str(action.get("command", ""))
	if cmd == "":
		return
	var args = action.get("args", {})
	await run(cmd, args if args is Dictionary else {})


func can_go_back() -> bool:
	return not _stack.is_empty()


func back() -> void:
	if _stack.is_empty():
		await run("player.profile.get", {}, false)
		return
	var req: Dictionary = _stack.pop_back()
	await run(req["command"], req["args"], false)


func refresh_current() -> void:
	if not last_request.is_empty():
		await run(last_request["command"], last_request["args"], false)


func switch_language(l: String) -> void:
	I18n.set_lang(l)
	await Api.command("player.language.set", {"lang": l})
	await refresh_current()


func _on_notice(data: Dictionary) -> void:
	Session.add_notice(data)
	var v = data.get("view")
	if v is Dictionary:
		Session.absorb_view(v)


func _on_announce(data: Dictionary) -> void:
	var n := data.duplicate()
	if data.get("texts") is Dictionary and data["texts"].has(I18n.lang):
		n["text"] = str(data["texts"][I18n.lang])
	n["kind"] = "announce"
	Session.add_notice(n)
