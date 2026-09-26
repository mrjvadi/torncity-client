class_name SideMenu
extends GlowPanel
## The side menu: the server's main menu (Session.hub_actions — the profile
## screen's actions), one row per action. The client adds only an icon, chosen
## by the command's domain (AssetLib.action_icon), and a Settings row.

signal picked(action: Dictionary)

var _rows: VBoxContainer
var _header: Control
var _avatar: AvatarRing
var _name: Label
var _rank: Label


func _init() -> void:
	super._init()
	radius = AppTheme.R_CARD
	shadow = 24
	padding = 14


func _ready() -> void:
	var col := UI.vbox(8)
	add_child(col)
	# the player, on top of the phone drawer (the desktop sidebar has the HUD card)
	_avatar = AvatarRing.new()
	_avatar.custom_minimum_size = Vector2(76, 76)
	_name = UI.label("", "HeadLabel")
	_name.clip_text = true
	_rank = UI.label("", "DimLabel")
	var who := UI.vbox(2, [_name, _rank])
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := ColorRect.new()
	line.color = AppTheme.col("stroke")
	line.custom_minimum_size = Vector2(0, 1)
	_header = UI.vbox(14, [UI.margin(UI.hbox(16, [_avatar, who]), 10, 8, 10, 0), line])
	_header.visible = false
	col.add_child(_header)
	Session.changed.connect(_refresh_header)
	_refresh_header()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_rows = UI.vbox(4)
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows)
	build()
	Session.hub_changed.connect(build)
	I18n.changed.connect(func(_l): build())


func show_header(on: bool) -> void:
	if _header:
		_header.visible = on


func _refresh_header() -> void:
	var v := Session.vitals
	var nxt := int(v.get("next_level_xp", 0))
	_avatar.set_avatar(str(v.get("avatar", "")), int(v.get("level", 0)), float(v.get("xp", 0)) / float(nxt) if nxt > 0 else 0.0)
	_name.text = str(v.get("name", Session.player.get("name", "")))
	var rank = v.get("rank")
	_rank.text = TextIcons.strip(str(rank.get("name", ""))) if rank is Dictionary else ""


## The direction of the menu's rows, independent of the panel's own (the
## phone drawer lays the panel out LTR to place it).
func content_direction(d: int) -> void:
	for c in get_children():
		if c is Control:
			c.layout_direction = d


func build() -> void:
	UI.clear(_rows)
	# the inventory is not a tab any more: first in the menu
	var has_inv := Session.hub_actions.any(func(a): return a is Dictionary and str(a.get("command", "")) == "inventory.show")
	if not has_inv:
		_rows.add_child(_row("ln_inventory", I18n.t("nav.inventory"), {"command": "inventory.show"}))
	for a in Session.hub_actions:
		if a is Dictionary:
			_rows.add_child(_row(AssetLib.action_icon(str(a.get("command", ""))), TextIcons.strip(str(a.get("label", ""))), a))
	var line := ColorRect.new()
	line.color = AppTheme.col("stroke")
	line.custom_minimum_size = Vector2(0, 1)
	_rows.add_child(UI.margin(line, 14, 8, 14, 8))
	_rows.add_child(_row("ln_settings", I18n.t("settings.app"), {"command": "@settings"}))


func _row(icon_name: String, label: String, action: Dictionary) -> Button:
	var b := Button.new()
	b.theme_type_variation = "NavButton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 66)
	b.icon = AppTheme.icon(icon_name)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 30)
	b.add_theme_constant_override("h_separation", 16)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", AppTheme.col("text"))
	b.add_theme_color_override("font_hover_color", AppTheme.col("text"))
	b.add_theme_color_override("icon_normal_color", AppTheme.col("text_2"))
	b.add_theme_color_override("icon_hover_color", AppTheme.col("primary"))
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.text = label
	var hover := StyleBoxFlat.new()
	hover.bg_color = AppTheme.col("surface_2")
	hover.set_corner_radius_all(AppTheme.R_SMALL)
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
