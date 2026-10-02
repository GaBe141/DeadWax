extends Node2D
## A small, grounded conversation. It owns only which line is being shown.

const PressScript := preload("res://scripts/press.gd")
const LISTEN_RADIUS := 140.0
const DIALOGUE_TIME := 8.0

var heading := "A VOICE"
var lines: Array[String] = []
var ink := Color("26221e")
var stock := Color("e3bfb6")
var card_clearance := 125.0
var extra_hint := ""
var cinematic_mode := false
var _line := -1
var _card: Control
var _near := false
var _dialogue_remaining := 0.0

func _ready() -> void:
	_rebuild_card()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var in_range := player != null and player.global_position.distance_to(global_position) <= LISTEN_RADIUS
	_near = (
		player != null and player.is_on_floor()
		and in_range
	)
	if cinematic_mode:
		_dialogue_remaining = maxf(_dialogue_remaining - maxf(delta, 0.0), 0.0)
		if not in_range:
			_dialogue_remaining = 0.0
			if _line != -1:
				_line = -1
				_rebuild_card()
	_card.visible = _near and not cinematic_mode
	if _near and Input.is_action_just_pressed("enter_passage"):
		try_listen()

func try_listen() -> bool:
	if not _near or lines.is_empty() or (is_inside_tree() and get_tree().paused):
		return false
	_line = (_line + 1) % lines.size()
	_dialogue_remaining = DIALOGUE_TIME
	_rebuild_card()
	return true

func set_cinematic_mode(enabled: bool) -> void:
	cinematic_mode = enabled
	if _card != null:
		_card.visible = _near and not cinematic_mode

func cancel_dialogue() -> void:
	if not cinematic_mode:
		return
	_dialogue_remaining = 0.0
	_line = -1
	if _card != null:
		_rebuild_card()

func cinematic_snapshot() -> Dictionary:
	var snapshot := {"text": "E / Y · Listen", "radius": LISTEN_RADIUS, "priority": 20}
	if _dialogue_remaining > 0.0 and _line >= 0 and _line < lines.size() and _near:
		snapshot.dialogue = lines[_line]
		snapshot.speaker = heading
		snapshot.priority = 100
	return snapshot

func _rebuild_card() -> void:
	if _card != null:
		remove_child(_card)
		_card.queue_free()
	var text := "[E / Y]  Listen"
	if _line >= 0:
		text = lines[_line] + "\n\n[E / Y]  Listen on"
	if not extra_hint.is_empty():
		text += "\n" + extra_hint
	_card = PressScript.card(text, ink, stock, PressScript.PINK, PressScript.SIZE_BODY, heading)
	_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y - card_clearance)
	_card.visible = _near and not cinematic_mode
	z_index = 35
	add_child(_card)

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		PressScript.recard(_card, ink, stock)
