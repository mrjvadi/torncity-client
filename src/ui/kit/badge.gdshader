// An icon badge: a disc (or rounded square) with a lit gradient in its tint,
// a metallic rim, a glossy cap, and the glyph (a white SVG) with a small drop
// shadow. Put it on a TextureRect whose texture is the glyph.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.18, 0.76, 0.70, 1.0);
uniform vec4 rim : source_color = vec4(0.96, 0.76, 0.34, 1.0);
uniform float rim_w = 0.06;       // of the badge's size
uniform float icon_scale = 0.56;
uniform float square = 0.0;       // 0 = disc, 1 = rounded square
uniform float dim = 0.0;          // 1 = inactive, desaturated
uniform vec4 glyph_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float sd_rrect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV - 0.5;
	float d = mix(length(p) - 0.46, sd_rrect(p, vec2(0.44), 0.14), square);
	float aa = fwidth(d) * 1.2;
	float body = 1.0 - smoothstep(-aa, aa, d);
	float t = UV.y;
	vec3 base = mix(tint.rgb * 1.25 + 0.08, tint.rgb * 0.55, smoothstep(0.1, 0.95, t));
	vec2 lp = p - vec2(-0.12, -0.16);
	base += vec3(0.18) * (1.0 - smoothstep(0.0, 0.42, length(lp)));
	vec4 col = vec4(base, body);
	float ring = smoothstep(-rim_w - aa, -rim_w + aa, d) * body;
	vec3 metal = rim.rgb * (0.7 + 0.6 * (1.0 - t));
	col.rgb = mix(col.rgb, metal, ring * rim.a);
	// glyph with a drop shadow
	vec2 iu = (UV - 0.5) / icon_scale + 0.5;
	vec2 su = (UV - 0.5 - vec2(0.0, 0.025)) / icon_scale + 0.5;
	float inb = step(0.0, iu.x) * step(iu.x, 1.0) * step(0.0, iu.y) * step(iu.y, 1.0);
	float sib = step(0.0, su.x) * step(su.x, 1.0) * step(0.0, su.y) * step(su.y, 1.0);
	float ga = texture(TEXTURE, iu).a * inb;
	float sa = texture(TEXTURE, su).a * sib;
	col.rgb = mix(col.rgb, col.rgb * 0.35, sa * 0.7 * body);
	col.rgb = mix(col.rgb, glyph_color.rgb, ga * body);
	// glossy cap
	float cap = (1.0 - smoothstep(0.0, 0.02, length((p - vec2(0.0, -0.2)) * vec2(1.0, 1.9)) - 0.3)) * body;
	col.rgb = mix(col.rgb, vec3(1.0), cap * 0.18);
	float grey = dot(col.rgb, vec3(0.3, 0.59, 0.11));
	col.rgb = mix(col.rgb, vec3(grey) * 0.7, dim);
	COLOR = col;
}
