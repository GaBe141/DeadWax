extends "res://scripts/auditioner.gd"
## One name in the Yard has lost its last note. This first conversation asks
## for one complete Hood call and a fresh Set in the silence. The ordinary
## Auditioner still owns strikes, parries, damage, and the two saved outcomes.

const Press := preload("res://scripts/press.gd")
const LISTEN_RADIUS := 175.0
const NOTICE_RADIUS := 290.0
const STEP_RADIUS := 72.0
const NOTE_GAP := 0.58
const CALL_TIME := NOTE_GAP + 0.4 # The reply opens exactly as the second note ends.
const ANSWER_WINDOW := 2.0
const ANSWER_HOLD := 0.4
const REST_TIME := 0.75
const WHISPER_PERIOD := 5.6
enum Stage { WAITING, CALLING, ANSWERING, RESTING }

var ink := Color("26221e")
var stock := Color("e8e0cc")
var stage := Stage.WAITING
var _home_position := Vector2.ZERO
var _elapsed := 0.0
var _note := -1
var _answer_started := false
var _held := 0.0
var _near := false
var _noticed := false
var _reduced_motion := false
var _retry_delay := 0.0
var _whisper := 0.0
var _whisper_note := -1
var _card: Control
var _card_text := ""

func _ready() -> void:
	super._ready()
	_home_position = global_position
	_refresh_card()

func _physics_process(delta: float) -> void:
	# Sample the fresh response alongside Skip's grounded Hood/Set state.
	# An explicitly suspended actor also suspends its conversation.
	if delta <= 0.0 or get_tree().paused or not is_processing():
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return
	var distance := global_position.distance_to(_player.global_position)
	_noticed = distance <= NOTICE_RADIUS
	var grounded: bool = _player.is_on_floor() and float(_player.get("_stagger")) <= 0.0
	var nearby := grounded and distance < LISTEN_RADIUS
	var hood: bool = nearby and _player.hooded and absf(_player.velocity.x) < 35.0
	advance_phrase(delta, nearby, hood, Input.is_action_just_pressed("set"), nearby and _player.setting)

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused or not is_instance_valid(_player):
		return
	if state not in [S.FREED, S.DOWN] and stage != Stage.WAITING and _near:
		# The voice gives its listener space. Combat clocks never advance in
		# this quiet exchange, and a missed reply has a short, harmless rest.
		_advance_print(delta)
		_face = -1.0 if _player.global_position.x < global_position.x else 1.0
		_jit = Vector2.ZERO
	else:
		super._process(delta)
	_advance_whisper(delta)
	_refresh_card()
	queue_redraw()

func advance_phrase(delta: float, nearby: bool, hood: bool, set_pressed: bool, kneeling: bool) -> void:
	if delta <= 0.0 or state in [S.FREED, S.DOWN] or (is_inside_tree() and get_tree().paused):
		return
	_near = nearby
	_retry_delay = maxf(_retry_delay - delta, 0.0)
	if not nearby:
		_reset_phrase()
		return
	match stage:
		Stage.WAITING:
			if hood and _retry_delay <= 0.0:
				stage = Stage.CALLING
				_elapsed = 0.0
				_note = 0
				_whisper = 0.0
				_whisper_note = -1
				_go(S.CALM)
				_reach_t = 0.0
				_sound("yard_note_1")
		Stage.CALLING:
			if not hood:
				_rest()
				return
			_elapsed += delta
			if _note == 0 and _elapsed >= NOTE_GAP:
				_note = 1
				_sound("yard_note_2")
			if _elapsed >= CALL_TIME:
				stage = Stage.ANSWERING
				_elapsed = 0.0
				_answer_started = false
				_held = 0.0
		Stage.ANSWERING:
			_elapsed += delta
			if set_pressed and kneeling and not hood and _elapsed <= ANSWER_WINDOW:
				_answer_started = true
			if _answer_started:
				if not kneeling or hood:
					_rest()
					return
				_held += delta
				if _held >= ANSWER_HOLD:
					_free()
			elif _elapsed > ANSWER_WINDOW:
				_rest()
		Stage.RESTING:
			_elapsed += delta
			if _elapsed >= REST_TIME:
				_reset_phrase()

func _reset_phrase() -> void:
	stage = Stage.WAITING
	_elapsed = 0.0
	_note = -1
	_answer_started = false
	_held = 0.0

func _rest() -> void:
	_reset_phrase()
	stage = Stage.RESTING
	_go(S.CALM)
	_reach_t = 0.0

func _is_player_setting() -> bool:
	# The other Yard voice still uses ordinary sustained Set. This one needs
	# its two notes first; merely holding Set must never bypass the exchange.
	return false

func _creep(speed: float, delta: float) -> void:
	var previous_x := global_position.x
	var target := clampf(_player.global_position.x, _home_position.x - STEP_RADIUS, _home_position.x + STEP_RADIUS)
	global_position.x = move_toward(global_position.x, target, speed * delta)
	_print_stride += absf(global_position.x - previous_x) * PRINT_STRIDE_RADIANS

func on_player_strike(pos: Vector2, big: bool) -> void:
	if state in [S.FREED, S.DOWN] or (is_inside_tree() and get_tree().paused):
		return
	if global_position.distance_to(pos) <= STRIKE_HIT_RANGE:
		_reset_phrase()
		_retry_delay = REST_TIME
		_whisper = 0.0
		_whisper_note = -1
	super.on_player_strike(pos, big)

func _free() -> void:
	if state in [S.FREED, S.DOWN]:
		return
	state = S.FREED
	_t = 0.0
	resonance = 0.0
	freed.emit(global_position)
	_sound("yard_answer")
	_refresh_card()
	queue_redraw()

func _down() -> void:
	if state in [S.FREED, S.DOWN]:
		return
	_reset_phrase()
	super._down()
	_refresh_card()

func _advance_print(delta: float) -> void:
	if _reduced_motion:
		_print_recoil = 0.0
		return
	super._advance_print(delta)

func _advance_whisper(delta: float) -> void:
	if not _noticed or stage != Stage.WAITING or state not in [S.CALM, S.PURSUE]:
		_whisper = 0.0
		_whisper_note = -1
		return
	_whisper += delta
	var note := 0 if _whisper >= 1.4 and _whisper < 1.4 + NOTE_GAP else -1
	if _whisper >= 1.4 + NOTE_GAP and _whisper < 1.4 + CALL_TIME:
		note = 1
	if note != _whisper_note and note >= 0:
		_sound("yard_note_%d" % (note + 1), -19.0)
	_whisper_note = note
	if _whisper >= WHISPER_PERIOD:
		_whisper = 0.0

func _sound(sound_name: String, volume := -8.0) -> void:
	if not is_inside_tree():
		return
	var bank := _bank()
	if bank != null:
		bank.play(sound_name, volume)

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		Press.recard(_card, ink, stock)
	queue_redraw()

func _refresh_card() -> void:
	if not is_inside_tree():
		return
	var text := "It starts, then loses the ending.\nHold HOOD [K / B] and stand still."
	match stage:
		Stage.CALLING:
			text = "LISTEN  %s\nKeep your Hood up. Let it finish." % ("ONE" if _note == 0 else "TWO")
		Stage.ANSWERING:
			text = "IT LEAVES A SPACE FOR YOU\nLower Hood. Hold SET [L / LB]."
		Stage.RESTING:
			text = "It can try again.\nRaise your Hood when you're ready."
	if text != _card_text or _card == null:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		_card = Press.card(text, ink, stock, Press.PINK, Press.SIZE_BODY, "A HALF-REMEMBERED NAME")
		_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y - 155.0)
		_card.material = Press.unshaded_material()
		add_child(_card)
	_card.visible = _noticed and state not in [S.FREED, S.DOWN]

func animation_pose() -> Dictionary:
	return {"phase": S.keys()[state].to_lower(), "clock": 0.0 if _reduced_motion else _print_time,
		"stride": _print_stride, "recoil": 0.0 if _reduced_motion else _print_recoil, "face": _face,
		"jitter": Vector2.ZERO if _reduced_motion else _jit * 0.42, "state_time": _t,
		"reach": clampf(_reach_t / REACH_WIND, 0.0, 1.0), "recover": clampf(_t / RECOVER_TIME, 0.0, 1.0),
		"leave": clampf(_t / LEAVE_TIME, 0.0, 1.0), "burst": clampf(_t / BURST_TIME, 0.0, 1.0),
		"held": false, "resonance": resonance, "listening": clampf(_held / ANSWER_HOLD, 0.0, 1.0),
		"hp": hp, "hp_total": int(HP_MAX), "stage": S.keys()[state].to_lower() if state in [S.FREED, S.DOWN] else Stage.keys()[stage].to_lower(),
		"note": _whisper_note if stage == Stage.WAITING else _note, "answer": clampf(_held / ANSWER_HOLD, 0.0, 1.0),
		"near": _noticed, "reduced_motion": _reduced_motion}

func _draw() -> void:
	Press.draw_yard_voice(self, animation_pose(), ink, stock)
