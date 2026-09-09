extends Node2D
## A harmless resident of the plaza. Quiet company is the interaction;
## the Hound reads mercy already recorded by Main, and never writes outcomes.

const Press := preload("res://scripts/press.gd")
const PATROL_SPEED := 38.0
const APPROACH_SPEED := 64.0
const STARTLE_SPEED := 115.0
const NOTICE_RANGE := 260.0
const PET_RANGE := 96.0
const PET_DISTANCE := 68.0
const PET_TIME := 1.1
const QUIET_SPEED := 14.0
const QUIET_NOISE := 0.05
const NOTICE_TIME := 0.85
const NOTICE_COOLDOWN := 2.2
const STARTLE_RANGE := 250.0
const STARTLE_TIME := 0.85
const BODY_CLEARANCE := 80.0
const BASE_PATROL_RADIUS := 42.0
const MERCY_RADIUS_STEP := 18.0
const MAX_PATROL_RADIUS := 170.0

enum S { PATROL, NOTICE, APPROACH, SIT, PET, STARTLED }

var state: int = S.PATROL
var session_outcomes: Dictionary = {}
var home_position := Vector2(970, 574)
var patrol_limits := Vector2(620, 1080)
var ink := Color("26221e")
var stock := Color("e8e0cc")
var pet_progress := 0.0
var patrol_radius := BASE_PATROL_RADIUS

var _player: CharacterBody2D
var _visual_time := 0.0
var _state_time := 0.0
var _gait_time := 0.0
var _stride := 0.0
var _sit_blend := 0.0
var _tail_energy := 0.25
var _face := -1.0
var _patrol_direction := -1.0
var _approach_side := 1.0
var _startle_direction := 1.0
var _notice_cooldown := 0.0
var _mercy_scan := 0.0
var _pet_elapsed := 0.0
var _turn_after_notice := false

func _ready() -> void:
	add_to_group("world_resident")
	add_to_group("hears_strikes")
	position = Vector2(_bounded_x(home_position.x), home_position.y)
	_refresh_patrol_radius()
	z_index = 8

func _process(delta: float) -> void:
	if delta <= 0.0 or (is_inside_tree() and get_tree().paused):
		return
	_visual_time += delta
	_state_time += delta
	_notice_cooldown = maxf(_notice_cooldown - delta, 0.0)
	_mercy_scan -= delta
	if _mercy_scan <= 0.0:
		_refresh_patrol_radius()
		_mercy_scan = 0.5
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	var quiet := _quiet_player()
	var distance := global_position.distance_to(_player.global_position) if _player != null else INF
	var before_x := position.x
	if quiet and distance <= NOTICE_RANGE and state in [S.PATROL, S.NOTICE]:
		_approach_side = 1.0 if global_position.x >= _player.global_position.x else -1.0
		_turn_after_notice = false
		_go(S.APPROACH)
	match state:
		S.PATROL:
			var target := _bounded_x(home_position.x + _patrol_direction * patrol_radius)
			_walk_toward(target, PATROL_SPEED, delta)
			if absf(position.x - target) < 1.0:
				_turn_after_notice = true
				_go(S.NOTICE)
			elif distance <= NOTICE_RANGE and _notice_cooldown <= 0.0:
				_turn_after_notice = false
				_face_player()
				_go(S.NOTICE)
		S.NOTICE:
			if distance <= NOTICE_RANGE:
				_face_player()
			if _state_time >= NOTICE_TIME:
				if _turn_after_notice:
					_patrol_direction *= -1.0
				_notice_cooldown = NOTICE_COOLDOWN
				_go(S.PATROL)
		S.APPROACH:
			if not quiet or distance > NOTICE_RANGE * 1.2:
				_stop_listening()
			else:
				var player_local := to_local(_player.global_position) + position
				var target := _bounded_x(player_local.x + _approach_side * PET_DISTANCE)
				_walk_toward(target, APPROACH_SPEED, delta)
				_face_player()
				if absf(position.x - target) < 3.0 and distance <= PET_RANGE:
					_go(S.SIT)
		S.SIT, S.PET:
			_face_player()
			if not quiet or distance > PET_RANGE:
				_stop_listening()
			else:
				_pet_elapsed = minf(_pet_elapsed + delta, PET_TIME)
				pet_progress = _pet_elapsed / PET_TIME
				if state == S.SIT and _pet_elapsed >= PET_TIME:
					_go(S.PET)
		S.STARTLED:
			_walk_toward(position.x + _startle_direction * STARTLE_SPEED * delta, STARTLE_SPEED, delta)
			if _state_time >= STARTLE_TIME:
				_turn_after_notice = false
				_notice_cooldown = NOTICE_COOLDOWN
				_go(S.NOTICE)
	# Vertical footing and the whole ink silhouette stay inside the plaza.
	position.x = _bounded_x(position.x)
	position.y = home_position.y
	var traveled := absf(position.x - before_x)
	_gait_time += traveled * 0.18
	_stride = move_toward(_stride, clampf(traveled / delta / 75.0, 0.0, 1.0), delta * 7.0)
	_sit_blend = move_toward(_sit_blend, 1.0 if state in [S.SIT, S.PET] else 0.0, delta * 3.0)
	var wag := 1.0 if state == S.PET else (0.55 if state in [S.APPROACH, S.SIT] else 0.25)
	_tail_energy = move_toward(_tail_energy, wag, delta * 2.0)
	queue_redraw()

func _quiet_player() -> bool:
	return (
		is_instance_valid(_player) and _player.is_on_floor()
		and _player.get("hooded") == true
		and _player.velocity.length() < QUIET_SPEED
		and float(_player.get("noise")) < QUIET_NOISE
	)

func _refresh_patrol_radius() -> void:
	var mercies := 0
	for outcome in session_outcomes.values():
		if outcome == "freed":
			mercies += 1
	patrol_radius = minf(BASE_PATROL_RADIUS + MERCY_RADIUS_STEP * mercies, MAX_PATROL_RADIUS)

func _bounded_x(value: float) -> float:
	var left := minf(patrol_limits.x, patrol_limits.y) + BODY_CLEARANCE
	var right := maxf(patrol_limits.x, patrol_limits.y) - BODY_CLEARANCE
	if right < left:
		return (patrol_limits.x + patrol_limits.y) * 0.5
	return clampf(value, left, right)

func _walk_toward(target: float, speed: float, delta: float) -> void:
	var difference := target - position.x
	if absf(difference) > 0.5:
		_face = signf(difference)
	position.x = move_toward(position.x, _bounded_x(target), speed * delta)

func _face_player() -> void:
	if _player != null and absf(_player.global_position.x - global_position.x) > 1.0:
		_face = signf(_player.global_position.x - global_position.x)

func _go(next: int) -> void:
	state = next
	_state_time = 0.0

func _stop_listening() -> void:
	_pet_elapsed = 0.0
	pet_progress = 0.0
	_turn_after_notice = false
	_notice_cooldown = NOTICE_COOLDOWN
	_go(S.NOTICE)

func on_player_strike(pos: Vector2, _big: bool) -> void:
	if get_tree().paused or global_position.distance_to(pos) > STARTLE_RANGE:
		return
	_startle_direction = signf(global_position.x - pos.x)
	if is_zero_approx(_startle_direction):
		_startle_direction = -_face
	_pet_elapsed = 0.0
	pet_progress = 0.0
	_go(S.STARTLED)
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	queue_redraw()

func animation_pose() -> Dictionary:
	return {
		"phase": S.keys()[state].to_lower(), "time": _state_time,
		"clock": _visual_time, "gait": _gait_time, "face": _face,
		"speed": _stride, "sit": _sit_blend, "pet": pet_progress,
		"wag": _tail_energy,
	}

func _draw() -> void:
	Press.draw_hound(self, animation_pose(), ink, stock)
