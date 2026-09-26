extends GameScreen
## The generic screen, for anything the client has no bespoke layout for. It
## must still look designed: a hero header (badge for the command's domain,
## title, subtitle), the server text parsed into cards (headings, stat tiles,
## list rows, paragraphs), and the actions as an icon grid with the primary
## one pinned at the bottom.


func build() -> void:
	scroll_body(16)
	var parsed := TextSections.parse(str(resp.get("text", "")))
	content.add_child(_hero(parsed))
	maybe_notice_card()
	for b in parsed.blocks:
		content.add_child(_block(b))
	var acts: Array = resp.get("actions", [])
	if not acts.is_empty():
		var g := actions_grid(acts)
		if g.get_child_count() > 0:
			content.add_child(g)
	Fx.stagger_in(content)


func _hero(p: Dictionary) -> Control:
	var cmd := str(req.get("command", ""))
	var g := AssetLib.action_glyph(cmd)
	var tint: Color = g.get("tint", AppTheme.col("blue"))
	var hero := GlowPanel.new()
	hero.radius = 14
	hero.padding = 22
	hero.top_color = Color("#16243A").lerp(tint, 0.28)
	hero.bottom_color = Color("#0F1A2B").lerp(tint, 0.08)
	hero.border_color = Color(tint, 0.55)
	hero.accent = Color(tint, 0.9)
	var row := UI.hbox(18)
	hero.add_child(row)
	row.add_child(IconBadge.make(g, 104))
	var t := UI.vbox(4)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := TextIcons.strip(str(p.title)) if str(p.title) != "" else I18n.t("card.title")
	var tl := UI.label(title, "TitleLabel")
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_child(tl)
	if str(p.subtitle) != "":
		var st := UI.label(TextIcons.strip(str(p.subtitle)), "DimLabel")
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.add_child(st)
	row.add_child(t)
	var nav := UI.vbox(10)
	if Game.can_go_back():
		nav.add_child(round_button("back" if not I18n.is_rtl() else "forward", func(): Game.back()))
	nav.add_child(round_button("refresh", func(): Game.refresh_current()))
	row.add_child(nav)
	return hero


func _block(b: Dictionary) -> Control:
	var p := GlowPanel.new()
	p.radius = 12
	p.padding = 20
	var box := UI.vbox(12)
	p.add_child(box)
	if str(b.heading) != "":
		var h := UI.hbox(10)
		var ic := TextIcons.lead_icon(str(b.heading))
		if ic != "":
			h.add_child(UI.icon(ic, 34))
		h.add_child(UI.label(TextIcons.strip(str(b.heading)), "HeadLabel"))
		box.add_child(h)
	if not (b.stats as Array).is_empty():
		var g := GridContainer.new()
		g.columns = 2 if (b.stats as Array).size() > 1 else 1
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 10)
		for kv in b.stats:
			g.add_child(_stat_tile(str(kv[0]), str(kv[1])))
		box.add_child(g)
	if not (b.list as Array).is_empty():
		var lst := UI.vbox(0)
		for i in (b.list as Array).size():
			lst.add_child(_row(str(b.list[i]), i == (b.list as Array).size() - 1))
		box.add_child(lst)
	for para in b.para:
		box.add_child(UI.rich(str(para), 24))
	return p


func _stat_tile(k: String, v: String) -> Control:
	var tile := UI.vbox(4)
	var ic := TextIcons.lead_icon(k)
	var head := UI.hbox(8)
	if ic != "":
		head.add_child(UI.icon(ic, 26))
	head.add_child(UI.label(TextIcons.strip(k), "DimLabel"))
	tile.add_child(head)
	var val := UI.label(TextIcons.strip(v), "HeadLabel")
	val.add_theme_font_size_override("font_size", 28)
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.add_child(val)
	var p := UI.panel(tile, "InsetPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


func _row(text: String, last: bool) -> Control:
	var r := UI.vbox(0)
	var h := UI.hbox(12)
	h.custom_minimum_size.y = 58
	var ic := TextIcons.lead_icon(text)
	if ic != "":
		h.add_child(UI.icon(ic, 30))
	else:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = AppTheme.col("blue")
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dot)
	var l := UI.rich(TextIcons.strip(text) if ic != "" else text, 24)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	r.add_child(h)
	if not last:
		var sep := ColorRect.new()
		sep.custom_minimum_size.y = 1
		sep.color = Color("#2B4468", 0.6)
		r.add_child(sep)
	return r


func maybe_notice_card() -> void:
	var n := str(resp.get("notice", ""))
	if n != "":
		content.add_child(notice_banner(n))
	var err = resp.get("error")
	if err is Dictionary and str(err.get("message", "")) != "" and str(err.get("message", "")) != str(resp.get("text", "")):
		content.add_child(notice_banner(str(err["message"]), "error"))
