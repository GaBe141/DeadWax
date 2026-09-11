extends SceneTree
## Real strike edges verify readiness, early rejection, and one queued attack.
## The supplied readout owns neither cooldown nor the separate link-time rail.
const MainScene := preload("res://scenes/main.tscn")
const Skip := preload("res://scripts/skip.gd")
const Readout := preload("res://scripts/combo_readout.gd")
const Save := preload("res://scripts/save_store.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _rejected := 0
var _strikes: Array[Dictionary] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-readability-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated combo-readability fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	# This fixture jumps to earned-move mechanics; opening acquisition has its own suite.
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	await _physics(3)
	_main.player.strike_input_rejected.connect(func() -> void: _rejected += 1)
	_main.player.struck.connect(func(_pos: Vector2, _big: bool, _launched: bool) -> void:
		_strikes.append({"frame": Engine.get_physics_frames(), "stamp": _main.player.last_strike_ms,
			"step": _main.player.combo_step}))
	_snapshot_contract()
	await _early_and_held_input()
	await _exact_queue_boundary()
	await _queued_cancellation()
	_readout_ownership()
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated readability checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"): DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated readability directory")
	if _failures.is_empty():
		print("DEAD WAX COMBO READABILITY PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("COMBO READABILITY FAIL: " + failure)
	quit(1)

func _snapshot_contract() -> void:
	_check(Skip.STRIKE_COOLDOWN == 0.20 and Skip.STRIKE_BUFFER == 0.09 and Skip.COMBO_WINDOW == 0.65,
		"clarity retains the 200ms cooldown, final 90ms queue and separate .65s chain")
	var player: CharacterBody2D = _main.player
	for pair in [[0.20, "recover"], [0.09, "buffer"], [0.001, "buffer"], [0.0, "ready"], [-0.2, "ready"]]:
		player._strike_cd = pair[0]
		var snapshot: Dictionary = player.combo_snapshot()
		_check(snapshot.input_state == pair[1] and not snapshot.queued
			and is_equal_approx(snapshot.cooldown_remaining, maxf(pair[0], 0.0))
			and snapshot.cooldown_duration == 0.20, "snapshot truthfully distinguishes cooldown state " + str(pair[0]))
	player._strike_buffer = 0.05
	_check(player.combo_snapshot().input_state == "queued" and player.combo_snapshot().queued, "one accepted edge is explicitly queued")
	player.hooded = true
	_check(player.combo_snapshot().input_state == "blocked" and not player.combo_snapshot().queued, "Hood blocks the reported input state")
	player.hooded = false
	player.setting = true
	_check(player.combo_snapshot().input_state == "blocked", "Set blocks the reported input state")
	player.setting = false
	player._stagger = 0.1
	_check(player.combo_snapshot().input_state == "blocked", "stagger blocks the reported input state")
	player._stagger = 0.0
	player._strike_cd = 0.15
	var copy: Dictionary = player.combo_snapshot()
	copy.cooldown_remaining = 0.0
	copy.queued = false
	copy.input_state = "ready"
	_check(player._strike_cd == 0.15 and player._strike_buffer == 0.05, "snapshot edits cannot change gameplay cooldown or accepted input")
	player.cancel_pending_strike()

func _early_and_held_input() -> void:
	await _prepare()
	await _tap(KEY_J)
	_check(_main.player.combo_snapshot().input_state == "recover" and _main.combo_readout._input_hint.text == "RECOVERING",
		"an executed strike immediately reports recovery instead of inviting an impossible next hit")
	var count := _strikes.size()
	var rejected := _rejected
	var stamp: int = _main.player.last_strike_ms
	await _physics(1)
	await _tap(KEY_J)
	_check(_rejected == rejected + 1 and _strikes.size() == count and _main.player._strike_buffer == 0.0,
		"a fresh press before the final queue window is explicitly rejected once")
	_check(_main.player.last_strike_ms == stamp and _main.player.combo_step == 1,
		"an early press never advances the chain or opens the parry clock")
	_check(_main.combo_readout._early_t > 0 and _main.combo_readout._input_hint.text == "EARLY · WAIT",
		"Main presents an immediate early-press receipt during recovery")
	while _main.player._strike_cd > Skip.STRIKE_BUFFER: await _physics(1)
	await _frames(1)
	_check(_main.player.combo_snapshot().input_state == "buffer"
		and _main.combo_readout._input_hint.text == "EARLY · PRESS AGAIN", "the receipt updates when a new press can be accepted")
	await _physics(16)
	_check(_strikes.size() == count and _main.combo_readout._early_t == 0.0
		and _main.combo_readout._input_hint.text == "J / X · PRESS", "rejected input never executes later and its receipt expires to ready")
	await _prepare()
	count = _strikes.size()
	rejected = _rejected
	_key(KEY_J, true)
	await _physics(35)
	_key(KEY_J, false)
	_check(_strikes.size() == count + 1 and _rejected == rejected,
		"holding a strike generates neither repeated attacks nor repeated early receipts")

func _exact_queue_boundary() -> void:
	var tick := 1.0 / Engine.physics_ticks_per_second
	for overshoot in [0.002, 0.0]:
		await _prepare()
		await _tap(KEY_J)
		_main.player._strike_cd = Skip.STRIKE_BUFFER + tick + overshoot
		var count := _strikes.size()
		var rejected := _rejected
		var stamp: int = _main.player.last_strike_ms
		await _tap(KEY_J)
		if overshoot > 0.0:
			_check(_rejected == rejected + 1 and not _main.player.combo_snapshot().queued,
				"92ms remaining is still too early to enter the final 90ms queue")
			continue
		var snapshot: Dictionary = _main.player.combo_snapshot()
		_check(is_equal_approx(snapshot.cooldown_remaining, Skip.STRIKE_BUFFER)
			and snapshot.input_state == "queued" and snapshot.queued and _rejected == rejected,
			"a fresh edge at exactly 90ms remaining is accepted into the queue")
		_check(_strikes.size() == count and _main.player.last_strike_ms == stamp and snapshot.step == 1,
			"accepted input waits without prematurely striking or stamping a parry")
		await _frames(1)
		_check(_main.combo_readout._input_hint.text == "QUEUED · 2 SWEEP" and _main.combo_readout._early_t == 0.0,
			"queued status names the forthcoming Sweep and replaces an obsolete early receipt")
		await _physics(7)
		_check(_strikes.size() == count + 1 and _strikes.back().step == 2
			and _main.player.last_strike_ms > stamp, "the boundary queue survives the tick crossing zero and executes once")
		_check(_main.player.combo_snapshot().input_state == "recover" and not _main.player.combo_snapshot().queued,
			"execution consumes the queued edge and begins the next real cooldown")
		await _physics(15)
		_check(_strikes.size() == count + 1, "a consumed queue never repeats")

func _queued_cancellation() -> void:
	for action in [KEY_K, KEY_L]:
		await _prepare()
		await _tap(KEY_J)
		while _main.player._strike_cd > 0.055: await _physics(1)
		await _tap(KEY_J)
		_check(_main.player.combo_snapshot().queued, "quiet-verb fixture begins with an accepted queued edge")
		var count := _strikes.size()
		var rejected := _rejected
		_key(action, true)
		await _physics(2)
		_check(_main.player.combo_snapshot().input_state == "blocked" and not _main.player.combo_snapshot().queued
			and _main.combo_readout._input_hint.text == "WAIT", "Hood or Set immediately cancels the queue and shows blocked input")
		await _tap(KEY_J)
		_check(_rejected == rejected, "a blocked quiet verb does not misreport a timing rejection")
		_key(action, false)
		await _physics(16)
		_check(_strikes.size() == count and _main.player.combo_snapshot().input_state == "ready",
			"leaving the quiet verb cannot release its canceled queued attack")

func _readout_ownership() -> void:
	var view := Readout.new()
	view.size = Vector2(350, 104)
	view.practice_mode = true
	root.add_child(view)
	view.set_process(false)
	var supplied := {"step": 1, "remaining": 0.5, "window": 0.65, "label": "TAP",
		"input_state": "recover", "cooldown_remaining": 0.18, "cooldown_duration": 0.2, "queued": false}
	view.set_snapshot(supplied)
	view.set_process(false)
	_check(view._input_hint.text == "RECOVERING" and view._link_label.text == "LINK TIME",
		"the cooldown instruction and the link-time rail are separately labeled")
	var before: Dictionary = _main.player.combo_snapshot()
	var rail: Vector2 = view._window.size
	var copied: Dictionary = view._snapshot.duplicate(true)
	supplied.remaining = 0.0
	supplied.input_state = "ready"
	_check(view._snapshot == copied, "the readout copies its supplied snapshot")
	view._process(2.0)
	_check(view._window.size == rail and view._snapshot == copied and _main.player.combo_snapshot() == before,
		"presentation time cannot spend cooldown, queued input or the supplied link window")
	view.show_early_press()
	view.set_process(false)
	_check(view._input_hint.text == "EARLY · WAIT", "an explicit early receipt is immediately readable")
	paused = true
	var early: float = view._early_t
	view._process(1.0)
	_check(view._early_t == early and view._window.size == rail, "pause freezes the early receipt and link display")
	view.set_reduced_motion(true)
	_check(view._stamp == 0.0 and view._early_t == early and view._input_hint.text == "EARLY · WAIT",
		"reduced motion settles decoration while preserving meaningful timing advice")
	paused = false
	before = _main.player.combo_snapshot()
	view._process(Readout.EARLY_TIME + 0.01)
	_check(view._early_t == 0.0 and view._input_hint.text == "RECOVERING" and _main.player.combo_snapshot() == before,
		"the receipt expires under reduced motion without controlling gameplay timers")
	for state in ["ready", "buffer", "queued", "blocked"]:
		copied.input_state = state
		view.set_snapshot(copied)
		var expected: String = "QUEUED · 2 SWEEP" if state == "queued" else ("WAIT" if state == "blocked" else "J / X · PRESS")
		_check(view._input_hint.text == expected, "supplied " + state + " input has an unambiguous instruction")
	for step in [2, 3]:
		copied.step = step
		copied.label = "SWEEP" if step == 2 else "ACCENT"
		copied.input_state = "queued"
		view.set_snapshot(copied)
		var next_text := "QUEUED · 3 ACCENT" if step == 2 else "QUEUED · 1 TAP"
		_check(view._input_hint.text == next_text and view._headline.text == "%d  %s" % [step, copied.label],
			"the queued next beat stays distinct from the previously executed headline")
	_check(view.mouse_filter == Control.MOUSE_FILTER_IGNORE and view.focus_mode == Control.FOCUS_NONE,
		"the readout cannot capture gameplay or menu focus")
	view.free()

func _prepare() -> void:
	_release()
	_main._load_world_room(&"headshell")
	await _physics(3)
	_main.player.position = Vector2(300, 554)
	_main.player.velocity = Vector2.ZERO
	_main.player._strike_cd = 0.0
	_main.player._recover = 0.0
	_main.player._stagger = 0.0
	_main.player.cancel_pending_strike()
	await _physics(2)

func _release() -> void:
	for key in [KEY_J, KEY_K, KEY_L, KEY_SPACE]: _key(key, false)

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

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
