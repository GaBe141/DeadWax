extends SceneTree
## The quiet campaign keeps room guidance in a read-only, reachable Book page.
const Book := preload("res://scripts/inventory_menu.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	for action in ["inventory", "map"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for action in ["book_previous", "book_next", "book_scroll_up", "book_scroll_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for binding in [["book_previous", JOY_BUTTON_LEFT_SHOULDER], ["book_next", JOY_BUTTON_RIGHT_SHOULDER]]:
		var shoulder_binding := InputEventJoypadButton.new()
		shoulder_binding.button_index = int(binding[1])
		InputMap.action_add_event(StringName(binding[0]), shoulder_binding)
	for binding in [["book_scroll_up", -1.0], ["book_scroll_down", 1.0]]:
		var scroll_binding := InputEventJoypadMotion.new()
		scroll_binding.axis = JOY_AXIS_RIGHT_Y
		scroll_binding.axis_value = float(binding[1])
		InputMap.action_add_event(StringName(binding[0]), scroll_binding)
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var abilities := Abilities.new()
	var progression := Progression.new()
	var book := Book.new()
	book.abilities = abilities
	book.progression = progression
	book.set_reduced_motion(true)
	root.add_child(book)
	await _frames(3)
	book.open_inventory()
	book._select_slot(&"this_place")
	await _frames(2)
	_check(book.detail_title() == "THIS PLACE" and not book._detail_description.text.is_empty(),
		"standalone Books retain a usable place page without a room snapshot")
	_check(book.slot_count() == 8 and book.filled_slot_count() == 0,
		"place guidance never fills a carrying groove")
	_check(book.ability_count() == 7 and book.found_ability_count() == 0,
		"place guidance never grants an earned move")
	book.close_inventory()
	book.place_name = "The Headshell"
	book.place_objective = "Find your feet behind the cradle."
	book.place_notes = [
		{"heading": "THE FIRST STEPS", "body": "Tap left. Hold does not move you yet."},
		{"heading": "A QUIET GRIP", "body": "Some things only answer when you listen."},
	]
	var supplied_notes: Array[Dictionary] = book.place_notes.duplicate(true)
	var before_abilities: Dictionary = abilities.snapshot()
	var before_progression: Dictionary = progression.snapshot()
	book.open_inventory()
	book._select_slot(&"this_place")
	_check(book.detail_title() == "THE HEADSHELL", "room title is refreshed when the Book opens")
	_check(book._detail_description.text.begins_with(book.place_objective),
		"the current objective leads the room guidance")
	for note in supplied_notes:
		_check(book._detail_description.text.contains(note.heading) and book._detail_description.text.contains(note.body),
			"authored heading and body remain readable together in the Book")
	book._select_slot(&"gather")
	_check(book.detail_title() == "EMPTY GROOVE" and not book._detail_description.text.contains("Gather"),
		"an unearned Refrain keeps its name hidden")
	var long_body := ""
	for line in 24:
		long_body += "A line from the old room: listen, walk, and look before the next passage.\n"
	book.place_notes = [{"heading": "THE ROOM'S PRINT", "body": long_body}]
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		book.close_inventory()
		book.open_inventory()
		book._select_slot(&"this_place")
		book._focus_selected()
		await _frames(5)
		_check(root.gui_get_focus_owner() == book._place_button and _inside(book._place_button, dimensions),
			"This Place remains focus reachable inside %s" % dimensions)
		_check(_inside(book._journey_detail, dimensions), "place notes remain inside the compact Book page")
		_check(book._journey_notes.scroll_vertical == 0, "reopening place notes starts at their opening line")
		var key := InputEventKey.new()
		key.pressed = true
		key.keycode = KEY_PAGEDOWN
		book._input(key)
		await _frames(2)
		_check(book._journey_notes.scroll_vertical > 0, "Page Down reaches long room notes")
		book.select_page("equipment")
		var shoulder := InputEventJoypadButton.new()
		shoulder.button_index = JOY_BUTTON_LEFT_SHOULDER
		shoulder.pressed = true
		book._input(shoulder)
		await _frames(3)
		_check(book.current_page() == "journey" and root.gui_get_focus_owner() == book._place_button,
			"controller page navigation returns focus to the selected place guide")
	book.close_inventory()
	book.place_name = "The North Warren"
	book.place_objective = "Carry the phrase to the receiver."
	book.place_notes = [{"heading": "A SHUTTERED PIPE", "body": "The northern terrace waits for three notes."}]
	book.open_inventory()
	await _frames(2)
	_check(book.detail_title() == "THE NORTH WARREN"
		and book._detail_description.text.contains("three notes")
		and not book._detail_description.text.contains("cradle"),
		"a changed room replaces the previous place snapshot on reopen")
	_check(abilities.snapshot() == before_abilities and progression.snapshot() == before_progression,
		"opening, reading, scrolling and controller navigation never mutate permissions")
	_check(supplied_notes[0].body == "Tap left. Hold does not move you yet.",
		"reading leaves supplied room notes intact")
	book.close_inventory()
	_check(not paused, "closing the place guide restores play")
	book.queue_free()
	await _frames(3)
	if _failures.is_empty():
		print("DEAD WAX CINEMATIC BOOK PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error("CINEMATIC BOOK FAIL: " + failure)
		quit(1)

func _inside(control: Control, dimensions: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= -1.0 and rect.position.y >= -1.0 \
		and rect.end.x <= dimensions.x + 1.0 and rect.end.y <= dimensions.y + 1.0

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
