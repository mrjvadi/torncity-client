extends GameScreen
## How to get there: one card per transport mode with fare, time and energy.

const MODE_ICON := {"bus": "bus", "car": "car", "train": "train", "flight": "plane"}


func build() -> void:
	scroll_body(16)
	var v := view
	content.add_child(title_row(I18n.t("travel.to", {"city": str(v.get("to", ""))}), "travel", false))
	maybe_notice()
	if v.get("requoted", false):
		content.add_child(notice_banner(I18n.t("travel.requoted"), "warn"))
	var route := GlowPanel.new()
	route.custom_minimum_size = Vector2(0, 150)
	var rv := RouteView.new()
	rv.from_name = str(v.get("from", ""))
	rv.to_name = str(v.get("to", ""))
	rv.custom_minimum_size = Vector2(0, 110)
	route.add_child(rv)
	content.add_child(route)
	content.add_child(UI.hbox(10, [UI.icon("cash", 34), UI.label(I18n.t("travel.cash", {"cash": I18n.money(int(v.get("cash", 0)))}), "SmallLabel")]))
	var opts: Array = v.get("options", []) if v.get("options") is Array else []
	for o in opts:
		content.add_child(_option(o, int(v.get("cash", 0))))
	Fx.stagger_in(content)


func _option(o: Dictionary, cash: int) -> Control:
	var mode := str(o.get("mode_code", ""))
	var fare := int(o.get("fare", 0))
	var b := Button.new()
	b.theme_type_variation = "ActionButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 150)
	b.disabled = fare > cash
	var row := UI.hbox(18)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 22
	row.offset_right = -22
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UI.icon(MODE_ICON.get(mode, "travel"), 84))
	var col := UI.vbox(4)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := str(o.get("mode_name", mode))
	if o.get("vehicle") is Dictionary:
		name += " - " + str(o["vehicle"].get("name", ""))
	col.add_child(UI.label(name, "HeadLabel"))
	var facts := UI.hbox(14, [UI.icon("hourglass", 28), UI.label(I18n.dur(int(o.get("wait_seconds", 0))), "DimLabel"),
		UI.icon("energy", 28), UI.label(I18n.num(int(o.get("energy", 0))), "DimLabel")])
	col.add_child(facts)
	row.add_child(col)
	var price := UI.vbox(2)
	price.alignment = BoxContainer.ALIGNMENT_CENTER
	price.add_child(UI.label(I18n.money(fare) if fare > 0 else I18n.t("travel.free"), "MoneyLabel", HORIZONTAL_ALIGNMENT_CENTER))
	if o.get("busy", false):
		price.add_child(UI.chip("warning", I18n.t("travel.busy"), AppTheme.col("brick", 0.5)))
	row.add_child(price)
	b.add_child(row)
	Fx.press_feedback(b)
	b.pressed.connect(func(): Game.run("travel.start", {"city": str(view.get("to_code", "")), "mode": mode, "max": str(fare)}))
	return b
