extends SceneTree
## The empty movement room is a separate, unsaved title-screen activity.
## All checkpoint writes and physical input belong to this private fixture.
const MainScene := preload("res://scenes/main.tscn")
const Practice := preload("res://scripts/room_move_practice.gd")
const Campaign := preload("res://scripts/campaign.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Save := preload("res://scripts/save_store.gd")

var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _models: Array[RefCounted] = []
var _snapshots: Array = []
var _encounters: Dictionary = {}
var _disk: Array[PackedByteArray] = []
var _strikes := 0

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-practice-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated practice fixture")
	var progress := Progression.new()
	progress.unlock_refrain(Progression.Refrain.GATHER)
	progress.discover_technique(Progression.Technique.COUNT_IN)
	var saved := {"version": 1, "room_id": "the_stalls", "entry_id": "from_horn_plaza",
		"progression": progress.snapshot(), "shine": 5, "purchases": ["warm_thread"],
		"map": {"owned": true, "visited": ["headshell", "horn_plaza", "the_stalls"]},
		"completed": false, "encounters": {"groove_yard/yard_first_voice": "freed"}}
	var store := Save.new(_directory + "/checkpoint.json")
	_check(store.save_game(saved) and store.save_game(saved), "seed primary and recovery campaign checkpoints")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main.player.struck.connect(func(_pos: Vector2, _big: bool, _launched: bool) -> void: _strikes += 1)
	_main._continue_game()
	await _physics(4)
	_main._return_to_title()
	await _frames(3)
	_main.pressing.runtime_left = 8.0
	_capture_campaign()
	await _enter_from_title()
	await _movement_and_menus()
	await _return_and_continue()
	await _defensive_entries()
	await _without_a_checkpoint()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
	_check(store.delete_save(), "remove private practice checkpoints")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated practice directory")
	if _failures.is_empty():
		print("DEAD WAX MOVE PRACTICE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("MOVE PRACTICE FAIL: " + failure)
	quit(1)

func _capture_campaign() -> void:
	_models.assign([_main.progression, _main.economy, _main.map_state, _main.pressing])
	_snapshots = [_main.progression.snapshot(), _main.economy.snapshot(), _main.map_state.snapshot(),
		[_main.pressing.side, _main.pressing.runtime_left]]
	_encounters = _main.encounters.duplicate(true)
	_disk = _disk_bytes()

func _enter_from_title() -> void:
	_check(paused and _main.game_menu.screen == "title", "practice starts from the opaque paused title")
	var button := _button(_main.game_menu, "Move practice")
	_check(button != null and not button.disabled, "the title offers a focusable Move practice action")
	if button == null: return
	button.grab_focus()
	_key(KEY_SPACE, true)
	await _frames(4)
	_key(KEY_SPACE, false)
	await _physics(4)
	_check(_main.practice_mode and not _main.development_mode and not _main._has_session,
		"title intent opens practice without starting a campaign or development atlas")
	_check(not paused and not _main.game_menu.is_open and not _main.opening.is_open,
		"the room responds immediately without a cutscene or menu left open")
	_check(_main.room.get_script() == Practice and _main.world_room_id == &"",
		"practice has its own room factory and no campaign world ID")
	_check(Campaign.room_ids().size() == 21 and not Campaign.room_ids().has(_main.room.room_id),
		"the practice room does not enlarge the authored campaign registry")
	_check(_main.player.is_on_floor() and absf(_main.player.position.y - _main.room.spawn_pos.y) < 1.0,
		"confirming entry leaves the player grounded on the practice floor")
	for index in _models.size():
		var active: RefCounted = [_main.progression, _main.economy, _main.map_state, _main.pressing][index]
		_check(active != _models[index], "practice receives isolated model " + str(index))
	_check(_main.progression.snapshot() == Progression.new().snapshot()
		and _main.economy.snapshot() == {"shine": 0, "purchases": []}
		and _main.map_state.snapshot() == {"owned": false, "visited": []},
		"practice begins with no earned permissions, wallet purchases, or map marks")
	_check(_main.player.progression == _main.progression and _main.player.economy == _main.economy
		and _main.inventory.progression == _main.progression and _main.inventory.map_state == _main.map_state,
		"player and read-only Book use the isolated models")
	_check(_main.encounters.is_empty() and not _main.chapter_complete, "campaign choices and ending state stay outside practice")
	_check(_main.room._grooves.is_empty() and _main.room.entry_points.size() <= 1,
		"the empty room contains no grooves or destination arrivals")
	var forbidden := false
	for node in _descendants(_main.room):
		for group in ["hears_strikes", "strikable", "room_exit", "live_groove", "map_pickup"]:
			forbidden = forbidden or node.is_in_group(group)
		forbidden = forbidden or node.has_meta("chapter_state_id")
		forbidden = forbidden or node.get_script() in [load("res://scripts/refrain_pickup.gd"), load("res://scripts/chapter_marker.gd")]
	_check(not forbidden, "practice contains no enemies, dummies, pickups, passages, or completion point")
	_check(_disk_bytes() == _disk, "entering practice leaves primary and recovery checkpoint bytes untouched")
	_check(_campaign_snapshots() == _snapshots, "campaign model values remain unchanged behind practice")

func _movement_and_menus() -> void:
	var start: Vector2 = _main.player.position
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	_check(_main.player.position.x > start.x + 30 and _main.player.is_on_floor(), "real movement crosses the safe empty floor")
	_key(KEY_SPACE, true)
	await _physics(4)
	_key(KEY_SPACE, false)
	_check(_main.player.position.y < start.y - 20 and not _main.player.is_on_floor(), "the usual jump works in practice")
	await _physics(65)
	_check(_main.player.is_on_floor(), "ordinary movement and jumping return to safe floor")
	_key(KEY_J, true)
	await _physics(1)
	_key(KEY_J, false)
	_check(_main.player.combo_snapshot().step == 1, "an actual strike begins a practice combo before reset")
	_key(KEY_R, true)
	await _physics(3)
	_key(KEY_R, false)
	_check(_main.player.position.distance_to(_main.room.spawn_pos) < 1 and _main.player.velocity.is_zero_approx(),
		"physical R immediately resets to the authored practice start")
	_check(_main.player.combo_snapshot().step == 0 and _main.player.combo_snapshot().remaining == 0.0
		and _main.player._strike_buffer == 0.0, "physical R also clears combo and pending strike state")
	for edge in ["left", "right"]:
		var limit: float = _main.room.cam_limits.position.x if edge == "left" else _main.room.cam_limits.end.x
		_main.player.position = Vector2(limit + (24 if edge == "left" else -24), _main.room.spawn_pos.y)
		_main.player.velocity = Vector2.ZERO
		await _physics(2)
		var direction: Key = KEY_A if edge == "left" else KEY_D
		_key(direction, true)
		await _physics(12)
		_key(direction, false)
		_check(_main.player.is_on_floor() and _main.player.position.x > _main.room.cam_limits.position.x
			and _main.player.position.x < _main.room.cam_limits.end.x, edge + " wall keeps ordinary movement inside the safe room")
	_main._respawn()
	await _physics(2)
	_key(KEY_ESCAPE, true)
	await _frames(3)
	_key(KEY_ESCAPE, false)
	_check(paused and _main.game_menu.screen == "pause", "Escape pauses the unsaved practice activity")
	_check(_button(_main.game_menu, "Return to title") != null and _button(_main.game_menu, "Quit") != null
		and _button(_main.game_menu, "Save & return to title") == null and _button(_main.game_menu, "Save & quit") == null,
		"practice pause labels never promise a save")
	var position_before: Vector2 = _main.player.position
	var strikes_before := _strikes
	for key in [KEY_D, KEY_J, KEY_SPACE]: _key(key, true)
	await _frames(6)
	for key in [KEY_D, KEY_J, KEY_SPACE]: _key(key, false)
	_check(_main.player.position == position_before and _strikes == strikes_before, "pause freezes practice movement and attacks")
	_key(KEY_ESCAPE, true)
	await _frames(3)
	_key(KEY_ESCAPE, false)
	await _physics(3)
	_check(not paused and not _main.game_menu.is_open, "Escape resumes practice directly")
	_check(_main.player.is_on_floor() and _strikes == strikes_before, "dismissal cannot release a paused jump or strike")
	_key(KEY_I, true)
	await _frames(3)
	_key(KEY_I, false)
	_check(_main.inventory.is_open() and paused, "the practice Book is available as a paused read-only view")
	_key(KEY_ESCAPE, true)
	await _frames(3)
	_key(KEY_ESCAPE, false)
	await _physics(3)
	_check(not _main.inventory.is_open() and not paused, "canceling the Book returns directly to practice")
	for key in [KEY_M, KEY_B, KEY_E]:
		_key(key, true)
		await _physics(2)
		_key(key, false)
	_check(not _main.map_menu.is_open and not _main.shop.is_open and _main.practice_mode,
		"map, trade and passage input have no practice destination or vendor")
	_main._on_route_requested(&"headshell", &"default")
	_main._remember_encounter("practice/fake_choice", "freed")
	_main._queue_save()
	_check(_main._persist_session(), "unsaved practice treats a save request as a harmless no-op")
	await _frames(4)
	_check(_disk_bytes() == _disk and _campaign_snapshots() == _snapshots,
		"movement, reset, menus and queued save requests leave the campaign unchanged")
	_check(_main.map_state.visited.is_empty(), "practice never records a room visit")
	_check(_main.practice_mode and not _main._transition_pending and _main.encounters.is_empty(),
		"stale campaign route and encounter callbacks cannot alter the practice activity")

func _return_and_continue() -> void:
	var practiced: WeakRef = weakref(_main.room)
	_main._pause_game()
	await _frames(3)
	var button := _button(_main.game_menu, "Return to title")
	_check(button != null, "paused practice exposes its return action")
	if button != null:
		button.grab_focus()
		_key(KEY_ENTER, true)
		await _frames(3)
		_key(KEY_ENTER, false)
	await _frames(4)
	_check(not _main.practice_mode and not _main._has_session and paused and _main.game_menu.screen == "title",
		"Return to title ends practice behind the paused title backing")
	var backing: ColorRect = _main.game_menu._background
	var backing_ink: Color = backing.material.get_shader_parameter("ink")
	_check(backing.is_visible_in_tree() and backing.modulate.a == 1.0 and backing_ink.a == 1.0
		and backing.size == _main.game_menu.overlay.size, "returned title keeps its full opaque backing")
	_check(practiced.get_ref() == null, "returning removes the practice room instead of hiding a live simulation")
	_check([_main.progression, _main.economy, _main.map_state, _main.pressing] == _models,
		"returning reinstates the exact original campaign model objects")
	_check(_campaign_snapshots() == _snapshots and _main.encounters == _encounters,
		"returning preserves every campaign model value and saved choice")
	_check(_disk_bytes() == _disk, "returning from practice writes neither campaign checkpoint")
	var button_continue := _button(_main.game_menu, "Continue")
	_check(button_continue != null, "the existing campaign still has a Continue action")
	if button_continue != null:
		button_continue.grab_focus()
		_key(KEY_ENTER, true)
		await _frames(3)
		_key(KEY_ENTER, false)
	await _physics(4)
	_check(not _main.practice_mode and _main._has_session and _main.world_room_id == &"the_stalls"
		and _main.room_entry_id == &"from_horn_plaza", "Continue restores the actual checkpoint room and arrival")
	_check(not _main.opening.is_open and _main.player.shine == 5 and _main.economy.has_item(&"warm_thread")
		and _main.progression.has_refrain(Progression.Refrain.GATHER) and _main.map_state.owned,
		"Continue restores earned belongings without a practice or opening interlude")

func _defensive_entries() -> void:
	_main._return_to_title()
	await _frames(3)
	_main._start_practice()
	_main._return_to_title()
	await _physics(2)
	await _frames(3)
	_check(not _main.practice_mode and paused and _main.game_menu.screen == "title",
		"canceling entry immediately prevents its deferred callback from unpausing the title")
	_check(_main.progression == _models[0] and _main.map_state == _models[2],
		"a canceled practice entry restores campaign ownership immediately")
	_main._start_practice()
	await _physics(3)
	var practice_room: WeakRef = weakref(_main.room)
	_main._continue_game()
	await _physics(4)
	_check(not _main.practice_mode and practice_room.get_ref() == null and _main.world_room_id == &"the_stalls",
		"direct Continue defensively exits an active practice room")
	_check(_main.progression == _models[0] and _main.economy == _models[1] and _main.player.shine == 5,
		"defensive Continue uses the original campaign models")
	_main._return_to_title()
	await _frames(3)
	_main._start_practice()
	await _physics(3)
	practice_room = weakref(_main.room)
	_main._new_game(false)
	await _physics(4)
	_check(not _main.practice_mode and practice_room.get_ref() == null and _main._has_session
		and _main.world_room_id == &"headshell", "direct New Game exits practice and begins the authored campaign")
	_check(_main.progression == _models[0] and _main.economy == _models[1]
		and _main.progression.snapshot() == Progression.new().snapshot() and _main.player.shine == 0,
		"New Game resets the restored campaign models, not the discarded practice copies")

func _without_a_checkpoint() -> void:
	_main._return_to_title()
	await _frames(3)
	_check(_main.save_store.delete_save(), "remove checkpoint to exercise a first-launch practice visit")
	_main._show_title()
	await _frames(3)
	_check(_button(_main.game_menu, "Continue") == null and _button(_main.game_menu, "Move practice") != null,
		"practice is available before a first campaign save exists")
	var practice_button := _button(_main.game_menu, "Move practice")
	practice_button.grab_focus()
	_joy(JOY_BUTTON_A, true)
	await _frames(3)
	_joy(JOY_BUTTON_A, false)
	await _frames(3)
	await _physics(4)
	_check(_main.practice_mode and not _main._has_session, "first-launch practice still creates no campaign session")
	_check(_main.player.is_on_floor() and _main.player.position.distance_to(_main.room.spawn_pos) < 1.0
		and _main.player._buffer <= 0.0, "controller confirmation cannot become a practice jump")
	_main._pause_game()
	await _frames(3)
	_main._return_to_title()
	await _frames(3)
	_check(not FileAccess.file_exists(_main.save_path) and not FileAccess.file_exists(_main.save_path + ".bak"),
		"first-launch practice, pause and return never create a checkpoint")

func _campaign_snapshots() -> Array:
	return [_models[0].snapshot(), _models[1].snapshot(), _models[2].snapshot(),
		[_models[3].side, _models[3].runtime_left]]

func _disk_bytes() -> Array[PackedByteArray]:
	return [FileAccess.get_file_as_bytes(_main.save_path), FileAccess.get_file_as_bytes(_main.save_path + ".bak")]

func _button(node: Node, text: String) -> Button:
	if node is Button and node.text == text and node.is_visible_in_tree(): return node
	for child in node.get_children():
		var found := _button(child, text)
		if found != null: return found
	return null

func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result

func _release_inputs() -> void:
	for key in [KEY_A, KEY_D, KEY_J, KEY_K, KEY_L, KEY_R, KEY_I, KEY_M, KEY_B, KEY_E, KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
		_key(key, false)
	_joy(JOY_BUTTON_A, false)

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

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
