extends Node
## An offline stand-in for the game API and Centrifugo, so the client runs with
## no server at all (Config.mock). It answers the same HTTP routes with the
## same JSON shapes as the v1 contract (api/client-api.md on the server), keeps
## a small in-memory game state, and speaks the Centrifugo JSON protocol over a
## loopback transport — so the real protocol code runs in mock mode too.

const FIXTURES := "res://src/mock/fixtures.json"
const ACCESS_TTL := 900
const TIME_SCALE := 60.0      # one game minute is one real second (config game.time_scale)
const PING_EVERY := 25.0
const ANNOUNCE_EVERY := 50.0

var fx := {}
var st := {}
var latency := 0.12
var _refresh_tokens := {}
var _rng := RandomNumberGenerator.new()

# realtime
var _rt: Object = null
var _rt_subs := {}
var _ping_t := 0.0
var _announce_t := 20.0
var _announce_i := 0


func _ready() -> void:
	_rng.seed = 7
	fx = JSON.parse_string(FileAccess.get_file_as_string(FIXTURES))
	reset()


func reset() -> void:
	st = {
		"lang": "fa", "cash": 12450, "bank": 86300, "energy": 72, "max_energy": 100,
		"health": 88, "max_health": 100, "level": 7, "xp": 5400, "next_level_xp": 6500,
		"city": fx["home_city"], "place": "city_centre", "walk": null, "travel": null,
		"needs": {"hunger": 34, "sleep": 52, "stress": 22, "happiness": 71},
		"age": 27, "avatar": fx["player"]["avatar"], "shift": null, "achievements": 3, "certificates": 2,
	}


func now() -> float:
	return Time.get_unix_time_from_system()


func L(fa: String, en: String) -> String:
	return fa if st["lang"] == "fa" else en


func num(n: int) -> String:
	return Fmt.number(n, st["lang"])


func money(n: int) -> String:
	return Fmt.money(n, st["lang"])


func dur(s: int) -> String:
	return Fmt.duration(s, st["lang"])


# -- names -------------------------------------------------------------------------------------
func city_name(code: String) -> String:
	return str(fx["cities"].get(code, {}).get(st["lang"], code))


func place_row(code: String) -> Dictionary:
	for p in fx["places"]:
		if p["code"] == code:
			return p
	return {}


func place_name(code: String) -> String:
	return str(place_row(code).get(st["lang"], code))


func mode_row(code: String) -> Dictionary:
	for m in fx["modes"]:
		if m["code"] == code:
			return m
	return {}


func player_name() -> String:
	return str(fx["player"]["name_" + st["lang"]])


func named(code: String, name: String) -> Dictionary:
	return {"code": code, "name": name}


# -- tokens ----------------------------------------------------------------------------------------
static func _b64url(s: String) -> String:
	return Marshalls.utf8_to_base64(s).replace("+", "-").replace("/", "_").replace("=", "")


func jwt(claims: Dictionary) -> String:
	return "%s.%s.%s" % [_b64url('{"alg":"HS256","typ":"JWT"}'), _b64url(JSON.stringify(claims)), _b64url("mock-signature")]


func _issue() -> Dictionary:
	var refresh := "mock-refresh-%d" % _rng.randi()
	_refresh_tokens[refresh] = true
	var p: Dictionary = fx["player"]
	return {
		"access_token": jwt({"sub": str(p["id"]), "exp": int(now()) + ACCESS_TTL}),
		"refresh_token": refresh,
		"player": {"id": p["id"], "code": p["code"], "name": player_name(), "lang": st["lang"]},
	}


func _authorised(token: String) -> bool:
	if token == "":
		return false
	var exp := TokenLogic.jwt_exp(token)
	return exp == 0 or exp > int(now())


# -- HTTP ---------------------------------------------------------------------------------------------
func http(method: String, path: String, body, token: String) -> Dictionary:
	if latency > 0 and not Config.headless_capture:
		await get_tree().create_timer(latency).timeout
	_tick()
	var route := path.split("?")[0]
	match [method, route]:
		["POST", "/api/v1/auth/link"]:
			var code := AuthFlow.normalize_code(str(body.get("code", "")))
			if code == "" or code == "00000000":
				return _err(401, "invalid_code", L("این کد معتبر نیست یا منقضی شده است. در ربات /link را بفرستید تا کد تازه بگیرید.", "That code is not valid or has expired. Send /link to the bot for a new one."))
			st["lang"] = I18n.lang
			return {"status": 200, "data": _issue(), "error": ""}
		["POST", "/api/v1/auth/telegram"]:
			if not AuthFlow.is_plausible_init_data(str(body.get("init_data", ""))):
				return _err(401, "invalid_init_data", "invalid init data")
			st["lang"] = I18n.lang
			return {"status": 200, "data": _issue(), "error": ""}
		["POST", "/api/v1/auth/refresh"]:
			var rt := str(body.get("refresh_token", ""))
			if not _refresh_tokens.has(rt) and not rt.begins_with("mock-refresh-"):
				return _err(401, "invalid_refresh", "refresh token rejected")
			_refresh_tokens.erase(rt)
			return {"status": 200, "data": _issue(), "error": ""}
		["POST", "/api/v1/auth/logout"]:
			_refresh_tokens.erase(str(body.get("refresh_token", "")))
			return {"status": 204, "data": null, "error": ""}
	if not _authorised(token):
		return _err(401, "unauthorized", "unauthorized")
	match [method, route]:
		["GET", "/api/v1/bootstrap"]:
			return {"status": 200, "data": _bootstrap(), "error": ""}
		["GET", "/api/v1/realtime/token"]:
			return {"status": 200, "data": {"token": jwt({"sub": str(fx["player"]["id"]), "exp": int(now()) + 600})}, "error": ""}
		["GET", "/api/v1/realtime/subscribe"]:
			var ch := path.split("channel=")[1].uri_decode() if path.contains("channel=") else ""
			return {"status": 200, "data": {"token": jwt({"sub": str(fx["player"]["id"]), "channel": ch, "exp": int(now()) + 900})}, "error": ""}
		["GET", "/api/v1/world/city"]:
			var code := path.split("code=")[1].split("&")[0].uri_decode() if path.contains("code=") else str(st["city"])
			return {"status": 200, "data": world_fixture(code), "error": ""}
		["GET", "/api/v1/content"]:
			var since := path.split("since=")[1].uri_decode() if path.contains("since=") else ""
			var cat: Dictionary = content_fixture()
			if since == str(cat["version"]):
				return {"status": 200, "data": {"version": cat["version"], "unchanged": true}, "error": ""}
			return {"status": 200, "data": cat, "error": ""}
		["POST", "/api/v1/command"]:
			return {"status": 200, "data": command(str(body.get("command", "")), body.get("args", {})), "error": ""}
	return _err(404, "not_found", "not found")


var _content := {}


var _world := {}


## The city layout: the same template for every city (the real server builds
## it from its content and the city's companies).
func world_fixture(code: String) -> Dictionary:
	if _world.is_empty():
		_world = JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/world.json"))
	var w: Dictionary = _world.duplicate(true)
	w["city"] = code
	return w


## A company opened, closed or changed: {type:"world.plot"} on city:<code>.
func push_plot(plot: Dictionary, op := "upsert") -> void:
	var ch := "city:" + str(st["city"])
	var data := {"type": "world.plot", "city": st["city"], "op": op}
	if op == "remove":
		data["id"] = plot.get("id", "")
	else:
		data["plot"] = plot
	if _rt and _rt_subs.has(ch):
		_rt.deliver(JSON.stringify({"push": {"channel": ch, "pub": {"data": data}}}))


func content_fixture() -> Dictionary:
	if _content.is_empty():
		_content = JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/content.json"))
	return _content


func _err(status: int, code: String, message: String) -> Dictionary:
	return {"status": status, "data": {"ok": false, "error": {"code": code, "message": message}}, "error": code}


func _bootstrap() -> Dictionary:
	var cities := []
	for c in fx["cities"]:
		cities.append({"code": c, "name": city_name(c)})
	var places := []
	for p in fx["places"]:
		places.append({"code": p["code"], "name": p[st["lang"]]})
	var modes := []
	for m in fx["modes"]:
		modes.append({"code": m["code"], "name": m[st["lang"]]})
	return {
		"player": {"id": fx["player"]["id"], "code": fx["player"]["code"], "name": player_name(), "lang": st["lang"],
			"avatar": st["avatar"], "level": st["level"], "cash": st["cash"], "bank": st["bank"],
			"energy": st["energy"], "max_energy": st["max_energy"], "health": st["health"], "max_health": st["max_health"],
			"city_code": st["city"], "city": city_name(st["city"]), "needs": st["needs"], "rank": _rank()},
		"city": {"code": st["city"], "name": city_name(st["city"])},
		"cities": cities, "places": places, "modes": modes,
		"languages": [{"code": "fa", "name": "فارسی"}, {"code": "en", "name": "English"}],
	}


# -- the game clock -------------------------------------------------------------------------------------
## Resolve anything that finished while nobody asked (walks, journeys, shifts).
func _tick() -> void:
	var t := now()
	var w = st["walk"]
	if w is Dictionary and t >= w["ends"]:
		st["place"] = w["to"]
		st["walk"] = null
		push_notice("arrived", L("📍 به %s رسیدید." % place_name(w["to"]), "📍 You reached the %s." % place_name(w["to"]).to_lower()),
			{"place": named(w["to"], place_name(w["to"])), "city_code": st["city"]})
	var tr = st["travel"]
	if tr is Dictionary and t >= tr["ends"]:
		st["city"] = tr["to"]
		st["place"] = "city_centre"
		st["travel"] = null
		st["xp"] += 120
		push_notice("travel_arrived", L("📍 به %s رسیدید.\n⭐ ۱۲۰ امتیاز تجربه گرفتید." % city_name(tr["to"]), "📍 You arrived in %s.\n⭐ You earned 120 XP." % city_name(tr["to"])),
			{"city_code": st["city"], "city": city_name(st["city"])})
	var sh = st["shift"]
	if sh is Dictionary and t >= sh["ends"]:
		st["shift"] = null
		st["cash"] += int(fx["job"]["pay"])
		push_notice("shift_paid", L("💰 شیفت تمام شد و %s دستمزد گرفتید." % money(int(fx["job"]["pay"])), "💰 Your shift is over: you were paid %s." % money(int(fx["job"]["pay"]))),
			{"cash": st["cash"]})


func _process(delta: float) -> void:
	if st.is_empty():
		return
	_tick()
	if _rt == null:
		return
	_ping_t += delta
	if _ping_t >= PING_EVERY:
		_ping_t = 0.0
		_rt.deliver("{}")
	_announce_t += delta
	if _announce_t >= ANNOUNCE_EVERY:
		_announce_t = 0.0
		var list: Array = fx["announcements"][st["lang"]]
		push_announce(list[_announce_i % list.size()])
		_announce_i += 1


# -- commands ---------------------------------------------------------------------------------------------
func command(cmd: String, args: Dictionary) -> Dictionary:
	_tick()
	match cmd:
		"player.profile.get": return _profile()
		"map.list": return _city_map()
		"place.go": return _place_go(str(args.get("place", "")))
		"map.cities": return _cities()
		"travel.options": return _travel_options(str(args.get("city", "")))
		"travel.start": return _travel_start(str(args.get("city", "")), str(args.get("mode", "")))
		"travel.status": return _travel_status()
		"bank.show": return _bank("")
		"bank.deposit": return _bank_move(int(str(args.get("amount", "0"))), true)
		"bank.withdraw": return _bank_move(int(str(args.get("amount", "0"))), false)
		"inventory.show": return _inventory()
		"company.show": return _company_show(int(str(args.get("id", "0"))))
		"job.status": return _job()
		"job.work": return _job_work()
		"life.me": return _life()
		"player.settings": return _settings()
		"player.language.set":
			var l := str(args.get("lang", "fa"))
			if l in ["fa", "en"]:
				st["lang"] = l
			return _settings()
	return _generic(cmd)


func _resp(screen: String, text: String, view, actions: Array, notice := "") -> Dictionary:
	var r := {"ok": true, "screen": screen, "text": text, "view": view, "actions": actions}
	if notice != "":
		r["notice"] = notice
	return r


func _act(label: String, cmd: String, args := {}) -> Dictionary:
	return {"label": label, "command": cmd, "args": args}


func _back() -> Dictionary:
	return _act(L("🔙 بازگشت", "🔙 Back"), "player.profile.get")


func _refresh(cmd: String, args := {}) -> Dictionary:
	return _act(L("🔄 به‌روزرسانی", "🔄 Refresh"), cmd, args)


func _walk_view() -> Variant:
	var w = st["walk"]
	if not (w is Dictionary):
		return null
	var rem := maxi(0, int(w["ends"] - now()))
	return {"to": named(w["to"], place_name(w["to"])), "remaining_seconds": rem,
		"arrives_at": Time.get_datetime_string_from_unix_time(int(w["ends"])) + "Z", "from": named(w["from"], place_name(w["from"])),
		"total_seconds": int(w["dur"])}


func _rank() -> Dictionary:
	return {"code": "citizen", "name": L("شهروند", "Citizen"), "emoji": "🏅"}


func _profile() -> Dictionary:
	var tr = st["travel"]
	var v := {
		"name": player_name(), "code": fx["player"]["code"], "avatar": st["avatar"],
		"city_code": st["city"], "city": city_name(st["city"]),
		"place": named(st["place"], place_name(st["place"])), "walk": _walk_view(),
		"level": st["level"], "xp": st["xp"], "next_level_xp": st["next_level_xp"],
		"energy": st["energy"], "max_energy": st["max_energy"], "energy_full_in_seconds": (st["max_energy"] - st["energy"]) * 36,
		"health": st["health"], "max_health": st["max_health"], "cash": st["cash"], "bank": st["bank"],
		"travelling": tr is Dictionary, "travel_to_code": tr["to"] if tr is Dictionary else "",
		"travel_to": city_name(tr["to"]) if tr is Dictionary else "",
		"travel_remaining_seconds": maxi(0, int(tr["ends"] - now())) if tr is Dictionary else 0,
		"work": {"job": {"job": {"career_code": fx["job"]["career_code"], "career_name": fx["job"]["career_" + st["lang"]],
			"rank": fx["job"]["rank"], "title": fx["job"]["title_" + st["lang"]]}, "city_code": st["city"], "city": city_name(st["city"]),
			"pay": fx["job"]["pay"], "shift_ends_in_seconds": maxi(0, int(st["shift"]["ends"] - now())) if st["shift"] is Dictionary else 0},
			"course": null, "certificates": st["certificates"]},
		"jail": null, "hospital": null, "achievements": st["achievements"], "rank": _rank(),
		"age": st["age"], "stage": named("adult", L("بزرگسال", "Adult")),
		"needs": {"hunger": st["needs"]["hunger"], "sleep": st["needs"]["sleep"], "stress": st["needs"]["stress"],
			"happiness": st["needs"]["happiness"], "body_bps": 10000, "xpbps": 10000, "pressing": []},
	}
	var lines := [
		L("👤 %s", "👤 %s") % player_name(),
		L("📍 %s - %s", "📍 %s - %s") % [place_name(st["place"]), city_name(st["city"])],
		L("⭐ سطح %s - %s امتیاز تجربه تا سطح %s", "⭐ Level %s - %s XP to level %s") % [num(st["level"]), num(st["next_level_xp"] - st["xp"]), num(st["level"] + 1)],
		L("⚡ انرژی: %s از %s", "⚡ Energy: %s of %s") % [num(st["energy"]), num(st["max_energy"])],
		L("❤️ سلامت: %s از %s", "❤️ Health: %s of %s") % [num(st["health"]), num(st["max_health"])],
		L("💵 پول نقد: %s", "💵 Cash: %s") % money(st["cash"]),
		L("🏦 موجودی بانک: %s", "🏦 Bank: %s") % money(st["bank"]),
		L("🆔 کد بازیکن: %s", "🆔 Player code: %s") % fx["player"]["code"],
	]
	return _resp("profile", "\n".join(lines), v, [
		_act(L("🗺 نقشه", "🗺 Map"), "map.list"), _act(L("🏦 بانک", "🏦 Bank"), "bank.show"),
		_act(L("🛠 مهارت‌ها", "🛠 Skills"), "skills.list"), _act(L("👥 دوستان", "👥 Friends"), "social.friend.list"),
		_act(L("⚙️ تنظیمات", "⚙️ Settings"), "player.settings")])


func _places_here() -> Array:
	var fac: Array = fx["cities"][st["city"]]["facilities"]
	var out := []
	for p in fx["places"]:
		if p.has("requires") and not fac.has(p["requires"]):
			continue
		out.append(p)
	return out


func _city_map(notice := "") -> Dictionary:
	var tr = st["travel"]
	var places := []
	var lines := [L("🗺 نقشهٔ %s", "🗺 Map of %s") % city_name(st["city"])]
	var w = st["walk"]
	if w is Dictionary:
		lines.append(L("🚶 در راه %s هستید - %s مانده", "🚶 Walking to the %s - %s left") % [place_name(w["to"]), dur(int(w["ends"] - now()))])
	else:
		lines.append(L("📍 شما در %s هستید.", "📍 You are at the %s.") % place_name(st["place"]))
	for p in _places_here():
		var here: bool = p["code"] == st["place"] and not (w is Dictionary)
		places.append({"place": named(p["code"], p[st["lang"]]), "walk_seconds": int(p["walk"]), "energy": int(p["energy"]),
			"services": p["services"], "departures": p.get("departures", []), "shops": [], "here": here})
		lines.append(("• %s (" + L("همین‌جا", "here") + ")") % p[st["lang"]] if here else "• %s - %s" % [p[st["lang"]], dur(int(p["walk"]))])
	var v := {"city_code": st["city"], "city": city_name(st["city"]), "no_city": false,
		"travelling": tr is Dictionary, "travelling_to_code": tr["to"] if tr is Dictionary else "",
		"travelling_to": city_name(tr["to"]) if tr is Dictionary else "",
		"here": named(st["place"], place_name(st["place"])), "walking": _walk_view(), "others": 4 + _rng.randi() % 9,
		"places": places}
	var acts := []
	for p in places:
		if not p["here"]:
			acts.append(_act("🚶 %s" % p["place"]["name"], "place.go", {"place": p["place"]["code"]}))
	acts.append(_act(L("🧭 سفر به شهر دیگر", "🧭 Travel to another city"), "map.cities"))
	acts.append(_refresh("map.list"))
	return _resp("city_map", "\n".join(lines), v, acts, notice)


func _place_go(code: String) -> Dictionary:
	var p := place_row(code)
	if p.is_empty():
		return {"ok": false, "screen": "error", "text": L("چنین جایی در این شهر نیست.", "There is no such place in this city."), "error": {"code": "unknown_place", "message": ""}, "actions": [_back()]}
	if st["walk"] is Dictionary:
		return _city_map(L("🚶 هنوز در راه %s هستید." % place_name(st["walk"]["to"]), "🚶 You are still walking to the %s." % place_name(st["walk"]["to"])))
	if code == st["place"]:
		return _city_map(L("📍 شما الان در %s هستید." % place_name(code), "📍 You are at the %s already." % place_name(code)))
	var secs := int(p["walk"])
	st["energy"] = maxi(0, st["energy"] - int(p["energy"]))
	st["walk"] = {"from": st["place"], "to": code, "ends": now() + secs, "dur": secs}
	return _city_map(L("🚶 به سوی %s راه افتادید - %s پیاده‌روی." % [place_name(code), dur(secs)], "🚶 You set off for the %s - a %s walk." % [place_name(code), dur(secs)]))


func _distance(a: String, b: String) -> int:
	for r in fx["routes"]:
		if (r[0] == a and r[1] == b) or (r[0] == b and r[1] == a):
			return int(r[2])
	return 0


func _cities() -> Dictionary:
	var dests := []
	var lines := [L("🧭 سفر به شهر دیگر", "🧭 Travel to another city"), L("📍 شما در %s هستید.", "📍 You are in %s.") % city_name(st["city"])]
	for c in fx["cities"]:
		var d := _distance(st["city"], c)
		if d > 0:
			dests.append({"code": c, "name": city_name(c), "distance_km": d})
			lines.append(L("• %s - %s کیلومتر", "• %s - %s km") % [city_name(c), num(d)])
	var tr = st["travel"]
	var acts := []
	for d in dests:
		acts.append(_act("🧭 %s" % d["name"], "travel.options", {"city": d["code"]}))
	acts.append(_act(L("🗺 نقشه", "🗺 Map"), "map.list"))
	return _resp("cities", "\n".join(lines), {"destinations": dests, "page": 1, "pages": 1, "origin_code": st["city"],
		"origin": city_name(st["city"]), "travelling": tr is Dictionary, "travelling_to_code": tr["to"] if tr is Dictionary else "",
		"travelling_to": city_name(tr["to"]) if tr is Dictionary else ""}, acts)


func _options_for(to: String) -> Array:
	var d := _distance(st["city"], to)
	var here: Array = fx["cities"][st["city"]]["facilities"]
	var there: Array = fx["cities"][to]["facilities"]
	var out := []
	for m in fx["modes"]:
		var req: String = m["requires"]
		if req != "" and (not here.has(req) or not there.has(req)):
			continue
		var fare := int(m["base"]) + int(m["per"]) * d
		var game_minutes := int(m["boarding"]) + int(round(d * 60.0 / float(m["speed"])))
		out.append({"mode_code": m["code"], "mode_name": m[st["lang"]], "fare": fare,
			"wait_seconds": int(game_minutes * 60 / TIME_SCALE), "energy": int(m["energy"]), "busy": m["code"] == "bus",
			"vehicle": null, "condition": 0})
	return out


func _travel_options(to: String) -> Dictionary:
	if _distance(st["city"], to) == 0:
		return _cities()
	var opts := _options_for(to)
	var lines := [L("🧭 سفر به %s\n📍 مبدأ: %s", "🧭 Travel to %s\n📍 From: %s") % [city_name(to), city_name(st["city"])], L("با چه وسیله‌ای می‌روید؟", "How will you travel?")]
	var acts := []
	for o in opts:
		lines.append("• %s - %s - %s - %s" % [o["mode_name"], money(o["fare"]), dur(o["wait_seconds"]), num(o["energy"])])
		acts.append(_act("%s - %s" % [o["mode_name"], money(o["fare"])], "travel.start", {"city": to, "mode": o["mode_code"], "max": str(o["fare"])}))
	acts.append(_act(L("🔙 بازگشت", "🔙 Back"), "map.cities"))
	return _resp("travel_options", "\n".join(lines), {"from_code": st["city"], "from": city_name(st["city"]), "to_code": to,
		"to": city_name(to), "cash": st["cash"], "requoted": false, "options": opts}, acts)


func _travel_start(to: String, mode: String) -> Dictionary:
	for o in _options_for(to):
		if o["mode_code"] == mode:
			if st["cash"] < o["fare"]:
				return {"ok": false, "screen": "error", "text": L("💵 پول نقد کافی برای این کرایه ندارید.", "💵 You do not have enough cash for this fare."), "error": {"code": "insufficient_cash", "message": ""}, "actions": [_act(L("🏦 بانک", "🏦 Bank"), "bank.show")]}
			st["cash"] -= o["fare"]
			st["energy"] = maxi(0, st["energy"] - o["energy"])
			st["walk"] = null
			st["travel"] = {"from": st["city"], "to": to, "mode": mode, "ends": now() + o["wait_seconds"], "dur": o["wait_seconds"]}
			var r := _travel_status()
			r["notice"] = L("🧭 سفر با %s به سوی %s آغاز شد" % [o["mode_name"], city_name(to)], "🧭 Your %s journey to %s has begun" % [o["mode_name"].to_lower(), city_name(to)])
			return r
	return _travel_options(to)


func _travel_status() -> Dictionary:
	var tr = st["travel"]
	if not (tr is Dictionary):
		return _resp("travel_status", L("الان در سفر نیستید. برای سفر، «نقشه» را باز کنید.", "You are not travelling. Open the «Map» to travel."), null, [_act(L("🗺 نقشه", "🗺 Map"), "map.list")])
	var rem := maxi(0, int(tr["ends"] - now()))
	var m := mode_row(tr["mode"])
	return _resp("travel_status", L("🧭 در راه %s\n📍 مبدأ: %s\n⏳ %s تا رسیدن", "🧭 On the way to %s\n📍 From: %s\n⏳ %s to arrival") % [city_name(tr["to"]), city_name(tr["from"]), dur(rem)],
		{"from_code": tr["from"], "from": city_name(tr["from"]), "to_code": tr["to"], "to": city_name(tr["to"]), "mode_code": tr["mode"],
		"mode_name": m.get(st["lang"], tr["mode"]), "remaining_seconds": rem, "total_seconds": int(tr["dur"]),
		"arrives_at": Time.get_datetime_string_from_unix_time(int(tr["ends"])) + "Z"},
		[_refresh("travel.status")])


func _amounts(total: int, fee_bps: int) -> Array:
	var out := []
	for a in [1000, 5000, 10000]:
		if a + a * fee_bps / 10000 <= total:
			out.append({"amount": a, "nonce": "n%d" % a, "all": false})
	if total > 0:
		out.append({"amount": total * 10000 / (10000 + fee_bps), "nonce": "nall", "all": true})
	return out


func _bank(notice: String) -> Dictionary:
	var fee := 50
	var v := {"city_code": st["city"], "city": city_name(st["city"]), "travelling": st["travel"] is Dictionary, "no_city": false,
		"jailed": false, "cash": st["cash"], "bank": st["bank"], "withdrawal_fee_bps": fee,
		"deposits": _amounts(st["cash"], 0), "withdrawals": _amounts(st["bank"], fee),
		"can_deposit": st["cash"] > 0, "can_withdraw": st["bank"] > 0, "notice": notice}
	var acts := []
	for d in v["deposits"]:
		acts.append(_act((L("📥 واریز همه - %s", "📥 Deposit all - %s") if d["all"] else L("📥 واریز %s", "📥 Deposit %s")) % money(d["amount"]), "bank.deposit", {"amount": str(d["amount"]), "nonce": d["nonce"]}))
	for d in v["withdrawals"]:
		acts.append(_act((L("📤 برداشت همه - %s", "📤 Withdraw all - %s") if d["all"] else L("📤 برداشت %s", "📤 Withdraw %s")) % money(d["amount"]), "bank.withdraw", {"amount": str(d["amount"]), "nonce": d["nonce"]}))
	acts.append({"label": L("✏️ واریز مبلغ دلخواه", "✏️ Deposit another amount"), "command": "bank.deposit", "args": {}, "input": {"field": "amount", "text": L("چه مبلغی واریز شود؟", "How much to deposit?")}})
	acts.append({"label": L("✏️ برداشت مبلغ دلخواه", "✏️ Withdraw another amount"), "command": "bank.withdraw", "args": {}, "input": {"field": "amount", "text": L("چه مبلغی برداشت شود؟", "How much to withdraw?")}})
	var text := L("🏦 بانک %s\n💵 پول نقد: %s\n🏦 موجودی بانک: %s\nکارمزد برداشت: ٪۰٫۵", "🏦 Bank of %s\n💵 Cash: %s\n🏦 Bank: %s\nWithdrawal fee: 0.5%%") % [city_name(st["city"]), money(st["cash"]), money(st["bank"])]
	return _resp("bank", text, v, acts, notice)


func _bank_move(amount: int, deposit: bool) -> Dictionary:
	if amount <= 0:
		return _bank(L("⚠️ مبلغ باید بیشتر از صفر باشد.", "⚠️ The amount must be more than zero."))
	if deposit:
		if amount > st["cash"]:
			return _bank(L("⚠️ این مقدار پول نقد همراه ندارید.", "⚠️ You do not carry that much cash."))
		st["cash"] -= amount
		st["bank"] += amount
		return _bank(L("📥 %s به حساب بانکی شما واریز شد." % money(amount), "📥 %s was deposited to your account." % money(amount)))
	var fee := amount * 50 / 10000
	if amount + fee > st["bank"]:
		return _bank(L("⚠️ موجودی بانک برای این برداشت کافی نیست.", "⚠️ Your balance does not cover this withdrawal."))
	st["bank"] -= amount + fee
	st["cash"] += amount
	return _bank(L("📤 %s برداشت شد - کارمزد %s." % [money(amount), money(fee)], "📤 You withdrew %s - fee %s." % [money(amount), money(fee)]))


func _inventory() -> Dictionary:
	var lines := []
	var text := [L("🎒 کوله‌پشتی", "🎒 Backpack")]
	var i := 0
	for it in fx["inventory"]:
		i += 1
		lines.append({"item": named(it["code"], it[st["lang"]]), "design": "", "category": it["category"], "qty": it["qty"],
			"serial": "", "quality": it.get("quality", 0), "uses_left": it.get("uses_left", 0), "durability": it.get("durability", 0)})
		text.append("• %s × %s" % [it[st["lang"]], num(int(it["qty"]))])
	var acts := []
	for l in lines:
		acts.append(_act(l["item"]["name"], "inventory.item", {"item": l["item"]["code"]}))
	acts.append(_back())
	return _resp("inventory", "\n".join(text), {"lines": lines, "page": 1, "pages": 1, "total": lines.size(), "in_escrow": 0}, acts)


func _job() -> Dictionary:
	var j: Dictionary = fx["job"]
	var sh = st["shift"]
	var at_work: bool = st["place"] == j["workplace"] and not (st["walk"] is Dictionary)
	var v := {"employed": true, "job": {"career_code": j["career_code"], "career_name": j["career_" + st["lang"]], "rank": j["rank"], "title": j["title_" + st["lang"]]},
		"employer": j["employer_" + st["lang"]], "city_code": st["city"], "city": city_name(st["city"]), "pay": j["pay"],
		"energy_cost": j["energy_cost"], "energy": st["energy"], "max_energy": st["max_energy"], "performance": j["performance"],
		"shifts_in_tier": 7, "total_earned": 48200, "at_workplace": at_work, "top_tier": false,
		"shift_length_seconds": j["shift"], "workplace": named(j["workplace"], place_name(j["workplace"])),
		"walk_to_work_seconds": 0 if at_work else int(place_row(j["workplace"])["walk"]),
		"shift": {"remaining_seconds": maxi(0, int(sh["ends"] - now())), "ends_at": Time.get_datetime_string_from_unix_time(int(sh["ends"])) + "Z", "total_seconds": j["shift"]} if sh is Dictionary else null,
		"next": {"title": L("سرپرست فروش", "Sales supervisor"), "pay": 2600}, "promotion_ready": false, "missing": [L("۳ شیفت دیگر", "3 more shifts")]}
	var text := L("💼 %s در %s - %s برای هر شیفت\n📈 عملکرد: %s از ۱۰۰", "💼 %s at %s - %s per shift\n📈 Performance: %s of 100") % [v["job"]["title"], v["employer"], money(j["pay"]), num(j["performance"])]
	var acts := []
	if not (sh is Dictionary):
		acts.append(_act(L("🛠 شروع شیفت", "🛠 Start a shift") if at_work else L("🚶 رفتن به محل کار و شروع شیفت", "🚶 Walk to work and start"), "job.work"))
	acts.append(_act(L("💼 فرصت‌های شغلی", "💼 Job openings"), "job.list"))
	acts.append(_refresh("job.status"))
	return _resp("job_status", text, v, acts)


func _job_work() -> Dictionary:
	var j: Dictionary = fx["job"]
	if st["shift"] is Dictionary:
		return _job()
	if st["place"] != j["workplace"]:
		st["place"] = j["workplace"]  # the mock walks you there instantly
	if st["energy"] < int(j["energy_cost"]):
		var r := _job()
		r["notice"] = L("⚡ انرژی کافی ندارید.", "⚡ Not enough energy.")
		return r
	st["energy"] -= int(j["energy_cost"])
	st["shift"] = {"ends": now() + int(j["shift"])}
	var r := _job()
	r["notice"] = L("🛠 شیفت شروع شد.", "🛠 Your shift has started.")
	return r


func _life() -> Dictionary:
	var n: Dictionary = st["needs"]
	var v := {"needs": {"hunger": n["hunger"], "sleep": n["sleep"], "stress": n["stress"], "happiness": n["happiness"], "body_bps": 10000, "xpbps": 10000, "pressing": []},
		"age": st["age"], "stage": named("adult", L("بزرگسال", "Adult")), "intelligence": 58, "intelligence_max": 100, "course_bps": 600, "skill_bps": 400,
		"rank": _rank(), "next": {"code": "notable", "name": L("سرشناس", "Notable"), "emoji": "🎖"}, "next_need": 150000,
		"worth": {"cash": st["cash"], "bank": st["bank"], "escrow": 0, "equity": 0, "property": 0, "goods": 3200, "debts": 0, "savings": 0, "gold": 0, "loans": 0, "total": st["cash"] + st["bank"] + 3200},
		"spots": [], "sleep_in_seconds": 0, "home": false, "notice": "", "notice_args": {}}
	var text := L("🧬 زندگی من\n🎂 %s ساله - بزرگسال\n🍞 گرسنگی: %s\n🛏 خواب: %s\n😣 استرس: %s\n😊 شادی: %s", "🧬 My life\n🎂 Age %s - Adult\n🍞 Hunger: %s\n🛏 Sleep: %s\n😣 Stress: %s\n😊 Happiness: %s") % [num(st["age"]), num(n["hunger"]), num(n["sleep"]), num(n["stress"]), num(n["happiness"])]
	return _resp("life", text, v, [_act(L("🛏 خوابیدن", "🛏 Sleep"), "life.sleep"), _act(L("🪪 کارت من", "🪪 My card"), "life.card"), _act(L("🏆 برترین‌ها", "🏆 Leaderboards"), "life.top"), _back()])


func _company_show(id: int) -> Dictionary:
	for p in world_fixture(str(st["city"]))["plots"]:
		if p.get("kind") == "company" and int(p["ref"].get("company_id", 0)) == id:
			var nm: Dictionary = p["name"]
			var t := str(p["ref"]["code"])
			var tname := Content.name_of("company_type", t)
			var text := L("🏢 %s\n%s · مالک: %s\n\n📈 تولید امروز: ۱۲۰ واحد\n👥 کارمندان: ۸" % [nm["fa"], tname, p["ref"]["owner"]],
				"🏢 %s\n%s · Owner: %s\n\n📈 Output today: 120 units\n👥 Staff: 8" % [nm["en"], tname, p["ref"]["owner"]])
			return _resp("company", text, {"company": {"id": id, "type": t, "name": nm[st["lang"]], "owner": p["ref"]["owner"], "staff": 8}},
				[_act(L("📦 انبار", "📦 Stock"), "company.stock", {"id": id}), _act(L("👥 کارمندان", "👥 Staff"), "company.staff", {"id": id}), _back()])
	return _resp("error", L("این شرکت پیدا نشد.", "Company not found."), null, [_back()])


func _settings() -> Dictionary:
	var other := "en" if st["lang"] == "fa" else "fa"
	return _resp("settings", L("⚙️ تنظیمات\n🌐 زبان: فارسی", "⚙️ Settings\n🌐 Language: English"), null,
		[_act(L("🌐 تغییر زبان به English", "🌐 Switch language to فارسی"), "player.language.set", {"lang": other}), _back()])


## Any other command: a text card, the way the bot would answer it.
func _generic(cmd: String) -> Dictionary:
	var titles := {
		"skills.list": ["🛠 مهارت‌ها\n• مدیریت - سطح ۳ - ٪۴۰ تا سطح بعد\n• رانندگی - سطح ۲ - ٪۷۵ تا سطح بعد\n• آشپزی - سطح ۱ - ٪۱۰ تا سطح بعد", "🛠 Skills\n• Management - level 3 - 40% to next level\n• Driving - level 2 - 75% to next level\n• Cooking - level 1 - 10% to next level"],
		"social.friend.list": ["👥 دوستان\n• نیما - سطح ۹ - در فنویک اسپن\n• مریم - سطح ۵ - در برنهاون", "👥 Friends\n• Nima - level 9 - in Fenwick Span\n• Maryam - level 5 - in Brennhaven"],
		"crime.hub": ["🕶 خلاف\nهر خلاف فقط در جای خودش شدنی است. خطر، پاداش و احتمال گیر افتادن را پیش از شروع ببینید.", "🕶 Crime\nEach crime can only be done at its own place. See the risk, the reward and the chance of arrest before you start."],
		"education.list": ["🎓 آموزش\n📖 دورهٔ مدیریت پایه - ۳ ساعت - شهریه ۲٬۰۰۰ نیل\n📖 رانندگی حرفه‌ای - ۲ ساعت - شهریه ۱٬۲۰۰ نیل", "🎓 Education\n📖 Basic management - 3h - fee 2,000 Nil\n📖 Professional driving - 2h - fee 1,200 Nil"],
		"company.list": ["🏢 شرکت‌ها\nهنوز شرکتی ندارید. با ثبت شرکت، کارمند استخدام کنید و کالا تولید کنید.", "🏢 Companies\nYou do not own a company yet. Register one to hire staff and make goods."],
		"market.list": ["🏪 بازار معاملات\n• نان - ۱۲ نیل\n• فولاد - ۴۸۰ نیل\n• گوشی هوشمند - ۹٬۵۰۰ نیل", "🏪 Market\n• Bread - 12 Nil\n• Steel - 480 Nil\n• Smartphone - 9,500 Nil"],
		"mission.board": ["📋 تابلوی مأموریت\n🎯 تحویل بسته به بازار - پاداش ۶۰۰ نیل\n🎯 گشت در پارک - پاداش ۳۰۰ نیل", "📋 Mission board\n🎯 Deliver a parcel to the bazaar - reward 600 Nil\n🎯 Patrol the park - reward 300 Nil"],
	}
	var t = titles.get(cmd)
	var text: String = (t[0] if st["lang"] == "fa" else t[1]) if t != null else L("ℹ️ این بخش را سرور زنده نشان می‌دهد. (حالت آزمایشی)", "ℹ️ The live server shows this screen. (mock mode)")
	return _resp(cmd, text, null, [_refresh(cmd), _back()])


# -- realtime (Centrifugo loopback) -------------------------------------------------------------------------
func rt_attach(t: Object) -> void:
	_rt = t
	_rt_subs.clear()
	_ping_t = 0.0


func rt_detach(t: Object) -> void:
	if _rt == t:
		_rt = null


func rt_receive(text: String) -> void:
	var replies := []
	for cmd in CentrifugoProtocol.decode(text):
		if cmd.is_empty():
			continue  # a pong
		var id := int(cmd.get("id", 0))
		if cmd.has("connect"):
			var tok := str(cmd["connect"].get("token", ""))
			if not _authorised(tok):
				replies.append({"id": id, "error": {"code": 109, "message": "token expired"}})
				continue
			var personal := "player:%d" % int(fx["player"]["id"])
			_rt_subs[personal] = true
			replies.append({"id": id, "connect": {"client": "mock-%d" % _rng.randi(), "version": "mock", "expires": true,
				"ttl": 600, "ping": int(PING_EVERY), "pong": true, "subs": {personal: {}}}})
		elif cmd.has("subscribe"):
			_rt_subs[str(cmd["subscribe"]["channel"])] = true
			replies.append({"id": id, "subscribe": {"expires": true, "ttl": 900}})
		elif cmd.has("unsubscribe"):
			_rt_subs.erase(str(cmd["unsubscribe"]["channel"]))
			replies.append({"id": id, "unsubscribe": {}})
		elif cmd.has("refresh"):
			replies.append({"id": id, "refresh": {"client": "mock", "version": "mock", "expires": true, "ttl": 600}})
		elif cmd.has("sub_refresh"):
			replies.append({"id": id, "sub_refresh": {"expires": true, "ttl": 900}})
	if _rt and not replies.is_empty():
		_rt.deliver(CentrifugoProtocol.encode(replies))


func push_notice(kind: String, text: String, view := {}) -> void:
	var ch := "player:%d" % int(fx["player"]["id"])
	var data := {"type": "notice", "kind": kind, "text": text}
	if not view.is_empty():
		data["view"] = view
	if _rt and _rt_subs.has(ch):
		_rt.deliver(JSON.stringify({"push": {"channel": ch, "pub": {"data": data}}}))


func push_announce(text: String) -> void:
	var ch := "city:" + str(st["city"])
	if _rt and _rt_subs.has(ch):
		_rt.deliver(JSON.stringify({"push": {"channel": ch, "pub": {"data": {"type": "announce", "text": text}}}}))
