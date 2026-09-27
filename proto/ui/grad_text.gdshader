// A vertical gradient across a Label's text (gold numbers, lit titles). The
// outline stays dark because it is multiplied, not replaced.
shader_type canvas_item;

uniform vec4 top_c : source_color = vec4(1.0, 0.96, 0.7, 1.0);
uniform vec4 bottom_c : source_color = vec4(1.0, 0.68, 0.12, 1.0);
uniform float y0 = 0.0;
uniform float h = 32.0;
varying float ly;

void vertex() {
	ly = VERTEX.y;
}

void fragment() {
	float t = clamp((ly - y0) / h, 0.0, 1.0);
	COLOR = vec4(COLOR.rgb * mix(top_c.rgb, bottom_c.rgb, t), COLOR.a);
}
