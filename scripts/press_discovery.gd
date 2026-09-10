extends RefCounted
## The held breath and the little voice above the market. Pure printed poses.

const PINK := Color("ddb176")

static func draw_voice(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var clock := float(pose.get("clock", 0.0))
	var freed := int(pose.get("stage", 0)) == 4
	var singing := int(pose.get("stage", 0)) == 1
	var breath := sin(clock * 2.1) * 1.2
	# A small record sleeve with its own horn, seated on the shelf.
	canvas.draw_line(Vector2(-24, 26), Vector2(25, 26), ink, 3.0, true)
	canvas.draw_line(Vector2(-10, 14), Vector2(-15, 25), ink, 3.0, true)
	canvas.draw_line(Vector2(10, 14), Vector2(16, 25), ink, 3.0, true)
	canvas.draw_set_transform(Vector2(0, breath))
	canvas.draw_circle(Vector2(0, -12), 31, Color(PINK, 0.065), true, -1, true)
	canvas.draw_rect(Rect2(-24, -37, 48, 55), stock.lerp(ink, 0.12))
	canvas.draw_rect(Rect2(-24, -37, 48, 55), ink, false, 2.5)
	canvas.draw_line(Vector2(-21, -34), Vector2(21, -34), PINK, 1.5, true)
	for screw in [Vector2(-20, -32), Vector2(20, -32), Vector2(-20, 13), Vector2(20, 13)]:
		canvas.draw_circle(screw, 1.5, PINK, true, -1, true)
	canvas.draw_circle(Vector2(0, -12), 20, ink, true, -1, true)
	for radius in [11.0, 15.0, 18.0]:
		canvas.draw_arc(Vector2(0, -12), radius, 0.2, TAU - 0.3, 40, Color(stock, 0.36), 1.0, true)
	canvas.draw_circle(Vector2(0, -12), 6, PINK if freed else stock, true, -1, true)
	canvas.draw_circle(Vector2(0, -12), 2, ink, true, -1, true)
	canvas.draw_line(Vector2(-24, -5), Vector2(-35, 4 if freed else -11), ink, 2.5, true)
	canvas.draw_line(Vector2(24, -5), Vector2(35, -18 if singing else 4), ink, 2.5, true)
	canvas.draw_arc(Vector2(0, 4), 6, 0.1, PI - 0.1, 14, stock, 2.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	if bool(pose.get("near", false)):
		for index in 3:
			var center := Vector2(-22 + index * 22, -57)
			var active := singing and index <= int(pose.get("note", -1))
			canvas.draw_circle(center, 5, PINK if active or freed else stock, true, -1, true)
			canvas.draw_arc(center, 5, 0, TAU, 20, ink, 1.5, true)
		if int(pose.get("stage", 0)) == 2:
			canvas.draw_rect(Rect2(-34, -73, 68, 4), Color(ink, 0.25))
			canvas.draw_rect(Rect2(-34, -73, 68 * float(pose.get("answer", 0.0)), 4), PINK)
		for index in int(pose.get("responses", 0)):
			canvas.draw_line(Vector2(-9 + index * 14, 36), Vector2(-3 + index * 14, 36), PINK, 3, true)

static func draw_refrain(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var clock := float(pose.get("clock", 0.0))
	var bob := sin(clock * 2.2) * 3.0
	canvas.draw_line(Vector2(-32, 32), Vector2(32, 32), Color(ink, 0.6), 2, true)
	canvas.draw_set_transform(Vector2(0, bob))
	for halo in range(4, 0, -1):
		canvas.draw_circle(Vector2.ZERO, 29 + halo * 4, Color(PINK, 0.022), true, -1, true)
	canvas.draw_circle(Vector2.ZERO, 29, stock, true, -1, true)
	canvas.draw_arc(Vector2.ZERO, 29, 0, TAU, 64, ink, 2.5, true)
	canvas.draw_circle(Vector2.ZERO, 23, ink, true, -1, true)
	canvas.draw_arc(Vector2.ZERO, 18, -1.2, 4.6, 48, Color(stock, 0.5), 1.2, true)
	canvas.draw_arc(Vector2.ZERO, 13, 0.2, 5.7, 40, Color(stock, 0.6), 1, true)
	canvas.draw_circle(Vector2.ZERO, 7, PINK, true, -1, true)
	canvas.draw_circle(Vector2.ZERO, 2, stock, true, -1, true)
	for mark in range(12):
		var direction := Vector2.from_angle(mark * TAU / 12.0)
		canvas.draw_line(direction * 25, direction * 27, PINK, 1.1, true)
	# The held breath curls up from the centre of the pressing.
	canvas.draw_arc(Vector2(0, -30), 9, PI * 1.05, TAU * 0.98, 20, PINK, 2, true)
	if bool(pose.get("near", false)):
		canvas.draw_line(Vector2(-35, -11), Vector2(-40, -18), PINK, 2, true)
		canvas.draw_line(Vector2(35, -11), Vector2(40, -18), PINK, 2, true)
	canvas.draw_set_transform(Vector2.ZERO)
