extends SceneTree
## Menu motion may run while paused. Intent, focus and truthful model values
## must never wait for it; all checkpoints here are private to this test run.
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-gui-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated GUI fixture")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(2)
	await _title_and_pause()
	await _book()
	await _shop()
	await _reduced_motion()
	await _hud()
	await _narrow_and_cleanup()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated GUI checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated GUI directory")
	if _failures.is_empty():
		print("DEAD WAX GUI ANIMATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("GUI ANIMATION FAIL: " + failure)
	quit(1)

func _title_and_pause() -> void:
	var menu: CanvasLayer = _main.game_menu
	_check(paused and menu.is_open and menu.screen == "title", "title is immediately open and owns the pause")
	var initial := _visual_tree(menu.overlay)
	var world := _world_snapshot()
	var phase: float = menu._record.phase
	await _frames(8)
	_check(_visual_tree(menu.overlay) != initial, "title entrance advances on the paused tree")
	_check(menu._record.phase > phase, "record grooves turn while the title pauses gameplay")
	_check(_world_snapshot() == world, "title animation cannot advance the world underneath")
	_check(_focus_inside(menu.overlay), "title focus is available before entrance completes")
	# Rebuild several pages in one turn. Old deferred work must not reclaim focus.
	var old_page: WeakRef = weakref(menu._page)
	menu._open_subpage("settings")
	menu._open_subpage("controls")
	menu.close_menu()
	menu.show_title(false)
	await _frames(3)
	_check(old_page.get_ref() == null, "superseded menu pages are freed during rapid navigation")
	_check(menu.screen == "title" and _focus_inside(menu.overlay), "rapid page replacement focuses the current title")
	await _tap(KEY_ENTER)
	await _physics(3)
	_check(_main._has_session and not paused and not menu.is_open, "New game accepts physical Enter during its entrance")
	_main._pause_game()
	var hud := _hud_snapshot()
	world = _world_snapshot()
	initial = _visual_tree(menu.overlay)
	await _frames(8)
	_check(_visual_tree(menu.overlay) != initial, "pause menu entrance keeps moving")
	_check(_world_snapshot() == world and _hud_snapshot() == hud, "pause menu freezes both world and in-progress HUD motion")
	menu._show_screen("pause")
	await _frames(1)
	await _tap(KEY_ENTER)
	await _physics(2)
	_check(not paused and not menu.is_open, "Resume accepts physical Enter without waiting for its reveal")
	await _frames(18)
	_check(not menu.overlay.visible and not _focus_inside(menu.overlay), "finished entrance work cannot reshow a closed menu or steal focus")

func _book() -> void:
	_main.economy.restore(7, ["warm_thread"])
	_main.progression.discover_technique(ProgressionScript.Technique.COUNT_IN)
	var book: CanvasLayer = _main.inventory
	var model := _model_snapshot()
	book.open_inventory()
	_check(book.is_open() and paused and book.shine_text().contains("7"), "Book opens with the current Shine before animation runs")
	_check(book._wares_label.text.contains("Warm Thread"), "Book ownership is truthful immediately on entry")
	book._select_slot(&"count-in")
	_check(String(book.detail_title()).to_upper() == "COUNT-IN" and book.selected_slot() == &"count-in", "Book selection updates its detail synchronously")
	await _frames(1)
	var before := _visual_tree(book.overlay)
	var world := _world_snapshot()
	await _frames(8)
	_check(_visual_tree(book.overlay) != before, "Book panes reveal while the world is paused")
	_check(_world_snapshot() == world and _model_snapshot() == model, "Book animation changes no movement, money, purchases or knowledge")
	book.close_inventory()
	book.open_inventory()
	book._select_slot(&"hood")
	book.close_inventory()
	book.open_inventory()
	book._select_slot(&"set")
	await _frames(3)
	_check(book.selected_slot() == &"set" and book.detail_title() == "SET" and _focus_inside(book.overlay), "rapid Book close/reopen preserves the newest selected detail and focus")
	await _tap(KEY_ESCAPE)
	_check(not book.is_open() and not paused, "physical Escape closes Book during its entrance")
	await _frames(20)
	_check(not book.overlay.visible and not _focus_inside(book.overlay), "old Book animation work cannot reopen or refocus it")

func _shop() -> void:
	_main._load_world_room(&"bootlegger")
	await _physics(3)
	_main.player.position = Vector2(720, 574)
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_main.economy.restore(7, ["warm_thread"])
	_main._open_shop()
	var shop: CanvasLayer = _main.shop
	var model := _model_snapshot()
	_check(shop.is_open and paused and shop.balance_text().contains("007"), "shop displays the true balance immediately on opening")
	shop._select(&"soft_lining", false)
	_check(shop.selected_item() == &"soft_lining" and shop._detail_title.text == "SOFT LINING" and not shop.buy_button().disabled,
		"shop selection and affordable purchase state do not wait for animation")
	var before := _visual_tree(shop.overlay)
	var world := _world_snapshot()
	var hud := _hud_snapshot()
	await _frames(8)
	_check(_visual_tree(shop.overlay) != before, "shop reveals while its gameplay is paused")
	_check(_model_snapshot() == model and _world_snapshot() == world and _hud_snapshot() == hud, "shop motion alone cannot alter wallet, world or HUD")
	# A legitimate explicit purchase is allowed before the entrance settles.
	shop.buy_button().grab_focus()
	await _tap(KEY_ENTER)
	_check(_main.economy.balance == 4 and _main.economy.has_item(&"soft_lining"), "physical Buy during animation makes one authorized transaction")
	_check(shop.balance_text().contains("004") and shop.buy_button().disabled, "purchase balance and owned state refresh synchronously")
	var purchased := _model_snapshot()
	await _frames(20)
	_check(_model_snapshot() == purchased, "purchase pulse cannot repeat a debit or reward")
	_main._close_shop()
	await _physics(2)
	_main._open_shop()
	_main._close_shop()
	await _physics(2)
	_main._open_shop()
	await _frames(2)
	_check(shop.is_open and paused and _focus_inside(shop.overlay), "rapid shop close/reopen ends with the current shop focused")
	await _tap(KEY_ESCAPE)
	await _physics(2)
	_check(not shop.is_open and not paused and not _focus_inside(shop.overlay), "shop Escape remains immediate during reveal")
	await _frames(18)
	_check(not shop.overlay.visible and _model_snapshot() == purchased, "closed shop leaves no stale visual or transaction callback")

func _reduced_motion() -> void:
	_main._pause_game()
	await _frames(2)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	var menu: CanvasLayer = _main.game_menu
	var reduced := _visual_tree(menu.overlay)
	var phase: float = menu._record.phase
	var focus := root.gui_get_focus_owner()
	await _frames(20)
	_check(_visual_tree(menu.overlay) == reduced and is_equal_approx(menu._record.phase, phase), "enabling reduced motion settles an active menu and record immediately")
	_check(root.gui_get_focus_owner() == focus and _focus_inside(menu.overlay), "reduced motion preserves the focused semantic action")
	menu._open_subpage("settings")
	await _frames(3)
	_check(_focus_inside(menu.overlay) and _fully_visible(menu._page), "settings remain fully visible and focusable with reduced motion")
	_main._resume_game()
	await _physics(2)
	for panel in [_main.inventory, _main.shop]:
		_main._settings.reduced_motion = false
		_main._apply_settings()
		if panel == _main.inventory: panel.open_inventory()
		else: _main._open_shop()
		await _frames(2)
		_main._settings.reduced_motion = true
		_main._apply_settings()
		await _frames(1)
		var snapshot := _visual_tree(panel.overlay)
		await _frames(18)
		_check(snapshot == _visual_tree(panel.overlay), panel.name + " settles active pane and focus animation when reduced motion changes")
		_check(_focus_inside(panel.overlay), panel.name + " retains focus after motion is disabled")
		if panel == _main.inventory: panel.close_inventory()
		else: _main._close_shop()
		await _physics(2)

func _hud() -> void:
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_main._load_world_room(&"horn_plaza")
	await _physics(1)
	var model := _model_snapshot()
	var before := _hud_snapshot()
	await _physics(8)
	_check(_hud_snapshot() != before, "room HUD visibly arrives during normal gameplay")
	_check(_model_snapshot() == model, "HUD room presentation changes no model values")
	var balance: int = _main.economy.balance
	_main.player.add_shine(1)
	await _physics(1)
	_check(_main.economy.balance == balance + 1 and _main.status.text.contains("SHINE %02d" % (balance + 1)), "real Shine credit updates the stored and displayed balance immediately")
	_check(_main.hud_motion.shine_notice.visible and _main.hud_motion.shine_notice.text.contains("1"), "earning Shine starts a truthful footer receipt")
	_main._flash("RUNG BACK !!")
	_main._pause_game()
	var frozen := _hud_snapshot()
	await _frames(18)
	_check(_hud_snapshot() == frozen, "pause freezes status pulse, feedback stamp and Shine receipt")
	_main._resume_game()
	await _physics(2)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	var motion := _hud_transforms()
	await _physics(8)
	_check(_hud_transforms() == motion, "reduced motion keeps HUD transforms settled while text timers continue")
	_main._respawn()
	_check(not _main.hud_motion.shine_notice.visible, "recovery clears transient earned-Shine receipt")
	_check(_main.economy.balance == balance + 1, "settling and clearing the receipt cannot credit Shine twice")

func _narrow_and_cleanup() -> void:
	root.min_size = Vector2i.ZERO
	root.content_scale_size = Vector2i(880, 720)
	root.size = Vector2i(880, 720)
	await _frames(3)
	_main._pause_game()
	await _frames(3)
	_check(not _main.game_menu._art.visible and _focus_inside(_main.game_menu.overlay), "narrow pause keeps its actions available when the record is hidden")
	_check(_inside_viewport(_main.game_menu._first_focus), "narrow default action has an onscreen hit target")
	_main._resume_game()
	await _physics(2)
	_main.inventory.open_inventory()
	await _frames(3)
	_check(_focus_inside(_main.inventory.overlay) and _inside_viewport(root.gui_get_focus_owner()), "narrow Book preserves an onscreen focused card")
	_main.inventory.close_inventory()
	await _physics(2)
	_main._load_world_room(&"bootlegger")
	await _physics(3)
	_main.player.position = Vector2(720, 574)
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_main._open_shop()
	await _frames(3)
	_check(_focus_inside(_main.shop.overlay) and _inside_viewport(root.gui_get_focus_owner()), "narrow shop preserves an onscreen focused product")
	_main._close_shop()
	await _physics(2)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _frames(2)
	for panel in [_main.game_menu, _main.inventory, _main.shop]:
		var motion: Node = panel._motion
		_check(motion != null and motion.active_count() == 0, panel.name + " retains no running animation after close")

func _visual_tree(node: Node) -> Dictionary:
	var result := {}
	for child in _descendants(node):
		if child is Control:
			result[child.get_instance_id()] = [child.position, child.scale, child.rotation, child.modulate, child.self_modulate, child.visible]
			if "level" in child:
				result[child.get_instance_id()].append([child.level, child.press_age])
	return result

func _hud_snapshot() -> Dictionary:
	var result := _hud_transforms()
	result["feedback_age"] = _main._fb_t
	result["feedback_alpha"] = _main.feedback.modulate.a
	result["save_age"] = _main._save_message_time
	result["status"] = _main.status.text
	result["receipt"] = [_main.hud_motion.shine_notice.text, _main.hud_motion.shine_notice.visible, _main.hud_motion.shine_notice.modulate]
	return result

func _hud_transforms() -> Dictionary:
	var result := {}
	for control in [_main.title, _main.subtitle, _main.title_rule, _main.feedback, _main.status, _main.hud_motion.shine_notice]:
		result[control.get_instance_id()] = [control.position, control.scale, control.rotation]
	return result

func _world_snapshot() -> Dictionary:
	return {"room": _main.world_room_id, "player": _main.player.transform, "pose": _main.player._animation_pose().duplicate(true),
		"atmosphere": _main.room.atmosphere.visual_snapshot().duplicate(true), "lighting": _main.room.lighting.visual_snapshot().duplicate(true)}

func _model_snapshot() -> Dictionary:
	return {"wallet": _main.economy.snapshot(), "progression": _main.progression.snapshot(), "encounters": _main.encounters.duplicate(true)}

func _focus_inside(control: Control) -> bool:
	var focused := root.gui_get_focus_owner()
	return focused != null and control.is_ancestor_of(focused) and focused.is_visible_in_tree()

func _fully_visible(control: Control) -> bool:
	return control.is_visible_in_tree() and is_equal_approx(control.modulate.a, 1.0)

func _inside_viewport(control: Control) -> bool:
	if control == null: return false
	return Rect2(Vector2.ZERO, Vector2(root.content_scale_size)).encloses(control.get_global_rect())

func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result

func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(1)
	_key(code, false)
	await _frames(1)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count): await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
