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
	var m := UI.margin(content, 22, 20, 22, 28)
	_body_margin = m
	var s := UI.scroll(m)
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(s)
	return content


func title_row(title: String, icon_name: String, refresh := true) -> HBoxContainer:
	var row := UI.hbox(14)
	# the badge for the screen's command domain; local screens use their key
	var cmd := str(req.get("command", ""))
	row.add_child(IconBadge.make(AssetLib.action_glyph(cmd if cmd != "" else icon_name), 58))
	var t := UI.label(title, "TitleLabel")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	row.add_child(t)
	if Game.can_go_back() and not (req.get("command", "") in ["map.list", "player.profile.get", "bank.show", "job.status"]):
		row.add_child(round_button("back" if not I18n.is_rtl() else "forward", func(): Game.back()))
	if refresh:
		row.add_child(round_button("refresh", func(): Game.refresh_current()))
	return row


func round_button(icon_name: String, fn: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = "GhostButton"
	b.icon = AppTheme.icon(icon_name)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(72, 72)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_constant_override("icon_max_width", 34)
	var sb: StyleBoxFlat = AppTheme.button_box(AppTheme.col("panel_hi"), false, 36)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	b.add_theme_stylebox_override("normal", sb)
	b.pressed.connect(fn)
	Fx.press_feedback(b)
	return b


## A notice from the response (what just happened), as a coloured banner.
func notice_banner(text: String, kind := "ok") -> Control:
	var p := GlowPanel.new()
	var c := AppTheme.col("leaf" if kind == "ok" else ("pomegranate" if kind == "error" else "saffron"))
	p.top_color = c.darkened(0.55)
	p.bottom_color = c.darkened(0.65)
	p.border_color = Color(c, 0.6)
	p.highlight = Color(c, 0.3)
	p.radius = 10
	p.padding = 16
	p.shadow = 8
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


## Pin a primary action at the bottom of the screen, above the tab bar.
func pin_cta(a: Dictionary) -> void:
	if _cta_bar:
		_cta_bar.queue_free()
	var bar := Control.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -124
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# a fade so the content scrolls under it
	var fade := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	var gr := Gradient.new()
	gr.set_color(0, Color(AppTheme.col("night"), 0.0))
	gr.set_color(1, Color(AppTheme.col("night"), 0.96))
	gt.gradient = gr
	fade.texture = gt
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(fade)
	var b := ActionKit.cta(a, self)
	b.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	b.offset_left = 22
	b.offset_right = -22
	b.offset_bottom = -18
	b.offset_top = -106
	bar.add_child(b)
	add_child(bar)
	_cta_bar = bar
	if _body_margin:
		_body_margin.add_theme_constant_override("margin_bottom", 140)
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
	b.theme_type_variation = {"buy": "GoldButton", "danger": "DangerButton", "ghost": "GhostButton"}.get(style, "Button")
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(112, 56)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(fn)
	Fx.press_feedback(b)
	return b


## A segmented control: pills in a rounded track; calls fn(index) on change.
func segmented(labels: Array, active: int, fn: Callable) -> Control:
	var track := PanelContainer.new()
	track.theme_type_variation = "InsetPanel"
	var row := UI.hbox(6)
	track.add_child(row)
	for i in labels.size():
		var b := Button.new()
		b.theme_type_variation = "Button" if i == active else "NavButton"
		b.text = str(labels[i])
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 60
		b.add_theme_font_size_override("font_size", 22)
		if i != active:
			b.add_theme_color_override("font_color", AppTheme.col("text_dim"))
		b.pressed.connect(func(): fn.call(i))
		row.add_child(b)
	return track


## A card: the navy glow panel with padding; returns its content column.
func panel_card(pad := 20, accent := Color(0, 0, 0, 0)) -> VBoxContainer:
	var p := GlowPanel.new()
	p.radius = 12
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
		var h := UI.hbox(10)
		if icon_name != "":
			h.add_child(UI.icon(icon_name, 38))
		h.add_child(UI.label(heading, "HeadLabel"))
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
