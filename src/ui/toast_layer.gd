class_name ToastLayer
extends Control
## Realtime notices and quick results slide down from the top as toasts.

const LIFE := 4.5
const MAX := 3

var top_inset := 12.0
var _stack: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## kind picks the accent: "notice", "announce", "error", "ok".
func show_toast(text: String, kind := "notice", icon_name := "") -> void:
	var accent := {"announce": "saffron", "error": "pomegranate", "ok": "leaf"}.get(kind, "turquoise")
	var p := GlowPanel.new()
	p.top_color = Color("#1F3150")
	p.bottom_color = Color("#16243A")
	p.accent = AppTheme.col(accent)
	p.radius = 10
	p.padding = 18
	p.shadow = 20
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var ic := icon_name if icon_name != "" else TextIcons.lead_icon(text)
	if ic == "":
		ic = {"announce": "bell", "error": "warning", "ok": "check"}.get(kind, "info")
	var row := UI.hbox(14, [UI.icon(ic, 48)])
	var body := UI.rich(TextIcons.strip(text) if TextIcons.lead_icon(text) != "" else text, 24)
	row.add_child(body)
	p.add_child(row)
	var w := minf(get_viewport_rect().size.x - 32, 680)
	p.custom_minimum_size.x = w
	body.custom_minimum_size.x = w - 48 - 14 - p.padding * 2
	add_child(p)
	p.position = Vector2((get_viewport_rect().size.x - w) / 2.0, -400)
	p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _dismiss(p))
	_stack.push_front(p)
	while _stack.size() > MAX:
		_dismiss(_stack.back())
	await get_tree().process_frame
	_layout()
	if not Config.headless_capture:
		get_tree().create_timer(LIFE).timeout.connect(func(): _dismiss(p))
	TelegramApp.haptic("light")


func clear() -> void:
	for p in _stack:
		if is_instance_valid(p):
			p.queue_free()
	_stack.clear()


func _layout() -> void:
	var y := top_inset
	for p in _stack:
		if not is_instance_valid(p):
			continue
		var target := Vector2((get_viewport_rect().size.x - p.size.x) / 2.0, y)
		if Config.headless_capture:
			p.position = target
		else:
			p.create_tween().tween_property(p, "position", target, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		y += p.size.y + 12


func _dismiss(p: Control) -> void:
	if not is_instance_valid(p) or not _stack.has(p):
		return
	_stack.erase(p)
	var t := p.create_tween()
	t.tween_property(p, "modulate:a", 0.0, 0.25)
	t.parallel().tween_property(p, "position:y", p.position.y - 40, 0.25)
	t.tween_callback(p.queue_free)
	_layout()
