class_name SideMenu
extends GlowPanel
## The side menu: the server's main menu (Session.hub_actions — the profile
## screen's actions), one row per action. The client adds only an icon, chosen
## by the command's domain (AssetLib.action_icon), and a Settings row.

signal picked(action: Dictionary)

var _rows: VBoxContainer


func _init() -> void:
	super._init()
	radius = 10
	shadow = 18
	padding = 12


func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	_rows = UI.vbox(4)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	build()
	Session.hub_changed.connect(build)
	I18n.changed.connect(func(_l): build())


func build() -> void:
	UI.clear(_rows)
	for a in Session.hub_actions:
		if a is Dictionary:
			_rows.add_child(_row(AssetLib.action_icon(str(a.get("command", ""))), TextIcons.strip(str(a.get("label", ""))), a))
	_rows.add_child(_row("ln_settings", I18n.t("more.settings"), {"command": "@settings"}))


func _row(icon_name: String, label: String, action: Dictionary) -> Button:
	var b := Button.new()
	b.theme_type_variation = "NavButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 62)
	b.icon = AppTheme.icon(icon_name)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 30)
	b.add_theme_constant_override("h_separation", 16)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", AppTheme.col("text"))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.text = label
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#1D2F4B")
	hover.set_corner_radius_all(8)
	hover.content_margin_left = 14
	hover.content_margin_right = 14
	var normal := StyleBoxEmpty.new()
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.pressed.connect(func(): picked.emit(action))
	return b
