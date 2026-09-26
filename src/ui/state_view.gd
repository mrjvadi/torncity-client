class_name StateView
extends VBoxContainer
## Empty / error / offline / done states: an illustration, a title, a line of
## text and an optional action button. Used by every screen that can be empty.


static func make(kind: String, title: String, text := "", action_label := "", fn := Callable()) -> StateView:
	var v := StateView.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(Illustration.make(kind, 220))
	var t := UI.label(title, "TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if text != "":
		var d := UI.label(text, "DimLabel", HORIZONTAL_ALIGNMENT_CENTER)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 300
		v.add_child(d)
	if action_label != "" and fn.is_valid():
		var b := UI.button(action_label, "", "Button" if kind != "error" else "DangerButton", fn)
		b.custom_minimum_size = Vector2(300, 80)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(b)
	if not Config.headless_capture:
		Fx.stagger_in(v, 0.06, 18.0)
	return v
