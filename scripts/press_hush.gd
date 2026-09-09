extends RefCounted
## A sleeve moving around planted feet: breathing, measured anticipation,
## the catch, and a held bow. All motion is ink; the body never moves its node.

static func draw(
	canvas: CanvasItem, pose: int, ticks: int, parries: int, face: float,
	time: float, ink: Color, stock: Color, motion: Dictionary = {}
) -> void:
	var pale := stock.lightened(0.07)
	var faded := ink.lerp(stock, 0.48)
	var clock: float = motion.get("clock", time)
	var breath := sin(clock * 2.3)
	var cloth := sin(clock * 2.3 - 0.65)
	var sway := sin(clock * 1.15) * 3.0
	var head := Vector2(sway, -83.0 - breath * 2.4)
	var shoulder := Vector2(face * 17.0 + sway * 0.6, -49.0 - breath * 1.4)
	var hand := Vector2(face * 47.0 + sway, -8.0 - breath * 2.0)
	var lean := 0.0
	var bow := 0.0
	var sleeve_lag := cloth * 3.4
	if pose == 2:
		# The clock resets on each audible tick, so count plus fractional beat
		# advances the anticipation continuously all the way into the swing.
		var count_progress := clampf((ticks + time / 0.42) / 4.0, 0.0, 1.0)
		var tension := smoothstep(0.18, 1.0, count_progress)
		hand = hand.lerp(Vector2(-face * 66.0, -72.0), tension)
		lean = -face * tension * 7.0
		head += Vector2(lean, tension * 2.0)
		shoulder.x += lean
		sleeve_lag -= face * tension * 4.0
	elif pose == 3:
		# The hand arrives at its full extension at the existing 120 ms contact.
		var sweep := clampf(time / 0.12, 0.0, 1.0)
		var travel := sweep * sweep
		hand = _curve(Vector2(-face * 66.0, -72.0), Vector2(face * 42.0, -137.0), Vector2(face * 124.0, -29.0), travel)
		lean = face * lerpf(-7.0, 12.0, travel)
		head += Vector2(lean, -sin(sweep * PI) * 3.0)
		shoulder += Vector2(lean, -sin(sweep * PI) * 2.0)
		sleeve_lag = -face * 13.0 * sin(sweep * PI)
	elif pose == 4:
		# The reflected point recoils, then the sleeve finds its hanging weight.
		var catch := smoothstep(0.0, 0.16, time)
		var release := smoothstep(0.2, 1.0, time)
		var recoil := Vector2(-face * 76.0, -40.0)
		hand = Vector2(face * 124.0, -29.0).lerp(recoil, catch).lerp(hand, release)
		lean = -face * sin(clampf(time / 0.4, 0.0, 1.0) * PI) * 11.0
		head += Vector2(lean, -sin(catch * PI) * 3.0)
		shoulder.x += lean
		sleeve_lag += face * sin(time * 14.0) * exp(-time * 4.0) * 9.0
	elif pose == 5:
		bow = smoothstep(0.0, 1.0, float(motion.get("settle", 1.0)))
		var settle := sin(bow * PI) * 5.0
		head = head.lerp(Vector2(8.0, -21.0), bow) + Vector2(settle, 0)
		shoulder = shoulder.lerp(Vector2(20.0, -4.0), bow)
		hand = Vector2(face * 124.0, -29.0).lerp(Vector2(79.0, 35.0), bow)
		sleeve_lag *= 1.0 - bow
	else:
		# The rules may start another count immediately. Cloth and hand can
		# still finish the previous arc without delaying that next count.
		var follow: float = motion.get("follow_through", 0.0)
		hand = hand.lerp(Vector2(face * 136.0, -8.0), follow * follow)
		lean = face * follow * 8.0
		head.x += lean
		shoulder.x += lean
	if pose == 2:
		var follow: float = motion.get("follow_through", 0.0)
		hand = hand.lerp(Vector2(face * 136.0, -8.0), follow * follow)

	var left_hem := Vector2(lerpf(-37.0, -45.0, bow) + sleeve_lag, 40.0)
	var right_hem := Vector2(lerpf(45.0, 44.0, bow) + sleeve_lag * 0.6, 40.0)
	var left_shoulder := Vector2(-26.0 + sway * 0.5 + lean, -45.0 - breath).lerp(Vector2(-23, -13), bow)
	var right_shoulder := Vector2(31.0 + sway * 0.5 + lean, -45.0 - breath).lerp(Vector2(22, -7), bow)
	canvas.draw_colored_polygon(PackedVector2Array([
		left_hem, left_shoulder, head + Vector2(-15, -4),
		head + Vector2(14, -5), right_shoulder, right_hem,
	]), ink)
	canvas.draw_polyline(PackedVector2Array([
		left_hem, left_shoulder + Vector2(5, 0), head + Vector2(0, -14),
		right_shoulder - Vector2(4, 0), right_hem,
	]), faded, 2.0, true)
	var elbow := shoulder.lerp(hand, 0.48) + Vector2(-face * 8.0, 16.0 - bow * 8.0)
	_sleeve(canvas, shoulder, elbow + Vector2(sleeve_lag * 0.3, 0), 8.0, 11.0, faded)
	_sleeve(canvas, elbow + Vector2(sleeve_lag * 0.3, 0), hand, 11.0, 4.0, faded)
	canvas.draw_polyline(PackedVector2Array([shoulder, elbow, hand]), pale, 4.0, true)
	var finger := Vector2(face * 23.0, -20.0).lerp(Vector2(8, 1), bow)
	canvas.draw_line(hand, hand + finger, faded, 3.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-16, 3), head + Vector2(0, -15), head + Vector2(17, 4),
		head + Vector2(10, 17), head + Vector2(-10, 17),
	]), pale)
	canvas.draw_line(head + Vector2(-6, 6), head + Vector2(8, 6), ink, 2.0, true)
	canvas.draw_line(left_shoulder + Vector2(14, 15), left_hem + Vector2(17, -4), faded, 2.0, true)
	canvas.draw_line(right_shoulder + Vector2(-19, 15), right_hem + Vector2(-16, -4), faded, 2.0, true)
	canvas.draw_line(Vector2(-28, 40), Vector2(34, 40), faded, 2.0, true)
	if pose == 5:
		return
	for index in range(3):
		var mark := Vector2(-19 + index * 19, -126)
		var color := pale if index < parries else faded
		canvas.draw_arc(mark, 5.0, 0, TAU, 16, color, 2.0, true)
		if pose == 2 and index < ticks:
			var tick_lift := exp(-time * 10.0) * 3.0 if index == ticks - 1 else 0.0
			canvas.draw_line(mark + Vector2(0, -15 - tick_lift), mark + Vector2(0, -8 - tick_lift), ink, 3.0, true)

static func _curve(start: Vector2, control: Vector2, finish: Vector2, progress: float) -> Vector2:
	return start.lerp(control, progress).lerp(control.lerp(finish, progress), progress)

static func _sleeve(canvas: CanvasItem, start: Vector2, finish: Vector2, start_width: float, finish_width: float, color: Color) -> void:
	var axis := (finish - start).normalized()
	var normal := Vector2(-axis.y, axis.x)
	canvas.draw_colored_polygon(PackedVector2Array([
		start + normal * start_width, finish + normal * finish_width,
		finish - normal * finish_width, start - normal * start_width,
	]), color)
