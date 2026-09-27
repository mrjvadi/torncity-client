class_name CityWorldView
extends SubViewportContainer
## The 3D city inside the UI: a SubViewport holding CityWorld3D. It loads the
## layout from GET /api/v1/world/city?code=, applies {type:"world.plot"}
## updates from the city channel, and speaks the same API the city screen
## used with the 2D map (place_tapped, set_view, arrive, here, selected).
## Tapping a company plot sends company.show (the server decides what to show).

signal place_tapped(code: String)
signal plot_tapped(plot: Dictionary)

var world: CityWorld3D
var here := ""
var selected := ""
var slots := {}          # place code -> plot id
var _vp: SubViewport
var _city := ""
var _pending_view := {}
var _loading := false


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	# An iPhone's web view has little GPU memory and kills the page when it
	# runs out; the 3D city renders at half the screen's pixels there (the
	# screen is 3x dense, so it stays sharp), a quarter of the memory.
	if Config.phone_web():
		stretch_shrink = 2
	_vp = SubViewport.new()
	# WebGL resolves a multisampled viewport with a framebuffer blit Safari
	# refuses; the web build draws without it.
	_vp.msaa_3d = Viewport.MSAA_DISABLED if OS.has_feature("web") else Viewport.MSAA_2X
	_vp.handle_input_locally = true
	_vp.physics_object_picking = false
	add_child(_vp)
	world = CityWorld3D.new()
	_vp.add_child(world)
	world.plot_tapped.connect(_on_plot)
	Realtime.world_plot.connect(_on_world_plot)
	I18n.changed.connect(func(_l): _relabel())


func _gui_input(event: InputEvent) -> void:
	# SubViewportContainer forwards input to the viewport; the camera reads it
	if world and world.cam:
		var e := event
		if stretch_shrink > 1 and (event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag):
			e = event.duplicate()
			e.position = event.position / float(stretch_shrink)
		world.cam.handle(e)
		accept_event()


## The map.list view (where the player is, walking...). Loads the city's
## layout the first time, or when the player is in another city.
func set_view(v: Dictionary) -> void:
	var code := str(v.get("city_code", Session.city_code))
	if code == "":
		code = Session.city_code
	_pending_view = v
	var first := false
	if code != _city and not _loading:
		_loading = true
		var r: Dictionary = await Api.get_json("/api/v1/world/city?code=" + code.uri_encode())
		_loading = false
		if r.get("status", 0) == 200 and r.get("data") is Dictionary:
			_city = code
			world.build(r["data"])
			_index_slots()
			first = true
	_apply_view(_pending_view)
	if first:
		world.cam.look_at_point(home_point(), default_zoom(), false)


func _index_slots() -> void:
	slots.clear()
	for p in world.model.plots.values():
		var ref = p.get("ref", {})
		if ref is Dictionary and str(ref.get("table", "")) == "place":
			slots[str(ref.get("code", ""))] = str(p["id"])


func _apply_view(v: Dictionary) -> void:
	here = ""
	for p in v.get("places", []):
		if p is Dictionary and p.get("here", false):
			here = str(p.get("place", {}).get("code", ""))
	if here == "" and v.get("here") is Dictionary:
		here = str(v["here"].get("code", ""))
	var w = v.get("walking")
	if w is Dictionary and w.get("to") is Dictionary:
		var to := str(w["to"].get("code", ""))
		var total := 0.0
		for p in v.get("places", []):
			if str(p.get("place", {}).get("code", "")) == to:
				total = float(p.get("walk_seconds", 0))
		var left := float(w.get("remaining_seconds", 0))
		var from := here if here != "" and here != to else _any_other(to)
		world.walk(slots.get(from, ""), slots.get(to, ""), left, maxf(total, left))
	else:
		world.place_player(slots.get(here, ""))
	if selected == "" or not slots.has(selected):
		selected = here
	if slots.has(selected):
		world.select(slots[selected])


func _any_other(to: String) -> String:
	for c in slots:
		if c != to:
			return c
	return to


func _on_plot(p: Dictionary) -> void:
	plot_tapped.emit(p)
	var ref = p.get("ref", {})
	if not (ref is Dictionary):
		return
	match str(p.get("kind", "")):
		"place":
			selected = str(ref.get("code", ""))
			place_tapped.emit(selected)
		"company":
			if ref.has("company_id"):
				Game.run("company.show", {"id": ref["company_id"]})


func _on_world_plot(data: Dictionary) -> void:
	if str(data.get("city", _city)) != _city:
		return
	world.apply_update(data)
	_index_slots()


func arrive(code: String) -> void:
	here = code
	selected = code
	world.arrive(slots.get(code, ""))


func pulse_place(code: String) -> void:
	world.bounce(slots.get(code, ""))


func select(code: String) -> void:
	selected = code
	world.select(slots.get(code, ""))


func focus(code: String) -> void:
	world.focus(slots.get(code, ""))


func _relabel() -> void:
	if world and not world._world_desc.is_empty():
		world.build(world._world_desc)
		_apply_view(_pending_view)


## Where the camera starts: where the player is, else downtown, else the middle.
func home_point() -> Vector3:
	if slots.has(here):
		return world.model.plot_center(world.model.plots[slots[here]])
	for d in world.model.districts:
		if str(d.get("kind", "")) == "cbd":
			var c := WorldModel.district_rect(d).get_center()
			return Vector3(c.x, 0, c.y)
	var b := world.model.bounds.get_center()
	return Vector3(b.x, 0, b.y)


func default_zoom() -> float:
	return 20.0 if size.x < size.y else 26.0
