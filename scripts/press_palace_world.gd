extends RefCounted
## The Palace is a single quiet, weighty chamber. Its large stone silhouettes,
## shallow wax reflections and contact marks receive only supplied palettes
## and snapshots; no actor, camera, collision or arena controller is read here.

static func draw(canvas: CanvasItem, plane: StringName, bounds: Rect2,
		pose: Dictionary, ink: Color, stock: Color, brass: Color) -> void:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	match plane:
		&"far": _far(canvas, bounds, ink, stock)
		&"middle": _middle(canvas, bounds, pose, ink, stock, brass)
		&"contact": _contacts(canvas, pose, ink, stock)
		&"foreground": _foreground(canvas, pose, ink, stock, brass)

static func _far(c: CanvasItem, bounds: Rect2, ink: Color, stock: Color) -> void:
	var center := bounds.get_center().x
	var ceiling := bounds.position.y
	var top := bounds.position
	var wall := stock.lerp(ink, 0.045)
	var stone := stock.lerp(ink, 0.12)
	var dark := stock * Color(0.64, 0.69, 0.73, 1.0)
	_wash(c, bounds, stock * Color(0.67, 0.73, 0.79, 1.0), wall)
	# One broad acoustic vault sets the room's scale. The irregular band carries
	# a bevel and a shadow rather than individually outlined miniature stones.
	var spring := Vector2(center, ceiling + 528.0)
	var radius := Vector2(563.0, 391.0)
	_recess(c, spring, radius, ceiling + 612.0, dark)
	_arch(c, spring + Vector2(-9.0, 7.0), radius + Vector2(31.0, 27.0),
		ceiling + 612.0, 53.0, stock.lerp(ink, 0.065))
	_arch(c, spring, radius + Vector2(7.0, 2.0), ceiling + 612.0, 25.0, stone)
	var curve := _curve(spring, radius + Vector2(4.0, 0.0))
	c.draw_polyline(curve.slice(5, 19), Color(stock.lerp(ink, 0.25), 0.17), 3.0, true)
	# A single high slit establishes where the warm central spill enters. Its
	# lower edge dissolves high above combat rather than resembling a ledge.
	_recess(c, Vector2(center, ceiling + 286.0), Vector2(84.0, 133.0),
		ceiling + 346.0, stock.lerp(ink, 0.14))
	_wash(c, Rect2(center - 70.0, ceiling + 257.0, 140.0, 112.0),
		Color(stock.lerp(ink, 0.105), 0.32), Color(dark, 0.0))
	# Fewer, heavier pillars frame the usable floor. Their long edges are broken
	# and dim; no decorative sill, stair or false floor appears in the chamber.
	_pier(c, center - 639.0, top.y, 112.0, 620.0, stone, dark, ink, stock, false)
	_pier(c, center + 529.0, top.y, 112.0, 620.0, stone, dark, ink, stock, true)
	_pier(c, bounds.position.x - 37.0, top.y, 300.0, 620.0,
		stock.lerp(ink, 0.073), dark, ink, stock, false)
	_pier(c, bounds.end.x - 265.0, top.y, 300.0, 620.0,
		stock.lerp(ink, 0.073), dark, ink, stock, true)
	# A continuous wash hides architectural feet behind the real playing plane.
	_wash(c, Rect2(bounds.position.x, ceiling + 458.0, bounds.size.x, 154.0),
		Color(stock, 0.0), Color(stock, 0.68))

static func _middle(c: CanvasItem, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color, brass: Color) -> void:
	var center := bounds.get_center().x
	var offset: Vector2 = pose.get("middle_offset", Vector2.ZERO)
	for fixture in [Vector2(center - 380.0, 285.0), Vector2(center, 225.0), Vector2(center + 380.0, 285.0)]:
		fixture.y += bounds.position.y
		fixture -= offset
		# Fixtures are drawn by the native lighting controller. This shallow wall
		# pocket surrounds that exact origin without duplicating the flame.
		var dark := stock * Color(0.68, 0.71, 0.73, 1.0)
		_recess(c, fixture + Vector2(0.0, 20.0), Vector2(35.0, 52.0), fixture.y + 54.0, dark)
		_arch(c, fixture + Vector2(0.0, 20.0), Vector2(38.0, 55.0),
			fixture.y + 52.0, 5.0, Color(stock.lerp(ink, 0.17), 0.62))
		c.draw_line(fixture + Vector2(-29.0, 40.0), fixture + Vector2(-26.0, 6.0),
			Color(stock.lerp(brass, 0.30), 0.20), 2.0, true)
	# Two long, broad wax stains are fixed to the architecture, far behind feet.
	# They read as material age without filling the room with small ornaments.
	for side in [-1.0, 1.0]:
		var origin := Vector2(center + side * 534.0, bounds.position.y + 392.0)
		var shape := PackedVector2Array([origin + Vector2(-14, -77), origin + Vector2(13, -69),
			origin + Vector2(8, 32), origin + Vector2(4, 118), origin + Vector2(-6, 83)])
		c.draw_colored_polygon(shape, Color(stock.lerp(ink, 0.13), 0.24))

static func _contacts(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var surface_y := float(pose.get("surface_y", 610.0))
	var dark := ink if ink.get_luminance() < stock.get_luminance() else stock
	for actor: Dictionary in pose.get("actors", []):
		var foot: Vector2 = actor.get("foot_position", Vector2.ZERO)
		var height := maxf(0.0, float(actor.get("height", surface_y - foot.y)))
		var weight := exp(-height / 95.0)
		if weight < 0.08:
			continue
		var width := clampf(float(actor.get("width", 22.0)), 12.0, 35.0)
		var radius := Vector2(width * (0.55 + weight * 0.45), 3.3 * (0.62 + weight * 0.38))
		# Soft nested ellipses stay flat on the actual floor and below the actor.
		# Their height fading reads a jump without moving any gameplay node.
		_ellipse(c, Vector2(foot.x, surface_y + 2.0), radius * 1.50, Color(dark * 0.48, weight * 0.06))
		_ellipse(c, Vector2(foot.x, surface_y + 2.0), radius * 1.13, Color(dark * 0.39, weight * 0.11))
		_ellipse(c, Vector2(foot.x, surface_y + 2.0), radius, Color(dark * 0.32, weight * 0.22))

static func _foreground(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color, brass: Color) -> void:
	var floor_y := float(pose.get("surface_y", 610.0))
	for surface: Rect2 in pose.get("surfaces", []):
		if absf(surface.position.y - floor_y) > 2.0:
			continue
		var end_y := minf(surface.end.y, floor_y + 86.0)
		if end_y <= floor_y + 12.0:
			continue
		# Reflection is a shallow vertical wash below the real lip, not a mirror
		# silhouette that could masquerade as another actor or landing warning.
		for pool in [[1280.0, 165.0, 0.032], [900.0, 97.0, 0.015], [1660.0, 97.0, 0.015]]:
			var rect := Rect2(float(pool[0]) - float(pool[1]), floor_y + 12.0,
				float(pool[1]) * 2.0, end_y - floor_y - 12.0)
			rect = rect.intersection(surface)
			if rect.has_area():
				_wash(c, rect, Color(ink.lerp(brass, 0.20), float(pool[2])), Color(stock, 0.0))

static func _pier(c: CanvasItem, x: float, y: float, width: float, height: float,
		face: Color, shadow: Color, ink: Color, stock: Color, right: bool) -> void:
	var lean := -8.0 if right else 8.0
	var shape := PackedVector2Array([Vector2(x, y - 12), Vector2(x + width, y - 12),
		Vector2(x + width + lean * 0.4, y + height * 0.38),
		Vector2(x + width + lean, y + height), Vector2(x + lean, y + height),
		Vector2(x + lean * 0.45, y + height * 0.46)])
	c.draw_colored_polygon(shape, face)
	var inner_x := x + (width * 0.77 if right else width * 0.23)
	c.draw_polygon(PackedVector2Array([Vector2(inner_x, y), Vector2(inner_x + width * 0.23, y),
		Vector2(inner_x + lean + width * 0.23, y + height), Vector2(inner_x + lean, y + height)]),
		PackedColorArray([Color(shadow, 0.6), Color(shadow, 0.28), Color(shadow, 0.55), Color(shadow, 0.75)]))
	var edge_x := x + width - 3.0 if right else x + 3.0
	c.draw_polyline(PackedVector2Array([Vector2(edge_x, y + 135), Vector2(edge_x + lean * 0.42, y + 318),
		Vector2(edge_x + lean * 0.75, y + 469)]), Color(stock.lerp(ink, 0.30), 0.14), 3.0, true)

static func _curve(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := PI + float(index) * PI / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points

static func _arch(c: CanvasItem, center: Vector2, radius: Vector2,
		bottom: float, thickness: float, paint: Color) -> void:
	var shape := PackedVector2Array([Vector2(center.x - radius.x - thickness, bottom)])
	shape.append_array(_curve(center, radius + Vector2.ONE * thickness))
	shape.append(Vector2(center.x + radius.x + thickness, bottom))
	shape.append(Vector2(center.x + radius.x, bottom))
	var inner := _curve(center, radius)
	inner.reverse()
	shape.append_array(inner)
	shape.append(Vector2(center.x - radius.x, bottom))
	c.draw_colored_polygon(shape, paint)

static func _recess(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float, paint: Color) -> void:
	var shape := PackedVector2Array([Vector2(center.x - radius.x, bottom)])
	shape.append_array(_curve(center, radius))
	shape.append(Vector2(center.x + radius.x, bottom))
	c.draw_colored_polygon(shape, paint)

static func _ellipse(c: CanvasItem, center: Vector2, radius: Vector2, paint: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := float(index) * TAU / 24.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	c.draw_colored_polygon(points, paint)

static func _wash(c: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	c.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))
