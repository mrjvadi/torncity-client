// Frosted glass for panels over the city: the screen behind, blurred (mipmap
// LOD plus a small tap ring), tinted by the panel's own StyleBox colour.
// COLOR comes from the StyleBoxFlat (fill, border, antialiased edges), so the
// panel keeps its rounded shape and border.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod = 3.2;
uniform float tint = 0.58;        // 0 = clear glass, 1 = the StyleBox colour
uniform float spread = 7.0;       // tap distance, in screen pixels

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * spread;
	vec3 b = textureLod(screen_tex, SCREEN_UV, blur_lod).rgb * 0.36;
	b += textureLod(screen_tex, SCREEN_UV + vec2(px.x, 0.0), blur_lod).rgb * 0.16;
	b += textureLod(screen_tex, SCREEN_UV - vec2(px.x, 0.0), blur_lod).rgb * 0.16;
	b += textureLod(screen_tex, SCREEN_UV + vec2(0.0, px.y), blur_lod).rgb * 0.16;
	b += textureLod(screen_tex, SCREEN_UV - vec2(0.0, px.y), blur_lod).rgb * 0.16;
	// a faint top sheen
	float sheen = smoothstep(0.0, 0.35, 1.0 - UV.y) * 0.04;
	COLOR = vec4(mix(b, COLOR.rgb, tint) + sheen, COLOR.a);
}
