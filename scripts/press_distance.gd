extends RefCounted
## Quiet, authored distance. A handful of large cut-paper shapes carries each
## district; the room's separate middle plane owns its recognisable fixtures.
## No texture, gameplay, camera or clock is read here.

const HALLS := [&"overture_stair", &"bootlegger", &"whistlers", &"addie", &"worn_gallery", &"smoothed_floor", &"the_arm"]
const UNPLAYED := [&"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"]

static func draw(c: CanvasItem, id: StringName, area: Rect2, ink: Color, stock: Color) -> void:
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return
	c.draw_set_transform(area.position)
	var size := area.size
	# The air remains visible beneath broad washes. All values follow the
	# supplied ink/stock, including an actual A/B palette reversal.
	var p := {
		"far": stock.lerp(ink, 0.09), "near": stock.lerp(ink, 0.16),
		"shade": stock.lerp(ink, 0.025), "rim": stock.lerp(ink, 0.22),
		"mist": stock.lerp(ink, 0.10),
	}
	_wash(c, Rect2(Vector2.ZERO, size), Color(stock, 0.12), Color(p.shade, 0.40))
	if id in [&"overture_well", &"the_drop"]:
		_shaft(c, size, p, id == &"the_drop")
	elif id in UNPLAYED:
		_vault(c, size, p, id)
	elif id in HALLS:
		_hall(c, size, p, id)
	elif id in [&"headshell", &"practice_room", &"label_descent"]:
		_cradle(c, size, p, id)
	else:
		_roofs(c, size, p, id)
	# Forms dissolve before they meet playable surfaces. This is a continuous
	# vertex-colour wash, without tiled marks or a drawn background floor.
	_wash(c, Rect2(0, size.y * 0.46, size.x, size.y * 0.54),
		Color(stock, 0.0), Color(stock, 0.92))
	c.draw_set_transform(Vector2.ZERO)

static func _roofs(c: CanvasItem, s: Vector2, p: Dictionary, id: StringName) -> void:
	# Two uneven groups of broad roofs; no windows, bricks or repeated towers.
	_mass(c, s, [Vector2(-0.04, 0.65), Vector2(0.04, 0.52), Vector2(0.17, 0.51),
		Vector2(0.23, 0.38), Vector2(0.29, 0.49), Vector2(0.41, 0.56),
		Vector2(0.49, 0.62), Vector2(0.69, 0.61), Vector2(0.77, 0.47),
		Vector2(0.92, 0.45), Vector2(1.05, 0.60), Vector2(1.05, 1.0), Vector2(-0.04, 1.0)], p.far)
	var lower := 0.06 if id == &"groove_yard" else 0.0
	_mass(c, s, [Vector2(-0.04, 0.52 + lower), Vector2(0.06, 0.40 + lower),
		Vector2(0.18, 0.41 + lower), Vector2(0.23, 0.57 + lower),
		Vector2(0.34, 0.58 + lower), Vector2(0.35, 0.86), Vector2(-0.04, 0.92)], p.near)
	_mass(c, s, [Vector2(0.70, 0.65), Vector2(0.74, 0.49), Vector2(0.85, 0.46),
		Vector2(0.91, 0.34), Vector2(1.04, 0.49), Vector2(1.04, 0.92), Vector2(0.71, 0.87)], p.near)
	# A single broken ridge per group gives the silhouette a drawn edge.
	_edge(c, s, [Vector2(0.025, 0.441 + lower), Vector2(0.06, 0.40 + lower),
		Vector2(0.145, 0.407 + lower)], Color(p.rim, 0.27))
	_edge(c, s, [Vector2(0.865, 0.44), Vector2(0.91, 0.34), Vector2(0.995, 0.437)], Color(p.rim, 0.21))

static func _cradle(c: CanvasItem, s: Vector2, p: Dictionary, id: StringName) -> void:
	# An empty acoustic chamber frames the actual cradle, organ or descent.
	var center := Vector2(s.x * 0.54, s.y * 0.58)
	var radius := Vector2(s.x * 0.49, s.y * 0.55)
	if id == &"label_descent":
		center = Vector2(s.x * 0.53, s.y * 0.47)
		radius = Vector2(s.x * 0.45, s.y * 0.44)
	_arch_mass(c, center, radius, s.y * 1.04, p.far, s.x * 0.075)
	_mass(c, s, [Vector2(-0.04, -0.04), Vector2(0.105, -0.04), Vector2(0.09, 0.45),
		Vector2(0.12, 0.90), Vector2(-0.04, 1.04)], p.near)
	_mass(c, s, [Vector2(0.89, -0.04), Vector2(1.04, -0.04), Vector2(1.04, 1.04),
		Vector2(0.86, 0.91), Vector2(0.90, 0.46)], p.near)
	_wash(c, Rect2(s * Vector2(0.28, 0.18), s * Vector2(0.49, 0.64)),
		Color(p.mist, 0.16), Color(p.mist, 0.0))

static func _hall(c: CanvasItem, s: Vector2, p: Dictionary, id: StringName) -> void:
	var center := Vector2(s.x * 0.56, s.y * 0.62)
	var radius := Vector2(s.x * 0.46, s.y * 0.56)
	if id == &"whistlers":
		center.x = s.x * 0.63
		radius.x = s.x * 0.53
	elif id == &"the_arm":
		center.x = s.x * 0.60
	_arch_mass(c, center, radius, s.y * 1.04, p.far, s.x * 0.055)
	# One foreground pier on either edge, leaning slightly like cut paper.
	_mass(c, s, [Vector2(-0.03, -0.03), Vector2(0.14, -0.03), Vector2(0.16, 0.54),
		Vector2(0.13, 0.95), Vector2(-0.03, 1.04)], p.near)
	_mass(c, s, [Vector2(0.93, -0.03), Vector2(1.04, -0.03), Vector2(1.04, 1.04),
		Vector2(0.90, 0.94), Vector2(0.925, 0.41)], p.near)
	_edge(c, s, [Vector2(0.135, 0.19), Vector2(0.145, 0.43), Vector2(0.14, 0.66)], Color(p.rim, 0.17))

static func _shaft(c: CanvasItem, s: Vector2, p: Dictionary, torn: bool) -> void:
	var notch := 0.055 if torn else 0.0
	# Tall simple faces leave a clear central shaft at every camera height.
	_mass(c, s, [Vector2(-0.04, -0.04), Vector2(0.23, -0.04), Vector2(0.25, 0.25),
		Vector2(0.20 + notch, 0.48), Vector2(0.24, 0.72), Vector2(0.20, 1.04),
		Vector2(-0.04, 1.04)], p.far)
	_mass(c, s, [Vector2(0.82, -0.04), Vector2(1.04, -0.04), Vector2(1.04, 1.04),
		Vector2(0.76, 1.04), Vector2(0.80 - notch, 0.67), Vector2(0.77, 0.34)], p.near)
	_arch_mass(c, Vector2(s.x * 0.51, s.y * 0.35), Vector2(s.x * 0.42, s.y * 0.29),
		s.y * 0.92, Color(p.far, 0.40), s.x * 0.05)
	_wash(c, Rect2(s * Vector2(0.28, 0.0), s * Vector2(0.48, 1.0)),
		Color(p.mist, 0.17), Color(p.mist, 0.0))

static func _vault(c: CanvasItem, s: Vector2, p: Dictionary, id: StringName) -> void:
	# Unplayed chambers have a lower, wider silhouette than the upper halls.
	var center := Vector2(s.x * 0.51, s.y * 0.57)
	var radius := Vector2(s.x * 0.49, s.y * 0.43)
	_arch_mass(c, center, radius, s.y * 1.02, p.far, s.x * 0.09)
	if id == &"verse_hall":
		# One recessed acoustic bay supplies scale to the long central walk.
		# It has no sill or lit rim that could suggest a platform or passage.
		_recess(c, Vector2(s.x * 0.48, s.y * 0.49), Vector2(s.x * 0.19, s.y * 0.31),
			s.y * 1.02, Color(p.shade, 0.72))
	if id in [&"verse_warren_n", &"verse_warren_s"]:
		_mass(c, s, [Vector2(-0.04, 0.28), Vector2(0.08, 0.20), Vector2(0.19, 0.25),
			Vector2(0.27, 0.43), Vector2(0.22, 0.66), Vector2(0.25, 0.96), Vector2(-0.04, 1.04)], p.near)
		_mass(c, s, [Vector2(0.82, 0.37), Vector2(0.93, 0.28), Vector2(1.04, 0.31),
			Vector2(1.04, 1.04), Vector2(0.78, 0.91), Vector2(0.80, 0.65)], p.near)
	else:
		_mass(c, s, [Vector2(-0.04, -0.04), Vector2(0.10, -0.04), Vector2(0.13, 0.40),
			Vector2(0.095, 0.92), Vector2(-0.04, 1.04)], p.near)
		_mass(c, s, [Vector2(0.90, -0.04), Vector2(1.04, -0.04), Vector2(1.04, 1.04),
			Vector2(0.87, 0.94), Vector2(0.92, 0.51)], p.near)
	_wash(c, Rect2(s * Vector2(0.24, 0.27), s * Vector2(0.57, 0.61)),
		Color(p.mist, 0.14), Color(p.mist, 0.0))

static func _mass(c: CanvasItem, size: Vector2, points: Array, paint: Color) -> void:
	var shape := PackedVector2Array()
	for point: Vector2 in points:
		shape.append(point * size)
	c.draw_colored_polygon(shape, paint)

static func _edge(c: CanvasItem, size: Vector2, points: Array, paint: Color) -> void:
	var shape := PackedVector2Array()
	for point: Vector2 in points:
		shape.append(point * size)
	c.draw_polyline(shape, paint, 2.0, true)

static func _arch_mass(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float,
		paint: Color, thickness: float) -> void:
	# A filled band has visual weight without a row of repeated stone joints.
	var shape := PackedVector2Array([Vector2(center.x - radius.x - thickness, bottom)])
	for i in range(25):
		var a := PI + float(i) / 24.0 * PI
		shape.append(center + Vector2(cos(a), sin(a)) * (radius + Vector2.ONE * thickness))
	shape.append(Vector2(center.x + radius.x + thickness, bottom))
	shape.append(Vector2(center.x + radius.x, bottom))
	for i in range(24, -1, -1):
		var a := PI + float(i) / 24.0 * PI
		shape.append(center + Vector2(cos(a), sin(a)) * radius)
	shape.append(Vector2(center.x - radius.x, bottom))
	c.draw_colored_polygon(shape, paint)

static func _wash(c: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	c.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
		rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))

static func _recess(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float, paint: Color) -> void:
	var shape := PackedVector2Array([Vector2(center.x - radius.x, bottom)])
	for i in range(25):
		var a := PI + float(i) / 24.0 * PI
		shape.append(center + Vector2(cos(a), sin(a)) * radius)
	shape.append(Vector2(center.x + radius.x, bottom))
	c.draw_colored_polygon(shape, paint)
