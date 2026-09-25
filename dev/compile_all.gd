# Loads every script and scene so the parser reports errors with the
# autoloads in place:  godot --headless -s dev/compile_all.gd
extends SceneTree

func _init() -> void:
	await process_frame
	var bad := 0
	for dir in ["res://src", "res://tests"]:
		for f in _walk(dir):
			if f.ends_with(".gd") or f.ends_with(".tscn"):
				var r = load(f)
				if r == null or (r is GDScript and not r.can_instantiate()):
					bad += 1
					printerr("FAILED: ", f)
	print("compile_all: %d failed" % bad)
	quit(1 if bad > 0 else 0)


func _walk(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_walk(dir.path_join(sub)))
	return out
