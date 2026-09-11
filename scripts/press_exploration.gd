extends RefCounted
## Reverse impressions. Fixed origins and explicit snapshots keep drawing
## independent of traversal, interactions, save state and the record clock.

const BRASS := Color("d6b77c")

static func draw(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	var reward := bool(pose.get("reward", false))
	var opened := bool(pose.get("open", false))
	var revealed := opened or bool(pose.get("far_face", false))
	var center := Vector2(0, -34)
	var accent := BRASS if revealed or reward else ink.lerp(stock, 0.36)
	canvas.draw_line(Vector2(-45, 25), Vector2(45, 25), ink.lerp(stock, 0.4), 3.0, true)
	if reward:
		center.y -= sin(float(pose.get("clock", 0.0)) * 2.0) * 2.0
		canvas.draw_circle(center, 27, stock.lerp(ink, 0.1), true, -1, true)
		for radius in [27, 22, 17]:
			canvas.draw_arc(center, radius, 0, TAU, 48, accent, 1.5, true)
		canvas.draw_circle(center, 5, ink, true, -1, true)
		canvas.draw_line(center + Vector2(-34, 18), center + Vector2(34, -18), ink, 5.0, true)
		canvas.draw_line(center + Vector2(-34, 18), center + Vector2(34, -18), BRASS, 2.0, true)
		return
	canvas.draw_style_box(_arch(ink, stock), Rect2(-43, -94, 86, 116))
	for index in 4:
		canvas.draw_arc(center, 19 + index * 6, -PI * 0.85, PI * 0.85, 40, Color(accent, 0.55), 1.3, true)
	if revealed:
		canvas.draw_line(Vector2(0, -72), Vector2(0, 14), accent, 3.0, true)
		canvas.draw_polyline(PackedVector2Array([Vector2(-17, -37), Vector2(0, -51), Vector2(17, -37)]), accent, 3.0, true)
		canvas.draw_polyline(PackedVector2Array([Vector2(-17, -23), Vector2(0, -9), Vector2(17, -23)]), accent, 3.0, true)
	else:
		for index in 3:
			canvas.draw_line(Vector2(-23, -52 + index * 18), Vector2(23, -38 + index * 18), accent, 3.0, true)
	if bool(pose.get("near", false)):
		canvas.draw_line(Vector2(-51, -32), Vector2(-46, -27), BRASS, 2.0, true)
		canvas.draw_line(Vector2(51, -32), Vector2(46, -27), BRASS, 2.0, true)

static func _arch(ink: Color, stock: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = stock.lerp(ink, 0.09)
	box.border_color = ink.lerp(stock, 0.25)
	box.set_border_width_all(2)
	box.corner_radius_top_left = 38
	box.corner_radius_top_right = 38
	return box
