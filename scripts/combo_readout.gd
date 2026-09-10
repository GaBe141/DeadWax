extends Control
## A supplied rhythm on the page. Skip owns the chain and its remaining time;
## this readout only gives a fresh beat a small, cancellable type impression.

const Press := preload("res://scripts/press.gd")
const STAMP_TIME := 0.16
const EARLY_TIME := 0.30
const BEATS := ["TAP", "SWEEP", "ACCENT"]

var practice_mode := false:
	set(value):
		if practice_mode != value:
			_early_t = 0.0
			_stamp = 0.0
		practice_mode = value
		_apply_snapshot()
var reduced_motion := false
var _ink := Color("f1dfb8")
var _stock := Color("13313a")
var _snapshot := {"step": 0, "remaining": 0.0, "window": 0.65, "label": "", "input_state": "ready"}
var _stamp := 0.0
var _early_t := 0.0
var _panel: Panel
var _headline: Label
var _input_hint: Label
var _link_label: Label
var _beats: Array[Label] = []
var _rail: ColorRect
var _window: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(300, 104)
	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	_headline = _label()
	_input_hint = _label()
	_link_label = _label()
	_link_label.text = "LINK TIME"
	for beat in BEATS:
		var label := _label()
		label.text = beat
		_beats.append(label)
	_rail = ColorRect.new()
	_rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rail)
	_window = ColorRect.new()
	_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_window)
	resized.connect(_resized)
	set_palette(_ink, _stock)
	_apply_snapshot()
	set_process(false)

func _label() -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	add_child(label)
	return label

func set_snapshot(value: Dictionary) -> void:
	var step := clampi(int(value.get("step", 0)), 0, 3)
	var window := maxf(float(value.get("window", 0.65)), 0.001)
	var remaining := clampf(float(value.get("remaining", 0.0)), 0.0, window)
	var active := step > 0 and remaining > 0.0
	var fresh := active and (step != int(_snapshot.step) or remaining > float(_snapshot.remaining) + 0.10)
	var input_state := String(value.get("input_state", "ready"))
	if input_state not in ["ready", "recover", "buffer", "queued", "blocked"]:
		input_state = "blocked"
	_snapshot = {"step": step if active else 0, "remaining": remaining if active else 0.0,
		"window": window, "label": String(value.get("label", "")) if active else "", "input_state": input_state,
		"cooldown_remaining": maxf(float(value.get("cooldown_remaining", 0.0)), 0.0),
		"cooldown_duration": maxf(float(value.get("cooldown_duration", 0.2)), 0.001),
		"queued": bool(value.get("queued", false))}
	if fresh or not active or input_state in ["queued", "blocked"]:
		_early_t = 0.0
	if fresh and is_node_ready() and not reduced_motion:
		_stamp = STAMP_TIME
	elif not active:
		_stamp = 0.0
	_apply_snapshot()
	set_process(_stamp > 0.0 or _early_t > 0.0)

func show_early_press() -> void:
	# Rejection begins in recovery. Once input opens, the receipt changes its
	# advice to PRESS AGAIN; a newer accepted/queued input always clears it.
	if String(_snapshot.input_state) != "recover" or (not practice_mode and int(_snapshot.step) == 0):
		return
	_early_t = EARLY_TIME
	_apply_snapshot()
	set_process(true)

func set_palette(ink: Color, stock: Color) -> void:
	_ink = ink
	_stock = stock
	if _panel == null:
		return
	var frame := Press.menu_button_style(ink, stock)
	frame.border_color = Color("b58d58").lerp(ink, 0.16)
	frame.border_width_left = 3
	frame.border_width_top = 2
	frame.shadow_color = Color(0.01, 0.04, 0.05, 0.42)
	frame.shadow_size = 5
	frame.shadow_offset = Vector2(0, 3)
	_panel.add_theme_stylebox_override("panel", frame)
	Press.set_display(_headline, Press.SIZE_MENU_ACTION, ink)
	Press.set_body(_input_hint, Press.SIZE_SMALL, ink, Color.TRANSPARENT, true)
	Press.set_body(_link_label, Press.SIZE_TINY, ink.lerp(stock, 0.30))
	_rail.color = ink.lerp(stock, 0.82)
	_window.color = Press.PINK
	_apply_snapshot()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		_stamp = 0.0
	set_process(_stamp > 0.0 or _early_t > 0.0)
	_apply_snapshot()

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	_stamp = maxf(_stamp - delta, 0.0)
	_early_t = maxf(_early_t - delta, 0.0)
	_apply_snapshot()
	set_process(_stamp > 0.0 or _early_t > 0.0)

func _resized() -> void:
	_stamp = 0.0
	set_process(_early_t > 0.0)
	_apply_snapshot()

func _apply_snapshot() -> void:
	if _headline == null:
		return
	var step := int(_snapshot.step)
	visible = practice_mode or step > 0
	_headline.text = "%d  %s" % [step, _snapshot.label] if step > 0 else "J / X · THREE BEATS"
	_input_hint.visible = true
	_input_hint.text = _input_text()
	_input_hint.add_theme_color_override("font_color", Press.PINK if _early_t > 0.0 or String(_snapshot.input_state) == "queued" else _ink)
	var inner := maxf(size.x - 24.0, 1.0)
	_headline.position = Vector2(12, 4)
	_headline.size = Vector2(inner, 30)
	_input_hint.position = Vector2(12, 31)
	_input_hint.size = Vector2(inner, 19)
	for index in _beats.size():
		var label := _beats[index]
		label.position = Vector2(12 + inner * index / 3.0, 55)
		label.size = Vector2(inner / 3.0, 19)
		var color := _ink if index < step else _ink.lerp(_stock, 0.55)
		if index == step - 1: color = Press.PINK
		Press.set_body(label, Press.SIZE_SMALL, color, Color.TRANSPARENT, index == step - 1)
	_link_label.position = Vector2(12, 78)
	_link_label.size = Vector2(78, 18)
	var rail_width := maxf(inner - 84.0, 1.0)
	_rail.position = Vector2(96, 86)
	_rail.size = Vector2(rail_width, 2)
	_window.position = _rail.position
	_window.size = Vector2(rail_width * float(_snapshot.remaining) / float(_snapshot.window), 2)
	_window.visible = step > 0
	_apply_stamp()

func _input_text() -> String:
	match String(_snapshot.input_state):
		"queued":
			var next := int(_snapshot.step) % BEATS.size()
			return "QUEUED · %d %s" % [next + 1, BEATS[next]]
		"ready", "buffer": return "EARLY · PRESS AGAIN" if _early_t > 0.0 else "J / X · PRESS"
		"blocked": return "WAIT"
		"recover": return "EARLY · WAIT" if _early_t > 0.0 else "RECOVERING"
	return "WAIT"

func _apply_stamp() -> void:
	if _headline == null:
		return
	var impulse := 0.0 if reduced_motion else pow(_stamp / STAMP_TIME, 2.0)
	_headline.position.y = 4.0 - impulse * 2.0
	_headline.modulate.a = 1.0 - impulse * 0.18
