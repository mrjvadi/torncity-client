class_name Portrait
extends Control
## A square portrait in a slot frame. The player's chosen avatar (life.yml
## presets) when they have one; otherwise a rendered default portrait.

const DEFAULTS := ["businessman", "hoodie", "woman", "thug", "fighter", "swat"]

var code := ""
var _tex: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_avatar(c: String, seed_text := "") -> void:
	code = c
	_tex = null
	if c != "" and c != "photo" and c != "none":
		_tex = AppTheme.tex("avatar/" + c)
	if _tex == null:
		var i := absi(hash(seed_text if seed_text != "" else str(Session.player.get("id", 0)))) % DEFAULTS.size()
		_tex = AppTheme.tex("portrait/" + DEFAULTS[i])
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(AppTheme.kitbox("slot_selected", 0, 0), r)
	if _tex:
		var inner := r.grow(-5)
		draw_colored_polygon(GlowPanel.rounded_rect(inner, 6, 4), Color("#1B2C46"))
		draw_texture_rect(_tex, inner, false)
