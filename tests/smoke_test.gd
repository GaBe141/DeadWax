extends SceneTree
## Dependency-free headless validation for Dead Wax.
## Run with: .\deadwax.cmd test

const SkipScript := preload("res://scripts/skip.gd")
const TestPressingScript := preload("res://scripts/test_pressing.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const RoomLabelScript := preload("res://scripts/room_label.gd")

const EXPECTED_STRATA := 6
const EXPECTED_WORLD_ROOMS := 53
const EXPECTED_PROTOTYPE_ROOMS := [
	"THE LABEL",
	"THE PRACTICE ROOM",
	"THE VERSE — a warren of the Unplayed",
	"THE UNPLAYED",
	"THE SMOOTHED FLOOR",
]
const REQUIRED_INPUT_ACTIONS := [
	"move_left",
	"move_right",
	"move_up",
	"move_down",
	"jump",
	"strike",
	"lift",
	"set",
	"restart",
	"switch_room",
]

var _checks := 0
var _failures: Array[String] = []
var _parried_events := 0
var _shattered_events := 0
var _bout_won_events := 0
var _combat_event_order: Array[String] = []
var _observed_dummy: Node
var _strike_target: Node
var _refrain_events: Array[int] = []
var _technique_events: Array[int] = []
var _launch_events: Array[bool] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_progression_state()
	await _check_gather_player()
	_check_gather_route_geometry()
	_check_world_map()
	await _check_project_boot()
	await _check_combat_regressions()

	if _failures.is_empty():
		print("DEAD WAX SMOKE PASS (%d checks)" % _checks)
		quit(0)
		return

	for failure in _failures:
		push_error("SMOKE FAIL: %s" % failure)
	push_error("DEAD WAX SMOKE FAILED: %d issue(s), %d checks" % [_failures.size(), _checks])
	quit(1)

func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)

func _check_progression_state() -> void:
	var state := ProgressionScript.new()
	_refrain_events.clear()
	_technique_events.clear()
	state.refrain_unlocked.connect(_record_refrain_unlocked)
	state.technique_discovered.connect(_record_technique_discovered)

	_expect(not state.has_refrain(ProgressionScript.Refrain.GATHER), "Gather starts locked")
	_expect(not state.has_refrain(ProgressionScript.Refrain.REST), "Rest starts locked")
	_expect(not state.has_refrain(ProgressionScript.Refrain.JUMP_CUT), "Jump-Cut starts locked")
	_expect(
		not state.knows_technique(ProgressionScript.Technique.COUNT_IN),
		"Count-In starts undiscovered but remains knowledge-executable"
	)
	_expect(
		not state.knows_technique(ProgressionScript.Technique.STEP_TURN),
		"Step-Turn starts undiscovered"
	)
	_expect(state.unlock_refrain(ProgressionScript.Refrain.GATHER), "Gather unlock succeeds once")
	_expect(
		not state.unlock_refrain(ProgressionScript.Refrain.GATHER),
		"duplicate Gather unlock is idempotent"
	)
	_expect(
		_refrain_events == [ProgressionScript.Refrain.GATHER],
		"Gather unlock emits exactly one progression event"
	)
	_expect(
		state.discover_technique(ProgressionScript.Technique.COUNT_IN),
		"Count-In discovery succeeds once"
	)
	_expect(
		not state.discover_technique(ProgressionScript.Technique.COUNT_IN),
		"duplicate Count-In discovery is idempotent"
	)
	_expect(
		_technique_events == [ProgressionScript.Technique.COUNT_IN],
		"Count-In discovery emits exactly one knowledge event"
	)

	var saved := state.snapshot()
	var restored := ProgressionScript.new()
	restored.unlock_refrain(ProgressionScript.Refrain.REST)
	restored.discover_technique(ProgressionScript.Technique.STEP_TURN)
	_refrain_events.clear()
	_technique_events.clear()
	restored.refrain_unlocked.connect(_record_refrain_unlocked)
	restored.technique_discovered.connect(_record_technique_discovered)
	_expect(restored.restore_snapshot(saved), "progression snapshot restores")
	_expect(restored.has_refrain(ProgressionScript.Refrain.GATHER), "snapshot preserves Gather")
	_expect(not restored.has_refrain(ProgressionScript.Refrain.REST), "snapshot restore replaces old Refrains")
	_expect(
		restored.knows_technique(ProgressionScript.Technique.COUNT_IN),
		"snapshot preserves Count-In discovery"
	)
	_expect(
		not restored.knows_technique(ProgressionScript.Technique.STEP_TURN),
		"snapshot restore replaces old technique discoveries"
	)
	_expect(_refrain_events.is_empty(), "snapshot restore does not replay Refrain signals")
	_expect(_technique_events.is_empty(), "snapshot restore does not replay technique signals")
	_expect(
		not restored.restore_snapshot({"version": 999}),
		"unknown progression snapshot versions are rejected"
	)
	_expect(
		restored.has_refrain(ProgressionScript.Refrain.GATHER),
		"rejected progression snapshots leave existing Refrains unchanged"
	)
	_expect(
		restored.knows_technique(ProgressionScript.Technique.COUNT_IN),
		"rejected progression snapshots leave existing techniques unchanged"
	)

func _check_gather_player() -> void:
	for action in [&"move_left", &"move_right", &"move_up", &"move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var state := ProgressionScript.new()
	var player := SkipScript.new()
	player.progression = state
	player.air_density = 0.0
	player.air_strikes_max = 0
	root.add_child(player)
	_launch_events.clear()
	player.struck.connect(_record_launch)

	player.refill_air_strikes()
	_expect(player.air_strikes_left == 0, "dry rooms have no breath before Gather")
	player.call("_strike")
	_expect(player.velocity.is_zero_approx(), "a dry strike cannot launch before Gather")

	state.unlock_refrain(ProgressionScript.Refrain.GATHER)
	player.refill_air_strikes()
	_expect(is_zero_approx(player.air_density), "Gather does not mutate the room's air density")
	_expect(player.air_strike_capacity() == 1, "Gather grants one breath in dry rooms")
	player.call("_strike")
	_expect(not player.velocity.is_zero_approx(), "Gather launches once in dry air")
	_expect(player.air_strikes_left == 0, "the Gather breath is consumed")
	player.velocity = Vector2.ZERO
	player.call("_strike")
	_expect(player.velocity.is_zero_approx(), "Gather cannot launch twice before a refill")
	_expect(_launch_events == [false, true, false], "dry Gather strike results are locked, launch, spent")

	player.air_strikes_max = 2
	player.refill_air_strikes()
	_expect(player.air_strike_capacity() == 2, "Gather does not stack onto environmental breaths")
	player.queue_free()
	await process_frame

func _record_launch(_pos: Vector2, _big: bool, launched: bool) -> void:
	_launch_events.append(launched)

func _check_gather_route_geometry() -> void:
	const PLAYER_HEIGHT := 52.0
	const LABEL_FLOOR_TOP := 580.0
	const LABEL_GROOVE_X := 760.0
	var standing_center := LABEL_FLOOR_TOP - PLAYER_HEIGHT / 2.0
	var shelf_top: float = RoomLabelScript.GATHER_SHELF_POS.y - RoomLabelScript.GATHER_SHELF_SIZE.y / 2.0
	var landing_center := shelf_top - PLAYER_HEIGHT / 2.0
	var required_rise := standing_center - landing_center
	var jump_rise: float = SkipScript.JUMP_VELOCITY * SkipScript.JUMP_VELOCITY / (2.0 * SkipScript.GRAVITY)
	var gather_rise: float = SkipScript.AIR_IMPULSE * SkipScript.AIR_IMPULSE / (2.0 * SkipScript.GRAVITY)
	_expect(required_rise > jump_rise, "the Label return shelf is above an ordinary jump")
	_expect(required_rise < jump_rise + gather_rise, "one staged Gather breath can reach the Label shelf")

	var baffle_left: float = RoomLabelScript.GATHER_BAFFLE_POS.x - RoomLabelScript.GATHER_BAFFLE_SIZE.x / 2.0
	var shelf_right: float = RoomLabelScript.GATHER_SHELF_POS.x + RoomLabelScript.GATHER_SHELF_SIZE.x / 2.0
	var baffle_bottom: float = RoomLabelScript.GATHER_BAFFLE_POS.y + RoomLabelScript.GATHER_BAFFLE_SIZE.y / 2.0
	_expect(
		baffle_left <= shelf_right
		and RoomLabelScript.GATHER_BAFFLE_POS.x > RoomLabelScript.GATHER_SHELF_POS.x
		and baffle_left < LABEL_GROOVE_X,
		"the dry baffle joins the shelf and separates it from the live groove"
	)
	_expect(LABEL_FLOOR_TOP - baffle_bottom > PLAYER_HEIGHT, "the player can walk beneath the dry baffle")

func _record_refrain_unlocked(refrain: int) -> void:
	_refrain_events.append(refrain)

func _record_technique_discovered(technique: int) -> void:
	_technique_events.append(technique)

func _check_world_map() -> void:
	var file := FileAccess.open("res://data/world_map.json", FileAccess.READ)
	_expect(file != null, "world_map.json opens")
	if file == null:
		return

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	_expect(
		parse_error == OK,
		"world_map.json parses (line %d: %s)" % [parser.get_error_line(), parser.get_error_message()]
	)
	if parse_error != OK:
		return

	var parsed: Variant = parser.data
	_expect(parsed is Dictionary, "world map root is an object")
	if not (parsed is Dictionary):
		return
	var world: Dictionary = parsed

	_expect(int(world.get("version", 0)) > 0, "world map version is positive")
	_expect(int(world.get("grid_cell", 0)) > 0, "world map grid_cell is positive")

	var strata_value: Variant = world.get("strata", [])
	var rooms_value: Variant = world.get("rooms", [])
	_expect(strata_value is Array, "world map strata is an array")
	_expect(rooms_value is Array, "world map rooms is an array")
	if not (strata_value is Array) or not (rooms_value is Array):
		return

	var strata: Array = strata_value
	var rooms: Array = rooms_value
	_expect(strata.size() == EXPECTED_STRATA, "world map has %d strata" % EXPECTED_STRATA)
	_expect(rooms.size() == EXPECTED_WORLD_ROOMS, "world map has %d rooms" % EXPECTED_WORLD_ROOMS)

	var stratum_ids := {}
	for stratum_value in strata:
		_expect(stratum_value is Dictionary, "each stratum is an object")
		if not (stratum_value is Dictionary):
			continue
		var stratum: Dictionary = stratum_value
		var stratum_id := String(stratum.get("id", ""))
		_expect(not stratum_id.is_empty(), "each stratum has an id")
		if stratum_id.is_empty():
			continue
		_expect(not stratum_ids.has(stratum_id), "stratum id '%s' is unique" % stratum_id)
		stratum_ids[stratum_id] = true

	var room_ids := {}
	for room_value in rooms:
		_expect(room_value is Dictionary, "each room is an object")
		if not (room_value is Dictionary):
			continue
		var room_data: Dictionary = room_value
		var room_id := String(room_data.get("id", ""))
		_expect(not room_id.is_empty(), "each room has an id")
		if room_id.is_empty():
			continue
		_expect(not room_ids.has(room_id), "room id '%s' is unique" % room_id)
		room_ids[room_id] = true
		_expect(
			stratum_ids.has(String(room_data.get("stratum", ""))),
			"room '%s' references a known stratum" % room_id
		)
		_expect(float(room_data.get("w", 0.0)) > 0.0, "room '%s' has positive width" % room_id)
		_expect(float(room_data.get("h", 0.0)) > 0.0, "room '%s' has positive height" % room_id)
		if room_id == "practice_room":
			var practice_tags: Array = room_data.get("tags", [])
			var practice_rewards: Array = room_data.get("rewards", [])
			_expect("technique" in practice_tags, "world map classifies Count-In as a technique")
			_expect("refrain" not in practice_tags, "world map no longer classifies Count-In as a Refrain")
			_expect("tech:count-in" in practice_rewards, "world map uses Count-In's canonical technique id")

	for room_value in rooms:
		if not (room_value is Dictionary):
			continue
		var room_data: Dictionary = room_value
		var room_id := String(room_data.get("id", "<unknown>"))
		var specials_value: Variant = room_data.get("specials", [])
		_expect(specials_value is Array, "room '%s' specials is an array" % room_id)
		if not (specials_value is Array):
			continue
		for special_value in specials_value:
			_expect(special_value is Dictionary, "room '%s' special is an object" % room_id)
			if not (special_value is Dictionary):
				continue
			var special: Dictionary = special_value
			var target := String(special.get("to", ""))
			_expect(room_ids.has(target), "room '%s' special target '%s' exists" % [room_id, target])

func _check_project_boot() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_expect(packed != null, "main scene loads")
	if packed == null:
		return

	var initial_master_effects := AudioServer.get_bus_effect_count(0)
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	_expect(main.get("player") != null, "main creates the player")
	_expect(main.get("camera") != null, "main creates the camera")
	_expect(main.get("audio") != null, "main creates the audio bank")
	_expect(main.get("progression") != null, "main owns the session progression state")
	var boot_player: CharacterBody2D = main.get("player")
	_expect(
		boot_player.progression == main.get("progression"),
		"main injects one progression state into the player"
	)

	for action in REQUIRED_INPUT_ACTIONS:
		_expect(InputMap.has_action(action), "input action '%s' exists" % action)

	for index in EXPECTED_PROTOTYPE_ROOMS.size():
		main.call("_load_room", index)
		await process_frame
		await process_frame

		var room := main.get("room") as Node2D
		_expect(room != null, "prototype room %d instantiates" % index)
		if room == null:
			continue
		_expect(
			String(room.get("band_name")) == EXPECTED_PROTOTYPE_ROOMS[index],
			"prototype room %d is %s" % [index, EXPECTED_PROTOTYPE_ROOMS[index]]
		)
		var spawn: Vector2 = room.get("spawn_pos")
		_expect(is_finite(spawn.x) and is_finite(spawn.y), "room '%s' spawn is finite" % room.get("band_name"))
		_expect(is_finite(float(room.get("death_y"))), "room '%s' death plane is finite" % room.get("band_name"))
		var limits: Rect2 = room.get("cam_limits")
		_expect(limits.size.x > 0.0 and limits.size.y > 0.0, "room '%s' camera bounds are positive" % room.get("band_name"))

	# Gather is earned at The Unplayed's exit and survives room recreation.
	main.call("_load_room", 3)
	await process_frame
	await process_frame
	var unplayed := main.get("room") as Node2D
	var pickups := _room_group_members(unplayed, &"refrain_pickup")
	_expect(pickups.size() == 1, "The Unplayed presents one Gather pickup while locked")
	var session_progression: RefCounted = main.get("progression")
	_refrain_events.clear()
	session_progression.connect("refrain_unlocked", _record_refrain_unlocked)
	if not pickups.is_empty():
		var collection_player: CharacterBody2D = main.get("player")
		collection_player.global_position = pickups[0].global_position
	await process_frame
	await process_frame
	_expect(
		bool(session_progression.call("has_refrain", ProgressionScript.Refrain.GATHER)),
		"approaching the Unplayed pickup unlocks Gather"
	)
	_expect(
		_refrain_events == [ProgressionScript.Refrain.GATHER],
		"the Gather pickup emits one session unlock"
	)
	var post_collection_player: CharacterBody2D = main.get("player")
	_expect(post_collection_player.air_strikes_left == 2, "Gather unlock reapplies The Unplayed's capacity immediately")

	var expected_capacity := [1, 1, 1, 2, 1]
	var expected_density := [0.0, 0.0, 0.35, 1.0, 0.0]
	for index in EXPECTED_PROTOTYPE_ROOMS.size():
		main.call("_load_room", index)
		await process_frame
		await process_frame
		var current_player: CharacterBody2D = main.get("player")
		var current_room: Node2D = main.get("room")
		_expect(main.get("progression") == session_progression, "progression survives room %d recreation" % index)
		_expect(
			current_player.air_strike_capacity() == expected_capacity[index],
			"Gather capacity respects room %d's environmental maximum" % index
		)
		_expect(
			is_equal_approx(float(current_room.get("air_density")), expected_density[index]),
			"Gather leaves room %d's air density unchanged" % index
		)

	main.call("_load_room", 0)
	await process_frame
	await process_frame
	var gathered_player: CharacterBody2D = main.get("player")
	gathered_player.air_strikes_left = 0
	main.call("_respawn")
	_expect(gathered_player.air_strikes_left == 1, "respawning in dry wax refills Gather's breath")

	main.call("_load_room", 3)
	await process_frame
	await process_frame
	unplayed = main.get("room") as Node2D
	_expect(
		_room_group_members(unplayed, &"refrain_pickup").is_empty(),
		"The Unplayed does not respawn an acquired Gather pickup"
	)
	var gathered_unplayed_player: CharacterBody2D = main.get("player")
	_expect(gathered_unplayed_player.air_strike_capacity() == 2, "The Unplayed remains a two-breath room")

	_technique_events.clear()
	session_progression.connect("technique_discovered", _record_technique_discovered)
	main.call("_on_door_opened")
	main.call("_on_door_opened")
	_expect(
		bool(session_progression.call("knows_technique", ProgressionScript.Technique.COUNT_IN)),
		"opening a count-in door records the knowledge technique"
	)
	_expect(
		_technique_events == [ProgressionScript.Technique.COUNT_IN],
		"Count-In discovery is recorded once without gating execution"
	)

	var audio := main.get("audio") as Node
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	while AudioServer.get_bus_effect_count(0) > initial_master_effects:
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	# Give the audio thread a pair of frames to release transient pickup SFX.
	await process_frame
	await process_frame
	main.queue_free()
	await process_frame
	await process_frame

func _room_group_members(current_room: Node, group: StringName) -> Array[Node]:
	var result: Array[Node] = []
	for node in get_nodes_in_group(group):
		if current_room.is_ancestor_of(node):
			result.append(node)
	return result

func _check_combat_regressions() -> void:
	_expect(
		is_equal_approx(float(SkipScript.POGO_RANGE), float(TestPressingScript.STRIKE_HIT_RANGE)),
		"Test Pressing hit reach matches the player's pogo reach"
	)
	_expect(
		is_equal_approx(float(SkipScript.POGO_RANGE), float(AuditionerScript.STRIKE_HIT_RANGE)),
		"Auditioner hit reach matches the player's pogo reach"
	)

	var player := SkipScript.new()
	root.add_child(player)
	player.air_strikes_max = 2
	player.struck.connect(_relay_strike)

	var range_dummy := TestPressingScript.new()
	root.add_child(range_dummy)
	_strike_target = range_dummy
	player.global_position = Vector2.ZERO
	range_dummy.global_position = Vector2(SkipScript.POGO_RANGE, 0.0)
	player.velocity = Vector2.ZERO
	player.air_strikes_left = 0
	player.call("_strike")
	_expect(range_dummy.hp < TestPressingScript.HP_MAX, "pogo-range strike damages its target")
	_expect(not player.velocity.is_zero_approx(), "pogo-range strike launches the player")
	_expect(player.air_strikes_left == 2, "successful pogo refills air strikes")

	range_dummy.hp = TestPressingScript.HP_MAX
	range_dummy.resonance = 0.0
	range_dummy.global_position = Vector2(SkipScript.POGO_RANGE + 1.0, 0.0)
	player.velocity = Vector2.ZERO
	player.air_strikes_left = 0
	player.call("_strike")
	_expect(
		is_equal_approx(range_dummy.hp, TestPressingScript.HP_MAX),
		"out-of-range strike does not damage a pogo target"
	)
	_expect(player.velocity.is_zero_approx(), "out-of-range strike does not pogo")
	_expect(player.air_strikes_left == 0, "failed pogo does not refill air strikes")
	range_dummy.queue_free()
	_strike_target = null
	player.struck.disconnect(_relay_strike)
	await process_frame

	var normal_dummy := TestPressingScript.new()
	root.add_child(normal_dummy)
	normal_dummy.set("_player", player)
	normal_dummy.set("state", TestPressingScript.S.SWING)
	normal_dummy.set("resonance", 0.8)
	_reset_combat_events()
	_connect_combat_events(normal_dummy)
	player.last_strike_ms = Time.get_ticks_msec()
	normal_dummy.call("_resolve_swing", 0.0)
	_expect(_parried_events == 1, "resonance-completing parry emits parried once")
	_expect(_shattered_events == 1, "resonance-completing parry emits shattered once")
	_expect(_bout_won_events == 0, "normal parry never emits muted bout victory")
	_expect(
		int(normal_dummy.get("state")) == int(TestPressingScript.S.DOWN),
		"resonance-completing parry leaves the Test Pressing down"
	)
	_expect(
		_combat_event_order == [
			"parried:%d" % TestPressingScript.S.STAGGER,
			"shattered:%d" % TestPressingScript.S.DOWN,
		],
		"normal terminal parry signals stagger before shatter"
	)
	normal_dummy.queue_free()
	await process_frame

	var muted_progress_dummy := TestPressingScript.new()
	muted_progress_dummy.muted = true
	root.add_child(muted_progress_dummy)
	muted_progress_dummy.set("_player", player)
	muted_progress_dummy.set("state", TestPressingScript.S.SWING)
	_reset_combat_events()
	_connect_combat_events(muted_progress_dummy)
	player.last_strike_ms = Time.get_ticks_msec()
	muted_progress_dummy.call("_resolve_swing", 0.0)
	_expect(_parried_events == 1, "non-winning muted parry emits parried once")
	_expect(_shattered_events == 0, "non-winning muted parry does not emit shattered")
	_expect(_bout_won_events == 0, "non-winning muted parry does not emit bout victory")
	_expect(
		int(muted_progress_dummy.get("state")) == int(TestPressingScript.S.STAGGER),
		"non-winning muted parry leaves the Test Pressing staggered"
	)
	_expect(
		is_zero_approx(float(muted_progress_dummy.get("resonance"))),
		"non-winning muted parry does not build resonance"
	)
	_expect(
		int(muted_progress_dummy.get("parry_count")) == 1,
		"non-winning muted parry advances the bout counter"
	)
	_expect(
		_combat_event_order == ["parried:%d" % TestPressingScript.S.STAGGER],
		"non-winning muted parry signals while staggered"
	)
	muted_progress_dummy.queue_free()
	await process_frame

	var muted_dummy := TestPressingScript.new()
	muted_dummy.muted = true
	root.add_child(muted_dummy)
	muted_dummy.set("_player", player)
	muted_dummy.set("state", TestPressingScript.S.SWING)
	muted_dummy.set("resonance", 0.8)
	muted_dummy.set("parry_count", 2)
	_reset_combat_events()
	_connect_combat_events(muted_dummy)
	player.last_strike_ms = Time.get_ticks_msec()
	muted_dummy.call("_resolve_swing", 0.0)
	_expect(_parried_events == 1, "muted third parry emits parried once")
	_expect(_shattered_events == 0, "muted third parry does not emit shattered")
	_expect(_bout_won_events == 1, "muted third parry emits bout victory once")
	_expect(
		int(muted_dummy.get("state")) == int(TestPressingScript.S.DOWN),
		"muted third parry leaves the Test Pressing down"
	)
	_expect(
		is_zero_approx(float(muted_dummy.get("resonance"))),
		"muted bout victory clears resonance"
	)
	_expect(int(muted_dummy.get("parry_count")) == 0, "muted bout victory resets its parry count")
	_expect(
		_combat_event_order == [
			"parried:%d" % TestPressingScript.S.STAGGER,
			"bout_won:%d" % TestPressingScript.S.DOWN,
		],
		"muted terminal parry signals stagger before bout victory"
	)
	muted_dummy.queue_free()
	player.queue_free()
	await process_frame
	await process_frame

func _reset_combat_events() -> void:
	_parried_events = 0
	_shattered_events = 0
	_bout_won_events = 0
	_combat_event_order.clear()

func _connect_combat_events(dummy: Node) -> void:
	_observed_dummy = dummy
	dummy.connect("parried", _record_parried)
	dummy.connect("shattered", _record_shattered)
	dummy.connect("bout_won", _record_bout_won)

func _record_parried() -> void:
	_parried_events += 1
	_combat_event_order.append("parried:%d" % int(_observed_dummy.get("state")))

func _record_shattered(_pos: Vector2) -> void:
	_shattered_events += 1
	_combat_event_order.append("shattered:%d" % int(_observed_dummy.get("state")))

func _record_bout_won() -> void:
	_bout_won_events += 1
	_combat_event_order.append("bout_won:%d" % int(_observed_dummy.get("state")))

func _relay_strike(pos: Vector2, big: bool, _launched: bool) -> void:
	if is_instance_valid(_strike_target):
		_strike_target.call("on_player_strike", pos, big)
