extends SceneTree
## The elite commits its directions before moving. Real input then has to
## turn toward the threat, while its rear and completed swings offer a punish.
## Checkpoints and every input edge belong to this disposable fixture.

const Backcutter := preload("res://scripts/backcutter.gd")
const Pressing := preload("res://scripts/test_pressing.gd")
const MainScene := preload("res://scenes/main.tscn")
const Save := preload("res://scripts/save_store.gd")
const Wave := preload("res://scripts/strike_wave.gd")

class PlayerFixture extends CharacterBody2D:
	var noise := 1.0
	var last_strike_ms := -1000
	var facing := 1.0
	var strike_face := 1.0
	var hits := 0
	func _ready() -> void:
		add_to_group("player")
	func executed_strike_facing() -> float:
		return strike_face
	func take_hit(_origin: Vector2) -> void:
		hits += 1

var _checks := 0
var _failures: Array[String] = []
var _world: Node2D
var _player: PlayerFixture
var _main: Node2D
var _directory := ""
var _parries := 0
var _shatters := 0

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_world = Node2D.new()
	root.add_child(_world)
	_player = PlayerFixture.new()
	_world.add_child(_player)
	await _frames(2)
	_check_directional_guard()
	_check_fixed_cross_up()
	_check_rear_interruptions()
	_check_parries_and_punish()
	_check_edges_and_time()
	_check_motion_and_terminal()
	_world.queue_free()
	await _frames(3)
	await _main_fixture()
	await _check_native_turning_strikes()
	await _check_native_parry()
	await _check_native_pogo()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15, true).timeout
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private cross-up checkpoints")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private cross-up fixture directory")
	if _failures.is_empty():
		print("DEAD WAX BACKCUTTER PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("BACKCUTTER FAIL: " + failure)
	quit(1)

func _foe(origin := Vector2(1050, 567)) -> Node2D:
	var foe := Backcutter.new()
	foe.position = origin
	foe.arena_bounds = Rect2(660, 200, 1240, 420)
	_world.add_child(foe)
	foe.set_process(false)
	foe.set_physics_process(false)
	foe._player = _player
	foe.parried.connect(func() -> void: _parries += 1)
	foe.shattered.connect(func(_pos: Vector2) -> void: _shatters += 1)
	_player.position = origin + Vector2(100, 17)
	_player.strike_face = -1.0
	_player.facing = -1.0
	_player.last_strike_ms = -1000
	return foe

func _check_directional_guard() -> void:
	var foe := _foe()
	_check(foe is Pressing and not (foe is PhysicsBody2D)
		and foe.get_child_count() == 0, "the elite inherits proven combat without a new collision barrier")
	_check(Backcutter.PARRY_WINDOW_MS == 100 and Backcutter.STRIKE_HIT_RANGE == 120.0
		and Backcutter.HP_MAX == 5.0 and Backcutter.OPENING_DURATION == 1.0,
		"the new opponent preserves hit reach, parry timing and inherited health")
	foe._begin_attack()
	var tell: Dictionary = foe.encounter_snapshot()
	_check(tell.phase == &"tell" and tell.mode == &"cross" and tell.face == 1.0,
		"the first encounter begins with a visible committed cross-up tell")
	var health: float = foe.hp
	var resonance: float = foe.resonance
	var progress: float = tell.progress
	_check(foe.on_player_strike(_player.position, true) == &"guard" and foe.hp == health
		and foe.resonance == resonance and foe.encounter_snapshot().progress == progress,
		"a correctly aimed frontal Accent guards without damage or timer rewind")
	_player.strike_face = 1.0
	_check(foe.on_player_strike(_player.position, true) == &"ignored" and foe.hp == health,
		"swinging away cannot contact the enemy through the player's back")
	_player.position = foe.position + Vector2(-65, 17)
	_player.strike_face = -1.0
	_check(foe.on_player_strike(_player.position, false) == &"ignored" and foe.hp == health,
		"crossing behind still requires turning the attack toward the target")
	_player.strike_face = 1.0
	_check(foe.on_player_strike(_player.position, false) == &"hit" and foe.hp == health - 1.0
		and foe.encounter_snapshot().phase == &"open" and foe.encounter_snapshot().opening_remaining == 1.0,
		"an aimed rear hit breaks the locked guard into a full punish window")
	_check(foe.on_player_strike(foe.position + Vector2(-121, 0), true) == &"ignored",
		"rear openings retain the ordinary 120px contact limit")
	var snapshot: Dictionary = foe.encounter_snapshot()
	snapshot.face = -snapshot.face
	snapshot.landing_world = Vector2.ZERO
	_check(foe.encounter_snapshot().face != snapshot.face
		and foe.encounter_snapshot().landing_world == tell.landing_world,
		"presentation snapshots cannot mutate attack directions or captured destinations")
	foe.free()

func _check_fixed_cross_up() -> void:
	for direction in [-1.0, 1.0]:
		var foe := _foe()
		_player.position = foe.position + Vector2(100 * direction, 17)
		foe._begin_attack()
		var tell: Dictionary = foe.encounter_snapshot()
		var start: Vector2 = foe.position
		var landing: Vector2 = tell.landing_world
		_check(tell.face == direction and tell.attack_face == -direction
			and is_equal_approx(landing.x, _player.position.x + 90.0 * direction)
			and is_equal_approx(landing.y, start.y), "cross-up %s captures an opposite-side destination and final attack direction" % direction)
		_player.position = start + Vector2(-400 * direction, -120)
		foe._physics_process(Backcutter.CROSS_TELL - 0.001)
		_check(foe.position == start and foe.encounter_snapshot().face == direction
			and foe.encounter_snapshot().landing_world == landing, "cross-up %s never tracks a player changing sides during the tell" % direction)
		foe._physics_process(0.0011)
		_check(foe.encounter_snapshot().phase == &"leap" and foe.position == start,
			"cross-up %s starts its real travel only after the complete tell" % direction)
		var hits_before := _player.hits
		var previous := start
		for step in range(1, 9):
			foe._physics_process(Backcutter.LEAP_DURATION / 8.0)
			var pose: Dictionary = foe.encounter_snapshot()
			_check(absf(foe.position.x - previous.x) <= absf(landing.x - start.x) / 8.0 + 0.01
				and foe.position.x >= minf(start.x, landing.x) - 0.01
				and foe.position.x <= maxf(start.x, landing.x) + 0.01,
				"cross-up %s step %d moves smoothly toward the fixed landing" % [direction, step])
			_check(pose.landing_world == landing and pose.attack_face == -direction
				and _player.hits == hits_before, "cross-up %s step %d neither homes nor hits in the air" % [direction, step])
			if step < 8:
				_check(foe.position.y < start.y and pose.face == direction,
					"cross-up %s step %d keeps a raised silhouette and captured takeoff guard" % [direction, step])
			previous = foe.position
		_check(foe.position.is_equal_approx(landing) and foe.encounter_snapshot().phase == &"landing"
			and foe.encounter_snapshot().face == -direction,
			"cross-up %s plants at the fixed destination and flips once toward its precommitted attack" % direction)
		_player.position = landing + Vector2(100 * direction, 17)
		foe._physics_process(Backcutter.LANDING_WINDUP - 0.001)
		_check(foe.position == landing and foe.encounter_snapshot().face == -direction
			and _player.hits == hits_before, "cross-up %s provides its full planted wind-up without homing or damage" % direction)
		foe._physics_process(0.0011)
		_check(foe.encounter_snapshot().phase == &"swing" and _player.hits == hits_before,
			"cross-up %s commits the final swing before contact" % direction)
		foe._physics_process(Backcutter.SWING_CONTACT_TIME)
		_check(_player.hits == hits_before and foe.encounter_snapshot().phase == &"open"
			and is_equal_approx(foe.encounter_snapshot().opening_remaining, 1.0),
			"cross-up %s misses a player on its final rear and gives a full punish" % direction)
		foe.free()

func _check_rear_interruptions() -> void:
	for phase in [&"tell", &"leap", &"landing", &"swing"]:
		var foe := _foe()
		foe._begin_attack()
		if phase != &"tell": foe._physics_process(Backcutter.CROSS_TELL)
		if phase == &"leap": foe._physics_process(Backcutter.LEAP_DURATION * 0.5)
		if phase in [&"landing", &"swing"]: foe._physics_process(Backcutter.LEAP_DURATION)
		if phase == &"swing": foe._physics_process(Backcutter.LANDING_WINDUP)
		var before: Dictionary = foe.encounter_snapshot()
		var landing: Vector2 = before.landing_world
		_player.position = foe.position + Vector2(-60 * before.face, 0)
		_player.strike_face = before.face
		var hits_before := _player.hits
		_check(foe.on_player_strike(_player.position, false) == &"hit" and foe.hp == 4.0,
			"a rear punish confirms ordinary damage during %s" % phase)
		if phase == &"leap":
			_check(foe.encounter_snapshot().phase == &"leap" and foe.encounter_snapshot().interrupted
				and foe.encounter_snapshot().landing_world == landing,
				"interrupting in the air breaks the guard while retaining the announced safe arc")
			foe._physics_process(Backcutter.LEAP_DURATION * 0.5)
			_check(foe.position.is_equal_approx(landing) and foe.encounter_snapshot().phase == &"open",
				"an interrupted leap grounds at its committed mark and skips the attack")
		_check(foe.encounter_snapshot().phase == &"open" and foe.encounter_snapshot().opening_remaining == 1.0
			and _player.hits == hits_before, "a %s rear interruption delivers one full safe punish window" % phase)
		foe.free()

func _check_parries_and_punish() -> void:
	for scenario in [&"hit", &"miss", &"parry", &"wrong_way", &"too_old", &"future"]:
		var foe := _foe()
		foe._begin_attack()
		foe._physics_process(Backcutter.CROSS_TELL)
		foe._physics_process(Backcutter.LEAP_DURATION)
		var final_face: float = foe.encounter_snapshot().attack_face
		_player.position = foe.position + Vector2(80 * final_face, 17)
		_player.strike_face = -final_face
		_player.facing = final_face
		if scenario == &"miss": _player.position.x += 500 * final_face
		if scenario == &"wrong_way": _player.strike_face = final_face
		_player.last_strike_ms = -1000
		if scenario in [&"parry", &"wrong_way"]: _player.last_strike_ms = Time.get_ticks_msec()
		if scenario == &"too_old": _player.last_strike_ms = Time.get_ticks_msec() - 101
		if scenario == &"future": _player.last_strike_ms = Time.get_ticks_msec() + 100
		var hits_before := _player.hits
		var parries_before := _parries
		foe._physics_process(Backcutter.LANDING_WINDUP)
		foe._physics_process(Backcutter.SWING_CONTACT_TIME)
		_check(_player.hits == hits_before + (0 if scenario in [&"miss", &"parry"] else 1)
			and _parries == parries_before + (1 if scenario == &"parry" else 0),
			"%s resolves only the committed front, a fresh directional strike and the 100ms clock" % scenario)
		_check(foe.encounter_snapshot().phase == &"open" and foe.is_pogoable() == (scenario != &"wrong_way")
			and is_equal_approx(foe.encounter_snapshot().opening_remaining, 1.0),
			"%s leaves the same complete opening while pogo eligibility respects aimed contact" % scenario)
		var health: float = foe.hp
		_player.position = foe.position + Vector2(-60, 0)
		_player.strike_face = 1.0
		_check(foe.on_player_strike(_player.position, false) == &"hit" and foe.hp == health - 1.0,
			"%s opening accepts an aimed punish from either side" % scenario)
		foe._physics_process(0.999)
		_check(foe.encounter_snapshot().phase == &"open"
			and foe.encounter_snapshot().opening_remaining > 0.0,
			"%s punishing cannot prematurely remove the final opening frame" % scenario)
		foe._physics_process(0.002)
		_check(foe.encounter_snapshot().phase == &"idle", "%s opening closes without extending on contact" % scenario)
		foe.free()

func _check_edges_and_time() -> void:
	for origin_x in [684.0, 720.0, 1000.0, 1500.0, 1840.0, 1876.0]:
		for side in [-1.0, 1.0]:
			var foe := _foe(Vector2(origin_x, 567))
			_player.position = foe.position + Vector2(100 * side, 17)
			foe._begin_attack()
			var committed: Dictionary = foe.encounter_snapshot()
			_check(committed.landing_world.x >= foe.arena_bounds.position.x + Backcutter.BOUND_MARGIN
				and committed.landing_world.x <= foe.arena_bounds.end.x - Backcutter.BOUND_MARGIN,
				"wall %s side %s never captures a landing outside the real floor bounds" % [origin_x, side])
			if committed.mode == &"front":
				_check(committed.landing_world == foe.position and committed.face == side
					and committed.attack_face == side,
					"wall %s side %s falls back to a readable stationary frontal attack" % [origin_x, side])
			else:
				_check((committed.landing_world.x - _player.position.x) * side > 0.0,
					"wall %s side %s only commits a genuine opposite-side landing" % [origin_x, side])
			foe.free()
	var foe := _foe()
	foe._begin_attack()
	var before: Dictionary = foe.encounter_snapshot()
	foe._physics_process(0.0)
	foe._physics_process(-10.0)
	_check(foe.encounter_snapshot() == before, "zero and negative delta cannot consume an attack tell")
	paused = true
	foe._physics_process(5.0)
	_check(foe.encounter_snapshot() == before, "pause freezes committed geometry and combat time even during direct stepping")
	paused = false
	var hits_before := _player.hits
	foe._physics_process(5.0)
	_check(foe.encounter_snapshot().phase == &"leap" and _player.hits == hits_before,
		"a long tell tick cannot skip travel, landing and strike warnings into immediate damage")
	foe._physics_process(5.0)
	_check(foe.encounter_snapshot().phase == &"landing" and _player.hits == hits_before,
		"a long travel tick plants the actor while retaining a fresh landing wind-up")
	foe._physics_process(5.0)
	_check(foe.encounter_snapshot().phase == &"swing" and _player.hits == hits_before,
		"a long wind-up tick still exposes the final swing before contact")
	foe.free()

func _check_motion_and_terminal() -> void:
	var foe := _foe()
	foe._begin_attack()
	foe.set_reduced_motion(true)
	foe.reink(Color("ecddbc"), Color("152a32"))
	_check(foe.reduced_motion and foe.ink == Color("ecddbc") and foe.stock == Color("152a32"),
		"the elite receives explicit room palettes and reduced-motion settings")
	foe._physics_process(Backcutter.CROSS_TELL)
	foe._physics_process(Backcutter.LEAP_DURATION / 2.0)
	_check(foe.encounter_snapshot().phase == &"leap" and foe.position.y < 567.0,
		"reduced motion preserves functional cross-up travel and attack tells")
	foe.reset_attempt()
	_check(foe.position == Vector2(1050, 567) and foe.hp == 5.0
		and foe.encounter_snapshot().phase == &"idle" and foe.resonance == 0.0,
		"resetting an unfinished leap returns its exact grounded home and stock health")
	foe._begin_attack()
	_check(foe.encounter_snapshot().mode == &"cross", "recovery restores the first readable cross-up rather than a stale alternation")
	_player.position = foe.position + Vector2(-60, 0)
	_player.strike_face = 1.0
	var shatters_before := _shatters
	for hit in range(3): foe.on_player_strike(_player.position, true)
	_check(foe.encounter_snapshot().phase == &"down" and _shatters == shatters_before + 1
		and not foe.is_pogoable() and not foe.is_in_group("hears_strikes") and not foe.is_in_group("strikable"),
		"three inherited two-point rear accents resolve once and retire combat immediately")
	foe._physics_process(20.0)
	foe.reset_attempt()
	_check(foe.encounter_snapshot().phase == &"down" and _shatters == shatters_before + 1
		and foe.on_player_strike(foe.position, true) == &"ignored",
		"a resolved elite never reforms or resets into another reward")
	foe.free()

func _main_fixture() -> void:
	_directory = "user://deadwax-backcutter-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated cross-up checkpoint fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._start_practice()
	await _physics(4)
	_main.room.arena.set_physics_process(false)
	_check(_main.practice_mode and _main.abilities.has_ability(&"pogo"),
		"native input exercises the real disposable practice moveset")

func _native_foe() -> Node2D:
	var foe := Backcutter.new()
	foe.position = Vector2(1280, 567)
	foe.arena_bounds = _main.room.arena.arena_bounds
	_main.room.add_child(foe)
	foe.set_process(false)
	foe.set_physics_process(false)
	foe._player = _main.player
	return foe

func _check_native_turning_strikes() -> void:
	var foe := _native_foe()
	await _place_player(foe.position + Vector2(-65, 17), 1.0)
	foe._begin_attack()
	# The enemy locks left. Actual jump and right movement cross its rear.
	_key(KEY_SPACE, true)
	_key(KEY_D, true)
	await _physics(1)
	_key(KEY_SPACE, false)
	await _physics(24)
	_key(KEY_D, false)
	_check(_main.player.position.x > foe.position.x and _main.player.position.y < 584.0,
		"ordinary physical jump and right movement can cross a locked enemy guard")
	await _place_player(foe.position + Vector2(65, 17), 1.0)
	var health: float = foe.hp
	_key(KEY_D, true)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_key(KEY_D, false)
	_check(foe.hp == health and _main.player.last_strike_contact == &"miss"
		and _main.player.executed_strike_facing() == 1.0,
		"an actual right-facing J after crossing the rear cannot strike backward")
	await _reset_strike()
	_key(KEY_A, true)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_key(KEY_A, false)
	_check(foe.hp == health - 1.0 and _main.player.last_strike_contact == &"hit"
		and _main.player.executed_strike_facing() == -1.0,
		"an actual left turn plus J confirms the rear punish through Main's broadcast")
	_key(KEY_D, true)
	await _physics(1)
	_key(KEY_D, false)
	_check(_main.player.facing == 1.0 and _main.player.executed_strike_facing() == -1.0,
		"a later live turn cannot rewrite the last executed strike direction")
	_main.player.reset_animation()
	_check(_main.player.executed_strike_facing() == -1.0,
		"resetting presentation never changes the gameplay direction paired with the last strike clock")
	foe.queue_free()
	await _frames(2)

func _check_native_pogo() -> void:
	var foe := _native_foe()
	await _place_player(foe.position + Vector2(-65, -40), -1.0, false)
	foe._begin_attack()
	# The guard faces left; Skip is airborne at its right rear.
	await _place_player(foe.position + Vector2(65, -40), 1.0, false)
	var health: float = foe.hp
	_key(KEY_D, true)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_key(KEY_D, false)
	_check(foe.hp == health and _main.player.last_strike_contact == &"miss"
		and _main.player.velocity.y >= 0.0,
		"an airborne strike aimed away grants neither contact nor a phantom pogo")
	await _place_player(foe.position + Vector2(65, -40), -1.0, false)
	_key(KEY_A, true)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_key(KEY_A, false)
	_check(foe.hp == health - 1.0 and _main.player.last_strike_contact == &"hit"
		and _main.player.velocity.y < -100.0,
		"an aimed airborne rear contact earns the same damage and real pogo rebound")
	foe.queue_free()
	await _frames(2)
	_check(_main.encounters.is_empty() and _main.economy.balance == 0 and _main.collection.snapshot().offcuts == 0
		and not FileAccess.file_exists(_main.save_path),
		"native elite drills add no story, Shine, Offcuts or campaign checkpoint")

func _check_native_parry() -> void:
	for correct_direction in [false, true]:
		var foe := _native_foe()
		await _place_player(foe.position + Vector2(100, 17), -1.0)
		foe._begin_attack()
		foe._physics_process(Backcutter.CROSS_TELL)
		foe._physics_process(Backcutter.LEAP_DURATION)
		var attack_face: float = foe.encounter_snapshot().attack_face
		await _place_player(foe.position + Vector2(80 * attack_face, 17),
			-attack_face if correct_direction else attack_face)
		foe._physics_process(Backcutter.LANDING_WINDUP)
		var health: int = _main._health
		var turn_key := KEY_D if correct_direction else KEY_A
		_key(turn_key, true)
		_key(KEY_J, true)
		await _physics(1)
		_key(KEY_J, false)
		_key(turn_key, false)
		var executed_face: float = _main.player.executed_strike_facing()
		# Live orientation is deliberately the opposite of that real J. The
		# enemy must use the executed stroke, not a cosmetic later direction.
		_main.player.facing = -executed_face
		foe._physics_process(Backcutter.SWING_CONTACT_TIME)
		_check(_main._health == health - (0 if correct_direction else 1)
			and foe.parry_count == (1 if correct_direction else 0)
			and foe.encounter_snapshot().phase == &"open",
			"native %s J uses captured attack direction for the landed cross-up's parry" % ("aimed" if correct_direction else "wrong-way"))
		foe.queue_free()
		await _frames(2)

func _place_player(pos: Vector2, face: float, grounded := true) -> void:
	_release_inputs()
	_main.player.position = pos
	_main.player.velocity = Vector2.ZERO
	_main.player.facing = face
	await _reset_strike()
	if grounded: await _physics(3)

func _reset_strike() -> void:
	_main.player._strike_cd = 0.0
	_main.player._recover = 0.0
	_main.player._stagger = 0.0
	_main.player.cancel_pending_strike()
	await _frames(1)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _release_inputs() -> void:
	for code in [KEY_A, KEY_D, KEY_J, KEY_SPACE]: _key(code, false)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
