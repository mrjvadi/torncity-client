extends GameScreen
## «My life»: needs as gauges, age and stage, intelligence, rank and net worth.


func build() -> void:
	scroll_body(18)
	var v := view
	content.add_child(title_row(I18n.t("more.life"), "life"))
	maybe_notice()
	var needs: Dictionary = v.get("needs", {}) if v.get("needs") is Dictionary else {}
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", 8)
	for n in [["hunger", "brick", true], ["sleep", "violet", true], ["stress", "rose", true], ["happiness", "leaf", false]]:
		var r := Ring.new()
		r.icon_name = n[0]
		var val := int(needs.get(n[0], 0))
		var c := AppTheme.col(n[1])
		if n[2] and val >= 90:
			c = AppTheme.col("pomegranate")
		r.color = c
		r.thickness = 12
		r.custom_minimum_size = Vector2(150, 190)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.set_value(val / 100.0, I18n.num(val), I18n.t("need." + n[0]))
		g.add_child(r)
	var needs_card := card(I18n.t("life.needs"), "life")
	needs_card.add_child(g)
	needs_card.add_child(UI.label(I18n.t("life.needs_hint"), "DimLabel", -1, true))

	var me := card(I18n.t("life.me"), "profile")
	var stage = v.get("stage")
	me.add_child(_fact("age", I18n.t("life.age"), "%s - %s" % [I18n.num(int(v.get("age", 0))), str(stage.get("name", "")) if stage is Dictionary else ""]))
	var ib := StatBar.new()
	ib.icon_name = "study"
	ib.color = AppTheme.col("lapis").lightened(0.2)
	ib.set_value(int(v.get("intelligence", 0)), int(v.get("intelligence_max", 100)), "%s - %s" % [I18n.t("life.intelligence"), I18n.of(int(v.get("intelligence", 0)), int(v.get("intelligence_max", 100)))])
	me.add_child(ib)
	var rank = v.get("rank")
	var nxt = v.get("next")
	if rank is Dictionary:
		me.add_child(_fact("rank", I18n.t("life.rank"), TextIcons.strip(str(rank.get("name", "")))))
	if nxt is Dictionary:
		me.add_child(_fact("promotion", I18n.t("life.next_rank"), "%s - %s" % [TextIcons.strip(str(nxt.get("name", ""))), I18n.money(int(v.get("next_need", 0)))]))

	var w = v.get("worth")
	if w is Dictionary:
		var wc := card(I18n.t("life.worth"), "moneybag")
		var total := maxi(1, int(w.get("total", 0)))
		wc.add_child(UI.label(I18n.money(int(w.get("total", 0))), "HugeLabel"))
		for part in [["cash", "cash", "leaf"], ["bank", "bank", "sky"], ["goods", "inventory", "earth"], ["property", "home", "brick"],
				["equity", "stock", "turquoise"], ["savings", "moneybag", "saffron"], ["gold", "gold", "saffron"], ["debts", "warning", "pomegranate"]]:
			var amount := int(w.get(part[0], 0))
			if amount == 0:
				continue
			var b := StatBar.new()
			b.icon_name = part[1]
			b.color = AppTheme.col(part[2])
			b.compact = true
			b.set_value(absi(amount), total, "%s - %s" % [I18n.t("worth." + part[0]), I18n.money(amount)])
			b.custom_minimum_size.y = 40
			wc.add_child(b)
	content.add_child(actions_grid(resp.get("actions", []), ["player.profile.get"]))
	Fx.stagger_in(content)


func _fact(icon_name: String, k: String, val: String) -> Control:
	return UI.hbox(10, [UI.icon(icon_name, 34), UI.label(k, "DimLabel"), UI.spacer(), UI.label(val, "SmallLabel")])
