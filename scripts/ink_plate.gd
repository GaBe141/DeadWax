extends Node2D
## The art-direction test's drawing of a room (ink_test.gd). The room adds
## this in place of its Quiet Wax layers and removes it to turn back. It only
## draws: no collision, no routes, no clocks that reach gameplay. The far town
## drifts a little with the camera; everything else is fixed to the page.

const Press := preload("res://scripts/press.gd")
const Plaza := preload("res://scripts/press_ink_plaza.gd")
const Ink := preload("res://scripts/press_ink.gd")

const PLANES := [[&"paper", -100], [&"far", -90], [&"set", -60]]
const FAR_DRIFT := Vector2(0.12, 0.065)

var room_id: StringName
var bounds := Rect2(0, 0, 1800, 820)
var far_face := false
## Passage positions by destination, read from the room's own exits.
var exits: Dictionary = {}
var reduced_motion := false
var _layers: Array[InkPlane] = []
var _contacts: Contacts
var _source: Node

class InkPlane extends Node2D:
	var plane: StringName
	var plate: Node2D
	func _draw() -> void:
		Press.draw_ink_room(self, plane, plate.snapshot())

## Soft ink shadows where figures meet the street, from the room's own
## contact projection (room_atmosphere.gd).
class Contacts extends Node2D:
	var actors: Array = []
	var far_face := false
	func _draw() -> void:
		var p := Plaza.palette(far_face)
		var k := Ink.new(self, 7)
		for actor in actors:
			var foot: Vector2 = actor.get("foot_position", Vector2.ZERO)
			var surface := float(actor.get("surface_y", foot.y))
			var lift := clampf(float(actor.get("height", 0.0)) / 160.0, 0.0, 1.0)
			var width := float(actor.get("width", 17.0)) * lerpf(1.25, 0.55, lift)
			var shadow := k.ellipse_points(Vector2(foot.x, surface + 1.5), Vector2(width, 3.2 * (1.0 - lift * 0.5)), 0.0, 16)
			k.fill(shadow, Color(p.ink, 0.22 * (1.0 - lift * 0.6)), 1.6)
			for i in 4:
				var x := foot.x - width * 0.7 + i * width * 0.45
				k.batch.add_polyline(PackedVector2Array([Vector2(x, surface + 4), Vector2(x + 5, surface - 1)]), Color(p.ink, 0.35 * (1.0 - lift)), 0.9, true)
		k.flush()

func setup(source: Node, field: Rect2, id: StringName, face_b: bool) -> void:
	_source = source
	bounds = field
	room_id = id
	far_face = face_b
	exits.clear()
	for child in source.get_children():
		if child.is_in_group("room_exit") and "target_room" in child:
			exits[StringName(child.get("target_room"))] = (child as Node2D).position.x

func snapshot() -> Dictionary:
	return {"room_id": room_id, "far_face": far_face, "exits": exits}

func _ready() -> void:
	add_to_group("ink_plate")
	for entry in PLANES:
		var layer := InkPlane.new()
		layer.name = String(entry[0]).capitalize()
		layer.plane = entry[0]
		layer.plate = self
		layer.z_index = entry[1]
		add_child(layer)
		_layers.append(layer)
	_contacts = Contacts.new()
	_contacts.name = "Contacts"
	_contacts.z_index = 2
	_contacts.far_face = far_face
	add_child(_contacts)
	_sync_camera()

func _process(_delta: float) -> void:
	_sync_camera()
	var atmosphere: Node = _source.get("atmosphere") if is_instance_valid(_source) else null
	if atmosphere != null and atmosphere.has_method("visual_snapshot"):
		var actors: Array = atmosphere.call("visual_snapshot").get("actors", [])
		if actors != _contacts.actors:
			_contacts.actors = actors
			_contacts.queue_redraw()

func _sync_camera() -> void:
	if not is_inside_tree() or _layers.is_empty():
		return
	var camera := get_viewport().get_camera_2d()
	var travel := Vector2.ZERO
	if camera != null and not reduced_motion:
		travel = camera.get_screen_center_position() - bounds.get_center()
	_layers[1].position = travel * FAR_DRIFT

## Turning the pressing over reprints the same drawing reversed out of wax.
func reink(face_b: bool) -> void:
	far_face = face_b
	if _contacts != null:
		_contacts.far_face = far_face
		_contacts.queue_redraw()
	for layer in _layers:
		layer.queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_sync_camera()
