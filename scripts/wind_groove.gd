extends "res://scripts/hot_groove.gd"
## A worn whistle answers a strike in one fixed direction. Skip still selects
## and pings it as an ordinary groove; no new player verb or permission exists.

const WIND_X := 740.0
const WIND_Y := -650.0
const ECHO_MULT := 1.25

var direction := -1.0

func ping() -> void:
	var echo := is_echo_hot()
	super.ping()
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not is_live():
		return
	player.velocity = Vector2(direction * WIND_X, WIND_Y) * (ECHO_MULT if echo else 1.0)
	var bank := get_tree().get_first_node_in_group("audio_bank")
	if bank != null:
		bank.call("play", "reach", -12.0, 1.45)
