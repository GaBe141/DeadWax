extends RefCounted
## Quiet canvas marks. All health, noise, timing and palette values arrive
## explicitly from Main; these marks own no gameplay state.

static func draw(canvas: CanvasItem, extent: Vector2, state: Dictionary, ink: Color, accent: Color) -> void:
	var edge := minf(12.0, extent.y * 0.018)
	canvas.draw_rect(Rect2(0, 0, extent.x, edge), Color(0.015, 0.022, 0.028, 0.7))
	canvas.draw_rect(Rect2(0, extent.y - edge, extent.x, edge), Color(0.015, 0.022, 0.028, 0.7))
	var health := int(state.get("health", 3))
	var maximum := int(state.get("max_health", 3))
	var origin := Vector2(30, 35)
	for index in maximum:
		var center := origin + Vector2(index * 18, 0)
		var diamond := PackedVector2Array([center + Vector2(0, -6), center + Vector2(4, 0), center + Vector2(0, 6), center + Vector2(-4, 0)])
		canvas.draw_colored_polygon(diamond, Color(ink, 0.85 if index < health else 0.12))
		canvas.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(ink, 0.42), 1.0, true)
	var noise := clampf(float(state.get("noise", 0.0)), 0.0, 1.0)
	if noise > 0.03:
		canvas.draw_line(Vector2(26, 55), Vector2(106, 55), Color(ink, 0.12), 2.0)
		canvas.draw_line(Vector2(26, 55), Vector2(26 + noise * 80, 55), Color(accent, 0.65), 2.0)
	if bool(state.get("b_side", false)):
		var ratio := clampf(float(state.get("runtime", 0.0)), 0.0, 1.0)
		var center := Vector2(extent.x - 37, 37)
		canvas.draw_arc(center, 13, -PI * 0.5, TAU - PI * 0.5, 40, Color(ink, 0.18), 1.5, true)
		canvas.draw_arc(center, 13, -PI * 0.5, -PI * 0.5 + TAU * ratio, 40, Color(accent if ratio < 0.25 else ink, 0.8), 2.0, true)
		canvas.draw_circle(center, 2.5, Color(ink, 0.8), true, -1, true)
	var title_alpha := float(state.get("title_alpha", 0.0))
	if title_alpha > 0.0:
		var y := extent.y * 0.36 + 58
		var half_width := minf(extent.x * 0.2, 210.0)
		canvas.draw_line(Vector2(extent.x * 0.5 - half_width, y), Vector2(extent.x * 0.5 + half_width, y), Color(ink, title_alpha * 0.42), 1.0, true)
