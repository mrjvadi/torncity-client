extends GameScreen
## Crime: a heat meter, then one card per crime in a two-column grid: the
## crime's badge, its success chance as a ring, energy cost, reward range,
## and the server's Commit action (a confirm action: asks first).
## view = {heat, jail_seconds, crimes: [{crime, chance, energy, reward, cooldown_seconds}]}


func build() -> void:
	scroll_body(16)
	content.add_child(title_row(TextIcons.strip(str(resp.get("text", "")).split("\n")[0]), "crime"))
	maybe_notice()
	var heat := int(view.get("heat", 0))
	var hb := panel_card(18, AppTheme.col("red", 0.8))
	var hrow := UI.hbox(12)
	hrow.add_child(IconBadge.make(AssetLib.glyph("action:crime"), 52))
	var bar := StatBar.new()
	bar.icon_name = ""
	bar.label_text = I18n.t("crime.heat")
	bar.color = AppTheme.col("red")
	bar.invert = true
	bar.custom_minimum_size = Vector2(100, 48)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hrow.add_child(bar)
	hb.add_child(hrow)
	bar.set_value(heat, 100, I18n.digits("%d/100" % heat))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	for c in view.get("crimes", []):
		g.add_child(_card(c))
	content.add_child(g)
	var rest := actions_grid(page_actions())
	if rest.get_child_count() > 0:
		content.add_child(rest)
	Fx.stagger_in(content)


func _card(c: Dictionary) -> Control:
	var cr: Dictionary = c.get("crime", {})
	var code := str(cr.get("code", ""))
	var chance := int(c.get("chance", 0))
	var col := AppTheme.col("green") if chance >= 60 else (AppTheme.col("yellow") if chance >= 30 else AppTheme.col("red"))
	var p := GlowPanel.new()
	p.radius = 14
	p.padding = 16
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UI.vbox(10)
	p.add_child(box)
	var head := UI.hbox(10)
	head.add_child(IconBadge.make(AssetLib.glyph_for("crime", code), 60))
	var nm := UI.label(Content.name_of("crime", code, str(cr.get("name", code))), "SmallLabel")
	nm.add_theme_font_override("font", AppTheme.font_bold)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	box.add_child(head)
	var ring := Ring.new()
	ring.color = col
	ring.thickness = 10
	ring.custom_minimum_size = Vector2(120, 120)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ring)
	ring.set_value(chance / 100.0, I18n.digits("%d%%" % chance), I18n.t("crime.chance"))
	var facts := UI.hbox(8)
	facts.add_child(UI.chip("energy", I18n.num(int(c.get("energy", 0)))))
	facts.add_child(UI.chip("cash", I18n.digits(str(c.get("reward", "")))))
	box.add_child(facts)
	var cd := int(c.get("cooldown_seconds", 0))
	var a := row_action("crime", code)
	if cd > 0:
		var w := pill(I18n.dur(cd), "ghost", func(): pass)
		w.disabled = true
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(w)
	elif not a.is_empty():
		var b := pill(ActionKit.label_of(a), "danger", func(): ActionKit.run(a, self))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(b)
	return p
