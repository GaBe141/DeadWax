extends "res://scripts/room_base.gd"
## Disposable combat floors outside the campaign. Main owns health, recovery,
## and returning to the sleeve; the arena owns only its temporary opponents.

const ArenaScript := preload("res://scripts/practice_arena.gd")
const PracticeAtmosphere := preload("res://scripts/practice_atmosphere.gd")

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
	_setup_palace_art()
	arena = ArenaScript.new()
	arena.name = "PracticeArena"
	arena.position = spawn_pos
	arena.arena_bounds = Rect2(660, 200, 1240, 420)
	arena.reink(_solid_color(), _stock_color())
	add_child(arena)

func _setup_palace_art() -> void:
	var surfaces: Array[Rect2] = []
	for index in _skins.size():
		var skin: ColorRect = _skins[index]
		var printed := PressScript.palace_surface(skin.size, _solid_color(), _stock_color(),
			&"floor" if index == 0 else &"stone")
		skin.material = printed.material
		printed.free()
		surfaces.append(Rect2(skin.get_parent().position + skin.position, skin.size))
	atmosphere = PracticeAtmosphere.new()
	atmosphere.name = "Atmosphere"
	atmosphere.call("setup", room_id, cam_limits, _solid_color(), _stock_color(), surfaces)
	add_child(atmosphere)
	lighting = LightingScript.new()
	lighting.name = "Lighting"
	lighting.call("setup", room_id, cam_limits, surfaces)
	lighting.ink = _solid_color()
	lighting.stock = _stock_color()
	add_child(lighting)

func set_actor_impressions(impressions: Array[Dictionary]) -> void:
	if is_instance_valid(atmosphere):
		atmosphere.call("set_actor_impressions", impressions)

func apply_side(next_side: int) -> void:
	super.apply_side(next_side)
	for skin in _skins:
		PressScript.reink_palace_surface(skin, _solid_color(), _stock_color())
	if is_instance_valid(arena): arena.reink(_solid_color(), _stock_color())
