class_name WorldModel
extends RefCounted
## The city as the server describes it (GET /api/v1/world/city?code=), plus
## live {type:"world.plot"} updates. Pure data and geometry, no nodes; unit-
## tested in tests/test_world_model.gd. World units: 1 = one road tile (~10 m);
## a point (x, y) of the layout is (x, 0, y) in 3D.
##
## Schema v2:
##   {city, version, bounds: [x0, y0, x1, y1],
##    districts: [{id, kind, name: {fa, en}, rect: [x0, y0, x1, y1]}],
##    roads: [{id, class: street|avenue|boulevard|highway, pts: [[x, y], ...]}],
##    rails: [{id, pts}], water: [{id, rect: [x, y, w, h]}],
##    features: [{type: runway|apron|plane|pier|ship|field, ...}],
##    plots: [{id, x, y, w, h, kind: place|company|home|decor|green, model, rot?, district?, ref?, name?}]}

const WIDTH := {"street": 1.3, "avenue": 1.9, "boulevard": 3.6, "highway": 2.6}
const SIDEWALK := {"street": 0.4, "avenue": 0.45, "boulevard": 0.5, "highway": 0.0}

var city := ""
var version := 0
var bounds := Rect2(-10, -10, 20, 20)
var districts: Array = []
var roads: Array = []          # [{id, class, pts: PackedVector2Array}]
var rails: Array = []
var water: Array = []
var features: Array = []
var plots := {}                # id -> plot

# road graph: nodes are segment ends and crossings; edges run along roads
var nodes: Array = []          # Vector2
var edges := {}                # node index -> [[other index, length]]
var node_class := {}           # node index -> widest road class through it
var _edge_list: Array = []     # [a, b, class]


func load_world(d: Dictionary) -> void:
	city = str(d.get("city", ""))
	version = int(d.get("version", 0))
	var b: Array = d.get("bounds", [-10, -10, 10, 10])
	bounds = Rect2(Vector2(b[0], b[1]), Vector2(b[2] - b[0], b[3] - b[1]))
	districts = d.get("districts", [])
	water = d.get("water", [])
	features = d.get("features", [])
	roads.clear()
	for r in d.get("roads", []):
		roads.append({"id": str(r.get("id", "")), "class": str(r.get("class", "street")), "pts": _pts(r.get("pts", []))})
	rails.clear()
	for r in d.get("rails", []):
		rails.append({"id": str(r.get("id", "")), "pts": _pts(r.get("pts", []))})
	plots.clear()
	for p in d.get("plots", []):
		if p is Dictionary and p.has("id"):
			plots[str(p["id"])] = p
	_build_graph()


static func _pts(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


## Apply a realtime update: {op: "upsert"|"remove", plot?, id?}. Returns the
## id that changed ("" if nothing did). A plot replaces any plot it overlaps.
func apply(update: Dictionary) -> String:
	if str(update.get("op", "upsert")) == "remove":
		var id := str(update.get("id", ""))
		return id if plots.erase(id) else ""
	var p = update.get("plot")
	if not (p is Dictionary) or not p.has("id"):
		return ""
	var r := plot_rect(p)
	for oid in plots.keys():
		if oid != str(p["id"]) and plot_rect(plots[oid]).grow(-0.05).intersects(r.grow(-0.05)):
			plots.erase(oid)
	plots[str(p["id"])] = p
	return str(p["id"])


static func plot_rect(p: Dictionary) -> Rect2:
	return Rect2(float(p.get("x", 0)), float(p.get("y", 0)), float(p.get("w", 1)), float(p.get("h", 1)))


func plot_center(p: Dictionary) -> Vector3:
	var c := plot_rect(p).get_center()
	return Vector3(c.x, 0, c.y)


func plot_at(pt: Vector2) -> Dictionary:
	var best := {}
	var area := INF
	for p in plots.values():
		var r := plot_rect(p)
		if r.has_point(pt) and r.get_area() < area:
			area = r.get_area()
			best = p
	return best


func plot_for_place(code: String) -> Dictionary:
	for p in plots.values():
		var ref = p.get("ref", {})
		if ref is Dictionary and str(ref.get("table", "")) == "place" and str(ref.get("code", "")) == code:
			return p
	return {}


func district_at(pt: Vector2) -> Dictionary:
	var best := {}
	var area := INF
	for d in districts:
		var r := district_rect(d)
		if r.has_point(pt) and r.get_area() < area:
			area = r.get_area()
			best = d
	return best


static func district_rect(d: Dictionary) -> Rect2:
	var r: Array = d.get("rect", [0, 0, 0, 0])
	return Rect2(Vector2(r[0], r[1]), Vector2(r[2] - r[0], r[3] - r[1]))


# -- the road graph -------------------------------------------------------------------------------
func _build_graph() -> void:
	nodes.clear()
	edges.clear()
	node_class.clear()
	_edge_list.clear()
	# every straight piece, then split pieces where they cross
	var segs: Array = []
	for r in roads:
		var pts: PackedVector2Array = r.pts
		for i in pts.size() - 1:
			segs.append([pts[i], pts[i + 1], r["class"]])
	var cuts: Array = []
	for s in segs:
		cuts.append([0.0, 1.0])
	for i in segs.size():
		for j in range(i + 1, segs.size()):
			var hit = Geometry2D.segment_intersects_segment(segs[i][0], segs[i][1], segs[j][0], segs[j][1])
			if hit != null:
				cuts[i].append(_t_on(segs[i], hit))
				cuts[j].append(_t_on(segs[j], hit))
	for i in segs.size():
		var ts: Array = cuts[i]
		ts.sort()
		var prev := -1
		for t in ts:
			var p: Vector2 = (segs[i][0] as Vector2).lerp(segs[i][1], t)
			var n := _node(p, segs[i][2])
			if prev >= 0 and prev != n:
				var L: float = (nodes[prev] as Vector2).distance_to(nodes[n])
				edges.get_or_add(prev, []).append([n, L])
				edges.get_or_add(n, []).append([prev, L])
				_edge_list.append([prev, n, segs[i][2]])
			prev = n


static func _t_on(s: Array, p: Vector2) -> float:
	var d: Vector2 = s[1] - s[0]
	return clampf((p - s[0]).dot(d) / maxf(d.length_squared(), 1e-6), 0.0, 1.0)


func _node(p: Vector2, cls: String) -> int:
	for i in nodes.size():
		if (nodes[i] as Vector2).distance_to(p) < 0.05:
			if WIDTH.get(cls, 1.0) > WIDTH.get(node_class.get(i, "street"), 1.0):
				node_class[i] = cls
			return i
	nodes.append(p)
	node_class[nodes.size() - 1] = cls
	return nodes.size() - 1


## Crossings: nodes where three or more edge ends meet, with their widest class.
func crossings() -> Array:
	var out: Array = []
	for i in nodes.size():
		if edges.get(i, []).size() >= 3:
			out.append([nodes[i], node_class.get(i, "street"), edges[i].size()])
	return out


func edge_list() -> Array:
	return _edge_list


## The nearest point on the road network: [point, edge index].
func snap(pt: Vector2) -> Array:
	var best := [pt, -1]
	var bd := INF
	for i in _edge_list.size():
		var e: Array = _edge_list[i]
		if str(e[2]) == "highway":
			continue   # nobody walks on the highway
		var q := Geometry2D.get_closest_point_to_segment(pt, nodes[e[0]], nodes[e[1]])
		var d := q.distance_to(pt)
		if d < bd:
			bd = d
			best = [q, i]
	return best


## Where a plot's door meets the street.
func entrance(p: Dictionary) -> Vector2:
	return snap(plot_rect(p).get_center())[0]


## A path along the roads from one point to another (both snapped), as points.
func route(a: Vector2, b: Vector2) -> PackedVector2Array:
	var sa := snap(a)
	var sb := snap(b)
	var out := PackedVector2Array([sa[0]])
	if sa[1] < 0 or sb[1] < 0 or sa[1] == sb[1]:
		out.append(sb[0])
		return out
	var ea: Array = _edge_list[sa[1]]
	var eb: Array = _edge_list[sb[1]]
	var best: Array = []
	var best_len := INF
	for s in [ea[0], ea[1]]:
		for t in [eb[0], eb[1]]:
			var path := _dijkstra(s, t)
			if path.is_empty():
				continue
			var L: float = (sa[0] as Vector2).distance_to(nodes[s]) + _len(path) + (nodes[t] as Vector2).distance_to(sb[0])
			if L < best_len:
				best_len = L
				best = path
	for n in best:
		out.append(nodes[n])
	out.append(sb[0])
	return out


func _len(path: Array) -> float:
	var L := 0.0
	for i in path.size() - 1:
		L += (nodes[path[i]] as Vector2).distance_to(nodes[path[i + 1]])
	return L


func _dijkstra(s: int, t: int) -> Array:
	var dist := {s: 0.0}
	var prev := {}
	var open := [s]
	var closed := {}
	while not open.is_empty():
		var bi := 0
		for i in open.size():
			if dist[open[i]] < dist[open[bi]]:
				bi = i
		var u: int = open.pop_at(bi)
		if closed.has(u):
			continue
		closed[u] = true
		if u == t:
			var path := [t]
			while path[0] != s:
				path.push_front(prev[path[0]])
			return path
		for e in edges.get(u, []):
			var nd: float = dist[u] + float(e[1])
			if nd < dist.get(e[0], INF):
				dist[e[0]] = nd
				prev[e[0]] = u
				open.append(e[0])
	return []
