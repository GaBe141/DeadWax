extends SceneTree
## Exercise real standing support, the earned balcony ascent, input edges and
## settled presentation independently of Main's save transaction tests.

const Campaign := preload("res://scripts/campaign.gd")
const Catalog := preload("res://scripts/lost_pressings_catalog.gd")
const Fixture := preload("res://scripts/lost_pressing.gd")
const Collection := preload("res://scripts/collection_state.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Pressing := preload("res://scripts/pressing_state.gd")
const Skip := preload("res://scripts/skip.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "strike", "lift", "set", "enter_passage"]
const BALCONY := Rect2(400, 400, 200, 30)

var _room: Node2D
var _player: CharacterBody2D
var _source: Node2D
var _requests := 0
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action): InputMap.add_action(action)
	_check(Catalog.entries().size() == 3, "three fixed exploration finds")
	for definition in Catalog.entries():
		await _fixture(definition)
		await _support_and_permissions(definition)
	await _gather_route()
	await _close()
	if _failures.is_empty():
		print("DEAD WAX LOST PRESSINGS WORLD PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("LOST PRESSINGS WORLD FAIL: " + failure)
	quit(1)

func _fixture(definition: Dictionary) -> void:
	await _close()
	_room = Campaign.create_room(definition.room_id)
	_room.abilities = Abilities.new()
	_room.abilities.unlock_ability(&"walk")
	_room.progression = Progression.new()
	root.add_child(_room)
	for actor in get_nodes_in_group("hears_strikes"):
		actor.set_physics_process(false)
		actor.set_process(false)
	_player = Skip.new()
	_player.abilities = _room.abilities
	_player.progression = _room.progression
	_player.position = Vector2(100, -300)
	root.add_child(_player)
	_source = Fixture.new()
	_source.definition = definition
	_source.position = definition.position
	_source.abilities = _room.abilities
	_source.progression = _room.progression
	_source.collection = Collection.new()
	_source.pressing = Pressing.new()
	_source.ink = _room.ink
	_source.stock = _room.bg_color
	_requests = 0
	_source.requested.connect(func(_origin: Node2D) -> void: _requests += 1)
	_room.add_child(_source)
	await _physics(3)

func _support_and_permissions(definition: Dictionary) -> void:
	var label := String(definition.id)
	_check(_source.position == definition.position and _source.scale == Vector2.ONE, label + " keeps its fixed origin")
	_check(not _has_collision(_source), label + " fixture adds no physics")
	_check(_room._skins.size() == (4 if definition.room_id == &"horn_plaza" else (10 if definition.room_id == &"the_stalls" else 3)), label + " preserves all other authored platforms; actual " + str(_room._skins.size()))
	for arrival in _room.entry_points.values():
		_check(definition.position.distance_to(arrival) > Fixture.INTERACT_RADIUS, label + " is clear of named arrivals")
	for child in _room.get_children():
		if child.is_in_group("room_exit") or child.has_method("try_listen"):
			var radius: float = child.LISTEN_RADIUS if child.has_method("try_listen") else 74.0
			_check(definition.position.distance_to(child.position) > Fixture.INTERACT_RADIUS + radius, label + " has separate interaction reach from " + String(child.name))
	await _reset_at(definition.position)
	_check(_player.is_on_floor() and _player.position.distance_to(definition.position) < 1.0, label + " has real standing support")
	_check(not _source.is_available() and not _source.try_interact() and _requests == 0, label + " cannot be claimed before its earned requirement")
	var empty: Dictionary = _source.collection.snapshot()
	match String(definition.requirement):
		"groove": _room.abilities.unlock_ability(&"groove")
		"gather": _room.progression.unlock_refrain(Progression.Refrain.GATHER)
		"jump_cut":
			_source.pressing.flip()
			_check(not _source.is_available(), "the far face alone grants no permission")
			_source.pressing.flip()
			_room.progression.unlock_refrain(Progression.Refrain.JUMP_CUT)
			_check(not _source.is_available(), "Dusk Seal remains inward on the A-side after Jump-Cut")
			_source.pressing.flip()
	_source.refresh()
	_check(_source.is_available(), label + " becomes available with its actual permission")
	_check(_source.try_interact() and _requests == 1, label + " emits one grounded request")
	_check(_source.collection.snapshot() == empty, label + " request never grants equipment or currency")
	await _reset_at(definition.position + Vector2(0, -100))
	_check(not _source.try_interact(), label + " cannot be collected in flight")
	await _reset_at(definition.position)
	# The held entering input is explicitly carried across fixture creation.
	_source._released = false
	Input.action_press("enter_passage")
	await _physics(4)
	_check(_requests == 1, label + " ignores held arrival confirmation")
	Input.action_release("enter_passage")
	await _physics(2)
	Input.action_press("enter_passage")
	await _physics(3)
	_check(_requests == 2, label + " accepts a new confirmation after release")
	_release()
	_source.set_reduced_motion(true)
	var clock: float = _source._clock
	await _physics(5)
	_check(is_equal_approx(_source._clock, clock) and _source.snapshot().clock == 0.0, label + " reduced motion freezes decoration")
	_source.set_reduced_motion(false)
	paused = true
	await process_frame
	await process_frame
	_check(is_equal_approx(_source._clock, clock), label + " pause freezes decoration")
	paused = false
	var ink: Color = _room.ink
	var stock: Color = _room.bg_color
	_room.apply_side(Pressing.Side.B)
	_check(_source.ink == stock and _source.stock == ink, label + " receives explicit B-side reinking")
	_room.apply_side(Pressing.Side.A)
	_check(_source.ink == ink and _source.stock == stock, label + " restores authored ink")
	_check(_source._card.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED, label + " card stays readable under room lighting")
	for window_size in [Vector2i(960, 540), Vector2i(1280, 720)]:
		root.size = window_size
		root.content_scale_size = window_size
		await process_frame
		_source.refresh()
		var rect: Rect2 = _source._card.get_global_rect()
		_check(rect.position.x >= 11.9 and rect.position.y >= 11.9 and rect.end.x <= window_size.x - 11.9 and rect.end.y <= window_size.y - 11.9, label + " card remains inside " + str(window_size))
	_check(_source.collection.claim_exploration_item(label), label + " accepts one owner-issued collection change")
	_source.refresh()
	_check(_source.visible and _source.is_collected() and not _source.is_available(), label + " leaves a settled empty sleeve")
	_check(not _source.try_interact() and _source.snapshot().clock == 0.0, label + " collected sleeve cannot replay a claim or bob")
	_check(_source.collection.snapshot().offcuts == 0 and _source.collection.snapshot().hunts == empty.hunts, label + " source never grants farming materials or clears")

func _gather_route() -> void:
	await _fixture(Catalog.definition(&"horn_plaza", &"seam_lining"))
	var balcony := _room.get_node("LostPressingBalcony") as StaticBody2D
	var collider := balcony.get_child(0) as CollisionShape2D
	_check(Rect2(balcony.position - collider.shape.size * 0.5, collider.shape.size) == BALCONY, "plaza balcony is exactly 200px above the ordinary floor")
	_check(_room.air_density == 0.0 and _room.air_strikes_max == 0, "plaza retains its dry air")
	# Gear alters handling but never jump rise. Try both approaches and a
	# maximum-speed run; each must land on the old road below the sleeve.
	for approach in [Vector2(350, 574), Vector2(650, 574)]:
		await _reset_at(approach)
		_player.apply_equipment({"speed": 1.4, "accel": 1.4, "air_control": 1.4})
		_player.velocity.x = signf(500.0 - approach.x) * Skip.RUN_SPEED * 1.4
		Input.action_press("jump")
		var reached := false
		for frame in 100:
			_axis(500.0)
			await _physics(1)
			reached = reached or _on_balcony()
		_check(not reached, "ordinary jump cannot reach high sleeve from " + str(approach))
		_release()
	_player.apply_equipment({})
	_room.abilities.unlock_ability(&"strike")
	_room.progression.unlock_refrain(Progression.Refrain.GATHER)
	await _reset_at(Vector2(350, 574))
	Input.action_press("jump")
	await _physics(15)
	Input.action_press("strike")
	await _physics(1)
	Input.action_release("strike")
	var landed := false
	for frame in 110:
		_axis(500.0)
		await _physics(1)
		if _on_balcony():
			landed = true
			break
	_release()
	_check(landed, "jump, Gather strike and steering reach the sleeve; actual " + str(_player.position))
	_check(_player.position.distance_to(_source.position) <= Fixture.INTERACT_RADIUS and _source.try_interact(), "earned landing can claim from its real supported origin")
	Input.action_press("move_right")
	for frame in 120:
		await _physics(1)
		if _player.position.x > 655.0: Input.action_release("move_right")
		if _player.is_on_floor() and absf(_player.position.y - 574.0) < 1.0: break
	_release()
	_check(_player.is_on_floor() and absf(_player.position.y - 574.0) < 1.0, "walking off the optional balcony returns safely to the existing road")
	_check(_room.session_outcomes.is_empty() and _player.shine == 0, "balcony route adds no story choice or Shine")

func _on_balcony() -> bool:
	return _player.is_on_floor() and absf(_player.position.y - 374.0) < 1.0 and _player.position.x >= 400.0 and _player.position.x <= 600.0

func _axis(target: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	var distance := target - _player.position.x
	var braking := Skip.RUN_FRICTION if _player.is_on_floor() else Skip.RUN_ACCEL * Skip.AIR_CONTROL
	var stopping := _player.velocity.x * _player.velocity.x / (2.0 * braking)
	if absf(distance) < 7.0 or (signf(distance) == signf(_player.velocity.x) and absf(distance) < stopping + 7.0): return
	Input.action_press("move_right" if distance > 0.0 else "move_left")

func _reset_at(origin: Vector2) -> void:
	_release()
	_player.position = origin
	_player.velocity = Vector2.ZERO
	_player._buffer = 0.0
	_player._coyote = 0.0
	_player._strike_cd = 0.0
	_player.cancel_pending_strike()
	await _physics(4)
	_player.velocity = Vector2.ZERO

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _release() -> void:
	for action in ACTIONS: Input.action_release(action)

func _close() -> void:
	_release()
	paused = false
	if is_instance_valid(_player): _player.free()
	if is_instance_valid(_room): _room.free()
	_player = null
	_room = null
	_source = null
	await process_frame

func _has_collision(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D: return true
	for child in node.get_children():
		if _has_collision(child): return true
	return false

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
