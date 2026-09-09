extends CanvasLayer
## The sleeve around the record. Main owns play, pause, saves and settings;
## this layer only presents those choices and emits the player's intent.

signal new_game_requested
signal continue_requested
signal resume_requested
signal title_requested
signal quit_requested
signal settings_changed(settings: Dictionary)

const PressScript := preload("res://scripts/press.gd")

const PAPER := Color(0.90, 0.87, 0.79)
const STOCK := Color(0.82, 0.78, 0.70)
const INK := Color(0.085, 0.075, 0.095)
const FADED := Color(0.39, 0.36, 0.37)
const PINK := PressScript.PINK
const NARROW_AT := 900.0

var is_open := false
var screen := ""
var settings: Dictionary = {
	"volume": 0.8,
	"reduced_motion": false,
	"fullscreen": false,
}

var overlay: Control
var _margin: MarginContainer
var _content: HBoxContainer
var _page: VBoxContainer
var _art: Control
var _first_focus: Control
var _footer: Label
var _notice: Label
var _background: ColorRect
var _can_continue := false
var _save_label := ""
var _return_screen := "title"


class RecordArt extends Control:
	## A sleeve illustration, with no animation or gameplay state.
	var ink := Color.BLACK
	var paper := Color.WHITE
	var accent := Color.MAGENTA

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		PressScript.draw_record(self, size, ink, paper, accent)


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frame()
	close_menu()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		match screen:
			"settings", "controls":
				_show_screen(_return_screen)
			"confirm_new":
				_show_screen("title")
			"pause", "ending":
				resume_requested.emit()


func show_title(can_continue: bool, save_label: String = "") -> void:
	_can_continue = can_continue
	_save_label = save_label
	_show_screen("title")


func show_pause() -> void:
	_show_screen("pause")


func show_ending() -> void:
	_show_screen("ending")


func close_menu() -> void:
	is_open = false
	screen = ""
	if overlay == null:
		return
	overlay.hide()
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != null and overlay.is_ancestor_of(focus_owner):
		focus_owner.release_focus()


func set_notice(message: String) -> void:
	if _notice != null:
		_notice.text = message
		_notice.visible = not message.is_empty()


func _build_frame() -> void:
	overlay = Control.new()
	overlay.name = "GameMenuOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.resized.connect(_resize_layout)

	_background = PressScript.plate(Vector2(1280.0, 720.0), PAPER, STOCK)
	overlay.add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_margin = MarginContainer.new()
	_margin.add_theme_constant_override("margin_top", 30)
	_margin.add_theme_constant_override("margin_bottom", 25)
	overlay.add_child(_margin)
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var sheet := VBoxContainer.new()
	sheet.add_theme_constant_override("separation", 20)
	_margin.add_child(sheet)

	var header := HBoxContainer.new()
	sheet.add_child(header)
	var imprint := _label("DW   /   AN INDEPENDENT PRESSING", PressScript.SIZE_TINY, INK)
	imprint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(imprint)
	header.add_child(_label("SIDE ONE  ·  01", PressScript.SIZE_TINY, FADED))
	sheet.add_child(_rule(INK))

	_content = HBoxContainer.new()
	_content.add_theme_constant_override("separation", 46)
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet.add_child(_content)

	sheet.add_child(_rule(INK))
	_footer = _label("", PressScript.SIZE_TINY, FADED)
	sheet.add_child(_footer)
	_notice = _label("", PressScript.SIZE_SMALL, INK)
	_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notice.hide()
	sheet.add_child(_notice)

	var texture := PressScript.paper_overlay(INK)
	overlay.add_child(texture)
	_resize_layout()


func _show_screen(next_screen: String) -> void:
	if overlay == null:
		return
	is_open = true
	screen = next_screen
	overlay.show()
	_first_focus = null
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 1.0
	scroll.follow_focus = true
	_content.add_child(scroll)
	_page = VBoxContainer.new()
	_page.name = "MenuPage"
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_page.alignment = BoxContainer.ALIGNMENT_CENTER
	_page.add_theme_constant_override("separation", 10)
	scroll.add_child(_page)

	match screen:
		"title":
			_build_title()
		"pause":
			_build_pause()
		"settings":
			_build_settings()
		"controls":
			_build_controls()
		"confirm_new":
			_build_confirmation()
		"ending":
			_build_ending()

	_build_art()
	_footer.text = "ARROWS / STICK  select     ENTER / A  choose"
	if screen != "title":
		_footer.text += "     ESC / B  back"
	_resize_layout()
	call_deferred("_focus_default")


func _build_title() -> void:
	_page.add_child(_label("01 / THE LABEL", PressScript.SIZE_SMALL, FADED))
	_page.add_child(_label("DEAD WAX", PressScript.SIZE_COVER, INK, true))
	_page.add_child(_paragraph("Some things only answer\nwhen you listen."))
	_space(16.0)
	if _can_continue:
		_button("Continue", continue_requested.emit, true)
		if not _save_label.is_empty():
			_page.add_child(_label(_save_label, PressScript.SIZE_TINY, FADED))
	_button("New game", _request_new_game, not _can_continue)
	_button("Settings", _open_subpage.bind("settings"))
	_button("How to play", _open_subpage.bind("controls"))
	_button("Quit", quit_requested.emit)


func _build_pause() -> void:
	_page.add_child(_label("THE NEEDLE IS LIFTED", PressScript.SIZE_SMALL, FADED))
	_page.add_child(_label("TAKE A BREATH.", PressScript.SIZE_MENU_TITLE, INK, true))
	_page.add_child(_paragraph("The record will wait."))
	_space(22.0)
	_button("Resume", resume_requested.emit, true)
	_button("Settings", _open_subpage.bind("settings"))
	_button("How to play", _open_subpage.bind("controls"))
	_button("Save & return to title", title_requested.emit)
	_button("Save & quit", quit_requested.emit)


func _build_ending() -> void:
	_page.add_child(_label("END OF SIDE ONE", PressScript.SIZE_SMALL, FADED))
	_page.add_child(_label("A LITTLE\nLESS ALONE.", PressScript.SIZE_MENU_TITLE, INK, true))
	_page.add_child(_paragraph("You found an answer in the noise.\nThere is more wax beneath your feet."))
	_space(12.0)
	_page.add_child(_label("The descent is still being pressed.", PressScript.SIZE_SMALL, FADED))
	_space(18.0)
	_button("Continue exploring", resume_requested.emit, true)
	_button("Save & return to title", title_requested.emit)


func _build_confirmation() -> void:
	_page.add_child(_label("A FRESH PRESSING", PressScript.SIZE_SMALL, FADED))
	_page.add_child(_label("BEGIN AGAIN?", PressScript.SIZE_MENU_TITLE, INK, true))
	_page.add_child(_paragraph("Starting a new game replaces your saved journey.\nYour settings will stay as they are."))
	_space(24.0)
	_button("Keep my journey", _show_screen.bind("title"), true)
	_button("Replace save & begin", new_game_requested.emit)


func _build_settings() -> void:
	_page.add_child(_label("MAKE YOURSELF AT HOME", PressScript.SIZE_SMALL, FADED))
	_page.add_child(_label("SETTINGS", PressScript.SIZE_MENU_TITLE, INK, true))
	_space(20.0)
	var volume_row := HBoxContainer.new()
	_page.add_child(volume_row)
	var volume_name := _label("Master volume", PressScript.SIZE_BODY, INK)
	volume_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume_row.add_child(volume_name)
	var volume_value := _label("%d%%" % roundi(float(settings.get("volume", 0.8)) * 100.0), PressScript.SIZE_BODY, FADED)
	volume_row.add_child(volume_value)
	var volume := HSlider.new()
	volume.name = "MasterVolume"
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = clampf(float(settings.get("volume", 0.8)), 0.0, 1.0)
	volume.custom_minimum_size.y = 40.0
	volume.focus_mode = Control.FOCUS_ALL
	volume.value_changed.connect(func(value: float) -> void:
		volume_value.text = "%d%%" % roundi(value * 100.0)
		_update_setting("volume", value)
	)
	var volume_frame := PanelContainer.new()
	volume_frame.add_theme_stylebox_override("panel", PressScript.menu_slider_style())
	_page.add_child(volume_frame)
	volume_frame.add_child(volume)
	volume.focus_entered.connect(func() -> void:
		volume_frame.add_theme_stylebox_override("panel", PressScript.menu_slider_style(true))
	)
	volume.focus_exited.connect(func() -> void:
		volume_frame.add_theme_stylebox_override("panel", PressScript.menu_slider_style())
	)
	_first_focus = volume
	_space(10.0)
	_checkbox("Fullscreen", "fullscreen")
	_checkbox("Reduced motion", "reduced_motion")
	_page.add_child(_label("Steadies camera movement and shake.", PressScript.SIZE_TINY, FADED))
	_space(22.0)
	_button("Back", _show_screen.bind(_return_screen))


func _build_controls() -> void:
	_page.add_child(_label("YOUR HANDS ALREADY KNOW", PressScript.SIZE_SMALL, FADED))
	_page.add_child(_label("HOW TO PLAY", PressScript.SIZE_MENU_TITLE, INK, true))
	var controls := GridContainer.new()
	controls.columns = 3
	controls.add_theme_constant_override("h_separation", 20)
	controls.add_theme_constant_override("v_separation", 9)
	_page.add_child(controls)
	for heading in ["ACTION", "KEYBOARD", "CONTROLLER"]:
		controls.add_child(_label(heading, PressScript.SIZE_TINY, FADED))
	for row in [
		["Move", "A / D or ← / →", "Left stick"],
		["Jump", "Space", "A"],
		["Strike", "J / X", "X"],
		["Raise Hood", "Hold K / C", "Hold B"],
		["Kneel / Set", "Hold L", "Hold LB"],
		["Enter passage", "E", "Y"],
		["The Book", "I", "Start"],
		["Pause", "Esc", "Back"],
		["Last entrance", "R", "—"],
	]:
		for cell in row:
			controls.add_child(_label(String(cell), PressScript.SIZE_SMALL, INK))
	_page.add_child(_paragraph("A timely strike can answer an incoming blow.\nThree hits lift the needle back to your last entrance.\nYour discoveries stay with you."))
	_button("Back", _show_screen.bind(_return_screen), true)


func _build_art() -> void:
	_art = Control.new()
	_art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_art.size_flags_stretch_ratio = 1.05
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_art)
	var record := RecordArt.new()
	record.ink = INK
	record.paper = PAPER
	record.accent = PINK
	_art.add_child(record)
	record.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var label_center := CenterContainer.new()
	label_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(label_center)
	label_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label_center.offset_top = -24.0
	var label_stack := VBoxContainer.new()
	label_stack.add_theme_constant_override("separation", 0)
	label_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_center.add_child(label_stack)
	var imprint := _label("DEAD WAX", PressScript.SIZE_TITLE, INK, true)
	imprint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_stack.add_child(imprint)
	var edition := _label("SIDE ONE", PressScript.SIZE_TINY, INK)
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_stack.add_child(edition)
	var hole_space := Control.new()
	hole_space.custom_minimum_size.y = 25.0
	label_stack.add_child(hole_space)
	var speed := _label("33⅓   /   DW—001", PressScript.SIZE_TINY, INK)
	speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_stack.add_child(speed)


func _resize_layout() -> void:
	if overlay == null or _margin == null:
		return
	var narrow := overlay.size.x < NARROW_AT
	var margin_size := 28 if narrow else 54
	_margin.add_theme_constant_override("margin_left", margin_size)
	_margin.add_theme_constant_override("margin_right", margin_size)
	if _art != null and is_instance_valid(_art):
		_art.visible = not narrow
	if _background != null:
		var material := _background.material as ShaderMaterial
		material.set_shader_parameter("plate_px", overlay.size)


func _request_new_game() -> void:
	if _can_continue:
		_show_screen("confirm_new")
	else:
		new_game_requested.emit()


func _open_subpage(next_screen: String) -> void:
	_return_screen = screen
	_show_screen(next_screen)


func _update_setting(key: String, value: Variant) -> void:
	settings[key] = value
	settings_changed.emit(settings.duplicate(true))


func _checkbox(text: String, key: String) -> void:
	var checkbox := CheckButton.new()
	checkbox.name = key.to_pascal_case()
	checkbox.text = text
	checkbox.button_pressed = bool(settings.get(key, false))
	checkbox.custom_minimum_size.y = 48.0
	_style_button(checkbox)
	checkbox.toggled.connect(func(value: bool) -> void: _update_setting(key, value))
	_page.add_child(checkbox)


func _button(text: String, action: Callable, default_focus := false) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size.y = 44.0
	_style_button(button)
	button.pressed.connect(action)
	_page.add_child(button)
	if default_focus or _first_focus == null:
		_first_focus = button
	return button


func _style_button(button: Button) -> void:
	button.add_theme_font_override("font", PressScript.BodyFont)
	button.add_theme_font_size_override("font_size", PressScript.SIZE_BODY)
	for color_key in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(color_key, INK)
	button.add_theme_stylebox_override("normal", PressScript.menu_button_style(INK, PAPER))
	button.add_theme_stylebox_override("hover", PressScript.menu_button_style(INK, PAPER, true))
	button.add_theme_stylebox_override("pressed", PressScript.menu_button_style(INK, PAPER, true, true))
	button.add_theme_stylebox_override("focus", PressScript.menu_button_style(INK, PAPER, false, true))


func _label(text: String, font_size: int, color: Color, display := false) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display:
		PressScript.set_display(label, font_size, color)
	else:
		PressScript.set_body(label, font_size, color)
	return label


func _paragraph(text: String) -> Label:
	var label := _label(text, PressScript.SIZE_BODY, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _rule(color: Color) -> ColorRect:
	var line := PressScript.plate(Vector2(1280.0, 1.0), color, PAPER)
	line.custom_minimum_size.y = 1.0
	return line


func _space(height: float) -> void:
	var space := Control.new()
	space.custom_minimum_size.y = height
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.add_child(space)


func _focus_default() -> void:
	if is_open and is_instance_valid(_first_focus):
		_first_focus.grab_focus()
