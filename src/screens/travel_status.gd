extends GameScreen
## A journey under way: the vehicle travels the route as the clock runs down.

const MODE_ICON := {"bus": "bus", "car": "car", "train": "train", "flight": "plane"}

var _route: RouteView
var _left_label: Label
var _end := 0.0
var _total := 1


func build() -> void:
	scroll_body(18)
	var v := view
	if v.is_empty():
		content.add_child(title_row(I18n.t("travel.title"), "travel"))
		content.add_child(UI.rich(str(resp.get("text", ""))))
		content.add_child(actions_grid(resp.get("actions", []), [], 1))
		return
	content.add_child(title_row(I18n.t("travel.on_way", {"city": str(v.get("to", ""))}), "travel"))
	maybe_notice()
	var p := GlowPanel.new()
	p.accent = AppTheme.col("saffron")
	p.padding = 26
	var box := UI.vbox(18)
	_route = RouteView.new()
	_route.from_name = str(v.get("from", ""))
	_route.to_name = str(v.get("to", ""))
	_route.vehicle_icon = MODE_ICON.get(str(v.get("mode_code", "")), "travel")
	_route.custom_minimum_size = Vector2(0, 170)
	box.add_child(_route)
	_left_label = UI.label("", "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_left_label)
	box.add_child(UI.label(I18n.t("travel.by", {"mode": str(v.get("mode_name", ""))}), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER))
	p.add_child(box)
	content.add_child(p)
	var rem := int(v.get("remaining_seconds", 0))
	_total = maxi(1, int(v.get("total_seconds", rem)))
	_end = Time.get_unix_time_from_system() + rem
	tick()
	content.add_child(actions_grid(resp.get("actions", []), [], 1))
	Fx.stagger_in(content)


func tick() -> void:
	if _route == null:
		return
	var left := maxi(0, int(_end - Time.get_unix_time_from_system()))
	_route.progress = 1.0 - float(left) / _total
	_route.queue_redraw()
	_left_label.text = I18n.t("travel.left", {"left": I18n.dur(left)}) if left > 0 else I18n.t("travel.arriving")
