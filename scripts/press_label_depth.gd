extends RefCounted
## Transparent, hand-painted architecture over the cached distant panorama.
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
		for r in [178.0, 220.0, 250.0]:
			Brush.ellipse(c, Vector2(290, 305), Vector2(r, r * 0.94), Brush.fade(p.copper, 0.14), 7)
		Brush.archway(c, Vector2(1055, 265), Vector2(217, 208), 586, _faint(p, 0.28), 19)
		return
	Brush.curve(c, Vector2(47, 86), Vector2(340, 190), Vector2(653, 132), p.body, 24)
	Brush.curve(c, Vector2(45, 81), Vector2(339, 182), Vector2(653, 126), Brush.fade(p.copper, 0.62), 4)
	for side in [80.0, 635.0]:
		Brush.curve(c, Vector2(side, 150), Vector2(side - 37, 350), Vector2(side + 3, 578), Brush.fade(p.body, 0.80), 22)
		Brush.line(c, Vector2(side - 7, 177), Vector2(side - 18, 519), Brush.fade(p.gold, 0.17), 3)
	Brush.curve(c, Vector2(102, 543), Vector2(346, 578), Vector2(610, 542), p.copper, 8)
	for i in range(6):
		var x := 127.0 + i * 85
		Brush.cable(c, Vector2(x, 148 + sin(i) * 12), Vector2(x + 27, 535), 18, _faint(p, 0.62))
		c.draw_circle(Vector2(x, 147 + sin(i) * 12), 4.5, Brush.fade(p.gold, 0.65), true, -1, true)
	var lamp := Vector2(590 + sin(time * 0.30) * 3.0, 290)
	Brush.cable(c, Vector2(578, 137), lamp - Vector2(0, 14), 12, p)
	Brush.lamp(c, lamp, p, 0.75)
	Brush.window(c, Rect2(size.x - 137, 177, 85, 339), p, true)
	if outcome == "freed":
		Brush.curve(c, Vector2(101, 549), Vector2(331, 569), Vector2(557, 548), Brush.fade(p.gold, 0.68), 3)
	Brush.motes(c, Rect2(530, 250, 600, 270), time, p.gold, 13)

static func _plaza(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(7):
			var x := -120.0 + i * 325
			_roof(c, Rect2(x, 167 + sin(i * 1.4) * 39, 279, 425), _faint(p, 0.25), i)
		return
	for i in range(5):
		Brush.archway(c, Vector2(180 + i * 350, 372), Vector2(138, 212), 603, _faint(p, 0.68), 13)
	Brush.cable(c, Vector2(-30, 93), Vector2(size.x + 20, 109), 190, p)
	for i in range(8):
		var a := Vector2(56 + i * 246, 99 + sin(float(i) / 7 * PI) * 91)
		Brush.wash(c, PackedVector2Array([a, a + Vector2(42, 4), a + Vector2(24, 49)]), Color(p.copper if i % 2 == 0 else p.sage, 0.37))
	Brush.ellipse(c, Vector2(809, 569), Vector2(237, 41), Brush.fade(p.copper, 0.17), 6)
	Brush.ellipse(c, Vector2(809, 569), Vector2(222, 35), Brush.fade(p.gold, 0.19), 2)

static func _street(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(5):
			_roof(c, Rect2(-90 + i * 477, 145 + Brush.grain(i * 3.0) * 100, 397, 420), _faint(p, 0.22), i)
		return
	for i in range(5):
		var x := 91.0 + i * 435
		Brush.window(c, Rect2(x, 247 + (i % 2) * 29, 62, 139), _faint(p, 0.80), i % 3 != 1)
		Brush.window(c, Rect2(x + 149, 208 + (i % 2) * 30, 46, 117), _faint(p, 0.62), i % 2 == 0)
		Brush.curve(c, Vector2(x - 33, 414), Vector2(x + 123, 389), Vector2(x + 225, 421), Brush.fade(p.copper, 0.35), 9)
	Brush.cable(c, Vector2(-80, 119), Vector2(size.x + 60, 104), 180, p)
	Brush.cable(c, Vector2(213, 0), Vector2(407, 552), -53, _faint(p, 0.47))
	Brush.cable(c, Vector2(1488, 0), Vector2(1610, 528), 24, _faint(p, 0.36))

static func _practice(c: CanvasItem, _size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		Brush.archway(c, Vector2(842, 333), Vector2(614, 354), 611, _faint(p, 0.31), 20)
		for i in range(5):
			Brush.ellipse(c, Vector2(350 + i * 215, 283), Vector2(69, 88), Brush.fade(p.copper, 0.07), 10)
		return
	Brush.column(c, 143, 96, 598, 84, _faint(p, 0.75))
	Brush.column(c, 1510, 97, 598, 88, _faint(p, 0.75))
	Brush.window(c, Rect2(1010, 156, 160, 271), p, true)
	for i in range(7):
		var x := 247.0 + i * 35
		var top := 272.0 - sin(i * 0.38) * 96
		Brush.line(c, Vector2(x, top), Vector2(x, 519), Brush.fade(p.copper, 0.45), 16)
		Brush.line(c, Vector2(x - 4, top + 5), Vector2(x - 4, 505), Brush.fade(p.gold, 0.21), 3)
		Brush.ellipse(c, Vector2(x, top), Vector2(8, 4), Brush.fade(p.shadow, 0.75), 2)
	Brush.cable(c, Vector2(303, 91), Vector2(380 + sin(time * 0.22) * 2, 240), 17, p)
	Brush.motes(c, Rect2(830, 180, 400, 339), time, p.gold, 14)

static func _stalls(c: CanvasItem, size: Vector2, far: bool, time: float, p: Dictionary) -> void:
	if far:
		for i in range(5):
			_roof(c, Rect2(-93 + i * 532, 121 + sin(i) * 34, 419, 434), _faint(p, 0.24), i)
		return
	for i in range(4):
		var x := 180.0 + i * 552
		var sway := sin(time * 0.38 + i) * 3
		var cloth := PackedVector2Array([Vector2(x - 104, 179), Vector2(x + 189, 161),
			Vector2(x + 224 + sway, 234), Vector2(x + 163, 252), Vector2(x + 68, 248), Vector2(x - 119 + sway, 266)])
		Brush.wash(c, cloth, Color(p.copper if i % 2 == 0 else p.sage, 0.40))
		Brush.stroke(c, PackedVector2Array([cloth[5], cloth[4], cloth[3], cloth[2]]), Brush.fade(p.gold, 0.33), 3)
		Brush.cable(c, Vector2(x - 104, 177), Vector2(x + 188, 160), 7, p)
		for fold in range(5):
			Brush.line(c, Vector2(x - 63 + fold * 52, 185), Vector2(x - 60 + fold * 60 + sway, 246), Brush.fade(p.shadow, 0.23), 3)
		Brush.window(c, Rect2(x - 58, 320, 80, 119), _faint(p, 0.54), i == 0, false)
	Brush.cable(c, Vector2(106, 47), Vector2(size.x - 102, 91), 92, _faint(p, 0.72))
	# Low reflections decorate the service lane without inventing a floor.
	for i in range(12):
		var x := 541.0 + i * 93
		Brush.line(c, Vector2(x, 841 + sin(i * 2.0) * 6), Vector2(x + 49, 842), Brush.fade(p.gold, 0.06), 2)
	Brush.motes(c, Rect2(110, 226, size.x - 220, 326), time, p.gold, 21)

static func _yard(c: CanvasItem, _size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(11):
			var x := 35.0 + i * 205
			Brush.curve(c, Vector2(x, 599), Vector2(x + 13, 234), Vector2(x - 54, 118 + sin(i) * 61), Brush.fade(p.shadow, 0.28), 12)
			Brush.curve(c, Vector2(x - 14, 319), Vector2(x - 119, 177), Vector2(x - 122, 221), Brush.fade(p.edge, 0.14), 3)
		return
	for i in range(9):
		var x := 130.0 + i * 235
		var h := 76.0 + Brush.grain(i * 17.0) * 77
		Brush.archway(c, Vector2(x, 545 - h), Vector2(34, 33), 578, _faint(p, 0.67), 13)
		for mark in range(3):
			Brush.line(c, Vector2(x - 19, 552 - h + mark * 12), Vector2(x + 17, 548 - h + mark * 12), Brush.fade(p.gold, 0.21), 2)
		Brush.curve(c, Vector2(x - 47, 595), Vector2(x - 45, 552), Vector2(x - 76, 555), Brush.fade(p.sage, 0.45), 3)
	for i in range(6):
		var x := 173.0 + i * 347
		Brush.curve(c, Vector2(x, 588), Vector2(x + 43, 529), Vector2(x + 70, 544), Brush.fade(p.sage, 0.27), 2)

static func _descent(c: CanvasItem, _size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(4):
			Brush.archway(c, Vector2(1080, 346 + i * 8), Vector2(482 - i * 58, 371 - i * 37), 628, _faint(p, 0.12), 24)
		return
	Brush.archway(c, Vector2(1110, 365), Vector2(211, 229), 602, p, 25)
	Brush.column(c, 849, 283, 604, 55, _faint(p, 0.77))
	Brush.column(c, 1377, 283, 604, 55, _faint(p, 0.77))
	Brush.ellipse(c, Vector2(1110, 240), Vector2(57, 60), Brush.fade(p.copper, 0.67), 11)
	Brush.ellipse(c, Vector2(1110, 240), Vector2(42, 46), Brush.fade(p.gold, 0.24), 3)
	for side in [-1.0, 1.0]:
		Brush.cable(c, Vector2(1110 + side * 212, 87), Vector2(1110 + side * 104, 513), 75, p)
	Brush.cable(c, Vector2(27, 182), Vector2(739, 129), 107, _faint(p, 0.63))

static func _stair(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(4):
			Brush.curve(c, Vector2(-120, 53 + i * 126), Vector2(850, 154 + i * 150), Vector2(size.x + 140, 675 + i * 113), Brush.fade(p.copper, 0.08), 17)
		return
	for i in range(6):
		var x := 174.0 + i * 310
		var top := 85 + i * 108.0
		Brush.column(c, x, top, minf(size.y + 80, top + 655), 61, _faint(p, 0.58))
		Brush.cable(c, Vector2(x - 36, top + 46), Vector2(x + 157, top + 323), 35, _faint(p, 0.78))
	Brush.archway(c, Vector2(1516, 681), Vector2(166, 178), 930, p, 18)
	Brush.window(c, Rect2(88, 61, 70, 210), _faint(p, 0.77), true)

static func _roof(c: CanvasItem, box: Rect2, p: Dictionary, seed: int) -> void:
	var ridge := box.position + Vector2(box.size.x * (0.42 + Brush.grain(seed) * 0.16), -59 - Brush.grain(seed + 3) * 52)
	Brush.wash(c, PackedVector2Array([box.position + Vector2(-14, 5), ridge, Vector2(box.end.x + 11, box.position.y + 17), box.end, Vector2(box.position.x, box.end.y)]), p.body)
	Brush.stroke(c, PackedVector2Array([box.position + Vector2(-14, 2), ridge, Vector2(box.end.x + 11, box.position.y + 14)]), p.edge, 7)
	Brush.line(c, ridge + Vector2(-8, 4), Vector2(box.end.x + 11, box.position.y + 18), p.copper, 2)

static func _faint(p: Dictionary, alpha: float) -> Dictionary:
	var copy := {}
	for key in p: copy[key] = Color(p[key], alpha)
	return copy
