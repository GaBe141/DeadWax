extends "res://scripts/test_pressing.gd"
## HUSH keeps the proven three-parry rules; his defeat is a held bow,
## not the practice pressing's timed reformation.

const PressScript := preload("res://scripts/press.gd")
const BOW_SETTLE_TIME := 0.8
const SWING_FOLLOW_TIME := 0.26

var print_ink := Color("494450")
var print_stock := Color("ded5df")
var _won := false
var _hush_time := 0.0
var _pose_age := 0.0
var _shown_pose: int = S.CALM
var _swing_tail := 0.0

func _ready() -> void:
	muted = true
	super._ready()
	add_to_group("chapter_boss")

func _process(delta: float) -> void:
	if delta <= 0.0 or (is_inside_tree() and get_tree().paused):
		return
	_hush_time += delta
	_pose_age += delta
	_swing_tail = maxf(_swing_tail - delta, 0.0)
	if not _won:
		super._process(delta)
	if state != _shown_pose:
		if _shown_pose == S.SWING and state in [S.ALERT, S.COUNTING]:
			_swing_tail = SWING_FOLLOW_TIME
		_shown_pose = state
		_pose_age = 0.0
	queue_redraw()

func on_player_strike(pos: Vector2, big: bool) -> void:
	# HUSH keeps his time. Rewinding the swing on a close raw strike would
	# postpone contact beyond the same strike's 100 ms parry window.
	if muted:
		return
	super.on_player_strike(pos, big)

func _down(spill: bool) -> void:
	if _won:
		return
	super._down(spill)
	if not spill:
		_won = true
		remove_from_group("strikable")
		_pose_age = 0.0
		_shown_pose = S.DOWN
		_swing_tail = 0.0
	queue_redraw()

func restore_outcome(outcome: String) -> void:
	if outcome != "won":
		return
	_won = true
	state = S.DOWN
	parry_count = 0
	resonance = 0.0
	_t = 0.0
	_hush_time = 0.0
	_pose_age = BOW_SETTLE_TIME
	_shown_pose = S.DOWN
	_swing_tail = 0.0
	remove_from_group("strikable")
	queue_redraw()

func reset_attempt() -> void:
	if _won:
		return
	state = S.CALM
	parry_count = 0
	resonance = 0.0
	hp = HP_MAX
	_count = 0
	_t = 0.0
	_hush_time = 0.0
	_pose_age = 0.0
	_shown_pose = S.CALM
	_swing_tail = 0.0
	queue_redraw()

func _draw() -> void:
	var motion := {
		"clock": _hush_time,
		"age": _pose_age,
		"settle": clampf(_pose_age / BOW_SETTLE_TIME, 0.0, 1.0),
		"follow_through": clampf(_swing_tail / SWING_FOLLOW_TIME, 0.0, 1.0),
	}
	PressScript.draw_hush(self, state, _count, 3 if _won else parry_count, _face, _t, print_ink, print_stock, motion)
