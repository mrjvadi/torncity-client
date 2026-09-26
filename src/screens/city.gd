extends GameScreen
## «City»: the map of the player's own city. Tap a building to see it; walk
## there with one button. Realtime arrival notices land the walker.

var map: CityWorldView
var _status_label: Label
var _top: Control
var _sheet: GlassPanel
var _sheet_box: VBoxContainer
var _zoom: VBoxContainer
var _walk_end := 0.0
var _walk_to := ""


func build() -> void:
	map = CityWorldView.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.place_tapped.connect(_show_place)
	add_child(map)

	# under the HUD: the city and what the player is doing, on glass
	_top = UI.hbox(10)
	_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_top.offset_left = 14
	_top.offset_right = -14
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	var chip := GlassPanel.new()
	chip.radius = 22
	chip.pad = Vector4(14, 10, 18, 10)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var brow := UI.hbox(12)
	brow.add_child(IconBadge.make(AssetLib.glyph("city:" + str(view.get("city_code", ""))), 52))
	var bcol := UI.vbox(0)
	bcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cname := UI.label(Content.name_of("city", str(view.get("city_code", "")), str(view.get("city", ""))), "HeadLabel")
	cname.add_theme_font_size_override("font_size", 26)
	bcol.add_child(cname)
	_status_label = UI.label("", "DimLabel")
	_status_label.add_theme_font_size_override("font_size", 19)
	_status_label.add_theme_color_override("font_color", Color("#C9D5E8"))
	_status_label.clip_text = true
	bcol.add_child(_status_label)
	brow.add_child(bcol)
	chip.add_child(brow)
	_top.add_child(chip)
	# the server's "other cities" action, if it offers one
	for a in resp.get("actions", []):
		if a is Dictionary and str(a.get("command", "")) == "map.cities":
			var travel := RoundIconButton.make(AssetLib.icon("action:travel"), func(): Game.run_action(a), 72)
			_top.add_child(travel)
			break

	# zoom controls on the reading-start edge
	_zoom = UI.vbox(10)
	_zoom.set_anchors_preset(Control.PRESET_CENTER_LEFT if not I18n.is_rtl() else Control.PRESET_CENTER_RIGHT)
	_zoom.grow_vertical = Control.GROW_DIRECTION_BOTH
	_zoom.add_child(RoundIconButton.make(AppTheme.icon("ln_plus"), func(): map.world.cam.look_at_point(map.world.cam.target, map.world.cam.zoom * 0.7), 64))
	_zoom.add_child(RoundIconButton.make(AppTheme.icon("ln_minus"), func(): map.world.cam.look_at_point(map.world.cam.target, map.world.cam.zoom / 0.7), 64))
	_zoom.add_child(RoundIconButton.make(AppTheme.icon("ln_locate"), func(): map.focus(map.here), 64))
	add_child(_zoom)

	# the sheet for the selected place, above the tab bar
	_sheet = GlassPanel.new()
	_sheet.radius = 28
	_sheet.pad = Vector4(20, 18, 20, 18)
	_sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sheet.offset_left = 12
	_sheet.offset_right = -12
	_sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_sheet_box = UI.vbox(12)
	_sheet.add_child(_sheet_box)
	add_child(_sheet)
	_place_chrome()
	if shell and shell.has_signal("insets_changed"):
		shell.insets_changed.connect(_place_chrome)
	_apply(resp)


func _place_chrome() -> void:
	var ins := insets()
	_top.offset_top = ins.top + 4
	_sheet.offset_bottom = -ins.bottom - 4
	_zoom.offset_left = 14 if not I18n.is_rtl() else -78
	_zoom.offset_right = _zoom.offset_left + 64


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
	var name := Content.name_of("place", code, str(p["place"].get("name", code)))
	var head := UI.hbox(14)
	head.add_child(IconBadge.make(AssetLib.glyph_for("place", code), 104))
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
	for sv in p.get("services", []):
		tags.add_child(_tag("service", str(sv)))
	for d in p.get("departures", []):
		tags.add_child(_tag("mode", str(d)))
	for sh in p.get("shops", []):
		if sh is Dictionary:
			tags.add_child(UI.chip("cart", str(sh.get("name", ""))))
	if tags.get_child_count() > 0:
		col.add_child(tags)
	head.add_child(col)
	_sheet_box.add_child(head)

	# the server's own buttons for this place (walk there, its shops...)
	var buttons := UI.hbox(12)
	if _walk_to == code:
		var l := UI.button(I18n.t("map.on_the_way"), "walk", "GhostButton")
		l.disabled = true
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(l)
	else:
		for a in resp.get("actions", []):
			if a is Dictionary and _action_place(a) == code:
				var b := UI.action_button(a, "Button" if str(a.get("command", "")) == "place.go" else "GoldButton")
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				b.disabled = _walk_to != ""
				buttons.add_child(b)
	if buttons.get_child_count() > 0:
		_sheet_box.add_child(buttons)
	if not Config.headless_capture:
		_sheet.modulate.a = 0.0
		_sheet.create_tween().tween_property(_sheet, "modulate:a", 1.0, 0.2)


## A chip for a service or departure mode: name from the content catalogue,
## badge icon from the asset library (unknown codes get the category's look).
func _tag(table: String, code: String) -> Control:
	var g := AssetLib.glyph("%s:%s" % [table, code])
	var row := UI.hbox(6, [IconBadge.make(g, 34, false), UI.label(Content.name_of(table, code), "SmallLabel")])
	return UI.panel(row, "ChipPanel")


static func _action_place(a: Dictionary) -> String:
	var args = a.get("args", {})
	return str(args.get("place", "")) if args is Dictionary else ""


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
