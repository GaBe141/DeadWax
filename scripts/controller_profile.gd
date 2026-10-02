extends RefCounted
## A calibrated physical layout. This model neither changes InputMap nor reads
## live input; the device identity is the sole platform-facing operation.

const PHYSICAL: Array[StringName] = [
	&"stick_left", &"stick_right", &"stick_up", &"stick_down",
	&"a", &"b", &"x", &"y", &"l", &"r", &"z", &"start",
	&"dpad_left", &"dpad_right", &"dpad_up", &"dpad_down", &"c_up", &"c_down",
]
const VIRTUAL_BASE := 1000
const CAPTURE_DELTA := 0.55

static func valid(snapshot: Variant) -> bool:
	if not snapshot is Dictionary or not _keys(snapshot, ["version", "layout", "bindings"]):
		return false
	if not _whole(snapshot.version, 1, 1) or not snapshot.layout is String or snapshot.layout != "gamecube":
		return false
	if not snapshot.bindings is Dictionary or snapshot.bindings.size() != PHYSICAL.size():
		return false
	var seen: Array[StringName] = []
	for physical in snapshot.bindings:
		if not (physical is String or physical is StringName):
			return false
		var id := StringName(physical)
		if id not in PHYSICAL or id in seen or not _binding_valid(snapshot.bindings[physical]):
			return false
		seen.append(id)
	return seen.size() == PHYSICAL.size()

static func strength(binding: Dictionary, value: float) -> float:
	if not _binding_valid(binding) or not is_finite(value):
		return 0.0
	if binding.kind == "button":
		return clampf(value, 0.0, 1.0)
	var neutral := float(binding.rest)
	var direction := float(binding.sign)
	var reach := 1.0 - neutral if direction > 0.0 else 1.0 + neutral
	if reach <= 0.000001:
		return 0.0
	return clampf((value - neutral) * direction / reach, 0.0, 1.0)

static func capture(event: InputEvent, rests: Dictionary) -> Dictionary:
	if event == null or event.device < 0 or event.device >= VIRTUAL_BASE:
		return {}
	if event is InputEventJoypadButton:
		if event.pressed and event.button_index >= 0 and event.button_index <= 127:
			return {"kind": "button", "index": int(event.button_index)}
		return {}
	if not event is InputEventJoypadMotion or event.axis < 0 or event.axis > 9:
		return {}
	var neutral: Variant = rests.get(int(event.axis))
	if not _number(neutral) or float(neutral) < -1.0 or float(neutral) > 1.0 or not is_finite(event.axis_value):
		return {}
	var delta := float(event.axis_value) - float(neutral)
	if absf(delta) <= CAPTURE_DELTA + 0.000001:
		return {}
	return {"kind": "axis", "index": int(event.axis), "sign": 1.0 if delta > 0.0 else -1.0, "rest": float(neutral)}

static func device_key(device: int) -> String:
	var guid := Input.get_joy_guid(device).strip_edges().to_lower()
	var name := Input.get_joy_name(device).strip_edges().to_lower()
	var info: Dictionary = Input.get_joy_info(device)
	# XInput exposes a shared GUID. The additional descriptors distinguish its
	# named adapters where the backend supplies them, without tying a profile to
	# a transient device slot or USB port.
	var vendor := str(info.get("vendor_id", "")).strip_edges().to_lower()
	var product := str(info.get("product_id", "")).strip_edges().to_lower()
	if guid.is_empty():
		guid = "no-guid"
	if name.is_empty():
		name = "unnamed"
	return "%s|%s|%s|%s" % [guid, name, vendor, product]

static func _binding_valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("kind") is String:
		return false
	if value.kind == "button":
		return _keys(value, ["kind", "index"]) and _whole(value.index, 0, 127)
	if value.kind != "axis" or not _keys(value, ["kind", "index", "sign", "rest"]):
		return false
	return _whole(value.index, 0, 9) and _number(value.sign) and (value.sign == -1.0 or value.sign == 1.0) \
		and _number(value.rest) and float(value.rest) >= -1.0 and float(value.rest) <= 1.0

static func _keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in value:
		if not key is String or key not in expected:
			return false
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	return _number(value) and float(value) >= minimum and float(value) <= maximum and floorf(float(value)) == float(value)
