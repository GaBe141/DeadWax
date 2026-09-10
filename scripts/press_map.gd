extends RefCounted
## A folded route guide and the little sheet found in the Headshell.
## Geometry and names are authored data; no factory, save, or gameplay state.

const Chart := preload("res://scripts/campaign_chart.gd")
const PINK := Color("e1b36f")

static func draw_chart(canvas: CanvasItem, size: Vector2, pose: Dictionary, ink: Color,
		stock: Color, font: Font, display: Font) -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	# Three panels carry faint fold shadows, with the print crossing their seams.
	canvas.draw_rect(Rect2(Vector2.ZERO, size), stock.lerp(ink, 0.025))
	# Faint surveyed relief gives the guide depth without inventing a route.
	for band in range(15):
		var contour := PackedVector2Array()
		for sample in range(51):
			var x := float(sample) / 50.0 * size.x
			var y := size.y * (0.12 + band * 0.053) + sin(x * 0.009 + band * 0.4) * 14 + cos(x * 0.017 - band * 0.6) * 6
			contour.append(Vector2(x, clampf(y, 5, size.y - 5)))
		canvas.draw_polyline(contour, Color(PINK, 0.055), 1.0, true)
	for index in 3:
		var x := size.x * float(index) / 3.0
		canvas.draw_rect(Rect2(x, 0, size.x / 3.0, size.y), Color(ink, 0.012 if index == 1 else 0.025))
		if index > 0:
			canvas.draw_line(Vector2(x - 1, 0), Vector2(x - 1, size.y), Color(ink, 0.10), 1.0)
			canvas.draw_line(Vector2(x + 1, 0), Vector2(x + 1, size.y), Color(stock, 0.8), 2.0)
	canvas.draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2.0), Color(ink, 0.20), false, 1.0)
	var scale := minf((size.x - 28.0) / Chart.EXTENT.x, (size.y - 24.0) / Chart.EXTENT.y)
	if scale <= 0.0:
		return
	canvas.draw_set_transform((size - Chart.EXTENT * scale) * 0.5, 0.0, Vector2.ONE * scale)
	var current := StringName(pose.get("current_room", ""))
	var region := StringName(pose.get("region", Chart.region_for_room(current)))
	var page := Chart.page_snapshot(region, pose.get("visited", []), current)
	# The shortcut is always dashed: this guide does not claim a gate is open.
	for link in page.links:
		var from: Vector2 = link.from
		var to: Vector2 = link.to
		var walked := bool(link.walked)
		var color := Color(PINK if walked else ink, 0.82 if walked else 0.20)
		if bool(link.shortcut):
			canvas.draw_dashed_line(from, to, color, 2.0, 7.0, true, true)
		else:
			canvas.draw_line(from, to, color, 3.0 if walked else 2.0, true)
	# Border stubs name printed regions, never unreached rooms or a claimed unlock.
	for boundary in page.boundaries:
		var center: Vector2 = boundary.position
		var marker := Rect2(center - Vector2(99, 15), Vector2(198, 30))
		canvas.draw_rect(marker, stock)
		canvas.draw_line(marker.position + Vector2(10, 2), Vector2(marker.end.x - 10, marker.position.y + 2), Color(PINK, 0.35), 1.0, true)
		canvas.draw_string(display, center + Vector2(-99, 9), String(boundary.title),
			HORIZONTAL_ALIGNMENT_CENTER, 198, 24, Color(ink, 0.75 if boundary.visited else 0.45))
	for room in page.rooms:
		var center: Vector2 = room.position
		var box := Rect2(center - Chart.ROOM_SIZE * 0.5, Chart.ROOM_SIZE)
		var visited := bool(room.visited)
		var here := bool(room.here)
		var fill := ink if here else stock.lerp(ink, 0.06 if visited else 0.025)
		canvas.draw_rect(Rect2(box.position + Vector2(3, 4), box.size), Color("06181d", 0.42))
		canvas.draw_rect(box, fill)
		canvas.draw_rect(box, PINK if here else Color(ink, 0.70 if visited else 0.18), false, 2.5 if here else 1.5)
		if visited and not here:
			canvas.draw_line(box.position + Vector2(3, 3), Vector2(box.end.x - 3, box.position.y + 3), Color(PINK, 0.35), 1.0, true)
		# Corner scoring gives an unopened place a shape without giving it a name.
		if not visited:
			canvas.draw_line(box.position + Vector2(7, 7), box.position + Vector2(26, 7), Color(ink, 0.13), 1.0)
			canvas.draw_line(box.end - Vector2(7, 7), box.end - Vector2(26, 7), Color(ink, 0.13), 1.0)
		else:
			var lines := String(room.title).split("\n")
			var baseline := center.y - float(lines.size() - 1) * 12.0 + 7.0
			for index in lines.size():
				canvas.draw_string(font, Vector2(box.position.x + 4.0, baseline + index * 24.0),
					lines[index], HORIZONTAL_ALIGNMENT_CENTER, box.size.x - 8.0, 20, stock if here else ink)
		if here:
			var clock := float(pose.get("clock", 0.0))
			var glow := 0.80 if bool(pose.get("reduced_motion", false)) else 0.80 + sin(clock * 2.8) * 0.13
			var mark := center + Vector2(0, -Chart.ROOM_SIZE.y * 0.5 - 13.0)
			canvas.draw_circle(mark, 5.0, PINK, true, -1.0, true)
			canvas.draw_arc(mark, 9.0, 0, TAU, 28, Color(PINK, glow), 1.5, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_pickup(canvas: CanvasItem, pose: Dictionary, ink: Color, stock: Color) -> void:
	if bool(pose.get("owned", false)):
		return
	var clock := float(pose.get("clock", 0.0))
	var shift := 0.0 if bool(pose.get("reduced_motion", false)) else sin(clock * 2.0) * 1.6
	canvas.draw_rect(Rect2(-30, 23, 60, 3), ink)
	canvas.draw_line(Vector2(-21, 20), Vector2(22, 20), Color(ink, 0.55), 2.0, true)
	canvas.draw_set_transform(Vector2(0, shift - 4.0))
	canvas.draw_circle(Vector2(0, -2), 36, Color(PINK, 0.045), true, -1, true)
	var panels := [
		PackedVector2Array([Vector2(-26, -19), Vector2(-9, -24), Vector2(-9, 13), Vector2(-26, 18)]),
		PackedVector2Array([Vector2(-9, -24), Vector2(9, -18), Vector2(9, 20), Vector2(-9, 13)]),
		PackedVector2Array([Vector2(9, -18), Vector2(26, -23), Vector2(26, 14), Vector2(9, 20)]),
	]
	for index in panels.size():
		canvas.draw_colored_polygon(panels[index], stock.lerp(ink, 0.09 if index == 1 else 0.015))
		var outline: PackedVector2Array = panels[index].duplicate()
		outline.append(outline[0])
		canvas.draw_polyline(outline, ink, 2.0, true)
	var route := PackedVector2Array([Vector2(-20, -9), Vector2(-13, -11), Vector2(-4, -5), Vector2(5, -5), Vector2(15, 5), Vector2(21, 3)])
	canvas.draw_polyline(route, Color(ink, 0.70), 1.5, true)
	for dot in [Vector2(-20, -9), Vector2(-4, -5), Vector2(21, 3)]:
		canvas.draw_circle(dot, 2.2, ink, true, -1.0, true)
	canvas.draw_circle(Vector2(15, 5), 3.0, PINK, true, -1.0, true)
	if bool(pose.get("near", false)):
		canvas.draw_line(Vector2(-19, 9), Vector2(-12, 7), PINK, 2.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
