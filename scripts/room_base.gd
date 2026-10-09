extends Node2D
## Base for graybox rooms (strata). Rooms build their geometry in _ready
## and expose an air profile the player body reads.

const GrooveScript := preload("res://scripts/hot_groove.gd")
const PatchScript := preload("res://scripts/polish_patch.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")
const PressScript := preload("res://scripts/press.gd")
const RefrainPickupScript := preload("res://scripts/refrain_pickup.gd")
const AbilityPickupScript := preload("res://scripts/ability_pickup.gd")
const AbilitiesScript := preload("res://scripts/abilities_state.gd")
const RoomExitScript := preload("res://scripts/room_exit.gd")
const AtmosphereScript := preload("res://scripts/room_atmosphere.gd")
const LightingScript := preload("res://scripts/room_lighting.gd")

signal refrain_collected(refrain: int)
signal ability_requested(ability: StringName, source: Node2D)
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
## Seconds per beat while Groove pressure is on; 0 keeps Tick's count
## (groove_clock.gd DEFAULT_PERIOD). Counting foes here tick on this beat.
var beat_period := 0.0
var progression: RefCounted
var abilities: RefCounted

var bg_color := Color(0.85, 0.83, 0.78)
var ink := Color(0.14, 0.13, 0.12)

## Which face of the pressing this room is currently showing. Rooms author
## their A-side and never their B-side: turning over is a presentation of the
## same room, so nothing here is duplicated per side.
var side := PressingScript.Side.A
var cinematic_mode := false

## Main opts authored campaign rooms into the quiet presentation. Development
## rooms keep their full guidance. Later earned fixtures inherit the same mode.
func set_cinematic_mode(enabled: bool) -> void:
	cinematic_mode = enabled
	if not child_entered_tree.is_connected(_on_presentation_child):
		child_entered_tree.connect(_on_presentation_child)
	for note in _notes:
		if is_instance_valid(note): note.visible = not enabled
	for child in get_children():
		if child.has_method("set_cinematic_mode"):
			child.call("set_cinematic_mode", enabled)

func _on_presentation_child(child: Node) -> void:
	call_deferred("_settle_presentation_child", child)

func _settle_presentation_child(child: Variant) -> void:
	if not is_instance_valid(child) or child.get_parent() != self: return
	if child.has_method("set_cinematic_mode"):
		child.call("set_cinematic_mode", cinematic_mode)
	if child is Control and child in _notes:
		child.visible = not cinematic_mode

var _skins: Array[ColorRect] = []
var _notes: Array[Control] = []
var _grooves: Array[Node2D] = []
var _backdrop: ColorRect
var atmosphere: Node2D
var lighting: Node2D
var _world_materials := false

## Authored rooms opt in after laying their real platforms. Decoration never
## authors collision: foreground strips inherit the existing solid rectangles.
func setup_atmosphere(outcomes: Dictionary = {}) -> void:
	if atmosphere != null:
		return
	_world_materials = true
	for skin in _skins:
		_apply_world_material(skin)
	var surfaces: Array[Rect2] = []
	for skin in _skins:
		if skin.size.x >= 100 and skin.size.y >= 20 and skin.size.y <= 200:
			surfaces.append(Rect2(skin.get_parent().position + skin.position, skin.size))
	atmosphere = AtmosphereScript.new()
	atmosphere.name = "Atmosphere"
	atmosphere.call("setup", room_id, cam_limits, _solid_color(), _stock_color(), surfaces, outcomes)
	add_child(atmosphere)
	lighting = LightingScript.new()
	lighting.name = "Lighting"
	lighting.call("setup", room_id, cam_limits, surfaces, outcomes)
	lighting.ink = _solid_color()
	lighting.stock = _stock_color()
	add_child(lighting)
	lighting.connect("presentation_changed", Callable(atmosphere, "set_light_sources"))
	atmosphere.call("set_light_sources", lighting.presentation_sources())

## Main supplies copied feet, never gameplay actors. Atmosphere projects their
## contact ink only onto this room's actual platform faces.
func set_actor_impressions(impressions: Array[Dictionary]) -> void:
	if is_instance_valid(atmosphere) and atmosphere.has_method("set_actor_impressions"):
		var local_impressions: Array[Dictionary] = []
		for impression in impressions:
			var copied := impression.duplicate(true)
			if copied.get("foot_position") is Vector2:
				copied["foot_position"] = to_local(copied.foot_position)
			local_impressions.append(copied)
		atmosphere.call("set_actor_impressions", local_impressions)

func _apply_world_material(skin: ColorRect) -> void:
	var position: Vector2 = skin.get_parent().position
	var style: StringName = &"stone"
	if room_id in [&"headshell", &"horn_plaza", &"high_street", &"practice_room", &"the_stalls", &"groove_yard", &"label_descent"]:
		style = &"wax"
	elif room_id in [&"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"] and skin.size.y <= 45.0:
		style = &"brass"
	var printed := PressScript.world_surface(skin.size, _solid_color(), _stock_color(), PressScript.PINK, position.x + position.y, style)
	skin.material = printed.material
	printed.free()

func set_scenery_motion(reduced: bool) -> void:
	if atmosphere != null:
		atmosphere.call("set_reduced_motion", reduced)
	if lighting != null:
		lighting.call("set_reduced_motion", reduced)
	for child in get_children():
		if child != atmosphere and child != lighting and child.has_method("set_reduced_motion"):
			child.call("set_reduced_motion", reduced)

## An earned practice ledge needs the same engraving and shadows whether it
## appeared live or was built while restoring a resolved encounter.
func refresh_atmosphere(outcomes: Dictionary) -> void:
	if atmosphere == null:
		return
	atmosphere.session_outcomes = outcomes
	lighting.session_outcomes = outcomes
	for skin in _skins:
		if skin.size.x >= 100 and skin.size.y >= 20 and skin.size.y <= 200:
			var surface := Rect2(skin.get_parent().position + skin.position, skin.size)
			atmosphere.call("add_surface", surface)
			lighting.call("add_surface", surface)

func sync_scenery_camera() -> void:
	if atmosphere != null:
		atmosphere.call("sync_camera")

func platform(pos: Vector2, size: Vector2) -> void:
	var b := StaticBody2D.new()
	b.position = pos
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var vis := PressScript.plate(size, _solid_color(), _stock_color(), PressScript.PINK, pos.x + pos.y, true)
	b.add_child(vis)
	if _world_materials:
		_apply_world_material(vis)
	_skins.append(vis)
	add_child(b)

## The halftone tint block a room is printed over. Main lays this down once the
## room is in the tree, so no room script has to think about its own backdrop.
func lay_backdrop(bounds: Rect2) -> void:
	if _backdrop != null:
		return
	_backdrop = PressScript.backdrop(bounds.size, _solid_color())
	_backdrop.position = bounds.position
	_backdrop.z_index = -100
	_backdrop.visible = atmosphere == null
	add_child(_backdrop)

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
	var stock := _stock_color()
	for skin in _skins:
		if is_instance_valid(skin):
			PressScript.reink(skin, solid, stock, PressScript.PINK)
	for note in _notes:
		if is_instance_valid(note):
			PressScript.recard(note, solid, stock, PressScript.PINK)
	if _backdrop != null:
		PressScript.retint_backdrop(_backdrop, solid)
	if atmosphere != null:
		atmosphere.call("reink", solid, stock)
	if lighting != null:
		lighting.call("reink", solid, stock)
	for hot in _grooves:
		if is_instance_valid(hot):
			hot.call("set_current_side", next_side)
	for child in get_children():
		if child.is_in_group("ability_pickup") or child.is_in_group("exploration_fixture") or child.is_in_group("lost_pressing"):
			child.call("reink", solid, stock)
		if child.is_in_group("hears_strikes") and "muted" in child:
			child.set("muted", muted and next_side == PressingScript.Side.A)

## The ink a room is currently printed in, and the stock under it. Turning the
## pressing over trades the two.
func _solid_color() -> Color:
	return bg_color if side == PressingScript.Side.B else ink

func _stock_color() -> Color:
	return ink if side == PressingScript.Side.B else bg_color

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

func ability_pickup(pos: Vector2, id: StringName) -> void:
	var pickup := AbilityPickupScript.new()
	pickup.name = "Ability" + String(id).capitalize()
	pickup.position = pos
	pickup.abilities = abilities
	pickup.ability = id
	pickup.ink = _solid_color()
	pickup.stock = _stock_color()
	pickup.definition = AbilitiesScript.ability(id)
	if "session_outcomes" in self:
		pickup.session_outcomes = get("session_outcomes")
	pickup.requested.connect(ability_requested.emit)
	add_child(pickup)

func refresh_abilities() -> void:
	for child in get_children():
		if child.is_in_group("ability_pickup"):
			child.call("refresh_abilities")

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

## Room text is pasted up as a card, not floated as a caption: stock, a struck
## rule, and set type. A heading is pulled from a leading ALL-CAPS line so
## existing signage keeps reading the way it was written.
func sign_label(pos: Vector2, text: String) -> void:
	var heading := ""
	var body := text
	var break_at := text.find("\n")
	if break_at > 0:
		var first := text.substr(0, break_at)
		if first == first.to_upper() and first.strip_edges().length() > 2:
			heading = first.strip_edges()
			body = text.substr(break_at + 1)
	var note := PressScript.card(
		body, _solid_color(), _stock_color(), PressScript.PINK, PressScript.SIZE_BODY, heading
	)
	note.position = pos
	note.visible = not cinematic_mode
	_notes.append(note)
	add_child(note)
