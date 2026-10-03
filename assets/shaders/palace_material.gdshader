shader_type canvas_item;
render_mode blend_mix;
// Local material relief, never a post-process. Native room lamps shade this
// face; its lip is registered to the existing platform rather than the camera.
uniform vec4 ink : source_color = vec4(0.72, 0.64, 0.48, 1.0);
uniform vec4 stock : source_color = vec4(0.09, 0.17, 0.19, 1.0);
uniform vec4 accent : source_color = vec4(0.84, 0.72, 0.49, 1.0);
uniform vec2 surface_px = vec2(100.0, 100.0);
uniform int material_kind = 0; // 0: stone, 1: wax, 2: the actual arena floor

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float wash(vec2 p) {
	vec2 cell = floor(p);
	vec2 part = fract(p);
	part = part * part * (3.0 - 2.0 * part);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), part.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0)), part.x), part.y);
}

void fragment() {
	vec2 px = UV * surface_px;
	float reversed = step(dot(stock.rgb, vec3(0.2126, 0.7152, 0.0722)),
		dot(ink.rgb, vec3(0.2126, 0.7152, 0.0722)));
	vec3 dark = mix(ink.rgb, stock.rgb, reversed);
	vec3 pale = mix(stock.rgb, ink.rgb, reversed);
	float broad = wash(px * vec2(0.011, 0.019));
	float dragged = wash(px * vec2(0.024, 0.080));
	float tooth = hash21(floor(px * 0.52)) - 0.5;
	float floor_face = float(material_kind == 2);
	float wax_face = float(material_kind == 1);
	vec3 face = mix(dark * (0.68 + broad * 0.12), pale,
		0.075 + dragged * 0.032 + wax_face * 0.018);
	face += tooth * 0.007;
	// Broad imperfect striations replace a tiled brick grid. They begin below
	// the functional top edge and remain much quieter than combat marks.
	float layer = sin(px.y * 0.052 + wash(vec2(px.x * 0.007, 1.9)) * 4.0);
	float strata = pow(max(0.0, layer), 8.0) * smoothstep(12.0, 25.0, px.y);
	face = mix(face, dark * 0.63, strata * (0.10 + wax_face * 0.06));
	// A damp, shallow sheen belongs entirely to the real floor cutaway. The
	// centre reflects warm brass; the two wide side pools stay cool and dim.
	float center = exp(-pow((UV.x - 0.5) * 7.5, 2.0));
	float side = exp(-pow((UV.x - 0.36) * 11.0, 2.0))
		+ exp(-pow((UV.x - 0.64) * 11.0, 2.0));
	float polish = exp(-px.y / 29.0) * smoothstep(7.0, 14.0, px.y)
		* (0.63 + dragged * 0.37) * floor_face;
	vec3 reflection = mix(pale, accent.rgb, 0.35) * center
		+ mix(pale, vec3(0.46, 0.63, 0.68), 0.32) * side * 0.38;
	face += reflection * polish * 0.065;
	float lip = 1.0 - smoothstep(1.0, 3.7, px.y);
	face = mix(face, mix(pale, accent.rgb, 0.16) * 0.82, lip * floor_face);
	float lower = smoothstep(0.48, 1.0, UV.y);
	face = mix(face, dark * 0.62, lower * floor_face * 0.22);
	// Low-frequency relief produces real changes under the native PointLights.
	// No normal texture, screen read, collider or world transform is involved.
	float relief_x = sin(px.x * 0.028 + broad * 3.0) * 0.045;
	float relief_y = cos(px.y * 0.054 + dragged * 2.0) * 0.050;
	NORMAL = normalize(vec3(relief_x, relief_y, 1.0));
	COLOR = vec4(clamp(face, vec3(0.0), vec3(1.0)), ink.a);
}
