extends RefCounted
## A few broad landmarks over the quiet distant silhouettes.
const Brush := preload("res://scripts/press_world_brush.gd")

static func draw(c: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if not bounds.has_area(): return
	var p := Brush.palette(ink, stock)
	if layer == &"foreground":
		Brush.begin(c)
		Brush.face(c, pose.get("surfaces", []), p, room_id in [&"headshell", &"label_descent", &"overture_stair"])
		Brush.end(c)
		return
	if layer not in [&"far", &"middle"]: return
	var far := layer == &"far"
	var time := float(pose.get("clock", 0.0)) * float(pose.get("motion", 1.0))
	c.draw_set_transform(bounds.position)
	# Consecutive brush marks share draw calls (see Brush.begin), unless the
	# middle plane is moving and redrawn every few frames.
	var gather := far or not bool(pose.get("middle_moves", false))
	if gather:
		Brush.begin(c)
	match room_id:
		&"headshell": _headshell(c, bounds.size, far, time, p, String(pose.get("outcome", "")))
		&"horn_plaza": _plaza(c, bounds.size, far, p)
		&"high_street": _street(c, bounds.size, far, p)
		&"practice_room": _practice(c, bounds.size, far, time, p)
		&"the_stalls": _stalls(c, bounds.size, far, time, p)
		&"groove_yard": _yard(c, bounds.size, far, p)
		&"label_descent": _descent(c, bounds.size, far, p)
		&"overture_stair": _stair(c, bounds.size, far, p)
		&"rooms_to_let": _lodgings(c, bounds.size, far, time, p)
		&"print_shop": _print_shop(c, bounds.size, far, time, p)
		&"stall_cache": _cache(c, bounds.size, far, p)
		&"label_balcony": _balcony(c, bounds.size, far, time, p)
		&"unsigned_alcove": _alcove(c, bounds.size, far, p)
	if gather:
		Brush.end(c)
	c.draw_set_transform(Vector2.ZERO)

static func _headshell(c: CanvasItem, size: Vector2, far: bool, time: float, p: Dictionary, outcome: String) -> void:
	if far:
		Brush.ellipse(c, Vector2(290, 305), Vector2(230, 216), Brush.fade(p.body, 0.85), 12)
		return
	Brush.curve(c, Vector2(47, 86), Vector2(340, 190), Vector2(653, 132), Brush.fade(p.body, 0.8), 24)
	for side in [80.0, 635.0]:
		Brush.curve(c, Vector2(side, 150), Vector2(side - 37, 350), Vector2(side + 3, 578), Brush.fade(p.body, 0.65), 22)
	Brush.curve(c, Vector2(102, 543), Vector2(346, 578), Vector2(610, 542), Brush.fade(p.copper, 0.28), 7)
	var lamp := Vector2(590 + sin(time * 0.30) * 3.0, 290)
	Brush.line(c, Vector2(578, 137), lamp - Vector2(0, 14), Brush.fade(p.edge, 0.3), 1.5)
	Brush.lamp(c, lamp, _faint(p, 0.45), 0.75)
	Brush.flush(c)
	c.draw_rect(Rect2(size.x - 137, 210, 85, 290), Brush.fade(p.body, 0.45))
	if outcome == "freed":
		Brush.curve(c, Vector2(101, 549), Vector2(331, 569), Vector2(557, 548), Brush.fade(p.gold, 0.5), 3)

static func _plaza(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		_roof(c, Rect2(-80, 170, 470, 425), _faint(p, 0.85), 0)
		_roof(c, Rect2(size.x - 620, 195, 540, 400), _faint(p, 0.75), 2)
		return
	_plain_arch(c, Vector2(180, 372), Vector2(138, 212), 603, Brush.fade(p.body, 0.58), 22)
	_plain_arch(c, Vector2(size.x - 220, 372), Vector2(138, 212), 603, Brush.fade(p.body, 0.45), 22)

static func _street(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		_roof(c, Rect2(-90, 145, 430, 420), _faint(p, 0.8), 0)
		_roof(c, Rect2(size.x - 550, 170, 570, 400), _faint(p, 0.65), 2)
		return
	Brush.flush(c)
	c.draw_rect(Rect2(100, 247, 110, 154), Brush.fade(p.body, 0.6))
	Brush.curve(c, Vector2(69, 414), Vector2(192, 389), Vector2(316, 421), Brush.fade(p.copper, 0.18), 8)
	Brush.flush(c)
	c.draw_rect(Rect2(size.x - 290, 208, 140, 213), Brush.fade(p.body, 0.4))

static func _practice(c: CanvasItem, _size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		_plain_arch(c, Vector2(842, 333), Vector2(614, 354), 611, Brush.fade(p.body, 0.8), 34)
		return
	_pier(c, 143, 96, 598, 84, Brush.fade(p.body, 0.6))
	_pier(c, 1510, 97, 598, 88, Brush.fade(p.body, 0.5))
	for i in range(3):
		var x := 247.0 + i * 50
		var top := 260.0 - sin(i * 0.75) * 85
		Brush.line(c, Vector2(x, top), Vector2(x, 519), Brush.fade(p.copper, 0.18), 17)
	# One hanging marker preserves the room's small decorative response.
	var end := Vector2(380 + sin(time * 0.22) * 2, 240)
	Brush.line(c, Vector2(303, 91), end, Brush.fade(p.edge, 0.18), 1.5)

static func _stalls(c: CanvasItem, size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		_roof(c, Rect2(-93, 150, 470, 410), _faint(p, 0.8), 0)
		_roof(c, Rect2(size.x - 600, 121, 570, 434), _faint(p, 0.7), 2)
		return
	for i in range(0, 4, 2):
		var x := 180.0 + i * 552
		var sway := sin(time * 0.38 + i) * 3
		var cloth := PackedVector2Array([Vector2(x - 104, 179), Vector2(x + 189, 161),
			Vector2(x + 224 + sway, 234), Vector2(x + 163, 252), Vector2(x + 68, 248), Vector2(x - 119 + sway, 266)])
		Brush.wash(c, cloth, Brush.fade(p.copper, 0.18))

static func _yard(c: CanvasItem, _size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for x in [350.0, 1740.0]:
			Brush.curve(c, Vector2(x, 599), Vector2(x + 13, 234), Vector2(x - 54, 130), Brush.fade(p.body, 0.65), 16)
		return
	# The room already authors its headstones. Leave the voices and their
	# memory engraving clear rather than printing a second row over them.
	for x in [173.0, 1540.0]:
		Brush.curve(c, Vector2(x, 588), Vector2(x + 43, 529), Vector2(x + 70, 544), Brush.fade(p.sage, 0.14), 3)

static func _descent(c: CanvasItem, _size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		_plain_arch(c, Vector2(1080, 346), Vector2(482, 371), 628, Brush.fade(p.body, 0.75), 38)
		return
	# The authored door frame supplies the entrance; one worn disc is enough
	# to distinguish this threshold from the ordinary street arches.
	Brush.ellipse(c, Vector2(1110, 240), Vector2(57, 60), Brush.fade(p.copper, 0.24), 8)

static func _stair(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		Brush.curve(c, Vector2(-120, 53), Vector2(850, 154), Vector2(size.x + 140, 675), Brush.fade(p.body, 0.75), 36)
		return
	_pier(c, 174, 85, 740, 61, Brush.fade(p.body, 0.58))
	_pier(c, 1414, 517, minf(size.y + 80, 1172), 61, Brush.fade(p.body, 0.45))
	_plain_arch(c, Vector2(1516, 681), Vector2(166, 178), 930, Brush.fade(p.body, 0.55), 25)

static func _lodgings(c: CanvasItem, size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		# A papered hall wall with one tall window, and the stair going up.
		_plain_arch(c, Vector2(330, 300), Vector2(96, 150), 600, Brush.fade(p.body, 0.75), 20)
		Brush.curve(c, Vector2(size.x - 240, 598), Vector2(size.x - 110, 330), Vector2(size.x + 40, 120), Brush.fade(p.body, 0.7), 26)
		return
	# Radiator pipes along the skirting, knocking a little in the warm room.
	for pipe in range(2):
		var y := 548.0 + pipe * 14.0
		Brush.line(c, Vector2(60, y), Vector2(size.x - 60, y + 2 + sin(time * 1.3 + pipe) * 0.6), Brush.fade(p.copper, 0.28), 5)
	for rib in range(9):
		var x := 120.0 + rib * 24.0
		Brush.line(c, Vector2(x, 520), Vector2(x, 575), Brush.fade(p.copper, 0.22), 6)
	# A row of keys on hooks, every room's, none claimed.
	for hook in range(6):
		var x := 540.0 + hook * 34.0
		Brush.line(c, Vector2(x, 300), Vector2(x, 330 + Brush.grain(hook) * 8), Brush.fade(p.edge, 0.3), 1.5)
		Brush.dot(c, Vector2(x, 334 + Brush.grain(hook) * 8), 4.0, Brush.fade(p.gold, 0.5))
	Brush.flush(c)
	c.draw_rect(Rect2(500, 270, 250, 16), Brush.fade(p.body, 0.5))

static func _print_shop(c: CanvasItem, size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		_plain_arch(c, Vector2(size.x * 0.5, 320), Vector2(size.x * 0.44, 320), 606, Brush.fade(p.body, 0.72), 30)
		return
	# Drying lines across the shop, hung with tomorrow's sheets.
	for line in range(2):
		var y := 150.0 + line * 70.0
		var sag := Vector2(size.x * 0.5, y + 24 + sin(time * 0.3 + line) * 2)
		Brush.curve(c, Vector2(120, y), sag, Vector2(size.x - 120, y), Brush.fade(p.edge, 0.22), 1.5)
		for sheet in range(5):
			var x := 230.0 + sheet * 210.0 + line * 60.0
			var drop := y + 12 + 12 * sin(PI * (x - 120) / (size.x - 240))
			Brush.wash(c, PackedVector2Array([Vector2(x - 26, drop), Vector2(x + 26, drop + 1), Vector2(x + 24, drop + 62), Vector2(x - 28, drop + 60)]), Brush.fade(p.light, 0.16))
			Brush.line(c, Vector2(x - 16, drop + 18), Vector2(x + 14, drop + 18), Brush.fade(p.edge, 0.3), 2)
			Brush.line(c, Vector2(x - 12, drop + 30), Vector2(x + 8, drop + 30), Brush.fade(p.edge, 0.2), 1.2)
	# The press itself: a flywheel and a bed, resting.
	Brush.ellipse(c, Vector2(1010, 470), Vector2(62, 62), Brush.fade(p.edge, 0.34), 7)
	Brush.ellipse(c, Vector2(1010, 470), Vector2(14, 14), Brush.fade(p.copper, 0.4), 6)
	for spoke in range(4):
		var a := spoke * PI / 4.0 + time * 0.0
		Brush.line(c, Vector2(1010, 470) + Vector2.from_angle(a) * 14, Vector2(1010, 470) + Vector2.from_angle(a) * 58, Brush.fade(p.edge, 0.3), 3)
		Brush.line(c, Vector2(1010, 470) - Vector2.from_angle(a) * 14, Vector2(1010, 470) - Vector2.from_angle(a) * 58, Brush.fade(p.edge, 0.3), 3)
	Brush.flush(c)
	c.draw_rect(Rect2(880, 528, 260, 44), Brush.fade(p.body, 0.55))

static func _cache(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		Brush.ellipse(c, Vector2(size.x * 0.52, 360), Vector2(size.x * 0.5, 290), Brush.fade(p.body, 0.8), 14)
		return
	# Crates of unsold wax stacked to the lintel, their lids chalked blank.
	for stack in range(3):
		var x := 980.0 + stack * 86.0
		for crate in range(3 - stack):
			var y := 540.0 - crate * 58.0
			Brush.wash(c, PackedVector2Array([Vector2(x - 36, y), Vector2(x + 36, y - 2), Vector2(x + 34, y - 52), Vector2(x - 38, y - 50)]), Brush.fade(p.body, 0.55))
			Brush.line(c, Vector2(x - 22, y - 26), Vector2(x + 18, y - 27), Brush.fade(p.light, 0.25), 3)

static func _balcony(c: CanvasItem, size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		# The town from above: the horn's bell and the plaza, seen down past
		# the rail, with the streets curving away around them.
		Brush.ellipse(c, Vector2(size.x * 0.5, 470), Vector2(170, 46), Brush.fade(p.copper, 0.32), 10)
		Brush.ellipse(c, Vector2(size.x * 0.5, 470), Vector2(62, 18), Brush.fade(p.gold, 0.3), 5)
		for ring in range(3):
			var r := 300.0 + ring * 120.0
			Brush.ellipse(c, Vector2(size.x * 0.5, 480), Vector2(r, r * 0.26), Brush.fade(p.body, 0.5 - ring * 0.12), 9, PI * 1.06, PI * 1.94)
		return
	# The rail, worn to the shape of two hands at its middle.
	Brush.line(c, Vector2(90, 520), Vector2(size.x - 90, 520), Brush.fade(p.copper, 0.6), 7)
	for post in range(11):
		var x := 110.0 + post * (size.x - 220.0) / 10.0
		Brush.line(c, Vector2(x, 524), Vector2(x, 600), Brush.fade(p.copper, 0.45), 4)
	Brush.ellipse(c, Vector2(size.x * 0.5 - 22, 519), Vector2(26, 6), Brush.fade(p.gold, 0.35), 3)
	Brush.ellipse(c, Vector2(size.x * 0.5 + 24, 519), Vector2(26, 6), Brush.fade(p.gold, 0.35), 3)
	# Washing on a line between the two arches, the only movement up here.
	var sway := sin(time * 0.5) * 4.0
	Brush.curve(c, Vector2(380, 150), Vector2(640, 182 + sway * 0.4), Vector2(900, 150), Brush.fade(p.edge, 0.25), 1.5)
	for cloth in range(3):
		var x := 480.0 + cloth * 160.0
		Brush.wash(c, PackedVector2Array([Vector2(x - 24, 168), Vector2(x + 24, 168), Vector2(x + 30 + sway, 236), Vector2(x - 18 + sway, 238)]), Brush.fade(p.light, 0.2))

static func _alcove(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		# Roots come down through the vault from the graves above.
		Brush.ellipse(c, Vector2(size.x * 0.5, 380), Vector2(size.x * 0.52, 330), Brush.fade(p.body, 0.8), 16)
		for root in range(5):
			var x := 200.0 + root * 240.0
			Brush.curve(c, Vector2(x, 40), Vector2(x + 40 - Brush.grain(root) * 80, 180), Vector2(x - 20 + Brush.grain(root + 2) * 40, 330 + Brush.grain(root + 4) * 70), Brush.fade(p.sage, 0.3), 5)
		return
	# A chalk count on the wall, four even marks, in nobody's hand.
	for mark in range(4):
		var x := 340.0 + mark * 22.0
		Brush.line(c, Vector2(x, 300), Vector2(x + 2, 338), Brush.fade(p.light, 0.45), 3)
	Brush.line(c, Vector2(330, 346), Vector2(420, 344), Brush.fade(p.light, 0.3), 2)

static func _roof(c: CanvasItem, box: Rect2, p: Dictionary, seed: int) -> void:
	var ridge := box.position + Vector2(box.size.x * (0.42 + Brush.grain(seed) * 0.16), -59 - Brush.grain(seed + 3) * 52)
	Brush.wash(c, PackedVector2Array([box.position + Vector2(-14, 5), ridge, Vector2(box.end.x + 11, box.position.y + 17), box.end, Vector2(box.position.x, box.end.y)]), p.body)

static func _plain_arch(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float, paint: Color, weight: float) -> void:
	Brush.ellipse(c, center, radius, paint, weight, PI, TAU)
	for side in [-1.0, 1.0]:
		Brush.line(c, center + Vector2(side * radius.x, 0), Vector2(center.x + side * radius.x, bottom), paint, weight)

static func _pier(c: CanvasItem, x: float, top: float, bottom: float, width: float, paint: Color) -> void:
	Brush.wash(c, PackedVector2Array([Vector2(x - width * 0.48, top), Vector2(x + width * 0.5, top + 4),
		Vector2(x + width * 0.42, bottom), Vector2(x - width * 0.52, bottom)]), paint)

static func _faint(p: Dictionary, alpha: float) -> Dictionary:
	var copy := {}
	for key in p: copy[key] = Color(p[key], alpha)
	return copy
