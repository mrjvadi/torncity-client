class_name TestCase
extends RefCounted
## Base for tests: every method named test_* runs; assertions record failures.

var failures: PackedStringArray = []
var tree: SceneTree
var _current := ""


func check(cond: bool, msg := "") -> void:
	if not cond:
		failures.append("%s: %s" % [_current, msg if msg != "" else "check failed"])


func eq(got, want, msg := "") -> void:
	if typeof(got) != typeof(want) and not (typeof(got) in [TYPE_INT, TYPE_FLOAT] and typeof(want) in [TYPE_INT, TYPE_FLOAT]):
		failures.append("%s: %s expected %s (%s), got %s (%s)" % [_current, msg, var_to_str(want), type_string(typeof(want)), var_to_str(got), type_string(typeof(got))])
	elif got != want:
		failures.append("%s: %s expected %s, got %s" % [_current, msg, var_to_str(want), var_to_str(got)])


func near(got: float, want: float, eps := 0.001, msg := "") -> void:
	if absf(got - want) > eps:
		failures.append("%s: %s expected ~%s, got %s" % [_current, msg, want, got])


func frames(n := 1) -> void:
	for i in n:
		await tree.process_frame
