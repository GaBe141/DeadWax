shader_type canvas_item;
render_mode blend_mix, unshaded;
// A restrained transparent shaft sheet. The controller supplies its paused or
// frozen clock explicitly; this shader never advances its own presentation.
uniform vec4 ink : source_color = vec4(0.72, 0.64, 0.48, 1.0);
uniform vec4 stock : source_color = vec4(0.09, 0.17, 0.19, 1.0);
uniform vec4 accent : source_color = vec4(0.84, 0.72, 0.49, 1.0);
uniform vec2 field_px = vec2(2560.0, 720.0);
uniform float clock = 0.0;
uniform float motion = 1.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float shaft(vec2 px, vec2 source, float lean, float width) {
	float drop = max(0.0, px.y - source.y);
	float axis = source.x + drop * lean;
	float reach = width + drop * 0.28;
	float cross_section = exp(-pow((px.x - axis) / reach, 2.0) * 2.6);
	return cross_section * smoothstep(source.y - 5.0, source.y + 42.0, px.y)
		* (1.0 - smoothstep(510.0, 610.0, px.y));
}

void fragment() {
	vec2 px = UV * field_px;
	float west = shaft(px, vec2(900.0, 285.0), 0.17, 21.0);
	float center = shaft(px, vec2(1280.0, 225.0), -0.035, 37.0);
	float east = shaft(px, vec2(1660.0, 285.0), -0.17, 21.0);
	float beam = center * 0.035 + (west + east) * 0.020;
	vec3 cool = mix(ink.rgb, vec3(0.57, 0.72, 0.78), 0.60);
	vec3 warm = mix(ink.rgb, accent.rgb, 0.58);
	vec3 air = mix(cool, warm, center / max(0.001, center + west + east));
	// Sparse slow motes are local to the shafts. Static hash cells are broad
	// enough to stay inexpensive and avoid a crawling screen-grain overlay.
	vec2 grid = vec2(63.0, 87.0);
	vec2 cell = floor(px / grid);
	float seed = hash21(cell + vec2(7.0, 2.0));
	vec2 mote = vec2(0.13 + hash21(cell + vec2(1.0, 8.0)) * 0.74,
		fract(seed + clock * 0.014));
	mote.x += sin(clock * 0.19 + seed * 6.28) * 0.028;
	vec2 delta = (fract(px / grid) - mote) * grid;
	float dust = (1.0 - smoothstep(0.7, 1.9, length(delta)))
		* step(0.84, seed) * min(1.0, (west + center + east) * 1.7);
	float breathe = 1.0 + sin(clock * 0.34) * 0.018 * motion;
	float alpha = clamp(beam * breathe + dust * 0.17, 0.0, 0.18);
	COLOR = vec4(air, alpha);
}
