shader_type canvas_item;
render_mode blend_mix;
// The tint block behind a room: a halftone screen laid down in the same ink,
// far too faint to read as pattern, just enough that the space behind the
// platforms stops being a void. World-space, so it belongs to the room.

uniform vec4 ink : source_color = vec4(0.14, 0.13, 0.12, 1.0);
uniform vec2 field_px = vec2(2000.0, 1000.0);
uniform float cell = 9.0;       // halftone screen pitch, in px
uniform float dot_max = 0.40;    // largest dot radius as a fraction of the cell
uniform float strength = 0.05;  // overall tint weight
uniform float rule_every = 320.0; // faint horizontal rules, print-guide style
uniform float rule_strength = 0.032;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
		mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec2 px = UV * field_px;

	// Screen angled off-axis, the way a real halftone is, so it never moires
	// against the platform edges.
	float a = 0.3665;
	vec2 rot = vec2(px.x * cos(a) - px.y * sin(a), px.x * sin(a) + px.y * cos(a));
	vec2 cellv = fract(rot / cell) - 0.5;

	// Dot size drifts, so the tint breathes instead of tiling.
	float drift = vnoise(px * 0.0035);
	float radius = cell * dot_max * (0.45 + 0.85 * drift);
	float d = length(cellv * cell);
	float dots = 1.0 - smoothstep(radius - 0.8, radius + 0.8, d);

	// Printer's guide rules.
	float rule = 1.0 - smoothstep(0.0, 1.6, abs(fract(px.y / rule_every) - 0.5) * rule_every);

	float amount = dots * strength + rule * rule_strength;
	COLOR = vec4(ink.rgb, clamp(amount, 0.0, 1.0));
}
