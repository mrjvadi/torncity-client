extends Node
## Render every library model key (with CDN art) and every icon badge to PNG
## tiles for the contact sheet: dev/art_sheet.tscn -- <out dir>


func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	Config.headless_capture = true
	DirAccess.make_dir_recursive_absolute(out)
	# wait for the manifest, then fetch everything the library names
	var t := 0.0
	while AssetService.manifest.is_empty() and t < 15.0:
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	var keys: Array = AssetLib.models.keys()
	keys.sort()
	for k in keys:
		AssetLib.instantiate(k).free()
	for k in AssetLib.icons.keys():
		AssetLib.glyph(k)
	t = 0.0
	while not AssetService.idle() and t < 60.0:
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	var vp := SubViewport.new()
	vp.size = Vector2i(360, 360)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#A4B6DA")
	env.environment.ambient_light_energy = 0.45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment.tonemap_exposure = 0.92
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-30, 45, 0)
	vp.add_child(cam)
	for k in keys:
		if str(k) == "*":
			continue
		var base := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.0, 0.12, 2.0)
		base.mesh = bm
		base.position.y = -0.06
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#99A0AA") if not str(k).begins_with("home") else Color("#5B8B44")
		base.material_override = mat
		var n := AssetLib.instantiate(k)
		var holder := Node3D.new()
		holder.add_child(base)
		holder.add_child(n)
		vp.add_child(holder)
		var big := str(k).begins_with("vehicle") 
		cam.size = 2.2 if big else 3.4
		cam.position = Vector3(0, 0.55 if not big else 0.2, 0) + Basis.from_euler(cam.rotation).z * 50.0
		for _i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(out.path_join(str(k).replace(":", "_").replace("*", "any") + ".png"))
		holder.queue_free()
	# badges
	var badges := Control.new()
	var grid := GridContainer.new()
	grid.columns = 14
	grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var ik: Array = AssetLib.icons.keys()
	ik.sort()
	for k in ik:
		grid.add_child(IconBadge.make(AssetLib.glyph(k), 96))
	var bvp := SubViewport.new()
	bvp.size = Vector2i(14 * 110, int(ceil(ik.size() / 14.0)) * 110)
	bvp.transparent_bg = true
	bvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(bvp)
	bvp.add_child(grid)
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	bvp.get_texture().get_image().save_png(out.path_join("_badges.png"))
	print("art sheet tiles in ", out)
	get_tree().quit()
