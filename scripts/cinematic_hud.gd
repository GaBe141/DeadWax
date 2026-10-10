extends Control
## Presentation only. Main supplies a small status snapshot and one nearby
## source's caption. No input, models, rooms, pause or saves are owned here.

const Press := preload("res://scripts/press.gd")
const TITLE_TIME := 3.6
const XP_RECEIPT_TIME := 1.6       # gains inside this window add up to one receipt
const LEVEL_RECEIPT_TIME := 4.5
# The marks react to what Main reports. These clocks are presentation only and
# pause with play; Reduced motion settles them to their final state.
const CRACK_TIME := 0.5            # a lost diamond splits and falls away
const INK_TIME := 0.42             # a restored diamond fills from the bottom
const INK_STAGGER := 0.08          # several restored diamonds ink one after another
const XP_CATCH_RATE := 2.4         # line lengths per second while catching up a level
const BURST_TIME := 1.1            # the ring on a new level
const SETTLED := 99.0
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
## XP receipts sit under the status marks, apart from notices and dialogue.
var xp_receipt: Label
var _title_alpha := 0.0
var _xp_time := 0.0
var _xp_amount := 0
var _level_time := 0.0
var _level_text := ""
var _shown_health := -1
var _crack_age: Array[float] = []
var _ink_age: Array[float] = []
var _xp_level_shown := -1
var _xp_shown := 0.0
var _xp_flash := 0.0
var _burst_age := -1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_title = _label(Press.SIZE_BANNER, true)
	action_prompt = _label(Press.SIZE_BODY)
	dialogue = _label(Press.SIZE_BODY)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speaker = _label(Press.SIZE_SMALL, true)
	notice = _label(Press.SIZE_BODY)
	xp_receipt = _label(Press.SIZE_SMALL)
	xp_receipt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	for label in [area_title, action_prompt, dialogue, speaker, notice, xp_receipt]:
		if label != null: label.add_theme_color_override("font_color", ink)
	queue_redraw()

func set_status(snapshot: Dictionary) -> void:
	_state = snapshot.duplicate(true)
	_track_health(int(_state.get("health", 3)), int(_state.get("max_health", 3)))
	queue_redraw()

## A fresh session or restored checkpoint shows its marks as they are, without
## replaying a loss, a refill or a level.
func settle_marks() -> void:
	_shown_health = -1
	_crack_age.clear()
	_ink_age.clear()
	_xp_level_shown = -1
	_xp_flash = 0.0
	_burst_age = -1.0
	queue_redraw()

func _track_health(health: int, maximum: int) -> void:
	maximum = maxi(maximum, 0)
	health = clampi(health, 0, maximum)
	while _crack_age.size() < maximum:
		_crack_age.append(SETTLED)
		_ink_age.append(SETTLED)
	if _crack_age.size() > maximum:
		_crack_age = _crack_age.slice(0, maximum)
		_ink_age = _ink_age.slice(0, maximum)
	if _shown_health < 0 or _reduced_motion:
		_shown_health = health
		for index in maximum:
			_crack_age[index] = SETTLED
			_ink_age[index] = SETTLED
		return
	if health < _shown_health:
		for index in range(health, mini(_shown_health, maximum)):
			_crack_age[index] = 0.0
			_ink_age[index] = SETTLED
	elif health > _shown_health:
		var order := 0
		for index in range(_shown_health, health):
			_ink_age[index] = -INK_STAGGER * order
			_crack_age[index] = SETTLED
			order += 1
	_shown_health = health

func marks_snapshot() -> Dictionary:
	return {"cracks": _progress(_crack_age, CRACK_TIME), "inks": _progress(_ink_age, INK_TIME),
		"xp": _xp_shown, "xp_level": _xp_level_shown, "flash": _xp_flash,
		"burst": clampf(_burst_age / BURST_TIME, 0.0, 1.0) if _burst_age >= 0.0 else -1.0}

## -1 is a settled mark, 0..1 one in motion; a restored diamond waiting its
## turn reads 0, still empty.
static func _progress(ages: Array[float], duration: float) -> Array[float]:
	var result: Array[float] = []
	for age in ages:
		result.append(-1.0 if age >= duration else clampf(age / duration, 0.0, 1.0))
	return result

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

## Main reports XP actually granted. Quick gains read as one running total.
func present_xp(amount: int) -> void:
	if amount <= 0:
		return
	_xp_amount = _xp_amount + amount if _xp_time > 0.0 else amount
	_xp_time = XP_RECEIPT_TIME
	_update_labels()

func present_level(level: int, picks: int, book_key := "I / Start") -> void:
	_level_text = "LEVEL %d  ·  %s" % [level, "choose a gain in the Book (%s)" % book_key if picks > 0 else "every gain chosen"]
	_level_time = LEVEL_RECEIPT_TIME
	_burst_age = 0.0
	_update_labels()

func xp_text() -> String:
	return xp_receipt.text if xp_receipt != null and xp_receipt.visible else ""

func clear_save_error() -> void:
	if _notice_is_error:
		_notice_time = 0.0
		_notice_is_error = false
		_update_labels()

func reset_transients() -> void:
	_title_time = 0.0
	_notice_time = 0.0
	_notice_is_error = false
	_xp_time = 0.0
	_xp_amount = 0
	_level_time = 0.0
	_burst_age = -1.0
	_focus.clear()
	if area_title != null: _update_labels()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if enabled:
		for index in _crack_age.size():
			_crack_age[index] = SETTLED
			_ink_age[index] = SETTLED
		_xp_level_shown = -1
		_xp_flash = 0.0
		_advance_xp(0.0)
	_update_labels()

func _process(delta: float) -> void:
	_title_time = maxf(0.0, _title_time - delta)
	_notice_time = maxf(0.0, _notice_time - delta)
	_xp_time = maxf(0.0, _xp_time - delta)
	_level_time = maxf(0.0, _level_time - delta)
	if delta > 0.0:
		for index in _crack_age.size():
			if _crack_age[index] < CRACK_TIME: _crack_age[index] += delta
			if _ink_age[index] < INK_TIME: _ink_age[index] += delta
		if _burst_age >= 0.0:
			_burst_age += delta
			if _burst_age >= BURST_TIME: _burst_age = -1.0
		_advance_xp(delta)
	_update_labels()

## The hairline eases toward Main's ratio. A new level first runs the line to
## its end, flashes, and starts again from the left.
func _advance_xp(delta: float) -> void:
	var xp: Dictionary = _state.get("xp", {}) if _state.get("xp", {}) is Dictionary else {}
	if xp.is_empty():
		_xp_level_shown = -1
		return
	var level := int(xp.get("level", 1))
	var target := clampf(float(xp.get("ratio", 0.0)), 0.0, 1.0)
	_xp_flash = maxf(_xp_flash - delta * 2.0, 0.0)
	if _xp_level_shown < 0 or _reduced_motion or level < _xp_level_shown:
		_xp_level_shown = level
		_xp_shown = target
		return
	if level > _xp_level_shown:
		_xp_shown = minf(_xp_shown + delta * XP_CATCH_RATE, 1.0)
		if _xp_shown >= 1.0:
			_xp_level_shown += 1
			_xp_shown = 0.0
			_xp_flash = 1.0
		return
	if target <= _xp_shown:
		_xp_shown = target
		return
	_xp_shown = minf(target, _xp_shown + maxf((target - _xp_shown) * (1.0 - exp(-delta * 7.0)), delta * 0.15))

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
	# A level outranks a running total; both fade on their own clocks.
	var leveling := _level_time > 0.0
	xp_receipt.text = _level_text if leveling else "+%d XP" % _xp_amount
	xp_receipt.visible = leveling or _xp_time > 0.0
	var remaining := _level_time if leveling else _xp_time
	xp_receipt.modulate.a = 1.0 if _reduced_motion else clampf(remaining / 0.35, 0.0, 1.0)
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
	xp_receipt.position = Vector2(24, 70)
	xp_receipt.size = Vector2(minf(460, maxf(size.x - 48, 1)), 22)

func _draw() -> void:
	var pose := _state.duplicate(true)
	pose.title_alpha = _title_alpha if area_title != null and area_title.visible else 0.0
	var marks := marks_snapshot()
	pose.cracks = marks.cracks
	pose.inks = marks.inks
	pose.burst = marks.burst
	pose.burst_still = _reduced_motion
	if pose.get("xp", {}) is Dictionary and not (pose.xp as Dictionary).is_empty() and _xp_level_shown >= 0:
		pose.xp.ratio = _xp_shown
		pose.xp.flash = _xp_flash
	Press.draw_cinematic(self, size, pose, _ink, _accent)
