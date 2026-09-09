extends RefCounted
## The Label's distant cuts and the exposed edges of its wax. This plate reads
## only its arguments; even the small drafts are driven by the caller's clock.

static func draw(canvas: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	if layer == &"foreground":
		_foreground(canvas, room_id, bounds, pose, ink, stock)
		return
	if layer != &"far" and layer != &"middle":
		return
	var far := layer == &"far"
	var pale := stock.lerp(ink, 0.085 if far else 0.15)
	var dark := stock.lerp(ink, 0.14 if far else 0.235)
	var warm := stock.lerp(Color("a88a54"), 0.14 if far else 0.23)
	var time := float(pose.get("clock", 0.0)) * clampf(float(pose.get("motion", 1.0)), 0.0, 1.0)
	canvas.draw_set_transform(bounds.position)
	match room_id:
		&"headshell": _headshell(canvas, bounds.size, far, time, pale, dark, warm, stock, String(pose.get("outcome", "")))
		&"horn_plaza": _plaza(canvas, bounds.size, far, pale, dark, warm)
		&"high_street": _street(canvas, bounds.size, far, pale, dark, warm)
		&"practice_room": _practice(canvas, bounds.size, far, time, pale, dark, warm)
		&"the_stalls": _stalls(canvas, bounds.size, far, time, pale, dark, warm)
		&"groove_yard": _yard(canvas, bounds.size, far, pale, dark, warm)
		&"label_descent": _descent(canvas, bounds.size, far, pale, dark, warm)
		&"overture_stair": _stair(canvas, bounds.size, far, pale, dark, warm, stock)
	canvas.draw_set_transform(Vector2.ZERO)

static func _headshell(c: CanvasItem, size: Vector2, far: bool, t: float, pale: Color, dark: Color, warm: Color, stock: Color, outcome: String) -> void:
	if far:
		# A broad mouth of daylight finds the cartridge's brass ribs.
		c.draw_colored_polygon(PackedVector2Array([Vector2(size.x - 190, 82), Vector2(size.x, 60), Vector2(size.x, 580), Vector2(610, 580)]), warm)
		var hub := Vector2(285, 315)
		c.draw_circle(hub, 240, pale)
		for radius in [153.0, 170.0, 196.0, 225.0]:
			c.draw_arc(hub, radius, -PI * 0.76, PI * 0.83, 70, dark, 2.0, true)
		c.draw_circle(hub, 62, stock)
		c.draw_arc(hub, 69, 0, TAU, 38, warm, 6, true)
		for i in range(7):
			var x := 70.0 + i * 77.0
			c.draw_line(Vector2(x, 100), Vector2(x + 20, 180), pale, 13, true)
		return
	# The cradle is suspended inside a much larger, open mechanism.
	c.draw_line(Vector2(48, 157), Vector2(682, 183), dark, 20, true)
	c.draw_line(Vector2(57, 185), Vector2(82, 567), pale, 32, true)
	c.draw_line(Vector2(661, 190), Vector2(622, 556), pale, 25, true)
	for i in range(6):
		var x := 105.0 + i * 92.0
		c.draw_circle(Vector2(x, 160 + i * 4), 5, warm)
		c.draw_line(Vector2(x, 190), Vector2(x + 9, 220), dark, 3, true)
	c.draw_line(Vector2(80, 550), Vector2(622, 550), dark, 9, true)
	var hanging := Vector2(590 + sin(t * 0.36) * 3.0, 290)
	c.draw_line(Vector2(591, 185), hanging, warm, 2, true)
	c.draw_circle(hanging, 10, warm)
	c.draw_circle(hanging, 5, pale)
	# A returned arm leaves a warmer reflected edge; no new story is inferred.
	if outcome == "freed":
		c.draw_line(Vector2(94, 542), Vector2(505, 542), warm, 3, true)
	_panes(c, Rect2(size.x - 123, 175, 78, 309), 1, 4, pale, dark)

static func _plaza(c: CanvasItem, size: Vector2, far: bool, pale: Color, dark: Color, warm: Color) -> void:
	if far:
		for i in range(7):
			_ellipse(c, Vector2(size.x * 0.50, 930), Vector2(950 + i * 32, 580 + i * 15), PI, TAU, pale, 2.0)
		for i in range(13):
			var x := -75.0 + i * 155.0
			var h := 104.0 + float((i * 53) % 139)
			_roof(c, Rect2(x, 485 - h, 118, h), i % 3, pale, dark)
			if i % 3 == 0:
				c.draw_line(Vector2(x + 76, 485 - h), Vector2(x + 76, 439 - h), dark, 10)
			_panes(c, Rect2(x + 17, 500 - h, 81, h - 36), 2, 2, pale, warm)
		return
	# Outer arcades frame the voice and leave the centre of the square open.
	for side in [0, 1]:
		var base := 20.0 if side == 0 else size.x - 320.0
		for i in range(3):
			_arch(c, Vector2(base + 42 + i * 93, 390), 36, 545, pale, dark, 9)
		c.draw_line(Vector2(base, 335), Vector2(base + 294, 335), dark, 8)
	var points := PackedVector2Array()
	for i in range(25):
		var u := i / 24.0
		points.append(Vector2(u * size.x, 170 + sin(u * PI) * 71))
	c.draw_polyline(points, dark, 2, true)
	for i in range(10):
		var u := (i + 0.5) / 10.0
		var pin := Vector2(u * size.x, 170 + sin(u * PI) * 71)
		c.draw_line(pin, pin + Vector2(0, 22), dark, 1)
		c.draw_circle(pin + Vector2(0, 26), 5, warm)

static func _street(c: CanvasItem, size: Vector2, far: bool, pale: Color, dark: Color, warm: Color) -> void:
	if far:
		for i in range(10):
			var x := -50.0 + i * 225.0
			var top := 190.0 + float((i * 47) % 93)
			_roof(c, Rect2(x, top, 204, 330), (i + 1) % 3, pale, dark)
			var chimney := Rect2(x + 142, top - 39, 24, 47)
			c.draw_rect(chimney, dark)
			c.draw_rect(Rect2(chimney.position - Vector2(4, 0), Vector2(32, 7)), warm)
			_panes(c, Rect2(x + 22, top + 31, 160, 210), 3, 3, pale, dark)
		return
	# A second row is seen from under the eaves, staggered against the first.
	for i in range(5):
		var x := -100.0 + i * 485.0
		var top := 122.0 + (i % 3) * 28.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, top + 78), Vector2(x + 108, top), Vector2(x + 341, top + 24), Vector2(x + 395, top + 90)]), pale)
		c.draw_line(Vector2(x - 7, top + 79), Vector2(x + 404, top + 92), dark, 7, true)
		for rafter in range(8):
			var a := Vector2(x + 24 + rafter * 47, top + 86)
			c.draw_line(a, a + Vector2(-10, 21), dark, 4, true)
		c.draw_line(Vector2(x + 354, top + 106), Vector2(x + 354, 557), pale, 12)
		for band in range(3):
			c.draw_line(Vector2(x + 343, 322 + band * 66), Vector2(x + 365, 322 + band * 66), warm, 3)

static func _practice(c: CanvasItem, size: Vector2, far: bool, t: float, pale: Color, dark: Color, warm: Color) -> void:
	if far:
		# Acoustic panels are scored diagonally, rather than filled with windows.
		for i in range(8):
			var box := Rect2(38 + i * 215, 132 + (i % 2) * 28, 174, 383)
			c.draw_rect(box, pale)
			c.draw_rect(box.grow(-9), dark, false, 2)
			for line in range(8):
				var y := box.position.y + 40 + line * 40
				c.draw_line(Vector2(box.position.x + 23, y), Vector2(box.end.x - 23, y - 16), dark, 2)
		c.draw_line(Vector2(25, 548), Vector2(size.x - 25, 548), dark, 9)
		return
	var foot := Vector2(190, 527)
	c.draw_colored_polygon(PackedVector2Array([foot + Vector2(-76, 0), foot + Vector2(-35, -319), foot + Vector2(30, -319), foot + Vector2(72, 0)]), pale)
	c.draw_line(foot + Vector2(-72, -9), foot + Vector2(68, -9), dark, 7)
	var pivot := foot + Vector2(0, -38)
	var tip := pivot + Vector2(sin(t * 0.52) * 19, -218)
	c.draw_line(pivot, tip, dark, 5, true)
	c.draw_circle(pivot, 12, warm)
	c.draw_rect(Rect2(tip.lerp(pivot, 0.28) - Vector2(10, 6), Vector2(20, 12)), warm)
	for i in range(3):
		c.draw_line(Vector2(127 + i * 40, 539), Vector2(127 + i * 40, 551), warm, 3)
	_arch(c, Vector2(size.x - 211, 257), 122, 553, pale, dark, 15)
	for i in range(5):
		c.draw_line(Vector2(size.x - 301 + i * 44, 312), Vector2(size.x - 301 + i * 44, 500), pale, 5)

static func _stalls(c: CanvasItem, size: Vector2, far: bool, t: float, pale: Color, dark: Color, warm: Color) -> void:
	if far:
		for i in range(7):
			var x := -60.0 + i * 365.0
			_roof(c, Rect2(x, 143 + (i % 2) * 37, 310, 342), i % 3, pale, dark)
			c.draw_rect(Rect2(x + 24, 272, 260, 204), pale)
			for slat in range(12):
				c.draw_line(Vector2(x + 28, 280 + slat * 16), Vector2(x + 280, 280 + slat * 16), dark, 2)
		return
	# Long cloths hang behind the warm upper walk, with an almost still draft.
	c.draw_line(Vector2(-20, 160), Vector2(size.x + 20, 196), dark, 3, true)
	for i in range(8):
		var x := 55.0 + i * 285.0
		var y := 161.0 + x / size.x * 36.0
		var hem := y + 125 + (i % 3) * 32
		var drift := sin(t * 0.38 + i * 1.7) * 3.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, y), Vector2(x + 173, y + 3), Vector2(x + 166 + drift, hem), Vector2(x + 119 + drift, hem - 8), Vector2(x + 72 + drift, hem + 3), Vector2(x + drift, hem - 5)]), pale)
		for fold in range(5):
			var a := Vector2(x + 16 + fold * 32, y + 10)
			c.draw_line(a, Vector2(a.x + drift, hem - 15), dark, 2, true)
		c.draw_line(Vector2(x + 5, hem - 11), Vector2(x + 162, hem - 7), warm, 3, true)
		c.draw_rect(Rect2(x + 4, y - 5, 7, 17), dark)
		c.draw_rect(Rect2(x + 161, y - 2, 7, 17), dark)

static func _yard(c: CanvasItem, size: Vector2, far: bool, pale: Color, dark: Color, warm: Color) -> void:
	if far:
		var centre := Vector2(size.x * 0.52, 660)
		for ring in range(7):
			_ellipse(c, centre, Vector2(630 + ring * 79, 290 + ring * 19), PI, TAU, pale, 6 if ring % 3 == 0 else 2)
		for i in range(17):
			var u := i / 16.0
			var base := Vector2(35 + u * (size.x - 70), 430 - sin(u * PI) * 80)
			_stone(c, base, 21 + (i % 3) * 7, 58 + (i % 4) * 17, pale, dark)
		return
	for i in range(6):
		var base := Vector2(105 + i * 391, 558)
		_stone(c, base, 61 + (i % 2) * 12, 226 + (i % 3) * 27, pale, dark)
		for ring in range(3):
			c.draw_arc(base + Vector2(0, -167 - (i % 3) * 27), 43 + ring * 7, PI, TAU, 32, warm, 1.4, true)
		for line in range(4):
			var y := base.y - 112 + line * 17
			# Broken pressure marks, never newly legible names.
			c.draw_line(Vector2(base.x - 33, y), Vector2(base.x - 5 + (line % 2) * 8, y), dark, 2)
			c.draw_line(Vector2(base.x + 9, y), Vector2(base.x + 28 - (line % 3) * 4, y), dark, 2)

static func _descent(c: CanvasItem, size: Vector2, far: bool, pale: Color, dark: Color, warm: Color) -> void:
	var pivot := Vector2(size.x * 0.66, 454)
	if far:
		for i in range(7):
			c.draw_arc(pivot, 313 + i * 28, PI * 0.85, TAU + PI * 0.17, 100, pale, 15 if i % 3 == 0 else 3, true)
		for row in range(5):
			var y := 124 + row * 88
			c.draw_line(Vector2(0, y), Vector2(440 - row * 27, y), dark, 2)
			c.draw_line(Vector2(72 + (row % 2) * 120, y), Vector2(72 + (row % 2) * 120, y + 86), pale, 2)
		return
	_arch(c, pivot, 273, 588, pale, dark, 23)
	c.draw_arc(pivot, 301, PI, TAU, 72, warm, 5, true)
	for i in range(19):
		var angle := PI + i * PI / 18.0
		var direction := Vector2(cos(angle), sin(angle))
		c.draw_line(pivot + direction * 285, pivot + direction * 312, dark, 3, true)
	for side in [-1.0, 1.0]:
		var x: float = pivot.x + side * 312
		c.draw_line(Vector2(x, 452), Vector2(x, 585), dark, 3)
		c.draw_rect(Rect2(x - 22, 552, 44, 25), pale)
		for i in range(3):
			c.draw_circle(Vector2(x, 474 + i * 31), 4, warm)

static func _stair(c: CanvasItem, size: Vector2, far: bool, pale: Color, dark: Color, warm: Color, stock: Color) -> void:
	if far:
		# The cut crosses several pressings at once. Each exposed layer slants
		# into the shaft, so the deeper air reads differently from the street.
		for i in range(7):
			var y := -210.0 + i * 181.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(size.x, y + 585), Vector2(size.x, y + 627), Vector2(0, y + 42)]), pale)
			c.draw_line(Vector2(0, y + 48), Vector2(size.x, y + 633), dark, 2, true)
		c.draw_colored_polygon(PackedVector2Array([Vector2(1110, 0), Vector2(1245, 0), Vector2(860, size.y), Vector2(657, size.y)]), stock.lerp(warm, 0.5))
		return
	for i in range(5):
		var x := 118.0 + i * 374.0
		var start := 114.0 + i * 52.0
		c.draw_line(Vector2(x, start), Vector2(x, minf(start + 638, size.y - 20)), pale, 21)
		c.draw_line(Vector2(x + 16, start + 28), Vector2(x + 16, minf(start + 540, size.y - 32)), dark, 2)
		for score in range(5):
			var y := start + 57 + score * 93
			c.draw_line(Vector2(x - 13, y), Vector2(x + 14, y + 7), warm, 2, true)
	var centre := Vector2(size.x - 170, 777)
	for i in range(5):
		c.draw_arc(centre, 158 + i * 22, PI * 0.92, TAU, 60, dark if i == 2 else pale, 6 if i == 2 else 2, true)

static func _roof(c: CanvasItem, box: Rect2, kind: int, fill: Color, edge: Color) -> void:
	c.draw_rect(box, fill)
	var a := box.position
	var b := Vector2(box.end.x, box.position.y)
	if kind == 0:
		c.draw_colored_polygon(PackedVector2Array([a, a + Vector2(box.size.x * 0.46, -37), b]), fill)
		c.draw_line(a - Vector2(5, 0), a + Vector2(box.size.x * 0.46, -37), edge, 3, true)
		c.draw_line(a + Vector2(box.size.x * 0.46, -37), b + Vector2(5, 0), edge, 3, true)
	elif kind == 1:
		c.draw_rect(Rect2(a - Vector2(8, 12), Vector2(box.size.x + 16, 12)), edge)
		c.draw_rect(Rect2(a + Vector2(28, -27), Vector2(box.size.x - 56, 15)), fill)
	else:
		c.draw_colored_polygon(PackedVector2Array([a - Vector2(8, 0), a + Vector2(19, -31), b + Vector2(-24, -31), b + Vector2(8, 0)]), edge)

static func _panes(c: CanvasItem, box: Rect2, columns: int, rows: int, fill: Color, edge: Color) -> void:
	var cell := box.size / Vector2(columns, rows)
	for row in range(rows):
		for column in range(columns):
			var pane := Rect2(box.position + Vector2(column, row) * cell + Vector2(5, 6), cell - Vector2(13, 17))
			c.draw_rect(pane, edge)
			c.draw_line(pane.position + Vector2(pane.size.x * 0.5, 2), Vector2(pane.get_center().x, pane.end.y - 2), fill, 2)

static func _arch(c: CanvasItem, crown: Vector2, radius: float, base_y: float, fill: Color, edge: Color, weight: float) -> void:
	c.draw_arc(crown, radius, PI, TAU, 56, edge, weight, true)
	for side in [-1.0, 1.0]:
		c.draw_line(crown + Vector2(side * radius, 0), Vector2(crown.x + side * radius, base_y), fill, weight, true)
		c.draw_line(crown + Vector2(side * (radius - weight * 0.65), 0), Vector2(crown.x + side * (radius - weight * 0.65), base_y), edge, 2, true)

static func _stone(c: CanvasItem, base: Vector2, half_width: float, height: float, fill: Color, edge: Color) -> void:
	var crown := base - Vector2(0, height - half_width)
	c.draw_circle(crown, half_width, fill)
	c.draw_rect(Rect2(crown - Vector2(half_width, 0), Vector2(half_width * 2, height - half_width)), fill)
	c.draw_arc(crown, half_width - 5, PI, TAU, 32, edge, 2, true)
	c.draw_line(base + Vector2(-half_width - 5, 0), base + Vector2(half_width + 5, 0), edge, 4, true)

static func _ellipse(c: CanvasItem, centre: Vector2, radius: Vector2, start: float, end: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(97):
		var angle := lerpf(start, end, i / 96.0)
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	c.draw_polyline(points, color, width, true)

static func _foreground(c: CanvasItem, room_id: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	var view: Rect2 = pose.get("view", bounds)
	var score := ink.lerp(stock, 0.30)
	var fleck := ink.lerp(stock, 0.46)
	var seam := ink.lerp(stock, 0.16)
	for value in pose.get("surfaces", []):
		if not value is Rect2:
			continue
		var surface: Rect2 = value
		# Every stroke, including its thickness, stays within the exposed slab.
		var interior := Rect2(surface.position + Vector2(4, 11), surface.size - Vector2(8, 15))
		if interior.size.x < 12 or interior.size.y < 5 or not interior.intersects(view.grow(80)):
			continue
		var bottom := interior.end.y
		for line in range(mini(4, int(interior.size.y / 7))):
			var y := interior.position.y + 3 + line * 7
			c.draw_line(Vector2(interior.position.x + 2, y), Vector2(interior.end.x - 2, y), score if line == 0 else seam, 1)
		var start := interior.position.x + 13
		var count := mini(80, int((interior.size.x - 20) / 49))
		for i in range(count):
			var x := start + i * 49
			var y := interior.position.y + minf(10 + (i % 3) * 4, interior.size.y - 3)
			match room_id:
				&"headshell", &"label_descent":
					if interior.size.y >= 12:
						c.draw_circle(Vector2(x, y - 2), 2, fleck)
						c.draw_line(Vector2(x - 1, y - 2), Vector2(x + 1, y - 2), seam, 1)
				&"high_street", &"the_stalls":
					c.draw_line(Vector2(x, interior.position.y + 2), Vector2(x + 3, bottom - 2), seam, 1)
					c.draw_line(Vector2(x + 9, y), Vector2(minf(x + 22, interior.end.x - 2), y - 2), score, 1)
				&"practice_room":
					for mark in range(3):
						c.draw_line(Vector2(x + mark * 5, y), Vector2(x + mark * 5, minf(y + 3, bottom - 1)), fleck, 1)
				&"groove_yard":
					c.draw_line(Vector2(x, y), Vector2(x + 8, y), score, 2)
					c.draw_line(Vector2(x + 13, y), Vector2(x + 19, y), seam, 1)
				_:
					c.draw_line(Vector2(x, y), Vector2(x + 18, y - 2), score, 1)
	c.draw_set_transform(Vector2.ZERO)
