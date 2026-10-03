extends "res://scripts/room_base.gd"
## Disposable combat floors outside the campaign. Main owns health, recovery,
## and returning to the sleeve; the arena owns only its temporary opponents.

const ArenaScript := preload("res://scripts/practice_arena.gd")

var objective_label := "E / Y at the dial · begin floor 1 of 20."
var arena: Node2D

func _ready() -> void:
	room_id = &"move_practice"
	band_name = "The Wax Palace"
	band_desc = "Combat practice · twenty floors."
	bg_color = Color("182b30")
	ink = Color("b8a47b")
	cam_limits = Rect2(0, 0, 2560, 720)
	spawn_pos = Vector2(1280, 584)
	death_y = 980.0
	platform(Vector2(1280, 670), Vector2(2680, 120))
	platform(Vector2(-30, 240), Vector2(60, 740))
	platform(Vector2(2590, 240), Vector2(60, 740))
	arena = ArenaScript.new()
	arena.name = "PracticeArena"
	arena.position = spawn_pos
	arena.arena_bounds = Rect2(660, 200, 1240, 420)
	arena.reink(_solid_color(), _stock_color())
	add_child(arena)

func apply_side(next_side: int) -> void:
	super.apply_side(next_side)
	if is_instance_valid(arena): arena.reink(_solid_color(), _stock_color())
	queue_redraw()

func _draw() -> void:
	PressScript.draw_painted_distance(self, &"the_arm", cam_limits, _solid_color(), _stock_color())
