class_name GameScreen
extends Control
## Base of every screen in the shell's content area. A screen is built from one
## server response: resp = {ok, screen, text, view, actions, notice?, error?}.

var resp := {}
var req := {}
var view := {}
var content: VBoxContainer
var shell: Node
var _body_margin: MarginContainer
var _cta_bar: Control
var _scroll: ScrollContainer
var _pull: PullIndicator
var _pull_start := Vector2.INF
var _pull_amt := 0.0
const PULL_AT := 110.0


func setup(r: Dictionary, q: Dictionary, sh: Node) -> void:
	resp = r
	req = q
	shell = sh
	view = r.get("view") if r.get("view") is Dictionary else {}
	set_anchors_preset(Control.PRESET_FULL_RECT)
	layout_direction = I18n.direction()
	build()


## Override: lay the screen out.
func build() -> void:
	pass


## Override: live values ticking (countdowns). Called once a second by the shell.
func tick() -> void:
	pass


## A scrolling column with the standard margins; returns the column.
func scroll_body(sep := 18) -> VBoxContainer:
	content = UI.vbox(sep)
	var m := UI.margin(content, AppTheme.GUTTER, 20, AppTheme.GUTTER, 28)
	_body_margin = m
	# keep a readable measure on wide screens (~1040 px), and clear the
	# floating HUD and tab bar (content scrolls under their glass)
	var fit := func():
		var side := maxi(AppTheme.GUTTER, int((size.x - 1040.0) / 2.0))
		m.add_theme_constant_override("margin_left", side)
		m.add_theme_constant_override("margin_right", side)
		var ins := insets()
		m.add_theme_constant_override("margin_top", int(ins.top) + 16)
		m.add_theme_constant_override("margin_bottom", int(ins.bottom) + (140 if _cta_bar else 28))
	resized.connect(fit)
	if shell and shell.has_signal("insets_changed"):
		shell.insets_changed.connect(fit)
	fit.call_deferred()
	var s := UI.scroll(m)
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(s)
	_scroll = s
	return content


## The screen's app bar: back (when there is somewhere to go back to) or the
## domain's badge at the reading start, the title, and refresh at the end.
func title_row(title: String, icon_name: String, refresh := true) -> HBoxContainer:
	var row := UI.hbox(14)
	var cmd := str(req.get("command", ""))
	if Game.can_go_back() and not (cmd in ["map.list", "player.profile.get", "bank.show", "job.status"]):
		row.add_child(round_button("back" if not I18n.is_rtl() else "forward", func(): Game.back()))
	else:
		# the badge for the screen's command domain; local screens use their key
		var badge := IconBadge.make(AssetLib.action_glyph(cmd if cmd != "" else icon_name), 60)
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(badge)
	var t := UI.label(title, "TitleLabel")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	row.add_child(t)
	if refresh:
		row.add_child(round_button("refresh", func(): Game.refresh_current()))
	return row


func round_button(icon_name: String, fn: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = "GhostButton"
	b.icon = AppTheme.icon(icon_name)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(60, 60)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_constant_override("icon_max_width", 28)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := AppTheme.button_box(AppTheme.col("surface_3" if st != "normal" else "surface_2"), st.ends_with("pressed"), 30, AppTheme.col("stroke_hi"))
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 16
		sb.content_margin_bottom = 16
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(fn)
	Fx.press_feedback(b)
	return b


## A notice from the response (what just happened), as a coloured banner.
func notice_banner(text: String, kind := "ok") -> Control:
	var p := GlowPanel.new()
	var c := AppTheme.col("success" if kind == "ok" else ("danger" if kind == "error" else "gold"))
	p.tint_with(c, 0.2)
	p.border_color = Color(c, 0.5)
	p.radius = AppTheme.R_CONTROL
	p.padding = 16
	p.shadow = 0
	var ic := TextIcons.lead_icon(text)
	var row := UI.hbox(12, [UI.icon(ic if ic != "" else ("check" if kind == "ok" else "warning"), 40)])
	row.add_child(UI.rich(TextIcons.strip(text) if ic != "" else text, 24))
	p.add_child(row)
	return p


## The server's actions, placed by role (ActionKit): the primary one pinned
## at the bottom, back/refresh in the header, the rest as a grid of icon
## tiles. `skip` drops commands the screen already draws natively.
func actions_grid(actions: Array, skip := [], _cols := 0) -> Control:
	var s := ActionKit.sort(actions, skip)
	if not s.primary.is_empty():
		pin_cta(s.primary[0])
		s.tiles = s.primary.slice(1) + s.tiles
	return ActionKit.grid(s.tiles, self, tile_columns())


func tile_columns() -> int:
	var w := size.x if size.x > 0 else get_viewport_rect().size.x
	return clampi(int(w / 175.0), 3, 6)


# -- pull to refresh ---------------------------------------------------------------------------------------
func _input(e: InputEvent) -> void:
	if _scroll == null or not is_visible_in_tree() or not can_refresh():
		return
	var pressed_ev: bool = (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT) or e is InputEventScreenTouch
	if pressed_ev:
		if e.pressed:
			var gp: Vector2 = e.position
			if get_global_rect().has_point(gp) and gp.y > global_position.y + insets().top and _scroll.scroll_vertical <= 0:
				_pull_start = gp
				_pull_amt = 0.0
		else:
			if _pull_amt >= PULL_AT:
				_pull.spinning = true
				TelegramApp.haptic("medium")
				Game.refresh_current()
			elif _pull:
				_hide_pull()
			_pull_start = Vector2.INF
	elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _pull_start != Vector2.INF:
		var dy: float = e.position.y - _pull_start.y
		if _scroll.scroll_vertical > 0 or dy < 0:
			_pull_amt = 0.0
			if _pull:
				_hide_pull()
			return
		_pull_amt = dy * 0.55
		show_pull(_pull_amt / PULL_AT)


## Show the pull bubble at `f` (0..1 of the threshold); also for screenshots.
func show_pull(f: float, spinning := false) -> void:
	if _pull == null:
		_pull = PullIndicator.new()
		add_child(_pull)
	_pull.pull = f
	_pull.spinning = spinning
	_pull.position = Vector2((size.x - 64) / 2.0, insets().top - 40 + minf(f, 1.2) * 90.0)
	_pull.modulate.a = clampf(f * 1.5, 0, 1)
	_pull.queue_redraw()


func _hide_pull() -> void:
	if _pull:
		_pull.queue_free()
		_pull = null


## Screens built from a server command can be refreshed by pulling.
func can_refresh() -> bool:
	return str(req.get("command", "")) != ""


func insets() -> Dictionary:
	return shell.insets() if shell and shell.has_method("insets") else {"top": 0.0, "bottom": 0.0}


## Pin a primary action at the bottom of the screen, above the tab bar.
func pin_cta(a: Dictionary) -> void:
	if _cta_bar:
		_cta_bar.queue_free()
	var bar := Control.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	var ib: float = insets().bottom
	bar.offset_bottom = -ib + 10
	bar.offset_top = -ib - 118
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := ActionKit.cta(a, self)
	b.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	# as wide as the content column (the readable measure on wide screens)
	var fit := func():
		var side := maxi(AppTheme.GUTTER, int((size.x - 1040.0) / 2.0))
		b.offset_left = side
		b.offset_right = -side
	fit.call()
	resized.connect(fit)
	b.offset_bottom = -18
	b.offset_top = -106
	bar.add_child(b)
	add_child(bar)
	_cta_bar = bar
	if _body_margin:
		_body_margin.add_theme_constant_override("margin_bottom", int(ib) + 140)
	if not Config.headless_capture:
		b.modulate.a = 0.0
		b.create_tween().tween_property(b, "modulate:a", 1.0, 0.2)


## The server's per-row action whose args[key] == value (group "rows").
func row_action(key: String, value) -> Dictionary:
	for a in resp.get("actions", []):
		if a is Dictionary and a.get("args") is Dictionary and str(a["args"].get(key, "")) == str(value):
			return a
	return {}


## The actions that are not per-row (for the grid and the CTA).
func page_actions() -> Array:
	return resp.get("actions", []).filter(func(a): return a is Dictionary and str(a.get("group", "")) != "rows")


## A small pill button for a row (Buy, Sell, Enrol...). style: buy | danger | primary | ghost.
func pill(text: String, style: String, fn: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = {"buy": "TonalGold", "danger": "TonalDanger", "ghost": "GhostButton"}.get(style, "TonalPrimary")
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(112, 56)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(fn)
	Fx.press_feedback(b)
	return b


## A segmented control: pills in a rounded track; calls fn(index) on change.
## The pressed pill restyles itself immediately, independent of whatever
## `fn` does with the rest of the screen (it may only swap a table's rows).
func segmented(labels: Array, active: int, fn: Callable) -> Control:
	var track := PanelContainer.new()
	track.theme_type_variation = "InsetPanel"
	var row := UI.hbox(6)
	track.add_child(row)
	var buttons: Array[Button] = []
	var restyle := func(sel: int):
		for i in buttons.size():
			var bb := buttons[i]
			bb.theme_type_variation = "SegmentButton" if i == sel else "NavButton"
			if i == sel:
				bb.remove_theme_color_override("font_color")
			else:
				bb.add_theme_color_override("font_color", AppTheme.col("text_dim"))
	for i in labels.size():
		var b := Button.new()
		b.text = str(labels[i])
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 60
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(func():
			restyle.call(i)
			fn.call(i))
		row.add_child(b)
		buttons.append(b)
	restyle.call(active)
	track.set_meta("select", restyle)   # so a caller can switch tabs programmatically
	return track


## A card: the navy glow panel with padding; returns its content column.
func panel_card(pad := 20, accent := Color(0, 0, 0, 0)) -> VBoxContainer:
	var p := GlowPanel.new()
	p.padding = pad
	p.accent = accent
	var box := UI.vbox(12)
	p.add_child(box)
	content.add_child(p)
	return box


## A glowing card with a heading.
func card(heading := "", icon_name := "") -> VBoxContainer:
	var p := GlowPanel.new()
	var box := UI.vbox(14)
	if heading != "":
		var h := UI.hbox(12)
		if icon_name != "":
			h.add_child(UI.icon(icon_name, 34))
		var hl := UI.label(heading, "HeadLabel")
		hl.add_theme_font_size_override("font_size", 25)
		h.add_child(hl)
		box.add_child(h)
	p.add_child(box)
	content.add_child(p)
	return box


func maybe_notice() -> void:
	var n := str(resp.get("notice", ""))
	if n == "" and view.has("notice"):
		n = str(view.get("notice", ""))
	if n != "":
		content.add_child(notice_banner(n, "error" if n.begins_with("⚠") else "ok"))
	if not resp.get("ok", true):
		content.add_child(notice_banner(str(resp.get("text", "")), "error"))


func secs(key: String, v := view) -> int:
	return int(v.get(key, 0)) if v.get(key) != null else 0
