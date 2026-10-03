extends RefCounted
## Ground marks consume copied geometry and feet only. Projection belongs to
## the room; these impressions read no actor, collider, timer or gameplay state.

static func draw(canvas: CanvasItem, actors: Array[Dictionary], ink: Color, stock: Color) -> void:
	var dark := ink if ink.get_luminance() < stock.get_luminance() else stock
	for actor in actors:
		var foot: Vector2 = actor.get("foot_position", Vector2.ZERO)
		var surface_y := float(actor.get("surface_y", foot.y))
		var height := maxf(0.0, float(actor.get("height", surface_y - foot.y)))
		var weight := exp(-height / 90.0)
		if weight < 0.08:
			continue
		var width := clampf(float(actor.get("width", 22.0)), 9.0, 48.0)
		var radius := Vector2(width * (0.54 + weight * 0.46), 2.8 * (0.60 + weight * 0.40))
		var center := Vector2(foot.x, surface_y + 2.0)
		var clip: Rect2 = actor.get("clip", Rect2(center - radius * 2.0, radius * 4.0))
		if not clip.has_area():
			continue
		_ellipse(canvas, center, radius * 1.48, clip, Color(dark * 0.50, weight * 0.045))
		_ellipse(canvas, center, radius * 1.12, clip, Color(dark * 0.40, weight * 0.085))
		_ellipse(canvas, center, radius, clip, Color(dark * 0.32, weight * 0.17))

static func _ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, clip: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(24):
		var angle := float(index) * TAU / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	# Clipping the convex mark protects ledge ends and leaves every open gap
	# empty, even when a foot is directly at its platform's boundary.
	for edge in range(4):
		points = _clip_edge(points, clip, edge)
		if points.size() < 3:
			return
	canvas.draw_colored_polygon(points, color)

static func _clip_edge(points: PackedVector2Array, clip: Rect2, edge: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.is_empty():
		return result
	var previous := points[-1]
	var previous_inside := _inside(previous, clip, edge)
	for point in points:
		var inside := _inside(point, clip, edge)
		if inside != previous_inside:
			var delta := point - previous
			var value := clip.position.x if edge == 0 else (clip.end.x if edge == 1 else (clip.position.y if edge == 2 else clip.end.y))
			var fraction := (value - previous.x) / delta.x if edge < 2 else (value - previous.y) / delta.y
			result.append(previous + delta * fraction)
		if inside:
			result.append(point)
		previous = point
		previous_inside = inside
	return result

static func _inside(point: Vector2, clip: Rect2, edge: int) -> bool:
	match edge:
		0: return point.x >= clip.position.x
		1: return point.x <= clip.end.x
		2: return point.y >= clip.position.y
		_: return point.y <= clip.end.y
