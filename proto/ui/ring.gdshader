// A progress ring for timers (clockwise from the top in every language: a
// clock is never mirrored), with a dark groove and a glowing head.
shader_type canvas_item;

uniform float value = 0.4;
uniform vec4 color : source_color = vec4(0.17, 0.77, 0.70, 1.0);
uniform float width = 0.1;

void fragment() {
	vec2 p = UV - 0.5;
	float rad = length(p);
	float ring = 1.0 - smoothstep(0.0, 0.012, abs(rad - (0.5 - width)) - width * 0.5);
	float a = atan(p.x, -p.y) / 6.28318 + 0.5;
	a = fract(a + 0.5);
	float on = step(a, value);
	vec4 col = vec4(0.02, 0.03, 0.08, 0.85 * ring);
	col = mix(col, vec4(color.rgb * 1.2, 1.0), ring * on);
	float head = 1.0 - smoothstep(0.0, 0.08, abs(a - value));
	col.rgb += color.rgb * head * ring * 0.6;
	COLOR = col;
}
