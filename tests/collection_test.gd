extends SceneTree
## Integration: private checkpoints, real campaign posts, and saved equipment.
const MainScene := preload("res://scenes/main.tscn")
const Collection := preload("res://scripts/collection_state.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const Save := preload("res://scripts/save_store.gd")
var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-collection-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "private collection fixture")
	_check_schema()
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(4)
	_main._new_game(false)
	await _frames(5)
	await _check_posts()
	await _check_trial_transaction()
	await _check_equipment()
	await _check_bestiary_and_restore()
	await _check_isolation()
	_main.queue_free()
	await _frames(3)
	paused = false
	for name in ["checkpoint.json", "schema.json"]:
		_check(Save.new(_directory + "/" + name).delete_save(), "remove private " + name)
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove collection fixture directory")
	if _failures.is_empty():
		print("DEAD WAX COLLECTION INTEGRATION PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures: push_error("COLLECTION FAIL: " + failure)
		quit(1)

func _check_schema() -> void:
	var store := Save.new(_directory + "/schema.json")
	var legacy := {"version": 1, "room_id": "headshell", "entry_id": "default", "shine": 7,
		"progression": {"version": 1, "refrains": [], "techniques": []},
		"encounters": {"the_arm/tonearm": "freed"}}
	_check(store.save_game(legacy), "old saves remain valid")
	var loaded := store.load_game()
	_check(loaded.collection == Collection.default_snapshot() and loaded.shine == 7 and loaded.encounters == legacy.encounters,
		"legacy migration never invents loot or changes the story or Shine")
	var errors: Array = [null, {}, [], true]
	var corrupt := Collection.default_snapshot()
	corrupt.equipped.needle = "glass_needle"
	errors.append(corrupt)
	corrupt = Collection.default_snapshot()
	corrupt.rng_state = 0
	errors.append(corrupt)
	corrupt = Collection.default_snapshot()
	corrupt.hunts.label.wins = -1
	errors.append(corrupt)
	for value in errors:
		legacy.collection = value
		_check(not store.save_game(legacy) and store.load_game() == loaded, "malformed collection cannot replace a checkpoint")

func _check_posts() -> void:
	for hunt in Catalog.hunts():
		_main._load_world_room(StringName(hunt.room_id))
		await _frames(4)
		var trial: Node2D = _main.room.get_node_or_null("EchoTrial")
		_check(trial != null, "campaign installs " + String(hunt.id))
		if trial == null: continue
		_check(trial.position == hunt.position and not trial.has_meta("chapter_state_id"), "post has fixed position and no story outcome")
		_check(not trial is CollisionObject2D, "post adds no collision")
		for arrival in _main.room.entry_points.values():
			_check(trial.position.distance_to(arrival) > 76.0, "arrivals cannot start trials")
		var before: Dictionary = _main.collection.snapshot()
		_main._on_trial_claim(trial)
		_check(_main.collection.snapshot() == before, "idle post cannot grant a roll")
		_main.room.apply_side(1)
		_check(trial.ink == _main.room.bg_color and trial.stock == _main.room.ink, "post reinks on B")
		_main.room.apply_side(0)
		_check(trial.ink == _main.room.ink and trial.stock == _main.room.bg_color, "post restores A palette")
	_main._load_world_room(&"headshell")
	await _frames(3)
	_check(_main.room.get_node_or_null("EchoTrial") == null, "ordinary rooms retain their campaign layout")
	_check(get_nodes_in_group("echo_trial").is_empty(), "transition retires old trial posts")

func _check_trial_transaction() -> void:
	_main._load_world_room(&"practice_room")
	await _frames(4)
	var trial: Node2D = _main.room.get_node("EchoTrial")
	await _stand(trial.position)
	var before: Dictionary = _main.collection.snapshot()
	await _tap(KEY_E)
	_check(trial.snapshot().state == "active", "fresh E starts a nearby grounded trial")
	_main.inventory.open_inventory()
	_check(trial.snapshot().state == "idle", "Book clears an unfinished trial")
	_check(_main.collection.snapshot().rng_state == before.rng_state and _main.collection.snapshot().hunts.label.wins == 0,
		"abandoning a wave neither rolls nor awards materials")
	_main.inventory.close_inventory()
	await _frames(4)
	await _tap(KEY_E)
	# Resolve the summoned actors through their actual resolution signals. The
	# standalone trial suite covers their inherited combat and wave ownership.
	for frame in 260:
		for actor in get_nodes_in_group("echo_trial_actor"):
			if trial.is_ancestor_of(actor) and actor.has_method("_free"):
				actor.call("_free")
		await _frames(1)
		if trial.snapshot().state == "claim": break
	_check(trial.snapshot().state == "claim", "three complete waves leave a claim at the press")
	if trial.snapshot().state != "claim": return
	await _stand(trial.position)
	_main.inventory.open_inventory()
	_main.inventory.close_inventory()
	await _frames(4)
	_check(trial.snapshot().state == "claim", "reading the Book preserves a completed claim")
	var real_store: RefCounted = _main.save_store
	_main.save_store = Save.new(_directory + "/missing/checkpoint.json")
	before = _main.collection.snapshot()
	await _tap(KEY_E)
	_check(_main.collection.snapshot() == before and trial.snapshot().state == "claim",
		"failed reward write restores roll, owned gear, offcuts and pity; claim remains")
	_main.save_store = real_store
	var predicted := Collection.new()
	predicted.restore_snapshot(before)
	var receipt := predicted.finish_hunt("label")
	_check(not receipt.is_empty(), "retry has a deterministic expected reward")
	await _tap(KEY_E)
	_check(_main.collection.snapshot() == predicted.snapshot(), "successful retry commits exactly the same roll once")
	_check(real_store.load_game().collection == predicted.snapshot(), "gear and roll commit together on disk")
	before = _main.collection.snapshot()
	_main._on_trial_claim(trial)
	_check(_main.collection.snapshot() == before, "duplicate completion callback cannot mint another reward")
	_check(_main.player.shine == 0, "trial rewards do not mint Shine")
	_check(not _main.encounters.has("practice_room/echo_trial"), "trial copies do not become story encounters")

func _check_equipment() -> void:
	var seed := Collection.default_snapshot()
	seed.hunts.label = {"discovered": true, "wins": 1, "dry": 1}
	seed.hunts.overture = {"discovered": true, "wins": 1, "dry": 1}
	seed.owned = ["quicksilver_tip", "padded_sleeve", "glass_needle", "ballast_seal"]
	seed.offcuts = 80
	_main.collection.restore_snapshot(seed)
	_main._apply_purchases()
	_check(not _main._change_collection("equip", "quicksilver_tip"), "equipment changes require the Book")
	_main.inventory.open_inventory()
	_check(_main._change_collection("equip", "quicksilver_tip"), "owned needle equips through Main")
	_check(is_equal_approx(_main.player.equipment_speed, 1.12) and is_equal_approx(_main.player.equipment_friction, 0.8),
		"equipment applies its speed benefit and braking cost together")
	_check(not _main._change_collection("equip", "silk_hood"), "unowned equipment cannot be worn")
	_main._health = 2
	_check(_main._change_collection("equip", "padded_sleeve"), "health lining equips")
	_check(_main._max_health() == 4 and _main._health == 2, "extra capacity does not heal during an equipment swap")
	_check(_main._change_collection("unequip", "lining") and _main._change_collection("equip", "padded_sleeve") and _main._health == 2,
		"repeated health swaps cannot heal")
	var before: Dictionary = _main.collection.snapshot()
	var prior_speed: float = _main.player.equipment_speed
	var real_store: RefCounted = _main.save_store
	_main.save_store = Save.new(_directory + "/missing/checkpoint.json")
	_check(not _main._change_collection("equip", "glass_needle") and _main.collection.snapshot() == before
		and _main.player.equipment_speed == prior_speed, "failed equip rolls back before applying handling")
	_check(not _main._change_collection("craft", "blunt_stylus") and _main.collection.snapshot() == before,
		"failed craft restores materials and ownership together")
	_main.save_store = real_store
	_check(_main._change_collection("craft", "blunt_stylus"), "offcuts press a missing item from a completed source")
	_check(_main.collection.has_item("blunt_stylus") and _main.collection.snapshot().offcuts == 40,
		"targeted crafting consumes exactly forty offcuts")
	_check(not _main._change_collection("craft", "blunt_stylus"), "an owned piece cannot be repeatedly crafted")
	_check(_main.collection.snapshot().equipped.needle == "quicksilver_tip", "crafting does not silently equip its result")
	_main.inventory.close_inventory()
	await _frames(4)
	_main._respawn()
	_check(_main._health == 4, "recovery fills purchased and equipment-derived needle capacity")
	var equipped: Dictionary = _main.collection.snapshot()
	_main._persist_session()
	_main._return_to_title()
	_main._continue_game()
	await _frames(5)
	_check(_main.collection.snapshot().equipped == equipped.equipped and _main.collection.snapshot().offcuts == equipped.offcuts,
		"Continue restores the loadout and material balance")
	_check(_main._health == 4 and is_equal_approx(_main.player.equipment_speed, 1.12 * 0.92), "Continue restores derived handling and full health")

func _check_bestiary_and_restore() -> void:
	_main._load_world_room(&"horn_plaza")
	await _frames(4)
	var hound: Node2D = _main.room.get_node("Hound")
	_main.player.position = hound.position
	_main._observe_collection()
	_check(_main.collection.snapshot().bestiary.hound.seen, "approaching a resident discovers its bestiary page")
	_main._remember_encounter("the_arm/tonearm", "freed")
	_main._remember_encounter("groove_yard/yard_first_voice", "shattered")
	_main._remember_encounter("the_arm/tonearm", "freed")
	var entries: Dictionary = _main.collection.snapshot().bestiary
	_check(entries.tonearm.freed == 1 and entries.yard_voice.shattered == 1, "story choices backfill once without farming counters")
	var before: Dictionary = _main.collection.snapshot()
	_main.collection.backfill(_main.encounters)
	_check(_main.collection.snapshot() == before, "restored outcomes never increment the bestiary again")
	_main.inventory.open_inventory()
	_main.inventory.select_page("bestiary")
	_main.inventory.refresh_collection()
	_check(_main.collection.snapshot() == before, "bestiary remains a read-only field ledger")
	_main.inventory.close_inventory()
	await _frames(3)

func _check_isolation() -> void:
	_main._persist_session()
	var campaign_model: RefCounted = _main.collection
	var saved: Dictionary = _main.save_store.load_game()
	_main._return_to_title()
	_main._start_practice()
	await _frames(5)
	_check(_main.practice_mode and _main.collection != campaign_model, "move practice receives a disposable collection")
	_check(_main.room.get_node_or_null("EchoTrial") == null, "move practice remains an empty room")
	_main.collection.discover_hunt("label")
	_main.collection.finish_hunt("label")
	_main._persist_session()
	_check(_main.save_store.load_game() == saved, "practice cannot write collection state into the campaign")
	_main._return_to_title()
	_check(_main.collection == campaign_model, "leaving practice restores the same campaign model")
	_main._new_game(false)
	await _frames(4)
	_check(_main.collection.snapshot().owned.is_empty() and _main.collection.snapshot().offcuts == 0,
		"New Game clears equipment, materials and hunt progress")
	_check(is_equal_approx(_main.player.equipment_speed, 1.0) and _main._max_health() == 3,
		"New Game clears all equipment effects")

func _stand(at: Vector2) -> void:
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _frames(5)

func _tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)

func _frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
