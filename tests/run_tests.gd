# The test runner: godot --headless -s tests/run_tests.gd  (exit code = failures)
# Runs every tests/test_*.gd; each test_* method may await.
extends SceneTree

func _init() -> void:
	await process_frame
	# autoloads are looked up at run time: this script compiles before they exist
	root.get_node("Config").headless_capture = true
	root.get_node("Config").mock = true
	root.get_node("Mock").latency = 0.0
	var files := DirAccess.get_files_at("res://tests")
	var total := 0
	var failed := 0
	for f in files:
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_case.gd":
			continue
		var script: GDScript = load("res://tests/" + f)
		var t = script.new()
		t.tree = self
		for m in t.get_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			t._current = "%s::%s" % [f.get_basename(), name]
			var before: int = t.failures.size()
			await t.call(name)
			if t.failures.size() > before:
				failed += 1
				for i in range(before, t.failures.size()):
					printerr("FAIL ", t.failures[i])
			else:
				print("ok   ", t._current)
	print("\n%d tests, %d failed" % [total, failed])
	quit(failed)
