extends "res://scripts/room_base.gd"
## A traversable graybox built from one entry in the planned world map.
##
## This is structure, not design: the room's footprint, its stratum's air and
## palette, and one passage per planned route. Hand-authored rooms always win —
## Main only grays a room in when no bespoke script claims its id. Every
## measurement below is derived from Skip's plain jump so a graybox is walkable
## with no Refrain carried.

const ProgressionScript := preload("res://scripts/progression_state.gd")
const WorldMapScript := preload("res://scripts/world_map.gd")
# RefrainPickupScript, and the rest of the build helpers, come from room_base.

# -- footprint ----------------------------------------------------------------
const CELL_W := 600.0
const CELL_H := 360.0
const WALL := 60.0

# -- climb sizing -------------------------------------------------------------
## A ladder of two columns one RUNG_RUN apart. Rungs never overhang each other,
## so every hop is a plain jump sideways-and-up and no rung traps the player
## under the one above it. Skip rises ~124 px and covers ~200 px of ground
## while above a 70 px rise, which is the margin these numbers keep.
const RUNG_RISE := 70.0
const RUNG_RUN := 180.0
const RUNG_SIZE := Vector2(170.0, 24.0)

# -- portal placement ---------------------------------------------------------
const PORTAL_INSET := 90.0         # how far a side passage sits off its wall
const NORTH_PORTAL_TOP := 150.0    # landing height for a passage leaving upward
const EXIT_STAND_OFFSET := 35.0    # marker height above its landing
const ENTRY_STAND_OFFSET := 26.0   # Skip's half-height, so arrivals stand clean
const ARRIVAL_INSET := 96.0        # arrivals land inside the room, not in the door

# -- dressing -----------------------------------------------------------------
const NOTE_INSET := 130.0
const NOTE_TOP := 70.0
const NOTE_WIDTH := 520.0

# -- rewards ------------------------------------------------------------------
const REWARD_LIFT := 44.0          # pickup height above its plinth
const REWARD_SPACING := 260.0      # gap between plinths, and the shift step
const REWARD_CLEARANCE := 24.0     # margin beyond a pickup's own collect radius
const REWARD_SHIFT_TRIES := 6

## Air and weight per stratum. The Scratch is the boundary the fiction names:
## above it wax is spent and your strike only speaks to live grooves; below it
## the unplayed sound pools thick enough to swim.
const STRATUM_AIR := {
	&"label": {"density": 0.0, "strikes": 0, "gravity": 1.0, "fall_cap": 1.0, "groove": 1.0},
	&"overture": {"density": 0.25, "strikes": 1, "gravity": 1.0, "fall_cap": 0.9, "groove": 1.1},
	&"scratch": {"density": 0.6, "strikes": 1, "gravity": 0.9, "fall_cap": 0.75, "groove": 1.2},
	&"unplayed": {"density": 1.0, "strikes": 2, "gravity": 0.8, "fall_cap": 0.62, "groove": 1.3},
	&"undersong": {"density": 1.0, "strikes": 2, "gravity": 0.72, "fall_cap": 0.55, "groove": 1.35},
	&"deadwax": {"density": 0.85, "strikes": 2, "gravity": 0.85, "fall_cap": 0.68, "groove": 1.25},
}
const DEFAULT_AIR := {"density": 0.0, "strikes": 0, "gravity": 1.0, "fall_cap": 1.0, "groove": 1.0}

var world_id: StringName
var stratum_id: StringName
var room_size := Vector2.ZERO
var portals: Dictionary = {}

var _map: RefCounted

## Reads one planned room into this instance. Call before adding to the tree:
## Main injects progression first, then _ready builds the geometry.
func configure(map: RefCounted, id: StringName) -> bool:
	if map == null or not bool(map.call("has_room", id)):
		push_error("Graybox room '%s' is not in the world map." % id)
		return false
	_map = map
	world_id = id
	room_id = id

	var data: Dictionary = map.call("room", id)
	stratum_id = StringName(data.get("stratum", ""))
	var bounds: Rect2 = map.call("room_bounds", id)
	room_size = Vector2(bounds.size.x * CELL_W, bounds.size.y * CELL_H)

	band_name = String(data.get("name", String(id)))
	band_desc = String(data.get("notes", ""))
	_apply_stratum(map)
	_build_portals(map, bounds)

	spawn_pos = Vector2(room_size.x * 0.5, room_size.y - ENTRY_STAND_OFFSET)
	death_y = room_size.y + 500.0
	cam_limits = Rect2(-WALL * 2.0, -WALL * 2.0, room_size.x + WALL * 4.0, room_size.y + WALL * 4.0)
	return true

func _ready() -> void:
	if _map == null:
		return
	_build_shell()
	for target_value in portals:
		_build_portal(portals[target_value])
	_build_room_notes()

# -- configuration ------------------------------------------------------------

func _apply_stratum(map: RefCounted) -> void:
	var air: Dictionary = STRATUM_AIR.get(stratum_id, DEFAULT_AIR)
	air_density = float(air["density"])
	air_strikes_max = int(air["strikes"])
	gravity_mult = float(air["gravity"])
	fall_cap_mult = float(air["fall_cap"])
	groove_mult = float(air["groove"])

	var stratum: Dictionary = map.call("stratum_for_room", world_id)
	bg_color = Color(String(stratum.get("color", "#d9d5cc")))
	ink = Color(String(stratum.get("ink", "#26221e")))

## One portal per neighbouring room, carrying whichever directions exist: an
## outgoing route becomes a passage, an incoming one becomes a named arrival.
## A one-way plan route therefore yields a door on one side and an anchor on
## the other, which is exactly what the map describes.
func _build_portals(map: RefCounted, bounds: Rect2) -> void:
	portals.clear()
	for id in map.get("room_order") as Array:
		var neighbour := StringName(id)
		if neighbour == world_id:
			continue
		var side: StringName = map.call("contact_side", world_id, neighbour)
		if side.is_empty():
			continue
		portals[neighbour] = {
			"to": neighbour,
			"side": side,
			"position": _portal_position(map, bounds, neighbour, side),
			"outgoing": null,
			"incoming": false,
		}

	for route_value in map.call("routes_from", world_id):
		var route: Dictionary = route_value
		var target := StringName(route.get("to"))
		if portals.has(target):
			var portal: Dictionary = portals[target]
			portal["outgoing"] = route

	for id in map.get("room_order") as Array:
		var source := StringName(id)
		if not portals.has(source):
			continue
		for route_value in map.call("routes_from", source):
			var route: Dictionary = route_value
			if StringName(route.get("to")) == world_id:
				var portal: Dictionary = portals[source]
				portal["incoming"] = true

	for target_value in portals:
		var portal: Dictionary = portals[target_value]
		if bool(portal["incoming"]):
			register_entry(_entry_id(StringName(portal["to"])), _arrival_position(portal))

## The landing point for a portal, in room-local pixels. Side passages sit at
## the foot of the edge the two rooms actually share, so a room that only
## touches its neighbour high up gets a climb rather than a ground-floor door.
func _portal_position(
	map: RefCounted,
	bounds: Rect2,
	neighbour: StringName,
	side: StringName
) -> Vector2:
	var span: Vector2 = map.call("contact_span", world_id, neighbour, side)
	if side == WorldMapScript.SIDE_EAST or side == WorldMapScript.SIDE_WEST:
		var landing_top := clampf(
			(span.y - bounds.position.y) * CELL_H, NORTH_PORTAL_TOP, room_size.y
		)
		var x := room_size.x - PORTAL_INSET if side == WorldMapScript.SIDE_EAST else PORTAL_INSET
		return Vector2(x, landing_top)
	var mid_x := ((span.x + span.y) * 0.5 - bounds.position.x) * CELL_W
	var landing_x := clampf(mid_x, PORTAL_INSET, maxf(room_size.x - PORTAL_INSET, PORTAL_INSET))
	if side == WorldMapScript.SIDE_SOUTH:
		return Vector2(landing_x, room_size.y)
	return Vector2(landing_x, minf(NORTH_PORTAL_TOP, room_size.y))

func _arrival_position(portal: Dictionary) -> Vector2:
	var landing: Vector2 = portal["position"]
	var inward := 0.0
	match portal["side"]:
		WorldMapScript.SIDE_EAST:
			inward = -ARRIVAL_INSET
		WorldMapScript.SIDE_WEST:
			inward = ARRIVAL_INSET
	return Vector2(
		clampf(landing.x + inward, PORTAL_INSET, maxf(room_size.x - PORTAL_INSET, PORTAL_INSET)),
		landing.y - ENTRY_STAND_OFFSET
	)

func _entry_id(neighbour: StringName) -> StringName:
	return StringName("from_%s" % neighbour)

# -- geometry -----------------------------------------------------------------

func _build_shell() -> void:
	var half := WALL * 0.5
	platform(
		Vector2(room_size.x * 0.5, room_size.y + half),
		Vector2(room_size.x + WALL * 2.0, WALL)
	)
	platform(Vector2(room_size.x * 0.5, -half), Vector2(room_size.x + WALL * 2.0, WALL))
	platform(Vector2(-half, room_size.y * 0.5), Vector2(WALL, room_size.y + WALL * 2.0))
	platform(
		Vector2(room_size.x + half, room_size.y * 0.5),
		Vector2(WALL, room_size.y + WALL * 2.0)
	)

func _build_portal(portal: Dictionary) -> void:
	var landing: Vector2 = portal["position"]
	if not is_equal_approx(landing.y, room_size.y):
		platform(Vector2(landing.x, landing.y + RUNG_SIZE.y * 0.5), RUNG_SIZE)
		_build_climb(landing)

	var route: Variant = portal["outgoing"]
	if route == null:
		return
	_build_passage(landing, route as Dictionary)

## A two-column ladder from the floor up to an elevated landing, which is
## itself the top rung. Hops are spread evenly so none exceeds RUNG_RISE, and
## the columns alternate so a rung is never directly under the next one.
## Every graybox passage is therefore reachable on legs alone, with no Refrain.
func _build_climb(landing: Vector2) -> void:
	var total_rise := room_size.y - landing.y
	var hops := maxi(1, int(ceil(total_rise / RUNG_RISE)))
	if hops < 2:
		return
	var min_x := RUNG_SIZE.x * 0.5
	var max_x := maxf(room_size.x - RUNG_SIZE.x * 0.5, min_x)
	var inward := 1.0 if landing.x < room_size.x * 0.5 else -1.0
	var offset_x := clampf(landing.x + inward * RUNG_RUN, min_x, max_x)
	var rise := total_rise / float(hops)
	for hop in range(1, hops):
		# The landing is hop `hops`; alternate back down from it.
		var x := landing.x if (hops - hop) % 2 == 0 else offset_x
		platform(
			Vector2(clampf(x, min_x, max_x), room_size.y - rise * hop + RUNG_SIZE.y * 0.5),
			RUNG_SIZE
		)

func _build_passage(landing: Vector2, route: Dictionary) -> void:
	var target := StringName(route.get("to"))
	var requires: Array = route.get("requires", [])
	var refrain_key := WorldMapScript.required_refrain_key(requires)
	var refrain := ProgressionScript.refrain_for_key(refrain_key) if not refrain_key.is_empty() else -1
	var blocked := ""
	if refrain >= 0:
		blocked = "%s asks for %s." % [
			_map.call("room_name", target),
			ProgressionScript.refrain_label(refrain),
		]
	route_exit(
		Vector2(landing.x, landing.y - EXIT_STAND_OFFSET),
		target,
		_remote_entry_id(),
		_passage_name(route, target),
		refrain,
		blocked
	)

func _remote_entry_id() -> StringName:
	return StringName("from_%s" % world_id)

## A technique requirement names the move the route asks you to perform. It is
## printed, never enforced: knowledge in this game is journal state, so the
## passage stays open whether or not the session has recorded the move.
func _passage_name(route: Dictionary, target: StringName) -> String:
	var name := String(_map.call("room_name", target)).to_upper()
	var technique_key := WorldMapScript.required_technique_key(route.get("requires", []))
	if not technique_key.is_empty():
		var technique := ProgressionScript.technique_for_key(technique_key)
		if technique >= 0:
			return "%s\n(%s)" % [name, ProgressionScript.technique_label(technique)]
	return name

# -- dressing -----------------------------------------------------------------

## One wrapped block near the ceiling. Passage plaques hang off the floor and
## the climbs run up the walls, so the room's own text is the one thing that
## can be placed out of everything else's way.
func _build_room_notes() -> void:
	var data: Dictionary = _map.call("room", world_id)
	var stratum: Dictionary = _map.call("stratum_for_room", world_id)
	var lines := PackedStringArray([
		String(stratum.get("name", "")),
		band_name.to_upper(),
	])
	var notes := String(data.get("notes", ""))
	if not notes.is_empty():
		lines.append(notes)
	var tags: Array = data.get("tags", [])
	if not tags.is_empty():
		lines.append("[graybox — planned: %s]" % ", ".join(PackedStringArray(tags)))
	for reward_value in data.get("rewards", []):
		var reward := String(reward_value)
		if not reward.begins_with(WorldMapScript.TECHNIQUE_PREFIX):
			continue
		var technique := ProgressionScript.technique_for_key(
			reward.substr(WorldMapScript.TECHNIQUE_PREFIX.length())
		)
		if technique >= 0:
			lines.append("%s is proven here." % ProgressionScript.technique_label(technique))

	var heading := "%s · %s" % [String(stratum.get("name", "")), band_name.to_upper()]
	var note := PressScript.card(
		"\n".join(lines.slice(2)),
		_solid_color(),
		_stock_color(),
		PressScript.PINK,
		PressScript.SIZE_SMALL,
		heading
	)
	note.position = Vector2(NOTE_INSET, NOTE_TOP)
	_notes.append(note)
	add_child(note)

	_build_rewards(data)

## Refrains are the only reward the graybox actually grants: they are the
## permissions the planned shortcuts check, so the world stays self-consistent
## when walked end to end. Techniques stay unearned here on purpose — nothing
## in a graybox is a proof of the move, and no route depends on the record.
func _build_rewards(data: Dictionary) -> void:
	var offset := 0.0
	for reward_value in data.get("rewards", []):
		var reward := String(reward_value)
		if reward.begins_with(WorldMapScript.REFRAIN_PREFIX):
			var key := reward.substr(WorldMapScript.REFRAIN_PREFIX.length())
			var refrain := ProgressionScript.refrain_for_key(key)
			if refrain >= 0 and progression != null and not bool(
				progression.call("has_refrain", refrain)
			):
				_build_reward_plinth(refrain, offset)
				offset += REWARD_SPACING
		elif reward.begins_with(WorldMapScript.TECHNIQUE_PREFIX):
			var key := reward.substr(WorldMapScript.TECHNIQUE_PREFIX.length())
			var technique := ProgressionScript.technique_for_key(key)
			if technique >= 0:
				sign_label(
					Vector2(room_size.x * 0.5, room_size.y - 170.0),
					"%s is proven here." % ProgressionScript.technique_label(technique)
				)

## A Refrain sits on a plinth two rungs above the spawn, never beside it: a
## graybox still has to be climbed before it hands over a permission, and no
## arrival into the room may brush the pickup on the way in.
func _build_reward_plinth(refrain: int, offset: float) -> void:
	var min_x := RUNG_SIZE.x * 0.5
	var max_x := maxf(room_size.x - RUNG_SIZE.x * 0.5, min_x)
	var plinth_top := room_size.y - RUNG_RISE * 2.0
	var plinth_x := _clear_reward_x(
		clampf(spawn_pos.x + offset, min_x, max_x), plinth_top - REWARD_LIFT, min_x, max_x
	)
	platform(Vector2(plinth_x, plinth_top + RUNG_SIZE.y * 0.5), RUNG_SIZE)
	# One offset rung so the plinth is climbed from the side, never head-first.
	var step_x := plinth_x + RUNG_RUN
	if step_x > max_x:
		step_x = plinth_x - RUNG_RUN
	platform(
		Vector2(clampf(step_x, min_x, max_x), room_size.y - RUNG_RISE + RUNG_SIZE.y * 0.5),
		RUNG_SIZE
	)
	refrain_pickup(Vector2(plinth_x, plinth_top - REWARD_LIFT), refrain)

## Walks the plinth sideways until the pickup clears the spawn and every named
## arrival. A room whose passages sit above its floor can otherwise drop the
## player straight onto the reward it is supposed to make them climb for.
func _clear_reward_x(preferred_x: float, pickup_y: float, min_x: float, max_x: float) -> float:
	var clearance := RefrainPickupScript.COLLECT_RADIUS + REWARD_CLEARANCE
	for step in range(0, REWARD_SHIFT_TRIES):
		for direction in [1.0, -1.0]:
			var candidate := clampf(
				preferred_x + direction * REWARD_SPACING * float(step), min_x, max_x
			)
			if _reward_is_clear(Vector2(candidate, pickup_y), clearance):
				return candidate
			if step == 0:
				break
	return preferred_x

func _reward_is_clear(pickup: Vector2, clearance: float) -> bool:
	if spawn_pos.distance_to(pickup) <= clearance:
		return false
	for entry_id in entry_points:
		if (entry_points[entry_id] as Vector2).distance_to(pickup) <= clearance:
			return false
	return true
