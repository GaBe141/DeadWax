extends SceneTree
## Authored atmosphere is presentation only. Baseline component counts lock
## the playable geometry and entities independently of decorative layers.
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const CampaignScript := preload("res://scripts/campaign.gd")
const PatchScript := preload("res://scripts/polish_patch.gd")
const GrayboxScript := preload("res://scripts/room_graybox.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")
const PaintedWorld := preload("res://scripts/press_painted_world.gd")
const BASELINE := {
	&"headshell": [4, 4, 0, 0, 1, 0],
	&"horn_plaza": [3, 3, 0, 1, 4, 1],
	&"high_street": [7, 7, 0, 1, 2, 2],
	&"practice_room": [5, 5, 0, 1, 2, 2],
	&"the_stalls": [12, 12, 1, 1, 3, 2],
	&"groove_yard": [3, 3, 0, 0, 2, 2],
	&"label_descent": [5, 5, 0, 0, 2, 1],
	&"overture_stair": [9, 9, 0, 0, 2, 0],
	&"bootlegger": [4, 4, 0, 1, 2, 1],
	&"whistlers": [15, 15, 2, 1, 2, 1],
	&"addie": [3, 3, 0, 1, 2, 2],
	&"overture_well": [17, 17, 2, 1, 2, 1],
	&"worn_gallery": [8, 8, 0, 1, 4, 3],
	&"smoothed_floor": [3, 3, 0, 0, 2, 1],
	&"the_arm": [3, 3, 0, 0, 3, 1],
	&"the_drop": [14, 14, 0, 0, 2, 0],
	&"the_landing": [4, 4, 0, 0, 2, 0],
	&"verse_hall": [8, 8, 0, 0, 2, 1],
	&"verse_warren_n": [9, 9, 0, 0, 3, 2],
	&"verse_warren_s": [7, 7, 0, 0, 2, 1],
	&"deep_gallery": [7, 7, 0, 0, 2, 0],
}
var _main: Node2D
var _directory: String
var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for path in [PaintedWorld.LABEL_PATH, PaintedWorld.OVERTURE_PATH, PaintedWorld.WELL_PATH, PaintedWorld.UNPLAYED_PATH]:
		var painting := PaintedWorld.texture(path)
		_check(painting != null and painting.get_width() >= 700 and painting.get_height() >= 700,
			path + " imports its production painting at full usable resolution")
	_directory = "user://deadwax-scenery-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated scenery directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	await _physics(4)
	await _check_authored_rooms()
	await _check_camera_and_pause()
	await _check_reduced_motion()
	await _check_live_reduced_motion_outcomes()
	await _check_development_shell()
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(get_nodes_in_group("room_atmosphere").is_empty(), "closing Main frees every atmosphere layer")
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated scenery checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"):
		DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated scenery directory")
	if _failures.is_empty():
		print("DEAD WAX SCENERY PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("SCENERY FAIL: " + failure)
	quit(1)

func _check_authored_rooms() -> void:
	var previous: WeakRef
	for id in CampaignScript.room_ids():
		_main._load_world_room(id)
		await _physics(3)
		if previous != null:
			_check(previous.get_ref() == null, "room change releases the preceding atmosphere")
		var atmosphere := _atmosphere()
		_check(atmosphere != null, String(id) + " creates its atmosphere")
		_check(_inventory(_main.room) == BASELINE[id], String(id) + " keeps its original solids, colliders, grooves, wax, passages and outcomes")
		if atmosphere == null:
			continue
		previous = weakref(atmosphere)
		_check(get_nodes_in_group("room_atmosphere").size() == 1, String(id) + " keeps one live room atmosphere")
		_check(atmosphere.room_id == id and atmosphere.bounds == _main.room.cam_limits, String(id) + " gives the atmosphere the authored identity and bounds")
		_check(atmosphere.get_child_count() == 4, String(id) + " has three drawing planes and one ambient color field")
		for configuration in [["Far", -90], ["Middle", -55], ["Foreground", 18]]:
			var layer := atmosphere.get_node_or_null(configuration[0]) as Node2D
			_check(layer != null and layer.z_index == configuration[1], String(id) + " places " + configuration[0] + " in its intended visual depth")
		var air := atmosphere.get_node_or_null("Air") as ColorRect
		_check(air != null and air.z_index == -98 and air.mouse_filter == Control.MOUSE_FILTER_IGNORE, String(id) + " places the ambient color field behind every drawing plane without taking input")
		_check(not _has_gameplay_node(atmosphere), String(id) + " atmosphere has no collision, interaction or persistent reward node")
		_check(atmosphere.scale == Vector2.ONE and is_zero_approx(atmosphere.rotation), String(id) + " keeps scenery coordinates in the room's authored space")
		var solids := _solid_rectangles(_main.room)
		var valid_surfaces: bool = not atmosphere.surfaces.is_empty()
		for surface in atmosphere.surfaces:
			valid_surfaces = valid_surfaces and surface is Rect2 and solids.has(surface)
		_check(valid_surfaces, String(id) + " derives foreground surfaces only from its existing platforms")
		_check_foreground(atmosphere, solids, String(id))
		var gameplay := _gameplay_snapshot()
		var transforms := _solid_transforms(_main.room)
		var authored_ink: Color = _main.room.ink
		var authored_stock: Color = _main.room.bg_color
		_check(_palette_matches(atmosphere, authored_ink, authored_stock), String(id) + " starts every depth layer and color-field shader with the authored A-side palette")
		_main.room.apply_side(PressingScript.Side.B)
		_check(_palette_matches(atmosphere, authored_stock, authored_ink), String(id) + " swaps the whole atmosphere palette on the B-side")
		_main.room.apply_side(PressingScript.Side.A)
		_check(_palette_matches(atmosphere, authored_ink, authored_stock)
			and _main.room.ink == authored_ink and _main.room.bg_color == authored_stock, String(id) + " restores the exact A-side palette without mutating authored colors")
		atmosphere._process(0.05)
		_check(_solid_transforms(_main.room) == transforms and _gameplay_snapshot() == gameplay, String(id) + " visual updates leave platforms, purchases, knowledge and outcomes unchanged")

func _check_foreground(atmosphere: Node2D, solids: Array[Rect2], label: String) -> void:
	var bands: Array = atmosphere.visual_snapshot().foreground_bands
	var foreground: Node2D = atmosphere.get_node("Foreground")
	_check(bands.size() == atmosphere.surfaces.size() and foreground.get_child_count() == bands.size(), label + " prints one bounded foreground face for each selected platform")
	var valid := true
	for index in bands.size():
		var band: Rect2 = bands[index]
		var supported := false
		for solid in solids:
			if solid.encloses(band) and band.position.y >= solid.position.y + 10.0:
				supported = true
		var clip := foreground.get_child(index) as Control
		valid = valid and supported and clip != null
		if clip != null:
			valid = valid and clip.clip_contents and clip.mouse_filter == Control.MOUSE_FILTER_IGNORE
			valid = valid and Rect2(clip.position, clip.size) == band and clip.get_child_count() == 1
			if clip.get_child_count() == 1:
				valid = valid and clip.get_child(0).position == -band.position
	_check(valid, label + " clips foreground ink inside actual solids at least ten pixels below every playable lip")
	_check(_descendants(atmosphere).size() == 4 + 2 * bands.size(), label + " bounds scenery node count by its existing platform count")

func _check_camera_and_pause() -> void:
	_main._load_world_room(&"bootlegger", &"from_overture_stair")
	await _physics(3)
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_main.camera.position_smoothing_enabled = false
	_main.player.position = Vector2(780, 574)
	_main.player.velocity = Vector2.ZERO
	await _physics(4)
	_main.camera.force_update_scroll()
	var atmosphere := _atmosphere()
	if atmosphere == null:
		return
	atmosphere.sync_camera()
	var geometry := _solid_transforms(_main.room)
	var before := _offsets(atmosphere)
	var player_before: Vector2 = _main.player.position
	var camera_before: Vector2 = _main.camera.get_screen_center_position()
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	await _physics(8)
	var after := _offsets(atmosphere)
	_check(_main.player.position.x > player_before.x + 50 and _main.camera.get_screen_center_position().x > camera_before.x, "real walking moves the camera through a wide authored room")
	_check(not Vector2(after.far).is_equal_approx(before.far) and not Vector2(after.middle).is_equal_approx(before.middle), "camera travel produces actual far and middle parallax")
	var far_travel: Vector2 = after.far - before.far
	var middle_travel: Vector2 = after.middle - before.middle
	_check(far_travel.length() > middle_travel.length() and middle_travel.length() > 0.1, "distant layers move at different restrained rates")
	_check(after.foreground == before.foreground and _solid_transforms(_main.room) == geometry, "foreground and platform transforms stay fixed while the camera travels")
	_main._pause_game()
	var frozen: Dictionary = atmosphere.visual_snapshot().duplicate(true)
	var paused_player: Transform2D = _main.player.transform
	_key(KEY_D, true)
	await _frames(15)
	_key(KEY_D, false)
	_check(atmosphere.visual_snapshot() == frozen and _main.player.transform == paused_player, "pause freezes atmosphere clocks, parallax and physical movement together")
	_main._resume_game()
	await _physics(4)
	_check(atmosphere.visual_snapshot() != frozen, "the atmosphere resumes after pause")
	_main.camera.position_smoothing_enabled = true
	_main._respawn()
	var settled := _offsets(atmosphere)
	_main.camera.force_update_scroll()
	atmosphere.sync_camera()
	_check(_offsets(atmosphere) == settled, "recovery synchronizes scenery with the camera immediately, before another frame")
	_check(_solid_transforms(_main.room) == geometry, "recovery never moves authored platforms to settle parallax")

func _check_reduced_motion() -> void:
	var atmosphere := _atmosphere()
	if atmosphere == null:
		return
	_main._settings.reduced_motion = true
	_main._apply_settings()
	var frozen: Dictionary = atmosphere.visual_snapshot().duplicate(true)
	var offsets := _offsets(atmosphere)
	_main.player.position = Vector2(780, 574)
	_main.player.velocity = Vector2.ZERO
	_main.camera.force_update_scroll()
	await _physics(4)
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	await _physics(5)
	_check(_offsets(atmosphere) == offsets, "reduced motion holds every scenery layer still while the camera moves")
	_check(atmosphere.visual_snapshot() == frozen, "reduced motion also freezes ambient animation state")
	var original_ink: Color = atmosphere.ink
	var original_stock: Color = atmosphere.stock
	atmosphere.reink(original_stock, original_ink)
	_check(atmosphere.ink == original_stock and atmosphere.stock == original_ink, "reduced motion still permits palette changes")
	atmosphere.reink(original_ink, original_stock)
	_check(atmosphere.ink == original_ink and atmosphere.stock == original_stock and _offsets(atmosphere) == offsets, "palette restoration does not restart reduced-motion scenery")
	_main._load_world_room(&"overture_well", &"from_worn_gallery")
	await _physics(4)
	atmosphere = _atmosphere()
	_check(atmosphere != null, "a new room still creates its scenery with reduced motion enabled")
	if atmosphere != null:
		frozen = atmosphere.visual_snapshot().duplicate(true)
		await _physics(6)
		_check(atmosphere.visual_snapshot() == frozen, "reduced-motion settings propagate to newly entered rooms")

func _check_development_shell() -> void:
	var shell := GrayboxScript.new()
	shell.progression = _main.progression
	_check(shell.configure(_main.world, &"headshell"), "configure a planned development shell")
	root.add_child(shell)
	await _frames(2)
	_check(not shell.has_node("Atmosphere"), "planned grayboxes remain free of authored scenery")
	shell.queue_free()
	await _frames(2)

func _check_live_reduced_motion_outcomes() -> void:
	_main._settings.reduced_motion = true
	_main._apply_settings()
	for configuration in [
		[&"addie", "Addie", "addie/addie", "freed"],
		[&"addie", "Addie", "addie/addie", "shattered"],
		[&"the_arm", "Tonearm", "the_arm/tonearm", "freed"],
		[&"the_arm", "Tonearm", "the_arm/tonearm", "shattered"],
	]:
		var outcome_key: String = configuration[2]
		var outcome: String = configuration[3]
		var label := outcome_key + "=" + outcome
		_main.encounters.erase(outcome_key)
		_main._load_world_room(configuration[0])
		await _physics(4)
		var atmosphere := _atmosphere()
		if atmosphere == null:
			_check(false, label + " has scenery for its live resolution")
			continue
		var draws := {"Far": 0, "Middle": 0}
		for layer_name in ["Far", "Middle"]:
			var layer := atmosphere.get_node(layer_name) as CanvasItem
			layer.draw.connect(_count_layer_draw.bind(draws, layer_name))
			layer.queue_redraw()
		await _frames(4)
		_check(draws.Far > 0 and draws.Middle > 0, label + " observes actual far and middle draw callbacks")
		draws.Far = 0
		draws.Middle = 0
		var frozen: Dictionary = atmosphere.visual_snapshot().duplicate(true)
		var actor: Node = _main.room.get_node(configuration[1])
		# Use the live encounter signals that Main records, rather than silently
		# restoring a pose or directly queuing scenery for the test.
		if configuration[0] == &"addie":
			actor.call("_free" if outcome == "freed" else "_down")
		else:
			actor.call("_resolve_outcome", outcome)
		await _physics(7)
		_check(_main.encounters.get(outcome_key) == outcome, label + " reaches scenery through Main's live encounter recording")
		_check(atmosphere.get_node("Far").pose.outcome == outcome and atmosphere.get_node("Middle").pose.outcome == outcome
			and draws.Far > 0 and draws.Middle > 0, label + " redraws both printed layers with the new outcome despite reduced motion")
		var resolved: Dictionary = atmosphere.visual_snapshot()
		_check(resolved.reduced_motion and resolved.clock == frozen.clock and resolved.offsets == frozen.offsets,
			label + " updates its artwork without advancing the ambient clock or parallax")
		var settled_draws := draws.duplicate()
		await _physics(6)
		_check(draws == settled_draws, label + " stops redrawing once the static outcome artwork is current")

func _count_layer_draw(counts: Dictionary, layer_name: String) -> void:
	counts[layer_name] += 1

func _inventory(room: Node) -> Array[int]:
	var result: Array[int] = [0, 0, 0, 0, 0, 0]
	for node in _descendants(room):
		if node is StaticBody2D: result[0] += 1
		if node is CollisionShape2D: result[1] += 1
		if node.is_in_group("live_groove"): result[2] += 1
		if node.get_script() == PatchScript: result[3] += 1
		if node.is_in_group("room_exit"): result[4] += 1
		if node.has_meta("chapter_state_id"): result[5] += 1
	return result

func _has_gameplay_node(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D or node.get_script() == PatchScript:
		return true
	if node.has_meta("chapter_state_id"):
		return true
	for group in ["live_groove", "hears_strikes", "strikable", "chapter_boss", "room_exit", "chapter_endpoint", "world_resident", "refrain_pickup"]:
		if node.is_in_group(group):
			return true
	for child in node.get_children():
		if _has_gameplay_node(child):
			return true
	return false

func _solid_rectangles(room: Node) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for child in room.get_children():
		if not child is StaticBody2D:
			continue
		for shape in child.get_children():
			if shape is CollisionShape2D and shape.shape is RectangleShape2D:
				result.append(Rect2(child.position + shape.position - shape.shape.size / 2, shape.shape.size))
	return result

func _solid_transforms(room: Node) -> Dictionary:
	var result := {}
	for node in _descendants(room):
		if node is StaticBody2D or node is CollisionShape2D:
			result[node.get_instance_id()] = node.transform
	return result

func _offsets(atmosphere: Node2D) -> Dictionary:
	return {"far": atmosphere.get_node("Far").position, "middle": atmosphere.get_node("Middle").position,
		"foreground": atmosphere.get_node("Foreground").position}

func _palette_matches(atmosphere: Node2D, ink: Color, stock: Color) -> bool:
	if atmosphere.ink != ink or atmosphere.stock != stock:
		return false
	var material := atmosphere.get_node("Air").material as ShaderMaterial
	if material == null or material.get_shader_parameter("ink") != ink or material.get_shader_parameter("stock") != stock:
		return false
	for node in _descendants(atmosphere):
		if "ink" in node and "stock" in node:
			if node.ink != ink or node.stock != stock:
				return false
	return true

func _gameplay_snapshot() -> Dictionary:
	return {"economy": _main.economy.snapshot(), "progression": _main.progression.snapshot(), "encounters": _main.encounters.duplicate(true)}

func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_descendants(child))
	return result

func _atmosphere() -> Node2D:
	return _main.room.get_node_or_null("Atmosphere") as Node2D

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
