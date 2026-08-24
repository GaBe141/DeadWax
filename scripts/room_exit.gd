extends Node2D
## An intentional room boundary. Rooms describe where routes lead; Main owns
## the actual transition. Hold no world state here.

signal route_requested(target_room: StringName, target_entry: StringName)
signal route_blocked(message: String)

const ProgressionScript := preload("res://scripts/progression_state.gd")
const ACTIVATE_RADIUS := 74.0
const INK := Color(0.10, 0.085, 0.115)
const CHALK := Color(0.95, 0.92, 0.86)
const PINK := Color(0.90, 0.25, 0.50)

var progression: RefCounted
var target_room: StringName
var target_entry: StringName = &"default"
var display_name := "PASSAGE"
var required_refrain := -1
var blocked_message := ""

var _label: Label
var _near := false
var _was_locked := false
var _pulse := 0.0

func _ready() -> void:
	add_to_group("room_exit")
	_label = Label.new()
	_label.position = Vector2(-66, -106)
	_label.size = Vector2(132, 50)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", CHALK)
	_label.add_theme_color_override("font_outline_color", INK)
	_label.add_theme_constant_override("outline_size", 5)
	add_child(_label)
	_was_locked = is_locked()
	_refresh_label()

func _process(delta: float) -> void:
	_pulse += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var near_now := (
		player != null
		and global_position.distance_to(player.global_position) <= ACTIVATE_RADIUS
	)
	var locked_now := is_locked()
	if near_now != _near or locked_now != _was_locked:
		_near = near_now
		_was_locked = locked_now
		_refresh_label()
		queue_redraw()
	if _near and Input.is_action_just_pressed("enter_passage"):
		try_enter()
	queue_redraw()

func is_locked() -> bool:
	return (
		required_refrain >= 0
		and (
			progression == null
			or not bool(progression.call("has_refrain", required_refrain))
		)
	)

func try_enter() -> bool:
	if is_locked():
		var message := blocked_message
		if message.is_empty():
			message = "%s is sealed. Another Refrain fits here." % display_name
		route_blocked.emit(message)
		return false
	if target_room.is_empty():
		route_blocked.emit("This passage has nowhere to go yet.")
		return false
	route_requested.emit(target_room, target_entry)
	return true

func _refresh_label() -> void:
	if _label == null:
		return
	if is_locked():
		_label.text = "%s\n%s — SEALED" % [display_name, _required_refrain_label()]
	elif _near:
		_label.text = "%s\n[E / Y] ENTER" % display_name
	else:
		_label.text = display_name
	_label.modulate.a = 1.0 if _near else 0.78

func _required_refrain_label() -> String:
	match required_refrain:
		ProgressionScript.Refrain.GATHER:
			return "GATHER"
		ProgressionScript.Refrain.REST:
			return "REST"
		ProgressionScript.Refrain.JUMP_CUT:
			return "JUMP-CUT"
	return "REFRAIN"

func _draw() -> void:
	var pulse := 0.72 + sin(_pulse * 3.0) * 0.18 if _near else 0.48
	var color := Color(PINK.r, PINK.g, PINK.b, pulse)
	if is_locked():
		color = Color(INK.r, INK.g, INK.b, 0.72)
	draw_line(Vector2(-25, 20), Vector2(-25, -55), color, 4.0)
	draw_line(Vector2(25, 20), Vector2(25, -55), color, 4.0)
	draw_arc(Vector2(0, -55), 25.0, PI, TAU, 24, color, 4.0)
	draw_line(Vector2(-34, 22), Vector2(34, 22), color, 3.0)
	if is_locked():
		draw_line(Vector2(-19, -30), Vector2(19, -8), color, 4.0)
		draw_line(Vector2(19, -30), Vector2(-19, -8), color, 4.0)
	else:
		draw_line(Vector2(0, 5), Vector2(0, -34), color, 3.0)
		draw_line(Vector2(0, -34), Vector2(-9, -23), color, 3.0)
		draw_line(Vector2(0, -34), Vector2(9, -23), color, 3.0)
