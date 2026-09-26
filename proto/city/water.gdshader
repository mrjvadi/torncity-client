// Pools and the park lake: moving ripples and a sky-coloured sheen.
shader_type spatial;
uniform vec4 deep : source_color = vec4(0.10, 0.45, 0.62, 1.0);
uniform vec4 shallow : source_color = vec4(0.35, 0.85, 0.90, 1.0);
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float r = sin(wpos.x * 7.0 + TIME * 1.6) * sin(wpos.z * 6.0 - TIME * 1.3);
	vec3 c = mix(deep.rgb, shallow.rgb, 0.5 + 0.35 * r);
	ALBEDO = c;
	EMISSION = c * 0.25;
	ROUGHNESS = 0.08;
	METALLIC = 0.2;
}
