extends RefCounted
## The Press's HUSH figure: a tall, pale sleeve, a measuring arm, no hot ink.
## Pose numbers and progress arrive as values; this renderer reads no state.

static func draw(
	canvas: CanvasItem, pose: int, ticks: int, parries: int, face: float,
	time: float, ink: Color, stock: Color
) -> void:
	var pale := stock.lightened(0.07)
	var faded := ink.lerp(stock, 0.48)
	if pose == 5:
		canvas.draw_colored_polygon(PackedVector2Array([
			Vector2(-45, 39), Vector2(-23, -13), Vector2(6, -25), Vector2(44, 39),
		]), ink)
		canvas.draw_line(Vector2(-49, 40), Vector2(55, 40), faded, 3.0, true)
		canvas.draw_arc(Vector2(8, -21), 22, 0.2, PI - 0.2, 24, pale, 2.0, true)
		canvas.draw_line(Vector2(20, -4), Vector2(79, 35), faded, 4.0, true)
		return
	var sway := sin(time * 2.0) * 1.6
	var head := Vector2(sway, -83)
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(-37, 40), Vector2(-26, -45), head + Vector2(-15, -4),
		head + Vector2(14, -5), Vector2(31, -45), Vector2(45, 40),
	]), ink)
	canvas.draw_polyline(PackedVector2Array([
		Vector2(-36, 40), Vector2(-21, -45), head + Vector2(0, -14),
		Vector2(27, -45), Vector2(43, 40),
	]), faded, 2.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-16, 3), head + Vector2(0, -15), head + Vector2(17, 4),
		head + Vector2(10, 17), head + Vector2(-10, 17),
	]), pale)
	canvas.draw_line(head + Vector2(-6, 6), head + Vector2(8, 6), ink, 2.0, true)
	canvas.draw_line(Vector2(-12, -30), Vector2(-20, 36), faded, 2.0, true)
	canvas.draw_line(Vector2(12, -30), Vector2(29, 36), faded, 2.0, true)
	var hand := Vector2(face * 47, -8)
	if pose == 3:
		hand = Vector2(face * 124, -29)
	elif pose == 2 and ticks >= 3:
		hand = Vector2(-face * 66, -72)
	elif pose == 4:
		hand = Vector2(-face * 76, -40)
	canvas.draw_line(Vector2(face * 17, -49), hand, pale, 5.0, true)
	canvas.draw_line(hand, hand + Vector2(face * 23, -20), faded, 3.0, true)
	for index in range(3):
		var mark := Vector2(-19 + index * 19, -126)
		var color := pale if index < parries else faded
		canvas.draw_arc(mark, 5.0, 0, TAU, 16, color, 2.0, true)
		if pose == 2 and index < ticks:
			canvas.draw_line(mark + Vector2(0, -15), mark + Vector2(0, -8), ink, 3.0, true)
