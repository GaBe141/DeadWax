extends "res://scripts/room_base.gd"
## THE VERSE WARREN — first room of the Unplayed. Teaches the Auditioner and
## the SET-mercy exit: every soul here can be freed instead of shattered.
## One idea, one safe room (ENEMIES.md encounter rule). Graybox tuning arena.

const AuditionerScript := preload("res://scripts/auditioner.gd")

func _init() -> void:
	band_name = "THE VERSE — a warren of the Unplayed"
	band_desc = "They reach for you. Break them, or kneel and let them be heard."
	air_density = 0.35             # below the Scratch: the air answers a little
	air_strikes_max = 1
	gravity_mult = 1.0
	fall_cap_mult = 1.0
	groove_mult = 1.0
	bg_color = Color(0.16, 0.15, 0.20)     # darker, thicker than the dry rooms
	ink = Color(0.72, 0.70, 0.66)          # pale scratchboard ink on dark ground
	spawn_pos = Vector2(200, 470)
	death_y = 1200.0
	cam_limits = Rect2(-200, -800, 3400, 2000)

func _ready() -> void:
	platform(Vector2(1400, 600), Vector2(3000, 70))
	platform(Vector2(-70, 300), Vector2(60, 700))

	sign_label(Vector2(90, 320), "the verse.\nnobody down here has ever been heard.\nthey reach for you. it's all they want.")

	# the tell, taught — one lone Auditioner
	sign_label(Vector2(560, 330), "listen: a rising hum, then it reaches.\nSTRIKE [J] the reach to break it,\nor PARRY on the peak — RING IT BACK.")
	_auditioner(Vector2(840, 552))

	# the mercy, taught — kneel and hold
	sign_label(Vector2(1250, 320), "or don't fight it at all.\nKNEEL [hold L] close by, defenseless,\nfor one bar — and it is heard. it goes.")
	_auditioner(Vector2(1520, 552))
	_auditioner(Vector2(1650, 552))

	# the real question — clear space, THEN kneel
	sign_label(Vector2(2150, 320), "three at once.\ncan you make enough quiet\nto be kind?")
	_auditioner(Vector2(2360, 552))
	_auditioner(Vector2(2500, 552))
	_auditioner(Vector2(2640, 552))

	groove(Vector2(1060, 542))     # one groove for spacing / mobility

func _auditioner(pos: Vector2) -> void:
	var a := AuditionerScript.new()
	a.position = pos
	add_child(a)
