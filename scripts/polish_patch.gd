extends Node2D
## DULL WAX — a patch worn grey. Hood up (hold LIFT) beside it to buff the
## shine back in. Restores a small sound; mints one shine.

const RADIUS := 70.0
const POLISH_TIME := 1.2

var progress := 0.0
var done := false
var _sid := 0
var _sparkle := 0.0

func _ready() -> void:
	_sid = randi()
	z_index = 4

func _process(delta: float) -> void:
	if done:
		_sparkle = maxf(_sparkle - delta, 0.0)
		if _sparkle > 0.0:
			queue_redraw()
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.hooded and global_position.distance_to(player.global_position) < RADIUS:
		progress += delta / POLISH_TIME
		if progress >= 1.0:
			done = true
			_sparkle = 0.9
			player.shine += 1
			var bank := get_tree().get_first_node_in_group("audio_bank")
			if bank != null:
				bank.play("polish", -6.0)
	else:
		progress = maxf(progress - delta * 0.4, 0.0)
	queue_redraw()

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _sid + int(Time.get_ticks_msec() / 100)
	if done:
		# buffed: a faint bright ring, plus sparkles while fresh
		draw_arc(Vector2.ZERO, 26.0, 0, TAU, 24, Color(0.97, 0.95, 0.88, 0.8), 2.5)
		if _sparkle > 0.0:
			for i in range(5):
				var p := Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))
				draw_line(p - Vector2(4, 0), p + Vector2(4, 0), Color(0.95, 0.85, 0.45, _sparkle), 1.5)
				draw_line(p - Vector2(0, 4), p + Vector2(0, 4), Color(0.95, 0.85, 0.45, _sparkle), 1.5)
		return
	# dull blotch: grey scribble
	var col := Color(0.5, 0.48, 0.46, 0.55)
	for i in range(4):
		var r := 22.0 + i * 4.0 + rng.randf_range(-2, 2)
		draw_arc(Vector2.ZERO, r, rng.randf_range(0, TAU), rng.randf_range(2.0, 5.5), 14, col, 2.0)
	if progress > 0.0:
		draw_arc(Vector2.ZERO, 34.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 24, Color(0.90, 0.25, 0.50, 0.9), 3.0)
