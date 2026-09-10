extends RefCounted
## Small still lifes on the Bootlegger's velvet counter. Selection and palette
## arrive from the shop; these goods have no interactive geometry.
const BRASS := Color("d3a663")
const CREAM := Color("e7d5a9")
const TEAL := Color("24484d")
const NIGHT := Color("0b2029")

static func draw(canvas: CanvasItem, item_id: StringName, size: Vector2, ink: Color, stock: Color) -> void:
	if size.x < 1 or size.y < 1: return
	var center := size * 0.5
	var factor := minf(size.x / 330.0, size.y / 122.0)
	canvas.draw_set_transform(center, 0.0, Vector2.ONE * factor)
	canvas.draw_rect(Rect2(-154, -51, 308, 103), stock.lerp(NIGHT, 0.30))
	for row in range(16):
		var y := -49.0 + row * 6.5
		canvas.draw_line(Vector2(-151, y), Vector2(151, y + 2), Color(BRASS, 0.045), 2.2, true)
	canvas.draw_rect(Rect2(-151, -48, 302, 97), Color(BRASS, 0.35), false, 1)
	for radius in [55.0, 83.0, 113.0]:
		canvas.draw_arc(Vector2(0, 4), radius, 3.5, 5.9, 56, Color(BRASS, 0.09), 1.2, true)
	for ring in range(7, 0, -1):
		canvas.draw_set_transform(center + Vector2(0, 36) * factor, 0.0, Vector2(factor, factor * 0.16))
		canvas.draw_circle(Vector2.ZERO, 67 + ring * 5, Color(NIGHT, 0.07), true, -1, true)
	canvas.draw_set_transform(center, -0.045, Vector2.ONE * factor)
	match item_id:
		&"spare_groove":
			canvas.draw_rect(Rect2(-84, -36, 168, 77), NIGHT)
			canvas.draw_rect(Rect2(-82, -40, 164, 76), BRASS)
			canvas.draw_rect(Rect2(-78, -36, 156, 65), TEAL)
			canvas.draw_rect(Rect2(-71, -30, 142, 43), CREAM)
			canvas.draw_line(Vector2(-67, -25), Vector2(64, -25), Color("a7784b"), 2, true)
			for x in [-39.0, 39.0]:
				canvas.draw_circle(Vector2(x, -6), 20, NIGHT, true, -1, true)
				for radius in [11.0, 14.0, 17.0]:
					canvas.draw_arc(Vector2(x, -6), radius, 0, TAU, 42, Color(BRASS, 0.62), 1, true)
				canvas.draw_circle(Vector2(x, -6), 5, CREAM, true, -1, true)
				for tooth in range(6):
					var direction := Vector2.from_angle(tooth * TAU / 6)
					canvas.draw_line(Vector2(x, -6) + direction * 4, Vector2(x, -6) + direction * 8, BRASS, 2, true)
			canvas.draw_line(Vector2(-34, -6), Vector2(34, -6), Color(NIGHT, 0.36), 2, true)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-41, 24), Vector2(41, 24), Vector2(31, 34), Vector2(-31, 34)]), NIGHT)
			for corner in [Vector2(-72, -34), Vector2(72, -34), Vector2(-72, 28), Vector2(72, 28)]:
				canvas.draw_circle(corner, 2.4, CREAM, true, -1, true)
			canvas.draw_line(Vector2(-71, -38), Vector2(68, -38), Color(CREAM, 0.7), 1.3, true)
		&"soft_lining":
			var hood := PackedVector2Array([Vector2(-59, 34), Vector2(-39, -22), Vector2(-5, -48), Vector2(27, -17), Vector2(55, 35)])
			canvas.draw_colored_polygon(hood, Color("416467"))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-42, 29), Vector2(-28, -17), Vector2(-4, -33), Vector2(16, -12), Vector2(39, 29)]), NIGHT)
			canvas.draw_polyline(PackedVector2Array([Vector2(-59, 34), Vector2(-39, -22), Vector2(-5, -48), Vector2(27, -17)]), Color("8ca396"), 2.6, true)
			for fold in range(7):
				canvas.draw_line(Vector2(-31 + fold * 11, 27), Vector2(-10 + fold * 3, -25 + fold % 2 * 6), Color(CREAM, 0.11), 2, true)
			for stitch in range(10):
				var point := Vector2(-47 + stitch * 10, 32)
				canvas.draw_line(point, point + Vector2(3, -4), BRASS, 1.6, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(60, 15), Vector2(76, 12), Vector2(94, 19), Vector2(110, 15)]), Color(ink, 0.35), 1.4, true)
		&"warm_thread":
			canvas.draw_rect(Rect2(-51, -30, 88, 64), Color("8c503a"))
			for thread in range(20):
				var y := -28.0 + thread * 3.1
				canvas.draw_line(Vector2(-47, y), Vector2(33, y - 2), BRASS.lerp(CREAM, sin(thread * 1.8) * 0.22 + 0.12), 2.0, true)
			for y in [-36.0, 36.0]:
				canvas.draw_line(Vector2(-60, y + 3), Vector2(49, y + 3), NIGHT, 10, true)
				canvas.draw_line(Vector2(-60, y), Vector2(49, y), CREAM.lerp(BRASS, 0.40), 9, true)
				canvas.draw_line(Vector2(-56, y - 2), Vector2(44, y - 2), CREAM, 1.5, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(37, 23), Vector2(67, 39), Vector2(99, 31), Vector2(115, 4)]), BRASS, 2, true)
			canvas.draw_line(Vector2(110, -18), Vector2(120, 19), CREAM, 2.3, true)
			canvas.draw_arc(Vector2(110, -18), 2.5, 0, TAU, 16, BRASS, 1.1, true)
	canvas.draw_set_transform(Vector2.ZERO)
