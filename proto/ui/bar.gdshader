// A resource bar: a sunken capsule track and a lit fill that runs from the
// reading start (the right in Persian), with a shine sweeping across it and
// a bright cap at its end. `full` makes the whole bar breathe.
shader_type canvas_item;

uniform vec2 size = vec2(200.0, 28.0);
uniform float value = 0.5;
uniform vec4 fill : source_color = vec4(0.95, 0.70, 0.20, 1.0);
uniform vec4 track : source_color = vec4(0.02, 0.03, 0.07, 0.9);
uniform vec4 outline : source_color = vec4(0.0, 0.0, 0.0, 0.85);
uniform float rtl = 1.0;
uniform float full = 0.0;
uniform float speed = 0.35;

float sd_rrect(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = (UV - 0.5) * size;
	vec2 b = size * 0.5 - vec2(1.5);
	float r = b.y;
	float d = sd_rrect(p, b, r);
	vec4 col = vec4(outline.rgb, outline.a * (1.0 - smoothstep(0.5, 1.5, d)));
	float inside = 1.0 - smoothstep(-2.5, -1.5, d);
	float t = UV.y;
	vec3 tr = track.rgb + vec3(0.05) * t;
	col = mix(col, vec4(tr, track.a), inside);
	// fill region, measured from the reading start
	float x = mix(UV.x, 1.0 - UV.x, rtl);
	float edge = x * size.x;
	float filled = 1.0 - smoothstep(value * size.x - 1.0, value * size.x, edge);
	vec3 f = mix(fill.rgb * 1.35 + 0.06, fill.rgb * 0.8, smoothstep(0.15, 0.9, t));
	f = mix(f, vec3(1.0), (1.0 - smoothstep(0.1, 0.4, t)) * 0.28);
	float sweep = fract(TIME * speed);
	float sh = 1.0 - smoothstep(0.0, 0.06, abs(x - sweep * 1.4 + 0.2));
	f += vec3(0.35) * sh;
	float cap = 1.0 - smoothstep(0.0, 6.0, abs(edge - value * size.x));
	f += fill.rgb * cap * 0.5;
	float breathe = full * (0.5 + 0.5 * sin(TIME * 4.0));
	f += fill.rgb * breathe * 0.25;
	float in_fill = inside * filled * (1.0 - smoothstep(-3.0, -2.0, d));
	col = mix(col, vec4(f, 1.0), in_fill);
	COLOR = col;
}
