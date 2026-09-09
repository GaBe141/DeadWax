extends "res://scripts/auditioner.gd"
## A named voice uses the existing SET/strike rules. Her freed pose remains
## in the doorway; restoring it never plays the bar or emits an outcome again.

var _resolved := ""
var _print_defeat_elapsed := 0.0
var _print_defeat_active := false

func _process(delta: float) -> void:
	if not _resolved.is_empty():
		_advance_print(delta)
		if _print_defeat_active and delta > 0.0 and not get_tree().paused:
			_print_defeat_elapsed += minf(delta, 0.1)
			if _print_defeat_elapsed >= BURST_TIME:
				_print_defeat_active = false
				visible = false
		return
	super._process(delta)

func _holds_freed_impression() -> bool:
	return _resolved == "freed"

func _draw() -> void:
	# A live shatter gets its short impression before disappearing; the saved
	# outcome remains immediate and silent. No combat timer is resumed here.
	if _print_defeat_active:
		var pose := {"phase": "down", "face": _face, "clock": _print_time,
			"stride": _print_stride, "recoil": 0.0, "reach": 0.0,
			"jitter": Vector2.ZERO, "burst": clampf(_print_defeat_elapsed / BURST_TIME, 0.0, 1.0)}
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
