extends RefCounted
## One draw call for many marks. Godot 4.7's GL Compatibility renderer gives
## every polygon command its own draw call, and an antialiased polyline is
## three of them (its strip and two feathered edges), so a two-pass brush
## stroke costs six. This gathers the same triangles the engine would build,
## vertex for vertex and in the same order, into one triangle array.
##
## Only polygon-type marks belong here: polylines with a positive width,
## filled ellipses and filled polygons. Rects, lines and text are batched by
## the engine already and must stay ordinary draw calls; flush before drawing
## one so the order of marks, and so the picture, never changes.
##
## The tessellation mirrors servers/rendering/renderer_canvas_cull.cpp and
## scene/main/canvas_item.cpp of Godot 4.7.1-stable. Keep it in step if the
## engine is upgraded; tests/render_batch_test.gd, run windowed, compares the
## two pixel for pixel.

const FEATHER_SIZE := 1.25
const CMP_EPSILON := 0.00001
const ELLIPSE_SEGMENTS := 64

var points := PackedVector2Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()

func is_empty() -> bool:
	return points.is_empty()

func clear() -> void:
	points.clear()
	colors.clear()
	indices.clear()

## Sends everything gathered so far as one draw call on `canvas`, which must be
## inside its own _draw(). The current draw transform applies, as it would to
## the engine's own commands.
func flush(canvas: CanvasItem) -> void:
	if points.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
	clear()

## CanvasItem.draw_polyline(points, color, width, antialiased) for width >= 0.
func add_polyline(line: PackedVector2Array, color: Color, width: float, antialiased := false) -> void:
	var count := line.size()
	if count < 2 or width < 0.0:
		return
	width = _f32(width)
	if antialiased:
		width = compensated_width(width)
	var half_width := _f32(width * 0.5)
	var border_size := FEATHER_SIZE
	if width < 1.0:
		border_size = _f32(border_size * width)
	var loop := line[0].is_equal_approx(line[count - 1])
	var first_dir := Vector2.ZERO
	for i in range(1, count):
		first_dir = (line[i] - line[i - 1]).normalized()
		if not first_dir.is_zero_approx():
			break
	var last_dir := Vector2.ZERO
	for i in range(count - 1, 0, -1):
		last_dir = (line[i] - line[i - 1]).normalized()
		if not last_dir.is_zero_approx():
			break
	var pair_count := count * 2
	var open := 0 if loop else 1
	# Main strip, then the left and right feathers, laid out as the engine does.
	var main_size := pair_count + (4 * open if antialiased else 0)
	var side_size := pair_count + 5 * open
	var main_at := points.size()
	var left_at := main_at + main_size
	var right_at := left_at + side_size
	var total := main_size + (2 * side_size if antialiased else 0)
	points.resize(main_at + total)
	colors.resize(main_at + total)
	var transparent := Color(color.r, color.g, color.b, 0.0)
	var shift := 2 * open if antialiased else 0
	var prev := Vector2.ZERO
	for i in count:
		var first := i == 0
		var last := i == count - 1
		var pos := line[i]
		# compute_polyline_segment_dir
		var dir := prev
		if not last:
			dir = (line[i + 1] - pos).normalized()
			if dir.is_zero_approx():
				dir = prev
		if first and loop:
			prev = last_dir
		elif last and loop:
			prev = first_dir
		var base: Vector2
		if first and not loop:
			base = first_dir.orthogonal()
		elif last and not loop:
			base = last_dir.orthogonal()
		elif dir.is_equal_approx(prev):
			# compute_polyline_edge_offset_clamped falls back to the normal.
			base = dir.orthogonal()
		else:
			base = _edge_offset_clamped(dir, prev)
		var offset := base * half_width
		var j := i * 2 + shift
		var plus := pos + offset
		var minus := pos - offset
		points[main_at + j] = plus
		points[main_at + j + 1] = minus
		colors[main_at + j] = color
		colors[main_at + j + 1] = color
		if antialiased:
			var border := base * border_size
			points[left_at + j] = plus
			points[left_at + j + 1] = plus + border
			points[right_at + j] = minus
			points[right_at + j + 1] = minus - border
			colors[left_at + j] = color
			colors[left_at + j + 1] = transparent
			colors[right_at + j] = color
			colors[right_at + j + 1] = transparent
			if first and not loop:
				var begin := -dir * border_size
				points[main_at] = plus + begin
				points[main_at + 1] = minus + begin
				colors[main_at] = transparent
				colors[main_at + 1] = transparent
				points[left_at] = plus + begin
				points[left_at + 1] = plus + begin + border
				colors[left_at] = transparent
				colors[left_at + 1] = transparent
				points[right_at] = minus + begin
				points[right_at + 1] = minus + begin - border
				colors[right_at] = transparent
				colors[right_at + 1] = transparent
			if last and not loop:
				var end := prev * border_size
				var e := pair_count + 2
				points[main_at + e] = plus + end
				points[main_at + e + 1] = minus + end
				colors[main_at + e] = transparent
				colors[main_at + e + 1] = transparent
				points[left_at + e] = plus
				points[left_at + e + 1] = plus + end + border
				points[left_at + e + 2] = plus + end
				colors[left_at + e] = color
				colors[left_at + e + 1] = transparent
				colors[left_at + e + 2] = transparent
				points[right_at + e] = minus
				points[right_at + e + 1] = minus + end - border
				points[right_at + e + 2] = minus + end
				colors[right_at + e] = color
				colors[right_at + e + 1] = transparent
				colors[right_at + e + 2] = transparent
		prev = dir
	_strip_indices(main_at, main_size)
	if antialiased:
		_strip_indices(left_at, side_size)
		_strip_indices(right_at, side_size)

## CanvasItem.draw_circle(center, radius, color, true, -1, antialiased).
func add_circle(center: Vector2, radius: float, color: Color, antialiased := false) -> void:
	add_ellipse(center, radius, radius, color, antialiased)

## A filled ellipse, as RenderingServer.canvas_item_add_ellipse builds it.
func add_ellipse(center: Vector2, major: float, minor: float, color: Color, antialiased := false) -> void:
	major = _f32(major)
	minor = _f32(minor)
	if antialiased:
		major = _f32(maxf(0.0, major - FEATHER_SIZE * 0.25))
		minor = _f32(maxf(0.0, minor - FEATHER_SIZE * 0.25))
	var unit := _unit_circle()
	var base := points.size()
	points.append_array(Transform2D(Vector2(major, 0.0), Vector2(0.0, minor), center) * unit)
	points.append(center)
	var fill := PackedColorArray()
	fill.resize(ELLIPSE_SEGMENTS + 2)
	fill.fill(color)
	colors.append_array(fill)
	var center_index := base + ELLIPSE_SEGMENTS + 1
	for i in ELLIPSE_SEGMENTS:
		indices.append(center_index)
		indices.append(base + i)
		indices.append(base + i + 1)
	if not antialiased:
		return
	var border_size := FEATHER_SIZE
	var max_axis := _f32(maxf(major, minor) * 2.0)
	if 0.0 <= max_axis and max_axis < 1.0:
		border_size = _f32(border_size * _f32(max_axis * 0.5))
	var inner := Transform2D(Vector2(major, 0.0), Vector2(0.0, minor), center) * unit
	var outer := Transform2D(Vector2(_f32(major + border_size), 0.0), Vector2(0.0, _f32(minor + border_size)), center) * unit
	var strip := PackedVector2Array()
	strip.resize(2 * ELLIPSE_SEGMENTS + 2)
	var strip_colors := PackedColorArray()
	strip_colors.resize(2 * ELLIPSE_SEGMENTS + 2)
	var transparent := Color(color.r, color.g, color.b, 0.0)
	for i in ELLIPSE_SEGMENTS + 1:
		strip[i * 2] = inner[i]
		strip[i * 2 + 1] = outer[i]
		strip_colors[i * 2] = color
		strip_colors[i * 2 + 1] = transparent
	_add_strip(strip, strip_colors)

## CanvasItem.draw_colored_polygon(points, color): the engine's own
## triangulation, one triangle list.
func add_polygon(polygon: PackedVector2Array, color: Color) -> void:
	if polygon.size() < 3:
		return
	var triangles := Geometry2D.triangulate_polygon(polygon)
	if triangles.is_empty():
		return
	var base := points.size()
	points.append_array(polygon)
	var fill := PackedColorArray()
	fill.resize(polygon.size())
	fill.fill(color)
	colors.append_array(fill)
	for index in triangles:
		indices.append(base + index)

## CanvasItem.draw_arc(center, radius, start, end, point_count, color, width, antialiased).
func add_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color, width: float, antialiased := false) -> void:
	if point_count < 2:
		return
	var line := PackedVector2Array()
	line.resize(point_count)
	var delta := _f32(clampf(_f32(_f32(end_angle) - _f32(start_angle)), -TAU, TAU))
	radius = _f32(radius)
	for i in point_count:
		var theta := _f32(_f32(_f32(i / _f32(point_count - 1.0)) * delta) + _f32(start_angle))
		line[i] = center + Vector2(_f32(radius * _f32(cos(theta))), _f32(radius * _f32(sin(theta))))
	add_polyline(line, color, width, antialiased)

## The engine narrows antialiased lines so their feather keeps the drawn width.
static func compensated_width(width: float) -> float:
	if width > 0.0:
		if width <= FEATHER_SIZE * 2.0 + CMP_EPSILON:
			return _f32(width * 0.5)
		elif width <= FEATHER_SIZE * 4.0 + CMP_EPSILON:
			var t := _f32(_f32(width - FEATHER_SIZE * 2.0) / _f32(FEATHER_SIZE * 4.0 - FEATHER_SIZE * 2.0))
			var low := _f32(width * 0.5)
			var high := _f32(width - FEATHER_SIZE * 0.5)
			return _f32(low + _f32(t * _f32(high - low)))
		return _f32(width - FEATHER_SIZE * 0.5)
	return width

# -- internals ------------------------------------------------------------------

## A triangle strip as an indexed triangle list with the strip's own vertex
## order (odd triangles swap their first two vertices, as OpenGL does).
func _add_strip(strip: PackedVector2Array, strip_colors: PackedColorArray) -> void:
	var base := points.size()
	points.append_array(strip)
	colors.append_array(strip_colors)
	_strip_indices(base, strip.size())

func _strip_indices(start: int, size: int) -> void:
	var triangles := size - 2
	if triangles <= 0:
		return
	var at := indices.size()
	indices.resize(at + triangles * 3)
	var i := 0
	while i < triangles:
		var v := start + i
		indices[at] = v
		indices[at + 1] = v + 1
		indices[at + 2] = v + 2
		at += 3
		if i + 1 < triangles:
			indices[at] = v + 2
			indices[at + 1] = v + 1
			indices[at + 2] = v + 3
			at += 3
		i += 2

static func _edge_offset_clamped(dir: Vector2, prev: Vector2) -> Vector2:
	var length := 1.0
	var bisector := (prev * dir.length() - dir * prev.length()).normalized()
	var angle := _f32(atan2(bisector.cross(prev), bisector.dot(prev)))
	var sin_angle := _f32(sin(angle))
	if not is_zero_approx(sin_angle) and not dir.is_equal_approx(prev):
		length = clampf(_f32(1.0 / sin_angle), -3.0, 3.0)
	else:
		bisector = dir.orthogonal()
	if bisector.is_zero_approx():
		bisector = dir.orthogonal()
	return bisector * length

static var _unit: PackedVector2Array = PackedVector2Array()

## cos/sin of the engine's 64 segment angles, computed once.
static func _unit_circle() -> PackedVector2Array:
	if _unit.is_empty():
		var step := _f32(TAU / ELLIPSE_SEGMENTS)
		for i in ELLIPSE_SEGMENTS + 1:
			var angle := _f32(i * step)
			_unit.append(Vector2(cos(angle), sin(angle)))
	return _unit

## Rounds to single precision, the engine's real_t.
static func _f32(value: float) -> float:
	return Vector2(value, 0.0).x
