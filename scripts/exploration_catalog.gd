extends RefCounted
## Authored return seams, separate from the planned development atlas. These
## four impressions add two bidirectional links between existing rooms.

static func reward() -> Dictionary:
	return {"id": &"jump_cut", "room_id": &"verse_warren_n", "position": Vector2(350, 834)}

static func endpoints() -> Array[Dictionary]:
	return [
		{"id": &"warren_return", "room_id": &"verse_warren_n", "position": Vector2(1300, 454),
			"far_end": true, "target_room": &"high_street", "target_entry": &"from_verse_warren_n", "destination": "High Street"},
		{"id": &"warren_return", "room_id": &"high_street", "position": Vector2(370, 574),
			"far_end": false, "target_room": &"verse_warren_n", "target_entry": &"from_high_street", "destination": "The North Warren"},
		{"id": &"gallery_return", "room_id": &"deep_gallery", "position": Vector2(900, 834),
			"far_end": true, "target_room": &"headshell", "target_entry": &"from_deep_gallery", "destination": "The Headshell"},
		{"id": &"gallery_return", "room_id": &"headshell", "position": Vector2(635, 554),
			"far_end": false, "target_room": &"deep_gallery", "target_entry": &"from_headshell", "destination": "The Deep Gallery"},
	]

static func endpoints_for(room_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for endpoint in endpoints():
		if endpoint.room_id == room_id:
			result.append(endpoint)
	return result

static func definition(room_id: StringName, id: StringName) -> Dictionary:
	if id == &"jump_cut" and room_id == reward().room_id:
		return reward()
	for endpoint in endpoints_for(room_id):
		if endpoint.id == id:
			return endpoint
	return {}
