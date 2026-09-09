extends RefCounted
## The authored opening. This registry is deliberately separate from both the
## five practice rooms and the complete map's unauthored shells.

const OpeningScript := preload("res://scripts/room_opening.gd")
const START_ROOM: StringName = &"headshell"
const END_ROOM: StringName = &"overture_stair"
const IDS: Array[StringName] = [
	&"headshell", &"horn_plaza", &"high_street", &"practice_room",
	&"the_stalls", &"groove_yard", &"label_descent", &"overture_stair",
]

static func has_room(id: StringName) -> bool:
	return id in IDS

static func room_ids() -> Array[StringName]:
	return IDS.duplicate()

static func create_room(id: StringName) -> Node2D:
	if not has_room(id):
		return null
	var next_room := OpeningScript.new()
	next_room.configure(id)
	return next_room
