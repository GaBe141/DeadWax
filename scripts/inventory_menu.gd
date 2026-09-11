extends CanvasLayer
## Full-screen progression inventory. It reads session state but never owns it.
## The menu keeps processing while the paused game waits underneath.

signal opened
signal closed
signal map_requested
signal equip_requested(item_id: String)
signal unequip_requested(slot: String)
signal craft_requested(item_id: String)

const ProgressionScript := preload("res://scripts/progression_state.gd")
const PressScript := preload("res://scripts/press.gd")
const EconomyScript := preload("res://scripts/economy_state.gd")
const UiMotionScript := preload("res://scripts/ui_motion.gd")
const CollectionPages := preload("res://scripts/collection_book_pages.gd")
const WorldBackdrop := preload("res://scripts/ui_world_backdrop.gd")

## Above this size The Book is shouting, and shouting is set in wood type.
const DISPLAY_AT := 24

const CORE_SLOTS := [&"strike", &"hood", &"set"]

const PAPER := Color("f2e1bc")
const PAPER_DARK := Color("c2ae87")
const DEEP := Color("102c35")
const PINK := Color("d6a968")
const VIOLET := Color("52716d")
const FADED := Color("78928d")

var progression: RefCounted
var shine_source: Node
var economy: RefCounted
var map_state: RefCounted
var discoveries: RefCounted
var collection: RefCounted
var can_open: Callable

var overlay: Control
var _progress_label: Label
var _shine_label: Label
var _wares_label: Label
var _detail_kind: Label
var _detail_title: Label
var _detail_state: Label
var _detail_description: Label
var _slot_buttons: Dictionary = {}
var _selected_slot: StringName = &"strike"
var _open := false
var _tree_was_paused := false
var _motion: Node
var _reduced_motion := false
var _entrance_parts: Array[Control] = []
var _detail_stack: VBoxContainer
var _map_button: Button
var _map_note: Label
var _discovery_buttons: Dictionary = {}
var _journey: ScrollContainer
var _collection_pages: Control
var _page_buttons: Dictionary = {}
var _current_page := "journey"
var _page_margin: MarginContainer
var _page_stack: VBoxContainer
var _header: HBoxContainer
var _subtitle: Label
var _journey_detail: PanelContainer

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("inventory_menu")
	_motion = UiMotionScript.new()
	_motion.name = "UiMotion"
	add_child(_motion)
	_motion.reduced_motion = _reduced_motion
	_build_menu()
	if progression != null:
		progression.connect("refrain_unlocked", _on_progression_changed)
		progression.connect("technique_discovered", _on_progression_changed)
	_refresh()

func _exit_tree() -> void:
	if _open and get_tree() != null:
		get_tree().paused = _tree_was_paused

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if _open and event.is_pressed():
		var step := 0
		if event is InputEventKey and (event.keycode == KEY_TAB or event.physical_keycode == KEY_TAB):
			step = -1 if event.shift_pressed else 1
		elif event is InputEventJoypadButton:
			if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
				step = -1
			elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
				step = 1
		if step != 0:
			var order := ["journey", "equipment", "bestiary"]
			select_page(order[posmod(order.find(_current_page) + step, order.size())], true)
			get_viewport().set_input_as_handled()
			return
	if _open and event is InputEventKey and event.is_action_pressed("map") and map_state != null and bool(map_state.get("owned")):
		_request_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif (
		_open
		and event is InputEventKey
		and event.pressed
		and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE)
	):
		close_inventory()
		get_viewport().set_input_as_handled()

func is_open() -> bool:
	return _open

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _motion != null:
		_motion.reduced_motion = enabled

func open_inventory() -> void:
	if _open:
		return
	if can_open.is_valid() and not bool(can_open.call()):
		return
	_tree_was_paused = get_tree().paused
	_motion.settle()
	_open = true
	overlay.show()
	_refresh()
	_focus_selected()
	get_tree().paused = true
	for index in _entrance_parts.size():
		_motion.reveal(_entrance_parts[index], 0.0, 0.20, float(index) * 0.025)
	call_deferred("_focus_selected")
	opened.emit()

func close_inventory() -> void:
	if not _open:
		return
	_open = false
	overlay.hide()
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and overlay.is_ancestor_of(focus_owner):
		focus_owner.release_focus()
	_motion.settle()
	get_tree().paused = _tree_was_paused
	closed.emit()

func toggle_inventory() -> void:
	if _open:
		close_inventory()
	else:
		open_inventory()

func current_page() -> String:
	return _current_page

func select_page(page_id: String, focus_content := false) -> void:
	if page_id not in _page_buttons:
		return
	_settle_motion()
	_current_page = page_id
	_journey.visible = page_id == "journey"
	_collection_pages.visible = page_id != "journey"
	_collection_pages.show_page(page_id)
	for id in _page_buttons:
		var button: Button = _page_buttons[id]
		button.button_pressed = id == page_id
		_apply_card_style(button, id == page_id)
	if focus_content:
		_focus_selected()

func refresh_collection(notice := "") -> void:
	if _collection_pages != null:
		_collection_pages.refresh(collection, notice)

func slot_count() -> int:
	return CORE_SLOTS.size() + ProgressionScript.TECHNIQUE_ORDER.size() + ProgressionScript.REFRAIN_ORDER.size()

func filled_slot_count() -> int:
	var filled := 0
	for slot in _all_slots():
		if _slot_is_filled(slot):
			filled += 1
	return filled

func slot_text(slot: StringName) -> String:
	var button := _slot_buttons.get(slot) as Button
	return button.text if button != null else ""

func selected_slot() -> StringName:
	return _selected_slot

func detail_title() -> String:
	return _detail_title.text if _detail_title != null else ""

func shine_text() -> String:
	return _shine_label.text if _shine_label != null else ""

func is_fullscreen_layout() -> bool:
	return (
		overlay != null
		and is_zero_approx(overlay.anchor_left)
		and is_zero_approx(overlay.anchor_top)
		and is_equal_approx(overlay.anchor_right, 1.0)
		and is_equal_approx(overlay.anchor_bottom, 1.0)
	)

func _build_menu() -> void:
	overlay = Control.new()
	overlay.name = "InventoryOverlay"
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.resized.connect(_resize_page)

	var background := ColorRect.new()
	background.color = DEEP
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scenery := WorldBackdrop.new()
	scenery.kind = &"journal"
	overlay.add_child(scenery)
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var edge := ColorRect.new()
	edge.color = PINK
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	edge.offset_bottom = 5.0
	overlay.add_child(edge)

	var margin := MarginContainer.new()
	_page_margin = margin
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 24)
	overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	_page_stack = page
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)

	var header := HBoxContainer.new()
	_header = header
	header.custom_minimum_size.y = 62.0
	page.add_child(header)
	_entrance_parts.append(header)

	var title_stack := VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", -2)
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	title_stack.add_child(_make_label("INVENTORY — THE BOOK", 30, PAPER))
	_subtitle = _make_label("what you carry between grooves", 15, PAPER_DARK)
	title_stack.add_child(_subtitle)

	var count_stack := VBoxContainer.new()
	count_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(count_stack)
	_progress_label = _make_label("", 18, PINK)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_stack.add_child(_progress_label)
	_shine_label = _make_label("", 14, PAPER_DARK)
	_shine_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_stack.add_child(_shine_label)

	var rule := ColorRect.new()
	rule.color = VIOLET
	rule.custom_minimum_size.y = 2.0
	page.add_child(rule)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	page.add_child(tabs)
	for page_id in ["journey", "equipment", "bestiary"]:
		var button := Button.new()
		button.name = page_id.to_pascal_case() + "Tab"
		button.text = page_id.to_upper()
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(140, 36)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_override("font", PressScript.BodyFont)
		button.add_theme_font_size_override("font_size", PressScript.SIZE_SMALL)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", PAPER)
		button.add_theme_color_override("font_pressed_color", PINK)
		button.pressed.connect(select_page.bind(page_id, false))
		tabs.add_child(button)
		_page_buttons[page_id] = button
		_motion.bind_button(button, PINK)
	_journey = ScrollContainer.new()
	_journey.name = "Journey"
	_journey.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journey.follow_focus = true
	_journey.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_journey)
	var journey_page := VBoxContainer.new()
	journey_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journey_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journey_page.add_theme_constant_override("separation", 12)
	_journey.add_child(journey_page)
	var carried_row := HBoxContainer.new()
	carried_row.add_theme_constant_override("separation", 12)
	journey_page.add_child(carried_row)
	_wares_label = _make_label("", 14, PAPER_DARK)
	_wares_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_wares_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carried_row.add_child(_wares_label)
	for slot in [&"echo_spool", &"survey_slip"]:
		var button := Button.new()
		button.name = String(slot).to_pascal_case()
		button.custom_minimum_size = Vector2(150, 34)
		button.add_theme_font_override("font", PressScript.BodyFont)
		button.add_theme_font_size_override("font_size", PressScript.SIZE_SMALL)
		for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
			button.add_theme_color_override(key, PAPER)
		button.focus_entered.connect(_select_slot.bind(slot))
		button.pressed.connect(_select_slot.bind(slot))
		carried_row.add_child(button)
		_discovery_buttons[slot] = button
		_slot_buttons[slot] = button
		_motion.bind_button(button, PINK)
	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", 18)
	journey_page.add_child(map_row)
	_entrance_parts.append(map_row)
	var map_copy := VBoxContainer.new()
	map_copy.add_theme_constant_override("separation", 0)
	map_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_row.add_child(map_copy)
	map_copy.add_child(_make_label("FOLDED MAP", 18, PAPER))
	_map_note = _make_label("", 13, PAPER_DARK)
	map_copy.add_child(_map_note)
	_map_button = Button.new()
	_map_button.name = "OpenMap"
	_map_button.custom_minimum_size = Vector2(265, 44)
	_map_button.focus_mode = Control.FOCUS_ALL
	_map_button.add_theme_font_override("font", PressScript.BodyFont)
	_map_button.add_theme_font_size_override("font_size", PressScript.SIZE_SMALL)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		_map_button.add_theme_color_override(key, PAPER)
	_map_button.add_theme_color_override("font_disabled_color", PAPER_DARK)
	_map_button.pressed.connect(_request_map)
	map_row.add_child(_map_button)
	_motion.bind_button(_map_button, PINK)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journey_page.add_child(content)

	var shelves := VBoxContainer.new()
	shelves.add_theme_constant_override("separation", 8)
	shelves.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(shelves)
	_entrance_parts.append(shelves)
	_add_shelf(shelves, "CORE VERBS — ALWAYS YOURS", CORE_SLOTS)
	_add_shelf(shelves, "KNOWLEDGE — NAMED, NEVER GRANTED", _technique_slots())
	_add_shelf(shelves, "REFRAINS — CARRIED", _refrain_slots())

	var detail_panel := PanelContainer.new()
	_journey_detail = detail_panel
	detail_panel.custom_minimum_size.x = 350.0
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _panel_style())
	content.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 24)
	detail_margin.add_theme_constant_override("margin_top", 24)
	detail_margin.add_theme_constant_override("margin_right", 24)
	detail_margin.add_theme_constant_override("margin_bottom", 24)
	detail_panel.add_child(detail_margin)

	_detail_stack = VBoxContainer.new()
	_detail_stack.add_theme_constant_override("separation", 12)
	detail_margin.add_child(_detail_stack)
	_entrance_parts.append(_detail_stack)
	_detail_kind = _make_label("", 13, PINK)
	_detail_stack.add_child(_detail_kind)
	_detail_title = _make_label("", 30, PAPER)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_stack.add_child(_detail_title)
	var detail_rule := ColorRect.new()
	detail_rule.color = VIOLET
	detail_rule.custom_minimum_size.y = 2.0
	_detail_stack.add_child(detail_rule)
	_detail_state = _make_label("", 15, PAPER_DARK)
	_detail_stack.add_child(_detail_state)
	_detail_description = _make_label("", 17, PAPER)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_stack.add_child(_detail_description)

	_collection_pages = CollectionPages.new()
	_collection_pages.name = "CollectionPages"
	_collection_pages.book = self
	_collection_pages.motion = _motion
	_collection_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(_collection_pages)
	_collection_pages.equip_requested.connect(func(id: String) -> void: equip_requested.emit(id))
	_collection_pages.unequip_requested.connect(func(slot: String) -> void: unequip_requested.emit(slot))
	_collection_pages.craft_requested.connect(func(id: String) -> void: craft_requested.emit(id))
	select_page("journey")
	var footer := _make_label("[I / START] close   [TAB / LB RB] pages   [ARROWS] select   [ENTER / A] act", PressScript.SIZE_SMALL, PAPER_DARK)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(footer)
	_entrance_parts.append(footer)
	_resize_page()
	overlay.hide()

func _add_shelf(parent: VBoxContainer, title: String, slots: Array) -> void:
	var shelf := VBoxContainer.new()
	shelf.add_theme_constant_override("separation", 4)
	shelf.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(shelf)
	shelf.add_child(_make_label(title, 13, PAPER_DARK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shelf.add_child(row)
	for slot_value in slots:
		var slot := StringName(slot_value)
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 92)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_override("font", PressScript.BodyFont)
		button.add_theme_font_size_override("font_size", PressScript.SIZE_BODY)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", PAPER)
		button.add_theme_color_override("font_focus_color", PAPER)
		button.add_theme_color_override("font_pressed_color", PAPER)
		button.focus_entered.connect(_select_slot.bind(slot))
		button.pressed.connect(_select_slot.bind(slot))
		row.add_child(button)
		_slot_buttons[slot] = button
		_motion.bind_button(button, PINK)

func _refresh() -> void:
	if _progress_label == null:
		return
	_progress_label.text = "%d / %d GROOVES FILLED" % [filled_slot_count(), slot_count()]
	_shine_label.text = "SHINE %03d" % _shine_count()
	var carried: Array[String] = []
	if economy != null:
		for item in EconomyScript.catalog():
			if bool(economy.call("has_item", item.id)):
				carried.append(item.name)
	_wares_label.text = "FROM THE STALL · " + " / ".join(carried) if not carried.is_empty() else "SHINE · Polish worn wax. Trade at the Bootlegger's stall."
	for slot in _discovery_buttons:
		var button: Button = _discovery_buttons[slot]
		button.visible = _slot_is_filled(slot)
		button.text = _slot_name(slot)
		_apply_card_style(button, true)
	if _selected_slot in _discovery_buttons and not _slot_is_filled(_selected_slot):
		_selected_slot = &"strike"
	_refresh_map()
	for slot in _all_slots():
		var button := _slot_buttons.get(slot) as Button
		if button == null:
			continue
		var filled := _slot_is_filled(slot)
		button.text = _slot_card_text(slot, filled)
		_apply_card_style(button, filled)
	_select_slot(_selected_slot, false)
	refresh_collection()

func _refresh_map() -> void:
	var owned := map_state != null and bool(map_state.get("owned"))
	_map_note.text = "The places you have reached, kept on one page." if owned else "A folded page waits near the start."
	_map_button.text = "Open map  [M]" if owned else "Find in the Headshell"
	_map_button.disabled = not owned
	_apply_card_style(_map_button, owned)
	_map_button.modulate = Color.WHITE
	_map_button.add_theme_stylebox_override("disabled", _card_style(false, false, false))

func _request_map() -> void:
	if _open and map_state != null and bool(map_state.get("owned")):
		map_requested.emit()

func _select_slot(slot: StringName, animate := true) -> void:
	var changed := slot != _selected_slot
	_selected_slot = slot
	if _detail_title == null:
		return
	var filled := _slot_is_filled(slot)
	_detail_kind.text = _slot_kind(slot)
	_detail_title.text = _slot_name(slot) if filled else "EMPTY GROOVE"
	_detail_state.text = _slot_state(slot, filled)
	_detail_state.modulate = PINK if filled else FADED
	_detail_description.text = _slot_description(slot) if filled else _locked_description(slot)
	if animate and changed and _open:
		_motion.reveal(_detail_stack, 0.0, 0.16)

func _resize_page() -> void:
	_settle_motion()
	if _page_margin == null or _header == null or _subtitle == null:
		return
	var compact := overlay.size.y < 620
	_page_margin.add_theme_constant_override("margin_top", 16 if compact else 30)
	_page_margin.add_theme_constant_override("margin_bottom", 14 if compact else 24)
	_page_stack.add_theme_constant_override("separation", 8 if compact else 12)
	_header.custom_minimum_size.y = 43 if compact else 62
	_subtitle.visible = not compact
	if _journey_detail != null:
		_journey_detail.custom_minimum_size.x = 280 if overlay.size.x < 1000 else 350
	for slot in _all_slots():
		var button := _slot_buttons.get(slot) as Button
		if button != null:
			button.custom_minimum_size.x = 120 if overlay.size.x < 1000 else 150

func _settle_motion() -> void:
	if _motion != null:
		_motion.settle()

func _focus_selected() -> void:
	if not _open:
		return
	if _current_page != "journey":
		_collection_pages.focus_selected()
		return
	var button := _slot_buttons.get(_selected_slot) as Button
	if button != null:
		button.grab_focus()

func _slot_is_filled(slot: StringName) -> bool:
	if slot in CORE_SLOTS:
		return true
	if slot == &"echo_spool":
		return discoveries != null and discoveries.snapshot().echo_spool != "missing"
	if slot == &"survey_slip":
		return discoveries != null and bool(discoveries.snapshot().survey_slip)
	if progression == null:
		return false
	var technique := _progression_id_for_slot(ProgressionScript.TECHNIQUE_KEYS, slot)
	if technique >= 0:
		return bool(progression.call("knows_technique", technique))
	var refrain := _progression_id_for_slot(ProgressionScript.REFRAIN_KEYS, slot)
	if refrain >= 0:
		return bool(progression.call("has_refrain", refrain))
	return false

func _slot_card_text(slot: StringName, filled: bool) -> String:
	if not filled:
		return "— — —\n%s · %s" % [_slot_kind(slot), "UNLEARNED" if _is_technique_slot(slot) else "UNHEARD"]
	return "%s\n%s · %s" % [_slot_name(slot), _slot_kind(slot), _slot_state(slot, true)]

func _slot_state(slot: StringName, filled: bool) -> String:
	if slot == &"echo_spool" and filled:
		match String(discoveries.snapshot().echo_spool):
			"empty": return "EMPTY · A PHRASE TO FIND"
			"recorded": return "RECORDED · AN ANSWER TO CARRY"
			"restored": return "RESTORED · THE WARREN SINGS"
	if slot == &"survey_slip":
		return "A NOTE FOR THE WAY HOME"
	if not filled:
		return "UNLEARNED" if _is_technique_slot(slot) else "UNHEARD"
	if slot in CORE_SLOTS:
		return "ALWAYS YOURS"
	if _is_technique_slot(slot):
		return "RECORDED"
	return "HELD"

func _slot_name(slot: StringName) -> String:
	match slot:
		&"echo_spool": return "ECHO SPOOL"
		&"survey_slip": return "SURVEYOR'S SLIP"
		&"strike":
			return "STRIKE"
		&"hood":
			return "HOOD"
		&"set":
			return "SET"
	var technique := _progression_id_for_slot(ProgressionScript.TECHNIQUE_KEYS, slot)
	if technique >= 0 and progression != null:
		return String(progression.call("technique_label", technique))
	var refrain := _progression_id_for_slot(ProgressionScript.REFRAIN_KEYS, slot)
	if refrain >= 0 and progression != null:
		return String(progression.call("refrain_label", refrain))
	return "UNKNOWN"

func _slot_kind(slot: StringName) -> String:
	if slot in [&"echo_spool", &"survey_slip"]:
		return "FOUND IN THE GROOVES"
	if slot in CORE_SLOTS:
		return "CORE VERB"
	if _is_technique_slot(slot):
		return "TECHNIQUE"
	return "REFRAIN"

func _slot_description(slot: StringName) -> String:
	match slot:
		&"echo_spool":
			match String(discoveries.snapshot().echo_spool):
				"empty": return "A little reel from the Deep Gallery, still waiting for a voice. Find the three-note pipe on the South Warren's upper walk. Stand beside it and press E / Y to record the whole phrase."
				"recorded": return "Three notes, safely held. Carry them to the shuttered receiver on the North Warren's western terrace. Press E / Y and stay beside it while the phrase plays."
				"restored": return "The shutter is open. Three answering discs remember the phrase together. Return to the North Warren's western terrace and press E / Y to hear it again. The spool stays with you."
		&"survey_slip":
			return "A surveyor's sketch, tucked above the Landing. A balcony is circled over the Stalls' right bank: 'Jump. Gather at the crest. A voice waits above the shutters.' Its answer may shorten the road home."
		&"strike":
			return "Three fresh strikes chain Tap, Sweep, Accent. The last hit lands harder. Ring live wax, launch from grooves, or catch an incoming blow on the beat."
		&"hood":
			return "Raise the Hood to quiet your crackle. You move more slowly, but fewer things hear you."
		&"set":
			return "Kneel without striking. Stay close and defenseless long enough to hear what is reaching for you."
		&"count-in":
			return "Four even strikes. Any tempo. The pattern worked before the Book learned its name."
		&"step-turn":
			return "The Book remembers a turn taken without losing the measure. Its lesson waits deeper in the record."
		&"gather":
			return "Jump, then Strike near the crest to climb on one held breath. Land to refill it. Thicker air keeps its own larger capacity."
		&"rest":
			return "A remembered Refrain. Its effect is quiet here; another groove may answer it."
		&"jump-cut":
			return "Turn the pressing over with F or the right shoulder. Ink and air invert for twelve seconds; the A-side rewinds the time you spend."
	return "The groove has no readable note."

func _locked_description(slot: StringName) -> String:
	if _is_technique_slot(slot):
		return "An unnamed lesson waits here. Your hands may know it before the Book names it."
	return "An empty carrying groove. Somewhere in the record, a Refrain has not yet answered you."

func _all_slots() -> Array[StringName]:
	var slots: Array[StringName] = []
	for core_slot in CORE_SLOTS:
		slots.append(StringName(core_slot))
	slots.append_array(_technique_slots())
	slots.append_array(_refrain_slots())
	return slots

func _technique_slots() -> Array[StringName]:
	var slots: Array[StringName] = []
	for technique in ProgressionScript.TECHNIQUE_ORDER:
		slots.append(StringName(ProgressionScript.TECHNIQUE_KEYS[technique]))
	return slots

func _refrain_slots() -> Array[StringName]:
	var slots: Array[StringName] = []
	for refrain in ProgressionScript.REFRAIN_ORDER:
		slots.append(StringName(ProgressionScript.REFRAIN_KEYS[refrain]))
	return slots

func _is_technique_slot(slot: StringName) -> bool:
	return _progression_id_for_slot(ProgressionScript.TECHNIQUE_KEYS, slot) >= 0

func _progression_id_for_slot(keys: Dictionary, slot: StringName) -> int:
	for progression_id in keys:
		if StringName(keys[progression_id]) == slot:
			return int(progression_id)
	return -1

func _shine_count() -> int:
	if shine_source == null:
		return 0
	return int(shine_source.get("shine"))

func _on_progression_changed(_id: int) -> void:
	_refresh()
	if _open:
		_motion.pulse(_progress_label)

## The Book is set from the same case as the world: wood type for the headings
## it shouts, set text for everything it merely records.
func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label_node := Label.new()
	label_node.text = text
	if font_size >= DISPLAY_AT:
		PressScript.set_display(label_node, font_size, color)
		label_node.add_theme_constant_override("font_spacing_glyph", PressScript.TRACKING_DISPLAY)
	else:
		PressScript.set_body(label_node, font_size, color)
	return label_node

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("14333a")
	style.border_color = Color("92774f")
	style.shadow_color = Color(0.01, 0.03, 0.04, 0.5)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

func _apply_card_style(button: Button, filled: bool) -> void:
	button.add_theme_stylebox_override("normal", _card_style(filled, false, false))
	button.add_theme_stylebox_override("hover", _card_style(filled, true, false))
	button.add_theme_stylebox_override("focus", _card_style(filled, true, true))
	button.add_theme_stylebox_override("pressed", _card_style(filled, true, true))
	button.modulate = Color.WHITE if filled else Color(0.78, 0.82, 0.78)

func _card_style(filled: bool, highlighted: bool, focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color("21484b")
		if filled
		else Color("132f37")
	)
	if highlighted:
		style.bg_color = style.bg_color.lightened(0.10)
	style.border_color = PINK if focused else (Color("947d59") if filled else Color("405c5c"))
	style.border_width_left = 3 if focused else 1
	style.border_width_top = 3 if focused else 1
	style.border_width_right = 3 if focused else 1
	style.border_width_bottom = 3 if focused else 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 15.0
	style.content_margin_top = 12.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style
