shader_type canvas_item;
render_mode blend_mix;
// Local relief on actual campaign faces. Every texture comes from this plate's
// UVs; native room lights shade the surface without a screen or normal read.
uniform vec4 ink : source_color = vec4(0.72, 0.64, 0.48, 1.0);
uniform vec4 stock : source_color = vec4(0.09, 0.17, 0.19, 1.0);
uniform vec4 accent : source_color = vec4(0.90, 0.55, 0.45, 1.0);
uniform vec2 plate_px = vec2(100.0, 100.0);
uniform float plate_seed = 0.0;
uniform int material_kind = 0; // 0: cut stone, 1: wax, 2: worn brass

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + plate_seed) * 43758.5453);
}

float wash(vec2 p) {
	vec2 cell = floor(p);
	vec2 part = fract(p);
	part = part * part * (3.0 - 2.0 * part);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), part.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), part.x), part.y);
}

void fragment() {
	vec2 px = UV * plate_px;
	float reversed = step(dot(stock.rgb, vec3(0.2126, 0.7152, 0.0722)),
		dot(ink.rgb, vec3(0.2126, 0.7152, 0.0722)));
	vec3 dark = mix(ink.rgb, stock.rgb, reversed);
	vec3 pale = mix(stock.rgb, ink.rgb, reversed);
	float wax = float(material_kind == 1);
	float brass = float(material_kind == 2);
	float broad = wash(px * vec2(0.012, 0.022));
	float dragged = wash(px * vec2(0.036, 0.094));
	float fine = hash21(floor(px * 0.61)) - 0.5;
	float top_wash = exp(-px.y / 29.0);
	vec3 face = mix(dark * (0.68 + broad * 0.065), pale,
		0.074 + dragged * 0.050 + top_wash * 0.047 + wax * 0.014);
	vec3 metal = mix(dark * 0.75, mix(pale, vec3(0.73, 0.57, 0.32), 0.33),
		0.115 + broad * 0.055 + dragged * 0.025);
	face = mix(face, metal, brass);
	face += fine * 0.006;
	// Coarse wear has no tiled mortar grid. Wax sags; stone has broad seams;
	// brass is brushed along its face. Fine grain stays below silhouette scale.
	float wax_fold = sin(px.y * 0.050 + broad * 3.2);
	float stone_cut = sin(px.y * 0.067 + wash(vec2(px.x * 0.010, 1.7)) * 5.0);
	float scar = pow(max(0.0, mix(stone_cut, wax_fold, wax)), 9.0)
		* smoothstep(12.0, 27.0, px.y);
	face = mix(face, dark * 0.60, scar * (0.085 + wax * 0.035) * (1.0 - brass));
	float polish = exp(-px.y / 30.0) * smoothstep(7.0, 13.0, px.y)
		* (0.35 + broad * 0.65);
	face += mix(pale, accent.rgb, 0.18) * polish * (0.019 + wax * 0.016 + brass * 0.024);
	// The narrow upper lip registers exactly to the real rectangle. Its
	// uninterrupted highlight protects small ledges under dim and B palettes.
	float lip = 1.0 - smoothstep(2.0, 5.1, px.y);
	vec3 rim = mix(pale, vec3(0.84, 0.70, 0.46), 0.22 + brass * 0.13)
		* (0.90 + broad * 0.075);
	face = mix(face, rim, lip);
	float deep = smoothstep(0.58, 1.0, UV.y) * smoothstep(30.0, 90.0, plate_px.y);
	face = mix(face, stock.rgb, deep * 0.16);
	float relief_x = sin(px.x * (0.028 - wax * 0.008) + broad * 3.2)
		* (0.060 - wax * 0.018 - brass * 0.022);
	float relief_y = cos(px.y * (0.066 - wax * 0.027) + dragged * 2.1)
		* (0.071 - wax * 0.022 - brass * 0.022);
	NORMAL = normalize(vec3(relief_x, relief_y, 1.0));
	COLOR = vec4(clamp(face, vec3(0.0), vec3(1.0)), ink.a);
}
