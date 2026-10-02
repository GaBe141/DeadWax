extends Control
## Presentation only. Main supplies a small status snapshot and one nearby
## source's caption. No input, models, rooms, pause or saves are owned here.

const Press := preload("res://scripts/press.gd")
const TITLE_TIME := 3.6
var _state: Dictionary = {}
var _focus: Dictionary = {}
var _title_time := 0.0
var _notice_time := 0.0
var _notice_is_error := false
var _reduced_motion := false
var _ink := Color("f2e1bc")
var _accent := Color("d6a968")
var area_title: Label
var action_prompt: Label
var dialogue: Label
var speaker: Label
var notice: Label
var _title_alpha := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_title = _label(Press.SIZE_BANNER, true)
	action_prompt = _label(Press.SIZE_BODY)
	dialogue = _label(Press.SIZE_BODY)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speaker = _label(Press.SIZE_SMALL, true)
	notice = _label(Press.SIZE_BODY)
	resized.connect(_layout)
	_layout()
	_update_labels()

func _label(font_size: int, display := false) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if display: Press.set_display(label, font_size, _ink)
	else: Press.set_body(label, font_size, _ink)
	label.add_theme_color_override("font_shadow_color", Color(0.015, 0.02, 0.025, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.025, 0.85))
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	return label

func set_palette(ink: Color, accent: Color) -> void:
	_ink = ink
	_accent = accent
	for label in [area_title, action_prompt, dialogue, speaker, notice]:
		if label != null: label.add_theme_color_override("font_color", ink)
	queue_redraw()

func set_status(snapshot: Dictionary) -> void:
	_state = snapshot.duplicate(true)
	queue_redraw()

func set_focus(snapshot: Dictionary) -> void:
	_focus = snapshot.duplicate(true)
	_update_labels()

func present_area(text: String) -> void:
	reset_transients()
	area_title.text = text
	_title_time = TITLE_TIME
	_update_labels()

func present_notice(text: String, lifetime := 3.0) -> void:
	# These are short receipts, not tutorial plates. Errors remain complete
	# because a failed save needs an understandable, retryable response.
	var message := text.replace("\n", " ")
	if not message.to_lower().contains("save"):
		message = message.split(" — ")[0] if message.length() > 52 else message
		message = message.split(". ")[0] if message.length() > 60 else message
	notice.text = message
	_notice_is_error = message.to_lower().contains("save") and not message.to_lower().contains("saved")
	_notice_time = maxf(lifetime, 6.0) if _notice_is_error else lifetime
	_update_labels()

func clear_save_error() -> void:
	if _notice_is_error:
		_notice_time = 0.0
		_notice_is_error = false
		_update_labels()

func reset_transients() -> void:
	_title_time = 0.0
	_notice_time = 0.0
	_notice_is_error = false
	_focus.clear()
	if area_title != null: _update_labels()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	_update_labels()

func _process(delta: float) -> void:
	_title_time = maxf(0.0, _title_time - delta)
	_notice_time = maxf(0.0, _notice_time - delta)
	_update_labels()

func _update_labels() -> void:
	if area_title == null: return
	var speaking := not String(_focus.get("dialogue", "")).is_empty() and not (_notice_is_error and _notice_time > 0.0)
	_title_alpha = 1.0 if _reduced_motion and _title_time > 0 else clampf(minf((TITLE_TIME - _title_time) / 0.45, _title_time / 0.65), 0.0, 1.0)
	area_title.visible = _title_time > 0 and not speaking
	area_title.modulate.a = _title_alpha
	action_prompt.text = String(_focus.get("text", ""))
	action_prompt.visible = not action_prompt.text.is_empty()
	dialogue.text = String(_focus.get("dialogue", ""))
	dialogue.visible = speaking
	speaker.text = String(_focus.get("speaker", ""))
	speaker.visible = speaking and not speaker.text.is_empty()
	notice.visible = _notice_time > 0 and not speaking
	notice.modulate.a = 1.0 if _reduced_motion else clampf(_notice_time / 0.35, 0.0, 1.0)
	queue_redraw()

func _layout() -> void:
	if area_title == null: return
	area_title.position = Vector2(40, size.y * 0.36)
	area_title.size = Vector2(maxf(size.x - 80, 1), 55)
	var width := minf(740, size.x - 70)
	dialogue.position = Vector2((size.x - width) * 0.5, size.y - 145)
	dialogue.size = Vector2(width, 75)
	speaker.position = Vector2((size.x - width) * 0.5, size.y - 172)
	speaker.size = Vector2(width, 25)
	action_prompt.position = Vector2(25, size.y - 55)
	action_prompt.size = Vector2(maxf(size.x - 50, 1), 25)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.position = Vector2((size.x - width) * 0.5, size.y - 104)
	notice.size = Vector2(width, 48)

func _draw() -> void:
	var pose := _state.duplicate(true)
	pose.title_alpha = _title_alpha if area_title != null and area_title.visible else 0.0
	Press.draw_cinematic(self, size, pose, _ink, _accent)
