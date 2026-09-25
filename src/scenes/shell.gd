extends Control
## The in-game shell: HUD on top, the current screen in the middle, the tab
## bar at the bottom, and overlays (toasts, input prompts, a busy strip).
## Screens are loaded lazily from res://src/screens/<name>.tscn.

var hud: Hud
var nav: BottomNav
var host: Control
var toasts: ToastLayer
var current: GameScreen
var current_key := ""
var _busy: ColorRect
var _safe: MarginContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = AppTheme.col("night")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_safe = MarginContainer.new()
	_safe.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_safe)
	var col := UI.vbox(0)
	_safe.add_child(col)
	hud = Hud.new()
	hud.bell_pressed.connect(func(): open_local("notifications"))
	hud.avatar_pressed.connect(func(): open_tab("me"))
	col.add_child(hud)
	host = Control.new()
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.clip_contents = true
	col.add_child(host)
	nav = BottomNav.new()
	nav.tab_pressed.connect(open_tab)
	col.add_child(nav)
	_busy = ColorRect.new()
	_busy.color = AppTheme.col("turquoise")
	_busy.custom_minimum_size = Vector2(0, 4)
	_busy.visible = false
	host.add_child(_busy)
	toasts = ToastLayer.new()
	add_child(toasts)

	layout_direction = I18n.direction()
	Game.response.connect(_on_response)
	Game.ask_input.connect(_ask)
	Realtime.notice.connect(_on_notice)
	Realtime.announce.connect(_on_announce)
	Api.busy_changed.connect(_on_busy)
	I18n.changed.connect(func(_l): layout_direction = I18n.direction())
	TelegramApp.insets_changed.connect(func(_i): _apply_insets())
	_apply_insets()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func(): if current: current.tick())
	add_child(timer)


func _apply_insets() -> void:
	var i := TelegramApp.canvas_insets(get_viewport())
	_safe.add_theme_constant_override("margin_top", int(i.get("top", 0)))
	_safe.add_theme_constant_override("margin_bottom", int(i.get("bottom", 0)))
	_safe.add_theme_constant_override("margin_left", int(i.get("left", 0)))
	_safe.add_theme_constant_override("margin_right", int(i.get("right", 0)))
	toasts.top_inset = 12 + float(i.get("top", 0))


func start() -> void:
	open_tab("city")


func open_tab(tab: String) -> void:
	nav.select(tab)
	var cmd: String = ViewRouter.TABS[tab]["command"]
	if cmd == "":
		open_local("more")
	else:
		Game.run(cmd)


## Screens that live only in the client.
func open_local(name: String) -> void:
	var key: String = {"bell": "notifications", "settings": "settings", "more": "more", "notifications": "notifications"}.get(name, name)
	if key == "notifications" or key == "settings":
		nav.select("more")
	_show(key, {"ok": true, "screen": key, "text": "", "view": {}, "actions": []}, {"command": "", "args": {}})


func toast(text: String, kind := "notice", icon_name := "") -> void:
	toasts.show_toast(text, kind, icon_name)


func _on_response(resp: Dictionary, req: Dictionary) -> void:
	var screen := str(resp.get("screen", ""))
	var key := ViewRouter.scene_for(screen, resp.get("view"))
	var cmd := str(req.get("command", ""))
	# A toast-style answer: show it, keep the screen.
	if screen == "notice" and current != null:
		toast(str(resp.get("notice", resp.get("text", ""))), "error" if resp.get("alert", false) else "ok")
		return
	# A refusal (screen "error", or ok=false) on a screen that is up: say it, keep the screen.
	if (screen == "error" or not resp.get("ok", false)) and current != null and key == "card":
		toast(str(resp.get("text", resp.get("error", {}).get("message", ""))), "error")
		return
	# A walk answered with text only (not the map): toast it and show the map.
	if cmd == "place.go" and key == "card":
		toast(str(resp.get("text", "")), "ok")
		Game.run("map.list", {}, false)
		return
	nav.select(ViewRouter.tab_for(key, cmd))
	if key == current_key and current and current.has_method("update_response"):
		current.update_response(resp, req)
		return
	_show(key, resp, req)


func _show(key: String, resp: Dictionary, req: Dictionary) -> void:
	var path := "res://src/screens/%s.tscn" % key
	if not ResourceLoader.exists(path):
		path = "res://src/screens/card.tscn"
		key = "card"
	var scn: PackedScene = load(path)
	var s: GameScreen = scn.instantiate()
	var old := current
	current = s
	current_key = key
	host.add_child(s)
	host.move_child(_busy, -1)
	s.setup(resp, req, self)
	if old:
		if Config.headless_capture:
			old.queue_free()
		else:
			var t := old.create_tween()
			t.tween_property(old, "modulate:a", 0.0, 0.12)
			t.tween_callback(old.queue_free)
	if not Config.headless_capture:
		s.modulate.a = 0.0
		s.position.y = 18
		var t2 := s.create_tween().set_parallel()
		t2.tween_property(s, "modulate:a", 1.0, 0.22)
		t2.tween_property(s, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_notice(data: Dictionary) -> void:
	toast(str(data.get("text", "")), "notice")
	if current and current.has_method("on_notice"):
		current.on_notice(data)
	var kind := str(data.get("kind", ""))
	if kind in ["shift_paid", "paid", "income"]:
		Fx.coins(self, Vector2(size.x * 0.3, 150))
	elif kind in ["travel_arrived", "travel.completed", "level_up", "level.up"]:
		Fx.sparkle(self, size / 2.0)
		if current_key in ["travel_status", "city", "cities"]:
			Game.run("map.list", {}, false)


func _on_announce(data: Dictionary) -> void:
	var text := str(data.get("text", ""))
	if data.get("texts") is Dictionary and data["texts"].has(I18n.lang):
		text = str(data["texts"][I18n.lang])
	toast(text, "announce")
	if current and current.has_method("on_announce"):
		current.on_announce(data)


func _on_busy(b: bool) -> void:
	_busy.visible = b
	if b and not Config.headless_capture:
		_busy.size = Vector2(0, 4)
		_busy.position = Vector2.ZERO
		var t := _busy.create_tween().set_loops(0)
		t.tween_property(_busy, "size:x", host.size.x, 0.6).set_trans(Tween.TRANS_QUAD)
		t.tween_property(_busy, "position:x", host.size.x, 0.4)
		t.tween_callback(func(): _busy.position.x = 0; _busy.size.x = 0)


## An action that needs a value (an amount...): a small prompt.
func _ask(action: Dictionary) -> void:
	var input: Dictionary = action["input"]
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var p := GlowPanel.new()
	p.accent = AppTheme.col("turquoise")
	p.padding = 28
	var box := UI.vbox(18)
	box.add_child(UI.rich(str(input.get("text", ""))))
	var le := LineEdit.new()
	le.placeholder_text = "0"
	le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	le.alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(le)
	var row := UI.hbox(12)
	var ok := UI.button(I18n.t("common.confirm"), "check")
	var cancel := UI.button(I18n.t("common.cancel"), "close", "GhostButton")
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ok)
	row.add_child(cancel)
	box.add_child(row)
	p.add_child(box)
	dim.add_child(p)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.custom_minimum_size = Vector2(minf(size.x - 60, 640), 0)
	await get_tree().process_frame
	p.position = (size - p.size) / 2.0
	Fx.pop(p, 0.85)
	le.grab_focus()
	var done := func(send: bool):
		var value := Fmt.to_latin(le.text).strip_edges().replace(",", "").replace("٬", "")
		dim.queue_free()
		if send and value != "":
			var args: Dictionary = (action.get("args", {}) as Dictionary).duplicate()
			args[str(input.get("field", "value"))] = value
			Game.run(str(action["command"]), args)
	ok.pressed.connect(func(): done.call(true))
	le.text_submitted.connect(func(_t): done.call(true))
	cancel.pressed.connect(func(): done.call(false))
