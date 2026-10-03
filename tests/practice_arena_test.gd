extends SceneTree
## The combat ladder is disposable practice, with real inherited opponents.
## The fixture owns its checkpoint, settings, and all injected input.

const Arena := preload("res://scripts/practice_arena.gd")
const MainScene := preload("res://scenes/main.tscn")
const Save := preload("res://scripts/save_store.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Collection := preload("res://scripts/collection_state.gd")
const Voice := preload("res://scripts/auditioner.gd")
const Pressing := preload("res://scripts/test_pressing.gd")
const Looper := preload("res://scripts/street_looper.gd")
const Backcutter := preload("res://scripts/backcutter.gd")
const Wave := preload("res://scripts/strike_wave.gd")

class PlayerFixture extends CharacterBody2D:
	var hooded := false
	var setting := false
	var noise := 0.0
	var last_strike_ms := -1000
	var facing := 1.0
	var strike_face := 1.0
	var hits := 0
	func executed_strike_facing() -> float:
		return strike_face
	func _ready() -> void:
		add_to_group("player")
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(34, 52)
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
var _arena: Node2D
var _started := 0
var _cleared := 0
var _completed := 0
var _main_completed := 0
var _main: Node2D
var _directory := ""
var _models: Array[RefCounted] = []
var _snapshots: Array = []
var _choices: Dictionary = {}
var _bytes: Array[PackedByteArray] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	if not InputMap.has_action("enter_passage"): InputMap.add_action("enter_passage")
	await _fixture()
	await _check_ladder()
	await _check_warning_clearance()
	await _check_spawns()
	await _check_inherited_guards()
	await _check_cancel_during_resolution()
	await _close_fixture()
	await _main_fixture()
	await _check_main_controls_and_recovery()
	await _check_last_copy_death_race()
	await _check_campaign_isolation()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15, true).timeout
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private arena checkpoints")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private arena directory")
	if _failures.is_empty():
		print("DEAD WAX PRACTICE ARENA PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("PRACTICE ARENA FAIL: " + failure)
	quit(1)

func _fixture() -> void:
	_world = Node2D.new()
	root.add_child(_world)
	var floor_body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2800, 120)
	shape.shape = rectangle
	floor_body.position = Vector2(1280, 670)
	floor_body.add_child(shape)
	_world.add_child(floor_body)
	_player = PlayerFixture.new()
	_player.position = Vector2(1280, 584)
	_world.add_child(_player)
	_arena = Arena.new()
	_arena.position = _player.position
	_world.add_child(_arena)
	_arena.set_physics_process(false)
	_arena.floor_started.connect(func(_floor: int) -> void: _started += 1)
	_arena.floor_cleared.connect(func(_floor: int) -> void: _cleared += 1)
	_arena.run_completed.connect(func() -> void: _completed += 1)
	await _physics(4)

func _check_ladder() -> void:
	_check(_player.is_on_floor() and _arena.snapshot().state == &"idle"
		and _arena.snapshot().floor == 0 and _arena._copies.is_empty(), "practice begins on safe floor with no automatic encounter")
	_check(Arena.TOTAL_FLOORS == 20 and Arena.FLOOR_ROSTERS.size() == 20,
		"the ladder has twenty authored floors")
	_check(Arena.FLOOR_ROSTERS[7] == [&"backcutter"], "floor eight introduces one cross-up opponent in isolation")
	for index in Arena.FLOOR_ROSTERS.size():
		_check(Arena.FLOOR_ROSTERS[index].count(&"backcutter") <= 1
			and (index >= 7 or not Arena.FLOOR_ROSTERS[index].has(&"backcutter")),
			"floor %d spaces the elite introduction and never stacks cross-up opponents" % (index + 1))
	_check(_arena.can_interact(), "the grounded center stand accepts a deliberate start")
	var start: Vector2 = _player.position
	_player.position.x += Arena.INTERACT_RADIUS + 1.0
	_check(not _arena.can_interact() and not _arena.try_interact(), "distant interaction cannot start the arena")
	_player.position = start + Vector2(0, -80)
	await _physics(1)
	_check(not _arena.can_interact(), "airborne interaction cannot start the arena")
	_player.position = start
	_player.velocity = Vector2.ZERO
	await _physics(4)
	paused = true
	_check(not _arena.can_interact() and not _arena.try_interact(), "paused interaction cannot start the arena")
	paused = false
	_arena.set_reduced_motion(true)
	var witnessed: Array[StringName] = []
	for floor_number in range(1, 21):
		var starts_before := _started
		_check(_arena.try_interact() and _started == starts_before + 1, "floor %d begins once through grounded interaction" % floor_number)
		_check(_arena.snapshot().floor == floor_number and _arena.snapshot().state == &"warning"
			and _arena._copies.is_empty(), "floor %d warns before materializing opponents" % floor_number)
		_check(not _arena.try_interact(), "floor %d cannot stack another encounter while warning" % floor_number)
		_arena._physics_process(Arena.FLOOR_WARNING - 0.01)
		_check(_arena._copies.is_empty(), "floor %d enemies cannot arrive before the warning ends" % floor_number)
		var before: Dictionary = _arena.snapshot()
		paused = true
		_arena._physics_process(5.0)
		_check(_arena.snapshot() == before, "floor %d pause freezes warning and presentation" % floor_number)
		paused = false
		_arena._physics_process(0.02)
		_freeze_copies(_arena)
		var copies: Array = _arena._copies.duplicate()
		_check(copies.size() == Arena.FLOOR_ROSTERS[floor_number - 1].size()
			and copies.size() >= 1 and copies.size() <= 4, "floor %d uses its bounded authored roster" % floor_number)
		var actual: Array[StringName] = []
		for copy: Node2D in copies:
			var species: StringName = copy.get_meta("practice_species", &"")
			actual.append(species)
			if species not in witnessed: witnessed.append(species)
			_check(copy.is_in_group("practice_arena_actor") and copy.is_in_group("hears_strikes")
				and copy.is_in_group("strikable"), "floor %d copies participate in ordinary combat" % floor_number)
			_check(not copy.has_meta("chapter_state_id") and not copy.is_in_group("echo_trial_actor")
				and not copy.is_in_group("echo_trial"), "floor %d copies have no story or gear-trial identity" % floor_number)
			_check(copy.reduced_motion and _arena.arena_bounds.has_point(copy.global_position),
				"floor %d copies inherit reduced motion and remain on the floor" % floor_number)
			_check(absf(copy.global_position.x - _player.global_position.x) >= Arena.SPAWN_CLEARANCE,
				"floor %d gives each arriving copy safe player clearance" % floor_number)
		actual.sort()
		var expected: Array = Arena.FLOOR_ROSTERS[floor_number - 1].duplicate()
		expected.sort()
		_check(actual == expected and _arena.snapshot().state == &"active", "floor %d selects the authored enemy types" % floor_number)
		_check(not _arena.try_interact(), "floor %d cannot be skipped through the stand" % floor_number)
		var clears_before := _cleared
		for index in copies.size():
			var copy: Node2D = copies[index]
			if copy is Voice and floor_number == 1:
				_player.position = copy.global_position
				_player.setting = true
				copy._process(Voice.SET_FREE_TIME + 0.01)
				_player.setting = false
			else:
				_shatter(copy)
			var settled: Dictionary = _arena.snapshot()
			copy.bout_won.emit()
			copy.shattered.emit(copy.global_position)
			if copy.has_signal("freed"): copy.freed.emit(copy.global_position)
			_check(_arena.snapshot() == settled, "floor %d duplicate resolution callbacks cannot advance again" % floor_number)
			_check(not copy.is_in_group("hears_strikes") and not copy.is_in_group("strikable"),
				"floor %d resolved copies retire from combat synchronously" % floor_number)
			if index + 1 < copies.size():
				_check(_cleared == clears_before and _arena.snapshot().state == &"active",
					"floor %d waits for every opponent" % floor_number)
		await _frames(2)
		_check(_cleared == clears_before + 1 and _arena._copies.is_empty()
			and get_nodes_in_group("practice_arena_actor").is_empty(), "floor %d completes exactly once without reforming copies" % floor_number)
		_check(_arena.snapshot().state == (&"complete" if floor_number == 20 else &"rest"),
			"floor %d rests until the player deliberately continues" % floor_number)
		_player.position = start
		_player.velocity = Vector2.ZERO
		await _physics(4)
		_arena._physics_process(4.0)
		_check(_arena._copies.is_empty() and _arena.snapshot().floor == floor_number,
			"floor %d downtime cannot automatically start the next floor" % floor_number)
	_check(witnessed.size() == 4 and &"voice" in witnessed and &"pressing" in witnessed
		and &"looper" in witnessed and &"backcutter" in witnessed,
		"the ladder offers three ordinary enemy types and its distinct late cross-up opponent")
	_check(_completed == 1 and _arena.snapshot().floor == 20, "the twentieth clear completes one run")
	_check(_arena.try_interact() and _arena.snapshot().floor == 1 and _arena.snapshot().state == &"warning",
		"a complete run can restart from the first floor")
	_arena.reset_run()
	_check(_arena.snapshot().state == &"idle" and _arena.snapshot().floor == 0, "explicit run reset returns to a quiet stand")

func _check_warning_clearance() -> void:
	_player.position = _arena.position
	_player.velocity = Vector2.ZERO
	await _physics(4)
	_check(_arena.try_interact(), "a fairness probe can start the first floor")
	var marked: Array = _arena.snapshot().spawn_points
	_check(marked.size() == 1, "the first warning exposes its real future spawn location")
	if marked.is_empty(): return
	_player.position.x = _arena.global_position.x + marked[0].x
	_arena._physics_process(Arena.FLOOR_WARNING - 0.01)
	_check(_arena.snapshot().spawn_points == marked and _arena._copies.is_empty(),
		"moving toward a mark never silently moves it before its warning completes")
	_arena._physics_process(0.02)
	var replanned: Array = _arena.snapshot().spawn_points
	_check(_arena.snapshot().state == &"warning" and _arena._copies.is_empty()
		and is_equal_approx(_arena.snapshot().warning, Arena.FLOOR_WARNING) and replanned != marked,
		"crowding a mark replaces it with a full fresh warning instead of an instant enemy")
	for point: Vector2 in replanned:
		_check(absf(_arena.global_position.x + point.x - _player.position.x) >= Arena.SPAWN_CLEARANCE,
			"replacement marks remain beyond immediate player contact")
	_arena._physics_process(Arena.FLOOR_WARNING - 0.01)
	_check(_arena._copies.is_empty(), "a replacement location receives the complete warning duration")
	_arena._physics_process(0.02)
	_freeze_copies(_arena)
	_check(_arena.snapshot().state == &"active" and _arena._copies.size() == 1,
		"the safely announced replacement can then materialize")
	_arena.reset_run()
	await _frames(2)

func _check_spawns() -> void:
	# Four simultaneous copies must fit safely even when the player waits at an
	# edge or moves after a warning begins. Test the full arena, not one spawn.
	var largest := 0
	for index in Arena.FLOOR_ROSTERS.size():
		if Arena.FLOOR_ROSTERS[index].size() > Arena.FLOOR_ROSTERS[largest].size(): largest = index
	for index in range(31):
		_player.position = _arena.position
		_player.velocity = Vector2.ZERO
		await _physics(3)
		_arena._floor = largest + 1
		_arena._state = &"idle"
		_check(_arena.try_interact(), "spawn probe %d can retry the largest floor" % index)
		_player.position.x = lerpf(_arena.arena_bounds.position.x + 18.0, _arena.arena_bounds.end.x - 18.0, index / 30.0)
		_arena._physics_process(Arena.FLOOR_WARNING)
		if _arena.snapshot().state == &"warning":
			_check(_arena._copies.is_empty() and is_equal_approx(_arena.snapshot().warning, Arena.FLOOR_WARNING),
				"spawn probe %d gives every replacement mark its full warning" % index)
			_arena._physics_process(Arena.FLOOR_WARNING)
		_freeze_copies(_arena)
		var copies: Array = _arena._copies.duplicate()
		_check(copies.size() == 4 and _arena.snapshot().state == &"active", "spawn probe %d fits all four enemies after warning movement" % index)
		for copy: Node2D in copies:
			_check(absf(copy.global_position.x - _player.global_position.x) >= Arena.SPAWN_CLEARANCE,
				"spawn probe %d never materializes an enemy in immediate reach" % index)
			_check(_arena.arena_bounds.has_point(copy.global_position), "spawn probe %d stays within arena boundaries" % index)
			for other: Node2D in copies:
				if copy.get_instance_id() >= other.get_instance_id(): continue
				_check(absf(copy.global_position.x - other.global_position.x) >= Arena.COPY_SPACING,
					"spawn probe %d separates simultaneous opponents" % index)
		_arena.reset_current_floor()
		_check(_arena.snapshot().floor == largest + 1 and _arena.snapshot().state == &"idle"
			and _arena._copies.is_empty(), "spawn probe %d recovery retains its current floor without a reward" % index)
		await _frames(2)
		_check(get_nodes_in_group("practice_arena_actor").is_empty(), "spawn probe %d recovery leaves no old combat copies" % index)
	_arena.reset_run()

func _check_inherited_guards() -> void:
	_player.position = _arena.position
	_player.velocity = Vector2.ZERO
	await _physics(4)
	var floor_index := -1
	for index in Arena.FLOOR_ROSTERS.size():
		if &"looper" in Arena.FLOOR_ROSTERS[index]:
			floor_index = index
			break
	_check(floor_index >= 0, "an authored floor supplies a guarded Looper")
	if floor_index < 0: return
	_arena._floor = floor_index + 1
	_check(_arena.try_interact(), "guard fixture can begin its authored floor")
	_arena._physics_process(Arena.FLOOR_WARNING)
	_freeze_copies(_arena)
	var looper: Node2D
	for copy in _arena._copies:
		if copy is Looper: looper = copy
	_check(looper != null, "the guarded copy uses the real Street Looper inheritance")
	if looper == null: return
	_check(looper.on_player_strike(looper.global_position + Vector2(121, 0), false) == &"ignored",
		"arena actors preserve the inherited 120px hit reach")
	_check(looper.on_player_strike(looper.global_position, false) == &"hit", "an unengaged Looper permits its inherited opener")
	var health: float = looper.hp
	var timer: float = looper._t
	_check(looper.on_player_strike(looper.global_position, true) == &"guard" and looper.hp == health
		and looper._t == timer and not looper.is_pogoable(), "guarded practice hits neither damage nor restart the Looper's count")
	_player.position = looper.global_position + Vector2(400, 0)
	looper._player = _player
	looper._resolve_swing(400.0)
	_check(looper.is_pogoable() and looper.state == Pressing.S.STAGGER, "a dodged swing leaves the inherited one-second opening")
	_check(looper.on_player_strike(looper.global_position, true) == &"hit"
		and is_equal_approx(looper.hp, health - Pressing.HP_PER_BIG), "an opening Accent deals inherited heavy damage")
	var next_ink := Color("e5cf9e")
	var next_stock := Color("262132")
	_arena.reink(next_ink, next_stock)
	_check(_arena.ink == next_ink and _arena.stock == next_stock and looper.ink == next_ink and looper.stock == next_stock,
		"explicit reinking updates both the post and its live guarded actors")
	_arena.set_reduced_motion(true)
	var clock: float = _arena.snapshot().clock
	_arena._physics_process(0.2)
	_check(looper.reduced_motion and _arena.snapshot().clock == clock, "reduced motion freezes decoration without changing inherited guard rules")
	_arena.reset_current_floor()
	await _frames(2)

func _check_cancel_during_resolution() -> void:
	_arena.reset_run()
	_player.position = _arena.position
	_player.velocity = Vector2.ZERO
	await _physics(4)
	_check(_arena.try_interact(), "a callback cancellation probe begins")
	_arena._physics_process(Arena.FLOOR_WARNING)
	_freeze_copies(_arena)
	var clears_before := _cleared
	var on_outcome := func(_pos: Vector2) -> void: _arena.reset_current_floor()
	_arena.actor_shattered.connect(on_outcome, CONNECT_ONE_SHOT)
	_shatter(_arena._copies[0])
	_check(_arena.snapshot().state == &"idle" and _arena.snapshot().floor == 1 and _cleared == clears_before,
		"cancelling inside an outcome callback cannot subsequently grant a floor clear")
	await _frames(2)
	_check(get_nodes_in_group("practice_arena_actor").is_empty(), "callback cancellation removes every temporary actor")

func _close_fixture() -> void:
	_world.queue_free()
	await _frames(3)
	_check(get_nodes_in_group("practice_arena_actor").is_empty() and get_nodes_in_group("hears_strikes").is_empty()
		and get_nodes_in_group("strikable").is_empty(), "removing the standalone arena leaves no combat actors")

func _main_fixture() -> void:
	_directory = "user://deadwax-practice-arena-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated Main arena fixture")
	var progression := Progression.new()
	progression.unlock_refrain(Progression.Refrain.GATHER)
	progression.discover_technique(Progression.Technique.COUNT_IN)
	var collection := Collection.new()
	var collection_data := collection.snapshot()
	collection_data.owned = ["quicksilver_tip"]
	collection_data.equipped.needle = "quicksilver_tip"
	collection_data.offcuts = 12
	var saved := {"version": 1, "room_id": "the_stalls", "entry_id": "from_horn_plaza",
		"progression": progression.snapshot(), "abilities": {"version": 2, "unlocked": ["walk", "strike"]},
		"shine": 5, "purchases": ["warm_thread"], "completed": false,
		"map": {"owned": true, "visited": ["headshell", "horn_plaza", "the_stalls"]},
		"discoveries": {"echo_spool": "recorded", "survey_slip": true},
		"exploration": {"version": 1, "opened": ["warren_return"]}, "collection": collection_data,
		"encounters": {"groove_yard/yard_first_voice": "freed"}}
	var store := Save.new(_directory + "/checkpoint.json")
	_check(store.save_game(saved) and store.save_game(saved), "seed distinct campaign models and both private checkpoints")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._continue_game()
	await _physics(4)
	_main._return_to_title()
	await _frames(3)
	_models.assign([_main.progression, _main.abilities, _main.economy, _main.map_state, _main.discoveries,
		_main.exploration, _main.collection, _main.pressing])
	_snapshots = _campaign_snapshots()
	_choices = _main.encounters.duplicate(true)
	_bytes = _disk_bytes()
	_main._start_practice()
	await _physics(4)
	_arena = _main.room.get_node_or_null("PracticeArena")
	_check(_main.practice_mode and not _main._has_session and _arena != null, "Main enters the isolated practice arena through the title intent")
	if _arena == null: return
	_arena.run_completed.connect(func() -> void: _main_completed += 1)
	_check(_main.abilities.snapshot() == Abilities.legacy_snapshot() and _main.collection.snapshot().owned.is_empty()
		and _main.economy.snapshot() == {"shine": 0, "purchases": []}, "arena practice supplies all core moves with stock equipment and no wallet")
	_check(_disk_bytes() == _bytes and _campaign_snapshots() == _snapshots, "entering the arena cannot alter the campaign checkpoint or model values")

func _check_main_controls_and_recovery() -> void:
	if _arena == null: return
	_main.player.position = _arena.global_position
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_joy(JOY_BUTTON_Y, true)
	await _physics(3)
	_check(_arena.snapshot().state == &"warning" and _arena.snapshot().floor == 1, "fresh controller Y starts the first practice floor")
	await _physics(4)
	_check(_arena.snapshot().floor == 1, "held controller input cannot stack floors")
	_joy(JOY_BUTTON_Y, false)
	_arena.set_physics_process(false)
	var warning_before: Dictionary = _arena.snapshot()
	_main._pause_game()
	await _frames(3)
	_arena._physics_process(4.0)
	_check(paused and _arena.snapshot() == warning_before, "Main pause freezes the current arena warning instead of discarding the floor")
	_key(KEY_E, true)
	await _frames(2)
	_main._resume_game()
	await _physics(3)
	_key(KEY_E, false)
	_check(not paused and _arena.snapshot().floor == 1 and _arena._copies.is_empty(), "menu dismissal cannot consume held interaction as another start")
	_arena._physics_process(Arena.FLOOR_WARNING)
	_freeze_copies(_arena)
	_check(_arena._copies.size() == 1, "the first practice floor spawns a real opponent")
	_main._health = 1
	var words_before: Array[Label] = _root_word_labels()
	_shatter(_arena._copies[0])
	_check(_root_word_labels() == words_before and words_before.is_empty(),
		"a real arena shatter creates no floating word labels under Main")
	await _frames(2)
	_check(_arena.snapshot().state == &"rest" and _arena.snapshot().floor == 1
		and _main._health == _main._max_health(), "clearing a practice floor restores health without awarding currency")
	_check(_main.economy.balance == 0 and _main.collection.snapshot().offcuts == 0
		and _main.encounters.is_empty(), "practice clears mint neither Shine, Offcuts nor story outcomes")
	_main.player.position = _arena.global_position
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_arena.set_physics_process(true)
	_key(KEY_E, true)
	await _physics(2)
	_key(KEY_E, false)
	_arena.set_physics_process(false)
	_check(_arena.snapshot().floor == 2 and _arena.snapshot().state == &"warning", "a fresh E begins the next floor after a clear")
	_arena._physics_process(Arena.FLOOR_WARNING)
	_freeze_copies(_arena)
	var old_copies: Array = _arena._copies.duplicate()
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_check(not _strike_impressions().is_empty(), "an actual practice strike creates its world impression under Main")
	_key(KEY_R, true)
	await _physics(2)
	_key(KEY_R, false)
	_check(_strike_impressions().is_empty(), "physical R removes live strike impressions immediately with the discarded floor")
	_check(_arena.snapshot().floor == 2 and _arena.snapshot().state == &"idle" and _arena._copies.is_empty()
		and _main._health == _main._max_health(), "physical R retries the current floor with full health and no advancement")
	for copy in old_copies:
		_check(not is_instance_valid(copy) or (not copy.is_in_group("hears_strikes") and not copy.is_in_group("strikable")),
			"practice recovery retires every previous combat copy")
	_main.player.position = _arena.global_position
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_check(_arena.try_interact(), "the same attempted floor remains replayable after R")
	_arena._physics_process(Arena.FLOOR_WARNING)
	_freeze_copies(_arena)
	_main._health = 1
	_main._on_player_hit()
	await _frames(3)
	await _physics(2)
	_check(_arena.snapshot().floor == 2 and _arena.snapshot().state == &"idle" and _arena._copies.is_empty()
		and _main._health == _main._max_health() and not _main._respawn_pending,
		"losing the last health retries the current floor without skipping or restarting the run")
	_check(_disk_bytes() == _bytes and _campaign_snapshots() == _snapshots,
		"controller starts, clears, menus and deaths leave campaign bytes and models unchanged")

func _check_last_copy_death_race() -> void:
	if _arena == null: return
	# A terminal actor signal and fatal player hit may land in the same frame.
	# Both an ordinary floor and the finale must wait for deferred recovery.
	for floor_number in [2, 20]:
		_arena.reset_current_floor()
		_arena._floor = floor_number
		_main._respawn()
		await _physics(3)
		_check(_arena.try_interact(), "death race floor %d can begin its attempted floor" % floor_number)
		_arena._physics_process(Arena.FLOOR_WARNING)
		_freeze_copies(_arena)
		var copies: Array = _arena._copies.duplicate()
		for index in copies.size() - 1: _shatter(copies[index])
		_check(_arena._copies.size() == 1, "death race floor %d leaves one actual opponent" % floor_number)
		var completions_before := _main_completed
		_main._health = 1
		_main.player.take_hit(_arena._copies[0].global_position)
		_check(_main._respawn_pending and _main._health == 0,
			"death race floor %d queues deferred recovery from a real player hit" % floor_number)
		_shatter(_arena._copies[0])
		_check(_arena.snapshot().state == &"idle" and _arena.snapshot().floor == floor_number
			and _main._health == 0 and _main._respawn_pending,
			"death race floor %d resolves the final copy into the same retryable attempt immediately" % floor_number)
		_check(_main_completed == completions_before,
			"death race floor %d cannot announce a completed run before recovery" % floor_number)
		_check(_arena.try_interact() and _arena.snapshot().floor == floor_number,
			"death race floor %d a fresh stand interaction cannot advance or restart before deferred recovery" % floor_number)
		await _frames(3)
		await _physics(2)
		_check(_arena.snapshot().state == &"idle" and _arena.snapshot().floor == floor_number
			and _arena._copies.is_empty() and not _main._respawn_pending and _main._health == _main._max_health(),
			"death race floor %d deferred recovery completes with full health on the same attempted floor" % floor_number)
		_check(_arena.try_interact(), "death race floor %d remains available after recovery" % floor_number)
		_arena._physics_process(Arena.FLOOR_WARNING)
		_freeze_copies(_arena)
		copies = _arena._copies.duplicate()
		for copy: Node2D in copies: _shatter(copy)
		_check(_arena.snapshot().floor == floor_number
			and _arena.snapshot().state == (&"complete" if floor_number == 20 else &"rest")
			and _main._health == _main._max_health(),
			"death race floor %d a surviving retry can then clear normally" % floor_number)
		_check(_main_completed == completions_before + (1 if floor_number == 20 else 0),
			"death race floor %d only the surviving twentieth retry announces completion" % floor_number)
		await _frames(2)
	_check(_disk_bytes() == _bytes and _campaign_snapshots() == _snapshots,
		"same-frame defeat and clear races never mutate the campaign checkpoint or models")

func _check_campaign_isolation() -> void:
	if _arena == null: return
	_main.player.position = _arena.global_position
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_check(_arena.try_interact(), "an active practice floor can be left through the title")
	_arena._physics_process(Arena.FLOOR_WARNING)
	_freeze_copies(_arena)
	var copies: Array = _arena._copies.duplicate()
	var practiced: WeakRef = weakref(_main.room)
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	var impressions: Array[Node2D] = _strike_impressions()
	_check(not impressions.is_empty(), "a final actual strike leaves an impression ready to test paused title teardown")
	_main._pause_game()
	await _frames(2)
	_check(_strike_impressions() == impressions, "pausing freezes the live strike impression for review")
	_main._return_to_title()
	_check(_strike_impressions().is_empty(), "returning to title removes every practice strike impression before another room can load")
	for impression: Node2D in impressions:
		_check(not is_instance_valid(impression) or impression.get_parent() == null,
			"a discarded practice impression cannot remain hidden behind the title")
	_check(get_nodes_in_group("practice_arena_actor").is_empty() and get_nodes_in_group("hears_strikes").is_empty()
		and get_nodes_in_group("strikable").is_empty(), "returning to title removes arena combat groups immediately")
	for copy in copies:
		_check(not is_instance_valid(copy) or (not copy.is_in_group("hears_strikes") and not copy.is_in_group("strikable")),
			"title teardown cannot leave an old practice opponent listening")
	await _frames(3)
	_check(practiced.get_ref() == null and not _main.practice_mode and paused,
		"title teardown removes the entire practice simulation")
	_check([_main.progression, _main.abilities, _main.economy, _main.map_state, _main.discoveries,
		_main.exploration, _main.collection, _main.pressing] == _models, "title restores the exact eight original campaign model objects")
	_check(_campaign_snapshots() == _snapshots and _main.encounters == _choices and _disk_bytes() == _bytes,
		"practice teardown preserves every campaign value and both checkpoint copies")
	_main._continue_game()
	await _physics(4)
	_check(_strike_impressions().is_empty() and _root_word_labels().is_empty(),
		"Continue carries no old practice strike or floating word into the campaign")
	_check(_main.world_room_id == &"the_stalls" and _main.room_entry_id == &"from_horn_plaza"
		and _main.player.shine == 5 and _main.collection.snapshot().equipped.needle == "quicksilver_tip"
		and _main.discoveries.snapshot().echo_spool == "recorded" and _main.exploration.is_open(&"warren_return"),
		"Continue still restores the campaign arrival, gear, currency and discoveries after enemy practice")
	_check(not _main.abilities.has_ability(&"combo") and not _main.abilities.has_ability(&"set"),
		"practice moves never leak into an intentionally partial campaign moveset")

func _shatter(copy: Node2D) -> void:
	var striker: CharacterBody2D = _arena._player()
	var previous_position := striker.global_position
	if copy is Backcutter:
		copy._player = striker
		copy._begin_attack()
		# Force a genuine miss through every committed phase, then use its
		# normal opening. The separate elite suite exercises physical timing.
		striker.global_position = copy.global_position + Vector2(700, -300)
		for step in range(5):
			if copy.encounter_snapshot().phase == &"open": break
			copy._physics_process(Backcutter.CROSS_TELL)
		_check(copy.encounter_snapshot().phase == &"open", "an elite's completed miss exposes its real punish opening")
		striker.global_position = copy.global_position + Vector2(60, 0)
		if striker is PlayerFixture: striker.strike_face = -1.0
		else: striker.last_strike_facing = -1.0
	if copy is Looper:
		copy._engaged = true
		copy.state = Pressing.S.STAGGER
		copy._t = 0.0
	for hit in range(8):
		if not _arena._copies.has(copy): break
		copy.on_player_strike(striker.global_position if copy is Backcutter else copy.global_position, true)
	striker.global_position = previous_position
	_check(not _arena._copies.has(copy), "inherited damaging strikes resolve an arena opponent")

func _freeze_copies(arena: Node2D) -> void:
	for copy: Node in arena._copies:
		copy.set_process(false)
		copy.set_physics_process(false)

func _root_word_labels() -> Array[Label]:
	var words: Array[Label] = []
	for child in _main.get_children():
		if child is Label and child.text in ["BRIGHT", "LY", "OH", "!!"]:
			words.append(child)
	return words

func _strike_impressions() -> Array[Node2D]:
	var impressions: Array[Node2D] = []
	for child in _main.get_children():
		if child.get_script() == Wave: impressions.append(child)
	return impressions

func _campaign_snapshots() -> Array:
	var result: Array = []
	for index in _models.size():
		result.append([_models[index].side, _models[index].runtime_left] if index == 7 else _models[index].snapshot())
	return result

func _disk_bytes() -> Array[PackedByteArray]:
	return [FileAccess.get_file_as_bytes(_main.save_path), FileAccess.get_file_as_bytes(_main.save_path + ".bak")]

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _release_inputs() -> void:
	for code in [KEY_E, KEY_J, KEY_R, KEY_ESCAPE]: _key(code, false)
	_joy(JOY_BUTTON_Y, false)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
