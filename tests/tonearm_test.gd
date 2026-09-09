extends SceneTree
## Deterministic keeper mechanics with the real Skip; no audio, disk, or waits
## for attack timers. Contact resolution receives the actual strike-clock epoch.

const Tonearm := preload("res://scripts/tonearm.gd")
const Skip := preload("res://scripts/skip.gd")
var _checks := 0
var _failures: Array[String] = []
var _player: CharacterBody2D
var _boss: Node2D
var _events := {"hit": 0, "parry": 0, "freed": 0, "shattered": 0, "bout": 0}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["lift", "set", "move_left", "move_right", "move_up", "move_down", "jump", "strike"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	_player = Skip.new()
	root.add_child(_player)
	_player.set_process(false)
	_player.set_physics_process(false)
	_player.took_hit.connect(func() -> void: _events.hit += 1)
	_new_boss()
	_check_dormant()
	_check_initiation()
	_check_count()
	_check_contact()
	_check_openings()
	_check_mercy()
	_check_force()
	_check_restore_and_reset()
	_check_pause()
	await _check_actual_player()
	_boss.free()
	_player.free()
	if _failures.is_empty():
		print("DEAD WAX TONEARM PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("TONEARM FAIL: " + failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func _new_boss() -> void:
	if is_instance_valid(_boss):
		_boss.free()
	_boss = Tonearm.new()
	root.add_child(_boss)
	_boss.set_process(false)
	_boss._player = _player
	_player.position = Vector2(-80.0, 0.0)
	_player.setting = false
	_player.noise = 0.0
	_player.last_strike_ms = -100000
	_player.velocity = Vector2.ZERO
	_player._stagger = 0.0
	for key in _events:
		_events[key] = 0
	_boss.parried.connect(func() -> void: _events.parry += 1)
	_boss.freed.connect(func(_pos: Vector2) -> void: _events.freed += 1)
	_boss.shattered.connect(func(_pos: Vector2) -> void: _events.shattered += 1)
	_boss.bout_won.connect(func() -> void: _events.bout += 1)

func _advance(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.00001:
		var step := minf(remaining, 0.05)
		_boss._process(step)
		remaining -= step

func _wait_for_answer() -> void:
	_advance(Tonearm.GESTURE_TIME + 0.2)
	_check(_boss.state == Tonearm.S.WAITING, "the upward gesture ends in a peaceful wait")

func _provoke() -> void:
	_wait_for_answer()
	_boss.on_player_strike(_player.position, false)
	_check(_boss.state == Tonearm.S.COUNTING, "a nearby first strike begins a count")

func _sweep(age: int, distance := 80.0) -> void:
	_boss._engaged = true
	_boss._face = -1.0
	_boss._go(Tonearm.S.SWEEP)
	_player.position = Vector2(-distance, 0.0)
	_player.last_strike_ms = 10000 - age
	_boss._resolve_sweep(10000)

func _check_dormant() -> void:
	_check(_boss.is_in_group("chapter_boss") and _boss.is_in_group("hears_strikes") and _boss.is_in_group("strikable"), "the keeper joins Main's combat and reset groups")
	_check(not _boss.is_pogoable(), "the untouched keeper never grants a pogo")
	_player.position = Vector2(-1000.0, 0.0)
	_player.noise = 1.0
	_advance(12.0)
	_check(_boss.state == Tonearm.S.DORMANT and not _boss._engaged, "far noise leaves it dormant")
	_boss.on_player_strike(_player.position, true)
	_check(not _boss._engaged, "far strikes never provoke the keeper")
	_player.position = Vector2(-80.0, 0.0)
	_advance(20.0)
	_check(_boss.state == Tonearm.S.WAITING and not _boss._engaged, "approach and sustained noise never begin an attack")
	_check(_boss._gestured and _events.hit == 0, "it points upward once without contact damage")
	_player.position = Vector2(-1000.0, 0.0)
	_advance(2.0)
	_player.position = Vector2(-80.0, 0.0)
	_advance(0.1)
	_check(_boss.state == Tonearm.S.WAITING, "returning does not repeat the gesture")

func _check_initiation() -> void:
	_new_boss()
	_boss.on_player_strike(_player.position, false)
	_check(_boss.state == Tonearm.S.GESTURE and _boss._engaged, "an immediate strike still lets the keeper point upward once")
	_check(_boss.hp == Tonearm.HP_MAX and _events.hit == 0, "the first strike initiates without invisible chip or retaliation")
	_advance(Tonearm.GESTURE_TIME + 0.05)
	_check(_boss.state == Tonearm.S.COUNTING, "the provoked gesture ends in a count")
	_boss.on_player_strike(_player.position, true)
	_check(_boss.hp == Tonearm.HP_MAX, "strikes during the windup do not chip health")

func _check_count() -> void:
	_new_boss()
	_provoke()
	for beat in range(1, 4):
		_advance(Tonearm.TICK_GAP + 0.001)
		_check(_boss._count == beat and _boss.state == Tonearm.S.COUNTING, "beat %d is visibly counted before the sweep" % beat)
	_check(_events.hit == 0 and not _boss.is_pogoable(), "three count marks cannot damage or open the keeper")
	_advance(Tonearm.TICK_GAP + 0.03)
	_check(_boss.state == Tonearm.S.SWEEP and _events.hit == 0, "the fourth beat begins a visible sweep before impact")
	_advance(Tonearm.SWEEP_TIME + 0.03)
	_check(_boss.state == Tonearm.S.RECOVERY and _events.hit == 1, "a single nearby hit lands at sweep completion")
	_boss._resolve_sweep(10000)
	_check(_events.hit == 1, "re-resolving the same sweep cannot duplicate contact damage")

func _check_contact() -> void:
	for age in [0, 1, 99, 100]:
		_new_boss()
		_sweep(age)
		_check(_events.parry == 1 and _events.hit == 0 and _boss.state == Tonearm.S.STAGGER, "%dms strike catches the sweep" % age)
		_check(_boss.hp == Tonearm.HP_MAX, "a parry opens rather than also chips health")
	for age in [-1, 101, 1000]:
		_new_boss()
		_sweep(age)
		_check(_events.parry == 0 and _events.hit == 1, "%dms strike is outside the inclusive 100ms parry window" % age)
	_new_boss()
	_sweep(1000, Tonearm.CONTACT_RANGE)
	_check(_events.hit == 1, "the marked reach boundary is contact")
	_new_boss()
	_sweep(0, Tonearm.CONTACT_RANGE + 0.01)
	_check(_events.hit == 0 and _events.parry == 0, "outside the 130px reach there is neither damage nor a phantom parry")
	_new_boss()
	_sweep(1000, -80.0)
	_check(_events.hit == 0, "crossing behind the committed face dodges the sweep")
	_new_boss()
	_boss._engaged = true
	_boss._go(Tonearm.S.SWEEP)
	_player.position = Vector2(0.0, -Tonearm.CONTACT_RANGE - 1.0)
	_boss._resolve_sweep(10000)
	_check(_events.hit == 0, "jumping above the tip avoids the monumental beam's impression")

func _check_openings() -> void:
	_new_boss()
	_provoke()
	_boss.on_player_strike(_player.position, true)
	_check(_boss.hp == Tonearm.HP_MAX, "the closed cartridge rejects big strikes")
	_sweep(1000, Tonearm.CONTACT_RANGE + 10.0)
	_check(_boss.is_pogoable(), "a missed sweep gives a vulnerable grounded tip")
	_boss.on_player_strike(Vector2(Tonearm.STRIKE_HIT_RANGE + 0.01, 0.0), false)
	_check(_boss.hp == Tonearm.HP_MAX and _boss.is_pogoable(), "a missed strike does not consume the opening")
	_boss.on_player_strike(Vector2(Tonearm.STRIKE_HIT_RANGE, 0.0), false)
	_check(_boss.hp == Tonearm.HP_MAX - Tonearm.HP_PER_HIT, "the same 120px reach used by Skip confirms a hit")
	_check(not _boss.is_pogoable(), "a consumed opening cannot award a second pogo")
	_boss.on_player_strike(Vector2.ZERO, true)
	_check(_boss.hp == Tonearm.HP_MAX - Tonearm.HP_PER_HIT, "one opening cannot take duplicate strikes")
	_advance(Tonearm.RECOVER_TIME + 0.05)
	_check(_boss.state == Tonearm.S.COUNTING and not _boss.is_pogoable(), "the next count closes the opening")
	_sweep(100)
	_boss.on_player_strike(Vector2.ZERO, true)
	_check(is_equal_approx(_boss.hp, Tonearm.HP_MAX - Tonearm.HP_PER_HIT - Tonearm.HP_PER_BIG), "a hot strike bites deeper in a parry opening")

func _check_mercy() -> void:
	_new_boss()
	_player.setting = true
	_advance(0.5)
	_check(_boss.outcome.is_empty(), "kneeling during the upward gesture does not skip it")
	_advance(Tonearm.GESTURE_TIME)
	_player.position = Vector2(-Tonearm.SET_RANGE - 1.0, 0.0)
	_advance(Tonearm.SET_FREE_TIME + 0.1)
	_check(_boss.outcome.is_empty() and _boss._listening == 0.0, "listening requires proximity to the grounded point")
	_player.position = Vector2(-80.0, 0.0)
	_advance(Tonearm.SET_FREE_TIME + 0.1)
	_check(_boss.outcome == "freed" and _events.freed == 1 and _events.shattered == 0 and _events.bout == 0, "a full initial Set resolves peacefully with one exclusive reward")
	_check(_events.hit == 0 and not _boss.is_pogoable(), "the peaceful route has no attack or residual pogo")
	_advance(20.0)
	_boss.on_player_strike(Vector2.ZERO, true)
	_boss._resolve_outcome("shattered")
	_check(_boss.outcome == "freed" and _events.freed == 1 and _events.shattered == 0, "the freed silhouette remains and cannot be shattered later")
	_new_boss()
	_provoke()
	_sweep(100)
	_player.setting = true
	_advance(Tonearm.SET_FREE_TIME + 0.05)
	_check(_boss.outcome == "freed" and _events.freed == 1, "the longer parry recovery leaves enough time for mercy")
	_new_boss()
	_provoke()
	_sweep(1000)
	_player.setting = true
	_advance(Tonearm.RECOVER_TIME + 0.05)
	_check(_boss.outcome.is_empty() and _boss._listening == 0.0, "a normal recovery does not silently build mercy through an attack")

func _check_force() -> void:
	_new_boss()
	_provoke()
	for strike in range(int(Tonearm.HP_MAX)):
		_sweep(1000, Tonearm.CONTACT_RANGE + 1.0)
		_boss.on_player_strike(Vector2.ZERO, false)
	_check(_boss.outcome == "shattered" and _events.shattered == 1 and _events.freed == 0 and _events.bout == 0, "six distinct openings yield one exclusive shattered outcome")
	_check(not _boss.is_in_group("strikable") and not _boss.is_in_group("hears_strikes"), "a resolved arm leaves strike and pogo dispatch")
	_boss._resolve_outcome("freed")
	_boss.reset_attempt()
	_advance(20.0)
	_check(_boss.outcome == "shattered" and _boss.state == Tonearm.S.DOWN and _boss.hp == 0.0 and _events.shattered == 1, "the broken silhouette never reforms or emits another reward")

func _check_restore_and_reset() -> void:
	for result in ["freed", "shattered"]:
		_new_boss()
		_boss.restore_outcome(result)
		_boss.restore_outcome(result)
		_boss.reset_attempt()
		_check(_boss.outcome == result and _events.freed == 0 and _events.shattered == 0 and _events.parry == 0, "restoring %s is silent, repeatable and permanent" % result)
	_new_boss()
	_boss.restore_outcome("invalid")
	_check(_boss.outcome.is_empty() and _boss.state == Tonearm.S.DORMANT, "an invalid outcome cannot resolve the keeper")
	_boss.reset_attempt()
	_check(_boss.state == Tonearm.S.DORMANT and not _boss._gestured, "reset before approach preserves the unseen gesture")
	_provoke()
	_sweep(100)
	_boss.on_player_strike(Vector2.ZERO, false)
	_player.setting = true
	_advance(0.4)
	_boss.reset_attempt()
	_check(_boss.hp == Tonearm.HP_MAX and _boss.state == Tonearm.S.WAITING and not _boss._engaged, "recovery resets unfinished health and aggression")
	_check(_boss._listening == 0.0 and _boss._t == 0.0 and not _boss.is_pogoable(), "recovery clears all unfinished contact and listening windows")
	_player.setting = false
	_advance(10.0)
	_check(_boss.state == Tonearm.S.WAITING and _events.hit == 0, "the reset keeper once again refuses to swing first")

func _check_pause() -> void:
	_new_boss()
	_provoke()
	var before: float = _boss._t
	_boss._process(0.0)
	_boss._process(-1.0)
	_check(_boss._t == before, "nonpositive delta does not advance or reverse the count")
	paused = true
	_boss._process(10.0)
	_boss.on_player_strike(Vector2.ZERO, true)
	_check(_boss._t == before and _boss.hp == Tonearm.HP_MAX, "pause freezes count and combat dispatch")
	paused = false
	_boss._process(20.0)
	_check(_boss._t <= Tonearm.MAX_FRAME_STEP and _events.hit == 0, "a long frame cannot consume a complete tell and deliver an unseen hit")

func _check_actual_player() -> void:
	_new_boss()
	_player.struck.connect(_dispatch_strike)
	_player._strike()
	_check(_boss._engaged and _player.velocity == Vector2.ZERO, "Skip's real first strike provokes without a false pogo launch")
	_boss._go(Tonearm.S.SWEEP)
	_boss._resolve_sweep(_player.last_strike_ms + Tonearm.PARRY_WINDOW_MS)
	_check(_events.parry == 1 and _boss.state == Tonearm.S.STAGGER, "Skip's actual strike timestamp resolves a 100ms parry")
	_player._strike()
	_check(_player.velocity.y < 0.0 and _boss.hp == Tonearm.HP_MAX - 1.0, "Skip's real pogo grants exactly one confirmed hit on the open tip")
	_player.struck.disconnect(_dispatch_strike)
	_new_boss()
	var floor_body := StaticBody2D.new()
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(800.0, 40.0)
	shape_node.shape = shape
	floor_body.add_child(shape_node)
	floor_body.position.y = 46.0
	root.add_child(floor_body)
	await physics_frame
	_player.velocity = Vector2.ZERO
	_player._physics_process(1.0 / 60.0)
	await physics_frame
	_player._physics_process(1.0 / 60.0)
	_check(_player.is_on_floor(), "the actual player settles at the authored center above a floor")
	Input.action_press("set")
	_player._physics_process(1.0 / 60.0)
	_check(_player.setting, "the actual grounded Set verb is recognized")
	_advance(Tonearm.GESTURE_TIME + Tonearm.SET_FREE_TIME + 0.3)
	_check(_boss.outcome == "freed", "the real grounded Set state peacefully resolves the encounter")
	Input.action_release("set")
	floor_body.free()

func _dispatch_strike(pos: Vector2, big: bool, _launched: bool) -> void:
	_boss.on_player_strike(pos, big)
