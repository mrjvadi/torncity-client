# Renders SVGs to one PNG contact sheet, without a window:
#   godot --headless -s dev/contact_sheet.gd -- <out.png> <cell_px> <file.svg>...
# Used to review generated art (the PNG is not part of the game).
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var cell := int(args[1])
	var files := args.slice(2)
	var cols := int(ceil(sqrt(files.size())))
	var rows := int(ceil(files.size() / float(cols)))
	var sheet := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#e9ecf3") if out.contains("light") else Color("#1A2139"))
	for i in files.size():
		var src := FileAccess.get_file_as_string(files[i])
		var img := Image.new()
		# Rasterise at a scale that fits the SVG's width into the cell.
		var w := 256.0
		var m := RegEx.create_from_string('width="([0-9.]+)"').search(src)
		if m: w = float(m.get_string(1))
		var err := img.load_svg_from_string(src, cell / w)
		if err != OK:
			push_error("cannot load " + files[i]); continue
		img.convert(Image.FORMAT_RGBA8)
		var x := (i % cols) * cell
		var y := (i / cols) * cell
		sheet.blend_rect(img, Rect2i(0, 0, min(img.get_width(), cell), min(img.get_height(), cell)), Vector2i(x, y))
	sheet.save_png(out)
	print("saved ", out)
	quit()
