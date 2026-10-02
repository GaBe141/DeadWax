extends SceneTree
## Calibration keeps raw hardware disposable until one explicit save intent.
const Menu := preload("res://scripts/controller_menu.gd")
const Profile := preload("res://scripts/controller_profile.gd")
var _checks := 0
var _failures: Array[String] = []
var _requests: Array[Dictionary] = []
var _closed := 0
var _menu: CanvasLayer

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	root.min_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var accept := InputEventJoypadButton.new()
	accept.device = 88
	accept.button_index = 0
	InputMap.action_add_event("ui_accept", accept)
	_menu = Menu.new()
	root.add_child(_menu)
	_menu.profile_requested.connect(func(key: String, profile: Dictionary) -> void:
		_requests.append({"key": key, "profile": profile.duplicate(true)})
	)
	_menu.closed.connect(func() -> void: _closed += 1)
	await _frames(3)
	_menu.open_controller([])
	_check(_menu.is_open and _menu._phase == "disconnected", "no pad still offers a cancellable setup sheet")
	_menu.close_menu()
	_menu.close_menu()
	_check(_closed == 1 and _requests.is_empty(), "cancel emits once without a profile")
	var devices := [{"id": 88, "key": "test-adapter", "name": "USB GameCube", "configured": false}, {"id": 89, "key": "other-pad", "name": "Second pad", "configured": true}]
	_menu.open_controller(devices)
	await _frames(3)
	_check(_menu.selected_device == 88 and _menu._device_picker.visible, "multiple pads offer an explicit selected device")
	_button(0, true, 88, true)
	await _frames(2)
	_check(_menu._phase == "ready", "raw A cannot activate the focused Ready button")
	_button(0, false, 88, true)
	await _frames(2)
	_menu._begin_capture()
	_arm()
	_button(1, true, 89)
	_check(_menu._step == 0, "another controller cannot fill a physical control")
	_button(1, false, 89)
	_axis(0, -1)
	_check(_menu._step == 1 and not _menu._armed, "a full stick movement captures exactly one control")
	_axis(0, -1)
	_menu._process(0.1)
	_menu._process(0.1)
	_check(_menu._step == 1 and not _menu._armed, "holding the previous direction cannot arm or fill the next control")
	_axis(0, 0)
	_arm()
	_check(_menu._armed, "returning to neutral arms the next physical prompt")
	_menu._rests[4] = -1.0
	_menu._axes[4] = -1.0
	_menu._rests[5] = 1.0
	_menu._axes[5] = 1.0
	var captures := [
		{"kind": "axis", "index": 0, "value": 1.0, "rest": 0.0},
		{"kind": "axis", "index": 1, "value": -1.0, "rest": 0.0},
		{"kind": "axis", "index": 1, "value": 1.0, "rest": 0.0},
		{"kind": "button", "index": 0}, {"kind": "button", "index": 1},
		{"kind": "button", "index": 2}, {"kind": "button", "index": 3},
		{"kind": "axis", "index": 4, "value": 1.0, "rest": -1.0},
		{"kind": "axis", "index": 5, "value": -1.0, "rest": 1.0},
		{"kind": "button", "index": 4}, {"kind": "button", "index": 5},
		{"kind": "axis", "index": 6, "value": -1.0, "rest": 0.0},
		{"kind": "axis", "index": 6, "value": 1.0, "rest": 0.0},
		{"kind": "axis", "index": 7, "value": -1.0, "rest": 0.0},
		{"kind": "axis", "index": 7, "value": 1.0, "rest": 0.0},
		{"kind": "axis", "index": 3, "value": -1.0, "rest": 0.0},
		{"kind": "axis", "index": 3, "value": 1.0, "rest": 0.0},
	]
	for capture in captures:
		var previous := int(_menu._step)
		if capture.kind == "button":
			_button(int(capture.index), true)
			_button(int(capture.index), false)
		else:
			_axis(int(capture.index), float(capture.value))
			_axis(int(capture.index), float(capture.rest))
		_check(_menu._step == previous + 1, "requested control advances once after neutral")
		_arm()
	_check(_menu._phase == "review" and _menu._bindings.size() == 18 and _requests.is_empty(), "all 18 controls reach review without applying anything")
	_check(_menu._bindings.get("l", {}).get("rest") == -1.0 and _menu._bindings.get("r", {}).get("rest") == 1.0, "analog triggers retain their actual released rests")
	_check(_menu._bindings.get("dpad_up", {}).get("kind") == "axis", "axis D-pads remain valid calibration inputs")
	for dimensions in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await _frames(4)
		_check(_inside(_menu._save_button, dimensions) and _inside(_menu._retry_button, dimensions), "review actions remain visible at %s" % dimensions)
		_check(_inside(_menu._body, dimensions), "18 physical-to-action review rows fit at %s" % dimensions)
	_button(0, true, 88, true)
	await _frames(2)
	_check(_requests.is_empty(), "raw A cannot activate the focused Save layout button")
	_button(0, false, 88, true)
	_menu._request_save()
	_menu._request_save()
	_check(_requests.size() == 1 and _menu.is_open, "explicit save emits one intent and waits for Main")
	_check(not _requests.is_empty() and _requests[0].key == "test-adapter" and Profile.valid(_requests[0].profile), "save intent contains the selected device key and complete profile")
	_menu.set_notice("Write failed. Try again.")
	_menu._request_save()
	_check(_requests.size() == 2, "failed persistence leaves the same reviewed layout retryable")
	_menu.set_notice("")
	_menu._retry()
	_check(_menu._step == 17 and _menu._phase == "capture" and not _menu._bindings.has("c_down"), "Retry last reopens exactly the final physical prompt")
	_check(not _requests.is_empty() and _requests[0].profile.bindings.size() == 18, "editing the disposable layout cannot mutate the already emitted snapshot")
	_menu._reset()
	_check(_menu._bindings.is_empty() and _menu._phase == "ready", "Start over discards only this sheet's unfinished layout")
	_menu._on_connection_changed(88, false)
	_menu._reset()
	_check(_menu.selected_device == -1 and _menu._phase == "disconnected", "disconnect cannot be bypassed with Start over")
	_menu.close_menu()
	_check(_closed == 2 and _requests.size() == 2, "cancel never emits another save intent")
	_check(not devices[0].has("available"), "connection updates leave the caller's device snapshot untouched")
	_menu.queue_free()
	await _frames(3)
	if _failures.is_empty():
		print("DEAD WAX CONTROLLER MENU PASS (%d checks)" % _checks)
		quit(0)
	else:
		for failure in _failures:
			push_error("CONTROLLER MENU FAIL: " + failure)
		quit(1)

func _arm() -> void:
	_menu._process(0.1)
	_menu._process(0.1)

func _button(index: int, pressed: bool, device := 88, dispatch := false) -> void:
	var event := InputEventJoypadButton.new()
	event.device = device
	event.button_index = index
	event.pressed = pressed
	if dispatch:
		Input.parse_input_event(event)
	else:
		_menu._input(event)

func _axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 88
	event.axis = index
	event.axis_value = value
	_menu._input(event)

func _inside(control: Control, dimensions: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.position.x >= -1 and rect.position.y >= -1 and rect.end.x <= dimensions.x + 1 and rect.end.y <= dimensions.y + 1

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(label)
