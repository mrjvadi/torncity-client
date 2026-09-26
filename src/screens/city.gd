extends GameScreen
## «City»: the map of the player's own city. Tap a building to see it; walk
## there with one button. Realtime arrival notices land the walker.

const SERVICE_ICON := {"bank": "bank", "police": "police", "city_hall": "office", "market": "market",
	"auction_house": "auction", "university": "study", "training_center": "book"}
const SERVICE_CMD := {"bank": "bank.show", "police": "crime.jail", "city_hall": "gov.city", "market": "market.list",
	"auction_house": "auction.list", "university": "education.list", "training_center": "education.list"}
const MODE_ICON := {"bus": "bus", "car": "car", "train": "train", "flight": "plane"}

var map: CityMapView
var _status: GlowPanel
var _status_label: Label
var _sheet: GlowPanel
var _sheet_box: VBoxContainer
var _walk_end := 0.0
var _walk_to := ""


func build() -> void:
	map = CityMapView.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.place_tapped.connect(_show_place)
	add_child(map)

	# top: city banner + status
	var top := UI.vbox(10)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_right = -18
	top.offset_top = 14
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	var bar := UI.hbox(10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var banner := GlowPanel.new()
	banner.padding = 14
	banner.radius = 10
	banner.top_color = Color(0.13, 0.17, 0.3, 0.92)
	banner.bottom_color = Color(0.1, 0.13, 0.24, 0.92)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var brow := UI.hbox(10, [UI.icon("city", 44)])
	var bcol := UI.vbox(0)
	bcol.add_child(UI.label(I18n.name_of("city", str(view.get("city_code", "")), str(view.get("city", ""))), "HeadLabel"))
	_status_label = UI.label("", "DimLabel")
	_status_label.clip_text = true
	bcol.add_child(_status_label)
	bcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brow.add_child(bcol)
	banner.add_child(brow)
	bar.add_child(banner)
	var travel := round_button("travel", func(): Game.run("map.cities"))
	travel.custom_minimum_size = Vector2(84, 84)
	bar.add_child(travel)
	top.add_child(bar)

	# bottom sheet for the selected place
	_sheet = GlowPanel.new()
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.offset_left = 14
	_sheet.offset_right = -14
	_sheet.offset_bottom = -14
	_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_sheet.accent = AppTheme.col("blue", 0.9)
	_sheet.top_color = Color(0.17, 0.21, 0.37, 0.96)
	_sheet.bottom_color = Color(0.12, 0.15, 0.28, 0.96)
	_sheet_box = UI.vbox(12)
	_sheet.add_child(_sheet_box)
	add_child(_sheet)

	_apply(resp)


## A new city_map response while the map is up: update in place (the walker keeps walking).
func update_response(r: Dictionary, q: Dictionary) -> void:
	resp = r
	req = q
	view = r.get("view") if r.get("view") is Dictionary else {}
	_apply(r)


func _apply(r: Dictionary) -> void:
	if view.get("travelling", false):
		shell.toast(I18n.t("travel.already", {"city": str(view.get("travelling_to", ""))}), "notice")
	await get_tree().process_frame
	map.set_view(view)
	var w = view.get("walking")
	if w is Dictionary and w.get("to") is Dictionary:
		_walk_to = str(w["to"].get("code", ""))
		_walk_end = Time.get_unix_time_from_system() + float(w.get("remaining_seconds", 0))
	else:
		_walk_to = ""
		_walk_end = 0.0
	var n := str(r.get("notice", ""))
	if n != "":
		shell.toast(n, "ok")
	if not r.get("ok", true):
		shell.toast(str(r.get("text", "")), "error")
	_show_place(_walk_to if _walk_to != "" else map.selected)
	tick()


func _place_row(code: String) -> Dictionary:
	for p in view.get("places", []):
		if str(p.get("place", {}).get("code", "")) == code:
			return p
	return {}


func _show_place(code: String) -> void:
	UI.clear(_sheet_box)
	var p := _place_row(code)
	if p.is_empty():
		_sheet.visible = false
		return
	_sheet.visible = true
	var name := I18n.name_of("place", code, str(p["place"].get("name", code)))
	var head := UI.hbox(14)
	var thumb := UI.tex(AppTheme.tex("place/" + code), Vector2(118, 118))
	head.add_child(thumb)
	var col := UI.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(name, "TitleLabel"))
	var facts := UI.hbox(12)
	if p.get("here", false):
		facts.add_child(UI.icon("pin", 30))
		facts.add_child(UI.label(I18n.t("map.here"), "SmallLabel"))
		var others := int(view.get("others", 0))
		if others > 0:
			facts.add_child(UI.icon("friends", 30))
			facts.add_child(UI.label(I18n.num(others), "SmallLabel"))
	else:
		facts.add_child(UI.icon("walk", 30))
		facts.add_child(UI.label(I18n.dur(int(p.get("walk_seconds", 0))), "SmallLabel"))
		var e := int(p.get("energy", 0))
		if e > 0:
			facts.add_child(UI.icon("energy", 30))
			facts.add_child(UI.label(I18n.num(e), "SmallLabel"))
	col.add_child(facts)
	# what is here: services, departures, shops
	var tags := HFlowContainer.new()
	tags.add_theme_constant_override("h_separation", 8)
	tags.add_theme_constant_override("v_separation", 8)
	for s in p.get("services", []):
		tags.add_child(UI.chip(SERVICE_ICON.get(s, "info"), I18n.t("service." + str(s))))
	for d in p.get("departures", []):
		tags.add_child(UI.chip(MODE_ICON.get(d, "travel"), I18n.name_of("mode", str(d), str(d).capitalize())))
	for sh in p.get("shops", []):
		if sh is Dictionary:
			tags.add_child(UI.chip("cart", str(sh.get("name", ""))))
	if tags.get_child_count() > 0:
		col.add_child(tags)
	head.add_child(col)
	_sheet_box.add_child(head)

	var buttons := UI.hbox(12)
	if _walk_to == code:
		var l := UI.button(I18n.t("map.on_the_way"), "walk", "GhostButton")
		l.disabled = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(l)
	elif not p.get("here", false):
		var go := UI.button(I18n.t("map.walk_here"), "walk", "", func(): _go(code))
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.disabled = _walk_to != ""
		buttons.add_child(go)
	for s in p.get("services", []):
		if SERVICE_CMD.has(s) and p.get("here", false):
			var b := UI.button(I18n.t("service." + str(s)), SERVICE_ICON.get(s, "info"), "GoldButton", func(): Game.run(SERVICE_CMD[s]))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			buttons.add_child(b)
	if not (p.get("departures", []) as Array).is_empty() and p.get("here", false):
		var t := UI.button(I18n.t("map.depart"), "travel", "GoldButton", func(): Game.run("map.cities"))
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(t)
	if buttons.get_child_count() > 0:
		_sheet_box.add_child(buttons)
	if not Config.headless_capture:
		_sheet.modulate.a = 0.0
		_sheet.create_tween().tween_property(_sheet, "modulate:a", 1.0, 0.2)


func _go(code: String) -> void:
	TelegramApp.haptic("medium")
	await Game.run("place.go", {"place": code})
	# A live server may answer the walk with a short text card rather than the
	# map; the shell then shows it as a toast and we reload the map.


func tick() -> void:
	var here := map.here
	if _walk_to != "":
		var left := maxi(0, int(_walk_end - Time.get_unix_time_from_system()))
		_status_label.text = I18n.t("map.walking", {"place": I18n.name_of("place", _walk_to), "left": I18n.dur(left)})
		if left <= 0 and _walk_end > 0:
			_walk_end = 0
			# the arrival notice usually beats us to it; if not, ask
			get_tree().create_timer(1.5).timeout.connect(func():
				if _walk_to != "" and is_inside_tree():
					Game.run("map.list", {}, false))
	else:
		_status_label.text = I18n.t("map.at", {"place": I18n.name_of("place", here)}) if here != "" else ""


## Realtime notices while the map is open.
func on_notice(data: Dictionary) -> void:
	var v = data.get("view")
	if str(data.get("kind", "")) == "arrived" or (v is Dictionary and v.get("place") is Dictionary and _walk_to != ""):
		var code := _walk_to
		if v is Dictionary and v.get("place") is Dictionary:
			code = str(v["place"].get("code", code))
		_walk_to = ""
		_walk_end = 0
		map.arrive(code)
		await get_tree().create_timer(0.8).timeout
		if is_inside_tree():
			Game.run("map.list", {}, false)


func on_announce(_data: Dictionary) -> void:
	if map.slots.has("city_hall"):
		map.pulse_place("city_hall")
