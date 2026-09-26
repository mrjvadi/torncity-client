extends "res://tests/test_case.gd"
## The server-driven city layout.

const OPEN := {"straight": 5, "end": 4, "corner": 6, "t": 14, "cross": 15, "single": 0}


func _world() -> WorldModel:
	var m := WorldModel.new()
	m.load_world(JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/world.json")))
	return m


func test_load() -> void:
	var m := _world()
	eq(m.w, 16)
	check(m.roads.size() > 100, "roads")
	check(not m.plot_for_place("bazaar").is_empty(), "bazaar plot")
	check(not m.plot_for_place("sky_garden").is_empty(), "made-up place has a plot")
	var p := m.plot_for_place("bazaar")
	eq(m.plot_at(Vector2i(int(p["x"]) + 1, int(p["y"]) + 1)).get("id"), p["id"])


func test_road_pieces() -> void:
	eq(WorldModel.road_piece(WorldModel.N | WorldModel.S, OPEN), {"kind": "straight", "rot": 0})
	eq(WorldModel.road_piece(WorldModel.E | WorldModel.W, OPEN).kind, "straight")
	eq(WorldModel.road_piece(15, OPEN), {"kind": "cross", "rot": 0})
	for m in range(1, 16):
		var r := WorldModel.road_piece(m, OPEN)
		eq(WorldModel.rotate_mask(int(OPEN[r.kind]), r.rot / 90), m, "mask %d" % m)


func test_updates() -> void:
	var m := _world()
	var home: Dictionary = {}
	for p in m.plots.values():
		if p.get("kind") == "home":
			home = p
			break
	var id := m.apply({"op": "upsert", "plot": {"id": "company:9", "x": home["x"], "y": home["y"], "w": 1, "h": 1,
		"kind": "company", "model": "company:hovercraft_yard", "ref": {"table": "company_type", "code": "hovercraft_yard", "company_id": 9}}})
	eq(id, "company:9")
	check(not m.plots.has(home["id"]), "the home it replaced is gone")
	eq(m.plot_at(Vector2i(int(home["x"]), int(home["y"]))).get("id"), "company:9")
	eq(m.apply({"op": "remove", "id": "company:9"}), "company:9")
	check(m.plot_at(Vector2i(int(home["x"]), int(home["y"]))).is_empty(), "removed")


func test_route() -> void:
	var m := _world()
	var a := m.entrance(m.plot_for_place("bazaar"))
	var b := m.entrance(m.plot_for_place("hospital"))
	var path := m.route(a, b)
	eq(path[0], a)
	eq(path[-1], b)
	for t in path:
		check(m.roads.has(t), "on the road")
