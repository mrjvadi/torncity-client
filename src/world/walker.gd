class_name Walker
extends Node2D
## The player on the city map. Uses the rendered walk-cycle sprite sheet
## (assets/art/character/walker.png + walker.json: 4 isometric directions x N
## frames) when present, and a vector stand-in otherwise. An AnimationPlayer
## carries the idle bob and the arrival hop; the player's avatar floats above.

var facing := "sw"
var walking := false
var avatar_code := ""
var _sprite: AnimatedSprite2D
var _anim: AnimationPlayer
var _body: Node2D
var _meta := {}
var _t := 0.0


func _ready() -> void:
	_body = Node2D.new()
	add_child(_body)
	var meta_path := "res://assets/art/character/walker.json"
	if FileAccess.file_exists(meta_path):
		_meta = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	var sheet: Texture2D = load("res://assets/art/character/walker.png") if ResourceLoader.exists("res://assets/art/character/walker.png") else null
	if sheet and _meta is Dictionary and not _meta.is_empty():
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = _frames(sheet)
		var sc := float(_meta.get("display_height", 64)) / float(_meta["frame_size"][1])
		_sprite.scale = Vector2(sc, sc)
		_sprite.centered = false
		_sprite.offset = -Vector2(_meta["anchor"][0], _meta["anchor"][1])
		_body.add_child(_sprite)
	_build_anim()
	_play()


func _frames(sheet: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var fw: int = _meta["frame_size"][0]
	var fh: int = _meta["frame_size"][1]
	var rows: Dictionary = _meta["rows"]          # "walk_se": row index...
	var n: int = _meta["frames"]
	for anim_name in rows:
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(_meta.get("fps", 10)))
		sf.set_animation_loop(anim_name, true)
		var count := n if anim_name.begins_with("walk") else int(_meta.get("idle_frames", 1))
		for f in count:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(f * fw, int(rows[anim_name]) * fh, fw, fh)
			at.filter_clip = true
			sf.add_frame(anim_name, at)
	return sf


func _build_anim() -> void:
	_anim = AnimationPlayer.new()
	add_child(_anim)
	var lib := AnimationLibrary.new()
	var idle := Animation.new()
	idle.length = 1.6
	idle.loop_mode = Animation.LOOP_LINEAR
	var tr := idle.add_track(Animation.TYPE_VALUE)
	idle.track_set_path(tr, NodePath("%s:position" % _body.name))
	idle.track_insert_key(tr, 0.0, Vector2.ZERO)
	idle.track_insert_key(tr, 0.8, Vector2(0, -2.5))
	idle.track_insert_key(tr, 1.6, Vector2.ZERO)
	lib.add_animation("idle", idle)
	var hop := Animation.new()
	hop.length = 0.7
	var t2 := hop.add_track(Animation.TYPE_VALUE)
	hop.track_set_path(t2, NodePath("%s:position" % _body.name))
	hop.track_insert_key(t2, 0.0, Vector2.ZERO)
	hop.track_insert_key(t2, 0.18, Vector2(0, -22), 0.5)
	hop.track_insert_key(t2, 0.36, Vector2.ZERO)
	hop.track_insert_key(t2, 0.5, Vector2(0, -7))
	hop.track_insert_key(t2, 0.7, Vector2.ZERO)
	var t3 := hop.add_track(Animation.TYPE_VALUE)
	hop.track_set_path(t3, NodePath("%s:scale" % _body.name))
	hop.track_insert_key(t3, 0.0, Vector2(1.15, 0.85))
	hop.track_insert_key(t3, 0.18, Vector2(0.92, 1.1))
	hop.track_insert_key(t3, 0.36, Vector2(1.12, 0.88))
	hop.track_insert_key(t3, 0.7, Vector2.ONE)
	lib.add_animation("hop", hop)
	_anim.add_animation_library("", lib)
	_anim.animation_finished.connect(func(_n): _play())


func set_walking(on: bool, dir := "") -> void:
	walking = on
	if dir != "":
		facing = dir
	_play()


func celebrate() -> void:
	if Config.headless_capture:
		return
	_anim.play("hop")


func _play() -> void:
	if _sprite:
		var a := ("walk_" if walking else "idle_") + facing
		if _sprite.sprite_frames.has_animation(a):
			if _sprite.animation != a or not _sprite.is_playing():
				_sprite.play(a)
	if not walking and _anim and _anim.current_animation != "hop" and not Config.headless_capture:
		_anim.play("idle")


func _process(delta: float) -> void:
	_t += delta * (9.0 if walking else 0.0)
	if _sprite == null:
		queue_redraw()


## Vector stand-in: shadow, legs swinging, body, head, facing cue.
func _draw() -> void:
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0, 0), 13, Color(0, 0, 0, 0.0))
	var shadow := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20
		shadow.append(Vector2(cos(a) * 16, sin(a) * 7))
	draw_colored_polygon(shadow, Color(0.05, 0.06, 0.12, 0.35))
	if _sprite:
		return
	var off := _body.position if _body else Vector2.ZERO
	var swing := sin(_t) * 7.0 if walking else 0.0
	var skin := Color("#E8B48C")
	var shirt := AppTheme.col("turquoise")
	var pants := AppTheme.col("slate")
	var flip := -1.0 if facing in ["nw", "sw"] else 1.0
	draw_line(off + Vector2(-4, -16), off + Vector2(-4 + swing * flip, -1), pants.darkened(0.2), 6, true)
	draw_line(off + Vector2(4, -16), off + Vector2(4 - swing * flip, -1), pants, 6, true)
	draw_colored_polygon(GlowPanel.rounded_rect(Rect2(off + Vector2(-10, -38), Vector2(20, 24)), 7, 4), shirt)
	draw_line(off + Vector2(-10, -34), off + Vector2(-12 - swing * flip * 0.6, -20), shirt.darkened(0.2), 5, true)
	draw_line(off + Vector2(10, -34), off + Vector2(12 + swing * flip * 0.6, -20), shirt.darkened(0.1), 5, true)
	draw_circle(off + Vector2(0, -46), 9, skin)
	var back := facing in ["nw", "ne"]
	draw_arc(off + Vector2(0, -48), 9, PI, TAU, 16, Color("#3A2A22"), 7 if back else 5, true)
