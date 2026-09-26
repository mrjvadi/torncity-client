extends GameScreen
## Education: the course in progress as a hero card (progress bar and time
## left), then the other courses as cards with their fee and the server's
## Enrol action; finished courses carry a check.
## view = {intelligence, courses: [{course, status: active|available|done, progress, seconds_left, fee}]}

var _timers: Array = []


func build() -> void:
	scroll_body(16)
	content.add_child(title_row(TextIcons.strip(str(resp.get("text", "")).split("\n")[0]), "education"))
	maybe_notice()
	var courses: Array = view.get("courses", [])
	for c in courses:
		if str(c.get("status", "")) == "active":
			content.add_child(_active(c))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	for c in courses:
		if str(c.get("status", "")) != "active":
			g.add_child(_course(c))
	content.add_child(g)
	var rest := actions_grid(page_actions())
	if rest.get_child_count() > 0:
		content.add_child(rest)
	Fx.stagger_in(content)
	tick()


func _name(c: Dictionary) -> String:
	var co: Dictionary = c.get("course", {})
	return Content.name_of("course", str(co.get("code", "")), str(co.get("name", "")))


func _active(c: Dictionary) -> Control:
	var p := GlowPanel.new()
	p.padding = 22
	p.tint_with(AppTheme.col("violet"), 0.2)
	p.accent = AppTheme.col("violet")
	var box := UI.vbox(12)
	p.add_child(box)
	var head := UI.hbox(16)
	head.add_child(IconBadge.make(AssetLib.glyph("action:education"), 88))
	var col := UI.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(I18n.t("education.studying"), "DimLabel"))
	col.add_child(UI.label(_name(c), "TitleLabel"))
	head.add_child(col)
	box.add_child(head)
	var bar := StatBar.new()
	bar.icon_name = ""
	bar.color = AppTheme.col("violet")
	bar.custom_minimum_size = Vector2(100, 30)
	box.add_child(bar)
	var left := UI.label("", "SmallLabel")
	left.add_theme_color_override("font_color", AppTheme.col("info"))
	box.add_child(left)
	var prog := float(c.get("progress", 0))
	var secs := float(c.get("seconds_left", 0))
	_timers.append([left, Time.get_unix_time_from_system() + secs, bar, prog, secs])
	bar.set_value(prog * 100, 100, I18n.digits("%d%%" % int(prog * 100)))
	return p


func _course(c: Dictionary) -> Control:
	var status := str(c.get("status", ""))
	var co: Dictionary = c.get("course", {})
	var p := GlowPanel.new()
	p.padding = 16
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UI.vbox(10)
	p.add_child(box)
	var badge := IconBadge.make(AssetLib.glyph("course:" + str(co.get("code", "")), "") if AssetLib.icons.has("course:" + str(co.get("code", ""))) else AssetLib.glyph("action:education"), 64)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(badge)
	var nm := UI.label(_name(c), "SmallLabel")
	nm.add_theme_font_override("font", AppTheme.font_bold)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(nm)
	if status == "done":
		box.add_child(UI.chip("check", I18n.t("education.done"), Color(AppTheme.col("success"), 0.3)))
	else:
		box.add_child(UI.chip("cash", I18n.money(int(c.get("fee", 0)))))
		var a := row_action("course", co.get("code", ""))
		if not a.is_empty():
			var b := pill(ActionKit.label_of(a), "primary", func(): ActionKit.run(a, self))
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			box.add_child(b)
	return p


func tick() -> void:
	var now := Time.get_unix_time_from_system()
	for t in _timers:
		var left := maxf(0.0, float(t[1]) - now)
		(t[0] as Label).text = I18n.t("education.left", {"time": I18n.dur(int(left))})
