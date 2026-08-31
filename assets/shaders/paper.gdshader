shader_type canvas_item;
render_mode blend_mix;
// The sheet the whole game is printed on. Screen-space and static on
// purpose: paper does not swim when the camera pans, film grain does.

uniform vec4 tint : source_color = vec4(0.10, 0.09, 0.08, 1.0);
uniform float grain = 0.055;
uniform float vignette = 0.30;
uniform float vignette_start = 0.44;
uniform float paper_seed = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + paper_seed) * 43758.5453);
}

void fragment() {
	// Tooth: a fixed speckle keyed to the screen, not the world.
	float n = hash21(floor(FRAGCOORD.xy));
	float speck = (n - 0.5) * grain;

	// A soft press of shadow into the corners, as if the sheet is lit.
	vec2 d = UV - vec2(0.5);
	d.x *= 1.18;
	float vig = smoothstep(vignette_start, 0.86, length(d)) * vignette;

	COLOR = vec4(tint.rgb, clamp(vig + speck, 0.0, 1.0));
}
