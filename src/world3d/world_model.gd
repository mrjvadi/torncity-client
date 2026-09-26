class_name WorldModel
extends RefCounted
## The city as the server describes it (GET /api/v1/world/city?code=), plus
## live {type:"world.plot"} updates. Pure data and geometry, no nodes, so it is
## unit-tested.
##
##   {city, version, grid: {w, h}, ground?, water?: {side, width},
##    roads: [[x, y], ...],
##    plots: [{id, x, y, w, h, kind, model, rot?, ref?: {table, code, company_id?...}, name?: {fa, en}}]}
##
## Tiles are 1 x 1 world units; tile (x, y) spans x..x+1 and z = y..y+1,
## shifted so the grid is centred on the origin. North is -z.

const N := 1
const E := 2
const S := 4
const W := 8

var city := ""
var version := 0
var w := 0
var h := 0
var ground := "grass"
var water := {}
var roads := {}      # Vector2i -> true
var plots := {}      # id -> plot
var _tile_plot := {} # Vector2i -> plot id


func load_world(d: Dictionary) -> void:
	city = str(d.get("city", ""))
	version = int(d.get("version", 0))
	var g = d.get("grid", {})
	w = int(g.get("w", 0))
	h = int(g.get("h", 0))
	ground = str(d.get("ground", "grass"))
	water = d.get("water", {}) if d.get("water") is Dictionary else {}
	roads.clear()
	for r in d.get("roads", []):
		if r is Array and r.size() >= 2:
			roads[Vector2i(int(r[0]), int(r[1]))] = true
	plots.clear()
	_tile_plot.clear()
	for p in d.get("plots", []):
		if p is Dictionary and p.has("id"):
			_put(p)


## Apply a realtime update: {op: "upsert"|"remove", plot?, id?}. Returns the
## id that changed ("" if nothing did).
func apply(update: Dictionary) -> String:
	var op := str(update.get("op", "upsert"))
	if op == "remove":
		var id := str(update.get("id", ""))
		if plots.has(id):
			_drop(id)
			return id
		return ""
	var p = update.get("plot")
	if not (p is Dictionary) or not p.has("id"):
		return ""
	if plots.has(str(p["id"])):
		_drop(str(p["id"]))
	_put(p)
	return str(p["id"])


func _put(p: Dictionary) -> void:
	var id := str(p["id"])
	# a new plot replaces whatever stood on its tiles (a home becomes a company)
	for t in tiles_of(p):
		if _tile_plot.has(t) and _tile_plot[t] != id:
			_drop(_tile_plot[t])
	plots[id] = p
	for t in tiles_of(p):
		_tile_plot[t] = id


func _drop(id: String) -> void:
	var p: Dictionary = plots.get(id, {})
	for t in tiles_of(p):
		if _tile_plot.get(t) == id:
			_tile_plot.erase(t)
	plots.erase(id)


static func tiles_of(p: Dictionary) -> Array:
	var out := []
	for dy in int(p.get("h", 1)):
		for dx in int(p.get("w", 1)):
			out.append(Vector2i(int(p.get("x", 0)) + dx, int(p.get("y", 0)) + dy))
	return out


func plot_at(t: Vector2i) -> Dictionary:
	return plots.get(_tile_plot.get(t, ""), {})


## The plot that shows a game place (by place code).
func plot_for_place(code: String) -> Dictionary:
	for p in plots.values():
		var ref = p.get("ref", {})
		if ref is Dictionary and str(ref.get("table", "")) == "place" and str(ref.get("code", "")) == code:
			return p
	return {}


## World position of a tile's centre (y = 0).
func tile_pos(t: Vector2i) -> Vector3:
	return Vector3(t.x - w / 2.0 + 0.5, 0.0, t.y - h / 2.0 + 0.5)


func world_to_tile(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x + w / 2.0), floori(p.z + h / 2.0))


func plot_center(p: Dictionary) -> Vector3:
	return Vector3(float(p.get("x", 0)) + float(p.get("w", 1)) / 2.0 - w / 2.0, 0.0,
		float(p.get("y", 0)) + float(p.get("h", 1)) / 2.0 - h / 2.0)


## Road neighbours of a road tile as a bit set (N, E, S, W).
func road_mask(t: Vector2i) -> int:
	var m := 0
	if roads.has(t + Vector2i(0, -1)): m |= N
	if roads.has(t + Vector2i(1, 0)): m |= E
	if roads.has(t + Vector2i(0, 1)): m |= S
	if roads.has(t + Vector2i(-1, 0)): m |= W
	return m


## Rotate a side mask by quarter turns counter-clockwise seen from above
## (Godot's +Y rotation): E -> N -> W -> S -> E.
static func rotate_mask(m: int, quarters: int) -> int:
	var out := m
	for _i in posmod(quarters, 4):
		var r := 0
		if out & E: r |= N
		if out & N: r |= W
		if out & W: r |= S
		if out & S: r |= E
		out = r
	return out


## Which road piece a tile needs, and its rotation in degrees. `open` gives
## each piece's open sides at rotation 0 (from the asset library, so the
## model kit can change without code changes).
static func road_piece(mask: int, open: Dictionary) -> Dictionary:
	var n := 0
	for b in [N, E, S, W]:
		if mask & b:
			n += 1
	var kind := "single"
	match n:
		4: kind = "cross"
		3: kind = "t"
		2: kind = "straight" if mask == (N | S) or mask == (E | W) else "corner"
		1: kind = "end"
	var base := int(open.get(kind, 0))
	for q in 4:
		if rotate_mask(base, q) == mask:
			return {"kind": kind, "rot": q * 90}
	return {"kind": kind, "rot": 0}


## The road tile a plot's door opens onto: the nearest road next to it.
func entrance(p: Dictionary) -> Vector2i:
	var best := Vector2i(int(p.get("x", 0)), int(p.get("y", 0)))
	var best_d := INF
	var c := Vector2(float(p.get("x", 0)) + float(p.get("w", 1)) / 2.0, float(p.get("y", 0)) + float(p.get("h", 1)) / 2.0)
	for t in tiles_of(p):
		for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
			var n: Vector2i = t + d
			if roads.has(n):
				var dist := (Vector2(n) + Vector2(0.5, 0.5)).distance_to(c) + (0.0 if d == Vector2i(0, 1) else 0.01)
				if dist < best_d:
					best_d = dist
					best = n
	return best


## Shortest road path between two road tiles (breadth-first).
func route(from: Vector2i, to: Vector2i) -> Array:
	if from == to:
		return [from]
	var prev := {from: from}
	var q := [from]
	while not q.is_empty():
		var t: Vector2i = q.pop_front()
		for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
			var n: Vector2i = t + d
			if roads.has(n) and not prev.has(n):
				prev[n] = t
				if n == to:
					var path := [n]
					while path[0] != from:
						path.push_front(prev[path[0]])
					return path
				q.append(n)
	return [from, to]
