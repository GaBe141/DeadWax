extends Node
## Calibrated adapters emit standard virtual joypad events. Main owns the
## scoped InputMap and hotplug lifecycle; this node owns only held input.

const Profile := preload("res://scripts/controller_profile.gd")
const VIRTUAL_BASE := 1000
const PRESS_THRESHOLD := 0.60
const RELEASE_THRESHOLD := 0.40
const BUTTONS := {
	&"a": JOY_BUTTON_A, &"b": JOY_BUTTON_B, &"x": JOY_BUTTON_X, &"y": JOY_BUTTON_Y,
	&"l": JOY_BUTTON_LEFT_SHOULDER, &"r": JOY_BUTTON_RIGHT_SHOULDER,
	&"z": JOY_BUTTON_START, &"start": JOY_BUTTON_BACK,
	&"dpad_left": JOY_BUTTON_DPAD_LEFT, &"dpad_right": JOY_BUTTON_DPAD_RIGHT,
	&"dpad_up": JOY_BUTTON_DPAD_UP, &"dpad_down": JOY_BUTTON_DPAD_DOWN,
}

var profiles: Dictionary = {}
var suspended := false
var _devices: Dictionary = {}
var _physical: Dictionary = {}
var _buttons: Dictionary = {}
var _axes: Dictionary = {}
var _blocked: Dictionary = {}

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func configure(next_profiles: Dictionary, devices: Array = []) -> void:
	var accepted: Dictionary = {}
	for key in next_profiles:
		if key is String and not key.is_empty() and Profile.valid(next_profiles[key]):
			accepted[key] = next_profiles[key].duplicate(true)
	profiles = accepted
	refresh(devices)

func refresh(devices: Array = []) -> void:
	_release_all()
	_devices.clear()
	_blocked.clear()
	var connected := devices.duplicate(true)
	if connected.is_empty():
		for device in Input.get_connected_joypads():
			connected.append({"id": device, "key": Profile.device_key(device)})
	for entry in connected:
		if not entry is Dictionary or not entry.get("id") is int or entry.id < 0 or entry.id >= VIRTUAL_BASE \
			or not entry.get("key") is String or _devices.has(entry.id):
			continue
		var device := int(entry.id)
		var key := String(entry.key)
		if profiles.has(key) and Profile.valid(profiles[key]):
			_devices[device] = profiles[key].duplicate(true)
			_block_until_neutral(device)

func has_profile(device: int) -> bool:
	return _devices.has(device)

func profile_device(device: int) -> int:
	return VIRTUAL_BASE + device

func configured_devices() -> Array[int]:
	var result: Array[int] = []
	for device in _devices:
		result.append(int(device))
	result.sort()
	return result

func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion) \
		or event.device >= VIRTUAL_BASE or not has_profile(event.device):
		return
	if not suspended:
		_translate(event)
	get_viewport().set_input_as_handled()

func _translate(event: InputEvent) -> void:
	var device := event.device
	var state: Dictionary = _physical.get(device, {})
	var blocked: Dictionary = _blocked.get(device, {})
	var bindings: Dictionary = _devices[device].bindings
	for physical in Profile.PHYSICAL:
		var binding: Dictionary = bindings[physical]
		var value := -1.0
		if event is InputEventJoypadButton and binding.kind == "button" and int(binding.index) == event.button_index:
			value = 1.0 if event.pressed else 0.0
		elif event is InputEventJoypadMotion and binding.kind == "axis" and int(binding.index) == event.axis:
			value = Profile.strength(binding, event.axis_value)
		if value < 0.0:
			continue
		if blocked.has(physical):
			if value <= RELEASE_THRESHOLD:
				blocked.erase(physical)
			state[physical] = 0.0
		else:
			state[physical] = value
	_physical[device] = state
	_blocked[device] = blocked
	for physical in BUTTONS:
		var index := int(BUTTONS[physical])
		var value := float(state.get(physical, 0.0))
		var held := bool(_buttons.get(device, {}).get(index, false))
		var next := value > RELEASE_THRESHOLD if held else value >= PRESS_THRESHOLD
		_emit_button(device, index, next)
	_emit_axis(device, JOY_AXIS_LEFT_X, float(state.get(&"stick_right", 0.0)) - float(state.get(&"stick_left", 0.0)))
	_emit_axis(device, JOY_AXIS_LEFT_Y, float(state.get(&"stick_down", 0.0)) - float(state.get(&"stick_up", 0.0)))
	_emit_axis(device, JOY_AXIS_RIGHT_Y, float(state.get(&"c_down", 0.0)) - float(state.get(&"c_up", 0.0)))

func _emit_button(device: int, index: int, pressed: bool) -> void:
	var state: Dictionary = _buttons.get(device, {})
	if bool(state.get(index, false)) == pressed:
		return
	state[index] = pressed
	_buttons[device] = state
	var event := InputEventJoypadButton.new()
	event.device = profile_device(device)
	event.button_index = index
	event.pressed = pressed
	event.pressure = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func _emit_axis(device: int, index: int, value: float) -> void:
	value = clampf(value, -1.0, 1.0)
	var state: Dictionary = _axes.get(device, {})
	if is_equal_approx(float(state.get(index, 0.0)), value):
		return
	state[index] = value
	_axes[device] = state
	var event := InputEventJoypadMotion.new()
	event.device = profile_device(device)
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)

func _block_until_neutral(device: int) -> void:
	var blocked: Dictionary = {}
	for physical in Profile.PHYSICAL:
		var binding: Dictionary = _devices[device].bindings[physical]
		var value := 0.0
		if binding.kind == "button":
			value = 1.0 if Input.is_joy_button_pressed(device, int(binding.index)) else 0.0
		else:
			value = Profile.strength(binding, Input.get_joy_axis(device, int(binding.index)))
		if value > RELEASE_THRESHOLD:
			blocked[physical] = true
	_blocked[device] = blocked

func _release_all() -> void:
	for device in _buttons.keys():
		for index in _buttons[device].keys():
			_emit_button(device, index, false)
	for device in _axes.keys():
		for index in _axes[device].keys():
			_emit_axis(device, index, 0.0)
	_physical.clear()
	_buttons.clear()
	_axes.clear()
