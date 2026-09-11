extends VBoxContainer
## Read-only leaves of The Book. Every fitting and crafting action is an intent;
## Main supplies the resulting snapshot only after its transaction succeeds.

signal equip_requested(item_id: String)
signal unequip_requested(slot: String)
signal craft_requested(item_id: String)

const Press := preload("res://scripts/press.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const INK := Color("f2e1bc")
const FADED := Color("c2ae87")
const ACCENT := Color("d6a968")
const SLOTS := ["needle", "lining", "charm"]

var book: CanvasLayer
var motion: Node
var _model: RefCounted
var _snapshot: Dictionary = {}
var _page := "equipment"
var _selected_item := ""
var _selected_species := ""
var _equipment: VBoxContainer
var _bestiary: VBoxContainer
var _gear_buttons: Dictionary = {}
var _species_buttons: Dictionary = {}
var _slot_names: Dictionary = {}
var _clear_buttons: Dictionary = {}
var _completion: Label
var _offcuts: Label
var _gear_title: Label
var _gear_kind: Label
var _gear_description: Label
var _gear_tradeoff: Label
var _gear_source: Label
var _gear_odds: Label
var _gear_action: Button
var _recipe: Label
var _fit_summary: Label
var _notice: Label
var _hunt_progress: Label
var _species_progress: Label
var _species_title: Label
var _species_kind: Label
var _species_description: Label
var _species_habitat: Label
var _species_tip: Label
var _species_counts: Label
var _gear_detail: VBoxContainer
var _species_detail: VBoxContainer
var _gear_list: ScrollContainer
var _species_list: ScrollContainer
var _gear_notes: ScrollContainer
var _species_notes: ScrollContainer

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	_build_equipment()
	_build_bestiary()
	show_page(_page)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not book.is_open() or not event is InputEventKey or not event.pressed:
		return
	if event.keycode == KEY_PAGEDOWN or event.physical_keycode == KEY_PAGEDOWN:
		scroll_notes(120)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_PAGEUP or event.physical_keycode == KEY_PAGEUP:
		scroll_notes(-120)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not book.is_open():
		return
	for device in Input.get_connected_joypads():
		var amount := Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
		if absf(amount) > 0.25:
			scroll_notes(amount * 520.0 * delta)
			break

func scroll_notes(amount: float) -> void:
	var notes := _gear_notes if _page == "equipment" else _species_notes
	if notes != null:
		notes.scroll_vertical += roundi(amount)

func show_page(page_id: String) -> void:
	_page = page_id
	if _equipment == null:
		return
	_equipment.visible = page_id == "equipment"
	_bestiary.visible = page_id == "bestiary"

func refresh(model: RefCounted, notice := "") -> void:
	_model = model
	_snapshot = model.snapshot() if model != null else {}
	if _equipment == null:
		return
	var owned: Array = _snapshot.get("owned", [])
	var equipped: Dictionary = _snapshot.get("equipped", {})
	var offcuts := int(_snapshot.get("offcuts", 0))
	_completion.text = "RARE PRESSINGS   %02d / %02d" % [owned.size(), Catalog.items().size()]
	_offcuts.text = "OFFCUTS %03d" % offcuts
	_notice.text = notice
	_notice.visible = not notice.is_empty()
	var modifiers: Dictionary = model.modifiers() if model != null else {"speed": 1.0, "accel": 1.0, "friction": 1.0, "air_control": 1.0, "hood_speed": 1.0, "noise_decay": 1.0, "health": 0}
	_fit_summary.text = "CURRENT FIT · Combined equipment effects\nRun %d%% / Acceleration %d%% / Braking %d%%\nAir steering %d%% / Hood %d%% / Noise fading %d%%\nNeedle capacity %+d. Combined health changes stop at ±1; handling at 65–140%% of normal. Recover to fill added health." % [roundi(modifiers.speed * 100), roundi(modifiers.accel * 100), roundi(modifiers.friction * 100), roundi(modifiers.air_control * 100), roundi(modifiers.hood_speed * 100), roundi(modifiers.noise_decay * 100), int(modifiers.health)]
	for slot in SLOTS:
		var item_id := String(equipped.get(slot, ""))
		var item: Dictionary = Catalog.item(item_id)
		var title: Label = _slot_names[slot]
		title.text = String(item.get("name", "Nothing fitted"))
		var clear: Button = _clear_buttons[slot]
		clear.disabled = item_id.is_empty()
		clear.tooltip_text = "Remove this %s. Its benefits and its cost both end." % slot
	for id in _gear_buttons:
		var item: Dictionary = Catalog.item(id)
		var button: Button = _gear_buttons[id]
		var fitted: bool = String(equipped.get(item.slot, "")) == String(id)
		button.text = "%s%s\n%s / %s" % ["● " if fitted else ("+ " if id in owned else "· "), item.name, String(item.slot).to_upper(), "FITTED" if fitted else ("CARRIED" if id in owned else String(item.rarity).to_upper())]
		book._apply_card_style(button, id in owned)
		button.tooltip_text = String(item.tradeoff)
	var hunt_lines: Array[String] = []
	var hunts: Dictionary = _snapshot.get("hunts", {})
	for hunt in Catalog.hunts():
		var progress: Dictionary = hunts.get(hunt.id, {})
		var wins := int(progress.get("wins", 0))
		hunt_lines.append("%s %d/%d%s" % [hunt.name, mini(wins, int(hunt.mastery_wins)), int(hunt.mastery_wins), " ✓" if wins >= int(hunt.mastery_wins) else ""])
	_hunt_progress.text = "OPTIONAL MASTERY  ·  " + "  /  ".join(hunt_lines) + "\nNOTES  ·  Mouse wheel / PgUp PgDn / right stick"
	var seen := 0
	var bestiary: Dictionary = _snapshot.get("bestiary", {})
	for id in _species_buttons:
		var entry: Dictionary = Catalog.species_entry(id)
		var known := bool(bestiary.get(id, {}).get("seen", false))
		if known:
			seen += 1
		var button: Button = _species_buttons[id]
		button.text = String(entry.name) if known else "— UNRECORDED VOICE —"
		book._apply_card_style(button, known)
	_species_progress.text = "%02d / %02d VOICES RECORDED" % [seen, Catalog.species().size()]
	_select_item(_selected_item, false)
	_select_species(_selected_species, false)
	# A completed transaction can disable its focused action. Restore a usable
	# list target without accepting a second action from the same input.
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and is_ancestor_of(focus) and focus is Button and focus.disabled:
		call_deferred("focus_selected")

func focus_selected() -> void:
	if not is_visible_in_tree():
		return
	var button: Button = _gear_buttons.get(_selected_item) if _page == "equipment" else _species_buttons.get(_selected_species)
	if button != null:
		button.grab_focus()

func select_item(item_id: String) -> void:
	_select_item(item_id)

func select_species(species_id: String) -> void:
	_select_species(species_id)

func _build_equipment() -> void:
	_equipment = VBoxContainer.new()
	_equipment.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_equipment.add_theme_constant_override("separation", 10)
	add_child(_equipment)
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 10)
	_equipment.add_child(slots)
	for slot in SLOTS:
		var panel := _panel()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slots.add_child(panel)
		var body := _inset(panel, 10)
		var heading := HBoxContainer.new()
		body.add_child(heading)
		var kind := _label(String(slot).to_upper(), Press.SIZE_SMALL, ACCENT)
		kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(kind)
		var clear := _button("Remove", _request_unequip.bind(slot))
		clear.custom_minimum_size = Vector2(76, 30)
		_small_button(clear)
		heading.add_child(clear)
		_clear_buttons[slot] = clear
		var title := _label("Nothing fitted", Press.SIZE_BODY, INK)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(title)
		_slot_names[slot] = title
	var ledger := HBoxContainer.new()
	_equipment.add_child(ledger)
	_completion = _label("", Press.SIZE_HEADING, INK)
	_completion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ledger.add_child(_completion)
	_offcuts = _label("", Press.SIZE_BODY, ACCENT)
	ledger.add_child(_offcuts)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_equipment.add_child(columns)
	_gear_list = _scroll()
	_gear_list.size_flags_stretch_ratio = 0.90
	columns.add_child(_gear_list)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	_gear_list.add_child(list)
	for hunt in Catalog.hunts():
		list.add_child(_label(String(hunt.name).to_upper(), Press.SIZE_SMALL, FADED))
		for item in Catalog.items():
			if item.source != hunt.id:
				continue
			var id := String(item.id)
			if _selected_item.is_empty():
				_selected_item = id
			var button := _button("", _select_item.bind(id, true))
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.custom_minimum_size.y = 62
			button.focus_entered.connect(_select_item.bind(id, true))
			list.add_child(button)
			_gear_buttons[id] = button
	var detail_column := VBoxContainer.new()
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_column.add_theme_constant_override("separation", 8)
	columns.add_child(detail_column)
	var detail_scroll := _scroll()
	_gear_notes = detail_scroll
	detail_column.add_child(detail_scroll)
	var panel := _panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(panel)
	_gear_detail = _inset(panel, 18)
	_gear_kind = _text(_gear_detail, Press.SIZE_SMALL, ACCENT)
	_gear_title = _text(_gear_detail, Press.SIZE_TITLE, INK)
	_gear_description = _text(_gear_detail, Press.SIZE_BODY, FADED)
	_gear_detail.add_child(_rule())
	_gear_tradeoff = _text(_gear_detail, Press.SIZE_BODY, INK)
	_gear_source = _text(_gear_detail, Press.SIZE_SMALL, ACCENT)
	_gear_odds = _text(_gear_detail, Press.SIZE_SMALL, FADED)
	_recipe = _text(_gear_detail, Press.SIZE_SMALL, FADED)
	_gear_detail.add_child(_rule())
	_fit_summary = _text(_gear_detail, Press.SIZE_TINY, FADED)
	_gear_action = _button("", _request_item_action)
	detail_column.add_child(_gear_action)
	for button in _gear_buttons.values():
		button.focus_neighbor_right = button.get_path_to(_gear_action)
	_notice = _text(detail_column, Press.SIZE_SMALL, ACCENT)
	_hunt_progress = _text(_equipment, Press.SIZE_TINY, FADED)

func _build_bestiary() -> void:
	_bestiary = VBoxContainer.new()
	_bestiary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bestiary.add_theme_constant_override("separation", 12)
	add_child(_bestiary)
	_species_progress = _text(_bestiary, Press.SIZE_HEADING, INK)
	var introduction := _text(_bestiary, Press.SIZE_SMALL, FADED)
	introduction.text = "A field guide to the lives caught in the record. Meet them to leave a name here."
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	_bestiary.add_child(columns)
	_species_list = _scroll()
	_species_list.size_flags_stretch_ratio = 0.72
	columns.add_child(_species_list)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	_species_list.add_child(list)
	for entry in Catalog.species():
		var id := String(entry.id)
		if _selected_species.is_empty():
			_selected_species = id
		var button := _button("", _select_species.bind(id, true))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		button.focus_entered.connect(_select_species.bind(id, true))
		list.add_child(button)
		_species_buttons[id] = button
	var detail_scroll := _scroll()
	_species_notes = detail_scroll
	columns.add_child(detail_scroll)
	var panel := _panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.add_child(panel)
	_species_detail = _inset(panel, 22)
	_species_kind = _text(_species_detail, Press.SIZE_SMALL, ACCENT)
	_species_title = _text(_species_detail, Press.SIZE_TITLE, INK)
	_species_detail.add_child(_rule())
	_species_description = _text(_species_detail, Press.SIZE_BODY, INK)
	_species_habitat = _text(_species_detail, Press.SIZE_SMALL, FADED)
	_species_tip = _text(_species_detail, Press.SIZE_BODY, ACCENT)
	_species_counts = _text(_species_detail, Press.SIZE_SMALL, FADED)
	var note_hint := _text(_bestiary, Press.SIZE_TINY, FADED)
	note_hint.text = "NOTES  ·  Mouse wheel / PgUp PgDn / right stick"

func _select_item(id: String, animate := true) -> void:
	var item: Dictionary = Catalog.item(id)
	if item.is_empty():
		return
	var changed := id != _selected_item
	_selected_item = id
	var owned: Array = _snapshot.get("owned", [])
	var equipped: Dictionary = _snapshot.get("equipped", {})
	var fitted := String(equipped.get(item.slot, "")) == id
	var hunt: Dictionary = Catalog.hunt(item.source)
	var source_state: Dictionary = _snapshot.get("hunts", {}).get(item.source, {})
	var wins := int(source_state.get("wins", 0))
	var dry := int(source_state.get("dry", 0))
	_gear_kind.text = "%s / %s / %s" % [String(item.slot).to_upper(), String(item.rarity).to_upper(), "FITTED" if fitted else ("CARRIED" if id in owned else "NOT FOUND")]
	_gear_title.text = String(item.name)
	_gear_description.text = String(item.description)
	_gear_tradeoff.text = String(item.tradeoff)
	_gear_source.text = "%s\n%s" % [hunt.name, hunt.description]
	_gear_odds.text = "%d%% per clear. Any gear: 10%%.\nGuaranteed gear within 20 clears without a drop; missing pieces take priority. %d clears remain." % [int(item.drop_chance), maxi(1, 20 - dry)]
	if id in owned:
		_recipe.text = "One piece per slot. Fitting another %s replaces the current one." % String(item.slot)
		_gear_action.text = "Remove %s" % String(item.slot) if fitted else "Fit %s" % String(item.slot)
		_gear_action.disabled = _model == null
	else:
		_recipe.text = "Every clear: +1 Offcut. Duplicate gear: +5 more.\nBind a missing piece for 40 Offcuts after one clear of its source."
		_gear_action.text = "Bind for 40 Offcuts" if wins > 0 else "Clear this trial to bind"
		_gear_action.disabled = _model == null or not bool(_model.can_craft(id))
	book._apply_card_style(_gear_action, not _gear_action.disabled)
	_gear_action.focus_neighbor_left = _gear_action.get_path_to(_gear_buttons[id])
	if changed:
		_gear_notes.scroll_vertical = 0
	if animate and changed and is_visible_in_tree():
		motion.reveal(_gear_detail, 0.0, 0.16)

func _select_species(id: String, animate := true) -> void:
	var entry: Dictionary = Catalog.species_entry(id)
	if entry.is_empty():
		return
	var changed := id != _selected_species
	_selected_species = id
	var record: Dictionary = _snapshot.get("bestiary", {}).get(id, {})
	var seen := bool(record.get("seen", false))
	_species_kind.text = "FIELD NOTE / RECORDED" if seen else "FIELD NOTE / UNWRITTEN"
	_species_title.text = String(entry.name) if seen else "AN UNRECORDED VOICE"
	_species_description.text = String(entry.description) if seen else "There is a space for someone you have not met. Their name and habits will appear when your paths cross."
	_species_habitat.text = "WHERE THEY BELONG\n" + String(entry.habitat) if seen else "Explore the Label, Overture and Unplayed to fill these pages."
	_species_tip.text = "LISTENING NOTE\n" + String(entry.tip) if seen else "A meeting is enough to make a note. You do not need to harm every life in the record."
	_species_counts.text = "FREED  %d     SHATTERED  %d\nRecorded story outcomes remain as you left them." % [int(record.get("freed", 0)), int(record.get("shattered", 0))] if seen else ""
	if changed:
		_species_notes.scroll_vertical = 0
	if animate and changed and is_visible_in_tree():
		motion.reveal(_species_detail, 0.0, 0.16)

func _request_item_action() -> void:
	if _model == null or _gear_action.disabled or not book.is_open() or _page != "equipment":
		return
	var item: Dictionary = Catalog.item(_selected_item)
	if item.is_empty():
		return
	if bool(_model.has_item(_selected_item)):
		if String(_snapshot.get("equipped", {}).get(item.slot, "")) == _selected_item:
			unequip_requested.emit(String(item.slot))
		else:
			equip_requested.emit(_selected_item)
	elif bool(_model.can_craft(_selected_item)):
		craft_requested.emit(_selected_item)

func _request_unequip(slot: String) -> void:
	if book.is_open() and _page == "equipment" and not String(_snapshot.get("equipped", {}).get(slot, "")).is_empty():
		unequip_requested.emit(slot)

func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	return scroll

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", book._panel_style())
	return panel

func _inset(panel: PanelContainer, inset: int) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, inset)
	panel.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	margin.add_child(body)
	return body

func _rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.custom_minimum_size.y = 1
	rule.color = Color("52716d")
	return rule

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	if font_size >= Press.SIZE_TITLE:
		Press.set_display(label, font_size, color)
	else:
		Press.set_body(label, font_size, color)
	return label

func _text(parent: Node, font_size: int, color: Color) -> Label:
	var label := _label("", font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _button(value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.focus_mode = Control.FOCUS_ALL
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", Press.BodyFont)
	button.add_theme_font_size_override("font_size", Press.SIZE_SMALL)
	for key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(key, INK)
	button.add_theme_color_override("font_disabled_color", FADED)
	button.pressed.connect(action)
	book._apply_card_style(button, true)
	button.add_theme_stylebox_override("disabled", book._card_style(false, false, false))
	motion.bind_button(button, ACCENT)
	return button

func _small_button(button: Button) -> void:
	for key in ["normal", "hover", "focus", "pressed", "disabled"]:
		var style := button.get_theme_stylebox(key).duplicate() as StyleBoxFlat
		style.content_margin_left = 7
		style.content_margin_right = 7
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		button.add_theme_stylebox_override(key, style)
