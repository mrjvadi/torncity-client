// Turns a flat glyph (a white SVG on transparency) into a raised, lit,
// glossy object: the glyph's blurred alpha is a height field, its slope a
// normal, lit from the top left with a diffuse term, a sharp specular and a
// rim; a dark outline and a soft drop shadow sit it on the screen. The
// material picks the palette (gold, ruby, emerald...). In the real game this
// would be baked once per icon into a texture; here it runs live.
shader_type canvas_item;

uniform vec4 light_c : source_color = vec4(1.0, 0.92, 0.55, 1.0);
uniform vec4 dark_c : source_color = vec4(0.72, 0.36, 0.02, 1.0);
uniform vec4 outline_c : source_color = vec4(0.10, 0.04, 0.0, 1.0);
uniform float bevel = 0.035;       // blur radius, in UV
uniform float outline_w = 0.022;   // in UV
uniform float spec = 0.9;
uniform float pad = 0.1;           // glyph inset inside the rect

float a_at(sampler2D tex, vec2 uv) {
	vec2 g = (uv - pad) / (1.0 - 2.0 * pad);
	if (g.x < 0.0 || g.y < 0.0 || g.x > 1.0 || g.y > 1.0) return 0.0;
	return texture(tex, g).a;
}

float height(sampler2D tex, vec2 uv) {
	float h = a_at(tex, uv) * 0.2;
	for (int i = 0; i < 8; i++) {
		float an = float(i) * 0.785398;
		vec2 o = vec2(cos(an), sin(an));
		h += a_at(tex, uv + o * bevel) * 0.07;
		h += a_at(tex, uv + o * bevel * 0.5) * 0.03;
	}
	return h;
}

void fragment() {
	float a = a_at(TEXTURE, UV);
	// outline: the glyph grown by outline_w
	float grown = a;
	float sh = 0.0;
	for (int i = 0; i < 12; i++) {
		float an = float(i) * 0.5236;
		vec2 o = vec2(cos(an), sin(an));
		grown = max(grown, a_at(TEXTURE, UV + o * outline_w));
		sh = max(sh, a_at(TEXTURE, UV - vec2(0.0, 0.05) + o * outline_w * 1.4));
	}
	vec4 col = vec4(0.0, 0.0, 0.0, sh * 0.45);
	col = mix(col, outline_c, grown);
	if (a > 0.001) {
		vec2 e = vec2(bevel * 0.5, 0.0);
		float hx = height(TEXTURE, UV + e.xy) - height(TEXTURE, UV - e.xy);
		float hy = height(TEXTURE, UV + e.yx) - height(TEXTURE, UV - e.yx);
		vec3 n = normalize(vec3(-hx, -hy, 0.12));
		vec3 L = normalize(vec3(-0.5, -0.7, 0.8));
		float diff = clamp(dot(n, L), 0.0, 1.0);
		vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
		float s = pow(clamp(dot(n, H), 0.0, 1.0), 40.0) * spec;
		float t = clamp((UV.y - pad) / (1.0 - 2.0 * pad), 0.0, 1.0);
		vec3 base = mix(light_c.rgb, dark_c.rgb, smoothstep(0.2, 1.05, t));
		vec3 c = base * (0.72 + 0.5 * diff) + vec3(s);
		// a soft top gloss band, like lacquer
		c = mix(c, vec3(1.0), (1.0 - smoothstep(0.05, 0.4, t)) * 0.18);
		col = mix(col, vec4(c, 1.0), a);
	}
	COLOR = col;
}
