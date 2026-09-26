class_name Hud
extends GlowPanel
## The top HUD as a player card: portrait, name, level and XP; health, energy
## and happiness bars with their values; cash and bank. It redraws from
## Session.vitals whenever a view or a realtime notice updates them.

signal bell_pressed
signal avatar_pressed
signal menu_pressed

var _portrait: Portrait
var _name: Label
var _level: Label
var _xp: StatBar
var _cash: ResourceChip
var _bank: ResourceChip
var _energy: ResourceChip
var _health: ResourceChip
var _bell: Button


func _init() -> void:
	super._init()
	radius = 0
	shadow = 16
	top_color = Color("#16243A")
	bottom_color = Color("#0F1A2B")
	border_color = Color("#2B4468")
	highlight = Color(0, 0, 0, 0)
	padding = 14


func _ready() -> void:
	var root := UI.vbox(10)
	add_child(root)

	var top := UI.hbox(12)
	root.add_child(top)
	top.add_child(_icon_button("ln_menu", func(): menu_pressed.emit()))
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(76, 76)
	_portrait.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: avatar_pressed.emit())
	top.add_child(_portrait)

	var who := UI.vbox(2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	_name = UI.label("", "HeadLabel")
	_name.add_theme_font_size_override("font_size", 26)
	_name.clip_text = true
	who.add_child(_name)
	_level = UI.label("", "SmallLabel")
	_level.add_theme_color_override("font_color", AppTheme.col("cyan"))
	who.add_child(_level)
	_xp = StatBar.new()
	_xp.icon_name = ""
	_xp.compact = true
	_xp.show_text = false
	_xp.custom_minimum_size = Vector2(60, 8)
	_xp.color = AppTheme.col("blue")
	who.add_child(_xp)
	top.add_child(who)

	_bell = _icon_button("ln_messages", func(): bell_pressed.emit())
	_bell.draw.connect(_draw_dot)
	top.add_child(_bell)

	# resource chips (asset keys resolve to badge icons in the library)
	var chips := GridContainer.new()
	chips.columns = 4
	chips.add_theme_constant_override("h_separation", 8)
	chips.add_theme_constant_override("v_separation", 8)
	root.add_child(chips)
	_cash = ResourceChip.make("res:cash", false, I18n.money_short)
	_bank = ResourceChip.make("res:bank", false, I18n.money_short)
	_energy = ResourceChip.make("stat:energy", true, I18n.num)
	_health = ResourceChip.make("stat:health", true, I18n.num)
	for c in [_cash, _bank, _energy, _health]:
		chips.add_child(c)

	Session.changed.connect(refresh)
	I18n.changed.connect(func(_l): refresh())
	refresh()


func _icon_button(icon_name: String, fn: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = "GhostButton"
	b.icon = AppTheme.icon(icon_name)
	b.expand_icon = true
	b.custom_minimum_size = Vector2(76, 76)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_constant_override("icon_max_width", 36)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, AppTheme.kitbox("slot", 10, 10))
	b.pressed.connect(fn)
	Fx.press_feedback(b)
	return b


func _draw_dot() -> void:
	if Session.unread > 0:
		var p := Vector2(_bell.size.x * 0.76, _bell.size.y * 0.24)
		_bell.draw_circle(p, 11, AppTheme.col("night"))
		_bell.draw_circle(p, 8, AppTheme.col("red"))


func refresh() -> void:
	var v := Session.vitals
	_portrait.set_avatar(str(v.get("avatar", "")))
	_name.text = str(v.get("name", Session.player.get("name", "")))
	var lvl := int(v.get("level", 0))
	var rank = v.get("rank")
	var rank_name := TextIcons.strip(str(rank.get("name", ""))) if rank is Dictionary else ""
	_level.text = I18n.t("profile.level", {"level": I18n.num(lvl)}) + ("  ·  " + rank_name if rank_name != "" else "")
	var nxt := int(v.get("next_level_xp", 0))
	_xp.visible = nxt > 0
	_xp.set_value(int(v.get("xp", 0)), maxi(nxt, 1))
	_cash.set_amount(int(v.get("cash", 0)))
	_bank.set_amount(int(v.get("bank", 0)))
	_energy.set_amount(int(v.get("energy", 0)), int(v.get("max_energy", 100)))
	_health.set_amount(int(v.get("health", 0)), int(v.get("max_health", 100)))
	_bell.queue_redraw()
