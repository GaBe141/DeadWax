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
		# A torn edge crossing the older shaft painting makes the wound distinct
		# from the Well. The centre stays open enough to read the return climb.
		for side in [-1.0, 1.0]:
			var x: float = size.x * (0.5 + side * 0.36)
			Brush.curve(c, Vector2(x, -90), Vector2(x - side * 160, size.y * 0.45), Vector2(x + side * 37, size.y + 90), Brush.fade(p.shadow, 0.45), 146)
			Brush.curve(c, Vector2(x - side * 49, -70), Vector2(x - side * 208, size.y * 0.45), Vector2(x - side * 28, size.y + 70), Brush.fade(p.copper, 0.20), 13)
		return
	for i in range(6):
		var side := -1.0 if i % 2 == 0 else 1.0
		var x: float = size.x * 0.5 + side * (230 + i * 34)
		var end := Vector2(x + side * 48 + sin(clock * 0.17 + i) * 4, size.y * (0.48 + i * 0.071))
		Brush.cable(c, Vector2(x - side * 70, -60), end, 130 - i * 16, _faint(p, 0.66))
		Brush.line(c, end, end + Vector2(4, 31), Brush.fade(p.copper, 0.54), 5)
		for strand in range(3):
			Brush.line(c, end + Vector2(4, 31), end + Vector2(-7 + strand * 10, 44 + strand * 4), Brush.fade(p.gold, 0.35), 1)
	for i in range(7):
		var y := 135.0 + i * (size.y - 190) / 7
		Brush.curve(c, Vector2(size.x * 0.13, y), Vector2(size.x * 0.48, y + 43), Vector2(size.x * 0.87, y + 5), Brush.fade(p.copper, 0.10), 6)
	Brush.motes(c, Rect2(size.x * 0.25, 170, size.x * 0.5, size.y - 260), clock, p.copper, 24)

static func _landing(c: CanvasItem, _size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	var center := Vector2(980, 355)
	if far:
		for i in range(3):
			Brush.archway(c, center + Vector2(0, i * 15), Vector2(383 + i * 109, 273 + i * 75), 659, _faint(p, 0.16), 24)
		return
	# An unmoving spindle sits behind the junction. It is an architectural
	# landmark rather than a spinning mechanism or a misleading interactive cue.
	_ellipse_fill(c, center + Vector2(0, 199), Vector2(291, 52), Brush.fade(p.shadow, 0.92))
	for i in range(5):
		var ring := center + Vector2(0, 197 - i * 8)
		var radius := Vector2(284 - i * 19, 45 - i * 3)
		_ellipse_fill(c, ring, radius, p.body.lerp(p.copper, 0.10 + i * 0.035))
		Brush.ellipse(c, ring, radius, Brush.fade(p.copper, 0.54), 3)
		Brush.ellipse(c, ring - Vector2(0, 1), radius - Vector2(3, 2), Brush.fade(p.gold, 0.12), 1, PI, TAU)
	Brush.column(c, center.x, 205, 512, 86, p)
	_ellipse_fill(c, Vector2(center.x, 205), Vector2(43, 17), p.copper)
	Brush.ellipse(c, Vector2(center.x, 205), Vector2(43, 17), Brush.fade(p.gold, 0.43), 3)
	_ellipse_fill(c, Vector2(center.x, 205), Vector2(28, 9), p.shadow)
	for y in [266.0, 349.0, 487.0]:
		Brush.ellipse(c, Vector2(center.x, y), Vector2(43, 8), Brush.fade(p.copper, 0.48), 3, 0, PI)
	for side in [-1.0, 1.0]:
		var x: float = center.x + side * 468
		Brush.archway(c, Vector2(x, 355), Vector2(139, 183), 620, _faint(p, 0.25), 24)
		Brush.window(c, Rect2(x - 32, 200, 64, 107), _faint(p, 0.45), true)
	Brush.motes(c, Rect2(center.x - 354, 166, 708, 347), clock, p.gold, 15)

static func _verse(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	if far:
		for i in range(7):
			Brush.archway(c, Vector2(164 + i * 411, 414), Vector2(209, 331), 680, _faint(p, 0.12), 26)
		return
	for i in range(6):
		var x := 199.0 + i * (size.x - 370) / 5
		Brush.archway(c, Vector2(x, 307), Vector2(122, 163), 678, _faint(p, 0.29), 18)
		# Half-erased copper handwriting follows the vaults. Its rhythm comes
		# from incomplete strokes; gameplay instructions remain real room cards.
		for glyph in range(13):
			var angle := PI * (1.12 + glyph * 0.062)
			var point := Vector2(x, 307) + Vector2(cos(angle), sin(angle)) * Vector2(151, 194)
			Brush.curve(c, point + Vector2(-4, 4), point + Vector2(3, -10 - glyph % 3), point + Vector2(7, 5), Brush.fade(p.gold, 0.23), 1.5)
			if glyph % 3 == 0:
				Brush.line(c, point + Vector2(-6, 1), point + Vector2(8, -1), Brush.fade(p.copper, 0.29), 1)
		for row in range(4):
			var y := 370.0 + row * 26
			Brush.curve(c, Vector2(x - 59, y), Vector2(x + 8, y - 6), Vector2(x + 62 - row * 12, y + 1), Brush.fade(p.copper, 0.13), 2)
	Brush.motes(c, Rect2(184, 172, size.x - 360, 354), clock, p.light, 16)

static func _warren(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary, lower: bool) -> void:
	if far:
		for row in range(3):
			for i in range(5):
				var center := Vector2(123 + i * 431 + row % 2 * 116, 111 + row * 212)
				Brush.ellipse(c, center, Vector2(112, 96), Brush.fade(p.shadow, 0.15), 12)
		return
	for i in range(7):
		var x := 143.0 + i * (size.x - 285) / 6
		var y := 225.0 + (i % 3) * 76 + (46 if lower else 0)
		var radius := 65.0 + (i % 3) * 11
		# The old record homes hang from the vault on paired copper ties.
		# These attachments make their piled wax rims read as built dwellings.
		for side in [-1.0, 1.0]:
			Brush.cable(c, Vector2(x + side * radius * 0.81, -30), Vector2(x + side * radius * 0.69, y - radius * 0.47), 24, _faint(p, 0.41))
		_record_burrow(c, Vector2(x, y), radius, _faint(p, 0.56), i % 3 == 1)
		for tier in range(3):
			var base := Vector2(x, y + radius * 0.79 + tier * 5)
			_ellipse_fill(c, base, Vector2(radius * 0.77 - tier * 5, 9), Brush.fade(p.shadow, 0.82))
			Brush.ellipse(c, base, Vector2(radius * 0.77 - tier * 5, 9), Brush.fade(p.copper, 0.30), 2, 0, PI)
		if i % 2 == 0:
			Brush.cable(c, Vector2(x - 69, y - 7), Vector2(x + 96, y + 34), 34, _faint(p, 0.39))
	# Long cloth tails move by a few pixels behind the actors and never imply
	# a climbable cable or create edges between the actual platform islands.
	for i in range(4):
		var x := 256.0 + i * (size.x - 490) / 3
		var hem := 402.0 + i % 2 * 43
		var flutter := sin(clock * 0.21 + i) * 3
		Brush.wash(c, PackedVector2Array([Vector2(x - 21, 142), Vector2(x + 22, 145), Vector2(x + 18 + flutter, hem), Vector2(x - 9 + flutter, hem - 12)]), Brush.fade(p.copper, 0.22))
		Brush.curve(c, Vector2(x - 8, 156), Vector2(x - 5, 299), Vector2(x + 1 + flutter, hem - 13), Brush.fade(p.gold, 0.11), 2)
	if not lower:
		for i in range(4):
			var center := Vector2(230 + i * 413, 654 + i % 2 * 31)
			Brush.cable(c, center + Vector2(-43, -189), center + Vector2(-39, -24), 18, _faint(p, 0.30))
			Brush.cable(c, center + Vector2(43, -174), center + Vector2(39, -24), 18, _faint(p, 0.30))
			_record_burrow(c, center, 59, _faint(p, 0.37), i == 1)
	Brush.motes(c, Rect2(166, 175, size.x - 330, size.y - 360), clock, p.copper, 17)

static func _record_burrow(c: CanvasItem, center: Vector2, radius: float, p: Dictionary, lit: bool) -> void:
	_ellipse_fill(c, center, Vector2(radius + 5, radius * 0.86 + 5), Color(p.shadow, minf(1.0, p.shadow.a * 1.5)))
	_ellipse_fill(c, center, Vector2(radius - 5, radius * 0.86 - 5), p.body)
	Brush.ellipse(c, center, Vector2(radius, radius * 0.86), Brush.fade(p.copper, 0.77), 8)
	for ring in range(4):
		Brush.ellipse(c, center, Vector2(radius - ring * 6, (radius - ring * 6) * 0.86), Brush.fade(p.copper, 0.49 - ring * 0.08), 2)
	Brush.ellipse(c, center - Vector2(1, 1), Vector2(radius - 3, (radius - 3) * 0.86), Brush.fade(p.gold, 0.19), 1, PI * 1.15, PI * 1.65)
	Brush.window(c, Rect2(center + Vector2(-radius * 0.27, -radius * 0.41), Vector2(radius * 0.54, radius * 0.73)), p, lit)
	Brush.line(c, center + Vector2(-radius * 0.47, radius * 0.57), center + Vector2(radius * 0.50, radius * 0.58), Brush.fade(p.gold, 0.31), 4)

static func _gallery(c: CanvasItem, _size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	var center := Vector2(650, 625)
	if far:
		Brush.archway(c, center, Vector2(601, 451), 863, _faint(p, 0.18), 28)
		for i in range(5):
			Brush.ellipse(c, center + Vector2(0, 102), Vector2(183 + i * 87, 124 + i * 42), Brush.fade(p.copper, 0.055), 4, PI, TAU)
		return
	for side in [-1.0, 1.0]:
		var x: float = center.x + side * 548
		Brush.column(c, x, 70, 849, 70, _faint(p, 0.30))
		Brush.window(c, Rect2(x - 38, 128, 76, 183), _faint(p, 0.41), true)
		_chair(c, Vector2(center.x + side * 130, 765), side, p)
	# Two empty chairs and a closed score: a still, unfinished duet. Nothing
	# flashes, plays or changes outcomes merely for arriving at this landmark.
	Brush.line(c, center + Vector2(0, 22), center + Vector2(0, 168), Brush.fade(p.copper, 0.48), 5)
	Brush.line(c, center + Vector2(-22, 170), center + Vector2(22, 170), Brush.fade(p.copper, 0.42), 4)
	Brush.wash(c, PackedVector2Array([center + Vector2(-44, -12), center + Vector2(-2, -5), center + Vector2(43, -13), center + Vector2(39, 44), center + Vector2(-1, 49), center + Vector2(-41, 41)]), Brush.fade(p.body, 0.93))
	Brush.line(c, center + Vector2(-1, -2), center + Vector2(-1, 43), Brush.fade(p.gold, 0.27), 2)
	for side in [-1.0, 1.0]:
		for row in range(4):
			Brush.line(c, center + Vector2(side * 9, 8 + row * 7), center + Vector2(side * 32, 5 + row * 7), Brush.fade(p.light, 0.13), 1)
	Brush.motes(c, Rect2(center.x - 398, 350, 796, 427), clock, p.gold, 12)

static func _chair(c: CanvasItem, point: Vector2, face: float, p: Dictionary) -> void:
	for side in [-1.0, 1.0]:
		Brush.line(c, point + Vector2(side * 32, -5), point + Vector2(side * 40, 67), p.shadow, 11)
		Brush.line(c, point + Vector2(side * 31, -5), point + Vector2(side * 39, 65), p.copper, 6)
		Brush.line(c, point + Vector2(side * 30, 1), point + Vector2(side * 37, 54), Brush.fade(p.gold, 0.17), 1)
	_ellipse_fill(c, point + Vector2(0, -8), Vector2(42, 12), p.shadow)
	_ellipse_fill(c, point + Vector2(0, -13), Vector2(40, 8), p.copper)
	Brush.ellipse(c, point + Vector2(0, -13), Vector2(39, 7), Brush.fade(p.gold, 0.25), 1, PI, TAU)
	var back := point + Vector2(face * 30, -4)
	Brush.curve(c, back, back + Vector2(face * 13, -81), back + Vector2(face * 1, -117), p.shadow, 13)
	Brush.curve(c, back, back + Vector2(face * 13, -81), back + Vector2(face * 1, -117), p.copper, 7)
	_ellipse_fill(c, back + Vector2(0, -85), Vector2(29, 36), p.copper)
	_ellipse_fill(c, back + Vector2(-2, -87), Vector2(23, 29), p.body)
	Brush.ellipse(c, back + Vector2(-2, -87), Vector2(23, 29), Brush.fade(p.gold, 0.25), 2)
	for stripe in range(4):
		Brush.line(c, back + Vector2(-13 + stripe * 7, -105), back + Vector2(-12 + stripe * 7, -71), Brush.fade(p.light, 0.11), 1)

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
