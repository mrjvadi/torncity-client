class_name Hud
extends GlowPanel
## The top HUD: who you are, your money and your vitals. It redraws from
## Session.vitals whenever any view or notice updates them.

signal bell_pressed
signal avatar_pressed

var _avatar: AvatarBadge
var _name: Label
var _rank: Label
var _where: Label
var _cash: Label
var _bank: Label
var _energy: StatBar
var _health: StatBar
var _needs := {}
var _bell: Button
var _dot: Control
var _last_cash := -1
var _last_bank := -1


func _init() -> void:
	super._init()
	radius = 0
	shadow = 18
	top_color = Color("#2A3563")
	bottom_color = Color("#1E2746")
	border_color = Color(1, 1, 1, 0.06)
	padding = 16


func _ready() -> void:
	var root := UI.vbox(10)
	add_child(root)

	var top := UI.hbox(14)
	root.add_child(top)
	_avatar = AvatarBadge.new()
	_avatar.diameter = 96
	var av_btn := Button.new()
	av_btn.flat = true
	av_btn.custom_minimum_size = Vector2(96, 96)
	av_btn.focus_mode = Control.FOCUS_NONE
	av_btn.add_child(_avatar)
	av_btn.pressed.connect(func(): avatar_pressed.emit())
	top.add_child(av_btn)

	var who := UI.vbox(2)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name = UI.label("", "HeadLabel")
	_name.clip_text = true
	who.add_child(_name)
	var tags := UI.hbox(8)
	_rank = UI.label("", "SmallLabel")
	_rank.add_theme_color_override("font_color", AppTheme.col("saffron"))
	_where = UI.label("", "DimLabel")
	_where.clip_text = true
	_where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tags.add_child(UI.icon("rank", 26))
	tags.add_child(_rank)
	tags.add_child(UI.icon("pin", 26))
	tags.add_child(_where)
	who.add_child(tags)
	top.add_child(who)

	_bell = Button.new()
	_bell.flat = true
	_bell.icon = AppTheme.icon("bell")
	_bell.expand_icon = true
	_bell.custom_minimum_size = Vector2(72, 72)
	_bell.focus_mode = Control.FOCUS_NONE
	_bell.pressed.connect(func(): bell_pressed.emit())
	Fx.press_feedback(_bell)
	_dot = _bell
	_bell.draw.connect(_draw_dot)
	top.add_child(_bell)

	var money := UI.hbox(10)
	root.add_child(money)
	var cash_box := _money_pill("cash")
	_cash = cash_box.get_meta("label")
	var bank_box := _money_pill("bank")
	_bank = bank_box.get_meta("label")
	money.add_child(cash_box)
	money.add_child(bank_box)

	var bars := UI.hbox(16)
	root.add_child(bars)
	_energy = _bar("energy", AppTheme.col("saffron"))
	_health = _bar("health", AppTheme.col("pomegranate"))
	bars.add_child(_energy)
	bars.add_child(_health)

	var needs := UI.hbox(12)
	root.add_child(needs)
	for n in [["hunger", "brick", true], ["sleep", "violet", true], ["stress", "rose", true], ["happiness", "leaf", false]]:
		var b := _bar(n[0], AppTheme.col(n[1]), true)
		b.invert = n[2]
		_needs[n[0]] = b
		needs.add_child(b)

	Session.changed.connect(refresh)
	I18n.changed.connect(func(_l): refresh())
	refresh()


func _draw_dot() -> void:
	if Session.unread > 0:
		var c := Vector2(_bell.size.x * 0.7, _bell.size.y * 0.24)
		_bell.draw_circle(c, 11, AppTheme.col("night"))
		_bell.draw_circle(c, 8, AppTheme.col("pomegranate"))


func _money_pill(icon_name: String) -> PanelContainer:
	var l := UI.label("", "MoneyLabel")
	l.add_theme_font_size_override("font_size", 28)
	if icon_name == "bank":
		l.add_theme_color_override("font_color", AppTheme.col("sky"))
	var h := UI.hbox(8, [UI.icon(icon_name, 36), l])
	var p := UI.panel(h, "ChipPanel")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.set_meta("label", l)
	return p


func _bar(icon_name: String, c: Color, compact := false) -> StatBar:
	var b := StatBar.new()
	b.icon_name = icon_name
	b.color = c
	b.compact = compact
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func refresh() -> void:
	var v := Session.vitals
	_avatar.set_avatar(str(v.get("avatar", "")), str(v.get("name", "")), int(v.get("level", 0)))
	_name.text = str(v.get("name", Session.player.get("name", "")))
	var rank = v.get("rank")
	_rank.text = TextIcons.strip(str(rank.get("name", ""))) if rank is Dictionary else ""
	_rank.visible = _rank.text != ""
	_where.text = I18n.name_of("city", Session.city_code, str(v.get("city", "")))
	var cash := int(v.get("cash", 0))
	var bank := int(v.get("bank", 0))
	Fx.roll_number(_cash, _last_cash if _last_cash >= 0 else cash, cash, I18n.money_short)
	Fx.roll_number(_bank, _last_bank if _last_bank >= 0 else bank, bank, I18n.money_short)
	if _last_cash >= 0 and cash > _last_cash:
		Fx.pulse(_cash)
	_last_cash = cash
	_last_bank = bank
	var e := int(v.get("energy", 0))
	var me := int(v.get("max_energy", 100))
	_energy.set_value(e, me, I18n.of(e, me))
	var h := int(v.get("health", 0))
	var mh := int(v.get("max_health", 100))
	_health.set_value(h, mh, I18n.of(h, mh))
	var needs = v.get("needs")
	if needs is Dictionary:
		for k in _needs:
			_needs[k].set_value(float(needs.get(k, 0)), 100.0, I18n.num(int(needs.get(k, 0))))
	_dot.queue_redraw()
