extends RefCounted
## Fixed equipment finds in the authored world. The catalog owns no rewards,
## saves, collision or permission state.

static func entries() -> Array[Dictionary]:
	return [
		{"id": &"copper_stylus", "room_id": &"the_stalls", "position": Vector2(1550, 454),
			"requirement": "groove", "clue": "Ride the Stalls' warm groove.\nSearch the first eastern shutter."},
		{"id": &"seam_lining", "room_id": &"horn_plaza", "position": Vector2(500, 374),
			"requirement": "gather", "clue": "A high seam overlooks the homeward door.\nReturn with a breath held in the air."},
		{"id": &"dusk_seal", "room_id": &"addie", "position": Vector2(1080, 574),
			"requirement": "jump_cut", "clue": "Beyond Addie's door, a seal faces inward.\nTurn the wax to read its other face."},
	]

static func for_room(room_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries():
		if entry.room_id == room_id:
			result.append(entry)
	return result

static func definition(room_id: StringName, id: StringName) -> Dictionary:
	for entry in for_room(room_id):
		if entry.id == id:
			return entry
	return {}
