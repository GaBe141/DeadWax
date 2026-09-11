extends SceneTree
## Execute real input against Main and compare the accent with ordinary launches.
## Combo timing is simulation state; drawing and checkpoints never own it.
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const SkipScript := preload("res://scripts/skip.gd")
const DummyScript := preload("res://scripts/test_pressing.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")

class GrooveProbe extends Node2D:
	var hot := false
	var pings := 0
	func _ready() -> void: add_to_group("live_groove")
	func reach() -> float: return 20.0
	func is_echo_hot() -> bool: return hot
	func ping() -> void: pings += 1

var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _strikes: Array[Dictionary] = []
var _beats := 0
var _input_stamp := -100000

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-combo-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated combo fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	# This fixture jumps to earned-move mechanics; opening acquisition has its own suite.
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	await _physics(4)
	_main.player.struck.connect(_on_struck)
	_main.player.on_beat.connect(func() -> void: _beats += 1)
	await _sequence_and_expiry()
	await _fresh_edges_and_buffer()
	await _cancellation()
	await _launch_invariants()
	await _combat_boundaries()
	await _readout_ownership()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated combo checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated combo directory")
	if _failures.is_empty():
		print("DEAD WAX COMBO PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("COMBO FAIL: " + failure)
	quit(1)

func _sequence_and_expiry() -> void:
	await _prepare()
	var initial: Dictionary = _main.progression.snapshot().duplicate(true)
	var beats_before := _beats
	for index in range(4):
		await _ready_strike()
		var count_before := _strikes.size()
		await _tap(KEY_J)
		_check(_strikes.size() == count_before + 1, "ready press %d strikes immediately" % (index + 1))
		var hit: Dictionary = _strikes.back()
		var step := index % 3 + 1
		_check(hit.step == step and hit.label == ["TAP", "SWEEP", "ACCENT"][step - 1], "executed presses cycle TAP / SWEEP / ACCENT / TAP")
		_check(hit.big == (step == 3) and not hit.launched, "only the planted third strike is the stronger accent")
		_check(hit.pose_step == step and hit.strike_ms >= hit.input_ms, "strike pose and parry clock describe this execution")
		if index > 0:
			_check(int(hit.frame) - int(_strikes[-2].frame) >= 12, "combo preserves the 200ms cooldown")
	_check(_beats == beats_before, "an accent without a hot groove never announces ON BEAT")
	_check(_main.progression.snapshot() == initial and _main.player.shine == 0, "an empty combo grants no knowledge, Refrain or Shine")
	await _ready_strike()
	await _tap(KEY_J)
	await _ready_strike()
	await _tap(KEY_J)
	_check(_main.player.combo_step == 3, "expiry fixture ends on an accent")
	var remaining: float = _main.player.combo_remaining
	_main.player._process(10.0)
	_main.player._process(10.0)
	_check(is_equal_approx(_main.player.combo_remaining, remaining), "presentation frames cannot spend the gameplay combo window")
	var copied: Dictionary = _main.player.combo_snapshot()
	copied.step = 0
	copied.remaining = 99.0
	_check(_main.player.combo_step == 3 and _main.player.combo_remaining < 1, "snapshot mutation cannot change a live combo")
	await _physics(41)
	var expired: Dictionary = _main.player.combo_snapshot()
	_check(expired.step == 0 and is_zero_approx(expired.remaining) and expired.label == "", "a .65-second physics window expires to an empty chain")
	_check(_main.player._animation_pose().combo_step == 3, "expired chain retains the executed accent for presentation")
	await _tap(KEY_J)
	_check(_strikes.back().step == 1 and not _strikes.back().big, "a press after expiry starts TAP")

func _fresh_edges_and_buffer() -> void:
	await _prepare()
	var count_before := _strikes.size()
	_key(KEY_J, true)
	await _physics(46)
	_key(KEY_J, false)
	_check(_strikes.size() == count_before + 1 and _main.player.combo_step == 0, "holding beyond cooldown and expiry executes only one hit")
	await _prepare()
	await _tap(KEY_J)
	await _physics(1)
	count_before = _strikes.size()
	await _tap(KEY_J)
	await _physics(16)
	_check(_strikes.size() == count_before and _main.player.combo_step == 1, "an early edge expires without advancing the chain")
	await _prepare()
	await _prime_accent()
	count_before = _strikes.size()
	while _main.player._strike_cd > 0.055: await _physics(1)
	var old_stamp: int = _main.player.last_strike_ms
	await _tap(KEY_J)
	_check(_main.player._strike_buffer > 0 and _main.player.combo_step == 2 and _strikes.size() == count_before,
		"a late third press waits without advancing the chain")
	_check(_main.player.last_strike_ms == old_stamp, "buffering does not prematurely open the parry clock")
	await _physics(8)
	_check(_strikes.size() == count_before + 1 and _strikes.back().step == 3 and _strikes.back().big,
		"one buffered edge executes exactly one accent")
	_check(_main.player.last_strike_ms > old_stamp and int(_strikes[-1].frame) - int(_strikes[-2].frame) >= 12,
		"buffered accent stamps the actual execution without shortening cooldown")
	await _physics(22)
	_check(_strikes.size() == count_before + 1, "consumed accent never repeats")
	await _prepare()
	for step in range(1, 4):
		await _ready_strike()
		_joy(JOY_BUTTON_X, true)
		await _physics(1)
		_joy(JOY_BUTTON_X, false)
		_check(_strikes.back().step == step, "controller X advances the same fresh-press chain")

func _cancellation() -> void:
	for blocker in ["hood", "set", "stagger", "hit", "pause", "book", "shop", "recover", "passage", "explicit"]:
		await _prepare(&"bootlegger" if blocker == "shop" else &"headshell", 760.0 if blocker == "shop" else 300.0)
		await _prime_accent()
		while _main.player._strike_cd > 0.055: await _physics(1)
		await _tap(KEY_J)
		_check(_main.player.combo_step == 2 and _main.player._strike_buffer > 0, blocker + " fixture has a chain and queued accent")
		var count_before := _strikes.size()
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
			"explicit": _main.player.cancel_pending_strike()
		if paused: await _frames(3)
		else: await _physics(2)
		var snapshot: Dictionary = _main.player.combo_snapshot()
		_check(snapshot.step == 0 and is_zero_approx(snapshot.remaining) and is_zero_approx(_main.player._strike_buffer),
			blocker + " cancels both the live chain and pending accent")
		match blocker:
			"hood": _key(KEY_K, false)
			"set": _key(KEY_L, false)
			"pause": _main._resume_game()
			"book": _main.inventory.close_inventory()
			"shop": _main._close_shop()
		await _physics(24)
		_check(_strikes.size() == count_before, blocker + " cannot leak a delayed attack on return")
		await _tap(KEY_J)
		_check(_strikes.back().step == 1, blocker + " resumes with TAP on the next fresh press")

func _launch_invariants() -> void:
	for kind in ["ground_foe", "pogo", "gather", "thick_air", "cold_groove", "hot_groove"]:
		var ordinary: Dictionary = await _launch_case(kind, false)
		var accent: Dictionary = await _launch_case(kind, true)
		_check(ordinary.velocity.is_equal_approx(accent.velocity), kind + " accent preserves the ordinary launch velocity")
		_check(ordinary.launched == accent.launched and ordinary.breaths == accent.breaths,
			kind + " accent preserves launch eligibility and breath spending")
		_check(accent.big and ordinary.big == (kind == "hot_groove"), kind + " receives one stronger accent hit")
		_check(ordinary.beats == (1 if kind == "hot_groove" else 0) and accent.beats == ordinary.beats,
			kind + " accent cannot duplicate or invent a hot-groove beat")
		if kind in ["ground_foe", "pogo"]:
			_check(is_equal_approx(ordinary.damage, DummyScript.HP_PER_HIT)
				and is_equal_approx(accent.damage, DummyScript.HP_PER_BIG), kind + " accent uses existing big-hit damage only")
		if kind.ends_with("groove"):
			_check(ordinary.pings == 1 and accent.pings == 1, kind + " is pinged once per strike")

func _launch_case(kind: String, accent: bool) -> Dictionary:
	await _prepare()
	if accent: await _prime_accent()
	await _ready_strike()
	var player: CharacterBody2D = _main.player
	var foe: Node2D
	var groove: GrooveProbe
	if kind in ["pogo", "gather"]:
		player.position = Vector2(650, 250)
		player.velocity = Vector2.ZERO
		await _physics(1)
	if kind == "gather":
		_main.progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
	if kind in ["ground_foe", "thick_air"]:
		player.air_density = 1.0
		player.air_strikes_max = 2
	player.refill_air_strikes()
	if kind in ["ground_foe", "pogo"]:
		foe = DummyScript.new()
		foe.position = player.position + Vector2(100, 0)
		_main.room.add_child(foe)
		foe.set_process(false)
	if kind.ends_with("groove"):
		groove = GrooveProbe.new()
		groove.hot = kind == "hot_groove"
		groove.position = player.position + Vector2(0, 70)
		_main.room.add_child(groove)
	player.velocity = Vector2(80, -100 if kind in ["pogo", "gather"] else 0)
	var beats_before := _beats
	await _tap(KEY_J)
	var result: Dictionary = _strikes.back().duplicate(true)
	result["beats"] = _beats - beats_before
	result["damage"] = DummyScript.HP_MAX - foe.hp if foe != null else 0.0
	result["pings"] = groove.pings if groove != null else 0
	_check(result.step == (3 if accent else 1), kind + " fixture executes the intended combo step")
	if kind == "ground_foe":
		_check(not result.launched and player.is_on_floor() and result.breaths == 2,
			"grounded foe accent stays planted and retains both breaths")
	return result

func _combat_boundaries() -> void:
	_check(SkipScript.STRIKE_COOLDOWN == 0.20 and SkipScript.STRIKE_BUFFER == 0.09
		and SkipScript.STRIKE_RECOVER == 0.10 and DummyScript.PARRY_WINDOW_MS == 100,
		"combo preserves cooldown, input buffer, recovery and parry tuning")
	for distance in [120.0, 121.0]:
		await _prepare()
		await _prime_accent()
		await _ready_strike()
		_main.player.position = Vector2(650, 250)
		await _physics(1)
		_main.player.velocity = Vector2.ZERO
		var foe := DummyScript.new()
		foe.position = _main.player.position + Vector2(distance, 0)
		_main.room.add_child(foe)
		foe.set_process(false)
		await _tap(KEY_J)
		_check(_strikes.back().big and _strikes.back().launched == (distance == 120.0), "accent retains the 120px pogo boundary")
		_check(is_equal_approx(DummyScript.HP_MAX - foe.hp, DummyScript.HP_PER_BIG if distance == 120.0 else 0.0),
			"accent hit range matches pogo reach")
	await _prepare()
	await _prime_accent()
	await _ready_strike()
	var foe := DummyScript.new()
	foe.position = _main.player.position + Vector2(100, 0)
	_main.room.add_child(foe)
	foe.set_process(false)
	_key(KEY_SPACE, true)
	await _tap(KEY_J)
	_key(KEY_SPACE, false)
	_check(_strikes.back().step == 3 and _strikes.back().launched and _main.player.velocity.y < -700,
		"jump and accent on the same physics frame preserve the airborne rebound")
	_check(_main.progression.unlocked_refrains().is_empty() and _main.progression.discovered_techniques().is_empty()
		and _main.player.shine == 0, "combo combat never grants progression or currency")

func _prepare(id: StringName = &"headshell", x: float = 300.0) -> void:
	_release_inputs()
	_main.progression.reset()
	_main._load_world_room(id)
	await _physics(3)
	for actor in get_nodes_in_group("hears_strikes"):
		if _main.room.is_ancestor_of(actor): actor.set_process(false)
	var player: CharacterBody2D = _main.player
	player.position = Vector2(x, 554 if id == &"headshell" else 574)
	player.velocity = Vector2.ZERO
	player._strike_cd = 0.0
	player._recover = 0.0
	player._stagger = 0.0
	player.air_density = 0.0
	player.air_strikes_max = 0
	await _physics(4)

func _readout_ownership() -> void:
	await _prepare()
	await _tap(KEY_J)
	var player_snapshot: Dictionary = _main.player.combo_snapshot()
	var readout: Control = _main.combo_readout
	readout.set_snapshot(player_snapshot)
	_check(readout.visible and readout._headline.text == "1  TAP" and readout._window.visible,
		"the live readout immediately presents the executed beat and remaining window")
	readout.set_snapshot({"step": 3, "remaining": 0.5, "window": 0.65, "label": "ACCENT"})
	_check(_main.player.combo_snapshot() == player_snapshot, "a supplied readout snapshot cannot mutate Skip's chain or timer")
	_main._pause_game()
	var stamp: float = readout._stamp
	var window_size: Vector2 = readout._window.size
	await _frames(8)
	_check(readout._stamp == stamp and readout._window.size == window_size, "world pause freezes the readout impression and supplied window")
	readout.set_reduced_motion(true)
	_check(is_zero_approx(readout._stamp) and is_equal_approx(readout._headline.modulate.a, 1.0)
		and readout._window.visible and readout._window.size == window_size,
		"reduced motion settles the stamp while retaining truthful supplied information")
	var old_stock: Color = readout._stock
	var dark_stock := Color("242024")
	_main._apply_hud_palette(dark_stock)
	_check(readout._stock == dark_stock, "Main forwards reversed HUD stock to the combo readout")
	_main._apply_hud_palette(old_stock)
	_check(readout._stock == old_stock, "returning palette restores the readout stock exactly")
	readout.set_reduced_motion(false)
	_main._resume_game()
	await _physics(2)
	_check(not readout.visible and _main.player.combo_step == 0, "resume presents the cancelled empty chain without stale beat text")

func _prime_accent() -> void:
	await _tap(KEY_J)
	await _ready_strike()
	await _tap(KEY_J)

func _ready_strike() -> void:
	for frame in range(20):
		if _main.player._strike_cd <= 0: return
		await _physics(1)

func _on_struck(_position: Vector2, big: bool, launched: bool) -> void:
	var snapshot: Dictionary = _main.player.combo_snapshot()
	_strikes.append({"frame": Engine.get_physics_frames(), "velocity": _main.player.velocity,
		"big": big, "launched": launched, "step": snapshot.step, "label": snapshot.label,
		"pose_step": _main.player._animation_pose().combo_step, "breaths": _main.player.air_strikes_left,
		"strike_ms": _main.player.last_strike_ms, "input_ms": _input_stamp})

func _release_inputs() -> void:
	for code in [KEY_A, KEY_D, KEY_J, KEY_SPACE, KEY_K, KEY_L]: _key(code, false)
	_joy(JOY_BUTTON_X, false)

func _tap(code: Key) -> void:
	_key(code, true)
	await _physics(1)
	_key(code, false)

func _key(code: Key, pressed: bool) -> void:
	if code == KEY_J and pressed: _input_stamp = Time.get_ticks_msec()
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _joy(button: JoyButton, pressed: bool) -> void:
	if button == JOY_BUTTON_X and pressed: _input_stamp = Time.get_ticks_msec()
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
