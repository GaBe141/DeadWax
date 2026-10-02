extends SceneTree
## Calibration data, virtual event routing and held-state cleanup use fake
## events only. No attached controller or campaign checkpoint is required.

const Profile := preload("res://scripts/controller_profile.gd")
const Router := preload("res://scripts/controller_router.gd")
const DEVICE := 77
const ACTION := &"deadwax_controller_profile_test"
var _checks := 0
var _failures: Array[String] = []

class EventWitness extends Node:
	var seen: Array[InputEvent] = []
	func _input(event: InputEvent) -> void:
		seen.append(event)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_schema()
	_check_strength()
	_check_capture()
	await _check_router()
	if _failures.is_empty():
		print("DEAD WAX CONTROLLER PROFILE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("CONTROLLER PROFILE FAIL: " + failure)
	quit(1)

func _snapshot() -> Dictionary:
	var bindings: Dictionary = {}
	for index in Profile.PHYSICAL.size():
		bindings[String(Profile.PHYSICAL[index])] = {"kind": "button", "index": index + 10}
	for entry in [["stick_left", 0, -1.0], ["stick_right", 0, 1.0], ["stick_up", 1, -1.0], ["stick_down", 1, 1.0],
		["dpad_left", 4, -1.0], ["dpad_right", 4, 1.0], ["dpad_up", 5, -1.0], ["dpad_down", 5, 1.0],
		["c_up", 8, -1.0], ["c_down", 8, 1.0]]:
		bindings[entry[0]] = {"kind": "axis", "index": entry[1], "sign": entry[2], "rest": 0.0}
	bindings.l = {"kind": "axis", "index": 6, "sign": 1.0, "rest": -1.0}
	bindings.r = {"kind": "axis", "index": 7, "sign": -1.0, "rest": 1.0}
	return {"version": 1, "layout": "gamecube", "bindings": bindings}

func _check_schema() -> void:
	var good := _snapshot()
	_check(Profile.PHYSICAL.size() == 18 and Profile.PHYSICAL[0] == &"stick_left" and Profile.PHYSICAL[17] == &"c_down", "physical calibration order is stable")
	_check(Profile.valid(good), "complete GameCube profile is valid")
	_check(Profile.valid(JSON.parse_string(JSON.stringify(good))), "whole JSON numbers round-trip without losing the profile")
	var shared := good.duplicate(true)
	shared.bindings.b = shared.bindings.a.duplicate(true)
	_check(Profile.valid(shared), "bindings may share raw indices without inventing physical IDs")
	var invalid: Array = [null, true, 1, "profile", [], {}, {"version": 1, "layout": "gamecube"}]
	for field in ["version", "layout", "bindings"]:
		var missing := good.duplicate(true)
		missing.erase(field)
		invalid.append(missing)
	var extra := good.duplicate(true)
	extra.extra = true
	invalid.append(extra)
	for value in [true, false, "1", 0, 2, 1.5, NAN, INF]:
		var bad := good.duplicate(true)
		bad.version = value
		invalid.append(bad)
	for value in [null, true, &"gamecube", "standard", "", 1]:
		var bad := good.duplicate(true)
		bad.layout = value
		invalid.append(bad)
	for value in [null, [], true, {"a": {"kind": "button", "index": 0}}]:
		var bad := good.duplicate(true)
		bad.bindings = value
		invalid.append(bad)
	var unknown := good.duplicate(true)
	unknown.bindings.erase("a")
	unknown.bindings.invented = {"kind": "button", "index": 0}
	invalid.append(unknown)
	var omitted := good.duplicate(true)
	omitted.bindings.erase("c_down")
	invalid.append(omitted)
	for value in [null, true, [], {}, {"kind": "button"}, {"kind": "button", "index": 0, "rest": 0.0},
		{"kind": "invented", "index": 0}, {"kind": "axis", "index": 0}, {"kind": &"button", "index": 0}]:
		var bad := good.duplicate(true)
		bad.bindings.a = value
		invalid.append(bad)
	for value in [true, false, "0", -1, 128, 0.5, NAN, INF]:
		var bad := good.duplicate(true)
		bad.bindings.a = {"kind": "button", "index": value}
		invalid.append(bad)
	for value in [-1, 10, 1.5, true, "1", NAN, INF]:
		var bad := good.duplicate(true)
		bad.bindings.l.index = value
		invalid.append(bad)
	for field in ["sign", "rest"]:
		for value in [null, true, "1", NAN, INF, -INF, -1.1, 1.1]:
			var bad := good.duplicate(true)
			bad.bindings.l[field] = value
			invalid.append(bad)
	var zero_sign := good.duplicate(true)
	zero_sign.bindings.l.sign = 0.0
	invalid.append(zero_sign)
	for value in invalid:
		_check(not Profile.valid(value), "invalid profile is rejected: " + str(value))

func _check_strength() -> void:
	var positive := {"kind": "axis", "index": 0, "sign": 1.0, "rest": 0.0}
	var negative := {"kind": "axis", "index": 0, "sign": -1.0, "rest": 0.0}
	_check(is_equal_approx(Profile.strength(positive, 0.72), 0.72), "positive stick preserves travel strength")
	_check(is_equal_approx(Profile.strength(negative, -0.72), 0.72), "negative stick preserves travel strength")
	_check(Profile.strength(positive, -1.0) == 0.0 and Profile.strength(negative, 1.0) == 0.0, "opposite direction never leaks into a binding")
	_check(Profile.strength(positive, 2.0) == 1.0 and Profile.strength(positive, NAN) == 0.0, "strength is clamped and rejects nonfinite input")
	var trigger := {"kind": "axis", "index": 6, "sign": 1.0, "rest": -1.0}
	_check(Profile.strength(trigger, -1.0) == 0.0 and Profile.strength(trigger, 1.0) == 1.0, "negative-rest trigger spans its full physical travel")
	_check(is_equal_approx(Profile.strength(trigger, 0.2), 0.6), "negative-rest trigger normalizes halfway through its range")
	trigger.sign = -1.0
	trigger.rest = 1.0
	_check(is_equal_approx(Profile.strength(trigger, -0.2), 0.6), "positive-rest trigger normalizes reversed travel")
	trigger.rest = -1.0
	_check(Profile.strength(trigger, -1.0) == 0.0, "zero-length axis never divides by zero")
	positive.rest = 0.1
	_check(is_equal_approx(Profile.strength(positive, 0.55), 0.5), "captured offset neutral is removed before normalizing")
	_check(Profile.strength({"kind": "button", "index": 0}, 1.0) == 1.0 and Profile.strength({}, 1.0) == 0.0, "digital strengths and malformed bindings are bounded")

func _check_capture() -> void:
	var button := _button(127, true)
	_check(Profile.capture(button, {}) == {"kind": "button", "index": 127}, "pressed raw button captures its real index")
	button.pressed = false
	_check(Profile.capture(button, {}).is_empty(), "button release cannot calibrate a control")
	button.pressed = true
	button.device = Router.VIRTUAL_BASE
	_check(Profile.capture(button, {}).is_empty(), "virtual events never enter calibration")
	var rests := {0: 0.05, 6: -1.0, 7: 1.0}
	_check(Profile.capture(_motion(0, 0.12), rests).is_empty(), "idle drift does not capture a direction")
	_check(Profile.capture(_motion(0, 0.6), rests).is_empty(), "capture threshold requires more than 0.55 travel")
	_check(Profile.capture(_motion(0, -0.7), rests) == {"kind": "axis", "index": 0, "sign": -1.0, "rest": 0.05}, "axis captures polarity and its previously measured rest")
	_check(Profile.capture(_motion(6, 1.0), rests).sign == 1.0 and Profile.capture(_motion(7, -1.0), rests).sign == -1.0, "either trigger rest convention captures correctly")
	_check(Profile.capture(_motion(8, 1.0), rests).is_empty(), "unmeasured axis never assumes a rest")
	_check(Profile.capture(_motion(0, NAN), rests).is_empty() and Profile.capture(_motion(0, 1.0), {0: INF}).is_empty(), "capture rejects nonfinite motion and rest")
	_check(Profile.capture(InputEventKey.new(), rests).is_empty() and Profile.capture(null, rests).is_empty(), "keyboard and missing events cannot calibrate a pad")

func _check_router() -> void:
	var router := Router.new()
	var witness := EventWitness.new()
	witness.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(witness)
	root.add_child(router)
	_check(router.process_mode == Node.PROCESS_MODE_ALWAYS, "router keeps receiving calibration/menu events while paused")
	var profile := _snapshot()
	var devices: Array = [{"id": DEVICE, "key": "fake", "name": "Fixture adapter", "configured": false}]
	_send(_motion(6, -1.0))
	_send(_motion(7, 1.0))
	router.configure({"fake": profile, "bad": {}, "": profile}, devices)
	_check(router.profiles.size() == 1 and router.profiles.has("fake"), "configure retains valid named profiles only")
	profile.bindings.a.index = 99
	_check(router.profiles.fake.bindings.a.index == 14, "configure owns a deep copy of bindings")
	_check(router.has_profile(DEVICE) and not router.has_profile(76), "only configured physical devices are routed")
	_check(router.profile_device(DEVICE) == 1077 and router.configured_devices() == [DEVICE], "device scopes are stable and physical listing is explicit")
	InputMap.add_action(ACTION)
	var joy := InputEventJoypadButton.new()
	joy.device = router.profile_device(DEVICE)
	joy.button_index = JOY_BUTTON_A
	InputMap.action_add_event(ACTION, joy)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F10
	InputMap.action_add_event(ACTION, key)
	witness.seen.clear()
	_send(_button(14, true))
	_check(Input.is_action_pressed(ACTION) and Input.is_joy_button_pressed(1077, JOY_BUTTON_A), "virtual button activates scoped InputMap and raw joy state")
	_check(_witness_has(witness, 1077, JOY_BUTTON_A) and not _witness_has(witness, DEVICE, 14), "translated events reach menus while raw calibrated events are consumed")
	_send(_button(14, false))
	_check(not Input.is_action_pressed(ACTION), "virtual button release clears the action")
	for mapping in [[15, JOY_BUTTON_B], [16, JOY_BUTTON_X], [17, JOY_BUTTON_Y]]:
		_send(_button(mapping[0], true))
		_check(Input.is_joy_button_pressed(1077, mapping[1]), "calibrated face button keeps its intended semantic index")
		_send(_button(mapping[0], false))
	paused = true
	witness.seen.clear()
	_send(_button(15, true))
	_check(Input.is_joy_button_pressed(1077, JOY_BUTTON_B) and _witness_has(witness, 1077, JOY_BUTTON_B), "virtual events continue reaching ALWAYS menu listeners during tree pause")
	_send(_button(15, false))
	paused = false
	_send(_motion(6, 0.22))
	_check(Input.is_joy_button_pressed(1077, JOY_BUTTON_LEFT_SHOULDER), "analog L presses above normalized 0.60")
	_send(_motion(6, 0.0))
	_check(Input.is_joy_button_pressed(1077, JOY_BUTTON_LEFT_SHOULDER), "analog L stays held in the hysteresis band")
	_send(_motion(6, -0.22))
	_check(not Input.is_joy_button_pressed(1077, JOY_BUTTON_LEFT_SHOULDER), "analog L releases below normalized 0.40")
	_send(_motion(7, -0.3))
	_check(Input.is_joy_button_pressed(1077, JOY_BUTTON_RIGHT_SHOULDER), "reversed analog R produces a standard right shoulder")
	_send(_button(20, true))
	_send(_button(21, true))
	_check(Input.is_joy_button_pressed(1077, JOY_BUTTON_START) and Input.is_joy_button_pressed(1077, JOY_BUTTON_BACK), "physical Z opens Book and physical Start requests Pause")
	_send(_motion(0, -0.8))
	_check(is_equal_approx(Input.get_joy_axis(1077, JOY_AXIS_LEFT_X), -0.8), "paired left/right bindings recombine negative travel")
	_send(_motion(0, 0.7))
	_check(is_equal_approx(Input.get_joy_axis(1077, JOY_AXIS_LEFT_X), 0.7), "crossing neutral releases the opposite stick direction")
	_send(_motion(1, 0.8))
	_send(_motion(8, -0.9))
	_check(is_equal_approx(Input.get_joy_axis(1077, JOY_AXIS_LEFT_Y), 0.8) and is_equal_approx(Input.get_joy_axis(1077, JOY_AXIS_RIGHT_Y), -0.9), "stick and C vertical axes remain separate")
	_send(_motion(4, -1.0))
	_send(_motion(5, 1.0))
	_check(Input.is_joy_button_pressed(1077, JOY_BUTTON_DPAD_LEFT) and Input.is_joy_button_pressed(1077, JOY_BUTTON_DPAD_DOWN), "axis-based D-pad becomes standard digital directions")
	key = InputEventKey.new()
	key.physical_keycode = KEY_F10
	key.pressed = true
	_send(key)
	_send(_button(14, true))
	_send(_button(14, false))
	_check(Input.is_action_pressed(ACTION), "releasing pad keeps a concurrently held keyboard action")
	key = InputEventKey.new()
	key.physical_keycode = KEY_F10
	key.pressed = false
	_send(key)
	_check(not Input.is_action_pressed(ACTION), "keyboard release remains unaffected")
	router.suspended = true
	router.refresh(devices)
	Input.flush_buffered_events()
	_check(not Input.is_joy_button_pressed(1077, JOY_BUTTON_RIGHT_SHOULDER) and not Input.is_joy_button_pressed(1077, JOY_BUTTON_START), "refresh releases held virtual buttons")
	_check(Input.get_joy_axis(1077, JOY_AXIS_LEFT_X) == 0.0 and Input.get_joy_axis(1077, JOY_AXIS_RIGHT_Y) == 0.0, "refresh recenters every emitted virtual axis")
	_check(router._physical.is_empty() and router._buttons.is_empty() and router._axes.is_empty(), "refresh discards held physical and virtual caches")
	witness.seen.clear()
	_send(_button(14, true))
	_check(not Input.is_action_pressed(ACTION) and not _witness_has(witness, DEVICE, 14), "suspended calibration consumes raw input without translating it")
	router.suspended = false
	router.refresh(devices)
	_send(_button(14, true))
	_send(_motion(0, 0.7))
	_send(_motion(7, -0.3))
	_check(not Input.is_action_pressed(ACTION) and Input.get_joy_axis(1077, JOY_AXIS_LEFT_X) == 0.0 \
		and not Input.is_joy_button_pressed(1077, JOY_BUTTON_RIGHT_SHOULDER), "held controls cannot reactivate after calibration or reconnection")
	_send(_button(14, false))
	_send(_motion(0, 0.0))
	_send(_motion(7, 1.0))
	_send(_button(14, true))
	_send(_motion(0, -0.8))
	_send(_motion(7, -0.3))
	_check(Input.is_action_pressed(ACTION) and is_equal_approx(Input.get_joy_axis(1077, JOY_AXIS_LEFT_X), -0.8) \
		and Input.is_joy_button_pressed(1077, JOY_BUTTON_RIGHT_SHOULDER), "neutral or release rearms controls for the next deliberate input")
	_send(_button(14, false))
	witness.seen.clear()
	var unprofiled := _button(14, true)
	unprofiled.device = 76
	_send(unprofiled)
	_check(_witness_has(witness, 76, 14), "unprofiled devices remain available to ordinary controls")
	var virtual := InputEventJoypadButton.new()
	virtual.device = Router.VIRTUAL_BASE
	virtual.button_index = JOY_BUTTON_A
	virtual.pressed = true
	var virtual_binding := virtual.duplicate() as InputEventJoypadButton
	virtual_binding.pressed = false
	InputMap.action_add_event(ACTION, virtual_binding)
	_send(virtual)
	_check(Input.is_action_pressed(ACTION) and Input.is_joy_button_pressed(1000, JOY_BUTTON_A) \
		and _witness_has(witness, 1000, JOY_BUTTON_A), "native Input accepts virtual device 1000 and router never reroutes its events")
	virtual = InputEventJoypadButton.new()
	virtual.device = Router.VIRTUAL_BASE
	virtual.button_index = JOY_BUTTON_A
	virtual.pressed = false
	_send(virtual)
	router.configure({}, devices)
	Input.flush_buffered_events()
	_check(router.configured_devices().is_empty() and not Input.is_joy_button_pressed(1077, JOY_BUTTON_RIGHT_SHOULDER) \
		and Input.get_joy_axis(1077, JOY_AXIS_LEFT_X) == 0.0, "removing a profile releases virtual input before forgetting its device")
	InputMap.erase_action(ACTION)
	router.queue_free()
	witness.queue_free()
	await process_frame

func _button(index: int, pressed: bool) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = DEVICE
	event.button_index = index
	event.pressed = pressed
	return event

func _motion(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = DEVICE
	event.axis = axis
	event.axis_value = value
	return event

func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	Input.flush_buffered_events()

func _witness_has(witness: EventWitness, device: int, button: int) -> bool:
	for event in witness.seen:
		if event is InputEventJoypadButton and event.device == device and event.button_index == button:
			return true
	return false

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
