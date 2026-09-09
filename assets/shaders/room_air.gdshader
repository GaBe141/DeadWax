shader_type canvas_item;
render_mode blend_mix;
// A still sheet of light under the architecture. No screen sampling or TIME:
// the paper stays put while its separate woodcut layers carry the parallax.
uniform vec4 ink : source_color = vec4(0.15, 0.13, 0.12, 1.0);
uniform vec4 stock : source_color = vec4(0.91, 0.88, 0.80, 1.0);
uniform vec2 field_px = vec2(1800.0, 820.0);
uniform float warmth = 0.35;
uniform float depth = 0.0;

float tooth(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV;
	float edge = smoothstep(0.15, 0.70, abs(p.x - 0.5));
	float lower = smoothstep(0.22, 1.0, p.y);
	float light = exp(-dot((p - vec2(0.42, 0.20)) * vec2(1.9, 1.1),
		(p - vec2(0.42, 0.20)) * vec2(1.9, 1.1)) * 3.4);
	vec3 paper = mix(stock.rgb, ink.rgb, edge * 0.065 + lower * (0.075 + depth * 0.05));
	vec3 warm = mix(stock.rgb, vec3(1.0, 0.87, 0.64), warmth * 0.15);
	paper = mix(paper, warm, light * 0.65);
	vec2 px = p * field_px;
	float grain = (tooth(floor(px * 0.72)) - 0.5) * 0.016;
	// Fine fibre takes the place of large, repeating printer-guide squares.
	float fibre = (tooth(vec2(floor(px.y * 0.45), floor(px.x / 90.0))) - 0.5) * 0.008;
	COLOR = vec4(clamp(paper + grain + fibre, vec3(0.0), vec3(1.0)), 1.0);
}
