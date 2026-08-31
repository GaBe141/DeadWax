extends RefCounted
## Runtime reader for the planned world in data/world_map.json.
##
## The planning map owns topology and presentation only: where rooms sit on the
## grid, which edges touch, and what a special route asks of the player.
## Geometry, air, and gameplay stay with whatever builds the room.
##
## Contact resolution mirrors the routing model the smoke suite locks: a
## declared special replaces the open contact for that pair, and a one-way
## special is never walked back from its target.

const DEFAULT_PATH := "res://data/world_map.json"
const SCHEMA_VERSION := 2

const SIDE_NORTH := &"north"
const SIDE_SOUTH := &"south"
const SIDE_EAST := &"east"
const SIDE_WEST := &"west"

const KIND_CONTACT := &"contact"
const SPECIAL_KINDS := [&"gate", &"shortcut", &"story", &"secret"]

const REFRAIN_PREFIX := "refrain:"
const TECHNIQUE_PREFIX := "tech:"

var grid_cell := 0
var room_order: Array[StringName] = []
var stratum_order: Array[StringName] = []

var _rooms: Dictionary = {}
var _strata: Dictionary = {}
var _routes: Dictionary = {}

# -- loading ------------------------------------------------------------------

func load_from(path: String = DEFAULT_PATH) -> bool:
	_rooms.clear()
	_strata.clear()
	_routes.clear()
	room_order.clear()
	stratum_order.clear()
	grid_cell = 0

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("World map '%s' could not be opened." % path)
		return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_error(
			"World map '%s' failed to parse (line %d: %s)."
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return false

	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		push_error("World map '%s' root is not an object." % path)
		return false
	var world: Dictionary = parsed
	if int(world.get("version", 0)) != SCHEMA_VERSION:
		push_error("World map '%s' is not schema version %d." % [path, SCHEMA_VERSION])
		return false

	grid_cell = int(world.get("grid_cell", 0))
	if grid_cell <= 0:
		push_error("World map '%s' has a non-positive grid_cell." % path)
		return false

	var strata_value: Variant = world.get("strata", [])
	var rooms_value: Variant = world.get("rooms", [])
	if not (strata_value is Array) or not (rooms_value is Array):
		push_error("World map '%s' strata and rooms must be arrays." % path)
		return false

	for stratum_value in strata_value as Array:
		if not (stratum_value is Dictionary):
			continue
		var stratum_data: Dictionary = stratum_value
		var stratum_id := StringName(stratum_data.get("id", ""))
		if stratum_id.is_empty() or _strata.has(stratum_id):
			continue
		_strata[stratum_id] = stratum_data
		stratum_order.append(stratum_id)

	for room_value in rooms_value as Array:
		if not (room_value is Dictionary):
			continue
		var room_data: Dictionary = room_value
		var id := StringName(room_data.get("id", ""))
		if id.is_empty() or _rooms.has(id):
			continue
		_rooms[id] = room_data
		room_order.append(id)

	if _rooms.is_empty():
		push_error("World map '%s' declares no rooms." % path)
		return false

	_build_routes()
	return true

# -- queries ------------------------------------------------------------------

func room_count() -> int:
	return room_order.size()

func has_room(id: StringName) -> bool:
	return _rooms.has(id)

func room(id: StringName) -> Dictionary:
	return _rooms.get(id, {})

func has_stratum(id: StringName) -> bool:
	return _strata.has(id)

func stratum(id: StringName) -> Dictionary:
	return _strata.get(id, {})

func stratum_for_room(id: StringName) -> Dictionary:
	return stratum(StringName(room(id).get("stratum", "")))

func room_name(id: StringName) -> String:
	return String(room(id).get("name", String(id)))

func room_bounds(id: StringName) -> Rect2:
	var data := room(id)
	if data.is_empty():
		return Rect2()
	return Rect2(
		float(data.get("x", 0.0)),
		float(data.get("y", 0.0)),
		float(data.get("w", 0.0)),
		float(data.get("h", 0.0))
	)

func spawn_room_id() -> StringName:
	for id in room_order:
		if "spawn" in Array(room(id).get("tags", [])):
			return id
	return room_order[0] if not room_order.is_empty() else &""

## Every route leaving `id`, as dictionaries carrying:
##   to, side, span (Vector2 of shared grid range), kind, requires, label.
## Open contacts and traversable specials are returned together; the caller
## decides how each kind is presented.
func routes_from(id: StringName) -> Array:
	return _routes.get(id, [])

## The canonical refrain requirement of a route, or an empty string when the
## route asks for a technique or nothing at all. Techniques are execution
## challenges, never permissions, so they are deliberately not returned here.
static func required_refrain_key(requires: Array) -> String:
	for requirement_value in requires:
		var requirement := String(requirement_value)
		if requirement.begins_with(REFRAIN_PREFIX):
			return requirement.substr(REFRAIN_PREFIX.length())
	return ""

## The canonical technique a route asks the player to perform, or an empty
## string. Naming it lets a passage read as a challenge without gating entry.
static func required_technique_key(requires: Array) -> String:
	for requirement_value in requires:
		var requirement := String(requirement_value)
		if requirement.begins_with(TECHNIQUE_PREFIX):
			return requirement.substr(TECHNIQUE_PREFIX.length())
	return ""

static func opposite_side(side: StringName) -> StringName:
	match side:
		SIDE_NORTH:
			return SIDE_SOUTH
		SIDE_SOUTH:
			return SIDE_NORTH
		SIDE_EAST:
			return SIDE_WEST
		SIDE_WEST:
			return SIDE_EAST
	return side

# -- topology -----------------------------------------------------------------

func _build_routes() -> void:
	for id in room_order:
		_routes[id] = []

	var special_pairs := {}
	for id in room_order:
		for special in _specials_of(id):
			special_pairs[_pair_key(id, StringName(special.get("to", "")))] = true

	# Open contacts: every touching pair the plan does not describe as special.
	for left_index in room_order.size():
		var left_id := room_order[left_index]
		for right_index in range(left_index + 1, room_order.size()):
			var right_id := room_order[right_index]
			if special_pairs.has(_pair_key(left_id, right_id)):
				continue
			var side := contact_side(left_id, right_id)
			if side.is_empty():
				continue
			_append_route(left_id, right_id, side, KIND_CONTACT, [], "")
			_append_route(right_id, left_id, opposite_side(side), KIND_CONTACT, [], "")

	# Specials: traversable from their source, and back only when bidirectional.
	for id in room_order:
		for special in _specials_of(id):
			var target := StringName(special.get("to", ""))
			if not _rooms.has(target):
				continue
			var side := contact_side(id, target)
			if side.is_empty():
				continue
			var kind := StringName(special.get("kind", ""))
			var requires: Array = special.get("requires", [])
			var label := String(special.get("label", ""))
			_append_route(id, target, side, kind, requires, label)
			if String(special.get("direction", "")) == "bidirectional":
				_append_route(target, id, opposite_side(side), kind, requires, label)

## The side of `from_id` that `to_id` sits against, or an empty name when the
## two rooms do not share an edge. Grid y grows downward: deeper is south.
func contact_side(from_id: StringName, to_id: StringName) -> StringName:
	var from_rect := room_bounds(from_id)
	var to_rect := room_bounds(to_id)
	if from_rect.size == Vector2.ZERO or to_rect.size == Vector2.ZERO:
		return &""
	var horizontal_overlap := (
		maxf(from_rect.position.x, to_rect.position.x)
		< minf(from_rect.end.x, to_rect.end.x)
	)
	var vertical_overlap := (
		maxf(from_rect.position.y, to_rect.position.y)
		< minf(from_rect.end.y, to_rect.end.y)
	)
	if vertical_overlap:
		if is_equal_approx(from_rect.end.x, to_rect.position.x):
			return SIDE_EAST
		if is_equal_approx(to_rect.end.x, from_rect.position.x):
			return SIDE_WEST
	if horizontal_overlap:
		if is_equal_approx(from_rect.end.y, to_rect.position.y):
			return SIDE_SOUTH
		if is_equal_approx(to_rect.end.y, from_rect.position.y):
			return SIDE_NORTH
	return &""

## The grid range the two rooms share along their contact edge.
func contact_span(from_id: StringName, to_id: StringName, side: StringName) -> Vector2:
	var from_rect := room_bounds(from_id)
	var to_rect := room_bounds(to_id)
	if side == SIDE_EAST or side == SIDE_WEST:
		return Vector2(
			maxf(from_rect.position.y, to_rect.position.y),
			minf(from_rect.end.y, to_rect.end.y)
		)
	return Vector2(
		maxf(from_rect.position.x, to_rect.position.x),
		minf(from_rect.end.x, to_rect.end.x)
	)

func _specials_of(id: StringName) -> Array:
	var specials_value: Variant = room(id).get("specials", [])
	if not (specials_value is Array):
		return []
	var result: Array = []
	for special_value in specials_value as Array:
		if special_value is Dictionary:
			result.append(special_value)
	return result

func _append_route(
	from_id: StringName,
	to_id: StringName,
	side: StringName,
	kind: StringName,
	requires: Array,
	label: String
) -> void:
	var routes: Array = _routes[from_id]
	routes.append({
		"to": to_id,
		"side": side,
		"span": contact_span(from_id, to_id, side),
		"kind": kind,
		"requires": requires.duplicate(),
		"label": label,
	})

func _pair_key(left_id: StringName, right_id: StringName) -> String:
	var ids := [String(left_id), String(right_id)]
	ids.sort()
	return "%s|%s" % ids
