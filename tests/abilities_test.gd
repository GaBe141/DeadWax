extends SceneTree
## Real campaign input, failure-safe acquisition, migration and isolated practice.
## Deliberate room positioning keeps the persistence cases separate from the
## physical route checks in ability_world_test; all saves are private fixtures.
const MainScene := preload("res://scenes/main.tscn")
const Abilities := preload("res://scripts/abilities_state.gd")
const Pickup := preload("res://scripts/ability_pickup.gd")
const Save := preload("res://scripts/save_store.gd")
const Dummy := preload("res://scripts/test_pressing.gd")
const Progression := preload("res://scripts/progression_state.gd")
var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _strikes: Array[Dictionary] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-abilities-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private ability checkpoint directory")
	await _boot()
	_main._new_game(false)
	await _physics(4)
	await _opening()
	await _acquisition_context()
	await _remaining_moves()
	await _permissions()
	await _persistence()
	await _migration()
	await _close()
	await _development()
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated ability directory")
	if _failures.is_empty():
		print("DEAD WAX ABILITIES PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("ABILITIES FAIL: " + failure)
	quit(1)

func _opening() -> void:
	_check(_main.abilities.snapshot() == Abilities.default_snapshot(), "New Game owns no discoverable move")
	_check(_main.player.abilities == _main.abilities and _main.room.abilities == _main.abilities
		and _main.inventory.abilities == _main.abilities, "Main injects the same ability model before gameplay")
	_check(_main.save_store.load_game().abilities == Abilities.default_snapshot(), "first checkpoint explicitly saves an empty moveset")
	var origin: Vector2 = _main.player.position
	_key(KEY_D, true)
	await _physics(10)
	_key(KEY_D, false)
	_check(absf(_main.player.position.x - origin.x - _main.player.SHUFFLE_STEP) < 0.001, "before Walk, holding a direction gives only one tiny step")
	await _stand(Vector2(260, 554))
	await _tap(KEY_SPACE)
	_check(_main.player.position.y < 545 and not _main.player.is_on_floor(), "ordinary jump works before any pickup")
	await _stand(Vector2(260, 554))
	var clock_before: int = _main.player.last_strike_ms
	for code in [KEY_J, KEY_X, KEY_K, KEY_C, KEY_L]: await _tap(code)
	_joy(JOY_BUTTON_X, true)
	_joy(JOY_BUTTON_B, true)
	_joy(JOY_BUTTON_LEFT_SHOULDER, true)
	await _physics(3)
	_check(not _main.player.hooded and not _main.player.setting, "locked Hood and Set ignore keyboard and controller")
	_release()
	_main.player._strike()
	_check(_strikes.is_empty() and _main.player.last_strike_ms == clock_before and _main.player.noise == 0.0,
		"locked Strike emits no hit, parry clock, or noise even through its execution entry")
	_check(_main.player._strike_buffer == 0.0 and _main.player.combo_snapshot().input_state == "locked",
		"locked input cannot queue an invisible strike")
	_main._load_world_room(&"practice_room")
	await _physics(4)
	var trial: Node2D = _main.room.get_node("EchoTrial")
	await _stand(trial.position)
	_check(not trial.can_start(), "a powerless player cannot start a combat recording with no answer")
	_main._load_world_room(&"headshell")
	await _physics(3)

func _acquisition_context() -> void:
	var source := _pickup(&"strike")
	_check(source != null, "the missing needle exists in the opening")
	if source == null: return
	await _stand(Vector2(260, 554))
	_main._on_ability_requested(&"strike", source)
	await _stand(Vector2(365, 454))
	_check(not _main.player.is_on_floor(), "airborne pickup fixture is off the floor")
	_main._on_ability_requested(&"strike", source)
	await _stand(source.position)
	var foreign := Pickup.new()
	foreign.ability = &"strike"
	foreign.abilities = _main.abilities
	foreign.position = source.position
	root.add_child(foreign)
	_main._on_ability_requested(&"strike", foreign)
	foreign.queue_free()
	_main._on_ability_requested(&"set", source)
	source.position.x += 1
	_main._on_ability_requested(&"strike", source)
	source.position.x -= 1
	_check(_main.abilities.snapshot() == Abilities.default_snapshot(), "far, airborne, foreign, mismatched and moved sources cannot grant abilities")
	_main._pause_game()
	_main._on_ability_requested(&"strike", source)
	_main._resume_game()
	await _physics(3)
	_main.inventory.open_inventory()
	_main._on_ability_requested(&"strike", source)
	_main.inventory.close_inventory()
	await _physics(3)
	_main._transition_pending = true
	_main._on_ability_requested(&"strike", source)
	_main._transition_pending = false
	_main._respawn_pending = true
	_main._on_ability_requested(&"strike", source)
	_main._respawn_pending = false
	_check(not _main.abilities.has_ability(&"strike"), "menus and pending transitions or recovery reject stale requests")
	_check(_main._persist_session(), "stage empty ability checkpoint")
	var before: Dictionary = _main.save_store.load_game()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block private checkpoint staging")
	await _tap(KEY_E)
	_check(not _main.abilities.has_ability(&"strike") and _main.save_store.load_game() == before,
		"failed pickup write rolls back the permission and preserves disk")
	_check(_pickup(&"strike") == source and source.visible and source.can_request(), "failed pickup stays available to retry")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock private checkpoint")
	await _tap(KEY_E)
	_check(_main.abilities.has_ability(&"strike") and _main.save_store.load_game().abilities.unlocked == ["strike"],
		"fresh grounded E saves Strike before confirming acquisition")
	_check(_pickup(&"strike") == null and _main.player._strike_buffer == 0, "confirmed pickup retires and clears latent combat input")
	await _tap(KEY_E)
	_check(_main.abilities.snapshot().unlocked == ["strike"] and _main.player.shine == 0, "repeating interact grants neither another move nor Shine")
	_strikes.clear()
	for hit in 3:
		await _tap(KEY_J)
		await _physics(14)
	_check(_strikes.size() == 3, "basic Strike executes once per fresh press")
	for hit in _strikes:
		_check(hit.step == 1 and not hit.big, "Strike alone stays Tap without an unearned Accent")
	_check(_main.player.STRIKE_COOLDOWN == 0.2 and Dummy.PARRY_WINDOW_MS == 100, "earning moves preserves cooldown and parry constants")
	await _tap(KEY_K)
	await _tap(KEY_L)
	_check(not _main.player.hooded and not _main.player.setting and _main.abilities.snapshot().unlocked == ["strike"],
		"finding Strike grants neither Hood nor Set")

func _remaining_moves() -> void:
	await _collect(&"walk")
	await _collect(&"set", true)
	_key(KEY_L, true)
	await _physics(2)
	_check(_main.player.setting, "recovered Set kneels through actual input")
	_release()
	await _physics(2)
	await _collect(&"hood")
	_key(KEY_K, true)
	await _physics(2)
	_check(_main.player.hooded, "recovered Hood raises through actual input")
	_release()
	_main._load_world_room(&"practice_room", &"from_horn_plaza")
	await _physics(3)
	await _stand(Vector2(1320, 574))
	await _tap(KEY_E)
	_check(not _main.abilities.has_ability(&"groove"), "rear entrance cannot claim Groove through the closed Count-In sleeve")
	var door: Node = null
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == &"practice_count_in": door = child
	_check(door != null, "Count-In uses its existing stable encounter")
	if door != null:
		for beat in 4:
			await _tap(KEY_J)
			await create_timer(0.30).timeout
		_check(door.is_open and _main.encounters.get("practice_room/practice_count_in") == "opened",
			"four real basic strikes open and persist the Count-In from the far side")
		_check(not _main.abilities.has_ability(&"groove"), "opening a door does not auto-grant Groove")
	await _collect(&"groove")
	await _collect(&"combo")
	await _collect(&"pogo")
	_check(_main.abilities.snapshot() == Abilities.legacy_snapshot(), "seven distinct grounded discoveries complete the ordinary moveset")
	_check(_main.progression.snapshot().refrains.is_empty() and _main.player.shine == 0, "move pickups grant no Refrains or money")

func _collect(id: StringName, controller: bool = false) -> void:
	var record := Abilities.ability(id)
	_main._load_world_room(record.room_id)
	await _physics(3)
	_quiet_actors()
	await _stand(record.position)
	_check(_main.player.is_on_floor(), "%s collection starts grounded" % id)
	if controller:
		_joy(JOY_BUTTON_Y, true)
		await _physics(2)
		_joy(JOY_BUTTON_Y, false)
		await _physics(2)
	else:
		await _tap(KEY_E)
	_check(_main.abilities.has_ability(id) and String(id) in _main.save_store.load_game().abilities.unlocked,
		"%s is independently owned and checkpointed through interaction" % id)
	_check(_pickup(id) == null, "%s retires only after the save" % id)

func _permissions() -> void:
	# These fixtures deliberately select earned subsets to isolate physics.
	# End-to-end pickup and migration checks above/below retain real acquisitions.
	var owned: Dictionary = _main.abilities.snapshot()
	_main._load_world_room(&"headshell")
	await _physics(3)
	_main.abilities.restore_snapshot({"version": 2, "unlocked": ["walk", "strike"]})
	await _stand(Vector2(300, 554))
	var foe := Dummy.new()
	foe.position = Vector2(390, 554)
	_main.room.add_child(foe)
	foe.set_process(false)
	_main.player.air_density = 1.0
	_main.player.air_strikes_max = 2
	_main.player.refill_air_strikes()
	_check(_main.player.air_strike_capacity() == 0 and not _main.player.can_air_strike(), "unearned Groove disables environmental breaths")
	_main.abilities.unlock_ability(&"groove")
	_main.player.refill_air_strikes()
	var hp: float = foe.hp
	_main.player._strike_cd = 0
	await _tap(KEY_J)
	_check(foe.hp == hp - 1 and not _strikes.back().launched and _main.player.is_on_floor()
		and _main.player.air_strikes_left == 2, "grounded hits without Pogo still preserve footing and breaths in thick air: hp %s/%s, launch %s, floor %s, breaths %s" % [foe.hp, hp, _strikes.back().launched, _main.player.is_on_floor(), _main.player.air_strikes_left])
	await _stand(Vector2(300, 350))
	foe.position = _main.player.position + Vector2(90, 0)
	_main.player._strike_cd = 0
	_main.player.velocity = Vector2.ZERO
	_main.player.air_density = 0.0
	hp = foe.hp
	await _tap(KEY_J)
	_check(foe.hp == hp - 1 and not _strikes.back().launched, "airborne Strike damages without an unearned Pogo rebound")
	await _stand(Vector2(300, 350))
	foe.position = _main.player.position + Vector2(90, 0)
	_main.player._strike_cd = 0
	_main.player.velocity = Vector2.ZERO
	_main.player.air_density = 1.0
	_main.player.refill_air_strikes()
	await _tap(KEY_J)
	_check(_strikes.back().launched and _main.player.air_strikes_left == 1,
		"earned thick-air jet can accompany an airborne hit but spends a breath without Pogo")
	await _stand(Vector2(300, 350))
	foe.position = _main.player.position + Vector2(90, 0)
	_main.player._strike_cd = 0
	_main.player.velocity = Vector2.ZERO
	_main.player.air_density = 0.0
	_main.abilities.unlock_ability(&"pogo")
	_main.player.air_strikes_left = 0
	await _tap(KEY_J)
	_check(_strikes.back().launched and _strikes.back().velocity.y < -500 and _main.player.air_strikes_left == 2,
		"earned Pogo rebounds from a confirmed hit and refills earned breaths")
	foe.queue_free()
	await _physics(2)
	_main.abilities.restore_snapshot({"version": 2, "unlocked": ["walk", "strike"]})
	_main.progression.unlock_refrain(Progression.Refrain.GATHER)
	await _stand(Vector2(300, 554))
	_main.player.air_density = 1.0
	_main.player.air_strikes_max = 2
	_main.player.refill_air_strikes()
	_main.player._strike_cd = 0
	await _tap(KEY_J)
	_check(not _strikes.back().launched and _main.player.is_on_floor() and _main.player.air_strikes_left == 1,
		"Gather cannot borrow an unearned grounded thick-air jet")
	await _stand(Vector2(300, 350))
	_main.player._strike_cd = 0
	_main.player.velocity = Vector2.ZERO
	_key(KEY_D, true)
	await _tap(KEY_J)
	_release()
	_check(_strikes.back().launched and _strikes.back().velocity.y < -600 and absf(_strikes.back().velocity.x) < 100
		and _main.player.air_strikes_left == 0, "Gather without Groove keeps its single upward breath even in authored thick air")
	_main.progression.reset()
	_main.abilities.restore_snapshot(owned)
	_main._load_world_room(&"headshell")
	await _physics(3)

func _persistence() -> void:
	_main.abilities.restore_snapshot({"version": 2, "unlocked": ["walk", "strike", "set"]})
	_check(_main._persist_session(), "save a deliberately partial journey")
	var partial: Dictionary = _main.abilities.snapshot()
	_main.abilities.reset()
	_main._continue_game()
	await _physics(4)
	_check(_main.abilities.snapshot() == partial and _pickup(&"strike") == null and _pickup(&"set") == null,
		"Continue restores partial permissions before building pickups")
	_check(not _main.abilities.has_ability(&"hood") and _main.player.last_strike_ms == -100000,
		"Continue grants no missing move or replayed strike")
	_main._respawn()
	await _physics(5)
	_check(_main.abilities.snapshot() == partial, "recovery preserves the earned subset")
	_main._return_to_title()
	await _frames(3)
	var campaign_model: RefCounted = _main.abilities
	var disk: Dictionary = _main.save_store.load_game()
	_main._start_practice()
	await _physics(5)
	_check(_main.practice_mode and _main.abilities != campaign_model and _main.abilities.snapshot() == Abilities.legacy_snapshot(),
		"Move practice gets a disposable complete moveset")
	_check(_main.player.abilities == _main.abilities and _main.inventory.abilities == _main.abilities,
		"practice player and Book use the disposable permissions")
	_main.abilities.reset()
	_check(_main._persist_session() and _main.save_store.load_game() == disk, "practice cannot save its disposable moves")
	_main._return_to_title()
	await _frames(3)
	_check(_main.abilities == campaign_model and _main.abilities.snapshot() == partial,
		"leaving practice restores the original campaign object and owned moves")
	_main._continue_game()
	await _physics(4)
	_check(_main.abilities.snapshot() == partial, "Continue after practice retains partial progress")
	_main._new_game(false)
	await _physics(4)
	_check(_main.abilities.snapshot() == Abilities.default_snapshot() and _pickup(&"strike") != null and _pickup(&"set") != null,
		"New Game resets moves and recreates the two opening discoveries")

func _migration() -> void:
	var legacy := {"version": 1, "room_id": "high_street", "entry_id": "default", "shine": 3,
		"progression": {"version": 1, "refrains": [], "techniques": []}, "encounters": {"high_street/street_looper": "shattered"}}
	_check(_main.save_store.save_game(legacy), "unchanged version-one save is accepted")
	# Write a genuine old checkpoint: save_game normalizes its input and would
	# otherwise insert abilities before Continue ever exercised read migration.
	var file := FileAccess.open(_main.save_path, FileAccess.WRITE)
	_check(file != null, "open private raw legacy checkpoint")
	if file == null: return
	file.store_string(JSON.stringify(legacy))
	file.close()
	_check(not JSON.parse_string(FileAccess.get_file_as_string(_main.save_path)).has("abilities"), "legacy disk fixture really has no abilities field")
	_main._continue_game()
	await _physics(4)
	_check(_main.abilities.snapshot() == Abilities.legacy_snapshot() and _main.player.shine == 3
		and _main.encounters.get("high_street/street_looper") == "shattered", "legacy migration preserves every previously available move, money and outcome")
	_check(_pickup(&"hood") == null, "legacy owned pickup disappears without replaying acquisition")
	var before: Dictionary = _main.save_store.load_game()
	for invalid in [null, {}, {"version": 1, "unlocked": ["strike", "strike"]}, {"version": 1, "unlocked": ["flight"]},
		{"version": 1, "unlocked": [], "cheat": true}, {"version": true, "unlocked": []}]:
		var malformed := legacy.duplicate(true)
		malformed.abilities = invalid
		_check(not _main.save_store.save_game(malformed) and _main.save_store.load_game() == before,
			"malformed ability data cannot replace a validated checkpoint")

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main.player.struck.connect(func(_at: Vector2, big: bool, launched: bool) -> void:
		_strikes.append({"big": big, "launched": launched, "step": _main.player.combo_step, "velocity": _main.player.velocity}))

func _development() -> void:
	var store := Save.new(_directory + "/checkpoint.json")
	var before: Dictionary = store.load_game()
	var development: Node2D = MainScene.instantiate()
	development.development_mode = true
	development.save_path = _directory + "/checkpoint.json"
	development.settings_path = _directory + "/settings.cfg"
	root.add_child(development)
	await _physics(4)
	_check(development.abilities.snapshot() == Abilities.legacy_snapshot(), "development boots with every ordinary move")
	_check(development.player.abilities == development.abilities and development.room.abilities == development.abilities,
		"development injects its explicit complete model")
	development.abilities.reset()
	_check(development._persist_session() and store.load_game() == before, "development cannot overwrite campaign permissions")
	development.queue_free()
	await _frames(3)

func _pickup(id: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.is_in_group("ability_pickup") and child.ability == id: return child
	return null

func _quiet_actors() -> void:
	for actor in get_nodes_in_group("hears_strikes"):
		actor.set_process(false)
		actor.set_physics_process(false)

func _stand(at: Vector2) -> void:
	_release()
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _close() -> void:
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false

func _release() -> void:
	for code in [KEY_D, KEY_A, KEY_SPACE, KEY_J, KEY_X, KEY_K, KEY_C, KEY_L, KEY_E]: _key(code, false)
	for button in [JOY_BUTTON_X, JOY_BUTTON_B, JOY_BUTTON_Y, JOY_BUTTON_LEFT_SHOULDER]: _joy(button, false)

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(2)
	_key(code, false)
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
