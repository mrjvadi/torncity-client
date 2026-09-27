extends GameScreen
## Travel to another city: destinations as cards on a stylised route line.


func build() -> void:
	scroll_body(16)
	var v := view
	content.add_child(title_row(I18n.t("travel.title"), "travel"))
	maybe_notice()
	var origin := I18n.name_of("city", str(v.get("origin_code", "")), str(v.get("origin", "")))
	var here := GlowPanel.new()
	here.accent = AppTheme.col("primary")
	here.add_child(UI.hbox(12, [UI.icon("pin", 46), UI.label(I18n.t("travel.from", {"city": origin}), "HeadLabel")]))
	content.add_child(here)
	if v.get("travelling", false):
		content.add_child(notice_banner(I18n.t("travel.already", {"city": str(v.get("travelling_to", ""))}), "warn"))
		content.add_child(UI.button(I18n.t("travel.status"), "hourglass", "", func(): Game.run("travel.status")))
		return
	var dests: Array = v.get("destinations", []) if v.get("destinations") is Array else []
	if dests.is_empty():
		content.add_child(notice_banner(I18n.t("travel.none"), "warn"))
	for d in dests:
		content.add_child(_dest(d))
	var rest := actions_grid(resp.get("actions", []), ["travel.options"])
	if rest.get_child_count() > 0:
		content.add_child(rest)
	Fx.stagger_in(content)


func _dest(d: Dictionary) -> Control:
	var b := Button.new()
	b.theme_type_variation = "ActionButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 124)
	var row := UI.hbox(16)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 22
	row.offset_right = -22
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UI.icon("city", 64))
	var col := UI.vbox(2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(I18n.name_of("city", str(d.get("code", "")), str(d.get("name", ""))), "HeadLabel"))
	col.add_child(UI.label(I18n.t("travel.distance", {"km": int(d.get("distance_km", 0))}), "DimLabel"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var arrow := UI.icon("back" if I18n.is_rtl() else "forward", 36)
	row.add_child(arrow)
	b.add_child(row)
	Fx.press_feedback(b)
	b.pressed.connect(func(): Game.run("travel.options", {"city": str(d.get("code", ""))}))
	return b
