extends RefCounted
## Skip's living ink. Only an explicit pose and palette enter the Press;
## deformation is confined to draw commands, with the planted feet as pivot.

static func draw(canvas: CanvasItem, pose: Dictionary, palette: Dictionary) -> void:
	var ink: Color = palette.ink
	var pale: Color = palette.pale
	var pink: Color = palette.pink
	var hood_ink: Color = palette.hood
	var time: float = pose.time
	var stride: float = pose.stride
	var run: float = pose.run
	var air: float = pose.air
	var hood: float = pose.hood
	var kneel: float = pose.set
	var face: float = pose.face
	var land: float = pose.land
	var strike: float = pose.strike
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
	var tilt := face * (run * 0.13 + strike * 0.20 + kneel * 0.08)
	tilt -= float(pose.hit_direction) * sin(hurt * PI) * 0.23
	var bob := -absf(step) * run * 3.5 - sin(float(pose.launch) * PI) * 2.0
	var offset := Vector2(face * strike * 3.0, bob)
	var anchor := Vector2(0, 26)
	var translation := anchor + offset - (anchor * stretch).rotated(tilt)

	# Small articulated feet sell the stride while preserving the stylus body.
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var phase := stride + (PI if index == 0 else 0.0)
		var foot := Vector2(side * 8 + sin(phase) * run * 10, 25 - maxf(0, cos(phase)) * run * 8)
		foot += Vector2(-face * air * 5, -air * (4 + side * 2))
		var hip := Vector2(side * 7, 15 + kneel * 6)
		canvas.draw_line(hip, hip.lerp(foot, 0.5) + Vector2(-face * run * 3, 0), ink, 3.0, true)
		canvas.draw_line(hip.lerp(foot, 0.5) + Vector2(-face * run * 3, 0), foot, ink, 3.0, true)
		canvas.draw_line(foot, foot + Vector2(face * 5, 0), ink, 3.0, true)

	canvas.draw_set_transform(translation, tilt, stretch)
	var body := PackedVector2Array([Vector2(0, -34)])
	for index in range(15):
		var angle := lerpf(-0.55, 3.69, index / 14.0)
		body.append(Vector2(0, 8) + Vector2(cos(angle), sin(angle)) * 19.0)
	var flash := hurt > 0.0 and int(hurt * 7.0) % 2 == 0
	var fill: Color = pale if flash else palette.body
	canvas.draw_colored_polygon(body, fill)
	_outline(canvas, body, ink, time, 0.55 + noise * 1.6)

	# The flexible pickup tip trails the run and snaps with the strike.
	var tip := Vector2(face * (24 - run * 6 + strike * 15), -39 + step * run * 5 + strike * 29 + kneel * 14)
	var elbow := Vector2(face * (11 - run * 5), -43 + step * run * 3 + strike * 10)
	var stem := PackedVector2Array([Vector2(0, -34), elbow, tip])
	canvas.draw_polyline(stem, Color(ink, 1.0 - hood), 2.5, true)
	if noise > 0.03:
		canvas.draw_line(elbow, tip, Color(pink, noise * (1.0 - hood)), 2.0, true)

	# Lifting the sleeve is a short opening/closing motion, not a sprite swap.
	if hood > 0.0:
		var sleeve := PackedVector2Array([
			Vector2(-24, 26), Vector2(-12 * (1.0 - hood), lerpf(18, -44, hood)),
			Vector2(12 * (1.0 - hood), lerpf(18, -44, hood)), Vector2(24, 26),
		])
		canvas.draw_colored_polygon(sleeve, fill.lerp(Color(0.30, 0.28, 0.33), hood))
		_outline(canvas, sleeve, ink.lerp(hood_ink, hood), time, 0.45)
		canvas.draw_line(Vector2(-17, 22), Vector2(-4, -24 * hood), Color(hood_ink, hood * 0.40), 1.5, true)
		canvas.draw_line(Vector2(17, 22), Vector2(5, -21 * hood), Color(hood_ink, hood * 0.30), 1.5, true)
		if bool(palette.get("warm_thread", false)):
			var thread := Color(0.96, 0.69, 0.32, hood)
			canvas.draw_polyline(PackedVector2Array([
				Vector2(-20, 24), Vector2(-8 * (1.0 - hood), lerpf(20, -38, hood)),
				Vector2(8 * (1.0 - hood), lerpf(20, -38, hood)), Vector2(20, 24),
			]), thread, 2.2, true)
			canvas.draw_line(Vector2(-18, 21), Vector2(18, 21), thread, 1.8, true)
	var eye_center := Vector2(face * 2, lerpf(0, -12, hood) + kneel * 6)
	if hood > 0.35:
		canvas.draw_circle(eye_center, 9.0 * hood, Color(ink, hood), true, -1, true)
	var blink_phase := fmod(time, 4.7)
	var blink := clampf(1.0 - absf(blink_phase - 4.43) / 0.085, 0.0, 1.0)
	var lid := maxf(blink, 0.72 if hurt > 0.1 else kneel * 0.25)
	var eye_color := pale.lerp(hood_ink, hood)
	for side in [-1.0, 1.0]:
		var eye := eye_center + Vector2(side * lerpf(5.0, 3.2, hood), 0)
		if lid > 0.65:
			canvas.draw_line(eye + Vector2(-2.4, 0), eye + Vector2(2.4, 0), eye_color, 1.7, true)
		else:
			canvas.draw_circle(eye, lerpf(2.6, 1.6, hood) * (1.0 - lid * 0.45), eye_color, true, -1, true)
			if noise > 0.03 and hood < 0.5:
				canvas.draw_circle(eye, 1.1, Color(pink, noise * (1.0 - hood)), true, -1, true)
	canvas.draw_set_transform(Vector2.ZERO)

	# Strike and landing marks are short impressions, rooted at the actual body.
	if strike > 0.0:
		var radius := 32.0 + (1.0 - strike) * 22.0
		var start := -1.15 if face >= 0 else PI - 0.50
		var end := 0.50 if face >= 0 else PI + 1.15
		canvas.draw_arc(Vector2(0, -7), radius, start, end, 18, Color(pink, strike * 0.9), 3.5 if pose.big else 2.0, true)
	if land > 0.0 and float(pose.impact) > 0.35:
		for side in [-1.0, 1.0]:
			var puff := Vector2(side * (20 + (1.0 - land) * 21), 25 - sin(land * PI) * 5)
			canvas.draw_line(puff, puff + Vector2(side * 6, -2), Color(ink, land * 0.35), 1.5, true)
	if kneel > 0.0:
		var pulse := 0.70 + sin(time * 4.0) * 0.15
		for radius in [14.0, 23.0]:
			canvas.draw_arc(Vector2(face * 7, 22), radius + sin(time * 3.0) * 1.5, PI, TAU, 24, Color(pink, kneel * pulse * (0.6 if radius == 14 else 0.3)), 2.0, true)

static func _outline(canvas: CanvasItem, points: PackedVector2Array, color: Color, time: float, amplitude: float) -> void:
	var outline := PackedVector2Array()
	var frame := floorf(time * 11.0)
	for index in range(points.size()):
		var jitter := Vector2(sin(index * 11.3 + frame * 7.1), cos(index * 9.7 + frame * 5.3)) * amplitude
		outline.append(points[index] + jitter)
	outline.append(outline[0])
	canvas.draw_polyline(outline, color, 2.5, true)
