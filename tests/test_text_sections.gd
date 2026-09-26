extends "res://tests/test_case.gd"
## The generic screen's text parser.


func test_sections() -> void:
	var p := TextSections.parse("🏢 New Flight Drones\nDrone foundry · Owner: Sara\n\n📊 Today\nOutput: 120 units\nStaff: 8\n\n• Chips - 40\n• Frames - 12\n\nA quiet day at the foundry.")
	eq(p.title, "🏢 New Flight Drones")
	eq(p.blocks[0].heading, "📊 Today")
	eq(p.blocks[0].stats, [["Output", "120 units"], ["Staff", "8"]])
	eq(p.blocks[1].list, ["Chips - 40", "Frames - 12"])
	eq(p.blocks[2].para, ["A quiet day at the foundry."])


func test_persian_colon_and_single_line() -> void:
	var p := TextSections.parse("🏦 بانک\n\nموجودی: ۸۶٬۳۰۰ نیل")
	eq(p.title, "🏦 بانک")
	eq(p.blocks[0].stats, [["موجودی", "۸۶٬۳۰۰ نیل"]])
