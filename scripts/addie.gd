extends "res://scripts/auditioner.gd"
## A named voice uses the existing SET/strike rules. Her freed pose remains
## in the doorway; restoring it never plays the bar or emits an outcome again.

const PUTTER_RADIUS := 55.0
const PUTTER_STEP := 32.0
const PUTTER_SPEED := 14.0
const PUTTER_PAUSE_CYCLE := 6.0
const FRIEND_NOTICE_RANGE := 185.0
const FRIEND_STOP_RANGE := 48.0
const HOOD_PAT_RANGE := 70.0
const PAT_EASE := 3.0

var _resolved := ""
var _print_defeat_elapsed := 0.0
var _print_defeat_active := false
var _home_position := Vector2.ZERO
var _resident_clock := 0.0
var _resident_walking := false
var _resident_near := false
var _resident_quiet := false
var _resident_returning := false
var _pat := 0.0
var _pat_target := Vector2.ZERO

func _ready() -> void:
	_home_position = position
	super._ready()

func _process(delta: float) -> void:
	if not _resolved.is_empty():
		_advance_print(delta)
		if _resolved == "freed":
			_putter(delta)
		if _print_defeat_active and delta > 0.0 and not get_tree().paused:
			_print_defeat_elapsed += minf(delta, 0.1)
			if _print_defeat_elapsed >= BURST_TIME:
				_print_defeat_active = false
				visible = false
		return
	super._process(delta)

func _holds_freed_impression() -> bool:
	return _resolved == "freed"

## Friendly presentation data is also exposed to visual previews. None of this
## is a progression flag, a new lesson or a reason to reopen the encounter.
func resident_pose() -> Dictionary:
	return {
		"clock": _resident_clock, "walking": _resident_walking,
		"stride": _print_stride, "pat": _pat, "hand_target": _pat_target,
		"near": _resident_near, "quiet": _resident_quiet,
		"home": _home_position, "returning": _resident_returning,
	}

func _putter(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	var step := minf(delta, 0.1)
	_resident_clock += step
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	var left := _home_position.x - PUTTER_RADIUS
	var right := _home_position.x + PUTTER_RADIUS
	_resident_returning = position.x < left or position.x > right
	var destination := _home_position.x + (-PUTTER_STEP if int(_resident_clock / PUTTER_PAUSE_CYCLE) % 2 == 0 else PUTTER_STEP)
	_resident_near = false
	_resident_quiet = false
	var wants_pat := false
	if is_instance_valid(_player):
		var offset := _player.global_position - global_position
		_resident_near = offset.length() <= FRIEND_NOTICE_RANGE
		var grounded := _player is CharacterBody2D and (_player as CharacterBody2D).is_on_floor()
		_resident_quiet = _resident_near and grounded and (_player.get("hooded") == true or _player.get("setting") == true)
		if _resident_near and absf(offset.x) > 2.0:
			_face = signf(offset.x)
		if _resident_quiet and absf(offset.y) <= 64.0 and not _resident_returning:
			var player_here := to_local(_player.global_position) + position
			destination = clampf(player_here.x - _face * FRIEND_STOP_RANGE, left, right)
			wants_pat = offset.length() <= HOOD_PAT_RANGE and absf(offset.x) <= HOOD_PAT_RANGE
			# Skip's hood peaks 44px above their origin. Keep the hand in reach,
			# never stretch an arm across a doorway or after an airborne player.
			_pat_target = to_local(_player.global_position + Vector2(0.0, -43.0))
			_pat_target.x = clampf(_pat_target.x, -HOOD_PAT_RANGE, HOOD_PAT_RANGE)
			_pat_target.y = clampf(_pat_target.y, -75.0, -25.0)
	if _resident_returning:
		# An unresolved Addie may have wandered before being freed. She walks
		# home once rather than blinking across the room; then stays in her patch.
		destination = clampf(position.x, left, right)
	var old_x := position.x
	position.x = move_toward(position.x, destination, PUTTER_SPEED * step)
	position.y = _home_position.y
	_resident_walking = absf(position.x - old_x) > 0.001
	if _resident_walking:
		_print_stride += absf(position.x - old_x) * PRINT_STRIDE_RADIANS
		if not _resident_near:
			_face = signf(position.x - old_x)
	_pat = move_toward(_pat, 1.0 if wants_pat else 0.0, PAT_EASE * step)
	queue_redraw()

func _draw() -> void:
	# A live shatter gets its short impression before disappearing; the saved
	# outcome remains immediate and silent. No combat timer is resumed here.
	if _print_defeat_active:
		var pose := {"phase": "down", "face": _face, "clock": _print_time,
			"stride": _print_stride, "recoil": 0.0, "reach": 0.0,
			"jitter": Vector2.ZERO, "burst": clampf(_print_defeat_elapsed / BURST_TIME, 0.0, 1.0)}
		PrintPress.draw_auditioner(self, pose, INK, BODY, PALE, PINK, GREY, WARM)
		return
	if _resolved == "freed":
		var pose := {"phase": "freed", "face": _face, "clock": _print_time,
			"stride": _print_stride, "recoil": 0.0, "reach": 0.0,
			"jitter": Vector2.ZERO, "held": true, "leave": 0.0,
			"resident": resident_pose()}
		PrintPress.draw_auditioner(self, pose, INK, BODY, PALE, PINK, GREY, WARM)
		return
	super._draw()

func _free() -> void:
	if not _resolved.is_empty():
		return
	_resolved = "freed"
	super._free()
	_t = 0.12
	remove_from_group("strikable")
	queue_redraw()

func _down() -> void:
	if not _resolved.is_empty():
		return
	_resolved = "shattered"
	super._down()
	remove_from_group("strikable")
	_print_defeat_elapsed = 0.0
	_print_defeat_active = true
	queue_redraw()

func restore_outcome(outcome: String) -> void:
	if outcome not in ["freed", "shattered"]:
		return
	_resolved = outcome
	_print_defeat_active = false
	state = S.FREED if outcome == "freed" else S.DOWN
	resonance = 0.0
	_t = 0.12
	remove_from_group("strikable")
	visible = outcome == "freed"
	queue_redraw()
