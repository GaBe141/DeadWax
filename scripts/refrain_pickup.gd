extends Node2D
## A world pickup for an earned Refrain. Main performs the actual unlock;
## the floating impression never moves this node or its collection radius.

signal collected(refrain: int)

const ProgressionScript := preload("res://scripts/progression_state.gd")
const Press := preload("res://scripts/press.gd")
const COLLECT_RADIUS := 62.0
const NOTICE_RADIUS := 180.0

var progression: RefCounted
var refrain := ProgressionScript.Refrain.GATHER
var ink := Color("302631")
var stock := Color("e8d4c3")
var _collected := false
var _float_t := 0.0
var _near := false
var _reduced_motion := false
var _label: Control

func _ready() -> void:
	add_to_group("refrain_pickup")
	z_index = 4
	if _is_unlocked():
		_retire()
		return
	_label = Press.card(ProgressionScript.refrain_label(refrain).to_upper(), ink, stock, Press.PINK, Press.SIZE_HEADING, "REFRAIN")
	_label.position = Vector2(-_label.size.x * 0.5, -118)
	add_child(_label)

func _process(delta: float) -> void:
	if _collected or delta <= 0.0 or get_tree().paused:
		return
	if _is_unlocked():
		_retire()
		return
	if not _reduced_motion:
		_float_t += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var distance := global_position.distance_to(player.global_position) if player != null else INF
	var near_now := distance <= NOTICE_RADIUS
	if near_now != _near or not _reduced_motion:
		_near = near_now
		queue_redraw()
	if distance <= COLLECT_RADIUS:
		collect()

func collect() -> void:
	if _collected or get_tree().paused:
		return
	var should_report := not _is_unlocked()
	_retire()
	if should_report:
		collected.emit(refrain)

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _label != null:
		Press.recard(_label, ink, stock, Press.PINK)
	queue_redraw()

func animation_pose() -> Dictionary:
	return {"clock": 0.0 if _reduced_motion else _float_t, "near": _near,
		"reduced_motion": _reduced_motion, "refrain": refrain}

func _is_unlocked() -> bool:
	return progression != null and bool(progression.call("has_refrain", refrain))

func _retire() -> void:
	_collected = true
	hide()
	remove_from_group("refrain_pickup")
	set_process(false)
	queue_free()

func _draw() -> void:
	Press.draw_refrain_pickup(self, animation_pose(), ink, stock)
