extends RefCounted
## The unheard district: violet cut stone, oxidised copper and record burrows.
## These marks are scenery only. All coordinates, clocks and paint arrive from
## the room atmosphere; foreground marks stay inside its real platform clips.

const Brush := preload("res://scripts/press_world_brush.gd")
const ROOMS := [&"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"]

static func draw(c: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if room_id not in ROOMS or not bounds.has_area():
		return
	var p := Brush.palette(ink, stock)
	if layer == &"foreground":
		Brush.face(c, pose.get("surfaces", []), p, room_id in [&"the_drop", &"the_landing"])
		return
	if layer not in [&"far", &"middle"]:
		return
	var far := layer == &"far"
	var clock := float(pose.get("clock", 0.0)) * float(pose.get("motion", 1.0))
	c.draw_set_transform(bounds.position)
	match room_id:
		&"the_drop": _drop(c, bounds.size, far, clock, p)
		&"the_landing": _landing(c, bounds.size, far, clock, p)
		&"verse_hall": _verse(c, bounds.size, far, clock, p)
		&"verse_warren_n": _warren(c, bounds.size, far, clock, p, false)
		&"verse_warren_s": _warren(c, bounds.size, far, clock, p, true)
		&"deep_gallery": _gallery(c, bounds.size, far, clock, p)
	c.draw_set_transform(Vector2.ZERO)

static func _drop(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	if far:
		# Two torn shaft ribs frame the wound. The centre stays open enough to
		# read the return climb without a field of small architectural marks.
		for side in [-1.0, 1.0]:
			var x: float = size.x * (0.5 + side * 0.36)
			Brush.curve(c, Vector2(x, -90), Vector2(x - side * 160, size.y * 0.45), Vector2(x + side * 37, size.y + 90), Brush.fade(p.shadow, 0.45), 146)
			Brush.curve(c, Vector2(x - side * 49, -70), Vector2(x - side * 208, size.y * 0.45), Vector2(x - side * 28, size.y + 70), Brush.fade(p.copper, 0.20), 13)
		return
	for i: int in [0, 5]:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x: float = size.x * 0.5 + side * (230 + i * 34)
		var end := Vector2(x + side * 48 + sin(clock * 0.17 + i) * 4, size.y * (0.48 + i * 0.071))
		Brush.cable(c, Vector2(x - side * 70, -60), end, 130 - i * 16, _faint(p, 0.66))
		Brush.line(c, end, end + Vector2(4, 31), Brush.fade(p.copper, 0.54), 5)
	for i: int in [3]:
		var y := 135.0 + i * (size.y - 190) / 7
		Brush.curve(c, Vector2(size.x * 0.13, y), Vector2(size.x * 0.48, y + 43), Vector2(size.x * 0.87, y + 5), Brush.fade(p.copper, 0.10), 6)
	Brush.motes(c, Rect2(size.x * 0.25, 170, size.x * 0.5, size.y - 260), clock, p.copper, 3)

static func _landing(c: CanvasItem, _size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	var center := Vector2(980, 355)
	if far:
		_archway(c, center + Vector2(0, 15), Vector2(492, 348), 659, _faint(p, 0.13), 24)
		return
	# An unmoving spindle sits behind the junction. It is an architectural
	# landmark rather than a spinning mechanism or a misleading interactive cue.
	_ellipse_fill(c, center + Vector2(0, 199), Vector2(291, 52), Brush.fade(p.shadow, 0.92))
	var base := center + Vector2(0, 189)
	_ellipse_fill(c, base, Vector2(276, 45), p.body.lerp(p.copper, 0.15))
	Brush.ellipse(c, base, Vector2(276, 45), Brush.fade(p.copper, 0.38), 3)
	_column(c, center.x, 205, 512, 86, p)
	_ellipse_fill(c, Vector2(center.x, 205), Vector2(43, 17), p.copper)
	_ellipse_fill(c, Vector2(center.x, 205), Vector2(28, 9), p.shadow)
	Brush.motes(c, Rect2(center.x - 354, 166, 708, 347), clock, p.gold, 2)

static func _verse(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	if far:
		for x: float in [300.0, size.x - 300.0]:
			_archway(c, Vector2(x, 414), Vector2(209, 331), 680, _faint(p, 0.10), 26)
		return
	# A few broad vaults leave the central fight clear of decorative script.
	for i: int in [0, 5]:
		var x: float = 199.0 + i * (size.x - 370) / 5
		_archway(c, Vector2(x, 307), Vector2(122, 163), 678, _faint(p, 0.23), 18)
	Brush.motes(c, Rect2(184, 172, size.x - 360, 354), clock, p.light, 2)

static func _warren(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary, lower: bool) -> void:
	if far:
		# The district silhouette supplies room mass; keep this plane open.
		return
	for i: int in [1, 5]:
		var x := 143.0 + i * (size.x - 285) / 6
		var y := 225.0 + (i % 3) * 76 + (46 if lower else 0)
		var radius := 65.0 + (i % 3) * 11
		# The old record homes hang from the vault on paired copper ties.
		# These attachments make their piled wax rims read as built dwellings.
		Brush.cable(c, Vector2(x, -30), Vector2(x, y - radius * 0.65), 24, _faint(p, 0.32))
		_record_burrow(c, Vector2(x, y), radius, _faint(p, 0.56), i % 3 == 1)
		var base := Vector2(x, y + radius * 0.79)
		_ellipse_fill(c, base, Vector2(radius * 0.77, 9), Brush.fade(p.shadow, 0.82))
	# Long cloth tails move by a few pixels behind the actors and never imply
	# a climbable cable or create edges between the actual platform islands.
	for i in range(0, 4, 3):
		var x := 256.0 + i * (size.x - 490) / 3
		var hem := 402.0 + i % 2 * 43
		var flutter := sin(clock * 0.21 + i) * 3
		Brush.wash(c, PackedVector2Array([Vector2(x - 21, 142), Vector2(x + 22, 145), Vector2(x + 18 + flutter, hem), Vector2(x - 9 + flutter, hem - 12)]), Brush.fade(p.copper, 0.22))
	if not lower:
		for i: int in [1]:
			var center := Vector2(230 + i * 413, 654 + i % 2 * 31)
			Brush.cable(c, center + Vector2(0, -189), center + Vector2(0, -24), 18, _faint(p, 0.24))
			_record_burrow(c, center, 59, _faint(p, 0.37), i == 1)
	Brush.motes(c, Rect2(166, 175, size.x - 330, size.y - 360), clock, p.copper, 3)

static func _record_burrow(c: CanvasItem, center: Vector2, radius: float, p: Dictionary, lit: bool) -> void:
	_ellipse_fill(c, center, Vector2(radius + 5, radius * 0.86 + 5), Color(p.shadow, minf(1.0, p.shadow.a * 1.5)))
	_ellipse_fill(c, center, Vector2(radius - 5, radius * 0.86 - 5), p.body)
	Brush.ellipse(c, center, Vector2(radius, radius * 0.86), Brush.fade(p.copper, 0.60), 6)
	# One recessed opening is enough to read a dwelling; no window grille or
	# miniature vault competes with the nearby live voices.
	c.draw_rect(Rect2(center + Vector2(-radius * 0.24, -radius * 0.36), Vector2(radius * 0.48, radius * 0.70)),
		Brush.fade(p.gold if lit else p.shadow, 0.24 if lit else 0.80))

static func _gallery(c: CanvasItem, _size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	var center := Vector2(650, 625)
	if far:
		_archway(c, center, Vector2(601, 451), 863, _faint(p, 0.14), 28)
		return
	for side in [-1.0, 1.0]:
		var x: float = center.x + side * 548
		_column(c, x, 70, 849, 70, _faint(p, 0.24))
		_chair(c, Vector2(center.x + side * 130, 765), side, p)
	# Two empty chairs and a closed score: a still, unfinished duet. Nothing
	# flashes, plays or changes outcomes merely for arriving at this landmark.
	Brush.line(c, center + Vector2(0, 22), center + Vector2(0, 168), Brush.fade(p.copper, 0.48), 5)
	Brush.line(c, center + Vector2(-22, 170), center + Vector2(22, 170), Brush.fade(p.copper, 0.42), 4)
	Brush.wash(c, PackedVector2Array([center + Vector2(-42, -8), center + Vector2(32, -15), center + Vector2(39, 37), center + Vector2(-36, 47)]), Brush.fade(p.body, 0.93))
	Brush.line(c, center + Vector2(-31, -7), center + Vector2(-26, 41), Brush.fade(p.gold, 0.27), 2)
	Brush.motes(c, Rect2(center.x - 398, 350, 796, 427), clock, p.gold, 2)

static func _chair(c: CanvasItem, point: Vector2, face: float, p: Dictionary) -> void:
	for side in [-1.0, 1.0]:
		Brush.line(c, point + Vector2(side * 32, -5), point + Vector2(side * 40, 67), p.shadow, 11)
		Brush.line(c, point + Vector2(side * 31, -5), point + Vector2(side * 39, 65), p.copper, 6)
	_ellipse_fill(c, point + Vector2(0, -8), Vector2(42, 12), p.shadow)
	_ellipse_fill(c, point + Vector2(0, -13), Vector2(40, 8), p.copper)
	var back := point + Vector2(face * 30, -4)
	Brush.curve(c, back, back + Vector2(face * 13, -81), back + Vector2(face * 1, -117), p.shadow, 13)
	Brush.curve(c, back, back + Vector2(face * 13, -81), back + Vector2(face * 1, -117), p.copper, 7)
	_ellipse_fill(c, back + Vector2(0, -85), Vector2(29, 36), p.copper)
	_ellipse_fill(c, back + Vector2(-2, -87), Vector2(23, 29), p.body)

static func _archway(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float, p: Dictionary, weight: float) -> void:
	Brush.ellipse(c, center, radius, Brush.fade(p.shadow, 0.78), weight + 8, PI, TAU)
	Brush.ellipse(c, center, radius, Brush.fade(p.edge, 0.52), weight, PI, TAU)
	for side in [-1.0, 1.0]:
		Brush.line(c, center + Vector2(side * radius.x, 0), Vector2(center.x + side * radius.x, bottom), p.body, weight + 7)

static func _column(c: CanvasItem, x: float, top: float, bottom: float, width: float, p: Dictionary) -> void:
	Brush.wash(c, PackedVector2Array([Vector2(x - width * 0.48, top), Vector2(x + width * 0.50, top + 4),
		Vector2(x + width * 0.42, bottom), Vector2(x - width * 0.52, bottom)]), Brush.fade(p.body, 0.82))
	Brush.line(c, Vector2(x + width * 0.36, top), Vector2(x + width * 0.29, bottom), Brush.fade(p.shadow, 0.7), 7)

static func _ellipse_fill(c: CanvasItem, center: Vector2, radius: Vector2, paint: Color) -> void:
	var polygon := PackedVector2Array()
	for i in range(49):
		var angle := TAU * float(i) / 48.0
		polygon.append(center + Vector2(cos(angle), sin(angle)) * radius)
	Brush.wash(c, polygon, paint)

static func _faint(p: Dictionary, alpha: float) -> Dictionary:
	var copy := {}
	for key in p:
		copy[key] = Color(p[key], alpha)
	return copy
