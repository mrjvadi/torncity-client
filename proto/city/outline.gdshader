// The selected building: drawn again slightly grown, back faces only, in a
// pulsing gold, so it reads as an outline around the model.
shader_type spatial;
render_mode unshaded, cull_front;
uniform vec4 color : source_color = vec4(1.0, 0.82, 0.3, 1.0);
uniform float grow = 0.05;
void vertex() { VERTEX += NORMAL * grow * (1.0 + 0.25 * sin(TIME * 5.0)); }
void fragment() {
	ALBEDO = color.rgb;
	EMISSION = color.rgb * (0.8 + 0.4 * sin(TIME * 5.0));
}
