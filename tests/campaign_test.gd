extends SceneTree
## Campaign integration checks. All disk writes use a unique test directory.
## Geometry checks are conservative support/hop checks, not a feel playtest.

const MainScene := preload("res://scenes/main.tscn")
const ChapterScript := preload("res://scripts/campaign.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const SaveScript := preload("res://scripts/save_store.gd")
const SkipScript := preload("res://scripts/skip.gd")
const PLAYER_HALF_HEIGHT := 26.0

var _checks := 0
var _failures: Array[String] = []
var _directory: String
var _save_path: String
var _settings_path: String
var _main: Node2D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-campaign-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_save_path = _directory + "/checkpoint.json"
	_settings_path = _directory + "/settings.cfg"
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated campaign test directory")
	_check_registry()
	await _boot()
	await _check_title_and_new_game()
	await _check_pause_and_inventory()
	await _check_passage()
	await _check_needle_recovery()
	await _check_encounters()
	await _check_restart_and_continue()
	await _check_unknown_saved_entry()
	await _check_new_game_reset()
	await _check_ending()
	await _check_unreadable_title()
	await _close_main()
	_check(SaveScript.new(_save_path).delete_save(), "delete isolated campaign checkpoints")
	if FileAccess.file_exists(_settings_path):
		_check(DirAccess.remove_absolute(_settings_path) == OK, "delete isolated settings")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated campaign directory")
	if _failures.is_empty():
		print("DEAD WAX CAMPAIGN PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("CAMPAIGN FAIL: " + failure)
	quit(1)

func _check_registry() -> void:
	var ids: Array[StringName] = ChapterScript.room_ids()
	_check(ids.size() == 15, "campaign contains fifteen authored rooms")
	_check(ids.has(ChapterScript.START_ROOM) and ids.has(ChapterScript.END_ROOM), "chapter endpoints belong to registry")
	_check(not ChapterScript.has_room(&"unauthored_room"), "unknown room is outside authored campaign")
	_check(ChapterScript.create_room(&"unauthored_room") == null, "unknown room cannot create a shell in campaign")
	var entries := {}
	var edges: Array[Dictionary] = []
	for id in ids:
		var room: Node2D = ChapterScript.create_room(id)
		room.process_mode = Node.PROCESS_MODE_DISABLED
		room.progression = ProgressionScript.new()
		root.add_child(room)
		_check(room.room_id == id and not String(room.band_name).is_empty(), "%s boots with authored identity" % id)
		_check(not String(room.objective_label).is_empty(), "%s provides a player objective" % id)
		entries[id] = room.entry_points.keys()
		var portals: Array[Vector2] = [room.spawn_pos]
		for entry_id in room.entry_points:
			portals.append(room.entry_points[entry_id])
		var persistent := {}
		var exit_count := 0
		for child in room.get_children():
			if child.has_meta("chapter_state_id"):
				var state_id := String(child.get_meta("chapter_state_id"))
				_check(not persistent.has(state_id), "%s persistent encounter IDs are unique: %s" % [id, state_id])
				persistent[state_id] = true
			if child.is_in_group("room_exit"):
				exit_count += 1
				_check(ChapterScript.has_room(child.target_room), "%s passage remains in the authored chapter" % id)
				_check(child.required_refrain == -1, "%s passage never requires an unearned Refrain or recorded technique" % id)
				portals.append(child.position)
				edges.append({"source": id, "target": child.target_room, "entry": child.target_entry})
		_check(exit_count > 0, "%s has a way out" % id)
		_check_geometry(room, portals)
		room.free()
	for edge in edges:
		_check(edge.entry in entries.get(edge.target, []), "%s > %s names a real arrival" % [edge.source, edge.target])
	var reached := {}
	var frontier: Array[StringName] = [ChapterScript.START_ROOM]
	while not frontier.is_empty():
		var id: StringName = frontier.pop_front()
		if reached.has(id):
			continue
		reached[id] = true
		for edge in edges:
			if edge.source == id:
				frontier.append(edge.target)
	_check(reached.size() == ids.size(), "every authored room is connected to the opening")

func _check_geometry(room: Node2D, points: Array[Vector2]) -> void:
	var solids: Array[Rect2] = []
	for child in room.get_children():
		# Listening locks can be opened; their collision is checked in persistence.
		if not (child is StaticBody2D) or child.has_meta("chapter_state_id"):
			continue
		for shape_node in child.get_children():
			if shape_node is CollisionShape2D and shape_node.shape is RectangleShape2D:
				var size: Vector2 = shape_node.shape.size
				solids.append(Rect2(child.position + shape_node.position - size / 2.0, size))
	var reached := {}
	var frontier: Array[int] = []
	for index in solids.size():
		if _supports(solids[index], room.spawn_pos):
			frontier.append(index)
	var jump_rise := pow(SkipScript.JUMP_VELOCITY, 2.0) / (2.0 * SkipScript.GRAVITY)
	var jump_run := SkipScript.RUN_SPEED * 2.0 * absf(SkipScript.JUMP_VELOCITY) / SkipScript.GRAVITY * 0.8
	while not frontier.is_empty():
		var current: int = frontier.pop_front()
		if reached.has(current):
			continue
		reached[current] = true
		for index in solids.size():
			var rise := solids[current].position.y - solids[index].position.y
			var gap := maxf(solids[index].position.x - solids[current].end.x, solids[current].position.x - solids[index].end.x)
			if not reached.has(index) and rise <= jump_rise and gap <= jump_run:
				frontier.append(index)
	for point in points:
		var supported := false
		var reachable := false
		for index in solids.size():
			if _supports(solids[index], point):
				supported = true
				reachable = reachable or reached.has(index)
		_check(supported, "%s arrival/passage %s has floor beneath the player" % [room.room_id, point])
		var optional_loft: bool = room.room_id == &"the_stalls" and point.y == room.entry_points[&"from_worn_gallery"].y
		if optional_loft:
			_check(not reachable, "Stalls loft is an optional earned return, above the ordinary jump route")
		else:
			_check(reachable, "%s arrival/passage %s has a route over jump-sized steps" % [room.room_id, point])

func _supports(solid: Rect2, center: Vector2) -> bool:
	return absf(solid.position.y - center.y - PLAYER_HALF_HEIGHT) < 1.0 and center.x >= solid.position.x + 17.0 and center.x <= solid.end.x - 17.0

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _save_path
	_main.settings_path = _settings_path
	root.add_child(_main)
	await _frames(3)

func _check_title_and_new_game() -> void:
	_check(not _main.development_mode, "normal boot never opts into development controls")
	_check(paused and _main.game_menu.is_open and _main.game_menu.screen == "title", "normal boot opens title with simulation paused")
	_check(not _main._has_session and not FileAccess.file_exists(_save_path), "title backdrop does not start or save a campaign")
	var start: Vector2 = _main.player.position
	Input.action_press("move_right")
	Input.action_press("debug_grant")
	await _frames(5)
	Input.action_release("move_right")
	Input.action_release("debug_grant")
	_check(_main.player.position == start and _main.progression.unlocked_refrains().is_empty(), "title suppresses movement and debug unlocks")
	_main.game_menu.new_game_requested.emit()
	await _frames(3)
	_check(_main.opening.is_open and paused and not _main.game_menu.is_open, "New game begins the opening with the world paused")
	_main.opening.skip()
	await create_timer(0.6).timeout
	await _frames(3)
	_check(_main._has_session and not paused and not _main.game_menu.is_open, "New game starts a live session")
	_check(_main.world_room_id == &"headshell" and _main.room_entry_id == &"default", "New game starts in the Headshell")
	_check(_main.save_store.has_save(), "New game writes a recoverable checkpoint")
	start = _main.player.position
	_input_key(KEY_D, true)
	await _physics_frames(6)
	_input_key(KEY_D, false)
	_check(_main.player.position.x > start.x, "movement runs during the campaign (start=%s, end=%s, velocity=%s, paused=%s)" % [start, _main.player.position, _main.player.velocity, paused])
	Input.action_press("debug_grant")
	Input.action_press("world_map")
	Input.action_press("switch_room")
	await _frames(3)
	for action in ["debug_grant", "world_map", "switch_room"]:
		Input.action_release(action)
	_check(_main.world_room_id == &"headshell" and _main.progression.unlocked_refrains().is_empty(), "editor/debug build still hides room cycling and grant cheats in normal play")

func _check_pause_and_inventory() -> void:
	await _key(KEY_ESCAPE)
	_check(paused and _main.game_menu.screen == "pause", "physical Escape opens pause menu")
	var position: Vector2 = _main.player.position
	var shine: int = _main.player.shine
	var last_strike: int = _main.player.last_strike_ms
	for action in ["move_right", "jump", "strike", "set", "restart"]:
		Input.action_press(action)
	await _physics_frames(6)
	for action in ["move_right", "jump", "strike", "set", "restart"]:
		Input.action_release(action)
	_check(_main.player.position == position and _main.player.shine == shine and _main.player.last_strike_ms == last_strike, "pause suppresses movement, strike and restart")
	_main.game_menu.settings = {"volume": 0.35, "reduced_motion": true, "fullscreen": false}
	_main.game_menu.settings_changed.emit(_main.game_menu.settings)
	_check(not _main.camera.position_smoothing_enabled, "reduced motion stops camera smoothing")
	_check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.35), "volume applies to the audio bus")
	_check(FileAccess.file_exists(_settings_path), "settings are stored separately from a campaign")
	await _key(KEY_ESCAPE)
	_check(not paused and not _main.game_menu.is_open, "physical Escape resumes without reopening pause")
	await _key(KEY_I)
	_check(paused and _main.inventory.is_open(), "physical I opens The Book during a session")
	_main._pause_game()
	_check(not _main.game_menu.is_open, "pause cannot stack over The Book")
	await _key(KEY_I)
	_check(not paused and not _main.inventory.is_open(), "closing The Book restores play")
	await _joy_button(JOY_BUTTON_BACK)
	_check(paused and _main.game_menu.screen == "pause", "controller Back opens pause")
	await _joy_button(JOY_BUTTON_B)
	_check(not paused and not _main.game_menu.is_open, "controller B closes pause")
	if _main.game_menu.is_open:
		_main._resume_game()
		await _frames(3)
	await _joy_button(JOY_BUTTON_BACK)
	var focus: Control = _main.get_viewport().gui_get_focus_owner()
	_check(focus is Button and focus.text == "Resume", "controller pause initially focuses Resume")
	await _joy_button(JOY_BUTTON_DPAD_DOWN)
	focus = _main.get_viewport().gui_get_focus_owner()
	_check(focus is Button and focus.text == "Settings", "controller D-pad moves between menu choices")
	await _joy_button(JOY_BUTTON_A)
	_check(paused and _main.game_menu.screen == "settings", "controller A opens the selected settings page")
	await _joy_button(JOY_BUTTON_B)
	_check(paused and _main.game_menu.screen == "pause", "controller B returns from settings to pause")
	position = _main.player.position
	await _joy_button(JOY_BUTTON_A)
	await _physics_frames(3)
	_check(not paused and not _main.game_menu.is_open, "controller A confirms Resume")
	_check(absf(_main.player.position.y - position.y) < 1.0 and _main.player.velocity.y >= 0.0, "controller confirmation never leaks into a gameplay jump")
	if _main.game_menu.is_open:
		_main._resume_game()
		await _frames(3)
	await _joy_button(JOY_BUTTON_START)
	_check(paused and _main.inventory.is_open() and not _main.game_menu.is_open, "controller Start remains The Book")
	await _joy_button(JOY_BUTTON_START)
	_check(not paused and not _main.inventory.is_open(), "controller Start closes The Book")

func _check_passage() -> void:
	var passage: Node2D = null
	for child in _main.room.get_children():
		if child.is_in_group("room_exit") and child.target_room == &"horn_plaza":
			passage = child
	_check(passage != null, "Headshell has its physical plaza passage")
	if passage == null:
		return
	_main.player.position = passage.position
	_main.player.velocity = Vector2.ZERO
	await _physics_frames(2)
	await _key(KEY_E)
	_check(_main.world_room_id == &"horn_plaza" and _main.room_entry_id == &"from_headshell", "physical E transitions to the passage's named arrival")
	_check(_main.player.position.distance_to(_main.room.entry_position(&"from_headshell")) < 3.0, "passage lands at its named entry")
	_main.player.position += Vector2(120, -100)
	_main._respawn()
	_check(_main.player.position == _main.room.entry_position(&"from_headshell"), "respawn keeps the active passage entry")

func _check_encounters() -> void:
	_main._load_world_room(&"practice_room", &"from_high_street")
	await _frames(3)
	var door := _persistent(&"practice_count_in")
	_check(door != null, "practice contains its stable listening lock")
	if door != null:
		door.call("_open")
		await _frames(2)
		_check(_main.encounters.get("practice_room/practice_count_in") == "opened", "opening signal records the listening lock")
		_check(_main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN), "opened listening lock discovers Count-In")
	var patch := _persistent(&"practice_wax")
	if patch != null:
		_main.player.position = patch.position
		_main.player.hooded = true
		patch.call("_process", 1.3)
		_main.player.hooded = false
		_check(patch.done and _main.player.shine == 1, "polishing earns Shine in the campaign")
	_main._load_world_room(&"groove_yard", &"from_the_stalls")
	await _frames(3)
	var first := _persistent(&"yard_first_voice")
	var last := _persistent(&"yard_last_voice")
	_check(first != null and last != null, "yard contains two distinct persistent voices")
	if first != null and last != null:
		_main.player.position = first.position + Vector2(-150, -13)
		_main.player.setting = true
		first.call("_process", 1.21)
		_main.player.setting = false
		for strike in range(4):
			last.call("on_player_strike", last.position, false)
		await _frames(2)
		_check(_main.encounters.get("groove_yard/yard_first_voice") == "freed", "SET mercy records freed outcome")
		_check(_main.encounters.get("groove_yard/yard_last_voice") == "shattered", "striking records a distinct shattered outcome")
	_main._load_world_room(&"practice_room", &"from_horn_plaza")
	await _frames(3)
	door = _persistent(&"practice_count_in")
	patch = _persistent(&"practice_wax")
	_check(door != null and door.is_open and door.get_node("block").disabled, "room recreation keeps opened lock passable")
	_check(patch != null and patch.done and _main.player.shine == 1, "room recreation keeps polished wax spent")
	_main._load_world_room(&"groove_yard", &"from_the_stalls")
	await _frames(3)
	_check(_persistent(&"yard_first_voice") == null and _persistent(&"yard_last_voice") == null, "freed and shattered voices stay gone on room recreation")
	_main.player.shine = 19
	_main.progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
	_main._return_to_title()
	await _frames(3)
	_check(paused and not _main._has_session and _main.game_menu.screen == "title", "save and return to title ends the active session")
	var snapshot: Dictionary = _main.save_store.load_game()
	_check(snapshot.shine == 19 and snapshot.encounters.get("groove_yard/yard_first_voice") == "freed" and snapshot.encounters.get("groove_yard/yard_last_voice") == "shattered", "disk checkpoint preserves Shine and distinct choices")

func _check_needle_recovery() -> void:
	_check(_main._health == 3, "campaign starts with three needle hits")
	var arrival: Vector2 = _main.room.entry_position(_main.room_entry_id)
	_main.player.position += Vector2(220, -100)
	_main.player.shine = 7
	_main._on_player_hit()
	_check(_main._health == 2 and not _main._respawn_pending, "one hit spends a needle point without ending play")
	_main._on_player_hit()
	_main._on_player_hit()
	_check(_main._respawn_pending, "third hit queues one recovery")
	await _frames(3)
	_check(_main._health == 3 and not _main._respawn_pending, "needle recovery restores health once")
	_check(_main.player.position.distance_to(arrival) < 3 and _main.room_entry_id == &"from_headshell", "needle recovery returns to the active passage entry")
	_check(_main.player.shine == 7 and _main.world_room_id == &"horn_plaza", "needle recovery preserves room and earned Shine")
	_main.player.shine = 0

func _check_restart_and_continue() -> void:
	await _close_main()
	await _boot()
	_check(_main.game_menu._can_continue, "fresh boot offers Continue for a valid saved chapter")
	_check(_main.game_menu.settings.reduced_motion and is_equal_approx(_main.game_menu.settings.volume, 0.35), "settings survive a fresh Main instance")
	_main.game_menu.continue_requested.emit()
	await _frames(3)
	_check(not paused and _main._has_session and _main.world_room_id == &"groove_yard", "Continue restores the saved authored room")
	_check(_main.room_entry_id == &"from_the_stalls" and _main.player.shine == 19, "Continue restores entry and Shine")
	_check(_main.progression.has_refrain(ProgressionScript.Refrain.GATHER) and _main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN), "Continue restores earned Refrains and discovered knowledge")
	_check(_persistent(&"yard_first_voice") == null and _persistent(&"yard_last_voice") == null, "Continue cannot respawn resolved voices")
	_main._load_world_room(&"practice_room", &"from_horn_plaza")
	await _frames(3)
	var door := _persistent(&"practice_count_in")
	_check(door != null and door.is_open and door.get_node("block").disabled, "Continue preserves locks in other rooms")

func _check_new_game_reset() -> void:
	_main._new_game(false)
	await _frames(3)
	_check(_main.world_room_id == ChapterScript.START_ROOM and _main.encounters.is_empty() and _main.player.shine == 0, "New game clears prior room, encounters and Shine")
	_check(_main.progression.unlocked_refrains().is_empty() and _main.progression.discovered_techniques().is_empty() and not _main.chapter_complete, "New game clears earned progression and completion")
	_check(_main.game_menu.settings.reduced_motion, "New game preserves player settings")
	var snapshot: Dictionary = _main.save_store.load_game()
	_check(snapshot.room_id == "headshell" and snapshot.encounters.is_empty() and snapshot.shine == 0, "New game replaces the active checkpoint")
	_write_raw(_save_path, "{interrupted checkpoint")
	var recovered: Dictionary = _main.save_store.load_game()
	_check(not recovered.is_empty(), "New game also prepares a valid recovery checkpoint")
	if not recovered.is_empty():
		_check(recovered.room_id == "headshell" and recovered.encounters.is_empty() and recovered.shine == 0 and recovered.progression.refrains.is_empty(), "New game recovery cannot resurrect the replaced campaign")
	_check(_main._persist_session(), "repair isolated primary after recovery check")

func _check_unknown_saved_entry() -> void:
	var snapshot: Dictionary = _main.save_store.load_game()
	snapshot.room_id = "practice_room"
	snapshot.entry_id = "from_missing_room"
	_check(_main.save_store.save_game(snapshot), "prepare valid checkpoint with an obsolete named arrival")
	_main._has_session = false
	_main._show_title()
	_main._continue_game()
	await _frames(3)
	_check(_main.world_room_id == &"practice_room" and _main.room_entry_id == &"default", "Continue normalizes an obsolete saved arrival")
	_check(_main.player.position.distance_to(_main.room.spawn_pos) < 3, "obsolete arrival uses the room's supported default")
	_main._respawn()
	_check(_main.room_entry_id == &"default" and _main.player.position == _main.room.spawn_pos, "future respawns retain the normalized arrival")
	_check(_main._persist_session() and _main.save_store.load_game().entry_id == "default", "next checkpoint repairs the obsolete arrival on disk")

func _check_ending() -> void:
	# Combat outcomes are exercised in tonearm_test and overture_test. This
	# check covers the final interaction and its menu/save/Continue boundary.
	_main.encounters["the_arm/tonearm"] = "freed"
	_main._load_world_room(ChapterScript.END_ROOM, &"from_smoothed_floor")
	await _frames(3)
	var marker: Node2D = null
	for child in _main.room.get_children():
		if child.is_in_group("chapter_endpoint"):
			marker = child
	_check(marker != null, "authored endpoint contains an intentional listening point")
	if marker == null:
		return
	_main.player.position = marker.position
	_main.player.velocity = Vector2.ZERO
	await _physics_frames(4)
	await _key(KEY_E)
	_check(_main.chapter_complete and paused and _main.game_menu.screen == "ending", "physical E at the listening point completes the chapter")
	_check(_main.save_store.load_game().completed, "chapter completion reaches disk")
	_check(not marker.try_activate(), "listening point only completes once")
	_main._resume_game()
	await _frames(3)
	_main._on_chapter_completed()
	await _frames(3)
	_check(not paused and not _main.game_menu.is_open, "duplicate completion cannot replay the ending")
	_main._return_to_title()
	await _close_main()
	await _boot()
	_main._continue_game()
	await _frames(3)
	marker = null
	for child in _main.room.get_children():
		if child.is_in_group("chapter_endpoint"):
			marker = child
	_check(_main.chapter_complete and marker != null and marker.used, "Continue restores a completed listening point as used")
	if marker != null:
		_main.player.position = marker.position
		_main.player.velocity = Vector2.ZERO
		await _physics_frames(4)
		await _key(KEY_E)
		_check(not paused and not _main.game_menu.is_open, "restored listening point does not replay the ending")

func _check_unreadable_title() -> void:
	await _close_main()
	_write_raw(_save_path, "{broken primary")
	_write_raw(_save_path + ".bak", "{broken recovery")
	await _boot()
	_check(paused and _main.game_menu.screen == "title" and not _main.game_menu._can_continue, "unreadable primary and backup cannot offer Continue")
	_check(_main.game_menu._notice.visible and not _main.game_menu._notice.text.is_empty(), "unreadable save is explained on the title screen")
	_check(not _main._has_session, "unreadable save does not silently start a replacement game")

func _persistent(id: StringName) -> Node:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id:
			return child
	return null

func _key(code: Key) -> void:
	_input_key(code, true)
	await _frames(3)
	_input_key(code, false)
	await _frames(2)

func _input_key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _joy_button(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(3)
	event = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)

func _write_raw(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "open isolated campaign fixture")
		return
	file.store_string(content)
	file.close()

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _physics_frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame

func _close_main() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
