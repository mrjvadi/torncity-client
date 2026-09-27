extends Control
## The root: splash -> (auto login | link screen) -> the game shell.

var _screen: Control
var _taps := 0
var _slow := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Game.login_needed.connect(show_login)
	if Config.headless_capture:
		return  # the screenshot/test harness drives the flow itself
	show_splash()
	var min_splash := get_tree().create_timer(1.2)
	var ok := await Game.boot()
	if min_splash.time_left > 0:
		await min_splash.timeout
	if ok:
		show_shell()
	else:
		show_login()


func _swap(c: Control) -> void:
	if _screen:
		var old := _screen
		if Config.headless_capture:
			old.queue_free()
		else:
			var t := old.create_tween()
			t.tween_property(old, "modulate:a", 0.0, 0.25)
			t.tween_callback(old.queue_free)
	_screen = c
	add_child(c)
	if not Config.headless_capture:
		Fx.fade_in(c, 0.3)


func show_splash() -> Control:
	var s: Control = load("res://src/scenes/splash.tscn").instantiate()
	_swap(s)
	return s


func show_login() -> Control:
	var l: Control = load("res://src/scenes/login.tscn").instantiate()
	_swap(l)
	l.done.connect(show_shell)
	return l


func show_shell() -> Control:
	if _screen and _screen.name == "Shell":
		return _screen
	Game.mark("shell")
	var s: Control = load("res://src/scenes/shell.tscn").instantiate()
	s.name = "Shell"
	_swap(s)
	s.start()
	return s


## The first taps a web build gets, for the page's reporter: whether input
## reaches the game at all on a device that seems not to answer.
func _input(e: InputEvent) -> void:
	if _taps >= 4 or not OS.has_feature("web"):
		return
	if (e is InputEventScreenTouch or e is InputEventMouseButton) and e.pressed:
		_taps += 1
		Game.mark("tap %s at %d,%d" % ["touch" if e is InputEventScreenTouch else "mouse", int(e.position.x), int(e.position.y)])


## A frame that took over a second, for the page's reporter (the first few):
## where a device that seems stuck actually spends its time.
func _process(delta: float) -> void:
	if delta > 1.0 and _slow < 6 and OS.has_feature("web"):
		_slow += 1
		Game.mark("slow frame %d ms on %s" % [int(delta * 1000.0), _screen.name if _screen else "-"])
