extends Node
## A few short impressions on the page. Main supplies events and owns every
## value; these clocks only move noninteractive type and pause with the world.

const ROOM_TIME := 0.28
const STAMP_TIME := 0.18
const STATUS_TIME := 0.24
const RECEIPT_TIME := 1.25

var title: Label
var subtitle: Label
var title_rule: ColorRect
var feedback: Label
var status: Label
var shine_notice: Label
var reduced_motion := false

var _title_home := Vector2.ZERO
var _subtitle_home := Vector2.ZERO
var _receipt_home := Vector2.ZERO
var _room_t := 0.0
var _stamp_t := 0.0
var _status_t := 0.0
var _receipt_t := 0.0
var _receipt_amount := 0

func _ready() -> void:
	_title_home = title.position
	_subtitle_home = subtitle.position
	_receipt_home = shine_notice.position
	_apply_pose()
	set_process(false)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if enabled:
		_room_t = 0.0
		_stamp_t = 0.0
		_status_t = 0.0
	_apply_pose()

func present_room() -> void:
	reset_transients()
	_room_t = 0.0 if reduced_motion else ROOM_TIME
	_apply_pose()
	set_process(_room_t > 0.0)

func present_feedback() -> void:
	_stamp_t = 0.0 if reduced_motion else STAMP_TIME
	_apply_pose()
	set_process(true)

func present_status() -> void:
	_status_t = 0.0 if reduced_motion else STATUS_TIME
	_apply_pose()
	set_process(true)

func show_shine(amount: int) -> void:
	if amount <= 0:
		return
	_receipt_amount = _receipt_amount + amount if _receipt_t > 0.0 else amount
	shine_notice.text = "+%d SHINE" % _receipt_amount
	_receipt_t = RECEIPT_TIME
	present_status()

func reset_transients() -> void:
	_stamp_t = 0.0
	_status_t = 0.0
	_receipt_t = 0.0
	_receipt_amount = 0
	_apply_pose()

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	_room_t = maxf(0.0, _room_t - delta)
	_stamp_t = maxf(0.0, _stamp_t - delta)
	_status_t = maxf(0.0, _status_t - delta)
	_receipt_t = maxf(0.0, _receipt_t - delta)
	_apply_pose()
	set_process(_room_t + _stamp_t + _status_t + _receipt_t > 0.0)

func _apply_pose() -> void:
	if not is_instance_valid(title):
		return
	var entering := pow(_room_t / ROOM_TIME, 3.0)
	title.position = _title_home + Vector2(0.0, -6.0 * entering)
	subtitle.position = _subtitle_home + Vector2(0.0, -4.0 * entering)
	title.modulate.a = 1.0 - entering * 0.45
	subtitle.modulate.a = 1.0 - entering * 0.55
	title_rule.scale.x = 1.0 - entering
	feedback.pivot_offset = feedback.size * 0.5
	feedback.scale = Vector2.ONE * (1.0 + 0.045 * pow(_stamp_t / STAMP_TIME, 2.0))
	status.scale = Vector2.ONE * (1.0 + 0.025 * sin((_status_t / STATUS_TIME) * PI))
	shine_notice.visible = _receipt_t > 0.0
	if reduced_motion:
		shine_notice.position = _receipt_home
		shine_notice.modulate.a = 1.0
	else:
		var receipt_age := RECEIPT_TIME - _receipt_t
		shine_notice.position = _receipt_home + Vector2(0.0, 5.0 * pow(maxf(0.0, 1.0 - receipt_age / 0.20), 3.0))
		shine_notice.modulate.a = clampf(_receipt_t / 0.30, 0.0, 1.0)
