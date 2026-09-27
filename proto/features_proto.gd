extends "res://proto/screens_proto.gd"
## The features the game does not have yet, drawn as it would draw them:
## talking to each other, fighting each other, a first-session guide, a
## reason to come back each day, the city's newspaper, inviting friends, a
## casino, street races, land on the map, a will, cosmetics and seasonal
## events. Same pieces and conventions as screens_proto.gd; placeholder data.
##   godot --path . res://proto/screens_proto.tscn -- --screen=<name>
## Names: chats, chat, friends, tutorial, daily, gym, attack, fight, bounty,
## news, invite, casino, slots, race, plot, will, cosmetics, event.


func _dot(c: Vector2, online: bool) -> void:
	_circle(c, 9, Color(INK, 1.0), 3.0, LEAF if online else Color("#59607A"))


## A row of a list: a plated avatar at the reading start, a name, a line, and
## whatever the caller puts at the end.
func _person(r: Rect2, name: String, icon: String, pal: String, tint: Color, line: String, line_col := Color("#AEB8D8"), online := false, trim := Color(GOLD, 0.3)) -> void:
	_inset(r, trim)
	var s := r.size.y - 18.0
	_plate(icon, Rect2(r.end.x - s - 10, r.position.y + 9, s, s), pal, tint)
	_dot(Vector2(r.end.x - s - 2, r.position.y + s + 2), online)
	ui.add_child(_label(name, display_font, 23, Color.WHITE, Rect2(r.position.x + 200, r.position.y + 8, r.size.x - s - 220, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_txt(Rect2(r.position.x + 120, r.position.y + 44, r.size.x - s - 140, 30), line, 16, line_col)


# -- talking ---------------------------------------------------------------------------------------------------
func _s_chats() -> void:
	_hdr("گفتگوها", Color("#2A6AB0"))
	_inset(Rect2(20, 256, 680, 60), Color(GOLD, 0.35))
	_emboss("m_search", Rect2(640, 262, 48, 48), "steel")
	_txt(Rect2(40, 256, 590, 60), "جستجوی بازیکن یا گروه…", 18, Color("#6E7694"))
	# the channels everyone is in: the city, the faction, the class
	var chans := [["x_mega", "gold", "شهر فنویک", "1,240 آنلاین", 0], ["lion", "gold", "شیرهای البرز", "جناح  ·  38 عضو", 12], ["study", "violet", "کلاس اقتصاد", "همکلاسی‌ها", 3]]
	for i in chans.size():
		var c: Array = chans[i]
		var r := Rect2(478.0 - i * 229.0, 332, 222, 128)
		_card(r, Color(LAPIS, 0.35) if i == 0 else Color(0, 0, 0, 0))
		_emboss(c[0], Rect2(r.end.x - 76, r.position.y + 8, 68, 68), c[1])
		ui.add_child(_label(c[2], display_font, 20, Color.WHITE, Rect2(r.position.x + 8, r.position.y + 76, r.size.x - 16, 28), HORIZONTAL_ALIGNMENT_CENTER, 4))
		_txt(Rect2(r.position.x + 8, r.position.y + 100, r.size.x - 16, 24), c[3], 13, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
		if c[4] > 0:
			_count(Rect2(r.position.x + 12, r.position.y + 12, 38, 34), c[4])
	_sec(474, "پیام‌های خصوصی")
	var dms := [["آرش", "a_wolf", "steel", Color("#1E2A5A"), "امشب ساعت ۸ رستوران؟", "20:14", 2, true, false],
		["نگار", "eagle", "sapphire", Color("#101E60"), "در حال نوشتن…", "20:02", 0, true, true],
		["مهتاب", "a_raccoon", "cream", Color("#3A2A5A"), "مرسی بابت کمک توی بیمارستان", "18:40", 0, true, false],
		["بردیا", "lion", "gold", Color("#4A2A10"), "قرارداد رو امضا کردی؟", "دیروز", 1, false, false],
		["کاوه", "a_rabbit", "cream", Color("#2A3A6A"), "فردا شیفت من رو برمی‌داری؟", "دیروز", 0, false, false],
		["صنایع آراز", "factory", "steel", Color("#2A2F3A"), "پیشنهاد استخدام: مهندس ارشد", "2 روز", 0, false, false]]
	for i in dms.size():
		var d: Array = dms[i]
		var r := Rect2(20, 528 + i * 94, 680, 86)
		_person(r, d[0], d[1], d[2], d[3], d[4], LEAF if d[8] else Color("#AEB8D8"), d[7], Color(LAPIS, 0.6) if d[6] > 0 else Color(GOLD, 0.3))
		_txt(Rect2(36, r.position.y + 8, 120, 30), d[5], 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
		if d[6] > 0:
			_count(Rect2(36, r.position.y + 42, 36, 34), d[6])


func _bubble_msg(y: float, mine: bool, text: String, time: String, w := 420.0) -> float:
	var lines := ceili(text.length() / 30.0)
	var h := 30.0 + lines * 30.0
	var r := Rect2(700.0 - w if mine else 20.0, y, w, h)
	var top := Color("#1E7A6A") if mine else Color("#2A3366")
	var f := _frame(r, 20.0, top, top.darkened(0.35), Color(GOLD, 0.25), 0.0, 1.5)
	(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.3)
	var l := _txt(Rect2(r.position.x + 16, r.position.y + 8, w - 32, lines * 30.0), text, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, body_bold)
	_wrap(l, Vector2(w - 32, lines * 30.0))
	_txt(Rect2(r.position.x + 12, r.end.y - 26, 100, 22), time + ("  ✓✓" if mine else ""), 12, Color("#BFE9E3") if mine else Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	return r.end.y + 12


func _s_chat() -> void:
	_hdr("آرش", Color("#2A6AB0"))
	_inset(Rect2(20, 252, 680, 64), Color(ROSE, 0.4))
	_dot(Vector2(676, 284), true)
	_txt(Rect2(420, 252, 244, 64), "آنلاین  ·  در مرکز شهر", 16, Color("#BFFFD0"), HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_chip(Rect2(290, 268, 120, 32), "صمیمی", ROSE, 15)
	for i in 3:
		var ic: String = ["m_coffee", "f_rose", "u_fort"][i]
		var pal: String = ["amber", "ruby", "cream"][i]
		_button(Rect2(36 + i * 76, 262, 64, 44), Color("#3F55A8"), Color("#1A2560"), Color("#0A1030"), 14.0, 4.0)
		_emboss(ic if i < 2 else "f_heartplus", Rect2(46 + i * 76, 258, 44, 44), pal)
	_txt(Rect2(260, 330, 200, 26), "امروز", 14, Color("#8E97B4"), HORIZONTAL_ALIGNMENT_CENTER)
	var y := 364.0
	y = _bubble_msg(y, false, "سلام! امروز کلاس اقتصاد خیلی خوب بود", "19:40", 400)
	y = _bubble_msg(y, true, "آره، مخصوصاً بحث بورس. سهم آراز رو خریدی؟", "19:42", 440)
	y = _bubble_msg(y, false, "هنوز نه، منتظرم عرضه‌ی اولیه تموم بشه", "19:45", 420)
	# a gift, as the game says it
	_chip(Rect2(170, y, 380, 36), "آرش یک شاخه گل رز فرستاد  ·  صمیمیت +3", ROSE, 15)
	y += 52
	# an invitation, answerable in place
	var card := Rect2(20, y, 480, 150)
	_card(card, Color(SAFFRON, 0.4))
	_emboss("m_meal", Rect2(card.end.x - 84, y + 10, 72, 72), "gold")
	ui.add_child(_label("دعوت به قرار", display_font, 22, Color.WHITE, Rect2(card.position.x + 16, y + 10, 360, 34), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_txt(Rect2(card.position.x + 16, y + 44, 360, 26), "رستوران  ·  امشب 20:00  ·  صمیمیت +12", 15, Color("#FFE3B0"))
	_btn(Rect2(card.position.x + 250, y + 82, 210, 56), "قبول", "green")
	_btn(Rect2(card.position.x + 20, y + 82, 210, 56), "نه ممنون", "steel")
	y += 166
	y = _bubble_msg(y, false, "امشب ساعت ۸ رستوران؟", "20:14", 300)
	# the composer
	_inset(Rect2(20, 1020, 680, 76), Color(GOLD, 0.4))
	_txt(Rect2(120, 1020, 500, 76), "پیام بنویسید…", 19, Color("#6E7694"))
	_emboss("f_rose", Rect2(630, 1030, 56, 56), "ruby")
	var send := _button(Rect2(34, 1030, 72, 56), LEAF.lightened(0.3), LEAF.darkened(0.1), LEAF.darkened(0.55), 18.0, 5.0)
	_emboss("x_send", Rect2(46, 1030, 48, 48), "cream")


func _s_friends() -> void:
	_hdr("دوستان", Color("#2A6AB0"))
	var tabs := [["دوستان  12", true], ["درخواست‌ها  2", false], ["مسدود", false]]
	for i in tabs.size():
		var t: Array = tabs[i]
		var r := Rect2(478.0 - i * 229.0, 256, 222, 56)
		if t[1]:
			var f := _frame(r, 18.0, Color("#3A63D0"), Color("#15286A"), GOLD, 0.04, 3.0)
			(f.material as ShaderMaterial).set_shader_parameter("glow", Color("#8FB4FF", 0.5))
		else:
			_inset(r, Color(GOLD, 0.25))
		ui.add_child(_label(t[0], display_font, 20, Color.WHITE if t[1] else Color("#AEB8D8"), Rect2(r.position.x, r.position.y, r.size.x, r.size.y), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_sec(326, "درخواست‌های تازه")
	var reqs := [["مهتاب", "a_raccoon", "cream", Color("#3A2A5A"), "هم‌جناح  ·  سطح 6"], ["سینا", "a_foxkid", "fox", Color("#5E2A10"), "همکار  ·  سطح 5"]]
	for i in reqs.size():
		var q: Array = reqs[i]
		var r := Rect2(20, 380 + i * 94, 680, 86)
		_person(r, q[0], q[1], q[2], q[3], q[4], Color("#AEB8D8"), true, Color(LEAF, 0.5))
		_btn(Rect2(160, r.position.y + 14, 120, 58), "قبول", "green")
		_btn(Rect2(34, r.position.y + 14, 116, 58), "رد", "steel")
	_sec(578, "دوستان")
	# where each friend is, from what the game already knows about them
	var fr := [["آرش", "a_wolf", "steel", Color("#1E2A5A"), "در مرکز شهر  ·  آنلاین", LEAF, true],
		["نگار", "eagle", "sapphire", Color("#101E60"), "در کلاس مدیریت  ·  تا 21:10", Color("#8FB4FF"), true],
		["بردیا", "lion", "gold", Color("#4A2A10"), "در زندان  ·  تا 14:30", ANAR, false],
		["کاوه", "a_rabbit", "cream", Color("#2A3A6A"), "در سفر به آزور  ·  40 دقیقه", SAFFRON, false],
		["دنیا", "a_foxkid", "fox", Color("#5E2A10"), "در بیمارستان  ·  سلامت 32", ANAR, false]]
	for i in fr.size():
		var f: Array = fr[i]
		var r := Rect2(20, 632 + i * 94, 680, 86)
		_person(r, f[0], f[1], f[2], f[3], f[4], f[5], f[6])
		_btn(Rect2(34, r.position.y + 14, 150, 58), "پیام", "blue")


# -- the first session --------------------------------------------------------------------------------------
func _s_tutorial() -> void:
	_s_activity()
	# dim everything but the one thing to tap
	var hole := Rect2(360, 250, 346, 214)
	var dims := [Rect2(0, 0, W, hole.position.y), Rect2(0, hole.end.y, W, H - hole.end.y), Rect2(0, hole.position.y, hole.position.x, hole.size.y), Rect2(hole.end.x, hole.position.y, W - hole.end.x, hole.size.y)]
	for d in dims:
		_rect(d, Color(0.01, 0.01, 0.05, 0.78))
	var ring := _frame(Rect2(hole.position + Vector2(4, 4), hole.size - Vector2(8, 8)), 26.0, Color(0, 0, 0, 0), Color(0, 0, 0, 0), GOLD, 0.0, 5.0)
	(ring.material as ShaderMaterial).set_shader_parameter("glow", Color(GOLD, 0.9))
	(ring.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
	# a pointing hand under it
	_emboss("m_hand", Rect2(560, 430, 96, 96), "cream")
	# the guide: the fox, speaking
	_emboss("fox", Rect2(470, 800, 240, 240), "fox")
	var bub := Rect2(30, 620, 520, 250)
	_card(bub, Color(GOLD, 0.4))
	var tail := Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(470, 866), Vector2(530, 866), Vector2(540, 910)])
	tail.color = Color(0.06, 0.07, 0.17, 0.97)
	ui.add_child(tail)
	_big(Rect2(50, 636, 480, 44), "اول یک شغل پیدا کن!", 30, "#FFFFFF", "#FFE3B0")
	_wrap(_txt(Rect2(50, 684, 480, 100), "با شغل هر شیفت پول می‌گیری و مهارتت بالا می‌رود. روی «کار» بزن تا شغل‌های شهر را ببینی.", 18, Color("#DDE3F5")), Vector2(480, 100))
	for i in 6:
		_circle(Vector2(490 - i * 30, 820), 8, GOLD, 2.0, GOLD if i <= 1 else Color(0.12, 0.14, 0.28))
	_txt(Rect2(50, 804, 220, 32), "مرحله 2 از 6", 16, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
	_btn(Rect2(30, 1010, 200, 64), "رد کردن", "steel")
	# what finishing the guide gives
	_chip(Rect2(250, 1022, 210, 40), "جایزه‌ی پایان: 1,000 نیل", SAFFRON, 15)


# -- coming back each day -----------------------------------------------------------------------------------
func _s_daily() -> void:
	_hdr("جایزه‌ی روزانه", Color("#C0662A"))
	_card(Rect2(20, 256, 680, 88), Color(SAFFRON, 0.45))
	_emboss("x_flame", Rect2(612, 258, 84, 84), "amber")
	_big(Rect2(300, 262, 300, 46), "5 روز پشت‌سرهم", 34, "#FFFFFF", "#FFD66B")
	_txt(Rect2(260, 306, 340, 28), "اگر یک روز نیایی، از روز 1 شروع می‌شود", 15, Color("#FFE3B0"))
	_txt(Rect2(40, 262, 200, 26), "روز بعد تا", 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	_big(Rect2(40, 286, 200, 44), "07:42:10", 30, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_LEFT)
	# a week of rewards: claimed, today, locked, and the chest at the end
	var days := [["coins", "gold", "500 نیل"], ["energy", "amber", "انرژی +10"], ["coins", "gold", "800 نیل"], ["pill", "ruby", "دارو ×2"],
		["x_gem", "sapphire", "5 طلا"], ["coins", "gold", "1,500 نیل"], ["x_chest", "gold", "صندوق هفته"]]
	for i in days.size():
		var dd: Array = days[i]
		var r: Rect2
		if i < 4:
			r = Rect2(536.0 - i * 172.0, 360, 164, 148)
		elif i < 6:
			r = Rect2(536.0 - (i - 4) * 172.0, 520, 164, 148)
		else:
			r = Rect2(20, 520, 336, 148)
		var claimed := i < 4
		var today := i == 4
		_card(r, Color(GOLD, 0.8) if today else Color(0, 0, 0, 0))
		var ic := _emboss(dd[0], Rect2(r.position.x + (r.size.x - 76) / 2.0 if i < 6 else r.end.x - 120, r.position.y + 22, 76 if i < 6 else 110, 76 if i < 6 else 110), dd[1])
		if claimed:
			ic.modulate = Color(1, 1, 1, 0.35)
			_emboss("m_check", Rect2(r.end.x - 52, r.position.y + 6, 44, 44), "emerald")
		_txt(Rect2(r.position.x + 12, r.position.y + 8, 90, 26), "روز %d" % (i + 1), 15, Color("#FFE3B0") if today else Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
		if i == 6:
			_big(Rect2(r.position.x + 16, r.position.y + 40, 200, 44), dd[2], 28, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_LEFT)
			_txt(Rect2(r.position.x + 16, r.position.y + 86, 200, 44), "طلا، دارو و یک لباس", 15, Color("#C9D2EE"), HORIZONTAL_ALIGNMENT_LEFT)
		else:
			_txt(Rect2(r.position.x, r.position.y + 104, r.size.x, 32), dd[2], 17, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	_btn(Rect2(160, 680, 400, 72), "گرفتن جایزه‌ی روز 5", "gold")
	_sec(770, "کارهای امروز")
	var tasks := [["crime", "steel", "3 جرم انجام بده", 2, 3, "300 نیل"], ["x_lift", "amber", "در باشگاه تمرین کن", 1, 1, "انرژی +5"],
		["m_chat", "sapphire", "به یک دوست پیام بده", 0, 1, "100 نیل"], ["work", "teal", "یک شیفت کار کن", 1, 1, "تجربه +20"]]
	for i in tasks.size():
		var t: Array = tasks[i]
		var r := Rect2(20, 824 + i * 70, 680, 64)
		var done: bool = t[3] >= t[4]
		_inset(r, Color(LEAF, 0.55) if done else Color(GOLD, 0.3))
		_emboss(t[0], Rect2(642, r.position.y + 6, 52, 52), t[1])
		ui.add_child(_label(t[2], display_font, 19, Color.WHITE, Rect2(380, r.position.y + 2, 252, 34), HORIZONTAL_ALIGNMENT_RIGHT, 3))
		_bar(Rect2(390, r.position.y + 40, 240, 12), float(t[3]) / t[4], LEAF if done else LAPIS, done)
		_txt(Rect2(300, r.position.y + 30, 84, 30), "%d/%d" % [t[3], t[4]], 14, Color("#C9D2EE"), HORIZONTAL_ALIGNMENT_CENTER)
		if done:
			_btn(Rect2(34, r.position.y + 8, 200, 48), "بگیر  ·  " + t[5], "green")
		else:
			_txt(Rect2(34, r.position.y, 250, 64), t[5], 17, Color("#FFD66B"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)


# -- fighting each other ----------------------------------------------------------------------------------
# Four battle stats trained with energy at a gym; an attack spends energy and
# is decided by them, the weapons and the armour; the winner chooses what
# happens to the loser; a bounty pays whoever puts someone in hospital.

const BSTATS := [["x_biceps", "ruby", "قدرت", 1240, ANAR], ["x_sprint", "sapphire", "سرعت", 980, LAPIS], ["x_shield", "steel", "دفاع", 1105, Color("#8E97B4")], ["x_dodge", "emerald", "چالاکی", 860, LEAF]]


func _s_gym() -> void:
	_hdr("باشگاه", Color("#8A3A2A"))
	_card(Rect2(20, 256, 680, 150), Color(SAFFRON, 0.35))
	_emboss("x_lift", Rect2(590, 262, 104, 104), "amber")
	_big(Rect2(300, 266, 280, 46), "باشگاه آهنین", 34, "#FFFFFF", "#FFE3B0")
	_txt(Rect2(260, 312, 320, 26), "رده 3 از 8  ·  هر تمرین 20٪ بیشتر", 15, Color("#FFE3B0"))
	_txt(Rect2(40, 266, 220, 26), "قدرت نبرد", 15, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	_big(Rect2(40, 290, 220, 50), "4,185", 40, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_LEFT)
	_emboss("energy", Rect2(600, 350, 44, 44), "amber")
	_pbar(Rect2(60, 358, 530, 28), 0.85, SAFFRON, "85 از 100 انرژی")
	for i in BSTATS.size():
		var b: Array = BSTATS[i]
		var r := Rect2(366.0 - (i % 2) * 346.0, 424 + (i / 2) * 290, 334, 276)
		_card(r)
		_emboss(b[0], Rect2(r.position.x + 107, r.position.y + 10, 120, 120), b[1])
		ui.add_child(_label(b[2], display_font, 26, Color.WHITE, Rect2(r.position.x, r.position.y + 128, r.size.x, 36), HORIZONTAL_ALIGNMENT_CENTER, 5))
		_big(Rect2(r.position.x, r.position.y + 160, r.size.x, 44), _n(b[3]), 36, "#FFFFFF", Color(b[4]).lightened(0.5).to_html(false), HORIZONTAL_ALIGNMENT_CENTER)
		_txt(Rect2(r.position.x, r.position.y + 202, r.size.x, 22), "+12 در هر تمرین", 14, Color("#BFFFD0"), HORIZONTAL_ALIGNMENT_CENTER)
		_btn(Rect2(r.position.x + 30, r.position.y + 224, r.size.x - 60, 44), "تمرین  ·  5 انرژی", "gold" if i == 0 else "blue")
	_inset(Rect2(20, 1010, 680, 84), Color(LEAF, 0.4))
	_emboss("mood", Rect2(626, 1018, 64, 64), "amber")
	_wrap(_txt(Rect2(40, 1016, 576, 72), "شادی تو 78 است: هرچه شادتر باشی تمرین اثر بیشتری دارد. خواب و غذا را فراموش نکن.", 16, Color("#DDE3F5")), Vector2(576, 72))


func _stat_vs(y: float, name: String, mine: int, theirs: int, col: Color) -> void:
	var hi := float(maxi(mine, theirs))
	_txt(Rect2(300, y - 4, 120, 26), name, 15, Color("#C9D2EE"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	var wm := 230.0 * mine / hi
	var wt := 230.0 * theirs / hi
	_rect(Rect2(430, y, 230, 16), Color(0.1, 0.12, 0.25))
	_rect(Rect2(430, y, wm, 16), col)
	_rect(Rect2(60 + 230 - wt, y, wt, 16), col.darkened(0.2))
	_rect(Rect2(60, y, 230 - wt, 16), Color(0.1, 0.12, 0.25))
	_txt(Rect2(560, y + 16, 100, 20), _n(mine), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_txt(Rect2(60, y + 16, 100, 20), _n(theirs), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)


func _s_attack() -> void:
	_hdr("حمله", Color("#A01E2A"))
	_card(Rect2(20, 256, 680, 380), Color(ANAR, 0.4))
	_avatar_big(Rect2(540, 276, 140, 140), "fox", "fox", Color("#0E5E58"), FIROUZEH)
	_avatar_big(Rect2(40, 276, 140, 140), "lion", "gold", Color("#4A2A10"), ANAR)
	_emboss("swords", Rect2(290, 270, 140, 140), "ruby")
	_big(Rect2(280, 388, 160, 50), "در برابر", 26, "#FFFFFF", "#FFC9CC", HORIZONTAL_ALIGNMENT_CENTER)
	_big(Rect2(500, 428, 200, 40), "سارا", 28, "#FFFFFF", "#BFEFFF", HORIZONTAL_ALIGNMENT_CENTER)
	_big(Rect2(20, 428, 200, 40), "بردیا", 28, "#FFFFFF", "#FFC9CC", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(500, 464, 200, 22), "سطح 7", 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(20, 464, 200, 22), "سطح 12  ·  مرکز شهر", 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	var theirs := [1380, 1020, 1210, 700]
	for i in BSTATS.size():
		_stat_vs(500 + i * 32, BSTATS[i][2], BSTATS[i][3], theirs[i], BSTATS[i][4])
	_chip(Rect2(250, 594, 220, 34), "جایزه روی سرش: 5,000 نیل", SAFFRON, 15)
	_sec(648, "تجهیزات")
	var gear := [["rifle", "steel", "تفنگ شکاری", "آسیب 62  ·  دقت 70٪"], ["x_knife", "steel", "چاقوی ضامن‌دار", "آسیب 28"], ["x_vest", "emerald", "جلیقه‌ی ضدگلوله", "زره 45"]]
	for i in gear.size():
		var g: Array = gear[i]
		var r := Rect2(478.0 - i * 229.0, 702, 222, 150)
		_card(r)
		_emboss(g[0], Rect2(r.position.x + 66, r.position.y + 6, 90, 90), g[1])
		ui.add_child(_label(g[2], display_font, 19, Color.WHITE, Rect2(r.position.x, r.position.y + 92, r.size.x, 30), HORIZONTAL_ALIGNMENT_CENTER, 4))
		_txt(Rect2(r.position.x, r.position.y + 120, r.size.x, 24), g[3], 13, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_inset(Rect2(20, 868, 680, 116), Color(SAFFRON, 0.5))
	_ring(Rect2(584, 878, 96, 96), 0.62, SAFFRON)
	_txt(Rect2(584, 878, 96, 96), "62٪", 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	ui.add_child(_label("احتمال پیروزی", display_font, 23, Color.WHITE, Rect2(260, 878, 310, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_txt(Rect2(160, 914, 410, 26), "هزینه: 25 انرژی", 16, Color("#FFE3B0"))
	_txt(Rect2(100, 942, 470, 26), "اگر ببازی: حدود 40 دقیقه بیمارستان", 15, Color("#FFB0B4"))
	_btn(Rect2(120, 1002, 480, 90), "حمله", "red")


func _s_fight() -> void:
	_hdr("نتیجه‌ی نبرد", Color("#A01E2A"))
	_card(Rect2(20, 256, 680, 120), Color(GOLD, 0.6))
	_emboss("x_laurel", Rect2(590, 262, 104, 104), "gold")
	_emboss("x_laurel", Rect2(26, 262, 104, 104), "gold")
	_big(Rect2(140, 268, 440, 64), "پیروز شدی!", 52, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(140, 332, 440, 28), "بردیا در 4 دور از پا درآمد", 17, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_CENTER)
	_card(Rect2(20, 392, 680, 330))
	_txt(Rect2(380, 400, 300, 26), "سارا", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_txt(Rect2(40, 400, 300, 26), "بردیا", 16, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
	_pbar(Rect2(380, 428, 300, 22), 0.74, LEAF, "740 از 1,000")
	_pbar(Rect2(40, 428, 300, 22), 0.0, ANAR, "0 از 1,200")
	var log := [["rifle", "steel", "دور 1: با تفنگ شلیک کردی", "186 آسیب", LEAF], ["x_fist", "ruby", "دور 1: بردیا با مشت زد", "92 آسیب", ANAR],
		["x_dodge", "emerald", "دور 2: از ضربه‌ی چاقو جاخالی دادی", "بدون آسیب", LAPIS], ["rifle", "steel", "دور 2: شلیک به پا", "240 آسیب", LEAF],
		["x_knife", "steel", "دور 3: با چاقو زدی", "310 آسیب", LEAF], ["rifle", "steel", "دور 4: شلیک آخر", "464 آسیب", GOLD]]
	for i in log.size():
		var l: Array = log[i]
		var y := 466.0 + i * 42.0
		_emboss(l[0], Rect2(640, y, 38, 38), l[1])
		_txt(Rect2(220, y + 2, 412, 34), l[2], 17, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, body_bold)
		_txt(Rect2(40, y + 2, 170, 34), l[3], 16, Color(l[4]).lightened(0.3), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
	_sec(736, "با بردیا چه کنی؟")
	var opts := [["x_cash", "gold", "جیبش را بزن", "3,200 نیل", "سود: پول"], ["x_hosp", "ruby", "بیمارستان", "2 ساعت", "سود: احترام"], ["f_dove", "steel", "رهایش کن", "تجربه +50", "سود: تجربه"]]
	for i in opts.size():
		var o: Array = opts[i]
		var r := Rect2(478.0 - i * 229.0, 790, 222, 230)
		var b := _button(r, Color("#3F55A8"), Color("#1A2560"), Color("#0A1030"), 22.0, 8.0)
		_emboss(o[0], Rect2(r.position.x + 56, r.position.y + 8, 110, 110), o[1])
		b.add_child(_glabel(o[2], display_font, 25, "#FFFFFF", "#FFD66B", Rect2(0, 116, r.size.x, 36), HORIZONTAL_ALIGNMENT_CENTER, 5))
		b.add_child(_label(o[3], display_font, 20, Color("#FFE3B0"), Rect2(0, 152, r.size.x, 30), HORIZONTAL_ALIGNMENT_CENTER, 3))
		b.add_child(_label(o[4], body_bold, 14, Color("#C9D2EE"), Rect2(0, 182, r.size.x, 26), HORIZONTAL_ALIGNMENT_CENTER, 0))
	_chip(Rect2(170, 1040, 380, 44), "جایزه‌ی سر: 5,000 نیل به حسابت آمد", LEAF, 17)


func _s_bounty() -> void:
	_hdr("تحت تعقیب", Color("#6E3A10"))
	_inset(Rect2(20, 256, 680, 70), Color(SAFFRON, 0.5))
	_emboss("x_wanted", Rect2(632, 260, 60, 60), "amber")
	_wrap(_txt(Rect2(260, 258, 366, 66), "هر کس هدف را به بیمارستان بفرستد جایزه را می‌برد", 15, Color("#FFE3B0")), Vector2(366, 66))
	_btn(Rect2(36, 264, 210, 54), "+ گذاشتن جایزه", "gold")
	# name, avatar, palette, tint, level, reward, by, state
	var wanted := [["بردیا", "lion", "gold", Color("#4A2A10"), 12, "5,000", "ناشناس", ""],
		["رضا گرگه", "a_wolf", "steel", Color("#2A2F3A"), 18, "22,000", "جناح شیرها", ""],
		["مینا", "a_raccoon", "cream", Color("#3A2A5A"), 9, "1,500", "کاوه", "در بیمارستان"],
		["سامان", "x_ninja", "steel", Color("#1E1E28"), 21, "40,000", "دولت شهر", "در سفر"]]
	for i in wanted.size():
		var w: Array = wanted[i]
		var r := Rect2(366.0 - (i % 2) * 346.0, 342 + (i / 2) * 376, 334, 364)
		# a poster: paper, a title, the face, the price
		var f := _frame(r, 10.0, Color("#E9D6A8"), Color("#C9A86A"), Color("#6E4A1A"), 0.0, 3.0)
		(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.6)
		_big(Rect2(r.position.x, r.position.y + 8, r.size.x, 46), "تحت تعقیب", 34, "#6E1A10", "#3A0A04", HORIZONTAL_ALIGNMENT_CENTER)
		_plate(w[1], Rect2(r.position.x + 97, r.position.y + 56, 140, 140), w[2], w[3])
		_txt(Rect2(r.position.x, r.position.y + 198, r.size.x, 34), "%s  ·  سطح %d" % [w[0], w[4]], 21, Color("#3A2208"), HORIZONTAL_ALIGNMENT_CENTER, display_font)
		_big(Rect2(r.position.x, r.position.y + 230, r.size.x, 50), w[5] + " نیل", 38, "#FFE680", "#B06A00", HORIZONTAL_ALIGNMENT_CENTER)
		_txt(Rect2(r.position.x, r.position.y + 280, r.size.x, 22), "از طرف: " + w[6], 14, Color("#5A3A18"), HORIZONTAL_ALIGNMENT_CENTER, body_bold)
		if w[7] != "":
			_btn(Rect2(r.position.x + 40, r.position.y + 306, r.size.x - 80, 48), w[7], "steel")
		else:
			_btn(Rect2(r.position.x + 40, r.position.y + 306, r.size.x - 80, 48), "حمله", "red")


# -- the city's newspaper -----------------------------------------------------------------------------------
# Everything here is already an event on the server: strikes, elections,
# listings, arrests, bills, weddings. The paper only says them aloud.

const PAPER := Color("#EFE3C6")
const INKC := Color("#2A1E10")


func _paper(r: Rect2) -> void:
	var f := _frame(r, 8.0, PAPER, PAPER.darkened(0.12), Color("#8A6A3A"), 0.0, 2.0)
	(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.5)


func _s_news() -> void:
	_hdr("روزنامه", Color("#5A4A2A"))
	_paper(Rect2(20, 256, 680, 110))
	_big(Rect2(40, 258, 640, 66), "فنویک امروز", 54, "#2A1E10", "#5A3A18", HORIZONTAL_ALIGNMENT_CENTER)
	_rect(Rect2(40, 324, 640, 2), Color(INKC, 0.6))
	_txt(Rect2(40, 330, 640, 30), "یکشنبه 12 مهر  ·  شماره‌ی 214  ·  روز 3 جنگ", 15, INKC, HORIZONTAL_ALIGNMENT_CENTER, body_bold)
	var cats := [["همه", true], ["جنگ", false], ["سیاست", false], ["اقتصاد", false], ["جامعه", false], ["جرم", false]]
	for i in cats.size():
		var c: Array = cats[i]
		_chip(Rect2(592.0 - i * 114.0, 380, 106, 36), c[0], Color("#8A6A3A") if c[1] else Color("#3A4058"), 16)
	# the front page
	_paper(Rect2(20, 430, 680, 280))
	_emboss("u_ballistic", Rect2(40, 446, 200, 200), "ruby")
	_chip(Rect2(574, 446, 110, 30), "جنگ", ANAR, 14)
	var head := _txt(Rect2(260, 482, 424, 100), "موشک‌های فنویک پایگاه هوایی کالدریس را هدف گرفتند", 27, INKC, HORIZONTAL_ALIGNMENT_RIGHT, display_font)
	_wrap(head, Vector2(424, 100))
	_wrap(_txt(Rect2(260, 584, 424, 84), "ستاد کل: 7 موشک از پدافند گذشت و باند فرودگاه آسیب سنگین دید. کالدریس هنوز واکنشی نشان نداده است.", 15, Color("#4A3A20"), HORIZONTAL_ALIGNMENT_RIGHT, body_bold), Vector2(424, 84))
	_txt(Rect2(40, 668, 300, 26), "12 دقیقه پیش", 14, Color("#6A5A40"), HORIZONTAL_ALIGNMENT_LEFT, body_bold)
	# the rest of the paper
	var items := [["vote", "violet", "سیاست", "آرش کمالی با 54٪ رأی شهردار فنویک شد", "1 ساعت"],
		["chart", "emerald", "اقتصاد", "سهام صنایع آراز امروز 12٪ بالا رفت", "2 ساعت"],
		["f_rings", "gold", "جامعه", "سارا و آرش در تالار آزور ازدواج کردند", "3 ساعت"],
		["handcuffs", "steel", "جرم", "سرقت از بانک مرکزی؛ 3 نفر در زندان", "5 ساعت"],
		["gavel", "steel", "مجلس", "لایحه‌ی مالیات بازار با 31 رأی تصویب شد", "دیروز"]]
	for i in items.size():
		var it: Array = items[i]
		var r := Rect2(20, 724 + i * 74, 680, 68)
		_paper(r)
		_emboss(it[0], Rect2(634, r.position.y + 6, 56, 56), it[1])
		_txt(Rect2(150, r.position.y + 2, 476, 38), it[3], 18, INKC, HORIZONTAL_ALIGNMENT_RIGHT, display_font)
		_txt(Rect2(150, r.position.y + 36, 476, 26), it[2], 13, Color("#8A5A20"), HORIZONTAL_ALIGNMENT_RIGHT, body_bold)
		_txt(Rect2(36, r.position.y, 110, 68), it[4], 14, Color("#6A5A40"), HORIZONTAL_ALIGNMENT_LEFT, body_bold)


# -- inviting friends from Telegram --------------------------------------------------------------------------
func _s_invite() -> void:
	_hdr("دعوت دوستان", Color("#2A6AB0"))
	_card(Rect2(20, 256, 680, 290), Color(LAPIS, 0.45))
	_emboss("x_present", Rect2(560, 262, 130, 130), "ruby")
	_big(Rect2(40, 272, 510, 50), "دوستانت را بیاور", 38, "#FFFFFF", "#BFD4FF")
	_wrap(_txt(Rect2(40, 324, 510, 60), "وقتی دوستت به سطح 5 برسد، هر دو جایزه می‌گیرید.", 17, Color("#DDE3F5")), Vector2(510, 60))
	_inset(Rect2(40, 398, 640, 60), Color(GOLD, 0.5))
	var link := _txt(Rect2(180, 398, 490, 60), "t.me/torncity_bot?start=ref_S4R4", 19, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
	link.text_direction = Control.TEXT_DIRECTION_LTR
	_btn(Rect2(48, 406, 124, 44), "کپی", "steel")
	_btn(Rect2(40, 470, 640, 66), "اشتراک در تلگرام", "blue")
	_emboss("x_send", Rect2(560, 474, 54, 54), "cream")
	_sec(560, "جایزه‌های دعوت  ·  4 نفر")
	var steps := [[1, "coins", "gold", "1,000 نیل"], [3, "x_chest", "gold", "صندوق طلایی"], [5, "x_crown", "amber", "قاب ویژه"], [10, "x_car", "ruby", "ماشین مسابقه"], [25, "x_laurel", "gold", "لقب «سفیر»"]]
	var x0 := 640.0
	var x1 := 80.0
	_rect(Rect2(x1, 736, x0 - x1, 8), Color(0.2, 0.23, 0.4))
	var pos := [0.0, 0.25, 0.5, 0.75, 1.0]
	var reach := x0 - (x0 - x1) * 0.4
	_rect(Rect2(reach, 736, x0 - reach, 8), LAPIS.lightened(0.2))
	for i in steps.size():
		var s: Array = steps[i]
		var sx: float = x0 - (x0 - x1) * pos[i]
		var done: bool = s[0] <= 4
		_emboss(s[1], Rect2(sx - 42, 624, 84, 84), s[2]).modulate = Color(1, 1, 1, 1.0 if not done else 0.45)
		_circle(Vector2(sx, 740), 15, GOLD, 3.0, LAPIS.lightened(0.2) if done else Color(0.12, 0.14, 0.28))
		_txt(Rect2(sx - 20, 726, 40, 28), str(s[0]), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
		_txt(Rect2(sx - 70, 760, 140, 26), s[3], 14, Color("#FFE3B0") if not done else Color("#8E97B4"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	_sec(800, "دعوت‌شده‌ها")
	var ppl := [["نگار", "eagle", "sapphire", Color("#101E60"), "به سطح 5 رسید  ·  جایزه گرفتید", LEAF, true],
		["سینا", "a_foxkid", "fox", Color("#5E2A10"), "سطح 3 از 5", SAFFRON, false],
		["دنیا", "a_raccoon", "cream", Color("#3A2A5A"), "سطح 1 از 5", SAFFRON, false]]
	for i in ppl.size():
		var p: Array = ppl[i]
		var r := Rect2(20, 854 + i * 82, 680, 76)
		_person(r, p[0], p[1], p[2], p[3], p[4], p[5], true)
		if p[6]:
			_emboss("m_check", Rect2(40, r.position.y + 12, 52, 52), "emerald")
		else:
			_bar(Rect2(40, r.position.y + 30, 160, 16), 0.6 if i == 1 else 0.2, SAFFRON, false)


# -- the casino ------------------------------------------------------------------------------------------------
func _s_casino() -> void:
	_hdr("کازینو", Color("#6A2AA0"))
	_card(Rect2(20, 256, 680, 170), Color(VIOLET, 0.45))
	_emboss("coins", Rect2(596, 262, 96, 96), "gold")
	_txt(Rect2(360, 266, 230, 26), "ژتون‌ها", 15, Color("#E0D4FF"))
	_big(Rect2(300, 290, 290, 56), "2,400", 46, "#FFF6C8", "#FFB21F")
	_btn(Rect2(40, 272, 150, 56), "خرید ژتون", "gold")
	_btn(Rect2(200, 272, 110, 56), "فروش", "steel")
	_txt(Rect2(360, 356, 320, 24), "سقف باخت امروز", 14, Color("#AEB8D8"))
	_pbar(Rect2(200, 384, 480, 24), 0.24, SAFFRON, "1,200 از 5,000")
	_btn(Rect2(40, 374, 150, 44), "تغییر سقف", "steel")
	var games := [["x_slot", "amber", "اسلات", "بُرد تا ×500", Color(SAFFRON, 0.5)], ["x_cards", "ruby", "بلک‌جک", "در برابر دیلر", Color(0, 0, 0, 0)],
		["x_dice", "emerald", "تاس", "بیشتر یا کمتر از 7", Color(0, 0, 0, 0)], ["x_ticket", "violet", "بخت‌آزمایی", "قرعه‌کشی جمعه", Color(VIOLET, 0.5)]]
	for i in games.size():
		var g: Array = games[i]
		var r := Rect2(366.0 - (i % 2) * 346.0, 442 + (i / 2) * 230, 334, 218)
		_tile(r, g[0], g[1], g[2], g[3], 0, g[4])
	_inset(Rect2(20, 906, 680, 90), Color(VIOLET, 0.5))
	_emboss("x_ticket", Rect2(620, 916, 70, 70), "violet")
	ui.add_child(_label("جایزه‌ی بزرگ جمعه", display_font, 21, Color.WHITE, Rect2(300, 912, 310, 34), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_txt(Rect2(300, 946, 310, 30), "بلیت: 100 نیل  ·  2 روز و 4 ساعت", 14, Color("#AEB8D8"))
	_big(Rect2(40, 916, 260, 70), "1,240,000", 34, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_LEFT)
	_txt(Rect2(40, 1008, 640, 30), "آخرین برنده‌ها:  مهتاب 12,000 در اسلات  ·  کاوه 4,500 در بلک‌جک", 15, Color("#E0D4FF"), HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(40, 1042, 640, 30), "بازی مسئولانه: سقف روزانه را خودت تعیین می‌کنی و از آن بیشتر نمی‌شود.", 13, Color("#8E97B4"), HORIZONTAL_ALIGNMENT_CENTER)


func _s_slots() -> void:
	_hdr("اسلات", Color("#6A2AA0"))
	# the machine
	var m := _frame(Rect2(40, 262, 640, 520), 40.0, Color("#B0301A"), Color("#5A0A10"), GOLD, 0.06, 5.0)
	(m.material as ShaderMaterial).set_shader_parameter("glow", Color(GOLD, 0.6))
	_big(Rect2(40, 270, 640, 60), "گنج پارسی", 46, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
	for k in 12:
		_circle(Vector2(80 + k * 51.0, 344), 7, GOLD, 2.0, Color("#FFE680") if k % 2 == 0 else Color("#FF8A3A"))
	var reels := [["x_star", "x_crown", "f_hearts"], ["x_gem", "x_crown", "coins"], ["x_flame", "x_crown", "x_star"]]
	var pals := {"x_star": "gold", "x_crown": "gold", "f_hearts": "ruby", "x_gem": "sapphire", "coins": "gold", "x_flame": "amber"}
	for i in 3:
		var r := Rect2(476.0 - i * 196.0, 366, 180, 330)
		var f := _frame(r, 14.0, Color("#FFF8E8"), Color("#CFC2A0"), Color("#6E4A1A"), 0.0, 3.0)
		(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		for j in 3:
			var ic: String = reels[i][j]
			var e := _emboss(ic, Rect2(r.position.x + 36, r.position.y + 8 + j * 108, 108, 104), pals[ic])
			if j != 1:
				e.modulate = Color(1, 1, 1, 0.45)
	# the payline, lit
	_rect(Rect2(60, 528, 600, 4), Color(GOLD, 0.9))
	var win := _frame(Rect2(150, 700, 420, 64), 30.0, Color("#FFE680"), Color("#F5A11F"), Color("#9A4E06"), 0.0, 3.0)
	(win.material as ShaderMaterial).set_shader_parameter("glow", Color(GOLD, 0.8))
	_big(Rect2(150, 700, 420, 64), "بُرد!  3 تاج  ·  5,000", 32, "#5A2A00", "#3A1600", HORIZONTAL_ALIGNMENT_CENTER)
	# the bet
	_inset(Rect2(20, 800, 680, 90), Color(GOLD, 0.5))
	_txt(Rect2(470, 800, 210, 90), "شرط هر چرخش", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	var minus := _button(Rect2(340, 818, 56, 56), Color("#8E97B4"), Color("#4A536E"), Color("#1E2436"), 16.0, 5.0)
	minus.add_child(_label("−", display_font, 36, Color.WHITE, Rect2(0, -6, 56, 60), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_big(Rect2(190, 812, 140, 66), "100", 40, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
	var plus := _button(Rect2(124, 818, 56, 56), LEAF.lightened(0.3), LEAF.darkened(0.1), LEAF.darkened(0.55), 16.0, 5.0)
	plus.add_child(_label("+", display_font, 36, Color.WHITE, Rect2(0, -6, 56, 60), HORIZONTAL_ALIGNMENT_CENTER, 4))
	_chip(Rect2(34, 830, 80, 32), "حداکثر", Color("#59607A"), 14)
	var pay := [["x_crown", "gold", "×50"], ["x_gem", "sapphire", "×20"], ["f_hearts", "ruby", "×10"], ["x_star", "gold", "×5"]]
	for i in pay.size():
		var p: Array = pay[i]
		var x := 540.0 - i * 170.0
		_emboss(p[0], Rect2(x + 84, 904, 48, 48), p[1])
		_txt(Rect2(x, 904, 80, 48), "3 = " + p[2], 16, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_btn(Rect2(120, 972, 480, 100), "بچرخان!", "gold")


# -- street racing ---------------------------------------------------------------------------------------------
func _s_race() -> void:
	_hdr("مسابقه", Color("#A01E2A"))
	_card(Rect2(20, 256, 680, 400), Color(ANAR, 0.35))
	_txt(Rect2(40, 264, 640, 30), "جاده‌ی ساحلی آزور  ·  دور 2 از 3  ·  زنده", 17, Color("#FFD0D4"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	# the track: an oval of asphalt, a dashed line, the start
	var c := Vector2(360, 470)
	var pts := PackedVector2Array()
	for i in 97:
		var a := TAU * i / 96.0
		pts.append(c + Vector2(cos(a) * 280, sin(a) * 140))
	var asphalt := Line2D.new()
	asphalt.points = pts
	asphalt.width = 54
	asphalt.default_color = Color("#2A2C36")
	asphalt.antialiased = true
	_node(asphalt)
	var kerb := Line2D.new()
	kerb.points = pts
	kerb.width = 3
	kerb.default_color = Color("#FFFFFF", 0.6)
	_node(kerb)
	for k in 8:
		var y := 470 + 140 - 24 + k * 6.0
		_rect(Rect2(356 + (k % 2) * 6.0, y, 6, 6), Color.WHITE)
		_rect(Rect2(362 - (k % 2) * 6.0, y, 6, 6), Color.BLACK)
	# the cars, where they are on the lap
	var cars := [["نگار", 1.95, Color("#3F7BE8")], ["سارا", 1.80, FIROUZEH], ["کاوه", 1.45, SAFFRON], ["بردیا", 0.95, ANAR]]
	for car in cars:
		var a: float = PI / 2.0 - TAU * float(car[1]) / 2.0
		var p := c + Vector2(cos(a) * 280, sin(a) * 140)
		_circle(p, 13, Color.WHITE, 3.0, car[2])
		_txt(Rect2(p.x - 60, p.y - 44, 120, 28), car[0], 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 4)
	_emboss("x_flag", Rect2(320, 420, 80, 80), "steel")
	# the order
	var order := [["1", "نگار", "تندباد GT", "—", Color("#3F7BE8")], ["2", "سارا", "شاهین R", "+0.8 ثانیه", FIROUZEH], ["3", "کاوه", "کویر 4x4", "+2.1 ثانیه", SAFFRON], ["4", "بردیا", "پلنگ S", "+4.5 ثانیه", ANAR]]
	for i in order.size():
		var o: Array = order[i]
		var r := Rect2(20, 670 + i * 66, 680, 60)
		_inset(r, Color(FIROUZEH, 0.7) if i == 1 else Color(GOLD, 0.25))
		_big(Rect2(630, r.position.y, 56, 60), o[0], 34, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_CENTER)
		_circle(Vector2(606, r.position.y + 30), 10, Color.WHITE, 2.0, o[4])
		ui.add_child(_label(o[1], display_font, 21, Color.WHITE, Rect2(420, r.position.y, 170, 60), HORIZONTAL_ALIGNMENT_RIGHT, 4))
		_txt(Rect2(240, r.position.y, 170, 60), o[2], 15, Color("#AEB8D8"))
		_txt(Rect2(40, r.position.y, 190, 60), o[3], 16, Color("#FFD0D4"), HORIZONTAL_ALIGNMENT_LEFT, display_font, 3)
	_inset(Rect2(20, 940, 680, 150), Color(SAFFRON, 0.5))
	_emboss("x_car", Rect2(596, 950, 96, 96), "ruby")
	ui.add_child(_label("شاهین R", display_font, 24, Color.WHITE, Rect2(380, 950, 206, 36), HORIZONTAL_ALIGNMENT_RIGHT, 4))
	_txt(Rect2(300, 986, 286, 26), "سرعت 220  ·  شتاب 7.1  ·  کنترل 68", 14, Color("#AEB8D8"))
	_txt(Rect2(300, 1014, 286, 26), "جایزه‌ی نفر اول: 12,000 نیل", 15, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_btn(Rect2(40, 962, 240, 100), "نیترو ×2", "red")
	_emboss("x_flame", Rect2(44, 960, 60, 60), "amber")


# -- land on the map --------------------------------------------------------------------------------------------
# The server knows places but not plots: a plot is a lot in a district with a
# size, a zoning (what may stand on it), an owner or a price. The 3D city
# (city_proto) draws what stands on each; this is the ledger view of one
# district.

func _s_plot() -> void:
	_hdr("زمین‌ها", Color("#3D6B3A"))
	_card(Rect2(20, 256, 680, 450), Color(LEAF, 0.3))
	_txt(Rect2(40, 262, 640, 30), "محله‌ی باغ‌ها  ·  مسکونی  ·  20 قطعه", 17, Color("#BFFFD0"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	var map := Rect2(40, 300, 640, 344)
	_rect(map, Color("#1E2A20"))
	# plots in a grid between roads: mine, for sale, owned, green
	var state := ["o", "o", "s", "g", "o",
		"m", "o", "o", "s", "o",
		"o", "g", "o", "o", "sel",
		"s", "o", "m", "o", "g"]
	var owners := ["آ", "م", "", "", "ب", "", "ن", "ک", "", "د", "ر", "", "س", "ج", "", "", "ه", "", "ی", ""]
	var cw := 640.0 / 5.0
	var ch := 344.0 / 4.0
	for i in 20:
		var col := i % 5
		var row := i / 5
		var r := Rect2(map.end.x - (col + 1) * cw + 8, map.position.y + row * ch + 8, cw - 16, ch - 16)
		var st: String = state[i]
		match st:
			"m":
				_rect(r, Color(FIROUZEH, 0.75))
				_emboss("house", Rect2(r.position.x + r.size.x / 2 - 24, r.position.y + 8, 48, 48), "cream")
			"s", "sel":
				_rect(r, Color(GOLD, 0.25))
				_frame(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), 6.0, Color(0, 0, 0, 0), Color(0, 0, 0, 0), GOLD, 0.0, 3.0 if st == "sel" else 2.0)
				_txt(Rect2(r.position.x, r.position.y + r.size.y - 30, r.size.x, 26), "فروشی", 14, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
			"g":
				_rect(r, Color("#2E6A3A"))
				_emboss("x_sprout", Rect2(r.position.x + r.size.x / 2 - 22, r.position.y + 14, 44, 44), "emerald")
			_:
				_rect(r, Color("#3A4058"))
				_txt(Rect2(r.position.x, r.position.y, r.size.x, r.size.y), owners[i], 26, Color("#8E97B4"), HORIZONTAL_ALIGNMENT_CENTER, display_font)
		if st == "sel":
			var glow := _frame(r, 6.0, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(GOLD, 0.0), 0.0, 1.0)
			(glow.material as ShaderMaterial).set_shader_parameter("glow", Color(GOLD, 0.9))
			_emboss("x_map", Rect2(r.position.x + r.size.x / 2 - 26, r.position.y - 30, 52, 52), "ruby")
	var leg := [["مال من", FIROUZEH], ["فروشی", GOLD.darkened(0.2)], ["دیگران", Color("#59607A")], ["فضای سبز", Color("#2E8A4A")]]
	for i in leg.size():
		_chip(Rect2(536.0 - i * 164.0, 656, 150, 34), leg[i][0], leg[i][1], 15)
	# the chosen plot
	_card(Rect2(20, 722, 680, 372), Color(GOLD, 0.45))
	_emboss("x_field", Rect2(596, 734, 92, 92), "emerald")
	_big(Rect2(300, 738, 290, 46), "قطعه‌ی V-15", 34, "#FFFFFF", "#FFE3B0")
	_txt(Rect2(260, 786, 330, 26), "600 متر  ·  کاربری مسکونی  ·  نبش", 16, Color("#C9D2EE"))
	_txt(Rect2(40, 742, 240, 26), "قیمت", 15, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_LEFT)
	_big(Rect2(40, 766, 240, 50), "240,000", 38, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_LEFT)
	_txt(Rect2(40, 830, 640, 28), "همسایه‌ها: آرش و مهتاب  ·  نزدیک پارک  ·  مالیات سالانه 1٪", 15, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(40, 866, 640, 28), "چه می‌توان ساخت؟", 17, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	var builds := [["house", "amber", "خانه", "60,000  ·  4 روز"], ["f_house", "gold", "خانه‌ی خانوادگی", "140,000  ·  7 روز"], ["city", "sapphire", "ویلا با استخر", "320,000  ·  12 روز"]]
	for i in builds.size():
		var b: Array = builds[i]
		var r := Rect2(478.0 - i * 229.0, 900, 222, 96)
		_inset(r)
		_emboss(b[0], Rect2(r.end.x - 72, r.position.y + 12, 64, 64), b[1])
		ui.add_child(_label(b[2], display_font, 17, Color.WHITE, Rect2(r.position.x + 6, r.position.y + 12, r.size.x - 84, 32), HORIZONTAL_ALIGNMENT_RIGHT, 3))
		_txt(Rect2(r.position.x + 6, r.position.y + 48, r.size.x - 84, 26), b[3], 13, Color("#AEB8D8"))
	_btn(Rect2(370, 1010, 310, 72), "خرید زمین", "gold")
	_btn(Rect2(40, 1010, 310, 72), "پیشنهاد قیمت", "steel")


# -- a will --------------------------------------------------------------------------------------------------
func _s_will() -> void:
	_hdr("وصیت‌نامه", Color("#5A4A2A"))
	_paper(Rect2(20, 256, 680, 150))
	_emboss("x_scroll", Rect2(590, 262, 100, 100), "amber")
	_big(Rect2(260, 270, 320, 50), "وصیت‌نامه‌ی سارا", 36, "#2A1E10", "#5A3A18")
	_txt(Rect2(200, 322, 380, 26), "ثبت‌شده در محضر فنویک  ·  آخرین تغییر: 3 روز پیش", 14, INKC, HORIZONTAL_ALIGNMENT_RIGHT, body_bold)
	_txt(Rect2(200, 350, 380, 26), "وصی: آرش", 15, INKC, HORIZONTAL_ALIGNMENT_RIGHT, display_font)
	_emboss("x_seal", Rect2(40, 280, 110, 110), "ruby")
	_sec(420, "دارایی‌ها  ·  حدود 412,000 نیل")
	var assets := [["bank", "sapphire", "نقد و بانک", "98,750"], ["f_house", "amber", "نیمی از خانه‌ی خانوادگی", "90,000"], ["chart", "emerald", "1,200 سهم صنایع آراز", "63,000"], ["factory", "steel", "کافه‌ی سارا  ·  100٪", "160,000"]]
	for i in assets.size():
		var a: Array = assets[i]
		var r := Rect2(366.0 - (i % 2) * 346.0, 474 + (i / 2) * 84, 334, 76)
		_inset(r)
		_emboss(a[0], Rect2(r.end.x - 66, r.position.y + 8, 58, 58), a[1])
		_txt(Rect2(r.position.x + 8, r.position.y + 4, r.size.x - 80, 34), a[2], 15, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
		_txt(Rect2(r.position.x + 8, r.position.y + 38, r.size.x - 80, 30), a[3], 17, Color("#FFE3B0"), HORIZONTAL_ALIGNMENT_RIGHT, display_font, 3)
	_sec(652, "وارث‌ها")
	_chip(Rect2(40, 656, 140, 34), "جمع 100٪", LEAF, 16)
	var heirs := [["آرش", "a_wolf", "steel", Color("#1E2A5A"), 25, "همسر"], ["نیلا", "a_foxkid", "fox", Color("#5E2A10"), 35, "9 سال  ·  تا 18 سالگی نزد قیم"],
		["کیان", "a_rabbit", "cream", Color("#2A3A6A"), 25, "3 سال  ·  تا 18 سالگی نزد قیم"], ["نوزاد", "f_baby", "amber", Color("#5A3A10"), 15, "12 روزه  ·  تا 18 سالگی نزد قیم"]]
	for i in heirs.size():
		var h: Array = heirs[i]
		var r := Rect2(20, 706 + i * 76, 680, 70)
		_inset(r, Color(GOLD, 0.3))
		_plate(h[1], Rect2(r.end.x - 66, r.position.y + 6, 58, 58), h[2], h[3])
		ui.add_child(_label(h[0], display_font, 20, Color.WHITE, Rect2(460, r.position.y, 160, 40), HORIZONTAL_ALIGNMENT_RIGHT, 3))
		_txt(Rect2(300, r.position.y + 36, 320, 26), h[5], 13, Color("#AEB8D8"))
		_pbar(Rect2(110, r.position.y + 22, 220, 24), h[4] / 100.0, SAFFRON)
		_big(Rect2(34, r.position.y, 70, 70), "%d٪" % h[4], 24, "#FFFFFF", "#FFD66B", HORIZONTAL_ALIGNMENT_CENTER)
	_btn(Rect2(120, 1016, 480, 76), "ثبت در محضر  ·  500 نیل", "gold")


# -- cosmetics ----------------------------------------------------------------------------------------------------
func _framed_avatar(r: Rect2, col: Color, crown: String, pal: String) -> void:
	_ring(Rect2(r.position - Vector2(8, 8), r.size + Vector2(16, 16)), 1.0, col)
	var g := _frame(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), r.size.x / 2.0 + 4, Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(col, 0.0), 0.0, 1.0)
	(g.material as ShaderMaterial).set_shader_parameter("glow", Color(col, 0.6))
	_plate("fox", r, "fox", Color("#0E5E58"))
	if crown != "":
		_emboss(crown, Rect2(r.position.x + r.size.x * 0.28, r.position.y - r.size.y * 0.34, r.size.x * 0.44, r.size.y * 0.44), pal)


func _s_cosmetics() -> void:
	_hdr("ظاهر", Color("#6A2AA0"))
	_card(Rect2(20, 256, 680, 240), Color(GOLD, 0.45))
	_framed_avatar(Rect2(520, 300, 150, 150), GOLD, "x_crown", "gold")
	_big(Rect2(60, 300, 430, 64), "سارا", 54, "#FFE680", "#FF7A3A")
	_txt(Rect2(60, 364, 430, 30), "«سلطان بازار»", 22, Color("#E0D4FF"), HORIZONTAL_ALIGNMENT_RIGHT, display_font, 4)
	_txt(Rect2(60, 404, 430, 26), "همه‌چیز فقط ظاهری است؛ قدرتی نمی‌دهد", 14, Color("#AEB8D8"))
	var tabs := [["قاب", true], ["لقب", false], ["رنگ نام", false], ["پس‌زمینه", false]]
	for i in tabs.size():
		var t: Array = tabs[i]
		var r := Rect2(536.0 - i * 172.0, 510, 164, 56)
		if t[1]:
			var f := _frame(r, 18.0, Color("#8A4AE0"), Color("#3A1880"), GOLD, 0.04, 3.0)
			(f.material as ShaderMaterial).set_shader_parameter("glow", Color(VIOLET, 0.5))
		else:
			_inset(r, Color(GOLD, 0.25))
		ui.add_child(_label(t[0], display_font, 20, Color.WHITE if t[1] else Color("#AEB8D8"), r, HORIZONTAL_ALIGNMENT_CENTER, 4))
	# frame, colour, ornament, palette, state, price
	var frames := [["طلایی", GOLD, "x_crown", "gold", "on", ""], ["فیروزه", FIROUZEH, "", "", "own", ""], ["آتش", ANAR, "x_flame", "amber", "buy", "⭐ 50"],
		["بهار", LEAF, "x_flower", "gold", "event", "نوروز"], ["الماس", Color("#8FD8FF"), "x_gem", "sapphire", "buy", "⭐ 120"], ["شاهی", VIOLET, "x_star", "gold", "buy", "40 طلا"]]
	for i in frames.size():
		var fr: Array = frames[i]
		var r := Rect2(478.0 - (i % 3) * 229.0, 582 + (i / 3) * 256, 222, 244)
		_card(r, Color(GOLD, 0.6) if fr[4] == "on" else Color(0, 0, 0, 0))
		_framed_avatar(Rect2(r.position.x + 56, r.position.y + 40, 110, 110), fr[1], fr[2], fr[3])
		ui.add_child(_label(fr[0], display_font, 22, Color.WHITE, Rect2(r.position.x, r.position.y + 158, r.size.x, 32), HORIZONTAL_ALIGNMENT_CENTER, 4))
		match fr[4]:
			"on":
				_chip(Rect2(r.position.x + 36, r.position.y + 196, 150, 34), "در حال استفاده", LEAF, 14)
			"own":
				_btn(Rect2(r.position.x + 36, r.position.y + 194, 150, 42), "استفاده", "blue")
			"event":
				_chip(Rect2(r.position.x + 26, r.position.y + 196, 170, 34), "فقط در " + fr[5], Color("#59607A"), 14)
			_:
				_btn(Rect2(r.position.x + 36, r.position.y + 194, 150, 42), fr[5], "gold")


# -- a season's event --------------------------------------------------------------------------------------------
func _s_event() -> void:
	_hdr("جشن نوروز", Color("#2E8A4A"))
	var band := _gradient(Rect2(20, 256, 680, 200), Color("#3FAE63"), Color("#E05A8A"))
	band.modulate = Color(1, 1, 1, 0.55)
	_card(Rect2(20, 256, 680, 200), Color(LEAF, 0.5))
	_emboss("x_flower", Rect2(560, 262, 130, 130), "gold")
	_emboss("x_butterfly", Rect2(470, 268, 70, 70), "violet")
	_emboss("x_sprout", Rect2(40, 330, 90, 90), "emerald")
	_big(Rect2(150, 272, 400, 60), "بهار آمد!", 48, "#FFFFFF", "#FFE0F0", HORIZONTAL_ALIGNMENT_CENTER)
	_txt(Rect2(150, 334, 400, 28), "12 روز تا پایان جشن", 18, Color("#FFF0C0"), HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
	_inset(Rect2(190, 376, 340, 56), Color(GOLD, 0.6))
	_emboss("x_flower", Rect2(470, 378, 52, 52), "gold")
	_big(Rect2(200, 376, 260, 56), "340 سکه‌ی بهار", 26, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_RIGHT)
	# the reward track: free above, the pass below
	_sec(470, "مسیر جایزه  ·  مرحله 4")
	_btn(Rect2(40, 474, 200, 46), "پاس ویژه  ⭐ 150", "gold")
	var tiers := [["coins", "gold", "x_gem", "sapphire"], ["energy", "amber", "x_chest", "gold"], ["pill", "ruby", "x_crown", "gold"], ["coins", "gold", "x_car", "ruby"], ["x_chest", "gold", "x_flower", "gold"]]
	_rect(Rect2(40, 640, 640, 8), Color(0.2, 0.23, 0.4))
	_rect(Rect2(40 + 640 * 0.25, 640, 640 * 0.75, 8), LEAF)
	for i in tiers.size():
		var t: Array = tiers[i]
		var x := 568.0 - i * 132.0
		var done := i < 3
		var top := Rect2(x, 530, 112, 100)
		_card(top, Color(LEAF, 0.5) if i == 3 else Color(0, 0, 0, 0))
		_emboss(t[0], Rect2(x + 22, 538, 68, 68), t[1]).modulate = Color(1, 1, 1, 0.4 if done else 1.0)
		if done:
			_emboss("m_check", Rect2(x + 70, 530, 36, 36), "emerald")
		_circle(Vector2(x + 56, 644), 16, GOLD, 3.0, LEAF if i <= 3 else Color(0.12, 0.14, 0.28))
		_txt(Rect2(x + 36, 630, 40, 28), str(i + 1), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, display_font, 3)
		var bot := Rect2(x, 664, 112, 100)
		_card(bot, Color(GOLD, 0.35))
		_emboss(t[2], Rect2(x + 22, 672, 68, 68), t[3])
		_emboss("m_lock", Rect2(x + 74, 726, 34, 34), "steel")
	_txt(Rect2(40, 766, 640, 24), "بالا: رایگان برای همه  ·  پایین: با پاس ویژه", 14, Color("#AEB8D8"), HORIZONTAL_ALIGNMENT_CENTER)
	_sec(796, "کارهای جشن")
	var tasks := [["x_flower", "gold", "هفت‌سین را کامل کن", "5 از 7 سین در شهر پیدا شد", 5, 7, "+80"], ["x_flame", "amber", "چهارشنبه‌سوری", "سه‌شنبه شب در پارک", 0, 1, "+50"], ["x_present", "ruby", "به 3 دوست عیدی بده", "1 از 3", 1, 3, "+40"]]
	for i in tasks.size():
		var t: Array = tasks[i]
		var r := Rect2(20, 850 + i * 80, 680, 72)
		_inset(r, Color(LEAF, 0.4))
		_emboss(t[0], Rect2(634, r.position.y + 8, 56, 56), t[1])
		ui.add_child(_label(t[2], display_font, 20, Color.WHITE, Rect2(250, r.position.y + 2, 374, 36), HORIZONTAL_ALIGNMENT_RIGHT, 3))
		_txt(Rect2(250, r.position.y + 38, 374, 26), t[3], 14, Color("#AEB8D8"))
		_bar(Rect2(110, r.position.y + 30, 130, 14), float(t[4]) / t[5], LEAF, false)
		_big(Rect2(34, r.position.y, 70, 72), t[6], 22, "#FFF6C8", "#FFB21F", HORIZONTAL_ALIGNMENT_CENTER)
