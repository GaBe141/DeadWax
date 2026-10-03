extends RefCounted
## The double-cut rim marks an arena elite. Every directional mark and progress
## cut comes from a supplied combat snapshot; the press owns no encounter clock.

const Paint := preload("res://scripts/figure_paint.gd")

static func draw(c: Node2D, pose: Dictionary, ink: Color, stock: Color, font: Font, type_size: int) -> void:
	var phase := StringName(pose.get("phase", &"idle"))
	if phase == &"down": return
	var face := -1.0 if float(pose.get("face", -1.0)) < 0.0 else 1.0
	var attack_face := -1.0 if float(pose.get("attack_face", face)) < 0.0 else 1.0
	var paint := Paint.palette(ink, stock)
	var center: Vector2 = pose.get("body_center", Vector2(0, -26))
	if pose.get("body_pose") is Dictionary:
		center = _disc_center(pose.body_pose)
	var progress := clampf(float(pose.get("progress", 0.0)), 0.0, 1.0)
	var guarded := bool(pose.get("guard", false))
	var interrupted := bool(pose.get("interrupted", false))
	var blocked := clampf(float(pose.get("blocked", 0.0)), 0.0, 1.0)
	var cross := StringName(pose.get("mode", &"front")) == &"cross"
	var cue_mix := 0.58 if stock.get_luminance() > 0.38 else 0.16
	var warm: Color = paint.gold.lerp(ink, cue_mix)
	var live: Color = paint.coral.lerp(ink, cue_mix)
	# Two interrupted cast rims and a broad rear shoulder read at normal scale.
	# All pieces belong to the drawn disc; the floor, node and pivots stay fixed.
	for angles in [Vector2(-2.98, -1.88), Vector2(-1.63, -0.34), Vector2(0.30, 1.23), Vector2(1.64, 2.66)]:
		c.draw_arc(center, 35.0, angles.x, angles.y, 16, paint.edge, 6.5, true)
		c.draw_arc(center, 35.0, angles.x, angles.y, 16, paint.copper.lerp(paint.wood, 0.24), 3.5, true)
		c.draw_arc(center, 38.0, angles.x + 0.12, angles.y - 0.11, 14, Color(paint.gold, 0.72), 1.6, true)
	var rear := center + Vector2(-face * 29.0, -11.0)
	Paint.shape(c, PackedVector2Array([rear + Vector2(-face * 4, -14), rear + Vector2(-face * 18, -6),
		rear + Vector2(-face * 14, 14), rear + Vector2(face * 3, 17)]), paint.wood, paint.edge, 2.0)
	c.draw_line(rear + Vector2(-face * 13, -5), rear + Vector2(-face * 10, 10), paint.copper, 3.0, true)
	c.draw_line(rear + Vector2(-face * 11, -3), rear + Vector2(-face * 9, 3), Color(paint.gold, 0.68), 1.4, true)
	if guarded:
		# Only the committed FRONT has a shield. No mirrored rear bracket.
		var bracket := PackedVector2Array([center + Vector2(face * 35, -26), center + Vector2(face * 47, -17),
			center + Vector2(face * 47, 25), center + Vector2(face * 35, 34)])
		c.draw_polyline(bracket, paint.edge, 7.0 + blocked * 2.0, true)
		c.draw_polyline(bracket, paint.brass, 3.6 + blocked * 1.5, true)
		c.draw_polyline(bracket, Color(paint.gold, 0.80 + blocked * 0.20), 1.3, true)
		_text(c, font, type_size, "FRONT", Vector2(0, -91), ink, stock)
		_arrow(c, Vector2(face * 44, -95), face, ink, stock, 12.0)
	if cross and phase in [&"tell", &"leap"]:
		var landing: Vector2 = pose.get("landing_point", Vector2.ZERO)
		var takeoff: Vector2 = pose.get("takeoff_point", Vector2.ZERO)
		_landing(c, landing, attack_face, progress if phase == &"tell" else 1.0, live, ink, stock, not interrupted)
		# The takeoff curl stays at its captured floor origin while the disc leaps.
		c.draw_arc(takeoff + Vector2(0, -5), 18, PI + 0.12, TAU - 0.12, 22, Color(stock, 0.88), 5.0, true)
		c.draw_arc(takeoff + Vector2(0, -5), 18, PI + 0.12, TAU - 0.12, 22, ink, 2.0, true)
		_arrow(c, takeoff + Vector2(face * 20, -7), face, ink, stock, 9.0)
	elif phase == &"landing":
		var foot: Vector2 = pose.get("foot_offset", Vector2(0, 43))
		_landing(c, foot, attack_face, 1.0, live, ink, stock)
		_cut_bar(c, Vector2(-22, -79), progress, live, ink, stock)
	elif phase == &"tell":
		_cut_bar(c, Vector2(-22, -79), progress, live, ink, stock)
	elif phase == &"swing":
		# The reach direction is captured before takeoff, never inferred from Skip.
		_arrow(c, center + Vector2(attack_face * 64, 4), attack_face, live, stock, 24.0)
	elif phase == &"open":
		_text(c, font, type_size, "OPEN", Vector2(0, -91), ink, stock)
		var duration := maxf(float(pose.get("opening_duration", 1.0)), 0.001)
		var remaining := clampf(float(pose.get("opening_remaining", 0.0)) / duration, 0.0, 1.0)
		_cut_bar(c, Vector2(-22, -79), remaining, warm, ink, stock)
		for side in [-1.0, 1.0]:
			var mark := PackedVector2Array([center + Vector2(side * 43, -25), center + Vector2(side * 51, -25),
				center + Vector2(side * 51, -15)])
			c.draw_polyline(mark, Color(stock, 0.85), 4.5, true)
			c.draw_polyline(mark, ink, 1.8, true)
	c.draw_set_transform(Vector2.ZERO)

static func _disc_center(body: Dictionary) -> Vector2:
	# Match the existing pressing's drawn spring motion from the same pose.
	# The supplied clock never influences the actor's physical leap or contact.
	var clock := float(body.get("clock", 0.0))
	var face := float(body.get("face", -1.0))
	var phase := String(body.get("phase", "calm"))
	var boil := Vector2(sin(floor(clock * 10.0) * 12.7 + float(int(body.get("seed", 0)) % 71)),
		cos(floor(clock * 10.0) * 7.3)) * 0.7
	var center := Vector2(sin(clock * 1.7) * 1.8, -26.0 - sin(clock * 2.5) * 1.5) + boil
	if phase == "counting":
		var beat := float(body.get("beat", 0.0))
		var anticipation := (float(body.get("count", 0)) + beat) / 4.0
		center += Vector2(-face * anticipation * 6.0, anticipation * 5.0 - sin(minf(beat * 4.0, 1.0) * PI) * 3.0)
	elif phase == "swing":
		var swing := 1.0 - pow(1.0 - float(body.get("swing", 0.0)), 3.0)
		center += Vector2(face * swing * 7.0, -sin(swing * PI) * 3.0)
	elif float(body.get("follow_through", 0.0)) > 0.0:
		center.x += face * float(body.follow_through) * 5.0
	center.x -= face * float(body.get("recoil", 0.0)) * 9.0
	return center

static func _text(c: Node2D, font: Font, size: int, label: String, center: Vector2, ink: Color, stock: Color) -> void:
	var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var origin := center - Vector2(width * 0.5, 0)
	c.draw_string_outline(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(stock, 0.94))
	c.draw_string(font, origin, label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)

static func _arrow(c: Node2D, center: Vector2, face: float, ink: Color, stock: Color, width: float) -> void:
	var arrow := PackedVector2Array([center + Vector2(-face * width * 0.5, 0), center + Vector2(face * width * 0.5, 0),
		center + Vector2(face * (width * 0.5 - 5.0), -4), center + Vector2(face * width * 0.5, 0),
		center + Vector2(face * (width * 0.5 - 5.0), 4)])
	c.draw_polyline(arrow, Color(stock, 0.94), 5.0, true)
	c.draw_polyline(arrow, ink, 2.0, true)

static func _cut_bar(c: Node2D, origin: Vector2, progress: float, live: Color, ink: Color, stock: Color) -> void:
	c.draw_rect(Rect2(origin - Vector2(1, 1), Vector2(46, 5)), Color(stock, 0.88))
	c.draw_rect(Rect2(origin, Vector2(44, 3)), ink.lerp(stock, 0.64))
	if progress > 0.0: c.draw_rect(Rect2(origin, Vector2(44 * progress, 3)), live)
	c.draw_line(origin + Vector2(44, -2), origin + Vector2(44, 5), ink, 1.3, true)

static func _landing(c: Node2D, origin: Vector2, face: float, progress: float, live: Color, ink: Color, stock: Color, threat := true) -> void:
	var rim := PackedVector2Array()
	for index in range(25):
		var angle := float(index) * TAU / 24.0
		rim.append(origin + Vector2(cos(angle) * 25.0, sin(angle) * 5.0))
	c.draw_polyline(rim, Color(stock, 0.92), 5.0, true)
	c.draw_polyline(rim, ink, 1.8, true)
	var mark := live if threat else ink
	c.draw_line(origin + Vector2(-8, -9), origin + Vector2(8, 9), mark, 2.0, true)
	c.draw_line(origin + Vector2(8, -9), origin + Vector2(-8, 9), mark, 2.0, true)
	if threat: _arrow(c, origin + Vector2(face * 40, -11), face, ink, stock, 21.0)
	# The filling cut makes the fixed destination readable without pulsing it.
	c.draw_line(origin + Vector2(-24, 11), origin + Vector2(24, 11), Color(ink, 0.32), 2.0, true)
	if progress > 0.0:
		c.draw_line(origin + Vector2(-24, 11), origin + Vector2(-24 + 48 * progress, 11), mark, 2.5, true)
