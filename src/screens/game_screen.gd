class_name GameScreen
extends Control
## Base of every screen in the shell's content area. A screen is built from one
## server response: resp = {ok, screen, text, view, actions, notice?, error?}.

var resp := {}
var req := {}
var view := {}
var content: VBoxContainer
var shell: Node


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


## The server's action buttons, two per row. `skip` drops commands the screen draws natively.
func actions_grid(actions: Array, skip := [], cols := 2) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	for a in actions:
		if not (a is Dictionary) or skip.has(str(a.get("command", ""))):
			continue
		var b := UI.action_button(a)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(b)
	return g


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
