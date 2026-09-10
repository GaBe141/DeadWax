extends RefCounted
const Paint := preload("res://scripts/figure_paint.gd")
## A state printed beside the face. The supplied count and opening are the
## encounter's real clocks; no ornamental timing can obscure a change of guard.

static func draw(canvas: Node2D, pose: Dictionary, ink: Color, stock: Color, font: Font, type_size: int) -> void:
	var phase := String(pose.get("phase", "idle"))
	if phase == "down":
		return
	var paint := Paint.palette(ink,stock)
	var guarded := phase in ["guard", "swing"]
	var open := phase == "open"
	var blocked := clampf(float(pose.get("blocked", 0.0)), 0.0, 1.0)
	var warm: Color = paint.gold
	var mark := warm if open else ink
	var label := "LOOPER"
	if phase == "guard":
		var count := clampi(int(pose.get("count", 0)), 0, 3)
		label = "GUARD" if count == 0 else "GUARD %d" % count
	elif phase == "swing":
		label = "SWING"
	elif open:
		label = "OPEN"
	var width := maxf(78.0, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, type_size).x + 18.0)
	var card := Rect2(-width / 2.0, -112.0, width, 23.0)
	canvas.draw_rect(card, stock.lerp(ink, 0.055))
	canvas.draw_rect(card,Color(paint.brass,0.65),false,1.0)
	canvas.draw_line(card.position + Vector2(0, card.size.y), card.end, Color(mark, 0.70), 1.4, true)
	canvas.draw_string(font, Vector2(-width / 2.0, -95.0), label, HORIZONTAL_ALIGNMENT_CENTER, width, type_size, ink)
	# The three existing tick marks remain in their own clear band at y-70.
	# Guard brackets sit outside the moving disc and never cover its striking arm.
	if guarded:
		for side in [-1.0, 1.0]:
			var bracket := PackedVector2Array([Vector2(side * 33, -58), Vector2(side * 43, -51),
				Vector2(side * 43, -6), Vector2(side * 33, 1)])
			canvas.draw_polyline(bracket,paint.shadow,7.5+blocked,true)
			canvas.draw_polyline(bracket,paint.brass,4.0+blocked*1.5,true)
			canvas.draw_polyline(bracket,Color(paint.gold,0.7+blocked*0.3),1.3,true)
			Paint.bolt(canvas,Vector2(side*43,-29),2.2,paint.gold,paint.edge,paint.light)
	elif open:
		var duration := maxf(float(pose.get("opening_duration", 1.0)), 0.001)
		var remaining := clampf(float(pose.get("opening_remaining", 0.0)) / duration, 0.0, 1.0)
		canvas.draw_rect(Rect2(-29, -84, 58, 3), ink.lerp(stock, 0.78))
		if remaining > 0.0:
			canvas.draw_rect(Rect2(-29, -84, 58 * remaining, 3), warm)
		for side in [-1.0, 1.0]:
			var bracket := PackedVector2Array([Vector2(side * 44, -53), Vector2(side * 51, -53), Vector2(side * 51, -42)])
			canvas.draw_polyline(bracket, Color(stock, 0.85), 4.5, true)
			canvas.draw_polyline(bracket, Color(warm, 0.95), 2.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
