extends SceneTree
## The discovery is playable through both input sets; its saved phrase opens
## the real route and returns home without paying extra Shine or replaying it.
const MainScene := preload("res://scenes/main.tscn")
const Voice := preload("res://scripts/loft_voice.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Save := preload("res://scripts/save_store.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _freed_count := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_phrase_rules()
	_directory = "user://deadwax-loft-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_absolute(_directory)
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game()
	await _physics(3)
	_check(not _main.audio.home_song_snapshot().requested, "fresh home has no returned phrase")
	_main.progression.unlock_refrain(Progression.Refrain.GATHER)
	_main._load_world_room(&"the_stalls", &"from_groove_yard")
	await _physics(3)
	var voice: Node2D = _main.room.get_node("LoftVoice")
	voice.freed.connect(func(_pos: Vector2) -> void: _freed_count += 1)
	_main.player.position = voice.position + Vector2(55, 0)
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_check(_main.player.is_on_floor(), "loft listening spot has standing room")
	_key(KEY_L, true)
	await _physics(110)
	_check(voice.responses == 0 and _freed_count == 0, "holding Set without hearing a call cannot resolve the voice")
	_key(KEY_L, false)
	await _physics(2)
	_key(KEY_K, true)
	await _physics(20)
	var before: Dictionary = voice.animation_pose()
	_main._pause_game()
	await _frames(12)
	_check(voice.animation_pose() == before, "pause freezes audible call state and printed note cues")
	_main._resume_game()
	await _physics(2)
	await _wait_stage(voice, Voice.Stage.ANSWERING, 100)
	_key(KEY_K, false)
	await _physics(2)
	_key(KEY_L, true)
	await _physics(21)
	_key(KEY_L, false)
	_check(voice.responses == 1 and _freed_count == 0, "keyboard Hood and fresh Set complete one answer")
	await _wait_stage(voice, Voice.Stage.WAITING, 70)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	_check(voice.animation_pose().clock == 0.0, "reduced motion steadies the sleeve while retaining functional cues")
	_joy(JOY_BUTTON_B, true)
	await _wait_stage(voice, Voice.Stage.ANSWERING, 120)
	_joy(JOY_BUTTON_B, false)
	await _physics(2)
	_joy(JOY_BUTTON_LEFT_SHOULDER, true)
	await _physics(22)
	_joy(JOY_BUTTON_LEFT_SHOULDER, false)
	_check(voice.stage == Voice.Stage.FREED and _freed_count == 1, "controller Hood and Set complete the second answer once")
	_check(_main.encounters.get("the_stalls/loft_voice", "") == "freed", "Main records the returned phrase")
	_check(_main.player.shine == 0, "the lost phrase never creates Shine")
	_check(not _main.audio.home_song_snapshot().requested, "market discovery does not start the home music in the loft")
	var route := _exit_to(&"worn_gallery")
	_check(route != null and not route.is_locked(), "real loft passage opens after listening")
	_main.player.position = route.position
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_key(KEY_E, true)
	await _physics(3)
	_key(KEY_E, false)
	await _physics(3)
	_check(_main.world_room_id == &"worn_gallery" and _main.room_entry_id == &"from_the_stalls", "fresh passage input takes the new route to the Gallery")
	route = _exit_to(&"the_stalls")
	_check(route != null and not route.is_locked(), "Gallery return uses the same persistent discovery")
	_main._load_world_room(&"horn_plaza", &"from_the_stalls")
	await _physics(5)
	_check(_main.audio.home_song_snapshot().requested, "the discovered melody joins the plaza")
	_check(_main._persist_session(), "save the discovered phrase and home checkpoint")
	_main._show_title()
	await _frames(3)
	_main._continue_game()
	await _physics(5)
	_check(_main.audio.home_song_snapshot().requested and _main.progression.has_refrain(Progression.Refrain.GATHER), "Continue restores the home phrase and held breath")
	_main._load_world_room(&"the_stalls", &"from_worn_gallery")
	await _physics(4)
	voice = _main.room.get_node("LoftVoice")
	_check(voice.stage == Voice.Stage.FREED and _freed_count == 1, "return restores the voice silently without replaying its reward")
	_check(_main.player.is_on_floor(), "shortcut arrival lands safely in the loft")
	_main._load_world_room(&"headshell", &"from_horn_plaza")
	await _physics(4)
	_check(_main.audio.home_song_snapshot().requested, "the phrase also reaches the Headshell")
	_main._new_game()
	await _physics(4)
	_check(not _main.audio.home_song_snapshot().requested and _main.encounters.is_empty(), "New Game clears discovery and music together")
	_main.queue_free()
	await _frames(4)
	paused = false
	Save.new(_directory + "/checkpoint.json").delete_save()
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	DirAccess.remove_absolute(_directory)
	if _failures.is_empty():
		print("DEAD WAX LOFT VOICE PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures: push_error("LOFT VOICE FAIL: " + failure)
		quit(1)

func _check_phrase_rules() -> void:
	var voice := Voice.new()
	var count := [0]
	voice.freed.connect(func(_pos: Vector2) -> void: count[0] += 1)
	voice.advance_phrase(0.1, true, true, false, false)
	voice.advance_phrase(0.8, true, true, false, false)
	voice.advance_phrase(0.1, true, false, true, true)
	_check(voice.stage == Voice.Stage.WAITING, "lowering Hood halfway through a call asks to hear it again")
	voice.advance_phrase(0.1, true, true, false, false)
	voice.advance_phrase(Voice.CALL_TIME, true, true, false, false)
	voice.advance_phrase(Voice.ANSWER_WINDOW + 0.1, true, false, false, true)
	_check(voice.responses == 0, "preheld Set cannot answer the silent window")
	voice.advance_phrase(0.1, true, true, false, false)
	voice.advance_phrase(Voice.CALL_TIME, true, true, false, false)
	voice.advance_phrase(0.1, true, false, true, true)
	voice.advance_phrase(0.1, true, false, false, false)
	_check(voice.responses == 0, "a short Set tap does not complete an answer")
	voice.responses = 1
	voice.advance_phrase(0.1, false, false, false, false)
	_check(voice.responses == 0, "walking away resets the unfinished conversation")
	voice.restore_outcome("freed")
	voice.advance_phrase(10.0, true, false, true, true)
	voice.on_player_strike(Vector2.ZERO, true)
	_check(voice.stage == Voice.Stage.FREED and count[0] == 0, "restored resolution is stable and never emits a reward")
	voice.free()

func _exit_to(target: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.is_in_group("room_exit") and child.target_room == target: return child
	return null

func _wait_stage(voice: Node2D, target: int, limit: int) -> void:
	for frame in range(limit):
		if voice.stage == target: break
		await _physics(1)
	_check(voice.stage == target, "phrase reaches stage %d within its authored timing" % target)

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
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures.append(message)
