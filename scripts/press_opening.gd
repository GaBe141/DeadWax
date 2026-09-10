extends RefCounted
## Four plates from the same sleeve. The caller owns the edit and the clock;
## this press owns only paper, cuts, and explicitly supplied presentation poses.

const DESIGN := Vector2(1280, 720)
const INK := Color("29251f")
const PINK := Color("dd5278")
const GOLD := Color("c6a465")
const STOCKS := [Color("e9dfc7"), Color("dcdccf"), Color("e7e1d2"), Color("eee3ca")]

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
	c.draw_rect(Rect2(Vector2.ZERO, size), stock)
	var scale := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	c.draw_set_transform((size - DESIGN * scale) * 0.5, 0.0, Vector2.ONE * scale)
	_paper(c, stock)
	match shot:
		0: _living_record(c, progress, clock, stock)
		1: _last_windows(c, progress, clock, stock)
		2: _first_feet(c, progress, clock, stock)
		3: _open_way(c, progress, clock, stock)
	# Small registration cuts frame an illustration, never a UI panel.
	for x in [54.0, 1226.0]:
		var direction := 1.0 if x < 640.0 else -1.0
		c.draw_line(Vector2(x, 83), Vector2(x + direction * 14, 83), Color(INK, 0.18), 1, true)
		c.draw_line(Vector2(x, 83), Vector2(x, 97), Color(INK, 0.18), 1, true)
		c.draw_line(Vector2(x, 502), Vector2(x + direction * 14, 502), Color(INK, 0.18), 1, true)
	c.draw_set_transform(Vector2.ZERO)

static func _paper(c: CanvasItem, stock: Color) -> void:
	for row in range(30):
		var shade := stock.lerp(GOLD, sin(float(row) / 29.0 * PI) * 0.025)
		c.draw_rect(Rect2(0, row * 24, 1280, 24), shade)
	for index in range(260):
		var x := fposmod(index * 83.719 + sin(index * 0.7) * 49.0, 1280.0)
		var y := fposmod(index * 59.137 + cos(index * 1.7) * 31.0, 720.0)
		c.draw_line(Vector2(x, y), Vector2(x + 1.0 + float(index % 5), y - 0.6), Color(INK, 0.045), 0.65, true)

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
	_ellipse_fill(c, center + Vector2(0, 17), Vector2(456, 144), stock.lerp(INK, 0.15))
	_ellipse_fill(c, center, Vector2(462, 145), INK)
	for index in range(25):
		var radius := 453.0 - index * 11.0
		_ellipse(c, center, Vector2(radius, radius * 0.315), 0, TAU,
			Color(stock, 0.18 + float(index % 4) * 0.06), 1.0 if index % 4 else 1.65)
	_ellipse(c, center + Vector2(1, -2), Vector2(457, 142), PI + 0.05, TAU - 0.05, Color(stock, 0.76), 2.5)
	_ellipse_fill(c, center, Vector2(139, 44), GOLD.lerp(stock, 0.25))
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
	c.draw_colored_polygon(bell, stock.lerp(GOLD, 0.45))
	_outline(c, bell, INK.lerp(stock, 0.19), 3)
	for index in range(9):
		var rim := lip + Vector2(-133 + index * 33, 5 + sin(index * 0.39) * 14)
		c.draw_line(throat + Vector2((index - 4) * 2, 0), rim, Color(INK, 0.22), 2, true)
	_ellipse_fill(c, lip, Vector2(150, 42), INK.lerp(stock, 0.11), -0.08)
	_ellipse(c, lip, Vector2(153, 45), 0, TAU, stock.lerp(GOLD, 0.62), 9, -0.08)
	_ellipse(c, lip, Vector2(139, 33), 0, TAU, Color(stock, 0.33), 1.5, -0.08)
	c.draw_polyline(PackedVector2Array([Vector2(766, 361), Vector2(762, 394), Vector2(721, 414), Vector2(721, 449)]), INK.lerp(stock, 0.13), 14, true)
	c.draw_line(Vector2(670, 451), Vector2(800, 451), INK.lerp(stock, 0.13), 12, true)
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
		_ellipse(c, Vector2(640, 260), Vector2(radius * 1.9, radius * 0.73), PI + 0.30, TAU - 0.30, pale, 2)
	c.draw_colored_polygon(PackedVector2Array([Vector2(934, 117), Vector2(1118, 140), Vector2(909, 463), Vector2(565, 463)]), stock.lerp(GOLD, 0.10))
	var shell := PackedVector2Array([Vector2(285, 124), Vector2(878, 110), Vector2(976, 161), Vector2(902, 252), Vector2(355, 241)])
	c.draw_colored_polygon(shell, stock.lerp(INK, 0.27))
	_outline(c, shell, INK.lerp(stock, 0.27), 4)
	c.draw_polyline(PackedVector2Array([Vector2(304, 133), Vector2(873, 122), Vector2(947, 162)]), Color(stock, 0.64), 3, true)
	for index in range(8):
		var x := 376.0 + index * 66.0
		c.draw_line(Vector2(x, 159), Vector2(x + 25, 211), Color(INK, 0.24), 12, true)
		c.draw_line(Vector2(x + 3, 159), Vector2(x + 28, 211), Color(stock, 0.51), 2, true)
	for x in [386.0, 862.0]:
		c.draw_circle(Vector2(x, 224), 18, stock.lerp(INK, 0.57), true, -1, true)
		c.draw_circle(Vector2(x, 224), 7, GOLD, true, -1, true)
		c.draw_line(Vector2(x - 5, 224), Vector2(x + 5, 224), INK, 2, true)
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
	var light := stock.lerp(GOLD, 0.21)
	c.draw_colored_polygon(PackedVector2Array([Vector2(823, 250), Vector2(1020, 250), Vector2(1020, 457), Vector2(385, 457)]), light)
	# Warm nested cuts soften the window without shaders or screen reads.
	for index in range(7):
		var rect := Rect2(810 + index * 3, 235, 222 - index * 6, 226)
		c.draw_rect(rect, stock.lerp(Color("fff1ba"), 0.18 + index * 0.055))
	_ellipse_fill(c, crown, Vector2(108, 108), stock.lerp(Color("fff1ba"), 0.45))
	_ellipse(c, crown, Vector2(111, 111), PI, TAU, INK.lerp(stock, 0.23), 15)
	_ellipse(c, crown, Vector2(129, 130), PI, TAU, pale, 5)
	for side in [-1.0, 1.0]:
		c.draw_line(crown + Vector2(side * 111, 0), Vector2(921 + side * 111, 461), INK.lerp(stock, 0.23), 15, true)
		c.draw_line(crown + Vector2(side * 130, 0), Vector2(921 + side * 130, 461), pale, 5, true)
		for index in range(5):
			var y := 271.0 + index * 39.0
			c.draw_line(Vector2(921 + side * 140, y), Vector2(921 + side * 104, y + 5), Color(INK, 0.16), 1.5, true)
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
	c.draw_rect(rect, fill)
	c.draw_rect(Rect2(rect.end.x - rect.size.x * 0.16, rect.position.y, rect.size.x * 0.16, rect.size.y), fill.lerp(line, 0.20))
	var top := PackedVector2Array([rect.position + Vector2(-5, 0), Vector2(rect.position.x + rect.size.x * 0.23, roof),
		Vector2(rect.end.x - rect.size.x * 0.22, roof + (4 if variant % 2 else 0)), Vector2(rect.end.x + 5, rect.position.y)])
	c.draw_colored_polygon(top, line)
	c.draw_line(rect.position + Vector2(-5, 0), Vector2(rect.end.x + 5, rect.position.y), stock.lerp(line, 0.35), 2, true)
	var rows := 3 if rect.size.y > 120.0 else 2
	var columns := 3 if rect.size.x > 90 else 2
	for row in range(rows):
		for column in range(columns):
			var w := rect.size.x * 0.125
			var h := minf(27, rect.size.y * 0.19)
			var point := rect.position + Vector2(rect.size.x * 0.15 + column * rect.size.x * 0.26, 12 + row * rect.size.y * 0.26)
			var lit := clampf(warmth * (0.86 + sin(t * 0.55 + row + column * 3) * 0.05), 0.0, 1.0)
			c.draw_rect(Rect2(point, Vector2(w, h)), line.lerp(GOLD.lerp(stock, 0.48), lit))
			if w > 13:
				c.draw_line(point + Vector2(w * 0.5, 0), point + Vector2(w * 0.5, h), Color(line, 0.5), 1, true)
	c.draw_rect(Rect2(rect.position.x + rect.size.x * 0.59, rect.end.y - rect.size.y * 0.23, rect.size.x * 0.18, rect.size.y * 0.23), line)
	if rect.size.x > 100:
		# A shuttered shopfront, its cloth now quieter than the windows above.
		var awning := Vector2(rect.position.x + rect.size.x * 0.49, rect.end.y - rect.size.y * 0.25)
		for index in range(5):
			c.draw_rect(Rect2(awning + Vector2(index * rect.size.x * 0.065, sin(t * 0.5 + index) * warmth * 0.7), Vector2(rect.size.x * 0.066, 10)),
				line.lerp(stock, 0.21 if index % 2 else 0.43))
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
		c.draw_line(hip, foot, ink, 2.3 * scale, true)
		c.draw_line(foot, foot + Vector2(5, 0) * scale, ink, 2.3 * scale, true)
	c.draw_colored_polygon(body, ink.lerp(stock, 0.24))
	_outline(c, body, ink, 2.0 * scale)
	c.draw_polyline(PackedVector2Array([body_origin + Vector2(0, -34) * compression * scale,
		body_origin + Vector2(11 - run * 3, -43) * compression * scale,
		body_origin + Vector2(24 - run * 4, -39 + sin(stride) * run * 3) * compression * scale]), ink, 2.0 * scale, true)
	for side in [-1.0, 1.0]:
		c.draw_circle(body_origin + Vector2(2 + side * 5, 0) * scale, 2.6 * scale, stock, true, -1, true)

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
