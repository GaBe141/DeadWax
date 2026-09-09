extends SceneTree
## Real input and collision frames keep grounded combat separate from launches.
## Every disk write belongs to this run's private checkpoint directory.
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const SkipScript := preload("res://scripts/skip.gd")
const DummyScript := preload("res://scripts/test_pressing.gd")
const VoiceScript := preload("res://scripts/auditioner.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _strikes: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-attack-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated attack fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game()
	await _physics(4)
	_main.player.struck.connect(_on_struck)
	await _grounded_hits()
	await _airborne_hits()
	await _groove_priority()
	await _strike_edges()
	await _movement_recovery()
	await _queue_cancellation()
	await _parry_window()
	await _count_in()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated attack checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated attack directory")
	if _failures.is_empty():
		print("DEAD WAX ATTACK FEEL PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("ATTACK FEEL FAIL: " + failure)
	quit(1)

func _grounded_hits() -> void:
	var knowledge: Dictionary = _main.progression.snapshot().duplicate(true)
	for configuration in [[&"high_street", &"street_looper", 830.0], [&"groove_yard", &"yard_first_voice", 1010.0]]:
		await _prepare(configuration[0], configuration[2])
		var enemy := _persistent(configuration[1])
		var hp_before: float = enemy.hp
		_main.player.air_density = 1.0
		_main.player.air_strikes_max = 2
		_main.player.refill_air_strikes()
		_key(KEY_D, true)
		await _physics(5)
		var count_before := _strikes.size()
		var incoming: Vector2 = _main.player.velocity
		var y_before: float = _main.player.position.y
		_check(_main.player.is_on_floor(), String(configuration[1]) + " approaches on the real floor")
		_key(KEY_J, true)
		await _physics(1)
		_key(KEY_J, false)
		_key(KEY_D, false)
		_check(_strikes.size() == count_before + 1, String(configuration[1]) + " takes a strike on the first input frame")
		_check(is_equal_approx(hp_before - float(enemy.hp), 1.0), String(configuration[1]) + " receives normal damage")
		_check(not _strikes.back().launched and _main.player.is_on_floor() and absf(_main.player.position.y - y_before) < 1,
			String(configuration[1]) + " grounded damage does not force a pogo")
		_check(float(_strikes.back().vx) >= incoming.x and is_zero_approx(_main.player.velocity.y),
			String(configuration[1]) + " attack preserves forward motion without vertical recoil")
		_check(_main.player.air_strikes_left == 2, String(configuration[1]) + " grounded foe hit preserves held breaths")
	_check(_main.progression.snapshot() == knowledge and _main.player.shine == 0, "ordinary hits grant no knowledge, Refrain or Shine")

func _airborne_hits() -> void:
	for configuration in [[&"high_street", &"street_looper"], [&"groove_yard", &"yard_first_voice"]]:
		for distance in [120.0, 121.0]:
			await _prepare(configuration[0], 650)
			var enemy := _persistent(configuration[1])
			_main.player.position = Vector2(650, 250)
			_main.player.velocity = Vector2.ZERO
			await _physics(1)
			_main.player.velocity = Vector2.ZERO
			enemy.position = _main.player.position + Vector2(distance, 0)
			var hp_before: float = enemy.hp
			_check(not _main.player.is_on_floor(), "range fixture is airborne on a real physics frame")
			_key(KEY_J, true)
			await _physics(1)
			_key(KEY_J, false)
			var label := String(configuration[1]) + " at " + str(distance) + "px"
			_check(bool(_strikes.back().launched) == (distance == 120.0), label + " keeps the pogo boundary")
			_check(is_equal_approx(hp_before - float(enemy.hp), 1.0 if distance == 120.0 else 0.0), label + " matches pogo reach to confirmed damage")
			if distance == 120.0:
				_check(_main.player.velocity.y < -500, label + " retains the upward airborne rebound")
		await _prepare(configuration[0], 850 if configuration[0] == &"high_street" else 1020)
		_key(KEY_SPACE, true)
		_key(KEY_J, true)
		await _physics(1)
		_key(KEY_SPACE, false)
		_key(KEY_J, false)
		_check(_strikes.back().launched and _main.player.velocity.y < -700,
			String(configuration[1]) + " supports jump and pogo pressed on the same frame")
	await _prepare(&"smoothed_floor", 1000)
	var hush := _persistent(&"hush")
	await _tap(KEY_J)
	_check(_main.player.is_on_floor() and not _strikes.back().launched and is_equal_approx(hush.hp, DummyScript.HP_MAX),
		"a grounded raw strike against HUSH stays planted and grants no damage")
	await _physics(14)
	_main.player.position = Vector2(1000, 250)
	await _physics(1)
	_main.player.velocity = Vector2.ZERO
	hush.position = _main.player.position + Vector2(90, 0)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_check(not hush.is_pogoable() and not _strikes.back().launched, "muted HUSH cannot grant a rebound from a hit he ignores")

func _groove_priority() -> void:
	await _prepare(&"the_stalls", 500)
	var groove: Node2D = _main.room._grooves[0]
	groove.position = _main.player.position + Vector2(0, 65)
	var enemy := DummyScript.new()
	enemy.position = _main.player.position + Vector2(90, 0)
	_main.room.add_child(enemy)
	enemy.set_process(false)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_check(_strikes.back().launched and absf(float(_strikes.back().vx)) < 1 and float(_strikes.back().vy) < -850,
		"a nearby groove retains launch priority over a grounded foe")
	_check(is_equal_approx(enemy.hp, DummyScript.HP_MAX - 1.0), "groove launch still delivers the confirmed nearby enemy hit")

func _strike_edges() -> void:
	await _prepare(&"headshell", 300)
	var start := _strikes.size()
	_key(KEY_J, true)
	await _physics(1)
	_check(_strikes.size() == start + 1, "ready strike has no animation or input delay")
	await _physics(36)
	_key(KEY_J, false)
	_check(_strikes.size() == start + 1, "holding strike never auto-repeats")
	await _prepare(&"headshell", 300)
	start = _strikes.size()
	await _queue_near_end()
	_check(_main.player._strike_buffer > 0 and _strikes.size() == start + 1, "late second tap waits in one short buffer")
	await _physics(12)
	_check(_strikes.size() == start + 2, "late second tap executes once when cooldown ends")
	_check(int(_strikes[-1].frame) - int(_strikes[-2].frame) >= 12, "buffer cannot shorten the 200ms strike cadence")
	await _physics(20)
	_check(_strikes.size() == start + 2, "released buffered input does not repeat again")
	await _prepare(&"headshell", 300)
	start = _strikes.size()
	await _tap(KEY_J)
	await _physics(1)
	await _tap(KEY_J)
	await _physics(20)
	_check(_strikes.size() == start + 1 and is_zero_approx(_main.player._strike_buffer), "an early second tap expires rather than becoming a delayed attack")
	await _prepare(&"headshell", 300)
	start = _strikes.size()
	_joy(JOY_BUTTON_X, true)
	await _physics(1)
	_joy(JOY_BUTTON_X, false)
	while _main.player._strike_cd > 0.055: await _physics(1)
	_joy(JOY_BUTTON_X, true)
	await _physics(20)
	_joy(JOY_BUTTON_X, false)
	_check(_strikes.size() == start + 2, "controller strike buffers one edge and holding it adds no third hit")

func _movement_recovery() -> void:
	var reversed_after: Array[int] = []
	for attack in [false, true]:
		await _prepare(&"headshell", 280)
		_key(KEY_D, true)
		await _physics(10)
		if attack: await _tap(KEY_J)
		_key(KEY_D, false)
		_key(KEY_A, true)
		var start := Engine.get_physics_frames()
		for index in range(20):
			await _physics(1)
			if _main.player.velocity.x < 0:
				reversed_after.append(Engine.get_physics_frames() - start)
				break
		_key(KEY_A, false)
	_check(reversed_after.size() == 2 and reversed_after[1] <= reversed_after[0] + 2,
		"grounded attack adds at most two frames to a full-speed direction reversal")

func _queue_cancellation() -> void:
	for blocker in ["hood", "set", "stagger", "hit", "pause", "book", "shop", "recover", "passage"]:
		await _prepare(&"bootlegger" if blocker == "shop" else &"headshell", 760 if blocker == "shop" else 300)
		await _queue_near_end()
		var before := _strikes.size()
		match blocker:
			"hood": _key(KEY_K, true)
			"set": _key(KEY_L, true)
			"stagger": _main.player._stagger = 0.2
			"hit": _main.player.take_hit(_main.player.position + Vector2(100, 0))
			"pause": _main._pause_game()
			"book": _main.inventory.open_inventory()
			"shop": _main._open_shop()
			"recover": _main._respawn()
			"passage": _main._load_world_room(&"horn_plaza")
		if paused: await _frames(3)
		else: await _physics(2)
		_check(is_zero_approx(_main.player._strike_buffer), blocker + " cancels the pending strike")
		match blocker:
			"hood": _key(KEY_K, false)
			"set": _key(KEY_L, false)
			"pause": _main._resume_game()
			"book": _main.inventory.close_inventory()
			"shop": _main._close_shop()
		await _physics(24)
		_check(_strikes.size() == before, blocker + " cannot leak a delayed strike after play resumes")

func _parry_window() -> void:
	_check(DummyScript.PARRY_WINDOW_MS == 100 and VoiceScript.PARRY_WINDOW_MS == 100, "both ordinary encounters retain the 100ms parry window")
	await _prepare(&"high_street", 850)
	var dummy := _persistent(&"street_looper")
	dummy._player = _main.player
	dummy.state = DummyScript.S.SWING
	_main.player.last_strike_ms = Time.get_ticks_msec() - 95
	dummy._resolve_swing(90)
	_check(dummy.parry_count == 1 and dummy.state == DummyScript.S.STAGGER, "a strike inside 100ms still catches the looper swing")
	dummy.state = DummyScript.S.SWING
	_main.player.last_strike_ms = Time.get_ticks_msec() - 105
	dummy._resolve_swing(90)
	_check(dummy.parry_count == 1 and _main.player._stagger > 0, "a strike outside 100ms still takes the looper hit")
	await _prepare(&"groove_yard", 1020)
	var voice := _persistent(&"yard_first_voice")
	voice._player = _main.player
	voice.state = VoiceScript.S.REACH
	_main.player.last_strike_ms = Time.get_ticks_msec() - 95
	voice._resolve_reach(90)
	_check(voice.state == VoiceScript.S.STAGGER, "a strike inside 100ms still catches the voice reach")
	voice.state = VoiceScript.S.REACH
	_main.player.last_strike_ms = Time.get_ticks_msec() - 105
	voice._resolve_reach(90)
	_check(voice.state == VoiceScript.S.RECOVER and _main.player._stagger > 0, "a strike outside 100ms still takes the voice hit")

func _count_in() -> void:
	await _prepare(&"practice_room", 750)
	var door := _persistent(&"practice_count_in")
	_check(not _main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN), "combat and buffered inputs have not discovered Count-In")
	var count_before := _strikes.size()
	for beat in range(4):
		await _tap(KEY_J)
		if beat < 3:
			var until := Time.get_ticks_msec() + 300
			while Time.get_ticks_msec() < until: await _physics(1)
	await _physics(2)
	_check(_strikes.size() == count_before + 4 and door.is_open, "four deliberately spaced physical strikes still open the listening door")
	_check(_main.progression.knows_technique(ProgressionScript.Technique.COUNT_IN)
		and _main.encounters.get("practice_room/practice_count_in") == "opened", "Count-In alone records its knowledge and opened lock")
	_check(_main.player.shine == 0 and _main.progression.unlocked_refrains().is_empty(), "the feel adjustment never adds currency or earned permissions")

func _queue_near_end() -> void:
	await _tap(KEY_J)
	while _main.player._strike_cd > 0.055: await _physics(1)
	await _tap(KEY_J)

func _prepare(id: StringName, x: float) -> void:
	_release_inputs()
	_main._load_world_room(id)
	await _physics(3)
	for actor in get_nodes_in_group("hears_strikes"):
		if _main.room.is_ancestor_of(actor): actor.set_process(false)
	_main.player.position = Vector2(x, 554 if id == &"headshell" else 574)
	_main.player.velocity = Vector2.ZERO
	_main.player._strike_cd = 0
	_main.player._strike_buffer = 0
	_main.player._recover = 0
	_main.player._stagger = 0
	_main.player.air_density = 0
	_main.player.air_strikes_max = 0
	await _physics(4)

func _persistent(id: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id: return child
	return null

func _on_struck(_position: Vector2, big: bool, launched: bool) -> void:
	_strikes.append({"frame": Engine.get_physics_frames(), "vx": _main.player.velocity.x,
		"vy": _main.player.velocity.y, "big": big, "launched": launched})

func _release_inputs() -> void:
	for code in [KEY_A, KEY_D, KEY_J, KEY_SPACE, KEY_K, KEY_L]: _key(code, false)
	_joy(JOY_BUTTON_X, false)

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(1)
	_key(code, false)

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

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
