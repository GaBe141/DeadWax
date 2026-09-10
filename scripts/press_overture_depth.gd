extends RefCounted
## The undercroft shares the Label's brushwork but turns toward violet stone,
## organ brass, hanging cloth and the long reflected light inside the Well.
const Brush := preload("res://scripts/press_world_brush.gd")
const ROOMS := [&"bootlegger", &"whistlers", &"addie", &"overture_well", &"worn_gallery", &"smoothed_floor", &"the_arm"]

static func draw(c: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if not ROOMS.has(room_id) or not bounds.has_area(): return
	var p := Brush.palette(ink, stock)
	if layer == &"foreground":
		Brush.face(c, pose.get("surfaces", []), p, room_id in [&"whistlers", &"overture_well", &"the_arm"])
		return
	if layer not in [&"far", &"middle"]: return
	var far := layer == &"far"
	var clock := float(pose.get("clock", 0.0)) * float(pose.get("motion", 1.0))
	var outcome := String(pose.get("outcome", ""))
	c.draw_set_transform(bounds.position)
	match room_id:
		&"bootlegger": _stall(c, bounds.size, far, clock, p)
		&"whistlers": _whistlers(c, bounds.size, far, clock, p)
		&"addie": _doorway(c, bounds.size, far, clock, p, outcome)
		&"overture_well": _well(c, bounds.size, far, clock, p)
		&"worn_gallery": _gallery(c, bounds.size, far, p)
		&"smoothed_floor": _hush(c, bounds.size, far, p)
		&"the_arm": _arm(c, bounds.size, far, p, outcome)
	c.draw_set_transform(Vector2.ZERO)

static func _stall(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	if far:
		Brush.archway(c, Vector2(822, 339), Vector2(674, 391), 603, _faint(p, 0.19), 29)
		Brush.ellipse(c, Vector2(794, 148), Vector2(382, 152), Brush.fade(p.gold, 0.045), 24)
		return
	for i in range(3):
		var x := 187.0 + i * 519
		Brush.column(c, x, 124, 603, 46, _faint(p, 0.68))
	for row in range(3):
		var y := 286.0 + row * 99
		Brush.curve(c, Vector2(247, y), Vector2(807, y + 10), Vector2(size.x - 184, y - 2), Brush.fade(p.copper, 0.54), 12)
		Brush.line(c, Vector2(253, y - 5), Vector2(size.x - 190, y - 6), Brush.fade(p.gold, 0.23), 2)
		for i in range(17):
			var x := 274.0 + i * 65
			var h := 34.0 + Brush.grain(i * 7.0 + row * 31) * 47
			var tilt := (Brush.grain(i * 13.0) - 0.5) * 8
			Brush.wash(c, PackedVector2Array([Vector2(x + tilt, y - h), Vector2(x + 29 + tilt, y - h - 2), Vector2(x + 28, y - 8), Vector2(x, y - 7)]),
				Color(p.copper if i % 3 == 0 else p.sage, 0.35))
			Brush.line(c, Vector2(x + 6 + tilt, y - h + 5), Vector2(x + 7, y - 14), Brush.fade(p.gold, 0.18), 2)
	Brush.cable(c, Vector2(749, -25), Vector2(765 + sin(clock * 0.22) * 1.5, 99), 11, p)
	Brush.lamp(c, Vector2(765, 118), p, 1.75)
	Brush.motes(c, Rect2(494, 139, 628, 361), clock, p.gold, 18)

static func _whistlers(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	if far:
		for i in range(9):
			var x := -106.0 + i * 369
			var top := 53.0 + Brush.grain(i) * 90
			Brush.curve(c, Vector2(x, size.y + 60), Vector2(x - 109, size.y * 0.55), Vector2(x + 37, top), Brush.fade(p.body, 0.24), 69)
			Brush.curve(c, Vector2(x - 21, size.y), Vector2(x - 128, size.y * 0.55), Vector2(x + 14, top + 9), Brush.fade(p.edge, 0.17), 7)
		return
	for i in range(7):
		var x := 146.0 + i * 391
		var top := 62.0 + Brush.grain(i * 11.0) * 137
		_pipe(c, Vector2(x, top), size.y + 54, 43 + (i % 3) * 9, _faint(p, 0.72))
		var a := Vector2(x + 42, top + 143)
		Brush.wash(c, PackedVector2Array([a, a + Vector2(34, -9), a + Vector2(66 + sin(clock * 0.40 + i) * 7, 90), a + Vector2(46, 126)]), Brush.fade(p.copper, 0.24))
	for i in range(7):
		var y := 218.0 + i * 97
		Brush.curve(c, Vector2(-90, y), Vector2(size.x * 0.45, y - 38 + sin(clock * 0.17 + i) * 13),
			Vector2(size.x + 80, y - 14), Brush.fade(p.light, 0.035), 2)
	Brush.motes(c, Rect2(214, 187, size.x - 400, 659), clock, p.light, 18)

static func _doorway(c: CanvasItem, _size: Vector2, far: bool, clock: float, p: Dictionary, outcome: String) -> void:
	if far:
		Brush.archway(c, Vector2(856, 343), Vector2(573, 369), 629, _faint(p, 0.22), 31)
		if outcome == "freed":
			Brush.ellipse(c, Vector2(845, 314), Vector2(321, 227), Brush.fade(p.gold, 0.06), 36)
		return
	Brush.archway(c, Vector2(845, 350), Vector2(220, 209), 602, p, 22)
	for side in [-1.0, 1.0]:
		var x: float = 845.0 + side * 244
		var flutter := sin(clock * 0.25 + side) * 4
		var hem := 511.0 if outcome == "freed" else 551.0
		var cloth := PackedVector2Array([Vector2(x - 56, 136), Vector2(x + 56, 136), Vector2(x + 67 + flutter, hem),
			Vector2(x + 24, hem + 16), Vector2(x - 24, hem + 3), Vector2(x - 71 + flutter, hem + 13)])
		Brush.wash(c, cloth, Brush.fade(p.copper, 0.46 if outcome != "shattered" else 0.20))
		for fold in range(5):
			Brush.curve(c, Vector2(x - 39 + fold * 20, 152), Vector2(x - 57 + fold * 26, 368), Vector2(x - 52 + fold * 27 + flutter, hem - 5),
				Brush.fade(p.light, 0.13), 3)
		Brush.line(c, Vector2(x - 70, 132), Vector2(x + 69, 132), Brush.fade(p.gold, 0.40), 5)
	Brush.window(c, Rect2(1318, 224, 93, 183), _faint(p, 0.70), outcome != "shattered")
	Brush.cable(c, Vector2(1245, 98), Vector2(1216, 325), 58, p)
	Brush.lamp(c, Vector2(1216, 342), _faint(p, 0.70 if outcome != "shattered" else 0.27), 0.83)
	Brush.motes(c, Rect2(666, 182, 397, 371), clock, p.gold, 10)

static func _well(c: CanvasItem, size: Vector2, far: bool, clock: float, p: Dictionary) -> void:
	if far:
		for i in range(5):
			Brush.ellipse(c, Vector2(size.x * 0.51, 240 + i * 285), Vector2(491, 171), Brush.fade(p.copper, 0.12), 18)
		return
	# Continuous bowed ribs describe the full descent, including the return climb.
	for side in [-1.0, 1.0]:
		var x: float = size.x * 0.5 + side * 486
		Brush.curve(c, Vector2(x, -64), Vector2(x - side * 87, size.y * 0.53), Vector2(x + side * 12, size.y + 72), Brush.fade(p.body, 0.79), 82)
		Brush.curve(c, Vector2(x - side * 21, -48), Vector2(x - side * 111, size.y * 0.54), Vector2(x - side * 18, size.y + 43), Brush.fade(p.copper, 0.38), 7)
		for i in range(7):
			var y := 89.0 + i * 237
			Brush.curve(c, Vector2(x - side * 47, y), Vector2(size.x * 0.5, y + 97), Vector2(size.x * 0.5 - side * 428, y + 4), Brush.fade(p.edge, 0.12), 10)
	Brush.cable(c, Vector2(515, -60), Vector2(730, size.y + 100), 144, _faint(p, 0.56))
	Brush.cable(c, Vector2(761, -50), Vector2(552, size.y + 120), -103, _faint(p, 0.32))
	Brush.window(c, Rect2(309, 100, 92, 156), _faint(p, 0.70), true)
	Brush.motes(c, Rect2(358, 189, 617, size.y - 270), clock, p.light, 24)

static func _gallery(c: CanvasItem, size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(7):
			Brush.archway(c, Vector2(147 + i * 395, 344), Vector2(201, 290), 626, _faint(p, 0.16), 22)
		return
	Brush.curve(c, Vector2(-71, 116), Vector2(size.x * 0.51, 141), Vector2(size.x + 75, 109), Brush.fade(p.copper, 0.27), 11)
	for i in range(7):
		var x := 209.0 + i * 357
		Brush.column(c, x + 149, 148, 610, 43, _faint(p, 0.54))
		var center := Vector2(x, 308 + sin(i) * 14)
		Brush.ellipse(c, center, Vector2(59, 83), Brush.fade(p.shadow, 0.64), 14)
		Brush.ellipse(c, center, Vector2(57, 82), Brush.fade(p.copper, 0.70), 6)
		Brush.ellipse(c, center, Vector2(49, 73), Brush.fade(p.gold, 0.24), 2)
		c.draw_circle(center + Vector2(-4, -20), 17, Brush.fade(p.light, 0.09), true, -1, true)
		Brush.curve(c, center + Vector2(-36, 47), center + Vector2(-1, -19), center + Vector2(35, 48), Brush.fade(p.light, 0.09), 23)
		for tear in range(3):
			Brush.line(c, center + Vector2(-32, -39 + tear * 37), center + Vector2(27, -46 + tear * 37), Brush.fade(p.shadow, 0.36), 4)
		Brush.line(c, center + Vector2(-23, 101), center + Vector2(25, 100), Brush.fade(p.gold, 0.21), 5)

static func _hush(c: CanvasItem, _size: Vector2, far: bool, p: Dictionary) -> void:
	if far:
		for i in range(4):
			Brush.archway(c, Vector2(1100, 340), Vector2(421 + i * 103, 274 + i * 84), 605, _faint(p, 0.13), 27)
		return
	for x in [231.0, 1974.0]:
		Brush.column(c, x, 44, 614, 106, _faint(p, 0.73))
		Brush.column(c, x + (-105 if x > 1100 else 105), 72, 610, 51, _faint(p, 0.44))
	# Steady side drapes, kept outside the opponent's clear central silhouette.
	for side in [-1.0, 1.0]:
		var x: float = 1100.0 + side * 651
		Brush.wash(c, PackedVector2Array([Vector2(x - side * 91, -30), Vector2(x + side * 91, -30),
			Vector2(x + side * 85, 454), Vector2(x + side * 42, 425)]), Brush.fade(p.copper, 0.23))
		Brush.curve(c, Vector2(x - side * 68, 0), Vector2(x - side * 37, 239), Vector2(x + side * 61, 437), Brush.fade(p.gold, 0.12), 3)
	Brush.ellipse(c, Vector2(1100, 589), Vector2(269, 22), Brush.fade(p.light, 0.12), 2)
	Brush.ellipse(c, Vector2(1100, 589), Vector2(247, 16), Brush.fade(p.gold, 0.12), 1)

static func _arm(c: CanvasItem, size: Vector2, far: bool, p: Dictionary, outcome: String) -> void:
	if far:
		var pivot := Vector2(1125, 211)
		for i in range(12):
			var angle := PI * (1.05 + i * 0.073)
			Brush.line(c, pivot + Vector2.from_angle(angle) * 171, pivot + Vector2.from_angle(angle) * 790, Brush.fade(p.copper, 0.08), 17)
		Brush.archway(c, Vector2(1125, 395), Vector2(901, 479), 626, _faint(p, 0.18), 36)
		return
	var pivot := Vector2(size.x * 0.50, 132)
	Brush.ellipse(c, pivot, Vector2(134, 113), Brush.fade(p.copper, 0.51), 21)
	Brush.ellipse(c, pivot, Vector2(108, 89), Brush.fade(p.gold, 0.20), 4)
	for i in range(10):
		var angle := float(i) / 10 * TAU
		c.draw_circle(pivot + Vector2(cos(angle), sin(angle)) * Vector2(124, 104), 4, Brush.fade(p.gold, 0.50), true, -1, true)
	Brush.cable(c, Vector2(775, -43), Vector2(927, 509), 64, _faint(p, 0.45))
	Brush.cable(c, Vector2(1442, -39), Vector2(1362, 507), -57, _faint(p, 0.49))
	Brush.archway(c, Vector2(1820, 382), Vector2(169, 231), 602, _faint(p, 0.81), 23)
	if outcome == "freed":
		Brush.ellipse(c, Vector2(1820, 382), Vector2(162, 223), Brush.fade(p.gold, 0.41), 3, PI, TAU)
	elif outcome == "shattered":
		Brush.line(c, Vector2(1733, 209), Vector2(1773, 224), Brush.fade(p.shadow, 0.82), 9)

static func _pipe(c: CanvasItem, top: Vector2, bottom: float, width: float, p: Dictionary) -> void:
	Brush.curve(c, top, Vector2(top.x - 14, bottom * 0.53), Vector2(top.x + 11, bottom), p.body, width)
	Brush.curve(c, top + Vector2(-width * 0.25, 7), Vector2(top.x - 25, bottom * 0.53), Vector2(top.x - 2, bottom), Brush.fade(p.copper, 0.45), width * 0.17)
	Brush.ellipse(c, top, Vector2(width * 0.51, width * 0.25), p.edge, 5)
	Brush.ellipse(c, top, Vector2(width * 0.32, width * 0.13), p.shadow, 5)
	for y in [top.y + 167, top.y + 439, top.y + 737]:
		if y < bottom: Brush.line(c, Vector2(top.x - width * 0.55, y), Vector2(top.x + width * 0.55, y + 2), Brush.fade(p.copper, 0.56), 8)

static func _faint(p: Dictionary, alpha: float) -> Dictionary:
	var copy := {}
	for key in p: copy[key] = Color(p[key], alpha)
	return copy
