extends SceneTree
## The first Yard voice teaches listening through real Hood/Set input.
## Fixed local memory and the existing outcome key survive private v1 saves.
const MainScene := preload("res://scenes/main.tscn")
const Voice := preload("res://scripts/yard_voice.gd")
const OrdinaryVoice := preload("res://scripts/auditioner.gd")
const Save := preload("res://scripts/save_store.gd")
const Progression := preload("res://scripts/progression_state.gd")
const MEMORY_ORIGIN := Vector2(1110, 587)
const OUTCOME_KEY := "groove_yard/yard_first_voice"
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _freed := 0
var _shattered := 0

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_check_phrase_rules()
	_directory = "user://deadwax-yard-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated Yard fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	await _keyboard_call_and_memory()
	await _old_choices_and_new_game()
	await _controller_call()
	await _between_physics_response()
	await _live_shatter_memory()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated Yard checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated Yard directory")
	if _failures.is_empty():
		print("DEAD WAX YARD VOICE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("YARD VOICE FAIL: " + failure)
	quit(1)

func _check_phrase_rules() -> void:
	var voice := _fixture()
	voice.advance_phrase(0.0, true, true, false, false)
	voice.advance_phrase(-1.0, true, true, false, false)
	_check(voice.stage == Voice.Stage.WAITING, "nonpositive deltas cannot begin a listening call")
	voice.advance_phrase(4.0, true, false, true, true)
	_check(voice.state != OrdinaryVoice.S.FREED and voice.stage == Voice.Stage.WAITING,
		"holding Set without a complete Hood call never grants mercy")
	_begin_call(voice)
	voice.advance_phrase(Voice.CALL_TIME * 0.5, true, true, false, false)
	voice.advance_phrase(0.1, true, false, true, true)
	_check(voice.stage == Voice.Stage.RESTING, "lowering Hood mid-call gives a harmless rest before trying again")
	voice.advance_phrase(Voice.REST_TIME, true, false, false, false)
	_begin_call(voice)
	voice.advance_phrase(0.1, false, true, false, false)
	_check(voice.stage == Voice.Stage.WAITING, "walking out of listening range cancels an unfinished call")
	_begin_call(voice)
	voice.on_player_strike(voice.global_position, false)
	_check(voice.stage == Voice.Stage.WAITING and is_equal_approx(voice.hp, OrdinaryVoice.HP_MAX - OrdinaryVoice.HP_PER_HIT),
		"striking cancels the phrase and retains ordinary damage")
	voice.free()

	voice = _fixture()
	_begin_call(voice)
	voice.advance_phrase(Voice.CALL_TIME * 0.5, true, true, true, false)
	voice.advance_phrase(Voice.CALL_TIME * 0.5, true, true, false, false)
	_check(voice.stage == Voice.Stage.ANSWERING, "two complete Hood notes open the response window")
	voice.advance_phrase(Voice.ANSWER_HOLD + 0.1, true, false, false, true)
	_check(voice.state != OrdinaryVoice.S.FREED, "Set pressed during the call cannot auto-answer its later silence")
	voice.advance_phrase(Voice.ANSWER_WINDOW + 0.1, true, false, false, false)
	_check(voice.state != OrdinaryVoice.S.FREED, "missing the generous answer window does not resolve the encounter")
	voice.advance_phrase(10.0, true, false, false, false)
	_check(voice.stage == Voice.Stage.WAITING, "a missed response safely returns to a fresh listening attempt")
	_begin_call(voice)
	voice.advance_phrase(Voice.CALL_TIME, true, true, false, false)
	voice.advance_phrase(0.1, true, false, true, true)
	voice.advance_phrase(0.1, true, false, false, false)
	_check(voice.state != OrdinaryVoice.S.FREED, "tapping Set and standing again never substitutes for a held response")
	voice.free()

	voice = _fixture()
	var events: Array[int] = [0, 0]
	voice.freed.connect(func(_pos: Vector2) -> void: events[0] += 1)
	voice.shattered.connect(func(_pos: Vector2) -> void: events[1] += 1)
	_begin_call(voice)
	voice.advance_phrase(Voice.CALL_TIME, true, true, false, false)
	voice.advance_phrase(Voice.ANSWER_HOLD * 0.5, true, false, true, true)
	_check(events == [0, 0], "a partial answer grants no premature outcome")
	voice.advance_phrase(Voice.ANSWER_HOLD * 0.5 + 0.001, true, false, false, true)
	_check(events == [1, 0] and voice.state == OrdinaryVoice.S.FREED and not voice.is_pogoable(),
		"one full fresh held response frees the voice once and ends combat")
	voice.advance_phrase(10.0, true, false, true, true)
	for strike in range(5): voice.on_player_strike(voice.global_position, true)
	_check(events == [1, 0], "resolved mercy cannot replay or become a shatter")
	voice.free()

	voice = _fixture()
	events = [0, 0]
	voice.freed.connect(func(_pos: Vector2) -> void: events[0] += 1)
	voice.shattered.connect(func(_pos: Vector2) -> void: events[1] += 1)
	voice.on_player_strike(voice.global_position + Vector2(121, 0), false)
	_check(voice.hp == OrdinaryVoice.HP_MAX and voice.is_pogoable(), "out-of-range strike preserves ordinary HP and pogo eligibility")
	for strike in range(5): voice.on_player_strike(voice.global_position, false)
	_check(events == [0, 1] and voice.state == OrdinaryVoice.S.DOWN and not voice.is_pogoable(),
		"the ordinary four-hit shatter remains exclusive and emits exactly once")
	voice.free()

func _keyboard_call_and_memory() -> void:
	_main._new_game(false)
	await _physics(3)
	var voice: Node2D = await _prepare_yard()
	var memory: Node2D = _main.room.get_node("YardMemory")
	_check(voice.get_script() == Voice and _persistent(&"yard_last_voice").get_script() == OrdinaryVoice,
		"only the first authored Yard voice receives the listening exchange")
	_check(memory.position == MEMORY_ORIGIN and memory.outcome == "", "unresolved Yard memory stays at the authored empty site")
	_check(not memory.has_meta("chapter_state_id") and not memory.is_in_group("strikable")
		and not memory.has_signal("freed") and not memory.has_signal("shattered"), "the memory is presentation without a second encounter or reward emitter")
	var routes := _routes()
	var progression: Dictionary = _main.progression.snapshot()
	_key(KEY_L, true)
	await _physics(80)
	_key(KEY_L, false)
	_check(_freed == 0 and not _main.encounters.has(OUTCOME_KEY), "real blind Set cannot trigger inherited Auditioner mercy")
	await _physics(2)
	_main.player.position = voice.position + Vector2(-145, -13)
	_main.player.velocity = Vector2.ZERO
	_key(KEY_K, true)
	await _wait_stage(voice, Voice.Stage.CALLING, 30)
	await _physics(12)
	var phrase: Dictionary = voice.animation_pose()
	var memory_pose: Dictionary = memory.animation_pose()
	var health: int = _main._health
	_main._pause_game()
	await _frames(8)
	_check(voice.animation_pose() == phrase and memory.animation_pose() == memory_pose, "pause freezes the listening phrase and local memory art")
	_main._settings.reduced_motion = true
	_main._apply_settings()
	_check(voice.animation_pose().clock == 0.0 and memory.animation_pose().clock == 0.0, "reduced motion immediately steadies both presentations")
	_main._resume_game()
	await _physics(3)
	await _wait_stage(voice, Voice.Stage.ANSWERING, 100)
	_check(voice.animation_pose().stage == "answering" and voice.animation_pose().clock == 0.0,
		"semantic listening cues still reach the silent window with reduced motion")
	_key(KEY_K, false)
	await _physics(2)
	_key(KEY_L, true)
	await _physics(28)
	_key(KEY_L, false)
	await _frames(3)
	_check(_freed == 1 and _shattered == 0 and _main.encounters.get(OUTCOME_KEY) == "freed",
		"actual Hood then fresh held Set resolves through Main's existing saved key")
	_check(_main._health == health, "the complete close listening exchange does not inflict a reach hit")
	_check(_main.player.shine == 0 and _main.progression.snapshot() == progression and _routes() == routes,
		"listening adds no Shine, Refrain, technique or changed route")
	_check(memory.outcome == "freed" and memory.position == MEMORY_ORIGIN, "the live response appears at the fixed remembered place")
	_main.room.apply_side(1)
	_check(memory.ink == _main.room.bg_color and memory.stock == _main.room.ink, "memory reverses with its room's ink and stock")
	_main.room.apply_side(0)
	await _physics(75)
	_check(_persistent(&"yard_first_voice") == null and memory.position == MEMORY_ORIGIN,
		"freed actor leaves after its ordinary departure while its memory stays")
	_check(_main._persist_session(), "save the heard Yard through Main")
	var saved := FileAccess.get_file_as_bytes(_main.save_path)
	await _physics(12)
	_check(FileAccess.get_file_as_bytes(_main.save_path) == saved, "memory animation does not write the checkpoint")
	_main._return_to_title()
	await _frames(3)
	_main._continue_game()
	await _physics(4)
	memory = _main.room.get_node("YardMemory")
	_check(_persistent(&"yard_first_voice") == null and memory.outcome == "freed" and _freed == 1,
		"Continue restores the empty actor site and its memory without another freed signal")
	_check(_main.player.shine == 0 and _main.progression.snapshot() == progression, "silent restoration adds no rewards")

func _old_choices_and_new_game() -> void:
	for outcome in ["freed", "shattered"]:
		var old := {"version": 1, "room_id": "groove_yard", "entry_id": "from_the_stalls",
			"progression": Progression.new().snapshot(), "shine": 6, "completed": false,
			"encounters": {OUTCOME_KEY: outcome}}
		_check(_main.save_store.save_game(old), "existing v1 " + outcome + " Yard choice remains valid")
		_main._continue_game()
		await _physics(4)
		var memory: Node2D = _main.room.get_node("YardMemory")
		_check(_persistent(&"yard_first_voice") == null and memory.outcome == outcome and memory.position == MEMORY_ORIGIN,
			"old " + outcome + " outcome silently restores its distinct fixed memory")
		_check(_freed == 1 and _shattered == 0 and _main.player.shine == 6 and _main.progression.unlocked_refrains().is_empty(),
			"old " + outcome + " save receives no replayed rewards or new permission")
		var pose: Dictionary = memory.animation_pose()
		memory.restore_outcome(outcome)
		_check(memory.animation_pose() == pose, "reapplying " + outcome + " does not restart its decorative reveal")
	_main._new_game(false)
	await _physics(3)
	_main._load_world_room(&"groove_yard", &"from_the_stalls")
	await _physics(3)
	_check(_persistent(&"yard_first_voice") != null and _main.room.get_node("YardMemory").outcome == ""
		and _main.encounters.is_empty(), "New Game starts a new waiting voice and clears its old memory")

func _controller_call() -> void:
	var voice: Node2D = await _prepare_yard()
	_joy(JOY_BUTTON_B, true)
	await _wait_stage(voice, Voice.Stage.ANSWERING, 130)
	_joy(JOY_BUTTON_B, false)
	await _physics(2)
	_joy(JOY_BUTTON_LEFT_SHOULDER, true)
	await _physics(28)
	_joy(JOY_BUTTON_LEFT_SHOULDER, false)
	_check(_freed == 2 and _main.encounters.get(OUTCOME_KEY) == "freed", "controller Hood and fresh held shoulder Set play the same complete response")
	_check(_main.player.shine == 0 and _main.progression.unlocked_refrains().is_empty(), "controller listening grants no extra progression or currency")

func _between_physics_response() -> void:
	_main._new_game(false)
	await _physics(3)
	var voice: Node2D = await _prepare_yard()
	var previous_ticks := Engine.physics_ticks_per_second
	var previous_fps := Engine.max_fps
	Engine.physics_ticks_per_second = 5
	Engine.max_fps = 120
	_key(KEY_K, true)
	await _wait_stage(voice, Voice.Stage.ANSWERING, 15)
	_key(KEY_K, false)
	await _physics(1)
	var physics_before := Engine.get_physics_frames()
	var freed_before := _freed
	_key(KEY_L, true)
	await _frames(2)
	_check(Engine.get_physics_frames() == physics_before and not _main.player.setting,
		"fresh Set arrives during render frames before the next grounded physics update")
	await _physics(3)
	_key(KEY_L, false)
	Engine.physics_ticks_per_second = previous_ticks
	Engine.max_fps = previous_fps
	_check(_freed == freed_before + 1 and _main.encounters.get(OUTCOME_KEY) == "freed",
		"a held Set edge between physics ticks still answers once on the next physics updates")

func _live_shatter_memory() -> void:
	_main._new_game(false)
	await _physics(3)
	var voice: Node2D = await _prepare_yard()
	var memory: Node2D = _main.room.get_node("YardMemory")
	var shattered_before := _shattered
	var freed_before := _freed
	for hit in range(4): voice.on_player_strike(voice.global_position, false)
	_check(_shattered == shattered_before + 1 and _freed == freed_before
		and _main.encounters.get(OUTCOME_KEY) == "shattered", "ordinary force still records its existing exclusive shatter outcome")
	_check(memory.outcome == "shattered" and memory.position == MEMORY_ORIGIN,
		"live force leaves its distinct memory at the same fixed site")
	await _physics(35)
	_check(_persistent(&"yard_first_voice") == null and memory.outcome == "shattered",
		"the shattered actor departs without taking its quiet engraving with it")
	_check(_main.player.shine == 0 and _main.progression.unlocked_refrains().is_empty(),
		"the new shatter memory adds no currency or Refrain")

func _fixture() -> Node2D:
	var voice := Voice.new()
	voice.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(voice)
	return voice

func _begin_call(voice: Node2D) -> void:
	voice.advance_phrase(0.01, true, true, false, false)
	_check(voice.stage == Voice.Stage.CALLING, "quiet nearby Hood begins a fresh call")

func _prepare_yard() -> Node2D:
	_release_inputs()
	# This fixture jumps to earned-move mechanics; opening acquisition has its own suite.
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	_main._load_world_room(&"groove_yard", &"from_the_stalls")
	await _physics(3)
	var voice := _persistent(&"yard_first_voice") as Node2D
	voice.freed.connect(func(_pos: Vector2) -> void: _freed += 1)
	voice.shattered.connect(func(_pos: Vector2) -> void: _shattered += 1)
	_main.player.position = voice.position + Vector2(-145, -13)
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_check(_main.player.is_on_floor(), "authored Yard listening spot supports the real player")
	return voice

func _persistent(id: StringName) -> Node:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id: return child
	return null

func _routes() -> Array[String]:
	var result: Array[String] = []
	for child in _main.room.get_children():
		if child.is_in_group("room_exit"):
			result.append("%s:%s:%d" % [child.target_room, child.target_entry, child.required_refrain])
	result.sort()
	return result

func _wait_stage(voice: Node2D, stage: int, limit: int) -> void:
	for frame in range(limit):
		if voice.stage == stage: break
		await _physics(1)
	_check(voice.stage == stage, "real input reaches authored phrase stage " + str(stage))

func _release_inputs() -> void:
	for key in [KEY_K, KEY_L, KEY_J, KEY_D, KEY_A, KEY_SPACE]: _key(key, false)
	for button in [JOY_BUTTON_B, JOY_BUTTON_LEFT_SHOULDER]: _joy(button, false)

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

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
