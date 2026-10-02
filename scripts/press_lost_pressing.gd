extends RefCounted
## Small cabinets and folded sleeves. Drawing reads only its explicit pose;
## the impression never supplies a foothold or changes an interaction origin.

const BRASS := Color("d6b77c")

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var collected := bool(pose.get("collected", false))
	var available := bool(pose.get("available", false))
	var far_face := bool(pose.get("far_face", false))
	var reverse := String(pose.get("requirement", "")) == "jump_cut"
	var accent := BRASS if available else ink.lerp(stock, 0.45)
	var paper := stock.lerp(ink, 0.18)
	# The grounded cabinet has a distinct empty recess once taken. Its feet
	# end at the real floor, and all small movement belongs to the loose tab.
	canvas.draw_rect(Rect2(-37, -62, 74, 84), stock.lerp(ink, 0.08))
	canvas.draw_rect(Rect2(-37, -62, 74, 84), ink.lerp(stock, 0.28), false, 2.0)
	canvas.draw_rect(Rect2(-43, 20, 86, 5), ink.lerp(stock, 0.25))
	for x in [-29.0, 29.0]:
		canvas.draw_line(Vector2(x, 24), Vector2(x, 26), ink, 3.0, true)
	canvas.draw_line(Vector2(-30, -54), Vector2(30, -54), accent, 1.5, true)
	canvas.draw_rect(Rect2(-28, -43, 56, 51), stock)
	if collected:
		canvas.draw_polyline(PackedVector2Array([Vector2(-23, 4), Vector2(-23, -32), Vector2(0, -22), Vector2(23, -32), Vector2(23, 4)]), ink.lerp(stock, 0.5), 1.5, true)
		canvas.draw_line(Vector2(-18, 10), Vector2(-7, 10), accent, 2.0, true)
		canvas.draw_line(Vector2(-2, 10), Vector2(18, 10), ink.lerp(stock, 0.6), 1.5, true)
		return
	var bob := sin(float(pose.get("clock", 0.0)) * 1.8) * 1.3
	canvas.draw_set_transform(Vector2(0, bob - 16))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-24, -22), Vector2(18, -24), Vector2(25, -15), Vector2(23, 28), Vector2(-24, 25)]), paper)
	canvas.draw_polyline(PackedVector2Array([Vector2(-24, 25), Vector2(-24, -22), Vector2(18, -24), Vector2(25, -15), Vector2(23, 28)]), ink.lerp(stock, 0.2), 1.5, true)
	canvas.draw_line(Vector2(18, -24), Vector2(16, -14), accent, 1.0, true)
	canvas.draw_line(Vector2(16, -14), Vector2(25, -15), accent, 1.0, true)
	if reverse and not far_face:
		for index in 3:
			canvas.draw_line(Vector2(-16, -8 + index * 9), Vector2(16, -13 + index * 9), accent, 2.0, true)
	else:
		match String(pose.get("id", "")):
			"copper_stylus":
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(-7, -13), Vector2(9, -9), Vector2(-2, 19), Vector2(-6, 21)]), accent)
				canvas.draw_line(Vector2(-7, -13), Vector2(-6, 21), ink, 1.5, true)
				canvas.draw_line(Vector2(12, -7), Vector2(6, 11), ink.lerp(stock, 0.4), 1.0, true)
			"seam_lining":
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(-17, 17), Vector2(-12, -6), Vector2(0, -15), Vector2(13, -7), Vector2(18, 18)]), accent)
				canvas.draw_arc(Vector2(0, 5), 11, PI, TAU, 24, stock, 3.0, true)
				for index in 4:
					canvas.draw_line(Vector2(-10 + index * 7, 13), Vector2(-8 + index * 7, 17), stock, 1.0, true)
			"dusk_seal":
				canvas.draw_circle(Vector2(0, 2), 15, accent, true, -1, true)
				canvas.draw_arc(Vector2(0, 2), 10, 0, TAU, 32, stock, 1.5, true)
				canvas.draw_circle(Vector2(4, -1), 7, stock, true, -1, true)
				canvas.draw_line(Vector2(-10, 12), Vector2(-15, 22), accent, 3.0, true)
				canvas.draw_line(Vector2(10, 12), Vector2(14, 21), accent, 3.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	if bool(pose.get("near", false)):
		canvas.draw_line(Vector2(-48, -25), Vector2(-43, -20), accent, 2.0, true)
		canvas.draw_line(Vector2(48, -25), Vector2(43, -20), accent, 2.0, true)
