extends "res://scripts/room_base.gd"
## An empty floor outside the campaign. No listeners, rewards or exits: Main
## owns entry from the sleeve and return through the pause menu.

var objective_label := "Three fresh strikes: Tap, Sweep, Accent."

func _ready() -> void:
	room_id = &"move_practice"
	band_name = "A blank side"
	band_desc = "Move practice · take your time."
	bg_color = Color(0.88, 0.85, 0.77)
	ink = Color(0.17, 0.16, 0.20)
	cam_limits = Rect2(0, 0, 2560, 720)
	spawn_pos = Vector2(640, 584)
	death_y = 980.0
	platform(Vector2(1280, 670), Vector2(2680, 120))
	platform(Vector2(-30, 240), Vector2(60, 740))
	platform(Vector2(2590, 240), Vector2(60, 740))
