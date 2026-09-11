extends SceneTree
## Independent Book view tests: snapshots are read-only and only deliberate
## button intent can request a fit, removal or binding from Main.
const Book := preload("res://scripts/inventory_menu.gd")
const Collection := preload("res://scripts/collection_state.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const Progression := preload("res://scripts/progression_state.gd")
var _checks := 0
var _failures: Array[String] = []
var _intents: Array[String] = []
var _book: CanvasLayer
var _collection: RefCounted

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	for action in ["inventory", "map"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	_collection = Collection.new()
	_book = Book.new()
	_book.progression = Progression.new()
	_book.collection = _collection
	root.add_child(_book)
	_book.equip_requested.connect(func(id: String) -> void: _intents.append("equip:" + id))
	_book.unequip_requested.connect(func(slot: String) -> void: _intents.append("remove:" + slot))
	_book.craft_requested.connect(func(id: String) -> void: _intents.append("craft:" + id))
	await _frames(3)
	_book.open_inventory()
	await _frames(3)
	_check(paused and _book.current_page() == "journey", "opening preserves Journey and tree pause")
	_check(_book.slot_count() == 8 and _book.filled_slot_count() == 3, "gear and species never inflate the eight groove count")
	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	Input.parse_input_event(tab)
	await _frames(2)
	_check(_book.current_page() == "equipment", "fresh Tab pages from Journey into equipment")
	tab.pressed = false
	Input.parse_input_event(tab)
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	shoulder.pressed = true
	Input.parse_input_event(shoulder)
	await _frames(2)
	_check(_book.current_page() == "bestiary", "controller shoulder pages through the Book")
	shoulder.pressed = false
	Input.parse_input_event(shoulder)
	var state: Dictionary = _collection.snapshot()
	_book.select_page("equipment", true)
	await _frames(3)
	var pages: Control = _book._collection_pages
	_check(pages._equipment.is_visible_in_tree() and not _book._journey.visible, "equipment page takes the Book content area")
	_check(pages._gear_buttons.size() == Catalog.items().size(), "every catalog gear target has a selectable card")
	_check(pages._gear_title.text == Catalog.items()[0].name and pages._gear_tradeoff.text == Catalog.items()[0].tradeoff, "selection exposes the actual catalog trade-off")
	_check(pages._gear_odds.text.contains("4%") and pages._gear_odds.text.contains("20"), "odds and bounded dry streak are printed")
	_check(pages._gear_action.disabled, "unearned recipe cannot request a bind")
	_check(_collection.snapshot() == state and _intents.is_empty(), "page browsing is read-only")
	_book.select_page("bestiary", true)
	await _frames(2)
	for button in pages._species_buttons.values():
		_check(button.text == "— UNRECORDED VOICE —", "unseen species does not disclose a name")
	_check(not pages._species_title.text.contains("Auditioner"), "unknown detail keeps species name hidden")
	state.bestiary.auditioner = {"seen": true, "freed": 2, "shattered": 1}
	state.owned = ["quicksilver_tip"]
	state.hunts.label = {"discovered": true, "wins": 1, "dry": 1}
	state.offcuts = 40
	_check(_collection.restore_snapshot(state), "restore populated collection fixture")
	_book.refresh_collection()
	pages.select_species("auditioner")
	_check(pages._species_title.text == "Auditioner" and pages._species_counts.text.contains("FREED  2"), "silent refresh shows seen species and saved outcomes")
	_book.select_page("equipment", true)
	pages.select_item("quicksilver_tip")
	pages.focus_selected()
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.physical_keycode = KEY_RIGHT
	right.pressed = true
	Input.parse_input_event(right)
	await _frames(2)
	_check(root.gui_get_focus_owner() == pages._gear_action, "Right from a carried piece reaches its equipment action")
	right.pressed = false
	Input.parse_input_event(right)
	var accept := InputEventKey.new()
	accept.keycode = KEY_ENTER
	accept.physical_keycode = KEY_ENTER
	accept.pressed = true
	Input.parse_input_event(accept)
	await _frames(2)
	accept.pressed = false
	Input.parse_input_event(accept)
	await _frames(2)
	_check(_intents == ["equip:quicksilver_tip"] and _collection.snapshot() == state, "fit emits exact intent without mutating carried state")
	_collection.equip("quicksilver_tip")
	_book.refresh_collection("Fitted.")
	_check(pages._notice.text == "Fitted." and pages._slot_names.needle.text == "Quicksilver Tip", "Main's refreshed snapshot presents a completed fitting")
	pages._gear_action.pressed.emit()
	_check(_intents.back() == "remove:needle" and _collection.snapshot().equipped.needle == "quicksilver_tip", "remove emits only the occupied slot intent")
	pages.select_item("blunt_stylus")
	_check(not pages._gear_action.disabled, "source clear and forty Offcuts enable a missing piece")
	pages._gear_action.pressed.emit()
	_check(_intents.back() == "craft:blunt_stylus" and _collection.snapshot().offcuts == 40, "binding emits intent without spending Offcuts")
	state = _collection.snapshot()
	state.offcuts = 0
	_collection.restore_snapshot(state)
	_book.refresh_collection("Could not save; your Offcuts are unchanged.")
	_check(pages._gear_action.disabled and pages._notice.visible, "failed or changed state refresh disables stale crafting intent")
	pages._gear_action.pressed.emit()
	_check(_intents.size() == 3, "disabled button cannot bypass resource rules even through direct emission")
	_book.set_reduced_motion(true)
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _frames(4)
		for page in ["equipment", "bestiary"]:
			_book.select_page(page, true)
			await _frames(3)
			var focus: Control = root.gui_get_focus_owner()
			_check(focus != null and _inside(focus, dimensions), "%s focused entry remains inside %s" % [page, dimensions])
			_check(_book._page_buttons[page].get_global_rect().end.x <= dimensions.x, "page tabs fit the viewport")
			if page == "equipment":
				_check(_inside(pages._gear_action, dimensions), "equipment action remains visible while notes scroll")
				var before := int(pages._gear_notes.scroll_vertical)
				var down := InputEventKey.new()
				down.keycode = KEY_PAGEDOWN
				down.physical_keycode = KEY_PAGEDOWN
				down.pressed = true
				Input.parse_input_event(down)
				await _frames(2)
				_check(int(pages._gear_notes.scroll_vertical) > before, "Page Down scrolls long notes without changing equipment")
				down.pressed = false
				Input.parse_input_event(down)
	_book.close_inventory()
	_check(not paused, "closing expanded Book resumes the original tree state")
	var count := _intents.size()
	pages._request_unequip("needle")
	_check(_intents.size() == count, "hidden Book cannot issue equipment intent")
	_book.queue_free()
	await _frames(3)
	if _failures.is_empty():
		print("DEAD WAX COLLECTION BOOK PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error("COLLECTION BOOK FAIL: " + failure)
		quit(1)

func _inside(control: Control, dimensions: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= dimensions.x + 1 and rect.end.y <= dimensions.y + 1

func _frames(count: int) -> void:
	for index in count:
		await process_frame

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
