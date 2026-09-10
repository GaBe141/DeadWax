extends RefCounted
## The folded guide describes only authored campaign rooms and their passages.
## Pure data: safe for map/save models without loading scenes or room factories.

const EXTENT := Vector2(1180, 520)
const ROOM_SIZE := Vector2(166, 64)
const ROOMS := [
	{"id": &"headshell", "label": "The Headshell", "title": "HEADSHELL", "position": Vector2(110, 200)},
	{"id": &"horn_plaza", "label": "The Horn Plaza", "title": "HORN PLAZA", "position": Vector2(300, 200)},
	{"id": &"high_street", "label": "The High Street", "title": "HIGH STREET", "position": Vector2(110, 70)},
	{"id": &"practice_room", "label": "The Practice Room", "title": "PRACTICE\nROOM", "position": Vector2(300, 70)},
	{"id": &"the_stalls", "label": "The Stalls", "title": "THE STALLS", "position": Vector2(490, 200)},
	{"id": &"groove_yard", "label": "The Locked-Groove Yard", "title": "LOCKED-GROOVE\nYARD", "position": Vector2(680, 200)},
	{"id": &"label_descent", "label": "The Descent Gate", "title": "DESCENT\nGATE", "position": Vector2(870, 200)},
	{"id": &"overture_stair", "label": "The Overture Stair", "title": "OVERTURE\nSTAIR", "position": Vector2(1060, 200)},
	{"id": &"bootlegger", "label": "The Bootlegger's Stall", "title": "BOOTLEGGER", "position": Vector2(1060, 355)},
	{"id": &"whistlers", "label": "The Whistlers", "title": "WHISTLERS", "position": Vector2(870, 355)},
	{"id": &"addie", "label": "Addie's Doorway", "title": "ADDIE'S\nDOORWAY", "position": Vector2(680, 355)},
	{"id": &"overture_well", "label": "The Overture Well", "title": "OVERTURE\nWELL", "position": Vector2(490, 355)},
	{"id": &"worn_gallery", "label": "The Worn Gallery", "title": "WORN\nGALLERY", "position": Vector2(300, 355)},
	{"id": &"smoothed_floor", "label": "The Smoothed Floor", "title": "SMOOTHED\nFLOOR", "position": Vector2(110, 355)},
	{"id": &"the_arm", "label": "The Arm", "title": "THE ARM", "position": Vector2(110, 465)},
]
const LINKS := [
	{"a": &"headshell", "b": &"horn_plaza", "shortcut": false},
	{"a": &"horn_plaza", "b": &"high_street", "shortcut": false},
	{"a": &"high_street", "b": &"practice_room", "shortcut": false},
	{"a": &"practice_room", "b": &"horn_plaza", "shortcut": false},
	{"a": &"horn_plaza", "b": &"the_stalls", "shortcut": false},
	{"a": &"the_stalls", "b": &"groove_yard", "shortcut": false},
	{"a": &"groove_yard", "b": &"label_descent", "shortcut": false},
	{"a": &"label_descent", "b": &"overture_stair", "shortcut": false},
	{"a": &"overture_stair", "b": &"bootlegger", "shortcut": false},
	{"a": &"bootlegger", "b": &"whistlers", "shortcut": false},
	{"a": &"whistlers", "b": &"addie", "shortcut": false},
	{"a": &"addie", "b": &"overture_well", "shortcut": false},
	{"a": &"overture_well", "b": &"worn_gallery", "shortcut": false},
	{"a": &"worn_gallery", "b": &"smoothed_floor", "shortcut": false},
	{"a": &"smoothed_floor", "b": &"the_arm", "shortcut": false},
	{"a": &"worn_gallery", "b": &"the_arm", "shortcut": true},
	{"a": &"the_stalls", "b": &"worn_gallery", "shortcut": true},
]

static func room_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for room in ROOMS:
		ids.append(room.id)
	return ids

static func room_label(id: StringName) -> String:
	for room in ROOMS:
		if room.id == id:
			return room.label
	return ""

static func rooms() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for room in ROOMS:
		result.append(room.duplicate(true))
	return result

static func links() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for link in LINKS:
		result.append(link.duplicate(true))
	return result
