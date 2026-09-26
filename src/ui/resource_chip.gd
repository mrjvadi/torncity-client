class_name ResourceChip
extends PanelContainer
## A HUD resource chip: a small badge icon, the value (rolling when it
## changes) and, for a stat with a maximum, a thin bar under it.

var key := ""
var _value: Label
var _bar: StatBar
var _last := -1
var _format: Callable


static func make(asset_key: String, with_bar: bool, format: Callable) -> ResourceChip:
	var c := ResourceChip.new()
	c.key = asset_key
	c._format = format
	c.theme_type_variation = "InsetPanel"
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UI.hbox(8)
	row.add_child(IconBadge.make(AssetLib.glyph(asset_key), 40))
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	c._value = UI.label("", "SmallLabel")
	c._value.add_theme_font_override("font", AppTheme.font_bold)
	c._value.add_theme_font_size_override("font_size", 22)
	c._value.clip_text = true
	col.add_child(c._value)
	if with_bar:
		c._bar = StatBar.new()
		c._bar.icon_name = ""
		c._bar.compact = true
		c._bar.show_text = false
		c._bar.custom_minimum_size = Vector2(40, 8)
		c._bar.color = AssetLib.glyph(asset_key)["tint"]
		col.add_child(c._bar)
	row.add_child(col)
	c.add_child(row)
	return c


func set_amount(v: int, max_v := -1) -> void:
	if _bar and max_v > 0:
		_value.text = I18n.digits("%d/%d" % [v, max_v])
		_bar.set_value(v, max_v)
	else:
		Fx.roll_number(_value, _last if _last >= 0 else v, v, _format)
		if _last >= 0 and v > _last:
			Fx.pulse(_value)
	_last = v
