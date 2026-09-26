extends Node
## Render the 3D city alone (autoloads available, unlike -s scripts):
##   DISPLAY=... godot --path . --resolution WxH res://dev/world_shot.tscn -- out.png <zoom> [x z]


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	Config.headless_capture = true
	var w = JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/world.json"))
	w["city"] = "fenwick_span"
	Content._apply(JSON.parse_string(FileAccess.get_file_as_string("res://src/mock/content.json")), false)
	var world := CityWorld3D.new()
	add_child(world)
	await get_tree().process_frame
	world.build(w)
	var t := Vector3(float(a[2]), 0, float(a[3])) if a.size() > 3 else Vector3(32, 0, 24)
	# let the CDN art arrive first
	var waited := 0.0
	while (AssetService.manifest.is_empty() or not AssetService.idle()) and waited < 30.0:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	for _i in 4:
		await get_tree().process_frame
	world.cam.look_at_point(t, float(a[1]), false)
	for _i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(a[0])
	print("saved ", a[0])
	get_tree().quit()
