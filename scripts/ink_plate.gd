extends Node2D
## A room's drawing in the ink look (ink_look.gd). The room adds this in
## place of its Quiet Wax layers and removes it to turn back. It only draws:
## no collision, no routes, no clocks that reach gameplay. The far plane
## drifts a little with the camera; everything else is fixed to the page.
##
## Horn Plaza is composed by hand (press_ink_plaza.gd). Every other room is
## composed from its own geometry (press_ink_room.gd): the plate reads the
## room's solid faces, passages and landmarks once at setup and hands them
## to the drawing as plain data.

const Press := preload("res://scripts/press.gd")
const Plaza := preload("res://scripts/press_ink_plaza.gd")
const Room := preload("res://scripts/press_ink_room.gd")
const Ink := preload("res://scripts/press_ink.gd")
const Light := preload("res://scripts/press_ink_light.gd")
const Set := preload("res://scripts/press_ink_set.gd")
const InkLook := preload("res://scripts/ink_look.gd")

## The still planes. The light lies over the set and the passages (z 0) but
## under contact shadows (2), fixtures (3-4) and figures, so what can be
## touched stays clear of the dawn.
const PLANES := [[&"paper", -100], [&"far", -90], [&"set", -60], [&"light", 1]]
const FAR_DRIFT := Vector2(0.12, 0.065)

var room_id: StringName
var bounds := Rect2(0, 0, 1800, 820)
## Whether the page is scratchboard (ink_look.gd `scratchboard`).
var scratchboard := false
## Passage positions by destination, read from the room's own exits.
var exits: Dictionary = {}
## The room as the generic drawing sees it (press_ink_room.gd `describe`).
var scene: Dictionary = {}
var reduced_motion := false
var _layers: Array[InkPlane] = []
var _live: Live
var _contacts: Contacts
var _source: Node
var _published: Array = []
var _rig: Dictionary = {}

class InkPlane extends Node2D:
	var plane: StringName
	var plate: Node2D
	func _draw() -> void:
		Press.draw_ink_room(self, plane, plate.snapshot())

## The light that moves: the lantern breathing, a dying bulb, dust in the
## beams (press_ink_light.gd). Its clock stops under Reduced motion.
class Live extends Node2D:
	var plate: Node2D
	var time := 0.0
	func _process(delta: float) -> void:
		if plate.reduced_motion:
			return
		time += delta
		queue_redraw()
	func _draw() -> void:
		var rig: Dictionary = plate.light_rig()
		if rig.is_empty():
			return
		var k := Ink.new(self, 11)
		Light.draw_live(k, rig, plate.scratchboard, time)
		k.flush()

## Soft ink shadows where figures meet the street, from the room's own
## contact projection (room_atmosphere.gd), and the long ones the lamps near
## the street throw.
class Contacts extends Node2D:
	var actors: Array = []
	var scratchboard := false
	var rig: Dictionary = {}
	func _draw() -> void:
		var p := Set.palette(scratchboard)
		var k := Ink.new(self, 7)
		for actor in actors:
			var foot: Vector2 = actor.get("foot_position", Vector2.ZERO)
			var surface := float(actor.get("surface_y", foot.y))
			var lift := clampf(float(actor.get("height", 0.0)) / 160.0, 0.0, 1.0)
			var width := float(actor.get("width", 17.0)) * lerpf(1.25, 0.55, lift)
			if not rig.is_empty():
				Light.figure_shadows(k, rig, p.ink, foot, surface, width, lift)
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
	scratchboard = InkLook.page_is_scratchboard(id, face_b)
	_read_room()

## What the drawing needs from the room, read once: its passages, solid faces
## and landmarks. Nothing live is read after this.
func _read_room() -> void:
	exits.clear()
	var passages: Array[Dictionary] = []
	for child in _source.get_children():
		if child.is_in_group("room_exit") and "target_room" in child:
			var at := (child as Node2D).position
			exits[StringName(child.get("target_room"))] = at.x
			passages.append({"target": StringName(child.get("target_room")), "at": at,
				"name": String(child.get("display_name")) if "display_name" in child else ""})
	var surfaces: Array[Rect2] = []
	if _source.has_method("surface_rects"):
		surfaces = _source.call("surface_rects")
	var landmarks: Array[Dictionary] = []
	if _source.has_method("landmark_records"):
		landmarks = _source.call("landmark_records")
	var spawn: Vector2 = _source.get("spawn_pos") if "spawn_pos" in _source else bounds.get_center()
	scene = Room.describe(room_id, bounds, surfaces, passages, landmarks, spawn)
	_rig = {}

## A solid face laid after the plate went up (an earned ledge): the drawing
## is composed again around it.
func add_surface(_surface: Rect2) -> void:
	_read_room()
	Room.forget(room_id)
	for layer in _layers:
		layer.queue_redraw()
	if _contacts != null:
		_contacts.rig = light_rig()
	_publish_lamps()

func snapshot() -> Dictionary:
	return {"room_id": room_id, "far_face": scratchboard, "scratchboard": scratchboard, "exits": exits, "scene": scene}

## The room's light.
func light_rig() -> Dictionary:
	if InkLook.hand_drawn(room_id):
		return Plaza.light_rig()
	if _rig.is_empty() and not scene.is_empty():
		_rig = Room.light_rig(scene)
	return _rig

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
	_live = Live.new()
	_live.name = "Live"
	_live.plate = self
	_live.z_index = 1
	add_child(_live)
	_contacts = Contacts.new()
	_contacts.name = "Contacts"
	_contacts.z_index = 2
	_contacts.scratchboard = scratchboard
	_contacts.rig = light_rig()
	add_child(_contacts)
	_publish_lamps()
	_sync_camera()

func _exit_tree() -> void:
	# Only this plate's own lamps: a plate leaving after the next one arrived
	# (the same room reloaded) must not put out its successor's.
	if is_same(InkLook.lamps, _published):
		InkLook.lamps = []

## Lamps in world space, for the figures that walk past them.
func _publish_lamps() -> void:
	var lamps: Array = []
	for lamp: Dictionary in light_rig().get("lamps", []):
		var lit := lamp.duplicate()
		lit["at"] = to_global(Vector2(lamp.at))
		lamps.append(lit)
	_published = lamps
	InkLook.lamps = lamps

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

## Turning the pressing over reprints the same drawing on the other page.
## (Not `reink`: the rooms reink every child that has one with their own two
## colours, and the plate takes its page from the look.)
func reprint(face_b: bool) -> void:
	scratchboard = InkLook.page_is_scratchboard(room_id, face_b)
	if _contacts != null:
		_contacts.scratchboard = scratchboard
		_contacts.queue_redraw()
	for layer in _layers:
		layer.queue_redraw()
	if _live != null:
		_live.queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_sync_camera()
