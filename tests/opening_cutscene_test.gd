extends SceneTree
## Native title/input handoff plus deterministic advancement of the film's
## public timeline. Save files belong only to this run's private directory.
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _finished := 0
var _strikes := 0
var _shots: Array[int] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-opening-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private opening fixture")
	root.min_size = Vector2i.ZERO
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main.opening.finished.connect(func() -> void: _finished += 1)
	_main.opening.shot_started.connect(func(index: int) -> void: _shots.append(index))
	_main.player.struck.connect(func(_pos: Vector2, _big: bool, _launched: bool) -> void: _strikes += 1)
	await _actual_new_game_and_skip()
	await _controller_skip()
	await _pointer_and_focus()
	await _natural_timeline_and_motion()
	await _replay_and_continue()
	await _deferred_menu_closes()
	_check_cancel()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove private opening checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private opening fixture")
	if _failures.is_empty():
		print("DEAD WAX OPENING CUTSCENE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("OPENING CUTSCENE FAIL: " + failure)
	quit(1)

func _actual_new_game_and_skip() -> void:
	_check(paused and _main.game_menu.screen == "title" and not _main.opening.is_open,
		"boot shows the title without playing the opening automatically")
	_check(not FileAccess.file_exists(_main.save_path), "title alone never creates a campaign checkpoint")
	_key(KEY_ENTER, true)
	await _frames(5)
	_check(_finished == 0, "held title confirmation cannot finish or skip the film")
	_key(KEY_ENTER, false)
	await _frames(3)
	_check(_main.opening.is_open and _main.opening.shot == 0 and paused and not _main.game_menu.is_open,
		"physical title confirmation opens shot one over a paused new game")
	_check(_main._has_session and _main.world_room_id == &"headshell" and _main.save_store.has_save(),
		"New Game creates its recoverable Headshell entry before the film")
	_main.opening.advance(0.25)
	var world := _physical_snapshot()
	var model := _model_snapshot()
	var saved := FileAccess.get_file_as_bytes(_main.save_path)
	var film_time: float = _main.opening.elapsed
	var film_shot: int = _main.opening.shot
	for key in [KEY_D, KEY_SPACE, KEY_J, KEY_L, KEY_E, KEY_I, KEY_M, KEY_B, KEY_F, KEY_R]: _key(key, true)
	await _physics(8)
	_check(_main.opening.is_open and (_main.opening.shot > film_shot or _main.opening.elapsed > film_time),
		"film timeline advances while gameplay is paused")
	_check(_main.opening.shot == 1, "fresh Space advances one shot while holding it never repeats")
	_check(_physical_snapshot() == world and _model_snapshot() == model,
		"held gameplay inputs change no player, world, encounter or progression state during the opening")
	_check(FileAccess.get_file_as_bytes(_main.save_path) == saved, "intro activity never rewrites campaign progress")
	_check(not _main.game_menu.is_open and not _main.inventory.is_open() and not _main.shop.is_open and not _main.map_menu.is_open,
		"pause, Book, trade and map cannot stack over the opening")
	_main._on_route_requested(&"horn_plaza", &"from_headshell")
	await _frames(2)
	_check(not _main._transition_pending and _main.world_room_id == &"headshell", "a passage request cannot leave the film's starting room")
	_key(KEY_ESCAPE, true)
	await _frames(1)
	_check(_main.opening.is_open and paused and _finished == 0, "fresh Escape starts an exit while keeping gameplay paused")
	await create_timer(0.55).timeout
	await _physics(4)
	_check(_finished == 1 and not _main.opening.is_open and not paused, "Escape hands off to play exactly once after the short exit")
	_check(_main.player.position.distance_to(world.position) < 1.0 and _strikes == 0
		and not _main.player.setting and _main.player.last_strike_ms == world.last_strike,
		"held movement, jump, strike, Set and passage inputs do not leak into the first gameplay frames")
	_check(_main.player._strike_buffer <= 0.0 and _main.player._buffer <= 0.0 and not _main._transition_pending,
		"opening handoff clears queued jump, attack and passage state")
	_release_inputs()
	await _physics(2)
	_check(not paused and not _main.game_menu.is_open, "releasing the skip key does not reopen pause")
	var start: Vector2 = _main.player.position
	_key(KEY_D, true)
	await _physics(5)
	_key(KEY_D, false)
	_check(_main.player.position.x > start.x, "a fresh movement input works after the opening")

func _controller_skip() -> void:
	_release_inputs()
	_joy(JOY_BUTTON_A, true)
	_main._new_game()
	await _frames(4)
	var before := _finished
	_check(_main.opening.is_open and _main.opening.shot == 0 and paused, "a held controller confirmation cannot skip the new opening")
	_joy(JOY_BUTTON_A, false)
	await _frames(3)
	_main.opening.advance(0.25)
	_joy(JOY_BUTTON_B, true)
	await _frames(1)
	_check(_main.opening.is_open and paused and _finished == before, "fresh controller B begins the same short exit")
	await create_timer(0.55).timeout
	await _physics(3)
	_check(not _main.opening.is_open and not paused and _finished == before + 1,
		"controller B completes one clean handoff")
	_check(_main.player.is_on_floor() and _strikes == 0 and not _main.game_menu.is_open,
		"held confirm and skip never become a jump, attack or pause action")
	_release_inputs()

func _pointer_and_focus() -> void:
	_main._new_game()
	_main.opening.set_process(false)
	_main.opening.advance(0.25)
	await _frames(3)
	var next_button: Button = _main.opening.next_button
	var skip_button: Button = _main.opening.skip_button
	var before := _finished
	var point := next_button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	Input.parse_input_event(move)
	await _frames(1)
	_mouse_button(point, true)
	await _frames(1)
	_mouse_button(point, false)
	await _frames(2)
	_check(_main.opening.shot == 1 and _finished == before and paused, "mouse Next advances one shot without starting gameplay")
	next_button.grab_focus()
	_key(KEY_RIGHT, true)
	await _frames(1)
	_key(KEY_RIGHT, false)
	await _frames(1)
	_check(skip_button.has_focus(), "keyboard focus moves from Next to Skip")
	_joy(JOY_BUTTON_A, true)
	await _frames(1)
	_joy(JOY_BUTTON_A, false)
	_check(_main.opening.is_open and paused and _main.opening.animation_pose().finishing,
		"controller confirm activates the focused Skip action")
	_main.opening.advance(0.6)
	_main.opening.set_process(true)
	await _physics(3)
	_check(_finished == before + 1 and not paused and not _main.opening.is_open, "focused Skip completes one handoff")
	var focus := root.gui_get_focus_owner()
	_check(focus == null or not _main.opening.overlay.is_ancestor_of(focus), "hidden opening controls release keyboard focus after exit")

func _natural_timeline_and_motion() -> void:
	_shots.clear()
	var before := _finished
	_main._new_game()
	_main.opening.set_process(false)
	await _frames(3)
	_check(_main.opening.SHOT_DURATIONS == [5.5, 6.0, 5.5, 6.0], "four authored shots retain their complete 23-second reading time")
	var world := _physical_snapshot()
	_main.opening.advance(0.9)
	_check(_main.opening.shot == 0 and is_equal_approx(_main.opening.elapsed, 0.9), "public advancement moves the actual shot timeline")
	_main._settings.reduced_motion = true
	_main._apply_settings()

	var pose: Dictionary = _main.opening.animation_pose()
	_check(bool(pose.reduced_motion) and pose.clock == 0.0 and is_equal_approx(_main.opening.art.modulate.a, 1.0),
		"reduced motion immediately settles open film artwork and its decorative clock")
	_main.opening.advance(0.2)
	_check(_main.opening.elapsed > 0.9 and _main.opening.animation_pose() == pose,
		"reduced motion keeps the story timeline running while holding its illustrated pose still")
	for size in [Vector2i(960, 600), Vector2i(1280, 720)]:
		root.content_scale_size = size
		root.size = size
		await _frames(3)
		_check(_opaque_cover(_main.opening), "opening retains an opaque full-screen backing at " + str(size))
		_check(_main.opening.is_open and _main.opening.shot == 0 and paused, "resize neither restarts the film nor releases pause")
	_check(_main.player.position == world.position and _main.player.last_strike_ms == world.last_strike,
		"motion settings and resize preserve the paused player")
	world = _physical_snapshot()
	for index in range(4):
		_check(_main.opening.shot == index, "natural film presents shot " + str(index + 1))
		_main.opening.advance(float(_main.opening.SHOT_DURATIONS[index]) - float(_main.opening.elapsed) + 0.001)
	_check(_shots == [0, 1, 2, 3], "natural progression starts each authored shot exactly once, in order")
	_check(_physical_snapshot() == world and paused, "the complete story advances no world frames before its exit")
	_main.opening.advance(0.6)
	_main.opening.set_process(true)
	await _physics(3)
	_check(_finished == before + 1 and not _main.opening.is_open and not paused, "the last shot naturally hands off into play")
	_main.opening.advance(100.0)
	_main.opening.skip()
	await _frames(2)
	_check(_finished == before + 1 and _shots == [0, 1, 2, 3], "completed timelines ignore extra advances and repeated skips")
	_main._settings.reduced_motion = false
	_main._apply_settings()

func _replay_and_continue() -> void:
	_main.progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
	_main.economy.restore(4, ["warm_thread"])
	_main.encounters["the_stalls/loft_voice"] = "freed"
	_main.map_state.collect()
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(3)
	_main._return_to_title()
	await _frames(3)
	var saved := FileAccess.get_file_as_bytes(_main.save_path)
	var model := _model_snapshot()
	var before := _finished
	_main.game_menu.opening_requested.emit()
	await _frames(3)
	_check(_main.opening.is_open and paused and not _main.game_menu.is_open and not _main._has_session,
		"title's Watch Opening action plays a preview without starting a new campaign")
	_main.opening.skip()
	_main.opening.advance(0.6)
	await _frames(3)
	_check(not _main.opening.is_open and paused and _main.game_menu.screen == "title" and not _main._has_session,
		"skipping a preview returns to the title instead of entering gameplay")
	_check(_finished == before + 1 and _model_snapshot() == model and FileAccess.get_file_as_bytes(_main.save_path) == saved,
		"replaying the opening preserves existing Refrains, wallet, map, choices and checkpoint bytes")
	_main.game_menu.continue_requested.emit()
	await _physics(4)
	_check(not _main.opening.is_open and not paused and _main._has_session and _main.world_room_id == &"horn_plaza",
		"Continue restores the saved room directly without replaying the film")
	_check(_finished == before + 1 and _model_snapshot() == model, "Continue restores the same campaign data without another intro completion")

func _check_cancel() -> void:
	var film: CanvasLayer = _main.opening.get_script().new()
	root.add_child(film)
	var completions: Array[int] = []
	film.finished.connect(func() -> void: completions.append(1))
	film.play_opening()
	film.advance(1.0)
	film.cancel()
	film.advance(100.0)
	film.skip()
	_check(not film.is_open and completions.is_empty(), "cancel retires the film silently without a delayed finished signal")
	film.queue_free()

func _deferred_menu_closes() -> void:
	_main._open_map()
	_check(_main.map_menu.is_open, "stale map-close fixture opens the owned carried map")
	_main._close_map()
	_main._new_game()
	await _frames(4)
	_check(_main.opening.is_open and paused, "a deferred map close cannot unpause a newer opening")
	_main.opening.skip()
	_main.opening.advance(0.6)
	await _physics(3)
	_main._load_world_room(&"bootlegger")
	await _physics(3)
	_main.player.position = Vector2(720, 574)
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_main._open_shop()
	_check(_main.shop.is_open, "stale shop-close fixture opens beside the Bootlegger")
	_main._close_shop()
	_main._new_game()
	await _frames(4)
	_check(_main.opening.is_open and paused, "a deferred shop close cannot unpause a newer opening")
	_main.opening.skip()
	_main.opening.advance(0.6)
	await _physics(3)

func _opaque_cover(node: Node) -> bool:
	var viewport := Rect2(Vector2.ZERO, Vector2(root.content_scale_size))
	for child in node.get_children():
		if child is ColorRect and child.is_visible_in_tree() and child.color.a >= 0.99 and child.modulate.a >= 0.99:
			if child.get_global_rect().encloses(viewport): return true
		if _opaque_cover(child): return true
	return false

func _physical_snapshot() -> Dictionary:
	return {"room": _main.world_room_id, "position": _main.player.position, "velocity": _main.player.velocity,
		"last_strike": _main.player.last_strike_ms, "strikes": _strikes, "pose": _main.player._animation_pose().duplicate(true),
		"atmosphere": _main.room.atmosphere.visual_snapshot().duplicate(true), "lighting": _main.room.lighting.visual_snapshot().duplicate(true)}

func _model_snapshot() -> Dictionary:
	return {"progression": _main.progression.snapshot(), "wallet": _main.economy.snapshot(),
		"map": _main.map_state.snapshot(), "encounters": _main.encounters.duplicate(true)}

func _release_inputs() -> void:
	for key in [KEY_D, KEY_SPACE, KEY_J, KEY_K, KEY_L, KEY_E, KEY_I, KEY_M, KEY_B, KEY_F, KEY_R, KEY_ENTER, KEY_ESCAPE]: _key(key, false)
	for button in [JOY_BUTTON_A, JOY_BUTTON_B]: _joy(button, false)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
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
