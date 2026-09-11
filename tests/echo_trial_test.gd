extends SceneTree
## Temporary combat recordings must be replayable without becoming story
## encounters. Claims are intents; their contents belong to Main's transaction.

const Trial := preload("res://scripts/echo_trial.gd")
const Auditioner := preload("res://scripts/auditioner.gd")
const Pressing := preload("res://scripts/test_pressing.gd")
const Looper := preload("res://scripts/street_looper.gd")

class PlayerFixture extends CharacterBody2D:
	var hooded := false
	var setting := false
	var noise := 1.0
	var last_strike_ms := -1000
	var hits := 0
	func _ready() -> void:
		add_to_group("player")
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(36, 52)
		shape.shape = rectangle
		add_child(shape)
	func _physics_process(delta: float) -> void:
		velocity.y += 1200.0 * delta
		move_and_slide()
	func take_hit(_position: Vector2) -> void:
		hits += 1

var _checks := 0
var _failures: Array[String] = []
var _world: Node2D
var _player: PlayerFixture
var _trial: Node2D
var _starts := 0
var _claims := 0

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	if not InputMap.has_action("enter_passage"): InputMap.add_action("enter_passage")
	for hunt in [&"label", &"overture", &"unplayed"]:
		await _fixture(hunt)
		await _check_trial(hunt)
		await _check_spawns(hunt)
		await _close_fixture()
	await _fixture(&"label")
	await _check_inherited_combat()
	await _close_fixture()
	if _failures.is_empty():
		print("DEAD WAX ECHO TRIAL PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("ECHO TRIAL FAIL: " + failure)
	quit(1)

func _fixture(hunt: StringName) -> void:
	_world = Node2D.new()
	root.add_child(_world)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(4000, 60)
	shape.shape = rectangle
	floor_body.position = Vector2(1500, 890 if hunt == &"unplayed" else 630)
	floor_body.add_child(shape)
	_world.add_child(floor_body)
	_player = PlayerFixture.new()
	_player.position = Trial.PROFILES[hunt].position
	_world.add_child(_player)
	_trial = Trial.new()
	_trial.hunt_id = hunt
	_trial.position = Trial.PROFILES[hunt].position
	_world.add_child(_trial)
	_trial.set_physics_process(false)
	_trial.start_requested.connect(func(_source: Node) -> void: _starts += 1)
	_trial.completed.connect(func(_source: Node) -> void: _claims += 1)
	await _physics(4)

func _check_trial(hunt: StringName) -> void:
	var prefix := String(hunt) + ": "
	_check(_player.is_on_floor(), prefix + "fixture is grounded on the unchanged campaign floor")
	_check(_trial.can_start() and not _trial.can_claim(), prefix + "idle post offers only a start")
	var starts := _starts
	_check(_trial.try_interact() and _starts == starts + 1 and _trial.snapshot().state == &"idle", prefix + "fresh interaction emits intent without autonomously starting")
	paused = true
	_check(not _trial.can_start() and not _trial.begin_trial() and not _trial.try_interact(), prefix + "pause refuses starts")
	paused = false
	var original: Vector2 = _player.position
	_player.position.x += Trial.INTERACT_RADIUS + 1
	_check(not _trial.can_start() and not _trial.begin_trial(), prefix + "outside grounded reach refuses start")
	_player.position = original + Vector2(0, -80)
	await _physics(1)
	_check(not _trial.can_start(), prefix + "airborne start is refused")
	_player.position = original
	_player.velocity = Vector2.ZERO
	await _physics(4)
	_check(_trial.begin_trial(), prefix + "Main can approve one valid trial")
	_check(not _trial.begin_trial() and not _trial.can_start(), prefix + "active trial cannot stack another wave set")
	_check(_trial.snapshot().wave == 1 and _trial.snapshot().remaining == 0, prefix + "first wave starts with a clear warning")
	_trial._physics_process(0.95)
	_check(_trial.snapshot().remaining == 0, prefix + "copies never attack before the first warning completes")
	var before: Dictionary = _trial.snapshot()
	paused = true
	_trial._physics_process(4.0)
	_check(_trial.snapshot() == before, prefix + "pause freezes warning and visual clock")
	paused = false
	_trial.set_reduced_motion(true)
	_trial._physics_process(0.06)
	_freeze_copies()
	_check(_trial.snapshot().remaining == 1 and _trial.snapshot().clock == 0.0, prefix + "reduced motion preserves semantic wave timing")
	for wave in range(1, 4):
		if wave > 1:
			_trial._physics_process(Trial.WAVE_WARNING)
			_freeze_copies()
		var copies: Array = _trial._copies.duplicate()
		_check(copies.size() == Trial.WAVE_COUNTS[wave - 1], prefix + "authored copy count for wave " + str(wave))
		for copy: Node2D in copies:
			_check(copy.is_in_group("echo_trial_actor") and copy.is_in_group("hears_strikes") and copy.is_in_group("strikable"), prefix + "temporary copy participates in real strike and pogo groups")
			_check(not copy.has_meta("chapter_state_id") and not copy.has_method("add_shine"), prefix + "temporary copy has no story identity or currency grant")
			_check(absf(copy.global_position.x - _player.global_position.x) >= Trial.SPAWN_CLEARANCE, prefix + "copy spawns beyond immediate contact")
			_check(_trial.trial_bounds().has_point(copy.global_position), prefix + "copy begins on its authored trial floor")
			_check(copy.reduced_motion, prefix + "new copies inherit reduced motion")
			if copy.has_signal("freed") and wave == 2:
				copy.freed.emit(copy.global_position)
			else:
				copy.shattered.emit(copy.global_position)
			var resolved: Dictionary = _trial.snapshot()
			copy.bout_won.emit()
			copy.shattered.emit(copy.global_position)
			_check(_trial.snapshot() == resolved, prefix + "duplicate terminal signals cannot resolve an extra copy or wave")
			_check(not copy.is_in_group("hears_strikes") and not copy.is_in_group("strikable"), prefix + "resolved copies leave combat groups immediately")
		await process_frame
	_check(_trial.snapshot().state == &"claim" and _trial.can_claim(), prefix + "only all four resolutions earn a grounded claim")
	var claims := _claims
	_check(_trial.try_interact() and _claims == claims + 1 and _trial.snapshot().state == &"claim", prefix + "claim emits an intent until Main confirms the save")
	_trial.reward_failed()
	_check(_trial.snapshot().save_failed and _trial.can_claim(), prefix + "failed save keeps the same earned claim retryable")
	_trial.cancel_trial()
	_check(_trial.can_claim(), prefix + "opening a menu preserves a completed claim")
	_check(_trial.try_interact() and _claims == claims + 2, prefix + "retry emits the same claim without recombat")
	var receipt := {"message": "A TEST PRESSING", "items": ["test"]}
	_trial.accept_reward(receipt)
	receipt.items.append("changed")
	_check(_trial.snapshot().state == &"idle" and _trial.snapshot().receipt.items == ["test"], prefix + "successful claim becomes an independent settled receipt")
	_trial.accept_reward({"message": "DUPLICATE"})
	_check(_trial.snapshot().receipt.message == "A TEST PRESSING", prefix + "duplicate acceptance cannot overwrite a receipt")
	_check(_trial.begin_trial(), prefix + "a collected trial can immediately be played again")
	_trial._physics_process(Trial.WAVE_WARNING)
	_freeze_copies()
	_trial.cancel_trial()
	_check(_trial.snapshot().state == &"idle" and _trial._copies.is_empty(), prefix + "cancelling an unfinished trial clears all copies without a claim")
	await process_frame
	_check(get_nodes_in_group("echo_trial_actor").is_empty(), prefix + "cancelled recordings leave no orphan actors")
	_check(_trial.begin_trial(), prefix + "another attempt remains available after cancellation")
	_player.position.x = _trial.trial_bounds().end.x + 1
	_trial._physics_process(0.01)
	_check(_trial.snapshot().state == &"idle", prefix + "walking outside the trial ends the attempt without locking an exit")
	_player.position = original
	_player.velocity = Vector2.ZERO
	await _physics(4)
	_trial._state = &"claim"
	_trial.cancel_trial(true)
	_check(_trial.snapshot().state == &"idle", prefix + "recovery or transitions can explicitly discard a room claim")
	_trial.reink(Color("f4e4bb"), Color("1e1c24"))
	_check(_trial.ink == Color("f4e4bb") and _trial.stock == Color("1e1c24"), prefix + "post accepts explicit room reinking")

func _check_spawns(hunt: StringName) -> void:
	var bounds: Rect2 = _trial.trial_bounds()
	# Player positions near one edge used to leave an insufficient safe region
	# for the second copy. Test the full walkable interval, not just the post.
	for index in range(31):
		_trial._state = &"active"
		_trial._wave = 3
		_player.position.x = lerpf(bounds.position.x + 1.0, bounds.end.x - 1.0, index / 30.0)
		_trial._spawn_wave()
		_freeze_copies()
		var copies: Array = _trial._copies.duplicate()
		_check(copies.size() == 2, String(hunt) + ": final wave has safe room across the whole floor " + str(index))
		if copies.size() == 2:
			_check(absf(copies[0].global_position.x - copies[1].global_position.x) >= Trial.COPY_SPACING,
				String(hunt) + ": simultaneous copies remain separated")
			for copy: Node2D in copies:
				_check(absf(copy.global_position.x - _player.global_position.x) >= Trial.SPAWN_CLEARANCE,
					String(hunt) + ": walking to an edge cannot cause a contact spawn")
		_trial.cancel_trial(true)
		await process_frame

func _check_inherited_combat() -> void:
	_player.position = _trial.position
	_player.velocity = Vector2.ZERO
	await _physics(4)
	_check(_trial.begin_trial(), "combat fixture begins")
	_trial._spawn_wave()
	_freeze_copies()
	var voice: Node2D = _trial._copies[0]
	_check(voice is Auditioner and voice.hp == Auditioner.HP_MAX and voice.is_pogoable(), "voice copies inherit health and pogo rules")
	voice.on_player_strike(voice.global_position + Vector2(121, 0), false)
	_check(voice.hp == Auditioner.HP_MAX, "echo voices retain the 120px strike reach")
	voice.on_player_strike(voice.global_position, true)
	_check(is_equal_approx(voice.hp, Auditioner.HP_MAX - Auditioner.HP_PER_BIG), "echo accents use inherited damage")
	_player.position = voice.global_position + Vector2(0, -13)
	_player.setting = true
	voice._process(Auditioner.SET_FREE_TIME + 0.01)
	_check(_trial.snapshot().wave == 2 and _trial.snapshot().remaining == 0, "a complete actual Set frees a copy and advances the trial")
	_player.setting = false
	_trial.cancel_trial()
	await process_frame
	_trial.hunt_id = &"unplayed"
	_trial.position = Vector2(1300, 834)
	_player.position = _trial.position
	_trial._state = &"active"
	_trial._wave = 1
	_trial._spawn_wave()
	_freeze_copies()
	var looper: Node2D = _trial._copies[0]
	_check(looper is Looper and looper.hp == Pressing.HP_MAX, "deep copies retain the authored Street Looper combat model")
	looper.on_player_strike(looper.global_position, false)
	var health: float = looper.hp
	var timer: float = looper._t
	looper.on_player_strike(looper.global_position, true)
	_check(looper.hp == health and looper._t == timer and not looper.is_pogoable(), "deep copy guards cannot be burst or rewound by repeated strikes")
	_trial.reink(Color("302922"), Color("ded4bc"))
	_check(looper.ink == _trial.ink and looper.stock == _trial.stock, "live copy cues reink with their post")
	_trial.cancel_trial(true)

func _freeze_copies() -> void:
	for copy: Node in _trial._copies: copy.set_process(false)

func _close_fixture() -> void:
	_trial.cancel_trial(true)
	_world.queue_free()
	await process_frame
	await process_frame
	_check(get_nodes_in_group("echo_trial_actor").is_empty(), "removing a trial leaves no recordings in the next room")

func _physics(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _check(value: bool, message: String) -> void:
	_checks += 1
	if not value: _failures.append(message)
