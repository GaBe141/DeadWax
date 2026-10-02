extends SceneTree
## Full-game calibration and semantic controls use a private adapter and files.
const MainScript := preload("res://scripts/main.gd")
const Profile := preload("res://scripts/controller_profile.gd")
const Save := preload("res://scripts/save_store.gd")
const Progression := preload("res://scripts/progression_state.gd")
const DEVICE := 77
const DEVICE_KEY := "deadwax-integration-gamecube"

class ControllerMain extends MainScript:
	var connected := true
	func _controller_devices() -> Array:
		return [{"id": DEVICE, "key": DEVICE_KEY, "name": "Fixture USB GameCube",
			"configured": controller_profiles.has(DEVICE_KEY)}] if connected else []

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
	_directory = "user://deadwax-controller-integration-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private controller fixture")
	var config := ConfigFile.new()
	config.set_value("audio", "volume", 0.37)
	config.set_value("display", "reduced_motion", true)
	config.set_value("controllers", "profiles", {"broken": {"version": 1}})
	config.set_value("future", "retained", "untouched")
	_check(config.save(_directory + "/settings.cfg") == OK, "seed private settings")
	await _boot()
	await _calibration()
	await _gameplay()
	await _menus()
	await _persistence_and_practice()
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private campaign")
	for name in ["settings.cfg", "settings.cfg.tmp"]:
		if FileAccess.file_exists(_directory + "/" + name): DirAccess.remove_absolute(_directory + "/" + name)
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private fixture directory")
	if _failures.is_empty():
		print("DEAD WAX CONTROLLER INTEGRATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("CONTROLLER INTEGRATION FAIL: " + failure)
	quit(1)

func _boot() -> void:
	_main = ControllerMain.new()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(4)

func _profile() -> Dictionary:
	var bindings := {}
	for index in Profile.PHYSICAL.size():
		bindings[String(Profile.PHYSICAL[index])] = {"kind": "button", "index": index + 12}
	for pair in [["stick_left", 0, -1.0], ["stick_right", 0, 1.0], ["stick_up", 1, -1.0],
		["stick_down", 1, 1.0], ["c_up", 3, -1.0], ["c_down", 3, 1.0]]:
		bindings[pair[0]] = {"kind": "axis", "index": pair[1], "sign": pair[2], "rest": 0.0}
	bindings.l = {"kind": "axis", "index": 4, "sign": 1.0, "rest": 0.0}
	bindings.r = {"kind": "axis", "index": 5, "sign": 1.0, "rest": 0.0}
	return {"version": 1, "layout": "gamecube", "bindings": bindings}

func _calibration() -> void:
	_check(_main.game_menu.screen == "title" and paused, "ordinary boot remains on title")
	_check(_main.controller_profiles.is_empty(), "malformed stored layout is ignored")
	_check(is_equal_approx(_main._settings.volume, 0.37) and _main._settings.reduced_motion, "existing preferences restore")
	_check(not _main.controller_router.has_profile(DEVICE), "uncalibrated device retains ordinary controls")
	_main.game_menu._open_subpage("settings")
	_main._open_controller_setup()
	await _frames(2)
	_check(_main.controller_menu.is_open and _main.controller_router.suspended and paused, "setup suspends translation and world")
	_check(not _main._can_open_inventory(), "setup excludes other gameplay menus")
	_button(16, true)
	await _frames(2)
	_check(_main.controller_menu._phase == "ready", "raw A cannot confirm the setup sheet")
	_button(16, false)
	var good := _profile()
	_main._save_controller_profile(DEVICE_KEY, good)
	await _frames(4)
	_check(not _main.controller_menu.is_open and not _main.controller_router.suspended, "successful settings commit closes setup")
	_check(paused and _main.game_menu.screen == "settings", "setup returns to paused settings")
	_check(root.gui_get_focus_owner() == _main.game_menu._first_focus, "setup restores controller focus to the settings sheet")
	_check(_main.controller_router.has_profile(DEVICE), "saved physical adapter is installed")
	_check(_main.game_menu.controller_labels.inventory == "Z" and _main.inventory.controller_labels.pause_game == "Start", "menus describe physical GameCube labels")
	_check(_main._controller_text("L / LB · Answer. F / RB · Turn.") == "L · Answer. F / R · Turn.", "world instructions use the learned physical shoulders")
	var saved := ConfigFile.new()
	_check(saved.load(_main.settings_path) == OK, "saved layout can be read")
	_check(Profile.valid(saved.get_value("controllers", "profiles")[DEVICE_KEY]), "complete layout persists outside campaign")
	_check(saved.get_value("future", "retained") == "untouched", "layout commit retains unrelated settings")
	_check(not FileAccess.file_exists(_main.save_path), "title calibration cannot create a campaign")
	_main._change_settings({"volume": 0.43, "reduced_motion": false, "fullscreen": false})
	_check(saved.load(_main.settings_path) == OK and saved.get_value("controllers", "profiles")[DEVICE_KEY] == good, "ordinary settings edits preserve calibration")
	_main._open_controller_setup()
	var before: Dictionary = _main.controller_profiles.duplicate(true)
	var path: String = _main.settings_path
	_main.settings_path = _directory + "/unavailable/settings.cfg"
	var changed := good.duplicate(true)
	changed.bindings.a.index = 64
	_main._save_controller_profile(DEVICE_KEY, changed)
	_check(_main.controller_profiles == before and _main.controller_menu.is_open, "failed settings write leaves installed profile and retry sheet intact")
	_check(_main.controller_menu._notice.text.contains("Could not save"), "failed write explains that layout is retryable")
	_main.settings_path = path
	_main._save_controller_profile("disconnected-controller", good)
	_check(_main.controller_profiles == before and _main.controller_menu.is_open, "disconnected source cannot save a layout")
	_main._save_controller_profile(DEVICE_KEY, {"version": 1})
	_check(_main.controller_profiles == before, "invalid intent cannot install partial controls")
	_main.controller_menu.close_menu()
	await _frames(4)
	_check(not _main.controller_router.suspended and paused, "cancel restores routing without resuming play")

func _gameplay() -> void:
	_main._new_game(false)
	await _physics(4)
	await _stand(Vector2(180, 554))
	_axis(0, 1.0)
	await _physics(3)
	_check(is_equal_approx(_main.player.position.x, 181.0), "calibrated stick flick shuffles exactly one pixel before Walk")
	await _physics(10)
	_check(is_equal_approx(_main.player.position.x, 181.0), "held calibrated stick never repeats the opening shuffle")
	_axis(0, 0.0)
	await _physics(2)
	_key(KEY_D, true)
	await _physics(2)
	var shuffle_x: float = _main.player.position.x
	_main._refresh_controllers()
	await _physics(3)
	_check(is_equal_approx(_main.player.position.x, shuffle_x), "USB refresh cannot invent a fresh keyboard shuffle")
	_key(KEY_D, false)
	await _physics(2)
	_axis(0, 1.0)
	await _physics(3)
	_check(is_equal_approx(_main.player.position.x, shuffle_x + 1.0), "neutral then a new flick permits one more pixel")
	_release()
	_main.abilities.restore_snapshot({"version": 2, "unlocked": ["walk", "strike", "set", "hood", "combo", "groove", "pogo"]})
	_main.player.reset_animation()
	await _stand(Vector2(520, 554))
	_axis(0, 1.0)
	await _physics(14)
	_check(_main.player.velocity.x > 330 and _main.player.position.x > 550, "earned Walk uses calibrated stick acceleration")
	_key(KEY_D, true)
	_main._refresh_controllers()
	Input.flush_buffered_events()
	_check(Input.is_action_pressed("move_right"), "controller refresh preserves a held keyboard direction")
	_key(KEY_D, false)
	_axis(0, 0.0)
	await _physics(12)
	_check(is_zero_approx(_main.player.velocity.x), "refresh releases controller travel before a fresh flick")
	await _stand(Vector2(520, 554))
	_button(16, true)
	await _physics(2)
	_check(not _main.player.is_on_floor() and _main.player.velocity.y < 0.0, "physical A jumps")
	_button(16, false)
	await _physics(45)
	await _stand(Vector2(520, 554))
	_button(18, true)
	await _physics(2)
	_check(_main.player._strike_cd > 0.0, "physical X strikes")
	_button(18, false)
	await _physics(15)
	_button(17, true)
	await _physics(3)
	_check(_main.player.hooded, "physical B raises the Hood")
	_button(17, false)
	_axis(4, 1.0)
	await _physics(3)
	_check(_main.player.setting, "physical L holds Set")
	_axis(4, 0.0)
	await _physics(2)
	_main.progression.unlock_refrain(Progression.Refrain.JUMP_CUT)
	var side: Variant = _main.pressing.side
	_axis(5, 1.0)
	await _physics(3)
	_check(_main.pressing.side != side, "physical R flips only with the earned Refrain")
	_axis(5, 0.0)
	_axis(0, -1.0)
	_button(17, true)
	_axis(4, 1.0)
	await _physics(4)
	_main.connected = false
	_main._on_controller_connection(DEVICE, false)
	Input.flush_buffered_events()
	_check(not Input.is_action_pressed("move_left") and not _main.controller_router.has_profile(DEVICE), "unplug releases virtual direction")
	_check(not Input.is_action_pressed("lift") and not Input.is_action_pressed("set"), "unplug also releases Hood and analog Set")
	_main.connected = true
	_main._on_controller_connection(DEVICE, true)
	_button(17, false)
	_axis(4, 0.0)
	_axis(0, 0.0)
	await _physics(14)
	_check(is_zero_approx(_main.player.velocity.x), "reconnecting cannot keep Skip moving")
	_release()

func _menus() -> void:
	await _stand(Vector2(520, 554))
	_button(22, true) # physical Z
	await _frames(3)
	_check(_main.inventory.is_open() and paused and not _main.game_menu.is_open, "Z opens only The Book")
	_button(22, false)
	await _frames(3)
	_axis(5, 1.0)
	await _frames(3)
	_check(_main.inventory._current_page == "equipment", "physical R advances Book page")
	_axis(5, 0.0)
	_axis(4, 1.0)
	await _frames(3)
	_check(_main.inventory._current_page == "journey", "physical L returns Book page")
	_axis(4, 0.0)
	_axis(3, 1.0)
	await _frames(2)
	_check(Input.get_action_strength("book_scroll_down") > 0.99 and not Input.is_action_pressed("move_down"), "C stick scrolls notes independently of movement")
	_axis(3, 0.0)
	_button(17, true)
	await _frames(3)
	_check(not _main.inventory.is_open() and not paused, "B closes The Book")
	await _physics(3)
	_check(not _main.player.hooded and not Input.is_action_pressed("lift"), "held Book Back cannot raise Hood underneath")
	_button(17, false)
	await _physics(3)
	_button(23, true) # physical Start
	await _frames(3)
	_check(_main.game_menu.screen == "pause" and paused and not _main.inventory.is_open(), "physical Start opens only pause")
	_button(23, false)
	await _frames(3)
	_button(23, true)
	await _frames(3)
	_check(not paused and not _main.game_menu.is_open, "fresh Start resumes from pause")
	_button(23, false)
	_main.map_state.collect()
	_button(27, true) # D-pad Down
	await _frames(3)
	_check(_main.map_menu.is_open and paused, "D-pad Down opens the owned map")
	_button(27, false)
	await _frames(3)
	_axis(0, 1.0)
	await _frames(3)
	_check(_main.map_menu._region == &"overture", "right stick direction pages the map correctly")
	_axis(0, -1.0)
	await _frames(3)
	_check(_main.map_menu._region == &"label", "left stick direction pages back rather than forward")
	_axis(0, 0.0)
	_button(17, true)
	await _frames(4)
	_check(not _main.map_menu.is_open and not paused, "B closes the map through Main")
	await _physics(3)
	_check(not _main.player.hooded, "held map Back also stays out of gameplay")
	_button(17, false)
	await _physics(3)
	_button(26, true) # D-pad Up away from a shop
	await _frames(3)
	_check(not _main.shop.is_open and not _main.inventory.is_open(), "D-pad Up cannot shop outside its authored context")
	_button(26, false)

func _persistence_and_practice() -> void:
	_check(_main._persist_session(), "private campaign commits normally")
	var checkpoint: Dictionary = _main.save_store.load_game()
	_check(not checkpoint.has("controllers"), "controller preferences never enter campaign checkpoint")
	_main._return_to_title()
	await _frames(3)
	var disk_before := FileAccess.get_file_as_string(_main.save_path)
	_main._start_practice()
	await _frames(4)
	_check(_main.practice_mode and not paused, "Move practice is still isolated and playable")
	_button(23, true)
	await _frames(3)
	_button(23, false)
	_main.game_menu._open_subpage("settings")
	_main._open_controller_setup()
	_check(_main.controller_menu.is_open and paused, "controller setup also works from practice pause")
	_main._save_controller_profile(DEVICE_KEY, _profile())
	await _frames(4)
	_check(FileAccess.get_file_as_string(_main.save_path) == disk_before, "practice calibration cannot alter campaign data")
	_main._return_to_title()
	await _frames(3)
	_release()
	_main.queue_free()
	await _frames(3)
	await _boot()
	_check(_main.controller_router.has_profile(DEVICE) and _main.controller_profiles[DEVICE_KEY] == _profile(), "fresh boot restores the complete calibrated adapter")
	_check(is_equal_approx(_main._settings.volume, 0.43), "volume survives calibration and restart")
	_main._continue_game()
	await _physics(4)
	_check(_main.world_room_id == StringName(checkpoint.room_id) and _main.abilities.snapshot() == checkpoint.abilities, "Continue preserves campaign abilities and room")
	_check(_main.controller_router.has_profile(DEVICE), "Continue keeps controller settings independent")

func _stand(at: Vector2) -> void:
	_release()
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _release() -> void:
	for axis in [0, 1, 3, 4, 5]: _axis(axis, 0.0)
	for index in range(16, 30): _button(index, false)
	_key(KEY_D, false)

func _axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = DEVICE
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _button(index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = DEVICE
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition: _failures.append(label)
