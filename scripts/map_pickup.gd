extends Node2D
## A folded page left near the start. Main owns collection and persistence;
## this node reads ownership and reports contact with its fixed origin.

signal collected

const Press := preload("res://scripts/press.gd")
const COLLECT_RADIUS := 52.0
const NOTICE_RADIUS := 165.0

var map_state: RefCounted
var ink := Color("26221e")
var stock := Color("e8e0cc")
var _collected := false
var _clock := 0.0
var _near := false
var _reduced_motion := false

func _ready() -> void:
	add_to_group("map_pickup")
	z_index = 3
	if _is_owned():
		_retire()

func _process(delta: float) -> void:
	if _collected or delta <= 0.0 or get_tree().paused:
		return
	if _is_owned():
		_retire()
		return
	if not _reduced_motion:
		_clock += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var distance := global_position.distance_to(player.global_position) if player != null else INF
	var near_now := distance <= NOTICE_RADIUS
	if near_now != _near or not _reduced_motion:
		_near = near_now
		queue_redraw()
	if distance <= COLLECT_RADIUS:
		collect()

func collect() -> void:
	if _collected:
		return
	if _is_owned():
		_retire()
		return
	_collected = true
	hide()
	remove_from_group("map_pickup")
	set_process(false)
	collected.emit()
	queue_free()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	queue_redraw()

func animation_pose() -> Dictionary:
	return {"clock": 0.0 if _reduced_motion else _clock, "near": _near,
		"owned": _collected or _is_owned(), "reduced_motion": _reduced_motion}

func _is_owned() -> bool:
	return map_state != null and bool(map_state.get("owned"))

func _retire() -> void:
	_collected = true
	hide()
	remove_from_group("map_pickup")
	set_process(false)
	queue_free()

func _draw() -> void:
	Press.draw_map_pickup(self, animation_pose(), ink, stock)
