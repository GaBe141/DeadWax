extends CanvasLayer
## Full-screen progression inventory. It reads session state but never owns it.
## The menu keeps processing while the paused game waits underneath.

signal opened
signal closed

const ProgressionScript := preload("res://scripts/progression_state.gd")

const CORE_SLOTS := [&"strike", &"hood", &"set"]

const PAPER := Color(0.90, 0.87, 0.79)
const PAPER_DARK := Color(0.77, 0.72, 0.66)
const DEEP := Color(0.055, 0.045, 0.070)
const PINK := Color(0.90, 0.25, 0.50)
const VIOLET := Color(0.40, 0.29, 0.48)
const FADED := Color(0.48, 0.45, 0.50)

var progression: RefCounted
var shine_source: Node
var can_open: Callable

var overlay: Control
var _progress_label: Label
var _shine_label: Label
var _detail_kind: Label
var _detail_title: Label
var _detail_state: Label
var _detail_description: Label
var _slot_buttons: Dictionary = {}
var _selected_slot: StringName = &"strike"
var _open := false
var _tree_was_paused := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("inventory_menu")
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

func open_inventory() -> void:
	if _open:
		return
	if can_open.is_valid() and not bool(can_open.call()):
		return
	_tree_was_paused = get_tree().paused
	_open = true
	overlay.show()
	_refresh()
	_focus_selected()
	get_tree().paused = true
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
	get_tree().paused = _tree_was_paused
	closed.emit()

func toggle_inventory() -> void:
	if _open:
		close_inventory()
	else:
		open_inventory()

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

	var background := ColorRect.new()
	background.color = DEEP
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var edge := ColorRect.new()
	edge.color = PINK
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	edge.offset_bottom = 5.0
	overlay.add_child(edge)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 24)
	overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 62.0
	page.add_child(header)

	var title_stack := VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", -2)
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)
	title_stack.add_child(_make_label("INVENTORY — THE BOOK", 30, PAPER))
	title_stack.add_child(_make_label("what you carry between grooves", 15, PAPER_DARK))

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

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(content)

	var shelves := VBoxContainer.new()
	shelves.add_theme_constant_override("separation", 8)
	shelves.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shelves.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(shelves)
	_add_shelf(shelves, "CORE VERBS — ALWAYS YOURS", CORE_SLOTS)
	_add_shelf(shelves, "KNOWLEDGE — NAMED, NEVER GRANTED", _technique_slots())
	_add_shelf(shelves, "REFRAINS — CARRIED", _refrain_slots())

	var detail_panel := PanelContainer.new()
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

	var detail_stack := VBoxContainer.new()
	detail_stack.add_theme_constant_override("separation", 12)
	detail_margin.add_child(detail_stack)
	_detail_kind = _make_label("", 13, PINK)
	detail_stack.add_child(_detail_kind)
	_detail_title = _make_label("", 30, PAPER)
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_stack.add_child(_detail_title)
	var detail_rule := ColorRect.new()
	detail_rule.color = VIOLET
	detail_rule.custom_minimum_size.y = 2.0
	detail_stack.add_child(detail_rule)
	_detail_state = _make_label("", 15, PAPER_DARK)
	detail_stack.add_child(_detail_state)
	_detail_description = _make_label("", 17, PAPER)
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_stack.add_child(_detail_description)

	var footer := _make_label("[I / START] toggle     [ESC] close     [ARROWS / STICK] select", 14, PAPER_DARK)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(footer)
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
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_color_override("font_hover_color", PAPER)
		button.add_theme_color_override("font_focus_color", PAPER)
		button.add_theme_color_override("font_pressed_color", PAPER)
		button.focus_entered.connect(_select_slot.bind(slot))
		button.pressed.connect(_select_slot.bind(slot))
		row.add_child(button)
		_slot_buttons[slot] = button

func _refresh() -> void:
	if _progress_label == null:
		return
	_progress_label.text = "%d / %d GROOVES FILLED" % [filled_slot_count(), slot_count()]
	_shine_label.text = "SHINE %03d" % _shine_count()
	for slot in _all_slots():
		var button := _slot_buttons.get(slot) as Button
		if button == null:
			continue
		var filled := _slot_is_filled(slot)
		button.text = _slot_card_text(slot, filled)
		_apply_card_style(button, filled)
	_select_slot(_selected_slot)

func _select_slot(slot: StringName) -> void:
	_selected_slot = slot
	if _detail_title == null:
		return
	var filled := _slot_is_filled(slot)
	_detail_kind.text = _slot_kind(slot)
	_detail_title.text = _slot_name(slot) if filled else "EMPTY GROOVE"
	_detail_state.text = _slot_state(slot, filled)
	_detail_state.modulate = PINK if filled else FADED
	_detail_description.text = _slot_description(slot) if filled else _locked_description(slot)

func _focus_selected() -> void:
	if not _open:
		return
	var button := _slot_buttons.get(_selected_slot) as Button
	if button != null:
		button.grab_focus()

func _slot_is_filled(slot: StringName) -> bool:
	if slot in CORE_SLOTS:
		return true
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
	if not filled:
		return "UNLEARNED" if _is_technique_slot(slot) else "UNHEARD"
	if slot in CORE_SLOTS:
		return "ALWAYS YOURS"
	if _is_technique_slot(slot):
		return "RECORDED"
	return "HELD"

func _slot_name(slot: StringName) -> String:
	match slot:
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
	if slot in CORE_SLOTS:
		return "CORE VERB"
	if _is_technique_slot(slot):
		return "TECHNIQUE"
	return "REFRAIN"

func _slot_description(slot: StringName) -> String:
	match slot:
		&"strike":
			return "Ring live wax, launch from grooves, and catch an incoming blow on the beat."
		&"hood":
			return "Raise the Hood to quiet your crackle. You move more slowly, but fewer things hear you."
		&"set":
			return "Kneel without striking. Stay close and defenseless long enough to hear what is reaching for you."
		&"count-in":
			return "Four even strikes. Any tempo. The pattern worked before the Book learned its name."
		&"step-turn":
			return "The Book remembers a turn taken without losing the measure. Its lesson waits deeper in the record."
		&"gather":
			return "Carry one held breath into dry wax. Rooms with thicker air keep their own larger capacity."
		&"rest":
			return "A remembered Refrain. Its effect is quiet here; another groove may answer it."
		&"jump-cut":
			return "A remembered Refrain. Its effect is quiet here; another groove may answer it."
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

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label_node := Label.new()
	label_node.text = text
	label_node.add_theme_font_size_override("font_size", font_size)
	label_node.add_theme_color_override("font_color", color)
	return label_node

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.075, 0.13, 0.96)
	style.border_color = VIOLET
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
	button.modulate = Color.WHITE if filled else Color(0.72, 0.69, 0.74)

func _card_style(filled: bool, highlighted: bool, focused: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = (
		Color(0.23, 0.14, 0.27, 0.98)
		if filled
		else Color(0.105, 0.085, 0.125, 0.92)
	)
	if highlighted:
		style.bg_color = style.bg_color.lightened(0.10)
	style.border_color = PINK if focused else (VIOLET if filled else Color(0.25, 0.22, 0.28))
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
