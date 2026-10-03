extends Node2D
## The Palace's quiet depth and contact ink. Its supplied actor impressions
## describe feet only: this presentation never inspects combat or adds physics.

const Press := preload("res://scripts/press.gd")
const REDRAW_STEP := 1.0 / 24.0

var room_id: StringName
var bounds := Rect2(0, 0, 2560, 720)
var ink := Color("b8a47b")
var stock := Color("182b30")
var surfaces: Array[Rect2] = []
var session_outcomes: Dictionary = {}
var reduced_motion := false
var foreground_bands: Array[Rect2] = []
var _clock := 0.0
var _redraw_left := 0.0
var _air: ColorRect
var _far: PalaceLayer
var _middle: PalaceLayer
var _contacts: PalaceLayer
var _foreground: Node2D
var _faces: Array[PalaceLayer] = []
var _actors: Array[Dictionary] = []
var _pose: Dictionary = {}

class PalaceLayer extends Node2D:
	var plane: StringName
	var bounds: Rect2
	var ink: Color
	var stock: Color
	var pose: Dictionary
	var redraws := 0
	func _draw() -> void:
		redraws += 1
		Press.draw_palace_world(self, plane, bounds, pose, ink, stock)

func setup(id: StringName, field: Rect2, next_ink: Color, next_stock: Color,
		floor_surfaces: Array[Rect2]) -> void:
	room_id = id
	bounds = field
	ink = next_ink
	stock = next_stock
	surfaces = floor_surfaces.duplicate()

func _ready() -> void:
	add_to_group("room_atmosphere")
	_pose = {"clock": 0.0, "motion": 1.0, "view": bounds,
		"surfaces": surfaces, "actors": _actors, "surface_y": 610.0}
	_far = _layer(&"far", "Far", -90)
	_middle = _layer(&"middle", "Middle", -55)
	_air = Press.palace_air(bounds.size, ink, stock)
	_air.name = "Air"
	_air.position = bounds.position
	_air.z_index = -40
	add_child(_air)
	_contacts = _layer(&"contact", "Contacts", 2)
	_foreground = Node2D.new()
	_foreground.name = "Foreground"
	_foreground.z_index = 18
	add_child(_foreground)
	for surface in surfaces:
		_add_surface_art(surface)
	_update_pose()
	sync_camera()

func _layer(plane: StringName, label: String, order: int) -> PalaceLayer:
	var layer := PalaceLayer.new()
	layer.name = label
	layer.plane = plane
	layer.bounds = bounds
	layer.ink = ink
	layer.stock = stock
	layer.pose = _pose
	layer.z_index = order
	add_child(layer)
	return layer

func add_surface(surface: Rect2) -> void:
	if surfaces.has(surface):
		return
	surfaces.append(surface)
	if is_instance_valid(_foreground):
		_add_surface_art(surface)

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
	_foreground.add_child(clip)
	var face := PalaceLayer.new()
	face.plane = &"foreground"
	face.bounds = bounds
	face.ink = ink
	face.stock = stock
	face.pose = _pose.duplicate()
	face.pose["surfaces"] = [surface]
	face.pose["surface_y"] = surface.position.y
	face.position = -band.position
	clip.add_child(face)
	_faces.append(face)

func set_actor_impressions(impressions: Array[Dictionary]) -> void:
	var next: Array[Dictionary] = []
	for impression in impressions:
		var foot: Vector2 = impression.get("foot_position", Vector2.ZERO)
		var surface_y: float = impression.get("surface_y", 610.0)
		if not foot.is_finite() or not is_finite(surface_y):
			continue
		var record := impression.duplicate(true)
		record["foot_position"] = foot
		record["surface_y"] = surface_y
		record["height"] = maxf(0.0, surface_y - foot.y)
		next.append(record)
	if next == _actors:
		return
	_actors = next
	_pose["actors"] = _actors
	if is_instance_valid(_contacts):
		_contacts.queue_redraw()

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	if not reduced_motion:
		_clock += minf(delta, 0.1)
	sync_camera()
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = REDRAW_STEP
		_update_pose()
		if not reduced_motion:
			_middle.queue_redraw()

func _update_pose() -> void:
	_pose["clock"] = _clock
	_pose["motion"] = 0.0 if reduced_motion else 1.0
	if is_instance_valid(_air):
		var material := _air.material as ShaderMaterial
		material.set_shader_parameter("clock", _clock)
		material.set_shader_parameter("motion", _pose["motion"])

func sync_camera() -> void:
	if not is_inside_tree() or not is_instance_valid(_far):
		return
	var camera := get_viewport().get_camera_2d()
	var center := bounds.get_center()
	if camera != null:
		center = camera.get_screen_center_position()
	var viewport_size := get_viewport_rect().size
	_pose["view"] = Rect2(center - viewport_size * 0.5, viewport_size)
	var travel := center - bounds.get_center()
	_far.position = Vector2(travel.x * 0.07, travel.y * 0.035) if not reduced_motion else Vector2.ZERO
	_middle.position = Vector2(travel.x * 0.025, travel.y * 0.015) if not reduced_motion else Vector2.ZERO
	_pose["middle_offset"] = _middle.position
	# Shafts, feet and engraved platform faces register to the real architecture.
	_air.position = bounds.position
	_contacts.position = Vector2.ZERO
	_foreground.position = Vector2.ZERO

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_update_pose()
	sync_camera()
	if is_instance_valid(_middle):
		_middle.queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if is_instance_valid(_air):
		Press.reink_palace_air(_air, ink, stock)
	var prints: Array[PalaceLayer] = []
	for layer in [_far, _middle, _contacts]:
		if is_instance_valid(layer): prints.append(layer)
	prints.append_array(_faces)
	for layer in prints:
		layer.ink = ink
		layer.stock = stock
		layer.queue_redraw()

func visual_snapshot() -> Dictionary:
	var offsets: Array[Vector2] = []
	for layer in [_far, _middle, _contacts, _foreground]:
		if is_instance_valid(layer): offsets.append(layer.position)
	return {"clock": _clock, "offsets": offsets, "reduced_motion": reduced_motion,
		"ink": ink, "stock": stock, "surface_count": surfaces.size(),
		"foreground_bands": foreground_bands.duplicate(), "actors": _actors.duplicate(true),
		"far_redraws": _far.redraws if is_instance_valid(_far) else 0,
		"middle_redraws": _middle.redraws if is_instance_valid(_middle) else 0,
		"contact_redraws": _contacts.redraws if is_instance_valid(_contacts) else 0}
