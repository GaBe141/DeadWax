shader_type canvas_item;
render_mode blend_mix, unshaded;
// Transparent fixed-world light shafts. The supplied clock freezes with the
// room; no shader time, screen sampling, camera shift or backbuffer is used.
uniform vec4 ink : source_color = vec4(0.72, 0.64, 0.48, 1.0);
uniform vec4 stock : source_color = vec4(0.09, 0.17, 0.19, 1.0);
uniform vec4 accent : source_color = vec4(0.84, 0.72, 0.49, 1.0);
uniform vec2 field_px = vec2(1800.0, 820.0);
uniform vec2 field_origin = vec2(0.0);
uniform float clock = 0.0;
uniform float motion = 1.0;
uniform int source_count = 0;
// Position, unstretched native radius, effective native energy.
uniform vec4 source0 = vec4(0.0);
uniform vec4 source1 = vec4(0.0);
uniform vec4 source2 = vec4(0.0);
uniform vec4 source3 = vec4(0.0);
uniform vec4 source_color0 : source_color = vec4(1.0);
uniform vec4 source_color1 : source_color = vec4(1.0);
uniform vec4 source_color2 : source_color = vec4(1.0);
uniform vec4 source_color3 : source_color = vec4(1.0);
uniform float source_lean0 = 0.0;
uniform float source_lean1 = 0.0;
uniform float source_lean2 = 0.0;
uniform float source_lean3 = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float shaft(vec2 px, vec4 source, float lean) {
	float reach = max(1.0, source.z * 0.92);
	float drop = px.y - source.y;
	float axis = source.x + max(0.0, drop) * lean;
	float width = max(14.0, source.z * 0.050) + max(0.0, drop) * 0.19;
	float cone = exp(-pow((px.x - axis) / width, 2.0) * 2.2);
	return cone * smoothstep(-3.0, 32.0, drop)
		* (1.0 - smoothstep(reach * 0.52, reach, drop))
		* clamp(source.w / 0.36, 0.0, 1.4);
}

void fragment() {
	vec2 px = UV * field_px + field_origin;
	float a = source_count > 0 ? shaft(px, source0, source_lean0) : 0.0;
	float b = source_count > 1 ? shaft(px, source1, source_lean1) : 0.0;
	float c = source_count > 2 ? shaft(px, source2, source_lean2) : 0.0;
	float d = source_count > 3 ? shaft(px, source3, source_lean3) : 0.0;
	float spill = a + b + c + d;
	vec3 tint = (source_color0.rgb * a + source_color1.rgb * b
		+ source_color2.rgb * c + source_color3.rgb * d) / max(0.001, spill);
	vec3 air = mix(mix(ink.rgb, accent.rgb, 0.22), tint, 0.55);
	// A few slow motes appear only within light. Sparse broad cells avoid a
	// moving screen-grain overlay or interference with an encounter's tells.
	vec2 grid = vec2(71.0, 93.0);
	vec2 cell = floor(px / grid);
	float seed = hash21(cell + vec2(7.0, 2.0));
	vec2 mote = vec2(0.16 + hash21(cell + vec2(1.0, 8.0)) * 0.68,
		fract(seed + clock * 0.011));
	mote.x += sin(clock * 0.17 + seed * 6.28) * 0.022;
	vec2 delta = (fract(px / grid) - mote) * grid;
	float dust = (1.0 - smoothstep(0.7, 1.8, length(delta)))
		* step(0.86, seed) * min(1.0, spill * 1.6);
	float breath = 1.0 + sin(clock * 0.28) * 0.012 * motion;
	float alpha = clamp(spill * 0.029 * breath + dust * 0.12, 0.0, 0.14);
	COLOR = vec4(air, alpha);
}
