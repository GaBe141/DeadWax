extends Node2D
## DULL WAX — a patch worn grey. Hood up (hold LIFT) beside it to buff the
## shine back in. Restores a small sound; mints one shine.

const Press := preload("res://scripts/press.gd")
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
			if player.has_method("add_shine"):
				if not bool(player.call("add_shine", 1)):
					progress = 1.0
					queue_redraw()
					return
			else:
				player.shine += 1
			done = true
			_sparkle = 0.9
			var bank := get_tree().get_first_node_in_group("audio_bank")
			if bank != null:
				bank.play("polish", -6.0)
	else:
		progress = maxf(progress - delta * 0.4, 0.0)
	queue_redraw()

func _draw() -> void:
	Press.draw_polish(self, {"done": done, "progress": progress, "sparkle": _sparkle})
