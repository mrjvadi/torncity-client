extends TestCase


func test_assign_known_and_unknown() -> void:
	var a := CityLayout.assign(["bazaar", "airport", "space_port"])
	eq(a["bazaar"], CityLayout.SLOTS["bazaar"])
	check(a.has("space_port"), "unknown place gets a lot")
	check(a["space_port"] != a["bazaar"] and a["space_port"] != a["airport"], "no shared lot")


func test_projection_roundtrip() -> void:
	var w := Vector2(123, 45)
	var back := CityLayout.unproject(CityLayout.project(w))
	near(back.x, w.x)
	near(back.y, w.y)


func test_route_is_on_roads() -> void:
	var r := CityLayout.route(Vector2i(0, 0), Vector2i(3, 2))
	eq(r[0], CityLayout.door(Vector2i(0, 0)))
	eq(r[r.size() - 1], CityLayout.door(Vector2i(3, 2)))
	for i in range(1, r.size()):
		var d := r[i] - r[i - 1]
		check(is_zero_approx(d.x) or is_zero_approx(d.y), "segments follow the grid")
	eq(CityLayout.route(Vector2i(1, 1), Vector2i(1, 1)).size(), 1)


func test_along_and_facing() -> void:
	var r := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	eq(CityLayout.along(r, 0.0), Vector2(0, 0))
	eq(CityLayout.along(r, 0.5), Vector2(10, 0))
	eq(CityLayout.along(r, 1.0), Vector2(10, 10))
	eq(CityLayout.facing(Vector2(1, 0)), "se")
	eq(CityLayout.facing(Vector2(0, -1)), "ne")


func test_night_and_day() -> void:
	near(CityMapView.night_amount(12.0), 0.0)
	near(CityMapView.night_amount(23.0), 1.0)
	check(CityMapView.night_amount(18.5) > 0.0 and CityMapView.night_amount(18.5) < 1.0, "dusk ramps")
