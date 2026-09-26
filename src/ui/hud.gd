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
var _cash: Label
var _bank: Label
var _health: StatBar
var _energy: StatBar
var _happy: StatBar
var _bell: Button
var _last_cash := -1
var _last_bank := -1


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

	var top := UI.hbox(14)
	root.add_child(top)
	top.add_child(_icon_button("ln_menu", func(): menu_pressed.emit()))
	_portrait = Portrait.new()
	_portrait.custom_minimum_size = Vector2(104, 104)
	_portrait.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: avatar_pressed.emit())
	top.add_child(_portrait)

	var who := UI.vbox(4)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name = UI.label("", "HeadLabel")
	_name.clip_text = true
	who.add_child(_name)
	_level = UI.label("", "SmallLabel")
	_level.add_theme_color_override("font_color", AppTheme.col("cyan"))
	who.add_child(_level)
	_xp = StatBar.new()
	_xp.icon_name = ""
	_xp.compact = true
	_xp.show_text = false
	_xp.color = AppTheme.col("blue")
	who.add_child(_xp)
	top.add_child(who)

	_bell = _icon_button("ln_messages", func(): bell_pressed.emit())
	_bell.draw.connect(_draw_dot)
	top.add_child(_bell)

	var bars := GridContainer.new()
	bars.columns = 1
	bars.add_theme_constant_override("v_separation", 6)
	root.add_child(bars)
	_health = _bar("health", AppTheme.col("red"))
	_energy = _bar("energy", AppTheme.col("yellow"))
	_happy = _bar("happiness", AppTheme.col("green"))
	for b in [_health, _energy, _happy]:
		bars.add_child(b)

	var money := UI.hbox(10)
	root.add_child(money)
	var c := _money_pill("cash", "yellow")
	_cash = c.get_meta("label")
	var k := _money_pill("bank", "cyan")
	_bank = k.get_meta("label")
	money.add_child(c)
	money.add_child(k)

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


func _money_pill(icon_name: String, color: String) -> PanelContainer:
	var l := UI.label("", "MoneyLabel")
	l.add_theme_font_size_override("font_size", 27)
	l.add_theme_color_override("font_color", AppTheme.col(color))
	var h := UI.hbox(8, [UI.icon(icon_name, 36), l])
	var p := UI.panel(h, "InsetPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.set_meta("label", l)
	return p


func _bar(icon_name: String, c: Color) -> StatBar:
	var b := StatBar.new()
	b.icon_name = icon_name
	b.color = c
	b.label_text = I18n.t("stat." + icon_name)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = 36
	return b


func refresh() -> void:
	var v := Session.vitals
	_portrait.set_avatar(str(v.get("avatar", "")))
	_name.text = str(v.get("name", Session.player.get("name", "")))
	var lvl := int(v.get("level", 0))
	var rank = v.get("rank")
	var rank_name := TextIcons.strip(str(rank.get("name", ""))) if rank is Dictionary else ""
	_level.text = I18n.t("profile.level", {"level": lvl}) + ("  ·  " + rank_name if rank_name != "" else "")
	var xp := int(v.get("xp", 0))
	var nxt := int(v.get("next_level_xp", 0))
	_xp.visible = nxt > 0
	_xp.set_value(xp, maxi(nxt, 1))
	var cash := int(v.get("cash", 0))
	var bank := int(v.get("bank", 0))
	Fx.roll_number(_cash, _last_cash if _last_cash >= 0 else cash, cash, I18n.money)
	Fx.roll_number(_bank, _last_bank if _last_bank >= 0 else bank, bank, I18n.money)
	if _last_cash >= 0 and cash > _last_cash:
		Fx.pulse(_cash)
	_last_cash = cash
	_last_bank = bank
	for pair in [[_health, "health", "max_health"], [_energy, "energy", "max_energy"]]:
		var cur := int(v.get(pair[1], 0))
		var mx := int(v.get(pair[2], 100))
		pair[0].label_text = I18n.t("stat." + pair[1])
		pair[0].set_value(cur, mx, I18n.digits("%d/%d" % [cur, mx]))
	var needs = v.get("needs")
	var h := int(needs.get("happiness", 0)) if needs is Dictionary else 0
	_happy.label_text = I18n.t("stat.happiness")
	_happy.set_value(h, 100, I18n.digits("%d/100" % h))
	_bell.queue_redraw()
