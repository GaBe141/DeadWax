extends RefCounted
## A pressed disc on an articulated spring stand. Pose data carries the
## existing contact timing; this helper only prints the movement between beats.

static func draw_pressing(canvas: CanvasItem, pose: Dictionary, ink: Color, wax: Color, pale: Color, accent: Color, grey: Color) -> void:
	var phase: String = pose.phase
	var face: float = pose.face
	var clock: float = pose.clock
	var recoil: float = pose.recoil
	if pose.muted:
		accent = grey
	var boil := Vector2(sin(floor(clock * 10.0) * 12.7 + float(int(pose.seed) % 71)), cos(floor(clock * 10.0) * 7.3)) * 0.7
	var breath := sin(clock * 2.5)
	var center := Vector2(sin(clock * 1.7) * 1.8, -26.0 - breath * 1.5) + boil
	var tilt := sin(clock * 1.7) * 0.025
	var squash := Vector2.ONE
	var beat: float = pose.beat
	var arm := Vector2(face * 27.0, 8.0 + breath * 2.0)
	if phase == "counting":
		var anticipation := (float(pose.count) + beat) / 4.0
		var tick_pop := sin(minf(beat * 4.0, 1.0) * PI) * 3.0
		center += Vector2(-face * anticipation * 6.0, anticipation * 5.0 - tick_pop)
		tilt -= face * anticipation * 0.14
		squash = Vector2(1.0 + anticipation * 0.045, 1.0 - anticipation * 0.06)
		arm = Vector2(face * (24.0 + anticipation * 20.0), 6.0 - anticipation * 43.0)
	elif phase == "swing":
		var swing := 1.0 - pow(1.0 - float(pose.swing), 3.0)
		center += Vector2(face * swing * 7.0, -sin(swing * PI) * 3.0)
		tilt = face * (-0.14 + swing * 0.32)
		arm = Vector2(face * 44.0, -37.0).lerp(Vector2(face * 110.0, 26.0), swing)
	elif float(pose.follow_through) > 0.0:
		var tail: float = pose.follow_through
		arm = Vector2(face * 27.0, 8.0).lerp(Vector2(face * 116.0, 34.0), tail)
		center.x += face * tail * 5.0
		tilt += face * tail * 0.12
	center.x -= face * recoil * 9.0
	tilt -= face * recoil * 0.3
	squash += Vector2(recoil * 0.09, -recoil * 0.08)
	if phase == "stagger":
		var settle := exp(-float(pose.state_time) * 4.5)
		tilt -= face * cos(float(pose.state_time) * 20.0) * 0.22 * settle
		arm = Vector2(-face * (35.0 + settle * 30.0), -25.0 - settle * 18.0)
	if phase == "down":
		_down(canvas, pose, ink, wax, pale, accent, grey)
		return
	# The baseline never wobbles. The two rods and collar absorb the motion.
	canvas.draw_line(Vector2(-16.0, 42.0), Vector2(16.0, 42.0), ink, 4.0, true)
	var collar := center.lerp(Vector2(0.0, 42.0), 0.63)
	canvas.draw_polyline(PackedVector2Array([Vector2(-16.0, 42.0), collar + Vector2(-5.0, 0.0), center + Vector2(-5.0, 12.0)]), ink, 4.0, true)
	canvas.draw_polyline(PackedVector2Array([Vector2(16.0, 42.0), collar + Vector2(5.0, 0.0), center + Vector2(5.0, 12.0)]), ink, 4.0, true)
	canvas.draw_line(collar + Vector2(-9.0, -3.0), collar + Vector2(9.0, -3.0), grey, 2.5, true)
	canvas.draw_set_transform(center, tilt, squash)
	canvas.draw_circle(Vector2(1.6, 1.0), 30.5, Color(accent, 0.28), true, -1.0, true)
	canvas.draw_circle(Vector2.ZERO, 30.0, wax, true, -1.0, true)
	canvas.draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 48, grey if pose.muted else pale, 3.0, true)
	canvas.draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 36, Color(pale, 0.35), 1.5, true)
	canvas.draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 28, Color(pale, 0.3), 1.5, true)
	# A label register turns slowly like an eccentric record, making idle motion
	# legible even while the spring has nearly settled.
	canvas.draw_arc(Vector2.ZERO, 25.0, clock * 0.23, clock * 0.23 + 0.34, 10, Color(pale, 0.55), 1.5, true)
	if recoil > 0.4:
		canvas.draw_line(Vector2(face * 8.0 - 3.0, -3.0), Vector2(face * 8.0 + 3.0, 0.0), pale, 2.2, true)
	else:
		canvas.draw_circle(Vector2(face * 8.0, -2.0), 3.0, pale if phase == "calm" else accent, true, -1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	var elbow := center + Vector2(face * 19.0, -2.0)
	canvas.draw_polyline(PackedVector2Array([center, elbow, center + arm]), accent if phase == "swing" else (grey if phase == "stagger" else ink), 4.0 if phase != "swing" else 5.0, true)
	canvas.draw_circle(center + arm, 3.0, accent, true, -1.0, true)
	if phase == "swing" or float(pose.follow_through) > 0.55:
		canvas.draw_arc(center, minf(arm.length(), 109.0), -0.24 if face > 0.0 else PI - 0.48, 0.48 if face > 0.0 else PI + 0.24, 20, Color(accent, 0.28), 2.0, true)
	if phase == "counting":
		for index in mini(int(pose.count), 3):
			var pulse := sin(minf(beat * 3.0, 1.0) * PI) if index == int(pose.count) - 1 else 0.0
			var mark := center + Vector2(-14.0 + index * 10.0, -44.0 - pulse * 3.0)
			canvas.draw_line(mark, mark + Vector2(0.0, 8.0 + pulse * 2.0), accent, 3.0, true)
	if float(pose.resonance) > 0.01:
		canvas.draw_arc(center, 34.0, -PI / 2.0, -PI / 2.0 + TAU * float(pose.resonance), 44, accent, 4.0, true)
	for index in int(pose.hp_total):
		var pip := center + Vector2(-((int(pose.hp_total) - 1) * 9.0) * 0.5 + index * 9.0, 44.0)
		canvas.draw_line(pip + Vector2(0.0, -4.0), pip + Vector2(0.0, 4.0), pale if index < int(ceil(float(pose.hp))) else Color(grey, 0.4), 3.0, true)

static func _down(canvas: CanvasItem, pose: Dictionary, ink: Color, wax: Color, pale: Color, accent: Color, grey: Color) -> void:
	var progress: float = pose.reform
	var burst := clampf(float(pose.state_time) / 0.45, 0.0, 1.0)
	var reform := clampf((progress - 0.82) / 0.18, 0.0, 1.0)
	var center := Vector2(0.0, 5.0 - reform * 31.0)
	canvas.draw_line(Vector2(-16.0, 42.0), center + Vector2(-4.0, 10.0), ink, 4.0, true)
	canvas.draw_line(Vector2(16.0, 42.0), center + Vector2(4.0, 10.0), ink, 4.0, true)
	if pose.muted:
		canvas.draw_set_transform(center, 0.0, Vector2(1.0, 0.38 + reform * 0.62))
		canvas.draw_circle(Vector2.ZERO, 25.0, wax, true, -1.0, true)
		canvas.draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 40, grey, 2.5, true)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	canvas.draw_arc(center, 20.0 + reform * 10.0, 0.4, PI - 0.4, 24, grey, 3.0, true)
	for index in range(6):
		var angle := float(index) * TAU / 6.0 + 0.4
		var radius := lerpf(15.0 + burst * 35.0, 24.0, reform)
		var shard := Vector2(0.0, -26.0).lerp(center, burst) + Vector2.from_angle(angle) * radius
		var alpha := maxf(1.0 - burst, reform)
		canvas.draw_set_transform(shard, angle + burst * 0.9 * (1.0 - reform))
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-7.0, -5.0), Vector2(8.0, -3.0), Vector2(0.0, 9.0)]), Color(ink, alpha))
		canvas.draw_line(Vector2(-7.0, -5.0), Vector2(8.0, -3.0), Color(pale, alpha), 1.5, true)
	canvas.draw_set_transform(Vector2.ZERO)
	if burst < 1.0:
		canvas.draw_arc(Vector2(0.0, -26.0), 30.0 + burst * 30.0, 0.0, TAU, 40, Color(accent, 1.0 - burst), 2.0, true)
