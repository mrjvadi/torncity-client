extends "res://tests/test_case.gd"
## The server-driven city layout (schema v2).


func _world() -> WorldModel:
	var m := WorldModel.new()
	m.load_world(JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/world.json")))
	return m


func test_load() -> void:
	var m := _world()
	check(m.bounds.size.x > 100, "a city with outskirts")
	check(m.districts.size() >= 8, "districts")
	check(not m.plot_for_place("bazaar").is_empty(), "bazaar plot")
	check(not m.plot_for_place("sky_garden").is_empty(), "made-up place has a plot")
	var ap := m.plot_for_place("airport")
	var ring := Rect2(-4, -4, 72, 54)
	check(not ring.intersects(WorldModel.plot_rect(ap)), "the airport is outside the ring road")
	eq(str(m.district_at(WorldModel.plot_rect(m.plot_for_place("business_district")).get_center()).get("kind")), "cbd")


func test_graph_and_route() -> void:
	var m := _world()
	check(m.crossings().size() > 20, "street crossings")
	var a := m.entrance(m.plot_for_place("bazaar"))
	var b := m.entrance(m.plot_for_place("hospital"))
	var path := m.route(a, b)
	check(path.size() >= 2, "a route")
	eq(path[0], a)
	eq(path[path.size() - 1], b)
	# every step runs along a road: consecutive points share an x or a y
	for i in path.size() - 1:
		var d: Vector2 = path[i + 1] - path[i]
		check(absf(d.x) < 0.01 or absf(d.y) < 0.01, "axis-aligned step %d" % i)


func test_updates() -> void:
	var m := _world()
	var home: Dictionary = {}
	for p in m.plots.values():
		if p.get("kind") == "home":
			home = p
			break
	var id := m.apply({"op": "upsert", "plot": {"id": "company:9", "x": home["x"], "y": home["y"], "w": 2, "h": 2,
		"kind": "company", "model": "company:hovercraft_yard", "ref": {"table": "company_type", "code": "hovercraft_yard", "company_id": 9}}})
	eq(id, "company:9")
	check(not m.plots.has(home["id"]), "the home it replaced is gone")
	eq(m.plot_at(WorldModel.plot_rect(home).get_center()).get("id"), "company:9")
	eq(m.apply({"op": "remove", "id": "company:9"}), "company:9")
