extends RefCounted
## Gesture first, then a short impression at each supplied point of contact.
## Every input is presentation data; the Press neither finds nor damages targets.

const CONTACT_TIME := 0.14
const BURST_TIME := 0.085
const PINK := Color("ed987b")
const BRASS := Color("e5bd70")
const LIGHT := Color("fff0ce")
const SHADOW := Color("183137")

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var age := maxf(float(pose.get("age", 0.0)), 0.0)
	var life := maxf(float(pose.get("life", 0.3)), 0.001)
	var hit_radius := maxf(float(pose.get("hit_radius", 120.0)), 1.0)
	var echo_radius := maxf(float(pose.get("echo_radius", hit_radius)), 1.0)
	var big := bool(pose.get("big", false))
	var combo_step := clampi(int(pose.get("combo_step", 1)), 1, 3)
	var facing := -1.0 if float(pose.get("facing", 1.0)) < 0.0 else 1.0
	var phase := float(int(pose.get("seed", 0)) % 997) * 0.013
	var contact := StringName(pose.get("contact", &"miss"))
	var color := ink.lerp(PINK, 0.65) if big else ink.lerp(BRASS, 0.20)
	var progress := clampf(age / CONTACT_TIME, 0.0, 1.0)
	var strength := pow(1.0 - progress, 1.5)
	if strength > 0.0:
		# Four faint cuts acknowledge radial reach without turning the attack into
		# an expanding reticle. The arm's gesture carries the visual emphasis.
		var edge_strength := maxf(1.0 - age / 0.065, 0.0)
		for index in 4:
			var start := phase + index * TAU / 4.0
			var points := _arc(hit_radius, start, 0.30, phase + index, 7)
			canvas.draw_polyline(points, Color(color, edge_strength * 0.14), 1.0, true)
		_combo_stroke(canvas, combo_step, facing, hit_radius, progress, strength, color, stock, contact)
	# These points are the targets actually struck. A miss cannot paint a hit
	# burst at the end of the gesture; guarded contact has a smaller hard chip.
	for supplied in pose.get("impacts", []):
		if not supplied is Dictionary or not supplied.get("offset") is Vector2:
			continue
		_impact(canvas, supplied.offset, StringName(supplied.get("kind", &"hit")),
			age, combo_step == 3 or big, facing, phase)
	# This slow ripple describes a launch or resonant air, not delayed damage.
	if bool(pose.get("launched", false)) or echo_radius > hit_radius + 12.0:
		var echo := clampf(age / life, 0.0, 1.0)
		var echo_strength := pow(1.0 - echo, 2.0) * (0.24 if big else 0.17)
		var echo_reach := echo_radius * (0.25 + 0.75 * echo)
		for index in 3:
			var points := _arc(echo_reach, phase + index * TAU / 3.0, TAU * 0.23, phase + index + 9, 15)
			canvas.draw_polyline(points, Color(color, echo_strength), 1.3, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func _combo_stroke(canvas: CanvasItem, step: int, face: float, radius: float, progress: float, strength: float, ink: Color, stock: Color, contact: StringName) -> void:
	# A completed cut is visible on frame one. Its trailing edge settles after
	# contact, never grows into a later damage radius.
	var points := PackedVector2Array()
	match step:
		1:
			points = PackedVector2Array([Vector2(radius * 0.27, -10), Vector2(radius * 0.64, -5),
				Vector2(radius * 0.94, -1), Vector2(radius * 0.81, 5)])
		2:
			points = _arc(radius * 0.82, -1.35 + progress * 0.12, 2.38, 2.8, 25)
		3:
			points = PackedVector2Array([Vector2(radius * 0.35, -radius * 0.63),
				Vector2(radius * 0.64, -radius * 0.34), Vector2(radius * 0.78, 2),
				Vector2(radius * 0.69, radius * 0.28)])
	for index in points.size(): points[index].x *= face
	var weight := 0.40 if contact == &"miss" else (0.64 if contact == &"guard" else 1.0)
	var width := (5.0 if step == 3 else 3.3) * (0.68 if contact == &"miss" else 1.0)
	canvas.draw_polyline(points,Color(SHADOW,strength * weight * 0.58),width + 2.2,true)
	canvas.draw_polyline(points,Color(ink,strength * weight * 0.82),width,true)
	canvas.draw_polyline(points,Color(LIGHT,strength * weight * 0.76),1.0,true)
	if step == 2:
		var echo := _arc(radius * 0.66, -0.85, 1.50, 1.2, 20)
		for index in echo.size(): echo[index].x *= face
		canvas.draw_polyline(echo, Color(ink, strength * weight * 0.26), 1.3, true)
	elif step == 3:
		var follow := points.duplicate()
		for index in follow.size(): follow[index] += Vector2(-face * 9.0, -3.0)
		canvas.draw_polyline(follow, Color(ink, strength * weight * 0.25), 1.3, true)

static func _impact(canvas: CanvasItem, point: Vector2, kind: StringName, age: float, heavy: bool, face: float, phase: float) -> void:
	var progress := clampf(age / BURST_TIME, 0.0, 1.0)
	var strength := pow(1.0 - progress, 1.35)
	if strength <= 0.0:
		return
	var guarded := kind == &"guard"
	var reach := (10.0 if guarded else (21.0 if heavy else 15.0)) * (0.75 + progress * 0.55)
	var axis := (point.normalized() if point.length_squared() > 1.0 else Vector2(face, 0.0))
	var side := axis.orthogonal()
	var core := PackedVector2Array([point - axis * 3.0, point + side * (5.0 if guarded else 7.0),
		point + axis * (5.0 if guarded else 9.0), point - side * (4.0 if guarded else 6.0)])
	canvas.draw_colored_polygon(core, Color(BRASS if guarded else LIGHT, strength * 0.96))
	var outline := core.duplicate()
	outline.append(core[0])
	canvas.draw_polyline(outline, Color(SHADOW, strength * 0.72), 1.1, true)
	canvas.draw_line(point - side * reach * 0.56, point + side * reach * 0.56,
		Color(SHADOW, strength * 0.72), 3.6 if guarded else 4.5, true)
	canvas.draw_line(point - side * reach * 0.56, point + side * reach * 0.56,
		Color(LIGHT, strength * 0.92), 1.6 if guarded else 2.5, true)
	for index in (4 if guarded else (7 if heavy else 5)):
		var angle := phase + index * 2.39996
		var direction := Vector2.from_angle(angle)
		var start := point + direction * (reach * 0.38 + progress * 3.0)
		var end := point + direction * reach * (0.75 + 0.24 * sin(index * 3.7))
		canvas.draw_line(start, end, Color(SHADOW, strength * 0.60), 3.4 if guarded else (4.0 if heavy else 3.5), true)
		canvas.draw_line(start, end, Color(BRASS if index % 2 == 0 else LIGHT, strength * 0.88),
			1.7 if guarded else (2.3 if heavy else 1.8), true)
	if heavy and not guarded:
		canvas.draw_line(point - axis * reach * 0.38, point + axis * reach,
			Color(LIGHT, strength * 0.72), 3.0, true)

static func _arc(radius: float, start: float, sweep: float, seed: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := start + sweep * float(index) / float(count - 1)
		var bite := (0.5 + sin(seed * 3.1 + index * 7.7) * 0.5) * minf(radius * 0.018, 2.0)
		points.append(Vector2.from_angle(angle) * (radius - bite))
	return points
