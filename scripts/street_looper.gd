extends "res://scripts/test_pressing.gd"
## The High Street's first opponent keeps its count through stray strikes.
## An opening hit wakes it; every completed swing leaves a full combo opening.

const OPENING_DURATION := 1.0
const SWING_CONTACT_TIME := 0.12
const BLOCKED_FLASH_TIME := 0.18
const DEFEAT_SETTLE_TIME := 0.45

var ink := Color("26221e")
var stock := Color("e8e0cc")
var reduced_motion := false
var _engaged := false
var _blocked_time := 0.0

func _ready() -> void:
	super._ready()
	add_to_group("reset_on_recovery")

func is_pogoable() -> bool:
	return not muted and (state == S.STAGGER or (not _engaged and state in [S.CALM, S.ALERT]))

func _process(delta: float) -> void:
	if delta <= 0.0 or (is_inside_tree() and get_tree().paused):
		return
	if state == S.DOWN:
		# The prototype re-forms. This saved encounter keeps its broken stand.
		if _t < DEFEAT_SETTLE_TIME:
			_t = minf(_t + delta, DEFEAT_SETTLE_TIME)
			queue_redraw()
		return
	_advance_print(delta)
	_blocked_time = maxf(_blocked_time - delta, 0.0)
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var distance := global_position.distance_to(_player.global_position)
	_face = signf(_player.global_position.x - global_position.x)
	if _face == 0.0:
		_face = -1.0
	resonance = maxf(resonance - RES_DECAY * delta, 0.0)
	_t += delta
	match state:
		S.CALM:
			if _player.noise > 0.25 and distance < HEAR_RANGE:
				state = S.ALERT
				_t = 0.0
				var bank := _bank()
				if bank != null: bank.play("alert", -10.0)
		S.ALERT:
			if distance < ATTACK_RANGE:
				_begin_count()
			elif not _engaged and _player.noise < 0.03 and _t > 2.0:
				state = S.CALM
				_t = 0.0
		S.COUNTING:
			# Leaving range is a useful dodge, not a way to cancel the count.
			if _t >= TICK_GAP:
				_t = 0.0
				_count += 1
				var bank := _bank()
				if _count <= 3:
					if bank != null: bank.play("tick", -8.0, 1.0 + 0.06 * _count)
				else:
					state = S.SWING
					if bank != null: bank.play("swing", -6.0)
		S.SWING:
			if _t >= SWING_CONTACT_TIME:
				_resolve_swing(distance)
		S.STAGGER:
			if _t >= OPENING_DURATION:
				if distance < ATTACK_RANGE:
					_begin_count()
				else:
					state = S.ALERT
					_t = 0.0
	queue_redraw()

func _begin_count() -> void:
	_engaged = true
	state = S.COUNTING
	_count = 0
	_t = 0.0

func on_player_strike(pos: Vector2, big: bool) -> void:
	if state == S.DOWN or global_position.distance_to(pos) > STRIKE_HIT_RANGE:
		return
	if not is_pogoable():
		# A guard hit is still a real player strike for the parry clock. It
		# changes only this short cue, never the beat, health or resonance.
		_blocked_time = 0.0 if reduced_motion else BLOCKED_FLASH_TIME
		queue_redraw()
		return
	var opening_hit := not _engaged and state in [S.CALM, S.ALERT]
	super.on_player_strike(pos, big)
	if opening_hit and state != S.DOWN:
		_begin_count()

func _resolve_swing(distance: float) -> void:
	if state == S.DOWN:
		return
	_engaged = true
	# Keep the proven contact range, 100 ms clock and parry resonance reward.
	super._resolve_swing(distance)
	if state != S.DOWN:
		state = S.STAGGER
		_t = 0.0
		_blocked_time = 0.0
	queue_redraw()

func _down(spill: bool) -> void:
	if state == S.DOWN:
		return
	super._down(spill)
	_blocked_time = 0.0
	remove_from_group("strikable")
	remove_from_group("hears_strikes")
	queue_redraw()

func reset_attempt() -> void:
	if state == S.DOWN:
		return
	state = S.CALM
	hp = HP_MAX
	resonance = 0.0
	parry_count = 0
	_engaged = false
	_count = 0
	_t = 0.0
	_blocked_time = 0.0
	_print_time = 0.0
	_print_recoil = 0.0
	_print_swing_tail = 0.0
	queue_redraw()

func encounter_snapshot() -> Dictionary:
	var phase := "guard" if _engaged else "idle"
	match state:
		S.COUNTING: phase = "guard"
		S.SWING: phase = "swing"
		S.STAGGER: phase = "open"
		S.DOWN: phase = "down"
	return {
		"phase": phase, "count": 0 if state in [S.CALM, S.ALERT] else _count,
		"beat": clampf(_t / TICK_GAP, 0.0, 1.0) if state == S.COUNTING else 0.0,
		"opening_remaining": maxf(OPENING_DURATION - _t, 0.0) if state == S.STAGGER else 0.0,
		"opening_duration": OPENING_DURATION,
		"blocked": _blocked_time / BLOCKED_FLASH_TIME,
	}

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled: _blocked_time = 0.0
	queue_redraw()

func _draw() -> void:
	super._draw()
	PrintPress.draw_looper_cue(self, encounter_snapshot(), ink, stock)
