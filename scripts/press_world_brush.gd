extends RefCounted
## A small shared brush kit. Every mark is deterministic and receives its paint;
## no world state, wall clock, collision or camera is read here.

static func palette(ink: Color, stock: Color) -> Dictionary:
	var reversed := ink.get_luminance() < stock.get_luminance()
	return {
		"shadow": stock.lerp(ink, 0.045), "body": stock.lerp(ink, 0.13),
		"edge": stock.lerp(ink, 0.32), "light": stock.lerp(ink, 0.68),
		"gold": ink.lerp(Color("9a6245") if reversed else Color("ffc77c"), 0.40),
		"copper": stock.lerp(Color("794d51") if reversed else Color("b78066"), 0.46),
		"sage": stock.lerp(Color("607b70"), 0.36),
	}

static func grain(seed: float) -> float:
	return fposmod(sin(seed * 127.1 + 31.7) * 43758.5453, 1.0)

static func fade(paint: Color, opacity: float) -> Color:
	return Color(paint, paint.a * opacity)

static func stroke(c: CanvasItem, points: PackedVector2Array, paint: Color, width: float, seed := 0.0) -> void:
	if points.size() < 2: return
	var rough := PackedVector2Array()
	for i in points.size():
		var offset := Vector2(grain(seed + i * 7) - 0.5, grain(seed + i * 11) - 0.5) * minf(width * 0.25, 1.1)
		rough.append(points[i] + offset)
	c.draw_polyline(rough, Color(paint, paint.a * 0.23), width + 2.0, true)
	c.draw_polyline(points, paint, width, true)

static func line(c: CanvasItem, a: Vector2, b: Vector2, paint: Color, width: float, seed := 0.0) -> void:
	stroke(c, PackedVector2Array([a, a.lerp(b, 0.32), a.lerp(b, 0.71), b]), paint, width, seed)

static func curve(c: CanvasItem, a: Vector2, bend: Vector2, b: Vector2, paint: Color, width: float) -> void:
	var points := PackedVector2Array()
	for i in range(25):
		var t := float(i) / 24.0
		points.append(a * (1.0 - t) * (1.0 - t) + bend * 2.0 * t * (1.0 - t) + b * t * t)
	stroke(c, points, paint, width, a.x + b.y)

static func ellipse(c: CanvasItem, center: Vector2, size: Vector2, paint: Color, width := 2.0, start := 0.0, end := TAU) -> void:
	var points := PackedVector2Array()
	for i in range(49):
		var angle := lerpf(start, end, float(i) / 48.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	stroke(c, points, paint, width, center.x)

static func wash(c: CanvasItem, polygon: PackedVector2Array, paint: Color) -> void:
	if polygon.size() < 3: return
	c.draw_colored_polygon(polygon, paint)

static func window(c: CanvasItem, box: Rect2, p: Dictionary, lit := true, arch := true) -> void:
	var radius := box.size.x * 0.5
	var crown := Vector2(box.get_center().x, box.position.y + radius)
	var body := Rect2(box.position + Vector2(0, radius if arch else 0.0), box.size - Vector2(0, radius if arch else 0.0))
	var fill: Color = p.gold if lit else p.shadow
	if arch: c.draw_circle(crown, radius, fade(fill, 0.26 if lit else 0.65), true, -1, true)
	c.draw_rect(body, fade(fill, 0.25 if lit else 0.65))
	if arch:
		ellipse(c, crown, Vector2.ONE * (radius + 3.0), fade(p.edge, 0.75), 4.0, PI, TAU)
	else:
		line(c, box.position, Vector2(box.end.x, box.position.y), p.edge, 4)
	for side in [-1.0, 1.0]:
		var x: float = crown.x + side * (radius + 2)
		line(c, Vector2(x, crown.y if arch else box.position.y), Vector2(x, box.end.y), p.edge, 5)
	line(c, Vector2(box.position.x - 7, box.end.y + 3), Vector2(box.end.x + 7, box.end.y + 3), p.copper, 5)
	line(c, Vector2(crown.x, box.position.y + 10), Vector2(crown.x, box.end.y - 2), fade(p.shadow, 0.75), 3)
	line(c, Vector2(box.position.x + 2, box.get_center().y + 10), Vector2(box.end.x - 2, box.get_center().y + 10), p.shadow, 3)
	if lit:
		line(c, Vector2(box.position.x + 5, crown.y + 4), Vector2(box.position.x + 5, box.end.y - 10), fade(p.gold, 0.48), 2)

static func column(c: CanvasItem, x: float, top: float, bottom: float, width: float, p: Dictionary) -> void:
	wash(c, PackedVector2Array([Vector2(x - width * 0.48, top), Vector2(x + width * 0.50, top + 4),
		Vector2(x + width * 0.42, bottom), Vector2(x - width * 0.52, bottom)]), fade(p.body, 0.82))
	line(c, Vector2(x - width * 0.33, top + 8), Vector2(x - width * 0.38, bottom - 9), fade(p.light, 0.23), 7)
	line(c, Vector2(x + width * 0.36, top), Vector2(x + width * 0.29, bottom), fade(p.shadow, 0.9), 9)
	for y in [top, bottom - 11]:
		line(c, Vector2(x - width * 0.64, y), Vector2(x + width * 0.63, y + 2), p.edge, 11)
		line(c, Vector2(x - width * 0.61, y - 5), Vector2(x + width * 0.60, y - 4), fade(p.gold, 0.27), 2)
	for i in range(5):
		var y := lerpf(top + 30, bottom - 30, float(i) / 4.0)
		line(c, Vector2(x - width * 0.35, y), Vector2(x + width * 0.30, y - 3), fade(p.edge, 0.30), 1)

static func archway(c: CanvasItem, center: Vector2, radius: Vector2, bottom: float, p: Dictionary, weight := 14.0) -> void:
	ellipse(c, center, radius, fade(p.shadow, 0.86), weight + 11, PI, TAU)
	ellipse(c, center, radius, fade(p.edge, 0.70), weight, PI, TAU)
	ellipse(c, center + Vector2(0, -3), radius + Vector2(3, 1), fade(p.gold, 0.21), 2.5, PI, TAU)
	for side in [-1.0, 1.0]:
		line(c, center + Vector2(side * radius.x, 0), Vector2(center.x + side * radius.x, bottom), p.body, weight + 7)
		line(c, center + Vector2(side * (radius.x - 4), 0), Vector2(center.x + side * (radius.x - 4), bottom), fade(p.edge, 0.60), 3)
	for i in range(11):
		var angle := PI + float(i) / 10.0 * PI
		var a := center + Vector2(cos(angle), sin(angle)) * (radius - Vector2.ONE * weight * 0.35)
		var b := center + Vector2(cos(angle), sin(angle)) * (radius + Vector2.ONE * weight * 0.35)
		line(c, a, b, fade(p.shadow, 0.65), 2)

static func cable(c: CanvasItem, a: Vector2, b: Vector2, sag: float, p: Dictionary) -> void:
	var bend := (a + b) * 0.5 + Vector2(0, sag)
	curve(c, a + Vector2(0, 2), bend + Vector2(0, 3), b + Vector2(0, 2), p.shadow, 4)
	curve(c, a, bend, b, fade(p.edge, 0.64), 1.4)

static func lamp(c: CanvasItem, point: Vector2, p: Dictionary, scale := 1.0) -> void:
	for i in range(5, 0, -1):
		c.draw_circle(point, float(i) * 12 * scale, fade(p.gold, 0.006 * (6 - i)), true, -1, true)
	wash(c, PackedVector2Array([point + Vector2(-16, -6) * scale, point + Vector2(-8, -18) * scale,
		point + Vector2(8, -18) * scale, point + Vector2(17, -5) * scale]), p.copper)
	line(c, point + Vector2(-17, -5) * scale, point + Vector2(17, -4) * scale, p.gold, 2 * scale)
	c.draw_circle(point + Vector2(0, 3) * scale, 5 * scale, p.gold, true, -1, true)

static func motes(c: CanvasItem, area: Rect2, clock: float, paint: Color, count := 12) -> void:
	for i in range(count):
		var x := area.position.x + grain(i * 13.0) * area.size.x + sin(clock * 0.23 + i) * 9
		var y := area.position.y + grain(i * 29.0) * area.size.y + sin(clock * 0.16 + i * 2.0) * 6
		c.draw_circle(Vector2(x, y), 0.7 + grain(i) * 1.1, Color(paint, 0.08 + grain(i * 3.0) * 0.13), true, -1, true)

static func face(c: CanvasItem, surfaces: Array, p: Dictionary, metal := false) -> void:
	for value in surfaces:
		if not value is Rect2: continue
		var raw: Rect2 = value
		var r := Rect2(raw.position + Vector2(5, 13), raw.size - Vector2(10, 18))
		if r.size.x < 16 or r.size.y < 5: continue
		# All detail remains inside the supplied collider face and its parent clip.
		for row in range(mini(4, int(r.size.y / 6))):
			var y := r.position.y + 2 + row * 6
			var points := PackedVector2Array()
			for i in range(17):
				var x := lerpf(r.position.x + 2, r.end.x - 2, i / 16.0)
				points.append(Vector2(x, clampf(y + sin(i * 1.7 + raw.position.x) * 1.0, r.position.y + 1, r.end.y - 1)))
			c.draw_polyline(points, fade(p.light, 0.14 if metal else 0.10), 1.0)
		if r.size.y > 18 and metal:
			for x in [r.position.x + 7, r.end.x - 7]:
				c.draw_circle(Vector2(x, r.get_center().y), 2.1, fade(p.copper, 0.62))
				c.draw_circle(Vector2(x - 0.5, r.get_center().y - 0.5), 0.7, fade(p.gold, 0.72))
