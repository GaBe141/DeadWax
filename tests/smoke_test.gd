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
const EXPECTED_PROTOTYPE_IDS := ["label", "practice", "verse", "unplayed", "smoothed"]
const EXPECTED_ROUTE_EDGES := [
	"label>practice",
	"label>smoothed",
	"practice>label",
	"practice>verse",
	"verse>practice",
	"verse>unplayed",
	"unplayed>verse",
	"unplayed>smoothed",
	"smoothed>unplayed",
	"smoothed>label",
]
const WORLD_ROUTE_PROGRESSIONS := [
	"tech:count-in",
	"tech:step-turn",
	"refrain:gather",
	"refrain:rest",
	"refrain:jump-cut",
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
	"enter_passage",
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

	_expect(int(world.get("version", 0)) == 2, "world map uses the split route-metadata schema")
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
	var room_by_id := {}
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
		room_by_id[room_id] = room_data
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
			if room_by_id.has(target):
				_expect(
					_world_rooms_touch(room_data, room_by_id[target]),
					"room '%s' special route physically touches '%s'" % [room_id, target]
				)
			_expect(
				String(special.get("kind", "")) in ["gate", "shortcut", "story", "secret"],
				"room '%s' special route has a topology kind" % room_id
			)
			var requires_value: Variant = special.get("requires", null)
			_expect(requires_value is Array, "room '%s' special route has a requirements array" % room_id)
			if requires_value is Array:
				for requirement_value in requires_value:
					_expect(
						String(requirement_value) in WORLD_ROUTE_PROGRESSIONS,
						"room '%s' route requirement is a canonical progression id" % room_id
					)
			_expect(
				String(special.get("direction", "")) in ["bidirectional", "oneway"],
				"room '%s' special route declares direction separately" % room_id
			)

	_check_world_routing(rooms, room_by_id)

func _check_world_routing(rooms: Array, room_by_id: Dictionary) -> void:
	# Space-efficiency metrics deliberately use the undirected packing graph.
	# Direction and requirements are exercised separately below.
	var packing_adjacency := {}
	for room_value in rooms:
		var room_data: Dictionary = room_value
		packing_adjacency[String(room_data.get("id"))] = {}

	for left_index in rooms.size():
		var left: Dictionary = rooms[left_index]
		for right_index in range(left_index + 1, rooms.size()):
			var right: Dictionary = rooms[right_index]
			_expect(
				not _world_rooms_overlap(left, right),
				"world rooms '%s' and '%s' do not overlap" % [left.get("id"), right.get("id")]
			)
			if _world_rooms_touch(left, right):
				_connect_world_rooms(packing_adjacency, String(left.get("id")), String(right.get("id")))

	for room_value in rooms:
		var room_data: Dictionary = room_value
		var source := String(room_data.get("id"))
		for special_value in room_data.get("specials", []):
			if special_value is Dictionary:
				var target := String(special_value.get("to"))
				if room_by_id.has(target):
					_connect_world_rooms(packing_adjacency, source, target)

	var frontier: Array[String] = [String(rooms[0].get("id"))]
	var visited := {}
	while not frontier.is_empty():
		var current := String(frontier.pop_front())
		if visited.has(current):
			continue
		visited[current] = true
		var neighbors: Dictionary = packing_adjacency.get(current, {})
		for neighbor in neighbors:
			if not visited.has(String(neighbor)):
				frontier.append(String(neighbor))
	_expect(visited.size() == rooms.size(), "all 53 planned rooms belong to one packing graph")

	var dead_ends := 0
	for room_id in packing_adjacency:
		var neighbors: Dictionary = packing_adjacency[room_id]
		if neighbors.size() == 1:
			dead_ends += 1
	_expect(dead_ends == 7, "compact world routing has exactly seven planned dead ends")
	_expect(_count_world_bridges(packing_adjacency) == 18, "compact world routing has exactly 18 bridge connections")
	_expect(_world_stratum_density(rooms, "unplayed") >= 0.48, "The Unplayed packs at least 48% of its bounds")
	_expect(_world_stratum_density(rooms, "undersong") >= 0.63, "The Undersong packs at least 63% of its bounds")
	_check_world_progression_routing(rooms, room_by_id)

func _connect_world_rooms(adjacency: Dictionary, left_id: String, right_id: String) -> void:
	var left_neighbors: Dictionary = adjacency[left_id]
	var right_neighbors: Dictionary = adjacency[right_id]
	left_neighbors[right_id] = true
	right_neighbors[left_id] = true

func _count_world_bridges(adjacency: Dictionary) -> int:
	var visited := {}
	var discovered := {}
	var low := {}
	var clock := [0]
	var bridge_count := [0]
	for room_id_value in adjacency:
		var room_id := String(room_id_value)
		if not visited.has(room_id):
			_visit_world_bridges(room_id, "", adjacency, visited, discovered, low, clock, bridge_count)
	return int(bridge_count[0])

func _visit_world_bridges(
	room_id: String,
	parent_id: String,
	adjacency: Dictionary,
	visited: Dictionary,
	discovered: Dictionary,
	low: Dictionary,
	clock: Array,
	bridge_count: Array
) -> void:
	visited[room_id] = true
	clock[0] = int(clock[0]) + 1
	discovered[room_id] = int(clock[0])
	low[room_id] = int(clock[0])
	var neighbors: Dictionary = adjacency[room_id]
	for neighbor_value in neighbors:
		var neighbor_id := String(neighbor_value)
		if neighbor_id == parent_id:
			continue
		if not visited.has(neighbor_id):
			_visit_world_bridges(neighbor_id, room_id, adjacency, visited, discovered, low, clock, bridge_count)
			low[room_id] = mini(int(low[room_id]), int(low[neighbor_id]))
			if int(low[neighbor_id]) > int(discovered[room_id]):
				bridge_count[0] = int(bridge_count[0]) + 1
		else:
			low[room_id] = mini(int(low[room_id]), int(discovered[neighbor_id]))

func _check_world_progression_routing(rooms: Array, room_by_id: Dictionary) -> void:
	var special_pairs := {}
	var special_routes := {}
	var open_contacts := {}
	for room_value in rooms:
		var room_data: Dictionary = room_value
		var room_id := String(room_data.get("id"))
		special_routes[room_id] = []
		open_contacts[room_id] = {}
		for special_value in room_data.get("specials", []):
			if special_value is Dictionary:
				var target := String(special_value.get("to"))
				special_pairs[_world_pair_key(room_id, target)] = true

	for room_value in rooms:
		var room_data: Dictionary = room_value
		var source := String(room_data.get("id"))
		for special_value in room_data.get("specials", []):
			if not special_value is Dictionary:
				continue
			var special: Dictionary = special_value
			var target := String(special.get("to"))
			if not room_by_id.has(target):
				continue
			var requirements: Array = special.get("requires", [])
			var source_routes: Array = special_routes[source]
			source_routes.append({"to": target, "requires": requirements})
			if String(special.get("direction")) == "bidirectional":
				var target_routes: Array = special_routes[target]
				target_routes.append({"to": source, "requires": requirements})

	for left_index in rooms.size():
		var left: Dictionary = rooms[left_index]
		var left_id := String(left.get("id"))
		for right_index in range(left_index + 1, rooms.size()):
			var right: Dictionary = rooms[right_index]
			var right_id := String(right.get("id"))
			if _world_rooms_touch(left, right) and not special_pairs.has(_world_pair_key(left_id, right_id)):
				_connect_world_rooms(open_contacts, left_id, right_id)

	# Search actual player states instead of treating every previously visited
	# room as a teleport source. Technique requirements are execution challenges
	# in-game; treating them as owned state here is a deliberately harsher check.
	var progression_bits := {}
	for progression_index in WORLD_ROUTE_PROGRESSIONS.size():
		progression_bits[WORLD_ROUTE_PROGRESSIONS[progression_index]] = 1 << progression_index
	var state_queue: Array[Dictionary] = []
	var seen_states := {}
	var reached_rooms := {}
	var full_mask := (1 << WORLD_ROUTE_PROGRESSIONS.size()) - 1
	var full_mask_reached := false
	_queue_world_state("headshell", 0, room_by_id, progression_bits, state_queue, seen_states)
	var queue_index := 0
	while queue_index < state_queue.size():
		var state: Dictionary = state_queue[queue_index]
		queue_index += 1
		var source := String(state.get("room"))
		var owned_mask := int(state.get("owned"))
		reached_rooms[source] = true
		if owned_mask == full_mask:
			full_mask_reached = true
		var neighbors: Dictionary = open_contacts[source]
		for target_value in neighbors:
			_queue_world_state(
				String(target_value), owned_mask, room_by_id, progression_bits, state_queue, seen_states
			)
		var routes: Array = special_routes[source]
		for route_value in routes:
			var route: Dictionary = route_value
			var requirements: Array = route.get("requires", [])
			if _world_requirements_met(requirements, owned_mask, progression_bits):
				_queue_world_state(
					String(route.get("to")), owned_mask, room_by_id, progression_bits, state_queue, seen_states
				)
	_expect(
		reached_rooms.size() == rooms.size(),
		"all 53 planned rooms remain reachable with one-way routes and strict acquired requirements"
	)
	_expect(
		full_mask_reached,
		"one strict planned traversal can acquire all five route progressions"
	)

func _world_pair_key(left_id: String, right_id: String) -> String:
	var ids := [left_id, right_id]
	ids.sort()
	return "%s|%s" % ids

func _queue_world_state(
	room_id: String,
	owned_mask: int,
	room_by_id: Dictionary,
	progression_bits: Dictionary,
	state_queue: Array[Dictionary],
	seen_states: Dictionary
) -> void:
	var room_data: Dictionary = room_by_id[room_id]
	var next_mask := owned_mask
	for reward_value in room_data.get("rewards", []):
		var reward := String(reward_value)
		if progression_bits.has(reward):
			next_mask |= int(progression_bits[reward])
	var state_key := "%s#%d" % [room_id, next_mask]
	if seen_states.has(state_key):
		return
	seen_states[state_key] = true
	state_queue.append({"room": room_id, "owned": next_mask})

func _world_requirements_met(
	requirements: Array,
	owned_mask: int,
	progression_bits: Dictionary
) -> bool:
	for requirement_value in requirements:
		var requirement := String(requirement_value)
		if not progression_bits.has(requirement):
			return false
		if (owned_mask & int(progression_bits[requirement])) == 0:
			return false
	return true

func _world_rooms_overlap(left: Dictionary, right: Dictionary) -> bool:
	return (
		maxf(float(left.get("x")), float(right.get("x")))
		< minf(float(left.get("x")) + float(left.get("w")), float(right.get("x")) + float(right.get("w")))
		and maxf(float(left.get("y")), float(right.get("y")))
		< minf(float(left.get("y")) + float(left.get("h")), float(right.get("y")) + float(right.get("h")))
	)

func _world_rooms_touch(left: Dictionary, right: Dictionary) -> bool:
	var horizontal_overlap := (
		maxf(float(left.get("x")), float(right.get("x")))
		< minf(float(left.get("x")) + float(left.get("w")), float(right.get("x")) + float(right.get("w")))
	)
	var vertical_overlap := (
		maxf(float(left.get("y")), float(right.get("y")))
		< minf(float(left.get("y")) + float(left.get("h")), float(right.get("y")) + float(right.get("h")))
	)
	var touches_x := (
		is_equal_approx(float(left.get("x")) + float(left.get("w")), float(right.get("x")))
		or is_equal_approx(float(right.get("x")) + float(right.get("w")), float(left.get("x")))
	)
	var touches_y := (
		is_equal_approx(float(left.get("y")) + float(left.get("h")), float(right.get("y")))
		or is_equal_approx(float(right.get("y")) + float(right.get("h")), float(left.get("y")))
	)
	return (touches_x and vertical_overlap) or (touches_y and horizontal_overlap)

func _world_stratum_density(rooms: Array, stratum_id: String) -> float:
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	var used_area := 0.0
	for room_value in rooms:
		var room_data: Dictionary = room_value
		if String(room_data.get("stratum")) != stratum_id:
			continue
		min_x = minf(min_x, float(room_data.get("x")))
		min_y = minf(min_y, float(room_data.get("y")))
		max_x = maxf(max_x, float(room_data.get("x")) + float(room_data.get("w")))
		max_y = maxf(max_y, float(room_data.get("y")) + float(room_data.get("h")))
		used_area += float(room_data.get("w")) * float(room_data.get("h"))
	var bounds_area := (max_x - min_x) * (max_y - min_y)
	return used_area / bounds_area if bounds_area > 0.0 else 0.0

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

	var observed_route_edges: Array[String] = []
	var observed_arrivals: Array[Dictionary] = []
	var entry_ids_by_room := {}
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
		var current_room_id := String(room.get("room_id"))
		_expect(current_room_id == EXPECTED_PROTOTYPE_IDS[index], "prototype room %d has a stable route id" % index)
		var entries: Dictionary = room.get("entry_points")
		entry_ids_by_room[current_room_id] = entries.duplicate()
		for entry_id_value in entries:
			var entry_id := StringName(entry_id_value)
			var entry_position: Vector2 = entries[entry_id_value]
			for listener in _room_group_members(room, &"hears_strikes"):
				if listener.has_signal("freed"):
					_expect(
						entry_position.distance_to(listener.position) > AuditionerScript.REACH_RANGE,
						"room '%s' entry '%s' starts outside Auditioner reach" % [current_room_id, entry_id]
					)
		var spawn: Vector2 = room.get("spawn_pos")
		_expect(is_finite(spawn.x) and is_finite(spawn.y), "room '%s' spawn is finite" % room.get("band_name"))
		_expect(is_finite(float(room.get("death_y"))), "room '%s' death plane is finite" % room.get("band_name"))
		var limits: Rect2 = room.get("cam_limits")
		_expect(limits.size.x > 0.0 and limits.size.y > 0.0, "room '%s' camera bounds are positive" % room.get("band_name"))
		var exits := _room_group_members(room, &"room_exit")
		_expect(exits.size() == 2, "room '%s' has two compact-loop passages" % room.get("band_name"))
		for exit in exits:
			var target_room := String(exit.get("target_room"))
			var target_entry := String(exit.get("target_entry"))
			_expect(target_room in EXPECTED_PROTOTYPE_IDS, "room '%s' routes to a known prototype room" % room.get("band_name"))
			_expect(target_entry != "default", "route %s>%s uses a named arrival" % [current_room_id, target_room])
			observed_arrivals.append({"source": current_room_id, "target": target_room, "entry": target_entry})
			observed_route_edges.append("%s>%s" % [current_room_id, target_room])

	observed_route_edges.sort()
	var expected_route_edges: Array = EXPECTED_ROUTE_EDGES.duplicate()
	expected_route_edges.sort()
	_expect(observed_route_edges == expected_route_edges, "prototype passages form the intended bidirectional five-room loop")
	for arrival in observed_arrivals:
		var target_entries: Dictionary = entry_ids_by_room.get(String(arrival.get("target")), {})
		_expect(
			target_entries.has(StringName(arrival.get("entry"))),
			"route %s>%s resolves named arrival '%s'" % [arrival.get("source"), arrival.get("target"), arrival.get("entry")]
		)

	# A locked shortcut cannot transition; a normal passage uses a named entry
	# and makes that arrival the new death/R respawn point.
	main.call("_load_room", 0)
	await process_frame
	await process_frame
	var label_room := main.get("room") as Node2D
	var locked_shortcut := _route_to(label_room, &"smoothed")
	_expect(locked_shortcut != null, "The Label exposes the Smoothed shortcut")
	if locked_shortcut != null:
		_expect(bool(locked_shortcut.call("is_locked")), "The Label shortcut starts Gather-locked")
		_expect(not bool(locked_shortcut.call("try_enter")), "a locked passage rejects traversal")
	await process_frame
	_expect(int(main.get("room_idx")) == 0, "a rejected passage leaves the current room unchanged")

	var practice_passage := _route_to(label_room, &"practice")
	_expect(practice_passage != null, "The Label summit routes to Practice")
	if practice_passage != null:
		var passage_player: CharacterBody2D = main.get("player")
		passage_player.global_position = practice_passage.global_position
		Input.action_press("enter_passage")
	await process_frame
	Input.action_release("enter_passage")
	await process_frame
	await process_frame
	_expect(int(main.get("room_idx")) == 1, "proximity plus E/Y requests a Main-owned transition")
	_expect(String(main.get("room_entry_id")) == "from_label", "the transition selects Practice's named entry")
	var routed_player: CharacterBody2D = main.get("player")
	var routed_room: Node2D = main.get("room")
	var routed_arrival: Vector2 = routed_room.call("entry_position", &"from_label")
	_expect(routed_player.global_position.is_equal_approx(routed_arrival), "the player arrives at Practice's Label-side anchor")
	routed_player.global_position += Vector2(300, -120)
	main.call("_respawn")
	_expect(routed_player.global_position.is_equal_approx(routed_arrival), "R respawns at the active room entry")

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

	# Gather opens the compact return edge. Both transitions preserve the same
	# session state while selecting the correct side of each room.
	main.call("_load_room", 0)
	await process_frame
	await process_frame
	label_room = main.get("room") as Node2D
	var open_shortcut := _route_to(label_room, &"smoothed")
	_expect(open_shortcut != null and not bool(open_shortcut.call("is_locked")), "Gather opens The Label's Smoothed shortcut")
	if open_shortcut != null:
		open_shortcut.call("try_enter")
	await process_frame
	await process_frame
	_expect(int(main.get("room_idx")) == 4, "the Gather shortcut reaches Smoothed")
	_expect(String(main.get("room_entry_id")) == "from_label", "the shortcut arrives on Smoothed's Label side")
	var smoothed_room := main.get("room") as Node2D
	var label_return := _route_to(smoothed_room, &"label")
	_expect(label_return != null, "Smoothed provides the compact return to The Label")
	if label_return != null:
		label_return.call("try_enter")
	await process_frame
	await process_frame
	_expect(int(main.get("room_idx")) == 0, "the compact loop returns to The Label")
	_expect(String(main.get("room_entry_id")) == "from_smoothed", "the return uses The Label's Smoothed-side anchor")
	_expect(main.get("progression") == session_progression, "room routes preserve the progression owner")

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

	# Let route/pickup one-shots finish before the existing audio teardown.
	await create_timer(0.65).timeout
	await process_frame
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

func _route_to(current_room: Node, target_room: StringName) -> Node:
	for exit in _room_group_members(current_room, &"room_exit"):
		if exit.get("target_room") == target_room:
			return exit
	return null

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
