// A title ribbon: a lit band with a metallic edge, and swallow-tailed ends
// folded behind it in a darker shade.
shader_type canvas_item;

uniform vec2 size = vec2(420.0, 90.0);
uniform vec4 face_top : source_color = vec4(0.86, 0.22, 0.24, 1.0);
uniform vec4 face_bottom : source_color = vec4(0.52, 0.08, 0.12, 1.0);
uniform vec4 edge : source_color = vec4(0.96, 0.76, 0.34, 1.0);

float sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	float hb = size.y * 0.34;          // half height of the band
	float body_w = size.x * 0.5 - size.y * 0.55;
	vec4 col = vec4(0.0);
	// tails: lower, darker, with a V notch at the outer end
	float tx = abs(p.x) - body_w + size.y * 0.15;
	float tail_y = p.y - size.y * 0.1;
	float in_tail = step(0.0, tx) * step(abs(tail_y), hb * 0.9) * step(tx, size.y * 0.55);
	float notch = step(size.y * 0.55 - abs(tail_y) * 0.9, tx);
	in_tail *= 1.0 - notch;
	vec3 tail_c = face_bottom.rgb * 0.6;
	col = mix(col, vec4(tail_c, 1.0), in_tail);
	// fold shadow where the band meets the tail
	float fold = step(abs(abs(p.x) - body_w), size.y * 0.12) * step(0.0, p.y) * step(p.y, hb + size.y * 0.12);
	col = mix(col, vec4(face_bottom.rgb * 0.35, 1.0), fold * 0.9);
	// band, gently arched
	float arch = (p.x / size.x) * (p.x / size.x) * size.y * 0.25;
	float d = sd_box(p + vec2(0.0, arch), vec2(body_w, hb));
	float inside = 1.0 - smoothstep(-1.0, 0.0, d);
	float t = clamp((p.y + arch + hb) / (2.0 * hb), 0.0, 1.0);
	vec3 face = mix(face_top.rgb, face_bottom.rgb, t);
	face = mix(face, vec3(1.0), (1.0 - smoothstep(0.05, 0.35, t)) * 0.22);
	col = mix(col, vec4(face, 1.0), inside);
	float rim = (1.0 - smoothstep(-1.0, 0.0, d)) * smoothstep(-5.0, -4.0, d);
	col = mix(col, vec4(edge.rgb * (0.8 + 0.4 * (1.0 - t)), 1.0), rim);
	COLOR = col;
}
