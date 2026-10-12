extends RefCounted
## The ink kit for the art-direction test (ink_test.gd): the canon's "detail
## language" (docs/art/direction.html, density target) as brush marks. Thick
## tapering ink that fills its shape, hatching on the shadowed third, cross-
## hatch in the deep shadows, grime, stains and flat colour under texture.
##
## Marks are gathered as triangles and sent as one draw call per run, with a
## feathered edge on every stroke so they stay smooth at any window size.
## Every mark is deterministic: it receives its seed and paint, and no clock,
## camera, collision or game state is read here.

const Geometry := preload("res://scripts/press_geometry.gd")

const FEATHER := 0.9

var canvas: CanvasItem
var batch := Geometry.new()
var rng := RandomNumberGenerator.new()
## With a tape, nothing is drawn: triangle runs and lettering are recorded in
## order, to be played back onto any canvas (play). Still scenery is drawn
## once this way and kept.
var tape: Array = []
var recording := false

func _init(target: CanvasItem, seed_value := 1, record := false) -> void:
	canvas = target
	rng.seed = seed_value
	recording = record

## Sends what has been gathered. Call before any other draw call on the canvas.
func flush() -> void:
	if batch.is_empty():
		return
	if recording:
		tape.append([&"triangles", batch.points.duplicate(), batch.colors.duplicate(), batch.indices.duplicate()])
		batch.clear()
		return
	batch.flush(canvas)

## Plays a recorded tape onto `target`, inside its _draw().
static func play(target: CanvasItem, recorded: Array) -> void:
	var item := target.get_canvas_item()
	for entry in recorded:
		match entry[0]:
			&"triangles":
				RenderingServer.canvas_item_add_triangle_array(item, entry[3], entry[1], entry[2])
			&"text":
				target.draw_set_transform(entry[1], entry[2])
				target.draw_string(entry[3], entry[4], entry[5], entry[6], entry[7], entry[8], entry[9])
				target.draw_set_transform(Vector2.ZERO)

func reseed(seed_value: int) -> void:
	rng.seed = seed_value

func rand(low: float, high: float) -> float:
	return rng.randf_range(low, high)

func chance(probability: float) -> bool:
	return rng.randf() < probability

# -- text -----------------------------------------------------------------------

## Type set on the page in the current ink. Flushes the gathered marks first so
## lettering lands above what was drawn before it.
func text(font: Font, at: Vector2, words: String, size: int, paint: Color, angle := 0.0,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	_letter(at, angle, font, Vector2.ZERO, words, align, width, size, paint)

## Letters set one by one along an arc, like a label's rim type.
func arc_text(font: Font, center: Vector2, radius: float, start_angle: float, words: String,
		size: int, paint: Color, tracking := 1.0) -> void:
	var angle := start_angle
	for character in words:
		var advance := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * tracking
		var step := advance / radius
		var at := center + Vector2.from_angle(angle + step * 0.5) * radius
		_letter(at, angle + step * 0.5 + PI * 0.5, font, Vector2(-advance * 0.5 / tracking, 0), character,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, paint)
		angle += step

func _letter(at: Vector2, angle: float, font: Font, offset: Vector2, words: String, align: int,
		width: float, size: int, paint: Color) -> void:
	flush()
	if recording:
		tape.append([&"text", at, angle, font, offset, words, align, width, size, paint])
		return
	canvas.draw_set_transform(at, angle)
	canvas.draw_string(font, offset, words, align, width, size, paint)
	canvas.draw_set_transform(Vector2.ZERO)

# -- the basic marks --------------------------------------------------------------

## A ribbon through `points` with one width per point: the core of every
## stroke. A transparent feather keeps both edges soft.
func ribbon(points: PackedVector2Array, widths: PackedFloat32Array, paint: Color,
		alphas := PackedFloat32Array(), feather := FEATHER) -> void:
	var count := points.size()
	if count < 2:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var normals := PackedVector2Array()
	left.resize(count)
	right.resize(count)
	normals.resize(count)
	for i in count:
		var back := (points[i] - points[maxi(i - 1, 0)]).normalized()
		var ahead := (points[mini(i + 1, count - 1)] - points[i]).normalized()
		if back.is_zero_approx():
			back = ahead
		if ahead.is_zero_approx():
			ahead = back
		var tangent := (back + ahead).normalized()
		if tangent.is_zero_approx():
			tangent = ahead
		var normal := tangent.orthogonal()
		var miter := 1.0 / maxf(absf(normal.dot(ahead.orthogonal())), 0.5)
		var half := widths[i] * 0.5 * miter
		normals[i] = normal
		left[i] = points[i] + normal * half
		right[i] = points[i] - normal * half
	var base := batch.points.size()
	for i in count:
		var tint := paint
		if not alphas.is_empty():
			tint = Color(paint, paint.a * alphas[i])
		var clear := Color(tint, 0.0)
		batch.points.append(left[i])
		batch.colors.append(tint)
		batch.points.append(right[i])
		batch.colors.append(tint)
		batch.points.append(left[i] + normals[i] * feather)
		batch.colors.append(clear)
		batch.points.append(right[i] - normals[i] * feather)
		batch.colors.append(clear)
	for i in count - 1:
		var a := base + i * 4
		var b := a + 4
		# Body, then the two feathered edges.
		batch.indices.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b,
			a + 2, a, b + 2, a, b, b + 2, a + 1, a + 3, b + 1, a + 3, b + 3, b + 1]))

## A hand-drawn stroke: resampled, wobbled, and tapered at both ends. `taper`
## is the share of the length each end spends thinning to `tip` × width.
func stroke(points: PackedVector2Array, width: float, paint: Color, wobble := 0.6,
		taper := 0.22, tip := 0.18, step := 5.0) -> void:
	# A dozen or so joints carry a hand's wobble; more only costs triangles.
	var length := 0.0
	for i in range(1, points.size()):
		length += points[i].distance_to(points[i - 1])
	var line := resample(points, maxf(step, length / 14.0))
	if line.size() < 2:
		return
	line = wobbled(line, wobble)
	var widths := PackedFloat32Array()
	widths.resize(line.size())
	var pressure := rand(0.0, TAU)
	for i in line.size():
		var t := float(i) / float(line.size() - 1)
		var shape := 1.0
		if taper > 0.0:
			shape = minf(smoothstep(0.0, taper, t), smoothstep(1.0, 1.0 - taper, t))
			shape = lerpf(tip, 1.0, shape)
		widths[i] = maxf(width * shape * (1.0 + sin(pressure + t * 5.0) * 0.12), 0.35)
	ribbon(line, widths, paint)

## A straight hand stroke from a to b.
func line(a: Vector2, b: Vector2, width: float, paint: Color, wobble := 0.6, taper := 0.22) -> void:
	stroke(PackedVector2Array([a, b]), width, paint, wobble, taper)

## A quick, even-width line (hatching, rules, grain). Cheap: no resampling.
func hair(a: Vector2, b: Vector2, width: float, paint: Color) -> void:
	var tilt := Vector2(rand(-0.4, 0.4), rand(-0.4, 0.4))
	ribbon(PackedVector2Array([a, a.lerp(b, 0.5) + tilt, b]),
		PackedFloat32Array([width * 0.55, width, width * 0.6]), paint)

## A closed outline that is heavier at its corners and overshoots them a
## little, like a pen that lifted at every joint.
func outline(polygon: PackedVector2Array, width: float, paint: Color, wobble := 0.5, overshoot := 1.5, corners := true) -> void:
	var count := polygon.size()
	for i in count:
		var a := polygon[i]
		var b := polygon[(i + 1) % count]
		var along := (b - a).normalized()
		var first := a - along * rand(0.0, overshoot)
		var last := b + along * rand(0.0, overshoot)
		var line_points := resample(PackedVector2Array([first, last]), maxf(6.0, first.distance_to(last) / 10.0))
		line_points = wobbled(line_points, wobble)
		var widths := PackedFloat32Array()
		widths.resize(line_points.size())
		for j in line_points.size():
			var t := float(j) / float(maxi(line_points.size() - 1, 1))
			widths[j] = width * lerpf(0.78, 1.16, absf(t - 0.5) * 2.0)
		ribbon(line_points, widths, paint)
	# Heavy joints only where the line is heavy enough to show them.
	if corners and width >= 1.8:
		for corner in polygon:
			blob(corner, width * 0.62, paint, 5)

## A main outline drawn twice, the way a quick hand goes back over a shape:
## the heavy line, then a lighter, slightly wandering second pass.
func sketch(polygon: PackedVector2Array, width: float, paint: Color) -> void:
	outline(polygon, width, paint, 0.9, 4.0)
	var ghost := PackedVector2Array()
	var drift := Vector2(rand(-1.2, 1.2), rand(-1.2, 1.2))
	for point in polygon:
		ghost.append(point + drift + Vector2(rand(-0.8, 0.8), rand(-0.8, 0.8)))
	outline(ghost, width * 0.35, Color(paint, paint.a * 0.45), 1.4, 6.0, false)

## An open outline: one stroke through every point, heavy at its bends.
func path(points: PackedVector2Array, width: float, paint: Color, wobble := 0.5) -> void:
	stroke(points, width, paint, wobble, 0.12, 0.35)

## A small irregular dot of ink.
func blob(center: Vector2, radius: float, paint: Color, sides := 7) -> void:
	if radius <= 0.2:
		return
	var ring := PackedVector2Array()
	var turn := rand(0.0, TAU)
	for i in sides:
		ring.append(center + Vector2.from_angle(turn + TAU * i / sides) * radius * rand(0.78, 1.12))
	fill(ring, paint)

## A flat. Feathered so an unlined edge stays smooth.
func fill(polygon: PackedVector2Array, paint: Color, feather := FEATHER) -> void:
	if polygon.size() < 3:
		return
	var triangles := Geometry2D.triangulate_polygon(polygon)
	if triangles.is_empty():
		return
	var base := batch.points.size()
	batch.points.append_array(polygon)
	for i in polygon.size():
		batch.colors.append(paint)
	for index in triangles:
		batch.indices.append(base + index)
	if feather <= 0.0:
		return
	var count := polygon.size()
	var clockwise := Geometry2D.is_polygon_clockwise(polygon)
	var ring := base + count
	for i in count:
		var back := (polygon[i] - polygon[(i - 1 + count) % count]).normalized()
		var ahead := (polygon[(i + 1) % count] - polygon[i]).normalized()
		var normal := (back + ahead).normalized().orthogonal()
		if clockwise:
			normal = -normal
		batch.points.append(polygon[i] + normal * feather)
		batch.colors.append(Color(paint, 0.0))
	for i in count:
		var j := (i + 1) % count
		batch.indices.append_array(PackedInt32Array([base + i, ring + i, base + j, base + j, ring + i, ring + j]))

## A flat that sits a little off its line work: print misregistration.
func misregistered(polygon: PackedVector2Array, paint: Color, offset := Vector2(1.6, -1.2)) -> void:
	var moved := PackedVector2Array()
	for point in polygon:
		moved.append(point + offset)
	fill(moved, paint)

func rect_points(box: Rect2) -> PackedVector2Array:
	return PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)])

## A box with its corners nudged so nothing on the page is ruler-straight.
func rough_rect(box: Rect2, jitter := 1.2) -> PackedVector2Array:
	var points := rect_points(box)
	for i in points.size():
		points[i] += Vector2(rand(-jitter, jitter), rand(-jitter, jitter))
	return points

func ellipse_points(center: Vector2, radii: Vector2, rotation := 0.0, count := 36, start := 0.0, end := TAU) -> PackedVector2Array:
	var points := PackedVector2Array()
	var closed := is_equal_approx(end - start, TAU)
	var total := count if closed else count + 1
	for i in total:
		var angle := lerpf(start, end, float(i) / float(count))
		points.append(center + (Vector2(cos(angle), sin(angle)) * radii).rotated(rotation))
	return points

## Outline plus flat in one call: the most common mark on the page.
func shape(polygon: PackedVector2Array, flat: Color, edge: Color, width := 2.6) -> void:
	fill(polygon, flat)
	outline(polygon, width, edge)

# -- light --------------------------------------------------------------------------

## A wash over `area` whose strength varies across the page, like a second
## printing in a tint: `strength(point)` (0..1) scales the paint's alpha at
## every corner of a `cell`-sized grid, blended smoothly between them.
func wash(area: Rect2, cell: float, paint: Color, strength: Callable) -> void:
	var columns := int(ceil(area.size.x / cell)) + 1
	var rows := int(ceil(area.size.y / cell)) + 1
	var base := batch.points.size()
	for row in rows:
		for column in columns:
			var at := area.position + Vector2(minf(column * cell, area.size.x), minf(row * cell, area.size.y))
			batch.points.append(at)
			batch.colors.append(Color(paint, paint.a * clampf(float(strength.call(at)), 0.0, 1.0)))
	for row in rows - 1:
		for column in columns - 1:
			var i := base + row * columns + column
			batch.indices.append_array(PackedInt32Array([i, i + 1, i + columns, i + 1, i + columns + 1, i + columns]))

## A soft round light: full `paint` at the centre, falling away to nothing at
## `radius`, held a little brighter over its inner `core`.
func glow(center: Vector2, radius: float, paint: Color, core := 0.3, sides := 24) -> void:
	if radius <= 0.5 or paint.a <= 0.0:
		return
	var base := batch.points.size()
	batch.points.append(center)
	batch.colors.append(paint)
	for ring: Array in [[core, 0.55], [1.0, 0.0]]:
		for i in sides:
			batch.points.append(center + Vector2.from_angle(TAU * i / sides) * radius * float(ring[0]))
			batch.colors.append(Color(paint, paint.a * float(ring[1])))
	for i in sides:
		var j := (i + 1) % sides
		batch.indices.append_array(PackedInt32Array([base, base + 1 + i, base + 1 + j]))
		var inner := base + 1
		var outer := base + 1 + sides
		batch.indices.append_array(PackedInt32Array([inner + i, outer + i, inner + j, inner + j, outer + i, outer + j]))

## A convex shape coloured corner by corner: a beam fading along its length.
func graded(polygon: PackedVector2Array, colours: PackedColorArray) -> void:
	if polygon.size() < 3 or colours.size() != polygon.size():
		return
	var base := batch.points.size()
	batch.points.append_array(polygon)
	batch.colors.append_array(colours)
	for i in range(1, polygon.size() - 1):
		batch.indices.append_array(PackedInt32Array([base, base + i, base + i + 1]))

# -- hatching -------------------------------------------------------------------

## Parallel hand hatching clipped to `polygon`. Lines start and stop a little
## short of the edges, as a pen does.
func hatch(polygon: PackedVector2Array, angle: float, spacing: float, width: float, paint: Color,
		coverage := 1.0) -> void:
	if polygon.size() < 3:
		return
	var direction := Vector2.from_angle(angle)
	var across := direction.orthogonal()
	var low := INF
	var high := -INF
	var reach := 0.0
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= polygon.size()
	for point in polygon:
		var d := (point - center).dot(across)
		low = minf(low, d)
		high = maxf(high, d)
		reach = maxf(reach, (point - center).length())
	var offset := low + rand(0.0, spacing)
	while offset < high:
		if rng.randf() <= coverage:
			var origin := center + across * offset
			var a := origin - direction * (reach + 4.0)
			var b := origin + direction * (reach + 4.0)
			for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), polygon):
				if piece.size() < 2:
					continue
				var start: Vector2 = piece[0]
				var finish: Vector2 = piece[piece.size() - 1]
				var length := start.distance_to(finish)
				if length < 2.0:
					continue
				var inset := minf(length * 0.18, 2.4)
				var along := (finish - start) / length
				start += along * rand(-0.6, inset)
				finish -= along * rand(-0.6, inset)
				hair(start, finish, width * rand(0.8, 1.15), paint)
		offset += spacing * rand(0.82, 1.18)

## Two passes of hatching at right angles: the deep shadows.
func crosshatch(polygon: PackedVector2Array, angle: float, spacing: float, width: float, paint: Color) -> void:
	hatch(polygon, angle, spacing, width, paint)
	hatch(polygon, angle + PI * 0.5, spacing * 1.15, width * 0.9, paint, 0.85)

## Hatching on the shadowed part of a shape: the side away from `light`
## (a direction), `share` of its width.
func shade(polygon: PackedVector2Array, light: Vector2, share: float, spacing: float, width: float, paint: Color,
		angle := -PI * 0.25, cross := false) -> void:
	var cut := shadow_side(polygon, light, share)
	for piece in cut:
		if cross:
			crosshatch(piece, angle, spacing, width, paint)
		else:
			hatch(piece, angle, spacing, width, paint)

## The part of a polygon facing away from `light`.
func shadow_side(polygon: PackedVector2Array, light: Vector2, share: float) -> Array[PackedVector2Array]:
	var away := -light.normalized()
	var low := INF
	var high := -INF
	for point in polygon:
		var d := point.dot(away)
		low = minf(low, d)
		high = maxf(high, d)
	var threshold := lerpf(high, low, share)
	var cross_dir := away.orthogonal()
	var far := 4000.0
	var origin := away * threshold
	var half_plane := PackedVector2Array([
		origin + cross_dir * far, origin + cross_dir * far + away * far,
		origin - cross_dir * far + away * far, origin - cross_dir * far,
	])
	var result: Array[PackedVector2Array] = []
	for piece in Geometry2D.intersect_polygons(polygon, half_plane):
		result.append(piece)
	return result

# -- grime --------------------------------------------------------------------------

## Flecks: tiny ticks and dots of dirt scattered over a box.
func flecks(area: Rect2, count: int, paint: Color, size := 1.2) -> void:
	for i in count:
		var at := area.position + Vector2(rng.randf() * area.size.x, rng.randf() * area.size.y)
		if chance(0.55):
			blob(at, size * rand(0.4, 1.0), Color(paint, paint.a * rand(0.45, 1.0)), 5)
		else:
			var tick := Vector2.from_angle(rand(0.0, TAU)) * size * rand(1.0, 2.6)
			hair(at - tick, at + tick, size * 0.55, Color(paint, paint.a * rand(0.4, 0.9)))

## Flecks inside a polygon only.
func flecks_in(polygon: PackedVector2Array, count: int, paint: Color, size := 1.2) -> void:
	var box := bounds(polygon)
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 6:
		tries += 1
		var at := box.position + Vector2(rng.randf() * box.size.x, rng.randf() * box.size.y)
		if not Geometry2D.is_point_in_polygon(at, polygon):
			continue
		placed += 1
		if chance(0.6):
			blob(at, size * rand(0.4, 1.0), Color(paint, paint.a * rand(0.45, 1.0)), 5)
		else:
			var tick := Vector2.from_angle(rand(0.0, TAU)) * size * rand(1.0, 2.4)
			hair(at - tick, at + tick, size * 0.5, Color(paint, paint.a * rand(0.4, 0.9)))

## A water streak run down from a sill or a seam: thin, fading as it falls.
func streak(top: Vector2, length: float, width: float, paint: Color) -> void:
	var points := PackedVector2Array()
	var widths := PackedFloat32Array()
	var alphas := PackedFloat32Array()
	var steps := maxi(int(length / 6.0), 2)
	var drift := rand(-1.5, 1.5)
	for i in steps + 1:
		var t := float(i) / float(steps)
		points.append(top + Vector2(sin(t * 3.0 + drift) * 1.2 + drift * t, length * t))
		widths.append(width * lerpf(1.0, 0.35, t) * rand(0.8, 1.2))
		alphas.append(lerpf(1.0, 0.0, t * t))
	ribbon(points, widths, paint, alphas)

## An irregular stain: a soft blotch with a faint tide-line.
func stain(center: Vector2, radius: float, paint: Color, ring := true) -> void:
	var points := PackedVector2Array()
	var sides := 18
	var phase := rand(0.0, TAU)
	var lumps := rand(2.0, 4.0)
	for i in sides:
		var angle := TAU * i / sides
		var r := radius * (1.0 + sin(angle * lumps + phase) * 0.18 + rand(-0.08, 0.08))
		points.append(center + Vector2(cos(angle), sin(angle) * rand(0.72, 0.9)) * r)
	fill(points, paint, 2.5)
	if ring:
		var edge := points.duplicate()
		edge.append(points[0])
		var widths := PackedFloat32Array()
		widths.resize(edge.size())
		widths.fill(0.9)
		ribbon(edge, widths, Color(paint, minf(paint.a * 2.2, 1.0)))

## Stipple: a sprinkle of dots, denser toward `toward` (a point) if given.
func stipple(polygon: PackedVector2Array, count: int, paint: Color, size := 0.9) -> void:
	var box := bounds(polygon)
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 5:
		tries += 1
		var at := box.position + Vector2(rng.randf() * box.size.x, rng.randf() * box.size.y)
		if Geometry2D.is_point_in_polygon(at, polygon):
			blob(at, size * rand(0.5, 1.1), paint, 4)
			placed += 1

## A crack: a jagged line that forks once or twice.
func crack(start: Vector2, direction: Vector2, length: float, width: float, paint: Color, forks := 1) -> void:
	var points := PackedVector2Array([start])
	var at := start
	var heading := direction.normalized()
	var steps := maxi(int(length / 7.0), 2)
	for i in steps:
		heading = heading.rotated(rand(-0.6, 0.6)).lerp(direction.normalized(), 0.4).normalized()
		at += heading * length / steps
		points.append(at)
	stroke(points, width, paint, 0.2, 0.0, 1.0, 100.0)
	if forks > 0 and points.size() > 2:
		var from := points[rng.randi_range(1, points.size() - 2)]
		crack(from, direction.rotated(rand(-0.9, 0.9)), length * 0.45, width * 0.7, paint, forks - 1)

# -- geometry helpers ---------------------------------------------------------------

static func bounds(polygon: PackedVector2Array) -> Rect2:
	var box := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		box = box.expand(point)
	return box

## Points every `step` pixels along a polyline, keeping its corners.
static func resample(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 2:
		return points
	result.append(points[0])
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var length := a.distance_to(b)
		var pieces := maxi(int(ceil(length / step)), 1)
		for j in range(1, pieces + 1):
			result.append(a.lerp(b, float(j) / pieces))
	return result

## A gentle hand wobble: a slow bend plus a little tremor, zero at the ends'
## average so the stroke still meets what it was aimed at.
func wobbled(points: PackedVector2Array, amount: float) -> PackedVector2Array:
	if amount <= 0.0 or points.size() < 3:
		return points
	var result := PackedVector2Array()
	var bend := rand(-1.0, 1.0) * amount
	var phase := rand(0.0, TAU)
	var count := points.size()
	for i in count:
		var t := float(i) / float(count - 1)
		var ahead := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		var normal := ahead.orthogonal()
		var offset := sin(t * PI) * bend + sin(t * 9.0 + phase) * amount * 0.35 + rand(-0.25, 0.25) * amount
		result.append(points[i] + normal * offset)
	return result

## A quadratic curve as points.
static func bezier(a: Vector2, control: Vector2, b: Vector2, count := 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count + 1:
		var t := float(i) / float(count)
		points.append(a * (1.0 - t) * (1.0 - t) + control * 2.0 * t * (1.0 - t) + b * t * t)
	return points

## A cubic curve as points.
static func cubic(a: Vector2, c1: Vector2, c2: Vector2, b: Vector2, count := 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in count + 1:
		var t := float(i) / float(count)
		var u := 1.0 - t
		points.append(a * u * u * u + c1 * 3.0 * u * u * t + c2 * 3.0 * u * t * t + b * t * t * t)
	return points

## A sagging cable between two points.
static func sag(a: Vector2, b: Vector2, drop: float, count := 18) -> PackedVector2Array:
	return bezier(a, (a + b) * 0.5 + Vector2(0, drop * 2.0), b, count)
