extends Node2D
## An intentional room boundary. Rooms describe where routes lead; Main owns
## the actual transition. Hold no world state here.

signal route_requested(target_room: StringName, target_entry: StringName)
signal route_blocked(message: String)

const ProgressionScript := preload("res://scripts/progression_state.gd")
const PressScript := preload("res://scripts/press.gd")
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
var ink := INK
var stock := CHALK

var _label: Label
var _near := false
var _was_locked := false

func _ready() -> void:
	add_to_group("room_exit")
	_label = Label.new()
	_label.position = Vector2(-96, -112)
	_label.size = Vector2(192, 54)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PressScript.set_display(_label, PressScript.SIZE_HEADING, ink, stock)
	_label.add_theme_constant_override("font_spacing_glyph", PressScript.TRACKING_DISPLAY)
	add_child(_label)
	_was_locked = is_locked()
	_refresh_label()

func _process(_delta: float) -> void:
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
	PressScript.draw_passage(self, {"near": _near, "locked": is_locked()}, ink, stock)

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _label != null:
		PressScript.set_display(_label, PressScript.SIZE_HEADING, ink, stock)
	queue_redraw()
