extends RefCounted
## The folded guide describes only authored campaign rooms and their passages.
## Pure data: safe for map/save models without loading scenes or room factories.
## Positions belong to a region's sheet. The Drop shares the Unplayed page as
## its approach; this guide grouping does not replace its Scratch stratum.

const EXTENT := Vector2(1000, 430)
const ROOM_SIZE := Vector2(174, 64)
const REGIONS := [
	{"id": &"label", "title": "THE LABEL"},
	{"id": &"overture", "title": "THE OVERTURE"},
	{"id": &"unplayed", "title": "THE UNPLAYED"},
]
const ROOMS := [
	{"id": &"headshell", "region": &"label", "label": "The Headshell", "title": "HEADSHELL", "position": Vector2(145, 205)},
	{"id": &"horn_plaza", "region": &"label", "label": "The Horn Plaza", "title": "HORN PLAZA", "position": Vector2(365, 205)},
	{"id": &"high_street", "region": &"label", "label": "The High Street", "title": "HIGH STREET", "position": Vector2(365, 75)},
	{"id": &"practice_room", "region": &"label", "label": "The Practice Room", "title": "PRACTICE\nROOM", "position": Vector2(585, 75)},
	{"id": &"the_stalls", "region": &"label", "label": "The Stalls", "title": "THE STALLS", "position": Vector2(585, 205)},
	{"id": &"groove_yard", "region": &"label", "label": "The Locked-Groove Yard", "title": "LOCKED-GROOVE\nYARD", "position": Vector2(805, 205)},
	{"id": &"label_descent", "region": &"label", "label": "The Descent Gate", "title": "DESCENT\nGATE", "position": Vector2(805, 350)},
	{"id": &"overture_stair", "region": &"overture", "label": "The Overture Stair", "title": "OVERTURE\nSTAIR", "position": Vector2(165, 75)},
	{"id": &"bootlegger", "region": &"overture", "label": "The Bootlegger's Stall", "title": "BOOTLEGGER", "position": Vector2(385, 75)},
	{"id": &"whistlers", "region": &"overture", "label": "The Whistlers", "title": "WHISTLERS", "position": Vector2(605, 75)},
	{"id": &"addie", "region": &"overture", "label": "Addie's Doorway", "title": "ADDIE'S\nDOORWAY", "position": Vector2(825, 75)},
	{"id": &"overture_well", "region": &"overture", "label": "The Overture Well", "title": "OVERTURE\nWELL", "position": Vector2(825, 220)},
	{"id": &"worn_gallery", "region": &"overture", "label": "The Worn Gallery", "title": "WORN\nGALLERY", "position": Vector2(605, 220)},
	{"id": &"smoothed_floor", "region": &"overture", "label": "The Smoothed Floor", "title": "SMOOTHED\nFLOOR", "position": Vector2(385, 220)},
	{"id": &"the_arm", "region": &"overture", "label": "The Arm", "title": "THE ARM", "position": Vector2(385, 355)},
	{"id": &"the_drop", "region": &"unplayed", "label": "The Drop", "title": "THE DROP", "position": Vector2(165, 95)},
	{"id": &"the_landing", "region": &"unplayed", "label": "The Landing", "title": "THE LANDING", "position": Vector2(385, 95)},
	{"id": &"verse_hall", "region": &"unplayed", "label": "The Verse Hall", "title": "VERSE HALL", "position": Vector2(605, 95)},
	{"id": &"verse_warren_n", "region": &"unplayed", "label": "North Warren", "title": "NORTH WARREN", "position": Vector2(825, 95)},
	{"id": &"deep_gallery", "region": &"unplayed", "label": "The Deep Gallery", "title": "DEEP GALLERY", "position": Vector2(825, 290)},
	{"id": &"verse_warren_s", "region": &"unplayed", "label": "South Warren", "title": "SOUTH WARREN", "position": Vector2(605, 290)},
]
## A border marker represents only the real passage leading off this sheet.
const BOUNDARIES := [
	{"region": &"label", "id": &"overture_stair", "position": Vector2(805, 408)},
	{"region": &"label", "id": &"worn_gallery", "position": Vector2(365, 350)},
	{"region": &"overture", "id": &"label_descent", "position": Vector2(165, 220)},
	{"region": &"overture", "id": &"the_stalls", "position": Vector2(605, 355)},
	{"region": &"overture", "id": &"the_drop", "position": Vector2(165, 355)},
	{"region": &"unplayed", "id": &"the_arm", "position": Vector2(165, 290)},
	{"region": &"label", "id": &"verse_warren_n", "position": Vector2(145, 75), "route_id": "warren_return"},
	{"region": &"label", "id": &"deep_gallery", "position": Vector2(145, 350), "route_id": "gallery_return"},
	{"region": &"unplayed", "id": &"high_street", "position": Vector2(825, 25), "route_id": "warren_return"},
	{"region": &"unplayed", "id": &"headshell", "position": Vector2(825, 405), "route_id": "gallery_return"},
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
	{"a": &"the_arm", "b": &"the_drop", "shortcut": false},
	{"a": &"the_drop", "b": &"the_landing", "shortcut": false},
	{"a": &"the_landing", "b": &"verse_hall", "shortcut": false},
	{"a": &"verse_hall", "b": &"verse_warren_n", "shortcut": false},
	{"a": &"verse_warren_n", "b": &"deep_gallery", "shortcut": false},
	{"a": &"deep_gallery", "b": &"verse_warren_s", "shortcut": false},
	{"a": &"verse_warren_s", "b": &"verse_warren_n", "shortcut": false},
	{"a": &"verse_warren_n", "b": &"high_street", "shortcut": true, "route_id": "warren_return"},
	{"a": &"deep_gallery", "b": &"headshell", "shortcut": true, "route_id": "gallery_return"},
]

static func region_for_room(id: StringName) -> StringName:
	for room in ROOMS:
		if room.id == id:
			return room.region
	return &"label"

static func region_title(id: StringName) -> String:
	for region in REGIONS:
		if region.id == id:
			return region.title
	return ""

static func page_snapshot(region: StringName, visited: Array, current: StringName, opened: Array = []) -> Dictionary:
	var known: Dictionary = {}
	for id in visited:
		known[StringName(id)] = true
	known[current] = true
	var visible_returns: Dictionary = {}
	for link in LINKS:
		var route_id := String(link.get("route_id", ""))
		if not route_id.is_empty() and (route_id in opened or (known.has(link.a) and known.has(link.b))):
			visible_returns[route_id] = true
	var page := {"rooms": [], "links": [], "boundaries": []}
	var centers: Dictionary = {}
	var local_ids: Array[StringName] = []
	for room in ROOMS:
		if room.region != region:
			continue
		local_ids.append(room.id)
		centers[room.id] = room.position
		page.rooms.append({"id": room.id, "position": room.position,
			"title": room.title if known.has(room.id) else "",
			"visited": known.has(room.id), "here": room.id == current})
	for boundary in BOUNDARIES:
		if boundary.region != region:
			continue
		var route_id := String(boundary.get("route_id", ""))
		if not route_id.is_empty() and not visible_returns.has(route_id):
			continue
		var is_open := route_id in opened
		var title := "TO " + region_title(region_for_room(boundary.id))
		if not route_id.is_empty():
			title = "RETURN TO " + region_title(region_for_room(boundary.id)) if is_open else "BACK OF THE WAX"
		centers[boundary.id] = boundary.position
		page.boundaries.append({"id": boundary.id, "position": boundary.position,
			"title": title, "visited": known.has(boundary.id), "route_id": route_id, "open": is_open})
	for link in LINKS:
		var route_id := String(link.get("route_id", ""))
		if not route_id.is_empty() and not visible_returns.has(route_id):
			continue
		if (link.a in local_ids or link.b in local_ids) and centers.has(link.a) and centers.has(link.b):
			page.links.append({"a": link.a, "b": link.b, "from": centers[link.a], "to": centers[link.b],
				"shortcut": link.shortcut, "walked": known.has(link.a) and known.has(link.b),
				"route_id": route_id, "open": route_id in opened})
	return page

static func return_ids() -> Array[String]:
	var result: Array[String] = []
	for link in LINKS:
		if link.has("route_id"):
			result.append(String(link.route_id))
	return result

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
