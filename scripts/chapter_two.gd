extends RefCounted
## The authored descent through the Overture, kept separate from its map shells.

const OvertureScript := preload("res://scripts/room_overture.gd")
const START_ROOM: StringName = &"bootlegger"
const END_ROOM: StringName = &"the_arm"
const IDS: Array[StringName] = [
	&"bootlegger", &"whistlers", &"addie", &"overture_well",
	&"worn_gallery", &"smoothed_floor", &"the_arm",
]

static func has_room(id: StringName) -> bool:
	return id in IDS

static func room_ids() -> Array[StringName]:
	return IDS.duplicate()

static func create_room(id: StringName) -> Node2D:
	if not has_room(id):
		return null
	var next_room := OvertureScript.new()
	next_room.configure(id)
	return next_room
