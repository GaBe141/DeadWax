extends RefCounted
## A low brass counter and temporary arrival impressions. Every position,
## phase and progress value belongs to the caller; this drawing owns no arena
## attempt, collision, actor, reward or interaction.

static func draw(c: CanvasItem, pose: Dictionary, ink: Color, stock: Color,
		brass: Color, font: Font, type_size: int) -> void:
	var phase := String(pose.get("phase", "idle"))
	var floor_number := int(pose.get("floor", 0))
	var complete := phase == "complete"
	var engaged := phase in ["warning", "active"]
	# A brass cut must remain readable on either supplied sheet colour.
	var warm := brass.lerp(ink, 0.56 if stock.get_luminance() > 0.45 else 0.16)
	var edge := ink.lerp(stock, 0.42)
	var body := stock.lerp(ink, 0.15)
	# The foot sits on the real platform top, twenty-six pixels below the
	# supplied post origin. It is drawn behind figures, without a solid body.
	c.draw_colored_polygon(PackedVector2Array([Vector2(-35, 26), Vector2(-31, 15),
		Vector2(31, 15), Vector2(35, 26)]), body)
	c.draw_line(Vector2(-37, 26), Vector2(37, 26), edge, 2.0, true)
	c.draw_line(Vector2(-25, 17), Vector2(25, 17), Color(warm, 0.44), 1.0, true)
	c.draw_rect(Rect2(-15, -17, 30, 33), body)
	c.draw_line(Vector2(-15, -15), Vector2(-15, 14), Color(edge, 0.72), 2.0, true)
	c.draw_line(Vector2(15, -15), Vector2(15, 14), Color(edge, 0.72), 2.0, true)
	var dial := Vector2(0, -26)
	c.draw_circle(dial, 27.0, body, true, -1.0, true)
	c.draw_arc(dial, 27.0, -PI * 0.89, PI * 0.92, 48, edge, 2.3, true)
	c.draw_arc(dial, 22.0, -PI * 0.90, PI * 0.90, 40,
		Color(warm, 0.88 if engaged or complete else 0.40), 1.2, true)
	# Twenty quiet cuts form the counter. Progress is a supplied floor, never
	# inferred from a presentation clock or from the positions of enemies.
	var total := maxi(int(pose.get("total_floors", 20)), 1)
	for index in range(total):
		var angle := -PI * 0.88 + float(index) / maxf(float(total - 1), 1.0) * PI * 1.76
		var lit := index < floor_number
		c.draw_line(dial + Vector2.from_angle(angle) * 29.0,
			dial + Vector2.from_angle(angle) * (33.0 if lit else 31.5),
			Color(warm if lit else edge, 0.75 if lit else 0.34), 1.3, true)
	var stamp := "%02d" % floor_number if floor_number > 0 else "—"
	var width := font.get_string_size(stamp, HORIZONTAL_ALIGNMENT_LEFT, -1, type_size).x
	c.draw_string(font, dial + Vector2(-width * 0.5, 4.0), stamp,
		HORIZONTAL_ALIGNMENT_LEFT, -1, type_size, warm if engaged or complete else edge)
	# An inert needle points to the last chosen floor. Decorative breathing is
	# tiny and explicitly frozen under reduced motion; warning cues below are
	# functional and still use the supplied progress in that setting.
	var clock := 0.0 if bool(pose.get("reduced_motion", false)) else float(pose.get("time", 0.0))
	var angle := -PI * 0.85 + float(floor_number) / float(total) * PI * 1.70
	var needle := dial + Vector2.from_angle(angle) * 18.0
	c.draw_line(dial, needle, Color(warm, 0.56), 1.3, true)
	c.draw_circle(dial, 2.0, warm, true, -1.0, true)
	if phase in ["idle", "rest", "complete"]:
		var shine := 0.66 + sin(clock * 0.85) * 0.08
		c.draw_line(Vector2(-31, 5), Vector2(-25, 1), Color(warm, shine), 1.5, true)
		c.draw_line(Vector2(25, 1), Vector2(31, 5), Color(warm, shine), 1.5, true)
	if phase == "warning":
		var progress := clampf(float(pose.get("warning_progress", 0.0)), 0.0, 1.0)
		for point in pose.get("spawn_points", []):
			if point is Vector2:
				_arrival(c, point, progress, ink, stock, warm)

static func _arrival(c: CanvasItem, origin: Vector2, progress: float,
		ink: Color, stock: Color, warm: Color) -> void:
	# The broad oval names the true arrival point. Nothing sweeps across the
	# arena or grows toward the player: both the center and foot remain fixed.
	var floor_center := origin + Vector2(0, 26)
	var ghost := ink.lerp(stock, 0.58)
	c.draw_set_transform(floor_center, 0.0, Vector2(1.0, 0.28))
	c.draw_arc(Vector2.ZERO, 33.0, 0.0, TAU, 40, Color(ghost, 0.68), 1.8, true)
	c.draw_arc(Vector2.ZERO, 29.0, -PI * 0.5, -PI * 0.5 + TAU * progress,
		40, Color(warm, 0.92), 3.0, true)
	c.draw_set_transform(Vector2.ZERO)
	for side in [-1.0, 1.0]:
		var x: float = origin.x + side * 21.0
		c.draw_line(Vector2(x, origin.y + 18), Vector2(x, origin.y - 33),
			Color(ghost, 0.23), 1.0, true)
		c.draw_line(Vector2(x, origin.y + 18),
			Vector2(x, origin.y + 18 - progress * 51.0), Color(warm, 0.55), 1.4, true)
	# One small downward cut remains legible at the end of the warning.
	c.draw_polyline(PackedVector2Array([origin + Vector2(-6, -43),
		origin + Vector2(0, -38), origin + Vector2(6, -43)]), Color(warm, 0.78), 1.6, true)
