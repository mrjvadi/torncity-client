// An ornate game panel, drawn entirely on the GPU so it stays crisp at any
// size: a soft drop shadow, a vertical gradient face with a faint girih
// (eight-point star) lattice, a glow along the inside of the edge, and a
// metallic trim whose light comes from the top.
shader_type canvas_item;

uniform vec2 size = vec2(200.0, 100.0);
uniform float radius = 24.0;
uniform float margin = 16.0;          // room around the panel for the shadow
uniform vec4 fill_top : source_color = vec4(0.12, 0.15, 0.30, 0.94);
uniform vec4 fill_bottom : source_color = vec4(0.05, 0.06, 0.14, 0.94);
uniform vec4 trim : source_color = vec4(0.96, 0.76, 0.34, 1.0);
uniform float trim_w = 3.0;
uniform vec4 glow : source_color = vec4(0.17, 0.77, 0.70, 0.0);
uniform float pattern = 0.06;
uniform float shadow = 0.6;

float sd_rrect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}
float sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}
float star8(vec2 p, float s) {
	vec2 r = vec2(p.x - p.y, p.x + p.y) * 0.70710678;
	return min(sd_box(p, vec2(s)), sd_box(r, vec2(s)));
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	vec2 b = size * 0.5 - margin;
	float r = min(radius, min(b.x, b.y));
	float d = sd_rrect(p, b, r);

	float ds = sd_rrect(p - vec2(0.0, margin * 0.4), b, r);
	vec4 col = vec4(0.0, 0.0, 0.02, (1.0 - smoothstep(-2.0, margin, ds)) * shadow);

	float t = clamp((p.y + b.y) / (2.0 * b.y), 0.0, 1.0);
	vec3 face = mix(fill_top.rgb, fill_bottom.rgb, t);
	vec2 cell = vec2(46.0);
	vec2 g = mod(p + b, cell) - cell * 0.5;
	float line = 1.0 - smoothstep(0.5, 1.5, abs(star8(g, 11.5)));
	face += trim.rgb * line * pattern;
	face += glow.rgb * glow.a * exp(d / 9.0);
	face += vec3(0.06) * (1.0 - smoothstep(0.0, 0.3, t));
	float inside = 1.0 - smoothstep(-1.0, 0.0, d);
	col = mix(col, vec4(face, mix(fill_top.a, fill_bottom.a, t)), inside);

	// metallic trim: bright on top, deeper at the bottom, a dark line inside it
	float ring = smoothstep(-trim_w - 1.0, -trim_w, d) * (1.0 - smoothstep(-1.0, 0.0, d));
	float lit = 0.72 + 0.5 * (1.0 - t) + 0.35 * pow(max(0.0, -p.y / b.y), 3.0);
	vec3 metal = trim.rgb * lit;
	col = mix(col, vec4(metal, trim.a), ring * trim.a);
	float dark = smoothstep(-trim_w - 2.5, -trim_w - 1.5, d) * (1.0 - smoothstep(-trim_w - 1.0, -trim_w, d));
	col.rgb = mix(col.rgb, col.rgb * 0.45, dark * 0.8 * trim.a);
	COLOR = col;
}
