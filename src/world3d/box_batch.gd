class_name BoxBatch
extends RefCounted
## Many boxes of one material merged into one mesh (one draw call): roads,
## sidewalks, markings, districts. add() takes a centre, a size and a yaw.

var _st := SurfaceTool.new()
var _n := 0

const _FACES := [
	[Vector3(1, 0, 0), [Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(1, -1, 1)]],
	[Vector3(-1, 0, 0), [Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, -1)]],
	[Vector3(0, 1, 0), [Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1)]],
	[Vector3(0, -1, 0), [Vector3(-1, -1, 1), Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1)]],
	[Vector3(0, 0, 1), [Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1), Vector3(-1, -1, 1)]],
	[Vector3(0, 0, -1), [Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, -1, -1)]],
]


func _init() -> void:
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)


## A box centred at `c`, `size` along its own axes, turned `yaw` radians about Y.
## top_only: just the top face (flat markings and ground patches).
func add(c: Vector3, size: Vector3, yaw := 0.0, top_only := false) -> void:
	var b := Basis(Vector3.UP, yaw)
	var h := size / 2.0
	for f in _FACES:
		if top_only and f[0] != Vector3(0, 1, 0):
			continue
		var n: Vector3 = b * f[0]
		var q: Array = f[1]
		var v: Array = []
		for p in q:
			v.append(c + b * (Vector3(p.x * h.x, p.y * h.y, p.z * h.z)))
		for i in [0, 2, 1, 0, 3, 2]:   # Godot: clockwise front faces
			_st.set_normal(n)
			_st.add_vertex(v[i])
	_n += 1


## A flat strip from a to b (on the ground plane), `width` wide, at height y.
func strip(a: Vector2, b: Vector2, width: float, y: float, thick := 0.02, top_only := false) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.001:
		return
	var mid := (a + b) / 2.0
	add(Vector3(mid.x, y, mid.y), Vector3(width, thick, L), atan2(d.x, d.y), top_only)


func count() -> int:
	return _n


func build(mat: Material, parent: Node3D, shadows := false) -> MeshInstance3D:
	if _n == 0:
		return null
	var mi := MeshInstance3D.new()
	mi.mesh = _st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
