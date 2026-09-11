extends RefCounted
## A portable duplicator plays temporary impressions. The caller supplies its
## state and room palette; this plate never reads encounters or rewards.

const BRASS := Color("d6b77c")

static func draw(c: CanvasItem, state: Dictionary, ink: Color, stock: Color) -> void:
	var phase := String(state.get("state", "idle"))
	var clock := float(state.get("clock", 0.0))
	var metal := ink.lerp(stock, 0.27)
	var warm := BRASS.lerp(ink, 0.18)
	var active := phase == "active"
	var claim := phase == "claim"
	c.draw_colored_polygon(PackedVector2Array([Vector2(-46, 24), Vector2(-42, -8), Vector2(43, -8), Vector2(49, 24)]), stock.lerp(ink, 0.12))
	c.draw_polyline(PackedVector2Array([Vector2(-46, 24), Vector2(-42, -8), Vector2(43, -8), Vector2(49, 24)]), metal, 2.5, true)
	c.draw_line(Vector2(-51, 26), Vector2(53, 26), metal, 2.5, true)
	c.draw_rect(Rect2(-35, 1, 69, 13), stock.lerp(ink, 0.20))
	for index in range(4):
		c.draw_line(Vector2(-28 + index * 10, 6), Vector2(-24 + index * 10, 6), Color(ink, 0.50), 1.0, true)
	var reel := Vector2(0, -36)
	c.draw_circle(reel, 33, stock.lerp(ink, 0.12), true, -1.0, true)
	c.draw_arc(reel, 33, 0.0, TAU, 48, warm if active or claim else metal, 2.3, true)
	c.draw_arc(reel, 27, 0.0, TAU, 44, ink.lerp(stock, 0.48), 1.2, true)
	var angle := clock * (1.4 if active else 0.12)
	for index in range(3):
		var p := reel + Vector2.from_angle(angle + index * TAU / 3.0) * 16.0
		c.draw_circle(p, 7.0, stock.lerp(ink, 0.33), true, -1.0, true)
		c.draw_arc(p, 7.0, 0.0, TAU, 20, Color(ink, 0.20), 1.0, true)
	c.draw_circle(reel, 4, warm, true, -1.0, true)
	c.draw_line(Vector2(22, -57), Vector2(40, -68), metal, 3.0, true)
	c.draw_line(Vector2(40, -68), Vector2(49, -33), metal, 3.0, true)
	c.draw_circle(Vector2(49, -33), 5, warm if active else ink.lerp(stock, 0.45), true, -1.0, true)
	# Three lamps describe progress without relying on ambient animation.
	for index in range(3):
		var done := claim or int(state.get("wave", 0)) > index + 1
		var current := active and int(state.get("wave", 0)) == index + 1
		var p := Vector2(-19 + index * 19, 17)
		c.draw_circle(p, 3.5, warm if done or current else stock, true, -1.0, true)
		if current: c.draw_arc(p, 6, 0.0, TAU, 18, warm, 1.0, true)
	if claim:
		# A small stamped sleeve is the claim, never a moving pickup collider.
		c.draw_rect(Rect2(38, -5, 26, 29), ink.lerp(stock, 0.17))
		c.draw_rect(Rect2(38, -5, 26, 29), warm, false, 1.5)
		c.draw_arc(Vector2(51, 8), 7, 0.0, TAU, 24, stock, 1.8, true)
		c.draw_line(Vector2(44, 19), Vector2(58, 19), stock, 1.0, true)
