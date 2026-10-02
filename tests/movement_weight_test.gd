extends SceneTree
## Actual collision frames exercise weight without campaign saves or rewards.
const Skip := preload("res://scripts/skip.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "strike", "lift", "set"]
var _player: CharacterBody2D
var _floor: StaticBody2D
var _checks := 0
var _failures: Array[String] = []
var _stock_coast := 0.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action): InputMap.add_action(action)
	_floor = StaticBody2D.new()
	_floor.position = Vector2(0, 500)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10000, 40)
	shape.shape = rectangle
	_floor.add_child(shape)
	root.add_child(_floor)
	_player = Skip.new()
	root.add_child(_player)
	await _run_and_coast()
	await _reverse()
	await _set_and_hood()
	await _air_handling()
	await _equipment()
	await _shuffle()
	_release()
	_player.free()
	_floor.free()
	await process_frame
	if _failures.is_empty():
		print("DEAD WAX MOVEMENT WEIGHT PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("MOVEMENT WEIGHT FAIL: " + failure)
	quit(1)

func _run_and_coast() -> void:
	await _reset()
	Input.action_press("move_right")
	await _physics(5)
	_check(_player.velocity.x > 120.0 and _player.velocity.x < 190.0,
		"the run builds speed over several frames rather than snapping to its ceiling")
	await _physics(16)
	_check(is_equal_approx(_player.velocity.x, 340.0) and _player.is_on_floor(),
		"the heavier run retains the original full speed and floor contact")
	Input.action_release("move_right")
	var start := _player.position.x
	await _physics(1)
	_check(_player.velocity.x > 250.0 and _player.velocity.x < 340.0 and _player.position.x > start,
		"releasing a full run carries a short, diminishing coast")
	var stopped := false
	for frame in 12:
		await _physics(1)
		if is_zero_approx(_player.velocity.x):
			stopped = true
			break
	_stock_coast = _player.position.x - start
	_check(stopped and _stock_coast > 18.0 and _stock_coast < 28.0,
		"stock feet settle within a body width instead of sliding indefinitely; coast %.2f" % _stock_coast)
	var settled := _player.position.x
	await _physics(8)
	_check(is_equal_approx(_player.position.x, settled), "a completed coast stays at rest")

func _reverse() -> void:
	await _reset()
	_player.velocity.x = 340.0
	var start := _player.position.x
	Input.action_press("move_left")
	await _physics(1)
	_check(_player.facing == -1.0 and _player.velocity.x > 250.0,
		"a reversal faces the new input immediately while the existing momentum unwinds")
	var frames := 1
	while _player.velocity.x >= 0.0 and frames < 18:
		await _physics(1)
		frames += 1
	_check(_player.velocity.x < 0.0 and frames >= 9 and frames <= 13,
		"full-speed direction reversal has a deliberate but bounded stop; frames %d" % frames)
	_check(_player.position.x > start + 20.0 and _player.position.x < start + 35.0,
		"turning carries the existing forward motion without adding a lurch")
	await _physics(15)
	_check(is_equal_approx(_player.velocity.x, -340.0) and _player.position.x < start,
		"holding the new direction finishes a normal run in that direction")

func _set_and_hood() -> void:
	await _reset()
	_player.velocity.x = 340.0
	var start := _player.position.x
	Input.action_press("set")
	Input.action_press("move_right")
	await _physics(8)
	_check(_player.setting and _player.is_on_floor() and is_zero_approx(_player.velocity.x),
		"grounded Set stops the run even while a direction remains held")
	_check(_player.position.x - start < 16.0, "Set plants more firmly than a released run")
	var planted := _player.position
	await _physics(12)
	_check(_player.position == planted, "holding Set cannot resume movement")
	await _reset()
	Input.action_press("lift")
	Input.action_press("move_right")
	await _physics(20)
	_check(_player.hooded and is_equal_approx(_player.velocity.x, 340.0 * 0.62),
		"Hood keeps its slower, quiet handling ceiling")
	Input.action_release("move_right")
	start = _player.position.x
	await _physics(10)
	_check(is_zero_approx(_player.velocity.x) and _player.position.x - start < _stock_coast,
		"the slower Hood settles over a shorter distance than a run")
	await _reset({"hood_speed": 1.2})
	Input.action_press("lift")
	Input.action_press("move_right")
	await _physics(20)
	_check(is_equal_approx(_player.velocity.x, 340.0 * 0.62 * 1.2),
		"Hood equipment still changes its own speed rather than the run ceiling")

func _air_handling() -> void:
	await _reset({}, false)
	_player.velocity = Vector2(340.0, -300.0)
	Input.action_press("move_right")
	await _physics(5)
	_check(is_equal_approx(_player.velocity.x, 340.0) and is_equal_approx(_player.velocity.y, -162.5),
		"held airborne movement adds no speed or vertical propulsion at the run ceiling")
	await _reset({}, false)
	_player.velocity = Vector2(340.0, -300.0)
	await _physics(5)
	_check(is_equal_approx(_player.velocity.x, 340.0 - 760.0 * 5.0 / 60.0),
		"airborne neutral drag retains its previous rate")
	await _reset({"accel": 1.4}, false)
	_player.velocity = Vector2(0, -300)
	Input.action_press("move_right")
	await _physics(1)
	_check(is_equal_approx(_player.velocity.x, 1170.0 / 60.0),
		"ground acceleration equipment does not leak into air steering")
	await _reset({"air_control": 1.4}, false)
	_player.velocity = Vector2(0, -300)
	Input.action_press("move_right")
	await _physics(1)
	_check(is_equal_approx(_player.velocity.x, 1170.0 * 1.4 / 60.0)
		and is_equal_approx(_player.velocity.y, -272.5),
		"air equipment scales only the existing steering and leaves gravity unchanged")
	await _reset({}, false)
	_player.velocity = Vector2(680.0, -300.0)
	Input.action_press("move_right")
	await _physics(5)
	_check(is_equal_approx(_player.velocity.x, 680.0 - 1170.0 * 5.0 / 60.0),
		"steering a launch still sheds excess speed at the old rate")

func _equipment() -> void:
	await _reset({"accel": 1.25})
	Input.action_press("move_right")
	await _physics(5)
	_check(is_equal_approx(_player.velocity.x, 1900.0 * 1.25 * 5.0 / 60.0),
		"acceleration gear scales the heavier run-up")
	await _reset({"friction": 0.8})
	_player.velocity.x = 340.0
	var start := _player.position.x
	await _physics(15)
	_check(is_zero_approx(_player.velocity.x) and _player.position.x - start > _stock_coast + 4.0,
		"a braking trade-off carries more coast but still settles")
	await _reset({"speed": 1.12})
	Input.action_press("move_right")
	await _physics(24)
	_check(is_equal_approx(_player.velocity.x, 340.0 * 1.12),
		"speed gear retains its earned full-speed multiplier")

func _shuffle() -> void:
	await _reset({"speed": 1.4, "accel": 1.4, "friction": 0.65, "air_control": 1.4})
	_player.abilities = Abilities.new()
	var start := _player.position.x
	Input.action_press("move_right")
	await _physics(20)
	_check(is_equal_approx(_player.position.x, start + 1.0) and is_zero_approx(_player.velocity.x),
		"missing Walk remains exactly one pixel per fresh press even with handling gear")
	Input.action_release("move_right")
	await _physics(10)
	_check(is_equal_approx(_player.position.x, start + 1.0), "shuffle has no release coast")
	Input.action_press("jump")
	Input.action_press("move_left")
	await _physics(10)
	_check(not _player.is_on_floor() and absf(_player.position.x - start) < _player.safe_margin,
		"a fresh jump shuffle stays one pixel without held airborne travel")

func _reset(profile: Dictionary = {}, grounded: bool = true) -> void:
	_release()
	_player.abilities = null
	_player.apply_equipment(profile)
	_player.position = Vector2(-400, 454 if grounded else 0)
	_player.velocity = Vector2.ZERO
	_player._stagger = 0.0
	_player._recover = 0.0
	_player._buffer = 0.0
	_player._coyote = 0.0
	await _physics(4 if grounded else 1)
	_player.velocity = Vector2.ZERO

func _release() -> void:
	for action in ACTIONS: Input.action_release(action)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
