extends SceneTree
## Animation follows gameplay. Real inputs exercise visual transitions, while
## isolated checkpoints keep this suite away from a player's saved pressing.

const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const DummyScript := preload("res://scripts/test_pressing.gd")
const VoiceScript := preload("res://scripts/auditioner.gd")
const LooperScript := preload("res://scripts/street_looper.gd")
const HushScript := preload("res://scripts/hush.gd")
const TonearmScript := preload("res://scripts/tonearm.gd")
const BackcutterScript := preload("res://scripts/backcutter.gd")
const EchoTrialScript := preload("res://scripts/echo_trial.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _strike_count := 0
var _collider: CollisionShape2D
var _collider_transform: Transform2D
var _collider_size: Vector2
var _last_strike_pose: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-animation-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated animation directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	# This fixture jumps to earned-move mechanics; opening acquisition has its own suite.
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	await _physics(5)
	_main.player.struck.connect(_on_struck)
	for child in _main.player.get_children():
		if child is CollisionShape2D:
			_collider = child
	_check(_collider != null, "player retains its collision shape")
	if _collider != null:
		_collider_transform = _collider.transform
		_collider_size = _collider.shape.size
		_check(_collider_size == Vector2(34, 52), "animation keeps the authored 34 by 52 body")
	await _check_player_inputs()
	await _check_pause_and_recovery()
	await _check_enemy_clocks()
	await _check_contact_feedback()
	await _check_parry_feedback()
	await _check_feedback_lifecycle()
	await _check_launch_feedback()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	# Let the audio server release finite catch and hit cues after tree cleanup.
	await create_timer(0.15).timeout
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated animation checkpoints")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated animation directory")
	if _failures.is_empty():
		print("DEAD WAX SPRITE ANIMATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("SPRITE ANIMATION FAIL: " + failure)
	quit(1)

func _check_player_inputs() -> void:
	var player: CharacterBody2D = _main.player
	var idle: Dictionary = player._animation_pose()
	await _physics(8)
	_check(float(player._animation_pose().time) > float(idle.time), "idle impression clock advances during play")
	_check_shape("idle")
	var start := player.position
	_key(KEY_D, true)
	await _physics(12)
	var running: Dictionary = player._animation_pose()
	_check(player.position.x > start.x and player.velocity.x > 300.0, "run input still moves the physical player")
	_check(float(running.run) > 0.3 and not is_equal_approx(float(running.stride), float(idle.stride)), "running drives stride and weight in the pose")
	_check_shape("run")
	_key(KEY_D, false)
	await _physics(12)
	var before := _strike_count
	_key(KEY_J, true)
	await _physics(1)
	_check(_strike_count == before + 1, "strike gameplay signal fires on the first input physics frame")
	_check(float(player._animation_pose().strike) > 0.0, "strike pose begins with the gameplay strike")
	_check(float(_last_strike_pose.strike) > 0.0 and _last_strike_pose.strike_contact == &"miss"
		and is_zero_approx(float(_last_strike_pose.contact_pulse)), "the first input frame presents the completed miss receipt without a false impact")
	_check_shape("strike")
	_key(KEY_J, false)
	await _physics(28)
	_key(KEY_SPACE, true)
	await _physics(3)
	_check(not player.is_on_floor() and player.velocity.y < -100, "jump input still launches the body immediately")
	_check(float(player._animation_pose().air) > 0 and float(player._animation_pose().vertical) < 0, "rising pose follows actual airborne velocity")
	_check_shape("jump")
	var saw_fall := false
	var landed := false
	for frame in range(65):
		await _physics(1)
		saw_fall = saw_fall or (not player.is_on_floor() and player.velocity.y > 0 and float(player._animation_pose().vertical) > 0)
		if player.is_on_floor():
			landed = true
			break
	_key(KEY_SPACE, false)
	_check(saw_fall and landed, "air pose follows a full physical jump and landing")
	_check(float(player._animation_pose().land) > 0.0, "landing produces a visual compression impulse")
	_check_shape("landing")
	await _physics(20)
	_key(KEY_K, true)
	await _physics(14)
	_check(player.hooded and float(player._animation_pose().hood) > 0.7, "Hood input blends the visual hood into place")
	_check_shape("Hood")
	_key(KEY_K, false)
	await _physics(12)
	_key(KEY_L, true)
	await _physics(15)
	_check(player.setting and float(player._animation_pose().set) > 0.7, "Set input visibly kneels without changing the collision")
	_check_shape("Set")
	_key(KEY_L, false)
	await _physics(12)

func _check_pause_and_recovery() -> void:
	var player: CharacterBody2D = _main.player
	player.take_hit(player.position + Vector2(100, 0))
	await _physics(1)
	_check(float(player._animation_pose().hurt) > 0, "a real hit starts the hurt impression")
	_check_shape("hurt")
	_main._pause_game()
	var pose: Dictionary = player._animation_pose().duplicate(true)
	var physical := player.transform
	await _frames(24)
	_check(player._animation_pose() == pose and player.transform == physical, "pause freezes player animation and gameplay together")
	_main._resume_game()
	await _frames(3)
	_main._respawn()
	var reset: Dictionary = player._animation_pose()
	for key in ["time", "stride", "run", "air", "land", "impact", "launch", "strike", "hurt", "contact_pulse", "strike_hold", "parry", "queued"]:
		_check(is_zero_approx(float(reset[key])), "recovery clears player visual field " + key)
	_check(not bool(reset.big), "recovery clears the amplified-strike impression")
	_check(not bool(reset.strike_launched) and not bool(reset.strike_pogo), "recovery clears combat launch presentation")
	_check_shape("recovery")
	# Rendering interpolation itself must never move a body, resize a shape,
	# or change velocity. This checks a visual step with physics disabled.
	player.set_physics_process(false)
	var transform_before := player.transform
	var velocity_before := player.velocity
	player._process(0.07)
	_check(player.transform == transform_before and player.velocity == velocity_before, "visual updates never alter the player's transform or velocity")
	_check_shape("visual-only update")
	player.set_physics_process(true)

func _check_enemy_clocks() -> void:
	for configuration in [
		{"room": &"high_street", "entry": &"from_horn_plaza", "id": &"street_looper", "clock": "_print_time"},
		{"room": &"groove_yard", "entry": &"from_the_stalls", "id": &"yard_first_voice", "clock": "_print_time"},
		{"room": &"smoothed_floor", "entry": &"from_worn_gallery", "id": &"hush", "clock": "_hush_time"},
		{"room": &"the_arm", "entry": &"from_smoothed_floor", "id": &"tonearm", "clock": "_visual_time"},
	]:
		_main._load_world_room(configuration.room, configuration.entry)
		await _physics(5)
		var enemy := _persistent(configuration.id)
		_check(enemy != null, "animated encounter boots: " + String(configuration.id))
		if enemy == null:
			continue
		var clock_key := String(configuration.clock)
		_check(clock_key in enemy, "encounter owns a pausable animation clock: " + String(configuration.id))
		if not clock_key in enemy:
			continue
		var clock_before: float = enemy.get(clock_key)
		await _physics(8)
		_check(float(enemy.get(clock_key)) > clock_before, "encounter animation advances while playing: " + String(configuration.id))
		_check(enemy.scale == Vector2.ONE and is_zero_approx(enemy.rotation), "encounter drawing preserves gameplay transform: " + String(configuration.id))
		_main._pause_game()
		var frozen: float = enemy.get(clock_key)
		var physical := enemy.transform
		await _frames(20)
		_check(is_equal_approx(float(enemy.get(clock_key)), frozen) and enemy.transform == physical, "pause freezes encounter animation: " + String(configuration.id))
		_main._resume_game()
		await _frames(3)
		if enemy.is_in_group("chapter_boss"):
			_main._respawn()
			_check(is_zero_approx(float(enemy.get(clock_key))), "recovery resets unresolved boss animation: " + String(configuration.id))

func _check_contact_feedback() -> void:
	await _prepare_combat()
	var player: CharacterBody2D = _main.player
	var dummy := DummyScript.new()
	dummy.position = player.position + Vector2(100, 0)
	_main.room.add_child(dummy)
	dummy.set_process(false)
	var hold_times: Array[float] = []
	for beat in [1, 2, 3]:
		player._strike_cd = 0.0
		player._strike()
		var pose: Dictionary = player._animation_pose()
		_check(pose.combo_step == beat and pose.strike_contact == &"hit"
			and float(pose.contact_pulse) > 0.0 and float(pose.strike_hold) > 0.0,
			"Main confirms the hit and its drawn impact synchronously on beat " + str(beat))
		_check(dummy.hp == DummyScript.HP_MAX - (float(beat) if beat < 3 else 4.0),
			"the impact impression leaves ordinary damage truthful on beat " + str(beat))
		_check(not bool(pose.strike_launched) and not bool(pose.strike_pogo), "a planted hit carries no airborne recoil on beat " + str(beat))
		hold_times.append(float(pose.strike_hold))
		var before := _combat_snapshot(player)
		var strike_before := float(pose.strike)
		player._process(0.015)
		_check(is_equal_approx(float(player._animation_pose().strike), strike_before),
			"a confirmed impact briefly holds only its drawn strike pose on beat " + str(beat))
		_check(_combat_snapshot(player) == before, "impact drawing cannot spend combat clocks or alter movement on beat " + str(beat))
		_check_shape("confirmed hit " + str(beat))
		player._process(0.1)
		_check(is_zero_approx(float(player._animation_pose().strike_hold)) and float(player._animation_pose().strike) < strike_before,
			"the hit pose resumes its recovery after the presentation hold on beat " + str(beat))
	_check(hold_times[2] > hold_times[0] and is_equal_approx(hold_times[0], hold_times[1]),
		"a confirmed Accent holds its impact slightly longer than Tap and Sweep")
	var strike_face := float(player._animation_pose().strike_face)
	player.facing = -strike_face
	player._process(0.01)
	_check(player._animation_pose().strike_face == strike_face and player.executed_strike_facing() == strike_face,
		"turning during follow-through retains the executed strike's face in drawing and combat")
	dummy.position = player.position + Vector2(300, 0)
	player._strike_cd = 0.0
	player._strike()
	var missed: Dictionary = player._animation_pose()
	_check(missed.strike_contact == &"miss" and float(missed.strike) > 0.0
		and is_zero_approx(float(missed.contact_pulse)) and is_zero_approx(float(missed.strike_hold)),
		"a real miss recovers without replaying the previous hit's pulse or hold")

	await _prepare_combat()
	player = _main.player
	var guard := LooperScript.new()
	guard.position = player.position + Vector2(100, 0)
	_main.room.add_child(guard)
	guard.set_process(false)
	guard._engaged = true
	guard.state = LooperScript.S.COUNTING
	guard._t = 0.3
	player._strike()
	var blocked: Dictionary = player._animation_pose()
	_check(blocked.strike_contact == &"guard" and float(blocked.contact_pulse) > 0.0
		and is_zero_approx(float(blocked.strike_hold)), "a real guarded strike has its deflection pulse without a hit hold")
	_check(guard.hp == LooperScript.HP_MAX and guard._t == 0.3 and player.combo_step == 0,
		"a drawn deflection preserves guarded health, count and confirmed-chain rules")
	var guarded_before := _combat_snapshot(player)
	var guard_pose := float(blocked.strike)
	player._process(0.015)
	_check(float(player._animation_pose().strike) < guard_pose and _combat_snapshot(player) == guarded_before,
		"a guarded stroke immediately draws recovery without changing combat")
	_check_shape("guarded strike")

func _check_parry_feedback() -> void:
	for configuration in [
		{"name": "Auditioner", "script": VoiceScript, "reach": true},
		{"name": "Test Pressing", "script": DummyScript},
		{"name": "HUSH", "script": HushScript},
		{"name": "Street Looper", "script": LooperScript},
		{"name": "Tonearm", "script": TonearmScript, "tonearm": true},
		{"name": "Palace Backcutter", "script": BackcutterScript, "backcutter": true},
		{"name": "Echo Trial voice", "script": EchoTrialScript.EchoVoice, "reach": true},
		{"name": "Echo Trial pressing", "script": EchoTrialScript.EchoPressing},
	]:
		await _prepare_combat()
		var player: CharacterBody2D = _main.player
		var actor: Node2D = configuration.script.new()
		actor.position = player.position + Vector2(100, 0)
		_main.room.add_child(actor)
		actor.set_process(false)
		actor.set_physics_process(false)
		actor._player = player
		actor._face = -1.0
		if configuration.get("tonearm", false):
			actor._engaged = true
			actor.state = TonearmScript.S.SWEEP
		elif configuration.get("backcutter", false):
			actor._phase = &"swing"
			actor.state = DummyScript.S.SWING
		player._strike()
		var before := _combat_snapshot(player)
		if configuration.get("tonearm", false): actor._resolve_sweep(Time.get_ticks_msec())
		elif configuration.get("reach", false): actor._resolve_reach(100.0)
		else: actor._resolve_swing(100.0)
		var caught: Dictionary = player._animation_pose()
		var label := String(configuration.name)
		_check(float(caught.parry) > 0.0 and caught.parry_face == 1.0,
			label + " sends an immediate successful-catch pose toward its real origin")
		_check(is_zero_approx(float(caught.strike)) and is_zero_approx(float(caught.contact_pulse))
			and is_zero_approx(float(caught.strike_hold)) and not bool(caught.big),
			label + " catch takes visual priority over the outgoing stroke")
		_check(_combat_snapshot(player) == before, label + " catch presentation does not change Skip's physical or combat state")
		_check_shape(label + " parry")
		if not configuration.get("reach", false) and not configuration.get("tonearm", false):
			_check(actor.parry_count == 1, label + " still resolves exactly one actual parry")
		player.facing = -1.0
		player._process(0.02)
		_check(player._animation_pose().parry_face == 1.0, label + " catch keeps its attacker direction after Skip turns")
		player.present_parry(player.global_position + Vector2(-100, 0))
		_check(player._animation_pose().parry_face == -1.0, label + " can present a fresh catch from the opposite side")
		_check(_combat_snapshot(player) == before, label + " explicit visual catch never opens or rewrites the parry clock")
		player._strike_cd = 0.0
		actor.position = player.position + Vector2(300, 0)
		player._strike()
		_check(is_zero_approx(float(player._animation_pose().parry)) and float(player._animation_pose().strike) > 0.0,
			label + " next attack replaces a stale successful-catch pose")

func _check_feedback_lifecycle() -> void:
	await _prepare_combat()
	var player: CharacterBody2D = _main.player
	var dummy := DummyScript.new()
	dummy.position = player.position + Vector2(100, 0)
	_main.room.add_child(dummy)
	dummy.set_process(false)
	player._strike()
	player.set_process(true)
	player.set_physics_process(true)
	_main._pause_game()
	var frozen: Dictionary = player._animation_pose().duplicate(true)
	var frozen_body := _combat_snapshot(player)
	await _frames(16)
	_check(float(frozen.contact_pulse) > 0.0 and float(frozen.strike_hold) > 0.0,
		"pause fixture contains an active confirmed-contact impression")
	_check(player._animation_pose() == frozen and _combat_snapshot(player) == frozen_body,
		"pause freezes contact pulses and the drawn hold alongside the physical player")
	_main._resume_game()
	player.set_process(false)
	player.set_physics_process(false)
	player._strike_buffer = 0.04
	_check(player._animation_pose().queued == 1.0, "a queued-input pose truthfully reads an accepted pending edge")
	var queued_stamp: int = player.last_strike_ms
	player._process(0.05)
	_check(player._strike_buffer == 0.04 and player.last_strike_ms == queued_stamp,
		"drawing a pending edge cannot consume it or prematurely stamp an executed strike")
	player.cancel_pending_strike()
	_check(player._animation_pose().queued == 0.0, "cancelling the accepted edge immediately clears its drawn cue")
	player.present_parry(player.position + Vector2(100, 0))
	var frozen_parry: Dictionary = player._animation_pose().duplicate(true)
	player.set_process(true)
	_main._pause_game()
	await _frames(16)
	_check(player._animation_pose() == frozen_parry, "pause also freezes a successful-catch pose")
	_main._resume_game()
	player.set_process(false)
	var stamp_before: int = player.last_strike_ms
	var strike_face_before: float = player.last_strike_facing
	var cooldown_before: float = player._strike_cd
	player.take_hit(player.position + Vector2(100, 0))
	var hurt: Dictionary = player._animation_pose()
	_check(float(hurt.hurt) == 1.0 and is_zero_approx(float(hurt.strike)) and is_zero_approx(float(hurt.parry))
		and is_zero_approx(float(hurt.contact_pulse)) and is_zero_approx(float(hurt.strike_hold)),
		"damage immediately replaces attack and catch impressions with its actual hit reaction")
	_check(player.last_strike_ms == stamp_before and player.last_strike_facing == strike_face_before and player._strike_cd == cooldown_before,
		"damage presentation leaves the executed strike clock, face and cooldown intact")
	_check_shape("interrupted combat")
	player._stagger = 0.0
	player._strike_cd = 0.0
	player._strike()
	var interrupted: Dictionary = player._animation_pose()
	_check(float(interrupted.strike) > 0.0 and float(interrupted.contact_pulse) > 0.0 and float(interrupted.strike_hold) > 0.0,
		"the interrupted-hit fixture contains a fresh stroke, contact pulse and draw hold")
	stamp_before = player.last_strike_ms
	strike_face_before = player.last_strike_facing
	cooldown_before = player._strike_cd
	player.take_hit(player.position + Vector2(-100, 0))
	hurt = player._animation_pose()
	_check(float(hurt.hurt) == 1.0 and is_zero_approx(float(hurt.strike)) and is_zero_approx(float(hurt.contact_pulse))
		and is_zero_approx(float(hurt.strike_hold)) and not bool(hurt.strike_launched) and not bool(hurt.strike_pogo),
		"a fresh damage event interrupts all active strike and contact impressions")
	_check(player.last_strike_ms == stamp_before and player.last_strike_facing == strike_face_before and player._strike_cd == cooldown_before,
		"interrupting a confirmed impact still retains its executed combat clock and cooldown")
	player._stagger = 0.0
	player._strike_cd = 0.0
	player._strike()
	player.present_parry(player.position + Vector2(-100, 0))
	player._strike_buffer = 0.04
	_main._respawn()
	_check_feedback_settled(player, "recovery")
	player._strike()
	player.present_parry(player.position + Vector2(100, 0))
	_main._load_world_room(&"horn_plaza")
	_check_feedback_settled(player, "room passage")
	_check_shape("passage after combat")
	player.set_process(true)
	player.set_physics_process(true)
	await _physics(3)

func _check_launch_feedback() -> void:
	for kind in ["pogo", "gather"]:
		await _prepare_combat()
		var player: CharacterBody2D = _main.player
		player.position = Vector2(650, 250)
		player.set_physics_process(true)
		await _physics(1)
		player.set_physics_process(false)
		_check(not player.is_on_floor(), kind + " fixture starts physically airborne")
		if kind == "pogo":
			var dummy := DummyScript.new()
			dummy.position = player.position + Vector2(100, 0)
			_main.room.add_child(dummy)
			dummy.set_process(false)
		else:
			_main.progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
			player.refill_air_strikes()
		player.velocity = Vector2(80, -100)
		var breaths_before: int = player.air_strikes_left
		player._strike()
		var pose: Dictionary = player._animation_pose()
		_check(bool(pose.strike_launched) and bool(pose.strike_pogo) == (kind == "pogo"),
			kind + " has the correct launch impression and only actual foe recoil is marked Pogo")
		_check(player.velocity.y < -600 and player.air_strikes_left == (player.air_strike_capacity() if kind == "pogo" else breaths_before - 1),
			kind + " retains its original upward launch and breath rule")
		_check(pose.strike_contact == (&"hit" if kind == "pogo" else &"miss"),
			kind + " retains Main's actual combat-contact receipt")
		var before := _combat_snapshot(player)
		player._process(0.06)
		_check(_combat_snapshot(player) == before, kind + " recoil drawing never applies another launch impulse")
		_check_shape(kind + " recoil")
		player.reset_animation()
		_check_feedback_settled(player, kind + " reset")
	_restore_player_processing()

func _restore_player_processing() -> void:
	_main.player.set_process(true)
	_main.player.set_physics_process(true)

func _prepare_combat() -> void:
	_release_inputs()
	_restore_player_processing()
	_main.progression.reset()
	_main._load_world_room(&"headshell")
	await _physics(3)
	for actor in get_nodes_in_group("hears_strikes"):
		if _main.room.is_ancestor_of(actor):
			actor.set_process(false)
			actor.set_physics_process(false)
	var player: CharacterBody2D = _main.player
	player.position = Vector2(300, 554)
	player.velocity = Vector2.ZERO
	player.facing = 1.0
	player.free_combo_practice = false
	player._strike_cd = 0.0
	player._recover = 0.0
	player._stagger = 0.0
	player.air_density = 0.0
	player.air_strikes_max = 0
	player.cancel_pending_strike()
	player.reset_animation()
	await _physics(4)
	player.set_process(false)
	player.set_physics_process(false)

func _combat_snapshot(player: CharacterBody2D) -> Dictionary:
	return {"transform": player.transform, "velocity": player.velocity,
		"stamp": player.last_strike_ms, "face": player.last_strike_facing,
		"cooldown": player._strike_cd, "buffer": player._strike_buffer,
		"recover": player._recover, "stagger": player._stagger,
		"combo": player.combo_step, "window": player.combo_remaining,
		"contact": player.last_strike_contact, "step": player.executed_strike_step,
		"breaths": player.air_strikes_left, "noise": player.noise,
		"health": _main._health}

func _check_feedback_settled(player: CharacterBody2D, context: String) -> void:
	var pose: Dictionary = player._animation_pose()
	for field in ["strike", "contact_pulse", "strike_hold", "parry", "hurt", "queued"]:
		_check(is_zero_approx(float(pose[field])), context + " settles " + field)
	_check(not bool(pose.big) and not bool(pose.strike_launched) and not bool(pose.strike_pogo),
		context + " clears stronger-hit and launch flags")

func _release_inputs() -> void:
	for code in [KEY_A, KEY_D, KEY_J, KEY_SPACE, KEY_K, KEY_L]: _key(code, false)

func _check_shape(state: String) -> void:
	var player: Node2D = _main.player
	_check(player.scale == Vector2.ONE and is_zero_approx(player.rotation), state + " preserves the gameplay node transform")
	if _collider != null:
		_check(_collider.transform == _collider_transform and _collider.shape.size == _collider_size, state + " preserves the collision shape and transform")

func _persistent(id: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id:
			return child
	return null

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _on_struck(_position: Vector2, _big: bool, _launched: bool) -> void:
	_strike_count += 1
	_last_strike_pose = _main.player._animation_pose().duplicate(true)

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
