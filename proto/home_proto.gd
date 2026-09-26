extends Node
## A design prototype, not the game: the home screen as a game would draw it.
## The city at dusk in 3D is the home; the HUD floats over it, timers and
## "ready" states hang over the buildings they belong to (the Hay Day
## pattern), and a dock with a raised action button sits under the thumb.
## Everything is placeholder data. Run it alone:
##   godot --path . res://proto/home_proto.tscn [-- --shot=out.png]

const ART := "res://proto/art/"
const W := 720.0
const H := 1280.0

const GOLD := Color("#F2C255")
const FIROUZEH := Color("#2BC4B2")
const LAPIS := Color("#3552C8")
const SAFFRON := Color("#F5A623")
const ANAR := Color("#E5484D")
const LEAF := Color("#4CC47E")
const VIOLET := Color("#8E6CF0")
const INK := Color("#070A14")

var display_font: Font
var body_font: Font
var body_bold: Font
var cam: Camera3D
var ui: Control
var world: Node3D
var bubbles: Array = []      # [control, world position, phase]
var _t := 0.0
var _shot := ""
var _frames := 0
var _dock_btn: Control
var _coins: CPUParticles2D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			_shot = a.substr(7)
	display_font = load(ART + "fonts/Lalezar-Regular.ttf")
	body_font = load("res://assets/fonts/vazirmatn/Vazirmatn-Medium.woff2")
	body_bold = load("res://assets/fonts/vazirmatn/Vazirmatn-Black.woff2")
	_build_world()
	_build_ui()


func _process(delta: float) -> void:
	_t += delta
	# a slow drift, so the city feels alive
	cam.position = Vector3(15.5 + sin(_t * 0.25) * 0.4, 17.0, 15.5 + cos(_t * 0.25) * 0.4)
	cam.look_at(Vector3(0.4, 0, 0.4))
	for b in bubbles:
		var c: Control = b[0]
		var sp := cam.unproject_position(b[1])
		var vs := get_viewport().get_visible_rect().size
		var s := W / vs.x
		c.position = sp * s - Vector2(c.size.x / 2.0, c.size.y) + Vector2(0, sin(_t * 2.2 + b[2]) * 5.0)
	if _dock_btn:
		var k := 1.0 + 0.035 * sin(_t * 3.4)
		_dock_btn.scale = Vector2(k, k)
	_frames += 1
	if _shot != "" and _frames == 120:
		var img := get_viewport().get_texture().get_image()
		img.save_png(_shot)
		get_tree().quit()


# -- the city -------------------------------------------------------------------------------------
func _build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#1B2A5C")
	sm.sky_horizon_color = Color("#E9926A")
	sm.ground_horizon_color = Color("#6A5A78")
	sm.ground_bottom_color = Color("#141A33")
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#7F8FD0")
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.05
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.glow_bloom = 0.08
	e.fog_enabled = true
	e.fog_light_color = Color("#3B3F74")
	e.fog_density = 0.012
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#FFB27A")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-38, -58, 0)
	world.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 27.0
	cam.position = Vector3(10.5, 13, 10.5)
	world.add_child(cam)
	cam.look_at(Vector3.ZERO)

	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color("#3E6B4A")
	ground.material_override = gmat
	ground.position.y = -0.02
	world.add_child(ground)

	# a 9 x 9 block: two roads crossing, a plaza with a fountain at their
	# corner, buildings and trees around
	var n := 9
	for x in range(-n / 2, n / 2 + 1):
		for z in range(-n / 2, n / 2 + 1):
			var name := _tile_at(x, z)
			var rot := 0.0
			if name.begins_with("road-straight"):
				rot = 90.0 if z == 0 else 0.0
			if name == "":
				continue
			_place(name, Vector3(x, 0, z), rot)
			if name == "road-straight-lightposts":
				var l := OmniLight3D.new()
				l.light_color = Color("#FFC98A")
				l.light_energy = 1.6
				l.omni_range = 2.4
				l.position = Vector3(x, 0.9, z)
				world.add_child(l)
	# where the bubbles hang
	bubbles_at = {
		"work": Vector3(-1.25, 1.6, -1.25), "factory": Vector3(1.95, 1.3, -0.95),
		"market": Vector3(-0.1, 1.2, 2.8), "study": Vector3(4.3, 1.6, 2.5),
	}


var bubbles_at := {}


func _tile_at(x: int, z: int) -> String:
	if x == 0 and z == 0:
		return "road-intersection"
	if z == 0 or x == 0:
		return "road-straight-lightposts" if (abs(x) + abs(z)) % 2 == 0 else "road-straight"
	if (x == 1 and z == 1):
		return "pavement-fountain"
	if (x == 1 and z == -1) or (x == -1 and z == 1) or (x == -1 and z == -1):
		return "pavement"
	var h := absi((x * 73856093) ^ (z * 19349663)) % 10
	if abs(x) >= 4 or abs(z) >= 4:
		return ["grass-trees-tall", "grass-trees", "grass"][h % 3]
	return ["building-small-a", "building-small-b", "building-small-c", "building-small-d", "building-garage", "grass-trees", "building-small-a", "building-small-c", "grass-trees-tall", "building-small-b"][h]


func _place(name: String, at: Vector3, rot: float) -> void:
	var scn: PackedScene = load(ART + "models/%s.glb" % name)
	if scn == null:
		return
	var m: Node3D = scn.instantiate()
	m.position = at
	m.rotation_degrees.y = rot
	world.add_child(m)


# -- the HUD --------------------------------------------------------------------------------------
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	# every piece is placed by hand, already for a right-to-left reading:
	# lay out LTR so Godot does not mirror the positions a second time
	ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ui.size = Vector2(W, H)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	# readability: the sky darkens behind the HUD, the street behind the dock
	ui.add_child(_gradient(Rect2(0, 0, W, 300), Color(INK, 0.85), Color(INK, 0.0)))
	ui.add_child(_gradient(Rect2(0, 900, W, 380), Color(INK, 0.0), Color(INK, 0.92)))

	_header()
	_side_buttons()
	_world_bubbles()
	_ready_card()
	_dock()
	_coin_fx()


func _header() -> void:
	# avatar in a gold ring, a level gem under it
	var av := _badge("person", Rect2(578, 30, 112, 112), LAPIS, GOLD)
	(av.material as ShaderMaterial).set_shader_parameter("icon_scale", 0.62)
	var ring := _ring(Rect2(570, 22, 128, 128), 0.83, FIROUZEH)
	ui.move_child(ring, av.get_index())
	ring.z_index = 0
	var lvl := _frame(Rect2(560, 110, 56, 46), 14.0, Color("#4B2A08"), Color("#2A1604"), GOLD, 0.0, 6.0)
	_in(lvl).add_child(_label("7", display_font, 28, Color.WHITE, Rect2(0, 2, 56, 40), HORIZONTAL_ALIGNMENT_CENTER, 6))
	# name plate
	var plate := _frame(Rect2(318, 32, 262, 92), 22.0, Color(0.10, 0.13, 0.28, 0.9), Color(0.05, 0.06, 0.14, 0.9), GOLD, 0.05)
	_in(plate).add_child(_label("سارا", display_font, 34, Color.WHITE, Rect2(20, 12, 222, 44), HORIZONTAL_ALIGNMENT_RIGHT, 6))
	_in(plate).add_child(_label("فروشنده‌ی ارشد · فنویک", body_font, 16, Color("#C9D2EE"), Rect2(20, 52, 222, 26), HORIZONTAL_ALIGNMENT_RIGHT, 3))
	# cash
	var cash := _frame(Rect2(20, 38, 250, 70), 35.0, Color(0.09, 0.07, 0.03, 0.92), Color(0.04, 0.03, 0.01, 0.92), GOLD, 0.0)
	_in(cash).add_child(_label("12,450", display_font, 32, Color("#FFD66B"), Rect2(62, 12, 120, 46), HORIZONTAL_ALIGNMENT_RIGHT, 6))
	_badge("coins", Rect2(212, 30, 84, 84), SAFFRON, GOLD)
	var plus := _button(Rect2(28, 50, 50, 50), LEAF.lightened(0.25), LEAF.darkened(0.15), LEAF.darkened(0.55), 16.0, 5.0)
	plus.add_child(_label("+", display_font, 34, Color.WHITE, Rect2(0, -4, 50, 50), HORIZONTAL_ALIGNMENT_CENTER, 5))

	# the four bars, each saying when it is full
	var bars := [
		["energy", "96/100", 0.96, SAFFRON, "پر: 19:30", true],
		["nerve", "14/20", 0.70, ANAR, "پر: 19:55", false],
		["health", "88/100", 0.88, LEAF, "پر: 21:10", false],
	]
	for i in bars.size():
		var bdef: Array = bars[i]
		var x := 494.0 - i * 236.0
		var bar := _bar(Rect2(x, 176, 190, 34), bdef[2], bdef[3], bdef[5])
		bar.add_child(_label(bdef[1], display_font, 22, Color.WHITE, Rect2(0, 0, 150, 34), HORIZONTAL_ALIGNMENT_CENTER, 5))
		_badge(bdef[0], Rect2(x + 160, 162, 62, 62), bdef[3], GOLD)
		ui.add_child(_label(bdef[4], body_bold, 15, Color("#E8ECF8") if not bdef[5] else Color("#FFD66B"), Rect2(x, 212, 160, 24), HORIZONTAL_ALIGNMENT_CENTER, 3))


func _side_buttons() -> void:
	var right := [["missions", "مأموریت", VIOLET, 2], ["gift", "جایزه‌ی روز", ANAR, 1], ["trophy", "رتبه", SAFFRON, 0]]
	for i in right.size():
		var d: Array = right[i]
		var y := 262.0 + i * 108.0
		_badge(d[0], Rect2(628, y, 76, 76), d[2], GOLD, 1.0)
		ui.add_child(_label(d[1], display_font, 17, Color.WHITE, Rect2(600, y + 72, 132, 26), HORIZONTAL_ALIGNMENT_CENTER, 5))
		if d[3] > 0:
			_count(Rect2(626, y - 4, 30, 30), d[3])
	var left := [["inbox", "پیام‌ها", LAPIS, 3], ["society", "جناح", FIROUZEH, 0]]
	for i in left.size():
		var d: Array = left[i]
		var y := 262.0 + i * 108.0
		_badge(d[0], Rect2(16, y, 76, 76), d[2], GOLD, 1.0)
		ui.add_child(_label(d[1], display_font, 17, Color.WHITE, Rect2(-12, y + 72, 132, 26), HORIZONTAL_ALIGNMENT_CENTER, 5))
		if d[3] > 0:
			_count(Rect2(62, y - 4, 30, 30), d[3])


func _world_bubbles() -> void:
	# a shift is ready at work: pulsing, with a check
	_bubble("work", "شیفت آماده", FIROUZEH, -1.0, "check")
	# the factory's order is running: a ring and a countdown
	_bubble("factory", "14:02", LAPIS, 0.3, "")
	# goods sold at the market: coins waiting
	_bubble("market", "+48", SAFFRON, -1.0, "coins")
	# a course finished at the university
	_bubble("study", "مدرک آماده", VIOLET, -1.0, "study")


func _bubble(key: String, text: String, tint: Color, progress: float, icon: String) -> void:
	var box := Control.new()
	box.layout_direction = Control.LAYOUT_DIRECTION_LTR
	box.size = Vector2(150, 138)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(box)
	# the pin: a small pointer under the badge
	var pin := Polygon2D.new()
	pin.polygon = PackedVector2Array([Vector2(63, 86), Vector2(87, 86), Vector2(75, 100)])
	pin.color = GOLD
	box.add_child(pin)
	if progress >= 0.0:
		_ring(Rect2(29, 0, 92, 92), progress, tint, box)
	var glyph: String = icon if icon != "" else key
	_badge(glyph, Rect2(39, 10, 72, 72), tint, GOLD, 0.0, box)
	var chip := _frame(Rect2(8, 96, 134, 38), 19.0, Color(tint.darkened(0.45), 0.95), Color(tint.darkened(0.7), 0.95), GOLD, 0.0, 3.0, box)
	(chip.material as ShaderMaterial).set_shader_parameter("shadow", 0.35)
	_in(chip).add_child(_label(text, display_font, 19, Color.WHITE, Rect2(0, 1, 134, 34), HORIZONTAL_ALIGNMENT_CENTER, 5))
	bubbles.append([box, bubbles_at[key], randf() * 6.0])


func _ready_card() -> void:
	var card := _frame(Rect2(12, 918, 696, 132), 26.0, Color(0.07, 0.20, 0.24, 0.94), Color(0.03, 0.08, 0.12, 0.94), GOLD, 0.06)
	(card.material as ShaderMaterial).set_shader_parameter("glow", Color(FIROUZEH, 0.55))
	_badge("energy", Rect2(592, 942, 88, 88), SAFFRON, GOLD)
	ui.add_child(_label("انرژی 12 دقیقه دیگه پر میشه", display_font, 26, Color.WHITE, Rect2(244, 944, 340, 40), HORIZONTAL_ALIGNMENT_RIGHT, 6))
	ui.add_child(_label("یه شیفت برو که هدر نره  ·  −20 انرژی  ·  +1,850", body_font, 16, Color("#BFE9E3"), Rect2(222, 988, 362, 30), HORIZONTAL_ALIGNMENT_RIGHT, 3))
	var go := _button(Rect2(34, 948, 190, 78), Color("#FFE27A"), Color("#F5A623"), Color("#A5580A"), 22.0, 8.0)
	go.add_child(_label("شروع شیفت", display_font, 27, Color("#4A2400"), Rect2(0, 8, 190, 50), HORIZONTAL_ALIGNMENT_CENTER, 0))


func _dock() -> void:
	var dock := _frame(Rect2(4, 1122, 712, 156), 40.0, Color(0.10, 0.12, 0.26, 0.97), Color(0.04, 0.05, 0.12, 0.97), GOLD, 0.07)
	dock.z_index = 0
	var slots := [["city", "شهر", true, 624.0], ["activity", "فعالیت", false, 484.0], ["market", "اقتصاد", false, 164.0], ["society", "جامعه", false, 24.0]]
	for s in slots:
		var x: float = s[3]
		if s[2]:
			var hl := _frame(Rect2(x - 12, 1140, 96, 118), 24.0, Color(FIROUZEH, 0.35), Color(FIROUZEH, 0.08), GOLD, 0.0, 4.0)
			(hl.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		var b := _badge(s[0], Rect2(x, 1150, 72, 72), FIROUZEH if s[2] else Color("#5A6488"), GOLD if s[2] else Color("#8A93B8"), 1.0)
		(b.material as ShaderMaterial).set_shader_parameter("dim", 0.0 if s[2] else 0.35)
		ui.add_child(_label(s[1], display_font, 20, Color.WHITE if s[2] else Color("#AEB6D6"), Rect2(x - 20, 1222, 112, 30), HORIZONTAL_ALIGNMENT_CENTER, 5))
	# the raised action in the middle: what the player does most, right now a shift
	var holder := Control.new()
	holder.layout_direction = Control.LAYOUT_DIRECTION_LTR
	holder.position = Vector2(284, 1062)
	holder.size = Vector2(152, 152)
	holder.pivot_offset = Vector2(76, 76)
	ui.add_child(holder)
	_dock_btn = holder
	_ring(Rect2(0, 0, 152, 152), 1.0, Color("#FFD66B"), holder)
	var b := _badge("work", Rect2(12, 12, 128, 128), Color("#F5A623"), Color("#FFF1B8"), 0.0, holder)
	(b.material as ShaderMaterial).set_shader_parameter("rim_w", 0.07)
	var cap := _frame(Rect2(20, 120, 112, 40), 20.0, Color("#7A3E00"), Color("#4A2400"), GOLD, 0.0, 3.0, holder)
	_in(cap).add_child(_label("شیفت", display_font, 22, Color.WHITE, Rect2(0, 1, 112, 34), HORIZONTAL_ALIGNMENT_CENTER, 5))


func _coin_fx() -> void:
	_coins = CPUParticles2D.new()
	_coins.texture = _icon_tex("coins")
	_coins.amount = 9
	_coins.lifetime = 1.6
	_coins.one_shot = false
	_coins.explosiveness = 0.9
	_coins.direction = Vector2(0, -1)
	_coins.spread = 55.0
	_coins.initial_velocity_min = 220.0
	_coins.initial_velocity_max = 380.0
	_coins.gravity = Vector2(0, 520)
	_coins.scale_amount_min = 0.06
	_coins.scale_amount_max = 0.08
	_coins.color = Color("#FFD66B")
	_coins.angular_velocity_min = -200
	_coins.angular_velocity_max = 200
	ui.add_child(_coins)
	# follow the market bubble
	var t := Timer.new()
	t.wait_time = 0.05
	t.autostart = true
	t.timeout.connect(func():
		for b in bubbles:
			if b[1] == bubbles_at["market"]:
				_coins.position = (b[0] as Control).position + Vector2(75, 40))
	add_child(t)


# -- pieces ---------------------------------------------------------------------------------------
## The content rect of a panel made by _frame (inside its shadow margin).
func _in(frame: ColorRect) -> Control:
	return frame.get_meta("inner")


func _mat(path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://proto/ui/%s.gdshader" % path)
	return m


func _frame(r: Rect2, radius: float, top: Color, bottom: Color, trim: Color, pattern: float, trim_w := 3.0, parent: Node = null) -> ColorRect:
	var margin := 16.0
	var c := ColorRect.new()
	c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	c.position = r.position - Vector2(margin, margin)
	c.size = r.size + Vector2(margin, margin) * 2.0
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := _mat("frame")
	m.set_shader_parameter("size", c.size)
	m.set_shader_parameter("radius", radius)
	m.set_shader_parameter("margin", margin)
	m.set_shader_parameter("fill_top", top)
	m.set_shader_parameter("fill_bottom", bottom)
	m.set_shader_parameter("trim", trim)
	m.set_shader_parameter("trim_w", trim_w)
	m.set_shader_parameter("pattern", pattern)
	c.material = m
	(parent if parent else ui).add_child(c)
	# children are laid out in the panel's own rect
	var inner := Control.new()
	inner.layout_direction = Control.LAYOUT_DIRECTION_LTR
	inner.position = Vector2(margin, margin)
	inner.size = r.size
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(inner)
	c.set_meta("inner", inner)
	return c


func _button(r: Rect2, top: Color, bottom: Color, lip: Color, radius: float, lip_h: float) -> ColorRect:
	var c := ColorRect.new()
	c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	c.position = r.position
	c.size = r.size
	var m := _mat("button")
	m.set_shader_parameter("size", r.size)
	m.set_shader_parameter("radius", radius)
	m.set_shader_parameter("top", top)
	m.set_shader_parameter("bottom", bottom)
	m.set_shader_parameter("lip", lip)
	m.set_shader_parameter("lip_h", lip_h)
	c.material = m
	ui.add_child(c)
	return c


func _icon_tex(name: String) -> Texture2D:
	return load(ART + "icons/%s.svg" % name)


func _badge(icon: String, r: Rect2, tint: Color, rim: Color, square := 0.0, parent: Node = null) -> TextureRect:
	var t := TextureRect.new()
	t.layout_direction = Control.LAYOUT_DIRECTION_LTR
	t.texture = _icon_tex(icon)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := _mat("badge")
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("rim", rim)
	m.set_shader_parameter("square", square)
	t.material = m
	(parent if parent else ui).add_child(t)
	return t


func _bar(r: Rect2, value: float, fill: Color, full: bool) -> ColorRect:
	var c := ColorRect.new()
	c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	c.position = r.position
	c.size = r.size
	var m := _mat("bar")
	m.set_shader_parameter("size", r.size)
	m.set_shader_parameter("value", value)
	m.set_shader_parameter("fill", fill)
	m.set_shader_parameter("full", 1.0 if full else 0.0)
	c.material = m
	ui.add_child(c)
	return c


func _ring(r: Rect2, value: float, color: Color, parent: Node = null) -> ColorRect:
	var c := ColorRect.new()
	c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	c.position = r.position
	c.size = r.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := _mat("ring")
	m.set_shader_parameter("value", value)
	m.set_shader_parameter("color", color)
	c.material = m
	(parent if parent else ui).add_child(c)
	return c


func _count(r: Rect2, n: int) -> void:
	var b := _button(r, ANAR.lightened(0.2), ANAR, ANAR.darkened(0.5), 15.0, 3.0)
	b.add_child(_label(str(n), display_font, 20, Color.WHITE, Rect2(0, -2, r.size.x, r.size.y), HORIZONTAL_ALIGNMENT_CENTER, 4))


func _label(text: String, font: Font, px: int, color: Color, r: Rect2, align: int, outline: int) -> Label:
	var l := Label.new()
	l.layout_direction = Control.LAYOUT_DIRECTION_LTR
	l.text = text
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.text_direction = Control.TEXT_DIRECTION_RTL
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.95))
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		l.add_theme_constant_override("shadow_offset_y", 3)
		l.add_theme_constant_override("shadow_offset_x", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _gradient(r: Rect2, a: Color, b: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	gt.width = 4
	gt.height = 128
	var t := TextureRect.new()
	t.layout_direction = Control.LAYOUT_DIRECTION_LTR
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
