extends Node
## Small impressions on existing UI. Geometry, focus, input and actions remain
## entirely with the controls; inherited processing follows their menu or HUD.

const Press := preload("res://scripts/press.gd")
const REVEAL_ALPHA := 0.32
const PULSE_TIME := 0.20
const BUTTON_MARK := "InkMotion"

var reduced_motion := false:
	set(value):
		reduced_motion = value
		for id in _buttons.keys():
			var mark: Object = _buttons[id].get_ref()
			if is_instance_valid(mark):
				mark.set_reduced_motion(value)
		if value:
			settle()

var _motions: Dictionary = {}
var _buttons: Dictionary = {}

class ButtonMark extends Control:
	var accent := Color.MAGENTA
	var level := 0.0
	var press_age := 0.0
	var reduced := false
	var was_in_tree := false
	var _hovered := false
	var _button: WeakRef

	func _ready() -> void:
		was_in_tree = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)

	func bind(button: Button) -> void:
		_button = weakref(button)
		button.focus_entered.connect(_focus_changed)
		button.focus_exited.connect(_focus_changed)
		button.mouse_entered.connect(_mouse_entered)
		button.mouse_exited.connect(_mouse_exited)
		button.button_down.connect(pulse)
		button.pressed.connect(pulse)

	func _target() -> float:
		var button := _button.get_ref() as Button if _button != null else null
		if button == null or button.disabled:
			return 0.0
		return 1.0 if button.has_focus() or _hovered else 0.0

	func _focus_changed() -> void:
		if reduced:
			settle()

	func _mouse_entered() -> void:
		_hovered = true
		_focus_changed()

	func _mouse_exited() -> void:
		_hovered = false
		_focus_changed()

	func pulse() -> void:
		var button := _button.get_ref() as Button if _button != null else null
		if not reduced and is_visible_in_tree() and button != null and not button.disabled:
			press_age = PULSE_TIME
			queue_redraw()

	func set_reduced_motion(enabled: bool) -> void:
		reduced = enabled
		if enabled:
			settle()

	func settle() -> void:
		level = _target()
		press_age = 0.0
		queue_redraw()

	func _process(delta: float) -> void:
		if delta <= 0.0 or not is_visible_in_tree():
			return
		var target := _target()
		var previous := level
		var previous_press := press_age
		level = target if reduced else move_toward(level, target, delta * 9.0)
		press_age = 0.0 if reduced else maxf(press_age - delta, 0.0)
		if level != previous or press_age != previous_press:
			queue_redraw()

	func _draw() -> void:
		Press.draw_ui_focus(self, size, accent, level, press_age / PULSE_TIME)

## Alpha is safe for Container children and leaves their hitboxes in place.
## Distance stays in the shared call contract for decorative wrappers.
@warning_ignore("unused_parameter")
func reveal(control: Control, distance: float = 10.0, duration: float = 0.22, delay: float = 0.0) -> void:
	if not is_instance_valid(control):
		return
	_restore(control.get_instance_id())
	if reduced_motion or duration <= 0.0:
		return
	var base := control.modulate
	_motions[control.get_instance_id()] = {"target": weakref(control), "base": base,
		"age": -maxf(delay, 0.0), "duration": duration, "start": REVEAL_ALPHA}
	control.modulate = Color(base, base.a * REVEAL_ALPHA)

func pulse(control: Control) -> void:
	if not is_instance_valid(control) or reduced_motion:
		return
	var id := control.get_instance_id()
	if _buttons.has(id):
		var mark: Object = _buttons[id].get_ref()
		if is_instance_valid(mark):
			mark.pulse()
			return
	_restore(id)
	var base := control.modulate
	_motions[id] = {"target": weakref(control), "base": base,
		"age": 0.0, "duration": PULSE_TIME, "start": 0.58}
	control.modulate = Color(base, base.a * 0.58)

func bind_button(button: Button, accent: Color) -> void:
	if not is_instance_valid(button):
		return
	var mark := button.get_node_or_null(NodePath(BUTTON_MARK)) as ButtonMark
	if mark == null:
		mark = ButtonMark.new()
		mark.name = BUTTON_MARK
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(mark)
		mark.bind(button)
	mark.accent = accent
	mark.set_reduced_motion(reduced_motion)
	_buttons[button.get_instance_id()] = weakref(mark)
	_prune_buttons()

func settle() -> void:
	for id in _motions.keys():
		_restore(id)
	_prune_buttons()
	for id in _buttons:
		var mark: Object = _buttons[id].get_ref()
		if is_instance_valid(mark):
			mark.settle()

func active_count() -> int:
	return _motions.size()

func _process(delta: float) -> void:
	_prune_buttons()
	if delta <= 0.0:
		return
	for id in _motions.keys():
		var motion: Dictionary = _motions[id]
		var control := motion.target.get_ref() as Control
		if not is_instance_valid(control) or not control.is_inside_tree():
			_restore(id)
			continue
		motion.age += delta
		var progress := clampf(float(motion.age) / float(motion.duration), 0.0, 1.0)
		var amount := 1.0 - pow(1.0 - progress, 3.0)
		var base: Color = motion.base
		control.modulate = Color(base, base.a * lerpf(float(motion.start), 1.0, amount))
		if progress >= 1.0:
			_restore(id)

func _restore(id: int) -> void:
	if not _motions.has(id):
		return
	var motion: Dictionary = _motions[id]
	var control := motion.target.get_ref() as Control
	if is_instance_valid(control):
		control.modulate = motion.base
	_motions.erase(id)

func _prune_buttons() -> void:
	for id in _buttons.keys():
		var mark: Object = _buttons[id].get_ref()
		if not is_instance_valid(mark) or (mark.was_in_tree and not mark.is_inside_tree()):
			_buttons.erase(id)

func _exit_tree() -> void:
	settle()
