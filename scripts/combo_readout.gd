extends Control
## A supplied rhythm on the page. Skip owns the chain and its remaining time;
## this readout only gives a fresh beat a small, cancellable type impression.

const Press := preload("res://scripts/press.gd")
const STAMP_TIME := 0.16
const BEATS := ["TAP", "SWEEP", "ACCENT"]

var practice_mode := false:
	set(value):
		practice_mode = value
		_apply_snapshot()
var reduced_motion := false
var _ink := Color("26221e")
var _stock := Color("e8e0cc")
var _snapshot := {"step": 0, "remaining": 0.0, "window": 0.65, "label": ""}
var _stamp := 0.0
var _panel: Panel
var _headline: Label
var _input_hint: Label
var _beats: Array[Label] = []
var _rail: ColorRect
var _window: ColorRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(300, 80)
	_panel = Panel.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)
	_headline = _label()
	_input_hint = _label()
	_input_hint.text = "J / X"
	_input_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
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
	_snapshot = {"step": step if active else 0, "remaining": remaining if active else 0.0,
		"window": window, "label": String(value.get("label", "")) if active else ""}
	if fresh and is_node_ready() and not reduced_motion:
		_stamp = STAMP_TIME
	elif not active:
		_stamp = 0.0
	_apply_snapshot()
	set_process(_stamp > 0.0)

func set_palette(ink: Color, stock: Color) -> void:
	_ink = ink
	_stock = stock
	if _panel == null:
		return
	_panel.add_theme_stylebox_override("panel", Press.menu_button_style(ink, stock))
	Press.set_display(_headline, Press.SIZE_MENU_ACTION, ink)
	Press.set_body(_input_hint, Press.SIZE_TINY, ink.lerp(stock, 0.35))
	_rail.color = ink.lerp(stock, 0.82)
	_window.color = Press.PINK
	_apply_snapshot()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		_stamp = 0.0
		set_process(false)
	_apply_snapshot()

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	_stamp = maxf(_stamp - delta, 0.0)
	_apply_stamp()
	set_process(_stamp > 0.0)

func _resized() -> void:
	_stamp = 0.0
	set_process(false)
	_apply_snapshot()

func _apply_snapshot() -> void:
	if _headline == null:
		return
	var step := int(_snapshot.step)
	visible = practice_mode or step > 0
	_headline.text = "%d  %s" % [step, _snapshot.label] if step > 0 else "J / X · THREE BEATS"
	_input_hint.visible = step > 0
	var inner := maxf(size.x - 24.0, 1.0)
	_headline.position = Vector2(12, 4)
	_headline.size = Vector2(inner - 44.0, 30)
	_input_hint.position = Vector2(size.x - 54, 12)
	_input_hint.size = Vector2(42, 20)
	for index in _beats.size():
		var label := _beats[index]
		label.position = Vector2(12 + inner * index / 3.0, 39)
		label.size = Vector2(inner / 3.0, 19)
		var color := _ink if index < step else _ink.lerp(_stock, 0.55)
		if index == step - 1: color = Press.PINK
		Press.set_body(label, Press.SIZE_SMALL, color, Color.TRANSPARENT, index == step - 1)
	_rail.position = Vector2(12, 66)
	_rail.size = Vector2(inner, 2)
	_window.position = _rail.position
	_window.size = Vector2(inner * float(_snapshot.remaining) / float(_snapshot.window), 2)
	_window.visible = step > 0
	_apply_stamp()

func _apply_stamp() -> void:
	if _headline == null:
		return
	var impulse := 0.0 if reduced_motion else pow(_stamp / STAMP_TIME, 2.0)
	_headline.position.y = 4.0 - impulse * 2.0
	_headline.modulate.a = 1.0 - impulse * 0.18
