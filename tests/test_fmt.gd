extends TestCase


func test_digits() -> void:
	# Digits are always Western, even in Persian: the owner's rule.
	eq(Fmt.digits("2025 - 07:30", "fa"), "2025 - 07:30")
	eq(Fmt.digits("2025", "en"), "2025")


func test_number_grouping() -> void:
	eq(Fmt.number(0, "en"), "0")
	eq(Fmt.number(999, "en"), "999")
	eq(Fmt.number(1000, "en"), "1,000")
	eq(Fmt.number(1234567, "en"), "1,234,567")
	eq(Fmt.number(1234567, "fa"), "1٬234٬567")
	eq(Fmt.number(-5000, "en"), "−5,000")


func test_money() -> void:
	eq(Fmt.money(5000, "fa"), "5٬000 نیل")
	eq(Fmt.money(12450, "en"), "12,450 Nil")


func test_money_short() -> void:
	eq(Fmt.money_short(9999, "en"), "9,999")
	eq(Fmt.money_short(12450, "en"), "12.5K")
	eq(Fmt.money_short(86300, "fa"), "86٫3 هزار")
	eq(Fmt.money_short(2000000, "en"), "2M")


func test_duration() -> void:
	eq(Fmt.duration(8100, "fa"), "2 ساعت و 15 دقیقه")
	eq(Fmt.duration(7200, "en"), "2h")
	eq(Fmt.duration(900, "en"), "15m")
	eq(Fmt.duration(45, "fa"), "45 ثانیه")
	eq(Fmt.duration(-3, "en"), "0s")


func test_of_and_fill() -> void:
	eq(Fmt.of(72, 100, "fa"), "72 از 100")
	eq(Fmt.fill("Level {level} - {name}", {"level": 12, "name": "Sara"}, "fa"), "Level 12 - Sara")


func test_to_latin() -> void:
	eq(Fmt.to_latin("۱۲٣4"), "1234")


func test_rtl() -> void:
	check(Fmt.is_rtl("fa"))
	check(not Fmt.is_rtl("en"))
	eq(Fmt.isolate("K7Q2M9A"), "\u2068K7Q2M9A\u2069")
	I18n.set_lang("fa", false)
	eq(I18n.direction(), Control.LAYOUT_DIRECTION_RTL)
	eq(I18n.t("nav.city"), "شهر")
	I18n.set_lang("en", false)
	eq(I18n.direction(), Control.LAYOUT_DIRECTION_LTR)
	eq(I18n.t("nav.city"), "City")
	eq(I18n.t("profile.level", {"level": 3}), "Level 3")
	I18n.set_lang("fa", false)
	eq(I18n.t("profile.level", {"level": 3}), "سطح 3")
