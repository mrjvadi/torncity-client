class_name GlassPanel
extends PanelContainer
## A frosted-glass panel: the content behind it blurred and tinted navy, a
## soft 1 px light border, large radius and a drop shadow drawn underneath.
## Use it for anything floating over the city or over scrolling content.

const SHADER := preload("res://src/ui/shaders/glass.gdshader")

@export var radius := 22
@export var tint_color := Color("#0E1528")
@export var tint := 0.82
@export var pad := Vector4(18, 14, 18, 14)   # left, top, right, bottom
@export var border := Color(0.62, 0.72, 1.0, 0.14)
@export var drop_shadow := true


func _ready() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = tint_color
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.anti_aliasing = true
	sb.content_margin_left = pad.x
	sb.content_margin_top = pad.y
	sb.content_margin_right = pad.z
	sb.content_margin_bottom = pad.w
	add_theme_stylebox_override("panel", sb)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("tint", tint)
	material = m
	# children draw normally (not through the glass shader)
	for c in get_children():
		if c is CanvasItem:
			(c as CanvasItem).use_parent_material = false


## A shadow sibling drawn before the panel (a panel's own material would blur it).
func _enter_tree() -> void:
	# only for free-floating panels: a sibling inside a Container would take a slot
	if drop_shadow and not has_meta("shadow") and not (get_parent() is Container):
		var s := GlassShadow.new()
		s.target = self
		set_meta("shadow", s)
		(func():
			if get_parent():
				get_parent().add_child(s)
				get_parent().move_child(s, get_index())).call_deferred()


func _exit_tree() -> void:
	if has_meta("shadow"):
		var s = get_meta("shadow")
		if is_instance_valid(s):
			s.queue_free()
		remove_meta("shadow")
