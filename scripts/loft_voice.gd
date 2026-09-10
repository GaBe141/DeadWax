extends Node2D
## A lost phrase above the market. The player hears a whole call through the
## Hood, then starts Set in its silence. Main owns the resulting saved choice.

signal freed(pos: Vector2)

const Press := preload("res://scripts/press.gd")
const LISTEN_RADIUS := 125.0
const NOTE_TIME := 0.48
const CALL_TIME := NOTE_TIME * 3.0
const ANSWER_WINDOW := 1.15
const ANSWER_HOLD := 0.28
const REST_TIME := 0.65
const RESPONSES := 2
enum Stage { WAITING, CALLING, ANSWERING, RESTING, FREED }

var ink := Color("26221e")
var stock := Color("e8e0cc")
var card_offset := Vector2(0, -80)
var stage := Stage.WAITING
var responses := 0
var _elapsed := 0.0
var _note := -1
var _answer_started := false
var _held := 0.0
var _near := false
var _motion := 0.0
var _reduced_motion := false
var _card: Control
var _card_text := ""

func _ready() -> void:
	add_to_group("hears_strikes")
	z_index = 12
	_refresh_card()

func _physics_process(delta: float) -> void:
	if get_tree().paused or delta <= 0.0:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	_near = player != null and player.is_on_floor() and player.global_position.distance_to(global_position) <= LISTEN_RADIUS
	var quiet := _near and bool(player.get("hooded")) and absf(player.velocity.x) < 35.0
	var kneeling := _near and bool(player.get("setting"))
	advance_phrase(delta, _near, quiet, Input.is_action_just_pressed("set"), kneeling)
	if not _reduced_motion:
		_motion += delta
	_refresh_card()
	queue_redraw()

func advance_phrase(delta: float, nearby: bool, hood: bool, set_pressed: bool, kneeling: bool) -> void:
	if stage == Stage.FREED or delta <= 0.0:
		return
	if not nearby:
		_reset_call(true)
		return
	match stage:
		Stage.WAITING:
			if hood:
				stage = Stage.CALLING
				_elapsed = 0.0
				_note = 0
				_sound("loft_note_1")
		Stage.CALLING:
			if not hood:
				_reset_call()
				return
			_elapsed += delta
			var next_note := mini(int(_elapsed / NOTE_TIME), 2)
			if next_note != _note:
				_note = next_note
				_sound("loft_note_%d" % (_note + 1))
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
					_reset_call()
					return
				_held += delta
				if _held >= ANSWER_HOLD:
					responses += 1
					_sound("loft_answer")
					_elapsed = 0.0
					if responses >= RESPONSES:
						stage = Stage.FREED
						freed.emit(global_position)
					else:
						stage = Stage.RESTING
			elif _elapsed > ANSWER_WINDOW:
				_reset_call()
		Stage.RESTING:
			_elapsed += delta
			if _elapsed >= REST_TIME:
				_reset_call()

func _reset_call(forget_responses := false) -> void:
	stage = Stage.WAITING
	_elapsed = 0.0
	_note = -1
	_held = 0.0
	_answer_started = false
	if forget_responses:
		responses = 0

func on_player_strike(pos: Vector2, _big: bool) -> void:
	if stage != Stage.FREED and pos.distance_to(global_position) <= LISTEN_RADIUS:
		_reset_call()

func restore_outcome(outcome: String) -> void:
	if outcome == "freed":
		stage = Stage.FREED
		responses = RESPONSES
	else:
		_reset_call(true)
	_refresh_card()
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		Press.recard(_card, ink, stock)
	queue_redraw()

func _sound(sound_name: String) -> void:
	if not is_inside_tree():
		return
	var audio := get_tree().get_first_node_in_group("audio_bank")
	if audio != null:
		audio.call("play", sound_name, -8.0)

func _refresh_card() -> void:
	if not is_inside_tree():
		return
	var text := "Hold HOOD [K / B] and stand still.\nThree notes have lost their way."
	match stage:
		Stage.CALLING:
			text = "LISTEN  %s\nKeep your Hood up for all three." % ["ONE", "TWO", "THREE"][maxi(_note, 0)]
		Stage.ANSWERING:
			text = "THE SILENCE IS YOURS\nLower Hood. Hold SET [L / LB]."
		Stage.RESTING:
			text = "It remembers your answer.\nHood up. Hear it once more."
		Stage.FREED:
			text = "A way through the wall opens.\nListen for this phrase at home."
	if text != _card_text or _card == null:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		_card = Press.card(text, ink, stock, Press.PINK, Press.SIZE_BODY, "THE LOST PHRASE")
		_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y) + card_offset
		_card.material = Press.unshaded_material()
		add_child(_card)
	_card.visible = _near

func animation_pose() -> Dictionary:
	return {"clock": 0.0 if _reduced_motion else _motion, "stage": stage,
		"note": _note, "responses": responses, "near": _near,
		"answer": clampf(_held / ANSWER_HOLD, 0.0, 1.0)}

func _draw() -> void:
	Press.draw_loft_voice(self, animation_pose(), ink, stock)
