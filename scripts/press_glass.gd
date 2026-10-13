extends RefCounted
## A shop's display glass in its brass frame, and what is left of it. Pure
## drawing from an explicit snapshot: no state, no clock of its own.
const Brush := preload("res://scripts/press_world_brush.gd")
const Paint := preload("res://scripts/figure_paint.gd")

static func draw(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color, brass: Color, cream: Color) -> void:
	var size: Vector2 = pose.get("size", Vector2(26, 150))
	var half := size / 2.0
	var open := bool(pose.get("open", false))
	var bounce := clampf(float(pose.get("bounce", 0.0)), 0.0, 1.0)
	var shards := clampf(float(pose.get("shards", 0.0)), 0.0, 1.0)
	var hits := int(pose.get("hits", 0))
	var seed := int(pose.get("seed", 0))
	var p := Brush.palette(ink, stock)
	var paint := Paint.palette(ink, stock)
	var glass := Color(paint.light, 0.16)
	var sheen := Color(paint.light, 0.55)
	var frame := brass.lerp(ink, 0.25)
	# The frame: a sill, a lintel and two uprights with worn brass edges.
	c.draw_rect(Rect2(-half.x - 9, half.y - 3, size.x + 18, 10), paint.wood)
	c.draw_line(Vector2(-half.x - 9, half.y - 2), Vector2(half.x + 9, half.y - 2), frame, 2.0, true)
	c.draw_rect(Rect2(-half.x - 9, -half.y - 8, size.x + 18, 8), paint.wood)
	c.draw_line(Vector2(-half.x - 9, -half.y - 1), Vector2(half.x + 9, -half.y - 1), frame, 2.0, true)
	for side: float in [-1.0, 1.0]:
		var x := side * (half.x + 4)
		c.draw_line(Vector2(x, -half.y - 4), Vector2(x, half.y), paint.wood, 7.0, true)
		c.draw_line(Vector2(x - side * 2.5, -half.y - 2), Vector2(x - side * 2.5, half.y - 2), frame, 1.6, true)
	if not open:
		# A whole pane. The sheen leans with each bounce; chips mark the
		# strokes that only clacked against it.
		var lean := sin(bounce * PI) * 4.0
		var pane := PackedVector2Array([Vector2(-half.x + lean, -half.y), Vector2(half.x + lean, -half.y),
			Vector2(half.x, half.y - 4), Vector2(-half.x, half.y - 4)])
		c.draw_colored_polygon(pane, glass)
		c.draw_polyline(PackedVector2Array([Vector2(-half.x + 4 + lean * 0.5, -half.y + 10),
			Vector2(-half.x + 4 + lean * 0.5, half.y - 42)]), sheen, 2.2, true)
		c.draw_polyline(PackedVector2Array([Vector2(half.x - 6 + lean * 0.3, -half.y + 36),
			Vector2(half.x - 6 + lean * 0.3, -half.y + 70)]), Color(paint.light, 0.32), 1.4, true)
		c.draw_line(Vector2(-half.x + lean, -half.y), Vector2(half.x + lean, -half.y), Color(paint.light, 0.7), 1.2, true)
		for chip in range(mini(hits, 6)):
			var at := Vector2(-half.x + 6 + Brush.grain(seed + chip * 3) * (size.x - 12),
				-half.y + 20 + Brush.grain(seed + chip * 5 + 1) * (size.y - 40))
			c.draw_line(at, at + Vector2(3, -4), Color(paint.light, 0.75), 1.2, true)
			c.draw_line(at, at + Vector2(-2, 3), Color(paint.light, 0.55), 1.0, true)
		if bounce > 0.0:
			# The whole sheet rings dully for a moment.
			c.draw_rect(Rect2(-half.x, -half.y, size.x, size.y - 4), Color(paint.light, 0.18 * bounce))
		return
	# Broken: jagged teeth hang from the lintel and the sill, and for a moment
	# the fallen pieces catch the light on the floor.
	for tooth in range(5):
		var x := -half.x + 2 + tooth * (size.x - 4) / 4.0
		var drop := 6.0 + Brush.grain(seed + tooth * 7) * 22.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, -half.y), Vector2(x + 3, -half.y), Vector2(x + Brush.grain(seed + tooth) * 4 - 2, -half.y + drop)]), Color(paint.light, 0.45))
		var rise := 4.0 + Brush.grain(seed + tooth * 11 + 3) * 16.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x - 3, half.y - 4), Vector2(x + 3, half.y - 4), Vector2(x + Brush.grain(seed + tooth + 5) * 4 - 2, half.y - 4 - rise)]), Color(paint.light, 0.45))
	var scatter := 1.0 - shards
	for shard in range(9):
		var g := Brush.grain(seed + shard * 13)
		var at := Vector2(-26 + g * 68.0 + scatter * 10.0 * (g - 0.5), half.y + 2 - Brush.grain(seed + shard * 17) * 5.0)
		var alpha := 0.6 if shards > 0.0 else 0.28
		c.draw_line(at, at + Vector2(4 + g * 5, -1.5), Color(paint.light, alpha), 1.6, true)
	if shards > 0.0:
		# Pieces still in the air, falling in the first moments.
		for piece in range(7):
			var g := Brush.grain(seed + piece * 19 + 2)
			var fall := (1.0 - shards) * (half.y + 10)
			var at := Vector2(-half.x + g * size.x, -half.y + 16 + g * 80 + fall)
			if at.y > half.y: continue
			c.draw_line(at, at + Vector2(3, 3).rotated(g * TAU), Color(paint.light, 0.7 * shards), 1.8, true)
	c.draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Color(p.edge, 0.5), 1.0, true)
	c.draw_line(Vector2(-half.x, half.y - 4), Vector2(half.x, half.y - 4), Color(cream, 0.35), 1.0, true)
