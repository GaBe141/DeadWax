extends SceneTree
## The first Looper guards its count and offers one complete punish window.
const MainScene := preload("res://scenes/main.tscn")
const Looper := preload("res://scripts/street_looper.gd")
const Dummy := preload("res://scripts/test_pressing.gd")
const Save := preload("res://scripts/save_store.gd")
const KEY := "high_street/street_looper"
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _parries := 0
var _shatters := 0
var _strikes: Array[bool] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-looper-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated Looper checkpoint")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	# This fixture jumps to earned-move mechanics; opening acquisition has its own suite.
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	await _physics(3)
	_main.player.struck.connect(func(_pos: Vector2, _big: bool, launched: bool) -> void: _strikes.append(launched))
	_count_and_opening()
	_parry_and_terminal_state()
	await _native_guard_and_recovery()
	await _native_defeat_and_restore()
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated Looper checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"): DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated Looper directory")
	if _failures.is_empty():
		print("DEAD WAX STREET LOOPER PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("STREET LOOPER FAIL: " + failure)
	quit(1)

func _count_and_opening() -> void:
	_check(Looper.HP_MAX == 5.0 and Looper.STRIKE_HIT_RANGE == 120.0 and Looper.PARRY_WINDOW_MS == 100,
		"authored guard preserves five HP, 120px strikes and the 100ms parry clock")
	var foe := _fixture()
	foe.on_player_strike(foe.position + Vector2(121, 0), true)
	_check(foe.hp == 5.0 and not foe._engaged, "an out-of-range accent cannot wake or damage the Looper")
	_check(foe.is_pogoable(), "the first quiet approach offers one ordinary opening")
	foe.on_player_strike(foe.position + Vector2(120, 0), false)
	_check(foe.hp == 4.0 and foe._engaged and foe.state == Looper.S.COUNTING,
		"the first confirmed hit damages once and commits the complete count")
	foe._process(0.2)
	var hp: float = foe.hp
	var resonance: float = foe.resonance
	var count_time: float = foe._t
	for big in [false, true, true]: foe.on_player_strike(foe.position, big)
	_check(foe.hp == hp and foe.resonance == resonance and foe._t == count_time and foe._count == 0,
		"ordinary and accent guard hits cannot damage, build resonance, or rewind the count")
	_check(not foe.is_pogoable() and foe.encounter_snapshot().phase == "guard", "guarding is truthfully closed to a pogo")
	var copy: Dictionary = foe.encounter_snapshot()
	copy.phase = "open"
	copy.count = 100
	_check(foe._count == 0 and foe.encounter_snapshot().phase == "guard", "encounter snapshots are read-only copies")
	var frozen: Dictionary = foe.encounter_snapshot()
	foe._process(0.0)
	foe._process(-1.0)
	_check(foe.encounter_snapshot() == frozen, "zero and negative deltas never advance a count")
	paused = true
	foe._process(5.0)
	_check(foe.encounter_snapshot() == frozen, "pause freezes the same authored count and guard cue")
	paused = false
	foe.set_reduced_motion(true)
	_check(foe.encounter_snapshot().blocked == 0.0 and foe.encounter_snapshot().phase == "guard",
		"reduced motion removes guard flash without hiding the guarded state")
	foe.reink(Color("eeeecc"), Color("222222"))
	_check(foe.ink == Color("eeeecc") and foe.stock == Color("222222"), "Looper cues accept reversed room ink and stock")
	_main.player.position = foe.position + Vector2(600, 0)
	foe._process(Looper.TICK_GAP - foe._t + 0.001)
	_check(foe.state == Looper.S.COUNTING and foe._count == 1, "moving out of range does not cancel the first tick")
	for beat in [2, 3, 4]:
		foe._process(Looper.TICK_GAP)
		_check(foe._count == beat and foe.state == (Looper.S.SWING if beat == 4 else Looper.S.COUNTING),
			"the count advances exactly to authored beat " + str(beat))
	foe.on_player_strike(foe.position, true)
	_check(foe.hp == hp and not foe.is_pogoable() and foe._t == 0.0, "the swing remains guarded through raw accents")
	foe._process(Looper.SWING_CONTACT_TIME)
	_check(foe.state == Looper.S.STAGGER and foe.is_pogoable()
		and foe.encounter_snapshot().opening_remaining == Looper.OPENING_DURATION,
		"a safely dodged swing offers the full one-second opening")
	for big in [false, false, true]:
		foe.on_player_strike(foe.position, big)
		foe._process(0.2)
	_check(is_equal_approx(foe.hp, 0.4) and foe.state == Looper.S.STAGGER,
		"the punish window accepts Tap, Sweep and Accent using existing damage values")
	_check(is_equal_approx(foe.encounter_snapshot().opening_remaining, 0.4), "punishing does not extend the opening timer")
	foe._process(0.401)
	_check(foe.state == Looper.S.ALERT and not foe.is_pogoable() and foe.encounter_snapshot().phase == "guard",
		"an engaged Looper waiting far away never advertises another free opener")
	foe._process(3.0)
	foe.on_player_strike(foe.position, true)
	_check(is_equal_approx(foe.hp, 0.4) and foe._engaged, "walking away and quieting down cannot renew the initial cheap hit")
	_main.player.position = foe.position + Vector2(90, 0)
	foe._process(0.01)
	_check(foe.state == Looper.S.COUNTING and foe._count == 0, "returning after a miss begins another complete count")
	foe.free()

func _parry_and_terminal_state() -> void:
	var foe := _fixture()
	foe._begin_count()
	_main.player._stagger = 0.0
	_main.player.last_strike_ms = Time.get_ticks_msec() - 95
	foe._resolve_swing(90)
	_check(_parries == 1 and foe.parry_count == 1 and foe.state == Looper.S.STAGGER
		and foe._t == 0.0 and is_equal_approx(foe.resonance, Dummy.RES_PARRY),
		"95ms parry keeps the inherited reward and opens a complete punish window")
	foe._begin_count()
	_main.player._stagger = 0.0
	_main.player.last_strike_ms = Time.get_ticks_msec() - 105
	var health: int = _main._health
	foe._resolve_swing(90)
	_check(_parries == 1 and _main._health == health - 1 and foe.state == Looper.S.STAGGER and foe._t == 0.0,
		"105ms misses the parry, takes one hit, and still offers the full opening")
	foe.reset_attempt()
	_check(foe.hp == 5.0 and foe.resonance == 0.0 and foe.parry_count == 0 and not foe._engaged,
		"reset restores every unfinished encounter value")
	foe.state = Looper.S.STAGGER
	for hit in range(5): foe.on_player_strike(foe.position, false)
	_check(_shatters == 1 and foe.state == Looper.S.DOWN and not foe.is_pogoable(), "five opening hits shatter exactly once")
	foe._process(10.0)
	foe.reset_attempt()
	foe.on_player_strike(foe.position, true)
	_check(_shatters == 1 and foe.state == Looper.S.DOWN and not foe.is_in_group("hears_strikes")
		and not foe.is_in_group("strikable"), "a shattered Looper never reforms or replays its outcome")
	foe.free()

func _native_guard_and_recovery() -> void:
	var foe: Node2D = await _prepare_street()
	_check(foe.get_script() == Looper and foe.is_in_group("reset_on_recovery"), "High Street uses the authored recovery-aware Looper")
	foe._begin_count()
	_main.player.position = Vector2(820, 250)
	_main.player.velocity = Vector2.ZERO
	await _physics(1)
	foe.position = _main.player.position + Vector2(90, 0)
	_main.player.velocity = Vector2.ZERO
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_check(not _strikes.back() and foe.hp == 5.0 and _main.player.velocity.y > -50,
		"an actual airborne strike cannot pogo or damage the guarded Looper")
	foe.hp = 2.0
	foe.resonance = 0.5
	_key(KEY_R, true)
	await _physics(2)
	_key(KEY_R, false)
	_check(foe.hp == 5.0 and foe.resonance == 0.0 and not foe._engaged and foe.state == Looper.S.CALM,
		"physical R resets an unfinished count and damage through Main")
	_check(not _main.encounters.has(KEY), "recovering an unfinished Looper stores no outcome")
	var exits := 0
	var returns := 0
	for child in _main.room.get_children():
		if child.is_in_group("room_exit"):
			if child.is_in_group("reverse_passage"):
				returns += 1
				_check(child.target_room == &"verse_warren_n" and child.is_locked(),
					"the new Warren return stays independently sealed during Looper recovery")
				continue
			exits += 1
			_check(child.required_refrain == -1, "High Street passage remains free of encounter permissions")
	_check(exits == 2 and returns == 1 and not (foe is PhysicsBody2D), "both original routes remain beside the new return and the Looper adds no collision barrier")
	_main._on_route_requested(&"practice_room", &"from_high_street")
	await _physics(4)
	_check(_main.world_room_id == &"practice_room" and not _main.encounters.has(KEY), "leaving High Street does not require defeating the Looper")

func _native_defeat_and_restore() -> void:
	var foe: Node2D = await _prepare_street()
	var progression: Dictionary = _main.progression.snapshot()
	foe.state = Looper.S.STAGGER
	for hit in range(5): foe.on_player_strike(foe.position, false)
	await _frames(3)
	_check(_main.encounters.get(KEY) == "shattered", "the live defeat uses the existing persistent encounter key")
	_check(_main.player.shine == 0 and _main.progression.snapshot() == progression,
		"defeating the Looper grants no Shine, knowledge, or Refrain")
	_main._respawn()
	foe._process(10.0)
	_check(foe.state == Looper.S.DOWN, "Main recovery preserves the resolved broken stand")
	_check(_main._persist_session(), "Main saves the resolved authored Looper")
	_main._return_to_title()
	await _frames(3)
	_main._continue_game()
	await _physics(4)
	_check(_persistent() == null and _main.encounters.get(KEY) == "shattered", "Continue silently removes the already resolved actor")
	_check(_main.player.shine == 0 and _main.progression.snapshot() == progression, "restoration does not replay rewards")
	_main._new_game(false)
	await _physics(3)
	foe = await _prepare_street()
	_check(foe.hp == 5.0 and not foe._engaged and not _main.encounters.has(KEY), "New Game gives the new pressing its initial Looper")

func _fixture() -> Node2D:
	var foe := Looper.new()
	foe.process_mode = Node.PROCESS_MODE_DISABLED
	foe.position = _main.player.position + Vector2(90, 0)
	root.add_child(foe)
	foe._player = _main.player
	foe.parried.connect(func() -> void: _parries += 1)
	foe.shattered.connect(func(_pos: Vector2) -> void: _shatters += 1)
	return foe

func _prepare_street() -> Node2D:
	_release()
	_main._load_world_room(&"high_street", &"from_horn_plaza")
	await _physics(3)
	var foe := _persistent() as Node2D
	foe.set_process(false)
	_main.player._strike_cd = 0.0
	_main.player._stagger = 0.0
	_main.player.air_density = 0.0
	_main.player.air_strikes_max = 0
	return foe

func _persistent() -> Node:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == &"street_looper": return child
	return null

func _release() -> void:
	for key in [KEY_J, KEY_R, KEY_K, KEY_L, KEY_SPACE]: _key(key, false)

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
