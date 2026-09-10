extends RefCounted
## A small stone-and-brass doorway. Its fixed drawing bounds are the original
## passage marker's bounds; interaction still belongs entirely to RoomExit.
const Brush := preload("res://scripts/press_world_brush.gd")

static func draw(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var p := Brush.palette(ink, stock)
	var near := bool(pose.get("near", false))
	var locked := bool(pose.get("locked", false))
	var recess: Color = stock.lerp(p.shadow, 0.8)
	c.draw_circle(Vector2(0, -55), 23, recess, true, -1, true)
	c.draw_rect(Rect2(-23, -55, 46, 76), recess)
	# Rough outer voussoirs and a thin, burnished inner frame.
	Brush.ellipse(c, Vector2(0, -54), Vector2(26, 25), Brush.fade(p.edge, 0.90), 6, PI, TAU)
	Brush.ellipse(c, Vector2(0, -54), Vector2(23, 23), Brush.fade(p.gold, 0.70 if near else 0.42), 2, PI, TAU)
	for side in [-1.0, 1.0]:
		var x: float = side * 27
		Brush.line(c, Vector2(x, -53), Vector2(x, 19), Brush.fade(p.body, 0.98), 8)
		Brush.line(c, Vector2(x - side * 3, -53), Vector2(x - side * 3, 18), Brush.fade(p.gold, 0.69 if near else 0.39), 1.5)
		for row in range(4):
			var y := -41.0 + row * 17
			Brush.line(c, Vector2(x - 3, y), Vector2(x + 3, y - 1), Brush.fade(p.shadow, 0.72), 1)
	for i in range(7):
		var angle := PI + float(i) / 6 * PI
		Brush.line(c, Vector2(0, -54) + Vector2.from_angle(angle) * 24,
			Vector2(0, -54) + Vector2.from_angle(angle) * 29, Brush.fade(p.shadow, 0.72), 1.2)
	Brush.line(c, Vector2(-33, 21), Vector2(33, 21), p.copper, 4)
	Brush.line(c, Vector2(-30, 19), Vector2(30, 19), Brush.fade(p.gold, 0.79 if near else 0.40), 1.5)
	if locked:
		c.draw_rect(Rect2(-19, -48, 38, 66), Brush.fade(p.copper, 0.22))
		for side in [-1.0, 1.0]:
			Brush.line(c, Vector2(-17, -31 * side - 17), Vector2(17, 31 * side - 17), Brush.fade(p.copper, 0.84), 4)
		Brush.ellipse(c, Vector2(0, -18), Vector2(7, 8), p.gold, 2)
		c.draw_circle(Vector2(0, -19), 2.2, p.shadow, true, -1, true)
		Brush.line(c, Vector2(0, -18), Vector2(0, -13), p.shadow, 2)
	else:
		# The warm reveal is steady. Nearness changes exposure, never its clock.
		c.draw_rect(Rect2(-17, -50, 34, 65), Brush.fade(p.gold, 0.09 if near else 0.035))
		Brush.wash(c, PackedVector2Array([Vector2(-20, -51), Vector2(-11, -46), Vector2(-11, 13), Vector2(-20, 18)]), Brush.fade(p.copper, 0.68))
		Brush.line(c, Vector2(-12, -43), Vector2(-12, 11), Brush.fade(p.gold, 0.64), 1)
		Brush.curve(c, Vector2(2, -46), Vector2(16, -30), Vector2(3, -12), Brush.fade(p.gold, 0.57 if near else 0.29), 1.2)
		Brush.line(c, Vector2(2, -12), Vector2(10, -15), Brush.fade(p.gold, 0.65), 1.6)
	c.draw_set_transform(Vector2.ZERO)
