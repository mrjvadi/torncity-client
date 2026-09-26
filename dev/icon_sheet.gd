extends SceneTree
## Render every library icon key as a badge into one PNG (review sheet):
##   godot -s dev/icon_sheet.gd -- out.png


func _init() -> void:
	await process_frame
	var out := OS.get_cmdline_user_args()[0]
	var lib = root.get_node("AssetLib")
	var keys: Array = lib.icons.keys()
	keys.sort()
	var cols := 12
	var cell := 110
	var rows := int(ceil(keys.size() / float(cols)))
	root.size = Vector2i(cols * cell, rows * cell)
	var bg := ColorRect.new()
	bg.color = Color("#0F1A2B")
	bg.size = Vector2(root.size)
	root.add_child(bg)
	var grid := GridContainer.new()
	grid.columns = cols
	grid.layout_direction = Control.LAYOUT_DIRECTION_LTR
	grid.position = Vector2(12, 12)
	grid.add_theme_constant_override("h_separation", cell - 86)
	grid.add_theme_constant_override("v_separation", cell - 86)
	root.add_child(grid)
	for i in keys.size():
		grid.add_child(IconBadge.make(lib.glyph(keys[i]), 86))
	for _i in 4:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out, " ", keys.size(), " keys")
	quit()
