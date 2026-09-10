extends Control
## Painted surroundings and a tooled journal cover. No clock or interaction:
## the page's existing controls retain their own layout, focus and motion.
const Press := preload("res://scripts/press.gd")
const NIGHT := Color("102c35")
const BRASS := Color("cfa86d")
const CREAM := Color("f0dfb7")
var kind: StringName = &"journal"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x < 1 or size.y < 1: return
	Press.draw_painted_distance(self, &"bootlegger" if kind == &"stall" else &"headshell", Rect2(Vector2.ZERO, size), CREAM, NIGHT)
	draw_rect(Rect2(Vector2.ZERO, size), Color(NIGHT, 0.28 if kind == &"title" else 0.60))
	var rect := Rect2(Vector2(20, 18), size - Vector2(40, 36))
	if kind == &"title" and size.x >= 900:
		rect.size.x = size.x * 0.485
	# Layered glaze follows the page's outer silhouette, never a control's box.
	for index in range(7, 0, -1):
		draw_style_box(_plate(Color("071920"), Color(BRASS, 0.025), 12), rect.grow(index * 1.8))
	draw_style_box(_plate(Color(NIGHT, 0.91 if kind == &"title" else 0.80), Color(BRASS, 0.70), 9), rect)
	draw_style_box(_plate(Color.TRANSPARENT, Color(BRASS, 0.23), 6), rect.grow(-7))
	for row in range(34):
		var y := rect.position.y + rect.size.y * row / 34.0
		var warmth := sin(float(row) / 33.0 * PI)
		draw_line(Vector2(rect.position.x + 12, y), Vector2(rect.end.x - 12, y + 3), Color(CREAM, 0.012 + warmth * 0.012), 5, true)
	# Worn brass corner guards and the sewn edge of the cover.
	for corner in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var inward := Vector2(1 if corner.x < rect.get_center().x else -1, 1 if corner.y < rect.get_center().y else -1)
		draw_line(corner + Vector2(inward.x * 5, inward.y * 4), corner + Vector2(inward.x * 37, inward.y * 4), BRASS, 3, true)
		draw_line(corner + Vector2(inward.x * 4, inward.y * 5), corner + Vector2(inward.x * 4, inward.y * 37), BRASS, 3, true)
		draw_circle(corner + inward * 11, 3.1, BRASS, true, -1, true)
		draw_circle(corner + inward * 10, 1.0, CREAM, true, -1, true)
	for index in range(int(rect.size.y / 19.0)):
		var y := rect.position.y + 44.0 + index * 19.0
		if y > rect.end.y - 35: break
		draw_line(Vector2(rect.position.x + 8, y), Vector2(rect.position.x + 11, y + 5), Color(BRASS, 0.36), 1.0, true)
	if kind != &"title":
		var center := Vector2(size.x * 0.72, size.y * 0.60)
		for radius in [82.0, 113.0, 155.0, 206.0]:
			draw_arc(center, radius, 0.2, 5.5, 100, Color(BRASS, 0.05), 1.0, true)
		for index in range(24):
			var angle := index * TAU / 24.0
			draw_line(center + Vector2.from_angle(angle) * 154, center + Vector2.from_angle(angle) * 163, Color(BRASS, 0.08), 1.2, true)
	# Narrow top and bottom shadows frame the scene without moving the page.
	for index in range(12):
		var alpha := (1.0 - index / 12.0) * 0.065
		draw_rect(Rect2(0, index * 3, size.x, 3), Color("071920", alpha))
		draw_rect(Rect2(0, size.y - (index + 1) * 3, size.x, 3), Color("071920", alpha))

func _plate(fill: Color, line: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = line
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style
