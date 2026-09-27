class_name GameDock
extends Control
## The dock in the home screen's design (proto/home_proto.gd): one solid bar
## of five tabs, the city in the middle. The active tab widens and rises out
## of the bar on a lit tile and names itself; the others are struck icons
## with a quiet caption and, where something waits, a count. Drawn on a
## 720-wide design canvas centred in the width, mirrored for a left-to-right
## reader. Same face to the shell as BottomNav: tab_pressed, select.

signal tab_pressed(tab: String)

const W := 720.0
const H := 168.0
## Reading order: me, activity, city, economy, society.
const DOCK := [
	{"key": "profile", "icon": "person", "label": "nav.me"},
	{"key": "activity", "icon": "activity", "label": "nav.activity"},
	{"key": "map", "icon": "city", "label": "nav.city"},
	{"key": "market", "icon": "market", "label": "nav.economy"},
	{"key": "society", "icon": "society", "label": "nav.society"},
]

var active := "map"
var _canvas: Control


func _ready() -> void:
	Kit.fonts()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, H)
	resized.connect(_place)
	var shade := Kit.fade(self, Rect2(), Color(Kit.INK, 0.0), Color(Kit.INK, 0.9))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.offset_top = -230
	I18n.changed.connect(func(_l): _build())
	Session.changed.connect(_build)
	_build()


func select(tab: String) -> void:
	var known := false
	for t in DOCK:
		known = known or t["key"] == tab
	if not known or tab == active:
		return
	active = tab
	_build()


func _place() -> void:
	if _canvas:
		_canvas.position = Vector2((size.x - W) / 2.0, 0)


func _build() -> void:
	if _canvas:
		_canvas.queue_free()
	var rtl := I18n.is_rtl()
	_canvas = Control.new()
	_canvas.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.size = Vector2(W, H)
	add_child(_canvas)
	var bar := Kit.frame(_canvas, Rect2(-24, 38, 768, 170), 10.0, Color(0.09, 0.11, 0.24, 0.99), Color(0.03, 0.04, 0.10, 0.99), Kit.GOLD, 0.05, 3.0)
	(bar.material as ShaderMaterial).set_shader_parameter("shadow", 0.7)
	var active_i := 2
	for i in DOCK.size():
		if DOCK[i]["key"] == active:
			active_i = i
	var x := W
	for i in DOCK.size():
		var t: Dictionary = DOCK[i]
		var w := 208.0 if i == active_i else 128.0
		x -= w
		var tx := x if rtl else W - x - w
		var cx := tx + w / 2.0
		if i == active_i:
			var tile := Kit.frame(_canvas, Rect2(tx + 6, 0, w - 12, 176), 24.0, Color("#3A63D0"), Color("#15286A"), Kit.GOLD, 0.06, 3.0)
			var tm := tile.material as ShaderMaterial
			tm.set_shader_parameter("glow", Color("#8FB4FF", 0.55))
			tm.set_shader_parameter("shadow", 0.8)
			Kit.emboss(_canvas, t["icon"], Rect2(cx - 54, -2, 108, 108), "gold")
			Kit.glabel(_canvas, I18n.t(t["label"]), 28, "#FFFFFF", "#FFD66B", Rect2(tx, 102, w, 44), HORIZONTAL_ALIGNMENT_CENTER, 7)
		else:
			var ic := Kit.emboss(_canvas, t["icon"], Rect2(cx - 40, 50, 80, 80), "steel")
			ic.modulate = Color(0.78, 0.82, 0.95)
			Kit.label(_canvas, I18n.t(t["label"]), Kit.display_font, 19, Color("#9EA8CC"), Rect2(tx, 124, w, 32), HORIZONTAL_ALIGNMENT_CENTER, 4)
			var n := _count_for(t["key"])
			if n > 0:
				Kit.count(_canvas, Rect2(cx + 14, 48, 32, 32), n)
		# a groove between neighbours, skipped beside the raised tile
		if i < DOCK.size() - 1 and i != active_i and i + 1 != active_i:
			var gx := x - 1 if rtl else W - x - 1
			var g := ColorRect.new()
			g.position = Vector2(gx, 60)
			g.size = Vector2(2, 92)
			g.color = Color(0, 0, 0, 0.45)
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_canvas.add_child(g)
		var key: String = t["key"]
		Kit.hit(_canvas, Rect2(tx, 20, w, H - 20), func(): tab_pressed.emit(key))
	_place()


func _count_for(key: String) -> int:
	return Session.unread if key == "society" else 0
