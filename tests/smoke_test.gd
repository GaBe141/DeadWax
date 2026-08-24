extends SceneTree
## Dependency-free headless validation for Dead Wax.
## Run with: .\deadwax.cmd test

const SkipScript := preload("res://scripts/skip.gd")
const TestPressingScript := preload("res://scripts/test_pressing.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")

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

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
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

	var audio := main.get("audio") as Node
	if audio != null:
		for child in audio.get_children():
			if child is AudioStreamPlayer:
				child.stop()
				child.stream = null
	while AudioServer.get_bus_effect_count(0) > initial_master_effects:
		AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
	main.queue_free()
	await process_frame
	await process_frame

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
