extends Node2D
## The contact arrives at once; only its quieter echo expands through the air.
## This impression reports a strike and never resolves contact itself.

const Press := preload("res://scripts/press.gd")

var max_r := 150.0
var life := 0.3
var big := false
var hit_radius := 120.0
var ink := Color(0.15, 0.13, 0.12)
var stock := Color(0.92, 0.90, 0.85)
var launched := false

var _t := 0.0
var _sid := 0

func _ready() -> void:
	_sid = randi()
	z_index = 20
	material = Press.unshaded_material()

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	_t += delta
	if _t >= life:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	Press.draw_strike_wave(self, {
		"age": _t, "life": life, "hit_radius": hit_radius, "echo_radius": max_r,
		"big": big, "launched": launched, "seed": _sid,
	}, ink, stock)
