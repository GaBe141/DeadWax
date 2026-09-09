extends Node2D
## The first keeper of the record. It points up once; it never swings first.
## Its origin is the grounded stylus, shared by strike, pogo and contact reach.
## The overhead arm is a printed impression, never an invisible collision wall.

signal parried
signal shattered(pos: Vector2)
signal bout_won
signal freed(pos: Vector2)

const Press := preload("res://scripts/press.gd")

const NOTICE_RANGE := 520.0
const STRIKE_HIT_RANGE := 120.0
const CONTACT_RANGE := 130.0
const SET_RANGE := 135.0
const SET_FREE_TIME := 1.4
const GESTURE_TIME := 2.1
const TICK_GAP := 0.46
const COUNT_BEATS := 3
const SWEEP_TIME := 0.16
const RECOVER_TIME := 1.0
const PARRY_RECOVER_TIME := 2.4
const PARRY_WINDOW_MS := 100
const HP_MAX := 6.0
const HP_PER_HIT := 1.0
const HP_PER_BIG := 1.6
const MAX_FRAME_STEP := 0.1
const RESOLUTION_SETTLE_TIME := 1.1
const HIT_RECOIL_DECAY := 5.5

enum S { DORMANT, GESTURE, WAITING, COUNTING, SWEEP, RECOVERY, STAGGER, FREED, DOWN }
var state: int = S.DORMANT
var hp := HP_MAX
var ink := Color(0.16, 0.13, 0.19)
var stock := Color(0.91, 0.86, 0.77)
var outcome := ""
var _player: Node2D
var _t := 0.0
var _listening := 0.0
var _count := 0
var _face := -1.0
var _engaged := false
var _gestured := false
var _opening_hit := false
var _visual_time := 0.0
var _resolution_age := RESOLUTION_SETTLE_TIME
var _hit_recoil := 0.0

func _ready() -> void:
	add_to_group("hears_strikes")
	add_to_group("strikable")
	add_to_group("chapter_boss")
	z_index = 9

func is_pogoable() -> bool:
	return outcome.is_empty() and not _opening_hit and (state == S.RECOVERY or state == S.STAGGER)

func _bank() -> Node:
	return get_tree().get_first_node_in_group("audio_bank") if is_inside_tree() else null

func _sound(id: String, volume: float, pitch := 1.0) -> void:
	var bank := _bank()
	if bank != null:
		bank.play(id, volume, pitch)

func _process(delta: float) -> void:
	# Pausing freezes both the count and the act of listening. A frame hitch must
	# never eat an entire tell and deliver a sweep the player did not see.
	if delta <= 0.0 or (is_inside_tree() and get_tree().paused):
		return
	_visual_time += minf(delta, MAX_FRAME_STEP)
	_hit_recoil = maxf(_hit_recoil - delta * HIT_RECOIL_DECAY, 0.0)
	if not outcome.is_empty():
		_resolution_age = minf(_resolution_age + delta, RESOLUTION_SETTLE_TIME)
		queue_redraw()
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null or not outcome.is_empty():
		return
	var step := minf(delta, MAX_FRAME_STEP)
	var distance := global_position.distance_to(_player.global_position)
	_t += step
	if state == S.DORMANT or state == S.WAITING or state == S.RECOVERY or state == S.STAGGER:
		_face = -1.0 if _player.global_position.x < global_position.x else 1.0
	if state == S.WAITING or state == S.STAGGER:
		if _player.get("setting") == true and distance <= SET_RANGE:
			_listening += step
			if _listening >= SET_FREE_TIME:
				_resolve_outcome("freed")
		else:
			_listening = 0.0
	else:
		_listening = 0.0
	match state:
		S.DORMANT:
			if distance <= NOTICE_RANGE:
				_begin_gesture()
		S.GESTURE:
			if _t >= GESTURE_TIME:
				if _engaged:
					_begin_count()
				else:
					_go(S.WAITING)
		S.COUNTING:
			var beat := mini(int(_t / TICK_GAP), COUNT_BEATS)
			if beat > _count:
				_count = beat
				_sound("tick", -6.0, 0.76 + _count * 0.09)
			if _t >= TICK_GAP * (COUNT_BEATS + 1):
				_go(S.SWEEP)
				_sound("swing", -5.0, 0.75)
		S.SWEEP:
			if _t >= SWEEP_TIME:
				_resolve_sweep(Time.get_ticks_msec())
		S.RECOVERY:
			if _t >= RECOVER_TIME:
				_begin_count()
		S.STAGGER:
			if _t >= PARRY_RECOVER_TIME:
				_begin_count()
	queue_redraw()

func _go(next: int) -> void:
	state = next
	_t = 0.0
	_listening = 0.0
	queue_redraw()

func _begin_gesture() -> void:
	_gestured = true
	_go(S.GESTURE)

func _begin_count() -> void:
	_count = 0
	_opening_hit = false
	_go(S.COUNTING)
	if is_instance_valid(_player):
		_face = -1.0 if _player.global_position.x < global_position.x else 1.0

## `now_ms` is the instant this contact is resolved, in Skip's strike clock.
## Keeping it explicit also makes the inclusive 100ms boundary reproducible.
func _resolve_sweep(now_ms: int) -> void:
	if state != S.SWEEP or not _engaged or not outcome.is_empty() or get_tree().paused:
		return
	# Leave the damaging state before signals: a hit may synchronously respawn.
	_go(S.RECOVERY)
	_opening_hit = false
	if not is_instance_valid(_player):
		return
	var offset := _player.global_position - global_position
	# The count commits to one face. Passing behind or jumping above the tip is
	# a real dodge; nothing on the monumental overhead beam deals contact damage.
	if offset.length() > CONTACT_RANGE or offset.x * _face < -18.0:
		return
	var since_strike: int = now_ms - _player.last_strike_ms
	if since_strike >= 0 and since_strike <= PARRY_WINDOW_MS:
		_go(S.STAGGER)
		parried.emit()
		_sound("parry", -3.0, 0.8)
		return
	_player.take_hit(global_position)
	_sound("thud", -5.0, 0.78)

func on_player_strike(pos: Vector2, big: bool) -> void:
	if not outcome.is_empty() or global_position.distance_to(pos) > STRIKE_HIT_RANGE or get_tree().paused:
		return
	if not _engaged:
		_engaged = true
		_listening = 0.0
		if not _gestured:
			_begin_gesture()
		elif state != S.GESTURE:
			_begin_count()
		return
	# The cartridge opens only after a completed sweep. The swing-time strike
	# belongs solely to the parry check, never a simultaneous chip or double hit.
	if not is_pogoable():
		return
	_opening_hit = true
	_listening = 0.0
	hp = maxf(hp - (HP_PER_BIG if big else HP_PER_HIT), 0.0)
	_hit_recoil = 1.0
	_sound("thud", -9.0, 0.7)
	if hp <= 0.0:
		_resolve_outcome("shattered")
	queue_redraw()

func _resolve_outcome(result: String) -> void:
	if not outcome.is_empty() or (result != "freed" and result != "shattered"):
		return
	restore_outcome(result)
	# A live resolution moves into its held pose; a restored one starts there.
	_resolution_age = 0.0
	if result == "freed":
		freed.emit(global_position)
		_sound("freed", -5.0, 0.8)
	else:
		shattered.emit(global_position)
		_sound("shatter", -3.0, 0.75)

## Re-present the resolved impression without rewards, audio or new signals.
func restore_outcome(result: String) -> void:
	if not outcome.is_empty() or (result != "freed" and result != "shattered"):
		return
	outcome = result
	_engaged = false
	_opening_hit = true
	_go(S.FREED if result == "freed" else S.DOWN)
	_visual_time = 0.0
	_resolution_age = RESOLUTION_SETTLE_TIME
	_hit_recoil = 0.0
	if result == "shattered":
		hp = 0.0
	remove_from_group("strikable")
	remove_from_group("hears_strikes")

## A recovered needle gets a fresh attempt; a resolved keeper stays resolved.
func reset_attempt() -> void:
	if not outcome.is_empty():
		return
	hp = HP_MAX
	_engaged = false
	_opening_hit = false
	_count = 0
	_go(S.WAITING if _gestured else S.DORMANT)
	_visual_time = 0.0
	_hit_recoil = 0.0
	_resolution_age = RESOLUTION_SETTLE_TIME

func _draw() -> void:
	var pose := {
		"phase": S.keys()[state].to_lower(), "time": _t, "face": _face,
		"count": _count, "health": hp / HP_MAX, "health_total": int(HP_MAX),
		"listening": clampf(_listening / SET_FREE_TIME, 0.0, 1.0),
		"open": is_pogoable(), "engaged": _engaged,
		"windup": clampf(_t / (TICK_GAP * (COUNT_BEATS + 1)), 0.0, 1.0),
		"gesture": clampf(_t / GESTURE_TIME, 0.0, 1.0),
		"sweep": clampf(_t / SWEEP_TIME, 0.0, 1.0),
		"recovery": clampf(_t / (PARRY_RECOVER_TIME if state == S.STAGGER else RECOVER_TIME), 0.0, 1.0),
		"clock": _visual_time, "hit_recoil": _hit_recoil,
		"settle": clampf(_resolution_age / RESOLUTION_SETTLE_TIME, 0.0, 1.0),
	}
	Press.draw_tonearm(self, pose, ink, stock)
