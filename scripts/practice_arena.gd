extends Node2D
## A disposable combat run for Move practice. This post owns only its live
## copies and floor counter; Main keeps health, menus and campaign state.

signal floor_started(floor: int)
signal floor_cleared(floor: int)
signal run_completed
signal actor_parried
signal actor_shattered(pos: Vector2)
signal actor_freed(pos: Vector2)

const Press := preload("res://scripts/press.gd")
const EchoTrial := preload("res://scripts/echo_trial.gd")
const Backcutter := preload("res://scripts/backcutter.gd")
const INTERACT_RADIUS := 76.0
const FLOOR_WARNING := 1.2
const SPAWN_CLEARANCE := 220.0
const COPY_SPACING := 130.0
const TOTAL_FLOORS := 20
const FLOOR_ROSTERS := [
	[&"voice"],
	[&"voice", &"voice"],
	[&"pressing"],
	[&"voice", &"pressing"],
	[&"looper"],
	[&"voice", &"looper"],
	[&"pressing", &"pressing"],
	[&"backcutter"],
	[&"pressing", &"looper"],
	[&"voice", &"pressing", &"looper"],
	[&"voice", &"voice", &"backcutter"],
	[&"pressing", &"pressing", &"looper"],
	[&"voice", &"pressing", &"looper", &"voice"],
	[&"pressing", &"pressing", &"voice", &"backcutter"],
	[&"looper", &"looper"],
	[&"voice", &"looper", &"backcutter"],
	[&"pressing", &"looper", &"looper"],
	[&"voice", &"pressing", &"looper", &"backcutter"],
	[&"pressing", &"pressing", &"looper", &"looper"],
	[&"looper", &"backcutter", &"looper", &"pressing"],
]

# The room supplies spawn limits. All copies share its real floor; this node
# contributes no collision, movement permissions or authored room changes.
var arena_bounds := Rect2(660, 200, 1240, 420)
var ink := Color("2b2833")
var stock := Color("e0d9c4")
var _state: StringName = &"idle"
var _floor := 0
var _warning := 0.0
var _clock := 0.0
var _near := false
var _reduced_motion := false
var _copies: Array[Node2D] = []
var _resolved: Dictionary = {}
var _spawn_points: Array[Vector2] = []

func _ready() -> void:
	add_to_group("practice_arena")
	z_index = 4
	queue_redraw()

func _physics_process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused: return
	_near = _player_is_near()
	if _state == &"warning":
		var player := _player()
		if player == null:
			reset_current_floor()
		else:
			_warning = maxf(_warning - delta, 0.0)
			if _warning <= 0.0: _spawn_floor()
	if _near and Input.is_action_just_pressed("enter_passage"):
		try_interact()
	if not _reduced_motion: _clock += delta
	queue_redraw()

func _player() -> CharacterBody2D:
	if not is_inside_tree(): return null
	return get_tree().get_first_node_in_group("player") as CharacterBody2D

func _player_is_near() -> bool:
	var player := _player()
	return player != null and player.is_on_floor() and player.global_position.distance_to(global_position) <= INTERACT_RADIUS

func can_interact() -> bool:
	return is_inside_tree() and not get_tree().paused and _state in [&"idle", &"rest", &"complete"] and _player_is_near()

func try_interact() -> bool:
	if not can_interact(): return false
	var next_floor := 1
	if _state == &"rest": next_floor = _floor + 1
	elif _state == &"idle" and _floor > 0: next_floor = _floor
	var player := _player()
	var points := _plan_spawn_points(next_floor, player.global_position.x)
	if points.size() != FLOOR_ROSTERS[next_floor - 1].size(): return false
	_clear_copies()
	_floor = next_floor
	_state = &"warning"
	_warning = FLOOR_WARNING
	_spawn_points = points
	floor_started.emit(_floor)
	queue_redraw()
	return true

func _plan_spawn_points(floor_number: int, player_x: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if floor_number < 1 or floor_number > TOTAL_FLOORS or arena_bounds.size.x < 48.0:
		return points
	var count: int = FLOOR_ROSTERS[floor_number - 1].size()
	var candidates: Array[float] = []
	var left := arena_bounds.position.x + 24.0
	var right := arena_bounds.end.x - 24.0
	for index in range(49):
		candidates.append(lerpf(left, right, index / 48.0))
	candidates.sort_custom(func(a: float, b: float) -> bool:
		var distance_a := absf(a - player_x)
		var distance_b := absf(b - player_x)
		# Explicit tie-breaking keeps the roster layout reproducible.
		return a < b if is_equal_approx(distance_a, distance_b) else distance_a > distance_b)
	for candidate in candidates:
		if absf(candidate - player_x) < SPAWN_CLEARANCE: continue
		var clear := true
		for point in points:
			if absf(candidate - (global_position.x + point.x)) < COPY_SPACING:
				clear = false
				break
		if not clear: continue
		points.append(Vector2(candidate - global_position.x, 0.0))
		if points.size() == count: break
	return points

func _spawn_floor() -> void:
	if _state != &"warning" or not _copies.is_empty(): return
	var player := _player()
	if player == null:
		reset_current_floor()
		return
	var roster: Array = FLOOR_ROSTERS[_floor - 1]
	if _spawn_points.size() != roster.size():
		# An undersized future arena remains retryable instead of spawning an
		# unfair opponent or completing a floor that was never played.
		reset_current_floor()
		return
	for point in _spawn_points:
		if absf(global_position.x + point.x - player.global_position.x) < SPAWN_CLEARANCE:
			# The marked positions stay fixed for the entire tell. If Skip
			# approaches one, replacement marks get their own complete warning.
			_spawn_points = _plan_spawn_points(_floor, player.global_position.x)
			if _spawn_points.size() != roster.size(): reset_current_floor()
			else: _warning = FLOOR_WARNING
			queue_redraw()
			return
	_state = &"active"
	_warning = 0.0
	for index in roster.size():
		var kind: StringName = roster[index]
		var copy: Node2D
		match kind:
			&"voice":
				copy = EchoTrial.EchoVoice.new()
				copy.left_edge = arena_bounds.position.x + 18.0
				copy.right_edge = arena_bounds.end.x - 18.0
			&"looper": copy = EchoTrial.EchoLooper.new()
			&"backcutter":
				copy = Backcutter.new()
				copy.arena_bounds = arena_bounds
			_: copy = EchoTrial.EchoPressing.new()
		copy.name = "PracticeCopy%d_%d" % [_floor, index]
		copy.add_to_group("practice_arena_actor")
		copy.set_meta("practice_species", kind)
		copy.position = _spawn_points[index] + Vector2(0.0, 13.0 if kind == &"voice" else -17.0)
		copy.reink(ink, stock)
		copy.set_reduced_motion(_reduced_motion)
		copy.parried.connect(func() -> void:
			if _state == &"active" and _copies.has(copy): actor_parried.emit())
		copy.shattered.connect(func(pos: Vector2) -> void: _resolve_copy(copy, &"shattered", pos))
		copy.bout_won.connect(func() -> void: _resolve_copy(copy))
		if copy.has_signal("freed"):
			copy.freed.connect(func(pos: Vector2) -> void: _resolve_copy(copy, &"freed", pos))
		add_child(copy)
		_copies.append(copy)
	_spawn_points.clear()
	queue_redraw()

func _resolve_copy(copy: Node2D, outcome: StringName = &"", pos: Vector2 = Vector2.ZERO) -> void:
	if _state != &"active" or not is_instance_valid(copy) or not _copies.has(copy): return
	var id := copy.get_instance_id()
	if _resolved.has(id): return
	_resolved[id] = true
	_copies.erase(copy)
	_retire_copy(copy)
	var resolved_floor := _floor
	if outcome == &"shattered": actor_shattered.emit(pos)
	elif outcome == &"freed": actor_freed.emit(pos)
	if _state != &"active" or _floor != resolved_floor:
		queue_redraw()
		return
	if _copies.is_empty():
		_state = &"complete" if _floor == TOTAL_FLOORS else &"rest"
		floor_cleared.emit(_floor)
		if _state == &"complete": run_completed.emit()
	queue_redraw()

func _retire_copy(copy: Node2D) -> void:
	if not is_instance_valid(copy): return
	for group in [&"hears_strikes", &"strikable", &"reset_on_recovery", &"practice_arena_actor"]:
		copy.remove_from_group(group)
	copy.set_process(false)
	copy.set_physics_process(false)
	copy.queue_free()

func _clear_copies() -> void:
	for copy in _copies: _retire_copy(copy)
	_copies.clear()
	_resolved.clear()
	_spawn_points.clear()

func reset_current_floor() -> void:
	_clear_copies()
	_state = &"idle"
	_warning = 0.0
	_near = _player_is_near()
	queue_redraw()

func reset_run() -> void:
	reset_current_floor()
	_floor = 0
	queue_redraw()

func cancel_arena() -> void:
	reset_current_floor()

func _exit_tree() -> void:
	# Room replacement removes live listeners before another room is built.
	_clear_copies()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	for copy in _copies:
		if is_instance_valid(copy): copy.reink(ink, stock)
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	for copy in _copies:
		if is_instance_valid(copy): copy.set_reduced_motion(enabled)
	queue_redraw()

func snapshot() -> Dictionary:
	return {
		"phase": _state, "state": _state, "floor": _floor, "total_floors": TOTAL_FLOORS,
		"alive": _copies.size(), "remaining": _copies.size(), "near": _near,
		"warning": _warning, "warning_progress": 1.0 - _warning / FLOOR_WARNING if _state == &"warning" else 0.0,
		"time": 0.0 if _reduced_motion else _clock, "clock": 0.0 if _reduced_motion else _clock,
		"reduced_motion": _reduced_motion, "spawn_points": _spawn_points.duplicate(),
	}

func _draw() -> void:
	Press.draw_practice_arena(self, snapshot(), ink, stock)
