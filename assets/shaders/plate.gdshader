shader_type canvas_item;
render_mode blend_mix;
// A hand-painted cutaway of layered wax and aged stone. Its narrow upper
// lip follows the exact walkable rectangle; brushwork stays inside the face.

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
	float light_ink = step(dot(stock.rgb, vec3(0.2126, 0.7152, 0.0722)), dot(ink.rgb, vec3(0.2126, 0.7152, 0.0722)));
	vec3 shadow = mix(ink.rgb, stock.rgb, light_ink);
	vec3 light = mix(stock.rgb, ink.rgb, light_ink);
	float brush = vnoise(px * vec2(0.024, 0.16));
	float grain = vnoise(px * 0.77) - 0.5;
	float wash = exp(-px.y / 32.0);
	vec3 face = mix(shadow * 0.63, light, 0.085 + brush * 0.11 + wash * 0.08);
	face += grain * tooth * 0.17;
	// Uneven, staggered mason's joints follow the material, not a screen grid.
	float row = floor(px.y / 43.0);
	float joint_x = mod(px.x + row * 61.0 + plate_seed * 19.0, 138.0);
	float joint_y = mod(px.y + vnoise(vec2(px.x * 0.035, row)) * 3.0, 43.0);
	float joint = (1.0 - smoothstep(0.0, 1.6, min(joint_x, joint_y))) * smoothstep(7.0, 13.0, px.y);
	face = mix(face, shadow * 0.40, joint * 0.60);
	float strata = sin(px.y * 0.8 + vnoise(px * 0.04) * 3.0) * 0.009;
	face += strata;
	float lip = 1.0 - smoothstep(2.0, 5.5, px.y);
	vec3 rim = mix(light, vec3(0.84, 0.70, 0.46), 0.28) * (0.91 + brush * 0.09);
	face = mix(face, rim, lip);
	float erode = (vnoise(px * 0.34) - 0.5) * bite * smoothstep(2.0, 7.0, px.y);
	float alpha = coverage(px, erode);
	COLOR = vec4(face, alpha * ink.a);
}
