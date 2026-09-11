extends Node2D
## One carried phrase and the fixtures that remember it. The station owns only
## a cancellable interaction and its print; Main owns every saved discovery.

signal requested(action: StringName, source: Node2D)
signal cue_requested(cue: StringName)

const Progression := preload("res://scripts/progression_state.gd")
const Press := preload("res://scripts/press.gd")
const INTERACT_RADIUS := preload("res://scripts/discoveries_state.gd").INTERACT_RADIUS
const AudioBank := preload("res://scripts/audio_bank.gd")
const SEQUENCE_TIME := AudioBank.ECHO_PHRASE_SECONDS
const NOTE_TIME := SEQUENCE_TIME / 3.0

var action: StringName = &"collect_spool"
var discoveries: RefCounted
var progression: RefCounted
var ink := Color("ddc3a5")
var stock := Color("2b2638")
var _stage: StringName = &"idle"
var _elapsed := 0.0
var _clock := 0.0
var _near := false
var _reduced_motion := false
var _replaying := false
var _card: Control
var _card_text := ""
var _state: Dictionary = {"echo_spool": "missing", "survey_slip": false}

func _ready() -> void:
	add_to_group("echo_discovery")
	add_to_group("reset_on_recovery")
	z_index = 4
	refresh_discoveries()

func _physics_process(delta: float) -> void:
	if get_tree().paused or delta <= 0.0:
		return
	_near = _player_is_near()
	advance_sequence(delta, _near)
	if _near and Input.is_action_just_pressed("enter_passage"):
		try_interact()
	if not _reduced_motion:
		_clock += delta
	_refresh_card()
	queue_redraw()

func _player_is_near() -> bool:
	if not is_inside_tree():
		return false
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	return player != null and player.is_on_floor() and player.global_position.distance_to(global_position) <= INTERACT_RADIUS

func can_request() -> bool:
	var held := String(_state.get("echo_spool", "missing"))
	match action:
		&"collect_spool": return held == "missing"
		&"record_phrase": return held == "empty"
		&"restore_warren": return held == "recorded"
		&"collect_survey": return not bool(_state.get("survey_slip", false))
	return false

func try_interact() -> bool:
	# Proximity is checked afresh so callers cannot reuse an old prompt after
	# a recovery, a jump, or a room transition.
	_near = _player_is_near()
	if not _near or _stage != &"idle" or get_tree().paused:
		return false
	refresh_discoveries()
	var replay := action == &"restore_warren" and String(_state.echo_spool) == "restored"
	if not can_request() and not replay:
		return false
	if action in [&"collect_spool", &"collect_survey"]:
		var before := _state.duplicate(true)
		requested.emit(action, self)
		refresh_discoveries()
		if _state != before:
			cue_requested.emit(&"echo_collect")
		return true
	_stage = &"recording" if action == &"record_phrase" else &"playing"
	_elapsed = 0.0
	_replaying = replay
	cue_requested.emit(&"echo_record" if _stage == &"recording" else &"echo_play")
	_refresh_card()
	queue_redraw()
	return true

func advance_sequence(delta: float, nearby: bool) -> void:
	if _stage == &"idle" or delta <= 0.0:
		return
	if not nearby:
		reset_attempt()
		return
	_elapsed = minf(_elapsed + delta, SEQUENCE_TIME)
	if _elapsed < SEQUENCE_TIME:
		return
	var replay := _replaying
	_stage = &"idle"
	_elapsed = 0.0
	_replaying = false
	if not replay:
		var before := _state.duplicate(true)
		requested.emit(action, self)
		refresh_discoveries()
		if _state != before:
			cue_requested.emit(&"echo_complete")
	_refresh_card()
	queue_redraw()

func reset_attempt() -> void:
	if _stage != &"idle":
		cue_requested.emit(&"echo_stop")
	_stage = &"idle"
	_elapsed = 0.0
	_replaying = false
	_near = false
	_refresh_card()
	queue_redraw()

func refresh_discoveries() -> void:
	if discoveries != null:
		_state = discoveries.call("snapshot").duplicate(true)
	else:
		_state = {"echo_spool": "missing", "survey_slip": false}
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

func _heading() -> String:
	match action:
		&"collect_spool": return "THE ECHO SPOOL"
		&"record_phrase": return "THE LAST THREE NOTES"
		&"restore_warren": return "THE LISTENING ALCOVE"
		&"collect_survey": return "A SURVEYOR'S SLIP"
	return "AN ECHO"

func _prompt() -> String:
	if _stage == &"recording":
		return "RECORDING  %s\nStay close for all three notes." % ["ONE", "TWO", "THREE"][maxi(_current_note(), 0)]
	if _stage == &"playing":
		return "PLAYING  %s\nThe room is listening." % ["ONE", "TWO", "THREE"][maxi(_current_note(), 0)]
	var held := String(_state.echo_spool)
	match action:
		&"collect_spool":
			if held == "missing":
				return "A little reel, still unwound.\n[E / Y]  Take the Echo Spool"
			return "The empty cradle points south.\nThree notes wait above the old count."
		&"record_phrase":
			if held == "missing":
				return "Three notes, with nowhere to stay.\nAn empty spool rests in the Gallery."
			if held == "empty":
				return "Three notes catch on the old wire.\n[E / Y]  Record the phrase"
			if held == "recorded":
				return "The phrase is safe on your spool.\nA northern horn waits to hear it."
			return "The wire is quiet.\nIts phrase has found a room."
		&"restore_warren":
			if held == "recorded":
				return "The horn has kept three empty bars.\n[E / Y]  Play the recorded phrase"
			if held == "restored":
				if progression != null and not progression.has_refrain(Progression.Refrain.JUMP_CUT):
					return "A Refrain waits below this receiver.\n[E / Y]  Hear the room answer again"
				return "A little audience, at last.\n[E / Y]  Hear the room answer"
			if held == "empty":
				return "This horn knows an empty spool.\nBring it the southern room's phrase."
			return "An audience cut into the wall.\nTheir answering horn has gone quiet."
		&"collect_survey":
			if not bool(_state.survey_slip):
				return "A folded note above the road.\n[E / Y]  Keep the surveyor's slip"
			return "Above the Stalls, a voice waits.\nCarry your borrowed breath home."
	return ""

func _refresh_card() -> void:
	if not is_inside_tree():
		return
	var text := _prompt()
	if _card == null or text != _card_text:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		_card = Press.card(text, ink, stock, Press.BRASS, Press.SIZE_BODY, _heading())
		_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y - 106.0)
		_card.material = Press.unshaded_material()
		_card.z_index = 22
		add_child(_card)
	_card.visible = _near

func _current_note() -> int:
	if _stage == &"idle":
		return -1
	var note := -1
	for index in AudioBank.ECHO_TIMING.size():
		if _elapsed >= float(AudioBank.ECHO_TIMING[index][0]):
			note = index
	return note

func snapshot() -> Dictionary:
	return {"action": action, "kind": action, "stage": _stage,
		"note": _current_note(),
		"progress": _elapsed / SEQUENCE_TIME, "near": _near,
		"clock": 0.0 if _reduced_motion else _clock,
		"echo_spool": String(_state.echo_spool), "survey_slip": bool(_state.survey_slip),
		"prompt": _prompt(), "replaying": _replaying, "reduced_motion": _reduced_motion}

func _draw() -> void:
	Press.draw_echo_station(self, action, snapshot(), _clock, _reduced_motion, ink, stock)
