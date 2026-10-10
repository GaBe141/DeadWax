extends RefCounted
## Paper and ink between places: the ink wipe between rooms, the Book's board
## swinging open and shut, and its page turns. Pure drawing from explicit poses
## and an optional still of the previous frame; no clocks, input or game state.
## Without a still (headless runs, a failed read) the same shapes print in ink.

const Capture := preload("res://scripts/screen_capture.gd")
const INK := Color("0a1a1f")
const LEATHER := Color("0d232b")
const BOARD_EDGE := Color("06141a")
const BRASS := Color("d6b77c")
const CREAM := Color("f1dfb8")
const PAGE := Color("102c35")
const PAGE_BACK := Color("2b4a53")
const FAR := 10000.0

# -- the ink wipe between rooms -----------------------------------------------

## `progress` 0..1; `direction` 1 sweeps left to right (the new room appears
## from the left first). Reduced motion dissolves the still instead.
static func draw_wipe(canvas: CanvasItem, size: Vector2, pose: Dictionary, capture: Dictionary) -> void:
	var progress := clampf(float(pose.get("progress", 1.0)), 0.0, 1.0)
	if progress >= 1.0 or size.x < 1.0 or size.y < 1.0:
		return
	var texture := Capture.texture_of(capture)
	var screen := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	if bool(pose.get("reduced", false)):
		var fade := 1.0 - progress
		if texture != null:
			canvas.draw_texture_rect(texture, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, fade))
		else:
			canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(INK, fade))
		return
	var forward := float(pose.get("direction", 1.0)) >= 0.0
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var band := 58.0
	var travel := -band - 24.0 + (size.x + band * 2.0 + 48.0) * eased
	var rows := maxi(int(ceil(size.y / 22.0)), 4)
	var edge := PackedVector2Array()
	for row in rows + 1:
		var y := size.y * float(row) / float(rows)
		var ragged := sin(y * 0.031 + 1.7) * 9.0 + sin(y * 0.089 + 0.4) * 5.0 + sin(y * 0.23 + 2.1) * 2.5
		edge.append(Vector2(travel + ragged, y))
	# The previous frame still lies beyond the brush.
	var beyond := PackedVector2Array(edge)
	beyond.append(Vector2(size.x + FAR, size.y))
	beyond.append(Vector2(size.x + FAR, 0.0))
	for part in Geometry2D.intersect_polygons(_mirror(beyond, size.x, forward), screen):
		if texture != null:
			canvas.draw_colored_polygon(part, Color.WHITE, Capture.uvs(capture, part), texture)
		else:
			canvas.draw_colored_polygon(part, INK)
	# The brush: a dense core on the seam, wet ink trailing into the new room.
	for row in rows:
		var top := edge[row]
		var low := edge[row + 1]
		var tail_top := top - Vector2(band * (0.65 + 0.35 * absf(sin(row * 1.7))), 0)
		var tail_low := low - Vector2(band * (0.65 + 0.35 * absf(sin(row * 1.7 + 1.7))), 0)
		var trail := PackedVector2Array([tail_top, top, low, tail_low])
		canvas.draw_polygon(_mirror(trail, size.x, forward), PackedColorArray([Color(INK, 0.0), Color(INK, 0.9), Color(INK, 0.9), Color(INK, 0.0)]))
		var core := PackedVector2Array([top - Vector2(9, 0), top + Vector2(4, 0), low + Vector2(4, 0), low - Vector2(9, 0)])
		canvas.draw_colored_polygon(_mirror(core, size.x, forward), INK)
	# A few drops flung ahead of the stroke.
	for drop in 9:
		var y := size.y * fmod(drop * 0.377 + 0.11, 1.0)
		var ahead := 10.0 + fmod(drop * 23.7, 34.0) * (0.4 + eased)
		var at := Vector2(travel + sin(y * 0.031 + 1.7) * 9.0 + ahead, y)
		at.x = size.x - at.x if not forward else at.x
		canvas.draw_circle(at, 1.6 + fmod(drop * 1.9, 3.2), INK, true, -1, true)

# -- the Book's board -----------------------------------------------------------

## The board hinged on the rect's left edge. `swing` 0 lies flat over the page;
## 1 has turned edge-on. Its print is laid out at `reference` and scaled onto
## the rect, so a shrinking, closed Book keeps its own face.
static func draw_cover(canvas: CanvasItem, rect: Rect2, swing: float, display: Font, body: Font,
		alpha := 1.0, reference := Vector2.ZERO) -> void:
	var theta := clampf(swing, 0.0, 1.0) * PI * 0.5
	var turned := cos(theta)
	if turned <= 0.01 or alpha <= 0.0 or rect.size.x < 1.0 or rect.size.y < 1.0:
		return
	var reference_size := reference if reference.x > 1.0 and reference.y > 1.0 else rect.size
	var hinge := rect.position.x
	var width := rect.size.x * turned
	var lift := rect.size.y * 0.045 * sin(theta)
	var top := rect.position.y
	var bottom := rect.end.y
	var far := hinge + width
	var board := PackedVector2Array([Vector2(hinge, top), Vector2(far, top - lift), Vector2(far, bottom + lift), Vector2(hinge, bottom)])
	var cast := 52.0 * sin(theta)
	if cast > 1.0:
		canvas.draw_polygon(PackedVector2Array([Vector2(far, top - lift), Vector2(far + cast, top), Vector2(far + cast, bottom), Vector2(far, bottom + lift)]),
			PackedColorArray([Color(0, 0, 0, 0.42 * alpha), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.42 * alpha)]))
	canvas.draw_colored_polygon(board, Color(LEATHER, alpha))
	var scale := Vector2(rect.size.x * turned / reference_size.x, rect.size.y / reference_size.y)
	canvas.draw_set_transform(Vector2(hinge, top), 0.0, scale)
	_board_print(canvas, reference_size, display, body, alpha)
	canvas.draw_set_transform(Vector2.ZERO)
	# Turning away from the light darkens the board; its fore-edge catches brass.
	canvas.draw_colored_polygon(board, Color(0, 0, 0, 0.45 * (1.0 - turned) * alpha))
	canvas.draw_line(Vector2(far, top - lift), Vector2(far, bottom + lift), Color(BRASS, 0.5 * turned * alpha), 2.0, true)
	canvas.draw_polyline(PackedVector2Array([board[0], board[1], board[2], board[3], board[0]]), Color(BOARD_EDGE, alpha), 2.0, true)

static func _board_print(canvas: CanvasItem, size: Vector2, display: Font, body: Font, alpha: float) -> void:
	for line in range(0, int(size.y), 7):
		canvas.draw_line(Vector2(0, line), Vector2(size.x, line + 2), Color(CREAM, 0.018 * alpha), 1.0)
	var spine := minf(size.x * 0.035, 34.0)
	canvas.draw_rect(Rect2(0, 0, spine, size.y), Color(BOARD_EDGE, 0.55 * alpha))
	for band in [0.12, 0.88]:
		canvas.draw_line(Vector2(0, size.y * band), Vector2(spine, size.y * band), Color(BRASS, 0.7 * alpha), 3.0)
	var inset := minf(size.x, size.y) * 0.045
	canvas.draw_rect(Rect2(Vector2(spine + inset, inset), Vector2(size.x - spine - inset * 2.0, size.y - inset * 2.0)), Color(BRASS, 0.8 * alpha), false, 2.0)
	var inner := inset + 9.0
	canvas.draw_rect(Rect2(Vector2(spine + inner, inner), Vector2(size.x - spine - inner * 2.0, size.y - inner * 2.0)), Color(BRASS, 0.35 * alpha), false, 1.0)
	var center := Vector2(spine + (size.x - spine) * 0.5, size.y * 0.42)
	var radius := minf(size.x, size.y) * 0.16
	canvas.draw_circle(center, radius, Color(BOARD_EDGE, 0.9 * alpha), true, -1, true)
	for ring in [0.92, 0.80, 0.68, 0.56]:
		canvas.draw_arc(center, radius * ring, 0.3, TAU - 0.2, 64, Color(CREAM, 0.16 * alpha), 1.0, true)
	canvas.draw_circle(center, radius * 0.3, Color(BRASS, 0.92 * alpha), true, -1, true)
	canvas.draw_circle(center, radius * 0.05, Color(BOARD_EDGE, alpha), true, -1, true)
	var title := int(clampf(size.y * 0.07, 12.0, 64.0))
	canvas.draw_string(display, Vector2(spine, center.y + radius + title * 1.35), "THE BOOK",
		HORIZONTAL_ALIGNMENT_CENTER, size.x - spine, title, Color(CREAM, 0.92 * alpha))
	var small := int(clampf(size.y * 0.022, 9.0, 18.0))
	canvas.draw_string(body, Vector2(spine, center.y + radius + title * 1.35 + small * 2.0), "WHAT YOU CARRY BETWEEN GROOVES",
		HORIZONTAL_ALIGNMENT_CENTER, size.x - spine, small, Color(BRASS, 0.75 * alpha))

# -- page turns -------------------------------------------------------------------

## The old page folds over along a moving crease, its back passing over what
## is left of it, while the new page is already live beneath. `direction` 1
## turns forward (lifting from the right edge); -1 turns back.
static func draw_page_turn(canvas: CanvasItem, pose: Dictionary, capture: Dictionary) -> void:
	var rect: Rect2 = pose.get("rect", Rect2())
	var progress := clampf(float(pose.get("progress", 1.0)), 0.0, 1.0)
	if progress >= 1.0 or rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	var forward := float(pose.get("direction", 1.0)) >= 0.0
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var page := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var middle := lerpf(rect.end.x, rect.position.x, eased)
	var slant := rect.size.y * 0.14 * sin(eased * PI)
	# Worked in a forward frame, then mirrored about the page's centre.
	var a := Vector2(middle - slant, rect.position.y)
	var b := Vector2(middle + slant, rect.end.y)
	var along := (b - a).normalized()
	var normal := along.orthogonal()
	if normal.x < 0.0:
		normal = -normal
	var lifted_half := PackedVector2Array([a - along * FAR, b + along * FAR, b + along * FAR + normal * FAR, a - along * FAR + normal * FAR])
	var flat_half := PackedVector2Array([a - along * FAR, a - along * FAR - normal * FAR, b + along * FAR - normal * FAR, b + along * FAR])
	var texture := Capture.texture_of(capture)
	var axis := rect.position.x + rect.end.x
	for part in Geometry2D.intersect_polygons(page, flat_half):
		var shown := _mirror(part, axis, forward)
		if texture != null:
			canvas.draw_colored_polygon(shown, Color.WHITE, Capture.uvs(capture, shown), texture)
		else:
			canvas.draw_colored_polygon(shown, PAGE)
	var shade := 30.0 * sin(eased * PI)
	if shade > 1.0:
		var strip := PackedVector2Array([a, b, b + normal * shade, a + normal * shade])
		for part in Geometry2D.intersect_polygons(strip, page):
			canvas.draw_polygon(_mirror(part, axis, forward), _fade_colors(part, a, normal, shade, Color(0, 0, 0, 0.38), Color(0, 0, 0, 0)))
	for part in Geometry2D.intersect_polygons(page, lifted_half):
		var folded := PackedVector2Array()
		for point in part:
			folded.append(point - normal * 2.0 * (point - a).dot(normal))
		for flap in Geometry2D.intersect_polygons(folded, page):
			var colors := _fade_colors(flap, a, -normal, rect.size.x * 0.5, PAGE_BACK.darkened(0.35), PAGE_BACK.lightened(0.08))
			canvas.draw_polygon(_mirror(flap, axis, forward), colors)
			var outline := _mirror(flap, axis, forward)
			outline.append(outline[0])
			canvas.draw_polyline(outline, Color(CREAM, 0.32), 1.2, true)
	for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), page):
		canvas.draw_polyline(_mirror(piece, axis, forward), Color(CREAM, 0.30), 1.5, true)

# -- the closed Book returning to Skip's hands ---------------------------------

## First the board swings shut over the page as it was; then the closed Book
## shrinks into `target`, where Skip's own small book takes over.
const FOLD_SHUT := 0.45

static func draw_book_fold(canvas: CanvasItem, pose: Dictionary, capture: Dictionary, display: Font, body: Font) -> void:
	var rect: Rect2 = pose.get("rect", Rect2())
	var progress := clampf(float(pose.get("progress", 1.0)), 0.0, 1.0)
	if progress >= 1.0 or rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	if progress < FOLD_SHUT:
		var texture := Capture.texture_of(capture)
		if texture != null:
			var page := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
			canvas.draw_colored_polygon(page, Color.WHITE, Capture.uvs(capture, page), texture)
		else:
			canvas.draw_rect(rect, PAGE)
		var closing := progress / FOLD_SHUT
		draw_cover(canvas, rect, 1.0 - closing * closing * (3.0 - 2.0 * closing), display, body)
		return
	var flight := (progress - FOLD_SHUT) / (1.0 - FOLD_SHUT)
	var eased := flight * flight
	var target: Vector2 = pose.get("target", rect.get_center())
	var small := Rect2(target - Vector2(13, 10), Vector2(26, 20))
	var shrinking := Rect2(rect.position.lerp(small.position, eased), rect.size.lerp(small.size, eased))
	var alpha := 1.0 if flight < 0.78 else clampf(1.0 - (flight - 0.78) / 0.22, 0.0, 1.0)
	draw_cover(canvas, shrinking, 0.0, display, body, alpha, rect.size)

# -- helpers ------------------------------------------------------------------------

## A backward stroke is the forward one reflected: x becomes `axis - x`, where
## `axis` is the screen width or the sum of a page's two edges.
static func _mirror(points: PackedVector2Array, axis: float, forward: bool) -> PackedVector2Array:
	if forward:
		return points
	var result := PackedVector2Array()
	for point in points:
		result.append(Vector2(axis - point.x, point.y))
	return result

static func _fade_colors(points: PackedVector2Array, origin: Vector2, normal: Vector2, reach: float, near: Color, far: Color) -> PackedColorArray:
	var colors := PackedColorArray()
	for point in points:
		var distance := clampf((point - origin).dot(normal) / maxf(reach, 1.0), 0.0, 1.0)
		colors.append(near.lerp(far, distance))
	return colors
