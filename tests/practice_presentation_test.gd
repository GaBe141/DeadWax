extends SceneTree
## Palace presentation uses real world lights and supplied actor footprints.
## Its private checkpoint and offscreen native window never touch a live game.

const MainScene := preload("res://scenes/main.tscn")
const Save := preload("res://scripts/save_store.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Collection := preload("res://scripts/collection_state.gd")
const Press := preload("res://scripts/press.gd")
const Side := preload("res://scripts/pressing_state.gd")
const Arena := preload("res://scripts/practice_arena.gd")
const Backcutter := preload("res://scripts/backcutter.gd")

class ContactCanvas extends Node2D:
	var height := 0.0
	func _draw() -> void:
		Press.draw_palace_world(self, &"contact", Rect2(0, 0, 192, 192),
			{"surface_y": 96.0, "actors": [{"foot_position": Vector2(96, 96 - height),
			"kind": &"skip", "height": height}]}, Color("b8a47b"), Color("182b30"))

var _checks := 0
var _failures: Array[String] = []
var _main: Node2D
var _room: Node2D
var _air: Node2D
var _lighting: Node2D
var _directory := ""
var _models: Array[RefCounted] = []
var _snapshots: Array = []
var _choices: Dictionary = {}
var _bytes: Array[PackedByteArray] = []
var _geometry: Array = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	await _fixture()
	_check_structure()
	_check_shader_contracts()
	await _check_motion_pause_and_contacts()
	await _check_reinking()
	await _check_combat_marks()
	await _check_native_materials()
	await _check_teardown()
	_release_inputs()
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15, true).timeout
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private presentation checkpoints")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private presentation directory")
	if _failures.is_empty():
		print("DEAD WAX PRACTICE PRESENTATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("PRACTICE PRESENTATION FAIL: " + failure)
	quit(1)

func _fixture() -> void:
	_directory = "user://deadwax-palace-presentation-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private presentation directory")
	var progression := Progression.new()
	progression.unlock_refrain(Progression.Refrain.GATHER)
	progression.discover_technique(Progression.Technique.COUNT_IN)
	var collection := Collection.new()
	var gear: Dictionary = collection.snapshot()
	gear.owned = ["quicksilver_tip"]
	gear.equipped.needle = "quicksilver_tip"
	gear.offcuts = 12
	var saved := {"version": 1, "room_id": "the_stalls", "entry_id": "from_horn_plaza",
		"progression": progression.snapshot(), "abilities": {"version": 2, "unlocked": ["walk", "strike"]},
		"shine": 5, "purchases": ["warm_thread"], "completed": false,
		"map": {"owned": true, "visited": ["headshell", "horn_plaza", "the_stalls"]},
		"discoveries": {"echo_spool": "recorded", "survey_slip": true},
		"exploration": {"version": 1, "opened": ["warren_return"]}, "collection": gear,
		"encounters": {"groove_yard/yard_first_voice": "freed"}}
	var store := Save.new(_directory + "/checkpoint.json")
	_check(store.save_game(saved) and store.save_game(saved), "seed both private campaign copies with distinct carried models")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._continue_game()
	await _physics(4)
	_main._return_to_title()
	await _frames(3)
	_models.assign([_main.progression, _main.abilities, _main.economy, _main.map_state,
		_main.discoveries, _main.exploration, _main.collection, _main.pressing])
	_snapshots = _campaign_snapshots()
	_choices = _main.encounters.duplicate(true)
	_bytes = _disk_bytes()
	_main._start_practice()
	await _physics(4)
	_room = _main.room
	_air = _room.atmosphere
	_lighting = _room.lighting
	_check(_main.practice_mode and not _main._has_session and _air != null and _lighting != null,
		"Move practice installs its disposable atmosphere and native lighting")
	_geometry = _physical_geometry()

func _check_structure() -> void:
	_check(_room.room_id == &"move_practice" and _room.spawn_pos == Vector2(1280, 584)
		and _room.cam_limits == Rect2(0, 0, 2560, 720) and _room.death_y == 980.0,
		"the art pass preserves practice identity, camera field, entry and recovery boundary")
	_check(_room.arena.position == Vector2(1280, 584)
		and _room.arena.arena_bounds == Rect2(660, 200, 1240, 420)
		and Arena.TOTAL_FLOORS == 20 and Arena.FLOOR_ROSTERS[7] == [&"backcutter"],
		"the dial, spawn field, twenty-floor ladder and elite introduction stay fixed")
	var expected := [
		[Vector2(1280, 670), Vector2(2680, 120)],
		[Vector2(-30, 240), Vector2(60, 740)],
		[Vector2(2590, 240), Vector2(60, 740)]]
	var actual: Array = []
	for body: Node in _room.get_children():
		if body is StaticBody2D:
			var shapes := 0
			for child: Node in body.get_children():
				if child is CollisionShape2D:
					shapes += 1
					_check(child.shape is RectangleShape2D and child.position == Vector2.ZERO
						and child.rotation == 0 and child.scale == Vector2.ONE,
						"real practice colliders retain planted rectangular transforms")
					actual.append([body.position, child.shape.size])
			_check(shapes == 1 and body.rotation == 0 and body.scale == Vector2.ONE,
				"each original solid remains one untransformed collider")
	_check(actual == expected and _room._skins.size() == 3,
		"there are exactly the original floor and two wall bodies, with unchanged dimensions")
	_check(not _contains_gameplay(_air) and not _contains_gameplay(_lighting),
		"scenery, contacts, lamps and shadow polygons add no physics, combat groups or persistent identity")
	_check(_room.arena.snapshot().state == &"idle" and get_nodes_in_group("practice_arena_actor").is_empty(),
		"entering the improved room still leaves an empty, deliberately started practice floor")
	_check(_air.get_parent() == _room and _lighting.get_parent() == _room
		and _count_type(_main, &"CanvasModulate") == 1,
		"one world ambient node belongs to the practice room and disappears with it")
	_check(_lighting.lights.size() >= 3 and _lighting.lights.size() <= 4,
		"a small authored native light rig covers the combat floor")
	for light: PointLight2D in _lighting.lights:
		_check(light.texture != null and light.shadow_enabled and light.energy > 0
			and light.range_layer_min == 0 and light.range_layer_max == 0
			and light.shadow_item_cull_mask == 1 and light.range_item_cull_mask == 1,
			"native textured soft-shadow sources light world layer zero only")
		_check(_canvas_layer(light) == null and _canvas_layer(_main.status) != null
			and _main.game_menu.layer > 0 and _main.inventory.layer > 0,
			"world light cannot alter the HUD, pause backing or Book canvas")
	_check(_lighting.occluders.size() == _lighting.surfaces.size() and not _lighting.surfaces.is_empty(),
		"only actual solid surfaces receive native light occlusion")
	var surfaces := _solid_rectangles()
	for index in _lighting.occluders.size():
		var occluder: LightOccluder2D = _lighting.occluders[index]
		var surface: Rect2 = _lighting.surfaces[index]
		var inset := surface.grow(-2.0)
		var corners := PackedVector2Array([inset.position, Vector2(inset.end.x, inset.position.y),
			inset.end, Vector2(inset.position.x, inset.end.y)])
		_check(surfaces.has(surface) and occluder.occluder.polygon == corners
			and not occluder.sdf_collision and occluder.occluder_light_mask == 1,
			"an occluder follows a real rectangle with an exact two-pixel inset and no SDF collision")
		var lamp_clear := true
		for light: PointLight2D in _lighting.lights:
			lamp_clear = lamp_clear and not Geometry2D.is_point_in_polygon(occluder.to_local(light.global_position), corners)
		_check(lamp_clear, "lamps originate outside the solid shadow polygons")
	var state: Dictionary = _air.visual_snapshot()
	for band: Rect2 in state.foreground_bands:
		var contained := false
		for surface: Rect2 in surfaces:
			contained = contained or (band.position.y >= surface.position.y + 10
				and surface.encloses(band))
		_check(contained, "foreground material stays inside a real platform face below the landing edge")

func _check_shader_contracts() -> void:
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the material pass retains the GL Compatibility renderer")
	for path in ["res://assets/shaders/palace_material.gdshader", "res://assets/shaders/palace_air.gdshader"]:
		var source := FileAccess.get_file_as_string(path)
		var strip := RegEx.new()
		strip.compile("(?s)/\\*.*?\\*/|//[^\\n]*")
		var code := strip.sub(source, "", true)
		var clock := RegEx.new()
		clock.compile("\\bTIME\\b")
		_check(code.contains("shader_type canvas_item") and not code.contains("hint_screen_texture")
			and not code.contains("SCREEN_TEXTURE") and not code.contains("SCREEN_UV")
			and clock.search(code) == null, "palace shaders use explicit canvas inputs without screen reads or engine TIME: " + path)
		_check(code.contains("uniform vec4 ink") and code.contains("uniform vec4 stock"),
			"new surfaces carry explicit reinkable palette parameters: " + path)
	for skin: ColorRect in _room._skins:
		_check(skin.material is ShaderMaterial and not skin.material.shader.code.contains("render_mode unshaded")
			and skin.material.get_shader_parameter("ink") == _room.ink
			and skin.material.get_shader_parameter("stock") == _room.bg_color,
			"real floor and wall materials are natively shaded and receive authored palette roles")
	var air_rect: ColorRect = _air.get_node_or_null("Air")
	_check(air_rect != null and air_rect.mouse_filter == Control.MOUSE_FILTER_IGNORE
		and air_rect.material is ShaderMaterial and air_rect.material.shader.code.contains("unshaded"),
		"transparent atmospheric air is noninteractive and keeps its own exposure")

func _check_motion_pause_and_contacts() -> void:
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_main.camera.position_smoothing_enabled = false
	await _physics(3)
	var before: Dictionary = _air.visual_snapshot().duplicate(true)
	var lamps: Dictionary = _lighting.visual_snapshot().duplicate(true)
	var palette := _hud_palette()
	var camera_before: Vector2 = _main.camera.get_screen_center_position()
	_key(KEY_D, true)
	await _physics(24)
	_key(KEY_D, false)
	await _physics(7)
	var after: Dictionary = _air.visual_snapshot()
	_check(_main.camera.get_screen_center_position().x > camera_before.x
		and after.clock > before.clock, "walking advances the camera and decorative ambient clock")
	_check(after.far_redraws == before.far_redraws,
		"camera travel and ambient motion keep the distant vault artwork cached")
	_check(_lighting.visual_snapshot().positions == lamps.positions and _physical_geometry() == _geometry,
		"camera travel moves neither native lamps nor the three original solids")
	_check(_hud_palette() == palette, "new world exposure preserves the supplied HUD palette")
	_check_actor_feet("walking supplies the current player footprint")
	_main._pause_game()
	await _frames(2)
	var frozen: Dictionary = _air.visual_snapshot().duplicate(true)
	var light_frozen: Dictionary = _lighting.visual_snapshot().duplicate(true)
	_key(KEY_D, true)
	_key(KEY_SPACE, true)
	await _frames(12)
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_check(_air.visual_snapshot() == frozen and _lighting.visual_snapshot() == light_frozen,
		"pause freezes every scenery clock, snapshot, parallax offset and lamp energy")
	_main._resume_game()
	await _physics(3)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	await _physics(2)
	frozen = _air.visual_snapshot().duplicate(true)
	light_frozen = _lighting.visual_snapshot().duplicate(true)
	_key(KEY_A, true)
	await _physics(15)
	_key(KEY_A, false)
	_key(KEY_SPACE, true)
	await _physics(8)
	_key(KEY_SPACE, false)
	after = _air.visual_snapshot()
	_check(after.reduced_motion and after.clock == frozen.clock and after.offsets == frozen.offsets
		and after.far_redraws == frozen.far_redraws and after.middle_redraws == frozen.middle_redraws,
		"reduced motion freezes decorative clock, distant cache, middle movement and scenery parallax")
	_check(after.actors != frozen.actors and _main.player.position.y < _room.spawn_pos.y - 20,
		"reduced motion still follows the real airborne player footprint")
	_check_actor_feet("an ordinary jump keeps its explicit footprint rather than a planted decorative duplicate")
	_check(_lighting.visual_snapshot() == light_frozen and _physical_geometry() == _geometry,
		"jumping cannot move native fixtures, change their reduced exposure or resize collision")
	_main._respawn()
	_check_actor_feet("recovery synchronizes the footprint immediately before the next frame")
	_check(_main.player.position == _room.spawn_pos and _lighting.visual_snapshot().positions == lamps.positions,
		"recovery uses the original practice entry without dragging the lights")
	var recovery: Dictionary = _air.visual_snapshot().duplicate(true)
	await _physics(3)
	_check(_air.visual_snapshot().offsets == recovery.offsets,
		"recovery synchronizes decorative camera offsets immediately, with no following-frame snap")
	_check(_campaign_snapshots() == _snapshots and _disk_bytes() == _bytes,
		"movement, pause, reduced motion and recovery leave every campaign value and checkpoint byte untouched")

func _check_reinking() -> void:
	var authored: Array = [_room.ink, _room.bg_color]
	var geometry := _physical_geometry()
	var light_a: Dictionary = _lighting.visual_snapshot().duplicate(true)
	var shader_a := _surface_palettes()
	var clock: float = _air.visual_snapshot().clock
	_room.apply_side(Side.Side.B)
	_check([_room.ink, _room.bg_color] == authored and _physical_geometry() == geometry,
		"B-side reinking preserves authored colors, every body and its collision dimensions")
	_check(_air.visual_snapshot().ink == authored[1] and _air.visual_snapshot().stock == authored[0]
		and _lighting.ink == authored[1] and _lighting.stock == authored[0],
		"atmosphere and lamps receive the actual swapped palette")
	for skin: ColorRect in _room._skins:
		_check(skin.material.get_shader_parameter("ink") == authored[1]
			and skin.material.get_shader_parameter("stock") == authored[0],
			"RoomBase reinks each new shaded material through its existing shader parameters")
	_check(_lighting.ambient.color == _lighting.profile.ambient.lerp(Color.WHITE, 0.25),
		"only a real A/B palette swap receives the existing B-side ambient fill")
	_room.apply_side(Side.Side.A)
	_check(_lighting.visual_snapshot() == light_a and _surface_palettes() == shader_a
		and _air.visual_snapshot().clock == clock, "A/B/A restores exact authored materials and lamp exposure without resetting decorative time")
	_check(_physical_geometry() == _geometry and _campaign_snapshots() == _snapshots,
		"reinking cannot alter the player permissions, carried models or practice geometry")

func _check_combat_marks() -> void:
	var lamp_positions: Array = _lighting.visual_snapshot().positions.duplicate()
	_main._respawn()
	await _physics(3)
	var arena: Node2D = _room.arena
	_joy(JOY_BUTTON_Y, true)
	await _physics(2)
	_joy(JOY_BUTTON_Y, false)
	_check(arena.snapshot().state == &"warning" and arena.snapshot().floor == 1,
		"fresh controller Y still starts the floor through the unchanged center dial")
	arena.set_physics_process(false)
	var warning: Dictionary = arena.snapshot().duplicate(true)
	_air._process(0.1)
	_check(arena.snapshot() == warning and arena._copies.is_empty(),
		"shader and light updates never advance the functional spawn warning")
	arena._physics_process(Arena.FLOOR_WARNING)
	for copy: Node in arena._copies:
		copy.set_process(false)
		copy.set_physics_process(false)
	await _physics(2)
	_check(arena._copies.size() == 1 and _air.visual_snapshot().actors.size() == 2,
		"real materialized opponents receive footprints while warning marks add no fake actor")
	for impression: Dictionary in _air.visual_snapshot().actors:
		_check(impression.foot_position is Vector2 and impression.kind is StringName
			and not impression.has("actor") and not impression.has("hp") and not impression.has("phase"),
			"contact presentation receives only copied foot coordinates and a visual kind")
	arena.reset_current_floor()
	arena._floor = 8
	_main.player.position = arena.global_position
	_main.player.velocity = Vector2.ZERO
	await _physics(3)
	_check(arena.try_interact(), "the unchanged eighth-floor elite remains available")
	arena._physics_process(Arena.FLOOR_WARNING)
	var elite: Node2D = arena._copies[0]
	_check(elite is Backcutter, "floor eight still introduces the same real cross-up enemy")
	elite.set_physics_process(false)
	_main.player.position = elite.global_position + Vector2(80, 0)
	_main.player.set_physics_process(false)
	elite._player = _main.player
	elite._begin_attack()
	var commitment: Dictionary = elite.encounter_snapshot().duplicate(true)
	var elite_transform: Transform2D = elite.transform
	_air._process(0.1)
	_lighting._process(0.1)
	_check(elite.encounter_snapshot() == commitment and elite.transform == elite_transform,
		"decorative updates do not consume the elite tell, change its front guard or relocate its committed landing")
	elite._physics_process(Backcutter.CROSS_TELL)
	elite._physics_process(Backcutter.LEAP_DURATION * 0.5)
	_main._process(0.0)
	var airborne: Dictionary = elite.encounter_snapshot()
	_check(airborne.phase == &"leap" and airborne.landing_world == commitment.landing_world,
		"the cross-up follows the real unchanged committed vault while its landing cue remains fixed")
	var found := false
	for impression: Dictionary in _air.visual_snapshot().actors:
		if impression.kind == &"backcutter":
			found = impression.foot_position == elite.global_position + Backcutter.FOOT_OFFSET
	_check(found, "the elite contact impression follows its actual airborne foot position")
	_check(_lighting.visual_snapshot().positions == lamp_positions
		and _physical_geometry() == _geometry,
		"the moving elite casts presentation under fixed lamps and unchanged world collision")
	_main.player.set_physics_process(true)
	_main._respawn()
	await _physics(3)
	_check(_air.visual_snapshot().actors.size() == 1 and get_nodes_in_group("practice_arena_actor").is_empty(),
		"retry immediately discards enemy contact impressions together with the actual enemies")

func _check_native_materials() -> void:
	if DisplayServer.get_name() == "headless": return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(192, 192)
	viewport.world_2d = World2D.new()
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var canvas := Node2D.new()
	viewport.add_child(canvas)
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.16, 0.16, 0.16)
	canvas.add_child(ambient)
	var floor_skin: ColorRect = Press.palace_surface(Vector2(192, 192), Color("b8a47b"), Color("182b30"), &"floor")
	floor_skin.position = Vector2.ZERO
	canvas.add_child(floor_skin)
	var light := PointLight2D.new()
	light.position = Vector2(96, 96)
	light.texture = Press.light_texture()
	light.energy = 1.0
	light.height = 0.0
	light.texture_scale = 1.0
	light.enabled = false
	canvas.add_child(light)
	await _render_frames(3)
	var dark: Image = viewport.get_texture().get_image()
	light.enabled = true
	await _render_frames(3)
	var lit: Image = viewport.get_texture().get_image()
	_check(dark != null and lit != null and _image_luma(lit) > _image_luma(dark) * 1.02,
		"native GL rendering confirms the new floor shader actually responds to PointLight2D")
	floor_skin.queue_free()
	light.queue_free()
	ambient.queue_free()
	await _frames(2)
	var air_rect: ColorRect = Press.palace_air(Vector2(192, 192), Color("b8a47b"), Color("182b30"))
	canvas.add_child(air_rect)
	air_rect.material.set_shader_parameter("field_px", Vector2(2560, 720))
	air_rect.material.set_shader_parameter("motion", 1.0)
	air_rect.material.set_shader_parameter("clock", 0.0)
	await _render_frames(3)
	var still: Image = viewport.get_texture().get_image()
	air_rect.material.set_shader_parameter("clock", 12.0)
	await _render_frames(3)
	var moved: Image = viewport.get_texture().get_image()
	_check(_image_difference(still, moved) > 0.00001,
		"native atmospheric pixels change only when the explicit supplied shader clock advances")
	air_rect.material.set_shader_parameter("motion", 0.0)
	await _render_frames(3)
	still = viewport.get_texture().get_image()
	await _render_frames(3)
	moved = viewport.get_texture().get_image()
	_check(_image_difference(still, moved) == 0.0,
		"native reduced-motion air remains pixel-identical when the supplied clock is held")
	air_rect.queue_free()
	viewport.transparent_bg = true
	await _frames(2)
	var contact := ContactCanvas.new()
	canvas.add_child(contact)
	await _render_frames(3)
	var grounded := _alpha_metrics(viewport.get_texture().get_image())
	contact.height = 120.0
	contact.queue_redraw()
	await _render_frames(3)
	var airborne := _alpha_metrics(viewport.get_texture().get_image())
	_check(grounded.mass > airborne.mass and grounded.width > airborne.width and airborne.mass > 0,
		"native foot projection shrinks and fades with supplied jump height while staying on the floor")
	contact.height = 270.0
	contact.queue_redraw()
	await _render_frames(3)
	_check(_alpha_metrics(viewport.get_texture().get_image()).mass == 0.0,
		"a high airborne footprint fades out without leaving a second actor silhouette")
	viewport.queue_free()
	await _frames(2)

func _check_teardown() -> void:
	var room_ref: WeakRef = weakref(_room)
	var air_ref: WeakRef = weakref(_air)
	var light_ref: WeakRef = weakref(_lighting)
	_main._pause_game()
	_main._return_to_title()
	await _frames(4)
	_check(room_ref.get_ref() == null and air_ref.get_ref() == null and light_ref.get_ref() == null
		and _count_type(_main, &"CanvasModulate") == 0,
		"returning to title frees all practice scenery, lamps, occluders and ambient fill")
	_check([_main.progression, _main.abilities, _main.economy, _main.map_state,
		_main.discoveries, _main.exploration, _main.collection, _main.pressing] == _models,
		"title restores the exact original eight campaign model objects")
	_check(_campaign_snapshots() == _snapshots and _main.encounters == _choices and _disk_bytes() == _bytes,
		"the art and combat fixtures leave both checkpoints and every campaign choice unchanged")
	_main._continue_game()
	await _physics(4)
	_check(not _main.practice_mode and _main.world_room_id == &"the_stalls"
		and _main.room_entry_id == &"from_horn_plaza" and _main.collection.snapshot().equipped.needle == "quicksilver_tip",
		"Continue restores the original campaign entry and gear after the lighting pass")
	_check(_count_type(_main, &"CanvasModulate") == 1 and _main.room.atmosphere != _air
		and _main.room.lighting != _lighting and get_nodes_in_group("practice_arena_actor").is_empty(),
		"Continue owns exactly its campaign lighting with no old palace nodes or opponents")

func _check_actor_feet(message: String) -> void:
	var found := false
	for actor: Dictionary in _air.visual_snapshot().actors:
		if actor.kind == &"skip":
			# process_frame resumes fixtures before the tree's current idle pass;
			# its existing impression must be no more than one physics tick old.
			found = actor.foot_position.distance_to(_main.player.global_position + Vector2(0, 26)) <= 13.0
	_check(found, message)

func _contains_gameplay(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D or node.has_meta("chapter_state_id"):
		return true
	for group in ["hears_strikes", "strikable", "live_groove", "room_exit", "world_resident", "chapter_endpoint", "echo_trial"]:
		if node.is_in_group(group): return true
	for child: Node in node.get_children():
		if _contains_gameplay(child): return true
	return false

func _count_type(node: Node, type: StringName) -> int:
	var count := 1 if node.is_class(type) else 0
	for child: Node in node.get_children(): count += _count_type(child, type)
	return count

func _canvas_layer(node: Node) -> CanvasLayer:
	var parent := node.get_parent()
	while parent != null:
		if parent is CanvasLayer: return parent
		parent = parent.get_parent()
	return null

func _solid_rectangles() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for body: Node in _room.get_children():
		if body is StaticBody2D:
			for child: Node in body.get_children():
				if child is CollisionShape2D and child.shape is RectangleShape2D:
					result.append(Rect2(body.position + child.position - child.shape.size / 2, child.shape.size))
	return result

func _physical_geometry() -> Array:
	var result: Array = []
	for body: Node in _room.get_children():
		if body is StaticBody2D:
			result.append([body.get_instance_id(), body.transform])
			for child: Node in body.get_children():
				if child is CollisionShape2D:
					result.append([child.get_instance_id(), child.transform, child.shape.size])
	return result

func _surface_palettes() -> Array:
	var result: Array = []
	for skin: ColorRect in _room._skins:
		result.append([skin.material.get_shader_parameter("ink"), skin.material.get_shader_parameter("stock"),
			skin.material.get_shader_parameter("accent"), skin.material.get_shader_parameter("material_kind")])
	return result

func _hud_palette() -> Array:
	return [_main.status.get_theme_color("font_color"), _main.title.get_theme_color("font_color"),
		_main.masthead.color, _main.footer_stock.color]

func _campaign_snapshots() -> Array:
	var result: Array = []
	for index in _models.size():
		result.append([_models[index].side, _models[index].runtime_left] if index == 7 else _models[index].snapshot())
	return result

func _disk_bytes() -> Array[PackedByteArray]:
	return [FileAccess.get_file_as_bytes(_main.save_path), FileAccess.get_file_as_bytes(_main.save_path + ".bak")]

func _image_luma(image: Image) -> float:
	var result := 0.0
	var samples := 0
	for y in range(64, 129, 8):
		for x in range(64, 129, 8):
			var color := image.get_pixel(x, y)
			result += (color.r + color.g + color.b) / 3.0
			samples += 1
	return result / samples

func _image_difference(first: Image, second: Image) -> float:
	var result := 0.0
	for y in range(first.get_height()):
		for x in range(first.get_width()):
			var one := first.get_pixel(x, y)
			var two := second.get_pixel(x, y)
			result += absf(one.r - two.r) + absf(one.g - two.g) + absf(one.b - two.b) + absf(one.a - two.a)
	return result

func _alpha_metrics(image: Image) -> Dictionary:
	var mass := 0.0
	var left := image.get_width()
	var right := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var alpha := image.get_pixel(x, y).a
			mass += alpha
			if alpha > 0:
				left = mini(left, x)
				right = maxi(right, x)
	return {"mass": mass, "width": maxi(0, right - left + 1)}

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)

func _release_inputs() -> void:
	for code in [KEY_A, KEY_D, KEY_SPACE, KEY_E, KEY_R, KEY_ESCAPE]: _key(code, false)
	_joy(JOY_BUTTON_Y, false)

func _physics(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in count: await process_frame

func _render_frames(count: int) -> void:
	for frame in count:
		await process_frame
		await RenderingServer.frame_post_draw

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition: _failures.append(message)
