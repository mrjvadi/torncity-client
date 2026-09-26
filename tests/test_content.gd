extends "res://tests/test_case.gd"
## The content catalogue and the asset library: unknown content still renders.


func test_catalogue_lookup_and_fallbacks() -> void:
	var cat = JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/content.json"))
	Content._apply(cat, false)
	eq(Content.version, str(cat["version"]))
	I18n.set_lang("en")
	eq(Content.name_of("item", "quantum_toaster"), "Quantum toaster")
	eq(Content.name_of("item", "never_heard_of"), "never heard of")
	eq(Content.asset("place", "sky_garden", "model"), "place:sky_garden")
	eq(Content.asset("vehicle", "hovercraft", "model"), "vehicle:hovercraft")
	I18n.set_lang("fa")


func test_library_resolution() -> void:
	var lib := {"company:factory": "a", "company:*": "b", "*": "c"}
	eq(AssetLib.resolve(lib, "company:factory"), "a")
	eq(AssetLib.resolve(lib, "company:drone_foundry"), "b")
	eq(AssetLib.resolve(lib, "spaceship:x"), "c")
	eq(AssetLib.action_icon("bank.show"), "ln_bank")
	eq(AssetLib.action_icon("teleport.now"), "ln_menu")


func test_unknown_content_gets_a_model() -> void:
	for key in ["place:sky_garden", "company:drone_foundry", "totally:new"]:
		check(not AssetLib.model(key).is_empty(), "model for " + key)
	check(AssetLib.icon("item:quantum_toaster") != null, "icon for an unknown item")
