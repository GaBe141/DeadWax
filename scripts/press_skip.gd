extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## Skip's living ink. Only an explicit pose and palette enter the Press;
## deformation is confined to draw commands, with the planted feet as pivot.

static func draw(canvas: CanvasItem, pose: Dictionary, palette: Dictionary) -> void:
	var paint := Paint.palette(palette.ink, palette.pale)
	var ink: Color = paint.edge
	var pale: Color = paint.cream
	var pink: Color = paint.coral
	var hood_ink: Color = paint.teal
	var time: float = pose.time
	var stride: float = pose.stride
	var run: float = pose.run
	var air: float = pose.air
	var hood: float = pose.hood
	var kneel: float = pose.set
	var face: float = pose.face
	var land: float = pose.land
	var strike: float = pose.strike
	var combo_step := clampi(int(pose.get("combo_step", 1)), 1, 3)
	# Contact is immediate. The tip snaps on the first frame and settles quickly;
	# there is no visual windup to wait through.
	var snap := pow(clampf((strike - 0.40) / 0.60, 0.0, 1.0), 0.75)
	var hurt: float = pose.hurt
	var noise: float = pose.noise
	var breath := sin(time * 2.7)
	var step := sin(stride)
	var compression := sin(land * PI) * float(pose.impact)
	var rise := maxf(-float(pose.vertical), 0.0) * air
	var stretch := Vector2(
		1.0 + compression * 0.24 - rise * 0.10 + kneel * 0.15,
		1.0 - compression * 0.24 + rise * 0.16 - kneel * 0.30
	)
	stretch.y += breath * 0.018 * (1.0 - run) + cos(stride * 2.0) * run * 0.045
	var strike_tilt: float = [0.24, -0.22, 0.08][combo_step - 1]
	var tilt := face * (run * 0.13 + snap * strike_tilt + kneel * 0.08)
	if combo_step == 3:
		stretch += Vector2(0.15, -0.12) * snap
	tilt -= float(pose.hit_direction) * sin(hurt * PI) * 0.23
	var bob := -absf(step) * run * 3.5 - sin(float(pose.launch) * PI) * 2.0
	var offset := Vector2(face * snap * (-3.0 if combo_step == 2 else 5.0), bob)
	var anchor := Vector2(0, 26)
	var translation := anchor + offset - (anchor * stretch).rotated(tilt)

	# Small articulated feet sell the stride while preserving the stylus body.
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var phase := stride + (PI if index == 0 else 0.0)
		var foot := Vector2(side * 8 + sin(phase) * run * 10, 25 - maxf(0, cos(phase)) * run * 8)
		foot += Vector2(-face * air * 5, -air * (4 + side * 2))
		var hip := Vector2(side * 7, 15 + kneel * 6)
		var knee := hip.lerp(foot, 0.5) + Vector2(-face * run * 3, 0)
		Paint.segment(canvas, hip, knee, 4.0, paint.coat, ink, paint.teal)
		Paint.segment(canvas, knee, foot, 4.5, paint.brass, ink, paint.gold)
		canvas.draw_line(foot + Vector2(-3, 0), foot + Vector2(face * 5, 0), ink, 4.0, true)

	canvas.draw_set_transform(translation, tilt, stretch)
	var body := PackedVector2Array([Vector2(0, -34)])
	for index in range(15):
		var angle := lerpf(-0.55, 3.69, index / 14.0)
		body.append(Vector2(0, 8) + Vector2(cos(angle), sin(angle)) * 19.0)
	var flash := hurt > 0.0 and int(hurt * 7.0) % 2 == 0
	var fill: Color = paint.light if flash else paint.coat
	Paint.shape(canvas, body, fill, ink, 2.3)
	# A folded petrol coat surrounds the cream wax face. Broad painted planes
	# carry its volume; the needle-shaped outer silhouette remains recognizable.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,-31),Vector2(-15,-2),Vector2(-17,16),Vector2(-5,24),Vector2(-3,3)]), paint.shadow)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(2,-25),Vector2(13,-3),Vector2(17,13),Vector2(9,23),Vector2(4,5)]), paint.teal)
	Paint.hatch(canvas, Vector2(-10,19), 9, 13, Color(paint.teal,0.45), 4)
	var mask := PackedVector2Array([Vector2(0,-25),Vector2(10,-10),Vector2(12,4),Vector2(5,13),Vector2(-6,12),Vector2(-11,3),Vector2(-8,-11)])
	Paint.shape(canvas, mask, pale, paint.wax, 1.2)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(4,-18),Vector2(10,-8),Vector2(11,4),Vector2(5,12),Vector2(3,1)]), paint.wax)
	canvas.draw_line(Vector2(-5,-12),Vector2(-8,1),Color(paint.light,0.85),2.4,true)
	# The short copper scarf follows the body rather than the collision node.
	Paint.shape(canvas,PackedVector2Array([Vector2(-14,12),Vector2(12,12),Vector2(16,16),Vector2(2,19),Vector2(-13,17)]),paint.copper,ink,1.0)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-face*9,15),Vector2(-face*(26+run*6),11+sin(time*6)*2),Vector2(-face*19,20),Vector2(-face*8,19)]),paint.copper)
	canvas.draw_line(Vector2(-11,13),Vector2(10,14),paint.coral,1.3,true)

	# The flexible pickup tip trails the run and snaps with the strike.
	var tip := Vector2(face * (24 - run * 6 + snap * 23), -39 + step * run * 5 + snap * 33 + kneel * 14)
	var elbow := Vector2(face * (11 - run * 5), -43 + step * run * 3 + snap * 14)
	if combo_step == 2:
		tip = tip.lerp(Vector2(face * 50, 7), snap)
		elbow = elbow.lerp(Vector2(face * 21, -24), snap)
	elif combo_step == 3:
		tip = tip.lerp(Vector2(face * 34, 20), snap)
		elbow = elbow.lerp(Vector2(face * 38, -31), snap)
	var stem := PackedVector2Array([Vector2(0, -34), elbow, tip])
	canvas.draw_polyline(stem, Color(ink, 1.0 - hood), 5.0, true)
	canvas.draw_polyline(stem, Color(paint.brass, 1.0 - hood), 3.2, true)
	canvas.draw_line(elbow + Vector2(0,-1),tip + Vector2(0,-1),Color(paint.gold,1.0-hood),1.1,true)
	canvas.draw_circle(elbow,2.4,Color(paint.gold,1.0-hood),true,-1,true)
	if noise > 0.03:
		canvas.draw_line(elbow, tip, Color(pink, noise * (1.0 - hood)), 2.0, true)

	# Lifting the sleeve is a short opening/closing motion, not a sprite swap.
	if hood > 0.0:
		var sleeve := PackedVector2Array([
			Vector2(-24, 26), Vector2(-12 * (1.0 - hood), lerpf(18, -44, hood)),
			Vector2(12 * (1.0 - hood), lerpf(18, -44, hood)), Vector2(24, 26),
		])
		Paint.shape(canvas,sleeve,fill.lerp(paint.shadow,hood*0.7),ink,2.0)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(3,-36*hood),Vector2(21,24),Vector2(10,23),Vector2(0,-15*hood)]),Color(paint.teal,hood))
		canvas.draw_line(Vector2(-17, 22), Vector2(-4, -24 * hood), Color(hood_ink, hood * 0.40), 1.5, true)
		canvas.draw_line(Vector2(17, 22), Vector2(5, -21 * hood), Color(hood_ink, hood * 0.30), 1.5, true)
		if bool(palette.get("warm_thread", false)):
			var thread := Color(0.96, 0.69, 0.32, hood)
			canvas.draw_polyline(PackedVector2Array([
				Vector2(-20, 24), Vector2(-8 * (1.0 - hood), lerpf(20, -38, hood)),
				Vector2(8 * (1.0 - hood), lerpf(20, -38, hood)), Vector2(20, 24),
			]), thread, 2.2, true)
			canvas.draw_line(Vector2(-18, 21), Vector2(18, 21), thread, 1.8, true)
	var eye_center := Vector2(face * 1.5, lerpf(-2, -12, hood) + kneel * 6)
	if hood > 0.35:
		Paint.disc(canvas,eye_center,9.0*hood,paint.cream,ink,paint.light,hood)
	var blink_phase := fmod(time, 4.7)
	var blink := clampf(1.0 - absf(blink_phase - 4.43) / 0.085, 0.0, 1.0)
	var lid := maxf(blink, 0.72 if hurt > 0.1 else kneel * 0.25)
	var eye_color: Color = ink
	for side in [-1.0, 1.0]:
		var eye := eye_center + Vector2(side * lerpf(5.0, 3.2, hood), 0)
		if lid > 0.65:
			canvas.draw_line(eye + Vector2(-2.4, 0), eye + Vector2(2.4, 0), eye_color, 1.7, true)
		else:
			canvas.draw_circle(eye, lerpf(2.8, 2.1, hood) * (1.0 - lid * 0.45), eye_color, true, -1, true)
			canvas.draw_circle(eye+Vector2(-0.7,-0.8),0.8,paint.light,true,-1,true)
			if noise > 0.03 and hood < 0.5:
				canvas.draw_line(eye+Vector2(-2,-4),eye+Vector2(2,-3),Color(ink,noise*(1.0-hood)),1.2,true)
	canvas.draw_line(eye_center+Vector2(-2,6),eye_center+Vector2(2,6+hurt*2),ink,1.0,true)
	canvas.draw_set_transform(Vector2.ZERO)

	# Strike and landing marks are short impressions, rooted at the actual body.
	if snap > 0.0:
		_strike_cut(canvas, combo_step, face, snap, pink, bool(pose.big))
	if land > 0.0 and float(pose.impact) > 0.35:
		for side in [-1.0, 1.0]:
			var puff := Vector2(side * (20 + (1.0 - land) * 21), 25 - sin(land * PI) * 5)
			canvas.draw_line(puff, puff + Vector2(side * 6, -2), Color(ink, land * 0.35), 1.5, true)
	if kneel > 0.0:
		var pulse := 0.70 + sin(time * 4.0) * 0.15
		for radius in [14.0, 23.0]:
			canvas.draw_arc(Vector2(face * 7, 22), radius + sin(time * 3.0) * 1.5, PI, TAU, 24, Color(pink, kneel * pulse * (0.6 if radius == 14 else 0.3)), 2.0, true)

static func _strike_cut(canvas: CanvasItem, step: int, face: float, snap: float, color: Color, big: bool) -> void:
	var radius := 42.0 + (1.0 - snap) * 13.0
	var start := -1.15 if step == 1 else (-2.5 if step == 2 else -1.0)
	var sweep := 1.65 if step == 1 else (3.35 if step == 2 else 1.90)
	var points := PackedVector2Array()
	for index in 30:
		var point := Vector2.from_angle(start + sweep * index / 29.0) * radius
		point.x *= -1.0 if face < 0.0 else 1.0
		points.append(point + Vector2(0, -7))
	canvas.draw_polyline(points, Color(color, snap * 0.9), 4.0 if big or step == 3 else 2.8, true)
	if step == 3:
		var direction := -1.0 if face < 0.0 else 1.0
		for side in [-1.0, 1.0]:
			var mark := Vector2(direction * (radius - 3), -7 + side * 17)
			canvas.draw_line(mark, mark + Vector2(direction * 10, side * 5), Color(color, snap * 0.7), 2.4, true)

static func _outline(canvas: CanvasItem, points: PackedVector2Array, color: Color, time: float, amplitude: float) -> void:
	var outline := PackedVector2Array()
	var frame := floorf(time * 11.0)
	for index in range(points.size()):
		var jitter := Vector2(sin(index * 11.3 + frame * 7.1), cos(index * 9.7 + frame * 5.3)) * amplitude
		outline.append(points[index] + jitter)
	outline.append(outline[0])
	canvas.draw_polyline(outline, color, 2.5, true)
