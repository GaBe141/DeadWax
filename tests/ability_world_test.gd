extends SceneTree
## Recovered moves are grounded, fixed-origin choices. The first movement
## gate has a physical return route and cannot be skipped with faster gear.

const Campaign := preload("res://scripts/campaign.gd")
const Chart := preload("res://scripts/campaign_chart.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Skip := preload("res://scripts/skip.gd")
const Pressing := preload("res://scripts/pressing_state.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "strike", "lift", "set", "enter_passage"]

var _checks := 0
var _failures: Array[String] = []
var _room: Node2D
var _player: CharacterBody2D
var _abilities: RefCounted
var _requests := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action): InputMap.add_action(action)
	_check(Campaign.room_ids().size() == 21 and Chart.LINKS.size() == 24, "the authored passage graph keeps its 21 rooms and 24 pairs")
	for record in Abilities.catalog():
		await _placement(record)
	await _interaction()
	await _counted_sleeve()
	await _market_gate()
	await _close()
	if _failures.is_empty():
		print("DEAD WAX ABILITY WORLD PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("ABILITY WORLD FAIL: " + failure)
	quit(1)

func _fixture(id: StringName) -> void:
	await _close()
	_abilities = Abilities.new()
	_room = Campaign.create_room(id)
	_room.abilities = _abilities
	_room.progression = Progression.new()
	root.add_child(_room)
	for actor in get_nodes_in_group("hears_strikes"):
		actor.set_process(false)
		actor.set_physics_process(false)
	_player = Skip.new()
	_player.abilities = _abilities
	_player.progression = _room.progression
	root.add_child(_player)
	_requests = 0
	_room.ability_requested.connect(func(_id: StringName, _source: Node2D) -> void: _requests += 1)
	await _physics(2)

func _placement(record: Dictionary) -> void:
	await _fixture(record.room_id)
	var pickup := _pickup(record.id)
	_check(pickup != null, "%s has a real campaign pickup" % record.id)
	if pickup == null: return
	_check(pickup.position == record.position, "%s has the catalog's fixed interaction origin" % record.id)
	_check(pickup.find_children("*", "CollisionObject2D", true, false).is_empty(), "%s adds no route-blocking collision" % record.id)
	var clear: bool = pickup.position.distance_to(_room.spawn_pos) > pickup.INTERACT_RADIUS
	for entry in _room.entry_points.values():
		clear = clear and pickup.position.distance_to(entry) > pickup.INTERACT_RADIUS
	_check(clear, "%s never collects from an arrival anchor" % record.id)
	await _reset_at(record.position)
	_check(_player.is_on_floor() and _player.position.distance_to(record.position) < 1.0, "%s rests on an actual reachable-height platform" % record.id)
	_check(_requests == 0 and not _abilities.has_ability(record.id), "%s contact alone grants no move" % record.id)
	var origin: Vector2 = pickup.position
	_room.apply_side(Pressing.Side.B)
	_check(pickup.ink == _room.bg_color and pickup.stock == _room.ink, "%s reinks on the B-side" % record.id)
	_room.apply_side(Pressing.Side.A)
	_check(pickup.ink == _room.ink and pickup.stock == _room.bg_color, "%s restores its authored palette" % record.id)
	_room.set_scenery_motion(true)
	var before: Dictionary = pickup.snapshot()
	await _physics(5)
	_check(pickup.position == origin and pickup.snapshot().clock == 0.0 and before.clock == 0.0, "%s reduced-motion drawing leaves its origin fixed" % record.id)

func _interaction() -> void:
	await _fixture(&"headshell")
	var pickup := _pickup(&"strike")
	await _reset_at(Vector2(265, 554))
	Input.action_press("enter_passage")
	await _physics(2)
	_check(_requests == 0, "a press outside pickup reach is rejected")
	_player.position = Vector2(365, 554)
	_player.velocity = Vector2.ZERO
	await _physics(4)
	_check(_requests == 0, "holding interact while walking into range does not collect")
	Input.action_release("enter_passage")
	await _physics(2)
	Input.action_press("enter_passage")
	await _physics(2)
	_check(_requests == 1 and not _abilities.has_ability(&"strike"), "a fresh nearby press emits one intent and never owns the permission")
	await _physics(6)
	_check(_requests == 1 and pickup.visible, "a refused save leaves the same pickup without repeated held requests")
	_release()
	await _physics(2)
	Input.action_press("enter_passage")
	await _physics(2)
	_check(_requests == 2, "another fresh press can retry a refused pickup")
	_release()
	paused = true
	var frozen: Dictionary = pickup.snapshot()
	await process_frame
	_check(not pickup.try_interact() and pickup.snapshot() == frozen, "pause freezes the pickup and refuses interaction")
	paused = false
	_player.position.y -= 120
	_player.velocity = Vector2.ZERO
	await _physics(2)
	_check(not pickup.try_interact() and _requests == 2, "airborne proximity cannot collect a move")
	await _reset_at(Vector2(365, 554))
	_abilities.unlock_ability(&"strike")
	_room.refresh_abilities()
	await process_frame
	_check(_pickup(&"strike") == null and _abilities.has_ability(&"strike"), "only confirmed ownership silently retires the pickup")
	_check(_room.objective_label.contains("listening weight"), "recovering the needle advances the opening lead")
	# Restoring a room from owned state starts settled and emits no request.
	var restored: Node2D = Campaign.create_room(&"headshell")
	restored.abilities = _abilities
	root.add_child(restored)
	await process_frame
	var present := false
	for child in restored.get_children():
		if child.is_in_group("ability_pickup") and child.ability == &"strike": present = true
	_check(not present and _requests == 2, "silent room restoration does not replay acquisition")
	restored.free()

func _counted_sleeve() -> void:
	await _fixture(&"practice_room")
	var pickup := _pickup(&"groove")
	await _reset_at(Vector2(1320, 574))
	_check(not pickup.is_available() and not pickup.try_interact(), "the Plaza's rear entrance cannot bypass the Count-In sleeve")
	for outcome in ["freed", "shattered", "won"]:
		_room.session_outcomes["practice_room/practice_count_in"] = outcome
		_room.refresh_abilities()
		_check(not pickup.can_request(), "unrelated outcome %s does not open the sleeve" % outcome)
	_room.session_outcomes["label_descent/descent_count_in"] = "opened"
	_check(not pickup.can_request(), "a different listening door cannot unlock this sleeve")
	_room.session_outcomes["practice_room/practice_count_in"] = "opened"
	_room.refresh_abilities()
	_check(pickup.can_request() and pickup.try_interact() and _requests == 1, "the exact saved Count-In outcome makes the Groove claim available")
	_check(not _abilities.has_ability(&"groove"), "opening the door alone grants no move")

func _market_gate() -> void:
	await _fixture(&"the_stalls")
	_check(_room.objective_label.contains("Tick"), "the blocked span points back to the recoverable Groove")
	_player.equipment_speed = 1.4
	_player.equipment_accel = 1.4
	_player.equipment_air_control = 1.4
	for start in [Vector2(690, 574), Vector2(1430, 664)]:
		await _reset_at(start)
		_check(_player.is_on_floor(), "locked market approach begins grounded at %s" % start)
		Input.action_press("jump")
		Input.action_press("move_right")
		var crossed := false
		for frame in 95:
			await _physics(1)
			crossed = crossed or (_player.position.x >= 1360.0 and _player.position.y <= 455.0 and _player.is_on_floor())
		_check(not crossed, "ordinary jumping with maximum handling gear cannot cross from %s" % start)
		_release()
	# The live groove is also a solid 56px block. Running off its edge adds
	# both a foothold and coyote time, so the gate must survive that route too.
	for start_x in [610.0, 634.0]:
		for speed in [340.0, 476.0]:
			for delay in [0, 3]:
				_player.equipment_speed = speed / Skip.RUN_SPEED
				await _reset_at(Vector2(start_x, 518))
				_check(_player.is_on_floor(), "groove-top stress approach begins on the real block")
				_player.velocity.x = speed
				Input.action_press("move_right")
				await _physics(delay)
				Input.action_press("jump")
				var bypass := false
				for frame in 75:
					await _physics(1)
					bypass = bypass or (_player.position.x >= 753.0 and _player.position.y < 400.0 and _player.is_on_floor())
				_check(not bypass, "groove-top running jump stays gated at x%.0f speed%.0f delay%d" % [start_x, speed, delay])
				_release()
	_player.apply_equipment({})
	# A missed attempt costs no recovery: its low lane climbs back west.
	await _reset_at(Vector2(1030, 744))
	await _jump_toward(830.0, 659.0)
	_check(_player.is_on_floor() and absf(_player.position.y - 659.0) < 1.0, "the service floor returns to the western 85px step; actual %s" % _player.position)
	await _jump_toward(680.0, 574.0)
	_check(_player.is_on_floor() and absf(_player.position.y - 574.0) < 1.0, "the second ordinary jump returns to the original groove bank; actual %s" % _player.position)
	# The recovered move actually crosses the changed geometry under stock
	# movement and collision; the test does not teleport to the far bank.
	_abilities.unlock_ability(&"strike")
	_abilities.unlock_ability(&"groove")
	_room.refresh_abilities()
	_check(_room.objective_label.contains("live groove"), "recovering Groove replaces the blocked-route lead")
	await _reset_at(Vector2(615, 574))
	Input.action_press("jump")
	await _physics(8)
	Input.action_press("strike")
	Input.action_press("move_right")
	await _physics(1)
	Input.action_release("strike")
	var first_landing := false
	for frame in 100:
		_axis(955.0)
		await _physics(1)
		if _player.is_on_floor() and _player.position.x >= 770.0 and _player.position.y < 400.0:
			first_landing = true
			break
	_release()
	_check(first_landing, "earned Groove reaches the high market platform; actual %s" % _player.position)
	if first_landing:
		await _jump_toward(1150.0, 366.0)
		_check(_player.is_on_floor() and _player.position.x >= 1090.0 and _player.position.y < 400.0, "the first landing joins the ordinary upper platform route")
		Input.action_press("move_right")
		for frame in 125:
			await _physics(1)
			if _player.position.x >= 1460.0 and _player.is_on_floor(): break
		_release()
		_check(_player.position.x >= 1360.0 and absf(_player.position.y - 454.0) < 1.0, "the earned route reaches the eastern bank without another unlock")

func _pickup(id: StringName) -> Node2D:
	if not is_instance_valid(_room): return null
	for child in _room.get_children():
		if child.is_in_group("ability_pickup") and child.ability == id:
			return child
	return null

func _jump_toward(x: float, _y: float) -> void:
	_release()
	await _physics(2)
	Input.action_press("jump")
	for frame in 100:
		_axis(x)
		await _physics(1)
		if frame > 2 and _player.is_on_floor(): break
	_release()
	await _physics(3)

func _axis(x: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	if absf(x - _player.position.x) > 10.0:
		Input.action_press("move_right" if x > _player.position.x else "move_left")

func _reset_at(position: Vector2) -> void:
	_release()
	_player.position = position
	_player.velocity = Vector2.ZERO
	_player._buffer = 0.0
	_player._coyote = 0.0
	_player._strike_cd = 0.0
	_player.cancel_pending_strike()
	await _physics(4)

func _physics(frames: int) -> void:
	for frame in frames:
		await physics_frame
		await process_frame

func _release() -> void:
	for action in ACTIONS:
		Input.action_release(action)

func _close() -> void:
	_release()
	if is_instance_valid(_player): _player.free()
	if is_instance_valid(_room): _room.free()
	_player = null
	_room = null
	await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
