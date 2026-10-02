extends SceneTree
## Exploration equipment and regional leads remain read-only, reachable views.
const Book := preload("res://scripts/inventory_menu.gd")
const MapMenu := preload("res://scripts/map_menu.gd")
const Collection := preload("res://scripts/collection_state.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const LostPressings := preload("res://scripts/lost_pressings_catalog.gd")
const Chart := preload("res://scripts/campaign_chart.gd")
const Exploration := preload("res://scripts/exploration_state.gd")
var _checks := 0
var _failures: Array[String] = []
var _intents: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	for action in ["map", "inventory", "trade", "enter_passage", "strike", "jump", "lift", "set", "restart", "flip", "pause_game"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await _book_presentation()
	await _map_presentation()
	if _failures.is_empty():
		print("DEAD WAX LOST PRESSINGS BOOK PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures: push_error("LOST PRESSINGS BOOK FAIL: " + failure)
		quit(1)

func _book_presentation() -> void:
	var collection := Collection.new()
	var state := collection.snapshot()
	state.offcuts = 999
	for id in state.hunts:
		state.hunts[id] = {"discovered": true, "wins": 100, "dry": 0}
	_check(collection.restore_snapshot(state), "populated trial fixture restores")
	var book := Book.new()
	book.collection = collection
	book.set_reduced_motion(true)
	root.add_child(book)
	book.equip_requested.connect(func(id: String) -> void: _intents.append("equip:" + id))
	book.unequip_requested.connect(func(slot: String) -> void: _intents.append("remove:" + slot))
	book.craft_requested.connect(func(id: String) -> void: _intents.append("craft:" + id))
	await _frames(3)
	book.open_inventory()
	book.select_page("equipment", true)
	await _frames(4)
	var pages: Control = book._collection_pages
	_check(pages._selected_item == "copper_stylus", "new equipment page opens on the Lost Pressings group")
	_check(pages._gear_buttons.size() == 15 and pages._completion.text == "EQUIPMENT   00 / 15", "all fifteen fitting cards have honest overall count")
	_check(pages._lost_completion.text == "LOST PRESSINGS   0 / 3 FOUND"
		and pages._trial_completion.text == "ECHO TRIAL PRESSINGS   0 / 12 FOUND", "exploration and trial progress remain separate")
	for entry in LostPressings.entries():
		pages.select_item(String(entry.id))
		_check(pages._gear_source.text.contains(String(entry.clue)), "missing piece has its authored exploration lead")
		_check(pages._gear_odds.text.contains("guaranteed find") and not pages._gear_odds.text.contains("clears"), "exploration notes never print trial odds or pity")
		_check(pages._gear_action.disabled and not pages._recipe.text.contains("Offcut"), "trial mastery and materials cannot enable binding a Lost Pressing")
		pages._gear_action.pressed.emit()
	_check(_intents.is_empty() and collection.snapshot() == state, "reading or pressing missing discoveries cannot craft, grant or spend")
	state.owned = ["copper_stylus", "seam_lining", "dusk_seal", "quicksilver_tip"]
	_check(collection.restore_snapshot(state), "found exploration and trial equipment restore together")
	book.close_inventory()
	book.open_inventory()
	book.select_page("equipment", true)
	await _frames(4)
	_check(pages._completion.text == "EQUIPMENT   04 / 15" and pages._lost_completion.text.contains("3 / 3")
		and pages._trial_completion.text.contains("1 / 12"), "reopening reads silent restoration without conflating the two sources")
	for entry in LostPressings.entries():
		pages.select_item(String(entry.id))
		_check(not pages._gear_action.disabled and pages._gear_action.text.begins_with("Fit "), "each carried Lost Pressing can request its ordinary slot fit")
		pages._gear_action.pressed.emit()
		_check(_intents.back() == "equip:" + String(entry.id), "fit emits exact item intent")
	_check(collection.snapshot() == state and _intents.size() == 3, "fitting view leaves all ownership, slots and trial state with Main")
	_check(collection.equip("dusk_seal"), "fixture equips carried seal")
	book.refresh_collection()
	pages.select_item("dusk_seal")
	_check(pages._gear_action.text == "Remove charm" and pages._slot_names.charm.text == "Dusk Seal", "successful fitting snapshot presents occupied charm slot")
	pages._gear_action.pressed.emit()
	_check(_intents.back() == "remove:charm" and collection.snapshot().equipped.charm == "dusk_seal", "removal remains an intent")
	state = collection.snapshot()
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _frames(5)
		for entry in LostPressings.entries():
			pages.select_item(String(entry.id))
			pages.focus_selected()
			await _frames(4)
			var button: Button = pages._gear_buttons[String(entry.id)]
			_check(root.gui_get_focus_owner() == button and _inside(button, dimensions), "every Lost Pressing card can scroll into focus at " + str(dimensions))
			_check(_inside(pages._gear_action, dimensions), "fit action stays visible alongside scrolling exploration notes")
			_key(KEY_RIGHT, true)
			await _frames(2)
			_key(KEY_RIGHT, false)
			_check(root.gui_get_focus_owner() == pages._gear_action, "keyboard right reaches every carried Lost Pressing action")
		pages.select_item("copper_stylus")
		pages.focus_selected()
		await _frames(4)
		await _capture("equipment-%d" % dimensions.x)
		var down := InputEventJoypadButton.new()
		down.button_index = JOY_BUTTON_DPAD_DOWN
		down.pressed = true
		Input.parse_input_event(down)
		await _frames(3)
		down.pressed = false
		Input.parse_input_event(down)
		_check(root.gui_get_focus_owner() == pages._gear_buttons.seam_lining, "controller down moves between Lost Pressing cards")
	_check(collection.snapshot() == state, "focus, resizing and navigation cannot mutate equipment")
	book.close_inventory()
	book.free()
	await _frames(2)

func _map_presentation() -> void:
	var collection := Collection.new()
	var exploration := Exploration.new()
	var menu := MapMenu.new()
	menu.collection = collection
	menu.exploration = exploration
	menu.set_reduced_motion(true)
	root.add_child(menu)
	await _frames(3)
	var snapshot := {"owned": true, "visited": ["headshell"], "current_room": "headshell"}
	var original := snapshot.duplicate(true)
	var state := collection.snapshot()
	menu.show_map(snapshot)
	_check(menu.lost_pressings_status_text().contains("0 / 2 FOUND"), "Label page counts its two exploration finds")
	menu._select_region(&"overture")
	_check(menu.lost_pressings_status_text().contains("0 / 1 FOUND"), "Overture page counts its separate find")
	_check(not menu.lost_pressings_status_text().contains("Addie") and not menu.lost_pressings_status_text().contains("Stalls"), "regional status reveals no unvisited room name")
	menu._select_region(&"unplayed")
	_check(menu.lost_pressings_status_text().is_empty() and not menu._lost_status.visible, "regions without a Lost Pressing do not advertise a false hunt")
	_check(collection.snapshot() == state and snapshot == original and exploration.snapshot().opened.is_empty(), "map browsing cannot acquire gear, open routes or change supplied visit history")
	state.owned = ["copper_stylus", "dusk_seal"]
	collection.restore_snapshot(state)
	menu._select_region(&"label")
	_check(menu.lost_pressings_status_text().contains("0 / 2 FOUND"), "open map keeps its snapshot until refreshed")
	menu.close_map()
	menu.show_map(snapshot)
	_check(menu.lost_pressings_status_text().contains("1 / 2 FOUND"), "reopening reads saved Label ownership")
	menu._select_region(&"overture")
	_check(menu.lost_pressings_status_text().contains("1 / 1 FOUND"), "Overture ownership is counted independently")
	var visited: Array[String] = []
	for id in Chart.room_ids(): visited.append(String(id))
	menu.show_map({"owned": true, "visited": visited, "current_room": "headshell"})
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _frames(5)
		for region in [&"label", &"overture"]:
			menu._select_region(region)
			await _frames(4)
			_check(_inside(menu._lost_status, dimensions) and _inside(menu.close_button(), dimensions), "regional lead and close action fit at " + str(dimensions))
			_check(menu._chart.size.y > 180, "Lost Pressings line preserves usable chart height")
			await _capture("map-%s-%d" % [region, dimensions.x])
	_check(collection.snapshot() == state, "read-only regional totals never mutate collection")
	menu.free()
	await _frames(2)

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_cmdline_user_args().has("--capture"):
		return
	var directory := "res://.godot/lost-pressings-ui"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	var output := directory.path_join(filename + ".png")
	_check(root.get_texture().get_image().save_png(output) == OK, "native presentation capture saved")

func _inside(control: Control, dimensions: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= dimensions.x + 1 and rect.end.y <= dimensions.y + 1

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
