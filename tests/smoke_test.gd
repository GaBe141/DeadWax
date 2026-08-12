extends SceneTree
## Dependency-free headless validation for Dead Wax.
## Run with: .\deadwax.cmd test

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

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_world_map()
	await _check_project_boot()

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
