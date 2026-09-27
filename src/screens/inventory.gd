extends GameScreen
## The backpack: every item as a tile with its quantity and condition.

func build() -> void:
	scroll_body(18)
	content.add_child(title_row(I18n.t("more.inventory"), "inventory"))
	maybe_notice()
	var lines: Array = view.get("lines", []) if view.get("lines") is Array else []
	if lines.is_empty():
		content.add_child(UI.gap(60))
		content.add_child(StateView.make("empty", I18n.t("inventory.empty_title"), I18n.t("inventory.empty")))
		var rest0 := actions_grid(resp.get("actions", []))
		if rest0.get_child_count() > 0:
			content.add_child(rest0)
		return
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 14)
	for l in lines:
		g.add_child(_item(l))
	content.add_child(g)
	var pages := int(view.get("pages", 1))
	if pages > 1:
		content.add_child(UI.label(I18n.t("page.of", {"page": int(view.get("page", 1)), "pages": pages}), "DimLabel", HORIZONTAL_ALIGNMENT_CENTER))
	var acts: Array = resp.get("actions", [])
	var rest := actions_grid(acts, ["inventory.item", "player.profile.get"])
	if rest.get_child_count() > 0:
		content.add_child(rest)
	Fx.stagger_in(g, 0.03)


func _item(l: Dictionary) -> Control:
	var item: Dictionary = l.get("item", {})
	var b := Button.new()
	b.theme_type_variation = "ActionButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 190)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UI.vbox(6)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var code := str(item.get("code", ""))
	# the icon: the catalogue's asset key, else the item's category look
	var cat := str(Content.entry("item", code).get("category", l.get("category", "")))
	var ic := IconBadge.make(AssetLib.glyph(Content.asset("item", code, "icon"), cat), 92)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ic)
	var name := UI.label(Content.name_of("item", code, str(item.get("name", code))), "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	b.add_child(box)
	var qty := int(l.get("qty", 1))
	if qty > 1:
		var badge := UI.chip("", "×" + I18n.num(qty), AppTheme.col("surface_3"))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.position = Vector2(10, 10)
		b.add_child(badge)
	var dura := int(l.get("durability", 0))
	if dura > 0:
		var bar := StatBar.new()
		bar.icon_name = ""
		bar.compact = true
		bar.show_text = false
		bar.color = AppTheme.col("success")
		bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -22
		bar.offset_bottom = -12
		bar.offset_left = 14
		bar.offset_right = -14
		bar.set_value(dura, 100)
		b.add_child(bar)
	Fx.press_feedback(b)
	# the server's own button for this item, if it sent one
	for a in resp.get("actions", []):
		if a is Dictionary and a.get("args") is Dictionary and str(a["args"].get("item", "")) == code:
			b.pressed.connect(func(): Game.run_action(a))
			break
	return b
