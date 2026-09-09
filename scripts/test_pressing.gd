extends Node2D
## THE TEST PRESSING — a training dummy: a pressed disc on a stand.
## It hears by crackle. It ticks three times and swings on four (ask Tick).
## Strike it: resonance builds. Strike AS its swing lands: RUNG BACK (parry).
## At full resonance it peaks and shatters into what it was going to say.
## muted=true -> Hush rules: raw hits build nothing; only parries count.

const PrintPress := preload("res://scripts/press.gd")

signal parried
signal shattered(pos: Vector2)
signal bout_won            # muted mode: 3 parries

const HEAR_RANGE := 520.0
const ATTACK_RANGE := 230.0
const HIT_RANGE := 130.0
const PARRY_WINDOW_MS := 100     # M2: tightened from 130 — hard-but-fair; the heart stays learnable
const STRIKE_HIT_RANGE := 120.0

const RES_HIT := 0.14
const RES_HIT_BIG := 0.24
const RES_PARRY := 0.35
const RES_DECAY := 0.045

# -- HP: the slow, patient bar (M2 delta #1 — the two-bar Sekiro model) --------
const HP_MAX := 5.0               # committed grounded strikes to down it the slow way
const HP_PER_HIT := 1.0           # chip per ordinary strike
const HP_PER_BIG := 1.6           # a hot / on-echo strike bites deeper

const TICK_GAP := 0.42            # three ticks, then the swing on "four"
const REFORM_TIME := 2.6
const PHRASE := ["BRIGHT", "LY", "OH", "!!"]

var muted := false

enum S { CALM, ALERT, COUNTING, SWING, STAGGER, DOWN }
var state: int = S.CALM
var resonance := 0.0
var hp := HP_MAX
var parry_count := 0
var _t := 0.0
var _count := 0
var _face := -1.0
var _sid := 0
var _player: Node2D

# The stand has a spring; its impression moves while its gameplay origin stays.
const PRINT_RECOIL_TIME := 0.26
const PRINT_FOLLOW_THROUGH_TIME := 0.25
var _print_time := 0.0
var _print_recoil := 0.0
var _print_swing_tail := 0.0

func _ready() -> void:
	add_to_group("hears_strikes")
	add_to_group("strikable")
	_sid = randi()
	z_index = 8

func is_pogoable() -> bool:
	return state != S.DOWN

func _bank() -> Node:
	return get_tree().get_first_node_in_group("audio_bank")

func _process(delta: float) -> void:
	_advance_print(delta)
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var d := global_position.distance_to(_player.global_position)
	_face = signf(_player.global_position.x - global_position.x)
	if _face == 0.0:
		_face = -1.0
	resonance = maxf(resonance - RES_DECAY * delta, 0.0)
	_t += delta

	match state:
		S.CALM:
			if _player.noise > 0.25 and d < HEAR_RANGE:
				state = S.ALERT
				_t = 0.0
				var b := _bank()
				if b != null:
					b.play("alert", -10.0)
		S.ALERT:
			if _player.noise < 0.03 and _t > 2.0:
				state = S.CALM
			elif d < ATTACK_RANGE:
				state = S.COUNTING
				_t = 0.0
				_count = 0
		S.COUNTING:
			if d > ATTACK_RANGE * 1.6:
				state = S.ALERT
				_t = 0.0
			elif _t >= TICK_GAP:
				_t = 0.0
				_count += 1
				var b := _bank()
				if _count <= 3:
					if b != null:
						b.play("tick", -8.0, 1.0 + 0.06 * _count)
				else:
					state = S.SWING
					if b != null:
						b.play("swing", -6.0)
		S.SWING:
			# the swing lands at t = 0.12 (a beat after the wind)
			if _t >= 0.12:
				_resolve_swing(d)
		S.STAGGER:
			if _t >= 1.0:
				state = S.ALERT
				_t = 0.0
		S.DOWN:
			if _t >= REFORM_TIME:
				state = S.CALM
				resonance = 0.0
				hp = HP_MAX
				_t = 0.0
	queue_redraw()

func _advance_print(delta: float) -> void:
	if delta <= 0.0 or (is_inside_tree() and get_tree().paused):
		return
	var step := minf(delta, 0.1)
	_print_time += step
	_print_recoil = maxf(_print_recoil - step / PRINT_RECOIL_TIME, 0.0)
	_print_swing_tail = maxf(_print_swing_tail - step / PRINT_FOLLOW_THROUGH_TIME, 0.0)
	queue_redraw()

func _resolve_swing(d: float) -> void:
	_print_swing_tail = 1.0
	var b := _bank()
	if d <= HIT_RANGE + 20.0:
		var since_strike: int = Time.get_ticks_msec() - _player.last_strike_ms
		if since_strike >= 0 and since_strike <= PARRY_WINDOW_MS:
			# RUNG BACK — caught on the point and played back
			_print_recoil = 1.0
			parry_count += 1
			state = S.STAGGER
			_t = 0.0
			parried.emit()
			if b != null:
				b.play("parry", -3.0)
			if muted:
				# HUSH's floor has no resonance outcome: only three clean catches win.
				if parry_count >= 3:
					parry_count = 0
					_down(false)
					bout_won.emit()
				return
			_gain(RES_PARRY)
			return
		_player.take_hit(global_position)
		if b != null:
			b.play("thud", -5.0)
	state = S.ALERT
	_t = 0.0

func on_player_strike(pos: Vector2, big: bool) -> void:
	if state == S.DOWN:
		return
	if global_position.distance_to(pos) <= STRIKE_HIT_RANGE:
		_print_recoil = 0.24 if muted else (1.0 if big else 0.72)
		if muted:
			# his rules: it barely flinches, and learns nothing about breaking
			_t = maxf(_t - 0.1, 0.0)
			return
		# TWO BARS, one blow: build resonance (fast lane) AND chip HP (slow lane)
		_gain(RES_HIT_BIG if big else RES_HIT)
		if state == S.DOWN:
			return
		hp = maxf(hp - (HP_PER_BIG if big else HP_PER_HIT), 0.0)
		if hp <= 0.0:
			_down(true)

func _gain(amount: float) -> void:
	resonance += amount
	if resonance >= 1.0:
		# RESONANCE EXECUTE — a shatter from any remaining HP (Sekiro deathblow)
		_down(true)

func _down(spill: bool) -> void:
	state = S.DOWN
	_t = 0.0
	resonance = 0.0
	if spill:
		shattered.emit(global_position)
		var b := _bank()
		if b != null:
			b.play("shatter", -2.0)

# -- drawing ------------------------------------------------------------------

const INK := Color(0.15, 0.13, 0.14)
const WAX := Color(0.22, 0.19, 0.23)
const PALE := Color(0.92, 0.90, 0.86)
const PINK := Color(0.90, 0.25, 0.50)
const GREY := Color(0.55, 0.52, 0.58)

func _draw() -> void:
	var pose := {
		"phase": S.keys()[state].to_lower(), "clock": _print_time,
		"seed": _sid, "face": _face, "muted": muted,
		"recoil": _print_recoil, "follow_through": _print_swing_tail,
		"count": _count, "beat": clampf(_t / TICK_GAP, 0.0, 1.0),
		"swing": clampf(_t / 0.12, 0.0, 1.0),
		"state_time": _t, "reform": clampf(_t / REFORM_TIME, 0.0, 1.0),
		"resonance": resonance, "hp": hp, "hp_total": int(HP_MAX),
	}
	PrintPress.draw_pressing(self, pose, INK, WAX, PALE, PINK, GREY)
