extends SceneTree
## One deliberately mean pixel per fresh input; every checkpoint is private.
const MainScene := preload("res://scenes/main.tscn")
const Abilities := preload("res://scripts/abilities_state.gd")
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
	_directory = "user://deadwax-walk-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private Walk fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	await _physics(4)
	await _input_edges()
	await _physics_rules()
	await _earn_walk()
	await _persistence()
	await _old_save()
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"): DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private Walk directory")
	if _failures.is_empty():
		print("DEAD WAX WALK PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("WALK FAIL: " + failure)
	quit(1)

func _input_edges() -> void:
	_check(_main.abilities.snapshot() == {"version": 2, "unlocked": []}, "a fresh journey saves the new empty permission format")
	_check(_main.save_store.load_game().abilities == _main.abilities.snapshot(), "empty Walk state is explicit on disk")
	for code in [KEY_D, KEY_RIGHT, KEY_A, KEY_LEFT]:
		await _stand(Vector2(180, 554))
		var direction := 1.0 if code in [KEY_D, KEY_RIGHT] else -1.0
		_key(code, true)
		await _physics(2)
		_check(is_equal_approx(_main.player.position.x, 180 + direction), "a fresh %s input moves exactly one pixel" % code)
		await _physics(12)
		_check(is_equal_approx(_main.player.position.x, 180 + direction) and is_zero_approx(_main.player.velocity.x), "holding %s adds no movement or momentum" % code)
		_key(code, true, true)
		await _physics(3)
		_check(is_equal_approx(_main.player.position.x, 180 + direction), "keyboard repeat cannot add a %s step" % code)
		_key(code, false)
		await _physics(2)
		await _tap(code)
		_check(is_equal_approx(_main.player.position.x, 180 + 2 * direction), "release and fresh %s tap adds one step" % code)
	await _stand(Vector2(180, 554))
	_key(KEY_A, true)
	_key(KEY_D, true)
	await _physics(3)
	_check(is_equal_approx(_main.player.position.x, 180), "opposed fresh directions cancel instead of doubling travel")
	_release()
	await _physics(2)
	for direction in [-1.0, 1.0]:
		await _stand(Vector2(180, 554))
		_axis(direction)
		await _physics(3)
		_check(is_equal_approx(_main.player.position.x, 180 + direction), "a fresh stick deflection gives one pixel")
		await _physics(12)
		_check(is_equal_approx(_main.player.position.x, 180 + direction), "holding the stick does not walk")
		_axis(0.0)
		await _physics(2)
		_axis(direction)
		await _physics(3)
		_check(is_equal_approx(_main.player.position.x, 180 + direction * 2), "returning the stick to neutral allows another flick")
	_release()

func _physics_rules() -> void:
	var original_rate := Engine.physics_ticks_per_second
	for rate in [30, 60, 120]:
		Engine.physics_ticks_per_second = rate
		await _stand(Vector2(180, 554))
		for tap in 4: await _tap(KEY_A)
		_check(is_equal_approx(_main.player.position.x, 176), "four taps travel four pixels at %d physics ticks" % rate)
	Engine.physics_ticks_per_second = original_rate
	await _stand(Vector2(180, 554))
	_main.player.apply_equipment({"speed": 1.17, "accel": 1.3, "air_control": 1.4, "friction": 0.5})
	await _tap(KEY_D)
	_check(is_equal_approx(_main.player.position.x, 181), "equipment cannot enlarge a shuffle step")
	_main.player.apply_equipment({})
	await _stand(Vector2(180, 554))
	_key(KEY_SPACE, true)
	_key(KEY_D, true)
	await _physics(2)
	var jump_x: float = _main.player.position.x
	_check(absf(jump_x - 181) < _main.player.safe_margin, "the first airborne step stays within one pixel plus collision recovery margin")
	await _physics(8)
	_check(not _main.player.is_on_floor() and _main.player.position.y < 500, "jump remains available before Walk")
	_check(absf(_main.player.position.x - jump_x) < 0.001, "holding direction through a jump adds no air walking")
	_key(KEY_D, false)
	await _physics(1)
	await _tap(KEY_D)
	_check(absf(_main.player.position.x - jump_x - 1.0) < 0.001, "a fresh airborne tap still gives only one pixel")
	_release()
	await _stand(Vector2(18, 554))
	for tap in 5: await _tap(KEY_A)
	_check(_main.player.position.x >= 16.9 and _main.player.position.x <= 18, "tiny steps collide with the left wall")
	await _stand(Vector2(300, 554))
	_main.player.take_hit(Vector2(250, 554))
	await _physics(2)
	_check(_main.player.position.x > 305, "Walk restriction preserves external damage knockback")
	_main._reset_player()
	await _stand(Vector2(180, 554))
	_main._pause_game()
	_key(KEY_A, true)
	await _frames(3)
	_key(KEY_A, false)
	_check(is_equal_approx(_main.player.position.x, 180), "pause does not consume movement into the room")
	_main._resume_game()
	await _physics(4)
	_check(is_equal_approx(_main.player.position.x, 180), "closing pause cannot replay a completed tap")
	_main.inventory.open_inventory()
	await _frames(3)
	await _tap(KEY_A)
	_main.inventory.close_inventory()
	await _physics(4)
	_check(is_equal_approx(_main.player.position.x, 180), "Book navigation cannot leak a shuffle step")

func _earn_walk() -> void:
	_main._new_game(false)
	await _physics(4)
	var walk: Node2D = _main.room.get_node("AbilityWalk")
	_check(walk.position == Vector2(60, 554) and _main.player.position.distance_to(walk.position) > 76,
		"Walk sits behind the cradle outside arrival collection reach")
	_check(_main.player.is_on_floor(), "shuffle route begins on the real opening floor")
	for tap in 44: await _tap(KEY_A)
	_check(is_equal_approx(_main.player.position.x, 136), "44 real taps inch toward the lost soles without teleporting")
	await _tap(KEY_E)
	_check(not _main.abilities.has_ability(&"walk"), "44 taps leave Walk outside its fixed pickup reach")
	await _tap(KEY_A)
	_check(is_equal_approx(_main.player.position.x, 135) and not _main.abilities.has_ability(&"walk"), "45th tap reaches the pickup without automatically granting it")
	_check(_main._persist_session(), "save before the failed acquisition fixture")
	var before: Dictionary = _main.save_store.load_game()
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block private checkpoint staging")
	await _tap(KEY_E)
	_check(not _main.abilities.has_ability(&"walk") and _main.save_store.load_game() == before and is_instance_valid(walk) and walk.visible,
		"failed Walk save keeps both shuffle restriction and the retryable pickup")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock private checkpoint")
	_key(KEY_D, true)
	await _physics(5)
	_check(is_equal_approx(_main.player.position.x, 136), "failed pickup does not enable held walking")
	_release()
	await _physics(2)
	await _tap(KEY_A)
	await _tap(KEY_E)
	_check(_main.abilities.snapshot() == {"version": 2, "unlocked": ["walk"]}, "Walk grants only continuous movement")
	_check(_main.save_store.load_game().abilities == _main.abilities.snapshot() and _main.room.get_node_or_null("AbilityWalk") == null,
		"successful write retires Walk and persists the exact permission")
	_check(_main.player.shine == 0 and _main.progression.snapshot().refrains.is_empty(), "Walk grants no money or other progression")
	var origin: Vector2 = _main.player.position
	_key(KEY_D, true)
	await _physics(24)
	_key(KEY_D, false)
	_check(_main.player.position.x > origin.x + 70 and _main.player.velocity.x > 200, "held movement returns at the original speed and acceleration after Walk")
	_check(not _main.player.has_ability(&"strike") and not _main.player.has_ability(&"hood"), "finding feet leaves later abilities missing")

func _persistence() -> void:
	_main._continue_game()
	await _physics(4)
	_check(_main.abilities.has_ability(&"walk") and _main.room.get_node_or_null("AbilityWalk") == null, "Continue restores Walk before building the room")
	_main._respawn()
	await _physics(4)
	_check(_main.abilities.snapshot().unlocked == ["walk"], "recovery retains only the earned Walk")
	_main._new_game(false)
	await _physics(4)
	_check(not _main.abilities.has_ability(&"walk") and _main.room.get_node_or_null("AbilityWalk") != null, "New Game resets Walk and restores the opening joke")
	var before: Dictionary = _main.save_store.load_game()
	_main._return_to_title()
	await _frames(3)
	var campaign: RefCounted = _main.abilities
	_main._start_practice()
	await _physics(5)
	_check(_main.practice_mode and _main.abilities.has_ability(&"walk"), "Move practice provides Walk immediately")
	var origin: Vector2 = _main.player.position
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	_check(_main.player.position.x > origin.x + 60, "practice keeps continuous held movement")
	_main._return_to_title()
	await _frames(3)
	_check(_main.abilities == campaign and not _main.abilities.has_ability(&"walk") and _main.save_store.load_game() == before,
		"practice restores the shuffle-only campaign without writing its unlocked feet")
	_main._continue_game()
	await _physics(4)
	_check(not _main.abilities.has_ability(&"walk"), "explicit v2 empty Continue never receives a migration grant")

func _old_save() -> void:
	var old := {"version": 1, "room_id": "headshell", "entry_id": "default", "shine": 2,
		"abilities": {"version": 1, "unlocked": ["strike", "set"]},
		"progression": {"version": 1, "refrains": [], "techniques": []}, "encounters": {}}
	var file := FileAccess.open(_main.save_path, FileAccess.WRITE)
	_check(file != null, "open genuine previous-build checkpoint")
	if file == null: return
	file.store_string(JSON.stringify(old))
	file.close()
	_main._continue_game()
	await _physics(4)
	_check(_main.abilities.snapshot() == {"version": 2, "unlocked": ["walk", "strike", "set"]} and _main.player.shine == 2,
		"the previous ability build keeps walking and exactly its other found moves")
	_check(_main.room.get_node_or_null("AbilityWalk") == null and not _main.abilities.has_ability(&"hood"), "migration removes Walk silently without granting the rest of the catalog")
	var origin: Vector2 = _main.player.position
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	_check(_main.player.position.x > origin.x + 60, "previous saves retain their original held movement")

func _stand(at: Vector2) -> void:
	_release()
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _release() -> void:
	for code in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_E]: _key(code, false)
	_axis(0.0)

func _key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)

func _axis(amount: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = amount
	Input.parse_input_event(event)

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(2)
	_key(code, false)
	await _physics(2)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
