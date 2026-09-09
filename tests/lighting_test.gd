extends SceneTree
## Native lighting is confined to the world canvas. These fixtures never touch
## the player's checkpoint and preserve the geometry owned by authored rooms.
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const CampaignScript := preload("res://scripts/campaign.gd")
const GrayboxScript := preload("res://scripts/room_graybox.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-lighting-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated lighting directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game()
	await _physics(4)
	await _check_room_lights()
	await _check_motion_and_pause()
	await _check_live_outcomes()
	await _check_graybox()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(get_nodes_in_group("room_lighting").is_empty(), "closing Main frees every room light")
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated lighting checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated lighting directory")
	if _failures.is_empty():
		print("DEAD WAX LIGHTING PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("LIGHTING FAIL: " + failure)
	quit(1)

func _check_room_lights() -> void:
	var previous: WeakRef
	for id in CampaignScript.room_ids():
		_main._load_world_room(id)
		await _physics(3)
		if previous != null:
			_check(previous.get_ref() == null, String(id) + " releases the preceding room's lights")
		var lighting := _lighting()
		_check(lighting != null and lighting.get_parent() == _main.room, String(id) + " owns Lighting beside its atmosphere")
		if lighting == null:
			continue
		previous = weakref(lighting)
		_check(get_nodes_in_group("room_lighting").size() == 1, String(id) + " has one live lighting controller")
		_check(lighting.room_id == id and lighting.bounds == _main.room.cam_limits, String(id) + " uses its authored lighting identity and field")
		_check(lighting.ambient is CanvasModulate and lighting.ambient.get_parent() == lighting, String(id) + " uses native world ambient modulation")
		_check(lighting.lights.size() == lighting.profile.lights.size() and lighting.lights.size() >= 2 and lighting.lights.size() <= 4, String(id) + " has two to four authored native point lights")
		var valid_lights := true
		for light in lighting.lights:
			valid_lights = valid_lights and light is PointLight2D and light.texture != null
			valid_lights = valid_lights and is_finite(light.energy) and light.energy >= 0 and light.energy <= 4
			valid_lights = valid_lights and light.texture_scale > 0 and light.global_position.is_finite()
			valid_lights = valid_lights and light.range_layer_min == 0 and light.range_layer_max == 0
			valid_lights = valid_lights and (light.range_item_cull_mask & _main.player.light_mask) != 0
			valid_lights = valid_lights and light.shadow_enabled and light.shadow_item_cull_mask != 0
			valid_lights = valid_lights and light.shadow_filter != Light2D.SHADOW_FILTER_NONE and light.shadow_filter_smooth > 0
		_check(valid_lights, String(id) + " keeps textured soft-shadow lights finite, world-only, and able to light Skip")
		_check(not _contains_gameplay(lighting), String(id) + " lights add no collider, interaction or persistent reward")
		_check_occluders(lighting, String(id))
		_check(_canvas_layer(lighting) == null and _canvas_layer(_main.status) != null
			and _main.inventory.layer > 0 and _main.shop.layer > 0 and _main.game_menu.layer > 0,
			String(id) + " keeps HUD, Book, shop and menus on separate unlit canvases")
		lighting.set_reduced_motion(true)
		var before: Dictionary = lighting.visual_snapshot().duplicate(true)
		var materials := _platform_palettes()
		var geometry := _physical_transforms()
		var hud := _hud_palette()
		var gameplay := _gameplay_snapshot()
		lighting.reink(_main.room.bg_color, _main.room.ink)
		_check(_platform_palettes() == materials and _hud_palette() == hud, String(id) + " lighting palette changes do not rewrite platform shaders or HUD colors")
		lighting.reink(_main.room.ink, _main.room.bg_color)
		_check(lighting.visual_snapshot() == before, String(id) + " reinking restores exact authored A-side light exposure")
		_main.room.apply_side(PressingScript.Side.B)
		_main.room.apply_side(PressingScript.Side.A)
		_check(lighting.visual_snapshot() == before and _platform_palettes() == materials, String(id) + " A/B/A restores lighting and authored shader palettes exactly")
		lighting._process(0.08)
		_check(_physical_transforms() == geometry and _gameplay_snapshot() == gameplay, String(id) + " light updates leave platforms, currency, knowledge and encounter choices unchanged")

func _check_occluders(lighting: Node2D, label: String) -> void:
	var solids := _solid_rectangles()
	var valid: bool = lighting.occluders.size() == lighting.surfaces.size() and not lighting.surfaces.is_empty()
	var clear_origins := true
	for index in lighting.occluders.size():
		var occluder: LightOccluder2D = lighting.occluders[index]
		var surface: Rect2 = lighting.surfaces[index]
		valid = valid and solids.has(surface) and occluder.occluder != null and not occluder.sdf_collision
		if occluder.occluder == null:
			continue
		var polygon: PackedVector2Array = occluder.occluder.polygon
		valid = valid and polygon.size() == 4 and occluder.occluder_light_mask != 0
		var inside := surface.grow(-1.0)
		for point in polygon:
			valid = valid and point.is_finite() and inside.has_point(occluder.position + point)
		for light in lighting.lights:
			valid = valid and (light.shadow_item_cull_mask & occluder.occluder_light_mask) != 0
			clear_origins = clear_origins and not Geometry2D.is_point_in_polygon(occluder.to_local(light.global_position), polygon)
	_check(valid, label + " derives shadow polygons only from real platform interiors with matching light masks")
	_check(clear_origins, label + " keeps every light source outside solid shadow polygons")

func _check_motion_and_pause() -> void:
	_main._load_world_room(&"bootlegger", &"from_overture_stair")
	await _physics(4)
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_main.camera.position_smoothing_enabled = false
	_main.player.position = Vector2(780, 574)
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	var lighting := _lighting()
	if lighting == null:
		return
	var initial: Dictionary = lighting.visual_snapshot().duplicate(true)
	var geometry := _physical_transforms()
	var camera_before: Vector2 = _main.camera.get_screen_center_position()
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	await _physics(8)
	var moved: Dictionary = lighting.visual_snapshot()
	_check(_main.camera.get_screen_center_position().x > camera_before.x, "real walking moves the camera past the lamps")
	_check(moved.positions == initial.positions and _physical_transforms() == geometry, "lights and occluders remain fixed in world space during camera travel")
	_check(moved.clock > initial.clock, "normal room lighting advances its presentation clock")
	_main._pause_game()
	var frozen: Dictionary = lighting.visual_snapshot().duplicate(true)
	await _frames(15)
	_check(lighting.visual_snapshot() == frozen, "pause freezes lamp energy, exposure, position and clock")
	_main._resume_game()
	await _physics(4)
	_main._settings.reduced_motion = true
	_main._apply_settings()
	frozen = lighting.visual_snapshot().duplicate(true)
	_main.player.position = Vector2(780, 574)
	_main.player.velocity = Vector2.ZERO
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	await _physics(6)
	_check(frozen.reduced_motion and lighting.visual_snapshot() == frozen, "reduced motion freezes lamp breathing while the player and camera keep moving")
	_main._respawn()
	_check(lighting.visual_snapshot().positions == frozen.positions, "recovery never drags world lights to the room entry")
	_main._load_world_room(&"overture_well", &"from_worn_gallery")
	await _physics(4)
	lighting = _lighting()
	frozen = lighting.visual_snapshot().duplicate(true)
	await _physics(6)
	_check(frozen.reduced_motion and lighting.visual_snapshot() == frozen, "new rooms inherit stationary lighting from reduced-motion settings")

func _check_live_outcomes() -> void:
	_main._settings.reduced_motion = true
	_main._apply_settings()
	for configuration in [
		[&"addie", "Addie", "addie/addie", "freed"],
		[&"addie", "Addie", "addie/addie", "shattered"],
		[&"the_arm", "Tonearm", "the_arm/tonearm", "freed"],
		[&"the_arm", "Tonearm", "the_arm/tonearm", "shattered"],
	]:
		var key: String = configuration[2]
		var outcome: String = configuration[3]
		_main.encounters.erase(key)
		_main._load_world_room(configuration[0])
		await _physics(4)
		var lighting := _lighting()
		var before: Dictionary = lighting.visual_snapshot().duplicate(true)
		var actor: Node = _main.room.get_node(configuration[1])
		if configuration[0] == &"addie":
			actor.call("_free" if outcome == "freed" else "_down")
		else:
			actor.call("_resolve_outcome", outcome)
		await _physics(6)
		var after: Dictionary = lighting.visual_snapshot()
		_check(_main.encounters.get(key) == outcome and after.energies != before.energies,
			key + "=" + outcome + " changes actual lamp energy through the live recorded outcome")
		_check(after.reduced_motion and after.clock == before.clock and after.positions == before.positions,
			key + "=" + outcome + " updates its light without restarting ambient motion")
		await _physics(6)
		_check(lighting.visual_snapshot() == after, key + "=" + outcome + " holds its new steady light")

func _check_graybox() -> void:
	var shell := GrayboxScript.new()
	shell.progression = _main.progression
	_check(shell.configure(_main.world, &"headshell"), "configure an isolated development shell")
	root.add_child(shell)
	await _frames(2)
	_check(not shell.has_node("Lighting"), "planned development grayboxes gain no authored light rig")
	shell.queue_free()
	await _frames(2)

func _lighting() -> Node2D:
	return _main.room.get_node_or_null("Lighting") as Node2D

func _contains_gameplay(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D or node.has_meta("chapter_state_id"):
		return true
	for group in ["hears_strikes", "strikable", "live_groove", "room_exit", "world_resident", "chapter_endpoint"]:
		if node.is_in_group(group):
			return true
	for child in node.get_children():
		if _contains_gameplay(child):
			return true
	return false

func _solid_rectangles() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child in _main.room.get_children():
		if not child is StaticBody2D:
			continue
		for shape in child.get_children():
			if shape is CollisionShape2D and shape.shape is RectangleShape2D:
				result.append(Rect2(child.position + shape.position - shape.shape.size / 2, shape.shape.size))
	return result

func _physical_transforms() -> Dictionary:
	var result := {}
	for node in _descendants(_main.room):
		if node is StaticBody2D or node is CollisionShape2D or node is LightOccluder2D:
			result[node.get_instance_id()] = node.transform
	return result

func _platform_palettes() -> Array:
	var result := []
	for skin in _main.room._skins:
		result.append([skin.material.get_shader_parameter("ink"), skin.material.get_shader_parameter("stock")])
	return result

func _hud_palette() -> Array:
	return [_main.status.get_theme_color("font_color"), _main.title.get_theme_color("font_color"), _main.masthead.color, _main.footer_stock.color]

func _gameplay_snapshot() -> Dictionary:
	return {"economy": _main.economy.snapshot(), "progression": _main.progression.snapshot(), "encounters": _main.encounters.duplicate(true)}

func _canvas_layer(node: Node) -> CanvasLayer:
	var parent := node.get_parent()
	while parent != null:
		if parent is CanvasLayer:
			return parent
		parent = parent.get_parent()
	return null

func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _physics(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame

func _frames(count: int) -> void:
	for frame in range(count):
		await process_frame

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
