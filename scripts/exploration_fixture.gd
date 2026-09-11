extends Node2D
## A fixed impression in the wax. Main validates and saves every request;
## presentation only reads the carried phrase, Refrain and opened returns.

signal requested(action: StringName, source: Node2D)

const Press := preload("res://scripts/press.gd")
const Progression := preload("res://scripts/progression_state.gd")
const INTERACT_RADIUS := 76.0
const NOTICE_RADIUS := 185.0

var definition: Dictionary = {}
var progression: RefCounted
var discoveries: RefCounted
var exploration: RefCounted
var pressing: RefCounted
var target_room: StringName = &""
var target_entry: StringName = &"default"
var ink := Color("e6c58c")
var stock := Color("1b353b")
var _clock := 0.0
var _near := false
var _reduced_motion := false
var _released := false
var _card: Control
var _card_text := ""

func _ready() -> void:
	add_to_group("exploration_fixture")
	if not is_reward():
		add_to_group("reverse_passage")
		add_to_group("room_exit")
	z_index = 4
	refresh()

func is_reward() -> bool:
	return String(definition.get("id", "")) == "jump_cut"

func is_open() -> bool:
	return exploration != null and exploration.is_open(StringName(definition.get("id", "")))

func is_locked() -> bool:
	return not is_open()

func has_jump_cut() -> bool:
	return progression != null and progression.has_refrain(Progression.Refrain.JUMP_CUT)

func is_available() -> bool:
	if is_reward():
		return discoveries != null and discoveries.snapshot().echo_spool == "restored" and not has_jump_cut()
	return is_open() or (bool(definition.get("far_end", false)) and has_jump_cut() and pressing != null and pressing.on_b_side())

func intent() -> StringName:
	if is_reward(): return &"claim_jump_cut"
	return &"enter_shortcut" if is_open() else &"open_shortcut"

func _physics_process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	# Every fresh room and newly revealed object waits for the entering button
	# to be released. A carried confirmation can never open or traverse it.
	if not Input.is_action_pressed("enter_passage"):
		_released = true
	if not _reduced_motion:
		_clock += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_near = player != null and player.global_position.distance_to(global_position) <= NOTICE_RADIUS
	refresh()
	if _released and Input.is_action_just_pressed("enter_passage"):
		_released = false
		try_interact()
	queue_redraw()

func try_interact() -> bool:
	if not is_inside_tree() or get_tree().paused or not is_available():
		return false
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or not player.is_on_floor() or player.global_position.distance_to(global_position) > INTERACT_RADIUS:
		return false
	requested.emit(intent(), self)
	refresh()
	return true

func refresh() -> void:
	visible = not is_reward() or is_available()
	if not is_inside_tree(): return
	var text := _prompt()
	if _card == null or text != _card_text:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		_card = Press.card(text, ink, stock, Press.BRASS, Press.SIZE_BODY,
			"JUMP-CUT" if is_reward() else ("RETURN OPEN" if is_open() else "BACK OF THE WAX"))
		_card.material = Press.unshaded_material()
		_card.z_index = 22
		add_child(_card)
	var canvas_transform := get_global_transform_with_canvas()
	var scale_x := maxf(absf(canvas_transform.get_scale().x), 0.001)
	var min_x := (12.0 - canvas_transform.origin.x) / scale_x
	var max_x := (get_viewport_rect().size.x - 12.0 - canvas_transform.origin.x) / scale_x - _card.size.x
	_card.position = Vector2(clampf(-_card.size.x * 0.5, min_x, maxf(min_x, max_x)), -_card.size.y - (80.0 if is_reward() else 112.0))
	_card.visible = _near and visible
	queue_redraw()

func _prompt() -> String:
	if is_reward():
		return "The answer loosened a second face.\n[E / Y]  Take the Refrain\nF / RB turns the wax for twelve seconds."
	if is_open():
		return "%s\n[E / Y]  Enter — either side" % String(definition.get("destination", "A WAY HOME")).to_upper()
	if not bool(definition.get("far_end", false)):
		return "A seam pressed shut from within.\nFind its other end beneath the Arm."
	if not has_jump_cut():
		if discoveries != null and discoveries.snapshot().echo_spool == "restored":
			return "A return cut into the far face.\nA Refrain waits below the northern receiver."
		return "A return cut into the far face.\nRestore the northern Warren's lost phrase."
	if pressing != null and pressing.on_b_side():
		return "The return has turned toward you.\n[E / Y]  Unseal it for both sides"
	return "The seam runs through the back of the wax.\n[F / RB]  Turn over to unseal it"

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _card != null: Press.recard(_card, ink, stock, Press.BRASS)
	queue_redraw()

func snapshot() -> Dictionary:
	return {"reward": is_reward(), "open": is_open(), "available": is_available(),
		"far_face": pressing != null and pressing.on_b_side(), "near": _near,
		"clock": 0.0 if _reduced_motion else _clock, "prompt": _prompt()}

func _draw() -> void:
	Press.draw_exploration(self, snapshot(), ink, stock)
