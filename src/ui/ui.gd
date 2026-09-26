class_name UI
## Small factories so screens read as layout, not boilerplate.


static func label(text: String, variation := "", align := -1, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	l.horizontal_alignment = I18n.start_align() if align < 0 else align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func icon(name: String, size := 40) -> TextureRect:
	var t := TextureRect.new()
	t.texture = AppTheme.icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func tex(texture: Texture2D, size: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func hbox(sep := 12, children := []) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	for c in children:
		b.add_child(c)
	return b


static func vbox(sep := 14, children := []) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	for c in children:
		b.add_child(c)
	return b


static func spacer(h := true) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func margin(child: Control, l := 24, t := 16, r := 24, b := 16) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m


static func panel(child: Control, variation := "CardPanel") -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	p.add_child(child)
	return p


## A button with an icon from the set. `kind`: "", "GhostButton", "GoldButton", "DangerButton", "ActionButton".
static func button(text: String, icon_name := "", kind := "", on_press := Callable()) -> Button:
	var b := Button.new()
	b.text = text
	if kind != "":
		b.theme_type_variation = kind
	if icon_name != "":
		b.icon = AppTheme.icon(icon_name)
		b.expand_icon = true
	b.custom_minimum_size = Vector2(0, 84)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	Fx.press_feedback(b)
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


## A server action as a button: its leading emoji becomes the icon.
static func action_button(action: Dictionary, kind := "ActionButton") -> Button:
	var label := str(action.get("label", ""))
	var ic := TextIcons.lead_icon(label)
	if I18n.is_rtl() and ic in ["back", "forward"]:
		ic = "forward" if ic == "back" else "back"   # arrows point the reading way
	var b := button(TextIcons.strip(label), ic, kind)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.pressed.connect(func(): Game.run_action(action))
	return b


## Server text, with the glossary's emoji drawn as the client's icons.
static func rich(text: String, size := 0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.selection_enabled = false
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.text_direction = I18n.text_direction()
	if size > 0:
		r.add_theme_font_size_override("normal_font_size", size)
	var isz := int((size if size > 0 else AppTheme.SIZE_BODY) * 1.25)
	var bb := TextIcons.to_bbcode(text, isz, AppTheme.icon_path)
	# text_direction makes the paragraph start the language's way even when a
	# line opens with an icon.
	r.text = bb
	return r


## A thin pill: icon + value (used in the HUD and on cards).
static func chip(icon_name: String, text: String, color := Color.TRANSPARENT) -> PanelContainer:
	var h := hbox(8, [label(text, "SmallLabel")])
	if icon_name != "":
		var ic := icon(icon_name, 30)
		h.add_child(ic)
		h.move_child(ic, 0)
	var p := panel(h, "ChipPanel")
	if color.a > 0:
		var sb := AppTheme.box(color, 8, Color(color.lightened(0.25), 0.8), 1, 0, 12)
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		p.add_theme_stylebox_override("panel", sb)
	return p


static func scroll(child: Control) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
