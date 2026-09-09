extends RefCounted
## The plaza Hound is a little record on four feet. The print receives a pose
## and palette only: no player, input, progression or campaign access lives here.

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var phase: String = pose.phase
	var clock: float = pose.clock
	var gait: float = pose.gait
	var stride: float = pose.speed
	var sit: float = pose.sit
	var wag: float = pose.wag
	var pale := stock.lightened(0.12)
	var faded := ink.lerp(stock, 0.48)
	var warm := Color("b77e42")
	var breath := sin(clock * 2.8) * 1.2
	var bob := -absf(sin(gait)) * stride * 2.5
	var startle := 0.0
	if phase == "startled":
		startle = sin(clampf(float(pose.time) / 0.3, 0.0, 1.0) * PI)
		bob -= startle * 5.0
	var body := Vector2(-4.0 - sit * 8.0, -8.0 + breath + bob + sit * 4.0)
	var sniff := sin(clock * 7.0) * 2.0 if phase == "notice" else 0.0
	var nuzzle := sin(clock * 3.5) * 2.6 * float(pose.pet)
	var head := body + Vector2(34.0 + sniff + nuzzle, -22.0 - sit * 4.0)
	head.y -= startle * 5.0
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(pose.face), 1.0))
	# The rear pair leads the gait by half a cycle; front legs carry the sit.
	_leg(canvas, body + Vector2(-19, 8), -24.0, gait + PI, stride, sit, faded)
	_leg(canvas, body + Vector2(15, 8), 23.0, gait, stride, 0.0, faded)
	var tail_root := body + Vector2(-23, -2)
	var wag_angle := sin(clock * (5.0 + wag * 11.0)) * (0.12 + wag * 0.40)
	var tail_tip := tail_root + Vector2(-38, -14).rotated(wag_angle)
	if phase == "startled":
		tail_tip = tail_root + Vector2(-24, 13)
	canvas.draw_polyline(PackedVector2Array([tail_root, tail_root.lerp(tail_tip, 0.55) + Vector2(0, -7), tail_tip]), ink, 4.5, true)
	canvas.draw_circle(body + Vector2(-13, 14), 12.0 * sit + 2.0, ink, true, -1, true)
	canvas.draw_circle(body, 26.0, ink, true, -1, true)
	canvas.draw_circle(body + Vector2(19, 3), 12.0, ink, true, -1, true)
	canvas.draw_arc(body, 22.0, 0, TAU, 42, pale, 1.8, true)
	canvas.draw_arc(body, 16.0, 0, TAU, 36, faded, 1.0, true)
	canvas.draw_arc(body, 10.0, 0, TAU, 30, faded, 1.0, true)
	canvas.draw_circle(body, 5.0, warm if phase == "pet" else pale, true, -1, true)
	canvas.draw_circle(body, 1.5, ink, true, -1, true)
	_leg(canvas, body + Vector2(-14, 11), -15.0, gait, stride, sit, ink)
	_leg(canvas, body + Vector2(19, 9), 30.0, gait + PI, stride, 0.0, ink)
	# Folded paper ears, a sloped muzzle, and a small needle for a nose.
	var ear_lift := 8.0 * startle + (4.0 if phase == "notice" else 0.0)
	var ear_swing := sin(clock * 3.0 - 0.8) * 2.0 + stride * sin(gait - 0.5) * 3.0
	canvas.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-14, -4), head + Vector2(-24 + ear_swing, -22 - ear_lift), head + Vector2(-4, -8),
	]), faded)
	canvas.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-13, 5), head + Vector2(-10, -14), head + Vector2(7, -11),
		head + Vector2(22, 2), head + Vector2(9, 10),
	]), ink)
	canvas.draw_polyline(PackedVector2Array([
		head + Vector2(-13, 5), head + Vector2(-10, -14), head + Vector2(7, -11), head + Vector2(22, 2),
	]), pale, 1.8, true)
	canvas.draw_line(head + Vector2(21, 2), head + Vector2(29, 1), ink, 3.0, true)
	canvas.draw_line(head + Vector2(-6, -10), head + Vector2(-12 + ear_swing, 10), faded, 4.0, true)
	if phase == "pet":
		canvas.draw_arc(head + Vector2(6, -3), 3.4, PI, TAU, 10, pale, 1.7, true)
	else:
		canvas.draw_circle(head + Vector2(6, -3), 2.3 + startle * 0.6, pale, true, -1, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func _leg(canvas: CanvasItem, hip: Vector2, stance_x: float, gait: float, stride: float, sit: float, color: Color) -> void:
	var swing := sin(gait)
	var foot := Vector2(stance_x + swing * stride * 8.0, 26.0 - maxf(swing, 0.0) * stride * 7.0)
	foot.x = lerpf(foot.x, stance_x - 9.0, sit)
	var knee := hip.lerp(foot, 0.56) + Vector2(-4.0 - sit * 6.0, 0)
	canvas.draw_polyline(PackedVector2Array([hip, knee, foot]), color, 3.4, true)
	canvas.draw_line(foot + Vector2(-3, 0), foot + Vector2(5, 0), color, 3.0, true)
