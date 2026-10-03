extends "res://scripts/test_pressing.gd"
## A disposable Palace elite. Its guard and landing are committed before the
## tell, so crossing its back or turning for its vault has an honest payoff.

const FRONT_TELL := 0.70
const CROSS_TELL := 0.85
const LEAP_DURATION := 0.56
const LEAP_HEIGHT := 160.0
const LANDING_WINDUP := 0.24
const SWING_CONTACT_TIME := 0.12
const OPENING_DURATION := 1.0
const CROSS_LANDING_OFFSET := 90.0
const BOUND_MARGIN := 24.0
const IDLE_DELAY := 0.35
const APPROACH_SPEED := 86.0
const BLOCKED_FLASH_TIME := 0.18
const DEFEAT_SETTLE_TIME := 0.45
const FOOT_OFFSET := Vector2(0.0, 43.0)

var arena_bounds := Rect2(660.0, 200.0, 1240.0, 420.0)
var ink := Color("26221e")
var stock := Color("e8e0cc")
var reduced_motion := false
var _phase: StringName = &"idle"
var _mode: StringName = &"front"
var _phase_time := 0.0
var _blocked_time := 0.0
var _attack_face := -1.0
var _takeoff_face := -1.0
var _next_cross := true
var _interrupted := false
var _takeoff_world := Vector2.ZERO
var _landing_world := Vector2.ZERO
var _captured_player := Vector2.ZERO
var _home := Vector2.ZERO
var _home_set := false

func _ready() -> void:
	super._ready()
	# The parent's idle-frame combat must not run alongside these physics ticks.
	set_process(false)
	_home = global_position
	_home_set = true
	_takeoff_world = _home
	_landing_world = _home
	z_index = 9

func _process(_delta: float) -> void:
	pass

func _find_player() -> Node2D:
	if not is_instance_valid(_player) and is_inside_tree():
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player

func _physics_process(delta: float) -> void:
	if delta <= 0.0 or not is_inside_tree() or get_tree().paused:
		return
	if state == S.DOWN:
		_phase_time = minf(_phase_time + delta, DEFEAT_SETTLE_TIME)
		_t = _phase_time
		queue_redraw()
		return
	if not reduced_motion:
		_advance_print(delta)
	_blocked_time = maxf(_blocked_time - delta, 0.0)
	resonance = maxf(resonance - RES_DECAY * delta, 0.0)
	var player := _find_player()
	if player == null:
		return
	_phase_time += delta
	_t = _phase_time
	match _phase:
		&"idle":
			var horizontal := player.global_position.x - global_position.x
			if absf(horizontal) > 1.0:
				_face = signf(horizontal)
			var distance := global_position.distance_to(player.global_position)
			if distance < ATTACK_RANGE and _phase_time >= IDLE_DELAY:
				_begin_attack()
			elif distance < HEAR_RANGE and absf(horizontal) > ATTACK_RANGE * 0.85:
				global_position.x = clampf(global_position.x + _face * APPROACH_SPEED * delta,
					arena_bounds.position.x + BOUND_MARGIN, arena_bounds.end.x - BOUND_MARGIN)
		&"tell":
			var duration := CROSS_TELL if _mode == &"cross" else FRONT_TELL
			var count := mini(int(_phase_time / (duration / 3.0)), 3)
			if count > _count:
				_count = count
				var bank := _bank()
				if bank != null: bank.play("tick", -8.0, 1.0 + 0.06 * count)
			if _phase_time >= duration:
				if _mode == &"cross": _enter_phase(&"leap")
				else: _begin_swing()
		&"leap":
			var progress := clampf(_phase_time / LEAP_DURATION, 0.0, 1.0)
			# This moves the real actor origin along one captured, continuous arc.
			# It is neither a draw impulse nor an attack hitbox while airborne.
			global_position = _takeoff_world.lerp(_landing_world, progress) + Vector2.UP * sin(progress * PI) * LEAP_HEIGHT
			if progress >= 1.0:
				global_position = _landing_world
				_face = _attack_face
				_enter_phase(&"open" if _interrupted else &"landing")
		&"landing":
			if _phase_time >= LANDING_WINDUP: _begin_swing()
		&"swing":
			if _phase_time >= SWING_CONTACT_TIME: _resolve_swing(global_position.distance_to(player.global_position))
		&"open":
			if _phase_time >= OPENING_DURATION: _enter_phase(&"idle")
	queue_redraw()

func _enter_phase(next_phase: StringName) -> void:
	_phase = next_phase
	_phase_time = 0.0
	_t = 0.0
	match _phase:
		&"idle": state = S.ALERT
		&"tell", &"leap", &"landing": state = S.COUNTING
		&"swing": state = S.SWING
		&"open": state = S.STAGGER
		&"down": state = S.DOWN
	queue_redraw()

func _begin_attack() -> void:
	var player := _find_player()
	if player == null or state == S.DOWN:
		return
	_captured_player = player.global_position
	_takeoff_world = global_position
	_takeoff_face = signf(_captured_player.x - _takeoff_world.x)
	if _takeoff_face == 0.0: _takeoff_face = _face
	_face = _takeoff_face
	_attack_face = _takeoff_face
	_landing_world = _takeoff_world
	_mode = &"front"
	_interrupted = false
	_blocked_time = 0.0
	_count = 0
	if _next_cross:
		var destination := Vector2(_captured_player.x + _takeoff_face * CROSS_LANDING_OFFSET, _takeoff_world.y)
		var left := arena_bounds.position.x + BOUND_MARGIN
		var right := arena_bounds.end.x - BOUND_MARGIN
		# Clamping would turn an advertised crossover into a same-side strike.
		# An invalid far-side landing uses the complete front tell instead.
		if destination.x >= left and destination.x <= right and (_captured_player.x - _takeoff_world.x) * (destination.x - _captured_player.x) > 0.0:
			_mode = &"cross"
			_landing_world = destination
			_attack_face = -_takeoff_face
	_next_cross = not _next_cross
	_enter_phase(&"tell")

func _begin_swing() -> void:
	_enter_phase(&"swing")
	var bank := _bank()
	if bank != null: bank.play("swing", -6.0)

func _player_strike_points_here(pos: Vector2) -> bool:
	var player := _find_player()
	if player == null or not player.has_method("executed_strike_facing"):
		return false
	var strike_face: float = player.call("executed_strike_facing")
	return absf(strike_face) > 0.5 and (global_position.x - pos.x) * strike_face >= 0.0

func _guarded() -> bool:
	return not _interrupted and _phase in [&"tell", &"leap", &"landing", &"swing"]

func _from_rear(pos: Vector2) -> bool:
	return (pos.x - global_position.x) * _face < -1.0

func is_pogoable() -> bool:
	if muted or state == S.DOWN:
		return false
	var player := _find_player()
	if player == null or not _player_strike_points_here(player.global_position):
		return false
	return not _guarded() or _from_rear(player.global_position)

func on_player_strike(pos: Vector2, big: bool) -> StringName:
	if state == S.DOWN or global_position.distance_to(pos) > STRIKE_HIT_RANGE or not _player_strike_points_here(pos):
		return &"ignored"
	if _guarded() and not _from_rear(pos):
		_blocked_time = 0.0 if reduced_motion else BLOCKED_FLASH_TIME
		queue_redraw()
		return &"guard"
	var breaks_guard := _guarded() and _from_rear(pos)
	var receipt := super.on_player_strike(pos, big)
	if state != S.DOWN and receipt == &"hit" and breaks_guard:
		_interrupted = true
		_blocked_time = 0.0
		if _phase != &"leap": _enter_phase(&"open")
	queue_redraw()
	return receipt

func _resolve_swing(distance: float) -> void:
	if state == S.DOWN or _phase != &"swing":
		return
	_print_swing_tail = 0.0 if reduced_motion else 1.0
	var player := _find_player()
	var bank := _bank()
	# The swing occupies only the committed side. Crossing its rear or moving
	# out of reach yields the same full punish window as a successful catch.
	if player != null and distance <= HIT_RANGE + 20.0 and (player.global_position.x - global_position.x) * _face >= 0.0:
		var since_strike: int = Time.get_ticks_msec() - player.last_strike_ms
		if since_strike >= 0 and since_strike <= PARRY_WINDOW_MS and _player_strike_points_here(player.global_position):
			_print_recoil = 0.0 if reduced_motion else 1.0
			parry_count += 1
			_enter_phase(&"open")
			parried.emit()
			if bank != null: bank.play("parry", -3.0)
			if muted:
				if parry_count >= 3:
					parry_count = 0
					_down(false)
					bout_won.emit()
				return
			_gain(RES_PARRY)
			return
		player.take_hit(global_position)
		if bank != null: bank.play("thud", -5.0)
	_enter_phase(&"open")
	_blocked_time = 0.0

func _down(spill: bool) -> void:
	if state == S.DOWN:
		return
	_phase = &"down"
	_phase_time = 0.0
	_blocked_time = 0.0
	super._down(spill)
	remove_from_group("strikable")
	remove_from_group("hears_strikes")
	queue_redraw()

func reset_attempt() -> void:
	if state == S.DOWN:
		return
	if _home_set: global_position = _home
	hp = HP_MAX
	resonance = 0.0
	parry_count = 0
	_face = -1.0
	_takeoff_face = _face
	_attack_face = _face
	_takeoff_world = global_position
	_landing_world = global_position
	_captured_player = Vector2.ZERO
	_next_cross = true
	_interrupted = false
	_mode = &"front"
	_count = 0
	_blocked_time = 0.0
	_print_time = 0.0
	_print_recoil = 0.0
	_print_swing_tail = 0.0
	_enter_phase(&"idle")

func encounter_snapshot() -> Dictionary:
	var duration := IDLE_DELAY
	match _phase:
		&"tell": duration = CROSS_TELL if _mode == &"cross" else FRONT_TELL
		&"leap": duration = LEAP_DURATION
		&"landing": duration = LANDING_WINDUP
		&"swing": duration = SWING_CONTACT_TIME
		&"open": duration = OPENING_DURATION
		&"down": duration = DEFEAT_SETTLE_TIME
	return {
		"phase": _phase, "mode": _mode, "face": _face, "attack_face": _attack_face,
		"guard": _guarded(), "interrupted": _interrupted,
		"progress": clampf(_phase_time / duration, 0.0, 1.0),
		"opening_remaining": maxf(OPENING_DURATION - _phase_time, 0.0) if _phase == &"open" else 0.0,
		"opening_duration": OPENING_DURATION, "blocked": _blocked_time / BLOCKED_FLASH_TIME,
		"landing_point": _landing_world - global_position + FOOT_OFFSET,
		"takeoff_point": _takeoff_world - global_position + FOOT_OFFSET,
		"landing_world": _landing_world, "takeoff_world": _takeoff_world,
		"captured_player": _captured_player, "foot_offset": FOOT_OFFSET,
		"body_center": Vector2(0.0, -26.0), "hp": hp, "resonance": resonance,
		"clock": 0.0 if reduced_motion else _print_time, "reduced_motion": reduced_motion,
	}

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		_blocked_time = 0.0
		_print_recoil = 0.0
		_print_swing_tail = 0.0
	queue_redraw()

func _draw() -> void:
	var draw_phase := "calm"
	match _phase:
		&"tell", &"landing": draw_phase = "counting"
		&"swing": draw_phase = "swing"
		&"open": draw_phase = "stagger"
		&"down": draw_phase = "down"
	var duration := CROSS_TELL if _mode == &"cross" else FRONT_TELL
	var pose := {
		"phase": draw_phase, "clock": 0.0 if reduced_motion else _print_time,
		"seed": _sid, "face": _face, "muted": muted,
		"recoil": 0.0 if reduced_motion else _print_recoil,
		"follow_through": 0.0 if reduced_motion else _print_swing_tail,
		"count": _count, "beat": clampf(_phase_time / duration, 0.0, 1.0),
		"swing": clampf(_phase_time / SWING_CONTACT_TIME, 0.0, 1.0),
		"state_time": _phase_time, "reform": 0.0,
		"resonance": resonance, "hp": hp, "hp_total": int(HP_MAX),
	}
	PrintPress.draw_pressing(self, pose, ink, stock, stock, PINK, PrintPress.BRASS)
	var cue := encounter_snapshot()
	cue["body_pose"] = pose
	PrintPress.draw_backcutter_cue(self, cue, ink, stock)
