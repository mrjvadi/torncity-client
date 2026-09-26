extends Node
## Who is playing: tokens, the player, what bootstrap told us about the world,
## the latest vitals (for the HUD) and the notice feed.
##
## Tokens are kept in user://session.dat, encrypted (AES-256, FileAccess
## open_encrypted_with_pass) with a key derived from the device id
## (TokenLogic.storage_key). That keeps them out of casual reach, not away
## from someone who owns the device; the refresh token is the thing to revoke
## (POST /api/v1/auth/logout) if a device is lost.

signal changed          # player / vitals changed (HUD redraws)
signal logged_out
signal notice_added(notice: Dictionary)
signal hub_changed      # the server's main-menu actions changed

## The main menu, exactly as the server sends it: the actions of the
## profile/dashboard screen (the bot's hub keyboard). The side menu draws these.
var hub_actions: Array = []

const STORE := "user://session.dat"
const FEED_MAX := 60

var access_token := ""
var refresh_token := ""
var access_exp := 0
var player := {}        # {id, code, name, lang}
var bootstrap := {}
## Localised names by table: {"city": {code: name}, "place": {...}, "mode": {...}}
var names := {"city": {}, "place": {}, "mode": {}}
## HUD state, merged from any profile/dashboard/bank/job/life view.
var vitals := {}
var city_code := ""
var notices: Array = []
var unread := 0


func _ready() -> void:
	_load()


func set_hub(actions: Array) -> void:
	if actions.is_empty() or actions == hub_actions:
		return
	hub_actions = actions.duplicate(true)
	hub_changed.emit()


func logged_in() -> bool:
	return access_token != "" or refresh_token != ""


func set_tokens(access: String, refresh: String) -> void:
	access_token = access
	if refresh != "":
		refresh_token = refresh
	access_exp = TokenLogic.jwt_exp(access)
	_save()


func set_login(resp: Dictionary) -> void:
	set_tokens(str(resp.get("access_token", "")), str(resp.get("refresh_token", "")))
	var p = resp.get("player")
	if p is Dictionary:
		player = p
		if p.has("name"):
			vitals["name"] = p["name"]
		if p.has("code"):
			vitals["code"] = p["code"]
	_save()
	changed.emit()


func clear() -> void:
	access_token = ""
	refresh_token = ""
	access_exp = 0
	player = {}
	vitals = {}
	bootstrap = {}
	city_code = ""
	notices.clear()
	unread = 0
	if FileAccess.file_exists(STORE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STORE))
	logged_out.emit()


func set_bootstrap(b: Dictionary) -> void:
	bootstrap = b
	var p = b.get("player")
	if p is Dictionary:
		player.merge(p, true)
		absorb_view(p)
	var pc = b.get("player")
	if pc is Dictionary and str(pc.get("city_code", "")) != "":
		city_code = str(pc["city_code"])
	var city = b.get("city")
	if city is Dictionary and city.has("code"):
		city_code = str(city["code"])
		names["city"][city_code] = str(city.get("name", city_code))
	for pair in [["cities", "city"], ["places", "place"], ["modes", "mode"]]:
		var key: String = pair[0]
		var table: String = pair[1]
		var rows = b.get(key)
		if rows is Array:
			for r in rows:
				if r is Dictionary and r.has("code"):
					names[table][str(r["code"])] = str(r.get("name", r["code"]))
	changed.emit()


## Pull whatever the HUD shows out of a view (profile, dashboard, bank, job, life...).
func absorb_view(v: Dictionary) -> void:
	for k in ["name", "code", "avatar", "level", "xp", "next_level_xp", "energy", "max_energy",
			"health", "max_health", "cash", "bank", "city_code", "city", "rank", "needs",
			"energy_full_in_seconds", "travelling", "travel_to"]:
		if v.has(k) and v[k] != null:
			vitals[k] = v[k]
	if v.has("city_code") and str(v["city_code"]) != "":
		city_code = str(v["city_code"])
		if v.has("city"):
			names["city"][city_code] = str(v["city"])
	changed.emit()


func add_notice(n: Dictionary) -> void:
	var entry := n.duplicate()
	entry["at"] = Time.get_unix_time_from_system()
	notices.push_front(entry)
	if notices.size() > FEED_MAX:
		notices.resize(FEED_MAX)
	unread += 1
	notice_added.emit(entry)
	changed.emit()


func mark_read() -> void:
	unread = 0
	changed.emit()


## Swipe-to-dismiss on the notifications feed removes it locally; the server
## keeps no read/unread state for feed entries beyond `unread`.
func dismiss_notice(entry: Dictionary) -> void:
	var i := notices.find(entry)
	if i >= 0:
		notices.remove_at(i)
		changed.emit()


# -- storage ---------------------------------------------------------------------------------
func _key() -> String:
	return TokenLogic.storage_key(OS.get_unique_id())


func _save() -> void:
	var f := FileAccess.open_encrypted_with_pass(STORE, FileAccess.WRITE, _key())
	if f == null:
		return
	f.store_string(JSON.stringify({"refresh": refresh_token, "access": access_token, "player": player}))
	f.close()


func _load() -> void:
	if not FileAccess.file_exists(STORE):
		return
	var f := FileAccess.open_encrypted_with_pass(STORE, FileAccess.READ, _key())
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if d is Dictionary:
		refresh_token = str(d.get("refresh", ""))
		access_token = str(d.get("access", ""))
		access_exp = TokenLogic.jwt_exp(access_token)
		player = d.get("player", {}) if d.get("player") is Dictionary else {}
