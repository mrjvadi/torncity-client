extends GameScreen
## The backpack: every item as a tile with its quantity and condition.

const CATEGORY_ICON := {"food": "food", "medical": "hospital", "tools": "skills", "electronics": "phone",
	"weapon": "crime", "vehicle": "car", "material": "company", "goods": "market", "document": "certificate"}


func build() -> void:
	scroll_body(18)
	content.add_child(title_row(I18n.t("more.inventory"), "inventory"))
	maybe_notice()
	var lines: Array = view.get("lines", []) if view.get("lines") is Array else []
	if lines.is_empty():
		content.add_child(notice_banner(I18n.t("inventory.empty"), "warn"))
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
	var t := AppTheme.tex("item/" + code)
	var ic := UI.tex(t, Vector2(76, 76)) if t else UI.icon(CATEGORY_ICON.get(str(l.get("category", "")), "inventory"), 70)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ic)
	var name := UI.label(str(item.get("name", code)), "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	b.add_child(box)
	var qty := int(l.get("qty", 1))
	if qty > 1:
		var badge := UI.chip("", "×" + I18n.num(qty), AppTheme.col("saffron_dk"))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.position = Vector2(10, 10)
		b.add_child(badge)
	var dura := int(l.get("durability", 0))
	if dura > 0:
		var bar := StatBar.new()
		bar.icon_name = "skills"
		bar.compact = true
		bar.show_text = false
		bar.color = AppTheme.col("leaf")
		bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = -38
		bar.offset_bottom = -12
		bar.offset_left = 14
		bar.offset_right = -14
		bar.set_value(dura, 100)
		b.add_child(bar)
	Fx.press_feedback(b)
	b.pressed.connect(func(): Game.run("inventory.item", {"item": code}))
	return b
