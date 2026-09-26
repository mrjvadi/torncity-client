extends SceneTree
## Contact sheet of 3D models, each framed by an orthographic isometric camera
## under the city's light:
##   dev/xrun.sh -s dev/model_sheet.gd -- out.png <cell px> <cols> <res:// glb or dir>...


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
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var cell := int(args[1])
	var cols := int(args[2])
	var files: Array[String] = []
	for a in args.slice(3):
		if a.ends_with(".glb") or a.ends_with(".tscn"):
			files.append(a)
		else:
			for f in DirAccess.get_files_at(a):
				if f.ends_with(".glb"):
					files.append(a.path_join(f))
	await process_frame
	var rows := int(ceil(files.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * (cell + 18), false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#E9ECF1"))
	var vp := SubViewport.new()
	vp.size = Vector2i(cell, cell)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.8, 0.9)
	env.environment.ambient_light_energy = 0.45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(cam)
	for i in files.size():
		var ps: PackedScene = load(files[i])
		var n: Node3D = ps.instantiate()
		world.add_child(n)
		var acc := [null]
		_aabb(n, Transform3D.IDENTITY, acc)
		var a: AABB = acc[0] if acc[0] != null else AABB(Vector3.ZERO, Vector3.ONE)
		var c := a.get_center()
		var dir := Vector3(1, 0.82, 1).normalized()
		cam.size = maxf(a.size.length() * 0.95, 0.5)
		cam.look_at_from_position(c + dir * 50.0, c, Vector3.UP)
		cam.far = 200
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var x := (i % cols) * cell
		var y := (i / cols) * (cell + 18)
		sheet.blend_rect(img, Rect2i(0, 0, cell, cell), Vector2i(x, y))
		n.queue_free()
		print(i, " ", files[i].get_file())
	sheet.save_png(out)
	print("saved ", out)
	quit()
