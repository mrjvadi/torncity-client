class_name Hud
extends GlassPanel
## The HUD, floating on glass: the avatar with its level ring, name and rank,
## the notification bell with its unread count and the menu; under them the
## resource chips (cash, bank, energy, health), numbers counting up as they
## change. Redraws from Session.vitals.

signal bell_pressed
signal avatar_pressed
signal menu_pressed

var _avatar: AvatarRing
var _name: Label
var _rank: Label
var _cash: ResourceChip
var _bank: ResourceChip
var _energy: ResourceChip
var _health: ResourceChip
var _bell: RoundIconButton
var _menu: RoundIconButton
var _chips: GridContainer


func _init() -> void:
	radius = 26
	pad = Vector4(14, 12, 14, 12)


func _ready() -> void:
	super._ready()
	var root := UI.vbox(10)
	add_child(root)
	var top := UI.hbox(12)
	root.add_child(top)
	_avatar = AvatarRing.new()
	_avatar.custom_minimum_size = Vector2(78, 78)
	_avatar.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: avatar_pressed.emit())
	top.add_child(_avatar)
	var who := UI.vbox(0)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	_name = UI.label("", "HeadLabel")
	_name.add_theme_font_size_override("font_size", 27)
	_name.clip_text = true
	who.add_child(_name)
	_rank = UI.label("", "DimLabel")
	_rank.add_theme_font_size_override("font_size", 19)
	_rank.clip_text = true
	who.add_child(_rank)
	top.add_child(who)
	_bell = RoundIconButton.make(AssetLib.icon("action:notifications"), func(): bell_pressed.emit())
	top.add_child(_bell)
	_menu = RoundIconButton.make(AppTheme.icon("ln_menu"), func(): menu_pressed.emit())
	top.add_child(_menu)

	_chips = GridContainer.new()
	_chips.columns = 4
	_chips.add_theme_constant_override("h_separation", 8)
	_chips.add_theme_constant_override("v_separation", 8)
	root.add_child(_chips)
	_cash = ResourceChip.make("res:cash", false, I18n.money_short)
	_bank = ResourceChip.make("res:bank", false, I18n.money_short)
	_energy = ResourceChip.make("stat:energy", true, I18n.num)
	_health = ResourceChip.make("stat:health", true, I18n.num)
	for c in [_cash, _bank, _energy, _health]:
		_chips.add_child(c)
	Session.changed.connect(refresh)
	I18n.changed.connect(func(_l): refresh())
	refresh()


## In the desktop sidebar the card is narrow: two chips per row.
func set_sidebar(on: bool) -> void:
	if _chips:
		_chips.columns = 2 if on else 4


func refresh() -> void:
	var v := Session.vitals
	var nxt := int(v.get("next_level_xp", 0))
	var frac := float(v.get("xp", 0)) / float(nxt) if nxt > 0 else 0.0
	_avatar.set_avatar(str(v.get("avatar", "")), int(v.get("level", 0)), frac)
	_name.text = str(v.get("name", Session.player.get("name", "")))
	var rank = v.get("rank")
	_rank.text = TextIcons.strip(str(rank.get("name", ""))) if rank is Dictionary else ""
	_cash.set_amount(int(v.get("cash", 0)))
	_bank.set_amount(int(v.get("bank", 0)))
	_energy.set_amount(int(v.get("energy", 0)), int(v.get("max_energy", 100)))
	_health.set_amount(int(v.get("health", 0)), int(v.get("max_health", 100)))
	_bell.count = Session.unread
