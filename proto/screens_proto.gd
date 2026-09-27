extends "res://proto/home_proto.gd"
## Every feature of the game as a screen in the prototype's visual language:
## the top bar, a title ribbon with back and help, the content, the dock with
## its tab lit. Placeholder data throughout, shaped like the server's views.
##   godot --path . res://proto/screens_proto.tscn -- --screen=<name> [--shot=out.png]
## Names: profile, activity, job, crime, education, hospital, missions,
## economy, inventory, market, bank, company, property, stocks, society,
## inbox, faction, elections, government, war, forces [--branch=ground|air|navy|air_defence],
## unit, arsenal, airdefence, travel, levelup, leaderboard.

const TAB := {"profile": 0, "activity": 1, "job": 1, "crime": 1, "education": 1, "hospital": 1, "missions": 1,
	"leaderboard": 1, "economy": 3, "inventory": 3, "market": 3, "bank": 3, "company": 3, "property": 3,
	"stocks": 3, "society": 4, "inbox": 4, "faction": 4, "elections": 4, "government": 4, "war": 4,
	"forces": 4, "unit": 4, "arsenal": 4, "airdefence": 4,
	"travel": 2, "levelup": 2}

var _scr := "profile"


func _build_world() -> void:
	pass


func _build_ui() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			_scr = a.substr(9)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ui.size = Vector2(W, H)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var bg := TextureRect.new()
	bg.layout_direction = Control.LAYOUT_DIRECTION_LTR
	bg.texture = load(ART + "bg_city.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(W, H)
	ui.add_child(bg)
	ui.add_child(_gradient(Rect2(0, 0, W, H), Color(INK, 0.55), Color(INK, 0.85)))
	var vig := ColorRect.new()
	vig.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vig.size = Vector2(W, H)
	vig.material = _mat("vignette")
	ui.add_child(vig)
	dock_tab = TAB.get(_scr, 2)
	_top_bar()
	if has_method("_s_" + _scr):
		call("_s_" + _scr)
	_dock()


# -- pieces -----------------------------------------------------------------------------------------
func _hdr(title: String, tint: Color) -> void:
	var rib := ColorRect.new()
	rib.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rib.position = Vector2(126, 148)
	rib.size = Vector2(468, 96)
	var rm := _mat("ribbon")
	rm.set_shader_parameter("size", rib.size)
	rm.set_shader_parameter("face_top", tint.lightened(0.25))
	rm.set_shader_parameter("face_bottom", tint.darkened(0.3))
	rib.material = rm
	ui.add_child(rib)
	ui.add_child(_glabel(title, display_font, 36, "#FFFFFF", "#FFE6B8", Rect2(176, 150, 368, 66), HORIZONTAL_ALIGNMENT_CENTER, 7))
	var back := _button(Rect2(628, 158, 68, 68), Color("#3F55A8"), Color("#1A2560"), Color("#0A1030"), 34.0, 6.0)
	back.add_child(_label("›", display_font, 54, Color.WHITE, Rect2(0, -14, 68, 80), HORIZONTAL_ALIGNMENT_CENTER, 5))
	var help := _button(Rect2(24, 158, 68, 68), Color("#3F55A8"), Color("#1A2560"), Color("#0A1030"), 34.0, 6.0)
	help.add_child(_label("؟", display_font, 36, Color.WHITE, Rect2(0, -2, 68, 60), HORIZONTAL_ALIGNMENT_CENTER, 5))


func _card(r: Rect2, glow := Color(0, 0, 0, 0)) -> ColorRect:
	var c := _frame(r, 24.0, Color(0.10, 0.12, 0.27, 0.95), Color(0.04, 0.05, 0.13, 0.95), Color(GOLD, 0.85), 0.04, 2.5)
	if glow.a > 0.0:
		(c.material as ShaderMaterial).set_shader_parameter("glow", glow)
	return c


func _inset(r: Rect2, trim := Color(GOLD, 0.3)) -> ColorRect:
	var c := _frame(r, 18.0, Color(0.02, 0.03, 0.08, 0.78), Color(0.05, 0.05, 0.12, 0.78), trim, 0.0, 1.5)
	(c.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	return c


func _sec(y: float, text: String) -> void:
	ui.add_child(_glabel(text, display_font, 27, "#FFFFFF", "#FFD66B", Rect2(40, y, 640, 42), HORIZONTAL_ALIGNMENT_RIGHT, 6))
	var line := ColorRect.new()
	line.layout_direction = Control.LAYOUT_DIRECTION_LTR
	line.position = Vector2(40, y + 44)
	line.size = Vector2(640, 2)
	line.color = Color(GOLD, 0.35)
	ui.add_child(line)


func _txt(r: Rect2, text: String, px := 18, color := Color("#DDE3F5"), align := HORIZONTAL_ALIGNMENT_RIGHT, font: Font = null, outline := 0) -> Label:
	var l := _label(text, font if font else body_bold, px, color, r, align, outline)
	ui.add_child(l)
	return l


func _big(r: Rect2, text: String, px: int, top: String, bottom: String, align := HORIZONTAL_ALIGNMENT_RIGHT) -> void:
	ui.add_child(_glabel(text, display_font, px, top, bottom, r, align, 6))


const BTN := {
	"green": ["#8BE8A0", "#3FAE63", "#1A5A30", "#FFFFFF", "#E8FFEA", 6],
	"gold": ["#FFE680", "#F5A11F", "#9A4E06", "#5A2A00", "#3A1600", 0],
	"red": ["#FF8A8E", "#D8343B", "#6E1216", "#FFFFFF", "#FFE0E0", 6],
	"blue": ["#6F8CF0", "#2A45B0", "#101E60", "#FFFFFF", "#DDE6FF", 6],
	"steel": ["#8E97B4", "#4A536E", "#1E2436", "#FFFFFF", "#E0E6F5", 5],
}


func _btn(r: Rect2, text: String, kind := "green") -> ColorRect:
	var c: Array = BTN[kind]
	var lip := maxf(4.0, r.size.y * 0.1)
	var b := _button(r, Color(c[0]), Color(c[1]), Color(c[2]), minf(22.0, r.size.y / 2.0), lip)
	b.add_child(_glabel(text, display_font, int(r.size.y * 0.4), c[3], c[4], Rect2(0, 0, r.size.x, r.size.y - lip), HORIZONTAL_ALIGNMENT_CENTER, c[5]))
	return b


func _chip(r: Rect2, text: String, col: Color, px := 18) -> void:
	var f := _frame(r, r.size.y / 2.0, Color(col.darkened(0.45), 0.95), Color(col.darkened(0.72), 0.95), Color(col.lightened(0.2), 0.9), 0.0, 2.0)
	(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_in(f).add_child(_label(text, display_font, px, Color.WHITE, Rect2(0, 0, r.size.x, r.size.y), HORIZONTAL_ALIGNMENT_CENTER, 4))


func _pbar(r: Rect2, v: float, col: Color, text := "", full := false) -> void:
	var b := _bar(r, v, col, full)
	(b.material as ShaderMaterial).set_shader_parameter("outline", Color(GOLD, 0.6))
	if text != "":
		b.add_child(_label(text, display_font, int(r.size.y * 0.72), Color.WHITE, Rect2(0, -1, r.size.x, r.size.y), HORIZONTAL_ALIGNMENT_CENTER, 4))


func _plate(icon: String, r: Rect2, pal: String, tint := Color("#18204A")) -> void:
	_badge("person", r, tint, GOLD)
	var p: TextureRect = ui.get_child(ui.get_child_count() - 1)
	(p.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	_emboss(icon, Rect2(r.position + r.size * 0.02, r.size * 0.96), pal)


## A list row: a plated icon at the reading start, a title and a line under
## it, and an optional value at the end.
func _row(r: Rect2, icon: String, pal: String, title: String, sub: String, right := "", right_col := Color.WHITE, trim := Color(GOLD, 0.3)) -> void:
	_inset(r, trim)
	var s := minf(70.0, r.size.y - 14.0)
	_plate(icon, Rect2(r.end.x - s - 10, r.position.y + (r.size.y - s) / 2.0, s, s), pal)
	var tx := r.position.x + 14
	var tw := r.size.x - s - 40
	if sub == "":
		ui.add_child(_label(title, display_font, 23, Color.WHITE, Rect2(tx, r.position.y, tw, r.size.y), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	else:
		ui.add_child(_label(title, display_font, 23, Color.WHITE, Rect2(tx, r.position.y + r.size.y / 2.0 - 36, tw, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_txt(Rect2(tx, r.position.y + r.size.y / 2.0, tw, 30), sub, 16, Color("#AEB8D8"))
	if right != "":
		ui.add_child(_label(right, display_font, 24, right_col, Rect2(r.position.x + 18, r.position.y, 220, r.size.y), HORIZONTAL_ALIGNMENT_LEFT, 5))


func _tile(r: Rect2, icon: String, pal: String, title: String, sub: String, count := 0, glow := Color(0, 0, 0, 0)) -> void:
	_card(r, glow)
	var s := minf(104.0, r.size.y * 0.5)
	_emboss(icon, Rect2(r.position.x + (r.size.x - s) / 2.0, r.position.y + 14, s, s), pal)
	ui.add_child(_label(title, display_font, 25, Color.WHITE, Rect2(r.position.x, r.position.y + s + 16, r.size.x, 36), HORIZONTAL_ALIGNMENT_CENTER, 5))
	_txt(Rect2(r.position.x + 8, r.position.y + s + 52, r.size.x - 16, 28), sub, 16, Color("#BFE9E3") if glow.a > 0.0 else Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	if count > 0:
		_count(Rect2(r.position.x + 16, r.position.y + 14, 34, 34), count)


func _spark(r: Rect2, pts: Array, col: Color) -> void:
	var lo: float = pts.min()
	var hi: float = pts.max()
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = col
	line.antialiased = true
	var poly := PackedVector2Array()
	for i in pts.size():
		var p := Vector2(r.position.x + r.size.x * i / (pts.size() - 1), r.end.y - (float(pts[i]) - lo) / maxf(0.001, hi - lo) * r.size.y)
		line.add_point(p)
		poly.append(p)
	poly.append(r.end)
	poly.append(Vector2(r.position.x, r.end.y))
	var fill := Polygon2D.new()
	fill.polygon = poly
	fill.color = Color(col, 0.18)
	ui.add_child(fill)
	ui.add_child(line)


func _avatar(r: Rect2, icon := "fox", pal := "fox", tint := Color("#0E5E58")) -> void:
	_plate(icon, r, pal, tint)


# -- me -----------------------------------------------------------------------------------------------
func _s_profile() -> void:
	_hdr("پروفایل", Color("#1E7A7A"))
	_card(Rect2(20, 256, 680, 300), Color(FIROUZEH, 0.35))
	_ring(Rect2(512, 270, 176, 176), 0.83, FIROUZEH)
	_avatar(Rect2(524, 282, 152, 152))
	_big(Rect2(60, 272, 440, 60), "سارا", 44, "#FFFFFF", "#BFEFFF")
	_txt(Rect2(60, 330, 440, 30), "فروشنده‌ی ارشد  ·  تاجر  ·  27 ساله", 18)
	_chip(Rect2(380, 372, 120, 40), "سطح 7", Color("#6A3FD0"))
	_pbar(Rect2(60, 378, 300, 28), 0.83, FIROUZEH, "5,400 / 6,500")
	_chip(Rect2(250, 428, 250, 38), "کد بازیکن  K7Q2M9A", Color("#3552C8"), 16)
	_chip(Rect2(60, 490, 200, 44), "ویرایش آواتار", Color("#8E6CF0"), 18)
	_chip(Rect2(280, 490, 200, 44), "تنظیمات", Color("#5A6488"), 18)
	var stats := [["coins", "gold", "پول نقد", "12,450", "#FFD66B"], ["bank", "sapphire", "موجودی بانک", "86,300", "#9FB8FF"],
		["crowncoin", "emerald", "ارزش خالص", "101,950", "#8BE8A0"], ["rank", "gold", "رتبه‌ی ثروت", "تاجر", "#FFD66B"]]
	for i in stats.size():
		var st: Array = stats[i]
		var r := Rect2(20 + (i % 2) * 346, 572 + (i / 2) * 112, 334, 100)
		_inset(r)
		_emboss(st[0], Rect2(r.end.x - 86, r.position.y + 10, 80, 80), st[1])
		_txt(Rect2(r.position.x + 12, r.position.y + 12, 226, 28), st[2], 16, Color("#AEB8D8"))
		ui.add_child(_label(st[3], display_font, 30, Color(st[4]), Rect2(r.position.x + 12, r.position.y + 40, 226, 50), HORIZONTAL_ALIGNMENT_RIGHT, 5))
	_sec(806, "نیازها")
	var needs := [["bread", "amber", "گرسنگی", 0.34, Color("#D8744A")], ["sleepy", "violet", "خواب", 0.52, VIOLET],
		["heat", "ruby", "استرس", 0.22, Color("#FF8FA3")], ["sun", "gold", "شادی", 0.71, LEAF]]
	for i in needs.size():
		var n: Array = needs[i]
		var x := 366.0 - (i % 2) * 346.0
		var y := 862.0 + (i / 2) * 64.0
		_emboss(n[0], Rect2(x + 270, y - 6, 58, 58), n[1])
		_txt(Rect2(x + 180, y, 86, 44), n[2], 17)
		_pbar(Rect2(x, y + 8, 176, 28), n[3], n[4], str(int(n[3] * 100)))
	_sec(990, "دستاوردها  ·  4 از 9")
	var medals := ["trophy", "medal", "ribbon", "rank", "diamond", "swords", "vote", "eagle"]
	for i in medals.size():
		var got := i < 4
		_plate(medals[i], Rect2(612 - i * 82, 1046, 68, 68), "gold" if got else "steel", Color("#3A2A08") if got else Color("#161A28"))
		if not got:
			(ui.get_child(ui.get_child_count() - 1) as CanvasItem).modulate = Color(0.5, 0.5, 0.6)


# -- activity ---------------------------------------------------------------------------------------
func _s_activity() -> void:
	_hdr("فعالیت", Color("#1E6A8A"))
	var tiles := [["work", "teal", "کار", "شیفت آماده است", 0, true], ["crime", "steel", "جرم", "عصب 14/20  ·  داغی 12", 0, false],
		["study", "violet", "تحصیل", "مدیریت پایه  ·  1:29", 0, false], ["book", "sapphire", "مهارت‌ها", "13 مهارت  ·  2 ارتقا", 2, false],
		["missions", "violet", "مأموریت‌ها", "2 مأموریت فعال", 1, false], ["hospital", "ruby", "بیمارستان", "سلامت 88/100", 0, false],
		["bed", "sapphire", "خواب", "خستگی 52  ·  خانه", 0, false], ["podium", "gold", "رتبه‌ها", "رتبه‌ی 142 در ثروت", 0, false]]
	for i in tiles.size():
		var t: Array = tiles[i]
		var r := Rect2(366 - (i % 2) * 346, 256 + (i / 2) * 214, 334, 202)
		_tile(r, t[0], t[1], t[2], t[3], t[4], Color(FIROUZEH, 0.55) if t[5] else Color(0, 0, 0, 0))


func _s_job() -> void:
	_hdr("کار", Color("#8A5A10"))
	_card(Rect2(20, 256, 680, 220), Color(Color("#D8744A"), 0.3))
	_plate("work", Rect2(596, 276, 90, 90), "cream", Color("#7A3E00"))
	_big(Rect2(250, 276, 336, 48), "فروشنده‌ی ارشد", 34, "#FFFFFF", "#FFE6B8")
	_txt(Rect2(250, 326, 336, 28), "فروشگاه‌های البرز  ·  تجارت", 17, Color("#C9D2EE"))
	_chip(Rect2(346, 370, 240, 44), "1,850 نیل برای هر شیفت", Color("#B8860B"), 18)
	_chip(Rect2(346, 420, 240, 40), "3 شیفت از 4 امروز", Color("#3552C8"), 16)
	_ring(Rect2(48, 272, 176, 176), 0.64, LEAF)
	_big(Rect2(48, 318, 176, 60), "64", 50, "#E8FFE9", "#4CC47E", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(48, 376, 176, 28), "عملکرد", 17, Color("#CFE8D6"), HORIZONTAL_ALIGNMENT_CENTER)
	_btn(Rect2(20, 494, 680, 96), "شروع شیفت", "gold")
	_chip(Rect2(44, 516, 130, 42), "−20 انرژی", SAFFRON, 17)
	_chip(Rect2(546, 516, 130, 42), "6 دقیقه", Color("#3552C8"), 17)
	_sec(610, "نردبان ترفیع")
	var ladder := [["کارآموز", "گذرانده شد", "check", "emerald", "done"], ["فروشنده", "گذرانده شد", "check", "emerald", "done"],
		["فروشنده‌ی ارشد", "جایگاه فعلی تو", "work", "gold", "now"], ["سرپرست فروش", "عملکرد 70  ·  3 شیفت دیگر  ·  مدرک مدیریت", "rank", "steel", "next"],
		["مدیر فروشگاه", "از سطح 12", "clock", "steel", "locked"]]
	for i in ladder.size():
		var l: Array = ladder[i]
		var r := Rect2(20, 664 + i * 90, 680, 82)
		var trim := Color(FIROUZEH, 0.9) if l[4] == "now" else Color(GOLD, 0.3)
		_row(r, l[2], l[3], l[0], l[1], "", Color.WHITE, trim)
		if l[4] == "done":
			_chip(Rect2(40, r.position.y + 20, 110, 42), "✓", LEAF, 20)
		elif l[4] == "next":
			_pbar(Rect2(40, r.position.y + 28, 150, 26), 0.6, SAFFRON, "60٪")
		elif l[4] == "locked":
			(ui.get_child(ui.get_child_count() - 1) as CanvasItem).modulate = Color(0.6, 0.6, 0.7)


func _s_crime() -> void:
	_hdr("جرم", Color("#A01E2A"))
	_card(Rect2(20, 256, 680, 130), Color(ANAR, 0.3))
	_emboss("nerve", Rect2(610, 268, 70, 70), "ruby")
	_pbar(Rect2(360, 284, 240, 32), 0.7, ANAR, "عصب 14/20")
	_txt(Rect2(360, 322, 240, 26), "پر: 19:55", 15, Color("#FFC0C0"), HORIZONTAL_ALIGNMENT_CENTER)
	_emboss("heat", Rect2(270, 268, 70, 70), "amber")
	_pbar(Rect2(40, 284, 220, 32), 0.12, SAFFRON, "داغی 12")
	_txt(Rect2(40, 322, 220, 26), "سرد: 22:00", 15, Color("#FFD9A0"), HORIZONTAL_ALIGNMENT_CENTER)
	_chip(Rect2(484, 348, 120, 30), "خرده‌پا", VIOLET, 15)
	var chips := ["همه", "خیابانی", "دزدی", "سازمان‌یافته"]
	for i in chips.size():
		_chip(Rect2(560 - i * 150, 400, 140, 42), chips[i], FIROUZEH if i == 0 else Color("#3A4468"), 18)
	var crimes := [["جیب‌بری", "2 عصب  ·  300 تا 400", 0.82, LEAF, "crime", ""], ["دزدی از خانه", "5 عصب  ·  800 تا 4,000", 0.54, SAFFRON, "house", ""],
		["سرقت خودرو", "8 عصب  ·  5,000 تا 18,000", 0.31, SAFFRON, "tank", "30 دقیقه"], ["دستبرد به بانک", "از سطح 12", 0.09, ANAR, "bank", "قفل"],
		["جعل سند", "مهارت جعل 3 لازم است", 0.0, ANAR, "quill", "قفل"]]
	for i in crimes.size():
		var c: Array = crimes[i]
		var r := Rect2(20, 458 + i * 128, 680, 118)
		_inset(r)
		_plate(c[4], Rect2(612, r.position.y + 16, 80, 80), "steel", Color("#3A0E1E"))
		ui.add_child(_label(c[0], display_font, 25, Color.WHITE, Rect2(250, r.position.y + 10, 350, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_txt(Rect2(250, r.position.y + 46, 350, 26), c[1], 16, Color("#AEB8D8"))
		if c[5] == "قفل":
			_chip(Rect2(40, r.position.y + 36, 150, 46), "قفل", Color("#5A6488"), 19)
			(ui.get_child(ui.get_child_count() - 1) as CanvasItem).modulate = Color(0.8, 0.8, 0.9)
		else:
			_pbar(Rect2(250, r.position.y + 78, 350, 26), c[2], c[3], "%d٪" % int(c[2] * 100))
			if c[5] != "":
				_chip(Rect2(40, r.position.y + 36, 150, 46), c[5], Color("#3552C8"), 18)
			else:
				_btn(Rect2(40, r.position.y + 30, 160, 60), "انجام", "red")


func _s_education() -> void:
	_hdr("تحصیل", Color("#5A3AA8"))
	_card(Rect2(20, 256, 680, 170), Color(VIOLET, 0.4))
	_plate("study", Rect2(600, 274, 84, 84), "violet", Color("#2A1860"))
	_txt(Rect2(260, 270, 330, 26), "در حال تحصیل", 16, Color("#C8B8F0"))
	_big(Rect2(260, 294, 330, 50), "مدیریت پایه", 34, "#FFFFFF", "#E0D4FF")
	_pbar(Rect2(40, 362, 540, 32), 0.72, VIOLET, "1:29 مانده  ·  تا 20:58")
	_txt(Rect2(40, 300, 210, 40), "دانشگاه فنویک", 16, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	_sec(442, "دوره‌ها")
	var courses := [["رانندگی حرفه‌ای", "1,200 نیل  ·  2 ساعت  ·  مدرک", "bus", "sapphire", "btn"], ["شیمی صنعتی", "5,200 نیل  ·  6 ساعت  ·  +3 هوش", "pill", "emerald", "btn"],
		["کمک‌های اولیه", "گذرانده شد", "hospital", "ruby", "done"], ["حسابداری", "3,400 نیل  ·  4 ساعت", "chart", "gold", "btn"],
		["مهندسی نرم‌افزار", "از سطح 10  ·  هوش 60", "phone", "steel", "locked"]]
	for i in courses.size():
		var c: Array = courses[i]
		var r := Rect2(20, 496 + i * 104, 680, 94)
		_row(r, c[2], c[3], c[0], c[1])
		match c[4]:
			"btn":
				_btn(Rect2(40, r.position.y + 18, 150, 58), "ثبت‌نام", "green")
			"done":
				_chip(Rect2(40, r.position.y + 24, 150, 46), "✓ مدرک", LEAF, 18)
			"locked":
				_chip(Rect2(40, r.position.y + 24, 150, 46), "قفل", Color("#5A6488"), 18)
	_sec(1016, "مدرک‌های تو")
	_chip(Rect2(460, 1066, 220, 42), "کمک‌های اولیه", LEAF, 17)
	_chip(Rect2(230, 1066, 220, 42), "زبان انگلیسی", Color("#3552C8"), 17)


func _s_hospital() -> void:
	_hdr("بیمارستان", Color("#B02A34"))
	_card(Rect2(20, 256, 680, 420), Color(ANAR, 0.4))
	_ring(Rect2(210, 276, 300, 300), 0.35, ANAR)
	_plate("health", Rect2(270, 336, 180, 180), "ruby", Color("#3A0E1E"))
	_big(Rect2(40, 584, 640, 50), "مرخص: 42:10", 38, "#FFFFFF", "#FFC0C4", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(40, 630, 640, 30), "ساعت 20:05  ·  سلامت 34 از 100، هر ساعت +8", 17, Color("#FFD0D4"), HORIZONTAL_ALIGNMENT_CENTER)
	_chip(Rect2(470, 276, 210, 42), "زخمی در جیب‌بری", ANAR, 17)
	_sec(694, "درمان")
	_row(Rect2(20, 748, 680, 94), "pill", "emerald", "دارو", "+10 سلامت  ·  داری: 1", "", Color.WHITE)
	_btn(Rect2(40, 766, 150, 58), "مصرف", "green")
	_row(Rect2(20, 852, 680, 94), "stetho", "sapphire", "درمان سریع", "30 دقیقه زودتر مرخص شو", "", Color.WHITE)
	_btn(Rect2(40, 870, 150, 58), "1,200", "gold")
	_row(Rect2(20, 956, 680, 94), "shield", "gold", "بیمه‌ی درمان", "80٪ هزینه‌ی درمان  ·  تا 6 روز دیگر", "فعال", LEAF)
	_txt(Rect2(40, 1062, 640, 40), "در بیمارستان نمی‌توانی کار کنی یا جرم انجام بدهی.", 16, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)


func _s_missions() -> void:
	_hdr("مأموریت‌ها", Color("#5A3AA8"))
	_chip(Rect2(530, 256, 150, 44), "شهری", FIROUZEH, 19)
	_chip(Rect2(370, 256, 150, 44), "پلیس", Color("#3A4468"), 19)
	var ms := [["بازار را پر کن", "شهرداری", [["10 نان به بازار بفروش", true], ["2 نوشابه بخر", true], ["به دانشگاه برو", false]], 0.66, "+2,000", "+120 XP"],
		["شب امن", "کلانتری", [["3 شیفت شبانه کار کن", false], ["داغی زیر 20 بماند", true], ["به یک مسافر کمک کن", false]], 0.33, "+3,500", "+200 XP"]]
	for i in ms.size():
		var m: Array = ms[i]
		var y := 316.0 + i * 396.0
		_card(Rect2(20, y, 680, 380), Color(VIOLET, 0.3))
		_emboss("missions", Rect2(596, y + 14, 90, 90), "violet")
		_big(Rect2(250, y + 20, 336, 46), m[0], 32, "#FFFFFF", "#E0D4FF")
		_chip(Rect2(430, y + 70, 156, 36), m[1], Color("#3552C8"), 16)
		var objs: Array = m[2]
		for k in objs.size():
			var o: Array = objs[k]
			_emboss("check" if o[1] else "clock", Rect2(622, y + 118 + k * 56, 50, 50), "emerald" if o[1] else "steel")
			_txt(Rect2(200, y + 124 + k * 56, 414, 38), o[0], 19, Color.WHITE if not o[1] else Color("#9FE3B0"))
		_pbar(Rect2(200, y + 296, 480, 30), m[3], VIOLET, "%d از 3" % int(round(m[3] * 3)))
		_chip(Rect2(40, y + 120, 140, 44), m[4], Color("#B8860B"), 19)
		_chip(Rect2(40, y + 172, 140, 44), m[5], Color("#3552C8"), 17)
		_btn(Rect2(40, y + 282, 140, 62), "ادامه", "blue")


func _s_leaderboard() -> void:
	_hdr("رتبه‌ها", Color("#8A5A10"))
	var chips := ["ثروت", "جرم", "کار", "جناح"]
	for i in chips.size():
		_chip(Rect2(560 - i * 150, 256, 140, 42), chips[i], Color("#B8860B") if i == 0 else Color("#3A4468"), 18)
	var pod := [[1, "رضا", "12.4M", 260.0, 250.0, "gold"], [2, "مینا", "9.8M", 470.0, 200.0, "steel"], [3, "دانا", "7.1M", 50.0, 170.0, "fox"]]
	for p in pod:
		var x: float = p[3]
		var h: float = p[4]
		var base_y := 700.0 - h
		_card(Rect2(x, base_y, 200, h + 10), Color(GOLD, 0.35) if p[0] == 1 else Color(0, 0, 0, 0))
		_big(Rect2(x, base_y + 12, 200, 60), str(p[0]), 50, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
		_avatar(Rect2(x + 40, base_y - 140, 120, 120), ["lion", "eagle", "fox"][p[0] - 1], p[5], Color("#3A2A08") if p[0] == 1 else Color("#18204A"))
		ui.add_child(_label(p[1], display_font, 24, Color.WHITE, Rect2(x, base_y + 76, 200, 34), HORIZONTAL_ALIGNMENT_CENTER, 4))
		_txt(Rect2(x, base_y + 108, 200, 28), p[2], 17, Color("#FFD66B"), HORIZONTAL_ALIGNMENT_CENTER)
	var rows := [[4, "علی", "5.2M"], [5, "نیما", "4.9M"], [6, "سحر", "3.3M"], [7, "امید", "2.8M"]]
	for i in rows.size():
		var r: Array = rows[i]
		_row(Rect2(20, 724 + i * 82, 680, 74), "person", "steel", "%d   %s" % [r[0], r[1]], "", r[2], Color("#FFD66B"))
	_row(Rect2(20, 1056, 680, 60), "fox", "fox", "142   سارا (تو)", "", "101,950", Color("#FFD66B"), Color(FIROUZEH, 0.9))


# -- economy ----------------------------------------------------------------------------------------
func _s_economy() -> void:
	_hdr("اقتصاد", Color("#1E7A45"))
	_card(Rect2(20, 256, 680, 150), Color(LEAF, 0.3))
	_emboss("coins", Rect2(600, 268, 84, 84), "gold")
	_big(Rect2(400, 270, 190, 50), "12,450", 34, "#FFF6C8", "#FFB21F")
	_txt(Rect2(400, 318, 190, 26), "نقد", 16, Color("#E8D6A8"))
	_emboss("bank", Rect2(318, 268, 72, 72), "sapphire")
	_big(Rect2(160, 270, 150, 50), "86,300", 30, "#EAF1FF", "#8FB0FF")
	_txt(Rect2(160, 318, 150, 26), "بانک", 16, Color("#C8D4F5"))
	_spark(Rect2(40, 280, 110, 60), [60, 64, 61, 70, 74, 72, 80, 86], LEAF)
	_txt(Rect2(40, 346, 360, 28), "ارزش خالص 101,950  ·  +6٪ این هفته", 16, Color("#9FE3B0"), HORIZONTAL_ALIGNMENT_LEFT)
	var tiles := [["box", "gold", "کوله‌پشتی", "ارزش 1,240", 0], ["cart", "gold", "بازار", "4 سفارش فعال", 2], ["market", "teal", "مغازه‌ها", "8 مغازه در شهر", 0],
		["gavel", "violet", "مزایده", "3 در جریان", 1], ["factory", "gold", "شرکت‌های من", "2 شرکت  ·  +12,400", 0], ["house", "emerald", "ملک", "1 خانه  ·  1 مغازه", 0],
		["chart", "emerald", "بورس", "سبد +4.2٪", 0], ["crowncoin", "sapphire", "وام و پس‌انداز", "امتیاز اعتبار 720", 0], ["shield", "steel", "بیمه", "درمان فعال", 0]]
	for i in tiles.size():
		var t: Array = tiles[i]
		var r := Rect2(478 - (i % 3) * 229, 422 + (i / 3) * 232, 222, 222)
		_tile(r, t[0], t[1], t[2], t[3], t[4])


func _s_inventory() -> void:
	_hdr("کوله‌پشتی", Color("#8A5A10"))
	_card(Rect2(20, 256, 680, 76))
	_emboss("coins", Rect2(612, 262, 64, 64), "gold")
	_txt(Rect2(40, 256, 560, 76), "ارزش کل با قیمت امروز بازار:  1,240 نیل", 20, Color("#FFE9B0"))
	var cats := ["همه", "خوراکی", "ابزار", "کالا"]
	for i in cats.size():
		_chip(Rect2(560 - i * 150, 348, 140, 42), cats[i], FIROUZEH if i == 0 else Color("#3A4468"), 18)
	var items := [["bread", "amber", "نان", 4, 12], ["soda", "ruby", "نوشابه", 2, 18], ["pill", "emerald", "دارو", 1, 160], ["pistol", "steel", "کلت", 1, 2400],
		["phone", "sapphire", "گوشی", 1, 9500], ["ore", "steel", "سنگ آهن", 12, 85], ["toaster", "teal", "توستر", 1, 18500], ["ring", "gold", "انگشتر", 1, 42000],
		["box", "gold", "جعبه‌ی جایزه", 1, 0], ["book", "violet", "کتاب", 2, 300], ["keys", "gold", "کلید خانه", 1, 0], ["tag", "emerald", "بلیت", 1, 600]]
	for i in items.size():
		var it: Array = items[i]
		var r := Rect2(536 - (i % 4) * 172, 406 + (i / 4) * 188, 164, 178)
		var sel := i == 3
		_inset(r, Color(FIROUZEH, 0.95) if sel else Color(GOLD, 0.35))
		_emboss(it[0], Rect2(r.position.x + 32, r.position.y + 8, 100, 100), it[1])
		ui.add_child(_label(it[2], display_font, 20, Color.WHITE, Rect2(r.position.x, r.position.y + 110, r.size.x, 30), HORIZONTAL_ALIGNMENT_CENTER, 4))
		_txt(Rect2(r.position.x, r.position.y + 140, r.size.x, 26), ("%s نیل" % _n(it[4])) if it[4] > 0 else "—", 15, Color("#FFD66B"), HORIZONTAL_ALIGNMENT_CENTER)
		if it[3] > 1:
			_chip(Rect2(r.position.x + 8, r.position.y + 8, 56, 32), "×%d" % it[3], Color("#3552C8"), 16)
	_card(Rect2(20, 982, 680, 132), Color(FIROUZEH, 0.35))
	_emboss("pistol", Rect2(598, 994, 84, 84), "steel")
	_big(Rect2(420, 994, 170, 46), "کلت", 30, "#FFFFFF", "#DDE6FF")
	_pbar(Rect2(420, 1046, 170, 24), 0.72, LEAF, "دوام 72٪")
	_btn(Rect2(290, 1004, 120, 60), "هدیه", "blue")
	_btn(Rect2(160, 1004, 120, 60), "فروش", "gold")
	_btn(Rect2(30, 1004, 120, 60), "مجهز", "green")


func _n(v: int) -> String:
	var s := str(v)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


func _s_market() -> void:
	_hdr("بازار", Color("#1E7A45"))
	_card(Rect2(20, 256, 680, 110))
	_emboss("bread", Rect2(600, 262, 94, 94), "amber")
	_big(Rect2(380, 266, 210, 46), "نان", 34, "#FFFFFF", "#FFE6B8")
	_txt(Rect2(330, 314, 260, 28), "بهترین قیمت 12  ·  −2.1٪ امروز", 16, Color("#FFC0C0"))
	_spark(Rect2(44, 280, 250, 64), [14, 13.6, 13.8, 13.1, 12.9, 13.2, 12.4, 12.0], ANAR)
	_chip(Rect2(366, 382, 334, 50), "خرید فوری", FIROUZEH, 21)
	_chip(Rect2(20, 382, 334, 50), "فروش", Color("#3A4468"), 21)
	_txt(Rect2(40, 446, 640, 30), "فروشنده‌ها  ·  ارزان‌ترین اول  ·  بازار فنویک", 16, Color("#AEB8D8"))
	var sellers := [["Aftab Market", 12, 340], ["Reza", 13, 20], ["Mina", 14, 150], ["Ali", 15, 60]]
	for i in sellers.size():
		var s: Array = sellers[i]
		var r := Rect2(20, 482 + i * 86, 680, 78)
		_inset(r, Color(FIROUZEH, 0.9) if i == 0 else Color(GOLD, 0.3))
		_avatar(Rect2(620, r.position.y + 9, 60, 60), "person", "steel", Color("#18204A"))
		ui.add_child(_label(s[0], display_font, 23, Color.WHITE, Rect2(330, r.position.y, 280, 78), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_txt(Rect2(190, r.position.y, 130, 78), "× %d" % s[2], 18, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
		ui.add_child(_label(str(s[1]), display_font, 30, Color("#FFD66B"), Rect2(40, r.position.y, 140, 78), HORIZONTAL_ALIGNMENT_LEFT, 5))
	_sec(836, "تعداد")
	_btn(Rect2(600, 890, 80, 72), "+", "blue")
	_inset(Rect2(130, 890, 460, 72))
	_big(Rect2(130, 890, 460, 72), "25", 40, "#FFFFFF", "#DDE6FF", HORIZONTAL_ALIGNMENT_CENTER)
	_btn(Rect2(40, 890, 80, 72), "−", "blue")
	var presets := ["10", "25", "100", "همه"]
	for i in presets.size():
		_chip(Rect2(530 - i * 163, 974, 150, 40), presets[i], Color("#3A4468") if i != 1 else FIROUZEH, 18)
	_btn(Rect2(20, 1026, 680, 88), "خرید 25 نان  ·  308 نیل", "green")


## The bank: deposit or withdraw any amount. The amount is typed on the
## game's own keypad (the phone keyboard over a Godot web page is
## unreliable and hides the field), topped up with quick amounts, and
## checked against what the player holds before the button says exactly
## what will happen.
func _s_bank() -> void:
	_hdr("بانک", Color("#2A45B0"))
	_card(Rect2(20, 256, 680, 128), Color(LAPIS, 0.5))
	_emboss("bank", Rect2(596, 266, 90, 90), "sapphire")
	_txt(Rect2(330, 268, 256, 26), "موجودی بانک", 17, Color("#C8D4F5"))
	_big(Rect2(300, 292, 286, 60), "86,300", 44, "#EAF1FF", "#8FB0FF")
	_emboss("coins", Rect2(230, 276, 64, 64), "gold")
	_txt(Rect2(40, 268, 186, 26), "نقد", 17, Color("#E8D6A8"), HORIZONTAL_ALIGNMENT_LEFT)
	_big(Rect2(40, 292, 186, 60), "12,450", 34, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_LEFT)
	# deposit or withdraw
	_chip(Rect2(366, 400, 334, 52), "واریز", Color("#B8860B"), 22)
	_chip(Rect2(20, 400, 334, 52), "برداشت", Color("#3A4468"), 22)
	# the amount
	var field := _frame(Rect2(20, 468, 680, 104), 24.0, Color(0.02, 0.03, 0.08, 0.92), Color(0.05, 0.06, 0.14, 0.92), Color(GOLD, 0.95), 0.0, 3.0)
	(field.material as ShaderMaterial).set_shader_parameter("glow", Color(GOLD, 0.35))
	(field.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	_big(Rect2(130, 474, 460, 90), "7,500", 60, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(600, 468, 80, 104), "نیل", 20, Color("#E8D6A8"), HORIZONTAL_ALIGNMENT_CENTER)
	var caret := ColorRect.new()
	caret.layout_direction = Control.LAYOUT_DIRECTION_LTR
	caret.position = Vector2(470, 494)
	caret.size = Vector2(4, 56)
	caret.color = Color("#FFD66B")
	ui.add_child(caret)
	var clear := _button(Rect2(40, 494, 60, 54), Color("#8E97B4"), Color("#4A536E"), Color("#1E2436"), 27.0, 5.0)
	clear.add_child(_label("×", display_font, 40, Color.WHITE, Rect2(0, -10, 60, 64), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_txt(Rect2(40, 578, 640, 30), "نقد تو 12,450  ·  بعد از واریز: 4,950 نقد، 93,800 در بانک", 16, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	# quick amounts add to the field
	var quick := ["+1,000", "+5,000", "+10,000", "همه"]
	for i in quick.size():
		_chip(Rect2(530 - i * 170, 616, 160, 48), quick[i], Color("#B8860B") if i == 3 else Color("#3552C8"), 20)
	# the keypad: digits read left to right, as on every phone
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "000", "0", "⌫"]
	for i in keys.size():
		var col := i % 3
		var row := i / 3
		var r := Rect2(20 + col * 231, 680 + row * 84, 218, 76)
		var kind := "steel"
		if keys[i] == "⌫":
			kind = "red"
		elif keys[i] == "000":
			kind = "blue"
		_btn(r, keys[i], kind)
	_btn(Rect2(20, 1022, 680, 92), "واریز 7,500 نیل", "gold")
	_chip(Rect2(40, 1044, 150, 40), "بدون کارمزد", LEAF, 16)


func _s_company() -> void:
	_hdr("فولاد البرز", Color("#8A5A10"))
	_card(Rect2(20, 256, 680, 190), Color(GOLD, 0.3))
	_plate("factory", Rect2(590, 272, 96, 96), "gold", Color("#3A2A08"))
	_txt(Rect2(300, 276, 280, 28), "کارخانه  ·  سطح 3  ·  مال تو", 17, Color("#FFE9B0"))
	_big(Rect2(300, 304, 280, 56), "159,000", 40, "#FFF6C8", "#FFB21F")
	_txt(Rect2(300, 360, 280, 28), "صندوق شرکت", 16, Color("#E8D6A8"))
	_spark(Rect2(44, 286, 230, 80), [4, 6, 5, 8, 9, 7, 11, 12.4], LEAF)
	_txt(Rect2(44, 372, 230, 28), "سود دیروز +12,400", 17, Color("#9FE3B0"), HORIZONTAL_ALIGNMENT_LEFT)
	_sec(462, "خط تولید  ·  2 از 3")
	var orders := [["ابزار × 24", "14:02  ·  تا 19:32", 0.7], ["قطعه‌ی فولادی × 60", "42:10  ·  تا 20:00", 0.3]]
	for i in orders.size():
		var o: Array = orders[i]
		var r := Rect2(20, 516 + i * 104, 680, 94)
		_row(r, "arm", "gold", o[0], o[1])
		_pbar(Rect2(40, r.position.y + 34, 200, 28), o[2], LEAF, "%d٪" % int(o[2] * 100))
	_inset(Rect2(20, 724, 680, 94), Color(FIROUZEH, 0.6))
	_btn(Rect2(180, 740, 360, 62), "+ سفارش تولید تازه", "green")
	_sec(834, "کارکنان  ·  8 از 10")
	for i in 8:
		_avatar(Rect2(612 - i * 80, 890, 70, 70), "person", "steel" if i > 0 else "gold", Color("#18204A") if i > 0 else Color("#3A2A08"))
	_chip(Rect2(40, 976, 200, 40), "2 جای خالی", FIROUZEH, 17)
	_btn(Rect2(478, 1030, 222, 84), "انبار", "blue")
	_btn(Rect2(249, 1030, 222, 84), "استخدام", "green")
	_btn(Rect2(20, 1030, 222, 84), "تحقیق", "steel")


func _s_property() -> void:
	_hdr("ملک", Color("#1E7A45"))
	_sec(256, "املاک من")
	_row(Rect2(20, 310, 680, 96), "house", "emerald", "آپارتمان 2 خوابه", "مرکز شهر  ·  در حال سکونت  ·  +60 انرژی", "", Color.WHITE, Color(FIROUZEH, 0.8))
	_row(Rect2(20, 416, 680, 96), "market", "gold", "مغازه‌ی بازار", "اجاره داده شده به رضا", "+2,400/روز", LEAF)
	_sec(528, "برای فروش")
	var list := [["ویلای استخردار", "باغ‌ویلاها  ·  420 متر  ·  4 خواب", "2,400,000"], ["خانه‌ی حیاط‌دار", "محله‌ی شمالی  ·  180 متر", "380,000"], ["زمین صنعتی", "شهرک صنعتی  ·  800 متر", "85,000"]]
	for i in list.size():
		var l: Array = list[i]
		var y := 584.0 + i * 176.0
		_card(Rect2(20, y, 680, 166))
		_plate(["house", "house", "factory"][i], Rect2(584, y + 18, 100, 100), ["emerald", "teal", "steel"][i], Color("#18204A"))
		_big(Rect2(240, y + 18, 336, 44), l[0], 30, "#FFFFFF", "#DFFFE6")
		_txt(Rect2(240, y + 62, 336, 28), l[1], 16, Color("#AEB8D8"))
		_big(Rect2(240, y + 96, 336, 50), l[2] + " نیل", 32, "#FFF6C8", "#FFB21F")
		_btn(Rect2(40, y + 22, 180, 58), "بازدید", "blue")
		_btn(Rect2(40, y + 90, 180, 58), "خرید", "green")


func _s_stocks() -> void:
	_hdr("بورس", Color("#1E6A8A"))
	_card(Rect2(20, 256, 680, 150), Color(LEAF, 0.35))
	_txt(Rect2(300, 270, 380, 28), "ارزش سبد تو", 17, Color("#C8D4F5"))
	_big(Rect2(300, 298, 380, 60), "48,200 نیل", 44, "#E8FFE9", "#4CC47E")
	_chip(Rect2(520, 356, 160, 38), "+4.2٪ امروز", LEAF, 17)
	_spark(Rect2(44, 276, 240, 100), [40, 42, 41, 44, 43, 46, 45, 48.2], LEAF)
	var st := [["فولاد البرز", "FALB", 142, 3.1, [130, 133, 131, 136, 138, 137, 142]], ["پرواز نو", "PARV", 88, -1.4, [92, 91, 90, 89, 90, 88, 88]],
		["داروسازی مهر", "MEHR", 210, 0.8, [205, 207, 206, 209, 208, 210, 210]], ["گجت دانا", "DANA", 64, 7.9, [55, 56, 58, 57, 60, 62, 64]],
		["نان آفتاب", "AFTB", 31, -2.2, [33, 32.5, 32, 31.8, 31.5, 31.2, 31]], ["حمل‌ونقل کسمور", "KESS", 118, 0.0, [118, 117, 118, 119, 118, 118, 118]]]
	for i in st.size():
		var s: Array = st[i]
		var r := Rect2(20, 422 + i * 114, 680, 104)
		var up: bool = s[3] >= 0.0
		var col := LEAF if s[3] > 0.0 else (ANAR if s[3] < 0.0 else Color("#AEB8D8"))
		_inset(r)
		ui.add_child(_label(s[0], display_font, 24, Color.WHITE, Rect2(380, r.position.y + 10, 300, 40), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_txt(Rect2(380, r.position.y + 52, 300, 28), s[1], 15, Color("#8E97B4"))
		_spark(Rect2(220, r.position.y + 22, 140, 58), s[4], col)
		ui.add_child(_label(str(s[2]), display_font, 30, Color.WHITE, Rect2(40, r.position.y + 8, 160, 44), HORIZONTAL_ALIGNMENT_LEFT, 5))
		_txt(Rect2(40, r.position.y + 54, 160, 30), ("%s%.1f٪" % ["+" if up else "", s[3]]), 18, col, HORIZONTAL_ALIGNMENT_LEFT)


# -- society ----------------------------------------------------------------------------------------
func _s_society() -> void:
	_hdr("جامعه", Color("#5A3AA8"))
	var tiles := [["inbox", "sapphire", "پیام‌ها", "3 نخوانده", 3], ["society", "teal", "دوستان", "12 دوست  ·  4 آنلاین", 1],
		["lion", "gold", "جناح", "شیرهای البرز", 0], ["rank", "gold", "دولت شهر", "مالیات بازار 2.5٪", 0],
		["vote", "violet", "انتخابات", "رأی‌گیری شهرداری باز", 1], ["gavel", "steel", "قوانین", "2 لایحه در مجلس", 0],
		["swords", "ruby", "ارتش و جنگ", "جنگ با کالدریس  ·  روز 3", 0], ["podium", "gold", "رتبه‌ها", "رتبه‌ی 142", 0]]
	for i in tiles.size():
		var t: Array = tiles[i]
		var r := Rect2(366 - (i % 2) * 346, 256 + (i / 2) * 214, 334, 202)
		_tile(r, t[0], t[1], t[2], t[3], t[4], Color(ANAR, 0.45) if i == 6 else Color(0, 0, 0, 0))


func _s_inbox() -> void:
	_hdr("پیام‌ها", Color("#2A45B0"))
	var chips := ["همه", "کار", "اقتصاد", "جناح"]
	for i in chips.size():
		_chip(Rect2(560 - i * 150, 256, 140, 42), chips[i], FIROUZEH if i == 0 else Color("#3A4468"), 18)
	var msgs := [["work", "teal", "شیفت تمام شد", "1,850 نیل دستمزد گرفتی", "2 دقیقه", true],
		["cart", "gold", "کالایت فروخته شد", "4 نان در بازار فنویک  ·  +48", "10 دقیقه", true],
		["lion", "gold", "دعوت به جناح", "شیرهای البرز تو را دعوت کرد", "25 دقیقه", true],
		["rank", "gold", "خبر شهر", "شهردار مالیات بازار را نصف کرد", "1 ساعت", false],
		["vote", "violet", "انتخابات", "رأی‌گیری شهرداری شروع شد", "3 ساعت", false],
		["society", "teal", "درخواست دوستی", "مینا می‌خواهد دوستت باشد", "5 ساعت", false],
		["gift", "ruby", "جایزه‌ی روزانه", "بسته‌ی امروز آماده است", "دیروز", false]]
	for i in msgs.size():
		var m: Array = msgs[i]
		var r := Rect2(20, 314 + i * 114, 680, 104)
		_row(r, m[0], m[1], m[2], m[3], "", Color.WHITE, Color(FIROUZEH, 0.8) if m[5] else Color(GOLD, 0.3))
		_txt(Rect2(40, r.position.y + 12, 160, 26), m[4], 15, Color("#8E97B4"), HORIZONTAL_ALIGNMENT_LEFT)
		if m[5]:
			var dot := Polygon2D.new()
			var pts := PackedVector2Array()
			for k in 16:
				pts.append(Vector2(52, r.position.y + 70) + Vector2(cos(k * TAU / 16), sin(k * TAU / 16)) * 8)
			dot.polygon = pts
			dot.color = FIROUZEH
			ui.add_child(dot)
		if i == 2:
			_btn(Rect2(40, r.position.y + 40, 110, 52), "قبول", "green")
			_btn(Rect2(160, r.position.y + 40, 100, 52), "رد", "steel")


func _s_faction() -> void:
	_hdr("شیرهای البرز", Color("#8A5A10"))
	_card(Rect2(20, 256, 680, 200), Color(GOLD, 0.35))
	_plate("lion", Rect2(560, 270, 126, 126), "gold", Color("#3A2A08"))
	_txt(Rect2(240, 276, 310, 28), "سطح 4  ·  رتبه‌ی 7 شهر", 17, Color("#FFE9B0"))
	_big(Rect2(240, 304, 310, 50), "18 از 25 عضو", 32, "#FFFFFF", "#FFE6B8")
	_emboss("crowncoin", Rect2(40, 280, 70, 70), "gold")
	_big(Rect2(40, 350, 300, 44), "صندوق 420,000", 26, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_LEFT)
	_chip(Rect2(430, 404, 250, 40), "رئیس: سارا", Color("#B8860B"), 17)
	_card(Rect2(20, 472, 680, 250), Color(ANAR, 0.45))
	_txt(Rect2(260, 488, 420, 28), "جرم سازمان‌یافته", 17, Color("#FFC0C4"))
	_big(Rect2(260, 516, 420, 50), "سرقت از بانک مرکزی", 32, "#FFFFFF", "#FFD0D4")
	_ring(Rect2(40, 490, 200, 200), 0.62, ANAR)
	_big(Rect2(40, 556, 200, 60), "02:14:30", 30, "#FFFFFF", "#FFC0C4", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(40, 610, 200, 28), "تا شروع", 15, Color("#FFD0D4"), HORIZONTAL_ALIGNMENT_CENTER)
	for i in 5:
		_avatar(Rect2(612 - i * 74, 578, 64, 64), ["fox", "eagle", "lion", "person", "person"][i], ["fox", "sapphire", "gold", "steel", "steel"][i], Color("#18204A") if i < 4 else Color("#0A0C18"))
	_txt(Rect2(260, 646, 420, 28), "4 از 5 نفر  ·  یک جای خالی: راننده", 16, Color("#FFD0D4"))
	_btn(Rect2(260, 676, 200, 38), "پیوستن", "red")
	_sec(738, "اعضا")
	var mem := [["fox", "fox", "سارا", "رئیس", true], ["eagle", "sapphire", "مینا", "معاون", true], ["lion", "gold", "رضا", "عضو", false]]
	for i in mem.size():
		var m: Array = mem[i]
		var r := Rect2(20, 792 + i * 90, 680, 82)
		_row(r, m[0], m[1], m[2], m[3])
		_chip(Rect2(40, r.position.y + 20, 120, 40), "آنلاین" if m[4] else "2 ساعت پیش", LEAF if m[4] else Color("#3A4468"), 16)
	_btn(Rect2(366, 1066, 334, 50), "صندوق جناح", "gold")
	_btn(Rect2(20, 1066, 334, 50), "دعوت", "blue")


func _s_elections() -> void:
	_hdr("انتخابات", Color("#5A3AA8"))
	_card(Rect2(20, 256, 680, 160), Color(VIOLET, 0.4))
	_plate("vote", Rect2(590, 272, 96, 96), "violet", Color("#2A1860"))
	_big(Rect2(260, 276, 320, 50), "شهردار فنویک", 34, "#FFFFFF", "#E0D4FF")
	_txt(Rect2(260, 326, 320, 28), "رأی‌گیری تا پنجشنبه 20:00", 17, Color("#C8B8F0"))
	_chip(Rect2(40, 280, 200, 44), "1 روز 6 ساعت", VIOLET, 18)
	_txt(Rect2(40, 340, 300, 40), "2,340 رأی داده شده", 17, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	var cands := [["lion", "gold", "رضا", "«بازار آزاد، مالیات کم»", 0.46, "1,076", false], ["eagle", "sapphire", "مینا", "«امنیت، حمل‌ونقل ارزان»", 0.38, "889", true],
		["fox", "fox", "دانا", "«آموزش رایگان»", 0.16, "375", false]]
	for i in cands.size():
		var c: Array = cands[i]
		var y := 434.0 + i * 186.0
		_card(Rect2(20, y, 680, 174), Color(FIROUZEH, 0.4) if c[6] else Color(0, 0, 0, 0))
		_avatar(Rect2(580, y + 18, 104, 104), c[0], c[1], Color("#18204A"))
		_big(Rect2(260, y + 18, 310, 46), c[2], 32, "#FFFFFF", "#DDE6FF")
		_txt(Rect2(260, y + 64, 310, 28), c[3], 17, Color("#C9D2EE"))
		_pbar(Rect2(260, y + 110, 410, 32), c[4], [SAFFRON, LAPIS, ANAR][i], "%d٪  ·  %s رأی" % [int(c[4] * 100), c[5]])
		if c[6]:
			_chip(Rect2(40, y + 44, 190, 52), "✓ رأی تو", LEAF, 20)
		else:
			_btn(Rect2(40, y + 40, 190, 64), "رأی بده", "blue")
	_txt(Rect2(40, 1000, 640, 60), "هر شهروند بالای سطح 5 با 3 روز سکونت در شهر یک رأی دارد.", 16, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_btn(Rect2(20, 1060, 680, 56), "نامزد شو  ·  سپرده 25,000", "gold")


func _s_government() -> void:
	_hdr("دولت شهر", Color("#8A5A10"))
	_card(Rect2(20, 256, 680, 110))
	_avatar(Rect2(596, 266, 90, 90), "lion", "gold", Color("#3A2A08"))
	_big(Rect2(260, 270, 326, 46), "شهردار: رضا", 30, "#FFFFFF", "#FFE6B8")
	_txt(Rect2(260, 316, 326, 28), "12 روز تا پایان دوره  ·  شورا: 5 نفر", 16, Color("#C9D2EE"))
	_sec(382, "اهرم‌ها")
	var levers := [["cart", "gold", "مالیات بازار", "2.5٪", 0.25], ["work", "teal", "حداقل دستمزد", "900", 0.45], ["bus", "sapphire", "کرایه‌ی اتوبوس", "40", 0.3],
		["handcuffs", "steel", "وثیقه‌ی زندان", "5,000", 0.5], ["bank", "sapphire", "کارمزد بانک", "0.5٪", 0.1]]
	for i in levers.size():
		var l: Array = levers[i]
		var r := Rect2(20, 436 + i * 92, 680, 84)
		_inset(r)
		_plate(l[0], Rect2(616, r.position.y + 10, 64, 64), l[1])
		ui.add_child(_label(l[2], display_font, 22, Color.WHITE, Rect2(380, r.position.y, 226, 84), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_btn(Rect2(314, r.position.y + 16, 54, 52), "+", "blue")
		_pbar(Rect2(116, r.position.y + 28, 188, 28), l[4], SAFFRON, l[3])
		_btn(Rect2(52, r.position.y + 16, 54, 52), "−", "blue")
	_sec(900, "بودجه‌ی شهر")
	var parts := [["امنیت", 0.3, ANAR], ["آموزش", 0.2, VIOLET], ["سلامت", 0.2, LEAF], ["حمل‌ونقل", 0.15, LAPIS], ["رفاه", 0.15, SAFFRON]]
	var x := 680.0
	for p in parts:
		var w: float = 640.0 * p[1]
		x -= w
		var seg := ColorRect.new()
		seg.layout_direction = Control.LAYOUT_DIRECTION_LTR
		seg.position = Vector2(x, 956)
		seg.size = Vector2(w - 3, 40)
		seg.color = p[2]
		ui.add_child(seg)
		_txt(Rect2(x, 956, w - 3, 40), "%d٪" % int(p[1] * 100), 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
		_txt(Rect2(x, 1000, w - 3, 30), p[0], 15, Color("#DDE3F5"), HORIZONTAL_ALIGNMENT_CENTER)
	_btn(Rect2(20, 1046, 680, 70), "پیشنهاد تغییر به شورا", "gold")


func _s_war() -> void:
	_hdr("اتاق جنگ", Color("#A01E2A"))
	_card(Rect2(20, 256, 680, 230), Color(ANAR, 0.45))
	_plate("eagle", Rect2(566, 270, 118, 118), "sapphire", Color("#101E60"))
	_txt(Rect2(540, 392, 170, 30), "فنویک", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	_plate("lion", Rect2(36, 270, 118, 118), "ruby", Color("#3A0E1E"))
	_txt(Rect2(10, 392, 170, 30), "کالدریس", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	_big(Rect2(170, 276, 380, 50), "روز 3 جنگ", 34, "#FFFFFF", "#FFD0D4", HORIZONTAL_ALIGNMENT_CENTER)
	var tug := ColorRect.new()
	tug.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tug.position = Vector2(180, 340)
	tug.size = Vector2(360, 40)
	tug.color = ANAR
	ui.add_child(tug)
	var ours := ColorRect.new()
	ours.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ours.position = Vector2(180 + 360 * 0.42, 340)
	ours.size = Vector2(360 * 0.58, 40)
	ours.color = LAPIS
	ui.add_child(ours)
	_txt(Rect2(180, 340, 360, 40), "58٪   ·   42٪", 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 5)
	_chip(Rect2(180, 396, 170, 40), "خسارت ما 12٪", ANAR, 16)
	_chip(Rect2(370, 396, 170, 40), "خسارت آن‌ها 21٪", LAPIS, 16)
	_sec(502, "عملیات")
	var ops := [["u_fighter", "sapphire", "حمله‌ی هوایی", "4 جنگنده  ·  هدف: فرودگاه کالدریس", "آماده", ""], ["u_ballistic", "ruby", "حمله‌ی موشکی", "12 موشک  ·  هدف: پادگان", "", "18:40"],
		["u_tank", "emerald", "پیشروی زمینی", "3 گردان  ·  2 ساعت تا مرز", "آماده", ""]]
	for i in ops.size():
		var o: Array = ops[i]
		var r := Rect2(20, 556 + i * 152, 680, 142)
		_inset(r, Color(ANAR, 0.5))
		_plate(o[0], Rect2(590, r.position.y + 20, 96, 96), o[1], Color("#18204A"))
		ui.add_child(_label(o[2], display_font, 26, Color.WHITE, Rect2(240, r.position.y + 16, 340, 40), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_txt(Rect2(240, r.position.y + 60, 340, 28), o[3], 16, Color("#C9D2EE"))
		if o[5] != "":
			_ring(Rect2(60, r.position.y + 16, 110, 110), 0.4, SAFFRON)
			_txt(Rect2(60, r.position.y + 16, 110, 110), o[5], 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
		else:
			_btn(Rect2(40, r.position.y + 36, 180, 70), "پرتاب", "red")
	# the war's other rooms
	var rooms := [["u_troops", "نیروها", "cream"], ["u_ballistic", "زرادخانه", "ruby"], ["u_radar", "پدافند", "teal"]]
	for i in rooms.size():
		var rm: Array = rooms[i]
		var r := Rect2(478.0 - i * 229.0, 1016, 222, 88)
		var b := _button(r, Color("#3F55A8"), Color("#1A2560"), Color("#0A1030"), 22.0, 7.0)
		_emboss(rm[0], Rect2(r.end.x - 78, r.position.y + 6, 70, 70), rm[2])
		b.add_child(_glabel(rm[1], display_font, 27, "#FFFFFF", "#FFD66B", Rect2(8, 0, r.size.x - 88, r.size.y - 7), HORIZONTAL_ALIGNMENT_CENTER, 6))


# -- the world ----------------------------------------------------------------------------------------
func _s_travel() -> void:
	_hdr("سفر", Color("#1E6A8A"))
	var map := _frame(Rect2(20, 256, 680, 500), 26.0, Color("#16345A"), Color("#0B1B34"), GOLD, 0.03, 2.5)
	(map.material as ShaderMaterial).set_shader_parameter("glow", Color("#3FA8FF", 0.35))
	# land masses, as soft polygons
	var lands := [[Vector2(80, 330), Vector2(330, 300), Vector2(420, 380), Vector2(400, 560), Vector2(250, 640), Vector2(90, 560)],
		[Vector2(470, 300), Vector2(660, 320), Vector2(670, 520), Vector2(560, 700), Vector2(460, 600)]]
	for l in lands:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array(l)
		poly.color = Color("#3F6B4E")
		ui.add_child(poly)
	var cities := {"فنویک": Vector2(210, 420), "استمارچ": Vector2(130, 520), "آلدرین": Vector2(320, 540), "برنهاون": Vector2(560, 400),
		"کسمور": Vector2(600, 560), "کالدریس": Vector2(250, 330), "وانتور": Vector2(520, 640)}
	var routes := [["فنویک", "برنهاون", true], ["فنویک", "استمارچ", false], ["فنویک", "آلدرین", false], ["فنویک", "کالدریس", false], ["برنهاون", "کسمور", false], ["کسمور", "وانتور", false]]
	for rt in routes:
		var ln := Line2D.new()
		ln.width = 5.0 if rt[2] else 2.5
		ln.default_color = Color(GOLD, 1.0) if rt[2] else Color(1, 1, 1, 0.35)
		ln.antialiased = true
		ln.add_point(cities[rt[0]])
		ln.add_point(cities[rt[1]])
		ui.add_child(ln)
	for c in cities:
		var p: Vector2 = cities[c]
		var here: bool = c == "فنویک"
		var dest: bool = c == "برنهاون"
		if here or dest:
			_ring(Rect2(p - Vector2(34, 34), Vector2(68, 68)), 1.0, FIROUZEH if here else GOLD)
		_badge("person", Rect2(p - Vector2(18, 18), Vector2(36, 36)), FIROUZEH if here else (SAFFRON if dest else Color("#5A6488")), GOLD)
		((ui.get_child(ui.get_child_count() - 1) as CanvasItem).material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
		_txt(Rect2(p.x - 80, p.y + 20, 160, 30), c, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 5)
	_plane_icon(Vector2(385, 400))
	_card(Rect2(20, 772, 680, 342), Color(GOLD, 0.3))
	_big(Rect2(260, 784, 420, 50), "برنهاون", 34, "#FFFFFF", "#FFE6B8")
	_txt(Rect2(260, 832, 420, 28), "180 کیلومتر  ·  دولت کامن‌ولث", 16, Color("#C9D2EE"))
	var modes := [["bus", "sapphire", "اتوبوس", "2:10  ·  40 نیل  ·  −10⚡"], ["train", "teal", "قطار", "1:05  ·  120 نیل  ·  −6⚡"], ["plane", "gold", "هواپیما", "0:25  ·  600 نیل  ·  −2⚡"]]
	for i in modes.size():
		var m: Array = modes[i]
		_row(Rect2(236, 870 + i * 78, 444, 70), m[0], m[1], m[2], m[3], "", Color.WHITE, Color(GOLD, 0.95) if i == 2 else Color(GOLD, 0.3))
	_btn(Rect2(40, 930, 180, 110), "سفر", "gold")


func _plane_icon(at: Vector2) -> void:
	_emboss("plane", Rect2(at - Vector2(32, 32), Vector2(64, 64)), "gold")


func _s_levelup() -> void:
	# the city behind, dimmed, and a celebration in front
	var dim := ColorRect.new()
	dim.layout_direction = Control.LAYOUT_DIRECTION_LTR
	dim.size = Vector2(W, H)
	dim.color = Color(0.01, 0.01, 0.04, 0.7)
	ui.add_child(dim)
	for k in 16:
		var ray := Polygon2D.new()
		var a0 := k * TAU / 16.0
		ray.polygon = PackedVector2Array([Vector2(360, 540), Vector2(360, 540) + Vector2(cos(a0 - 0.08), sin(a0 - 0.08)) * 520, Vector2(360, 540) + Vector2(cos(a0 + 0.08), sin(a0 + 0.08)) * 520])
		ray.color = Color(1.0, 0.85, 0.4, 0.10)
		ui.add_child(ray)
	_ring(Rect2(210, 390, 300, 300), 1.0, Color("#FFD66B"))
	var gem := _frame(Rect2(250, 430, 220, 220), 60.0, Color("#6A4AE0"), Color("#2A1880"), GOLD, 0.06, 5.0)
	(gem.material as ShaderMaterial).set_shader_parameter("glow", Color("#B8A8FF", 0.7))
	_big(Rect2(250, 440, 220, 190), "8", 140, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_CENTER)
	var rib := ColorRect.new()
	rib.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rib.position = Vector2(90, 270)
	rib.size = Vector2(540, 110)
	var rm := _mat("ribbon")
	rm.set_shader_parameter("size", rib.size)
	rm.set_shader_parameter("face_top", Color("#8A6AF0"))
	rm.set_shader_parameter("face_bottom", Color("#3A1E9A"))
	rib.material = rm
	ui.add_child(rib)
	_big(Rect2(140, 272, 440, 80), "سطح بالاتر!", 50, "#FFFFFF", "#FFE6B8", HORIZONTAL_ALIGNMENT_CENTER)
	_card(Rect2(60, 720, 600, 280), Color(VIOLET, 0.5))
	_txt(Rect2(80, 736, 560, 34), "جایزه‌ها", 22, Color("#E0D4FF"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	var rewards := [["coins", "gold", "+2,000 نیل"], ["energy", "amber", "سقف انرژی +5"], ["plane", "sapphire", "باز شد: پرواز"]]
	for i in rewards.size():
		var rw: Array = rewards[i]
		var x := 460.0 - i * 190.0
		_inset(Rect2(x, 786, 176, 196))
		_emboss(rw[0], Rect2(x + 30, 796, 116, 116), rw[1])
		_txt(Rect2(x, 920, 176, 50), rw[2], 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	_btn(Rect2(160, 1020, 400, 90), "عالی!", "gold")


# -- the armed forces -----------------------------------------------------------------------------------
# Shaped like the server's military views (internal/telegram/screens/military.go):
# a country's equipment by branch (ground, air, navy, air defence) and class
# (configs/content/military.yml), each class split into its designs. A
# design's generation is its technology's (defence_industry.yml `generation`),
# and a family has no last generation: content adds the next one whenever it
# likes. So nothing here assumes a count: a class shows its newest designs
# and folds the rest into one card, and a generation's colour says how far it
# is behind the newest generation anyone makes (the frontier) — advanced,
# modern, standard, dated — so the colours mean the same at generation 3 as
# at generation 300, and the number is what tells generations apart.
# Counts are exact because the viewer holds clearance; everyone else sees
# bands.

const TIER_COL := [Color("#E0A82E"), Color("#9A5CF0"), Color("#3F7BE8"), Color("#7C86A6")]
const TIER_PAL := ["gold", "violet", "sapphire", "steel"]
const TIER_NAME := ["پیشرفته", "مدرن", "استاندارد", "قدیمی"]
const RANK_COL := [Color("#3F7BE8"), Color("#9A5CF0"), Color("#E0A82E")]
const RANK_PAL := ["sapphire", "violet", "gold"]
const RANGE_COL := [Color("#3FAE63"), Color("#3F7BE8"), Color("#9A5CF0")]

const BRANCHES := [["ground", "زمینی", "u_tank"], ["air", "هوایی", "u_airforce"], ["navy", "دریایی", "u_carrier"], ["air_defence", "پدافند", "u_radar"]]

# class: icon, name, unit word, designs held as [generation, count, design], status line,
# the frontier (the newest generation of it anyone makes).
# The personnel row is ranks, not generations.
const FORCES := {
	"air": [
		["u_fighter", "جنگنده", "فروند", [[9, 3, "سیمرغ"], [8, 12, "شاهین X"], [7, 20, "شاهین M"], [5, 10, "شاهین"], [4, 6, "آذرخش 4"], [2, 4, "آذرخش"], [1, 2, "صاعقه"]], "", 10],
		["u_stealth", "جنگنده‌ی رادارگریز", "فروند", [[6, 2, "شبح X"], [4, 4, "شبح"]], "", 7],
		["u_bomber", "بمب‌افکن", "فروند", [[3, 2, "عقاب B"], [1, 6, "عقاب"]], "", 5],
		["u_drone", "پهپاد رزمی", "فروند", [[12, 12, "کرکس"], [11, 40, "مهاجر 11"], [10, 24, "مهاجر"], [8, 30, "پرستو 8"], [6, 18, "پرستو"], [3, 50, "سار"], [2, 20, "سار"], [1, 10, "سار"]], "", 13],
	],
	"ground": [
		["u_helmet", "نیروی انسانی", "نفر", [[1, 1240, "سرباز"], [2, 310, "درجه‌دار"], [3, 86, "افسر"]], "ranks", -1],
		["u_tank", "تانک", "دستگاه", [[6, 8, "ببر"], [5, 32, "پلنگ 5"], [4, 60, "پلنگ"], [2, 20, "یوز"]], "", 7],
		["u_ifv", "نفربر رزمی", "دستگاه", [[3, 45, "گورخر 3"], [2, 90, "گورخر"]], "", 4],
		["u_artillery", "توپخانه", "قبضه", [[7, 4, "تندر"], [6, 18, "رعد 6"], [3, 36, "رعد"]], "", 8],
	],
	"navy": [
		["u_frigate", "ناوچه", "فروند", [[4, 2, "موج 4"], [3, 4, "موج"]], "", 5],
		["u_sub", "زیردریایی", "فروند", [[2, 1, "نهنگ 2"], [1, 2, "نهنگ"]], "", 3],
		["u_antiship", "موشک ضدکشتی", "فروند", [[5, 4, "زوبین"], [4, 16, "نیزه 4"], [2, 30, "نیزه"]], "", 6],
	],
	"air_defence": [
		["u_radar", "رادار هشدار زودهنگام", "سامانه", [[8, 1, "افق"], [6, 3, "دیدبان 6"], [5, 6, "دیدبان"]], "شبکه روشن  ·  برد 420 کیلومتر", 9],
		["u_sam", "پدافند کوتاه‌برد", "آتشبار", [[4, 10, "سپر 4"], [2, 18, "سپر"]], "4 تیر در هر پرتابگر", 5],
		["u_sam", "پدافند میان‌برد", "آتشبار", [[9, 2, "باور 9"], [7, 6, "باور 7"], [5, 8, "باور"]], "رهگیر موشک بالستیک", 10],
		["u_sam", "پدافند دوربرد", "آتشبار", [[3, 1, "ستیغ 3"], [2, 3, "ستیغ"]], "رهگیر موشک بالستیک", 4],
	],
}


# The frontier of the class being drawn; negative for a row of ranks.
var _front := 10
var _pivot: Node3D


## How far behind the frontier: 0 advanced (the newest or the one before),
## 1 modern (two or three behind), 2 standard (up to six), 3 dated.
func _tier(g: int) -> int:
	var behind := _front - g
	if behind <= 1:
		return 0
	if behind <= 3:
		return 1
	return 2 if behind <= 6 else 3


func _gcol(g: int) -> Color:
	return RANK_COL[g - 1] if _front < 0 else TIER_COL[_tier(g)]


func _gpal(g: int) -> String:
	return RANK_PAL[g - 1] if _front < 0 else TIER_PAL[_tier(g)]


func _gtop(g: int) -> String:
	return _gcol(g).lightened(0.8).to_html(false)


func _gbot(g: int) -> String:
	return _gcol(g).lightened(0.4).to_html(false)


## Newest generation first.
func _newest_first(gens: Array) -> Array:
	var out := gens.duplicate()
	out.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	return out


func _sum(gens: Array) -> int:
	var t := 0
	for g in gens:
		t += int(g[1])
	return t


func _arg(key: String, def: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % key):
			return a.substr(key.length() + 3)
	return def


func _node(n: Node2D) -> Node2D:
	ui.add_child(n)
	return n


func _circle(c: Vector2, r: float, col: Color, w := 2.0, fill := Color(0, 0, 0, 0)) -> void:
	var pts := PackedVector2Array()
	for i in 73:
		pts.append(c + Vector2.from_angle(TAU * i / 72.0) * r)
	if fill.a > 0.0:
		var p := Polygon2D.new()
		p.polygon = pts
		p.color = fill
		_node(p)
	var l := Line2D.new()
	l.points = pts
	l.width = w
	l.default_color = col
	l.antialiased = true
	_node(l)


func _line(a: Vector2, b: Vector2, col: Color, w := 2.0) -> void:
	var l := Line2D.new()
	l.points = PackedVector2Array([a, b])
	l.width = w
	l.default_color = col
	l.antialiased = true
	_node(l)


func _rect(r: Rect2, col: Color) -> void:
	var c := ColorRect.new()
	c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	c.position = r.position
	c.size = r.size
	c.color = col
	ui.add_child(c)


## One design a force holds: its generation's colour and number, the count,
## the design's name. `label` replaces "نسل n" where the tiers are ranks.
func _gen_card(r: Rect2, icon: String, gen: int, count: int, design: String, label := "", newest := false) -> void:
	var col := _gcol(gen)
	var f := _frame(r, 16.0, Color(col.darkened(0.5), 0.97), Color(col.darkened(0.82), 0.97), GOLD if newest else col.lightened(0.3), 0.05, 3.0 if newest else 2.0)
	var m := f.material as ShaderMaterial
	m.set_shader_parameter("shadow", 0.35)
	if newest:
		m.set_shader_parameter("glow", Color(GOLD, 0.45))
	_emboss(icon, Rect2(r.position.x + 4, r.position.y + 2, 62, 62), _gpal(gen))
	_chip(Rect2(r.end.x - 76, r.position.y + 8, 68, 28), label if label != "" else "نسل %d" % gen, col, 16)
	_big(Rect2(r.position.x + 8, r.position.y + 54, r.size.x - 16, 44), "×" + _n(count), 36, _gtop(gen), _gbot(gen))
	if label == "":
		_txt(Rect2(r.position.x + 6, r.position.y + 94, r.size.x - 12, 24), design, 15, Color("#C9D2EE"), HORIZONTAL_ALIGNMENT_CENTER)


## The frontier generation, not held yet: the defence industry sells it.
func _next_card(r: Rect2, icon: String, gen: int) -> void:
	var f := _frame(r, 16.0, Color(0.06, 0.07, 0.14, 0.9), Color(0.03, 0.04, 0.09, 0.9), Color("#59607A"), 0.0, 2.0)
	(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.2)
	var ic := _emboss(icon, Rect2(r.position.x + 4, r.position.y + 2, 62, 62), "steel")
	ic.modulate = Color(1, 1, 1, 0.3)
	_chip(Rect2(r.end.x - 76, r.position.y + 8, 68, 28), "نسل %d" % gen, Color("#59607A"), 16)
	_txt(Rect2(r.position.x + 8, r.position.y + 56, r.size.x - 16, 36), "+ خرید", 24, Color("#9EA8CC"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	_txt(Rect2(r.position.x + 6, r.position.y + 94, r.size.x - 12, 24), "از صنایع دفاعی", 14, Color("#6E7694"), HORIZONTAL_ALIGNMENT_CENTER)


## Every generation of a class in one card: how many it holds, a bar per
## generation, newest at the reading start. Past eight, the oldest share one bar.
func _all_gens_card(r: Rect2, gens: Array) -> void:
	var f := _frame(r, 16.0, Color(0.13, 0.15, 0.30, 0.97), Color(0.05, 0.06, 0.14, 0.97), Color(GOLD, 0.6), 0.04, 2.0)
	(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.35)
	_chip(Rect2(r.end.x - 96, r.position.y + 8, 88, 28), "%d نسل" % gens.size(), SAFFRON, 16)
	_txt(Rect2(r.position.x + 6, r.position.y + 8, r.size.x - 104, 28), "همه", 17, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
	var bars := gens.slice(0, 7) if gens.size() > 8 else gens
	var rest := gens.slice(7) if gens.size() > 8 else []
	var entries: Array = []
	for g in bars:
		entries.append([str(g[0]), int(g[1]), _gcol(int(g[0]))])
	if not rest.is_empty():
		entries.append(["≤%d" % int(rest[0][0]), _sum(rest), Color("#7C86A6")])
	var hi := 1
	for e in entries:
		hi = maxi(hi, int(e[1]))
	var n := entries.size()
	var slot := (r.size.x - 16.0) / n
	var bw := minf(slot - 4.0, 22.0)
	var base := r.position.y + 96.0
	for i in n:
		var e: Array = entries[i]
		var cx := r.end.x - 8.0 - slot * (i + 0.5)
		var h := maxf(4.0, 50.0 * float(e[1]) / hi)
		_rect(Rect2(cx - bw / 2.0, base - h, bw, h), Color(e[2]))
		_rect(Rect2(cx - bw / 2.0, base - h, bw, 3), Color(e[2]).lightened(0.5))
		_txt(Rect2(cx - slot / 2.0 - 4, base + 1, slot + 8, 20), e[0], 13 if n < 8 else 11, Color("#C9D2EE"), HORIZONTAL_ALIGNMENT_CENTER, display_font)


## A class: plate, name and total at the reading start; then its newest
## designs; with more than three, the newest two and a card for all of them;
## with fewer, the next generation to buy.
func _class_row(y: float, c: Array) -> void:
	var gens := _newest_first(c[3])
	var ranks: bool = c[4] == "ranks"
	_front = int(c[5])
	if ranks:
		gens = c[3]
	_inset(Rect2(20, y, 680, 142), Color(GOLD, 0.35))
	_plate(c[0], Rect2(576, y + 4, 76, 76), "cream", Color("#1E2A5A"))
	var name_px := 22 if (c[1] as String).length() < 12 else 18
	ui.add_child(_label(c[1], display_font, name_px, Color.WHITE, Rect2(522, y + 78, 180, 30), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_big(Rect2(522, y + 102, 180, 26), "%s %s" % [_n(_sum(gens)), c[2]], 19, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
	# how the class splits by tier, advanced at the reading start
	var parts := [0, 0, 0, 0]
	for g in gens:
		parts[0 if ranks else _tier(int(g[0]))] += int(g[1])
	var total := float(_sum(gens))
	var x := 692.0
	for t in 4:
		if ranks or parts[t] == 0:
			continue
		var w: float = 156.0 * parts[t] / total
		x -= w
		_rect(Rect2(x, y + 128, maxf(w - 2.0, 2.0), 7), TIER_COL[t])
	var slots: Array = []
	var newest: int = gens[0][0]
	if ranks or gens.size() == 3:
		slots = gens
	elif gens.size() > 3:
		slots = [gens[0], gens[1], "all"]
	else:
		slots = gens.duplicate()
		if newest < _front:
			slots.append("next")
	for i in slots.size():
		var r := Rect2(360.0 - i * 162.0, y + 10, 152, 122)
		var sl = slots[i]
		if sl is String and sl == "all":
			_all_gens_card(r, gens)
		elif sl is String and sl == "next":
			_next_card(r, c[0], _front)
		else:
			_gen_card(r, c[0], int(sl[0]), int(sl[1]), sl[2], sl[2] if ranks else "", i == 0 and not ranks)


## What the colours mean.
func _tier_legend(y: float) -> void:
	_txt(Rect2(470, y, 230, 30), "نسبت به جدیدترین نسل:", 15, Color("#AEB8D8"))
	for t in 4:
		_chip(Rect2(360.0 - t * 110.0, y, 102, 30), TIER_NAME[t], TIER_COL[t], 15)


func _forces_summary() -> void:
	_card(Rect2(20, 256, 680, 104), Color(LEAF, 0.3))
	_plate("eagle", Rect2(604, 266, 84, 84), "sapphire", Color("#101E60"))
	ui.add_child(_label("فنویک", display_font, 28, Color.WHITE, Rect2(440, 266, 156, 40), HORIZONTAL_ALIGNMENT_RIGHT, 5))
	_txt(Rect2(420, 306, 176, 28), "ستاد کل نیروهای مسلح", 15, Color("#AEB8D8"))
	_txt(Rect2(250, 262, 170, 26), "قدرت رزمی", 15, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_big(Rect2(250, 286, 170, 52), "18,420", 40, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
	_ring(Rect2(166, 264, 76, 76), 0.86, LEAF)
	_txt(Rect2(166, 264, 76, 76), "86٪", 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	_txt(Rect2(150, 336, 108, 22), "آمادگی", 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_chip(Rect2(34, 268, 118, 34), "محرمانه", ANAR, 17)
	_txt(Rect2(28, 308, 132, 22), "نگهداری هر دوره", 13, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(28, 328, 132, 26), "12,400", 19, Color("#FFD0D4"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)


func _branch_tabs(y: float, active: String) -> void:
	for i in BRANCHES.size():
		var b: Array = BRANCHES[i]
		var r := Rect2(536.0 - i * 172.0, y, 164, 76)
		var on: bool = b[0] == active
		if on:
			var f := _frame(r, 18.0, Color("#3A63D0"), Color("#15286A"), GOLD, 0.05, 3.0)
			(f.material as ShaderMaterial).set_shader_parameter("glow", Color("#8FB4FF", 0.5))
		else:
			_inset(r, Color(GOLD, 0.25))
		var ic := _emboss(b[2], Rect2(r.end.x - 70, y + 6, 64, 64), "gold" if on else "steel")
		if not on:
			ic.modulate = Color(0.8, 0.84, 0.95)
		ui.add_child(_label(b[1], display_font, 24 if on else 21, Color.WHITE if on else Color("#AEB8D8"), Rect2(r.position.x + 6, y, r.size.x - 78, 76), HORIZONTAL_ALIGNMENT_CENTER, 4))


func _s_forces() -> void:
	var branch := _arg("branch", "air")
	_hdr("نیروهای مسلح", Color("#3D6B3A"))
	_forces_summary()
	_branch_tabs(370, branch)
	_tier_legend(456)
	var rows: Array = FORCES[branch]
	for i in rows.size():
		_class_row(496 + i * 150, rows[i])


# -- one design, as its commander sees it ---------------------------------------------------------------
func _stat(r: Rect2, name: String, value: String, v: float, delta: String, col: Color) -> void:
	_txt(Rect2(r.position.x, r.position.y, r.size.x, 26), name, 16, Color("#AEB8D8"))
	var val := _label(value, display_font, 22, Color.WHITE, Rect2(r.position.x, r.position.y - 2, r.size.x - 120, 30), HORIZONTAL_ALIGNMENT_LEFT, 4)
	# a figure with a Latin unit reads left to right; one with a Persian word does not
	var latin := false
	for ch in value:
		latin = latin or (ch.to_lower() >= "a" and ch.to_lower() <= "z")
	val.text_direction = Control.TEXT_DIRECTION_LTR if latin else Control.TEXT_DIRECTION_RTL
	ui.add_child(val)
	_pbar(Rect2(r.position.x + 70, r.position.y + 32, r.size.x - 70, 18), v, col)
	if delta != "":
		var d := _txt(Rect2(r.position.x, r.position.y + 26, 64, 28), delta, 16, Color("#7FE39B"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
		d.text_direction = Control.TEXT_DIRECTION_LTR


func _arrow(r: Rect2, glyph: String) -> void:
	var b := _button(r, Color("#3F55A8"), Color("#1A2560"), Color("#0A1030"), 18.0, 5.0)
	b.add_child(_label(glyph, display_font, 40, Color.WHITE, Rect2(0, -10, r.size.x, r.size.y + 4), HORIZONTAL_ALIGNMENT_CENTER, 4))


## A showroom: the model on a lit plinth, rendered in its own world and laid
## into the page like any picture. It turns slowly.
func _showroom(r: Rect2, kind: String, band: Color) -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(int(r.size.x * 1.5), int(r.size.y * 1.5))
	sv.transparent_bg = true
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#8FA0D8")
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.1
	env.environment = e
	sv.add_child(env)
	var key := DirectionalLight3D.new()
	key.light_color = Color("#FFE2C0")
	key.light_energy = 1.4
	key.shadow_enabled = true
	key.rotation_degrees = Vector3(-48, 35, 0)
	sv.add_child(key)
	var rim := OmniLight3D.new()
	rim.light_color = band.lightened(0.3)
	rim.light_energy = 6.0
	rim.omni_range = 9.0
	rim.position = Vector3(-2.5, 2.2, -3.5)
	sv.add_child(rim)
	var fill := OmniLight3D.new()
	fill.light_color = Color("#9FB4FF")
	fill.light_energy = 1.4
	fill.omni_range = 12.0
	fill.position = Vector3(4, 1.5, 4)
	sv.add_child(fill)
	var kit = load("res://proto/city/arms.gd").new()
	var stage := Node3D.new()
	sv.add_child(stage)
	kit.ccyl(stage, 2.7, 0.22, Vector3(0, -1.11, 0), kit.mat(Color("#20263A"), 0.7, 0.35))
	kit.ccyl(stage, 2.9, 0.12, Vector3(0, -1.26, 0), kit.mat(Color("#141824"), 0.6, 0.5))
	var ring := TorusMesh.new()
	ring.inner_radius = 2.62
	ring.outer_radius = 2.72
	kit._mesh(stage, ring, Vector3(0, -1.0, 0), kit.mat(band, 0.0, 0.4, 0.9))
	_pivot = Node3D.new()
	stage.add_child(_pivot)
	if kind == "tank":
		var t: Node3D = kit.tank(_pivot, band)
		t.position = Vector3(0, -1.0, -0.2)
	else:
		var f: Node3D = kit.fighter(_pivot, band)
		f.position = Vector3(0, -0.35, 0.1)
		f.rotation_degrees = Vector3(-4, 0, 6)
	_pivot.rotation_degrees.y = 42.0
	var cam3 := Camera3D.new()
	cam3.fov = 27.0
	cam3.position = Vector3(5.6, 3.1, 6.2)
	sv.add_child(cam3)
	cam3.look_at(Vector3(0, -0.45, 0))
	var tr := TextureRect.new()
	tr.layout_direction = Control.LAYOUT_DIRECTION_LTR
	tr.texture = sv.get_texture()
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = r.position
	tr.size = r.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tr)


func _process(delta: float) -> void:
	_t += delta
	_frames += 1
	if _pivot:
		_pivot.rotation_degrees.y = 42.0 + _t * 14.0
	if _shot != "" and _frames == 40:
		get_viewport().get_texture().get_image().save_png(_shot)
		get_tree().quit()


# the design screens: class row, held index, maker, stats [name, value, bar, delta, colour]
const UNITS := {
	"fighter": {"title": "جنگنده", "branch": "air", "row": 0, "cur": 2, "maker": "صنایع هوایی آراز", "where": "نیروی هوایی",
		"stats": [["سرعت", "2,100 km/h", 0.72, "+300", "blue"], ["برد", "1,800 km", 0.6, "+300", "blue"],
			["محموله", "8,000 kg", 0.55, "+1,000", "blue"], ["نبرد هوایی", "2 موشک", 0.5, "", "blue"],
			["سطح مقطع راداری", "3.2 m²", 0.35, "−1.8", "green"], ["دیده می‌شود از", "268 km", 0.52, "−36", "green"]]},
	"tank": {"title": "تانک", "branch": "ground", "row": 1, "cur": 1, "maker": "صنایع زرهی تیرگان", "where": "نیروی زمینی",
		"stats": [["زره", "820", 0.78, "+140", "blue"], ["آتش", "640", 0.7, "+90", "blue"],
			["سرعت", "70 km/h", 0.5, "+5", "blue"], ["برد", "450 km", 0.45, "+50", "blue"],
			["کیفیت", "74", 0.74, "+6", "green"], ["نگهداری هر دوره", "35", 0.3, "", "green"]]},
}


func _s_unit() -> void:
	var kind := _arg("unit", "fighter")
	var u: Dictionary = UNITS[kind]
	var row: Array = FORCES[u["branch"]][u["row"]]
	var held: Array = _newest_first(row[3])
	_front = int(row[5])
	var cur: int = u["cur"]
	var g: int = held[cur][0]
	var col := _gcol(g)
	_hdr(u["title"], Color("#2A4BC8"))
	_card(Rect2(20, 256, 680, 330), Color(col, 0.45))
	_showroom(Rect2(24, 262, 360, 244), kind, col)
	_big(Rect2(370, 268, 316, 60), held[cur][2], 50, "#FFFFFF", _gtop(g))
	_txt(Rect2(370, 326, 316, 26), "طراح و سازنده: " + u["maker"], 16, Color("#C9D2EE"))
	_chip(Rect2(588, 362, 98, 34), "نسل %d" % g, col, 18)
	_chip(Rect2(470, 362, 110, 34), TIER_NAME[_tier(g)], col.darkened(0.2), 17)
	_txt(Rect2(370, 364, 92, 30), "جدیدترین: %d" % _front, 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	_big(Rect2(370, 404, 316, 60), "×%d" % held[cur][1], 54, "#FFF6C8", "#FFB21F")
	_txt(Rect2(370, 460, 316, 26), "از %d در %d نسل  ·  %s" % [_sum(held), held.size(), u["where"]], 16, Color("#C9D2EE"))
	# the generations held, a window of three around this one, arrows to the rest
	_arrow(Rect2(636, 512, 50, 60), "›")
	_arrow(Rect2(34, 512, 50, 60), "‹")
	for i in 3:
		var k := cur - 1 + i
		if k < 0 or k >= held.size():
			continue
		var gg: Array = held[k]
		var gc := _gcol(int(gg[0]))
		var on := k == cur
		var r := Rect2(460.0 - i * 184.0, 510, 172, 64)
		var f := _frame(r, 16.0, Color(gc.darkened(0.3 if on else 0.55)), Color(gc.darkened(0.8)), GOLD if on else Color(gc, 0.7), 0.0, 3.0 if on else 1.5)
		if on:
			(f.material as ShaderMaterial).set_shader_parameter("glow", Color(GOLD, 0.4))
		ui.add_child(_label("نسل %d" % gg[0], display_font, 21, Color.WHITE, Rect2(r.position.x + 60, r.position.y, 106, 64), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_big(Rect2(r.position.x + 10, r.position.y + 6, 60, 52), _n(int(gg[1])), 28, _gtop(int(gg[0])), _gbot(int(gg[0])), HORIZONTAL_ALIGNMENT_LEFT)
	var prev: int = held[cur + 1][0] if cur + 1 < held.size() else g
	_sec(604, "مشخصات  ·  در برابر نسل %d" % prev)
	var st_: Array = u["stats"]
	for i in st_.size():
		var sd: Array = st_[i]
		_stat(Rect2(370.0 - (i % 2) * 340.0, 660 + (i / 2) * 68, 320, 54), sd[0], sd[1], sd[2], sd[3], LAPIS if sd[4] == "blue" else LEAF)
	var st := [["آماده", "14", LEAF], ["در عملیات", "3", SAFFRON], ["آسیب‌دیده", "2", ANAR], ["در راه", "1", LAPIS]]
	for i in st.size():
		var s: Array = st[i]
		var r := Rect2(532.0 - i * 170.0, 866, 160, 84)
		_inset(r, Color(s[2], 0.6))
		_big(Rect2(r.position.x, r.position.y + 4, r.size.x, 46), s[1], 38, "#FFFFFF", Color(s[2]).lightened(0.4).to_html(false))
		_txt(Rect2(r.position.x, r.position.y + 50, r.size.x, 28), s[0], 16, Color("#C9D2EE"), HORIZONTAL_ALIGNMENT_CENTER)
	_inset(Rect2(20, 962, 680, 56))
	_emboss("u_fort", Rect2(640, 964, 52, 52), "cream")
	_txt(Rect2(36, 962, 600, 56), "پایگاه‌ها:  فنویک 8  ·  آزور 6  ·  تیرگان 5  ·  انبار 1", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_btn(Rect2(370, 1030, 330, 76), "ارتقا به نسل %d" % held[0][0], "gold")
	_btn(Rect2(20, 1030, 330, 76), "استقرار", "blue")


# -- missiles and munitions, across the branches, and a salvo --------------------------------------------
const MISSILES := [
	["u_ballistic", "موشک بالستیک", "رهگیری: فقط پدافند میان‌برد و دوربرد", [[6, 4], [5, 12], [3, 6], [2, 24], [1, 40]], 7],
	["u_cruise", "موشک کروز", "پرواز پست  ·  رادار از 40 کیلومتری می‌بیندش", [[4, 8], [3, 30], [1, 52]], 5],
	["u_antiship", "موشک ضدکشتی", "برای ناوگان  ·  در انبار بندر آزور", [[5, 4], [4, 16], [2, 30]], 6],
	["u_bomb", "بمب هدایت‌شونده", "مهمات جنگنده  ·  هر سورتی 2 بمب", [[7, 64], [3, 120]], 8],
]


func _pill(r: Rect2, top: String, value: String, col: Color, vtop: String, vbot: String) -> void:
	var f := _frame(r, 14.0, Color(col.darkened(0.5), 0.97), Color(col.darkened(0.82), 0.97), col.lightened(0.3), 0.0, 2.0)
	(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.2)
	_txt(Rect2(r.position.x, r.position.y + 4, r.size.x, 24), top, 14, Color(col.lightened(0.5)), HORIZONTAL_ALIGNMENT_CENTER)
	_big(Rect2(r.position.x, r.position.y + 28, r.size.x, 42), value, 28 if value.length() < 4 else 23, vtop, vbot, HORIZONTAL_ALIGNMENT_CENTER)


## The newest generations as pills, newest at the reading start; past three,
## the newest two and one pill for everything older.
func _gen_pills(x0: float, y: float, held: Array) -> void:
	var gens := _newest_first(held)
	var shown := gens if gens.size() <= 3 else gens.slice(0, 2)
	for i in shown.size():
		var g: int = shown[i][0]
		_pill(Rect2(x0 + (2 - i) * 78.0, y, 70, 76), "نسل %d" % g, _n(int(shown[i][1])), _gcol(g), _gtop(g), _gbot(g))
	if gens.size() > 3:
		var older := gens.slice(2)
		_pill(Rect2(x0, y, 70, 76), "+%d نسل" % older.size(), _n(_sum(older)), Color("#7C86A6"), "#FFFFFF", "#C9D2EE")


## A row of an arsenal: plate, name, note, total, the generations held.
func _arms_row(y: float, icon: String, name: String, note: String, held: Array, front: int, trim := Color(GOLD, 0.35)) -> void:
	_front = front
	_inset(Rect2(20, y, 680, 100), trim)
	_plate(icon, Rect2(608, y + 12, 78, 78), "cream", Color("#1E2A5A"))
	ui.add_child(_label(name, display_font, 23, Color.WHITE, Rect2(270, y + 8, 328, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_big(Rect2(270, y + 8, 200, 36), "کل " + _n(_sum(held)), 24, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_LEFT)
	_txt(Rect2(270, y + 46, 328, 48), note, 14, Color("#AEB8D8"))
	_gen_pills(32, y + 12, held)


func _stepper(y: float, icon: String, gen: int, name: String, have: int, n: int) -> void:
	_emboss(icon, Rect2(630, y, 56, 56), _gpal(gen))
	ui.add_child(_label(name, display_font, 20, Color.WHITE, Rect2(330, y, 296, 32), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_chip(Rect2(484, y + 30, 142, 28), "نسل %d  ▾" % gen, _gcol(gen), 15)
	_txt(Rect2(300, y + 30, 176, 28), "%d در انبار" % have, 14, Color("#AEB8D8"))
	var minus := _button(Rect2(236, y + 4, 52, 52), Color("#8E97B4"), Color("#4A536E"), Color("#1E2436"), 16.0, 5.0)
	minus.add_child(_label("−", display_font, 34, Color.WHITE, Rect2(0, -6, 52, 56), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_inset(Rect2(128, y + 4, 100, 52), Color(GOLD, 0.6))
	_big(Rect2(128, y + 4, 100, 52), str(n), 32, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_CENTER)
	var plus := _button(Rect2(68, y + 4, 52, 52), LEAF.lightened(0.3), LEAF.darkened(0.1), LEAF.darkened(0.55), 16.0, 5.0)
	plus.add_child(_label("+", display_font, 34, Color.WHITE, Rect2(0, -6, 52, 56), HORIZONTAL_ALIGNMENT_CENTER, 4))


func _s_arsenal() -> void:
	_hdr("زرادخانه", Color("#A01E2A"))
	for i in MISSILES.size():
		var m: Array = MISSILES[i]
		_arms_row(256 + i * 108, m[0], m[1], m[2], m[3], m[4])
	_sec(690, "طرح آتش")
	_card(Rect2(20, 746, 680, 360), Color(ANAR, 0.4))
	_plate("u_fort", Rect2(620, 756, 66, 66), "ruby", Color("#3A0E1E"))
	ui.add_child(_label("پایگاه هوایی کالدریس", display_font, 23, Color.WHITE, Rect2(300, 754, 312, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_txt(Rect2(300, 788, 312, 24), "فاصله 640 کیلومتر  ·  3 آتشبار میان‌برد", 14, Color("#FFC9CC"))
	_btn(Rect2(40, 764, 150, 50), "تغییر هدف", "steel")
	_rect(Rect2(40, 830, 640, 2), Color(GOLD, 0.25))
	_front = 7
	_stepper(842, "u_ballistic", 6, "موشک بالستیک", 4, 4)
	_front = 5
	_stepper(906, "u_cruise", 3, "موشک کروز", 30, 8)
	# the commander's estimate: the battle rolled a dozen times
	_inset(Rect2(36, 972, 648, 58), Color(SAFFRON, 0.5))
	_ring(Rect2(612, 974, 54, 54), 0.58, SAFFRON)
	_txt(Rect2(612, 974, 54, 54), "58٪", 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	_txt(Rect2(48, 972, 556, 30), "برآورد: 7 از 12 موشک از پدافند می‌گذرد", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_txt(Rect2(48, 1000, 556, 26), "خسارت احتمالی: سنگین  ·  آماده‌سازی 20 دقیقه", 15, Color("#FFE3B0"))
	_btn(Rect2(160, 1040, 400, 58), "پرتاب 12 موشک", "red")


# -- air defence ---------------------------------------------------------------------------------------------
func _s_airdefence() -> void:
	_hdr("پدافند هوایی", Color("#1E7A6A"))
	_card(Rect2(20, 256, 680, 420), Color(FIROUZEH, 0.35))
	var c := Vector2(300, 470)
	var R := 190.0
	_circle(c, R, Color(FIROUZEH, 0.8), 3.0, Color("#03140F", 0.92))
	# coverage of the batteries, widest first
	_circle(c + Vector2(10, 10), 150, Color(RANGE_COL[2], 0.8), 2.0, Color(RANGE_COL[2], 0.10))
	_circle(c + Vector2(-80, -70), 84, Color(RANGE_COL[1], 0.85), 2.0, Color(RANGE_COL[1], 0.12))
	_circle(c + Vector2(90, 96), 70, Color(RANGE_COL[1], 0.85), 2.0, Color(RANGE_COL[1], 0.12))
	for p in [Vector2(10, 10), Vector2(-80, -70), Vector2(90, 96), Vector2(-40, 60)]:
		_circle(c + p, 36, Color(RANGE_COL[0], 0.9), 2.0, Color(RANGE_COL[0], 0.14))
	for k in [0.33, 0.66]:
		_circle(c, R * k, Color(FIROUZEH, 0.22), 1.5)
	_line(c - Vector2(R, 0), c + Vector2(R, 0), Color(FIROUZEH, 0.22), 1.5)
	_line(c - Vector2(0, R), c + Vector2(0, R), Color(FIROUZEH, 0.22), 1.5)
	var sweep := Polygon2D.new()
	var pts := PackedVector2Array([c])
	var cols := PackedColorArray([Color(FIROUZEH, 0.0)])
	for i in 13:
		var a := -2.2 + 0.7 * i / 12.0
		pts.append(c + Vector2.from_angle(a) * R)
		cols.append(Color(FIROUZEH, 0.5 * i / 12.0))
	sweep.polygon = pts
	sweep.vertex_colors = cols
	_node(sweep)
	_line(c, c + Vector2.from_angle(-1.5) * R, Color("#A8FFF0", 0.9), 2.5)
	var cities := [[Vector2(10, 10), "فنویک", true], [Vector2(-80, -70), "آزور", false], [Vector2(90, 96), "تیرگان", false], [Vector2(-40, 60), "دشتک", false]]
	for ct in cities:
		var p: Vector2 = c + ct[0]
		_circle(p, 7 if ct[2] else 5, GOLD, 3.0, GOLD if ct[2] else Color("#FFF3B0"))
		_txt(Rect2(p.x - 70, p.y + 6, 140, 26), ct[1], 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	var blip := c + Vector2(128, -128)
	_line(c + Vector2(186, -176), blip, Color(ANAR, 0.7), 2.0)
	for d in [Vector2(0, 0), Vector2(14, -6), Vector2(-6, 12)]:
		_circle(blip + d, 5, ANAR, 2.0, Color(ANAR, 0.9))
	_chip(Rect2(blip.x - 150, blip.y - 50, 136, 32), "3 کروز  ·  4 دقیقه", ANAR, 15)
	var info := [["هشدار زودهنگام", "420 km", FIROUZEH], ["رادارگریز را می‌بیند از", "65 km", VIOLET], ["رهگیری امروز", "78٪", LEAF]]
	for i in info.size():
		var it: Array = info[i]
		_txt(Rect2(500, 280 + i * 92, 186, 26), it[0], 15, Color("#AEB8D8"))
		var v := _glabel(it[1], display_font, 34, "#FFFFFF", Color(it[2]).lightened(0.4).to_html(false), Rect2(500, 304 + i * 92, 186, 50), HORIZONTAL_ALIGNMENT_RIGHT, 6)
		v.text_direction = Control.TEXT_DIRECTION_LTR
		ui.add_child(v)
	_chip(Rect2(500, 560, 186, 34), "کوتاه‌برد", RANGE_COL[0], 16)
	_chip(Rect2(500, 600, 186, 34), "میان‌برد", RANGE_COL[1], 16)
	_chip(Rect2(500, 640, 186, 34), "دوربرد", RANGE_COL[2], 16)
	var ad: Array = FORCES["air_defence"]
	for i in ad.size():
		var a: Array = ad[i]
		_arms_row(690 + i * 104, a[0], a[1], a[4], a[3], a[5], Color(FIROUZEH, 0.45))
