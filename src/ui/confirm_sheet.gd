class_name ConfirmSheet
extends Control
## "Are you sure?" as a bottom sheet over a dimmed screen: for actions of
## kind danger / confirm. Slides up in 200 ms; tap outside to cancel.


static func ask(host: Node, title: String, text: String, on_yes: Callable, danger := true) -> void:
	var s := ConfirmSheet.new()
	var root := host.get_tree().root.get_child(host.get_tree().root.get_child_count() - 1)
	root.add_child(s)
	s._build(title, text, on_yes, danger)


func _build(title: String, text: String, on_yes: Callable, danger: bool) -> void:
	layout_direction = I18n.direction()
	# set_anchors_preset(FULL_RECT) collapses to a zero-size rect pinned to
	# the right edge on a fresh node whose layout_direction is RTL (a plain
	# top-level overlay, not inheriting RTL the way a screen already parented
	# under the RTL shell does) - set the anchors/offsets directly instead.
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _close())
	add_child(dim)
	var sheet := GlowPanel.new()
	sheet.radius = 14
	sheet.padding = 26
	sheet.accent = AppTheme.col("red" if danger else "blue")
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.offset_left = 16
	sheet.offset_right = -16
	sheet.offset_bottom = -16
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(sheet)
	var box := UI.vbox(16)
	sheet.add_child(box)
	var head := UI.hbox(14)
	head.add_child(IconBadge.make(AssetLib.glyph("action:" + ("danger" if danger else "confirm")), 64))
	var col := UI.vbox(4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.label(title, "HeadLabel"))
	var sub := UI.label(text if text != "" else I18n.t("confirm.sure"), "DimLabel")
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	head.add_child(col)
	box.add_child(head)
	var row := UI.hbox(12)
	var no := UI.button(I18n.t("confirm.cancel"), "", "GhostButton", _close)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var yes := UI.button(I18n.t("confirm.yes"), "", "DangerButton" if danger else "Button", func():
		_close()
		on_yes.call())
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(no)
	row.add_child(yes)
	box.add_child(row)
	if not Config.headless_capture:
		sheet.modulate.a = 0.0
		var tw := create_tween().set_parallel()
		tw.tween_property(sheet, "modulate:a", 1.0, 0.18)
		Fx.fade_in(dim, 0.18)


func _close() -> void:
	queue_free()
