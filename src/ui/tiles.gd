class_name Tiles
## Feature tiles for the «More» grid and profile shortcuts.


static func feature(icon_name: String, label: String, command: String, shell: Node, args := {}) -> Control:
	var b := Button.new()
	b.theme_type_variation = "ActionButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := UI.vbox(6)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := UI.icon(icon_name, 60)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ic)
	var l := UI.label(label, "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	b.add_child(box)
	Fx.press_feedback(b)
	b.pressed.connect(func():
		if command == "":
			shell.open_local(icon_name)
		else:
			Game.run(command, args))
	return b
