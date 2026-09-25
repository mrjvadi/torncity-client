extends TestCase


func test_runs_and_strip() -> void:
	var r := TextIcons.runs("⚡ انرژی: ۷۲ از ۱۰۰")
	eq(r[0], {"t": "icon", "v": "energy"})
	eq(TextIcons.strip("❤️ سلامت"), "سلامت", "variation selector dropped")
	eq(TextIcons.lead_icon("🏦 بانک"), "bank")
	eq(TextIcons.lead_icon("بانک 🏦"), "")
	eq(TextIcons.strip("🦄 unknown emoji"), "unknown emoji")


func test_bbcode_escapes_brackets() -> void:
	var bb := TextIcons.to_bbcode("[x] 💵", 20, func(n): return "res://i/%s.svg" % n)
	check(bb.begins_with("[lb]x] "), bb)
	check(bb.contains("[img=20x20]res://i/cash.svg[/img]"), bb)


func test_every_mapped_icon_exists() -> void:
	for e in TextIcons.MAP:
		var name: String = TextIcons.MAP[e]
		check(AppTheme.art_path("icon/" + name).ends_with(name + ".svg") or AppTheme.art_path("icon/" + name).ends_with(name + ".png"), "icon " + name)
