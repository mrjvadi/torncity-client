// Asphalt with a dashed centre line and solid edge lines, from the strip's
// own UVs (u across, v along, in world units).
shader_type spatial;
uniform vec4 asphalt : source_color = vec4(0.20, 0.21, 0.25, 1.0);
uniform vec4 paint : source_color = vec4(0.92, 0.88, 0.70, 1.0);
uniform float width = 1.4;
void fragment() {
	float u = UV.x * width;
	float v = UV.y;
	float centre = step(abs(u - width * 0.5), 0.025) * step(0.5, fract(v * 1.2));
	float edge = step(abs(u - 0.12), 0.02) + step(abs(u - (width - 0.12)), 0.02);
	vec3 c = mix(asphalt.rgb, paint.rgb, clamp(centre + edge, 0.0, 1.0));
	ALBEDO = c;
	ROUGHNESS = 0.9;
}
