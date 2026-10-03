extends SceneTree
## Real Main broadcasts connect authored combat receipts to finite sound and
## cached contact impressions. This fixture owns a private campaign checkpoint.

const MainScene := preload("res://scenes/main.tscn")
const Save := preload("res://scripts/save_store.gd")
const Audio := preload("res://scripts/audio_bank.gd")
const Wave := preload("res://scripts/strike_wave.gd")
const Pressing := preload("res://scripts/test_pressing.gd")
const Looper := preload("res://scripts/street_looper.gd")
const Tonearm := preload("res://scripts/tonearm.gd")
const CUES := ["strike_tap", "strike_sweep", "strike_accent", "strike_hit", "strike_finish", "strike_guard"]
const DURATIONS := [0.11, 0.15, 0.19, 0.10, 0.23, 0.065]

class VanishingVoice extends "res://scripts/auditioner.gd":
	func _down() -> void:
		super._down()
		queue_free()

var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	var original_effects := AudioServer.get_bus_effect_count(0)
	_directory = "user://deadwax-attack-feedback-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated attack-feedback fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	await _physics(3)
	_main.set_process(false)
	_main.player.set_process(false)
	_main.player.set_physics_process(false)
	_check_synthesis()
	await _check_finite_playback()
	await _check_empty_swing()
	await _check_connected_strokes()
	await _check_guard_and_mixed_contact()
	await _check_tonearm_impact()
	await _check_fatal_origin_and_pause()
	await _check_captured_direction()
	await _check_cinematic_readout()
	await _check_practice_readout()
	var stream_ids: Array[int] = []
	for cue in CUES: stream_ids.append(_main.audio._sounds[cue].get_instance_id())
	_main.audio.play("strike_finish", -8.0)
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.25, true).timeout
	var released := true
	for id in stream_ids: released = released and not is_instance_id_valid(id)
	_check(released, "teardown releases every cached strike stream after the mixer block")
	_check(get_nodes_in_group("audio_bank").is_empty() and AudioServer.get_bus_effect_count(0) == original_effects,
		"attack feedback leaves no audio bank or added master effect")
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated attack-feedback checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"): DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated attack-feedback directory")
	if _failures.is_empty():
		print("DEAD WAX ATTACK FEEDBACK PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("ATTACK FEEDBACK FAIL: " + failure)
	quit(1)

func _check_synthesis() -> void:
	var previous: Array[PackedByteArray] = []
	for index in CUES.size():
		var cue: String = CUES[index]
		var stream: AudioStreamWAV = _main.audio._sounds[cue]
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.mix_rate == Audio.RATE and not stream.stereo,
			cue + " is native 22050Hz mono PCM")
		_check(absf(stream.get_length() - float(DURATIONS[index])) <= 1.0 / Audio.RATE
			and stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, cue + " has a finite authored length")
		var peak := 0
		for frame in stream.data.size() / 2: peak = maxi(peak, absi(stream.data.decode_s16(frame * 2)))
		_check(peak > 1000 and peak < 32767, cue + " is audible without clipped samples")
		_check(stream.data.decode_s16(stream.data.size() - 2) == 0, cue + " finishes at a silent endpoint")
		_check(stream.data not in previous, cue + " has distinct attack or contact material")
		previous.append(stream.data)

func _check_finite_playback() -> void:
	var bank: Node = _main.audio
	var children := bank.get_child_count()
	for cue in CUES:
		var cached: int = bank._sounds[cue].get_instance_id()
		var index: int = bank._pool_i
		bank.play(cue, -9.0)
		var voice: AudioStreamPlayer = bank._pool[index]
		_check(voice.stream.get_instance_id() == cached and voice.playing and voice.process_mode != Node.PROCESS_MODE_ALWAYS,
			cue + " reuses its cached recording in the world SFX pool")
		voice.seek(voice.stream.get_length() - 0.015)
	await create_timer(0.25, true).timeout
	var finished := true
	for voice in bank._pool: finished = finished and not voice.playing
	_check(finished and bank._pool.size() == 10 and bank.get_child_count() == children,
		"finite strike cues finish without making extra audio players")
	var index_before: int = bank._pool_i
	await create_timer(0.08, true).timeout
	_check(bank._pool_i == index_before, "the bank schedules no repeated strike sounds")

func _check_empty_swing() -> void:
	await _prepare()
	var result := _strike()
	var wave: Node2D = result.wave
	_check(result.sounds == ["strike_tap"] and result.shake == 0.0,
		"an empty Tap produces only air and no impact shake")
	_check(wave.contact == &"miss" and wave.impacts.is_empty() and not wave.big and _main.player.combo_step == 0,
		"an empty campaign swing draws no target impact and banks no chain")

func _check_connected_strokes() -> void:
	await _prepare()
	var target := _actor(Pressing, Vector2(100, 0))
	for beat in [1, 2, 3]:
		var result := _strike()
		var wave: Node2D = result.wave
		var expected := [CUES[beat - 1], "strike_finish" if beat == 3 else "strike_hit"]
		_check(result.sounds == expected, "stroke %d plays its airy cue and one confirmed impact" % beat)
		_check(wave.combo_step == beat and wave.big == (beat == 3) and wave.contact == &"hit"
			and wave.impacts == [{"offset": Vector2(100, 0), "kind": &"hit"}],
			"stroke %d caches its real target rather than a gesture endpoint" % beat)
		_check(target.hp == 5.0 - (float(beat) if beat < 3 else 4.0), "third-hit payoff applies one 2HP impact")
		_check(result.shake == (5.0 if beat == 3 else 2.0), "the Accent's connected impact carries stronger shake")
		_main.player._physics_process(0.20 if beat < 3 else 0.32)
	# Losing contact on the actual Accent still leaves its visual gesture intact.
	await _prepare()
	target = _actor(Pressing, Vector2(100, 0))
	_strike()
	_main.player._physics_process(0.20)
	_strike()
	_main.player._physics_process(0.20)
	target.position = _main.player.position + Vector2(121, 0)
	var missed := _strike()
	_check(missed.sounds == ["strike_accent"] and missed.shake == 0.0
		and missed.wave.combo_step == 3 and missed.wave.big and missed.wave.impacts.is_empty(),
		"a missed Accent carries its gesture and airy sound without a false heavy impact")
	_check(_main.player.combo_step == 0 and target.hp == 3.0, "a missed Accent clears the chain and damages nothing")

func _check_guard_and_mixed_contact() -> void:
	await _prepare()
	var guard := _actor(Looper, Vector2(90, 0))
	guard._engaged = true
	guard.state = Looper.S.COUNTING
	guard._t = 0.3
	var blocked := _strike()
	_check(blocked.sounds == ["strike_tap", "strike_guard"] and blocked.shake == 0.0,
		"a protected Looper gives a dry guard sound instead of a wax impact")
	_check(blocked.wave.contact == &"guard" and blocked.wave.impacts == [{"offset": Vector2(90, 0), "kind": &"guard"}]
		and guard.hp == Looper.HP_MAX and guard._t == 0.3, "guard impression cannot damage or rewind the enemy")
	var target := _actor(Pressing, Vector2(-100, 0))
	var mixed := _strike()
	_check(mixed.sounds == ["strike_tap", "strike_hit"] and mixed.shake == 2.0,
		"mixed contacts produce one hit sound without a duplicate guard sound")
	_check(mixed.wave.contact == &"hit" and mixed.wave.impacts.size() == 2
		and mixed.wave.impacts.has({"offset": Vector2(90, 0), "kind": &"guard"})
		and mixed.wave.impacts.has({"offset": Vector2(-100, 0), "kind": &"hit"}),
		"mixed contacts keep separate real positions for both impressions")
	_check(target.hp == Pressing.HP_MAX - 1.0 and _main.player.combo_step == 1,
		"mixed contact advances only the confirmed hit and grants no guarded damage")

func _check_fatal_origin_and_pause() -> void:
	await _prepare()
	var target := _actor(VanishingVoice, Vector2(100, 13))
	target.hp = 0.1
	var result := _strike()
	var wave: Node2D = result.wave
	_check(result.sounds == ["strike_tap", "shatter", "strike_hit"] and wave.contact == &"hit"
		and wave.impacts == [{"offset": Vector2(100, 13), "kind": &"hit"}],
		"fatal contact keeps the target origin even when shattering queues it for removal")
	await _frames(2)
	_check(not is_instance_valid(target) and wave.impacts[0].offset == Vector2(100, 13),
		"the cached impact remains correct after the target leaves the tree")
	var age: float = wave._t
	var cached: Array = wave.impacts.duplicate(true)
	paused = true
	await _frames(3)
	wave._process(0.1)
	_check(wave._t == age and wave.impacts == cached, "tree pause freezes the contact impression and its cached origins")
	paused = false
	wave._process(0.04)
	_check(is_equal_approx(wave._t, age + 0.04) and wave.impacts == cached,
		"resuming advances only presentation age without resolving another hit")

func _check_tonearm_impact() -> void:
	await _prepare()
	var target := _actor(Tonearm, Vector2(100, 0))
	target._engaged = true
	target._go(Tonearm.S.RECOVERY)
	var result := _strike()
	_check(result.sounds == ["strike_tap", "strike_hit"] and target.hp == Tonearm.HP_MAX - 1.0,
		"an open Tonearm takes one hit with one impact sound and no duplicate thud")
	_check(result.wave.contact == &"hit" and target.outcome == "" and not target.is_pogoable(),
		"Tonearm contact preserves its single-hit opening and unresolved outcome")
	var guarded := _strike()
	_check(guarded.sounds == ["strike_sweep", "strike_guard"] and target.hp == Tonearm.HP_MAX - 1.0,
		"the consumed Tonearm opening gives a guard sound without another damaging impact")

func _check_cinematic_readout() -> void:
	await _prepare()
	_actor(Pressing, Vector2(100, 0))
	_strike()
	var view: Control = _main.combo_readout
	_check(view.cinematic_mode and not view.visible and _main.player.combo_step == 1,
		"a confirmed campaign hit keeps the combo readout hidden immediately")
	_main._on_strike_input_rejected()
	_check(view._early_t > 0.0 and not view.visible, "an early input receipt cannot reveal cinematic combo text")
	view._process(0.03)
	_check(not view.visible, "readout animation cannot reveal cinematic combo text")
	view.set_reduced_motion(true)
	_check(not view.visible, "reduced motion cannot reveal cinematic combo text")
	var original_ink: Color = view._ink
	var original_stock: Color = view._stock
	view.set_palette(Color("e8e0cc"), Color("26221e"))
	_check(not view.visible, "a palette refresh cannot reveal cinematic combo text")
	view.set_palette(original_ink, original_stock)
	view.set_reduced_motion(false)
	_main._process(0.01)
	_check(not view.visible and view.cinematic_mode, "Main's live snapshot refresh preserves the hidden campaign readout")

func _check_practice_readout() -> void:
	_main._return_to_title()
	var checkpoint := FileAccess.get_file_as_string(_directory + "/checkpoint.json")
	_main._start_practice()
	_main.player.set_physics_process(true)
	await _physics(4)
	_main.player.set_physics_process(false)
	_check(_main.practice_mode and _main.player.free_combo_practice
		and _main.combo_readout.practice_mode and not _main.combo_readout.cinematic_mode and _main.combo_readout.visible,
		"entering the real empty practice room restores its visible move guidance")
	for beat in [1, 2, 3]:
		var result := _strike()
		_check(result.wave.contact == &"miss" and result.wave.combo_step == beat and _main.player.combo_step == beat
			and _main.combo_readout.visible, "practice keeps the empty gesture on beat " + str(beat))
		if beat < 3: _main.player._physics_process(0.20)
	_check(FileAccess.get_file_as_string(_directory + "/checkpoint.json") == checkpoint,
		"free practice gestures leave the campaign checkpoint unchanged")

func _check_captured_direction() -> void:
	await _prepare()
	var player: CharacterBody2D = _main.player
	player.facing = -1.0
	var before_scale: Vector2 = player.scale
	var before_rotation: float = player.rotation
	var shape: CollisionShape2D = player.get_child(0)
	var before_shape: Transform2D = shape.transform
	var before_size: Vector2 = shape.shape.size
	var result := _strike()
	_check(player._animation_pose().strike_face == -1.0 and result.wave.facing == -1.0,
		"a strike captures the facing at the moment it executes")
	player.facing = 1.0
	player._process(0.03)
	_check(player._animation_pose().strike_face == -1.0 and result.wave.facing == -1.0,
		"turning cannot mirror an unfinished strike or its existing impression")
	_check(player.scale == before_scale and player.rotation == before_rotation
		and shape.transform == before_shape and shape.shape.size == before_size,
		"stronger attack poses preserve the gameplay node and collider")

func _prepare() -> void:
	paused = false
	_main._load_world_room(&"headshell")
	_main.player.set_physics_process(true)
	_main.player.position = Vector2(300, 554)
	_main.player.velocity = Vector2.ZERO
	_main.player._strike_cd = 0.0
	_main.player._recover = 0.0
	_main.player._stagger = 0.0
	_main.player.cancel_pending_strike()
	await _physics(3)
	_main.player.set_physics_process(false)
	_main._shake = 0.0

func _actor(script: Script, offset: Vector2) -> Node2D:
	var actor: Node2D = script.new()
	actor.position = _main.player.position + offset
	_main.room.add_child(actor)
	actor.set_process(false)
	actor.set_physics_process(false)
	return actor

func _strike() -> Dictionary:
	_main._shake = 0.0
	var bank: Node = _main.audio
	var index: int = bank._pool_i
	_main.player._strike()
	var sounds: Array[String] = []
	var at := index
	while at != bank._pool_i:
		var stream: AudioStream = bank._pool[at].stream
		for cue in bank._sounds:
			if bank._sounds[cue] == stream:
				sounds.append(String(cue))
				break
		at = (at + 1) % bank._pool.size()
	var wave: Node2D
	for child in _main.get_children():
		if child.get_script() == Wave: wave = child
	_check(wave != null, "Main creates a contact impression synchronously with the real strike")
	return {"sounds": sounds, "wave": wave, "shake": _main._shake}

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
