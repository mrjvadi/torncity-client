extends SceneTree
## Print each model's AABB size (x, y, z) for the kits given:
##   godot --headless -s dev/model_sizes.gd -- city-kit-commercial car-kit


func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		_aabb(c, t, acc)


func _init() -> void:
	for kit in OS.get_cmdline_user_args():
		var dir := "res://assets/kenney/" + kit
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".glb"):
				continue
			var ps: PackedScene = load(dir + "/" + f)
			var n := ps.instantiate()
			var acc := [null]
			_aabb(n, Transform3D.IDENTITY, acc)
			var a: AABB = acc[0] if acc[0] != null else AABB()
			print("%s/%s  size=(%.2f, %.2f, %.2f)  pos=(%.2f, %.2f, %.2f)" % [kit, f.get_basename(), a.size.x, a.size.y, a.size.z, a.position.x, a.position.y, a.position.z])
			n.free()
	quit()
