extends Node2D
## A room's lamps and ambient exposure. Light follows authored world positions;
## no light, shadow or presentation clock participates in physics or rewards.

const Press := preload("res://scripts/press.gd")
const Profiles := preload("res://scripts/lighting_profiles.gd")
const UPDATE_STEP := 1.0 / 30.0

var room_id: StringName
var bounds: Rect2
var surfaces: Array[Rect2] = []
var session_outcomes: Dictionary = {}
var ink := Color("26221e")
var stock := Color("e8e0cc")
var reduced_motion := false
var profile: Dictionary = {}
var lights: Array[PointLight2D] = []
var occluders: Array[LightOccluder2D] = []
var ambient: CanvasModulate
var _fixtures: Array[Node2D] = []
var _clock := 0.0
var _update_left := 0.0

class Lamp extends Node2D:
	var ink: Color
	var stock: Color
	var tint: Color
	func _draw() -> void:
		Press.draw_lamp(self, ink, stock, tint)

func setup(id: StringName, field: Rect2, floor_surfaces: Array[Rect2],
		outcomes: Dictionary = {}) -> void:
	room_id = id
	bounds = field
	surfaces = floor_surfaces.duplicate()
	session_outcomes = outcomes
	profile = Profiles.get_profile(id)

func _ready() -> void:
	add_to_group("room_lighting")
	ambient = CanvasModulate.new()
	ambient.name = "Ambient"
	add_child(ambient)
	for source in profile.get("lights", []):
		var light := PointLight2D.new()
		light.name = String(source.id)
		light.position = source.position
		light.texture = Press.light_texture()
		light.texture_scale = source.radius / 128.0
		light.scale = source.stretch
		light.color = source.color
		light.height = 0.0
		light.range_layer_min = 0
		light.range_layer_max = 0
		light.range_item_cull_mask = 1
		light.shadow_item_cull_mask = 1
		light.shadow_enabled = true
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		light.shadow_filter_smooth = 3.0
		add_child(light)
		lights.append(light)
		if source.get("fixture", false):
			var lamp := Lamp.new()
			lamp.name = String(source.id) + "Fixture"
			lamp.position = source.position
			lamp.z_index = -12
			lamp.ink = ink
			lamp.stock = stock
			lamp.tint = source.color
			lamp.material = Press.unshaded_material()
			add_child(lamp)
			_fixtures.append(lamp)
		if source.get("fixture", false) or source.get("glow", false):
			var halo := Sprite2D.new()
			halo.name = String(source.id) + "Glow"
			halo.position = source.position
			halo.z_index = -11
			halo.texture = Press.light_texture()
			halo.scale = Vector2.ONE * 0.46
			halo.modulate = Color(source.color, 0.16)
			halo.material = Press.glow_material()
			add_child(halo)
	# Only real platform faces stop a light. Insets keep their upper outlines
	# illuminated and avoid the self-shadow seam of an identical painted edge.
	for surface in surfaces:
		_add_occluder(surface)
	reink(ink, stock)
	_update_lights()

func add_surface(surface: Rect2) -> void:
	if surfaces.has(surface):
		return
	surfaces.append(surface)
	_add_occluder(surface)

func _add_occluder(surface: Rect2) -> void:
	var face := surface.grow(-2.0)
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = PackedVector2Array([face.position,
		Vector2(face.end.x, face.position.y), face.end,
		Vector2(face.position.x, face.end.y)])
	var occluder := LightOccluder2D.new()
	occluder.occluder = polygon
	occluder.occluder_light_mask = 1
	occluder.sdf_collision = false
	add_child(occluder)
	occluders.append(occluder)

func _process(delta: float) -> void:
	if delta <= 0.0 or get_tree().paused:
		return
	if not reduced_motion:
		_clock += minf(delta, 0.1)
	_update_left -= delta
	if _update_left <= 0.0:
		_update_left = UPDATE_STEP
		_update_lights()

func _update_lights() -> void:
	for index in lights.size():
		var source: Dictionary = profile.lights[index]
		var energy: float = source.energy
		var outcome := String(session_outcomes.get(source.get("outcome_key", ""), ""))
		if outcome == "freed":
			energy = float(source.get("freed_energy", energy))
		elif outcome == "shattered":
			energy = float(source.get("shattered_energy", energy))
		if not reduced_motion:
			var breath := sin(_clock * 1.13 + index * 2.3) * 0.65 + sin(_clock * 0.67 + index) * 0.35
			energy *= 1.0 + breath * float(source.get("pulse", 0.0))
		lights[index].energy = energy

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_update_lights()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	if ambient != null:
		var exposure: Color = profile.get("ambient", Color.WHITE)
		# Reversed white ink needs a little more fill on its darker paper.
		ambient.color = exposure.lerp(Color.WHITE, 0.25) if ink.get_luminance() > stock.get_luminance() else exposure
	for fixture in _fixtures:
		fixture.ink = ink
		fixture.stock = stock
		fixture.queue_redraw()

func visual_snapshot() -> Dictionary:
	var energies: Array[float] = []
	var positions: Array[Vector2] = []
	for light in lights:
		energies.append(light.energy)
		positions.append(light.global_position)
	return {"clock": _clock, "energies": energies, "positions": positions,
		"ambient": ambient.color if ambient != null else Color.WHITE,
		"reduced_motion": reduced_motion, "ink": ink, "stock": stock}
