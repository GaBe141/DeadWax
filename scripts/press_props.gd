extends RefCounted
## Small hand-painted objects. Geometry and clocks arrive from their owners.

static func draw_groove(canvas: CanvasItem, pose: Dictionary, ink: Color, wax: Color, brass: Color, accent: Color) -> void:
	var live: bool = pose.live
	var rim := brass if live else brass.lerp(ink, 0.55)
	var body := wax if live else wax.lerp(ink, 0.40)
	canvas.draw_rect(Rect2(-28, -28, 56, 56), ink)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-26,-26), Vector2(25,-26), Vector2(25,22), Vector2(20,26), Vector2(-26,26)]), rim)
	canvas.draw_rect(Rect2(-22, -22, 44, 44), body)
	canvas.draw_line(Vector2(-25,-25), Vector2(25,-25), wax, 2.0, true)
	canvas.draw_line(Vector2(25,-23), Vector2(25,24), ink.lightened(0.16), 3.0, true)
	canvas.draw_circle(Vector2.ZERO, 18, ink, true, -1.0, true)
	for index in 5:
		canvas.draw_arc(Vector2.ZERO, 7.0 + index * 2.2, 0, TAU, 44, Color(rim, 0.58), 0.8, true)
	canvas.draw_arc(Vector2.ZERO, 15.5, -2.55, -1.1, 18, Color(wax, 0.55 if live else 0.16), 2.0, true)
	canvas.draw_circle(Vector2.ZERO, 5, accent if live else rim, true, -1.0, true)
	canvas.draw_circle(Vector2.ZERO, 1.8, ink, true, -1.0, true)
	for point in [Vector2(-23,-23), Vector2(23,-23), Vector2(-23,23), Vector2(23,23)]:
		canvas.draw_circle(point, 1.6, ink, true, -1.0, true)
	if bool(pose.hot):
		canvas.draw_rect(Rect2(-28,-28,56,56), accent, false, 3.5)
	if float(pose.echo) >= 0.0:
		var progress: float = pose.echo
		var radius := 36.0 + (1.0 - progress) * 150.0
		canvas.draw_arc(Vector2.ZERO, radius, 0, TAU, 72, Color(accent, 0.25 + 0.75 * progress), 2.0 + 2.0 * progress, true)

static func draw_polish(canvas: CanvasItem, pose: Dictionary, ink: Color, brass: Color, wax: Color, accent: Color) -> void:
	var done: bool = pose.done
	canvas.draw_circle(Vector2(2,3), 28, Color(ink,0.64), true, -1.0, true)
	canvas.draw_circle(Vector2.ZERO, 26, brass.darkened(0.45) if done else ink.lerp(brass,0.25), true, -1.0, true)
	for index in 6:
		canvas.draw_arc(Vector2.ZERO, 9 + index * 3, 0, TAU, 44, Color(brass, 0.42 if done else 0.15), 1.0, true)
	canvas.draw_circle(Vector2.ZERO, 5, brass if done else brass.lerp(ink,0.45), true, -1.0, true)
	canvas.draw_circle(Vector2.ZERO, 1.6, ink, true, -1.0, true)
	if done:
		canvas.draw_arc(Vector2.ZERO, 25.5, -2.8, -0.6, 28, wax, 2, true)
		var sparkle: float = pose.sparkle
		for index in 5:
			var point := Vector2.from_angle(index * 2.39) * (24 + (1.0 - sparkle) * 13)
			canvas.draw_line(point - Vector2(4,0), point + Vector2(4,0), Color(wax,sparkle), 1.5, true)
			canvas.draw_line(point - Vector2(0,4), point + Vector2(0,4), Color(brass,sparkle), 1.5, true)
	else:
		for index in 8:
			var y := -20.0 + index * 5.5
			var span := sqrt(maxf(24 * 24 - y * y, 0))
			canvas.draw_line(Vector2(-span,y), Vector2(span,y + 1.5), Color(wax,0.12), 2.5, true)
	if float(pose.progress) > 0.0 and not done:
		canvas.draw_arc(Vector2.ZERO, 34, -PI/2, -PI/2 + TAU * float(pose.progress), 48, accent, 3, true)

static func draw_lamp(canvas: CanvasItem, ink: Color, stock: Color, tint: Color, brass: Color) -> void:
	var dark := ink if ink.get_luminance() < stock.get_luminance() else stock
	var rim := brass.lerp(dark, 0.23)
	canvas.draw_line(Vector2(0,-66),Vector2(0,-18),dark,3,true)
	canvas.draw_line(Vector2(-1,-65),Vector2(-1,-18),Color(rim,0.65),1,true)
	canvas.draw_arc(Vector2(0,-17),4,PI,TAU,16,rim,2,true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15,-8),Vector2(-8,-13),Vector2(-4,-17),Vector2(4,-17),Vector2(8,-13),Vector2(15,-8)]),dark)
	canvas.draw_line(Vector2(-13,-9),Vector2(13,-9),rim,2.5,true)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-10,-7),Vector2(10,-7),Vector2(8,13),Vector2(-8,13)]),tint.lerp(Color("fff1c9"),0.65))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(3,-6),Vector2(9,-6),Vector2(7,12),Vector2(3,12)]),Color(rim,0.38))
	canvas.draw_line(Vector2(-10,-7),Vector2(-8,13),rim,2,true)
	canvas.draw_line(Vector2(10,-7),Vector2(8,13),rim,2,true)
	canvas.draw_line(Vector2(0,-7),Vector2(0,13),rim,1.5,true)
	canvas.draw_line(Vector2(-11,14),Vector2(11,14),dark,4,true)
	canvas.draw_line(Vector2(-10,13),Vector2(10,13),rim,1.5,true)
