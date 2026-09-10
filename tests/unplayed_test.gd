extends SceneTree
## Real Main transitions and v1 checkpoints for the first Unplayed loop.
## Geometry across every entry is additionally checked by the campaign suites.
const MainScene := preload("res://scenes/main.tscn")
const Chapter := preload("res://scripts/chapter_three.gd")
const Campaign := preload("res://scripts/campaign.gd")
const Save := preload("res://scripts/save_store.gd")
const Patch := preload("res://scripts/polish_patch.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-unplayed-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated expansion checkpoint directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _physics(3)
	await _check_seal()
	await _check_loop()
	await _check_encounters()
	await _check_saved_locations()
	await _check_gallery()
	_main.queue_free()
	await _physics(3)
	paused = false
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "delete isolated expansion saves")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated expansion checkpoint directory")
	if _failures.is_empty():
		print("DEAD WAX UNPLAYED PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures: push_error("UNPLAYED FAIL: " + failure)
		quit(1)

func _check_seal() -> void:
	for outcome in ["freed", "shattered"]:
		_main._new_game(false)
		await _physics(3)
		_main._load_world_room(&"the_arm", &"from_smoothed_floor")
		await _physics(4)
		var passage := _exit_to(&"the_drop")
		_check(passage != null and passage.is_locked(), "the unresolved Arm holds the new descent")
		if passage == null: continue
		_check(not passage.try_enter(), "closed Drop refuses routing")
		_check(_main.world_room_id == &"the_arm", "failed entry leaves the player in the Arm")
		_main._remember_encounter("the_arm/tonearm", outcome)
		await _physics(4)
		_check(not passage.is_locked(), outcome + " releases the Drop")
		_check(not _main.chapter_complete and not paused, "resolving the boss still waits for an explicit ending interaction")
		var markers := get_nodes_in_group("chapter_endpoint")
		_check(markers.size() == 1, "the original listening endpoint still exists")
		for marker in markers:
			_check(marker.position.distance_to(passage.position) > 154, "Drop input cannot also activate the ending")
		var gallery := _exit_to(&"worn_gallery")
		_check(gallery != null and gallery.position.distance_to(passage.position) > 148, "Drop input cannot also enter Gallery")
		await _enter(&"the_drop")
		_check(not _main.chapter_complete and not paused and not _main.game_menu.is_open, "entering the expansion does not trigger an ending menu")
		_check(_main.progression.unlocked_refrains().is_empty(), "the descent never auto-grants the optional Gather")
		_check(_main.player.shine == 0, "entering below never adds currency")
		_check(Campaign.chapter_label(&"the_drop") == "THE SCRATCH", "the Drop carries its own stratum label")

func _check_loop() -> void:
	var route: Array[StringName] = [&"the_landing", &"verse_hall", &"verse_warren_n", &"deep_gallery",
		&"verse_warren_s", &"verse_warren_n", &"verse_hall", &"the_landing", &"the_drop", &"the_arm"]
	for target in route:
		await _enter(target)
		_check(_main.player.is_on_floor(), String(target) + " named arrival settles on real support")
		_check(_main.progression.unlocked_refrains().is_empty(), "the full return loop requires no Refrain grant")
	_check(not _main.chapter_complete and not paused, "the full loop returns home without forcing completion")
	for id in Chapter.room_ids():
		_check(String(id) in _main.map_state.visited, String(id) + " is recorded by the existing visit model")
		_main._load_world_room(id)
		await _physics(3)
		for child in _main.room.get_children():
			_check(child.get_script() != Patch and not child.is_in_group("refrain_pickup"), String(id) + " preserves the nine-patch economy and earned Refrain catalog")

func _check_encounters() -> void:
	_main._load_world_room(&"verse_hall")
	await _physics(5)
	var voice := _persistent(&"hall_voice")
	_check(voice != null, "Verse Hall has its authored voice")
	if voice != null:
		var origin := voice.position
		voice.on_player_strike(voice.global_position, false)
		_check(voice.hp < voice.HP_MAX, "new voice accepts ordinary strike damage")
		_main._respawn()
		await _physics(2)
		_check(voice.hp == voice.HP_MAX and voice.position == origin, "recovery resets the unfinished voice and its authored origin")
		voice._free()
		await _physics(3)
		_check(_main.encounters.get("verse_hall/hall_voice") == "freed", "Main records the actual voice resolution signal")
		_main._load_world_room(&"verse_hall")
		await _physics(4)
		_check(_persistent(&"hall_voice") == null, "resolved voice restores silently on return")
	_main._load_world_room(&"verse_warren_s")
	await _physics(5)
	var pressing := _persistent(&"warren_pressing")
	_check(pressing != null, "South Warren has its authored pressing")
	if pressing != null:
		for hit in range(6): pressing.on_player_strike(pressing.global_position, false)
		await _physics(3)
		_check(_main.encounters.get("verse_warren_s/warren_pressing") == "shattered", "southern pressing records one permanent defeat")
		_main._respawn()
		await _physics(3)
		_main._load_world_room(&"verse_warren_s")
		await _physics(4)
		_check(_persistent(&"warren_pressing") == null, "recovery and re-entry never reform a defeated campaign pressing")
	_check(_main.player.shine == 0, "the new encounters do not mint Shine")

func _check_saved_locations() -> void:
	_main.map_state.collect()
	for id in Chapter.room_ids():
		_main._load_world_room(id)
		await _physics(3)
		var entry: StringName = _main.room.entry_points.keys()[0]
		_main._load_world_room(id, entry)
		await _physics(3)
		_main.chapter_complete = true
		_check(_main._persist_session(), String(id) + " writes a valid v1 checkpoint")
		var saved: Dictionary = _main.save_store.load_game()
		_check(saved.get("version") == 1 and saved.get("room_id") == String(id), "expanded locations preserve the checkpoint schema")
		_main._return_to_title()
		_main._continue_game()
		await _physics(4)
		_check(_main.world_room_id == id and _main.room_entry_id == entry, String(id) + " Continue restores its named arrival")
		_check(_main.chapter_complete and _main.map_state.owned, "old chapter completion and carried map survive the extension")
		_check(_main.player.shine == 0 and _main.encounters.get("verse_hall/hall_voice") == "freed", "Continue preserves wallet and prior listening outcomes")
		_main._respawn()
		await _physics(2)
		_check(_main.player.position.distance_to(_main.room.entry_position(entry)) < 2, String(id) + " recovery respects the saved arrival")

func _check_gallery() -> void:
	_main._load_world_room(&"deep_gallery")
	await _physics(3)
	var post: Node2D
	for child in _main.room.get_children():
		if child.has_method("try_listen"): post = child
	_check(post != null, "Deep Gallery contains a deliberate listening destination")
	if post == null: return
	_main.player.position = post.position
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	var old_room: StringName = _main.world_room_id
	var old_outcomes: Dictionary = _main.encounters.duplicate()
	_key(KEY_E, true)
	await _physics(2)
	_key(KEY_E, false)
	await _physics(3)
	_check(post._line == 0 and _main.world_room_id == old_room, "grounded E reads the Gallery without accidentally entering a passage")
	_check(_main.encounters == old_outcomes and _main.player.shine == 0, "the quiet destination changes no progression or rewards")

func _enter(target: StringName) -> void:
	var source: StringName = _main.world_room_id
	var passage := _exit_to(target)
	_check(passage != null and not passage.is_locked(), "%s has a usable passage to %s" % [source, target])
	if passage == null or passage.is_locked(): return
	_main.player.position = passage.position
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_key(KEY_E, true)
	await _physics(2)
	_key(KEY_E, false)
	await _physics(5)
	_check(_main.world_room_id == target and _main.room_entry_id == StringName("from_" + String(source)), "%s to %s uses Main's actual deferred passage transition" % [source, target])
	var saved: Dictionary = _main.save_store.load_game()
	_check(saved.get("room_id") == String(target), String(target) + " passage checkpoints the new location")

func _persistent(id: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id: return child
	return null

func _exit_to(target: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.is_in_group("room_exit") and child.target_room == target: return child
	return null

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
