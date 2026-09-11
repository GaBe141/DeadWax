extends SceneTree
## Return routes and their leads are read-only views over Main-owned discovery.
const Chart := preload("res://scripts/campaign_chart.gd")
const MapMenu := preload("res://scripts/map_menu.gd")
const Book := preload("res://scripts/inventory_menu.gd")
const Exploration := preload("res://scripts/exploration_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Discoveries := preload("res://scripts/discoveries_state.gd")
var _checks := 0
var _failures: Array[String] = []

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
	root.content_scale_size = Vector2i(1280, 720)
	_chart_visibility()
	await _map_presentation()
	await _book_leads()
	if _failures.is_empty():
		print("DEAD WAX EXPLORATION MAP PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures: push_error("EXPLORATION MAP FAIL: " + failure)
		quit(1)

func _chart_visibility() -> void:
	_check(Chart.LINKS.size() == 26 and Chart.return_ids() == ["warren_return", "gallery_return"],
		"chart contains the two named permanent returns beside the original twenty-four passage pairs")
	for region in Chart.REGIONS:
		var page := Chart.page_snapshot(region.id, ["headshell"], &"headshell")
		_check(_returns(page).is_empty(), "unexplored return routes do not reveal topology on " + String(region.id))
		for boundary in page.boundaries:
			_check(String(boundary.route_id).is_empty(), "unknown return border labels are absent")
	var explored := ["verse_warren_n", "high_street"]
	for region in [&"label", &"unplayed"]:
		var page := Chart.page_snapshot(region, explored, &"verse_warren_n")
		var returns := _returns(page)
		_check(returns.size() == 1 and returns[0].route_id == "warren_return" and not returns[0].open,
			"visiting both endpoints reveals the sealed northern return on " + String(region))
		for boundary in page.boundaries:
			if boundary.route_id == "warren_return":
				_check(boundary.title == "BACK OF THE WAX" and not boundary.open,
					"sealed return supplies an honest back-of-wax label")
	for region in [&"label", &"unplayed"]:
		var page := Chart.page_snapshot(region, ["deep_gallery"], &"deep_gallery", ["gallery_return"])
		var returns := _returns(page)
		_check(returns.size() == 1 and returns[0].route_id == "gallery_return" and returns[0].open,
			"opening a return reveals its real connection even before using it")
		for room in page.rooms:
			if room.id != &"deep_gallery":
				_check(String(room.title).is_empty(), "opened passage never marks an unvisited place as visited")
		for boundary in page.boundaries:
			if boundary.route_id == "gallery_return":
				_check(boundary.open and String(boundary.title).begins_with("RETURN TO THE "),
					"opened border names a region rather than a hidden room")
	var visited: Array = Chart.room_ids()
	var pairs: Dictionary = {}
	for region in Chart.REGIONS:
		var page := Chart.page_snapshot(region.id, visited, &"headshell", Chart.return_ids())
		for link in page.links:
			pairs[_pair(link.a, link.b)] = true
		for boundary in page.boundaries:
			if String(boundary.route_id).is_empty(): continue
			var box := Rect2(boundary.position - Vector2(99, 20), Vector2(198, 40))
			_check(Rect2(Vector2.ZERO, Chart.EXTENT).encloses(box), "return stub stays inside its printed page")
			for room in page.rooms:
				_check(not box.intersects(Rect2(room.position - Chart.ROOM_SIZE * 0.5, Chart.ROOM_SIZE)),
					"return stub does not obscure an authored room card")
	_check(pairs.size() == 26, "fully explored pages represent all twenty-six real pairs")

func _map_presentation() -> void:
	var exploration := Exploration.new()
	var menu := MapMenu.new()
	menu.exploration = exploration
	root.add_child(menu)
	await _frames(3)
	var visited: Array[String] = []
	for id in Chart.room_ids(): visited.append(String(id))
	var snapshot := {"owned": true, "visited": visited, "current_room": "verse_warren_n"}
	var original := snapshot.duplicate(true)
	var state := exploration.snapshot()
	menu.show_map(snapshot)
	await _frames(3)
	_check(menu.selected_region() == &"unplayed" and menu.return_status_text().contains("SEALED · BACK OF THE WAX"),
		"current region presents explicit sealed status for known returns")
	_check(menu._chart.opened_returns.is_empty(), "looking at known routes never opens them")
	menu._select_region(&"overture")
	_check(menu.return_status_text().is_empty() and not menu._returns.visible, "unrelated pages add no fake return routes")
	menu._select_region(&"label")
	_check(menu.return_status_text().contains("Headshell") and menu.return_status_text().contains("High Street"),
		"return summaries identify their visited local endpoints")
	_check(exploration.snapshot() == state and snapshot == original, "paging and map presentation leave both supplied models untouched")
	exploration.open_shortcut(&"warren_return")
	_check(menu._chart.opened_returns.is_empty(), "an open map holds its supplied view until the next refresh")
	menu.close_map()
	menu.show_map(snapshot)
	await _frames(2)
	_check(menu.selected_region() == &"unplayed" and menu._chart.opened_returns == ["warren_return"],
		"reopening refreshes silent saved state and restores the current region")
	_check(menu.return_status_text().contains("North Warren: OPEN") and menu.return_status_text().contains("Deep Gallery: SEALED"),
		"opening one return never claims the other is unlocked")
	state = exploration.snapshot()
	menu.set_reduced_motion(true)
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _frames(4)
		for region in [&"label", &"unplayed"]:
			menu._select_region(region)
			await _frames(4)
			_check(_inside(menu.close_button(), dimensions) and _inside(menu._returns, dimensions),
				"return status and close action stay readable at " + str(dimensions))
			_check(menu._chart.size.y > 180, "route status leaves room for the map drawing")
	var clock: float = menu._chart.clock
	await _frames(6)
	_check(menu._chart.clock == clock and exploration.snapshot() == state, "reduced motion settles decoration without changing return state")
	menu.close_map()
	menu.show_map({"owned": true, "visited": ["headshell"], "current_room": "headshell"})
	_check(not menu.return_status_text().contains("North Warren") and not menu.return_status_text().contains("Deep Gallery"),
		"a partially visited guide never discloses far room names through the status line")
	menu.free()

func _book_leads() -> void:
	var book := Book.new()
	var progression := Progression.new()
	var discoveries := Discoveries.new()
	var exploration := Exploration.new()
	book.progression = progression
	book.discoveries = discoveries
	book.exploration = exploration
	root.add_child(book)
	await _frames(3)
	discoveries.restore_snapshot({"echo_spool": "restored", "survey_slip": false})
	book.open_inventory()
	book._select_slot(&"echo_spool")
	_check(book._detail_description.text.contains("below the northern receiver")
		and book._detail_description.text.contains("E / Y") and not book._detail_description.text.contains("Jump-Cut"),
		"restored spool leads to the separate pickup without revealing an unearned Refrain name")
	book._select_slot(&"jump-cut")
	_check(book.detail_title() == "EMPTY GROOVE" and not book.slot_text(&"jump-cut").contains("JUMP"),
		"unearned Jump-Cut keeps its name hidden")
	progression.unlock_refrain(Progression.Refrain.JUMP_CUT)
	book.refresh_abilities()
	book._select_slot(&"jump-cut")
	_check(book.detail_title() == "JUMP-CUT" and book._detail_description.text.contains("F / RB")
		and book._detail_description.text.contains("twelve seconds") and book._detail_description.text.contains("E / Y"),
		"earned Refrain describes flipping and the deliberate far-side interaction")
	_check(book._detail_description.text.contains("North Warren") and book._detail_description.text.contains("Deep Gallery"),
		"earned Refrain carries both exploration leads")
	exploration.open_shortcut(&"warren_return")
	exploration.open_shortcut(&"gallery_return")
	book.close_inventory()
	var original := {"exploration": exploration.snapshot(), "discoveries": discoveries.snapshot(), "progression": progression.snapshot()}
	book.open_inventory()
	book._select_slot(&"echo_spool")
	_check(book._detail_description.text.contains("open to High Street") and book._detail_description.text.contains("open to the Headshell")
		and not book._detail_description.text.contains("claim it"), "reopened Book refreshes both permanent returns and removes the completed pickup lead")
	_check(original == {"exploration": exploration.snapshot(), "discoveries": discoveries.snapshot(), "progression": progression.snapshot()},
		"Book notes cannot claim the Refrain or open a route")
	book.close_inventory()
	book.free()
	await _frames(2)

func _returns(page: Dictionary) -> Array:
	return page.links.filter(func(link: Dictionary) -> bool: return not String(link.route_id).is_empty())

func _pair(a: StringName, b: StringName) -> String:
	var ids := [String(a), String(b)]
	ids.sort()
	return "/".join(ids)

func _inside(control: Control, dimensions: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= dimensions.x + 1 and rect.end.y <= dimensions.y + 1

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
