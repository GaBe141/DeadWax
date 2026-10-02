extends RefCounted
## A few broad landmarks over the quiet distant silhouettes.
const Brush := preload("res://scripts/press_world_brush.gd")

static func draw(c: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if not bounds.has_area(): return
	var p := Brush.palette(ink, stock)
	if layer == &"foreground":
		Brush.face(c, pose.get("surfaces", []), p, room_id in [&"headshell", &"label_descent", &"overture_stair"])
		return
	if layer not in [&"far", &"middle"]: return
	var far := layer == &"far"
	var time := float(pose.get("clock", 0.0)) * float(pose.get("motion", 1.0))
	c.draw_set_transform(bounds.position)
	match room_id:
		&"headshell": _headshell(c, bounds.size, far, time, p, String(pose.get("outcome", "")))
		&"horn_plaza": _plaza(c, bounds.size, far, p)
		&"high_street": _street(c, bounds.size, far, p)
		&"practice_room": _practice(c, bounds.size, far, time, p)
		&"the_stalls": _stalls(c, bounds.size, far, time, p)
		&"groove_yard": _yard(c, bounds.size, far, p)
		&"label_descent": _descent(c, bounds.size, far, p)
		&"overture_stair": _stair(c, bounds.size, far, p)
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
	c.draw_rect(Rect2(100, 247, 110, 154), Brush.fade(p.body, 0.6))
	Brush.curve(c, Vector2(69, 414), Vector2(192, 389), Vector2(316, 421), Brush.fade(p.copper, 0.18), 8)
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
