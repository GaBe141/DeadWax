extends SceneTree
## The Book and combat receipt never offer a move that Skip has not found.
## Views use supplied permissions and leave the campaign models untouched.
const Book := preload("res://scripts/inventory_menu.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Readout := preload("res://scripts/combo_readout.gd")
var _checks := 0
var _failures: Array[String] = []
var _book: CanvasLayer
var _abilities: RefCounted

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
	_abilities = Abilities.new()
	_book = Book.new()
	_book.abilities = _abilities
	_book.progression = Progression.new()
	root.add_child(_book)
	await _frames(3)
	_book.open_inventory()
	await _frames(3)
	_check(paused and _book.current_page() == "journey", "new Book opens and pauses on Journey")
	_check(_book.slot_count() == 8 and _book.filled_slot_count() == 0,
		"tiny-step opening carries none of the original eight grooves")
	_check(_book.ability_count() == 7 and _book.found_ability_count() == 0,
		"seven earnable moves are tracked separately from knowledge and Refrains")
	_check(_abilities.snapshot().version == 2 and _book.selected_slot() == &"walk",
		"new version-two Book begins on the missing Walk lead")
	var original: Dictionary = _abilities.snapshot()
	for definition in Abilities.catalog():
		var id := StringName(definition.id)
		_book._select_slot(id)
		_check(_book.slot_text(id).contains("NOT FOUND"), "locked %s card does not advertise availability" % id)
		_check(_book.detail_title() == definition.name, "locked %s retains its identifiable name" % id)
		_check(_book._detail_description.text.contains(definition.lead), "locked %s presents the real exploration lead" % id)
		_check(not _book._detail_description.text.contains("ALWAYS YOURS"), "locked %s never promises a starting verb" % id)
	_check(_abilities.snapshot() == original, "viewing all leads cannot grant moves")
	_book.close_inventory()
	_abilities.unlock_ability(&"walk")
	_book.open_inventory()
	_book._select_slot(&"walk")
	_check(_book.found_ability_count() == 1 and _book.filled_slot_count() == 0,
		"finding Walk fills its own movement card without inflating groove slots")
	_check(_book.slot_text(&"walk").contains("FOUND") and not _book.slot_text(&"walk").contains("NOT FOUND"),
		"earned Walk no longer appears missing")
	_book.close_inventory()
	_abilities.unlock_ability(&"strike")
	_book.open_inventory()
	_book._select_slot(&"strike")
	await _frames(2)
	_check(_book.filled_slot_count() == 1 and _book.found_ability_count() == 2,
		"silent acquisition refreshes the exact counts on reopen")
	_check(_book.slot_text(&"strike").contains("FOUND") and not _book.slot_text(&"strike").contains("NOT FOUND"),
		"earned Strike visibly becomes available")
	var description: String = _book._detail_description.text
	_check(description.contains("single Tap") and description.contains("parry"), "basic Strike teaches only its available attack and parry")
	_check(not description.contains("Sweep") and not description.contains("launch") and not description.contains("rebound"),
		"basic Strike does not promise unearned chain, groove riding or pogo")
	_abilities.unlock_ability(&"combo")
	_book.refresh_abilities()
	_check(_book._detail_description.text.contains("Accent") and not _book._detail_description.text.contains("launch"),
		"new chain extends the Strike description without implying other refinements")
	_check(_book.filled_slot_count() == 1 and _book.found_ability_count() == 3,
		"refinement ownership does not inflate the eight groove slots")
	_check(_book._refinement_label.text.contains("1 / 3"), "refinement shelf has its own completion count")
	_abilities.restore_snapshot(Abilities.legacy_snapshot())
	_book.refresh_abilities()
	_check(_book.filled_slot_count() == 3 and _book.found_ability_count() == 7,
		"legacy full moveset remains visibly available")
	_check(_book._detail_description.text.contains("launch") and _book._detail_description.text.contains("rebound"),
		"fully restored Strike describes the earned traversal options")
	original = _abilities.snapshot()
	_book.set_reduced_motion(true)
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _frames(4)
		_abilities.restore_snapshot(Abilities.default_snapshot())
		_book.refresh_abilities()
		_book._select_slot(&"walk")
		_book._focus_selected()
		await _frames(4)
		_check(_book._detail_description.text == Abilities.ability(&"walk").lead
			and _book._detail_description.get_global_rect().end.y <= _book._journey_notes.get_global_rect().end.y + 1,
			"the first Walk location lead is entirely visible without scrolling")
		_abilities.restore_snapshot(original)
		_book.refresh_abilities()
		_book._select_slot(&"hood")
		for id in [&"walk", &"strike", &"combo", &"groove", &"pogo", &"jump-cut"]:
			_book._select_slot(id)
			_book._focus_selected()
			await _frames(4)
			var focused: Control = root.gui_get_focus_owner()
			_check(focused == _book._slot_buttons[id] and _inside(focused, dimensions),
				"%s remains focus-reachable inside %s" % [id, dimensions])
			_check(_inside(_book._journey_detail, dimensions), "selected notes stay visible beside the scrolling shelves")
			_check(_book._journey_notes.scroll_vertical == 0, "new selection returns its notes to their opening line")
		_book._select_slot(&"strike")
		await _frames(2)
		var before := int(_book._journey_notes.scroll_vertical)
		var down := InputEventKey.new()
		down.keycode = KEY_PAGEDOWN
		down.physical_keycode = KEY_PAGEDOWN
		down.pressed = true
		Input.parse_input_event(down)
		await _frames(2)
		down.pressed = false
		Input.parse_input_event(down)
		if dimensions.y == 540:
			_check(int(_book._journey_notes.scroll_vertical) > before, "Page Down reaches long Journey notes in a compact window")
	_check(_abilities.snapshot() == original, "selection, scrolling and reduced motion never mutate permissions")
	_book.close_inventory()
	_check(not paused, "closing the Book restores play")
	_abilities.restore_snapshot({"version": 1, "unlocked": []})
	_book.refresh_abilities()
	_check(_book.found_ability_count() == 1 and _book.filled_slot_count() == 0
		and not _book.slot_text(&"walk").contains("NOT FOUND"),
		"a version-one empty moveset retains its already-available Walk")
	_abilities.restore_snapshot({"version": 2, "unlocked": []})
	_book.refresh_abilities()
	_check(_book.found_ability_count() == 0 and _book.slot_text(&"walk").contains("NOT FOUND"),
		"explicit version-two empty permissions retain the tiny-step opening")
	_book.abilities = null
	_book.refresh_abilities()
	_check(_book.filled_slot_count() == 3 and _book.found_ability_count() == 7,
		"standalone legacy Book fixtures retain the complete moveset")
	_readout_permissions()
	_book.queue_free()
	await _frames(3)
	if _failures.is_empty():
		print("DEAD WAX ABILITY BOOK PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error("ABILITY BOOK FAIL: " + failure)
		quit(1)

func _readout_permissions() -> void:
	var view := Readout.new()
	view.size = Vector2(350, 104)
	root.add_child(view)
	var supplied := {"step": 3, "remaining": 0.5, "window": 0.65, "label": "ACCENT",
		"input_state": "queued", "cooldown_remaining": 0.08, "queued": true,
		"strike_unlocked": false, "chain_unlocked": false}
	view.set_snapshot(supplied)
	view.set_process(false)
	_check(not view.visible and view._snapshot.step == 0 and not view._snapshot.queued,
		"unearned Strike suppresses a stale attack receipt and queued hint")
	_check(not view._input_hint.text.contains("J / X") and not view._headline.text.contains("ACCENT"),
		"movement-only presentation never requests an unavailable strike")
	for beat in view._beats:
		_check(not beat.visible, "movement-only presentation hides every attack beat")
	_check(not view._rail.visible and not view._link_label.visible, "locked chain does not show a link timer")
	view.practice_mode = true
	_check(view._headline.text == "FIND YOUR NEEDLE", "explicitly displayed locked receipt gives a truthful exploration hint")
	supplied.strike_unlocked = true
	supplied.step = 1
	supplied.label = "TAP"
	supplied.remaining = 0.0
	supplied.input_state = "recover"
	supplied.queued = false
	supplied.cooldown_remaining = 0.17
	view.set_snapshot(supplied)
	view.set_process(false)
	_check(view._headline.text == "TAP" and view._input_hint.text == "RECOVERING",
		"basic Tap exposes actual recovery without requiring a chain window")
	_check(view._beats[0].visible and not view._beats[1].visible and not view._beats[2].visible,
		"only the earned Tap is displayed before chain acquisition")
	_check(not view._window.visible and not view._rail.visible and not view._link_label.visible,
		"basic attack advertises no link-time mechanic")
	supplied.input_state = "queued"
	supplied.queued = true
	view.set_snapshot(supplied)
	_check(view._input_hint.text == "QUEUED · TAP", "basic attack queue names another Tap rather than an unearned Sweep")
	var before: Dictionary = view._snapshot.duplicate(true)
	view.set_reduced_motion(true)
	view._process(1.0)
	_check(view._snapshot == before and supplied.step == 1, "readout motion cannot change supplied ability or combat state")
	supplied.chain_unlocked = true
	supplied.remaining = 0.5
	view.set_snapshot(supplied)
	_check(view._input_hint.text == "QUEUED · 2 SWEEP" and view._window.visible and view._beats[2].visible,
		"earned chain restores full three-beat instruction and link time")
	supplied.erase("strike_unlocked")
	supplied.erase("chain_unlocked")
	view.set_snapshot(supplied)
	_check(view._input_hint.text == "QUEUED · 2 SWEEP", "old supplied snapshots retain legacy full-chain presentation")
	view.free()

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
