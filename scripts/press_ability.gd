extends RefCounted
## Small engraved sleeves for the recovered moves. Palette and pose arrive
## explicitly; the drawing has no permission, collision, or save state.

const BRASS := Color("d6b77c")

static func draw(canvas: CanvasItem, state: Dictionary, ink: Color, stock: Color) -> void:
	var available := bool(state.get("available", true))
	var near := bool(state.get("near", false))
	var bob := sin(float(state.get("clock", 0.0)) * 2.0) * 2.4
	var accent := BRASS if available else ink.lerp(stock, 0.55)
	canvas.draw_line(Vector2(-30, 25), Vector2(30, 25), Color(ink, 0.65), 2.0, true)
	canvas.draw_rect(Rect2(-27, 20, 54, 5), ink.lerp(stock, 0.3))
	canvas.draw_set_transform(Vector2(0, bob - 9))
	if available:
		for index in range(3, 0, -1):
			canvas.draw_circle(Vector2.ZERO, 30 + index * 6, Color(accent, 0.028), true, -1, true)
	canvas.draw_rect(Rect2(-27, -29, 54, 55), stock.lerp(ink, 0.1))
	canvas.draw_rect(Rect2(-27, -29, 54, 55), ink, false, 2.0)
	canvas.draw_line(Vector2(-22, -23), Vector2(22, -23), accent, 2.0, true)
	canvas.draw_line(Vector2(-20, 20), Vector2(20, 20), Color(ink, 0.45), 1.0, true)
	var kind := StringName(state.get("ability", &"strike"))
	match kind:
		&"strike":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-7, -16), Vector2(9, -13), Vector2(2, 15), Vector2(-3, 17)]), accent)
			canvas.draw_line(Vector2(-7, -16), Vector2(-3, 17), ink, 1.5, true)
			canvas.draw_line(Vector2(-16, 8), Vector2(-11, 3), ink, 1.5, true)
			canvas.draw_line(Vector2(11, 6), Vector2(17, 8), ink, 1.5, true)
		&"set":
			canvas.draw_circle(Vector2(0, -11), 5, accent, true, -1, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(0, -4), Vector2(-4, 5), Vector2(9, 8), Vector2(13, 15)]), ink, 3.0, true)
			canvas.draw_line(Vector2(-16, 15), Vector2(17, 15), accent, 2.0, true)
			canvas.draw_line(Vector2(-4, 5), Vector2(-12, 12), ink, 3.0, true)
		&"hood":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-19, 13), Vector2(-14, -6), Vector2(0, -17), Vector2(14, -6), Vector2(19, 13)]), ink)
			canvas.draw_arc(Vector2(0, 4), 12, PI, TAU, 24, accent, 3.0, true)
			canvas.draw_circle(Vector2(0, 5), 6, stock, true, -1, true)
		&"combo":
			for index in 3:
				var x := -14.0 + index * 14.0
				canvas.draw_line(Vector2(x, 10), Vector2(x + 4, -6 - index * 4), accent, 3.0, true)
			canvas.draw_arc(Vector2(0, -2), 22, 0.1, PI - 0.1, 24, ink, 1.5, true)
		&"groove":
			for index in 3:
				canvas.draw_arc(Vector2(0, 9), 7 + index * 6, PI + 0.2, TAU - 0.2, 28, ink, 1.5, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(-6, -7), Vector2(0, -15), Vector2(6, -7)]), accent, 3.0, true)
			canvas.draw_line(Vector2(0, -15), Vector2(0, 10), accent, 2.5, true)
		&"pogo":
			canvas.draw_polyline(PackedVector2Array([Vector2(-17, -13), Vector2(0, 12), Vector2(17, -13)]), accent, 3.0, true)
			canvas.draw_arc(Vector2(0, 14), 10, PI, TAU, 20, ink, 2.0, true)
			canvas.draw_line(Vector2(11, -12), Vector2(17, -13), accent, 3.0, true)
			canvas.draw_line(Vector2(17, -13), Vector2(18, -6), accent, 3.0, true)
	if not available:
		canvas.draw_line(Vector2(-25, -20), Vector2(25, 20), Color(accent, 0.65), 5.0, true)
	if near:
		canvas.draw_line(Vector2(-35, -9), Vector2(-31, -3), accent, 2.0, true)
		canvas.draw_line(Vector2(35, -9), Vector2(31, -3), accent, 2.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
