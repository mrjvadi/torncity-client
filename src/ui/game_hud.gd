class_name GameHud
extends Control
## The phone HUD in the home screen's design (proto/home_proto.gd): a lit top
## bar with the avatar in its level ring, the name, rank and XP, cash and bank
## on recessed pills; under it the stat row, each bar with its struck icon and
## the time it fills. Drawn on a 720-wide design canvas centred in the width;
## a left-to-right reader gets it mirrored. Redraws from Session.vitals.

signal bell_pressed
signal avatar_pressed
signal menu_pressed

const W := 720.0
const H := 250.0

var _canvas: Control
var _xp_ring: ColorRect
var _xp_bar: ColorRect
var _level: Label
var _name: Label
var _rank: Label
var _cash: Label
var _bank: Label
var _bars := {}
var _bell_count: Control
var _rtl := true


func _ready() -> void:
	Kit.fonts()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, H)
	resized.connect(_place)
	# a shade under the chrome, so the numbers read over a bright city
	var shade := Kit.fade(self, Rect2(), Color(Kit.INK, 0.8), Color(Kit.INK, 0.0))
	shade.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shade.offset_bottom = 330
	Session.changed.connect(refresh)
	I18n.changed.connect(func(_l): _build())
	_build()


## Kept for the shell: the phone HUD has no sidebar form.
func set_sidebar(_on: bool) -> void:
	pass


func _build() -> void:
	if _canvas:
		_canvas.queue_free()
	_rtl = I18n.is_rtl()
	_bars.clear()
	_canvas = Control.new()
	_canvas.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.size = Vector2(W, H)
	add_child(_canvas)
	_top_bar()
	_stat_row()
	_place()
	refresh()


func _place() -> void:
	if _canvas:
		_canvas.position = Vector2((size.x - W) / 2.0, 0)


## A rect in design pixels, mirrored for a left-to-right reader.
func _r(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(x if _rtl else W - x - w, y, w, h)


func _align_end() -> int:
	return HORIZONTAL_ALIGNMENT_RIGHT if _rtl else HORIZONTAL_ALIGNMENT_LEFT


func _top_bar() -> void:
	var bar := Kit.frame(_canvas, Rect2(-24, -40, 768, 188), 44.0, Color(0.10, 0.12, 0.27, 0.96), Color(0.04, 0.05, 0.13, 0.96), Kit.GOLD, 0.06)
	(bar.material as ShaderMaterial).set_shader_parameter("glow", Color(Kit.LAPIS, 0.35))
	# the avatar on a teal plate, the XP ring around it, a level gem
	_xp_ring = Kit.ring(_canvas, _r(582, 8, 128, 128), 0.0, Kit.FIROUZEH)
	Kit.plate(_canvas, _r(592, 18, 108, 108), Color("#0E5E58"), Kit.GOLD)
	Kit.emboss(_canvas, "person", _r(606, 26, 80, 88), "teal")
	var gem := Kit.frame(_canvas, _r(566, 96, 50, 44), 13.0, Color("#3A2A8A"), Color("#1A1050"), Kit.GOLD, 0.0, 3.0)
	_level = Kit.glabel(Kit.inner(gem), "", 28, "#FFFFFF", "#FFD66B", Rect2(0, 0, 50, 44), HORIZONTAL_ALIGNMENT_CENTER)
	Kit.hit(_canvas, _r(566, 8, 150, 136), func(): avatar_pressed.emit())
	_name = Kit.glabel(_canvas, "", 36, "#FFFFFF", "#BFEFFF", _r(290, 18, 284, 50), _align_end(), 7)
	_rank = Kit.label(_canvas, "", Kit.body_font, 17, Color("#C9D2EE"), _r(290, 66, 284, 28), _align_end(), 3)
	_xp_bar = Kit.bar(_canvas, _r(386, 100, 170, 14), 0.0, Kit.FIROUZEH)
	# money: cash and bank, each a recessed pill with its object on the end
	var cash := Kit.frame(_canvas, _r(22, 22, 236, 56), 28.0, Color(0.02, 0.03, 0.08, 0.95), Color(0.05, 0.06, 0.14, 0.95), Color(Kit.GOLD, 0.9), 0.0, 2.5)
	(cash.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_cash = Kit.glabel(Kit.inner(cash), "", 30, "#FFF6C8", "#FFB21F", Rect2(48, 2, 136, 52) if _rtl else Rect2(52, 2, 136, 52), _align_end())
	Kit.emboss(_canvas, "coins", _r(198, 4, 90, 90), "gold")
	var plus := Kit.slab(_canvas, _r(30, 30, 40, 40), Kit.LEAF.lightened(0.3), Kit.LEAF.darkened(0.1), Kit.LEAF.darkened(0.55), 12.0, 4.0)
	Kit.label(plus, "+", Kit.display_font, 30, Color.WHITE, Rect2(0, -6, 40, 44), HORIZONTAL_ALIGNMENT_CENTER, 4)
	var bank := Kit.frame(_canvas, _r(22, 88, 236, 44), 22.0, Color(0.02, 0.03, 0.08, 0.95), Color(0.05, 0.06, 0.14, 0.95), Color("#9FB4FF", 0.7), 0.0, 2.0)
	(bank.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_bank = Kit.glabel(Kit.inner(bank), "", 24, "#EAF1FF", "#8FB0FF", Rect2(24, 0, 156, 44) if _rtl else Rect2(56, 0, 156, 44), _align_end(), 5)
	Kit.emboss(_canvas, "bank", _r(206, 76, 68, 68), "sapphire")
	Kit.hit(_canvas, _r(10, 10, 280, 136), func(): Game.run("bank.show"))


func _stat_row() -> void:
	# two bars on the reading side; the bell and the menu on the far end
	var stats := [
		["energy", "energy", Kit.SAFFRON, "amber"],
		["health", "health", Kit.LEAF, "emerald"],
	]
	for i in stats.size():
		var d: Array = stats[i]
		var x := 500.0 - i * 238.0
		var b := Kit.bar(_canvas, _r(x, 178, 176, 32), 0.0, d[2])
		var lbl := Kit.label(b, "", Kit.display_font, 22, Color.WHITE, Rect2(0, -1, 140, 34) if _rtl else Rect2(36, -1, 140, 34), HORIZONTAL_ALIGNMENT_CENTER, 5)
		Kit.emboss(_canvas, d[1], _r(x + 138, 156, 76, 76), d[3])
		var chip := Kit.frame(_canvas, _r(x + 22, 214, 110, 28), 14.0, Color(0.02, 0.03, 0.08, 0.85), Color(0.02, 0.03, 0.08, 0.85), Color(d[2], 0.8), 0.0, 2.0)
		(chip.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		var when := Kit.label(Kit.inner(chip), "", Kit.body_bold, 15, Color("#FFD66B"), Rect2(0, 0, 110, 28), HORIZONTAL_ALIGNMENT_CENTER)
		_bars[d[0]] = {"bar": b, "label": lbl, "chip": chip, "when": when}
	# the notification bell and the menu, each on a plate
	_plate_button("inbox", "sapphire", _r(118, 162, 76, 76), func(): bell_pressed.emit())
	_bell_count = Kit.count(_canvas, _r(114, 158, 30, 30), 0)
	_plate_button("menu", "steel", _r(26, 162, 76, 76), func(): menu_pressed.emit())


func _plate_button(icon: String, pal: String, r: Rect2, fn: Callable) -> void:
	Kit.plate(_canvas, r, Color("#18204A"), Kit.GOLD)
	Kit.emboss(_canvas, icon, Rect2(r.position + Vector2(8, 6), r.size - Vector2(16, 16)), pal)
	Kit.hit(_canvas, r, fn)


func refresh() -> void:
	if _level == null:
		return
	var v := Session.vitals
	var nxt := int(v.get("next_level_xp", 0))
	var frac := float(v.get("xp", 0)) / float(nxt) if nxt > 0 else 0.0
	(_xp_ring.material as ShaderMaterial).set_shader_parameter("value", clampf(frac, 0.0, 1.0))
	Kit.set_bar(_xp_bar, frac)
	_level.text = I18n.num(int(v.get("level", 0)))
	_name.text = str(v.get("name", Session.player.get("name", "")))
	var rank = v.get("rank")
	_rank.text = TextIcons.strip(str(rank.get("name", ""))) if rank is Dictionary else ""
	_cash.text = I18n.num(int(v.get("cash", 0)))
	_bank.text = I18n.num(int(v.get("bank", 0)))
	_set_stat("energy", int(v.get("energy", 0)), int(v.get("max_energy", 100)), int(v.get("energy_full_in_seconds", 0)))
	_set_stat("health", int(v.get("health", 0)), int(v.get("max_health", 100)), 0)
	_bell_count.visible = Session.unread > 0
	var lbl: Label = _bell_count.get_child(0)
	lbl.text = str(Session.unread) if Session.unread < 100 else "99+"


func _set_stat(key: String, value: int, max_v: int, full_in: int) -> void:
	var s: Dictionary = _bars[key]
	var full := max_v > 0 and value >= max_v
	Kit.set_bar(s["bar"], float(value) / float(max_v) if max_v > 0 else 0.0, full)
	(s["label"] as Label).text = I18n.num(value) + "/" + I18n.num(max_v)
	var chip: Control = s["chip"]
	chip.visible = full_in > 0 and not full
	if chip.visible:
		(s["when"] as Label).text = I18n.t("hud.full_at", {"time": _clock_in(full_in)})


## The Tehran wall-clock time `seconds` from now.
static func _clock_in(seconds: int) -> String:
	var t := int(Time.get_unix_time_from_system()) + seconds + 12600
	var d := Time.get_datetime_dict_from_unix_time(t)
	return Fmt.clock(int(d["hour"]), int(d["minute"]), I18n.lang)
