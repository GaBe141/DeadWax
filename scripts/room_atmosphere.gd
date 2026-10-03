extends Node2D
## Three printed planes around an authored room. Geometry, encounters, saves
## and inputs stay with the room. Camera travel only shifts decorative ink.

const Press := preload("res://scripts/press.gd")
const OVERTURE_IDS := [&"overture_stair", &"bootlegger", &"whistlers", &"addie", &"overture_well", &"worn_gallery", &"smoothed_floor", &"the_arm"]
const UNPLAYED_IDS := [&"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"]
const AMBIENT_IDS := [&"headshell", &"practice_room", &"the_stalls", &"bootlegger", &"whistlers", &"addie", &"overture_well", &"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"]
const REDRAW_STEP := 1.0 / 24.0

var room_id: StringName
var bounds := Rect2(0, 0, 1800, 820)
var ink := Color("26221e")
var stock := Color("e8e0cc")
var surfaces: Array[Rect2] = []
var session_outcomes: Dictionary = {}
var reduced_motion := false
var _clock := 0.0
var _redraw_left := 0.0
var _layers: Array[Node2D] = []
var _foreground_art: Array[Node2D] = []
var foreground_bands: Array[Rect2] = []
var _air: ColorRect
var _light_air: ColorRect
var _contacts: ContactLayer
var _actor_impressions: Array[Dictionary] = []
var _actors: Array[Dictionary] = []
var _sources: Array[Dictionary] = []
var _contact_revision := 0
var _pose: Dictionary = {}

class DepthLayer extends Node2D:
	var room_id: StringName
	var plane: StringName
	var bounds: Rect2
	var ink: Color
	var stock: Color
	var pose: Dictionary
	var redraws := 0
	func _draw() -> void:
		redraws += 1
		if plane == &"far":
			Press.draw_painted_distance(self, room_id, bounds, ink, stock)
		Press.draw_room_depth(self, room_id, plane, bounds, pose, ink, stock)

class ContactLayer extends Node2D:
	var ink: Color
	var stock: Color
	var actors: Array[Dictionary] = []
	func _draw() -> void:
		Press.draw_world_contacts(self, actors, ink, stock)

func setup(id: StringName, field: Rect2, next_ink: Color, next_stock: Color,
		floor_surfaces: Array[Rect2], outcomes: Dictionary = {}) -> void:
	room_id = id
	bounds = field
	ink = next_ink
	stock = next_stock
	surfaces = floor_surfaces.duplicate()
	session_outcomes = outcomes

func _ready() -> void:
	add_to_group("room_atmosphere")
	_pose = {"clock": 0.0, "motion": 1.0, "view": bounds, "surfaces": surfaces, "outcome": ""}
	var depth := 1.0 if room_id in OVERTURE_IDS or room_id in UNPLAYED_IDS else 0.0
	var warmth := 0.75 if room_id in [&"headshell", &"bootlegger", &"addie", &"the_landing", &"deep_gallery"] else 0.25
	_air = Press.room_air(bounds.size, ink, stock, warmth, depth)
	_air.name = "Air"
	_air.position = bounds.position
	_air.z_index = -98
	add_child(_air)
	for entry in [[&"far", "Far", -90], [&"middle", "Middle", -55]]:
		var layer := DepthLayer.new()
		layer.name = entry[1]
		layer.plane = entry[0]
		layer.z_index = entry[2]
		layer.room_id = room_id
		layer.bounds = bounds
		layer.ink = ink
		layer.stock = stock
		layer.pose = _pose
		add_child(layer)
		_layers.append(layer)
	_light_air = Press.world_light_air(bounds.size, ink, stock, _sources, bounds.position)
	_light_air.name = "LightAir"
	_light_air.position = bounds.position
	_light_air.z_index = -40
	add_child(_light_air)
	_contacts = ContactLayer.new()
	_contacts.name = "Contacts"
	_contacts.z_index = 2
	_contacts.ink = ink
	_contacts.stock = stock
	add_child(_contacts)
	var foreground := Node2D.new()
	foreground.name = "Foreground"
	foreground.z_index = 18
	add_child(foreground)
	_layers.append(foreground)
	# Clip each printed face below its walkable edge. Even an engraving that
	# reaches beyond its intended strokes cannot cover a player or bridge a gap.
	for surface in surfaces:
		_add_surface_art(surface)
	_update_pose()
	sync_camera()

func add_surface(surface: Rect2) -> void:
	if surfaces.has(surface):
		return
	surfaces.append(surface)
	_add_surface_art(surface)
	_project_contacts()

## Effective lamp snapshots arrive from RoomLighting. These transparent shafts
## share the native sources, rather than introducing a second lighting model.
func set_light_sources(sources: Array[Dictionary]) -> void:
	var local_sources: Array[Dictionary] = []
	for source in sources:
		var copied := source.duplicate(true)
		if copied.get("position") is Vector2:
			copied["position"] = to_local(copied.position)
		local_sources.append(copied)
	if local_sources == _sources:
		return
	_sources = local_sources
	if is_instance_valid(_light_air):
		Press.set_world_light_sources(_light_air, _sources)

func set_actor_impressions(impressions: Array[Dictionary]) -> void:
	var next: Array[Dictionary] = []
	for impression in impressions:
		var foot: Variant = impression.get("foot_position")
		var width: Variant = impression.get("width", 17.0)
		if not foot is Vector2 or not foot.is_finite() or not (width is float or width is int) or not is_finite(float(width)):
			continue
		next.append({"foot_position": foot, "kind": StringName(impression.get("kind", &"skip")), "width": clampf(float(width), 4.0, 64.0)})
	if next == _actor_impressions:
		return
	_actor_impressions = next
	_project_contacts()

func _project_contacts() -> void:
	var projected: Array[Dictionary] = []
	for impression in _actor_impressions:
		var foot: Vector2 = impression.foot_position
		var closest := Rect2()
		var distance := 251.0
		for surface in surfaces:
			var descent: float = surface.position.y - foot.y
			if foot.x >= surface.position.x and foot.x <= surface.end.x and descent >= -2.0 and descent <= 250.0 and descent < distance:
				closest = surface
				distance = descent
		if closest.size == Vector2.ZERO:
			continue
		var record := impression.duplicate(true)
		record["surface_y"] = closest.position.y
		record["height"] = maxf(0.0, distance)
		record["clip"] = Rect2(closest.position, Vector2(closest.size.x, minf(10.0, closest.size.y)))
		projected.append(record)
	if projected == _actors:
		return
	_actors = projected
	_contact_revision += 1
	if is_instance_valid(_contacts):
		_contacts.actors = _actors
		_contacts.queue_redraw()

func _add_surface_art(surface: Rect2) -> void:
	var band := Rect2(surface.position + Vector2(3, 10), surface.size - Vector2(6, 10))
	if band.size.x <= 0 or band.size.y <= 0:
		return
	foreground_bands.append(band)
	var clip := Control.new()
	clip.position = band.position
	clip.size = band.size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("Foreground").add_child(clip)
	var face := DepthLayer.new()
	face.room_id = room_id
	face.plane = &"foreground"
	face.bounds = bounds
	face.ink = ink
	face.stock = stock
	face.pose = _pose.duplicate()
	face.pose["surfaces"] = [surface]
	face.pose["view"] = bounds
	face.position = -band.position
	clip.add_child(face)
	_foreground_art.append(face)

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	if not reduced_motion:
		_clock += minf(delta, 0.1)
	sync_camera()
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = REDRAW_STEP
		var previous_outcome: String = _pose.get("outcome", "")
		_update_pose()
		if _pose["outcome"] != previous_outcome:
			# A choice still changes the room's light with motion switched off.
			for index in range(2):
				_layers[index].queue_redraw()
		elif not reduced_motion and room_id in AMBIENT_IDS:
			# Far ink is static; moving its node supplies parallax without
			# rebuilding the drawing. Only cloth, drafts and light motes tick.
			_layers[1].queue_redraw()

func _update_pose() -> void:
	_pose["clock"] = _clock
	_pose["motion"] = 0.0 if reduced_motion else 1.0
	var outcome_key := "addie/addie" if room_id == &"addie" else "the_arm/tonearm"
	_pose["outcome"] = String(session_outcomes.get(outcome_key, ""))
	if is_instance_valid(_light_air):
		var material := _light_air.material as ShaderMaterial
		material.set_shader_parameter("clock", _clock)
		material.set_shader_parameter("motion", _pose["motion"])

func sync_camera() -> void:
	if not is_inside_tree() or _layers.is_empty():
		return
	var camera := get_viewport().get_camera_2d()
	var center := bounds.get_center()
	if camera != null:
		center = camera.get_screen_center_position()
	var viewport_size := get_viewport_rect().size
	_pose["view"] = Rect2(center - viewport_size * 0.5, viewport_size)
	var travel := center - bounds.get_center()
	_layers[0].position = Vector2(travel.x * 0.12, travel.y * 0.065) if not reduced_motion else Vector2.ZERO
	_layers[1].position = Vector2(travel.x * 0.045, travel.y * 0.025) if not reduced_motion else Vector2.ZERO
	# Near ink is registered to the actual platform faces, never to the camera.
	_layers[2].position = Vector2.ZERO
	_light_air.position = bounds.position
	_contacts.position = Vector2.ZERO

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_update_pose()
	sync_camera()
	for layer in _layers:
		layer.queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if _air != null:
		Press.reink_room_air(_air, ink, stock)
	if is_instance_valid(_light_air):
		Press.reink_world_light_air(_light_air, ink, stock)
	if is_instance_valid(_contacts):
		_contacts.ink = ink
		_contacts.stock = stock
		_contacts.queue_redraw()
	var prints: Array[Node2D] = []
	if _layers.size() >= 2:
		prints.append_array([_layers[0], _layers[1]])
	prints.append_array(_foreground_art)
	for layer in prints:
		layer.ink = ink
		layer.stock = stock
		layer.queue_redraw()

func visual_snapshot() -> Dictionary:
	var offsets: Array[Vector2] = []
	for layer in _layers:
		offsets.append(layer.position)
	return {"clock": _clock, "offsets": offsets, "reduced_motion": reduced_motion,
		"ink": ink, "stock": stock, "surface_count": surfaces.size(), "foreground_bands": foreground_bands.duplicate(),
		"actors": _actors.duplicate(true), "contact_revision": _contact_revision,
		"light_sources": _sources.duplicate(true), "light_air_clock": _clock,
		"far_redraws": _layers[0].redraws if _layers.size() >= 2 else 0,
		"middle_redraws": _layers[1].redraws if _layers.size() >= 2 else 0}
