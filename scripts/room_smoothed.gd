extends "res://scripts/room_base.gd"
## THE SMOOTHED FLOOR — a duel on HUSH's terms.
## He burnished this arena mirror-flat. No live grooves. No resonance.
## Raw hits build nothing here. Only what you catch and play back counts.
## This is what fighting him will feel like: spacing, timing, nothing else.

const DummyScript := preload("res://scripts/test_pressing.gd")

func _init() -> void:
	band_name = "THE SMOOTHED FLOOR"
	band_desc = "His floor. Burnished flat. Your ring means nothing here."
	air_density = 0.0
	air_strikes_max = 0
	gravity_mult = 1.0
	fall_cap_mult = 1.0
	groove_mult = 1.0
	muted = true
	bg_color = Color(0.836, 0.822, 0.856)   # burnished pale
	ink = Color(0.38, 0.36, 0.42)           # everything grey. nothing pink.
	spawn_pos = Vector2(240, 480)
	death_y = 1200.0
	cam_limits = Rect2(-200, -800, 2600, 1800)

func _ready() -> void:
	platform(Vector2(1000, 600), Vector2(2400, 70))
	platform(Vector2(-150, 300), Vector2(60, 700))
	platform(Vector2(2150, 300), Vector2(60, 700))

	sign_label(Vector2(120, 340), "someone smoothed this floor\nby hand. recently. carefully.")
	sign_label(Vector2(620, 300), "resonance will not build here.\nraw hits mean nothing.\nonly what you CATCH and play\nback counts. three rung-backs\nend the bout.")

	var dummy := DummyScript.new()
	dummy.muted = true
	dummy.position = Vector2(1240, 522)
	add_child(dummy)

	sign_label(Vector2(1560, 360), "spacing. timing. nothing else.\n(this is what fighting him\nwill feel like.)")
	sign_label(Vector2(1780, 470), "a note, wedged in the wax:\n\"footwork.\nthe deep is worse.\"\n[TAB] — back to the label.")
