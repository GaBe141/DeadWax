extends Node2D
## A strike made visible — scribbly expanding rings.
## Spent wax chokes them small; unplayed air lets them bloom.

var max_r := 150.0
var life := 0.3
var big := false

var _t := 0.0
var _sid := 0

func _ready() -> void:
	_sid = randi()
	z_index = 20

func _process(delta: float) -> void:
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := _t / life
	var r := max_r * (0.25 + 0.75 * k)
	var a := 1.0 - k
	var col := Color(0.95, 0.25, 0.55, a) if big else Color(0.15, 0.13, 0.12, a)
	_scribble_circle(r, col, 5.0 if big else 3.0)
	_scribble_circle(r * 0.68, Color(col.r, col.g, col.b, a * 0.45), 2.0)

func _scribble_circle(r: float, col: Color, w: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _sid + int(_t * 10.0) * 977
	var pts := PackedVector2Array()
	var n := 26
	for i in range(n + 1):
		var ang := TAU * float(i) / float(n)
		var rr := r + rng.randf_range(-r * 0.06 - 1.5, r * 0.06 + 1.5)
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
	draw_polyline(pts, col, w)
