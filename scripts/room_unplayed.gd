extends "res://scripts/room_base.gd"
## STRATUM 3 — THE UNPLAYED (skipping ahead for the physics contrast)
## Below the Scratch. Nothing here was ever played; the pressed sound pools
## thick. Teaches: air jets ("breaths"), steering, amplified groove flings.
## Now also the FLOW course: pogo-pads to chain combat into traversal.

const DummyScript := preload("res://scripts/test_pressing.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")

func _init() -> void:
	room_id = &"unplayed"
	band_name = "THE UNPLAYED"
	band_desc = "Below the Scratch. Never played — the air answers your strike."
	air_density = 1.0
	air_strikes_max = 2
	gravity_mult = 0.8
	fall_cap_mult = 0.62
	groove_mult = 1.3
	bg_color = Color(0.10, 0.085, 0.115)   # wax dark
	ink = Color(0.90, 0.88, 0.84)          # scratchboard white line
	spawn_pos = Vector2(220, 480)
	register_entry(&"from_verse", Vector2(220, 509))
	register_entry(&"from_smoothed", Vector2(2350, -563))
	death_y = 1400.0
	cam_limits = Rect2(-300, -1000, 3500, 2700)

func _ready() -> void:
	# soft bottom — falling here is forgiving; the unplayed catches you
	platform(Vector2(1300, 820), Vector2(2900, 60))
	route_exit(Vector2(70, 760), &"verse", &"from_unplayed", "THE VERSE")

	# spawn island
	platform(Vector2(300, 560), Vector2(360, 50))
	sign_label(Vector2(120, 344), "nothing down here was ever played.\nit has waited. it is THICK.")
	sign_label(Vector2(140, 420), "STRIKE mid-air [J]. steer with held direction.\ntwo breaths, then touch stone.")

	# POGO PADS — strike a foe to recoil off it. combat carries you.
	sign_label(Vector2(120, 496), "the dummies are pogo pads:\nSTRIKE one to bounce off it.\nchain jet -> pogo -> fling. never land.")
	_pad(Vector2(1000, 320))
	_pad(Vector2(1520, 20))
	_pad(Vector2(2060, -180))

	# island hops — one or two breaths each
	platform(Vector2(760, 420), Vector2(220, 36))
	platform(Vector2(1200, 260), Vector2(220, 36))
	platform(Vector2(820, 60), Vector2(200, 30))
	sign_label(Vector2(740, -20), "steer back. the air wants a turn.")
	platform(Vector2(1350, -120), Vector2(240, 32))

	# the loud groove — amplified fling across the void
	sign_label(Vector2(1330, -220), "grooves run HOT down here.")
	groove(Vector2(1750, 40))
	platform(Vector2(2250, -60), Vector2(500, 50))

	# climb out
	groove(Vector2(2560, -240))
	platform(Vector2(2500, -520), Vector2(420, 34))
	refrain_pickup(Vector2(2460, -580), ProgressionScript.Refrain.GATHER)
	sign_label(Vector2(2100, -720), "GATHER what the unplayed taught you.\none breath will follow into dry wax.\nthe runout continues through HUSH.")
	route_exit(
		Vector2(2650, -580),
		&"smoothed",
		&"from_unplayed",
		"SMOOTHED",
		ProgressionScript.Refrain.GATHER,
		"Gather the held breath before you leave."
	)

func _pad(pos: Vector2) -> void:
	var d := DummyScript.new()
	d.position = pos
	add_child(d)
