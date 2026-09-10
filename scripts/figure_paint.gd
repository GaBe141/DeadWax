extends RefCounted
## Shared gouache materials. Supplied page colours tune contrast and contours;
## brush marks are deterministic, and no helper owns a clock or scene state.

static func palette(ink: Color, stock: Color) -> Dictionary:
	var dark := stock.get_luminance() < 0.38
	return {
		"edge": Color("13292e").lerp(ink, 0.10),
		"shadow": Color("132d34"), "coat": Color("23545a"),
		"teal": Color("487a78") if dark else Color("3b6a68"),
		"cream": Color("f2dfb5"), "light": Color("fff0ce"),
		"wax": Color("c8b286"), "brass": Color("b48c4e"),
		"gold": Color("e5bd70"), "copper": Color("c87955"),
		"coral": Color("ed987b"), "wood": Color("81513c"),
		"rim": Color("b8c9b1") if dark else Color("49645f"),
	}

static func shape(c: CanvasItem, points: PackedVector2Array, fill: Color, edge: Color, width := 1.8) -> void:
	c.draw_colored_polygon(points, fill)
	var line := points.duplicate()
	line.append(line[0])
	c.draw_polyline(line, edge, width, true)

static func segment(c: CanvasItem, start: Vector2, finish: Vector2, width: float, fill: Color, edge: Color, highlight: Color) -> void:
	c.draw_line(start, finish, edge, width + 2.5, true)
	c.draw_circle(start, width * 0.5 + 1.2, edge, true, -1, true)
	c.draw_circle(finish, width * 0.5 + 1.2, edge, true, -1, true)
	c.draw_line(start, finish, fill, width, true)
	c.draw_circle(start, width * 0.5, fill, true, -1, true)
	c.draw_circle(finish, width * 0.5, fill, true, -1, true)
	var normal := (finish - start).normalized().orthogonal()
	if normal.y > 0.0: normal = -normal
	c.draw_line(start + normal * width * 0.18, finish + normal * width * 0.18, Color(highlight, fill.a * 0.52), maxf(width * 0.20, 1.1), true)

static func disc(c: CanvasItem, center: Vector2, radius: float, fill: Color, edge: Color, highlight: Color, alpha := 1.0) -> void:
	c.draw_circle(center, radius + 1.5, Color(edge, alpha), true, -1, true)
	c.draw_circle(center, radius, Color(fill, alpha), true, -1, true)
	var shade := PackedVector2Array([center + Vector2(radius * 0.17, -radius * 0.96)])
	for index in range(19):
		var angle := lerpf(-1.4, 1.7, index / 18.0)
		shade.append(center + Vector2.from_angle(angle) * radius)
	shade.append(center + Vector2(-radius * 0.18, radius * 0.68))
	c.draw_colored_polygon(shade, Color(edge, 0.22 * alpha))
	c.draw_arc(center + Vector2(0.5, 0.5), radius - 2.0, -2.92, -1.10, 22, Color(highlight, alpha * 0.70), maxf(radius * 0.13, 1.4), true)
	c.draw_arc(center, radius - 0.8, 0.15, 1.45, 18, Color(edge, alpha * 0.55), 1.4, true)

static func hatch(c: CanvasItem, center: Vector2, width: float, height: float, color: Color, count := 5) -> void:
	for index in range(count):
		var offset := float(index) / maxf(count - 1, 1)
		var start := center + Vector2(-width * 0.5 + offset * width, sin(index * 2.1) * height * 0.12)
		c.draw_line(start, start + Vector2(-height * 0.24, -height * (0.64 + 0.25 * sin(index * 3.7))), color, 1.3 + (index % 2) * 0.6, true)

static func bolt(c: CanvasItem, center: Vector2, radius: float, metal: Color, edge: Color, light: Color) -> void:
	disc(c, center, radius, metal, edge, light)
	c.draw_line(center + Vector2(-radius * 0.48, radius * 0.12), center + Vector2(radius * 0.48, -radius * 0.12), edge, maxf(radius * 0.20, 1.0), true)
