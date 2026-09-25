class_name Fx
## Motion: eased tweens for entrances and feedback, and cheap particle bursts
## (CPUParticles2D: works on the Compatibility renderer and the web).


static func _still() -> bool:
	return Config.headless_capture


## Squash on press, spring back on release.
static func press_feedback(c: BaseButton) -> void:
	c.resized.connect(func(): c.pivot_offset = c.size / 2)
	c.button_down.connect(func():
		if _still(): return
		var t := c.create_tween()
		t.tween_property(c, "scale", Vector2(0.95, 0.95), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT))
	c.button_up.connect(func():
		if _still(): return
		var t := c.create_tween()
		t.tween_property(c, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))


## Children rise and fade in one after another.
static func stagger_in(container: Control, step := 0.045, rise := 26.0) -> void:
	if _still():
		return
	var i := 0
	for c in container.get_children():
		if not (c is CanvasItem):
			continue
		c.modulate.a = 0.0
		var t := container.create_tween()
		t.tween_interval(i * step)
		t.tween_property(c, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if c is Control and not (container is Container):
			var y: float = c.position.y
			c.position.y = y + rise
			t.parallel().tween_property(c, "position:y", y, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1


static func fade_in(c: CanvasItem, dur := 0.25) -> void:
	if _still():
		return
	c.modulate.a = 0.0
	c.create_tween().tween_property(c, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func pop(c: Control, from := 0.6) -> void:
	if _still():
		return
	c.pivot_offset = c.size / 2
	c.scale = Vector2(from, from)
	c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A number label that rolls from its old value to the new one.
static func roll_number(l: Label, from: int, to: int, fmt: Callable, dur := 0.6) -> void:
	if _still() or from == to:
		l.text = fmt.call(to)
		return
	var t := l.create_tween()
	t.tween_method(func(v: float): l.text = fmt.call(int(round(v))), float(from), float(to), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func pulse(c: CanvasItem, color := Color(1.4, 1.4, 1.4)) -> void:
	if _still():
		return
	var t := c.create_tween()
	t.tween_property(c, "modulate", color, 0.12)
	t.tween_property(c, "modulate", Color.WHITE, 0.4)


## A burst of textured particles at a point in `parent` (coins, sparkles...).
static func burst(parent: Node, at: Vector2, texture: Texture2D, amount := 18, color := Color.WHITE, spread := 180.0, speed := 420.0, scale_px := 34.0) -> void:
	if _still() or texture == null:
		return
	var p := CPUParticles2D.new()
	p.position = at
	p.texture = texture
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 1.1
	p.direction = Vector2.UP
	p.spread = spread
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 900)
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	var s := scale_px / maxf(1.0, texture.get_width())
	p.scale_amount_min = s * 0.6
	p.scale_amount_max = s
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.7, Color(1, 1, 1, 1))
	p.color_ramp = ramp
	p.z_index = 50
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## Soft floating sparkles (for arrivals and level-ups).
static func sparkle(parent: Node, at: Vector2, color := Color("#F6B93B")) -> void:
	burst(parent, at, AppTheme.icon("xp"), 14, color, 180.0, 260.0, 22.0)


static func coins(parent: Node, at: Vector2) -> void:
	burst(parent, at, AppTheme.icon("gold_coin") if AppTheme.icon("gold_coin") else AppTheme.icon("level"), 22, Color.WHITE, 70.0, 620.0, 30.0)
