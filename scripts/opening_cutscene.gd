extends CanvasLayer
## A little history printed before the first footstep. Main owns the paused
## world and the handoff; this layer owns only its four shots and input intent.

signal finished
signal shot_started(index: int)

const Press := preload("res://scripts/press.gd")
const SHOT_DURATIONS := [5.5, 6.0, 5.5, 6.0]
const CAPTIONS := [
	"Once, every groove held a voice.",
	"The song wore thin. The voices stayed.",
	"One small needle found its feet.",
	"Somewhere below, something is still playing.",
]
const IMPRINTS := ["THE RECORD", "THE WORN SONG", "THE NEEDLE", "SIDE ONE"]
const INK := Color("29232a")
const STOCK := Color("e8dfcb")
const EXIT_TIME := 0.35
const REVEAL_TIME := 0.45
const INPUT_ARM_TIME := 0.20

class OpeningArt extends Control:
	var pose: Dictionary = {}
	func _draw() -> void:
		Press.draw_opening(self, size, pose)

var is_open := false
var shot := 0
var elapsed := 0.0
var reduced_motion := false
var overlay: Control
var art: OpeningArt
var caption: Label
var imprint: Label
var brand: Label
var next_button: Button
var skip_button: Button
var _armed := false
var _arm_age := 0.0
var _finishing := false
var _exit_elapsed := 0.0
var _clock := 0.0

func _ready() -> void:
	layer = 125
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = Control.new()
	overlay.name = "OpeningOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backing := ColorRect.new()
	backing.color = STOCK
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art = OpeningArt.new()
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var paper := Press.paper_overlay(INK)
	overlay.add_child(paper)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Press.set_body(caption, Press.SIZE_TITLE, INK)
	overlay.add_child(caption)
	imprint = Label.new()
	Press.set_body(imprint, Press.SIZE_SMALL, INK)
	imprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(imprint)
	brand = Label.new()
	brand.text = "DEAD WAX"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Press.set_display(brand, Press.SIZE_BANNER, INK)
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(brand)
	next_button = _button("SPACE / A · Next", next_shot)
	skip_button = _button("ESC / B · Skip", skip)
	next_button.focus_neighbor_right = next_button.get_path_to(skip_button)
	skip_button.focus_neighbor_left = skip_button.get_path_to(next_button)
	overlay.resized.connect(_resize)
	_resize()
	cancel()

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", Press.BodyFont)
	button.add_theme_font_size_override("font_size", Press.SIZE_SMALL)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", Press.menu_button_style(INK, STOCK))
	button.add_theme_stylebox_override("hover", Press.menu_button_style(INK, STOCK, false, true))
	button.add_theme_stylebox_override("focus", Press.menu_focus_style(INK, STOCK))
	button.add_theme_stylebox_override("pressed", Press.menu_button_style(INK, STOCK, true))
	button.add_theme_color_override("font_pressed_color", STOCK)
	button.add_theme_color_override("font_hover_pressed_color", STOCK)
	button.pressed.connect(action)
	overlay.add_child(button)
	return button

func play_opening() -> void:
	shot = 0
	elapsed = 0.0
	_clock = 0.0
	_arm_age = 0.0
	_armed = false
	_finishing = false
	_exit_elapsed = 0.0
	is_open = true
	overlay.modulate.a = 1.0
	overlay.show()
	_update_shot()
	_update_print()

func cancel() -> void:
	is_open = false
	_finishing = false
	_armed = false
	if overlay != null:
		overlay.hide()
		var focus := get_viewport().gui_get_focus_owner()
		if focus != null and overlay.is_ancestor_of(focus): focus.release_focus()

func _process(delta: float) -> void:
	if is_open:
		# Returning from a long OS stall must not throw away an unread sentence.
		advance(minf(delta, 0.1))

func advance(delta: float) -> void:
	if not is_open or delta <= 0.0:
		return
	_arm_age += delta
	if not _armed and _arm_age >= INPUT_ARM_TIME and not _confirm_held():
		_armed = true
	_clock += delta
	var remaining := delta
	while remaining > 0.0 and not _finishing:
		var step := minf(remaining, float(SHOT_DURATIONS[shot]) - elapsed)
		elapsed += step
		remaining -= step
		if elapsed >= float(SHOT_DURATIONS[shot]):
			next_shot()
	if _finishing:
		_exit_elapsed += remaining
	_update_print()
	if _finishing and _exit_elapsed >= EXIT_TIME:
		cancel()
		finished.emit()

func next_shot() -> void:
	if not is_open or _finishing:
		return
	if shot == SHOT_DURATIONS.size() - 1:
		skip()
		return
	shot += 1
	elapsed = 0.0
	_update_shot()
	_update_print()

func skip() -> void:
	if not is_open or _finishing:
		return
	_finishing = true
	_exit_elapsed = 0.0
	_update_print()

func _confirm_held() -> bool:
	for action in [&"ui_accept", &"ui_cancel", &"jump", &"pause_game"]:
		if Input.is_action_pressed(action): return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()
		return
	if _armed and not _finishing:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_game"):
			skip()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
			if skip_button.has_focus(): skip()
			else: next_shot()
			get_viewport().set_input_as_handled()
			return
	# Leave pointer/focus events to these two buttons. The world stays paused.
	if event is InputEventMouse or event.is_action("ui_left") or event.is_action("ui_right") or event.is_action("ui_up") or event.is_action("ui_down"):
		return
	get_viewport().set_input_as_handled()

func _update_shot() -> void:
	caption.text = CAPTIONS[shot]
	imprint.text = "%02d / %s" % [shot + 1, IMPRINTS[shot]]
	brand.visible = shot == 3
	next_button.text = "SPACE / A · Begin" if shot == 3 else "SPACE / A · Next"
	shot_started.emit(shot)
	_resize()

func _update_print() -> void:
	if not is_open:
		return
	var reveal := 1.0 if reduced_motion else minf(clampf(elapsed / REVEAL_TIME, 0.0, 1.0), clampf((float(SHOT_DURATIONS[shot]) - elapsed) / REVEAL_TIME, 0.0, 1.0))
	art.pose = animation_pose()
	art.modulate.a = reveal
	art.queue_redraw()
	caption.modulate.a = reveal
	brand.modulate.a = reveal
	overlay.modulate.a = 1.0 - clampf(_exit_elapsed / EXIT_TIME, 0.0, 1.0) if _finishing else 1.0
	next_button.disabled = not _armed or _finishing
	skip_button.disabled = not _armed or _finishing

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_update_print()

func animation_pose() -> Dictionary:
	return {"shot": shot, "progress": 0.72 if reduced_motion else elapsed / float(SHOT_DURATIONS[shot]),
		"clock": 0.0 if reduced_motion else _clock, "reduced_motion": reduced_motion,
		"caption": CAPTIONS[shot], "finishing": _finishing, "armed": _armed}

func _resize() -> void:
	if overlay == null or caption == null:
		return
	var extent := overlay.size
	var scale := minf(extent.x / 1280.0, extent.y / 720.0)
	var field := Vector2(1280, 720) * scale
	var origin := (extent - field) * 0.5
	caption.position = origin + Vector2(70, 556 if shot == 3 else 530) * scale
	caption.size = Vector2(1140, 80) * scale
	caption.add_theme_font_size_override("font_size", maxi(18, roundi(27 * scale)))
	brand.position = origin + Vector2(70, 502) * scale
	brand.size = Vector2(1140, 60) * scale
	brand.add_theme_font_size_override("font_size", maxi(28, roundi(46 * scale)))
	imprint.position = origin + Vector2(36, 25) * scale
	skip_button.position = Vector2(extent.x - 186, extent.y - 56)
	skip_button.size = Vector2(164, 36)
	next_button.position = Vector2(extent.x - 402, extent.y - 56)
	next_button.size = Vector2(204, 36)
