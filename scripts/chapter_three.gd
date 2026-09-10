extends RefCounted
## The first authored rooms beneath the seal: a descent, a landing, and the
## western Unplayed loop. Planned rooms beyond the Gallery remain in the atlas.

const UnplayedScript := preload("res://scripts/room_unplayed_campaign.gd")
const START_ROOM: StringName = &"the_drop"
const END_ROOM: StringName = &"deep_gallery"
const IDS: Array[StringName] = [
	&"the_drop", &"the_landing", &"verse_hall",
	&"verse_warren_n", &"verse_warren_s", &"deep_gallery",
]

static func has_room(id: StringName) -> bool:
	return id in IDS

static func room_ids() -> Array[StringName]:
	return IDS.duplicate()

static func create_room(id: StringName) -> Node2D:
	if not has_room(id):
		return null
	var next_room := UnplayedScript.new()
	next_room.configure(id)
	return next_room
