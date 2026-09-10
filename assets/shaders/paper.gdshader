shader_type canvas_item;
render_mode blend_mix;
// The sheet the whole game is printed on. Screen-space and static on
// purpose: paper does not swim when the camera pans, film grain does.

uniform vec4 tint : source_color = vec4(0.10, 0.09, 0.08, 1.0);
uniform float grain = 0.016;
uniform float vignette = 0.42;
uniform float vignette_start = 0.25;
uniform float paper_seed = 0.0;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7)) + paper_seed) * 43758.5453);
}

void fragment() {
	// Tooth: a fixed speckle keyed to the screen, not the world.
	float n = hash21(floor(FRAGCOORD.xy));
	float speck = (n - 0.5) * grain;

	// Broad, still shadow joins the scenery at the edges of the view. The
	// central play area stays clear; HUD and menus draw above this sheet.
	vec2 d = UV - vec2(0.5);
	d.x *= 1.10;
	float vig = smoothstep(vignette_start, 0.80, length(d)) * vignette;

	COLOR = vec4(tint.rgb * 0.30, clamp(vig + speck, 0.0, 1.0));
}
