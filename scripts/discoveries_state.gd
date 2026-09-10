extends RefCounted
## Carried discoveries, owned by Main. Stations and the Book only read this
## model; Main validates interactions, saves the change, then presents it.

const EMPTY := {"echo_spool": "missing", "survey_slip": false}
const INTERACT_RADIUS := 76.0
const STAGES := ["missing", "empty", "recorded", "restored"]
const ACTION_ROOMS := {
	&"collect_spool": &"deep_gallery",
	&"record_phrase": &"verse_warren_s",
	&"restore_warren": &"verse_warren_n",
	&"collect_survey": &"the_landing",
}

var _echo_spool := "missing"
var _survey_slip := false

func snapshot() -> Dictionary:
	return {"echo_spool": _echo_spool, "survey_slip": _survey_slip}

func reset() -> void:
	_echo_spool = "missing"
	_survey_slip = false

static func valid_snapshot(data: Variant) -> bool:
	return (data is Dictionary and data.size() == 2
		and data.get("echo_spool") is String and data.get("echo_spool") in STAGES
		and data.get("survey_slip") is bool)

func restore_snapshot(data: Variant) -> bool:
	if not valid_snapshot(data):
		return false
	_echo_spool = data.echo_spool
	_survey_slip = data.survey_slip
	return true

static func action_room(action: StringName) -> StringName:
	return ACTION_ROOMS.get(action, &"")

func can_apply(action: StringName) -> bool:
	match action:
		&"collect_spool": return _echo_spool == "missing"
		&"record_phrase": return _echo_spool == "empty"
		&"restore_warren": return _echo_spool == "recorded"
		&"collect_survey": return not _survey_slip
	return false

func apply(action: StringName) -> bool:
	if not can_apply(action):
		return false
	match action:
		&"collect_spool": _echo_spool = "empty"
		&"record_phrase": _echo_spool = "recorded"
		&"restore_warren": _echo_spool = "restored"
		&"collect_survey": _survey_slip = true
	return true
