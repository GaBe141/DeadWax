extends Node2D
## A reached destination that asks for the passage input. Its room decides
## what the act means; it owns neither progression nor transitions.

signal activated

const PressScript := preload("res://scripts/press.gd")
const ACTIVATE_RADIUS := 80.0

var ink := Color(0.15, 0.13, 0.12)
var stock := Color(0.90, 0.87, 0.80)
var heading := "THE OVERTURE"
var prompt := "[E / Y]  Listen below"
var used := false
var _near := false
var _card: Control

func _ready() -> void:
	add_to_group("chapter_endpoint")
	_card = PressScript.card(prompt, ink, stock, PressScript.PINK, PressScript.SIZE_BODY, heading)
	_card.position = Vector2(-_card.size.x / 2.0, -124.0)
	_card.visible = false
	add_child(_card)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	_near = (
		player != null
		and player.is_on_floor()
		and player.global_position.distance_to(global_position) <= ACTIVATE_RADIUS
	)
	_card.visible = _near and not used
	if _near and not used and Input.is_action_just_pressed("enter_passage"):
		try_activate()

func try_activate() -> bool:
	if used or not _near:
		return false
	used = true
	_card.visible = false
	activated.emit()
	return true

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		PressScript.recard(_card, ink, stock)
