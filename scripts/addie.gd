extends "res://scripts/auditioner.gd"
## A named voice uses the existing SET/strike rules. Her freed pose remains
## in the doorway; restoring it never plays the bar or emits an outcome again.

var _resolved := ""

func _process(delta: float) -> void:
	if not _resolved.is_empty():
		return
	super._process(delta)

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
	visible = false

func restore_outcome(outcome: String) -> void:
	if outcome not in ["freed", "shattered"]:
		return
	_resolved = outcome
	state = S.FREED if outcome == "freed" else S.DOWN
	resonance = 0.0
	_t = 0.12
	remove_from_group("strikable")
	visible = outcome == "freed"
	queue_redraw()
