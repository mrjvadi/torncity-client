// A slowly turning sunburst behind the main button: soft rays fading out.
shader_type canvas_item;
uniform vec4 color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float count = 14.0;
uniform float speed = 0.25;
void fragment() {
	vec2 p = UV - 0.5;
	float r = length(p) * 2.0;
	float a = atan(p.y, p.x) + TIME * speed;
	float ray = smoothstep(0.35, 1.0, 0.5 + 0.5 * cos(a * count));
	float fade = (1.0 - smoothstep(0.35, 1.0, r)) * smoothstep(0.2, 0.45, r);
	float halo = (1.0 - smoothstep(0.3, 0.75, r)) * 0.35;
	COLOR = vec4(color.rgb, (ray * fade * 0.55 + halo) * color.a);
}
