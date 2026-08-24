extends "res://scripts/room_base.gd"
## THE PRACTICE ROOM — M1's new verbs, taught in one flat, kind arena.
## The Test Pressing (resonance + parry + hearing), the signed COUNT-IN door,
## dull wax to polish, one live groove for mobility.

const DummyScript := preload("res://scripts/test_pressing.gd")
const DoorScript := preload("res://scripts/refrain_door.gd")

func _init() -> void:
	room_id = &"practice"
	band_name = "THE PRACTICE ROOM"
	band_desc = "Tick loops here. The dummy counts to four. So can you."
	air_density = 0.0
	air_strikes_max = 0
	gravity_mult = 1.0
	fall_cap_mult = 1.0
	groove_mult = 1.0
	bg_color = Color(0.88, 0.855, 0.80)
	ink = Color(0.17, 0.155, 0.15)
	spawn_pos = Vector2(200, 480)
	register_entry(&"from_label", Vector2(180, 539))
	register_entry(&"from_verse", Vector2(2700, 539))
	death_y = 1200.0
	cam_limits = Rect2(-200, -800, 3400, 2000)

func _ready() -> void:
	# one long kind floor
	platform(Vector2(1400, 600), Vector2(3000, 70))
	platform(Vector2(-70, 300), Vector2(60, 700))   # left wall
	route_exit(Vector2(75, 530), &"label", &"from_practice", "THE LABEL")

	sign_label(Vector2(90, 330), "the practice room.\n\"3... 3... 3...\"\n(nobody has heard the 4 in years.)")

	# -- polishing corner --
	sign_label(Vector2(430, 400), "dull wax, gone grey.\nHOOD UP [hold K] beside it.\nbuff the shine back in.\n(shine buys things, someday.)")
	patch(Vector2(500, 540))
	patch(Vector2(620, 540))
	patch(Vector2(740, 540))

	# -- the hood, explained once --
	sign_label(Vector2(950, 360), "your hood is your silence.\nhooded: slower, softer, deaf to your\nown pink. things stop hearing you.")

	# -- the test pressing --
	var dummy := DummyScript.new()
	dummy.position = Vector2(1560, 522)
	add_child(dummy)
	sign_label(Vector2(1330, 300), "THE TEST PRESSING.\nit hears your crackle. it ticks THREE times.\nit swings on FOUR. strike [J] exactly as\nthe swing lands: RING IT BACK.")
	sign_label(Vector2(1350, 430), "fill its rim with pink — hits, on-beats,\nrung-backs — and it peaks. sorry, dummy.")

	# a groove to play with spacing
	groove(Vector2(1140, 542))

	# -- the signed count-in door --
	var door := DoorScript.new()
	door.position = Vector2(2280, 490)
	add_child(door)
	sign_label(Vector2(2020, 330), "≡ THE COUNT-IN\nfour even strikes. any tempo.\ncount it in. the door has\nalways been listening.")
	sign_label(Vector2(2380, 430), "everything opens for the\nplayer who knows.\nthe verse waits past this bar.")
	patch(Vector2(2520, 540))
	route_exit(Vector2(2800, 530), &"verse", &"from_practice", "THE VERSE")
