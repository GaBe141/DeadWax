extends SceneTree
## The return route is earned through movement. Real Skip collision frames
## distinguish the held breath from ordinary jumps and even amplified grooves.
const ChapterOne := preload("res://scripts/chapter_one.gd")
const ChapterTwo := preload("res://scripts/chapter_two.gd")
const SkipScript := preload("res://scripts/skip.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")
const LOFT := Rect2(1780, 280, 420, 30)
const OUTCOME := "the_stalls/loft_voice"
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "strike", "lift", "set", "enter_passage"]
var _room: Node2D
var _player: CharacterBody2D
var _checks := 0
var _failures: Array[String] = []
var _strikes: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action): InputMap.add_action(action)
	_room = ChapterOne.create_room(&"the_stalls")
	_room.progression = ProgressionScript.new()
	root.add_child(_room)
	_room.set_process(false)
	for child in _room.get_children(): child.set_process(false)
	_player = SkipScript.new()
	_player.progression = _room.progression
	_player.struck.connect(func(_position: Vector2, big: bool, launched: bool) -> void:
		_strikes.append({"big": big, "launched": launched}))
	root.add_child(_player)
	await _physics(3)
	_check_authorship()
	await _ordinary_approaches()
	await _strong_grooves()
	await _gather_approach()
	await _safe_return()
	_check_shortcut()
	_check_presentation()
	_release()
	_player.free()
	_room.free()
	await process_frame
	if _failures.is_empty():
		print("DEAD WAX GATHER ROUTE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("GATHER ROUTE FAIL: " + failure)
	quit(1)

func _check_authorship() -> void:
	var balcony := _room.get_node("LoftBalcony") as StaticBody2D
	var shape := balcony.get_child(0) as CollisionShape2D
	var rect := shape.shape as RectangleShape2D
	_check(Rect2(balcony.position - rect.size * 0.5, rect.size) == LOFT,
		"loft is a solid 200px rise above the dry bank")
	_check(_room.air_density == 0.0 and _room.air_strikes_max == 0, "Stalls air remains dry and unmodified")
	_check(_room.objective_label == "Let the live groove carry you across the market.", "first visit keeps its groove objective")
	_check(_room.entry_position(&"from_worn_gallery") == Vector2(2020, 254), "Gallery arrival is supported on the loft")
	_check(_room.entry_position(&"from_groove_yard") == Vector2(1990, 454), "existing Yard arrival remains below the loft")
	var voice := _room.get_node("LoftVoice")
	_check(voice.get_meta("chapter_state_id") == &"loft_voice" and voice.is_in_group("chapter_persistent"),
		"the loft voice has its own stable saved identity")
	_check(voice.position == Vector2(1870, 254), "voice stands on the shelf without blocking its passage")
	var polish_count := 0
	for child in _room.get_children():
		if child.get_meta("chapter_state_id", &"") == &"market_wax": polish_count += 1
	_check(polish_count == 1 and _player.shine == 0, "market keeps its original single polish patch")

func _ordinary_approaches() -> void:
	for start in [Vector2(1690, 454), Vector2(1760, 454), Vector2(1950, 454), Vector2(1280, 366)]:
		await _reset_at(start)
		_check(_player.is_on_floor(), "ordinary approach begins on its actual platform: %s" % start)
		Input.action_press("jump")
		Input.action_press("move_right")
		var reached := false
		for frame in range(95):
			await _physics(1)
			reached = reached or _on_loft()
		_check(not reached, "legs alone cannot reach loft from %s" % start)
		_release()
	# Dry strikes remain ordinary impressions before Gather is earned.
	await _reset_at(Vector2(1720, 454))
	Input.action_press("jump")
	await _physics(15)
	Input.action_press("strike")
	await _physics(1)
	_check(not _strikes.back().launched and _player.air_strikes_left == 0,
		"empty air cannot give the intended approach its second lift")
	_release()

func _strong_grooves() -> void:
	var groove := _room._grooves[0] as Node2D
	# The stress launch gives the groove its maximum repeated on-beat momentum,
	# even before a player could assemble it. This is a conservative reach test,
	# followed by real collisions and normal steering, with no Gather available.
	while Time.get_ticks_msec() < 450: await process_frame
	var maximum_speed: float = SkipScript.GROOVE_IMPULSE * SkipScript.BEAT_MULT / (1.0 - SkipScript.GROOVE_KEEP)
	for angle_index in range(19):
		var degrees := -90.0 + float(angle_index) * 5.0
		var away := Vector2.RIGHT.rotated(deg_to_rad(degrees))
		await _reset_at(groove.position + away * 220.0, false)
		_player.velocity = away * maximum_speed
		groove._ping_at = groove._now() - groove.ECHO_DELAY
		_player._strike()
		_check(_strikes.back().big and _strikes.back().launched, "stress launch uses a real on-beat groove at %s degrees" % degrees)
		Input.action_press("move_right")
		var reached := false
		for frame in range(180):
			await _physics(1)
			reached = reached or _on_loft()
			if frame > 2 and _player.is_on_floor(): break
		_check(not reached, "amplified groove cannot skip Gather at %s degrees" % degrees)
		_release()

func _gather_approach() -> void:
	_player.progression.unlock_refrain(ProgressionScript.Refrain.GATHER)
	_room._process(1.0 / 60.0)
	_check(_room.objective_label == "The upper room is closer than it was.", "Gather changes the objective without announcing another reward")
	await _reset_at(Vector2(1720, 454))
	_check(_player.air_strikes_left == 1, "Gather carries exactly one breath to the dry market")
	Input.action_press("jump")
	await _physics(15)
	Input.action_press("strike")
	await _physics(1)
	_check(_strikes.back().launched and _player.air_strikes_left == 0, "a real airborne strike spends the held breath")
	Input.action_release("strike")
	await _physics(3)
	var landed := false
	for frame in range(90):
		_axis(1830.0)
		await _physics(1)
		if _on_loft():
			landed = true
			break
	_release()
	_check(landed, "jump, upward Gather strike, and right steering physically reach the loft; actual %s" % _player.position)
	await _physics(3)
	_check(_player.air_strikes_left == 1 and _room.air_density == 0.0, "landing refills Gather without changing environmental air")

func _safe_return() -> void:
	# A miss/fall from the new shelf returns to the existing right bank.
	await _reset_at(Vector2(1810, 254))
	Input.action_press("move_left")
	var landed := false
	for frame in range(90):
		await _physics(1)
		if _player.position.x < 1735.0: Input.action_release("move_left")
		if _player.is_on_floor() and absf(_player.position.y - 454.0) < 1.0:
			landed = true
			break
	_release()
	_check(landed and _player.position.y < _room.death_y, "falling off the loft lands safely on the original bank")
	await _reset_at(_room.entry_position(&"from_worn_gallery"))
	_check(_on_loft(), "shortcut arrival settles on the actual loft floor")
	_check(_player.position.distance_to(_room.get_node("LoftPassage").position) > 74.0,
		"shortcut arrival is clear of automatic re-entry proximity")

func _check_shortcut() -> void:
	var passage := _room.get_node("LoftPassage")
	var routes: Array[StringName] = []
	_room.route_requested.connect(func(target: StringName, _entry: StringName) -> void: routes.append(target))
	_check(passage.is_locked() and not passage.try_enter(), "merely reaching the loft leaves its passage held")
	for wrong in ["opened", "shattered", "won"]:
		_room.session_outcomes[OUTCOME] = wrong
		_check(passage.is_locked(), "loft shortcut refuses unrelated outcome %s" % wrong)
	_room.session_outcomes[OUTCOME] = "freed"
	_room._process(1.0 / 60.0)
	_check(_room.objective_label == "A small song knows the way home. The gallery passage is open.",
		"live resolution updates the objective on the next room frame")
	_check(not passage.is_locked() and passage.try_enter() and routes == [&"worn_gallery"],
		"the saved phrase opens the same existing passage immediately")
	var voice := _room.get_node("LoftVoice")
	var rewards: Array[Vector2] = []
	voice.freed.connect(func(position: Vector2) -> void: rewards.append(position))
	_room.restore_encounters(_room.session_outcomes)
	_check(voice.stage == voice.Stage.FREED and rewards.is_empty(), "restoration leaves a settled voice without replaying a reward")
	_check(_player.shine == 0 and _player.progression.unlocked_refrains() == [ProgressionScript.Refrain.GATHER],
		"the encounter and shortcut create neither currency nor another Refrain")
	var gallery: Node2D = ChapterTwo.create_room(&"worn_gallery")
	gallery.process_mode = Node.PROCESS_MODE_DISABLED
	gallery.session_outcomes = _room.session_outcomes
	root.add_child(gallery)
	var reverse: Node
	for child in gallery.get_children():
		if child.is_in_group("room_exit") and child.target_room == &"the_stalls": reverse = child
	_check(reverse != null and reverse.target_entry == &"from_worn_gallery" and not reverse.is_locked(),
		"the discovered loop has a matching open Gallery return")
	_check(gallery.entry_points.has(&"from_the_stalls"), "Gallery recognizes the Stalls arrival")
	gallery.free()

func _check_presentation() -> void:
	var voice := _room.get_node("LoftVoice")
	_room.apply_side(PressingScript.Side.B)
	_check(voice.ink == _room.bg_color and voice.stock == _room.ink, "loft voice reinks on the B-side")
	_room.apply_side(PressingScript.Side.A)
	_check(voice.ink == _room.ink and voice.stock == _room.bg_color, "loft voice restores the authored palette")
	_room.set_scenery_motion(true)
	_check(voice._reduced_motion, "loft voice receives reduced-motion settings")

func _reset_at(position: Vector2, settle: bool = true) -> void:
	_release()
	_player.position = position
	_player.velocity = Vector2.ZERO
	_player._strike_cd = 0.0
	_player._buffer = 0.0
	_player._coyote = 0.0
	_player.cancel_pending_strike()
	await _physics(3 if settle else 1)
	_player.velocity = Vector2.ZERO

func _on_loft() -> bool:
	return _player.is_on_floor() and absf(_player.position.y + 26.0 - LOFT.position.y) < 1.0 and _player.position.x > LOFT.position.x

func _axis(target: float) -> void:
	var distance := target - _player.position.x
	var direction := signf(distance)
	var stopping := _player.velocity.x * _player.velocity.x / (2.0 * SkipScript.RUN_ACCEL * SkipScript.AIR_CONTROL)
	if absf(distance) < 4.0 and absf(_player.velocity.x) < 30.0: direction = 0.0
	elif signf(_player.velocity.x) == direction and absf(distance) < stopping + 3.0: direction = -direction
	Input.action_release("move_left")
	Input.action_release("move_right")
	if direction > 0.0: Input.action_press("move_right")
	elif direction < 0.0: Input.action_press("move_left")

func _release() -> void:
	for action in ACTIONS: Input.action_release(action)

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value: _failures.append(message)
