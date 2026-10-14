extends SceneTree
## Skip's gait: the pure sampler behind the stride, the lean, the skid, the
## jump and the landing, and the two drawing blends Main's player feeds it.
## Drawing never moves the body; these checks read pose values only.
const MainScene := preload("res://scenes/main.tscn")
const Gait := preload("res://scripts/press_skip_gait.gd")
const Press := preload("res://scripts/press.gd")
const Save := preload("res://scripts/save_store.gd")
const Abilities := preload("res://scripts/abilities_state.gd")

class ErrorLog extends Logger:
	var script_errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			script_errors.append("%s:%d %s" % [file, line, rationale if not rationale.is_empty() else code])
	func _log_message(_message: String, _error: bool) -> void:
		pass

class Canvas extends Node2D:
	var kind := ""
	var pose := {}
	var draws := 0
	func _draw() -> void:
		draws += 1
		match kind:
			"skip":
				Press.draw_skip(self, pose, {"ink": Color(0.13, 0.12, 0.11), "body": Color(0.62, 0.60, 0.63),
					"pale": Color(0.92, 0.90, 0.85), "pink": Press.PINK, "hood": Color(0.55, 0.52, 0.58), "warm_thread": false})
			"hound":
				Press.draw_hound(self, pose, Color("e3cfaa"), Color("254b4e"))
			"auditioner":
				Press.draw_auditioner(self, pose, Color(0.15, 0.13, 0.14), Color(0.24, 0.21, 0.26), Color(0.92, 0.90, 0.86), Press.PINK, Color(0.55, 0.52, 0.58), Color(0.96, 0.80, 0.42))

var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _log := ErrorLog.new()

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	OS.add_logger(_log)
	_directory = "user://deadwax-locomotion-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private checkpoint directory")
	_check_sampler()
	await _check_drawing()
	await _boot()
	_main._new_game(false)
	await _physics(4)
	await _check_player_blends()
	await _close()
	_check(_log.script_errors.is_empty(), "no script errors while the figures move: " + "; ".join(_log.script_errors))
	OS.remove_logger(_log)
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove isolated checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated directory")
	if _failures.is_empty():
		print("DEAD WAX LOCOMOTION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("LOCOMOTION FAIL: " + failure)
	quit(1)

# -- the pure gait -----------------------------------------------------------------

func _pose(over: Dictionary) -> Dictionary:
	var pose := {"stride": 0.0, "run": 0.0, "face": 1.0, "air": 0.0, "vertical": 0.0, "launch": 0.0,
		"land": 0.0, "impact": 0.0, "accel": 0.0, "skid": 0.0, "set": 0.0}
	for key in over: pose[key] = over[key]
	return pose

func _check_sampler() -> void:
	var still := Gait.sample(_pose({}))
	_check(is_zero_approx(float(still.bob)) and is_zero_approx(float(still.lean)) and Vector2(still.stretch).is_zero_approx()
		and is_zero_approx(float(still.arm)), "standing still, nothing leans, bobs, stretches or swings")
	for foot in still.feet:
		_check(is_equal_approx(Vector2(foot).y, Gait.SOLE), "a standing foot rests on the sole")
	_check(Gait.sample(_pose({"stride": 1.3, "run": 0.7})) == Gait.sample(_pose({"stride": 1.3, "run": 0.7})), "the sampler is deterministic")
	# The run cycle: one foot always bears weight on the sole, the lifted foot
	# moves the way Skip faces, the body rises between plants, and the free
	# arm swings against the legs.
	for face: float in [1.0, -1.0]:
		var planted_always := true
		var forward_when_lifted := true
		var rose := false
		var both_up := false
		for sample in range(32):
			var stride := TAU * sample / 32.0
			var gait := Gait.sample(_pose({"stride": stride, "run": 1.0, "face": face}))
			var ahead := Gait.sample(_pose({"stride": stride + 0.05, "run": 1.0, "face": face}))
			var planted := 0
			for index in range(2):
				var foot: Vector2 = gait.feet[index]
				if absf(foot.y - Gait.SOLE) < 0.01:
					planted += 1
				elif foot.y < Gait.SOLE - 0.5:
					var later: Vector2 = ahead.feet[index]
					if (later.x - foot.x) * face <= 0.0:
						forward_when_lifted = false
			planted_always = planted_always and planted >= 1
			both_up = both_up or planted == 0
			rose = rose or float(gait.bob) < -2.0
		_check(planted_always and not both_up, "facing %d, one foot bears weight at every phase of the run" % int(face))
		_check(forward_when_lifted, "facing %d, a lifted foot swings forward, never moonwalks" % int(face))
		_check(rose, "facing %d, the body rises between plants" % int(face))
		var swung := Gait.sample(_pose({"stride": PI * 0.5, "run": 1.0, "face": face}))
		_check(float(swung.arm) > 0.9 and absf(Vector2(swung.hand).x - Vector2(swung.shoulder).x) > 4.0, "facing %d, the free arm swings at a run" % int(face))
		_check(float(swung.lean) * face > 0.05, "facing %d, a run leans into its direction" % int(face))
	var slow := Gait.sample(_pose({"stride": 1.0, "run": 0.2}))
	_check(is_zero_approx(float(slow.arm)), "a stroll keeps the hands in the coat")
	# Mirror: the swing of the feet reverses with the facing.
	var right := Gait.sample(_pose({"stride": 1.0, "run": 1.0, "face": 1.0}))
	var left := Gait.sample(_pose({"stride": 1.0, "run": 1.0, "face": -1.0}))
	var mirrored := true
	for index in range(2):
		var side := -1.0 if index == 0 else 1.0
		var swing_right: float = Vector2(right.feet[index]).x - side * Gait.STANCE_X
		var swing_left: float = Vector2(left.feet[index]).x - side * Gait.STANCE_X
		mirrored = mirrored and is_equal_approx(swing_right, -swing_left)
	_check(mirrored, "turning around mirrors the stride exactly")
	# Lean: acceleration leans forward, braking back, a skid against the slide.
	var pushing := Gait.sample(_pose({"run": 0.5, "accel": 1.0}))
	var braking := Gait.sample(_pose({"run": 0.5, "accel": -1.0}))
	_check(float(pushing.lean) > float(braking.lean) and float(braking.lean) < 0.0, "acceleration leans forward and braking leans back")
	var skid := Gait.sample(_pose({"run": 0.6, "stride": 1.2, "skid": 1.0, "face": 1.0}))
	_check(float(skid.lean) > 0.15 and is_zero_approx(float(skid.step)) and is_zero_approx(float(skid.arm)), "a skid leans against the slide, plants the stride and drops the arm")
	_check(Vector2(skid.feet[1]).x - Vector2(skid.feet[0]).x > 2.0 * Gait.STANCE_X + 8.0, "a skid spreads the feet")
	for foot in skid.feet:
		_check(is_equal_approx(Vector2(foot).y, Gait.SOLE), "a skidding foot stays on the ground")
	# The jump: take-off stretches tall, rising tucks the feet, falling drops
	# them to meet the ground, landing squashes and splays, then settles.
	var takeoff := Gait.sample(_pose({"launch": 0.5, "air": 0.5, "vertical": -0.8}))
	_check(Vector2(takeoff.stretch).y > 0.1 and Vector2(takeoff.stretch).x < 0.0, "take-off stretches the body tall")
	var rising := Gait.sample(_pose({"air": 1.0, "vertical": -1.0}))
	var falling := Gait.sample(_pose({"air": 1.0, "vertical": 1.0}))
	for index in range(2):
		_check(Vector2(rising.feet[index]).y < Gait.SOLE - 3.0, "rising tucks foot %d" % index)
		_check(Vector2(falling.feet[index]).y > Vector2(rising.feet[index]).y + 4.0, "falling drops foot %d to meet the ground" % index)
	_check(Vector2(rising.point_sway).y < -3.0 and float(falling.scarf.lift) > 5.0, "the point lifts on the way up and the scarf on the way down")
	var landing := Gait.sample(_pose({"land": 0.5, "impact": 1.0}))
	_check(Vector2(landing.stretch).y < -0.15 and Vector2(landing.stretch).x > 0.15, "a hard landing squashes the body")
	_check(absf(Vector2(landing.feet[1]).x - Vector2(landing.feet[0]).x) > 2.0 * Gait.STANCE_X + 6.0, "a hard landing splays the feet")
	var settling := Gait.sample(_pose({"land": 0.15, "impact": 1.0}))
	_check(Vector2(settling.stretch).y > 0.02, "the landing overshoots once on its way back up")
	var soft := Gait.sample(_pose({"land": 0.5, "impact": 0.25}))
	_check(absf(Vector2(soft.stretch).y) < absf(Vector2(landing.stretch).y) * 0.5, "a soft landing squashes less than a hard one")
	# Old poses without the new fields still sample.
	var legacy := Gait.sample({"stride": 2.0, "run": 1.0, "face": 1.0, "air": 0.0, "vertical": 0.0, "launch": 0.0, "land": 0.0, "impact": 0.0, "set": 0.0})
	_check(legacy.feet.size() == 2 and is_zero_approx(float(legacy.lean) - float(Gait.sample(_pose({"stride": 2.0, "run": 1.0})).lean)), "a pose without accel or skid samples as before")

# -- drawing -----------------------------------------------------------------------

func _check_drawing() -> void:
	var canvas := Canvas.new()
	root.add_child(canvas)
	var skip_base := {"time": 1.0, "stride": 0.0, "run": 0.0, "air": 0.0, "vertical": 0.0, "hood": 0.0, "set": 0.0, "face": 1.0,
		"land": 0.0, "impact": 0.0, "launch": 0.0, "strike": 0.0, "big": false, "combo_step": 1, "strike_face": 1.0,
		"strike_contact": &"miss", "strike_hold": 0.0, "contact_pulse": 0.0, "parry": 0.0, "parry_face": 1.0, "queued": 0.0,
		"strike_launched": false, "strike_pogo": false, "hurt": 0.0, "hit_direction": -1.0, "noise": 0.0, "flat": 0.0,
		"book": 0.0, "item": 0.0, "item_kind": &"", "item_detail": &"", "nod": 0.0, "listen": 0.0, "glow": 0.0, "idle": 0.0, "beat": -1.0,
		"accel": 0.0, "skid": 0.0}
	var variants: Array = [
		{}, {"stride": 1.7, "run": 1.0}, {"stride": 4.0, "run": 1.0, "face": -1.0, "accel": 0.8},
		{"skid": 1.0, "run": 0.7}, {"launch": 0.7, "air": 0.5, "vertical": -0.9}, {"air": 1.0, "vertical": 0.9},
		{"land": 0.6, "impact": 1.0}, {"hood": 1.0, "run": 1.0, "stride": 2.0}, {"set": 1.0},
		{"strike": 0.6, "combo_step": 3, "big": true, "strike_contact": &"hit", "run": 0.5, "stride": 1.0},
		{"hurt": 0.8, "run": 1.0, "stride": 2.0}, {"strike_pogo": true, "strike_launched": true, "strike": 0.5, "air": 1.0, "vertical": -0.5},
	]
	var before := _log.script_errors.size()
	for variant in variants:
		var pose := skip_base.duplicate()
		for key in variant: pose[key] = variant[key]
		canvas.kind = "skip"
		canvas.pose = pose
		canvas.queue_redraw()
		await _frames(2)
	for hound in [{"speed": 0.0, "gait": 0.0}, {"speed": 1.0, "gait": 1.4}, {"speed": 1.0, "gait": 3.9, "face": -1.0}, {"sit": 1.0, "wag": 1.0, "phase": "pet", "pet": 0.5}, {"phase": "startled", "time": 0.1}]:
		var pose := {"phase": "wander", "time": 0.0, "clock": 1.0, "gait": 0.0, "face": 1.0, "speed": 0.0, "sit": 0.0, "pet": 0.0, "wag": 0.0}
		for key in hound: pose[key] = hound[key]
		canvas.kind = "hound"
		canvas.pose = pose
		canvas.queue_redraw()
		await _frames(2)
	for voice in [{"phase": "calm"}, {"phase": "pursue", "stride": 1.0}, {"phase": "pursue", "stride": 2.6, "face": -1.0}, {"phase": "reach", "reach": 0.7}]:
		var pose := {"phase": "calm", "clock": 1.0, "stride": 0.0, "recoil": 0.0, "face": 1.0, "jitter": Vector2.ZERO, "state_time": 0.0,
			"reach": 0.0, "recover": 0.0, "leave": 0.0, "burst": 0.0, "held": false, "resonance": 0.0, "listening": 0.0, "hp": 3, "hp_total": 3}
		for key in voice: pose[key] = voice[key]
		canvas.kind = "auditioner"
		canvas.pose = pose
		canvas.queue_redraw()
		await _frames(2)
	_check(canvas.draws >= variants.size() + 9 and _log.script_errors.size() == before, "every gait, trot and pursuit pose draws without a script error")
	canvas.free()

# -- the player's blends -------------------------------------------------------------

func _check_player_blends() -> void:
	for id in Abilities.IDS: _main.abilities.unlock_ability(id)
	_main._load_world_room(&"horn_plaza")
	await _physics(4)
	_quiet_actors()
	await _stand(Vector2(400, 574))
	var player: CharacterBody2D = _main.player
	var transform_before := player.transform
	_key(KEY_D, true)
	# The blends smooth over wall-clock time, so the lean is read at its peak
	# over the first frames of the start rather than at one frame.
	var starting_lean := 0.0
	for frame in 8:
		await _physics(1)
		starting_lean = maxf(starting_lean, float(player._animation_pose().accel))
	_check(starting_lean > 0.25, "setting off leans forward: the pose reads the real acceleration (%.2f)" % starting_lean)
	await _physics(22)
	var cruising: Dictionary = player._animation_pose()
	_check(absf(float(cruising.accel)) < 0.2 and float(cruising.run) > 0.9, "a steady run settles the lean")
	_check(is_zero_approx(float(cruising.skid)), "running the way Skip faces is not a skid")
	_key(KEY_D, false)
	_key(KEY_A, true)
	await _physics(3)
	var turning: Dictionary = player._animation_pose()
	_check(float(turning.skid) > 0.3 and player.velocity.x > 0.0 and player.facing < 0.0, "a hard turn is a skid: still sliding right, already facing left")
	await _physics(40)
	var settled: Dictionary = player._animation_pose()
	_check(float(settled.skid) < 0.05 and float(settled.accel) < 0.3, "once Skip runs the new way the skid is over")
	_key(KEY_A, false)
	var stopping_lean := 0.0
	for frame in 8:
		await _physics(1)
		stopping_lean = minf(stopping_lean, float(player._animation_pose().accel))
	_check(stopping_lean < -0.2, "letting go leans back against the braking (%.2f)" % stopping_lean)
	await _physics(22)
	_check(absf(float(player._animation_pose().accel)) < 0.05, "standing still, the lean is gone")
	_check(player.scale == Vector2.ONE and is_zero_approx(player.rotation) and absf(player.transform.origin.y - transform_before.origin.y) < 1.0,
		"the gait never scales or rotates the gameplay node")
	# Recovery clears both blends like every other drawing field.
	_key(KEY_D, true)
	await _physics(3)
	_key(KEY_D, false)
	player.reset_animation()
	var reset: Dictionary = player._animation_pose()
	_check(is_zero_approx(float(reset.accel)) and is_zero_approx(float(reset.skid)), "recovery clears the lean and the skid")
	# Pause freezes them with everything else.
	_key(KEY_D, true)
	await _physics(3)
	var frozen: Dictionary = player._animation_pose()
	paused = true
	await _frames(4)
	_check(player._animation_pose() == frozen, "pause freezes the lean and the skid with the rest of the pose")
	paused = false
	_key(KEY_D, false)

# -- helpers ---------------------------------------------------------------------

func _quiet_actors() -> void:
	for actor in get_nodes_in_group("hears_strikes"):
		actor.set_process(false)
		actor.set_physics_process(false)

func _stand(at: Vector2) -> void:
	_release()
	_main.player.position = at
	_main.player.velocity = Vector2.ZERO
	await _physics(4)

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)

func _close() -> void:
	_release()
	_main.queue_free()
	await _frames(3)
	paused = false

func _release() -> void:
	for code in [KEY_D, KEY_A, KEY_SPACE, KEY_J, KEY_K, KEY_L, KEY_E]: _key(code, false)

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
