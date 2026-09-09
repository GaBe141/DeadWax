extends Node2D
## Architectural woodcuts used exclusively by the press.

var kind: StringName = &"facade"
var extent := Vector2(400, 400)
var ink := Color(0.14, 0.13, 0.12)
var stock := Color(0.88, 0.85, 0.78)

func _draw() -> void:
	var w := extent.x
	var h := extent.y
	var faded := Color(ink, 0.18)
	var mid := Color(ink, 0.35)
	var base := Vector2(-w / 2.0, h / 2.0)
	match kind:
		&"resting_arm":
			var pivot := Vector2(w * 0.32, -h * 0.27)
			draw_circle(pivot, w * 0.07, mid)
			draw_line(pivot, Vector2(-w * 0.24, -h * 0.10), mid, 15)
			draw_line(Vector2(-w * 0.24, -h * 0.10), Vector2(-w * 0.34, h * 0.28), mid, 12)
			draw_arc(Vector2(-w * 0.34, h * 0.32), w * 0.11, 0.0, PI, 28, mid, 5)
		&"organ", &"overture":
			for i in range(9):
				var length := h * (0.50 + 0.40 * absf(i - 4.0) / 4.0)
				var x := -w * 0.45 + i * w * 0.11
				draw_rect(Rect2(Vector2(x, h * 0.45 - length), Vector2(w * 0.06, length)), faded)
				draw_line(Vector2(x + w * 0.025, h * 0.45 - length), Vector2(x + w * 0.025, h * 0.36), mid, 2)
				draw_rect(Rect2(Vector2(x, h * 0.12), Vector2(w * 0.06, h * 0.05)), mid)
			draw_rect(Rect2(Vector2(-w * 0.49, h * 0.45), Vector2(w * 0.98, h * 0.05)), mid)
		&"column":
			draw_rect(Rect2(Vector2(-w * 0.25, -h * 0.45), Vector2(w * 0.50, h * 0.90)), faded)
			for i in range(5):
				draw_line(Vector2(-w * 0.20 + i * w * 0.10, -h * 0.43), Vector2(-w * 0.20 + i * w * 0.10, h * 0.43), faded, 3)
			for y in [-h * 0.47, h * 0.43]:
				draw_rect(Rect2(Vector2(-w * 0.40, y), Vector2(w * 0.80, h * 0.04)), mid)
		&"counter":
			draw_rect(Rect2(Vector2(-w * 0.47, -h * 0.15), Vector2(w * 0.94, h * 0.64)), faded)
			draw_line(Vector2(-w * 0.5, -h * 0.15), Vector2(w * 0.5, -h * 0.15), mid, 11)
			for i in range(7):
				var x := -w * 0.40 + i * w * 0.12
				draw_rect(Rect2(Vector2(x, -h * 0.44), Vector2(w * 0.075, h * 0.25)), mid)
				draw_line(Vector2(x + w * 0.014, -h * 0.35), Vector2(x + w * 0.055, -h * 0.35), faded, 2)
		&"horn":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-w * 0.10, h * 0.26), Vector2(w * 0.07, h * 0.22),
				Vector2(w * 0.42, -h * 0.34), Vector2(-w * 0.43, -h * 0.46),
			]), faded)
			draw_arc(Vector2(0, -h * 0.34), w * 0.41, PI, TAU, 48, mid, 3.0)
			draw_line(Vector2(-w * 0.1, h * 0.22), Vector2(-w * 0.1, h * 0.48), mid, 14)
			draw_rect(Rect2(Vector2(-w * 0.25, h * 0.44), Vector2(w * 0.5, h * 0.06)), mid)
			for i in range(5):
				draw_line(Vector2(-w * 0.07, h * 0.18), Vector2(lerpf(-w * 0.37, w * 0.36, i / 4.0), -h * 0.32), faded, 2)
		&"headshell":
			draw_rect(Rect2(-extent / 2, extent), faded)
			draw_line(Vector2(-w * 0.43, -h * 0.36), Vector2(w * 0.36, -h * 0.26), mid, 9)
			draw_line(Vector2(w * 0.36, -h * 0.26), Vector2(w * 0.28, h * 0.40), mid, 11)
			for i in range(6):
				draw_rect(Rect2(Vector2(-w * 0.38 + i * w * 0.11, -h * 0.17), Vector2(w * 0.04, h * 0.40)), faded)
		&"arch", &"headstone":
			var radius := w * 0.38
			var crown := Vector2(0, -h * 0.5 + radius)
			draw_arc(crown, radius, PI, TAU, 48, mid, 13)
			for side in [-1.0, 1.0]:
				draw_line(crown + Vector2(side * radius, 0), Vector2(side * radius, h * 0.5), mid, 13)
			if kind == &"headstone":
				for i in range(5):
					draw_line(Vector2(-w * 0.23, i * h * 0.06), Vector2(w * 0.23, i * h * 0.06), faded, 3)
		&"stair":
			for i in range(9):
				var step := Vector2(w / 9, h * (i + 1) / 9)
				draw_rect(Rect2(base + Vector2(i * w / 9, -step.y), step), faded)
				draw_line(base + Vector2(i * w / 9, -step.y), base + Vector2((i + 1) * w / 9, -step.y), mid, 3)
		_:
			draw_rect(Rect2(-extent / 2, extent), faded)
			draw_line(Vector2(-w / 2, -h / 2), Vector2(w / 2, -h / 2), mid, 5)
			for row in range(3):
				for col in range(4):
					var p := Vector2(-w * 0.40 + col * w * 0.23, -h * 0.34 + row * h * 0.27)
					draw_rect(Rect2(p, Vector2(w * 0.10, h * 0.12)), mid)
			if kind == &"market":
				for i in range(10):
					var p := Vector2(-w / 2 + i * w / 10, -h * 0.12)
					draw_rect(Rect2(p, Vector2(w / 10, h * 0.20)), mid if i % 2 == 0 else faded)
	# Uneven engraved hatching anchors every subject to the same print stock.
	for i in range(12):
		var y := h * 0.5 - i * 4.0
		draw_line(Vector2(-w * 0.5, y), Vector2(-w * 0.18 + i * 3.0, y - 4), faded, 1)
