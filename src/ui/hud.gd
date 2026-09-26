class_name Hud
extends GlassPanel
## The HUD, floating on glass. On a phone it is one compact row: the avatar
## with its level ring, the three numbers a player checks all the time (cash,
## energy, health — counting up as they change), the notification bell with
## its unread count and the menu. The name, rank and bank live on the profile.
## In the desktop sidebar it becomes a player card: avatar, name and rank,
## bell, and the four numbers (with the bank) two per row.
## Redraws from Session.vitals.

signal bell_pressed
signal avatar_pressed
signal menu_pressed

var _avatar: AvatarRing
var _who: VBoxContainer
var _name: Label
var _rank: Label
var _cash: ResourceChip
var _bank: ResourceChip
var _energy: ResourceChip
var _health: ResourceChip
var _bell: RoundIconButton
var _menu: RoundIconButton
var _chips: GridContainer
var _top: HBoxContainer
var _root: VBoxContainer
var _sidebar := false


func _init() -> void:
	radius = 28
	pad = Vector4(12, 10, 12, 10)


func _ready() -> void:
	super._ready()
	_root = UI.vbox(12)
	add_child(_root)
	_top = UI.hbox(10)
	_root.add_child(_top)
	_avatar = AvatarRing.new()
	_avatar.custom_minimum_size = Vector2(68, 68)
	_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_avatar.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: avatar_pressed.emit())
	_who = UI.vbox(0)
	_who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_who.alignment = BoxContainer.ALIGNMENT_CENTER
	_name = UI.label("", "HeadLabel")
	_name.add_theme_font_size_override("font_size", 27)
	_name.clip_text = true
	_who.add_child(_name)
	_rank = UI.label("", "DimLabel")
	_rank.add_theme_font_size_override("font_size", 19)
	_rank.clip_text = true
	_who.add_child(_rank)

	_chips = GridContainer.new()
	_chips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chips.add_theme_constant_override("h_separation", 8)
	_chips.add_theme_constant_override("v_separation", 8)
	_cash = ResourceChip.make("res:cash", false, I18n.money_short)
	_bank = ResourceChip.make("res:bank", false, I18n.money_short)
	_energy = ResourceChip.make("stat:energy", true, I18n.num)
	_health = ResourceChip.make("stat:health", true, I18n.num)
	for c in [_cash, _bank, _energy, _health]:
		_chips.add_child(c)

	_bell = RoundIconButton.make(AssetLib.icon("action:notifications"), func(): bell_pressed.emit(), 58.0)
	_menu = RoundIconButton.make(AppTheme.icon("ln_menu"), func(): menu_pressed.emit(), 58.0)
	_arrange()
	Session.changed.connect(refresh)
	I18n.changed.connect(func(_l): refresh())
	refresh()


## In the desktop sidebar the HUD is a player card; on a phone, one row.
func set_sidebar(on: bool) -> void:
	_sidebar = on
	if _root:
		_arrange()


func _arrange() -> void:
	for n in [_avatar, _who, _chips, _bell, _menu]:
		if n.get_parent():
			n.get_parent().remove_child(n)
	if _sidebar:
		for n in [_avatar, _who, _bell]:
			_top.add_child(n)
		_root.add_child(_chips)
		_chips.columns = 2
		_bank.visible = true
		_who.visible = true
	else:
		for n in [_avatar, _chips, _bell, _menu]:
			_top.add_child(n)
		_chips.columns = 3
		_bank.visible = false
		_who.visible = false


func _notification(what: int) -> void:
	# pieces the current layout does not use are out of the tree: free them too
	if what == NOTIFICATION_PREDELETE:
		for n in [_avatar, _who, _chips, _bell, _menu]:
			if is_instance_valid(n) and n.get_parent() == null:
				n.free()


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
