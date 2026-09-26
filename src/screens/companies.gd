extends GameScreen
## The player's companies as cards: a badge for the company type (content
## catalogue asset key, so new types still get a look), name, type and level,
## what it is producing with a live progress bar and countdown, staff and cash.
## view = {companies: [{id, name, type, level, staff, cash,
##                      producing: {item, progress 0..1, eta_seconds, per_hour}}]}

var _timers: Array = []   # [label, end_unix, bar, progress0, eta0]


func build() -> void:
	scroll_body(16)
	content.add_child(title_row(TextIcons.strip(str(resp.get("text", "")).split("\n")[0]), "company"))
	maybe_notice()
	var list: Array = view.get("companies", [])
	if list.is_empty():
		var e := panel_card(24)
		e.add_child(UI.label(I18n.t("companies.none"), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER, true))
	for c in list:
		content.add_child(_card(c))
	var g := actions_grid(page_actions())
	if g.get_child_count() > 0:
		content.add_child(g)
	Fx.stagger_in(content)
	tick()


func _card(c: Dictionary) -> Control:
	var t := str(c.get("type", ""))
	var gl := AssetLib.glyph_for("company_type", t)
	var tint: Color = gl.get("tint", AppTheme.col("primary"))
	var p := GlowPanel.new()
	p.radius = 14
	p.padding = 20
	p.top_color = Color("#1A2A43").lerp(tint, 0.14)
	p.accent = Color(tint, 0.8)
	var box := UI.vbox(14)
	p.add_child(box)
	var head := UI.hbox(16)
	head.add_child(IconBadge.make(gl, 84))
	var col := UI.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(str(c.get("name", "")), "HeadLabel"))
	var sub := UI.hbox(8)
	sub.add_child(UI.chip("", Content.name_of("company_type", t), Color(tint, 0.25)))
	sub.add_child(UI.chip("", I18n.t("profile.level", {"level": I18n.num(int(c.get("level", 1)))}), Color("#2B4468")))
	col.add_child(sub)
	head.add_child(col)
	box.add_child(head)
	# production
	var pr = c.get("producing")
	if pr is Dictionary:
		var item: Dictionary = pr.get("item", {})
		var code := str(item.get("code", ""))
		var prow := UI.hbox(12)
		prow.add_child(IconBadge.make(AssetLib.glyph_for("item", code), 48))
		var pc := UI.vbox(6)
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var top := UI.hbox(8)
		var what := UI.label(I18n.t("companies.producing", {"item": Content.name_of("item", code, str(item.get("name", code)))}), "SmallLabel")
		what.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(what)
		var eta := UI.label("", "SmallLabel")
		eta.add_theme_color_override("font_color", AppTheme.col("info"))
		top.add_child(eta)
		pc.add_child(top)
		var bar := StatBar.new()
		bar.icon_name = ""
		bar.compact = true
		bar.show_text = false
		bar.custom_minimum_size = Vector2(80, 14)
		bar.color = AppTheme.col("success")
		pc.add_child(bar)
		var rate := UI.label(I18n.t("companies.rate", {"n": I18n.num(int(pr.get("per_hour", 0)))}), "DimLabel")
		rate.add_theme_font_size_override("font_size", 18)
		pc.add_child(rate)
		prow.add_child(pc)
		box.add_child(UI.panel(prow, "InsetPanel"))
		var prog := float(pr.get("progress", 0))
		var left := float(pr.get("eta_seconds", 0))
		_timers.append([eta, Time.get_unix_time_from_system() + left, bar, prog, left])
		bar.set_value(prog * 100.0, 100.0)
	# stats
	var stats := UI.hbox(10)
	stats.add_child(_stat("action:staff", I18n.num(int(c.get("staff", 0))), I18n.t("companies.staff")))
	stats.add_child(_stat("res:cash", I18n.money_short(int(c.get("cash", 0))), I18n.t("companies.cash")))
	box.add_child(stats)
	# the whole card opens the company (the server's row action)
	var a := row_action("id", c.get("id"))
	if not a.is_empty():
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		hit.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit.pressed.connect(func(): ActionKit.run(a, self))
		p.add_child.call_deferred(hit)
	return p


func _stat(key: String, value: String, caption: String) -> Control:
	var h := UI.hbox(10)
	h.add_child(IconBadge.make(AssetLib.glyph(key), 40, false))
	var v := UI.vbox(0)
	var vl := UI.label(value, "SmallLabel")
	vl.add_theme_font_override("font", AppTheme.font_bold)
	v.add_child(vl)
	var cl := UI.label(caption, "DimLabel")
	cl.add_theme_font_size_override("font_size", 17)
	v.add_child(cl)
	h.add_child(v)
	var p := UI.panel(h, "InsetPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func tick() -> void:
	var now := Time.get_unix_time_from_system()
	for t in _timers:
		var left := maxf(0.0, float(t[1]) - now)
		(t[0] as Label).text = I18n.dur(int(left))
		var total := float(t[4]) / maxf(0.01, 1.0 - float(t[3]))
		var p := 1.0 - left / maxf(total, 1.0)
		(t[2] as StatBar).set_value(clampf(p, 0, 1) * 100.0, 100.0)
