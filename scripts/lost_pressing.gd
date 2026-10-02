extends Node2D
## An equipment sleeve left at a fixed place. Main alone validates the source,
## commits its collection, and applies any later equipment choice.

signal requested(source: Node2D)

const Press := preload("res://scripts/press.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const Progression := preload("res://scripts/progression_state.gd")
const INTERACT_RADIUS := 76.0
const NOTICE_RADIUS := 185.0

var definition: Dictionary = {}
var collection: RefCounted
var abilities: RefCounted
var progression: RefCounted
var pressing: RefCounted
var ink := Color("e6c58c")
var stock := Color("1b353b")
var _clock := 0.0
var _near := false
var _reduced_motion := false
var _released := false
var _card: Control
var _card_text := ""

func _ready() -> void:
	add_to_group("lost_pressing")
	z_index = 4
	refresh()

func is_collected() -> bool:
	return collection != null and collection.has_item(String(definition.get("id", "")))

func is_available() -> bool:
	if collection == null or is_collected():
		return false
	match String(definition.get("requirement", "")):
		"groove":
			return abilities != null and abilities.has_ability(&"groove")
		"gather":
			return progression != null and progression.has_refrain(Progression.Refrain.GATHER)
		"jump_cut":
			return progression != null and progression.has_refrain(Progression.Refrain.JUMP_CUT) and pressing != null and pressing.on_b_side()
	return false

func _physics_process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	# An entering or menu-closing confirmation must be released before this
	# sleeve can request anything. Failed requests remain available to retry.
	if not Input.is_action_pressed("enter_passage"):
		_released = true
	if not _reduced_motion and not is_collected():
		_clock += delta
	refresh()
	if _released and Input.is_action_just_pressed("enter_passage"):
		_released = false
		try_interact()

func try_interact() -> bool:
	if not is_inside_tree() or get_tree().paused or not is_available():
		return false
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not player.is_on_floor() or player.global_position.distance_to(global_position) > INTERACT_RADIUS:
		return false
	requested.emit(self)
	refresh()
	return true

func _player_distance() -> float:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player.global_position.distance_to(global_position) if player != null else INF

func _nearest_prompt() -> bool:
	var distance := _player_distance()
	if distance > NOTICE_RADIUS:
		return false
	var player := get_tree().get_first_node_in_group("player") as Node2D
	# A neighbouring resident or passage already has its own local card.
	# Yield while that interaction is active; the fixed authored reaches do
	# not overlap, so this only settles presentation between the two stops.
	for neighbour in get_parent().get_children():
		if neighbour == self or not neighbour is Node2D:
			continue
		var neighbour_radius := 0.0
		if neighbour.has_method("try_listen"):
			neighbour_radius = float(neighbour.get("LISTEN_RADIUS"))
		elif neighbour.is_in_group("room_exit"):
			neighbour_radius = 76.0
		if neighbour_radius > 0.0 and player.global_position.distance_to(neighbour.global_position) <= neighbour_radius:
			return false
	for candidate in get_tree().get_nodes_in_group("lost_pressing"):
		if candidate == self or candidate.get_parent() != get_parent():
			continue
		var other_distance: float = candidate.call("_player_distance")
		if other_distance < distance - 0.01 or (is_equal_approx(other_distance, distance) and candidate.get_instance_id() < get_instance_id()):
			return false
	return true

func _prompt() -> String:
	if is_collected():
		return "An empty sleeve. Its pressing travels with you.\nFit or remove it in the Book's Equipment page."
	var item := Catalog.item(String(definition.get("id", "")))
	var tradeoff := String(item.get("tradeoff", "")).replace("; ", ";\n")
	if is_available():
		return "%s\n[E / Y]  Take the pressing\nChoose whether to fit it in the Book." % tradeoff
	return "%s\n%s" % [String(definition.get("clue", "A sleeve left in the wax.")), tradeoff]

func refresh() -> void:
	if not is_inside_tree():
		return
	_near = _nearest_prompt()
	var text := _prompt()
	if _card == null or text != _card_text:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		var item := Catalog.item(String(definition.get("id", "")))
		_card = Press.card(text, ink, stock, Press.BRASS, Press.SIZE_BODY,
			String(item.get("name", "LOST PRESSING")).to_upper())
		_card.material = Press.unshaded_material()
		_card.z_index = 22
		add_child(_card)
	# Keep type readable on either window size without moving the item, its
	# interaction reach, or the balcony that supports it.
	var canvas_transform := get_global_transform_with_canvas()
	var canvas_scale := canvas_transform.get_scale().abs()
	canvas_scale.x = maxf(canvas_scale.x, 0.001)
	canvas_scale.y = maxf(canvas_scale.y, 0.001)
	var minimum := (Vector2(12, 12) - canvas_transform.origin) / canvas_scale
	var maximum := (get_viewport_rect().size - Vector2(12, 12) - canvas_transform.origin) / canvas_scale - _card.size
	_card.position = Vector2(clampf(-_card.size.x * 0.5, minimum.x, maxf(minimum.x, maximum.x)),
		clampf(-_card.size.y - 84.0, minimum.y, maxf(minimum.y, maximum.y)))
	_card.visible = _near
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		Press.recard(_card, ink, stock, Press.BRASS)
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func snapshot() -> Dictionary:
	return {"id": definition.get("id", &""), "requirement": definition.get("requirement", ""),
		"collected": is_collected(), "available": is_available(), "near": _near,
		"far_face": pressing != null and pressing.on_b_side(),
		"clock": 0.0 if _reduced_motion or is_collected() else _clock, "prompt": _prompt()}

func _draw() -> void:
	Press.draw_lost_pressing(self, snapshot(), ink, stock)
