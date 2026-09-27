class_name ResourceChip
extends PanelContainer
## A compact HUD chip: a small badge icon and a big bold number (counting up
## when it changes); a stat with a maximum gets a thin bar under the number.

var key := ""
var _value: Label
var _bar: StatBar
var _last := -1
var _format: Callable


static func make(asset_key: String, with_bar: bool, format: Callable) -> ResourceChip:
	var c := ResourceChip.new()
	c.key = asset_key
	c._format = format
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(AppTheme.col("bg"), 0.55)
	sb.set_corner_radius_all(20)
	sb.border_color = AppTheme.col("stroke")
	sb.set_border_width_all(1)
	sb.anti_aliasing = true
	sb.content_margin_left = 6
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	c.add_theme_stylebox_override("panel", sb)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UI.hbox(8)
	var g := AssetLib.glyph(asset_key)
	var badge := IconBadge.make(g, 34)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)
	var col := UI.vbox(3)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	c._value = Label.new()
	c._value.add_theme_font_override("font", AppTheme.font_black)
	c._value.add_theme_font_size_override("font_size", 22)
	c._value.add_theme_color_override("font_color", AppTheme.col("gold") if asset_key == "res:cash" else AppTheme.col("text"))
	c._value.clip_text = true
	col.add_child(c._value)
	if with_bar:
		c._bar = StatBar.new()
		c._bar.icon_name = ""
		c._bar.compact = true
		c._bar.show_text = false
		c._bar.custom_minimum_size = Vector2(30, 6)
		c._bar.color = g["tint"]
		col.add_child(c._bar)
	row.add_child(col)
	c.add_child(row)
	return c


func set_amount(v: int, max_v := -1) -> void:
	if _bar and max_v > 0:
		_bar.set_value(v, max_v)
	Fx.roll_number(_value, _last if _last >= 0 else v, v, _format)
	if _last >= 0 and v > _last:
		Fx.pulse(_value)
	_last = v
