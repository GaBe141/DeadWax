extends RefCounted
## Shared gouache materials. Supplied page colours tune contrast and contours;
## brush marks are deterministic, and no helper owns a clock or scene state.
## In ink (ink_look.gd) the same figures take the page's working inks: black
## line and dark wax on paper, or white line out of wax on scratchboard, so
## every resident, voice and fixture prints in the room's own look.

const InkLook := preload("res://scripts/ink_look.gd")

static func palette(ink: Color, stock: Color) -> Dictionary:
	if InkLook.active:
		return ink_palette(InkLook.scratchboard)
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

## The gouache materials as the ink look prints them. Pink and gold are not
## here: pink is heard sound and gold is her, both from press.gd only.
static func ink_palette(scratchboard: bool) -> Dictionary:
	if scratchboard:
		return {
			"edge": InkLook.GROOVE, "shadow": Color("050407"), "coat": Color("1a1720"),
			"teal": Color("2b2832"), "cream": Color("8d8799"), "light": Color("d9d3c7"),
			"wax": Color("2a2531"), "brass": Color("7a6240"), "gold": Color("8c7a52"),
			"copper": Color("7a4a33"), "coral": Color("5c2b23"), "wood": Color("3a2e25"),
			"rim": Color("4a4258"),
		}
	return {
		"edge": InkLook.LINE, "shadow": Color("17141b"), "coat": Color("17141b"),
		"teal": Color("3a3a44"), "cream": Color("f0e8d4"), "light": InkLook.GROOVE,
		"wax": InkLook.DUST, "brass": InkLook.BRASS, "gold": Color("c9a05a"),
		"copper": Color("b06a42"), "coral": InkLook.CANCEL_RED, "wood": Color("8a6440"),
		"rim": Color("9a8f7a"),
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
	# A short worn edge and a broad underside give the joint weight without
	# turning every limb into a uniformly polished plastic tube.
	c.draw_line(start.lerp(finish, 0.16) - normal * width * 0.24, start.lerp(finish, 0.90) - normal * width * 0.24, Color(edge, fill.a * 0.24), maxf(width * 0.27, 1.0), true)
	c.draw_line(start.lerp(finish, 0.08) + normal * width * 0.23, start.lerp(finish, 0.64) + normal * width * 0.23, Color(highlight, fill.a * 0.48), maxf(width * 0.14, 1.0), true)

static func disc(c: CanvasItem, center: Vector2, radius: float, fill: Color, edge: Color, highlight: Color, alpha := 1.0) -> void:
	c.draw_circle(center, radius + 1.5, Color(edge, alpha), true, -1, true)
	c.draw_circle(center, radius, Color(fill, alpha), true, -1, true)
	var shade := PackedVector2Array([center + Vector2(radius * 0.17, -radius * 0.96)])
	for index in range(19):
		var angle := lerpf(-1.4, 1.7, index / 18.0)
		shade.append(center + Vector2.from_angle(angle) * radius)
	shade.append(center + Vector2(-radius * 0.18, radius * 0.68))
	c.draw_colored_polygon(shade, Color(edge, 0.28 * alpha))
	var edge_width := maxf(radius * 0.065, 1.0)
	c.draw_arc(center + Vector2(0.5, 0.5), radius - 1.5, -2.92, -2.10, 12, Color(highlight, alpha * 0.68), edge_width, true)
	c.draw_arc(center + Vector2(0.5, 0.5), radius - 1.5, -1.89, -1.10, 12, Color(highlight, alpha * 0.46), edge_width, true)
	c.draw_arc(center, radius - 0.8, 0.15, 1.45, 18, Color(edge, alpha * 0.55), 1.4, true)

static func hatch(c: CanvasItem, center: Vector2, width: float, height: float, color: Color, count := 5) -> void:
	for index in range(count):
		var offset := float(index) / maxf(count - 1, 1)
		var start := center + Vector2(-width * 0.5 + offset * width, sin(index * 2.1) * height * 0.12)
		c.draw_line(start, start + Vector2(-height * 0.24, -height * (0.64 + 0.25 * sin(index * 3.7))), color, 1.3 + (index % 2) * 0.6, true)

static func bolt(c: CanvasItem, center: Vector2, radius: float, metal: Color, edge: Color, light: Color) -> void:
	disc(c, center, radius, metal, edge, light)
	c.draw_line(center + Vector2(-radius * 0.48, radius * 0.12), center + Vector2(radius * 0.48, -radius * 0.12), edge, maxf(radius * 0.20, 1.0), true)
