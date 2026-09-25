class_name CityLayout
extends RefCounted
## Where each place stands on the city map, and the roads between them.
##
## The server has no coordinates for places (a place is a walk time away, not
## a point), so the client lays the city out on a 4 x 4 grid of lots in world
## units (the same isometric projection the place art is drawn in). Lots are
## joined by a road grid; the walker follows the roads. Unknown place codes
## take the free lots in order. Unit-tested in tests/test_city_layout.gd.

const LOT := 100.0     # a lot's side, world units (= the art's plot)
const ROAD := 30.0     # road width between lots
const N := 4

## Place code -> lot (i along world x, j along world y). The far corner (0,0)
## is the top of the screen; (3,3) the bottom.
const SLOTS := {
	"airport": Vector2i(0, 0),
	"industrial_zone": Vector2i(1, 0),
	"farmland": Vector2i(0, 1),
	"train_station": Vector2i(2, 0),
	"business_district": Vector2i(1, 1),
	"barracks": Vector2i(0, 2),
	"bus_terminal": Vector2i(3, 0),
	"bazaar": Vector2i(2, 1),
	"city_hall": Vector2i(1, 2),
	"police_station": Vector2i(0, 3),
	"hospital": Vector2i(3, 1),
	"city_centre": Vector2i(2, 2),
	"university": Vector2i(1, 3),
	"residential_area": Vector2i(3, 2),
	"park": Vector2i(2, 3),
}


static func step() -> float:
	return LOT + ROAD


static func size() -> float:
	return N * LOT + (N - 1) * ROAD


## Isometric projection (2:1), world -> map pixels at zoom 1.
static func project(w: Vector2, z := 0.0) -> Vector2:
	return Vector2(w.x - w.y, (w.x + w.y) * 0.5 - z)


## Map pixels -> world (on the ground plane).
static func unproject(p: Vector2) -> Vector2:
	return Vector2(p.y + p.x * 0.5, p.y - p.x * 0.5)


## Assign lots: known codes to their slot, the rest to free lots in order.
static func assign(codes: Array) -> Dictionary:
	var out := {}
	var used := {}
	for c in codes:
		if SLOTS.has(c):
			out[c] = SLOTS[c]
			used[SLOTS[c]] = true
	var free := []
	for j in N:
		for i in N:
			var v := Vector2i(i, j)
			if not used.has(v):
				free.append(v)
	# fill from the front (closest to the viewer) so extra places are visible
	free.sort_custom(func(a, b): return (a.x + a.y) > (b.x + b.y))
	for c in codes:
		if not out.has(c) and not free.is_empty():
			out[c] = free.pop_front()
	return out


## The world position of a lot's near corner (x,y max).
static func lot_origin(slot: Vector2i) -> Vector2:
	return Vector2(slot.x * step(), slot.y * step())


static func lot_center(slot: Vector2i) -> Vector2:
	return lot_origin(slot) + Vector2(LOT, LOT) * 0.5


## The road point in front of a lot: the middle of its front-left edge's road.
static func door(slot: Vector2i) -> Vector2:
	return lot_origin(slot) + Vector2(LOT * 0.5, LOT + ROAD * 0.5)


## The road route between two lots: out of the door, along the roads, in.
## Roads run along x in the gaps below each row (y = j*step + LOT + ROAD/2) and
## along y in the gaps right of each column (x = i*step + LOT + ROAD/2).
static func route(a: Vector2i, b: Vector2i) -> PackedVector2Array:
	var da := door(a)
	var db := door(b)
	var pts := PackedVector2Array([da])
	if a == b:
		return pts
	if a.y == b.y:
		pts.append(db)
		return pts
	# the column road between them: right of a's column, or of b's when b lies left
	var col_x := float(a.x if b.x >= a.x else b.x) * step() + LOT + ROAD * 0.5
	for p in [Vector2(col_x, da.y), Vector2(col_x, db.y), db]:
		if pts[pts.size() - 1].distance_to(p) > 0.5:
			pts.append(p)
	return pts


static func route_length(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in range(1, pts.size()):
		l += pts[i - 1].distance_to(pts[i])
	return l


## The point at fraction t (0..1) of the way along a route.
static func along(pts: PackedVector2Array, t: float) -> Vector2:
	if pts.size() == 1:
		return pts[0]
	var total := route_length(pts)
	var want := clampf(t, 0, 1) * total
	for i in range(1, pts.size()):
		var seg := pts[i - 1].distance_to(pts[i])
		if want <= seg or i == pts.size() - 1:
			return pts[i - 1].lerp(pts[i], clampf(want / maxf(seg, 0.001), 0, 1))
		want -= seg
	return pts[pts.size() - 1]


## The walker's facing on the iso grid for a world-space step.
## Returns "se" (+x), "nw" (-x), "sw" (+y) or "ne" (-y).
static func facing(delta: Vector2) -> String:
	if absf(delta.x) >= absf(delta.y):
		return "se" if delta.x >= 0 else "nw"
	return "sw" if delta.y >= 0 else "ne"
