extends Node2D
## Base for graybox rooms (strata). Rooms build their geometry in _ready
## and expose an air profile the player body reads.

const GrooveScript := preload("res://scripts/hot_groove.gd")
const PatchScript := preload("res://scripts/polish_patch.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")
const RefrainPickupScript := preload("res://scripts/refrain_pickup.gd")
const RoomExitScript := preload("res://scripts/room_exit.gd")

signal refrain_collected(refrain: int)
signal route_requested(target_room: StringName, target_entry: StringName)
signal route_blocked(message: String)

var room_id: StringName
var band_name := ""
var band_desc := ""
var spawn_pos := Vector2.ZERO
var entry_points: Dictionary = {}
var death_y := 2000.0
var cam_limits := Rect2(-500, -2000, 4000, 4000)

# air profile
var air_density := 0.0
var gravity_mult := 1.0
var fall_cap_mult := 1.0
var groove_mult := 1.0
var air_strikes_max := 0
var muted := false                 # HUSH rules: resonance systems off
var progression: RefCounted

var bg_color := Color(0.85, 0.83, 0.78)
var ink := Color(0.14, 0.13, 0.12)

## Which face of the pressing this room is currently showing. Rooms author
## their A-side and never their B-side: turning over is a presentation of the
## same room, so nothing here is duplicated per side.
var side := PressingScript.Side.A

var _skins: Array[ColorRect] = []
var _notes: Array[Label] = []
var _grooves: Array[Node2D] = []

func platform(pos: Vector2, size: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var vis := ColorRect.new()
	vis.color = _solid_color()
	vis.size = size
	vis.position = -size / 2.0
	b.add_child(vis)
	_skins.append(vis)
	add_child(b)

func groove(pos: Vector2, groove_side: int = PressingScript.Side.A) -> void:
	var p := GrooveScript.new()
	p.position = pos
	p.side = groove_side
	p.set_current_side(side)
	_grooves.append(p)
	add_child(p)

## Turns the room over. Ink and paper trade places, grooves pressed on the far
## face fall quiet, and anything HUSH burnished stops being burnished — he only
## ever smoothed the side that was face-up.
func apply_side(next_side: int) -> void:
	side = next_side
	var solid := _solid_color()
	for skin in _skins:
		if is_instance_valid(skin):
			skin.color = solid
	for note in _notes:
		if is_instance_valid(note):
			note.add_theme_color_override("font_color", Color(solid.r, solid.g, solid.b, 0.85))
	for hot in _grooves:
		if is_instance_valid(hot):
			hot.call("set_current_side", next_side)
	for child in get_children():
		if child.is_in_group("hears_strikes") and "muted" in child:
			child.set("muted", muted and next_side == PressingScript.Side.A)

func _solid_color() -> Color:
	return bg_color if side == PressingScript.Side.B else ink

func patch(pos: Vector2) -> void:
	var d := PatchScript.new()
	d.position = pos
	add_child(d)

func refrain_pickup(pos: Vector2, refrain: int) -> void:
	var pickup := RefrainPickupScript.new()
	pickup.position = pos
	pickup.progression = progression
	pickup.refrain = refrain
	pickup.collected.connect(_on_refrain_pickup_collected)
	add_child(pickup)

func _on_refrain_pickup_collected(refrain: int) -> void:
	refrain_collected.emit(refrain)

func register_entry(entry_id: StringName, pos: Vector2) -> void:
	entry_points[entry_id] = pos

func entry_position(entry_id: StringName) -> Vector2:
	if entry_id == &"default":
		return spawn_pos
	if not entry_points.has(entry_id):
		push_warning("Room '%s' has no entry '%s'; using its default spawn." % [room_id, entry_id])
		return spawn_pos
	return entry_points[entry_id] as Vector2

func route_exit(
	pos: Vector2,
	target_room: StringName,
	target_entry: StringName,
	display_name: String,
	required_refrain := -1,
	blocked_message := ""
) -> void:
	var exit := RoomExitScript.new()
	exit.position = pos
	exit.progression = progression
	exit.target_room = target_room
	exit.target_entry = target_entry
	exit.display_name = display_name
	exit.required_refrain = required_refrain
	exit.blocked_message = blocked_message
	exit.route_requested.connect(_on_exit_route_requested)
	exit.route_blocked.connect(_on_exit_route_blocked)
	add_child(exit)

func _on_exit_route_requested(target_room: StringName, target_entry: StringName) -> void:
	route_requested.emit(target_room, target_entry)

func _on_exit_route_blocked(message: String) -> void:
	route_blocked.emit(message)

func sign_label(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	var solid := _solid_color()
	l.add_theme_color_override("font_color", Color(solid.r, solid.g, solid.b, 0.85))
	l.add_theme_font_size_override("font_size", 15)
	_notes.append(l)
	add_child(l)
