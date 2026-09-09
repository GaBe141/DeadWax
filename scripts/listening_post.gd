extends Node2D
## A small, grounded conversation. It owns only which line is being shown.

const PressScript := preload("res://scripts/press.gd")
const LISTEN_RADIUS := 140.0

var heading := "A VOICE"
var lines: Array[String] = []
var ink := Color("26221e")
var stock := Color("e3bfb6")
var _line := -1
var _card: Control
var _near := false

func _ready() -> void:
	_rebuild_card()

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	_near = (
		player != null and player.is_on_floor()
		and player.global_position.distance_to(global_position) <= LISTEN_RADIUS
	)
	_card.visible = _near
	if _near and Input.is_action_just_pressed("enter_passage"):
		try_listen()

func try_listen() -> bool:
	if not _near or lines.is_empty():
		return false
	_line = (_line + 1) % lines.size()
	_rebuild_card()
	return true

func _rebuild_card() -> void:
	if _card != null:
		remove_child(_card)
		_card.queue_free()
	var text := "[E / Y]  Listen"
	if _line >= 0:
		text = lines[_line] + "\n\n[E / Y]  Listen on"
	_card = PressScript.card(text, ink, stock, PressScript.PINK, PressScript.SIZE_BODY, heading)
	_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y - 125.0)
	_card.visible = _near
	z_index = 35
	add_child(_card)

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		PressScript.recard(_card, ink, stock)
