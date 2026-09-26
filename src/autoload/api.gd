extends Node
## The game API (v1): auth, bootstrap, commands, realtime tokens.
##
## Every call returns a Dictionary {status: int, data: Variant, error: String}
## (status 0 = no answer). An authorised call refreshes the access token first
## when it is about to expire, and once more after a 401; if the refresh token
## is refused too, the session is over (Session.clear -> link screen).
## In mock mode the same calls are answered by the Mock autoload.

signal busy_changed(busy: bool)

const TIMEOUT := 15.0

var _refreshing := false
var _inflight := 0
signal _refresh_done(ok: bool)


func _set_busy(delta: int) -> void:
	_inflight += delta
	busy_changed.emit(_inflight > 0)


# -- auth ------------------------------------------------------------------------------------
func auth_link(code: String) -> Dictionary:
	var r := await _call("POST", "/api/v1/auth/link", {"code": code, "device_name": _device_name()}, false)
	if r.status == 200 and r.data is Dictionary:
		Session.set_login(r.data)
	return r


func auth_telegram(init_data: String) -> Dictionary:
	var r := await _call("POST", "/api/v1/auth/telegram", {"init_data": init_data}, false)
	if r.status == 200 and r.data is Dictionary:
		Session.set_login(r.data)
	return r


func refresh() -> bool:
	if _refreshing:
		return await _refresh_done
	if Session.refresh_token == "":
		return false
	_refreshing = true
	var r := await _call("POST", "/api/v1/auth/refresh", {"refresh_token": Session.refresh_token}, false)
	var ok: bool = r.status == 200 and r.data is Dictionary and str(r.data.get("access_token", "")) != ""
	if ok:
		Session.set_tokens(str(r.data["access_token"]), str(r.data.get("refresh_token", "")))
	elif r.status == 401 or r.status == 403 or r.status == 400:
		Session.clear()
	_refreshing = false
	_refresh_done.emit(ok)
	return ok


func logout() -> void:
	if Session.refresh_token != "":
		await _call("POST", "/api/v1/auth/logout", {"refresh_token": Session.refresh_token}, true)
	Session.clear()


# -- game ------------------------------------------------------------------------------------
func bootstrap() -> Dictionary:
	var r := await _authed("GET", "/api/v1/bootstrap", null)
	if r.status == 200 and r.data is Dictionary:
		Session.set_bootstrap(r.data)
	return r


## Run a game command. Returns the response body ({ok, screen, text, view,
## actions, notice?, error?}) or a synthetic error body when the call failed.
func command(cmd: String, args := {}) -> Dictionary:
	var body := {"command": cmd, "args": _stringify_args(args), "idempotency_key": _idem_key()}
	var r := await _authed("POST", "/api/v1/command", body)
	if r.data is Dictionary and (r.data as Dictionary).has("ok"):
		var d: Dictionary = r.data
		# screen "notice": a toast-style answer, notice = {text, alert}
		if d.get("notice") is Dictionary:
			var nd: Dictionary = d["notice"]
			d["notice"] = str(nd.get("text", ""))
			d["alert"] = bool(nd.get("alert", false))
		if d.get("view") is Dictionary:
			Session.absorb_view(d["view"])
		return d
	var code := "network" if r.status == 0 else ("auth" if r.status == 401 else "http_%d" % r.status)
	var msg := I18n.t("error.network") if r.status == 0 else I18n.t("error.server", {"status": r.status})
	return {"ok": false, "screen": "error", "text": msg, "error": {"code": code, "message": msg}, "actions": []}


## A plain authorised GET (content catalogue, world): {status, data}.
func get_json(path: String) -> Dictionary:
	return await _authed("GET", path, null)


func realtime_token() -> String:
	var r := await _authed("GET", "/api/v1/realtime/token", null)
	return str(r.data.get("token", "")) if r.data is Dictionary else ""


func subscription_token(channel: String) -> String:
	var r := await _authed("GET", "/api/v1/realtime/subscribe?channel=" + channel.uri_encode(), null)
	return str(r.data.get("token", "")) if r.data is Dictionary else ""


# -- plumbing --------------------------------------------------------------------------------
func _authed(method: String, path: String, body) -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	if Session.access_token == "" or TokenLogic.needs_refresh(Session.access_exp, now):
		if not await refresh():
			return {"status": 401, "data": null, "error": "auth"}
	var r := await _call(method, path, body, true)
	if r.status == 401:
		if await refresh():
			r = await _call(method, path, body, true)
	return r


func _call(method: String, path: String, body, auth: bool) -> Dictionary:
	_set_busy(1)
	var r: Dictionary
	if Config.mock:
		r = await Mock.http(method, path, body, Session.access_token if auth else "")
	else:
		r = await _http(method, path, body, auth)
	_set_busy(-1)
	return r


func _http(method: String, path: String, body, auth: bool) -> Dictionary:
	var req := HTTPRequest.new()
	req.timeout = TIMEOUT
	req.accept_gzip = true
	add_child(req)
	var headers := PackedStringArray(["Accept: application/json", "Accept-Language: " + I18n.lang])
	if auth and Session.access_token != "":
		headers.append("Authorization: Bearer " + Session.access_token)
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	var m := HTTPClient.METHOD_POST if method == "POST" else HTTPClient.METHOD_GET
	var err := req.request(Config.api(path), headers, m, payload)
	if err != OK:
		req.queue_free()
		return {"status": 0, "data": null, "error": "request_failed"}
	var res: Array = await req.request_completed
	req.queue_free()
	var status: int = res[1] if res[0] == HTTPRequest.RESULT_SUCCESS else 0
	var text: String = (res[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(text) if text != "" else null
	return {"status": status, "data": data, "error": "" if status != 0 else "network"}


## The API takes argument values as strings, like the bot's buttons.
static func _stringify_args(args: Dictionary) -> Dictionary:
	var out := {}
	for k in args:
		var v = args[k]
		out[k] = str(int(v)) if v is float and v == floor(v) else str(v)
	return out


static func _idem_key() -> String:
	var b := Crypto.new().generate_random_bytes(12)
	return Marshalls.raw_to_base64(b).replace("+", "-").replace("/", "_").trim_suffix("=")


func _device_name() -> String:
	var os := OS.get_name()
	var model := OS.get_model_name()
	return ("Torncity %s %s" % [os, model if model != "GenericDevice" else ""]).strip_edges().substr(0, 60)
