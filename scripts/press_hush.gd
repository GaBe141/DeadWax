extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## A sleeve moving around planted feet: breathing, measured anticipation,
## the catch, and a held bow. All motion is ink; the body never moves its node.

static func draw(
	canvas: CanvasItem, pose: int, ticks: int, parries: int, face: float,
	time: float, ink: Color, stock: Color, motion: Dictionary = {}
) -> void:
	var cue_ink := ink
	var paint := Paint.palette(ink,stock)
	ink = paint.edge
	var pale: Color = paint.cream
	var faded: Color = paint.teal
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
	Paint.shape(canvas,PackedVector2Array([
		left_hem, left_shoulder, head + Vector2(-15, -4),
		head + Vector2(14, -5), right_shoulder, right_hem,
	]),paint.shadow,ink,2.2)
	Paint.shape(canvas,PackedVector2Array([left_shoulder,head+Vector2(-4,8),Vector2(6,37),left_hem]),paint.coat,ink,1.3)
	Paint.shape(canvas,PackedVector2Array([right_shoulder,head+Vector2(7,12),Vector2(6,37),right_hem]),paint.teal,ink,1.1)
	canvas.draw_colored_polygon(PackedVector2Array([left_shoulder+Vector2(10,3),Vector2(-11+lean,29),left_hem+Vector2(7,-2)]),Color(paint.teal,0.55))
	canvas.draw_colored_polygon(PackedVector2Array([right_shoulder+Vector2(-8,6),Vector2(15+lean,30),right_hem+Vector2(-7,-2)]),Color(paint.shadow,0.66))
	Paint.hatch(canvas,Vector2(-18,33),21,21,Color(paint.teal,0.45),6)
	Paint.hatch(canvas,Vector2(25,30),22,29,Color(paint.cream,0.13),6)
	canvas.draw_polyline(PackedVector2Array([
		left_hem, left_shoulder + Vector2(5, 0), head + Vector2(0, -14),
		right_shoulder - Vector2(4, 0), right_hem,
	]),paint.brass,3.4,true)
	var elbow := shoulder.lerp(hand, 0.48) + Vector2(-face * 8.0, 16.0 - bow * 8.0)
	_sleeve(canvas, shoulder, elbow + Vector2(sleeve_lag * 0.3, 0), 15.0, 18.0, paint.coat)
	_sleeve(canvas, elbow + Vector2(sleeve_lag * 0.3, 0), hand, 18.0, 7.0, paint.coat)
	canvas.draw_polyline(PackedVector2Array([shoulder+Vector2(0,-5),elbow+Vector2(0,-5),hand]),paint.teal,7.0,true)
	Paint.segment(canvas,hand.lerp(elbow,0.10),hand,13,paint.brass,ink,paint.gold)
	Paint.disc(canvas,hand,7,pale,ink,paint.light)
	var finger := Vector2(face * 23.0, -20.0).lerp(Vector2(8, 1), bow)
	Paint.segment(canvas,hand,hand+finger,4.0,paint.brass,ink,paint.gold)
	Paint.shape(canvas,PackedVector2Array([head+Vector2(-20,-5),head+Vector2(-4,-23),head+Vector2(18,-12),head+Vector2(23,12),head+Vector2(0,23),head+Vector2(-21,12)]),paint.coat,ink,2.0)
	Paint.shape(canvas,PackedVector2Array([head+Vector2(-14,-5),head+Vector2(0,-17),head+Vector2(14,-3),head+Vector2(9,15),head+Vector2(0,22),head+Vector2(-11,12)]),pale,paint.wax,1.2)
	canvas.draw_colored_polygon(PackedVector2Array([head+Vector2(3,-13),head+Vector2(13,-3),head+Vector2(8,15),head+Vector2(0,22),head+Vector2(3,5)]),paint.wax)
	for side in [-1.0,1.0]:
		canvas.draw_line(head+Vector2(side*3,2),head+Vector2(side*9,0 if pose!=5 else 3),ink,2.1,true)
	canvas.draw_line(head+Vector2(-3,11),head+Vector2(3,11),ink,1.0,true)
	Paint.bolt(canvas,head+Vector2(0,26),5,paint.brass,ink,paint.light)
	canvas.draw_line(left_shoulder + Vector2(14, 15), left_hem + Vector2(17, -4), faded, 2.0, true)
	canvas.draw_line(right_shoulder + Vector2(-19, 15), right_hem + Vector2(-16, -4), faded, 2.0, true)
	canvas.draw_line(Vector2(-28, 40), Vector2(34, 40), paint.brass,3.2,true)
	if pose == 5:
		return
	for index in range(3):
		var mark := Vector2(-19 + index * 19, -126)
		var color := cue_ink if index < parries else cue_ink.lerp(stock, 0.55)
		canvas.draw_arc(mark, 5.0, 0, TAU, 16, color, 2.0, true)
		if pose == 2 and index < ticks:
			var tick_lift := exp(-time * 10.0) * 3.0 if index == ticks - 1 else 0.0
			canvas.draw_line(mark + Vector2(0, -15 - tick_lift), mark + Vector2(0, -8 - tick_lift), cue_ink, 3.0, true)

static func _curve(start: Vector2, control: Vector2, finish: Vector2, progress: float) -> Vector2:
	return start.lerp(control, progress).lerp(control.lerp(finish, progress), progress)

static func _sleeve(canvas: CanvasItem, start: Vector2, finish: Vector2, start_width: float, finish_width: float, color: Color) -> void:
	var axis := (finish - start).normalized()
	var normal := Vector2(-axis.y, axis.x)
	canvas.draw_colored_polygon(PackedVector2Array([
		start + normal * start_width, finish + normal * finish_width,
		finish - normal * finish_width, start - normal * start_width,
	]), color)
