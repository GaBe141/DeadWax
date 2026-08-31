shader_type canvas_item;
render_mode blend_mix;
// An inked plate. Ink is never perfectly laid down: pressure varies, the
// edge bites unevenly into the stock, and the second colour never quite
// registers with the first. All three are what stop a rectangle reading as
// a rectangle.

uniform vec4 ink : source_color = vec4(0.14, 0.13, 0.12, 1.0);
uniform vec4 stock : source_color = vec4(0.85, 0.83, 0.78, 1.0);
uniform vec4 accent : source_color = vec4(0.90, 0.25, 0.50, 1.0);
uniform vec2 plate_px = vec2(100.0, 100.0);
uniform vec2 misregister = vec2(2.0, -1.5);
uniform float bite = 2.4;        // how far the edge erodes, in px
uniform float tooth = 0.10;      // how much stock shows through the ink
uniform float fringe = 0.55;     // strength of the unregistered accent plate
uniform float plate_seed = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + plate_seed) * 43758.5453);
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

// Coverage of one plate at a pixel position, with a bitten edge.
float coverage(vec2 px, float erode) {
	vec2 d = min(px, plate_px - px);
	float edge = min(d.x, d.y);
	return smoothstep(-0.7, 1.0, edge + erode);
}

void fragment() {
	vec2 px = UV * plate_px;
	float erode = (vnoise(px * 0.34) - 0.5) * bite;

	float ink_a = coverage(px, erode);
	float acc_a = coverage(px - misregister, erode);

	// Uneven pressure: where the ink is thin, the stock reads through.
	float density = 1.0 - tooth * vnoise(px * 0.11 + 13.0);
	// Holidays: tiny spots the ink never took at all.
	density *= smoothstep(0.015, 0.075, vnoise(px * 1.35 + 51.0));

	vec3 inked = mix(stock.rgb, ink.rgb, density);
	vec3 col = mix(accent.rgb, inked, ink_a);
	float alpha = max(ink_a, acc_a * fringe);
	COLOR = vec4(col, alpha * ink.a);
}
