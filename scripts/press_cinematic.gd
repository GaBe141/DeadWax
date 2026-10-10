extends RefCounted
## Quiet canvas marks. All health, noise, timing and palette values arrive
## explicitly from Main; these marks own no gameplay state.

static func draw(canvas: CanvasItem, extent: Vector2, state: Dictionary, ink: Color, accent: Color) -> void:
	var edge := minf(12.0, extent.y * 0.018)
	canvas.draw_rect(Rect2(0, 0, extent.x, edge), Color(0.015, 0.022, 0.028, 0.7))
	canvas.draw_rect(Rect2(0, extent.y - edge, extent.x, edge), Color(0.015, 0.022, 0.028, 0.7))
	var health := int(state.get("health", 3))
	var maximum := int(state.get("max_health", 3))
	var origin := Vector2(30, 35)
	var cracks: Array = state.get("cracks", []) if state.get("cracks", []) is Array else []
	var inks: Array = state.get("inks", []) if state.get("inks", []) is Array else []
	for index in maximum:
		var center := origin + Vector2(index * 18, 0)
		var diamond := PackedVector2Array([center + Vector2(0, -6), center + Vector2(4, 0), center + Vector2(0, 6), center + Vector2(-4, 0)])
		var inking := float(inks[index]) if index < inks.size() else -1.0
		var filled := index < health
		if filled and inking >= 0.0:
			_reink(canvas, diamond, center, inking, ink, accent)
		else:
			canvas.draw_colored_polygon(diamond, Color(ink, 0.85 if filled else 0.12))
		canvas.draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(ink, 0.42), 1.0, true)
		var cracking := float(cracks[index]) if index < cracks.size() else -1.0
		if not filled and cracking >= 0.0:
			_crack(canvas, center, cracking, ink, accent)
	# Groove pressure: a quiet ring after the diamonds while something in the
	# room is listening, filled with the accent in the pocket. A functional
	# cue: it holds under Reduced motion.
	var beat: Dictionary = state.get("beat", {}) if state.get("beat", {}) is Dictionary else {}
	if bool(beat.get("live", false)):
		var mark := origin + Vector2(maximum * 18 + 8, 0)
		if bool(beat.get("lit", false)):
			canvas.draw_circle(mark, 4.5, Color(accent, 0.9), true, -1, true)
		else:
			canvas.draw_arc(mark, 4.0, 0.0, TAU, 20, Color(ink, 0.32), 1.2, true)
	var noise := clampf(float(state.get("noise", 0.0)), 0.0, 1.0)
	if noise > 0.03:
		canvas.draw_line(Vector2(26, 55), Vector2(106, 55), Color(ink, 0.12), 2.0)
		canvas.draw_line(Vector2(26, 55), Vector2(26 + noise * 80, 55), Color(accent, 0.65), 2.0)
	# Experience: a hairline toward the next level beneath the noise line, and
	# a small accent mark while a level's choice waits in the Book.
	var xp: Dictionary = state.get("xp", {}) if state.get("xp", {}) is Dictionary else {}
	if not xp.is_empty():
		var progress := clampf(float(xp.get("ratio", 0.0)), 0.0, 1.0)
		var flash := clampf(float(xp.get("flash", 0.0)), 0.0, 1.0)
		canvas.draw_line(Vector2(26, 62), Vector2(106, 62), Color(ink.lerp(accent, flash), 0.10 + flash * 0.45), 1.0)
		canvas.draw_line(Vector2(26, 62), Vector2(26 + progress * 80, 62), Color(ink.lerp(accent, flash), 0.55 + flash * 0.4), 1.0 + flash)
		if int(xp.get("picks", 0)) > 0:
			var mark := Vector2(114, 62)
			canvas.draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -4), mark + Vector2(3, 0), mark + Vector2(0, 4), mark + Vector2(-3, 0)]), Color(accent, 0.9))
		var burst := float(state.get("burst", -1.0))
		if burst >= 0.0:
			_burst(canvas, Vector2(114, 62), burst, bool(state.get("burst_still", false)), ink, accent)
	if bool(state.get("b_side", false)):
		var ratio := clampf(float(state.get("runtime", 0.0)), 0.0, 1.0)
		var center := Vector2(extent.x - 37, 37)
		canvas.draw_arc(center, 13, -PI * 0.5, TAU - PI * 0.5, 40, Color(ink, 0.18), 1.5, true)
		canvas.draw_arc(center, 13, -PI * 0.5, -PI * 0.5 + TAU * ratio, 40, Color(accent if ratio < 0.25 else ink, 0.8), 2.0, true)
		canvas.draw_circle(center, 2.5, Color(ink, 0.8), true, -1, true)
	var title_alpha := float(state.get("title_alpha", 0.0))
	if title_alpha > 0.0:
		var y := extent.y * 0.36 + 58
		var half_width := minf(extent.x * 0.2, 210.0)
		canvas.draw_line(Vector2(extent.x * 0.5 - half_width, y), Vector2(extent.x * 0.5 + half_width, y), Color(ink, title_alpha * 0.42), 1.0, true)

## A restored diamond fills with ink from its lower point, then rings once.
static func _reink(canvas: CanvasItem, diamond: PackedVector2Array, center: Vector2, progress: float, ink: Color, accent: Color) -> void:
	canvas.draw_colored_polygon(diamond, Color(ink, 0.12))
	var eased := 1.0 - pow(1.0 - progress, 2.0)
	var level := center.y + 6.0 - 12.0 * eased
	var surface := PackedVector2Array([Vector2(center.x - 6, level), Vector2(center.x + 6, level), Vector2(center.x + 6, center.y + 7), Vector2(center.x - 6, center.y + 7)])
	for part in Geometry2D.intersect_polygons(diamond, surface):
		canvas.draw_colored_polygon(part, Color(ink, 0.85))
	if progress < 0.92:
		var half := 4.0 * (1.0 - absf(level - center.y) / 6.0)
		canvas.draw_line(Vector2(center.x - half, level), Vector2(center.x + half, level), Color(accent, 0.8), 1.0, true)
	if progress > 0.7:
		var ring := (progress - 0.7) / 0.3
		canvas.draw_arc(center, 6.0 + ring * 4.0, 0.0, TAU, 20, Color(accent, (1.0 - ring) * 0.7), 1.0, true)

## A lost diamond splits along a crack; its halves drop away as chips fly.
static func _crack(canvas: CanvasItem, center: Vector2, progress: float, ink: Color, accent: Color) -> void:
	var fade := 1.0 - progress
	if progress < 0.3:
		var flash := 1.0 - progress / 0.3
		canvas.draw_polyline(PackedVector2Array([center + Vector2(0.5, -7), center + Vector2(-1.5, -2), center + Vector2(1.5, 1), center + Vector2(-0.5, 7)]),
			Color(accent, flash), 1.4, true)
	var spread := progress * 5.0
	var drop := progress * progress * 10.0
	var lean := progress * 0.6
	for side in [-1.0, 1.0]:
		var half := PackedVector2Array([Vector2(0.5, -6), Vector2(4.0 * side, 0), Vector2(-0.5, 6)])
		var moved := PackedVector2Array()
		for point in half:
			moved.append(center + point.rotated(lean * side) + Vector2(spread * side, drop))
		canvas.draw_colored_polygon(moved, Color(ink, 0.85 * fade))
	for chip in 3:
		var angle := -PI * 0.5 + (chip - 1) * 0.9
		var at := center + Vector2.from_angle(angle) * (3.0 + progress * 11.0) + Vector2(0, progress * progress * 8.0)
		canvas.draw_rect(Rect2(at - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), Color(ink, 0.8 * fade))

## A new level rings out from the mark waiting in the Book. Under Reduced
## motion one still ring fades in place instead of spreading.
static func _burst(canvas: CanvasItem, center: Vector2, progress: float, still: bool, ink: Color, accent: Color) -> void:
	var fade := 1.0 - progress
	if still:
		canvas.draw_arc(center, 9.0, 0.0, TAU, 28, Color(accent, fade * 0.85), 1.5, true)
		return
	if progress < 0.2:
		canvas.draw_circle(center, 5.0 * (1.0 - progress / 0.2), Color(accent, 0.9), true, -1, true)
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var radius := 5.0 + eased * 22.0
	canvas.draw_arc(center, radius, 0.0, TAU, 40, Color(accent, fade * 0.9), 1.0 + fade * 1.2, true)
	if progress < 0.6:
		var rays := 1.0 - progress / 0.6
		for ray in 8:
			var direction := Vector2.from_angle(ray * TAU / 8.0 + 0.2)
			canvas.draw_line(center + direction * (radius + 2.0), center + direction * (radius + 2.0 + rays * 6.0), Color(accent, rays * 0.85), 1.2, true)
	canvas.draw_arc(center, radius * 0.55, 0.0, TAU, 28, Color(ink, fade * 0.35), 1.0, true)
