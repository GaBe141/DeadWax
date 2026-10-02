extends CanvasLayer
## A disposable calibration sheet. Main alone saves and installs the result.

signal profile_requested(key: String, profile: Dictionary)
signal closed

const Press := preload("res://scripts/press.gd")
const Profile := preload("res://scripts/controller_profile.gd")
const INK := Color("f2e1bc")
const STOCK := Color("081b23")
const PAPER := Color("102c35")
const FADED := Color("c2ae87")
const STEPS := ["stick_left", "stick_right", "stick_up", "stick_down", "a", "b", "x", "y", "l", "r", "z", "start", "dpad_left", "dpad_right", "dpad_up", "dpad_down", "c_up", "c_down"]
const INSTRUCTIONS := ["Move the main stick left", "Move the main stick right", "Move the main stick up", "Move the main stick down", "Press A", "Press B", "Press X", "Press Y", "Squeeze L fully", "Squeeze R fully", "Press Z", "Press Start", "Press D-pad Left", "Press D-pad Right", "Press D-pad Up", "Press D-pad Down", "Move the C stick up", "Move the C stick down"]
const REVIEW := ["Move left / navigate", "Move right / navigate", "Navigate up", "Navigate down", "Jump / confirm", "Raise Hood / back", "Strike", "Interact", "Set / previous Book page", "Flip / next Book page", "Open The Book", "Pause", "Navigate left", "Navigate right", "Browse stall / navigate up", "Map / navigate down", "Scroll Book notes up", "Scroll Book notes down"]
const NAMES := ["Main stick ←", "Main stick →", "Main stick ↑", "Main stick ↓", "A", "B", "X", "Y", "L", "R", "Z", "Start", "D-pad ←", "D-pad →", "D-pad ↑", "D-pad ↓", "C stick ↑", "C stick ↓"]
const NEUTRAL_TOLERANCE := 0.18
const NEUTRAL_SECONDS := 0.16

var is_open := false
var selected_device := -1
var overlay: Control
var _devices: Array = []
var _selected_key := ""
var _rests: Dictionary = {}
var _axes: Dictionary = {}
var _buttons: Dictionary = {}
var _bindings: Dictionary = {}
var _step := 0
var _phase := "ready"
var _armed := false
var _neutral_time := 0.0
var _save_pending := false
var _reduced_motion := false
var _body: VBoxContainer
var _progress: Label
var _instruction: Label
var _status: Label
var _notice: Label
var _ready_button: Button
var _retry_button: Button
var _save_button: Button
var _device_picker: OptionButton
var _background: ColorRect

func _ready() -> void:
	layer = 130
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	overlay.hide()
	Input.joy_connection_changed.connect(_on_connection_changed)

func open_controller(devices: Array) -> void:
	_devices = devices.duplicate(true)
	is_open = true
	_save_pending = false
	overlay.show()
	_device_picker.clear()
	for device in _devices:
		_device_picker.add_item(String(device.get("name", "USB controller")) + (" · configured" if bool(device.get("configured", false)) else ""))
	_device_picker.visible = _devices.size() > 1
	if _devices.is_empty():
		selected_device = -1
		_selected_key = ""
		_phase = "disconnected"
		_show_step()
	else:
		_select_device(0)

func close_menu() -> void:
	if not is_open:
		return
	is_open = false
	_armed = false
	_save_pending = false
	overlay.hide()
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null and overlay.is_ancestor_of(focus):
		focus.release_focus()
	closed.emit()

func set_notice(message: String) -> void:
	_save_pending = false
	_notice.text = message
	_notice.visible = not message.is_empty()
	_save_button.disabled = _phase != "review"

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled # The calibration sheet is deliberately still.

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_menu()
			return
		if _phase == "ready" and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
			get_viewport().set_input_as_handled()
			_begin_capture()
			return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	# Capture before GUI handling: an unmapped A must never click Ready or Save.
	get_viewport().set_input_as_handled()
	if event.device != selected_device:
		return
	if event is InputEventJoypadButton:
		_buttons[event.button_index] = event.pressed
	else:
		_axes[event.axis] = event.axis_value
	if _phase != "capture" or not _armed:
		return
	var binding: Dictionary = Profile.capture(event, _rests)
	if binding.is_empty():
		return
	_armed = false
	_neutral_time = 0.0
	for existing in _bindings.values():
		if existing == binding:
			set_notice("That control is already assigned. Release it and try the requested control.")
			_update_capture_status()
			return
	_bindings[STEPS[_step]] = binding.duplicate(true)
	_step += 1
	set_notice("")
	if _step >= STEPS.size():
		_phase = "review"
	_show_step()

func _process(delta: float) -> void:
	if not is_open or _phase != "capture" or _armed:
		return
	if not _is_neutral():
		_neutral_time = 0.0
		return
	_neutral_time += minf(delta, 0.1)
	if _neutral_time >= NEUTRAL_SECONDS:
		_armed = true
		_update_capture_status()

func _is_neutral() -> bool:
	for pressed in _buttons.values():
		if bool(pressed):
			return false
	for index in 128:
		if Input.is_joy_button_pressed(selected_device, index):
			return false
	for index in 10:
		var value := float(_axes.get(index, Input.get_joy_axis(selected_device, index)))
		if absf(value - float(_rests.get(index, 0.0))) > NEUTRAL_TOLERANCE:
			return false
	return true

func _select_device(index: int) -> void:
	if index < 0 or index >= _devices.size():
		return
	selected_device = int(_devices[index].get("id", -1)) if bool(_devices[index].get("available", true)) else -1
	_selected_key = String(_devices[index].get("key", ""))
	_device_picker.select(index)
	_reset()

func _reset() -> void:
	_bindings.clear()
	_axes.clear()
	_buttons.clear()
	_rests.clear()
	_step = 0
	_armed = false
	_neutral_time = 0.0
	_save_pending = false
	_phase = "ready" if selected_device >= 0 else "disconnected"
	set_notice("")
	_show_step()

func _begin_capture() -> void:
	if _phase != "ready" or selected_device < 0:
		return
	_rests.clear()
	for index in 10:
		_rests[index] = Input.get_joy_axis(selected_device, index)
	_axes.clear()
	_buttons.clear()
	_phase = "capture"
	_armed = false
	_neutral_time = 0.0
	_show_step()

func _retry() -> void:
	if _save_pending or _phase not in ["capture", "review"]:
		return
	_step = maxi(0, _step - 1)
	_bindings.erase(STEPS[_step])
	_phase = "capture"
	_armed = false
	_neutral_time = 0.0
	set_notice("")
	_show_step()

func _request_save() -> void:
	if _phase != "review" or _save_pending:
		return
	var profile := {"version": 1, "layout": "gamecube", "bindings": _bindings.duplicate(true)}
	if not Profile.valid(profile):
		set_notice("This layout is incomplete. Start over and capture each requested control.")
		return
	_save_pending = true
	_save_button.disabled = true
	profile_requested.emit(_selected_key, profile)

func _on_connection_changed(device: int, connected: bool) -> void:
	if not is_open or connected:
		return
	for snapshot in _devices:
		if int(snapshot.get("id", -1)) == device:
			snapshot["available"] = false
	if device != selected_device:
		return
	selected_device = -1
	_phase = "disconnected"
	_armed = false
	_save_pending = false
	_show_step()
	set_notice("The selected controller was disconnected. Reconnect it, close this sheet, and reopen Controller setup.")

func _show_step() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_ready_button.visible = _phase == "ready"
	_save_button.visible = _phase == "review"
	_save_button.disabled = _save_pending
	_retry_button.disabled = _phase not in ["capture", "review"] or _save_pending
	if _phase == "disconnected":
		_progress.text = "NO CONTROLLER"
		_body.add_child(_text("Connect your USB controller, then reopen this sheet.", Press.SIZE_TITLE))
	elif _phase == "ready":
		_progress.text = "BEFORE YOU BEGIN"
		_body.add_child(_text("Let every control rest.", Press.SIZE_TITLE))
		_body.add_child(_text("Release both sticks, triggers, and buttons. Choose Ready with the mouse or Enter, then follow the 18 prompts. L / R and the D-pad can be buttons or axes.", Press.SIZE_BODY, FADED))
		_body.add_child(_text("Your current layout stays active until you choose Save layout. Escape cancels.", Press.SIZE_BODY, FADED))
		_ready_button.call_deferred("grab_focus")
	elif _phase == "capture":
		_progress.text = "CONTROL %02d / %02d" % [_step + 1, STEPS.size()]
		_instruction = _text(INSTRUCTIONS[_step], Press.SIZE_TITLE)
		_body.add_child(_instruction)
		_status = _text("", Press.SIZE_BODY, FADED)
		_body.add_child(_status)
		_body.add_child(_text("Use the selected controller. Mouse and keyboard keep Retry, Start over, and Cancel available.", Press.SIZE_SMALL, FADED))
		_update_capture_status()
	else:
		_progress.text = "REVIEW YOUR GAMECUBE LAYOUT"
		_body.add_child(_text("Ready for the record.", Press.SIZE_TITLE))
		var columns := HBoxContainer.new()
		columns.add_theme_constant_override("separation", 24)
		_body.add_child(columns)
		for column in 2:
			var rows := VBoxContainer.new()
			rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rows.add_theme_constant_override("separation", 7)
			columns.add_child(rows)
			for index in range(column * 9, column * 9 + 9):
				var row := HBoxContainer.new()
				rows.add_child(row)
				var physical := _text(NAMES[index], Press.SIZE_SMALL)
				physical.custom_minimum_size.x = 116
				row.add_child(physical)
				var action := _text(REVIEW[index], Press.SIZE_SMALL, FADED)
				action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(action)
		_save_button.call_deferred("grab_focus")

func _update_capture_status() -> void:
	if _phase == "capture" and is_instance_valid(_status):
		_status.text = "Ready. Make one full movement or press." if _armed else "Release every control before the next prompt."

func _build() -> void:
	overlay = Control.new()
	overlay.name = "ControllerSetupOverlay"
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background = Press.plate(Vector2(1280, 720), PAPER, STOCK)
	overlay.add_child(_background)
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.resized.connect(func() -> void:
		(_background.material as ShaderMaterial).set_shader_parameter("plate_px", overlay.size)
	)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	overlay.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sheet := VBoxContainer.new()
	sheet.add_theme_constant_override("separation", 14)
	margin.add_child(sheet)
	sheet.add_child(_text("DEAD WAX  /  CONTROLLER SETUP", Press.SIZE_SMALL, FADED))
	_device_picker = OptionButton.new()
	_device_picker.custom_minimum_size.y = 40
	_style_button(_device_picker)
	_device_picker.item_selected.connect(_select_device)
	sheet.add_child(_device_picker)
	_progress = _text("", Press.SIZE_SMALL, Press.BRASS)
	sheet.add_child(_progress)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	sheet.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 18)
	scroll.add_child(_body)
	_notice = _text("", Press.SIZE_SMALL, Press.BRASS)
	_notice.hide()
	sheet.add_child(_notice)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	sheet.add_child(actions)
	_ready_button = _button(actions, "Ready", _begin_capture)
	_save_button = _button(actions, "Save layout", _request_save)
	_retry_button = _button(actions, "Retry last", _retry)
	_button(actions, "Start over", _reset)
	_button(actions, "Cancel", close_menu)
	sheet.add_child(_text("MOUSE / KEYBOARD  ·  Enter chooses   Escape cancels", Press.SIZE_TINY, FADED))

func _text(value: String, size: int, color := INK) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Press.set_body(label, size, color)
	return label

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 44
	_style_button(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _style_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", Press.BodyFont)
	button.add_theme_font_size_override("font_size", Press.SIZE_BODY)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", PAPER)
	button.add_theme_stylebox_override("normal", Press.menu_button_style(INK, PAPER))
	button.add_theme_stylebox_override("hover", Press.menu_button_style(INK, PAPER, true))
	button.add_theme_stylebox_override("pressed", Press.menu_button_style(INK, PAPER, true, true))
	button.add_theme_stylebox_override("focus", Press.menu_focus_style(INK, PAPER))
