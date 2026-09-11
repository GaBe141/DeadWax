extends SceneTree
## Native campaign transactions and input boundaries, using only isolated saves.

const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const EconomyScript := preload("res://scripts/economy_state.gd")
const CampaignScript := preload("res://scripts/campaign.gd")
const PatchScript := preload("res://scripts/polish_patch.gd")
const SkipScript := preload("res://scripts/skip.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []
var _strikes := 0
var _purchase_requests := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-economy-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated economy directory")
	await _boot()
	_main._new_game(false)
	await _physics(5)
	await _check_patch_budget()
	await _check_earning()
	await _check_shop_boundary()
	await _check_transactions()
	await _check_continue_and_effects()
	await _check_old_save()
	await _check_gamepad()
	await _close()
	_check(SaveScript.new(_path()).delete_save(), "remove isolated economy checkpoints")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated economy directory")
	if _failures.is_empty():
		print("DEAD WAX ECONOMY PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("ECONOMY FAIL: " + failure)
	quit(1)

func _check_patch_budget() -> void:
	var patches: Array[String] = []
	var first_visit_budget := 0
	for id in CampaignScript.room_ids():
		_main._load_world_room(id)
		await _physics(2)
		for child in _main.room.get_children():
			if child.get_script() != PatchScript:
				continue
			var key := "%s/%s" % [id, child.get_meta("chapter_state_id", "")]
			_check(child.has_meta("chapter_state_id") and key not in patches, "authored wax has a unique persistent currency source: " + key)
			patches.append(key)
			if id in [&"horn_plaza", &"high_street", &"practice_room", &"the_stalls", &"bootlegger"]:
				first_visit_budget += 1
	var total_price := 0
	for item in EconomyScript.catalog():
		total_price += int(item.price)
	_check(patches.size() == 9, "the authored campaign offers nine one-time Shine patches")
	_check(total_price == patches.size(), "all catalog items are affordable from the authored patches without farming")
	_check(first_visit_budget == 5 and first_visit_budget >= int(EconomyScript.item(&"spare_groove").price)
		and first_visit_budget >= int(EconomyScript.item(&"soft_lining").price), "either functional upgrade is affordable at the first shop visit")
	_check(first_visit_budget < int(EconomyScript.item(&"spare_groove").price) + int(EconomyScript.item(&"soft_lining").price), "owning both functional upgrades rewards a later return")

func _check_earning() -> void:
	_main._new_game(false)
	await _physics(4)
	_check(_main.economy.snapshot() == {"shine": 0, "purchases": []} and _main.player.shine == 0, "new game starts with an empty shared wallet")
	_check(_main._health == 3 and _main.economy.max_health() == 3, "new game retains the original three-hit capacity")
	# Income is measured after finding the Hood; a fresh wallet still starts empty.
	_main.abilities.unlock_ability(&"hood")
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(4)
	var patch := _persistent(&"horn_wax")
	await _stand(patch.position)
	_key(KEY_K, true)
	await create_timer(1.45).timeout
	_check(patch.done and _main.economy.balance == 1 and _main.player.shine == 1, "actual Hood polishing credits exactly one Shine to the shared wallet")
	await create_timer(0.3).timeout
	_check(_main.economy.balance == 1, "holding the Hood over finished wax cannot mint again")
	_key(KEY_K, false)
	await _physics(3)
	var saved: Dictionary = _main.save_store.load_game()
	_check(saved.get("shine") == 1 and saved.encounters.get("horn_plaza/horn_wax") == "polished", "polishing autosaves balance together with its exhausted source")
	_main._load_world_room(&"headshell", &"from_horn_plaza")
	await _physics(2)
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(3)
	patch = _persistent(&"horn_wax")
	_check(patch.done, "returning restores the polished source")
	await _stand(patch.position)
	_key(KEY_K, true)
	await create_timer(1.3).timeout
	_key(KEY_K, false)
	_check(_main.economy.balance == 1, "room recreation cannot farm polished wax")
	_main._load_world_room(&"groove_yard", &"from_the_stalls")
	await _physics(3)
	var voice := _persistent(&"yard_first_voice")
	voice._down()
	await _frames(3)
	_check(_main.economy.balance == 1, "a live shatter outcome gives no killing currency")
	_main._load_world_room(&"addie", &"from_whistlers")
	await _physics(3)
	var addie := _persistent(&"addie")
	addie._free()
	await _frames(3)
	_check(_main.economy.balance == 1, "a live mercy outcome is not a money farm either")

func _check_shop_boundary() -> void:
	_main._new_game(false)
	await _physics(4)
	await _tap(KEY_B)
	_check(not _main.shop.is_open and not paused, "trade input cannot open a shop in another room")
	_check(not _main._purchase_item(&"spare_groove"), "purchase intent is rejected while the shop is closed")
	_main._load_world_room(&"bootlegger", &"from_overture_stair")
	await _physics(4)
	await _tap(KEY_B)
	_check(not _main.shop.is_open and not paused, "trade input cannot open the counter remotely")
	var resident: Node2D = _main.room.get_node("Bootlegger")
	await _stand(resident.position + Vector2(-42, 0))
	var line_before: int = resident._line
	await _tap(KEY_E)
	_check(resident._line == (line_before + 1) % resident.lines.size() and not _main.shop.is_open, "E still advances Bootlegger conversation without opening the shop")
	_key(KEY_SPACE, true)
	await _physics(4)
	_key(KEY_SPACE, false)
	await _tap(KEY_B)
	_check(not _main.player.is_on_floor() and not _main.shop.is_open, "an actual airborne B press cannot trade")
	await _land()
	await _stand(resident.position + Vector2(-42, 0))
	_key(KEY_B, true)
	await _frames(10)
	_check(_main.shop.is_open and paused, "grounded B opens a paused shop at the counter")
	_check(_main.economy.balance == 0 and _main.economy.snapshot().purchases.is_empty(), "holding the opening input cannot buy anything")
	_key(KEY_B, false)
	await _frames(3)
	var wallet: Dictionary = _main.economy.snapshot()
	_check(not _main._purchase_item(&"spare_groove") and _main.economy.snapshot() == wallet, "insufficient Shine leaves the complete wallet unchanged")
	_check(not _main._purchase_item(&"unknown_item") and _main.economy.snapshot() == wallet, "unknown product intent cannot debit or grant anything")
	var position_before: Vector2 = _main.player.position
	var pose_before: Dictionary = _main.player._animation_pose().duplicate(true)
	var strikes_before := _strikes
	for key in [KEY_I, KEY_E, KEY_R, KEY_J, KEY_SPACE, KEY_D]:
		await _tap(key)
	_check(not _main.inventory.is_open() and _main.shop.is_open and paused, "shop excludes the Book and preserves its pause")
	_check(_main.world_room_id == &"bootlegger" and not _main._transition_pending, "shop input cannot enter a passage")
	_check(_main.player.position == position_before and _strikes == strikes_before, "shop input cannot move, recover, jump or strike")
	_check(_main.player._animation_pose() == pose_before, "shop pause freezes player animation")
	_main.player.position = Vector2(1500, 574)
	_main.economy.credit(9)
	wallet = _main.economy.snapshot()
	_check(not _main._purchase_item(&"spare_groove") and _main.economy.snapshot() == wallet, "transaction rechecks proximity even if a stale shop is open")
	_main.player.position = position_before
	await _tap(KEY_ESCAPE)
	await _physics(3)
	_check(not _main.shop.is_open and not paused and not _main.game_menu.is_open, "Escape closes the shop without opening the pause menu")
	_check(_main.player.is_on_floor() and _main.player.position.is_equal_approx(position_before) and _strikes == strikes_before, "closing the shop leaks no pending jump, strike or recovery")

func _check_transactions() -> void:
	# Nine authored Shine was placed in this isolated wallet above. Product UI
	# requests an intent; only Main performs the purchase and synchronous save.
	await _tap(KEY_B)
	_check(_main.shop.is_open, "shop reopens normally after close")
	_main.shop.product_button(&"spare_groove").grab_focus()
	await _frames(2)
	var initial: Dictionary = _main.economy.snapshot()
	await _tap(KEY_ENTER)
	_check(_main.economy.snapshot() == initial and _main.shop.buy_button().has_focus(), "first Enter selects a product and focuses explicit Buy")
	var requests_before := _purchase_requests
	_key(KEY_ENTER, true)
	await _frames(10)
	_key(KEY_ENTER, true, true)
	await _frames(3)
	_key(KEY_ENTER, false)
	await _frames(3)
	_check(_purchase_requests == requests_before + 1, "holding and repeating Enter emits at most one purchase intent")
	_check(_main.economy.balance == 5 and _main.economy.has_item(&"spare_groove"), "explicit Buy spends four Shine and owns spare groove exactly once")
	_check(_main.player.shine == 5 and _main.economy.max_health() == 4, "the player and economy immediately share the purchased capacity and balance")
	var saved: Dictionary = _main.save_store.load_game()
	_check(saved.get("shine") == 5 and saved.get("purchases", []).has("spare_groove"), "successful purchase is already on disk when the input returns")
	var owned: Dictionary = _main.economy.snapshot()
	_check(not _main._purchase_item(&"spare_groove") and _main.economy.snapshot() == owned, "owned purchases cannot charge twice")
	# A directory occupying the stage filename forces a real, deterministic
	# filesystem failure while leaving the valid checkpoint available to read.
	_check(DirAccess.make_dir_absolute(_path() + ".tmp") == OK, "block only the isolated staged save")
	_check(not _main._purchase_item(&"soft_lining"), "Main rejects a transaction whose synchronous save fails")
	_check(_main.economy.snapshot() == owned and not _main.economy.has_item(&"soft_lining"), "failed save rolls back both currency and ownership")
	_check(is_equal_approx(_main.economy.hood_speed_multiplier(), 0.62), "failed purchase rolls back its movement effect")
	_check(is_equal_approx(_main.player.hood_speed_mult, 0.62), "a rejected transaction never applies the player upgrade")
	_check(_main.save_store.load_game() == saved, "failed purchase preserves the last valid disk checkpoint")
	_check(_main.shop.is_open and paused and _main.shop.balance_text().contains("5"), "failed purchase keeps the shop open with the restored balance")
	await _frames(5)
	_check(_main.economy.snapshot() == owned, "deferred work cannot revive a rolled-back purchase")
	_check(DirAccess.remove_absolute(_path() + ".tmp") == OK, "unblock the isolated staged save")
	_check(_main._purchase_item(&"soft_lining"), "the same purchase can succeed after storage recovers")
	_check(_main.economy.balance == 2 and _main.economy.has_item(&"soft_lining"), "soft lining costs three Shine once")
	_check(_main._purchase_item(&"warm_thread"), "the final two Shine buy the cosmetic thread")
	_check(_main.economy.balance == 0 and _main.economy.snapshot().purchases.size() == 3, "all nine Shine buy the three catalog items exactly")
	_check(_main.player.warm_thread and _main._max_health() == 4 and is_equal_approx(_main.player.hood_speed_mult, 0.75), "warm thread applies its cosmetic flag without changing either functional upgrade")
	_check(_main.progression.snapshot() == {"version": 1, "refrains": [], "techniques": []}, "shopping grants no traversal permission or combat knowledge")
	_main._close_shop()
	await _physics(4)

func _check_continue_and_effects() -> void:
	await _close()
	await _boot()
	_main._continue_game()
	await _physics(5)
	_check(_main.world_room_id == &"bootlegger" and _main.economy.balance == 0 and _main.economy.snapshot().purchases.size() == 3, "Continue restores spent currency and all purchases")
	_check(_main._health == 4 and _main.economy.max_health() == 4, "Continue starts at the entry with the owned four-hit capacity")
	_check(_main.player.warm_thread, "Continue restores the visible warm thread")
	await _check_walk_speed(0.75, "owned soft lining")
	_main._load_world_room(&"headshell")
	await _physics(4)
	await _stand(Vector2(500, 574))
	for hit in range(3):
		_main.player.take_hit(_main.player.position + Vector2(100, 0))
	_check(_main._health == 1 and not _main._respawn_pending, "spare groove survives three actual player hit signals")
	_main.player.take_hit(_main.player.position + Vector2(100, 0))
	await _physics(3)
	_check(_main._health == 4 and _main.player.position.distance_to(_main.room.entry_position(_main.room_entry_id)) < 5, "the fourth hit recovers at the room entry with owned full health")
	_check(_main.economy.balance == 0 and _main.economy.snapshot().purchases.size() == 3, "recovery retains every purchase and the spent wallet")
	_main._new_game(false)
	await _physics(5)
	_check(_main._health == 3 and _main.economy.snapshot() == {"shine": 0, "purchases": []}, "New Game clears purchases, money and spare capacity")
	_check(not _main.player.warm_thread, "New Game removes the old cosmetic thread")
	await _check_walk_speed(0.62, "an unupgraded new game")
	var disk: Dictionary = _main.save_store.load_game()
	_check(disk.get("shine") == 0 and disk.get("purchases", ["unexpected"]).is_empty(), "the new pressing saves the reset economy")

func _check_walk_speed(multiplier: float, label: String) -> void:
	# Compare purchased Hood handling after its separate world discovery.
	_main.abilities.unlock_ability(&"hood")
	_main._load_world_room(&"practice_room", &"from_high_street")
	await _physics(3)
	await _stand(Vector2(700, 574))
	var collider: CollisionShape2D = _main.player.get_child(0) as CollisionShape2D
	var original_size := Vector2.ZERO
	if collider != null:
		original_size = collider.shape.size
	_key(KEY_K, true)
	_key(KEY_D, true)
	await _physics(18)
	_check(is_equal_approx(_main.player.velocity.x, SkipScript.RUN_SPEED * multiplier), label + " uses the expected actual Hood walking speed")
	_check(_main.player.hooded and _main.player.noise < 0.05, label + " remains a quiet Hood walk")
	if collider != null:
		_check(collider.shape.size == original_size and original_size == Vector2(34, 52), label + " retains the authored player collider")
	_key(KEY_D, false)
	_key(KEY_K, false)
	await _physics(8)

func _check_old_save() -> void:
	await _close()
	# Write actual old JSON without the purchases field, before SaveStore can
	# normalize it. Continue must migrate it without inventing an owned upgrade.
	var old := {"version": 1, "room_id": "bootlegger", "entry_id": "from_overture_stair", "shine": 6,
		"progression": {"version": 1, "refrains": [], "techniques": ["count-in"]},
		"encounters": {"horn_plaza/horn_wax": "polished", "addie/addie": "freed"}, "completed": false}
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	_check(file != null, "open the isolated pre-shop save fixture")
	if file == null:
		return
	file.store_string(JSON.stringify(old))
	file.close()
	await _boot()
	_main._continue_game()
	await _physics(5)
	_check(_main.world_room_id == &"bootlegger" and _main.room_entry_id == &"from_overture_stair", "pre-shop Continue preserves its old room and arrival")
	_check(_main.player.shine == 6 and _main.economy.snapshot() == {"shine": 6, "purchases": []}, "pre-shop Continue preserves Shine with no invented purchases")
	_check(_main._health == 3 and _main.progression.snapshot() == old.progression and _main.encounters == old.encounters, "pre-shop Continue preserves old health rules, knowledge and choices")
	_main._load_world_room(&"horn_plaza", &"from_headshell")
	await _physics(3)
	var patch := _persistent(&"horn_wax")
	_check(patch.done, "old polished outcomes remain exhausted after migration")
	await _stand(patch.position)
	_key(KEY_K, true)
	await create_timer(1.3).timeout
	_key(KEY_K, false)
	_check(_main.economy.balance == 6, "loading an old checkpoint cannot re-earn its saved wax")

func _check_gamepad() -> void:
	_main._load_world_room(&"bootlegger", &"from_overture_stair")
	await _physics(3)
	await _stand(Vector2(718, 574))
	var before: Dictionary = _main.economy.snapshot()
	_joy(JOY_BUTTON_DPAD_UP, true)
	await _frames(8)
	_check(_main.shop.is_open and paused and _main.shop.selected_item() == &"spare_groove", "held D-pad Up opens the shop without leaking into initial navigation")
	_check(_main.economy.snapshot() == before, "the controller opening button never purchases")
	_joy(JOY_BUTTON_DPAD_UP, false)
	await _frames(3)
	await _tap_pad(JOY_BUTTON_DPAD_UP)
	_check(_main.shop.is_open and _main.shop.selected_item() == &"warm_thread", "after release a fresh D-pad Up navigates the catalog instead of closing trade")
	await _tap_pad(JOY_BUTTON_A)
	_check(_main.shop.buy_button().has_focus() and _main.economy.snapshot() == before, "controller A inspects the selected product before any debit")
	var requests_before := _purchase_requests
	_joy(JOY_BUTTON_A, true)
	await _frames(8)
	_joy(JOY_BUTTON_A, false)
	await _frames(4)
	_check(_purchase_requests == requests_before + 1 and _main.economy.balance == 4 and _main.economy.has_item(&"warm_thread"), "a second controller A buys the selected thread once")
	var position_before: Vector2 = _main.player.position
	await _tap_pad(JOY_BUTTON_B)
	await _physics(4)
	_check(not _main.shop.is_open and not paused and not _main.game_menu.is_open, "controller B leaves the shop and resumes campaign play")
	_check(_main.player.is_on_floor() and _main.player.position.is_equal_approx(position_before), "controller close leaves the player at the counter")
	# UI accept also means Jump in the world. Exercise the Leave button itself,
	# including a held accept, instead of relying only on cancel-key behavior.
	for use_gamepad in [true, false]:
		await _tap(KEY_B)
		_main.shop._leave.grab_focus()
		await _frames(2)
		if use_gamepad:
			_joy(JOY_BUTTON_A, true)
		else:
			_key(KEY_SPACE, true)
		await _frames(8)
		if use_gamepad:
			_joy(JOY_BUTTON_A, false)
		else:
			_key(KEY_SPACE, false)
		await _physics(5)
		var label := "controller A" if use_gamepad else "Space"
		_check(not _main.shop.is_open and not paused, label + " activates the focused Leave button")
		_check(_main.player.is_on_floor() and _main.player.position.is_equal_approx(position_before)
			and _main.player._buffer <= 0.0, label + " Leave activation cannot leak a jump into the resumed world")

func _persistent(id: StringName) -> Node2D:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id:
			return child
	return null

func _path() -> String:
	return _directory + "/checkpoint.json"

func _stand(position: Vector2) -> void:
	_main.player.position = position
	_main.player.velocity = Vector2.ZERO
	await _physics(5)

func _land() -> void:
	for frame in range(70):
		await _physics(1)
		if _main.player.is_on_floor():
			return
	_check(false, "player lands after the airborne shop attempt")

func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(3)
	_key(code, false)
	await _frames(3)

func _key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)

func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _tap_pad(button: JoyButton) -> void:
	_joy(button, true)
	await _frames(3)
	_joy(button, false)
	await _frames(3)

func _boot() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _path()
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main.player.struck.connect(func(_pos: Vector2, _big: bool, _launched: bool) -> void: _strikes += 1)
	_main.shop.purchase_requested.connect(func(_id: StringName) -> void: _purchase_requests += 1)

func _close() -> void:
	for key in [KEY_B, KEY_E, KEY_ENTER, KEY_ESCAPE, KEY_I, KEY_J, KEY_K, KEY_L, KEY_R, KEY_SPACE, KEY_D]:
		_key(key, false)
	for button in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_A, JOY_BUTTON_B]:
		_joy(button, false)
	if is_instance_valid(_main):
		_main.queue_free()
		await _frames(3)
	paused = false

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
