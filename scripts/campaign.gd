extends RefCounted
## Authored campaign only. The two chapter factories retain their own rooms;
## development shells and prototype rooms are never fallback destinations.

const LabelChapter := preload("res://scripts/chapter_one.gd")
const OvertureChapter := preload("res://scripts/chapter_two.gd")
const START_ROOM: StringName = LabelChapter.START_ROOM
const END_ROOM: StringName = &"the_arm"
const FINAL_ENCOUNTER := "the_arm/tonearm"

static func room_ids() -> Array[StringName]:
	var ids := LabelChapter.room_ids()
	ids.append_array(OvertureChapter.room_ids())
	return ids

static func has_room(id: StringName) -> bool:
	return LabelChapter.has_room(id) or OvertureChapter.has_room(id)

static func create_room(id: StringName) -> Node2D:
	if LabelChapter.has_room(id):
		return LabelChapter.create_room(id)
	return OvertureChapter.create_room(id)

static func encounter_resolved(outcomes: Dictionary) -> bool:
	return String(outcomes.get(FINAL_ENCOUNTER, "")) in ["freed", "shattered"]

## v1 opening saves used 'completed' for reaching the Overture Stair. The
## extended ending requires the Tonearm outcome too; existing progress stays.
static func saved_completion(data: Dictionary) -> bool:
	return bool(data.get("completed", false)) and encounter_resolved(data.get("encounters", {}))

static func chapter_label(id: StringName) -> String:
	return "THE OVERTURE" if OvertureChapter.has_room(id) or id == &"overture_stair" else "THE LABEL"
