extends CanvasLayer
## A read-only folded guide. Main owns acquiring it, exploration, and pausing.

signal close_requested

const Press := preload("res://scripts/press.gd")
const Chart := preload("res://scripts/campaign_chart.gd")
const Motion := preload("res://scripts/ui_motion.gd")
const PAPER := Color("17343c")
const STOCK := Color("0b222b")
const INK := Color("f1dfb8")
const FADED := Color("c0b28b")
const WorldBackdrop := preload("res://scripts/ui_world_backdrop.gd")

var is_open := false
var overlay: Control
var _snapshot: Dictionary = {}
var _motion: Node
var _chart: ChartArt
var _current: Label
var _count: Label
var _close: Button
var _header: Control
var _footer: Control
var _background: ColorRect
var _margin: MarginContainer
var _reduced_motion := false
var _opening_gate := false
var _close_pending := false

class ChartArt extends Control:
	var visited: Array[String] = []
	var current_room := ""
	var clock := 0.0
	var reduced_motion := false
	var _draw_left := 0.0
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _process(delta: float) -> void:
		if reduced_motion or delta <= 0.0 or not is_visible_in_tree():
			return
		clock += minf(delta, 0.1)
		_draw_left -= delta
		if _draw_left <= 0.0:
			_draw_left = 1.0 / 30.0
			queue_redraw()
	func _draw() -> void:
		Press.draw_campaign_map(self, size, {"visited": visited, "current_room": current_room,
			"clock": clock, "reduced_motion": reduced_motion}, INK, PAPER)

func _ready() -> void:
	layer = 115
	process_mode = Node.PROCESS_MODE_ALWAYS
	_motion = Motion.new()
	_motion.name = "UiMotion"
	add_child(_motion)
	_motion.reduced_motion = _reduced_motion
	_build()
	close_map()

func _process(_delta: float) -> void:
	if is_open and _opening_gate and not _held("map") and not _held("ui_accept"):
		_opening_gate = false

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()
		return
	if event.is_action("map"):
		get_viewport().set_input_as_handled()
		if event.is_pressed() and not _opening_gate:
			_request_close()
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		_request_close()
		return
	if event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()
		if event.is_pressed() and not _opening_gate:
			_request_close()
		return
	for action in ["inventory", "trade", "enter_passage", "strike", "jump", "lift", "set", "restart", "flip"]:
		if event.is_action(action):
			get_viewport().set_input_as_handled()
			return

func show_map(snapshot: Dictionary) -> void:
	if overlay == null:
		return
	if not bool(snapshot.get("owned", false)):
		close_map()
		return
	_motion.settle()
	_snapshot = snapshot.duplicate(true)
	var visited: Array[String] = []
	var ids := Chart.room_ids()
	for id in snapshot.get("visited", []):
		if StringName(id) in ids and not String(id) in visited:
			visited.append(String(id))
	var current := String(snapshot.get("current_room", ""))
	if StringName(current) in ids and current not in visited:
		visited.append(current)
	_chart.visited = visited
	_chart.current_room = current
	_chart.clock = 0.0
	_chart.queue_redraw()
	_current.text = Chart.room_label(StringName(current))
	_count.text = "%02d / %02d PLACES VISITED" % [visited.size(), ids.size()]
	is_open = true
	_opening_gate = true
	_close_pending = false
	overlay.show()
	_motion.reveal(_header, 0.0, 0.18)
	_motion.reveal(_chart, 0.0, 0.22)
	_motion.reveal(_footer, 0.0, 0.18, 0.025)
	_close.grab_focus()

func close_map() -> void:
	is_open = false
	_opening_gate = false
	_close_pending = false
	if overlay == null:
		return
	overlay.hide()
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and overlay.is_ancestor_of(focused):
		focused.release_focus()
	_motion.settle()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _motion != null:
		_motion.reduced_motion = enabled
	if _chart != null:
		_chart.reduced_motion = enabled
		_chart.queue_redraw()

func current_room() -> String:
	return _chart.current_room if _chart != null else ""

func close_button() -> Button:
	return _close

func _request_close() -> void:
	if is_open and not _close_pending:
		_close_pending = true
		close_requested.emit()

func _held(action: StringName) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)

func _build() -> void:
	overlay = Control.new()
	overlay.name = "MapOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.resized.connect(_resize_layout)
	_background = Press.map_backing(PAPER)
	overlay.add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scenery := WorldBackdrop.new()
	scenery.kind = &"chart"
	overlay.add_child(scenery)
	scenery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin = MarginContainer.new()
	_margin.add_theme_constant_override("margin_top", 24)
	_margin.add_theme_constant_override("margin_bottom", 20)
	overlay.add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet := VBoxContainer.new()
	sheet.add_theme_constant_override("separation", 14)
	_margin.add_child(sheet)
	_header = HBoxContainer.new()
	_header.add_theme_constant_override("separation", 30)
	sheet.add_child(_header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.add_child(titles)
	titles.add_child(_label("DW  /  A FOLDED GUIDE", Press.SIZE_TINY, FADED))
	titles.add_child(_label("THE WAY THROUGH", Press.SIZE_BANNER, INK, true))
	var location := VBoxContainer.new()
	location.alignment = BoxContainer.ALIGNMENT_CENTER
	_header.add_child(location)
	location.add_child(_label("YOU ARE HERE", Press.SIZE_TINY, FADED))
	_current = _label("", Press.SIZE_HEADING, INK)
	location.add_child(_current)
	_count = _label("", Press.SIZE_TINY, FADED)
	location.add_child(_count)
	_chart = ChartArt.new()
	_chart.name = "CampaignChart"
	_chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chart.reduced_motion = _reduced_motion
	sheet.add_child(_chart)
	_footer = HBoxContainer.new()
	_footer.add_theme_constant_override("separation", 24)
	sheet.add_child(_footer)
	var legend := VBoxContainer.new()
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer.add_child(legend)
	legend.add_child(_label("INK  visited     FAINT  unvisited     DASH  shortcut", Press.SIZE_SMALL, FADED))
	legend.add_child(_label("Routes may need opening.  M / D-pad Down or ESC / B to close.", Press.SIZE_SMALL, INK))
	_close = Button.new()
	_close.name = "CloseMap"
	_close.text = "Fold away"
	_close.custom_minimum_size = Vector2(160, 46)
	_close.focus_mode = Control.FOCUS_ALL
	_close.add_theme_font_override("font", Press.BodyFont)
	_close.add_theme_font_size_override("font_size", Press.SIZE_BODY)
	_close.add_theme_color_override("font_color", INK)
	_close.add_theme_color_override("font_focus_color", INK)
	for key in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		_close.add_theme_color_override(key, PAPER)
	_close.add_theme_stylebox_override("normal", Press.menu_button_style(INK, PAPER))
	_close.add_theme_stylebox_override("hover", Press.menu_button_style(INK, PAPER, true))
	_close.add_theme_stylebox_override("pressed", Press.menu_button_style(INK, PAPER, true, true))
	_close.add_theme_stylebox_override("focus", Press.menu_focus_style(INK, PAPER))
	_footer.add_child(_close)
	_motion.bind_button(_close, Press.PINK)
	_close.pressed.connect(_request_close)
	var tooth := Press.paper_overlay(INK)
	overlay.add_child(tooth)
	_resize_layout()

func _resize_layout() -> void:
	if _margin == null:
		return
	_motion.settle()
	var side := 26 if overlay.size.x < 1000 else 42
	_margin.add_theme_constant_override("margin_left", side)
	_margin.add_theme_constant_override("margin_right", side)

func _label(text: String, size: int, color: Color, display := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display:
		Press.set_display(label, size, color)
	else:
		Press.set_body(label, size, color)
	return label
