extends Node2D
## Close architectural subjects, drawn with the same brush as the distant rooms.
## These marks have no collision and never change their authored origin/extent.
const Brush := preload("res://scripts/press_world_brush.gd")
var kind: StringName = &"facade"
var extent := Vector2(400, 400)
var ink := Color("dbc697")
var stock := Color("152e37")

func _draw() -> void:
	var p := Brush.palette(ink, stock)
	draw_set_transform(Vector2.ZERO, 0.0, extent / Vector2(400, 400))
	match kind:
		&"headshell": _cradle(p)
		&"horn": _horn(p)
		&"resting_arm": _resting(p)
		&"organ", &"overture": _organ(p)
		&"column": Brush.column(self, 0, -187, 191, 130, p)
		&"counter": _counter(p)
		&"arch": Brush.archway(self, Vector2(0, -30), Vector2(144, 151), 191, p, 17)
		&"headstone": _headstone(p)
		&"market": _market(p)
		&"stair": _stair(p)
		_: _facade(p)
	draw_set_transform(Vector2.ZERO)

func _cradle(p: Dictionary) -> void:
	var body := PackedVector2Array([Vector2(-174, -106), Vector2(-133, -151), Vector2(134, -129),
		Vector2(175, -88), Vector2(133, 114), Vector2(83, 159), Vector2(-126, 129), Vector2(-161, 91)])
	Brush.wash(self, body, Brush.fade(p.shadow, 0.78))
	Brush.stroke(self, PackedVector2Array([body[0], body[1], body[2], body[3], body[4], body[5], body[6], body[7], body[0]]), Brush.fade(p.copper, 0.72), 9)
	Brush.curve(self, Vector2(-139, -124), Vector2(2, -144), Vector2(139, -108), Brush.fade(p.gold, 0.65), 3)
	for i in range(6):
		var x := -112.0 + i * 43
		Brush.curve(self, Vector2(x, -91), Vector2(x - 16, 16), Vector2(x - 8, 103), Brush.fade(p.body, 0.85), 15)
		Brush.line(self, Vector2(x - 5, -79), Vector2(x - 12, 81), Brush.fade(p.gold, 0.31), 2)
	Brush.ellipse(self, Vector2(6, 118), Vector2(65, 18), Brush.fade(p.copper, 0.80), 6)
	for point in [Vector2(-145, -89), Vector2(139, -74), Vector2(113, 111), Vector2(-134, 88)]:
		draw_circle(point, 6, p.copper, true, -1, true)
		draw_circle(point - Vector2(1, 2), 2, p.gold, true, -1, true)

func _horn(p: Dictionary) -> void:
	Brush.wash(self, PackedVector2Array([Vector2(-33, 89), Vector2(27, 65), Vector2(155, -124), Vector2(-160, -123)]), Brush.fade(p.copper, 0.53))
	Brush.curve(self, Vector2(-158, -122), Vector2(-107, 46), Vector2(-29, 105), Brush.fade(p.shadow, 0.82), 9)
	Brush.curve(self, Vector2(151, -121), Vector2(91, 12), Vector2(26, 68), Brush.fade(p.gold, 0.74), 6)
	Brush.ellipse(self, Vector2(-3, -123), Vector2(159, 53), Brush.fade(p.shadow, 0.80), 18)
	Brush.ellipse(self, Vector2(-3, -123), Vector2(164, 57), Brush.fade(p.copper, 0.91), 9)
	Brush.ellipse(self, Vector2(-3, -123), Vector2(157, 50), Brush.fade(p.gold, 0.74), 3)
	Brush.ellipse(self, Vector2(-3, -123), Vector2(112, 31), Brush.fade(p.body, 0.78), 15)
	for i in range(6):
		Brush.curve(self, Vector2(-21, 75), Vector2(-86 + i * 30, -28), Vector2(-135 + i * 54, -87), Brush.fade(p.gold, 0.23), 2)
	Brush.curve(self, Vector2(-20, 83), Vector2(-49, 139), Vector2(-16, 163), p.copper, 21)
	Brush.line(self, Vector2(-83, 183), Vector2(78, 180), p.body, 19)
	Brush.line(self, Vector2(-79, 175), Vector2(74, 173), Brush.fade(p.gold, 0.54), 3)

func _resting(p: Dictionary) -> void:
	Brush.ellipse(self, Vector2(114, -97), Vector2(38, 36), p.copper, 14)
	Brush.curve(self, Vector2(101, -91), Vector2(-30, -91), Vector2(-90, -22), Brush.fade(p.body, 0.94), 29)
	Brush.curve(self, Vector2(102, -103), Vector2(-30, -101), Vector2(-96, -30), Brush.fade(p.gold, 0.61), 5)
	Brush.curve(self, Vector2(-89, -21), Vector2(-135, 76), Vector2(-101, 135), p.copper, 16)
	Brush.ellipse(self, Vector2(-105, 146), Vector2(45, 27), Brush.fade(p.gold, 0.52), 6, 0, PI)

func _organ(p: Dictionary) -> void:
	for i in range(9):
		var x := -164.0 + i * 41
		var top := -91.0 - absf(i - 4.0) * 24
		Brush.curve(self, Vector2(x, top), Vector2(x - 5, 12), Vector2(x + 3, 184), Brush.fade(p.body, 0.24), 20)
		Brush.curve(self, Vector2(x - 5, top + 6), Vector2(x - 10, 12), Vector2(x - 3, 173), Brush.fade(p.copper, 0.28), 4)
		Brush.ellipse(self, Vector2(x, top), Vector2(10, 5), Brush.fade(p.gold, 0.26), 2)
		Brush.line(self, Vector2(x - 13, 99), Vector2(x + 13, 100), Brush.fade(p.copper, 0.27), 6)

func _counter(p: Dictionary) -> void:
	Brush.wash(self, PackedVector2Array([Vector2(-186, -46), Vector2(189, -36), Vector2(173, 184), Vector2(-175, 178)]), Brush.fade(p.shadow, 0.81))
	Brush.curve(self, Vector2(-197, -48), Vector2(-4, -59), Vector2(198, -42), Brush.fade(p.copper, 0.76), 19)
	Brush.curve(self, Vector2(-195, -57), Vector2(-4, -67), Vector2(196, -51), Brush.fade(p.gold, 0.55), 3)
	for i in range(7):
		var x := -163.0 + i * 53
		Brush.curve(self, Vector2(x, -24), Vector2(x - 5, 68), Vector2(x + 4, 170), Brush.fade(p.edge, 0.50), 3)
		for knot in range(2):
			Brush.ellipse(self, Vector2(x + 14, 43 + knot * 87), Vector2(9, 3), Brush.fade(p.copper, 0.25), 1)
	for i in range(5):
		var x := -132.0 + i * 59
		Brush.ellipse(self, Vector2(x, -89 - (i % 2) * 24), Vector2(22, 26), Brush.fade(p.body, 0.84), 16)
		Brush.ellipse(self, Vector2(x, -89 - (i % 2) * 24), Vector2(12, 15), Brush.fade(p.gold, 0.37), 2)

func _headstone(p: Dictionary) -> void:
	var crown := Vector2(0, -87)
	Brush.wash(self, PackedVector2Array([Vector2(-118, -85), Vector2(-88, -161), Vector2(4, -192),
		Vector2(96, -158), Vector2(124, -81), Vector2(112, 185), Vector2(-128, 184)]), Brush.fade(p.body, 0.59))
	Brush.archway(self, crown, Vector2(113, 99), 185, p, 9)
	for i in range(5):
		Brush.line(self, Vector2(-71, -37 + i * 30), Vector2(63 - (i % 2) * 24, -40 + i * 30), Brush.fade(p.light, 0.25), 4)
	Brush.curve(self, Vector2(-126, 178), Vector2(-86, 108), Vector2(-99, 60), Brush.fade(p.sage, 0.41), 6)

func _market(p: Dictionary) -> void:
	# A fabric edge and supporting timbers, with no opaque facade behind them.
	Brush.wash(self, PackedVector2Array([Vector2(-181, -110), Vector2(155, -131), Vector2(196, -52),
		Vector2(124, -28), Vector2(47, -38), Vector2(-35, -24), Vector2(-197, -38)]), Brush.fade(p.copper, 0.43))
	Brush.curve(self, Vector2(-194, -36), Vector2(-17, -17), Vector2(194, -53), Brush.fade(p.gold, 0.37), 4)
	for x in [-164.0, 168.0]:
		Brush.line(self, Vector2(x, -102), Vector2(x - 8, 190), Brush.fade(p.body, 0.68), 11)
		Brush.line(self, Vector2(x - 3, -94), Vector2(x - 12, 176), Brush.fade(p.copper, 0.45), 2)
	for i in range(6):
		Brush.line(self, Vector2(-142 + i * 52, -101), Vector2(-158 + i * 65, -44), Brush.fade(p.shadow, 0.25), 3)

func _stair(p: Dictionary) -> void:
	Brush.curve(self, Vector2(-193, -157), Vector2(4, -83), Vector2(197, 167), Brush.fade(p.copper, 0.44), 7)
	for i in range(8):
		var a := Vector2(-166 + i * 48, -153 + i * 45)
		Brush.curve(self, a, a + Vector2(-8, 62), a + Vector2(-1, 107), Brush.fade(p.body, 0.29), 6)

func _facade(p: Dictionary) -> void:
	Brush.curve(self, Vector2(-197, -137), Vector2(2, -181), Vector2(198, -121), Brush.fade(p.copper, 0.24), 9)
	Brush.archway(self, Vector2(-83, -20), Vector2(45, 73), 142, _faint(p, 0.33), 8)
	Brush.archway(self, Vector2(89, -39), Vector2(47, 79), 134, _faint(p, 0.25), 7)

func _faint(p: Dictionary, alpha: float) -> Dictionary:
	var copy := {}
	for key in p: copy[key] = Color(p[key], alpha)
	return copy
