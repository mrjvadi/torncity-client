// A chunky glossy game button: a dark outline, a body with a vertical
// gradient, a thick darker "lip" underneath that sinks when pressed, and a
// glossy highlight across the upper half.
shader_type canvas_item;

uniform vec2 size = vec2(200.0, 70.0);
uniform float radius = 20.0;
uniform vec4 top : source_color = vec4(0.36, 0.90, 0.82, 1.0);
uniform vec4 bottom : source_color = vec4(0.10, 0.62, 0.56, 1.0);
uniform vec4 lip : source_color = vec4(0.04, 0.36, 0.33, 1.0);
uniform vec4 outline : source_color = vec4(0.02, 0.05, 0.10, 1.0);
uniform float lip_h = 7.0;
uniform float pressed = 0.0;

float sd_rrect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	vec2 half_s = size * 0.5 - vec2(2.0);
	float lh = lip_h * (1.0 - pressed);
	// body sits above the lip
	vec2 bb = vec2(half_s.x, half_s.y - lip_h * 0.5);
	vec2 bc = vec2(0.0, -lip_h * 0.5 + (lip_h - lh));
	float r = min(radius, bb.y);
	float d_body = sd_rrect(p - bc, bb, r);
	float d_lip = sd_rrect(p - vec2(0.0, lip_h * 0.5), bb, r);
	float d_all = min(d_body, d_lip);

	vec4 col = vec4(outline.rgb, outline.a * (1.0 - smoothstep(1.2, 2.4, d_all)));
	float in_lip = 1.0 - smoothstep(-1.0, 0.0, d_lip);
	col = mix(col, lip, in_lip);
	float in_body = 1.0 - smoothstep(-1.0, 0.0, d_body);
	float t = clamp((p.y - bc.y + bb.y) / (2.0 * bb.y), 0.0, 1.0);
	vec3 face = mix(top.rgb, bottom.rgb, t);
	// gloss: a soft band over the upper half, fading downwards
	float gl = (1.0 - smoothstep(0.08, 0.5, t)) * (1.0 - smoothstep(-6.0, -2.0, d_body + 4.0) * 0.0);
	face = mix(face, vec3(1.0), gl * 0.32);
	// rim light along the top edge
	face += vec3(0.25) * (1.0 - smoothstep(-3.5, -1.5, d_body)) * (1.0 - t);
	col = mix(col, vec4(face, top.a), in_body);
	COLOR = col;
}
