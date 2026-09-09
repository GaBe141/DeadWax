extends "res://scripts/room_exit.gd"
## A passage held by an encounter, reading the Main-owned outcome dictionary.
## This never discovers a technique or changes the record it reads.

var session_outcomes: Dictionary = {}
var required_outcome_key := ""
var required_outcomes: Array[String] = []
var gate_label := "HELD CLOSED"

func is_locked() -> bool:
	return not String(session_outcomes.get(required_outcome_key, "")) in required_outcomes

func _refresh_label() -> void:
	if _label == null:
		return
	if is_locked():
		_label.text = "%s\n%s" % [display_name, gate_label]
	elif _near:
		_label.text = "%s\n[E / Y] ENTER" % display_name
	else:
		_label.text = display_name
	_label.modulate.a = 1.0 if _near else 0.78
