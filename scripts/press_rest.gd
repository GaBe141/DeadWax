extends RefCounted
## Matron's made bed: an iron frame, a quilt crocheted from tape ribbon, one
## pillow plumped for whoever comes next. Drawn from an explicit snapshot.
const Paint := preload("res://scripts/figure_paint.gd")

static func draw(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color, brass: Color) -> void:
	var paint := Paint.palette(ink, stock)
	var clock := float(pose.get("clock", 0.0))
	var near := bool(pose.get("near", false))
	var rested := clampf(float(pose.get("rested", 0.0)), 0.0, 1.0)
	var edge: Color = paint.edge
	var iron: Color = paint.shadow.lerp(ink, 0.2)
	# Feet, side rail and the two bed-ends of a narrow iron bed, foot to the left.
	for x: float in [-74.0, 70.0]:
		c.draw_line(Vector2(x, 26), Vector2(x, -4), iron, 4.0, true)
	c.draw_line(Vector2(-78, -4), Vector2(78, -4), iron, 5.0, true)
	for x: float in [-78.0, 78.0]:
		var top := -52.0 if x > 0 else -34.0
		c.draw_line(Vector2(x, 2), Vector2(x, top), iron, 4.0, true)
		c.draw_line(Vector2(x - 10, top), Vector2(x + 10, top), iron, 4.0, true)
		Paint.bolt(c, Vector2(x, top), 3.2, brass, edge, paint.light)
		for rail in range(2):
			var y := top + 12 + rail * 12
			c.draw_line(Vector2(x - 8, y), Vector2(x + 8, y), Color(iron, 0.8), 2.0, true)
	# The mattress and quilt. The quilt's ribbon rows are what her hands made.
	var quilt_lift := sin(clock * 0.7) * 0.4 + rested * 2.0
	Paint.shape(c, PackedVector2Array([Vector2(-72, -6), Vector2(72, -6), Vector2(74, -24 - quilt_lift), Vector2(-70, -22 - quilt_lift)]), paint.cream, edge, 1.6)
	var ribbon: Color = paint.copper.lerp(paint.wood, 0.3)
	for row in range(5):
		var y := -9.0 - row * 3.0 - quilt_lift * row / 5.0
		c.draw_line(Vector2(-66, y), Vector2(66, y + 0.6), Color(ribbon, 0.32 + (row % 2) * 0.14), 1.3, true)
	for stitch in range(9):
		var x := -60.0 + stitch * 15.0
		c.draw_line(Vector2(x, -8), Vector2(x + 2, -21 - quilt_lift), Color(paint.wax, 0.30), 1.0, true)
	c.draw_line(Vector2(-70, -22 - quilt_lift), Vector2(74, -24 - quilt_lift), paint.light, 1.2, true)
	# A turned-down sheet at the head, and a pillow plumped for the next guest.
	Paint.shape(c, PackedVector2Array([Vector2(30, -24 - quilt_lift), Vector2(72, -25 - quilt_lift), Vector2(70, -17), Vector2(34, -16)]), paint.light, edge, 1.2)
	var dent := rested * 3.0
	var pillow := PackedVector2Array([Vector2(36, -26 - quilt_lift), Vector2(70, -27 - quilt_lift), Vector2(72, -39 + dent), Vector2(54, -41 + dent * 1.4), Vector2(34, -38 + dent)])
	Paint.shape(c, pillow, paint.cream, edge, 1.4)
	c.draw_line(Vector2(40, -35 + dent), Vector2(66, -36 + dent), Color(paint.wax, 0.35), 1.0, true)
	if rested > 0.0:
		# The quilt settles after a guest; the only trace of a night here.
		c.draw_line(Vector2(-40, -22), Vector2(10, -23), Color(paint.wax, 0.45 * rested), 1.4, true)
	if near:
		# The brass bed-knobs catch whoever stands close.
		for x: float in [-78.0, 78.0]:
			var top := -52.0 if x > 0 else -34.0
			c.draw_arc(Vector2(x, top), 5.5, 0, TAU, 20, Color(brass, 0.55), 1.0, true)
	# A folded blanket at the foot and a hot-water bottle, radiator-warm.
	Paint.shape(c, PackedVector2Array([Vector2(-66, -27 - quilt_lift), Vector2(-34, -27 - quilt_lift), Vector2(-33, -33 - quilt_lift), Vector2(-66, -33 - quilt_lift)]), paint.teal, edge, 1.2)
	c.draw_line(Vector2(-62, -30 - quilt_lift), Vector2(-38, -30 - quilt_lift), Color(paint.light, 0.3), 1.0, true)
	Paint.disc(c, Vector2(-16, -31 - quilt_lift), 6.0, paint.copper, edge, paint.light, 0.95)
	c.draw_line(Vector2(-16, -37 - quilt_lift), Vector2(-16, -41 - quilt_lift), edge, 2.4, true)
	c.draw_line(Vector2(-19, -41 - quilt_lift), Vector2(-13, -41 - quilt_lift), brass, 2.0, true)
