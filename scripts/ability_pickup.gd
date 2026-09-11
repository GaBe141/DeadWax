extends Node2D
## A lost part of Skip, set down at a fixed place in the campaign. Only Main
## can return its permission after a successful checkpoint write.

signal requested(ability: StringName, source: Node2D)

const Press := preload("res://scripts/press.gd")
const INTERACT_RADIUS := 76.0
const NOTICE_RADIUS := 185.0

var abilities: RefCounted
var ability: StringName = &"strike"
var session_outcomes: Dictionary = {}
var definition: Dictionary = {}
var ink := Color("e6c58c")
var stock := Color("1b353b")
var _clock := 0.0
var _near := false
var _reduced_motion := false
var _retired := false
var _card: Control
var _card_text := ""

func _ready() -> void:
	add_to_group("ability_pickup")
	z_index = 4
	refresh_abilities()

func _physics_process(delta: float) -> void:
	if _retired or delta <= 0.0 or get_tree().paused:
		return
	if _is_owned():
		refresh_abilities()
		return
	_near = _player_distance() <= NOTICE_RADIUS
	if not _reduced_motion:
		_clock += delta
	_refresh_card()
	if Input.is_action_just_pressed("enter_passage"):
		try_interact()
	queue_redraw()

func is_available() -> bool:
	var key := String(definition.get("outcome_key", ""))
	return key.is_empty() or String(session_outcomes.get(key, "")) == "opened"

func can_request() -> bool:
	return not _retired and not _is_owned() and is_available()

func try_interact() -> bool:
	if not is_inside_tree() or get_tree().paused or not can_request():
		return false
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not player.is_on_floor() or player.global_position.distance_to(global_position) > INTERACT_RADIUS:
		return false
	requested.emit(ability, self)
	# A failed write leaves the same object and interaction available. Neither
	# the request nor a nearby held button is evidence of a successful pickup.
	refresh_abilities()
	return true

func refresh_abilities() -> void:
	if _is_owned():
		_retired = true
		hide()
		remove_from_group("ability_pickup")
		set_physics_process(false)
		queue_free()
		return
	_refresh_card()
	queue_redraw()

func _is_owned() -> bool:
	return abilities != null and bool(abilities.call("has_ability", ability))

func _player_distance() -> float:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player.global_position.distance_to(global_position) if player != null else INF

func _prompt() -> String:
	if not is_available():
		return "Four even strikes open the sleeve.\nThe listening door keeps the count."
	var hint := "A missing part, waiting for you."
	match ability:
		&"strike": hint = "J / X — strike and parry."
		&"set": hint = "Hold L / LB — kneel and listen."
		&"hood": hint = "Hold K / C / B — move quietly."
		&"groove": hint = "Strike live wax to launch."
		&"combo": hint = "Three fresh strikes: Tap, Sweep, Accent."
		&"pogo": hint = "Strike a vulnerable foe in the air to rebound."
	return "%s\n[E / Y]  Recover %s" % [hint, String(definition.get("name", ability)).to_upper()]

func _refresh_card() -> void:
	if not is_inside_tree() or _retired:
		return
	var text := _prompt()
	if _card == null or text != _card_text:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		_card = Press.card(text, ink, stock, Press.BRASS, Press.SIZE_BODY,
			String(definition.get("name", ability)).to_upper())
		_card.position = Vector2(-_card.size.x * 0.5, -_card.size.y - 70.0)
		_card.material = Press.unshaded_material()
		_card.z_index = 22
		add_child(_card)
	_card.visible = _near

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null:
		Press.recard(_card, ink, stock, Press.BRASS)
	queue_redraw()

func snapshot() -> Dictionary:
	return {"ability": ability, "clock": 0.0 if _reduced_motion else _clock,
		"near": _near, "available": is_available(), "owned": _retired or _is_owned(),
		"reduced_motion": _reduced_motion, "prompt": _prompt()}

func _draw() -> void:
	Press.draw_ability_pickup(self, snapshot(), ink, stock)
