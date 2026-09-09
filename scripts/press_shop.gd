extends RefCounted
## Counter illustrations: the actual goods, engraved without product or state
## lookups. The shop supplies the chosen ID, sheet dimensions and palette.

static func draw(canvas: CanvasItem, item_id: StringName, size: Vector2, ink: Color, stock: Color) -> void:
	var center := size * 0.5
	var factor := minf(size.x / 330.0, size.y / 122.0)
	var amber := Color("b87a39")
	canvas.draw_set_transform(center, -0.025, Vector2.ONE * factor)
	canvas.draw_rect(Rect2(Vector2(-154.0, -51.0), Vector2(308.0, 103.0)), stock.lerp(ink, 0.07))
	canvas.draw_line(Vector2(-144.0, 44.0), Vector2(144.0, 44.0), Color(ink, 0.25), 1.0, true)
	match item_id:
		&"spare_groove":
			canvas.draw_set_transform(center, -0.065, Vector2.ONE * factor)
			canvas.draw_rect(Rect2(Vector2(-82.0, -39.0), Vector2(164.0, 76.0)), ink)
			canvas.draw_rect(Rect2(Vector2(-72.0, -29.0), Vector2(144.0, 47.0)), stock)
			for x in [-39.0, 39.0]:
				canvas.draw_circle(Vector2(x, -6.0), 19.0, ink, true, -1.0, true)
				canvas.draw_arc(Vector2(x, -6.0), 14.0, 0.0, TAU, 42, Color(stock, 0.6), 1.0, true)
				canvas.draw_circle(Vector2(x, -6.0), 5.0, stock, true, -1.0, true)
			canvas.draw_line(Vector2(-35.0, -6.0), Vector2(35.0, -6.0), Color(ink, 0.3), 2.0, true)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-41.0, 27.0), Vector2(41.0, 27.0), Vector2(31.0, 36.0), Vector2(-31.0, 36.0)]), stock)
			canvas.draw_line(Vector2(-59.0, -35.0), Vector2(9.0, -35.0), amber, 3.0, true)
		&"soft_lining":
			var hood := PackedVector2Array([Vector2(-59.0, 34.0), Vector2(-39.0, -22.0), Vector2(-5.0, -48.0), Vector2(27.0, -17.0), Vector2(55.0, 35.0)])
			canvas.draw_colored_polygon(hood, ink)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-42.0, 29.0), Vector2(-28.0, -17.0), Vector2(-4.0, -33.0), Vector2(16.0, -12.0), Vector2(39.0, 29.0)]), stock.lerp(ink, 0.43))
			for stitch in range(8):
				var point := Vector2(-38.0 + stitch * 10.0, 30.0)
				canvas.draw_line(point, point + Vector2(3.0, -4.0), stock, 1.8, true)
			canvas.draw_line(Vector2(65.0, 14.0), Vector2(92.0, 14.0), Color(ink, 0.4), 2.0, true)
			canvas.draw_line(Vector2(69.0, 25.0), Vector2(109.0, 25.0), Color(ink, 0.25), 2.0, true)
		&"warm_thread":
			canvas.draw_rect(Rect2(Vector2(-50.0, -32.0), Vector2(90.0, 63.0)), ink)
			canvas.draw_line(Vector2(-61.0, -36.0), Vector2(51.0, -36.0), ink, 10.0, true)
			canvas.draw_line(Vector2(-61.0, 36.0), Vector2(51.0, 36.0), ink, 10.0, true)
			for thread in range(13):
				var y := -28.0 + thread * 4.5
				canvas.draw_line(Vector2(-46.0, y), Vector2(36.0, y - 2.0), amber, 2.0, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(39.0, 21.0), Vector2(67.0, 38.0), Vector2(99.0, 31.0), Vector2(115.0, 4.0)]), amber, 2.0, true)
			canvas.draw_line(Vector2(111.0, -15.0), Vector2(120.0, 18.0), ink, 2.3, true)
	canvas.draw_set_transform(Vector2.ZERO)
