extends SceneTree
## Main-owned exploration claims, exercised through private checkpoints and
## actual keyboard/controller input. The player's save is never opened.

const MainScene := preload("res://scenes/main.tscn")
const Catalog := preload("res://scripts/lost_pressings_catalog.gd")
const Fixture := preload("res://scripts/lost_pressing.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Save := preload("res://scripts/save_store.gd")
var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-lost-pressings-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "private checkpoint directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _physics(3)
	_main._new_game(false)
	await _physics(4)
	_seed()
	for definition in Catalog.entries():
		await _claim(definition)
	await _equipment_and_restore()
	await _practice()
	_main._new_game(false)
	await _physics(4)
	_check(_main.collection.snapshot().owned.is_empty(), "New Game clears every found pressing")
	_release()
	_main.queue_free()
	await _physics(3)
	paused = false
	await _development()
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "delete private save and backup")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private directory")
	if _failures.is_empty():
		print("DEAD WAX LOST PRESSINGS PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("LOST PRESSINGS FAIL: " + failure)
	quit(1)

func _seed() -> void:
	_main.abilities.restore_snapshot(Abilities.legacy_snapshot())
	_main.economy.restore(7, [])
	_main.encounters = {"the_arm/tonearm": "freed", "addie/addie": "freed"}
	var state: Dictionary = _main.collection.snapshot()
	for record in state.bestiary.values(): record.seen = true
	for record in state.hunts.values(): record.discovered = true
	_main.collection.restore_snapshot(state)
	_main.collection.backfill(_main.encounters)

func _claim(definition: Dictionary) -> void:
	var id := String(definition.id)
	_main._load_world_room(definition.room_id)
	await _physics(5)
	var source := _main.room.get_node_or_null("LostPressing_" + id) as Node2D
	_check(source != null, id + " installed at the authored room")
	if source == null: return
	_check(source.position == definition.position and source.definition == definition, id + " has fixed catalog identity")
	_check(source.collection == _main.collection and source.progression == _main.progression and source.abilities == _main.abilities and source.pressing == _main.pressing, "fixture reads Main's exact models")
	_check(not source is CollisionObject2D and not source.has_meta("chapter_state_id"), "sleeve adds no physics or story outcome")
	await _place(source.position)
	_check(_main.player.is_on_floor(), id + " origin has real support")
	var earned_abilities: Dictionary = _main.abilities.snapshot()
	if definition.requirement == "groove":
		var locked := earned_abilities.duplicate(true)
		locked.unlocked.erase("groove")
		_main.abilities.restore_snapshot(locked)
	else:
		_main.progression.reset()
	var before: Dictionary = _main.collection.snapshot()
	await _tap(KEY_E)
	_main._on_lost_pressing_requested(source)
	_check(not source.is_available() and _main.collection.snapshot() == before, "missing " + String(definition.requirement) + " blocks the claim")
	# E carried across a permission change cannot become a fresh claim.
	_key(KEY_E, true)
	await _physics(2)
	_main.abilities.restore_snapshot(earned_abilities)
	if definition.requirement == "gather": _main.progression.unlock_refrain(Progression.Refrain.GATHER)
	if definition.requirement == "jump_cut":
		_main.progression.unlock_refrain(Progression.Refrain.JUMP_CUT)
		_main._on_lost_pressing_requested(source)
		_check(not _main.collection.has_item(id), "Jump-Cut alone cannot claim the reverse-side sleeve on A")
		await _tap(KEY_F)
	await _physics(4)
	_check(source.is_available() and not _main.collection.has_item(id), "held E cannot collect a newly available sleeve")
	_key(KEY_E, false)
	await _physics(2)
	await _invalid_context(source)
	_check(_main.collection.snapshot() == before, "all rejected source and player contexts preserve collection")
	await _place(source.position)
	_check(_main._persist_session(), "save approach before deliberate failure")
	var saved: Dictionary = _main.save_store.load_game()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block staging write")
	await _tap(KEY_E)
	_check(_main.collection.snapshot() == before and _main.save_store.load_game() == saved, "failed write restores entire collection and old checkpoint")
	_check(source.is_available() and not _main._collection_busy, "failed pickup stays retryable")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock staging write")
	var preserved := _preserved()
	_joy(true)
	await _physics(4)
	_joy(false)
	await _physics(3)
	var expected := before.duplicate(true)
	expected.owned.append(id)
	_check(_main.collection.snapshot() == expected, "fresh controller Y changes only owned gear")
	_check(_main.save_store.load_game().collection == expected, "claimed gear is fully checkpointed")
	_check(not source.is_available() and source.visible, "collected sleeve stays settled without another reward")
	_check(_preserved() == preserved, "claim preserves health, Shine, progression, discoveries and story choices")
	await _tap(KEY_E)
	_main._on_lost_pressing_requested(source)
	_check(_main.collection.snapshot() == expected, "duplicate callbacks cannot mint gear or salvage")
	_main._respawn()
	await _physics(4)
	_check(_main.collection.snapshot() == expected and not source.is_available(), "recovery does not refill a sleeve")
	if _main.pressing.on_b_side(): await _tap(KEY_F)

func _invalid_context(source: Node2D) -> void:
	await _place(source.position + Vector2(77, 0))
	_main._on_lost_pressing_requested(source)
	await _place(source.position)
	_key(KEY_SPACE, true)
	await _physics(1)
	_key(KEY_SPACE, false)
	_check(not _main.player.is_on_floor(), "actual jump leaves the interaction floor")
	_main._on_lost_pressing_requested(source)
	await _place(source.position)
	var original: Dictionary = source.definition.duplicate(true)
	source.position.x += 1
	_main._on_lost_pressing_requested(source)
	source.position.x -= 1
	source.definition = original.duplicate(true)
	source.definition.requirement = "invented"
	_main._on_lost_pressing_requested(source)
	source.definition = original
	var foreign := Fixture.new()
	foreign.definition = original.duplicate(true)
	foreign.position = source.position
	foreign.collection = _main.collection
	foreign.abilities = _main.abilities
	foreign.progression = _main.progression
	foreign.pressing = _main.pressing
	_main.room.add_child(foreign)
	_main._on_lost_pressing_requested(foreign)
	_main.room.remove_child(foreign)
	foreign.free()
	_main._pause_game()
	_main._on_lost_pressing_requested(source)
	_main._resume_game()
	await _physics(3)
	_main.inventory.open_inventory()
	_main._on_lost_pressing_requested(source)
	_main.inventory.close_inventory()
	await _physics(3)
	_main._transition_pending = true
	_main._on_lost_pressing_requested(source)
	_main._transition_pending = false
	_main._respawn_pending = true
	_main._on_lost_pressing_requested(source)
	_main._respawn_pending = false
	_main._collection_busy = true
	_main._on_lost_pressing_requested(source)
	_main._collection_busy = false

func _equipment_and_restore() -> void:
	_main.inventory.open_inventory()
	await _physics(3)
	_main._health = 2
	var before: Dictionary = _main.collection.snapshot()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block equipment write")
	_main._equip_collection_item("dusk_seal")
	_check(_main.collection.snapshot() == before and _main._max_health() == 3 and _main._health == 2, "failed fitting changes neither health nor handling")
	DirAccess.remove_absolute(_main.save_path + ".tmp")
	_main._equip_collection_item("dusk_seal")
	_check(_main._max_health() == 4 and _main._health == 2, "fitting extra capacity never heals")
	_check(is_equal_approx(_main.collection.modifiers().speed, 0.9), "Dusk Seal applies its running cost")
	_main.inventory.close_inventory()
	await _physics(3)
	_main._persist_session()
	var saved: Dictionary = _main.collection.snapshot()
	_main._continue_game()
	await _physics(5)
	_check(_main.collection.snapshot() == saved and _main._health == 4, "Continue restores fitted gear and fills derived health")
	_check(not _main.room.get_node("LostPressing_dusk_seal").is_available(), "Continue silently restores an empty sleeve")
	_check(_main.map_menu.collection == _main.collection and _main.inventory.collection == _main.collection, "map and Book share the restored collection")

func _practice() -> void:
	var collection: RefCounted = _main.collection
	_main._return_to_title()
	await _physics(3)
	var before: Dictionary = _main.save_store.load_game()
	_main._start_practice()
	await _physics(4)
	_check(get_nodes_in_group("lost_pressing").is_empty(), "practice installs no campaign sleeves")
	_check(_main.collection != collection and _main.collection.snapshot().owned.is_empty(), "practice uses an empty disposable collection")
	_main.collection.claim_exploration_item("copper_stylus")
	_main._persist_session()
	_check(_main.save_store.load_game() == before, "practice cannot save a pressing into campaign")
	_main._leave_practice()
	await _physics(4)
	_check(_main.collection == collection and _main.inventory.collection == collection and _main.map_menu.collection == collection, "practice restores original model identity to all views")

func _development() -> void:
	var development: Node2D = MainScene.instantiate()
	development.development_mode = true
	development.save_path = _directory + "/checkpoint.json"
	development.settings_path = _directory + "/settings.cfg"
	root.add_child(development)
	await _physics(4)
	development._load_world_room(&"horn_plaza")
	await _physics(4)
	_check(get_nodes_in_group("lost_pressing").is_empty(), "development graybox never installs campaign rewards")
	development.queue_free()
	await _physics(3)
	paused = false

func _preserved() -> Dictionary:
	return {"health": _main._health, "max_health": _main._max_health(), "abilities": _main.abilities.snapshot(),
		"economy": _main.economy.snapshot(), "progression": _main.progression.snapshot(),
		"discoveries": _main.discoveries.snapshot(), "exploration": _main.exploration.snapshot(),
		"encounters": _main.encounters.duplicate(true), "completed": _main.chapter_complete}

func _place(position: Vector2) -> void:
	_release()
	_main.player.position = position
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

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

func _joy(pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_Y
	event.pressed = pressed
	Input.parse_input_event(event)

func _release() -> void:
	for code in [KEY_E, KEY_F, KEY_R, KEY_SPACE, KEY_J, KEY_D, KEY_A]: _key(code, false)
	_joy(false)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
