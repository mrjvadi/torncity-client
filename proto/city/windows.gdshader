// Tower facades at dusk: a grid of windows in world space, some lit warm,
// some dark, some cool; frames between them in the wall colour. Roofs (faces
// pointing up) stay plain.
shader_type spatial;

uniform vec4 wall : source_color = vec4(0.55, 0.58, 0.72, 1.0);
uniform vec4 glass : source_color = vec4(0.12, 0.16, 0.28, 1.0);
uniform vec4 lit : source_color = vec4(1.0, 0.78, 0.45, 1.0);
uniform float lit_share = 0.45;
uniform float floor_h = 0.28;
uniform float bay_w = 0.24;
uniform float seed = 0.0;
varying vec3 wpos;
varying vec3 wnorm;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed * 17.0) * 43758.5453); }

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = wall.rgb;
	float em = 0.0;
	if (abs(wnorm.y) < 0.5) {
		float u = abs(wnorm.x) > 0.5 ? wpos.z : wpos.x;
		vec2 cell = vec2(u / bay_w, wpos.y / floor_h);
		vec2 f = fract(cell);
		float win = step(0.18, f.x) * step(f.x, 0.82) * step(0.25, f.y) * step(f.y, 0.8);
		float h = hash(floor(cell) + floor(wpos.xz * 0.3));
		vec3 g = glass.rgb;
		if (h < lit_share) { g = lit.rgb * (0.7 + 0.5 * h / lit_share); em = win * 1.4; }
		else if (h > 0.9) { g = vec3(0.45, 0.7, 1.0) * 0.8; em = win * 0.6; }
		c = mix(c, g, win);
		// a lighter band at each floor slab
		c = mix(c, wall.rgb * 1.15, step(f.y, 0.06));
	}
	ALBEDO = c;
	EMISSION = c * em;
	ROUGHNESS = 0.7;
}
