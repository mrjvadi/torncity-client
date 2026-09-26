class_name GlassShadow
extends Control
## The soft shadow under a GlassPanel: layered translucent rounded rects,
## following the panel's rect every frame it moves.

var target: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(_d: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	visible = target.visible and target.is_visible_in_tree()
	var r := Rect2(target.position, target.size)
	if position != r.position - Vector2(24, 12) or size != r.size + Vector2(48, 48):
		position = r.position - Vector2(24, 12)
		size = r.size + Vector2(48, 48)
		queue_redraw()
	modulate.a = target.modulate.a


func _draw() -> void:
	if not is_instance_valid(target):
		return
	var rad := float((target as GlassPanel).radius) if target is GlassPanel else 18.0
	var base := Rect2(Vector2(24, 20), target.size)
	for i in 6:
		var g := base.grow(float(i) * 2.5)
		draw_colored_polygon(GlowPanel.rounded_rect(g, rad + i * 2.5, 6), Color(0.0, 0.02, 0.06, 0.07))
