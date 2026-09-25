extends GameScreen
## The bank: balance, cash in hand, quick deposits and withdrawals, any amount.


func build() -> void:
	scroll_body(18)
	var v := view
	content.add_child(title_row(I18n.t("bank.title", {"city": I18n.name_of("city", str(v.get("city_code", "")), str(v.get("city", "")))}), "bank"))
	maybe_notice()
	if v.get("travelling", false) or v.get("no_city", false):
		content.add_child(notice_banner(I18n.t("bank.closed"), "warn"))
	# balance hero
	var hero := GlowPanel.new()
	hero.top_color = Color("#2F4DA8")
	hero.bottom_color = Color("#223779")
	hero.accent = AppTheme.col("sky", 0.9)
	hero.padding = 26
	var hv := UI.vbox(8)
	hv.add_child(UI.hbox(10, [UI.icon("bank", 44), UI.label(I18n.t("stat.bank"), "SmallLabel")]))
	var bal := UI.label(I18n.money(int(v.get("bank", 0))), "HugeLabel")
	hv.add_child(bal)
	var cash_row := UI.hbox(10, [UI.icon("cash", 36), UI.label(I18n.t("stat.cash"), "DimLabel"), UI.spacer(),
		UI.label(I18n.money(int(v.get("cash", 0))), "MoneyLabel")])
	hv.add_child(cash_row)
	var fee := int(v.get("withdrawal_fee_bps", 0))
	if fee > 0:
		hv.add_child(UI.label(I18n.t("bank.fee", {"fee": Fmt.decimal(fee / 100.0, 1, I18n.lang)}), "DimLabel"))
	hero.add_child(hv)
	content.add_child(hero)
	Fx.pop(hero, 0.92)

	var acts: Array = resp.get("actions", [])
	_section(I18n.t("bank.deposit"), "deposit", acts, "bank.deposit", bool(v.get("can_deposit", true)))
	_section(I18n.t("bank.withdraw"), "withdraw", acts, "bank.withdraw", bool(v.get("can_withdraw", true)) and not v.get("jailed", false))
	var rest := actions_grid(acts, ["bank.deposit", "bank.withdraw", "bank.show"])
	if rest.get_child_count() > 0:
		content.add_child(rest)
	if str(resp.get("notice", "")).begins_with("📥") or str(v.get("notice", "")).begins_with("📥"):
		Fx.coins(self, Vector2(size.x / 2.0, 260))
	Fx.stagger_in(content)


func _section(title: String, icon_name: String, acts: Array, cmd: String, enabled: bool) -> void:
	var box := card(title, icon_name)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	for a in acts:
		if str(a.get("command", "")) != cmd:
			continue
		var b := UI.action_button(a, "GoldButton" if a.get("input") == null and icon_name == "deposit" else ("Button" if a.get("input") == null else "GhostButton"))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not enabled
		g.add_child(b)
	if g.get_child_count() == 0:
		box.add_child(UI.label(I18n.t("bank.nothing"), "DimLabel", -1, true))
	else:
		box.add_child(g)
