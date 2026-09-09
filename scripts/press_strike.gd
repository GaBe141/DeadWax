extends RefCounted
## Radial contact in one impression, followed by a quiet atmospheric echo.
## Every input is presentation data; the Press neither finds nor damages targets.

const CONTACT_TIME := 0.14
const CONTACT_DRIFT := 6.0
const BURST_TIME := 0.055
const PINK := Color(0.90, 0.25, 0.50)

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var age := maxf(float(pose.get("age", 0.0)), 0.0)
	var life := maxf(float(pose.get("life", 0.3)), 0.001)
	var hit_radius := maxf(float(pose.get("hit_radius", 120.0)), 1.0)
	var echo_radius := maxf(float(pose.get("echo_radius", hit_radius)), 1.0)
	var big := bool(pose.get("big", false))
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
			canvas.draw_polyline(points, Color(stock, strength * 0.45), 5.5 if big else 4.5, true)
			canvas.draw_polyline(points, Color(color, strength * 0.90), 3.6 if big else 2.6, true)
		var burst := maxf(1.0 - age / BURST_TIME, 0.0)
		for index in 8:
			var angle := phase + index * TAU / 8.0 + 0.18
			var direction := Vector2.from_angle(angle)
			canvas.draw_line(direction * (hit_radius - 13.0), direction * (hit_radius - 4.0),
				Color(color, burst * 0.55), 2.2 if big else 1.6, true)
	# This slow ripple describes a launch or resonant air, not delayed damage.
	if bool(pose.get("launched", false)) or echo_radius > hit_radius + 12.0:
		var echo := clampf(age / life, 0.0, 1.0)
		var echo_strength := pow(1.0 - echo, 2.0) * (0.24 if big else 0.17)
		var echo_reach := echo_radius * (0.25 + 0.75 * echo)
		for index in 3:
			var points := _arc(echo_reach, phase + index * TAU / 3.0, TAU * 0.23, phase + index + 9, 15)
			canvas.draw_polyline(points, Color(color, echo_strength), 1.3, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func _arc(radius: float, start: float, sweep: float, seed: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := start + sweep * float(index) / float(count - 1)
		var bite := (0.5 + sin(seed * 3.1 + index * 7.7) * 0.5) * minf(radius * 0.018, 2.0)
		points.append(Vector2.from_angle(angle) * (radius - bite))
	return points
