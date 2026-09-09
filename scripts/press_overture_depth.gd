extends RefCounted
## Depth plates for the seven Overture rooms. Camera offsets, time and palette
## are supplied by the room's atmosphere; this impression owns no world state.

const ROOMS := [&"bootlegger", &"whistlers", &"addie", &"overture_well", &"worn_gallery", &"smoothed_floor", &"the_arm"]
const OCHRE := Color("bd8753")
const ROSE := Color("b87977")

static func draw(canvas: CanvasItem, room_id: StringName, layer: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	if not ROOMS.has(room_id) or bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	var clock := float(pose.get("clock", 0.0)) * clampf(float(pose.get("motion", 1.0)), 0.0, 1.0)
	if not is_finite(clock):
		clock = 0.0
	if layer == &"foreground":
		_foreground(canvas, room_id, bounds, pose, ink, stock)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	if layer != &"far" and layer != &"middle":
		return
	var middle := layer == &"middle"
	match room_id:
		&"bootlegger": _stall(canvas, bounds, middle, clock, ink, stock)
		&"whistlers": _whistlers(canvas, bounds, middle, clock, ink, stock)
		&"addie": _doorway(canvas, bounds, middle, clock, ink, stock, String(pose.get("outcome", "")))
		&"overture_well": _well(canvas, bounds, middle, clock, ink, stock)
		&"worn_gallery": _gallery(canvas, bounds, middle, ink, stock)
		&"smoothed_floor": _hush(canvas, bounds, middle, ink, stock)
		&"the_arm": _arm(canvas, bounds, middle, ink, stock, String(pose.get("outcome", "")))
	canvas.draw_set_transform(Vector2.ZERO)

static func _stall(canvas: CanvasItem, bounds: Rect2, middle: bool, clock: float, ink: Color, stock: Color) -> void:
	var w := bounds.size.x
	var h := bounds.size.y
	if not middle:
		# A warm recess rather than another exposed wall: stacked shelves recede
		# toward the counter, with a second row continuing below the played floor.
		canvas.draw_rect(Rect2(100.0, 40.0, w - 200.0, h - 90.0), Color(ink, 0.085))
		for frame in range(4):
			var inset := 30.0 + frame * 25.0
			_frame(canvas, Rect2(100.0 + inset, 40.0 + inset * 0.5, w - 200.0 - inset * 2.0, h - 95.0 - inset), Color(ink, 0.055), 5.0)
		var x: float = 170.0
		while x < w - 120.0:
			canvas.draw_rect(Rect2(x, 100.0, 12.0, h - 180.0), Color(ink, 0.14))
			x += 270.0
		for row in range(3):
			var shelf_y := 188.0 + row * 205.0
			canvas.draw_rect(Rect2(143.0, shelf_y, w - 286.0, 12.0), Color(ink, 0.15))
			for index in range(17):
				var book_x := 177.0 + index * (w - 340.0) / 17.0
				var tall := 48.0 + _grain(index + row * 31) * 42.0
				canvas.draw_rect(Rect2(book_x, shelf_y - tall, 19.0 + _grain(index * 7) * 22.0, tall), Color(ink, 0.105 + 0.035 * _grain(index)))
				canvas.draw_line(Vector2(book_x + 5.0, shelf_y - tall + 9.0), Vector2(book_x + 5.0, shelf_y - 8.0), Color(stock, 0.16), 1.5, true)
		return
	# The shade's translucent cone is a wash on the back wall, behind actors.
	var lamp := Vector2(w * 0.45, 118.0)
	canvas.draw_line(Vector2(lamp.x, -30.0), lamp, Color(ink, 0.21), 3.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-28.0, 0.0), lamp + Vector2(28.0, 0.0), Vector2(lamp.x + 315.0, 598.0), Vector2(lamp.x - 270.0, 598.0)]), Color(OCHRE.lerp(stock, 0.65), 0.10))
	canvas.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-43.0, 8.0), lamp + Vector2(-21.0, -17.0), lamp + Vector2(18.0, -17.0), lamp + Vector2(43.0, 8.0)]), Color(ink, 0.24))
	canvas.draw_line(lamp + Vector2(-38.0, 9.0), lamp + Vector2(39.0, 9.0), Color(stock, 0.45), 2.5, true)
	for side in [0, 1]:
		var shelf_x := 102.0 if side == 0 else w - 255.0
		canvas.draw_rect(Rect2(shelf_x, 292.0, 160.0, 254.0), Color(ink, 0.16))
		for row in range(3):
			var y := 355.0 + row * 76.0
			canvas.draw_line(Vector2(shelf_x - 9.0, y), Vector2(shelf_x + 170.0, y), Color(ink, 0.24), 5.0, true)
			for reel in range(3):
				var center := Vector2(shelf_x + 28.0 + reel * 51.0, y - 23.0)
				canvas.draw_circle(center, 20.0, Color(ink, 0.21), true, -1.0, true)
				_ellipse(canvas, center, Vector2(14.0, 14.0), Color(stock, 0.28), 1.5)
				canvas.draw_circle(center, 3.0, Color(ink, 0.12), true, -1.0, true)
	for speck in range(14):
		var center := lamp + Vector2(-120.0 + _grain(speck * 9) * 240.0 + sin(clock * 0.24 + speck) * 1.5, 75.0 + _grain(speck + 91) * 275.0)
		canvas.draw_line(center, center + Vector2(1.0, 2.0), Color(OCHRE, 0.09), 1.0, true)

static func _whistlers(canvas: CanvasItem, bounds: Rect2, middle: bool, clock: float, ink: Color, stock: Color) -> void:
	var w := bounds.size.x
	var h := bounds.size.y
	if not middle:
		# Broad channels traverse the entire height, including the recovery route.
		for index in range(10):
			var x: float = -100.0 + index * (w + 200.0) / 9.0
			var width := 103.0 + _grain(index + 23) * 55.0
			var top := 35.0 + _grain(index + 8) * 95.0
			canvas.draw_rect(Rect2(x, top, width, h - top + 80.0), Color(ink, 0.085 + _grain(index) * 0.05))
			canvas.draw_rect(Rect2(x + width * 0.28, top + 14.0, width * 0.39, h - top + 80.0), Color(ink, 0.065))
			_ellipse(canvas, Vector2(x + width * 0.5, top), Vector2(width * 0.5, 18.0), Color(ink, 0.10), 3.0)
			for collar in range(3):
				var y := 292.0 + collar * 315.0 + _grain(index + 3) * 54.0
				canvas.draw_rect(Rect2(x - 7.0, y, width + 14.0, 13.0), Color(ink, 0.14))
		return
	for index in range(6):
		var x: float = 145.0 + index * (w - 270.0) / 5.0
		var top := 50.0 + _grain(index + 78) * 130.0
		var width := 60.0 + _grain(index + 66) * 45.0
		canvas.draw_rect(Rect2(x, top, width, h - top + 40.0), Color(ink, 0.17))
		canvas.draw_line(Vector2(x + 15.0, top + 20.0), Vector2(x + 15.0, h), Color(stock, 0.20), 3.0, true)
		canvas.draw_line(Vector2(x + width - 9.0, top), Vector2(x + width - 9.0, h), Color(ink, 0.235), 4.0, true)
		# Irregular lips and breaks make these sound-worn tubes, not new ladders.
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x, top), Vector2(x + width * 0.26, top + 17.0), Vector2(x + width * 0.45, top + 5.0), Vector2(x + width * 0.69, top + 28.0), Vector2(x + width, top + 11.0), Vector2(x + width, top + 47.0), Vector2(x, top + 40.0)]), Color(ink, 0.22))
		for mark in range(4):
			var y := 365.0 + mark * 168.0 + _grain(index + mark * 17) * 50.0
			canvas.draw_line(Vector2(x + 18.0, y), Vector2(x + width - 13.0, y - 17.0), Color(ink, 0.10), 2.0, true)
	for band in range(7):
		var line := PackedVector2Array()
		for segment in range(33):
			var x: float = w * float(segment) / 32.0
			var y := 138.0 + band * 140.0 + sin(x * 0.0036 + clock * 0.22 + band * 0.7) * 13.0
			line.append(Vector2(x, y))
		canvas.draw_polyline(line, Color(stock.lerp(ROSE, 0.45), 0.12), 1.5, true)

static func _doorway(canvas: CanvasItem, bounds: Rect2, middle: bool, clock: float, ink: Color, stock: Color, outcome: String) -> void:
	var center_x := bounds.size.x * 0.475
	if not middle:
		for depth in range(5):
			var half := 438.0 - depth * 58.0
			var top := 27.0 + depth * 46.0
			var rect := Rect2(center_x - half, top, half * 2.0, bounds.size.y - top + 30.0)
			canvas.draw_rect(rect, Color(ink, 0.020 + depth * 0.002))
			_frame(canvas, rect, Color(ink, 0.047), 12.0 - depth)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(center_x - 58.0, 200.0), Vector2(center_x + 89.0, 194.0), Vector2(center_x + 195.0, 598.0), Vector2(center_x - 151.0, 598.0)]), Color(OCHRE.lerp(stock, 0.40), 0.09 if outcome != "shattered" else 0.04))
		return
	var curtain_ink := Color(ROSE.lerp(ink, 0.66), 0.23)
	for side in [-1.0, 1.0]:
		var x: float = center_x + side * 207.0
		var hem := 518.0 + sin(clock * 0.34 + side) * 1.3
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - 56.0, 138.0), Vector2(x + 56.0, 138.0), Vector2(x + 42.0 + side * 45.0, hem), Vector2(x - 42.0 + side * 45.0, hem + 13.0)]), curtain_ink)
		for fold in range(4):
			var start := Vector2(x - 36.0 + fold * 23.0, 149.0)
			canvas.draw_line(start, Vector2(x - 12.0 + fold * 13.0 + side * 33.0, hem - 8.0), Color(stock, 0.19), 2.0, true)
	canvas.draw_line(Vector2(center_x - 291.0, 133.0), Vector2(center_x + 291.0, 133.0), Color(ink, 0.23), 8.0, true)
	# Domestic details sit well behind her threshold: a small sconce, a hook,
	# and the oval impression where a picture has been lifted from the paper.
	for x in [center_x - 500.0, center_x + 540.0]:
		_ellipse(canvas, Vector2(x, 298.0), Vector2(55.0, 70.0), Color(ink, 0.13), 5.0)
		_ellipse(canvas, Vector2(x, 298.0), Vector2(43.0, 58.0), Color(ink, 0.07), 1.5)
	var lamp := Vector2(center_x + 361.0, 342.0)
	canvas.draw_line(lamp + Vector2(25.0, 24.0), lamp + Vector2(0.0, 24.0), Color(ink, 0.23), 4.0, true)
	canvas.draw_line(lamp + Vector2(25.0, 24.0), lamp + Vector2(25.0, 49.0), Color(ink, 0.23), 4.0, true)
	canvas.draw_colored_polygon(PackedVector2Array([lamp + Vector2(-29.0, 0.0), lamp + Vector2(-18.0, -32.0), lamp + Vector2(18.0, -32.0), lamp + Vector2(29.0, 0.0)]), Color(ink, 0.20))
	_oval(canvas, lamp + Vector2(0.0, 40.0), Vector2(48.0, 87.0), Color(OCHRE, 0.055 if outcome != "shattered" else 0.025))

static func _well(canvas: CanvasItem, bounds: Rect2, middle: bool, clock: float, ink: Color, stock: Color) -> void:
	var w := bounds.size.x
	var h := bounds.size.y
	var center_x := w * 0.5
	if not middle:
		canvas.draw_rect(Rect2(w * 0.22, -60.0, w * 0.56, h + 120.0), Color(ink, 0.11))
		for rib in range(13):
			var offset := float(rib - 6) / 6.0
			var x: float = center_x + offset * w * 0.44
			var inner := center_x + offset * w * 0.30
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - 7.0, -50.0), Vector2(x + 7.0, -50.0), Vector2(inner + 6.0, h + 80.0), Vector2(inner - 6.0, h + 80.0)]), Color(ink, 0.135))
		for ring in range(10):
			var y := -50.0 + ring * (h + 100.0) / 9.0
			var radius := Vector2(w * (0.47 - ring * 0.009), 79.0 - ring * 2.0)
			_ellipse(canvas, Vector2(center_x, y), radius, Color(ink, 0.10), 3.0)
			_ellipse(canvas, Vector2(center_x, y + 13.0), radius, Color(stock, 0.15), 1.5)
		return
	for side in [-1.0, 1.0]:
		var x: float = center_x + side * w * 0.34
		canvas.draw_rect(Rect2(x - 37.0, -80.0, 74.0, h + 160.0), Color(ink, 0.18))
		canvas.draw_line(Vector2(x - side * 18.0, -80.0), Vector2(x - side * 18.0, h + 80.0), Color(stock, 0.17), 5.0, true)
		canvas.draw_line(Vector2(x + side * 30.0, -80.0), Vector2(x + side * 30.0, h + 80.0), Color(ink, 0.23), 4.0, true)
	for ring in range(7):
		var y := 109.0 + ring * 235.0
		_ellipse(canvas, Vector2(center_x, y), Vector2(w * 0.385, 79.0), Color(ink, 0.12), 6.0)
		_ellipse(canvas, Vector2(center_x, y - 8.0), Vector2(w * 0.385, 79.0), Color(stock, 0.13), 2.0)
		for rivet in range(9):
			var angle := PI * float(rivet) / 8.0
			var point := Vector2(center_x, y) + Vector2(cos(angle) * w * 0.385, sin(angle) * 79.0)
			canvas.draw_circle(point, 2.4, Color(ink, 0.11), true, -1.0, true)
	for thread in range(3):
		var x: float = center_x + (thread - 1) * 71.0
		var line := PackedVector2Array()
		for segment in range(24):
			var y := h * float(segment) / 23.0
			line.append(Vector2(x + sin(y * 0.006 + clock * 0.19 + thread) * 7.0, y))
		canvas.draw_polyline(line, Color(stock, 0.11), 1.0, true)

static func _gallery(canvas: CanvasItem, bounds: Rect2, middle: bool, ink: Color, stock: Color) -> void:
	var w := bounds.size.x
	if not middle:
		for index in range(9):
			var x: float = 40.0 + index * 315.0
			_arch(canvas, Vector2(x, 281.0), 103.0, bounds.size.y + 30.0, Color(ink, 0.115), 20.0)
			_arch(canvas, Vector2(x, 286.0), 79.0, bounds.size.y + 30.0, Color(ink, 0.05), 3.0)
		canvas.draw_rect(Rect2(0.0, 151.0, w, 13.0), Color(ink, 0.12))
		canvas.draw_rect(Rect2(0.0, 703.0, w, 14.0), Color(ink, 0.10))
		return
	for index in range(5):
		var x: float = 336.0 + index * 489.0
		_arch(canvas, Vector2(x, 287.0), 164.0, bounds.size.y + 30.0, Color(ink, 0.135), 17.0)
		_arch(canvas, Vector2(x, 287.0), 149.0, bounds.size.y + 30.0, Color(stock, 0.17), 2.0)
		var portrait := Vector2(x, 357.0)
		_oval(canvas, portrait, Vector2(53.0, 72.0), Color(ink, 0.155))
		_ellipse(canvas, portrait, Vector2(58.0, 77.0), Color(ink, 0.095), 3.0)
		# Worn cameo relief: a profile and shoulder, never another active person.
		var side := -1.0 if index % 2 == 0 else 1.0
		_oval(canvas, portrait + Vector2(side * 6.0, -12.0), Vector2(16.0, 22.0), Color(ink, 0.19))
		canvas.draw_colored_polygon(PackedVector2Array([portrait + Vector2(-32.0, 37.0), portrait + Vector2(-22.0, 17.0), portrait + Vector2(9.0, 9.0), portrait + Vector2(34.0, 34.0)]), Color(ink, 0.18))
		for scratch in range(4):
			var y := portrait.y - 34.0 + scratch * 22.0
			canvas.draw_line(Vector2(x - 40.0, y), Vector2(x + 39.0, y - 7.0), Color(stock, 0.26), 3.0, true)
		canvas.draw_rect(Rect2(x - 42.0, 455.0, 84.0, 8.0), Color(ink, 0.17))

static func _hush(canvas: CanvasItem, bounds: Rect2, middle: bool, ink: Color, stock: Color) -> void:
	var center := Vector2(bounds.size.x * 0.5, 404.0)
	if not middle:
		# Broad nested fields suggest polish catching the light, with no rings
		# drawn onto HUSH's playable floor and no conspicuous moving particles.
		for band in range(7):
			_oval(canvas, center, Vector2(840.0 - band * 88.0, 430.0 - band * 41.0), Color(ink, 0.095) if band == 0 else Color(stock, 0.16))
		for side in [-1.0, 1.0]:
			var x: float = center.x + side * 820.0
			canvas.draw_rect(Rect2(x - 64.0, 20.0, 128.0, bounds.size.y + 30.0), Color(ink, 0.10))
		return
	for side in [-1.0, 1.0]:
		var x: float = center.x + side * 674.0
		canvas.draw_rect(Rect2(x - 43.0, 93.0, 86.0, bounds.size.y + 30.0), Color(ink, 0.16))
		canvas.draw_line(Vector2(x - side * 21.0, 111.0), Vector2(x - side * 21.0, bounds.size.y), Color(stock, 0.25), 3.0, true)
		canvas.draw_rect(Rect2(x - 65.0, 84.0, 130.0, 22.0), Color(ink, 0.21))
	_ellipse(canvas, Vector2(center.x, 172.0), Vector2(671.0, 126.0), Color(ink, 0.085), 7.0, PI, TAU)
	_ellipse(canvas, Vector2(center.x, 172.0), Vector2(648.0, 109.0), Color(stock, 0.17), 2.0, PI, TAU)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(center.x - 104.0, -10.0), Vector2(center.x + 101.0, -10.0), Vector2(center.x + 380.0, 591.0), Vector2(center.x - 376.0, 591.0)]), Color(stock.lightened(0.08), 0.12))
	for index in range(3):
		var y := 662.0 + index * 43.0
		_ellipse(canvas, Vector2(center.x, y), Vector2(859.0 - index * 74.0, 27.0), Color(stock, 0.12), 1.5)

static func _arm(canvas: CanvasItem, bounds: Rect2, middle: bool, ink: Color, stock: Color, outcome: String) -> void:
	var hub := Vector2(bounds.size.x * 0.58, 410.0)
	if not middle:
		_oval(canvas, hub, Vector2(870.0, 670.0), Color(ink, 0.085))
		for ring in range(26):
			var radius := 178.0 + ring * 28.0
			_ellipse(canvas, hub, Vector2(radius, radius * 0.77), Color(ink, 0.052 + (0.022 if ring % 5 == 0 else 0.0)), 2.0 if ring % 5 == 0 else 1.0)
		for spoke in range(14):
			var angle := float(spoke) * TAU / 14.0
			var inner := hub + Vector2(cos(angle) * 165.0, sin(angle) * 128.0)
			var outer := hub + Vector2(cos(angle) * 865.0, sin(angle) * 666.0)
			canvas.draw_line(inner, outer, Color(ink, 0.055), 9.0, true)
		return
	# The distant spindle is offset from the live keeper, leaving its cartridge
	# silhouette, wind-up marks and the player's route unambiguous in front.
	var pivot := Vector2(bounds.size.x * 0.29, 315.0)
	canvas.draw_circle(pivot, 118.0, Color(ink, 0.16), true, -1.0, true)
	_ellipse(canvas, pivot, Vector2(93.0, 93.0), Color(stock, 0.27), 3.0)
	_ellipse(canvas, pivot, Vector2(70.0, 70.0), Color(ink, 0.09), 7.0)
	canvas.draw_circle(pivot, 23.0, Color(ink, 0.23), true, -1.0, true)
	for bolt in range(8):
		var point := pivot + Vector2.from_angle(TAU * float(bolt) / 8.0) * 102.0
		canvas.draw_circle(point, 5.0, Color(ink, 0.235), true, -1.0, true)
	canvas.draw_rect(Rect2(pivot.x - 62.0, -80.0, 124.0, 220.0), Color(ink, 0.17))
	canvas.draw_line(Vector2(pivot.x - 27.0, -60.0), Vector2(pivot.x - 27.0, 143.0), Color(stock, 0.19), 3.0, true)
	var warmth := 0.095 if outcome == "freed" else 0.06
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(1185.0, -40.0), Vector2(1290.0, -40.0), Vector2(1575.0, 593.0), Vector2(995.0, 593.0)]), Color(OCHRE.lerp(stock, 0.57), warmth))
	for rail in range(3):
		var y := 712.0 + rail * 48.0
		_ellipse(canvas, Vector2(hub.x, y), Vector2(860.0 - rail * 58.0, 61.0), Color(ink, 0.055), 3.0)

static func _foreground(canvas: CanvasItem, room_id: StringName, bounds: Rect2, pose: Dictionary, ink: Color, stock: Color) -> void:
	var surfaces: Array = pose.get("surfaces", [])
	var view: Rect2 = pose.get("view", bounds)
	var seed := ROOMS.find(room_id) * 97
	for index in surfaces.size():
		if not (surfaces[index] is Rect2):
			continue
		var surface: Rect2 = surfaces[index]
		# Clipping is geometric, not a screen-texture operation. Stroke centres
		# have extra clearance, so even their antialiased edges stay in the wax.
		var inset := Rect2(surface.position + Vector2(4.0, 12.0), surface.size - Vector2(8.0, 17.0))
		if inset.size.x < 10.0 or inset.size.y < 4.0:
			continue
		var area := inset.intersection(bounds).intersection(view.grow(4.0))
		if not area.has_area():
			continue
		var rows := mini(int(area.size.y / 6.0), 5)
		for row in range(rows):
			var y := area.position.y + 2.0 + row * (area.size.y - 4.0) / maxf(float(rows - 1), 1.0)
			var line := PackedVector2Array()
			var segments := maxi(int(area.size.x / 60.0), 1)
			for segment in range(segments + 1):
				var x: float = area.position.x + area.size.x * float(segment) / float(segments)
				var grain := (_grain(seed + index * 43 + segment * 7 + row * 17) - 0.5) * minf(area.size.y * 0.13, 2.0)
				line.append(Vector2(x, clampf(y + grain, area.position.y + 1.0, area.end.y - 1.0)))
			canvas.draw_polyline(line, Color(stock, 0.11 if room_id == &"smoothed_floor" else 0.17), 1.0, true)
		var count := mini(int(area.size.x / 96.0), 30)
		for grain in range(count):
			var x: float = area.position.x + 7.0 + _grain(seed + grain * 13 + index) * maxf(area.size.x - 14.0, 1.0)
			var y := area.position.y + 2.0 + _grain(seed + grain * 19 + 4) * maxf(area.size.y - 4.0, 1.0)
			var length := minf(4.0 + _grain(grain + 71) * 9.0, area.end.x - x - 1.0)
			if length > 0.0:
				canvas.draw_line(Vector2(x, y), Vector2(x + length, y), Color(stock, 0.13), 1.0, true)
		if area.size.y >= 20.0 and area.size.x >= 100.0 and room_id in [&"bootlegger", &"overture_well", &"the_arm"]:
			for x in [area.position.x + 12.0, area.end.x - 12.0]:
				var center := Vector2(x, area.position.y + area.size.y * 0.5)
				_ellipse(canvas, center, Vector2(2.5, 2.5), Color(stock, 0.22), 1.0)
				canvas.draw_circle(center, 0.8, Color(ink, 0.17), true, -1.0, true)

static func _frame(canvas: CanvasItem, rect: Rect2, color: Color, width: float) -> void:
	canvas.draw_rect(rect, color, false, width, true)

static func _arch(canvas: CanvasItem, crown: Vector2, radius: float, bottom: float, color: Color, width: float) -> void:
	_ellipse(canvas, crown, Vector2(radius, radius), color, width, PI, TAU)
	canvas.draw_line(crown + Vector2(-radius, 0.0), Vector2(crown.x - radius, bottom), color, width, true)
	canvas.draw_line(crown + Vector2(radius, 0.0), Vector2(crown.x + radius, bottom), color, width, true)

static func _ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, width: float, start := 0.0, end := TAU) -> void:
	var points := PackedVector2Array()
	var segments := 72 if maxf(radii.x, radii.y) > 200.0 else 40
	for index in range(segments + 1):
		var angle := lerpf(start, end, float(index) / float(segments))
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	canvas.draw_polyline(points, color, width, true)

static func _oval(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(80):
		var angle := TAU * float(index) / 80.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	canvas.draw_colored_polygon(points, color)

static func _grain(index: int) -> float:
	# A fixed integer avalanche gives reproducible tool marks without consuming
	# or reseeding the game's random stream.
	var value := (index * 1103515245 + 12345) & 0x7fffffff
	value = ((value >> 7) ^ value) & 65535
	return float(value) / 65535.0
