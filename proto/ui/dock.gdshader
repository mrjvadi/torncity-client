// The dock: a panel along the bottom whose top edge rises into a smooth
// hump at the centre, a pedestal for the main action button. Metallic trim
// along the whole edge, a girih lattice, a glow inside the rim.
shader_type canvas_item;

uniform vec2 size = vec2(720.0, 200.0);
uniform float top = 70.0;          // y of the dock's straight top edge
uniform float hump_r = 92.0;       // radius of the central rise
uniform float hump_y = 40.0;       // y of the rise's centre
uniform vec4 fill_top : source_color = vec4(0.12, 0.14, 0.31, 0.98);
uniform vec4 fill_bottom : source_color = vec4(0.03, 0.04, 0.11, 0.98);
uniform vec4 trim : source_color = vec4(0.96, 0.76, 0.34, 1.0);
uniform vec4 glow : source_color = vec4(0.17, 0.77, 0.70, 0.35);

float smin(float a, float b, float k) {
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
	return mix(b, a, h) - k * h * (1.0 - h);
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
	vec2 p = UV * size;
	float body = sd_box(p - vec2(size.x * 0.5, (top + size.y + 60.0) * 0.5), vec2(size.x * 0.5 + 40.0, (size.y + 60.0 - top) * 0.5));
	float hump = length(p - vec2(size.x * 0.5, hump_y + hump_r * 0.5)) - hump_r;
	float d = smin(body, hump, 38.0);

	// shadow above the edge
	vec4 col = vec4(0.0, 0.0, 0.02, (1.0 - smoothstep(-2.0, 22.0, d)) * 0.55);
	float t = clamp((p.y - hump_y) / (size.y - hump_y), 0.0, 1.0);
	vec3 face = mix(fill_top.rgb, fill_bottom.rgb, t);
	vec2 g = mod(p, vec2(46.0)) - 23.0;
	face += trim.rgb * (1.0 - smoothstep(0.5, 1.5, abs(star8(g, 11.5)))) * 0.06;
	face += glow.rgb * glow.a * exp(d / 12.0);
	float inside = 1.0 - smoothstep(-1.0, 0.0, d);
	col = mix(col, vec4(face, fill_top.a), inside);
	float ring = smoothstep(-4.5, -3.5, d) * (1.0 - smoothstep(-1.0, 0.0, d));
	float lit = 0.8 + 0.5 * (1.0 - t);
	col = mix(col, vec4(trim.rgb * lit, 1.0), ring);
	float dark = smoothstep(-7.0, -6.0, d) * (1.0 - smoothstep(-5.0, -4.0, d));
	col.rgb = mix(col.rgb, col.rgb * 0.5, dark * 0.8);
	COLOR = col;
}
