extends RefCounted
## The carried map and its pencil marks. Main owns visits and persistence;
## neither this state nor the map view grants traversal or moves the player.

const Chart := preload("res://scripts/campaign_chart.gd")

var owned := false
var visited: Array[String] = []

func collect() -> bool:
	if owned:
		return false
	owned = true
	return true

func visit(room_id: StringName) -> bool:
	if room_id not in Chart.room_ids() or String(room_id) in visited:
		return false
	visited.append(String(room_id))
	return true

func reset() -> void:
	owned = false
	visited.clear()

func snapshot() -> Dictionary:
	return {"owned": owned, "visited": visited.duplicate()}

func restore_snapshot(data: Dictionary) -> bool:
	if not valid_snapshot(data):
		return false
	owned = data.owned
	visited.assign(data.visited)
	return true

static func valid_snapshot(data: Variant) -> bool:
	if not (data is Dictionary) or data.size() != 2 or not (data.get("owned") is bool):
		return false
	var rooms: Variant = data.get("visited")
	if not (rooms is Array) or rooms.size() > Chart.room_ids().size():
		return false
	var seen: Array[String] = []
	for id in rooms:
		if not (id is String) or StringName(id) not in Chart.room_ids() or id in seen:
			return false
		seen.append(id)
	return true
