extends RefCounted
## Four plates from the same sleeve. The caller owns the edit and the clock;
## this press owns only paper, cuts, and explicitly supplied presentation poses.

const DESIGN := Vector2(1280, 720)
const PaintedWorld := preload("res://scripts/press_painted_world.gd")
const Paint := preload("res://scripts/figure_paint.gd")
const INK := Color("142c34")
const PINK := Color("e3af6c")
const GOLD := Color("cda565")
const STOCKS := [Color("b3c5b4"), Color("99b0ac"), Color("b6c7b5"), Color("c2cdb6")]

static func draw(c: CanvasItem, size: Vector2, pose: Dictionary) -> void:
	if size.x <= 0.0 or size.y <= 0.0: return
	var shot := clampi(int(pose.get("shot", 0)), 0, 3)
	var reduced := bool(pose.get("reduced_motion", false))
	var progress := clampf(float(pose.get("progress", 0.0)), 0.0, 1.0)
	var clock := maxf(float(pose.get("clock", 0.0)), 0.0)
	if reduced:
		progress = [0.76, 0.86, 0.94, 0.92][shot]
		clock = 0.0
	var stock: Color = STOCKS[shot]
	c.draw_rect(Rect2(Vector2.ZERO, size), Color("102c35"))
	PaintedWorld.draw(c, &"headshell", Rect2(Vector2.ZERO, size), Color("f2e1bc"), Color("102c35"))
	var scale := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	c.draw_set_transform((size - DESIGN * scale) * 0.5, 0.0, Vector2.ONE * scale)
	_paper(c, stock)
	match shot:
		0: _living_record(c, progress, clock, stock)
		1: _last_windows(c, progress, clock, stock)
		2: _first_feet(c, progress, clock, stock)
		3: _open_way(c, progress, clock, stock)
	# A soft night wash below the illustration keeps the unchanged captions clear.
	for row in range(22):
		c.draw_rect(Rect2(0, 506 + row * 10, 1280, 10), Color("102c35", minf(0.88, row * 0.10)))
	# Small registration cuts frame an illustration, never a UI panel.
	for x in [54.0, 1226.0]:
		var direction := 1.0 if x < 640.0 else -1.0
		c.draw_line(Vector2(x, 83), Vector2(x + direction * 14, 83), Color(INK, 0.18), 1, true)
		c.draw_line(Vector2(x, 83), Vector2(x, 97), Color(INK, 0.18), 1, true)
		c.draw_line(Vector2(x, 502), Vector2(x + direction * 14, 502), Color(INK, 0.18), 1, true)
	c.draw_set_transform(Vector2.ZERO)

static func _paper(c: CanvasItem, stock: Color) -> void:
	for row in range(30):
		var shade := Color(stock.lerp(GOLD, sin(float(row) / 29.0 * PI) * 0.16), 0.05)
		c.draw_rect(Rect2(0, row * 24, 1280, 24), shade)
	for ring in range(18, 0, -1):
		_ellipse_fill(c, Vector2(640, 302), Vector2(420 + ring * 10, 125 + ring * 7), Color(stock, 0.026))
	for index in range(260):
		var x := fposmod(index * 83.719 + sin(index * 0.7) * 49.0, 1280.0)
		var y := fposmod(index * 59.137 + cos(index * 1.7) * 31.0, 720.0)
		c.draw_line(Vector2(x, y), Vector2(x + 2.0 + float(index % 9), y - 0.6), Color(GOLD, 0.045), 0.9, true)

static func _living_record(c: CanvasItem, p: float, t: float, stock: Color) -> void:
	var center := Vector2(642, 350)
	var rise := _ease(p, 0.0, 0.30)
	# The street belongs to the disc: roofs follow its distant curve.
	for index in range(11):
		var x := 220.0 + index * 77.0
		var arch := sin(float(index) / 10.0 * PI)
		var baseline := 300.0 - arch * 86.0
		var growth := 0.48 + 0.52 * _ease(p, index * 0.018, 0.42 + index * 0.018)
		_house(c, Rect2(x, baseline - (58 + index % 3 * 21) * growth, 60, (58 + index % 3 * 21) * growth), index,
			stock.lerp(INK, 0.25), stock.lerp(INK, 0.52), stock, 0.86, t)
	_ellipse_fill(c, center + Vector2(0, 17), Vector2(456, 144), Color("58716a"))
	_ellipse_fill(c, center, Vector2(462, 145), INK)
	for index in range(19):
		_ellipse(c, center + Vector2(0, 5), Vector2(453 - index * 2, 139 - index * 0.55), 0.08, PI - 0.08,
			Color(GOLD, 0.05 + index % 3 * 0.016), 1.5)
	for index in range(25):
		var radius := 453.0 - index * 11.0
		_ellipse(c, center, Vector2(radius, radius * 0.315), 0, TAU,
			Color(stock, 0.18 + float(index % 4) * 0.06), 1.0 if index % 4 else 1.65)
	_ellipse(c, center + Vector2(1, -2), Vector2(457, 142), PI + 0.05, TAU - 0.05, Color(stock, 0.76), 2.5)
	_ellipse_fill(c, center, Vector2(139, 44), GOLD.lerp(stock, 0.25))
	for index in range(11):
		_ellipse(c, center + Vector2(0, index - 5), Vector2(122 - index * 2, 28), 0.2, 3.0,
			Color(stock, 0.07), 2)
	_ellipse(c, center, Vector2(131, 39), 0, TAU, Color(INK, 0.28), 1.5)
	_ellipse(c, center, Vector2(119, 35), 0, TAU, Color(INK, 0.16), 1)
	_ellipse_fill(c, center, Vector2(8, 3), INK)
	# A coloured voice travels the groove while the warm town comes into view.
	for index in range(3):
		var phase := t * 0.25 + index * 2.12
		var radius := 245.0 + index * 63.0
		_ellipse(c, center, Vector2(radius, radius * 0.315), phase, phase + 0.16 + rise * 0.07,
			PINK.lerp(stock, float(index) * 0.16), 2.6)
		var point := center + Vector2(cos(phase), sin(phase) * 0.315) * radius
		c.draw_circle(point, 2.3, stock, true, -1, true)
	# Front-bank roofs make this a place, rather than a decorative record icon.
	for index in range(4):
		var x := 287.0 + index * 186.0
		var y := 446.0 + sin(index * 1.2) * 24.0
		var height := (44.0 + index % 2 * 14) * (0.65 + rise * 0.35)
		_house(c, Rect2(x, y - height, 72, height), index + 2, stock.lerp(INK, 0.65), INK, stock, 0.90, t)
		if index % 2 == 0: _smoke(c, Vector2(x + 51, y - height - 12), t + index, stock.lerp(INK, 0.23))
	# Engraving at the cut edge catches the same brass as the windowpanes.
	for index in range(27):
		var angle := 0.20 + index * 0.103
		var point := center + Vector2(cos(angle) * 457, sin(angle) * 142)
		c.draw_line(point, point + Vector2(3, 5), Color(stock, 0.28), 1, true)

static func _last_windows(c: CanvasItem, p: float, t: float, stock: Color) -> void:
	var distant := stock.lerp(INK, 0.13)
	for index in range(8):
		var height := 70.0 + index % 3 * 27.0
		_house(c, Rect2(163 + index * 126, 331 - height, 87, height), index, distant, stock.lerp(INK, 0.20), stock, 0.0, 0.0)
	var vanishing := Vector2(741, 326)
	for index in range(11):
		c.draw_line(vanishing + Vector2((index - 5) * 8, 10), Vector2(126 + index * 105, 492), Color(INK, 0.10), 1.0, true)
	for index in range(6):
		var y := 361.0 + index * index * 5.0
		c.draw_line(Vector2(110 + (490 - y) * 1.1, y), Vector2(1180 - (490 - y) * 0.9, y), Color(INK, 0.10), 1.0, true)
	# Opposing streets leave a generous, empty square around the great horn.
	_house(c, Rect2(104, 157, 183, 284), 0, stock.lerp(INK, 0.37), stock.lerp(INK, 0.65), stock,
		1.0 - _ease(p, 0.08, 0.40), t)
	_house(c, Rect2(293, 223, 134, 216), 2, stock.lerp(INK, 0.27), stock.lerp(INK, 0.50), stock,
		1.0 - _ease(p, 0.29, 0.70), t)
	_house(c, Rect2(986, 187, 173, 264), 1, stock.lerp(INK, 0.32), stock.lerp(INK, 0.57), stock,
		1.0 - _ease(p, 0.50, 0.98), t)
	# The lip is a real hollow mouth; its ribs meet at the held neck.
	var lip := Vector2(716, 204)
	var throat := Vector2(766, 360)
	var bell := PackedVector2Array([Vector2(568, 193), Vector2(858, 206), Vector2(784, 373), Vector2(749, 374)])
	c.draw_colored_polygon(bell, Color("a77c46"))
	# Broad brushed facets give the bell a curved, tarnished copper surface.
	for index in range(18):
		var q := index / 18.0
		var next := (index + 1) / 18.0
		var panel := PackedVector2Array([Vector2(568 + q * 290, 193 + q * 13), Vector2(568 + next * 290, 193 + next * 13),
			Vector2(749 + next * 35, 374), Vector2(749 + q * 35, 374)])
		var shine := sin(q * PI) * 0.64 + sin(q * TAU) * 0.12
		c.draw_colored_polygon(panel, Color("66472e").lerp(Color("d4b575"), shine))
	_outline(c, bell, Color("413c2b"), 3)
	for index in range(43):
		var q := index / 42.0
		var rim := Vector2(579 + q * 266, 215 + sin(q * PI) * 18)
		var end := throat + Vector2((q - 0.5) * 24, 2)
		var begin := rim.lerp(end, 0.08 + fposmod(index * 0.731, 0.37))
		c.draw_line(begin, begin.lerp(end, 0.38 + fposmod(index * 0.213, 0.47)),
			Color(stock if index % 3 else INK, 0.10), 1.0 + index % 3, true)
	for index in range(9):
		var rim := lip + Vector2(-133 + index * 33, 5 + sin(index * 0.39) * 14)
		c.draw_line(throat + Vector2((index - 4) * 2, 0), rim, Color("3c4639", 0.30), 2, true)
	_ellipse_fill(c, lip, Vector2(156, 47), Color("5f5134"), -0.08)
	_ellipse_fill(c, lip, Vector2(150, 42), Color("675537"), -0.08)
	for index in range(12):
		_ellipse_fill(c, lip + Vector2(index * 1.2, index * 0.28), Vector2(147 - index * 4, 39 - index * 1.4),
			Color("101e22", 0.13), -0.08)
	_ellipse(c, lip, Vector2(154, 45), PI - 0.1, TAU + 0.1, Color("edcf8c"), 5, -0.08)
	_ellipse(c, lip, Vector2(151, 43), 0, PI, Color("b99656"), 4, -0.08)
	_ellipse(c, lip, Vector2(139, 33), 0, TAU, Color(stock, 0.22), 1.5, -0.08)
	for index in range(25):
		var angle := index * TAU / 25.0
		var point := lip + (Vector2(cos(angle) * 153, sin(angle) * 45)).rotated(-0.08)
		c.draw_line(point, point + Vector2(1, 2), Color("f1d496", 0.44), 1.5, true)
	var neck := [Vector2(766, 365), Vector2(762, 394), Vector2(721, 414), Vector2(721, 449)]
	for index in range(3): Paint.segment(c, neck[index], neck[index + 1], 14, Color("8a7348"), INK, GOLD)
	_ellipse_fill(c, Vector2(736, 454), Vector2(73, 9), Color("0d252c"))
	_ellipse(c, Vector2(736, 451), Vector2(67, 6), 0, PI, GOLD.lerp(INK, 0.45), 4)
	for index in range(5):
		var fade := 1.0 - _ease(p, 0.20 + index * 0.07, 0.64 + index * 0.07)
		var point := Vector2(551 + index * 63, 147 - sin(index * 1.3) * 21 - p * 18)
		_note(c, point, Color(PINK, 0.62 * fade), 0.74)
	# The sound goes, but faint, patient impressions remain in the street.
	for index in range(3):
		var point := Vector2(467 + index * 197, 433 + index % 2 * 23)
		_ellipse(c, point + Vector2(0, -15), Vector2(15, 18), 0.1, TAU - 0.4, Color(INK, 0.13), 1.2)
		c.draw_line(point + Vector2(-14, 7), point + Vector2(15, 7), Color(INK, 0.16), 1, true)
		c.draw_line(point + Vector2(0, 3), point + Vector2(sin(t * 0.5 + index) * 2, -8), Color(INK, 0.13), 1, true)
	for index in range(7):
		var x := 120.0 + index * 153.0
		c.draw_line(Vector2(x, 476), Vector2(x + 52, 473), Color(INK, 0.19), 1, true)

static func _first_feet(c: CanvasItem, p: float, t: float, stock: Color) -> void:
	var open := _ease(p, 0.10, 0.46)
	var falling := _ease(p, 0.40, 0.76)
	var landed := _ease(p, 0.76, 0.88)
	var pale := stock.lerp(INK, 0.16)
	# A cartridge seen from underneath, engraved with its empty brass channels.
	for radius in [175.0, 209.0, 245.0]:
		_ellipse(c, Vector2(640, 260), Vector2(radius * 1.9, radius * 0.73), PI + 0.30, TAU - 0.30, Color(pale, 0.34), 2)
	for index in range(18):
		c.draw_colored_polygon(PackedVector2Array([Vector2(934 + index * 2, 117), Vector2(1118 - index * 2, 140),
			Vector2(909 - index * 5, 463), Vector2(565 + index * 7, 463)]), Color("f8d58f", 0.018))
	var shell := PackedVector2Array([Vector2(285, 124), Vector2(878, 110), Vector2(976, 161), Vector2(902, 252), Vector2(355, 241)])
	c.draw_colored_polygon(shell, Color("24464a"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(288,124),Vector2(877,111),Vector2(970,161),Vector2(924,163),Vector2(863,134),Vector2(314,145)]),Color("567b71"))
	c.draw_colored_polygon(PackedVector2Array([Vector2(355,219),Vector2(909,226),Vector2(941,199),Vector2(902,252),Vector2(355,241)]),Color("112c34"))
	for index in range(46):
		var x := 363.0 + fposmod(index * 91.31, 497.0)
		var y := 144.0 + fposmod(index * 17.137, 73.0)
		c.draw_line(Vector2(x,y),Vector2(x+18+index%5*7,y-1),Color(stock,0.035+index%3*0.01),2+index%3,true)
	_outline(c, shell, Color("153035"), 4)
	c.draw_polyline(PackedVector2Array([Vector2(304, 133), Vector2(873, 122), Vector2(947, 162)]), Color("c6b279", 0.86), 3, true)
	c.draw_line(Vector2(365,236),Vector2(899,244),Color("8c7d53"),4,true)
	for index in range(8):
		var x := 376.0 + index * 66.0
		c.draw_line(Vector2(x, 159), Vector2(x + 25, 211), Color("0a2027"), 13, true)
		c.draw_line(Vector2(x + 3, 159), Vector2(x + 28, 211), Color("977e50"), 3, true)
		c.draw_line(Vector2(x + 4, 159), Vector2(x + 29, 209), Color(stock, 0.54), 1, true)
	for x in [386.0, 862.0]:
		Paint.bolt(c,Vector2(x,224),14,Color("ad8b50"),INK,Color("ead09c"))
	# The two arms let go instead of becoming an antagonist.
	for side in [-1.0, 1.0]:
		var pivot := Vector2(640 + side * 117, 228)
		var elbow := Vector2(640 + side * (67 + open * 95), 297 - open * 21)
		var tip := Vector2(640 + side * (21 + open * 159), 315 - open * 30)
		c.draw_polyline(PackedVector2Array([pivot, elbow, tip]), INK.lerp(stock, 0.22), 14, true)
		c.draw_polyline(PackedVector2Array([pivot + Vector2(-2, -4), elbow + Vector2(-2, -4), tip + Vector2(-2, -4)]), GOLD.lerp(stock, 0.33), 3, true)
		c.draw_circle(pivot, 11, stock.lerp(INK, 0.50), true, -1, true)
	# Falling is a committed arc; the impact compresses once, then feet settle.
	var drop := falling * falling
	var origin := Vector2(640 + sin(falling * PI) * 7, lerpf(277, 430.5, drop) - landed * 6)
	var impact := sin(landed * PI) * 0.23
	_ellipse_fill(c, Vector2(645, 464), Vector2(26 + drop * 35, 5 + drop * 3), Color(INK, 0.09 + drop * 0.08))
	_stylus(c, origin, 1.50, t, 0.0, 1.0 - landed, impact, INK, stock)
	if landed > 0.0 and landed < 1.0:
		for side in [-1.0, 1.0]:
			var start := Vector2(640 + side * (35 + landed * 26), 460)
			c.draw_line(start, start + Vector2(side * 16, -5), Color(INK, sin(landed * PI) * 0.33), 1.5, true)
	c.draw_line(Vector2(188, 471), Vector2(1088, 471), INK.lerp(stock, 0.50), 3, true)
	for index in range(26):
		var x := 203.0 + index * 33.0
		c.draw_line(Vector2(x, 478), Vector2(x + 17, 476), Color(INK, 0.17), 1, true)

static func _open_way(c: CanvasItem, p: float, t: float, stock: Color) -> void:
	var pale := stock.lerp(INK, 0.13)
	# The cradle is behind us now. The door occupies the light, not the needle.
	c.draw_line(Vector2(111, 141), Vector2(502, 153), pale, 20, true)
	c.draw_line(Vector2(157, 152), Vector2(208, 326), pale, 13, true)
	for index in range(6):
		var x := 211.0 + index * 48.0
		c.draw_line(Vector2(x, 177), Vector2(x + 19, 237), pale, 9, true)
	for index in range(6):
		_ellipse(c, Vector2(331, 250), Vector2(160 + index * 25, 88 + index * 17), 0.75, 3.85, Color(INK, 0.07), 1)
	var crown := Vector2(921, 235)
	for index in range(16):
		c.draw_colored_polygon(PackedVector2Array([Vector2(823+index*2,250),Vector2(1020-index*2,250),
			Vector2(1020-index*3,457),Vector2(385+index*18,457)]),Color("f2d596",0.022))
	# Warm nested cuts soften the window without shaders or screen reads.
	for index in range(7):
		var rect := Rect2(810 + index * 3, 235, 222 - index * 6, 226)
		c.draw_rect(rect, Color("9b8e62").lerp(Color("efd7a0"),0.35+index*0.08))
	_ellipse_fill(c, crown, Vector2(108, 108), Color("e1ca91"))
	for index in range(20):
		var y := 177.0 + index * 13.5
		var half_width := sqrt(maxf(0,108.0*108.0-pow(minf(y-235,0),2)))
		c.draw_line(Vector2(921-half_width+5,y),Vector2(921+half_width-5,y-2),Color("fff1c4",0.075),6,true)
	for radius in range(137,107,-1):
		var shade := sin((radius-107)/30.0*PI)
		_ellipse(c,crown,Vector2(radius,radius),PI,TAU,Color("263d3e").lerp(Color("be9d60"),shade*0.72),2)
	_ellipse(c, crown, Vector2(112, 112), PI, TAU, Color("eed19a"), 2.5)
	_ellipse(c, crown, Vector2(140, 140), PI, TAU, Color("213b3c"), 3)
	for index in range(13):
		var angle := PI + index * PI / 12.0
		c.draw_line(crown+Vector2.from_angle(angle)*114,crown+Vector2.from_angle(angle)*136,Color("1d3739",0.54),2,true)
	for side in [-1.0, 1.0]:
		Paint.segment(c,crown+Vector2(side*123,0),Vector2(921+side*123,461),27,Color("756e49"),Color("213b3c"),GOLD)
		c.draw_line(crown+Vector2(side*109,0),Vector2(921+side*109,457),Color("f1d49b"),2.5,true)
		for index in range(5):
			var y := 271.0 + index * 39.0
			c.draw_line(Vector2(921 + side * 137, y), Vector2(921 + side * 111, y + 2), Color("172f33",0.62),2,true)
			c.draw_line(Vector2(921 + side * 133,y+3),Vector2(921+side*115,y+4),Color(GOLD,0.40),1,true)
	var groove := PackedVector2Array()
	for index in range(81):
		var q := index / 80.0
		groove.append(Vector2(146 + q * 1066, 468 - sin(q * PI) * 24 + pow(q, 7) * 33))
	for offset in [-7.0, 6.0]:
		var echo := PackedVector2Array()
		for point in groove: echo.append(point + Vector2(0, offset))
		c.draw_polyline(echo, Color(INK, 0.15), 1.2, true)
	c.draw_polyline(groove, PINK, 2.8, true)
	var moving := _ease(p, 0.16, 0.83)
	var x := 481.0 + moving * 176.0
	var grounded := 1.0 if p > 0.16 and p < 0.83 else 0.0
	var floor_y := 468 - sin((x - 146) / 1066.0 * PI) * 24
	_stylus(c, Vector2(x, floor_y - 38.75), 1.25, t, grounded, 0.0, 0.0, INK, stock)
	var glint := fposmod(t * 0.065 + 0.57, 1.0)
	var glint_point := groove[clampi(int(glint * 80), 0, 80)]
	c.draw_circle(glint_point, 4.0, stock, true, -1, true)
	c.draw_circle(glint_point, 1.8, PINK, true, -1, true)
	for index in range(11):
		var point := Vector2(850 + index % 4 * 41, 172 + index * 23)
		point += Vector2(sin(t * 0.24 + index) * 2, cos(t * 0.34 + index) * 2)
		c.draw_line(point, point + Vector2(2, -2), Color(INK, 0.12), 1, true)

static func _house(c: CanvasItem, rect: Rect2, variant: int, fill: Color, line: Color, stock: Color, warmth: float, t: float) -> void:
	var roof := rect.position.y - rect.size.x * (0.15 if variant % 3 else 0.28)
	var plaster := Color("34585a").lerp(fill, 0.26)
	var shadow := Color("17383e").lerp(line, 0.22)
	var stone := Color("a79871").lerp(stock,0.23)
	c.draw_rect(Rect2(rect.position+Vector2(4,5),rect.size),Color(INK,0.35))
	c.draw_rect(rect, plaster)
	c.draw_rect(Rect2(rect.end.x - rect.size.x * 0.20, rect.position.y, rect.size.x * 0.20, rect.size.y), shadow)
	for index in range(28):
		var y := rect.position.y + 3 + fposmod(index * 31.715, maxf(rect.size.y - 7, 1))
		var x := rect.position.x + 3 + fposmod(index * 13.73, rect.size.x * 0.54)
		var width := minf(rect.end.x - x - 5, rect.size.x * (0.10 + index % 4 * 0.055))
		c.draw_line(Vector2(x,y),Vector2(x+width,y-0.5),Color(stone,0.055+index%3*0.018),1.4+index%3,true)
	var top := PackedVector2Array([rect.position + Vector2(-5, 0), Vector2(rect.position.x + rect.size.x * 0.23, roof),
		Vector2(rect.end.x - rect.size.x * 0.22, roof + (4 if variant % 2 else 0)), Vector2(rect.end.x + 5, rect.position.y)])
	c.draw_colored_polygon(top, shadow)
	c.draw_line(top[1],top[2],Color("a79061"),1.8,true)
	for index in range(7):
		var q := index / 7.0
		c.draw_line(top[1].lerp(top[2],q),top[0].lerp(top[3],q),Color(stone,0.17),1,true)
	c.draw_line(rect.position + Vector2(-5, 0), Vector2(rect.end.x + 5, rect.position.y), stone.lerp(shadow, 0.28), 2.4, true)
	c.draw_line(rect.position+Vector2(2,3),Vector2(rect.end.x-1,rect.position.y+3),Color(INK,0.7),1.5,true)
	var rows := 3 if rect.size.y > 120.0 else 2
	var columns := 3 if rect.size.x > 90 else 2
	for row in range(rows):
		for column in range(columns):
			var w := rect.size.x * 0.125
			var h := minf(27, rect.size.y * 0.19)
			var point := rect.position + Vector2(rect.size.x * 0.15 + column * rect.size.x * 0.26, 12 + row * rect.size.y * 0.26)
			var lit := clampf(warmth * (0.86 + sin(t * 0.55 + row + column * 3) * 0.05), 0.0, 1.0)
			if lit > 0.01:
				for glow in range(3,0,-1):
					c.draw_rect(Rect2(point-Vector2.ONE*glow*2,Vector2(w,h)+Vector2.ONE*glow*4),Color(GOLD,lit*0.035))
			c.draw_rect(Rect2(point-Vector2.ONE*1.5,Vector2(w,h)+Vector2.ONE*3),shadow)
			c.draw_rect(Rect2(point, Vector2(w, h)),Color("243b3b").lerp(Color("e7c68b"),lit))
			c.draw_line(point+Vector2(-2,h+1),point+Vector2(w+3,h+1),Color(stone,0.67),1.5,true)
			c.draw_line(point+Vector2(0,h*0.42),point+Vector2(w,h*0.42),Color(shadow,0.72),1,true)
			if w > 13:
				c.draw_line(point + Vector2(w * 0.5, 0), point + Vector2(w * 0.5, h), Color(shadow, 0.8), 1.3, true)
	var door := Rect2(rect.position.x + rect.size.x * 0.59, rect.end.y - rect.size.y * 0.23, rect.size.x * 0.18, rect.size.y * 0.23)
	c.draw_rect(door,shadow.lerp(INK,0.4))
	c.draw_line(door.position,Vector2(door.position.x,door.end.y),Color(stone,0.48),1.5,true)
	c.draw_line(door.position+Vector2(door.size.x*0.5,2),door.end-Vector2(door.size.x*0.5,2),Color(stone,0.18),1,true)
	c.draw_circle(door.position+Vector2(door.size.x*0.78,door.size.y*0.52),maxf(1.0,rect.size.x*0.006),GOLD,true,-1,true)
	if rect.size.x > 100:
		# A shuttered shopfront, its cloth now quieter than the windows above.
		var awning := Vector2(rect.position.x + rect.size.x * 0.49, rect.end.y - rect.size.y * 0.25)
		for index in range(5):
			c.draw_rect(Rect2(awning + Vector2(index * rect.size.x * 0.065, sin(t * 0.5 + index) * warmth * 0.7), Vector2(rect.size.x * 0.066, 10)),
				Color("8d6848") if index % 2 else Color("c4a06a"))
		for row in range(int(rect.size.y/20)):
			var y := rect.position.y+13.0+row*20
			c.draw_line(Vector2(rect.position.x+1,y),Vector2(rect.position.x+12,y-1),Color(stone,0.29),3,true)
			c.draw_line(Vector2(rect.end.x-11,y+3),Vector2(rect.end.x-1,y+2),Color(stone,0.15),2,true)
		for index in range(7):
			var y := rect.position.y + 28 + index * rect.size.y * 0.115
			c.draw_line(Vector2(rect.end.x - rect.size.x * 0.14, y), Vector2(rect.end.x - 5, y - 9), Color(stock, 0.15), 1, true)
	for index in range(4):
		var y := rect.end.y - 3 - index * 4
		c.draw_line(Vector2(rect.position.x + 4, y), Vector2(rect.position.x + rect.size.x * 0.44, y - 2), Color(stock, 0.14), 1, true)
	if variant % 2 == 0:
		c.draw_line(Vector2(rect.position.x + rect.size.x * 0.72, roof + 4), Vector2(rect.position.x + rect.size.x * 0.72, roof - 12), line, 5, true)

static func _stylus(c: CanvasItem, origin: Vector2, scale: float, t: float, run: float, air: float, squash: float, ink: Color, stock: Color) -> void:
	var stride := t * 9.0
	var compression := Vector2(1.0 + squash, 1.0 - squash)
	var bob := -absf(sin(stride)) * run * 1.8
	var body_origin := origin + Vector2(0, bob + squash * 26.0 * scale)
	var points := PackedVector2Array([Vector2(0, -34)])
	for index in range(15):
		var angle := lerpf(-0.55, 3.69, index / 14.0)
		points.append(Vector2(0, 8) + Vector2(cos(angle), sin(angle)) * 19)
	var body := PackedVector2Array()
	for point in points: body.append(body_origin + point * compression * scale)
	for side in [-1.0, 1.0]:
		var phase := stride + (PI if side < 0 else 0.0)
		var hip := origin + Vector2(side * 7, 14) * scale
		var foot := origin + Vector2(side * 8 + sin(phase) * 9 * run, 31 - maxf(cos(phase), 0) * 5 * run - air * 9) * scale
		Paint.segment(c,hip,foot,3.2*scale,Color("967a48"),ink,GOLD)
		c.draw_line(foot, foot + Vector2(5, 0) * scale, ink, 2.3 * scale, true)
	c.draw_colored_polygon(body, Color("28565b"))
	_outline(c, body, ink, 2.0 * scale)
	for local_points in [
		PackedVector2Array([Vector2(0,-31),Vector2(-15,-2),Vector2(-17,16),Vector2(-5,24),Vector2(-3,3)]),
		PackedVector2Array([Vector2(2,-25),Vector2(13,-3),Vector2(17,13),Vector2(9,23),Vector2(4,5)])]:
		var painted := PackedVector2Array()
		for point in local_points: painted.append(body_origin+point*compression*scale)
		c.draw_colored_polygon(painted,Color("15333b") if local_points[1].x<0 else Color("53817b"))
	var mask := PackedVector2Array()
	for point in [Vector2(0,-25),Vector2(10,-10),Vector2(12,4),Vector2(5,13),Vector2(-6,12),Vector2(-11,3),Vector2(-8,-11)]:
		mask.append(body_origin+point*compression*scale)
	c.draw_colored_polygon(mask,Color("e9d6aa"))
	_outline(c,mask,Color("a69c75"),1.0*scale)
	var scarf := PackedVector2Array()
	for point in [Vector2(-14,12),Vector2(12,12),Vector2(16,16),Vector2(2,19),Vector2(-13,17)]:
		scarf.append(body_origin+point*compression*scale)
	c.draw_colored_polygon(scarf,Color("c57d55"))
	c.draw_line(body_origin+Vector2(-11,13)*compression*scale,body_origin+Vector2(10,14)*compression*scale,Color("e9b080"),1.2*scale,true)
	c.draw_polyline(PackedVector2Array([body_origin + Vector2(0, -34) * compression * scale,
		body_origin + Vector2(11 - run * 3, -43) * compression * scale,
		body_origin + Vector2(24 - run * 4, -39 + sin(stride) * run * 3) * compression * scale]), ink, 4.0 * scale, true)
	c.draw_polyline(PackedVector2Array([body_origin + Vector2(0, -34) * compression * scale,
		body_origin + Vector2(11 - run * 3, -43) * compression * scale,
		body_origin + Vector2(24 - run * 4, -39 + sin(stride) * run * 3) * compression * scale]), GOLD, 2.2 * scale, true)
	for side in [-1.0, 1.0]:
		c.draw_circle(body_origin + Vector2(2 + side * 5, 0) * scale, 2.6 * scale, ink, true, -1, true)
		c.draw_circle(body_origin + Vector2(1 + side * 5, -1) * scale, 0.65 * scale, stock, true, -1, true)

static func _smoke(c: CanvasItem, origin: Vector2, t: float, color: Color) -> void:
	for index in range(3):
		var point := origin + Vector2(sin(t * 0.6 + index) * 3, -index * 10)
		_ellipse(c, point, Vector2(8 + index * 3, 4), -0.4, PI * 0.9, Color(color, 0.7 - index * 0.15), 1)

static func _note(c: CanvasItem, point: Vector2, color: Color, scale: float) -> void:
	_ellipse_fill(c, point, Vector2(5, 3) * scale, color, -0.3)
	c.draw_line(point + Vector2(4, 0) * scale, point + Vector2(4, -16) * scale, color, 1.6 * scale, true)
	c.draw_line(point + Vector2(4, -16) * scale, point + Vector2(11, -12) * scale, color, 1.6 * scale, true)

static func _ellipse(c: CanvasItem, center: Vector2, radii: Vector2, start: float, end: float, color: Color, width: float, angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	var count := maxi(12, int(absf(end - start) * 17))
	for index in range(count + 1):
		var phase := lerpf(start, end, float(index) / count)
		points.append(center + (Vector2(cos(phase), sin(phase)) * radii).rotated(angle))
	c.draw_polyline(points, color, width, true)

static func _ellipse_fill(c: CanvasItem, center: Vector2, radii: Vector2, color: Color, angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	for index in range(80):
		var phase := float(index) / 80.0 * TAU
		points.append(center + (Vector2(cos(phase), sin(phase)) * radii).rotated(angle))
	c.draw_colored_polygon(points, color)

static func _outline(c: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	var outline := points.duplicate()
	outline.append(outline[0])
	c.draw_polyline(outline, color, width, true)

static func _ease(value: float, start: float, end: float) -> float:
	var fraction := clampf((value - start) / (end - start), 0.0, 1.0)
	return fraction * fraction * (3.0 - 2.0 * fraction)
