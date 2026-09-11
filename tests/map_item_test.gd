extends SceneTree
## A carried map records travel; it never changes routes, money or techniques.
## Disk fixtures and Main instances use only this run's private user directory.
const MainScene := preload("res://scenes/main.tscn")
const MapStateScript := preload("res://scripts/map_state.gd")
const ChartScript := preload("res://scripts/campaign_chart.gd")
const CampaignScript := preload("res://scripts/campaign.gd")
const PickupScript := preload("res://scripts/map_pickup.gd")
const SaveScript := preload("res://scripts/save_store.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const ExplorationCatalog := preload("res://scripts/exploration_catalog.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _strikes := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-map-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated map fixture")
	_check_state_and_schema()
	await _boot()
	await _check_chart()
	_main._new_game(false)
	await _physics(4)
	await _check_pickup()
	await _check_inputs()
	await _check_persistence()
	await _check_region_journey()
	await _check_old_save()
	await _check_development()
	await _close()
	for name in ["checkpoint.json", "schema.json"]:
		_check(SaveScript.new(_directory + "/" + name).delete_save(), "remove isolated map save " + name)
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated map directory")
	if _failures.is_empty():
		print("DEAD WAX MAP ITEM PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("MAP ITEM FAIL: " + failure)
	quit(1)

func _check_state_and_schema() -> void:
	var state := MapStateScript.new()
	_check(state.snapshot() == {"owned": false, "visited": []}, "map starts unowned without history")
	_check(state.visit(&"headshell") and not state.visit(&"headshell"), "a real visit is recorded once, even before finding the map")
	_check(not state.visit(&"rooms_to_let") and not state.visit(&"label"), "planned and prototype rooms cannot enter the carried map")
	var expanded := MapStateScript.new()
	for id in [&"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"deep_gallery", &"verse_warren_s"]:
		_check(expanded.visit(id), "new authored room records a map visit: " + String(id))
	_check(MapStateScript.valid_snapshot(expanded.snapshot()), "expanded visits retain the version-one map schema")
	_check(state.collect() and not state.collect(), "collecting the map is idempotent")
	var snapshot := state.snapshot()
	var copied := snapshot.duplicate(true)
	_check(state.restore_snapshot(snapshot) and state.snapshot() == snapshot, "map state restores ownership and marks atomically")
	snapshot.visited.append("horn_plaza")
	_check(state.snapshot() == copied, "snapshot arrays cannot mutate the model")
	var store := SaveScript.new(_directory + "/schema.json")
	var sample := _old_save()
	_check(store.save_game(sample), "version-one checkpoint without map still saves")
	_check(store.load_game().map == {"owned": false, "visited": []}, "absent map adds no ownership or invented visit history")
	sample["map"] = copied
	_check(store.save_game(sample) and store.load_game().map == copied, "owned map and its visits survive validated disk roundtrip")
	var valid_save := store.load_game()
	var invalid: Array = [null, true, [], {}, {"owned": true}, {"visited": []},
		{"owned": 1, "visited": []}, {"owned": "yes", "visited": []},
		{"owned": true, "visited": "headshell"}, {"owned": true, "visited": [1]},
		{"owned": true, "visited": [true]}, {"owned": true, "visited": ["missing_room"]},
		{"owned": true, "visited": ["rooms_to_let"]}, {"owned": true, "visited": ["label"]},
		{"owned": true, "visited": ["headshell", "headshell"]},
		{"owned": true, "visited": [], "extra": true}]
	for index in invalid.size():
		_check(not MapStateScript.valid_snapshot(invalid[index]), "reject malformed map schema %d" % index)
		var bad := sample.duplicate(true)
		bad["map"] = invalid[index]
		_check(not store.save_game(bad) and store.load_game() == valid_save, "bad map %d preserves the complete prior checkpoint" % index)
		if invalid[index] is Dictionary:
			_check(not state.restore_snapshot(invalid[index]) and state.snapshot() == copied, "bad map restore %d preserves in-memory ownership and marks" % index)
	state.reset()
	_check(state.snapshot() == {"owned": false, "visited": []}, "reset removes the old map and visits")

func _check_chart() -> void:
	var actual_ids := CampaignScript.room_ids()
	var chart_ids := ChartScript.room_ids()
	actual_ids.sort()
	chart_ids.sort()
	_check(chart_ids == actual_ids and chart_ids.size() == 21, "folded chart names exactly the twenty-one authored rooms")
	var real_pairs: Array[String] = []
	for id in actual_ids:
		var room := CampaignScript.create_room(id)
		room.progression = _main.progression
		room.process_mode = Node.PROCESS_MODE_DISABLED
		if "map_state" in room: room.map_state = MapStateScript.new()
		root.add_child(room)
		for child in room.get_children():
			if not child.is_in_group("room_exit"): continue
			var pair := _pair(id, child.target_room)
			if pair not in real_pairs: real_pairs.append(pair)
		room.queue_free()
		await _frames(1)
	var factory_pairs := real_pairs.duplicate()
	factory_pairs.sort()
	_check(factory_pairs.size() == 24, "the original twenty-four factory passage pairs remain unchanged")
	var return_pairs: Array[String] = []
	for endpoint in ExplorationCatalog.endpoints():
		var pair := _pair(endpoint.room_id, endpoint.target_room)
		_check(endpoint.room_id in actual_ids and endpoint.target_room in actual_ids and pair not in factory_pairs,
			"Main's added return endpoint connects distinct authored rooms outside the existing passage pairs")
		if pair not in return_pairs:
			return_pairs.append(pair)
			real_pairs.append(pair)
	_check(return_pairs.size() == 2, "Main's exploration catalog adds exactly two return pairs")
	var chart_pairs: Array[String] = []
	for link in ChartScript.links():
		var pair := _pair(link.a, link.b)
		_check(pair not in chart_pairs and link.a in actual_ids and link.b in actual_ids, "chart passage is unique and connects authored rooms: " + pair)
		chart_pairs.append(pair)
		if link.shortcut:
			_check(pair in [_pair(&"worn_gallery", &"the_arm"), _pair(&"the_stalls", &"worn_gallery")] or pair in return_pairs,
				"only authored Gallery and wax returns are marked as shortcuts")
	real_pairs.sort()
	chart_pairs.sort()
	_check(chart_pairs == real_pairs and chart_pairs.size() == 26, "chart routes match the factory passages and Main-installed wax returns")
	var rooms := ChartScript.rooms()
	var original := ChartScript.rooms()
	rooms[0].label = "changed fixture"
	_check(ChartScript.rooms() == original, "chart copies cannot alter shared room names or geometry")
	var page_ids: Array[StringName] = []
	var page_pairs: Array[String] = []
	for region in ChartScript.REGIONS:
		var page := ChartScript.page_snapshot(region.id, ["headshell"], &"the_drop")
		for room in page.rooms:
			_check(room.id not in page_ids and ChartScript.region_for_room(room.id) == region.id, "each authored place belongs to exactly one map page: " + String(room.id))
			page_ids.append(room.id)
			_check(not String(room.title).is_empty() if room.id in [&"headshell", &"the_drop"] else String(room.title).is_empty(), "unvisited place names stay absent from drawing data: " + String(room.id))
			var box := Rect2(room.position - ChartScript.ROOM_SIZE * 0.5, ChartScript.ROOM_SIZE)
			_check(Rect2(Vector2.ZERO, ChartScript.EXTENT).encloses(box), "room card fits its page: " + String(room.id))
		for boundary in page.boundaries:
			_check(ChartScript.region_for_room(boundary.id) != region.id and String(boundary.title).begins_with("TO THE "), "boundary marker names a different printed region without disclosing room names")
		for link in page.links:
			var pair := _pair(link.a, link.b)
			_check(pair in chart_pairs, "page never invents a passage: " + pair)
			if pair not in page_pairs: page_pairs.append(pair)
	page_ids.sort()
	page_pairs.sort()
	_check(page_ids == actual_ids and page_pairs == factory_pairs, "partially explored pages preserve the original passages while concealing undiscovered wax returns")
	var revealed_pairs: Array[String] = []
	for region in ChartScript.REGIONS:
		for link in ChartScript.page_snapshot(region.id, actual_ids, &"headshell").links:
			var pair := _pair(link.a, link.b)
			if pair not in revealed_pairs: revealed_pairs.append(pair)
	revealed_pairs.sort()
	_check(revealed_pairs == real_pairs, "visiting both endpoints reveals every real return without opening it")

func _check_pickup() -> void:
	_check(not _main.map_state.owned and _main.map_state.visited == ["headshell"], "New game records its actual start without granting the map")
	var pickup := _pickup()
	_check(pickup != null and pickup.get_script() == PickupScript, "Headshell contains one authored map pickup")
	if pickup == null: return
	var center := pickup.global_position
	_check(center.distance_to(_main.room.spawn_pos) > PickupScript.COLLECT_RADIUS, "spawn never grants the map automatically")
	var arrivals_clear := true
	for entry in _main.room.entry_points.values():
		arrivals_clear = arrivals_clear and center.distance_to(entry) > PickupScript.COLLECT_RADIUS
	_check(arrivals_clear, "return arrivals stay clear of the map pickup")
	_check(not pickup is CollisionObject2D and not pickup.has_meta("chapter_state_id") and not pickup.is_in_group("strikable"), "map pickup adds no collision, combat target or encounter reward")
	await _tap(KEY_M)
	_check(not _main.map_menu.is_open and not paused, "M cannot open an unowned map")
	_main.inventory.open_inventory()
	_check(_main.inventory._map_button.disabled and _main.inventory.slot_count() == 8, "Book shows the missing item without adding a progression slot")
	_main.inventory.close_inventory()
	await _physics(2)
	var clock: float = pickup._clock
	await _physics(8)
	_check(pickup._clock > clock and pickup.global_position == center, "decorative animation never moves the collection center")
	_main._pause_game()
	var pose: Dictionary = pickup.animation_pose().duplicate(true)
	await _frames(8)
	_check(pickup.animation_pose() == pose, "pause freezes the uncollected map")
	_main._resume_game()
	await _physics(2)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	pose = pickup.animation_pose().duplicate(true)
	await _physics(8)
	_check(pickup.animation_pose() == pose and pose.reduced_motion, "reduced motion settles pickup decoration without moving its hit center")
	_main._settings.reduced_motion = false
	_main._apply_settings()
	# Stay just outside the fixed radius through several decorative poses.
	_main.player.position = center + Vector2(-52.5, 0)
	_main.player.velocity = Vector2.ZERO
	await _physics(18)
	_check(not _main.map_state.owned and pickup.global_position == center, "floating paper cannot collect from outside its fixed52px radius")
	var gameplay := _gameplay_snapshot()
	_key(KEY_D, true)
	for frame in range(10):
		await _physics(1)
		if _main.map_state.owned: break
	_key(KEY_D, false)
	await _physics(4)
	_check(_main.map_state.owned and _pickup() == null, "walking into the page collects it and retires the pickup")
	_check(_main.player.is_on_floor() and _gameplay_snapshot() == gameplay, "map collection leaves movement, currency, Refrains and knowledge unchanged")
	var saved: Dictionary = _main.save_store.load_game()
	_check(saved.map.owned and saved.map.visited == ["headshell"], "pickup autosaves ownership with the actual visit history")
	_main._on_map_collected()
	_check(_gameplay_snapshot() == gameplay and _main.map_state.snapshot() == saved.map, "duplicate collection cannot reward or change the map again")
	_main._respawn()
	_check(_main.map_state.owned and _pickup() == null, "recovery preserves map ownership and cannot respawn it")
	await _physics(3)
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(3)
	_main._load_world_room(&"headshell", &"from_horn_plaza")
	await _physics(3)
	_check(_pickup() == null and _main.map_state.visited == ["headshell", "horn_plaza"], "room recreation silently keeps the map and unique travel marks")

func _check_inputs() -> void:
	var map_action := InputMap.action_get_events("map")
	var keyboard := false
	var controller := false
	for event in map_action:
		keyboard = keyboard or (event is InputEventKey and event.physical_keycode == KEY_M)
		controller = controller or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_DOWN)
	_check(keyboard and controller, "campaign map exposes M and D-pad Down")
	_key(KEY_M, true)
	await _frames(8)
	_check(_main.map_menu.is_open and paused, "holding the opening key opens the map once and pauses play")
	_key(KEY_M, false)
	await _frames(2)
	_check(_main.map_menu.current_room() == "headshell", "map marks the actual current room")
	_check(_main.map_menu.selected_region() == &"label" and _main.map_menu.region_buttons().size() == 3, "map opens on the current region with three focusable page controls")
	var physical := _physical_snapshot()
	var model := _complete_snapshot()
	for key in [KEY_D, KEY_J, KEY_R, KEY_E, KEY_I, KEY_B, KEY_F]: await _tap(key)
	_check(_main.map_menu.is_open and not _main.inventory.is_open() and not _main.shop.is_open and not _main.game_menu.is_open, "map excludes passages, Book, shop and pause-menu overlap")
	_check(_physical_snapshot() == physical and _complete_snapshot() == model, "map input cannot move, attack, reset, spend or unlock anything")
	await _tap(KEY_RIGHT)
	_check(_main.map_menu.selected_region() == &"overture" and _main.map_menu.is_open, "Right turns to Overture without closing the guide")
	await _tap_pad(JOY_BUTTON_DPAD_RIGHT)
	_check(_main.map_menu.selected_region() == &"unplayed" and _main.map_menu.is_open, "controller Right turns to Unplayed")
	await _tap_pad(JOY_BUTTON_A)
	_check(_main.map_menu.is_open and paused, "confirming a focused page selects it without closing the guide")
	await _tap(KEY_LEFT)
	_check(_main.map_menu.selected_region() == &"overture", "Left turns back a page")
	_main.map_menu.region_buttons()[0].pressed.emit()
	_check(_main.map_menu.selected_region() == &"label", "clickable page buttons select their own region")
	_check(_physical_snapshot() == physical and _complete_snapshot() == model, "paging remains a read-only view of frozen play and all campaign state")
	await _tap(KEY_ESCAPE)
	await _physics(3)
	_check(not _main.map_menu.is_open and not paused and not _main.game_menu.is_open, "Escape closes only the map")
	_main._load_world_room(&"headshell")
	await _physics(4)
	var origin: Vector2 = _main.player.position
	for use_pad in [false, true]:
		if use_pad: await _tap_pad(JOY_BUTTON_DPAD_DOWN)
		else: await _tap(KEY_M)
		_check(_main.map_menu.is_open, "map opens through " + ("controller" if use_pad else "keyboard"))
		_main.map_menu.close_button().grab_focus()
		if use_pad: _joy(JOY_BUTTON_A, true)
		else: _key(KEY_SPACE, true)
		await _frames(8)
		if use_pad: _joy(JOY_BUTTON_A, false)
		else: _key(KEY_SPACE, false)
		await _physics(4)
		_check(not _main.map_menu.is_open and not paused, "focused map Close works with " + ("A" if use_pad else "Space"))
		_check(_main.player.is_on_floor() and _main.player.position.is_equal_approx(origin) and _main.player._buffer <= 0, "closing map cannot leak a held confirm into a jump")
	_main.inventory.open_inventory()
	_check(not _main.inventory._map_button.disabled and _main.inventory.slot_count() == 8 and _main.inventory.filled_slot_count() == 0, "owned map leaves all eight unearned progression grooves empty")
	await _frames(2)
	var selected_before := root.gui_get_focus_owner()
	await _tap_pad(JOY_BUTTON_DPAD_DOWN)
	_check(_main.inventory.is_open() and not _main.map_menu.is_open and root.gui_get_focus_owner() != selected_before, "Book D-pad Down keeps navigating cards after the map is owned")
	_main.inventory._map_button.grab_focus()
	await _tap_pad(JOY_BUTTON_A)
	_check(_main.map_menu.is_open and not _main.inventory.is_open() and paused, "Book map button transfers directly to the paused map")
	_main._settings.reduced_motion = true
	_main._apply_settings()
	var visual := _visual_snapshot(_main.map_menu.overlay)
	await _frames(12)
	_check(_visual_snapshot(_main.map_menu.overlay) == visual, "reduced motion settles map entrance and focus decoration")
	_main._close_map()
	await _physics(3)
	_main._pause_game()
	await _tap(KEY_M)
	_check(not _main.map_menu.is_open and _main.game_menu.is_open, "map cannot open over pause choices")
	_main._resume_game()
	await _physics(3)
	_main._load_world_room(&"bootlegger")
	await _physics(3)
	_main.player.position = Vector2(720, 574)
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_main._open_shop()
	await _tap(KEY_M)
	_check(_main.shop.is_open and not _main.map_menu.is_open, "map cannot open over a transaction")
	_main._close_shop()
	await _physics(3)

func _check_persistence() -> void:
	_main._load_world_room(&"high_street", &"from_practice_room")
	await _physics(3)
	var saved_map: Dictionary = _main.map_state.snapshot()
	_check(_main._persist_session(), "save owned map before a fresh Main instance")
	await _close()
	await _boot()
	_main._continue_game()
	await _physics(4)
	_check(_main.map_state.snapshot() == saved_map and _main.world_room_id == &"high_street", "Continue restores the map, visit history and current room")
	await _tap(KEY_M)
	_check(_main.map_menu.is_open and _main.map_menu.current_room() == "high_street", "restored map opens with the saved current room marker")
	_main._close_map()
	await _physics(3)
	_main._load_world_room(&"headshell")
	await _physics(3)
	_check(_pickup() == null, "Continue cannot regenerate the owned map pickup")
	_main._new_game(false)
	await _physics(4)
	_check(not _main.map_state.owned and _main.map_state.visited == ["headshell"] and _pickup() != null, "New game restores the pickup and clears the previous journey's map")

func _check_old_save() -> void:
	await _close()
	var old := _old_save()
	# Raw old JSON is intentional: do not normalize the absent field before boot.
	var store := SaveScript.new(_directory + "/checkpoint.json")
	store.delete_save()
	_write(_directory + "/checkpoint.json", old)
	await _boot()
	_main._continue_game()
	await _physics(4)
	_check(_main.world_room_id == &"overture_stair" and _main.room_entry_id == &"from_label_descent", "old v1 Continue preserves its room and named entry")
	_check(not _main.map_state.owned and _main.map_state.visited == ["overture_stair"], "old Continue starts unowned and records only its actual current location")
	_check(_main.economy.balance == 7 and _main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN)
		and _main.encounters.get("groove_yard/yard_first_voice") == "freed", "map migration preserves money, techniques and encounter choices")
	await _tap(KEY_M)
	_check(not _main.map_menu.is_open, "old save still needs to find the map")
	_main._load_world_room(&"headshell", &"from_horn_plaza")
	await _physics(3)
	_check(_pickup() != null and not _main.map_state.owned, "old journeys can return for the map without collecting at their arrival")

func _check_region_journey() -> void:
	_main.map_state.collect()
	for id in [&"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"deep_gallery", &"verse_warren_s"]:
		_main._load_world_room(id)
		await _physics(3)
		_check(String(id) in _main.map_state.visited, "entering the expansion records its actual room: " + String(id))
	var saved_map: Dictionary = _main.map_state.snapshot()
	_check(_main._persist_session(), "expanded map journey saves through the existing checkpoint format")
	await _close()
	await _boot()
	_main._continue_game()
	await _physics(4)
	_check(_main.map_state.snapshot() == saved_map and _main.world_room_id == &"verse_warren_s", "Continue restores all six expansion visits and its saved room")
	await _tap(KEY_M)
	_check(_main.map_menu.is_open and _main.map_menu.selected_region() == &"unplayed", "expanded Continue opens its current region automatically")
	await _tap(KEY_LEFT)
	_main._close_map()
	await _physics(3)
	await _tap(KEY_M)
	_check(_main.map_menu.selected_region() == &"unplayed", "reopening returns to the player's region instead of stale browsing state")
	_main._close_map()
	await _physics(3)

func _check_development() -> void:
	await _close()
	_main = MainScene.instantiate()
	_main.development_mode = true
	_main.save_path = _directory + "/never-used-development.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _physics(4)
	_main.map_state.collect()
	_main._open_map()
	_check(not _main.map_menu.is_open, "development mode cannot open the carried campaign map")
	await _tap(KEY_M)
	_check(not _main.map_menu.is_open and not _main.world_room_id.is_empty(), "development M still enters the planned world atlas")
	_check(not FileAccess.file_exists(_main.save_path), "development map access never writes a campaign checkpoint")

func _old_save() -> Dictionary:
	return {"version": 1, "room_id": "overture_stair", "entry_id": "from_label_descent", "shine": 7,
		"progression": {"version": 1, "refrains": [], "techniques": ["count-in"]},
		"encounters": {"groove_yard/yard_first_voice": "freed"}}

func _pickup() -> Node2D:
	return _main.room.get_node_or_null("FoldedMap") as Node2D

func _pair(first: StringName, second: StringName) -> String:
	var ids := [String(first), String(second)]
	ids.sort()
	return ids[0] + "/" + ids[1]

func _gameplay_snapshot() -> Dictionary:
	return {"economy": _main.economy.snapshot(), "progression": _main.progression.snapshot(), "encounters": _main.encounters.duplicate(true)}

func _complete_snapshot() -> Dictionary:
	var result := _gameplay_snapshot()
	result["map"] = _main.map_state.snapshot()
	result["exploration"] = _main.exploration.snapshot()
	return result

func _physical_snapshot() -> Dictionary:
	return {"room": _main.world_room_id, "position": _main.player.position, "velocity": _main.player.velocity,
		"pose": _main.player._animation_pose().duplicate(true), "strikes": _strikes,
		"atmosphere": _main.room.atmosphere.visual_snapshot().duplicate(true), "lighting": _main.room.lighting.visual_snapshot().duplicate(true)}

func _visual_snapshot(node: Node) -> Dictionary:
	var result := {}
	for child in node.get_children():
		if child is Control:
			result[child.get_instance_id()] = [child.position, child.scale, child.modulate, child.visible]
			if "level" in child: result[child.get_instance_id()].append([child.level, child.press_age])
		result.merge(_visual_snapshot(child))
	return result

func _write(path: String, contents: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(contents))
	file.close()

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main.player.struck.connect(func(_pos: Vector2, _big: bool, _launched: bool) -> void: _strikes += 1)

func _close() -> void:
	for code in [KEY_M, KEY_D, KEY_J, KEY_R, KEY_E, KEY_I, KEY_B, KEY_F, KEY_SPACE, KEY_ENTER, KEY_ESCAPE, KEY_LEFT, KEY_RIGHT]: _key(code, false)
	for button in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A, JOY_BUTTON_B]: _joy(button, false)
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false

func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(3)
	_key(code, false)
	await _frames(3)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _tap_pad(button: JoyButton) -> void:
	_joy(button, true)
	await _frames(3)
	_joy(button, false)
	await _frames(3)

func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
