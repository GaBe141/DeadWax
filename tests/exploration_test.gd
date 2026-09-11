extends SceneTree
## A restored phrase earns a real Refrain; two distant seams become saved
## return passages. Every checkpoint and deliberate failure is private.

const MainScene := preload("res://scenes/main.tscn")
const Catalog := preload("res://scripts/exploration_catalog.gd")
const Exploration := preload("res://scripts/exploration_state.gd")
const Fixture := preload("res://scripts/exploration_fixture.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Save := preload("res://scripts/save_store.gd")
const RETURNS := [
	{"id": &"warren_return", "near": &"high_street", "far": &"verse_warren_n"},
	{"id": &"gallery_return", "near": &"headshell", "far": &"deep_gallery"},
]
var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _reward_events := 0
var _reward_saved_before_signal := true

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-exploration-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private exploration checkpoint directory")
	await _boot()
	_main._new_game(false)
	await _physics(4)
	_seed_completed_approach()
	await _reward_order()
	await _reward_context()
	for route in RETURNS:
		await _open_and_return(route)
	await _continue_and_practice()
	await _old_restored_spool()
	await _close()
	await _development()
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private campaign and backup")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		_check(DirAccess.remove_absolute(_directory + "/settings.cfg") == OK, "remove private settings")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private exploration directory")
	if _failures.is_empty():
		print("DEAD WAX EXPLORATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("EXPLORATION FAIL: " + failure)
	quit(1)

func _seed_completed_approach() -> void:
	# This late-game transaction fixture begins beyond the Tonearm. Existing
	# discovery/ability suites exercise earning the approach and the phrase.
	_main.abilities.restore_snapshot(Abilities.legacy_snapshot())
	_main.progression.unlock_refrain(Progression.Refrain.GATHER)
	_main.progression.discover_technique(Progression.Technique.COUNT_IN)
	_main.economy.restore(7, [])
	_main.encounters = {"the_arm/tonearm": "freed", "high_street/street_looper": "shattered",
		"groove_yard/yard_first_voice": "freed", "verse_warren_n/north_voice": "freed",
		"verse_warren_n/lower_voice": "shattered"}
	# All ordinary observation notes are already known, so a return trip cannot
	# mask a shortcut accidentally changing rewards or historic choices.
	var collection: Dictionary = _main.collection.snapshot()
	for species in collection.bestiary:
		collection.bestiary[species].seen = true
	for hunt in collection.hunts:
		collection.hunts[hunt].discovered = true
	_main.collection.restore_snapshot(collection)
	_main.collection.backfill(_main.encounters)
	_main.progression.refrain_unlocked.connect(_on_refrain)

func _reward_order() -> void:
	await _load(&"verse_warren_n")
	var source := _reward()
	_check(source != null and source.position == Catalog.reward().position, "North Warren owns the fixed Refrain below its receiver")
	if source == null: return
	_check(source.progression == _main.progression and source.discoveries == _main.discoveries
		and source.exploration == _main.exploration and source.pressing == _main.pressing,
		"world fixtures read Main's exact owned models")
	_check(_main.inventory.exploration == _main.exploration and _main.map_menu.exploration == _main.exploration,
		"Book and map read the same exploration model")
	_check(not source is CollisionObject2D and not source.has_meta("chapter_state_id"), "Refrain impression adds no collision or story identity")
	await _place(source.position)
	var before := _preserved()
	for stage in ["missing", "empty", "recorded"]:
		_main.discoveries.restore_snapshot({"echo_spool": stage, "survey_slip": false})
		source.refresh()
		await _tap(KEY_E)
		_check(not source.visible and not source.is_available() and not _has_jump_cut(), "the " + stage + " spool cannot grant Jump-Cut")
		_main._on_exploration_requested(&"claim_jump_cut", source)
		await _tap(KEY_F)
		_check(not _has_jump_cut() and not _main.pressing.on_b_side() and _reward_events == 0, "out-of-order reward requests and unearned F remain inert")
	_main.discoveries.restore_snapshot({"echo_spool": "missing", "survey_slip": false})
	_check(_preserved() == before, "unavailable Refrain requests change no approach progress, currency, collection, or choice")
	_key(KEY_E, true)
	await _physics(2)
	_main.discoveries.restore_snapshot({"echo_spool": "restored", "survey_slip": true})
	_main._refresh_exploration()
	await _physics(5)
	_check(source.visible and source.is_available() and not _has_jump_cut(), "restoring the phrase reveals a pickup but a held E never auto-claims it")
	_key(KEY_E, false)
	await _physics(2)
	await _tap(KEY_F)
	_check(not _main.pressing.on_b_side() and not _has_jump_cut(), "the completed spool alone never enables flipping")

func _reward_context() -> void:
	var source := _reward()
	if source == null: return
	var before := _preserved()
	var progression_before: Dictionary = _main.progression.snapshot()
	await _invalid_context(source, &"claim_jump_cut")
	_check(_main.progression.snapshot() == progression_before and _reward_events == 0, "rejected contexts never expose a Refrain signal")
	await _place(source.position)
	_check(_main._persist_session(), "save the restored phrase before its reward")
	var saved: Dictionary = _main.save_store.load_game()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block the private Refrain write")
	await _tap(KEY_E)
	_check(_main.progression.snapshot() == progression_before and _main.save_store.load_game() == saved,
		"failed Refrain write restores all permission state and keeps the previous checkpoint")
	_check(source.visible and source.is_available() and _reward_events == 0, "failed Refrain stays retryable without an unlock cue")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock the private Refrain write")
	_joy(JOY_BUTTON_Y, true)
	await _physics(6)
	_check(_has_jump_cut() and _reward_events == 1 and _reward_saved_before_signal, "fresh grounded controller Y commits Jump-Cut before its sole unlock signal")
	_check(not source.visible and not source.is_available(), "owned Refrain retires its presentation without a repeat pickup")
	_joy(JOY_BUTTON_Y, false)
	await _physics(2)
	await _tap(KEY_E)
	_main._on_exploration_requested(&"claim_jump_cut", source)
	_check(_reward_events == 1 and _main.save_store.load_game().progression.refrains == ["gather", "jump-cut"], "repeated reward intent cannot grant another Refrain")
	_check(_preserved() == before, "Jump-Cut leaves Shine, equipment, techniques, the spool, and both story outcomes intact")

func _invalid_context(source: Node2D, action: StringName) -> void:
	var before: Dictionary = {"exploration": _main.exploration.snapshot(), "progression": _main.progression.snapshot()}
	await _place(source.position + Vector2(Fixture.INTERACT_RADIUS + 1.0, 0))
	_main._on_exploration_requested(action, source)
	await _place(source.position)
	_key(KEY_SPACE, true)
	await _physics(1)
	_key(KEY_SPACE, false)
	_check(not _main.player.is_on_floor(), "an actual jump leaves the interaction floor for " + String(source.definition.id))
	_main._on_exploration_requested(action, source)
	await _place(source.position)
	_check(_main.player.is_on_floor(), "authored exploration origin supports a grounded interaction")
	var foreign := Fixture.new()
	foreign.definition = source.definition.duplicate(true)
	foreign.position = source.position
	foreign.progression = _main.progression
	foreign.discoveries = _main.discoveries
	foreign.exploration = _main.exploration
	foreign.pressing = _main.pressing
	root.add_child(foreign)
	_main._on_exploration_requested(action, foreign)
	root.remove_child(foreign)
	# A second real script under the room still lacks the registered identity.
	_main.room.add_child(foreign)
	_main._on_exploration_requested(action, foreign)
	_main.room.remove_child(foreign)
	foreign.free()
	source.position.x += 1.0
	_main._on_exploration_requested(action, source)
	source.position.x -= 1.0
	var original: Dictionary = source.definition.duplicate(true)
	source.definition.position += Vector2.ONE
	_main._on_exploration_requested(action, source)
	source.definition = original
	_main._on_exploration_requested(&"invented", source)
	_main._pause_game()
	_main._on_exploration_requested(action, source)
	_main._resume_game()
	await _physics(3)
	_main.inventory.open_inventory()
	_main._on_exploration_requested(action, source)
	_main.inventory.close_inventory()
	await _physics(3)
	_main._transition_pending = true
	_main._on_exploration_requested(action, source)
	_main._transition_pending = false
	_main._respawn_pending = true
	_main._on_exploration_requested(action, source)
	_main._respawn_pending = false
	_check(_main.exploration.snapshot() == before.exploration and _main.progression.snapshot() == before.progression,
		"range, air, foreign/duplicate/moved identity, wrong action, menus, transition, and recovery reject " + String(action))

func _open_and_return(route: Dictionary) -> void:
	var id := StringName(route.id)
	var near_definition := Catalog.definition(route.near, id)
	var far_definition := Catalog.definition(route.far, id)
	var before := _preserved()
	await _load(route.near)
	await _face_a()
	var source := _return(id)
	_check(source != null and source.is_in_group("reverse_passage") and source.is_in_group("room_exit"), "near " + String(id) + " is one real return endpoint")
	if source == null: return
	await _place(source.position)
	await _tap(KEY_E)
	await _tap(KEY_F)
	_check(_main.pressing.on_b_side(), "earned F turns the actual near room over")
	await _tap(KEY_E)
	_main._on_exploration_requested(&"open_shortcut", source)
	_check(not _main.exploration.is_open(id) and _main.world_room_id == route.near and source.is_locked(), "the near end stays closed on A and B until unsealed from below")
	await _face_a()
	await _load(route.far)
	source = _return(id)
	_check(source != null and source.position == far_definition.position, "far " + String(id) + " uses its authored fixed origin")
	if source == null: return
	await _place(source.position)
	await _tap(KEY_E)
	_main._on_exploration_requested(&"enter_shortcut", source)
	_check(not _main.exploration.is_open(id) and _main.world_room_id == route.far, "far A-side and premature entry cannot open or traverse " + String(id))
	await _tap(KEY_F)
	_check(_main.pressing.on_b_side() and source.is_available(), "turning the far room reveals the unsealing interaction")
	await _invalid_context(source, &"open_shortcut")
	await _place(source.position)
	_check(_main._persist_session(), "save closed shortcut before its transaction")
	var saved: Dictionary = _main.save_store.load_game()
	var state_before: Dictionary = _main.exploration.snapshot()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block private shortcut write")
	await _tap(KEY_E)
	_check(_main.exploration.snapshot() == state_before and _main.save_store.load_game() == saved and source.is_locked(),
		"failed " + String(id) + " write leaves both world access and disk closed")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock private shortcut write")
	_key(KEY_E, true)
	await _physics(9)
	_check(_main.exploration.is_open(id) and not source.is_locked() and _main.save_store.load_game().exploration == _main.exploration.snapshot(),
		"fresh E saves and presents the permanent " + String(id) + " opening")
	_check(_main.world_room_id == route.far and not _main._transition_pending, "unsealing requires a separate press to travel, even while E stays held")
	_key(KEY_E, false)
	await _physics(2)
	_main._on_exploration_requested(&"open_shortcut", source)
	_check(_main.exploration.snapshot().opened.count(String(id)) == 1 and _main.world_room_id == route.far, "duplicate opening callback neither reopens nor travels")
	_key(KEY_E, true)
	await _physics(9)
	_check(_main.world_room_id == far_definition.target_room and _main.room_entry_id == far_definition.target_entry,
		"a new held E enters " + String(id) + " once at its named near arrival")
	_check(_main.player.position.distance_to(_main.room.entry_position(far_definition.target_entry)) < 3.0,
		"outbound return lands on its authored arrival without a held-input bounce")
	_key(KEY_E, false)
	await _physics(2)
	await _face_a()
	source = _return(id)
	_check(source != null and source.is_open(), "opened near endpoint works on the A-side")
	if source == null: return
	await _place(source.position)
	await _tap(KEY_E)
	_check(_main.world_room_id == near_definition.target_room and _main.room_entry_id == near_definition.target_entry,
		"fresh E walks " + String(id) + " back to its far named arrival on A")
	_check(_main.player.is_on_floor(), "the reverse arrival is supported")
	_check(_preserved() == before and _reward_events == 1, "opening and both directions preserve rewards, equipment, and story choices")

func _continue_and_practice() -> void:
	_check(_main.exploration.snapshot().opened == ["warren_return", "gallery_return"], "both independently earned returns are recorded once")
	var model: RefCounted = _main.exploration
	var before := _preserved()
	var room_id: StringName = _main.world_room_id
	var entry_id: StringName = _main.room_entry_id
	await _tap(KEY_F)
	_check(_main.pressing.on_b_side(), "save fixture ends on the far face")
	_check(_main._persist_session(), "persist the return arrival and earned Refrain")
	_main._return_to_title()
	await _physics(3)
	_main._continue_game()
	await _physics(5)
	_check(_main.exploration == model and _main.exploration.snapshot().opened == ["warren_return", "gallery_return"], "Continue silently restores both openings into the owned model")
	_check(_main.world_room_id == room_id and _main.room_entry_id == entry_id and _main.player.is_on_floor(), "Continue retains a newly added shortcut entry and its safe floor")
	_check(not _main.pressing.on_b_side() and _has_jump_cut() and _reward_events == 1, "Continue begins on A with Jump-Cut without a repeated pickup signal")
	_check(_return(&"gallery_return").is_open() and _preserved() == before, "restored A-side return remains usable without rewriting collection or choices")
	_main.player.position += Vector2(20, -30)
	await _tap(KEY_R)
	_check(_main.player.position.distance_to(_main.room.entry_position(entry_id)) < 3.0
		and _main.exploration.snapshot().opened == ["warren_return", "gallery_return"], "physical R returns to the shortcut entry and preserves both openings")
	_check(_has_jump_cut() and _reward_events == 1 and _preserved() == before, "recovery keeps the Refrain without replaying its signal or rewards")
	await _load(&"verse_warren_n")
	_check(_reward() != null and not _reward().visible and _reward_events == 1, "returning to the receiver silently hides an already owned Refrain")
	_main._persist_session()
	_main._return_to_title()
	await _physics(3)
	var saved: Dictionary = _main.save_store.load_game()
	_main._start_practice()
	await _physics(4)
	_check(_main.practice_mode and _main.exploration != model and _main.exploration.snapshot() == Exploration.default_snapshot(), "Move practice has disposable closed exploration")
	_check(get_nodes_in_group("exploration_fixture").is_empty(), "empty practice has no reward or shortcut fixtures")
	_main.exploration.open_shortcut(&"warren_return")
	_main._persist_session()
	_check(_main.save_store.load_game() == saved, "practice cannot persist a fabricated opened return")
	_main._return_to_title()
	await _physics(3)
	_check(_main.exploration == model and _main.exploration.snapshot().opened == ["warren_return", "gallery_return"], "leaving practice restores original exploration identity and both openings")
	_main._start_practice()
	await _physics(3)
	_main._new_game(false)
	await _physics(4)
	_check(not _main.practice_mode and _main.exploration == model and _main.exploration.snapshot() == Exploration.default_snapshot(), "New Game from practice resets the restored campaign model")
	_check(not _has_jump_cut() and _main.save_store.load_game().exploration == Exploration.default_snapshot(), "New Game removes Jump-Cut and both disk openings")

func _old_restored_spool() -> void:
	var old: Dictionary = _main.save_store.load_game()
	old.erase("exploration")
	old.room_id = "verse_warren_n"
	old.entry_id = "from_verse_hall"
	old.discoveries = {"echo_spool": "restored", "survey_slip": true}
	old.encounters = {"the_arm/tonearm": "shattered", "verse_warren_n/north_voice": "freed", "verse_warren_n/lower_voice": "shattered"}
	old.shine = 7
	var file := FileAccess.open(_main.save_path, FileAccess.WRITE)
	_check(file != null, "open a private pre-exploration checkpoint")
	if file == null: return
	file.store_string(JSON.stringify(old))
	file.close()
	_main._continue_game()
	await _physics(5)
	_check(_main.exploration.snapshot() == Exploration.default_snapshot() and not _has_jump_cut(), "an old restored spool grants neither automatic Jump-Cut nor a return opening")
	var source := _reward()
	_check(source != null and source.visible and source.is_available(), "an existing restored spool still exposes its unclaimed Refrain")
	if source == null: return
	await _place(source.position)
	var before := _preserved()
	var events_before := _reward_events
	await _tap(KEY_E)
	_check(_has_jump_cut() and _reward_events == events_before + 1, "an old completed discovery collects the new Refrain through fresh E")
	_check(_preserved() == before and _main.encounters["the_arm/tonearm"] == "shattered", "old force and mercy choices, Shine, and discovered items remain unchanged")

func _development() -> void:
	var store := Save.new(_directory + "/checkpoint.json")
	var saved := store.load_game()
	var development: Node2D = MainScene.instantiate()
	development.development_mode = true
	development.save_path = _directory + "/checkpoint.json"
	development.settings_path = _directory + "/settings.cfg"
	root.add_child(development)
	await _physics(4)
	_check(get_nodes_in_group("exploration_fixture").is_empty(), "development mechanics rooms install no campaign exploration")
	development._load_world_room(&"verse_warren_n")
	await _physics(4)
	_check(get_nodes_in_group("exploration_fixture").is_empty(), "planned North Warren graybox has no campaign reward or return")
	development.exploration.open_shortcut(&"gallery_return")
	_check(development._persist_session() and store.load_game() == saved, "development exploration cannot overwrite the campaign")
	development.queue_free()
	await _physics(3)
	paused = false

func _on_refrain(id: int) -> void:
	if id != Progression.Refrain.JUMP_CUT: return
	_reward_events += 1
	var saved: Dictionary = _main.save_store.load_game()
	_reward_saved_before_signal = _reward_saved_before_signal and not saved.is_empty() and "jump-cut" in saved.progression.refrains

func _preserved() -> Dictionary:
	return {"abilities": _main.abilities.snapshot(), "economy": _main.economy.snapshot(),
		"discoveries": _main.discoveries.snapshot(), "collection": _main.collection.snapshot(),
		"encounters": _main.encounters.duplicate(true), "completed": _main.chapter_complete,
		"gather": _main.progression.has_refrain(Progression.Refrain.GATHER),
		"techniques": _main.progression.snapshot().techniques}

func _reward() -> Node2D:
	return _main.room.get_node_or_null("JumpCutRefrain") as Node2D

func _return(id: StringName) -> Node2D:
	return _main.room.get_node_or_null("Return_" + String(id)) as Node2D

func _has_jump_cut() -> bool:
	return bool(_main.progression.has_refrain(Progression.Refrain.JUMP_CUT))

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _physics(3)

func _load(id: StringName) -> void:
	_release()
	_main._load_world_room(id)
	await _physics(4)

func _place(position: Vector2) -> void:
	_release()
	_main.player.position = position
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _face_a() -> void:
	if _main.pressing.on_b_side():
		await _tap(KEY_F)

func _close() -> void:
	_release()
	_main.queue_free()
	await _physics(3)
	paused = false

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(2)
	_key(code, false)
	await _physics(3)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _release() -> void:
	for code in [KEY_E, KEY_F, KEY_R, KEY_SPACE, KEY_J, KEY_K, KEY_L, KEY_D, KEY_A]:
		_key(code, false)
	_joy(JOY_BUTTON_Y, false)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
