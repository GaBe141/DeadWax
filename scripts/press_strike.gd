extends RefCounted
## Radial contact in one impression, followed by a quiet atmospheric echo.
## Every input is presentation data; the Press neither finds nor damages targets.

const CONTACT_TIME := 0.14
const CONTACT_DRIFT := 6.0
const BURST_TIME := 0.055
const PINK := Color("ed987b")

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var age := maxf(float(pose.get("age", 0.0)), 0.0)
	var life := maxf(float(pose.get("life", 0.3)), 0.001)
	var hit_radius := maxf(float(pose.get("hit_radius", 120.0)), 1.0)
	var echo_radius := maxf(float(pose.get("echo_radius", hit_radius)), 1.0)
	var big := bool(pose.get("big", false))
	var combo_step := clampi(int(pose.get("combo_step", 1)), 1, 3)
	var facing := -1.0 if float(pose.get("facing", 1.0)) < 0.0 else 1.0
	var phase := float(int(pose.get("seed", 0)) % 997) * 0.013
	var color := ink.lerp(PINK, 0.65) if big else ink
	var contact := clampf(age / CONTACT_TIME, 0.0, 1.0)
	var strength := pow(1.0 - contact, 1.5)
	var radius := hit_radius + CONTACT_DRIFT * (1.0 - pow(1.0 - contact, 2.0))
	if strength > 0.0:
		# Small gaps and bitten edges keep the footprint a struck print, not a reticle.
		for index in 6:
			var start := phase + index * TAU / 6.0
			var sweep := (0.74 + sin(index * 8.3 + phase) * 0.08) * TAU / 6.0
			var points := _arc(radius, start, sweep, phase + index, 12)
			# An opaque brush core and a dry inner edge read against the painted
			# world. The outer points still mark the same immediate contact radius.
			_ribbon(canvas,points,6.0 if big else 3.8,Color(color,strength*0.75))
			canvas.draw_polyline(points,Color(Color("f4ddb0"),strength*0.70),1.5,true)
		var burst := maxf(1.0 - age / BURST_TIME, 0.0)
		for index in 8:
			var angle := phase + index * TAU / 8.0 + 0.18
			var direction := Vector2.from_angle(angle)
			canvas.draw_line(direction * (hit_radius - 13.0), direction * (hit_radius - 4.0),
				Color(color, burst * 0.55), 2.2 if big else 1.6, true)
		_combo_stroke(canvas, combo_step, facing, hit_radius, contact, strength, color, stock)
	# This slow ripple describes a launch or resonant air, not delayed damage.
	if bool(pose.get("launched", false)) or echo_radius > hit_radius + 12.0:
		var echo := clampf(age / life, 0.0, 1.0)
		var echo_strength := pow(1.0 - echo, 2.0) * (0.24 if big else 0.17)
		var echo_reach := echo_radius * (0.25 + 0.75 * echo)
		for index in 3:
			var points := _arc(echo_reach, phase + index * TAU / 3.0, TAU * 0.23, phase + index + 9, 15)
			canvas.draw_polyline(points, Color(color, echo_strength), 1.3, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func _combo_stroke(canvas: CanvasItem, step: int, face: float, radius: float, progress: float, strength: float, ink: Color, stock: Color) -> void:
	# These inner cuts distinguish the gesture. The same outer 120px footprint
	# arrives on every first frame; none of these marks adds reach or contact.
	var points := PackedVector2Array()
	match step:
		1:
			points = PackedVector2Array([Vector2(radius * 0.68, -7), Vector2(radius * 0.91, -1), Vector2(radius * 0.80, 7)])
		2:
			points = _arc(radius * 0.82, -1.5 + progress * 0.20, 2.5, 2.8, 25)
		3:
			points = PackedVector2Array([Vector2(radius * 0.64, -radius * 0.33),
				Vector2(radius * 0.85, 0), Vector2(radius * 0.64, radius * 0.29)])
	for index in points.size(): points[index].x *= face
	canvas.draw_polyline(points,Color(Color("183137"),strength*0.40),7.5 if step==3 else 5.5,true)
	canvas.draw_polyline(points,Color(ink,strength*0.90),4.6 if step==3 else 3.2,true)
	canvas.draw_polyline(points,Color(Color("f4ddb0"),strength*0.55),1.0,true)
	if step == 2:
		var echo := _arc(radius * 0.71, -1.1, 1.7, 1.2, 20)
		for index in echo.size(): echo[index].x *= face
		canvas.draw_polyline(echo, Color(ink, strength * 0.35), 1.4, true)
	elif step == 3:
		for side in [-1.0, 1.0]:
			var start := Vector2(face * radius * 0.82, side * radius * 0.32)
			canvas.draw_line(start, start + Vector2(face * radius * 0.09, side * radius * 0.045), Color(ink, strength * 0.75), 3.0, true)

static func _arc(radius: float, start: float, sweep: float, seed: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := start + sweep * float(index) / float(count - 1)
		var bite := (0.5 + sin(seed * 3.1 + index * 7.7) * 0.5) * minf(radius * 0.018, 2.0)
		points.append(Vector2.from_angle(angle) * (radius - bite))
	return points

static func _ribbon(canvas: CanvasItem, points: PackedVector2Array, width: float, color: Color) -> void:
	var stroke := points.duplicate()
	for index in range(points.size()-1,-1,-1):
		stroke.append(points[index]-points[index].normalized()*width*(0.65+0.25*sin(index*1.7)))
	canvas.draw_colored_polygon(stroke,color)
