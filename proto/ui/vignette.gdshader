// A cinematic vignette and a whisper of warm/cool grading over the world.
shader_type canvas_item;
uniform float strength = 0.55;
void fragment() {
	vec2 p = UV - 0.5;
	float v = smoothstep(0.35, 0.85, length(p * vec2(1.0, 0.8)));
	COLOR = vec4(0.02, 0.02, 0.08, v * strength);
}
