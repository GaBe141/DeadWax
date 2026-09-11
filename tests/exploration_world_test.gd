extends SceneTree
## The two earned returns reuse existing floors. Every arrival is safe before
## any interaction, and the receiver reward has an ordinary-jump way back up.

const Campaign := preload("res://scripts/campaign.gd")
const Catalog := preload("res://scripts/exploration_catalog.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Discoveries := preload("res://scripts/discoveries_state.gd")
const MapState := preload("res://scripts/map_state.gd")
const Skip := preload("res://scripts/skip.gd")
const Pressing := preload("res://scripts/pressing_state.gd")
const EchoTrial := preload("res://scripts/echo_trial.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "strike", "lift", "set", "enter_passage"]
const ARRIVALS := {
	&"headshell": {"entry": &"from_deep_gallery", "position": Vector2(760, 494), "exit": Vector2(1120, 554), "solids": 4},
	&"high_street": {"entry": &"from_verse_warren_n", "position": Vector2(470, 574), "exit": Vector2(85, 574), "solids": 7},
	&"verse_warren_n": {"entry": &"from_high_street", "position": Vector2(1390, 454), "exit": Vector2(1600, 454), "solids": 9},
	&"deep_gallery": {"entry": &"from_headshell", "position": Vector2(1020, 834), "exit": Vector2(1800, 834), "solids": 7},
}

var _checks := 0
var _failures: Array[String] = []
var _room: Node2D
var _player: CharacterBody2D
var _map_collections := 0
var _refrain_collections := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action): InputMap.add_action(action)
	_check(Catalog.endpoints().size() == 4, "two return seams have four fixed campaign endpoints")
	for room_id in ARRIVALS:
		await _arrival(room_id)
	await _reward_return()
	await _close()
	if _failures.is_empty():
		print("DEAD WAX EXPLORATION WORLD PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("EXPLORATION WORLD FAIL: " + failure)
	quit(1)

func _fixture(id: StringName) -> void:
	await _close()
	_room = Campaign.create_room(id)
	_room.abilities = Abilities.new()
	_room.abilities.unlock_ability(&"walk")
	_room.progression = Progression.new()
	if "discoveries" in _room: _room.discoveries = Discoveries.new()
	if "map_state" in _room: _room.map_state = MapState.new()
	_map_collections = 0
	_refrain_collections = 0
	if _room.has_signal("map_collected"):
		_room.map_collected.connect(func() -> void: _map_collections += 1)
	_room.refrain_collected.connect(func(_id: int) -> void: _refrain_collections += 1)
	root.add_child(_room)
	# This is a traversal test; authored actors retain their identities and
	# outcomes but do not interrupt the measured jumps with combat.
	for actor in get_nodes_in_group("hears_strikes"):
		actor.set_process(false)
		actor.set_physics_process(false)
	_player = Skip.new()
	_player.abilities = _room.abilities
	_player.progression = _room.progression
	_player.position = Vector2(100, -300)
	root.add_child(_player)
	await _physics(2)

func _arrival(id: StringName) -> void:
	await _fixture(id)
	var record: Dictionary = ARRIVALS[id]
	var endpoint: Dictionary = Catalog.endpoints_for(id)[0]
	_check(_room.entry_points.get(record.entry) == record.position, "%s registers its exact return arrival" % id)
	_check(_room._skins.size() == record.solids, "%s keeps all existing platform geometry" % id)
	_check(get_nodes_in_group("reverse_passage").is_empty(), "%s factory leaves new passage installation to Main" % id)
	var counterpart := Catalog.definition(endpoint.target_room, endpoint.id)
	_check(counterpart.get("target_room") == id and counterpart.get("target_entry") == record.entry, "%s reciprocal endpoint targets its registered arrival" % id)
	_check(record.position.distance_to(endpoint.position) > 76.0, "%s arrival is outside its return seam's interaction reach" % id)
	_check(endpoint.position.distance_to(_room.spawn_pos) > 76.0, "%s seam is clear of the original spawn" % id)
	for entry in _room.entry_points:
		_check(endpoint.position.distance_to(_room.entry_points[entry]) > 76.0, "%s seam is clear of arrival %s" % [id, entry])
	_check_fixture_clearance(endpoint.position, "%s seam" % id)
	_check_arrival_clearance(record.position, id)
	await _reset_at(endpoint.position)
	_check(_grounded_at(endpoint.position), "%s interaction rests on an existing floor" % id)
	await _reset_at(record.position)
	_check(_grounded_at(record.position), "%s arrival has real standing support" % id)
	await _physics(12)
	_check(_map_collections == 0 and _refrain_collections == 0, "%s arrival does not auto-collect a map or Refrain" % id)
	_check(_room.progression.unlocked_refrains().is_empty(), "%s arrival grants no traversal permission" % id)
	var original_entries: Dictionary = _room.entry_points.duplicate(true)
	for side in [Pressing.Side.B, Pressing.Side.A]:
		_room.apply_side(side)
		await _physics(3)
		_check(_room.entry_points == original_entries and _grounded_at(record.position), "%s turning the pressing preserves its supported arrivals" % id)
	await _walk_to(record.exit.x)
	_check(_grounded_at(record.exit, 13.0), "%s new arrival walks back to an existing campaign passage; actual %s" % [id, _player.position])
	_check(_room.session_outcomes.is_empty() and _player.shine == 0, "%s return changes no encounter choice or income" % id)
	# The far endpoints are reached from the existing campaign approach with
	# ordinary movement, before Jump-Cut is owned or either seam is opened.
	if bool(endpoint.far_end):
		var approach: Vector2 = _room.entry_position(&"from_verse_hall") if id == &"verse_warren_n" else _room.entry_position(&"from_verse_warren_s")
		await _reset_at(approach)
		await _walk_to(endpoint.position.x)
		_check(_grounded_at(endpoint.position, 13.0), "%s far seam is reachable from the existing road with Walk alone" % id)

func _check_fixture_clearance(origin: Vector2, label: String) -> void:
	for child in _room.get_children():
		var radius := _interact_radius(child)
		if radius > 0.0:
			_check(origin.distance_to(child.position) > 76.0 + radius, "%s cannot share fresh interaction input with %s" % [label, child.name])
		if child.is_in_group("map_pickup") or child.is_in_group("refrain_pickup"):
			_check(origin.distance_to(child.position) > 76.0 + child.COLLECT_RADIUS, "%s interaction reach stays outside %s automatic collection" % [label, child.name])
	if _room.room_id == &"deep_gallery":
		_check(origin.distance_to(EchoTrial.PROFILES[&"unplayed"].position) > 152.0, "%s stays clear of Main's existing Echo Trial" % label)
	var reward := Catalog.reward()
	if _room.room_id == reward.room_id and origin != reward.position:
		_check(origin.distance_to(reward.position) > 152.0, "%s stays clear of the earned Jump-Cut pickup" % label)

func _check_arrival_clearance(origin: Vector2, id: StringName) -> void:
	for child in _room.get_children():
		if child.is_in_group("map_pickup") or child.is_in_group("refrain_pickup"):
			_check(origin.distance_to(child.position) > child.COLLECT_RADIUS, "%s arrival is outside %s automatic collection" % [id, child.name])
		var radius := _interact_radius(child)
		if radius > 0.0:
			_check(origin.distance_to(child.position) > radius, "%s arrival does not sit inside %s interaction" % [id, child.name])
	var reward := Catalog.reward()
	if id == reward.room_id:
		_check(origin.distance_to(reward.position) > 76.0, "%s return arrival cannot claim Jump-Cut merely by entering" % id)

func _interact_radius(actor: Node) -> float:
	if actor.is_in_group("room_exit"): return 76.0
	if actor.is_in_group("ability_pickup") or actor.is_in_group("echo_discovery"): return 76.0
	if actor.has_method("try_listen"): return actor.LISTEN_RADIUS
	return 0.0

func _reward_return() -> void:
	var reward := Catalog.reward()
	await _fixture(reward.room_id)
	_check(reward.position == Vector2(350, 834), "Jump-Cut is on the quiet floor below the northern receiver")
	_check_fixture_clearance(reward.position, "Jump-Cut reward")
	for entry in _room.entry_points:
		_check(reward.position.distance_to(_room.entry_points[entry]) > 76.0, "Jump-Cut is clear of arrival %s" % entry)
	await _reset_at(Vector2(350, 454))
	# Walk off the inner terrace and its next shelf, then turn left from the
	# lower step. The narrow gap directly beside the terrace is not a route.
	await _walk_to(710.0)
	await _walk_to(reward.position.x)
	_check(_grounded_at(reward.position, 13.0), "the receiver's lower reward can be reached without an airborne strike; actual %s" % _player.position)
	# Return via the room's original 100, 100, 90 and 90px steps. All other
	# core moves and all Refrains remain locked throughout this sequence.
	await _walk_to(450.0)
	await _jump_to(585.0)
	_check(_player.is_on_floor() and absf(_player.position.y - 734.0) < 1.0, "the lower floor returns to the first 100px step; actual %s" % _player.position)
	await _walk_to(680.0)
	await _jump_to(820.0)
	_check(_player.is_on_floor() and absf(_player.position.y - 634.0) < 1.0, "the second 100px step stays reachable without Gather; actual %s" % _player.position)
	await _walk_to(790.0)
	await _jump_to(590.0)
	_check(_player.is_on_floor() and absf(_player.position.y - 544.0) < 1.0, "the first 90px step clears its upper overhang; actual %s" % _player.position)
	await _walk_to(540.0)
	await _jump_to(430.0)
	await _walk_to(350.0)
	_check(_grounded_at(Vector2(350, 454), 13.0), "the final ordinary jump returns to the receiver; actual %s" % _player.position)
	_check(_room.abilities.snapshot().unlocked == ["walk"] and _room.progression.unlocked_refrains().is_empty(), "the entire receiver reward route uses only recovered Walk and the starting jump")
	_check(_room.session_outcomes.is_empty() and _player.shine == 0, "the reward's staging adds no encounter outcome or Shine")

func _grounded_at(origin: Vector2, tolerance := 1.0) -> bool:
	return _player.is_on_floor() and _player.position.distance_to(origin) < tolerance

func _walk_to(x: float) -> void:
	for frame in 240:
		_axis(x)
		await _physics(1)
		if absf(_player.position.x - x) < 9.0 and absf(_player.velocity.x) < 1.0 and _player.is_on_floor(): break
	_release()
	await _physics(3)

func _jump_to(x: float) -> void:
	_release()
	await _physics(2)
	Input.action_press("jump")
	for frame in 110:
		_axis(x)
		await _physics(1)
		if frame > 2 and _player.is_on_floor(): break
	_release()
	await _physics(3)

func _axis(x: float) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	var distance := x - _player.position.x
	var braking := Skip.RUN_FRICTION if _player.is_on_floor() else Skip.RUN_ACCEL * Skip.AIR_CONTROL
	var stopping := _player.velocity.x * _player.velocity.x / (2.0 * braking)
	if absf(distance) < 7.0 or (signf(distance) == signf(_player.velocity.x) and absf(distance) < stopping + 7.0): return
	Input.action_press("move_right" if distance > 0.0 else "move_left")

func _reset_at(position: Vector2) -> void:
	_release()
	_player.position = position
	_player.velocity = Vector2.ZERO
	_player._buffer = 0.0
	_player._coyote = 0.0
	await _physics(4)

func _physics(frames: int) -> void:
	for frame in frames:
		await physics_frame
		await process_frame

func _release() -> void:
	for action in ACTIONS: Input.action_release(action)

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
