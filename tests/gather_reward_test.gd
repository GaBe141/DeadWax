extends SceneTree
## The first carried breath is earned in-world and remains an air move.
## Native collision/input frames use an isolated campaign checkpoint.
const MainScene := preload("res://scenes/main.tscn")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const RoomScript := preload("res://scripts/room_overture.gd")
const PickupScript := preload("res://scripts/refrain_pickup.gd")
const SaveScript := preload("res://scripts/save_store.gd")
const SkipScript := preload("res://scripts/skip.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _unlocks: Array[int] = []
var _strikes: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-gather-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated Gather fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main.progression.refrain_unlocked.connect(func(refrain: int) -> void: _unlocks.append(refrain))
	_main.player.struck.connect(_on_struck)
	for outcome in ["freed", "shattered"]:
		await _earned_reward(outcome)
	await _old_completed_save()
	await _ground_and_air()
	await _practice_shelf()
	await _gallery_latch()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove private Gather checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private Gather fixture")
	if _failures.is_empty():
		print("DEAD WAX GATHER REWARD PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("GATHER REWARD FAIL: " + failure)
	quit(1)

func _earned_reward(outcome: String) -> void:
	_main._new_game(false)
	await _physics(3)
	await _prepare(&"the_arm", Vector2(1260, 574))
	var before := _unlocks.size()
	_check(_pickups().is_empty() and _main.room.get_node_or_null("GatherPracticeLedge") == null,
		"unresolved Arm reveals neither Gather nor its optional shelf")
	_check(_main.room._endpoint == null and not _main.progression.has_refrain(ProgressionScript.Refrain.GATHER),
		"arrival grants neither the ending nor Gather")
	_main.room.set_scenery_motion(true)
	var arm: Node2D = _main.room.get_node("Tonearm")
	arm._resolve_outcome(outcome)
	await _frames(3)
	_check(_main.encounters.get("the_arm/tonearm") == outcome and _pickups().size() == 1,
		outcome + " offers one physical reward through Main's live outcome path")
	_check(_unlocks.size() == before and not _main.chapter_complete,
		"resolving " + outcome + " never auto-collects or completes the chapter")
	var pickup: Node2D = _pickups()[0]
	var authored: Vector2 = pickup.position
	_check(authored == RoomScript.GATHER_POSITION and pickup._reduced_motion,
		"new reward keeps its authored origin and inherits reduced motion")
	for entry in _main.room.entry_points.values():
		_check(authored.distance_to(entry) > PickupScript.COLLECT_RADIUS, "reward stays clear of each Arm arrival")
	_check(_main.room._endpoint != null and not _main.room._endpoint.used, "explicit listening endpoint remains available before collection")
	var surface := Rect2(RoomScript.GATHER_LEDGE_POSITION - RoomScript.GATHER_LEDGE_SIZE * 0.5, RoomScript.GATHER_LEDGE_SIZE)
	_check(surface in _main.room.atmosphere.surfaces and surface in _main.room.lighting.surfaces,
		"live shelf joins the real engraved and light-occluding surfaces")
	_main.room.set_scenery_motion(false)
	await _frames(3)
	var clock_before: float = pickup._float_t
	paused = true
	await _frames(3)
	_check(pickup.position == authored and pickup._float_t == clock_before, "pause freezes pickup art without moving collection reach")
	paused = false
	_main.room.set_scenery_motion(true)
	await _frames(3)
	_check(pickup._float_t == clock_before and pickup.animation_pose().clock == 0.0, "reduced motion settles and freezes the pickup impression")
	_main.room.apply_side(1)
	_check(pickup.ink == _main.room.bg_color and pickup.stock == _main.room.ink, "pickup reverses with the room's ink and stock")
	_main.room.apply_side(0)
	_main.player.set_physics_process(false)
	_main.player.position = authored + Vector2(PickupScript.COLLECT_RADIUS + 1, 0)
	await _frames(2)
	_check(_pickups().size() == 1 and _unlocks.size() == before, "63px remains outside the fixed collection radius")
	_main.player.position = authored + Vector2(PickupScript.COLLECT_RADIUS, 0)
	await _frames(3)
	_check(_pickups().is_empty() and _unlocks.size() == before + 1, "62px contact collects exactly once")
	_check(_main.progression.unlocked_refrains() == [ProgressionScript.Refrain.GATHER]
		and _main.player.air_strikes_left == 1 and _main.player.shine == 0, "collection grants Gather's breath and no currency or other Refrain")
	_check(not _main.chapter_complete and not _main.room._endpoint.used, "collecting Gather does not trigger the ending")
	_main.player.set_physics_process(true)
	_main._respawn()
	await _physics(3)
	_check(_main.progression.has_refrain(ProgressionScript.Refrain.GATHER) and _pickups().is_empty(), "recovery preserves the collected breath")
	_check(_main._persist_session(), "Gather checkpoint writes through Main")
	_main._continue_game()
	await _physics(4)
	_check(_unlocks.size() == before + 1 and _pickups().is_empty() and _main.player.air_strikes_left == 1,
		"Continue restores Gather silently without another pickup or reward signal")
	_check(_main.room.get_node_or_null("GatherPracticeLedge") != null and _main.room._endpoint != null,
		"restored resolution retains the optional shelf and explicit endpoint")

func _old_completed_save() -> void:
	var old: Dictionary = _main.save_store.load_game()
	old.progression = ProgressionScript.new().snapshot()
	old.completed = true
	old.encounters["the_arm/tonearm"] = "freed"
	_check(_main.save_store.save_game(old), "stage old completed campaign without an earned breath")
	var before := _unlocks.size()
	_main._continue_game()
	await _physics(4)
	_check(_main.chapter_complete and _pickups().size() == 1 and _unlocks.size() == before,
		"old completed save can revisit its unclaimed reward without a migration grant")
	_main.player.position = RoomScript.GATHER_POSITION
	await _physics(2)
	_check(_main.progression.has_refrain(ProgressionScript.Refrain.GATHER) and _unlocks.size() == before + 1,
		"an old completed player collects Gather through ordinary contact")

func _ground_and_air() -> void:
	for configuration in [[&"headshell", Vector2(900, 554)], [&"smoothed_floor", Vector2(1000, 574)], [&"the_arm", Vector2(1260, 574)]]:
		if configuration[0] == &"the_arm": _main.encounters.erase("the_arm/tonearm")
		await _prepare(configuration[0], configuration[1])
		var before: Vector2 = _main.player.position
		await _tap(KEY_J)
		_check(not _strikes.back().launched and _main.player.is_on_floor() and absf(_main.player.position.y - before.y) < 1,
			"dry grounded Gather stays planted in " + String(configuration[0]))
		_check(_main.player.air_strikes_left == 1, "grounded strike preserves Gather in " + String(configuration[0]))
		if configuration[0] == &"the_arm":
			_check(_main.room.get_node("Tonearm")._engaged, "a planted strike still initiates the closed Tonearm")
	await _prepare(&"headshell", Vector2(900, 554))
	_key(KEY_SPACE, true)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_check(_strikes.back().launched and _main.player.velocity.y < -SkipScript.AIR_IMPULSE
		and _main.player.air_strikes_left == 0, "jump and Gather strike can launch in the same physics frame")
	await _physics(13)
	var velocity_before: float = _main.player.velocity.y
	await _tap(KEY_J)
	_check(not _strikes.back().launched and _main.player.velocity.y > velocity_before,
		"dry Gather grants only one breath before landing")
	_release_inputs()
	for configuration in [[KEY_A, -1.0], [KEY_D, 1.0]]:
		await _prepare(&"headshell", Vector2(970, 554))
		_key(configuration[0], true)
		_key(KEY_SPACE, true)
		await _physics(12)
		var height_before: float = _main.player.position.y
		await _tap(KEY_J)
		var carried: Vector2 = _strikes.back().velocity
		_check(_strikes.back().launched and carried.y < -SkipScript.AIR_IMPULSE,
			"holding horizontal movement still gives dry Gather upward height: " + str(configuration[1]))
		_check(carried.x * float(configuration[1]) > 0.0 and absf(carried.x) <= SkipScript.RUN_SPEED * SkipScript.AIR_KEEP + 1.0,
			"dry Gather carries existing horizontal momentum without adding a sideways jet: " + str(configuration[1]))
		await _physics(8)
		_check(_main.player.position.y < height_before - 65.0 and _main.player.air_strikes_left == 0,
			"held steering gains real height and spends only the carried breath: " + str(configuration[1]))
	await _prepare(&"headshell", Vector2(900, 554))
	_main.player.air_density = 0.8
	_main.player.air_strikes_max = 2
	_main.player.refill_air_strikes()
	await _tap(KEY_J)
	_check(_strikes.back().launched and _main.player.air_strikes_left == 1,
		"authored thick air retains its existing grounded launch and environmental capacity")
	_check(_main.player.air_density == 0.8 and _main.player.air_strikes_max == 2, "Gather never rewrites the room's air profile")
	await _prepare(&"headshell", Vector2(970, 554))
	_main.player.air_density = 0.8
	_main.player.air_strikes_max = 2
	_main.player.refill_air_strikes()
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	await _physics(12)
	var rising: float = _main.player.velocity.y
	await _tap(KEY_J)
	var jet: Vector2 = _strikes.back().velocity
	_check(_strikes.back().launched and jet.x > SkipScript.AIR_IMPULSE and jet.y > rising * 0.5,
		"the same held horizontal input still aims a room-provided thick-air jet sideways")
	await _prepare(&"the_stalls", Vector2(500, 574))
	var groove: Node2D = _main.room._grooves[0]
	groove.position = _main.player.position + Vector2(0, 65)
	await _tap(KEY_J)
	_check(_strikes.back().launched and _main.player.velocity.y < -850 and _main.player.air_strikes_left == 1,
		"grounded groove launch retains priority and refills Gather")

func _practice_shelf() -> void:
	_main.encounters["the_arm/tonearm"] = "freed"
	await _prepare(&"the_arm", Vector2(1400, 574))
	var floor_y: float = _main.player.position.y
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	await _physics(1)
	for frame in range(40):
		if _main.player.velocity.y >= -60.0: break
		await _physics(1)
	_check(_main.player.position.y > 410 and floor_y - _main.player.position.y < 140,
		"ordinary jump alone stays below the optional breath-height shelf")
	await _tap(KEY_J)
	var landed := false
	for frame in range(100):
		await _physics(1)
		if _main.player.is_on_floor():
			landed = absf(_main.player.position.y - 384.0) < 1.0
			break
	_release_inputs()
	_check(landed, "holding right and jump throughout a crest strike reaches the real practice shelf")
	await _physics(2)
	_check(landed and _main.player.air_strikes_left == 1, "landing on the practice shelf refills the breath")
	await _prepare(&"the_arm", Vector2(1820, 574))
	_check(_main.player.is_on_floor() and _main.player.position.distance_to(_main.room._endpoint.position) < 1.0,
		"safe floor still reaches the final listening point independently of the shelf")

func _gallery_latch() -> void:
	_main.encounters.erase("the_stalls/loft_voice")
	await _prepare(&"worn_gallery", Vector2(390, 494))
	var passage: Node2D
	for child in _main.room.get_children():
		if child.is_in_group("room_exit") and child.target_room == &"the_stalls": passage = child
	_check(passage != null and passage.target_entry == &"from_worn_gallery", "Gallery has the real Stalls shortcut destination")
	_check(_main.room.entry_points.get(&"from_the_stalls") == Vector2(390, 494) and _main.player.is_on_floor(),
		"Stalls arrival stands safely on the Gallery's existing arcade step")
	_check(passage.is_locked(), "an unheard loft voice holds the Gallery latch")
	_main.encounters["the_stalls/loft_voice"] = "shattered"
	_check(passage.is_locked(), "shattering does not impersonate the loft voice's response")
	_main.encounters["the_stalls/loft_voice"] = "freed"
	_check(not passage.is_locked() and passage.required_refrain == -1, "the heard phrase opens the shortcut without a Refrain gate")

func _prepare(id: StringName, position: Vector2) -> void:
	_release_inputs()
	_main._load_world_room(id)
	await _physics(3)
	for actor in get_nodes_in_group("hears_strikes"):
		if _main.room.is_ancestor_of(actor): actor.set_process(false)
	_main.player.position = position
	_main.player.velocity = Vector2.ZERO
	_main.player._strike_cd = 0.0
	_main.player._strike_buffer = 0.0
	_main.player._recover = 0.0
	_main.player._stagger = 0.0
	_main.player.air_density = 0.0
	_main.player.air_strikes_max = 0
	await _physics(4)

func _pickups() -> Array[Node]:
	var found: Array[Node] = []
	for pickup in get_nodes_in_group("refrain_pickup"):
		if _main.room.is_ancestor_of(pickup): found.append(pickup)
	return found

func _on_struck(_position: Vector2, _big: bool, launched: bool) -> void:
	_strikes.append({"launched": launched, "velocity": _main.player.velocity})

func _release_inputs() -> void:
	for key in [KEY_A, KEY_D, KEY_J, KEY_SPACE, KEY_K, KEY_L]: _key(key, false)

func _tap(key: Key) -> void:
	_key(key, true)
	await _physics(1)
	_key(key, false)

func _key(key: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
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
