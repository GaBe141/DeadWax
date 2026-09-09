extends SceneTree
## Animation follows gameplay. Real inputs exercise visual transitions, while
## isolated checkpoints keep this suite away from a player's saved pressing.

const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _strike_count := 0
var _collider: CollisionShape2D
var _collider_transform: Transform2D
var _collider_size: Vector2

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
	_main._new_game()
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
	_main.queue_free()
	await _frames(3)
	paused = false
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
	for key in ["time", "stride", "run", "air", "land", "impact", "launch", "strike", "hurt"]:
		_check(is_zero_approx(float(reset[key])), "recovery clears player visual field " + key)
	_check(not bool(reset.big), "recovery clears the amplified-strike impression")
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
