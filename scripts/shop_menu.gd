extends CanvasLayer
## The Bootlegger's counter is a view over a supplied snapshot. Main owns every
## purchase, save and pause transition; this layer only offers deliberate intent.

signal purchase_requested(item_id: StringName)
signal close_requested

const Press := preload("res://scripts/press.gd")
const Economy := preload("res://scripts/economy_state.gd")
const PAPER := Color("e4d9c3")
const STOCK := Color("c9bbaa")
const INK := Color("211d24")
const FADED := Color("71646a")
const AMBER := Color("b87a39")

var is_open := false
var overlay: Control
var _snapshot: Dictionary = {}
var _catalog: Array[Dictionary] = []
var _selected: StringName = &"spare_groove"
var _products: Dictionary = {}
var _opening_gate := false
var _purchase_pending := false
var _close_pending := false
var _margin: MarginContainer
var _columns: HBoxContainer
var _catalog_column: VBoxContainer
var _detail_column: VBoxContainer
var _title: Label
var _balance: Label
var _needle: Label
var _detail_title: Label
var _description: Label
var _status: Label
var _notice: Label
var _footer: Label
var _buy: Button
var _leave: Button
var _art: ItemArt

class ItemArt extends Control:
	var item_id: StringName = &"spare_groove"
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		Press.draw_shop_item(self, item_id, size, INK, PAPER)

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_catalog = Economy.catalog()
	_build()
	close_shop()

func _process(_delta: float) -> void:
	if is_open and _opening_gate and not Input.is_action_pressed("trade") and not Input.is_action_pressed("ui_accept"):
		_opening_gate = false

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_request_close()
		return
	if event.is_action("trade"):
		# D-pad Up opens the counter in the world and navigates the catalog
		# inside it. Keyboard B and the ordinary cancel buttons close it.
		var pad_up: bool = event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_UP
		if _opening_gate or not pad_up:
			get_viewport().set_input_as_handled()
			if event.is_pressed() and not _opening_gate:
				_request_close()
			return
	if event.is_action("inventory") or event.is_action("enter_passage"):
		get_viewport().set_input_as_handled()
		return
	if _opening_gate and event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()

func show_shop(snapshot: Dictionary) -> void:
	if overlay == null:
		return
	is_open = true
	_opening_gate = true
	_close_pending = false
	_selected = StringName(_catalog[0].id) if not _catalog.is_empty() else &""
	overlay.show()
	refresh_shop(snapshot)
	call_deferred("_focus_selected")

func refresh_shop(snapshot: Dictionary, notice: String = "") -> void:
	_snapshot = snapshot.duplicate(true)
	_purchase_pending = false
	if overlay == null:
		return
	_notice.text = notice
	_notice.visible = not notice.is_empty()
	_refresh_view()
	if is_open and _buy.disabled and get_viewport().gui_get_focus_owner() == _buy:
		call_deferred("_focus_selected")

func close_shop() -> void:
	is_open = false
	_opening_gate = false
	_purchase_pending = false
	_close_pending = false
	if overlay == null:
		return
	overlay.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and overlay.is_ancestor_of(focused):
		focused.release_focus()

func selected_item() -> StringName:
	return _selected

func buy_button() -> Button:
	return _buy

func product_button(item_id: StringName) -> Button:
	return _products.get(item_id) as Button

func balance_text() -> String:
	return _balance.text

func _build() -> void:
	overlay = Control.new()
	overlay.name = "ShopOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.resized.connect(_resize)
	var backing := Press.plate(Vector2(1280.0, 720.0), PAPER, STOCK, AMBER)
	overlay.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = MarginContainer.new()
	overlay.add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet := VBoxContainer.new()
	sheet.add_theme_constant_override("separation", 14)
	_margin.add_child(sheet)
	var imprint := HBoxContainer.new()
	sheet.add_child(imprint)
	var imprint_name := _label("DW   /   WORN NAMES ONLY", Press.SIZE_TINY, FADED)
	imprint_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	imprint.add_child(imprint_name)
	imprint.add_child(_label("THE OVERTURE", Press.SIZE_TINY, FADED))
	sheet.add_child(_rule())
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	sheet.add_child(header)
	var introduction := VBoxContainer.new()
	introduction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(introduction)
	_title = _label("THE BOOTLEGGER", Press.SIZE_MENU_TITLE, INK, true)
	introduction.add_child(_title)
	introduction.add_child(_label("A few good things, kept for you.", Press.SIZE_SMALL, FADED))
	var ledger := VBoxContainer.new()
	ledger.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(ledger)
	_balance = _label("SHINE 000", Press.SIZE_TITLE, INK, true)
	_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ledger.add_child(_balance)
	_needle = _label("", Press.SIZE_TINY, FADED)
	_needle.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ledger.add_child(_needle)
	_leave = _button("Leave", _request_close)
	_leave.custom_minimum_size.x = 94.0
	_leave.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_leave)
	var scroll := ScrollContainer.new()
	scroll.name = "StockScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	sheet.add_child(scroll)
	_columns = HBoxContainer.new()
	_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_columns.add_theme_constant_override("separation", 40)
	scroll.add_child(_columns)
	_catalog_column = VBoxContainer.new()
	_catalog_column.custom_minimum_size.x = 340.0
	_catalog_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_catalog_column.size_flags_stretch_ratio = 0.95
	_catalog_column.add_theme_constant_override("separation", 11)
	_columns.add_child(_catalog_column)
	_catalog_column.add_child(_label("ON THE COUNTER", Press.SIZE_HEADING, FADED, true))
	for index in _catalog.size():
		var item: Dictionary = _catalog[index]
		var id := StringName(item.id)
		var button := _button("", _select.bind(id, true))
		button.name = String(id).to_pascal_case()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 76.0
		button.focus_entered.connect(_select.bind(id, false))
		_catalog_column.add_child(button)
		_products[id] = button
	var note := _label("Every piece is yours to keep.\nNothing here runs out.", Press.SIZE_SMALL, FADED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_catalog_column.add_child(note)
	_detail_column = VBoxContainer.new()
	_detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_column.size_flags_stretch_ratio = 1.2
	_detail_column.add_theme_constant_override("separation", 9)
	_columns.add_child(_detail_column)
	_art = ItemArt.new()
	_art.custom_minimum_size = Vector2(200.0, 126.0)
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_column.add_child(_art)
	_detail_title = _label("", Press.SIZE_BANNER, INK, true)
	_detail_column.add_child(_detail_title)
	_description = _label("", Press.SIZE_BODY, INK)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_column.add_child(_description)
	_status = _label("", Press.SIZE_SMALL, FADED)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_column.add_child(_status)
	_buy = _button("Buy", _request_purchase)
	_buy.name = "BuySelected"
	_buy.custom_minimum_size.y = 50.0
	_detail_column.add_child(_buy)
	sheet.add_child(_rule())
	_notice = _label("", Press.SIZE_SMALL, INK)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.hide()
	sheet.add_child(_notice)
	_footer = _label("ARROWS / STICK  select     ENTER / A  inspect / buy     ESC / B  leave", Press.SIZE_TINY, FADED)
	_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sheet.add_child(_footer)
	var paper := Press.paper_overlay(INK)
	overlay.add_child(paper)
	_resize()

func _resize() -> void:
	if _margin == null:
		return
	var narrow := overlay.size.x < 1050.0
	for side in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, 26 if narrow else 52)
	_margin.add_theme_constant_override("margin_top", 22 if narrow else 32)
	_margin.add_theme_constant_override("margin_bottom", 18 if narrow else 25)
	_columns.add_theme_constant_override("separation", 25 if narrow else 44)
	_catalog_column.custom_minimum_size.x = 285.0 if narrow else 340.0
	Press.set_display(_title, Press.SIZE_BANNER if narrow else Press.SIZE_MENU_TITLE, INK)
	Press.set_display(_detail_title, Press.SIZE_TITLE if narrow else Press.SIZE_BANNER, INK)
	_art.custom_minimum_size.y = 104.0 if overlay.size.y < 650.0 else 126.0

func _refresh_view() -> void:
	var shine := maxi(int(_snapshot.get("shine", 0)), 0)
	_balance.text = "SHINE %03d" % shine
	_needle.text = "%d NEEDLE HITS" % maxi(int(_snapshot.get("max_health", 3)), 1)
	var purchases: Array = _snapshot.get("purchases", [])
	for entry in _catalog:
		var id := StringName(entry.id)
		var owned := purchases.has(String(id)) or purchases.has(id)
		var button: Button = _products[id]
		button.text = "%s\n%s" % [String(entry.name).to_upper(), "YOURS" if owned else "%02d SHINE" % int(entry.price)]
		_style_button(button, id == _selected)
	var item := Economy.item(_selected)
	if item.is_empty():
		return
	var owned := purchases.has(String(_selected)) or purchases.has(_selected)
	var price := int(item.price)
	_detail_title.text = String(item.name).to_upper()
	_description.text = String(item.description)
	_art.item_id = _selected
	_art.queue_redraw()
	_buy.disabled = owned or shine < price or _purchase_pending
	_buy.text = "Yours to keep" if owned else "Buy for %d Shine" % price
	if owned:
		_status.text = "Already fitted. Take it with you."
	elif shine < price:
		_status.text = "Bring %d more Shine. Polished wax catches the light." % (price - shine)
	else:
		_status.text = "%d Shine will remain." % (shine - price)
	_wire_focus()

func _select(item_id: StringName, inspect: bool) -> void:
	if not is_open or _close_pending:
		return
	_selected = item_id
	_refresh_view()
	if inspect and not _opening_gate and not _buy.disabled:
		_buy.grab_focus()

func _request_purchase() -> void:
	if not is_open or _opening_gate or _purchase_pending or _close_pending or _buy.disabled:
		return
	_purchase_pending = true
	_buy.disabled = true
	purchase_requested.emit(_selected)

func _request_close() -> void:
	if not is_open or _close_pending:
		return
	_close_pending = true
	close_requested.emit()

func _focus_selected() -> void:
	if is_open and _products.has(_selected):
		(_products[_selected] as Button).grab_focus()

func _wire_focus() -> void:
	var ids := _products.keys()
	for index in ids.size():
		var button: Button = _products[ids[index]]
		button.focus_neighbor_top = button.get_path_to(_products[ids[(index + ids.size() - 1) % ids.size()]])
		button.focus_neighbor_bottom = button.get_path_to(_products[ids[(index + 1) % ids.size()]])
		button.focus_neighbor_right = button.get_path_to(_leave if _buy.disabled else _buy)
		button.focus_neighbor_left = button.get_path_to(_leave)
		button.focus_next = button.get_path_to(_leave if _buy.disabled else _buy)
		button.focus_previous = button.get_path_to(_leave)
	_buy.focus_neighbor_left = _buy.get_path_to(_products[_selected])
	_buy.focus_neighbor_top = _buy.get_path_to(_products[_selected])
	_buy.focus_neighbor_right = _buy.get_path_to(_leave)
	_buy.focus_neighbor_bottom = _buy.get_path_to(_leave)
	_buy.focus_next = _buy.get_path_to(_leave)
	_buy.focus_previous = _buy.get_path_to(_products[_selected])
	_leave.focus_neighbor_bottom = _leave.get_path_to(_products[_selected])
	_leave.focus_neighbor_left = _leave.get_path_to(_products[_selected])
	_leave.focus_next = _leave.get_path_to(_products[_selected])
	_leave.focus_previous = _leave.get_path_to(_buy if not _buy.disabled else _products[_selected])

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = 44.0
	button.pressed.connect(callback)
	_style_button(button)
	return button

func _style_button(button: Button, selected := false) -> void:
	button.add_theme_font_override("font", Press.BodyFont)
	button.add_theme_font_size_override("font_size", Press.SIZE_BODY)
	button.add_theme_color_override("font_color", PAPER if selected else INK)
	button.add_theme_color_override("font_focus_color", PAPER if selected else INK)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", PAPER)
	button.add_theme_color_override("font_disabled_color", FADED)
	button.add_theme_stylebox_override("normal", Press.menu_button_style(INK, PAPER, selected))
	button.add_theme_stylebox_override("hover", Press.menu_button_style(INK, PAPER, true))
	button.add_theme_stylebox_override("pressed", Press.menu_button_style(INK, PAPER, true, true))
	button.add_theme_stylebox_override("focus", Press.menu_button_style(INK, PAPER, selected, true))
	button.add_theme_stylebox_override("disabled", Press.menu_button_style(INK, PAPER))

func _label(text: String, font_size: int, color: Color, display := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display:
		Press.set_display(label, font_size, color)
	else:
		Press.set_body(label, font_size, color)
	return label

func _rule() -> Control:
	var rule := Press.plate(Vector2(1280.0, 1.0), INK, PAPER, AMBER)
	rule.custom_minimum_size.y = 1.0
	return rule
