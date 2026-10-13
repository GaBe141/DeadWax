extends Node2D
## A MADE BED — Matron 33⅓'s cue point. Grounded E/Y asks Main to rest here:
## Main alone refills the diamonds, moves the active cue point to this bed and
## saves. The bed owns no health, no save and no outcome; it only asks.

signal rest_requested(source: Node2D)

const PressScript := preload("res://scripts/press.gd")
const REACH := 76.0
const CARD_CLEARANCE := 92.0

var entry_id: StringName = &"matron_bed"
var ink := Color("26221e")
var stock := Color("e3bfb6")
var cinematic_mode := false
var _card: Control
var _near := false
var _rested := 0.0
var _clock := 0.0

func _ready() -> void:
	add_to_group("rest_point")
	add_to_group("world_resident")
	z_index = 5
	_rebuild_card()

func _process(delta: float) -> void:
	if get_tree().paused or delta <= 0.0:
		return
	var step := minf(delta, 0.1)
	_clock += step
	_rested = maxf(_rested - step * 0.5, 0.0)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var near_now := player != null and player.is_on_floor() and player.global_position.distance_to(global_position) <= REACH
	if near_now != _near:
		_near = near_now
		_card.visible = _near and not cinematic_mode
	if _near and Input.is_action_just_pressed("enter_passage"):
		rest_requested.emit(self)
	queue_redraw()

## Main calls this only after a successful save.
func present_rest() -> void:
	_rested = 1.0
	queue_redraw()

func set_cinematic_mode(enabled: bool) -> void:
	cinematic_mode = enabled
	if _card != null:
		_card.visible = _near and not cinematic_mode

func cinematic_snapshot() -> Dictionary:
	return {"text": "E / Y · Rest", "radius": REACH, "priority": 22}

func snapshot() -> Dictionary:
	return {"clock": _clock, "near": _near, "rested": _rested}

func _rebuild_card() -> void:
	if _card != null:
		remove_child(_card)
		_card.queue_free()
	_card = PressScript.card("[E / Y]  Rest\nThe Hound knows this bed.", ink, stock, PressScript.ACCENT, PressScript.SIZE_BODY, "A MADE BED")
	_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y - CARD_CLEARANCE)
	_card.visible = _near and not cinematic_mode
	_card.z_index = 32
	add_child(_card)

func _draw() -> void:
	PressScript.draw_rest_point(self, snapshot(), ink, stock)

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	_rebuild_card()
	queue_redraw()
