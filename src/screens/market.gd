extends GameScreen
## The market: Buy / Sell tabs over a table. Buy rows: item badge, name and
## seller, price with its day change, quantity, and the server's Buy action.
## Sell rows: what the player holds, the best bid, the server's Sell action.
## view = {buy: [{id, item, price, qty, seller, change}], sell: [{item, qty, best_bid}], fee_bps}

var tab := 0
var _table: VBoxContainer


func build() -> void:
	scroll_body(16)
	content.add_child(title_row(TextIcons.strip(str(resp.get("text", "")).split("\n")[0]), "market"))
	maybe_notice()
	content.add_child(segmented([I18n.t("market.buy"), I18n.t("market.sell")], tab, func(i):
		tab = i
		_fill()))
	var box := panel_card(8)
	_table = box
	_fill()
	var fee := int(view.get("fee_bps", 0))
	if fee > 0:
		content.add_child(UI.label(I18n.t("market.fee", {"fee": I18n.digits("%.1f" % (fee / 100.0))}), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER))
	var g := actions_grid(page_actions())
	if g.get_child_count() > 0:
		content.add_child(g)
	Fx.stagger_in(content)


func _fill() -> void:
	UI.clear(_table)
	# header row
	var head := UI.hbox(10)
	head.custom_minimum_size.y = 44
	for h in [[I18n.t("market.item"), 3.2], [I18n.t("market.price"), 1.6], [I18n.t("market.qty"), 1.0]]:
		var l := UI.label(str(h[0]), "DimLabel")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = float(h[1])
		head.add_child(l)
	head.add_child(_wspace(104))
	_table.add_child(UI.margin(head, 12, 4, 12, 0))
	var rows: Array = view.get("buy" if tab == 0 else "sell", [])
	if rows.is_empty():
		_table.add_child(UI.label(I18n.t("market.empty"), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER))
	for i in rows.size():
		_table.add_child(_row(rows[i], i % 2 == 1))
	Fx.stagger_in(_table, 0.03, 12.0)


func _row(r: Dictionary, zebra: bool) -> Control:
	var item: Dictionary = r.get("item", {})
	var code := str(item.get("code", ""))
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#16243A", 0.55) if zebra else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	var row := UI.hbox(10)
	p.add_child(row)
	# item: badge + name (+ seller)
	var who := UI.hbox(10)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.size_flags_stretch_ratio = 3.2
	who.add_child(IconBadge.make(AssetLib.glyph_for("item", code), 52))
	var nm := UI.vbox(0)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name := UI.label(Content.name_of("item", code, str(item.get("name", code))), "SmallLabel")
	name.add_theme_font_override("font", AppTheme.font_bold)
	name.clip_text = true
	nm.add_child(name)
	var sub := str(r.get("seller", "")) if tab == 0 else I18n.t("market.you_have", {"qty": I18n.num(int(r.get("qty", 0)))})
	var sl := UI.label(sub, "DimLabel")
	sl.add_theme_font_size_override("font_size", 18)
	sl.clip_text = true
	nm.add_child(sl)
	who.add_child(nm)
	row.add_child(who)
	# price + change
	var pc := UI.vbox(0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_stretch_ratio = 1.6
	var price := int(r.get("price", r.get("best_bid", 0)))
	var pl := UI.label(I18n.money_short(price), "SmallLabel")
	pl.add_theme_font_override("font", AppTheme.font_bold)
	pl.add_theme_color_override("font_color", AppTheme.col("yellow"))
	pc.add_child(pl)
	if r.has("change"):
		var ch := float(r["change"])
		var cl := UI.label(("▲ " if ch > 0 else ("▼ " if ch < 0 else "• ")) + I18n.digits("%.1f%%" % absf(ch)), "DimLabel")
		cl.add_theme_font_size_override("font_size", 17)
		cl.add_theme_color_override("font_color", AppTheme.col("green") if ch > 0 else (AppTheme.col("red") if ch < 0 else AppTheme.col("text_dim")))
		pc.add_child(cl)
	elif tab == 1:
		var bl := UI.label(I18n.t("market.best_bid"), "DimLabel")
		bl.add_theme_font_size_override("font_size", 17)
		pc.add_child(bl)
	row.add_child(pc)
	var q := UI.label(I18n.num(int(r.get("qty", 0))), "SmallLabel")
	q.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	q.size_flags_stretch_ratio = 1.0
	row.add_child(q)
	# the server's row action
	var a := row_action("listing", r.get("id")) if tab == 0 else row_action("item", code)
	if not a.is_empty():
		var b := pill(ActionKit.label_of(a), "buy" if tab == 0 else "danger", func(): ActionKit.run(a, self))
		b.custom_minimum_size = Vector2(104, 52)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	else:
		row.add_child(_wspace(104))
	return p


static func _wspace(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
