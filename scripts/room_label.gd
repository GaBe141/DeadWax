extends "res://scripts/room_base.gd"
## STRATUM 1 — THE LABEL
## Played out. Dry: your strike only speaks to live grooves.
## Teaches: groove launches, dead-air gaps, wall-groove zigzags, ON BEAT.
## Hides: one unsigned groove-lock. If you know the count-in, you know.

const DoorScript := preload("res://scripts/refrain_door.gd")

func _init() -> void:
	band_name = "THE LABEL"
	band_desc = "Played out. Dry — your strike only speaks to live grooves."
	air_density = 0.0
	air_strikes_max = 0
	gravity_mult = 1.0
	fall_cap_mult = 1.0
	groove_mult = 1.0
	bg_color = Color(0.87, 0.85, 0.79)   # label paper
	ink = Color(0.16, 0.15, 0.14)        # print ink
	spawn_pos = Vector2(160, 500)
	death_y = 1000.0
	cam_limits = Rect2(-200, -1200, 3900, 2500)

func _ready() -> void:
	# spawn shelf
	platform(Vector2(500, 610), Vector2(900, 60))
	sign_label(Vector2(70, 400), "the song played through here\nlong ago. nothing answers.\n(almost.)")

	# lesson 1: stand on a live groove, strike, go up
	groove(Vector2(760, 552))
	sign_label(Vector2(620, 420), "a LIVE groove — still hot.\nstand close. STRIKE. [J]")
	platform(Vector2(900, 380), Vector2(260, 36))

	# lesson 2: spent-wax gap + buoy groove
	platform(Vector2(1180, 300), Vector2(200, 30))
	sign_label(Vector2(1100, 180), "spent wax ahead.\nyour strike dies alone out there.\nfall toward the hot patch. strike near it.")
	platform(Vector2(1560, 520), Vector2(60, 240))
	groove(Vector2(1560, 400))
	platform(Vector2(1980, 560), Vector2(400, 60))

	# the unsigned groove-lock: no hint here. that's the point.
	var door := DoorScript.new()
	door.position = Vector2(2193, 480)
	add_child(door)
	platform(Vector2(2100, 560), Vector2(240, 60))
	platform(Vector2(2400, 560), Vector2(360, 60))
	sign_label(Vector2(2300, 470), "you knew.\nthat's the whole game.")
	patch(Vector2(2440, 510))

	# lesson 3: the shaft — wall grooves, zigzag up
	sign_label(Vector2(1900, 430), "the shaft. strike as you rise\npast each hot patch — it flings you on.")
	platform(Vector2(2245, 100), Vector2(30, 340))
	platform(Vector2(2575, 60), Vector2(30, 980))
	groove(Vector2(2510, 360))
	groove(Vector2(2310, 120))
	groove(Vector2(2510, -120))
	platform(Vector2(2380, -260), Vector2(280, 30))

	# lesson 4: the loop plateau — ON BEAT
	platform(Vector2(2900, -240), Vector2(700, 40))
	groove(Vector2(2900, -288))
	sign_label(Vector2(2660, -420), "strike the groove. watch its loop\ncome back around. STRIKE AGAIN as it lands:\nON BEAT. it carries you further.")
	platform(Vector2(2900, -800), Vector2(220, 30))
	sign_label(Vector2(2810, -880), "x_X  you're getting it.\n[TAB] — the practice room.")
