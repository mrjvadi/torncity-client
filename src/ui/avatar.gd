class_name AvatarBadge
extends Control
## A round portrait: the player's chosen avatar (life.yml presets) in a ring,
## with an optional level badge. Unknown or "photo"/"none" avatars show initials.

@export var diameter := 92.0
@export var ring := Color("#2F80ED")

var code := ""
var initials := ""
var level := 0
var _tex: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_avatar(c: String, name := "", lvl := 0) -> void:
	code = c
	level = lvl
	initials = name.substr(0, 1).to_upper() if name != "" else "?"
	var t = AssetService.get_asset("avatar:" + c) if c != "" and c != "photo" and c != "none" else null
	_tex = t if t is Texture2D else null
	if _tex == null and c != "" and not AssetService.loaded.is_connected(_on_asset):
		AssetService.loaded.connect(_on_asset)
	queue_redraw()


func _draw() -> void:
	var d := minf(size.x, size.y)
	var c := Vector2(d, d) / 2.0
	draw_circle(c + Vector2(0, 4), d / 2.0, Color(0, 0, 0, 0.35))
	draw_circle(c, d / 2.0, ring)
	draw_circle(c, d / 2.0 - 4, AppTheme.col("night"))
	if _tex:
		draw_texture_rect(_tex, Rect2(Vector2(6, 6), Vector2(d - 12, d - 12)), false)
	else:
		var f := AppTheme.font_black
		var fs := int(d * 0.42)
		var w := f.get_string_size(initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2((d - w) / 2.0, d / 2.0 + fs * 0.36), initials, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, AppTheme.col("text"))
	draw_arc(c, d / 2.0 - 2, 0, TAU, 64, ring.lightened(0.25), 2.0, true)
	if level > 0:
		var t := I18n.num(level)
		var f2 := AppTheme.font_black
		var fs2 := int(d * 0.2)
		var tw := f2.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		var bw := maxf(d * 0.36, tw + 16)
		var br := Rect2(Vector2((d - bw) / 2.0, d - d * 0.2), Vector2(bw, d * 0.27))
		draw_colored_polygon(GlowPanel.rounded_rect(br.grow(2), br.size.y / 2 + 2, 6), AppTheme.col("night"))
		draw_colored_polygon(GlowPanel.rounded_rect(br, br.size.y / 2, 6), AppTheme.col("saffron"))
		draw_string(f2, Vector2(br.position.x + (bw - tw) / 2.0, br.position.y + br.size.y / 2 + fs2 * 0.38), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, AppTheme.col("ink"))


func _on_asset(k: String) -> void:
	if k == "avatar:" + code:
		var t = AssetService.get_asset(k)
		_tex = t if t is Texture2D else null
		queue_redraw()
