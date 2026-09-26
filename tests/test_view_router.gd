extends TestCase


func test_native_screens() -> void:
	var v := {"x": 1}
	eq(ViewRouter.scene_for("profile", v), "profile")
	eq(ViewRouter.scene_for("dashboard", v), "profile")
	eq(ViewRouter.scene_for("city_map", v), "city")
	eq(ViewRouter.scene_for("cities", v), "cities")
	eq(ViewRouter.scene_for("travel_options", v), "travel_options")
	eq(ViewRouter.scene_for("travel_status", v), "travel_status")
	eq(ViewRouter.scene_for("bank", v), "bank")
	eq(ViewRouter.scene_for("inventory", v), "inventory")
	eq(ViewRouter.scene_for("job_status", v), "job")
	eq(ViewRouter.scene_for("life", v), "life")


func test_fallback_to_card() -> void:
	eq(ViewRouter.scene_for("skills.list", null), "card")
	eq(ViewRouter.scene_for("bank", null), "card", "no view: card")
	eq(ViewRouter.scene_for("bank", {}), "card", "empty view: card")
	eq(ViewRouter.scene_for("company.lab", {"a": 1}), "card", "unknown screen: card")


func test_every_native_scene_exists() -> void:
	for s in ViewRouter.NATIVE.values():
		check(ResourceLoader.exists("res://src/screens/%s.tscn" % s), "scene for " + s)
	check(ResourceLoader.exists("res://src/screens/card.tscn"))


func test_tabs() -> void:
	eq(ViewRouter.tab_for("city"), "map")
	eq(ViewRouter.tab_for("travel_options"), "world")
	eq(ViewRouter.tab_for("bank"), "profile")
	eq(ViewRouter.tab_for("card", "company.lab"), "companies")
	eq(ViewRouter.tab_for("card", "market.list"), "market")
	eq(ViewRouter.tab_for("card", "crime.hub"), "")


func test_mock_answers_match_router() -> void:
	Mock.reset()
	for pair in [["player.profile.get", "profile"], ["map.list", "city"], ["map.cities", "cities"], ["bank.show", "bank"],
			["inventory.show", "inventory"], ["job.status", "job"], ["life.me", "life"], ["skills.list", "card"]]:
		var r := Mock.command(pair[0], {})
		eq(ViewRouter.scene_for(r["screen"], r.get("view")), pair[1], pair[0])
