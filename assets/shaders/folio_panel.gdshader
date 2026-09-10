shader_type canvas_item;
render_mode blend_mix;
// A restrained waxed-cloth page, with a fine brass inlay and rubbed edges.
uniform vec4 ink : source_color;
uniform vec4 stock : source_color;
uniform vec4 brass : source_color;
uniform vec2 panel_px = vec2(600.0, 80.0);

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 px = UV * panel_px;
	vec2 edge = min(px, panel_px - px);
	float rim = min(edge.x, edge.y);
	float tooth = grain(floor(px * 0.8)) - 0.5;
	float fibres = sin(px.y * 1.3 + sin(px.x * 0.025) * 1.6) * 0.003;
	vec3 base = mix(stock.rgb, ink.rgb, 0.045 + tooth * 0.018 + fibres);
	float inset = (1.0 - smoothstep(0.0, 1.0, abs(rim - 3.5))) * 0.28;
	float corners = (1.0 - smoothstep(14.0, 22.0, max(edge.x, edge.y))) * (1.0 - smoothstep(0.4, 1.8, abs(rim - 6.0)));
	base = mix(base, brass.rgb, max(inset, corners * 0.65));
	base = mix(base, stock.rgb * 0.70, (1.0 - smoothstep(0.0, 3.0, rim)) * 0.4);
	COLOR = vec4(base, stock.a);
}
