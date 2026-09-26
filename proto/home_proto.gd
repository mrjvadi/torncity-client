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
	if is_instance_valid(_dock_btn):
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
		"work": Vector3(-1.25, 1.6, -1.25), "factory": Vector3(1.4, 1.3, -0.4),
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
const PAL := {
	"gold": ["#FFF3B0", "#D97C00", "#3A1C00"],
	"amber": ["#FFF08A", "#E07000", "#3A1600"],
	"ruby": ["#FFB0B4", "#B3121E", "#3A0006"],
	"emerald": ["#C4FFD2", "#1E8F4A", "#03250F"],
	"sapphire": ["#CFE0FF", "#2A4BC8", "#050C33"],
	"violet": ["#E6DAFF", "#6A3FD0", "#1A0A3D"],
	"steel": ["#F4F7FF", "#7C86A6", "#12161F"],
	"fox": ["#FFD9AE", "#E0561B", "#3A1200"],
	"teal": ["#E6FFFB", "#2BC4B2", "#042A26"],
	"cream": ["#FFFFFF", "#FFEFCF", "#5A2E00"],
}

var _screen := "home"


func _build_ui() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			_screen = a.substr(9)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	# every piece is placed by hand, already for a right-to-left reading:
	# lay out LTR so Godot does not mirror the positions a second time
	ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ui.size = Vector2(W, H)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var vig := ColorRect.new()
	vig.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vig.size = Vector2(W, H)
	vig.material = _mat("vignette")
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(vig)
	ui.add_child(_gradient(Rect2(0, 0, W, 330), Color(INK, 0.8), Color(INK, 0.0)))
	ui.add_child(_gradient(Rect2(0, 880, W, 400), Color(INK, 0.0), Color(INK, 0.9)))

	_top_bar()
	_stat_row()
	_side_buttons()
	_world_bubbles()
	_ready_toast()
	_dock()
	_coin_fx()
	if _screen == "crime":
		_crime_popup()


func _top_bar() -> void:
	var bar := _frame(Rect2(-24, -40, 768, 188), 44.0, Color(0.10, 0.12, 0.27, 0.96), Color(0.04, 0.05, 0.13, 0.96), GOLD, 0.06)
	(bar.material as ShaderMaterial).set_shader_parameter("glow", Color(LAPIS, 0.35))
	# avatar: a fox on a teal plate, the XP ring around it, a level gem
	_ring(Rect2(582, 8, 128, 128), 0.83, FIROUZEH)
	_badge("person", Rect2(592, 18, 108, 108), Color("#0E5E58"), GOLD)
	var av: TextureRect = ui.get_child(ui.get_child_count() - 1)
	(av.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	_emboss("fox", Rect2(596, 20, 100, 100), "fox")
	var gem := _frame(Rect2(566, 96, 50, 44), 13.0, Color("#3A2A8A"), Color("#1A1050"), GOLD, 0.0, 3.0)
	_in(gem).add_child(_glabel("7", display_font, 28, "#FFFFFF", "#FFD66B", Rect2(0, 0, 50, 44), HORIZONTAL_ALIGNMENT_CENTER, 6))
	ui.add_child(_glabel("سارا", display_font, 36, "#FFFFFF", "#BFEFFF", Rect2(330, 18, 244, 50), HORIZONTAL_ALIGNMENT_RIGHT, 7))
	ui.add_child(_label("فروشنده‌ی ارشد  ·  تاجر", body_font, 17, Color("#C9D2EE"), Rect2(300, 66, 274, 28), HORIZONTAL_ALIGNMENT_RIGHT, 3))
	var xp := _bar(Rect2(386, 100, 170, 14), 0.83, FIROUZEH, false)
	(xp.material as ShaderMaterial).set_shader_parameter("outline", Color(GOLD, 0.7))
	# money: cash and bank, each a recessed pill with its object on the end
	var cash := _frame(Rect2(22, 22, 236, 56), 28.0, Color(0.02, 0.03, 0.08, 0.95), Color(0.05, 0.06, 0.14, 0.95), Color(GOLD, 0.9), 0.0, 2.5)
	(cash.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_in(cash).add_child(_glabel("12,450", display_font, 32, "#FFF6C8", "#FFB21F", Rect2(52, 2, 128, 52), HORIZONTAL_ALIGNMENT_RIGHT, 6))
	_emboss("coins", Rect2(198, 4, 90, 90), "gold")
	var plus := _button(Rect2(30, 30, 40, 40), LEAF.lightened(0.3), LEAF.darkened(0.1), LEAF.darkened(0.55), 12.0, 4.0)
	plus.add_child(_label("+", display_font, 30, Color.WHITE, Rect2(0, -6, 40, 44), HORIZONTAL_ALIGNMENT_CENTER, 4))
	var bank := _frame(Rect2(22, 88, 236, 44), 22.0, Color(0.02, 0.03, 0.08, 0.95), Color(0.05, 0.06, 0.14, 0.95), Color("#9FB4FF", 0.7), 0.0, 2.0)
	(bank.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_in(bank).add_child(_glabel("86,300", display_font, 25, "#EAF1FF", "#8FB0FF", Rect2(40, 0, 140, 44), HORIZONTAL_ALIGNMENT_RIGHT, 5))
	_emboss("bank", Rect2(206, 76, 68, 68), "sapphire")


func _stat_row() -> void:
	var bars := [
		["energy", "96", "/100", 0.96, SAFFRON, "amber", "پر 19:30", true],
		["nerve", "14", "/20", 0.70, ANAR, "ruby", "پر 19:55", false],
		["health", "88", "/100", 0.88, LEAF, "emerald", "پر 21:10", false],
	]
	for i in bars.size():
		var d: Array = bars[i]
		var x := 500.0 - i * 238.0
		var b := _bar(Rect2(x, 178, 176, 32), d[3], d[4], d[7])
		(b.material as ShaderMaterial).set_shader_parameter("outline", Color(GOLD, 0.75))
		b.add_child(_label(d[1] + d[2], display_font, 22, Color.WHITE, Rect2(0, -1, 140, 34), HORIZONTAL_ALIGNMENT_CENTER, 5))
		_emboss(d[0], Rect2(x + 138, 156, 76, 76), d[5])
		var chip := _frame(Rect2(x + 22, 214, 110, 28), 14.0, Color(0.02, 0.03, 0.08, 0.85), Color(0.02, 0.03, 0.08, 0.85), Color(d[4], 0.8) if d[7] else Color(0, 0, 0, 0), 0.0, 2.0)
		(chip.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		_in(chip).add_child(_label(d[6], body_bold, 15, Color("#FFD66B") if d[7] else Color("#DDE3F5"), Rect2(0, 0, 110, 28), HORIZONTAL_ALIGNMENT_CENTER, 0))


func _side_buttons() -> void:
	var right := [["missions", "مأموریت", "violet", 2], ["gift", "جایزه‌ی روز", "ruby", 1], ["trophy", "رتبه", "gold", 0]]
	for i in right.size():
		var d: Array = right[i]
		_plate_icon(Vector2(664, 312 + i * 112), d[0], d[2], d[1], d[3])
	var left := [["inbox", "پیام‌ها", "sapphire", 3], ["society", "جناح", "teal", 0]]
	for i in left.size():
		var d: Array = left[i]
		_plate_icon(Vector2(56, 312 + i * 112), d[0], d[2], d[1], d[3])


## An icon on a dark round plate with a gold rim, a caption ribbon under it,
## and an optional count.
func _plate_icon(c: Vector2, icon: String, pal: String, text: String, count: int) -> void:
	_badge("person", Rect2(c.x - 40, c.y - 40, 80, 80), Color("#18204A"), GOLD)
	var plate: TextureRect = ui.get_child(ui.get_child_count() - 1)
	(plate.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	_emboss(icon, Rect2(c.x - 42, c.y - 46, 84, 84), pal)
	var cap := _frame(Rect2(c.x - 58, c.y + 36, 116, 28), 14.0, Color(0.05, 0.06, 0.14, 0.92), Color(0.02, 0.03, 0.08, 0.92), Color(GOLD, 0.8), 0.0, 1.5)
	(cap.material as ShaderMaterial).set_shader_parameter("shadow", 0.3)
	_in(cap).add_child(_label(text, display_font, 17, Color.WHITE, Rect2(0, -1, 116, 30), HORIZONTAL_ALIGNMENT_CENTER, 4))
	if count > 0:
		_count(Rect2(c.x + 14, c.y - 46, 30, 30), count)


func _world_bubbles() -> void:
	_bubble("work", "شیفت آماده", FIROUZEH, -1.0, "check", "teal")
	_bubble("factory", "14:02", LAPIS, 0.3, "factory", "sapphire")
	_bubble("market", "+48", SAFFRON, -1.0, "coins", "gold")
	_bubble("study", "مدرک آماده", VIOLET, -1.0, "study", "violet")


func _bubble(key: String, text: String, tint: Color, progress: float, icon: String, pal: String) -> void:
	var box := Control.new()
	box.layout_direction = Control.LAYOUT_DIRECTION_LTR
	box.size = Vector2(150, 140)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(box)
	var pin := Polygon2D.new()
	pin.polygon = PackedVector2Array([Vector2(62, 84), Vector2(88, 84), Vector2(75, 102)])
	pin.color = GOLD
	box.add_child(pin)
	if progress >= 0.0:
		_ring(Rect2(27, -2, 96, 96), progress, tint, box)
	_badge("person", Rect2(37, 8, 76, 76), tint.darkened(0.55), GOLD, 0.0, box)
	var plate: TextureRect = box.get_child(box.get_child_count() - 1)
	(plate.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	_emboss(icon, Rect2(37, 6, 76, 76), pal, box)
	var chip := _frame(Rect2(8, 98, 134, 38), 19.0, Color(tint.darkened(0.45), 0.95), Color(tint.darkened(0.72), 0.95), GOLD, 0.0, 2.5, box)
	(chip.material as ShaderMaterial).set_shader_parameter("shadow", 0.35)
	_in(chip).add_child(_label(text, display_font, 20, Color.WHITE, Rect2(0, 0, 134, 36), HORIZONTAL_ALIGNMENT_CENTER, 5))
	bubbles.append([box, bubbles_at[key], randf() * 6.0])


func _ready_toast() -> void:
	var card := _frame(Rect2(14, 950, 692, 100), 30.0, Color(0.06, 0.22, 0.25, 0.95), Color(0.02, 0.08, 0.11, 0.95), GOLD, 0.05)
	(card.material as ShaderMaterial).set_shader_parameter("glow", Color(FIROUZEH, 0.5))
	_emboss("energy", Rect2(598, 940, 104, 104), "amber")
	ui.add_child(_glabel("انرژی 12 دقیقه دیگه پر میشه", display_font, 26, "#FFFFFF", "#CFF7F1", Rect2(226, 960, 364, 42), HORIZONTAL_ALIGNMENT_RIGHT, 6))
	ui.add_child(_label("یه شیفت برو که هدر نره  ·  −20 انرژی  ·  +1,850", body_font, 16, Color("#BFE9E3"), Rect2(206, 1002, 384, 30), HORIZONTAL_ALIGNMENT_RIGHT, 3))
	var go := _button(Rect2(30, 966, 182, 70), Color("#FFE680"), Color("#F5A11F"), Color("#9A4E06"), 22.0, 8.0)
	go.add_child(_glabel("شروع شیفت", display_font, 27, "#5A2A00", "#3A1600", Rect2(0, 4, 182, 54), HORIZONTAL_ALIGNMENT_CENTER, 0))


## The dock, in the pattern the best mobile games settled on: one solid bar
## of five tabs, the city (home) in the middle. The active tab widens, rises
## out of the bar on a lit tile and names itself; the others are icons with
## a quiet caption. No floating buttons: the thumb always finds a tab.
func _dock() -> void:
	_dock_btn = null
	var bar := _frame(Rect2(-24, 1150, 768, 170), 10.0, Color(0.09, 0.11, 0.24, 0.99), Color(0.03, 0.04, 0.10, 0.99), GOLD, 0.05, 3.0)
	(bar.material as ShaderMaterial).set_shader_parameter("shadow", 0.7)
	# right to left: me, activity, city, market, society
	var tabs := [["person", "من", 0], ["activity", "فعالیت", 1], ["city", "شهر", 0], ["market", "اقتصاد", 2], ["society", "جامعه", 3]]
	var active := 2
	var x := W
	for i in tabs.size():
		var t: Array = tabs[i]
		var w := 208.0 if i == active else 128.0
		x -= w
		var cx := x + w / 2.0
		if i == active:
			var tile := _frame(Rect2(x + 6, 1112, w - 12, 176), 24.0, Color("#3A63D0"), Color("#15286A"), GOLD, 0.06, 3.0)
			var tm := tile.material as ShaderMaterial
			tm.set_shader_parameter("glow", Color("#8FB4FF", 0.55))
			tm.set_shader_parameter("shadow", 0.8)
			_emboss(t[0], Rect2(cx - 54, 1110, 108, 108), "gold")
			ui.add_child(_glabel(t[1], display_font, 28, "#FFFFFF", "#FFD66B", Rect2(x, 1214, w, 44), HORIZONTAL_ALIGNMENT_CENTER, 7))
		else:
			var ic := _emboss(t[0], Rect2(cx - 40, 1162, 80, 80), "steel")
			ic.modulate = Color(0.78, 0.82, 0.95)
			ui.add_child(_label(t[1], display_font, 19, Color("#9EA8CC"), Rect2(x, 1236, w, 32), HORIZONTAL_ALIGNMENT_CENTER, 4))
			if t[2] > 0:
				_count(Rect2(cx + 14, 1160, 32, 32), t[2])
		# a groove between neighbours, skipped beside the raised tile
		if i < tabs.size() - 1 and i != active and i + 1 != active:
			var g := ColorRect.new()
			g.layout_direction = Control.LAYOUT_DIRECTION_LTR
			g.position = Vector2(x - 1, 1172)
			g.size = Vector2(2, 92)
			g.color = Color(0, 0, 0, 0.45)
			ui.add_child(g)
			var hl := ColorRect.new()
			hl.layout_direction = Control.LAYOUT_DIRECTION_LTR
			hl.position = Vector2(x + 1, 1172)
			hl.size = Vector2(1, 92)
			hl.color = Color(GOLD, 0.25)
			ui.add_child(hl)


func _crime_popup() -> void:
	var dim := ColorRect.new()
	dim.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dim.size = Vector2(W, H)
	dim.color = Color(0.01, 0.01, 0.04, 0.72)
	ui.add_child(dim)
	var red := Color("#C8242C")
	var panel := _frame(Rect2(34, 262, 652, 740), 34.0, Color(0.20, 0.07, 0.12, 0.98), Color(0.06, 0.03, 0.08, 0.98), GOLD, 0.07)
	(panel.material as ShaderMaterial).set_shader_parameter("glow", Color(red, 0.45))
	var rib := ColorRect.new()
	rib.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rib.position = Vector2(110, 212)
	rib.size = Vector2(500, 104)
	var rm := _mat("ribbon")
	rm.set_shader_parameter("size", rib.size)
	rib.material = rm
	ui.add_child(rib)
	ui.add_child(_glabel("جیب‌بری", display_font, 44, "#FFFFFF", "#FFD9B0", Rect2(160, 218, 400, 72), HORIZONTAL_ALIGNMENT_CENTER, 8))
	var close := _button(Rect2(620, 268, 56, 56), ANAR.lightened(0.25), ANAR, ANAR.darkened(0.55), 28.0, 5.0)
	close.add_child(_label("×", display_font, 40, Color.WHITE, Rect2(0, -8, 56, 60), HORIZONTAL_ALIGNMENT_CENTER, 5))

	# the crime (right) and the odds (left)
	_ring(Rect2(420, 338, 200, 200), 1.0, Color(red, 0.5))
	_badge("person", Rect2(436, 354, 168, 168), Color("#3A0E1E"), GOLD)
	var plate: TextureRect = ui.get_child(ui.get_child_count() - 1)
	(plate.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	_emboss("crime", Rect2(440, 350, 160, 160), "steel")
	var where := _frame(Rect2(440, 532, 160, 34), 17.0, Color(0.02, 0.03, 0.08, 0.9), Color(0.02, 0.03, 0.08, 0.9), Color(GOLD, 0.6), 0.0, 1.5)
	(where.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_in(where).add_child(_label("بازار · همین‌جا", body_bold, 16, Color("#FFE3B0"), Rect2(0, 0, 160, 34), HORIZONTAL_ALIGNMENT_CENTER, 0))
	_ring(Rect2(110, 344, 196, 196), 0.82, LEAF)
	ui.add_child(_glabel("82٪", display_font, 54, "#E8FFE9", "#4CC47E", Rect2(110, 390, 196, 80), HORIZONTAL_ALIGNMENT_CENTER, 7))
	ui.add_child(_label("شانس موفقیت", display_font, 20, Color("#CFE8D6"), Rect2(110, 460, 196, 34), HORIZONTAL_ALIGNMENT_CENTER, 4))
	ui.add_child(_label("مهارت جرم +3٪ این هفته", body_font, 15, Color("#9FB0A6"), Rect2(90, 536, 236, 28), HORIZONTAL_ALIGNMENT_CENTER, 0))

	# what it costs, what it pays, what can go wrong
	var tiles := [
		["nerve", "ruby", "هزینه", "2 عصب", Vector2(366, 588)],
		["money", "emerald", "پاداش", "300 تا 400", Vector2(58, 588)],
		["handcuffs", "steel", "اگر گیر بیفتی", "زندان 1 ساعت · 18٪", Vector2(366, 686)],
		["stopwatch", "sapphire", "دوباره", "15 دقیقه · 19:20", Vector2(58, 686)],
	]
	for t in tiles:
		var at: Vector2 = t[4]
		var tile := _frame(Rect2(at.x, at.y, 296, 84), 20.0, Color(0.02, 0.03, 0.08, 0.72), Color(0.05, 0.04, 0.10, 0.72), Color(GOLD, 0.35), 0.0, 1.5)
		(tile.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		_emboss(t[0], Rect2(at.x + 214, at.y + 4, 76, 76), t[1])
		ui.add_child(_label(t[2], body_font, 15, Color("#B9A8B8"), Rect2(at.x + 10, at.y + 8, 204, 26), HORIZONTAL_ALIGNMENT_RIGHT, 0))
		ui.add_child(_label(t[3], display_font, 23, Color.WHITE, Rect2(at.x + 10, at.y + 34, 204, 40), HORIZONTAL_ALIGNMENT_RIGHT, 4))

	# side effects, then the heat it adds
	var fx := [["+XP جرم", LEAF, 470.0], ["+6 داغی", SAFFRON, 330.0], ["+استرس", ANAR, 190.0]]
	for f in fx:
		var c := _frame(Rect2(f[2], 790, 124, 36), 18.0, Color(f[1].darkened(0.55), 0.95), Color(f[1].darkened(0.75), 0.95), Color(f[1], 0.9), 0.0, 2.0)
		(c.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		_in(c).add_child(_label(f[0], display_font, 19, Color.WHITE, Rect2(0, 0, 124, 36), HORIZONTAL_ALIGNMENT_CENTER, 4))
	var heat := _bar(Rect2(186, 846, 400, 22), 0.18, SAFFRON, false)
	(heat.material as ShaderMaterial).set_shader_parameter("outline", Color(GOLD, 0.6))
	_emboss("heat", Rect2(590, 830, 54, 54), "amber")
	ui.add_child(_label("داغی 12 ← 18", body_bold, 15, Color("#FFD9A0"), Rect2(70, 842, 112, 30), HORIZONTAL_ALIGNMENT_LEFT, 0))

	# the one thing to do
	var go := _button(Rect2(96, 894, 528, 88), LEAF.lightened(0.35), LEAF.darkened(0.05), LEAF.darkened(0.6), 26.0, 9.0)
	go.add_child(_glabel("انجام بده", display_font, 38, "#FFFFFF", "#E2FFE6", Rect2(150, 2, 330, 70), HORIZONTAL_ALIGNMENT_CENTER, 7))
	var cost := _frame(Rect2(116, 910, 110, 50), 25.0, Color(0.03, 0.18, 0.08, 0.85), Color(0.02, 0.10, 0.05, 0.85), Color(1, 1, 1, 0.5), 0.0, 1.5)
	(cost.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_in(cost).add_child(_label("−2", display_font, 26, Color.WHITE, Rect2(8, 2, 54, 46), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_emboss("nerve", Rect2(174, 906, 56, 56), "ruby")


func _coin_fx() -> void:
	_coins = CPUParticles2D.new()
	_coins.texture = _icon_tex("coins")
	_coins.amount = 9
	_coins.lifetime = 0.9
	_coins.one_shot = false
	_coins.explosiveness = 0.9
	_coins.direction = Vector2(0, -1)
	_coins.spread = 35.0
	_coins.initial_velocity_min = 140.0
	_coins.initial_velocity_max = 230.0
	_coins.gravity = Vector2(0, 640)
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


func _emboss(icon: String, r: Rect2, pal: String, parent: Node = null) -> TextureRect:
	var t := TextureRect.new()
	t.layout_direction = Control.LAYOUT_DIRECTION_LTR
	t.texture = _icon_tex(icon)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := _mat("emboss")
	var c: Array = PAL[pal]
	m.set_shader_parameter("light_c", Color(c[0]))
	m.set_shader_parameter("dark_c", Color(c[1]))
	m.set_shader_parameter("outline_c", Color(c[2]))
	t.material = m
	(parent if parent else ui).add_child(t)
	return t


func _glabel(text: String, font: Font, px: int, top: String, bottom: String, r: Rect2, align: int, outline: int) -> Label:
	var l := _label(text, font, px, Color.WHITE, r, align, outline)
	var m := _mat("grad_text")
	m.set_shader_parameter("top_c", Color(top))
	m.set_shader_parameter("bottom_c", Color(bottom))
	# Lalezar sits its glyphs a little low in the line box
	m.set_shader_parameter("y0", (r.size.y - px) / 2.0)
	m.set_shader_parameter("h", px * 1.05)
	l.material = m
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
