extends SceneTree
## One carried phrase joins three existing rooms; discoveries never mint income
## or grant a traversal verb. All physical input and saves use a private fixture.
const MainScene := preload("res://scenes/main.tscn")
const Discoveries := preload("res://scripts/discoveries_state.gd")
const Station := preload("res://scripts/echo_station.gd")
const Save := preload("res://scripts/save_store.gd")
const EMPTY := {"echo_spool": "missing", "survey_slip": false}
const LOCATIONS := {
	&"collect_spool": {"room": &"deep_gallery", "position": Vector2(340, 834)},
	&"record_phrase": {"room": &"verse_warren_s", "position": Vector2(1010, 554)},
	&"restore_warren": {"room": &"verse_warren_n", "position": Vector2(350, 454)},
	&"collect_survey": {"room": &"the_landing", "position": Vector2(980, 384)},
}

var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _requests: Array[StringName] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-discoveries-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated discoveries fixture")
	_check_model()
	_check_schema()
	await _boot()
	_main._new_game(false)
	await _physics(4)
	await _check_book(false)
	await _check_locations()
	await _check_order_and_context()
	await _check_phrase_loop()
	await _check_survey()
	await _check_persistence_and_practice()
	await _check_old_continue()
	await _close()
	for file in ["checkpoint.json", "schema.json"]:
		_check(Save.new(_directory + "/" + file).delete_save(), "remove isolated " + file)
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated discoveries directory")
	if _failures.is_empty():
		print("DEAD WAX DISCOVERIES PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("DISCOVERIES FAIL: " + failure)
	quit(1)

func _check_model() -> void:
	var state := Discoveries.new()
	_check(state.snapshot() == EMPTY, "new game owns neither spool nor survey")
	for action in [&"record_phrase", &"restore_warren", &"invented_action"]:
		_check(not state.can_apply(action) and not state.apply(action) and state.snapshot() == EMPTY,
			"missing spool rejects out-of-order action " + String(action))
	for action in LOCATIONS:
		_check(Discoveries.action_room(action) == LOCATIONS[action].room, "action belongs to exactly its authored room: " + String(action))
	_check(Discoveries.action_room(&"invented_action") == &"", "unknown action has no campaign location")
	var stages := ["empty", "recorded", "restored"]
	var actions: Array[StringName] = [&"collect_spool", &"record_phrase", &"restore_warren"]
	for index in actions.size():
		var action := actions[index]
		_check(state.can_apply(action) and state.apply(action), "ordered discovery advances: " + String(action))
		var expected := {"echo_spool": stages[index], "survey_slip": false}
		_check(state.snapshot() == expected, "ordered discovery preserves the independent survey")
		_check(not state.can_apply(action) and not state.apply(action) and state.snapshot() == expected,
			"duplicate discovery cannot replay a grant: " + String(action))
	var copy := state.snapshot()
	copy.echo_spool = "missing"
	_check(state.snapshot().echo_spool == "restored", "returned snapshots cannot rewrite the carried phrase")
	_check(state.apply(&"collect_survey") and not state.apply(&"collect_survey"), "the independent survey is collected only once")
	_check(state.snapshot() == {"echo_spool": "restored", "survey_slip": true}, "survey never consumes the recorded phrase")
	state.reset()
	_check(state.snapshot() == EMPTY, "reset clears both discoveries")
	_check(state.apply(&"collect_survey") and state.snapshot().echo_spool == "missing", "survey may be found before the spool")
	for stage in ["missing", "empty", "recorded", "restored"]:
		for survey in [false, true]:
			var fixture := {"echo_spool": stage, "survey_slip": survey}
			_check(Discoveries.valid_snapshot(fixture) and state.restore_snapshot(fixture) and state.snapshot() == fixture,
				"every valid combination restores without generating extra discoveries: %s/%s" % [stage, survey])

func _check_schema() -> void:
	var state := Discoveries.new()
	var store := Save.new(_directory + "/schema.json")
	var legacy := _legacy_save()
	_check(store.save_game(legacy), "an unchanged version-one checkpoint remains valid")
	var loaded: Dictionary = store.load_game()
	_check(loaded.discoveries == EMPTY and loaded.shine == legacy.shine and loaded.progression == legacy.progression
		and loaded.encounters == legacy.encounters, "absent discoveries migrate empty without altering money, permissions or choices")
	var earned := {"echo_spool": "recorded", "survey_slip": true}
	legacy["discoveries"] = earned
	_check(store.save_game(legacy) and store.load_game().discoveries == earned, "new discoveries survive a version-one disk roundtrip")
	_check(state.restore_snapshot(earned), "seed an earned in-memory phrase")
	var disk: Dictionary = store.load_game()
	var invalid: Array = [null, false, 1, "recorded", [], {}, {"echo_spool": "empty"}, {"survey_slip": false},
		{"echo_spool": true, "survey_slip": false}, {"echo_spool": 2, "survey_slip": false},
		{"echo_spool": "invented", "survey_slip": false}, {"echo_spool": "RECORDED", "survey_slip": false},
		{"echo_spool": "recorded", "survey_slip": 1}, {"echo_spool": "recorded", "survey_slip": "yes"},
		{"echo_spool": "recorded", "survey_slip": false, "reward": true}]
	for index in invalid.size():
		_check(not Discoveries.valid_snapshot(invalid[index]), "reject malformed discoveries %d" % index)
		_check(not state.restore_snapshot(invalid[index]) and state.snapshot() == earned,
			"invalid restore preserves the complete model %d" % index)
		var bad := legacy.duplicate(true)
		bad.discoveries = invalid[index]
		_check(not store.save_game(bad) and store.load_game() == disk, "invalid discovery save preserves checkpoint %d" % index)

func _check_locations() -> void:
	for action in LOCATIONS:
		var authored: Dictionary = LOCATIONS[action]
		_main._load_world_room(authored.room)
		await _physics(3)
		var node := _station(action)
		_check(node != null, "authored station exists: " + String(action))
		if node == null: continue
		_check(node.position == authored.position and node.discoveries == _main.discoveries,
			"station uses its fixed origin and Main's injected model: " + String(action))
		_check(not node is CollisionObject2D and not node.has_meta("chapter_state_id") and not node.is_in_group("strikable"),
			"discovery adds no combat, collision or encounter reward: " + String(action))
		_check(node.position.distance_to(_main.room.spawn_pos) > Station.INTERACT_RADIUS, "default spawn is outside discovery reach")
		for entry in _main.room.entry_points.values():
			_check(node.position.distance_to(entry) > Station.INTERACT_RADIUS, "named arrival cannot collect " + String(action))
		await _stand(node.position)
		await _physics(5)
		_check(_main.discoveries.snapshot() == EMPTY, "standing at a discovery never auto-collects it")
		_main.room.apply_side(1)
		_check(node.ink == _main.room.bg_color and node.stock == _main.room.ink, "discovery reinks on the opposite face")
		_main.room.apply_side(0)
		_check(node.ink == _main.room.ink and node.stock == _main.room.bg_color, "returning restores authored discovery colours")

func _check_order_and_context() -> void:
	await _prepare(&"record_phrase")
	var recorder := _station(&"record_phrase")
	if recorder != null:
		await _tap(KEY_E)
		_check(_main.discoveries.snapshot() == EMPTY, "a phrase cannot be recorded before finding the spool")
	await _prepare(&"restore_warren")
	await _tap(KEY_E)
	_check(_main.discoveries.snapshot() == EMPTY, "an empty receiver cannot grant the Warren conclusion")
	await _prepare(&"collect_spool")
	var pickup := _station(&"collect_spool")
	if pickup == null: return
	var checkpoint: Dictionary = _main.save_store.load_game()
	_main.player.position = pickup.position + Vector2(-Station.INTERACT_RADIUS - 10, 0)
	await _physics(3)
	_main._on_discovery_requested(&"collect_spool", pickup)
	_check(_main.discoveries.snapshot() == EMPTY, "Main refuses a discovery beyond the fixed interaction radius")
	await _stand(pickup.position + Vector2(0, -100))
	_check(not _main.player.is_on_floor(), "airborne validation fixture is above the platform")
	_main._on_discovery_requested(&"collect_spool", pickup)
	_check(_main.discoveries.snapshot() == EMPTY, "Main refuses an airborne discovery request")
	await _stand(pickup.position)
	_main._pause_game()
	_main._on_discovery_requested(&"collect_spool", pickup)
	_check(_main.discoveries.snapshot() == EMPTY, "paused play cannot accept a delayed discovery request")
	_main._resume_game()
	await _physics(3)
	_main.inventory.open_inventory()
	_main._on_discovery_requested(&"collect_spool", pickup)
	_check(_main.discoveries.snapshot() == EMPTY, "Book cannot leak an interaction into the world")
	_main.inventory.close_inventory()
	await _physics(3)
	_main._transition_pending = true
	_main._on_discovery_requested(&"collect_spool", pickup)
	_main._transition_pending = false
	_check(_main.discoveries.snapshot() == EMPTY, "pending passage transition refuses discovery callbacks")
	var foreign := Station.new()
	foreign.action = &"collect_spool"
	foreign.discoveries = _main.discoveries
	foreign.position = pickup.global_position
	root.add_child(foreign)
	_main._on_discovery_requested(&"collect_spool", foreign)
	_check(_main.discoveries.snapshot() == EMPTY, "a station outside the current room cannot grant a discovery")
	foreign.queue_free()
	await _frames(2)
	_main._on_discovery_requested(&"record_phrase", pickup)
	_check(_main.discoveries.snapshot() == EMPTY, "a source cannot submit a different station's action")
	_check(_main._persist_session(), "stage the current discovery location before failure test")
	checkpoint = _main.save_store.load_game()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block only this fixture's staged checkpoint")
	await _tap(KEY_E)
	_check(_main.discoveries.snapshot() == EMPTY and _main.save_store.load_game() == checkpoint,
		"failed synchronous save rolls back ownership and preserves the prior checkpoint")
	_check(_station(&"collect_spool") != null, "failed collection leaves the spool available to retry")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock isolated checkpoint")

func _check_phrase_loop() -> void:
	await _prepare(&"collect_spool")
	var before := _gameplay_snapshot()
	await _tap(KEY_E)
	_check(_main.discoveries.snapshot() == {"echo_spool": "empty", "survey_slip": false}, "fresh grounded E collects the physical spool")
	_check(_main.save_store.load_game().discoveries.echo_spool == "empty", "spool collection checkpoints immediately")
	await _tap(KEY_E)
	_check(_gameplay_snapshot() == before and _main.discoveries.snapshot().echo_spool == "empty", "repeated pickup input grants no income, permissions or encounter result")
	await _prepare(&"restore_warren")
	await _tap(KEY_E)
	_check(_main.discoveries.snapshot().echo_spool == "empty", "owning the empty spool is insufficient to wake the receiver")
	await _prepare(&"record_phrase")
	var recorder := _station(&"record_phrase")
	if recorder == null: return
	await _tap(KEY_E)
	recorder.advance_sequence(Station.NOTE_TIME * 0.5, true)
	_check(_main.discoveries.snapshot().echo_spool == "empty", "partial listening does not bank the phrase")
	recorder.advance_sequence(0.1, false)
	recorder.advance_sequence(Station.SEQUENCE_TIME + 1, true)
	_check(_main.discoveries.snapshot().echo_spool == "empty", "leaving range cancels the incomplete phrase")
	_check(recorder.try_interact(), "a fresh grounded interaction can restart the phrase")
	_main._pause_game()
	_main._resume_game()
	await _physics(3)
	recorder.advance_sequence(Station.SEQUENCE_TIME + 1, true)
	_check(_main.discoveries.snapshot().echo_spool == "empty", "opening a menu cancels the in-flight recording")
	_check(recorder.try_interact(), "recording restarts after the menu closes")
	paused = true
	var paused_pose: Dictionary = recorder.snapshot()
	await _frames(5)
	_check(recorder.snapshot() == paused_pose, "tree pause freezes presentation and recording time")
	paused = false
	recorder.reset_attempt()
	_check(recorder.try_interact(), "window-close failure fixture starts a recording")
	var blocked_save: String = _main.save_path + ".tmp"
	_check(DirAccess.make_dir_absolute(blocked_save) == OK, "block the isolated window-close save")
	if DirAccess.dir_exists_absolute(blocked_save):
		_main._quit_game()
		_check(paused and recorder.snapshot().stage == &"idle", "a failed window-close save opens pause with no unfinished recording")
		_check(DirAccess.remove_absolute(blocked_save) == OK, "unblock the window-close fixture")
		_main._resume_game()
		await _physics(3)
		recorder.advance_sequence(Station.SEQUENCE_TIME + 1, true)
		_check(_main.discoveries.snapshot().echo_spool == "empty", "resume after failed quit never completes the cancelled phrase")
	_main.room.set_scenery_motion(true)
	_check(recorder.try_interact(), "reduced motion still permits starting a recording")
	recorder.advance_sequence(Station.SEQUENCE_TIME + 0.05, true)
	_check(_main.discoveries.snapshot().echo_spool == "recorded", "the complete phrase records with reduced motion enabled")
	_check(_main.save_store.load_game().discoveries.echo_spool == "recorded", "recording and its saved state agree")
	_main.room.set_scenery_motion(false)
	await _prepare(&"restore_warren")
	var receiver := _station(&"restore_warren")
	if receiver == null: return
	var surfaces: Array = _main.room.atmosphere.surfaces.duplicate(true)
	var atmosphere: Node2D = _main.room.atmosphere
	var lighting: Node2D = _main.room.lighting
	receiver.requested.connect(func(action: StringName, _source: Node2D) -> void: _requests.append(action))
	await _tap_pad(JOY_BUTTON_Y)
	_check(_main.discoveries.snapshot().echo_spool == "recorded", "Y begins playback without resolving before its final note")
	receiver.advance_sequence(Station.SEQUENCE_TIME + 0.05, true)
	_check(_main.discoveries.snapshot() == {"echo_spool": "restored", "survey_slip": false}, "complete playback wakes the Warren once")
	_check(_main.save_store.load_game().discoveries.echo_spool == "restored", "the district conclusion is checkpointed")
	_check(_main.room.atmosphere == atmosphere and _main.room.lighting == lighting
		and _main.room.atmosphere.surfaces == surfaces and _main.room.lighting.surfaces == surfaces,
		"opening the audience shutters preserves platforms, routes and existing scenery layers")
	var completed: Dictionary = _main.discoveries.snapshot()
	_main._on_discovery_requested(&"restore_warren", receiver)
	_main.room.refresh_discoveries()
	_check(_main.discoveries.snapshot() == completed and _gameplay_snapshot() == before,
		"repeated resolution and refresh never award money, combat outcomes or progression")
	var request_count := _requests.size()
	_check(receiver.try_interact(), "the restored receiver offers a deliberate phrase replay")
	receiver.advance_sequence(Station.SEQUENCE_TIME + 0.05, true)
	_check(_requests.size() == request_count and _main.discoveries.snapshot() == completed,
		"a finite replay never emits another saved discovery request")
	for outcome in ["freed", "shattered"]:
		_main.encounters["verse_warren_n/north_voice"] = outcome
		_main.encounters["verse_warren_s/warren_pressing"] = outcome
		_main._load_world_room(&"verse_warren_n")
		await _physics(3)
		_check(_station(&"restore_warren") != null and _main.discoveries.snapshot() == completed,
			"either combat choice retains the discovered district: " + outcome)

func _check_survey() -> void:
	await _prepare(&"collect_survey")
	var survey := _station(&"collect_survey")
	if survey == null: return
	var before := _gameplay_snapshot()
	_check(_main.player.is_on_floor() and not _main.discoveries.snapshot().survey_slip, "survey requires a deliberate interaction on its ledge")
	await _tap(KEY_E)
	_check(_main.discoveries.snapshot() == {"echo_spool": "restored", "survey_slip": true}, "the return overlook holds an independent keepsake")
	_check(_main.save_store.load_game().discoveries.survey_slip and _gameplay_snapshot() == before,
		"the survey saves without granting a Refrain, technique or Shine")
	await _tap(KEY_E)
	_check(_gameplay_snapshot() == before, "survey cannot be farmed through repeated interaction")

func _check_persistence_and_practice() -> void:
	var earned: Dictionary = _main.discoveries.snapshot()
	var gameplay := _gameplay_snapshot()
	var model: RefCounted = _main.discoveries
	_check(_main.inventory.discoveries == model and _main.room.discoveries == model, "Book and room share Main's discovery model")
	_check(_main._persist_session(), "save the complete local discovery journey")
	_main._respawn()
	await _physics(3)
	_check(_main.discoveries.snapshot() == earned, "recovery preserves collected discoveries")
	_main._return_to_title()
	await _frames(3)
	var disk := FileAccess.get_file_as_bytes(_main.save_path)
	_main._start_practice()
	await _physics(4)
	_check(_main.practice_mode and _main.discoveries != model and _main.discoveries.snapshot() == EMPTY,
		"Move practice owns a separate empty discovery model")
	_check(_main.inventory.discoveries == _main.discoveries, "practice Book observes only practice discoveries")
	_main.discoveries.apply(&"collect_spool")
	_main.discoveries.apply(&"collect_survey")
	_main._queue_save()
	await _frames(3)
	_check(model.snapshot() == earned and FileAccess.get_file_as_bytes(_main.save_path) == disk,
		"practice mutation and save requests leave campaign discoveries and disk bytes untouched")
	_main._return_to_title()
	await _frames(3)
	_check(_main.discoveries == model and model.snapshot() == earned, "practice return restores the exact campaign discovery model")
	await _close()
	await _boot()
	_main._continue_game()
	await _physics(4)
	_check(_main.world_room_id == &"the_landing" and _main.discoveries.snapshot() == earned,
		"fresh Main Continue restores both discoveries before room construction")
	_check(_gameplay_snapshot() == gameplay and _main.inventory.discoveries == _main.discoveries,
		"Continue silently preserves the wallet, permissions, choices and Book binding")
	await _check_book(true)
	_main._new_game(false)
	await _physics(4)
	_check(_main.discoveries.snapshot() == EMPTY and _main.save_store.load_game().discoveries == EMPTY,
		"New Game clears both old discoveries in memory and on disk")

func _check_old_continue() -> void:
	var old := _legacy_save()
	_check(_main.save_store.save_game(old), "stage a pre-discovery checkpoint")
	_main._continue_game()
	await _physics(4)
	_check(_main.world_room_id == &"verse_warren_s" and _main.discoveries.snapshot() == EMPTY,
		"old Continue retains its actual arrival without inventing a carried item")
	_check(_main.player.shine == 7 and _main.progression.snapshot() == old.progression and _main.encounters == old.encounters,
		"adding discoveries never rewrites an old player's balance, permissions or choices")

func _check_book(owned: bool) -> void:
	var discoveries_before: Dictionary = _main.discoveries.snapshot()
	var gameplay_before := _gameplay_snapshot()
	_main.inventory.open_inventory()
	await _frames(3)
	_check(_main.inventory.slot_count() == 8, "carried items do not inflate the Book's core, technique or Refrain count")
	for slot in [&"echo_spool", &"survey_slip"]:
		var button: Button = _main.inventory._discovery_buttons[slot]
		_check(button.visible == owned, "Book only names an actually owned discovery: " + String(slot))
		if owned:
			button.pressed.emit()
			_check(_main.inventory._detail_title.text == _main.inventory._slot_name(slot)
				and not _main.inventory._detail_description.text.is_empty(), "owned discovery opens its readable journal entry")
	if owned:
		_main.inventory._discovery_buttons[&"echo_spool"].pressed.emit()
		_check(_main.inventory._detail_state.text.contains("RESTORED"), "fresh Continue's Book describes the restored phrase truthfully")
	_main.inventory.close_inventory()
	await _physics(3)
	_check(_main.discoveries.snapshot() == discoveries_before and _gameplay_snapshot() == gameplay_before,
		"reading discovery entries changes no carried state, income or permissions")

func _legacy_save() -> Dictionary:
	return {"version": 1, "room_id": "verse_warren_s", "entry_id": "from_deep_gallery", "shine": 7,
		"progression": {"version": 1, "refrains": [], "techniques": ["count-in"]},
		"encounters": {"the_arm/tonearm": "shattered", "groove_yard/yard_first_voice": "freed"}}

func _gameplay_snapshot() -> Dictionary:
	return {"economy": _main.economy.snapshot(), "progression": _main.progression.snapshot(),
		"encounters": _main.encounters.duplicate(true)}

func _station(action: StringName) -> Node2D:
	for node in _main.room.get_children():
		if node.is_in_group("echo_discovery") and node.action == action: return node
	return null

func _prepare(action: StringName) -> void:
	_main._load_world_room(LOCATIONS[action].room)
	await _physics(3)
	await _stand(LOCATIONS[action].position)

func _stand(at: Vector2) -> void:
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)

func _close() -> void:
	for code in [KEY_E, KEY_SPACE, KEY_ESCAPE, KEY_I, KEY_J, KEY_K, KEY_L]: _key(code, false)
	_joy(JOY_BUTTON_Y, false)
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(2)
	_key(code, false)
	await _physics(2)

func _tap_pad(button: JoyButton) -> void:
	_joy(button, true)
	await _physics(2)
	_joy(button, false)
	await _physics(2)

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

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
