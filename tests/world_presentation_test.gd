extends SceneTree
## Full-demo world materials and contact impressions are presentation only.
## Checkpoints/settings and native windows are private to this fixture.

const MainScene := preload("res://scenes/main.tscn")
const Save := preload("res://scripts/save_store.gd")
const Campaign := preload("res://scripts/campaign.gd")
const Atmosphere := preload("res://scripts/room_atmosphere.gd")
const RoomBase := preload("res://scripts/room_base.gd")
const Graybox := preload("res://scripts/room_graybox.gd")
const Press := preload("res://scripts/press.gd")
const Side := preload("res://scripts/pressing_state.gd")
# Captured from b077cb2 before this art pass. First hash locks every real
# rectangular solid; second locks entries, recovery limits and all passages.
const GEOMETRY := {
	&"headshell": ["5880a5ed471989eac5efd8a4b9b2d624b67d639163fa153d549a531588cd6b42", "86b425ad50107e94d2b0e99b6c9d0885cd3bcc9e3bb4d8f0461cef70ee58d060"],
	&"horn_plaza": ["88c3bc512f911183d3d11c317383dea98ce87966978095150bbe137694ed1fd8", "411b700c5538fd6edc6758efddfb6927f7f0c139afbcb7e57ce04b5e2ee54849"],
	&"high_street": ["3c4db7d386592563648a8f91b5018b5f7218596e98e7ebcb69f492e01350bd68", "6ca19dbedc85a2c0d7043e777a6bed7c226e93b2ed3264e99b18a64e42a81a73"],
	&"practice_room": ["3a3306c2892c97b54c584e153f4bfff80a422a9ebe5e2651a686f4dcd8f98081", "f6c36af966594b01887de8b6311b60d8105593904dc5b804825b27f42e02be23"],
	&"the_stalls": ["0f9613a9b96b6479c658580ae0cdefce3a9f449afac83bc2ed88e625f8f9f869", "388fa1e5880e8b96bf6993345466e1551b23a561978bd9e90cd7f33ee0f8f81a"],
	&"groove_yard": ["a094ed6dc7a6a8cdee19a5e7d1803cf5f2d044cdebc7e4f3ffb01d6290e6ff90", "8eddb2fc873a4a53168e3aec4c3afc71d75cc0d5ea4fb3eae54adee266a60bf5"],
	&"label_descent": ["cf6b2d15b67c78c17af63ad114c0fa1116952c4896648a50650282cfc9f71e7f", "549568a66f376007e4de39165ee6711f0b8a97efe62923a65f71e4d3e8dd1b3c"],
	&"overture_stair": ["e9e7171eed60e55030840a3461422db6299a77c1aee018700dff0cb0ec5fd6b5", "3d2821849b116d0427a15ccf79d5fb7b39bf30d6c976e3b1cc37867690bfdb96"],
	&"bootlegger": ["0fbd861f7da0ce6d392af9f306bdef174d4dc26769268f10dae242021a88fe40", "7fb4dc51e827641469249103e182f41021fed86abcad6de7a3cd617d8a960227"],
	&"whistlers": ["657687e5f8f03462a57bfe59432aaa2116fce147fb50d3f2dab550274d70749c", "c028487a0347c0f14fa2c4edd0f739a7e64fa5bb26a14448e4e9313186e196e3"],
	&"addie": ["fabbd294383eca1f6c0716fbf5dea6c1e3961be51a238244d3dc1637a0fff020", "8f9341c1edd383acde871ba958933b2e54f14a5b113c99a1c703fa16bc7b95b6"],
	&"overture_well": ["6e84ca2a3b5cd1aa13e553a3de15f43dc9044156e8e6e108b94ea5e9903bb05e", "4cee19b1963f9d6c71ee5989a2dbb244803a8b26702382959be39c7a92f0e352"],
	&"worn_gallery": ["7bd05e014e76979a1d7292d9e55b49bd18b4de08b6be39ba50bc556f1210f5fd", "06cc00589a840f215b1e203d369b7c2587a520e27e42369af8528559ad2febd4"],
	&"smoothed_floor": ["52388e03a0456db412519b9d5756f34d0291897739dda669d384cbc5304179b7", "a3e336c5cdf3261e4435946786073b15085027879bf186a93c7457f85844fc9f"],
	&"the_arm": ["d98ff6dafdbf7762f79d00ab95fcb7c5e825e1a2bc4b40d67cfebbfc8e0a5e84", "e53709724d51b505cf337501f20c1ee0823bdb7a1919f0ef3eaca4e385295f13"],
	&"the_drop": ["d7949b34fa243dd34d75d6102049fb7eae42493f8b7e3567217c2c0f5f7e0654", "7c6dd4c26a9dc84d8928d7c0b7579050df4437f5294cfe76467b5815bd5eec82"],
	&"the_landing": ["f177359229295d26db338ac1b884804d9729d5b5457f60be42dc23a719a264d3", "670b323fd31a9ac67cbe3179774d907e43f722f7562c1a6c1353ac7fe22b1a16"],
	&"verse_hall": ["7ffe904a44bd488c3f582e823e267804c277df0d59c8d910c970f259d6e7e6c8", "e467b19cc8c3641433e3e4508f0cd9af39a3d4fdf8e9ff8559bf0861ada93535"],
	&"verse_warren_n": ["240df0e5435568363e71d0f43295faf094faab1934d3e228a3bede9b1cf1ce39", "0abac73552c8359ecc22bf32e4364ee06a50390eca33723cbc3d0150d008df06"],
	&"verse_warren_s": ["000de6c0c613507266d48ff154383b78ca8d3fd7f8ff714f1d2112a47c80278f", "5df7805ebef4c78aba3cbe42032c22e4457678020da68c8a816b41a79b0ec070"],
	&"deep_gallery": ["d0b4d5a069057a2901d704852aaf99368a36e0f1c290637eb87a3b9c797fb15b", "e358d66f2e3f73efd6dd8e2042894cc37f4825d7d1e7bb8cc10290b867f91726"],
}

class ContactCanvas extends Node2D:
	var contacts: Array[Dictionary] = []
	func _draw() -> void:
		Press.draw_world_contacts(self, contacts, Color("b8a47b"), Color("182b30"))

var _main: Node2D
var _directory := ""
var _checks := 0
var _failures: Array[String] = []
var _bytes: Array[PackedByteArray] = []

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	await _fixture()
	_check_shader_sources()
	await _check_authored_world()
	await _check_projection()
	await _check_live_movement()
	await _check_live_surface()
	await _check_other_modes()
	await _check_native_pixels()
	_key(KEY_D, false)
	_key(KEY_SPACE, false)
	_main._has_session = false
	_main.queue_free()
	await _frames(3)
	paused = false
	_check(get_nodes_in_group("room_atmosphere").is_empty() and get_nodes_in_group("room_lighting").is_empty(),
		"closing Main releases every world material/light presentation controller")
	_check(Save.new(_directory + "/checkpoint.json").delete_save(), "remove private world presentation checkpoint")
	if FileAccess.file_exists(_directory + "/settings.cfg"): DirAccess.remove_absolute(_directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private world presentation directory")
	if _failures.is_empty():
		print("DEAD WAX WORLD PRESENTATION PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures: push_error("WORLD PRESENTATION FAIL: " + failure)
	quit(1)

func _fixture() -> void:
	_directory = "user://deadwax-world-presentation-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private world presentation directory")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	await _physics(3)
	_main.set_process(false)
	_main.player.set_physics_process(false)
	# Room construction is not passage use; its art must neither save nor
	# discover anything. Pause, recovery and live movement are checked later.
	_main._has_session = false
	_bytes = _disk_bytes()

func _check_shader_sources() -> void:
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the full-demo art pass preserves GL Compatibility")
	for path in ["res://assets/shaders/world_material.gdshader", "res://assets/shaders/world_light_air.gdshader"]:
		var source := FileAccess.get_file_as_string(path)
		var comments := RegEx.new()
		comments.compile("(?s)/\\*.*?\\*/|//[^\\n]*")
		var code := comments.sub(source, "", true)
		var time := RegEx.new()
		time.compile("\\bTIME\\b")
		_check(code.contains("shader_type canvas_item") and not code.contains("hint_screen_texture")
			and not code.contains("SCREEN_TEXTURE") and not code.contains("SCREEN_UV") and time.search(code) == null,
			"world shader uses explicit canvas coordinates without screen reads or engine TIME: " + path)
		_check(code.contains("uniform vec4 ink") and code.contains("uniform vec4 stock")
			and not code.contains("sampler2D"), "world shader palette and local relief need no texture dependency: " + path)

func _check_authored_world() -> void:
	_check(Campaign.room_ids().size() == 21 and GEOMETRY.size() == 21, "the shipped campaign retains exactly twenty-one authored rooms")
	var previous_air: WeakRef
	var previous_light: WeakRef
	for id in Campaign.room_ids():
		_main._load_world_room(id)
		_main.player.set_physics_process(false)
		_freeze_actors()
		await _frames(3)
		if previous_air != null:
			_check(previous_air.get_ref() == null and previous_light.get_ref() == null, String(id) + " releases the preceding room's air, contacts and lamps")
		var room: Node2D = _main.room
		# Main legitimately records visits and opens the Arm return on arrival;
		# only subsequent presentation operations must preserve these values.
		var carried := _model_snapshots()
		var choices: Dictionary = _main.encounters.duplicate(true)
		var air: Node2D = room.atmosphere
		var lighting: Node2D = room.lighting
		_check(air != null and lighting != null and air.get_parent() == room and lighting.get_parent() == room,
			String(id) + " opts its real authored room into the shared world treatment")
		if air == null or lighting == null: continue
		previous_air = weakref(air)
		previous_light = weakref(lighting)
		_check(_layout_hashes(room) == GEOMETRY[id], String(id) + " keeps every pre-art solid, spawn, arrival, camera limit and passage exactly fixed")
		_check(_count_class(_main, &"CanvasModulate") == 1 and not _contains_gameplay(air)
			and not _contains_gameplay(lighting), String(id) + " owns one world ambient field and no decorative gameplay node")
		var surfaces := _solid_rectangles(room)
		var material_valid: bool = not room._skins.is_empty()
		for skin: ColorRect in room._skins:
			material_valid = material_valid and skin.material is ShaderMaterial
			material_valid = material_valid and skin.material.shader.resource_path == "res://assets/shaders/world_material.gdshader"
			material_valid = material_valid and not skin.material.shader.code.contains("render_mode unshaded")
			material_valid = material_valid and skin.material.get_shader_parameter("ink") == room.ink
			material_valid = material_valid and skin.material.get_shader_parameter("stock") == room.bg_color
			material_valid = material_valid and skin.light_mask == 1 and skin.mouse_filter == Control.MOUSE_FILTER_IGNORE
		_check(material_valid, String(id) + " shades every actual platform skin with explicit authored material colors")
		var light_air := air.get_node_or_null("LightAir") as ColorRect
		_check(light_air != null and light_air.mouse_filter == Control.MOUSE_FILTER_IGNORE and light_air.z_index < 0
			and light_air.material is ShaderMaterial and light_air.material.shader.resource_path == "res://assets/shaders/world_light_air.gdshader",
			String(id) + " places noninteractive transparent local light air beneath actors")
		var contacts := air.get_node_or_null("Contacts") as Node2D
		_check(contacts != null and contacts.position == Vector2.ZERO and contacts.z_index < 10,
			String(id) + " registers ground impressions to the world beneath functional actor marks")
		var valid_bands := true
		for band: Rect2 in air.visual_snapshot().foreground_bands:
			var contained := false
			for solid: Rect2 in surfaces:
				contained = contained or (solid.encloses(band) and band.position.y >= solid.position.y + 10.0)
			valid_bands = valid_bands and contained
		_check(valid_bands, String(id) + " leaves all walkable lips and gaps free of foreground material")
		air.set_reduced_motion(true)
		lighting.set_reduced_motion(true)
		if light_air != null: _check_sources(air, lighting, String(id))
		var geometry := _layout_hashes(room)
		var palettes := _material_palettes(room)
		var lamp_a: Dictionary = lighting.visual_snapshot().duplicate(true)
		var authored := [room.ink, room.bg_color]
		room.apply_side(Side.Side.B)
		var reinked := true
		for skin: ColorRect in room._skins:
			reinked = reinked and skin.material.get_shader_parameter("ink") == authored[1]
			reinked = reinked and skin.material.get_shader_parameter("stock") == authored[0]
		_check(reinked and air.ink == authored[1] and air.stock == authored[0]
			and light_air.material.get_shader_parameter("ink") == authored[1], String(id) + " reinks materials, contacts and transparent air on the B side")
		room.apply_side(Side.Side.A)
		_check(_material_palettes(room) == palettes and lighting.visual_snapshot() == lamp_a
			and _layout_hashes(room) == geometry and [room.ink, room.bg_color] == authored,
			String(id) + " restores exact A-side material/exposure without mutating authored colors or geometry")
		air._process(0.1)
		lighting._process(0.1)
		_check(_model_snapshots() == carried and _main.encounters == choices and _disk_bytes() == _bytes,
			String(id) + " scenery, lamp updates and reinking change no carried model, choice or checkpoint byte")

func _check_sources(air: Node2D, lighting: Node2D, label: String) -> void:
	var state: Dictionary = air.visual_snapshot()
	var sources: Array = state.light_sources
	var valid: bool = sources.size() == lighting.lights.size() and sources.size() >= 2 and sources.size() <= 4
	for index in sources.size():
		var source: Dictionary = sources[index]
		valid = valid and source.position == lighting.lights[index].global_position
		valid = valid and is_equal_approx(float(source.energy), lighting.lights[index].energy)
		valid = valid and source.color == lighting.lights[index].color and float(source.radius) > 0.0
	_check(valid, label + " derives transparent shaft origins, tint and exposure from actual fixed world lamps")

func _check_projection() -> void:
	var air := Atmosphere.new()
	var surfaces: Array[Rect2] = [Rect2(10, 100, 80, 30), Rect2(10, 200, 150, 30), Rect2(180, 100, 60, 30)]
	air.setup(&"headshell", Rect2(0, 0, 300, 300), Color("b8a47b"), Color("182b30"), surfaces)
	root.add_child(air)
	air.set_process(false)
	await _frames(2)
	var actors: Array[Dictionary] = [{"foot_position": Vector2(50, 98), "kind": &"skip"}]
	air.set_actor_impressions(actors)
	var contacts: Array = air.visual_snapshot().actors
	_check(contacts.size() == 1 and contacts[0].surface_y == 100.0 and contacts[0].height == 2.0,
		"ground projection chooses the nearest real top underneath a supplied foot")
	actors[0].foot_position = Vector2(50, 150)
	_check(air.visual_snapshot().actors == contacts, "the presentation copies foot snapshots rather than retaining mutable input dictionaries")
	air.set_actor_impressions(actors)
	contacts = air.visual_snapshot().actors
	_check(contacts.size() == 1 and contacts[0].surface_y == 200.0 and contacts[0].height == 50.0,
		"a foot below the upper shelf projects to the lower real shelf without upward shadow ghosts")
	actors[0].foot_position = Vector2(170, 100)
	air.set_actor_impressions(actors)
	_check(air.visual_snapshot().actors.is_empty(), "gaps between real platforms receive no invented ground shadow")
	actors[0].foot_position = Vector2(10.5, 100)
	air.set_actor_impressions(actors)
	contacts = air.visual_snapshot().actors
	_check(contacts.size() == 1 and contacts[0].clip is Rect2 and contacts[0].clip.position.x >= 10.0
		and contacts[0].clip.end.x <= 90.0, "edge contacts carry a strict physical face clip rather than spilling into a gap")
	actors[0].foot_position = Vector2(50, -160)
	air.set_actor_impressions(actors)
	_check(air.visual_snapshot().actors.is_empty(), "feet far above all real surfaces leave no planted duplicate silhouette")
	actors[0].foot_position = Vector2(NAN, 100)
	air.set_actor_impressions(actors)
	_check(air.visual_snapshot().actors.is_empty(), "malformed nonfinite foot snapshots cannot reach drawing")
	actors[0].foot_position = Vector2(50, 101.5)
	air.set_actor_impressions(actors)
	contacts = air.visual_snapshot().actors
	_check(contacts.size() == 1 and contacts[0].surface_y == 100.0 and contacts[0].height == 0.0,
		"normal landing tolerance keeps a grounded actor attached to its true upper shelf")
	for contact: Dictionary in contacts:
		_check(not _contains_object(contact), "ground impression snapshots contain no actor/node/resource references")
	air.queue_free()
	await _frames(2)
	var translated := RoomBase.new()
	translated.room_id = &"headshell"
	translated.cam_limits = Rect2(0, 0, 300, 300)
	translated.position = Vector2(450, -300)
	root.add_child(translated)
	translated.platform(Vector2(50, 115), Vector2(100, 30))
	translated.setup_atmosphere()
	translated.atmosphere.set_process(false)
	translated.lighting.set_process(false)
	var world_feet: Array[Dictionary] = [{"foot_position": translated.to_global(Vector2(50, 100)), "kind": &"skip"}]
	translated.set_actor_impressions(world_feet)
	var localized: Array = translated.atmosphere.visual_snapshot().actors
	_check(localized.size() == 1 and localized[0].foot_position == Vector2(50, 100) and localized[0].surface_y == 100.0,
		"room boundary converts supplied world feet into local surfaces before projecting")
	var world_sources: Array[Dictionary] = [{"position": translated.to_global(Vector2(80, 20)), "radius": 120.0,
		"color": Color.WHITE, "energy": 0.4}]
	translated.atmosphere.set_light_sources(world_sources)
	_check(translated.atmosphere.visual_snapshot().light_sources[0].position == Vector2(80, 20)
		and world_sources[0].position == translated.to_global(Vector2(80, 20)),
		"world lamp origins localize once without mutating the supplied source snapshot")
	translated.queue_free()
	await _frames(2)

func _check_live_movement() -> void:
	_main._has_session = true
	_main._observation_clock = INF
	_main.abilities.unlock_ability(&"walk")
	_main._load_world_room(&"bootlegger", &"from_overture_stair")
	_main.player.position = Vector2(780, 574)
	_main.player.velocity = Vector2.ZERO
	_main.player.set_physics_process(true)
	_main.set_process(true)
	_freeze_actors()
	_main._settings.reduced_motion = false
	_main._apply_settings()
	_main.camera.position_smoothing_enabled = false
	await _physics(4)
	var air: Node2D = _main.room.atmosphere
	var lighting: Node2D = _main.room.lighting
	var before: Dictionary = air.visual_snapshot().duplicate(true)
	var lamps: Dictionary = lighting.visual_snapshot().duplicate(true)
	var geometry := _layout_hashes(_main.room)
	_key(KEY_D, true)
	await _physics(20)
	_key(KEY_D, false)
	await _physics(6)
	var after: Dictionary = air.visual_snapshot()
	_check(after.clock > before.clock and after.offsets != before.offsets, "real walking advances the room's restrained parallax and explicit ambient clock")
	_check(after.far_redraws == before.far_redraws, "camera travel and material motion keep distant artwork cached")
	_check(lighting.visual_snapshot().positions == lamps.positions and _layout_hashes(_main.room) == geometry,
		"camera travel cannot drag lamps, relocate passages or alter collision")
	_check_sources(air, lighting, "walking")
	_check_skip_contact(air, "Main supplies the actual walking player's foot and no gameplay reference")
	_main._pause_game()
	await _frames(2)
	var frozen: Dictionary = air.visual_snapshot().duplicate(true)
	var light_frozen: Dictionary = lighting.visual_snapshot().duplicate(true)
	await _frames(10)
	_check(air.visual_snapshot() == frozen and lighting.visual_snapshot() == light_frozen,
		"pause freezes decorative clock, shader exposure, actor contacts and parallax together")
	_main._resume_game()
	_main._settings.reduced_motion = true
	_main._apply_settings()
	await _physics(3)
	frozen = air.visual_snapshot().duplicate(true)
	_key(KEY_D, true)
	await _physics(10)
	_key(KEY_D, false)
	_key(KEY_SPACE, true)
	await _physics(7)
	_key(KEY_SPACE, false)
	after = air.visual_snapshot()
	_check(after.clock == frozen.clock and after.light_air_clock == frozen.light_air_clock and after.offsets == frozen.offsets
		and after.far_redraws == frozen.far_redraws and after.middle_redraws == frozen.middle_redraws,
		"reduced motion freezes only decoration, shader time and parallax while keeping the static distance cache")
	_check(after.actors != frozen.actors and _main.player.position.y < 554.0,
		"reduced motion still follows an ordinary real jump instead of planting a fake actor shadow")
	_check_skip_contact(air, "jumping sends the current actual foot to surface projection")
	_main._respawn()
	_check_skip_contact(air, "recovery supplies the new foot immediately before another process frame")
	_check(_main.player.position == _main.room.entry_position(_main.room_entry_id), "recovery retains the saved entry position")
	var settled: Dictionary = air.visual_snapshot().duplicate(true)
	await _physics(3)
	_check(air.visual_snapshot().offsets == settled.offsets, "recovery synchronizes parallax immediately without a delayed scenery snap")
	_main.set_process(false)
	_main.player.set_physics_process(false)

func _check_live_surface() -> void:
	_main._load_world_room(&"the_arm")
	_main.player.set_physics_process(false)
	_freeze_actors()
	await _frames(3)
	var room: Node2D = _main.room
	var air: Node2D = room.atmosphere
	var lighting: Node2D = room.lighting
	air.set_reduced_motion(true)
	lighting.set_reduced_motion(true)
	var before: Dictionary = air.visual_snapshot().duplicate(true)
	var positions: Array = lighting.visual_snapshot().positions.duplicate()
	var lamp_refs: Array = lighting.lights.duplicate()
	var shelf: Rect2 = Rect2(900, 300, 130, 28)
	room.platform(shelf.get_center(), shelf.size)
	var skin: ColorRect = room._skins.back()
	_check(skin.material is ShaderMaterial and skin.material.shader.resource_path == "res://assets/shaders/world_material.gdshader",
		"a newly earned physical ledge receives the same world material immediately")
	room.refresh_atmosphere(_main.encounters)
	await _frames(2)
	var after: Dictionary = air.visual_snapshot()
	_check(after.surface_count == before.surface_count + 1 and air.surfaces.has(shelf) and lighting.surfaces.has(shelf)
		and lighting.occluders.size() == lighting.surfaces.size(), "refreshing a new real ledge adds exactly its foreground face, projection surface and inset occluder")
	_check(after.clock == before.clock and lighting.lights == lamp_refs and lighting.visual_snapshot().positions == positions,
		"live surface refresh preserves existing ambient time, native lamps and their fixed world origins")
	var contacts: Array[Dictionary] = [{"foot_position": Vector2(965, 300), "kind": &"skip"}]
	room.set_actor_impressions(contacts)
	_check(air.visual_snapshot().actors.size() == 1 and air.visual_snapshot().actors[0].surface_y == 300.0,
		"actor ground projection recognizes a newly earned physical ledge in the same frame")
	var count: int = after.surface_count
	room.refresh_atmosphere(_main.encounters)
	_check(air.visual_snapshot().surface_count == count and lighting.lights == lamp_refs,
		"repeated refreshes never duplicate surfaces, lamps or shadow polygons")
	var steady: Dictionary = air.visual_snapshot().duplicate(true)
	lighting.session_outcomes = {"the_arm/tonearm": "freed"}
	lighting._update_lights()
	_check_sources(air, lighting, "live quiet Tonearm outcome")
	_check(air.visual_snapshot().light_sources != steady.light_sources and air.visual_snapshot().clock == steady.clock,
		"live injected outcomes update transparent shaft exposure without restarting reduced-motion dust")

func _check_other_modes() -> void:
	var shell := Graybox.new()
	shell.progression = _main.progression
	_check(shell.configure(_main.world, &"headshell"), "configure a planned development shell independently of campaign art")
	root.add_child(shell)
	await _frames(2)
	_check(not shell.has_node("Atmosphere") and not shell.has_node("Lighting"), "development grayboxes retain their original unlit backdrop")
	for skin: ColorRect in shell._skins:
		_check(skin.material.shader.resource_path != "res://assets/shaders/world_material.gdshader", "development platform skins do not silently opt into campaign material art")
	shell.queue_free()
	await _frames(2)
	_main._return_to_title()
	await _frames(2)
	_main._start_practice()
	await _frames(3)
	_main.player.set_physics_process(false)
	_check(_main.room.room_id == &"move_practice" and _main.room.atmosphere.get_script().resource_path == "res://scripts/practice_atmosphere.gd"
		and not _main.room.atmosphere.has_node("LightAir"), "Wax Palace retains its separately authored atmosphere and combat light rig")
	for skin: ColorRect in _main.room._skins:
		_check(skin.material.shader.resource_path == "res://assets/shaders/palace_material.gdshader", "the existing Palace material is not replaced by a campaign material")
	_main._return_to_title()
	await _frames(2)
	_check(_count_class(_main, &"CanvasModulate") == 0, "title receives no leaked world ambient modulation")

func _check_native_pixels() -> void:
	if DisplayServer.get_name() == "headless": return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(192, 192)
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var canvas := Node2D.new()
	viewport.add_child(canvas)
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.16, 0.16, 0.16)
	canvas.add_child(ambient)
	var skin: ColorRect = Press.world_surface(Vector2(192, 192), Color("b8a47b"), Color("182b30"), Press.PINK, 0.0, &"stone")
	skin.position = Vector2.ZERO
	canvas.add_child(skin)
	var light := PointLight2D.new()
	light.position = Vector2(96, 96)
	light.texture = Press.light_texture()
	light.energy = 1.0
	light.enabled = false
	canvas.add_child(light)
	await _render_frames(3)
	var dark: Image = viewport.get_texture().get_image()
	light.enabled = true
	await _render_frames(3)
	var lit: Image = viewport.get_texture().get_image()
	_check(_image_luma(lit) > _image_luma(dark) * 1.02, "native GL pixels prove real world relief materials respond to actual PointLight2D")
	skin.queue_free()
	light.queue_free()
	ambient.queue_free()
	await _frames(2)
	var sources: Array[Dictionary] = [{"position": Vector2(96, 20), "radius": 170.0, "color": Color("f2bd77"), "energy": 0.8}]
	var air: ColorRect = Press.world_light_air(Vector2(192, 192), Color("b8a47b"), Color("182b30"), sources)
	canvas.add_child(air)
	air.material.set_shader_parameter("clock", 0.0)
	await _render_frames(3)
	var first: Image = viewport.get_texture().get_image()
	air.material.set_shader_parameter("clock", 12.0)
	await _render_frames(3)
	var second: Image = viewport.get_texture().get_image()
	_check(_image_difference(first, second) > 0.00001, "native local dust and haze respond to the explicitly supplied presentation clock")
	air.material.set_shader_parameter("motion", 0.0)
	await _render_frames(3)
	first = viewport.get_texture().get_image()
	await _render_frames(5)
	second = viewport.get_texture().get_image()
	_check(_image_difference(first, second) == 0.0, "native reduced-motion haze stays pixel-identical while its explicit clock is held")
	sources[0].energy = 0.0
	Press.set_world_light_sources(air, sources)
	await _render_frames(3)
	second = viewport.get_texture().get_image()
	_check(_image_difference(first, second) > 0.00001, "native transparent shafts follow supplied actual lamp exposure even with motion reduced")
	air.queue_free()
	viewport.transparent_bg = true
	await _frames(2)
	var contact := ContactCanvas.new()
	contact.contacts = [{"foot_position": Vector2(96, 100), "kind": &"skip", "surface_y": 100.0,
		"height": 0.0, "width": 34.0, "clip": Rect2(20, 100, 152, 32)}]
	canvas.add_child(contact)
	await _render_frames(3)
	var grounded := _alpha_metrics(viewport.get_texture().get_image())
	contact.contacts[0].height = 100.0
	contact.contacts[0].foot_position.y = 0.0
	contact.queue_redraw()
	await _render_frames(3)
	var jumping := _alpha_metrics(viewport.get_texture().get_image())
	_check(grounded.mass > jumping.mass and grounded.width > jumping.width and jumping.mass > 0.0,
		"native projected contacts shrink and fade when the real supplied actor rises")
	contact.contacts[0].height = 0.0
	contact.contacts[0].foot_position = Vector2(20.5, 100)
	contact.queue_redraw()
	await _render_frames(3)
	var edge: Image = viewport.get_texture().get_image()
	var outside := 0.0
	for y in edge.get_height():
		for x in range(20): outside += edge.get_pixel(x, y).a
	_check(outside == 0.0 and _alpha_metrics(edge).mass > 0.0, "native contact pixels stop at the actual platform edge and never paint a gap")
	contact.contacts[0].height = 250.0
	contact.queue_redraw()
	await _render_frames(3)
	_check(_alpha_metrics(viewport.get_texture().get_image()).mass == 0.0, "high airborne actor impressions vanish instead of leaving a ground silhouette")
	viewport.queue_free()
	await _frames(2)

func _check_skip_contact(air: Node2D, message: String) -> void:
	var found := false
	for contact: Dictionary in air.visual_snapshot().actors:
		if contact.kind == &"skip":
			found = contact.foot_position.distance_to(_main.player.global_position + Vector2(0, 26)) <= 13.0
			found = found and not _contains_object(contact)
	_check(found, message)

func _layout_hashes(room: Node2D) -> Array:
	var solids: Array = []
	var routes: Array = []
	for child: Node in room.get_children():
		if child is StaticBody2D:
			for shape: Node in child.get_children():
				if shape is CollisionShape2D: solids.append([child.position, shape.position, shape.shape.size])
		if child.is_in_group("room_exit"): routes.append([child.position, child.target_room, child.target_entry])
	return [var_to_str(solids).sha256_text(), var_to_str([room.spawn_pos, room.entry_points, room.death_y, room.cam_limits, routes]).sha256_text()]

func _solid_rectangles(room: Node2D) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for body: Node in room.get_children():
		if body is StaticBody2D:
			for child: Node in body.get_children():
				if child is CollisionShape2D and child.shape is RectangleShape2D:
					result.append(Rect2(body.position + child.position - child.shape.size / 2, child.shape.size))
	return result

func _material_palettes(room: Node2D) -> Array:
	var result: Array = []
	for skin: ColorRect in room._skins:
		result.append([skin.material.get_shader_parameter("ink"), skin.material.get_shader_parameter("stock"),
			skin.material.get_shader_parameter("accent"), skin.material.get_shader_parameter("material_kind")])
	return result

func _model_snapshots() -> Array:
	return [_main.progression.snapshot(), _main.abilities.snapshot(), _main.economy.snapshot(), _main.map_state.snapshot(),
		_main.discoveries.snapshot(), _main.exploration.snapshot(), _main.collection.snapshot(), [_main.pressing.side, _main.pressing.runtime_left]]

func _disk_bytes() -> Array[PackedByteArray]:
	return [FileAccess.get_file_as_bytes(_main.save_path), FileAccess.get_file_as_bytes(_main.save_path + ".bak")]

func _freeze_actors() -> void:
	for group in ["hears_strikes", "chapter_boss", "world_resident"]:
		for actor: Node in get_nodes_in_group(group):
			actor.set_physics_process(false)
			actor.set_process(false)

func _contains_object(value: Variant) -> bool:
	if value is Object: return true
	if value is Dictionary:
		for key in value:
			if _contains_object(key) or _contains_object(value[key]): return true
	if value is Array:
		for item in value:
			if _contains_object(item): return true
	return false

func _contains_gameplay(node: Node) -> bool:
	if node is CollisionObject2D or node is CollisionShape2D or node is CollisionPolygon2D or node.has_meta("chapter_state_id"): return true
	for group in ["hears_strikes", "strikable", "live_groove", "room_exit", "world_resident", "chapter_endpoint", "echo_trial"]:
		if node.is_in_group(group): return true
	for child: Node in node.get_children():
		if _contains_gameplay(child): return true
	return false

func _count_class(node: Node, type: StringName) -> int:
	var count := 1 if node.is_class(type) else 0
	for child: Node in node.get_children(): count += _count_class(child, type)
	return count

func _image_luma(value: Image) -> float:
	var result := 0.0
	var samples := 0
	for y in range(64, 129, 8):
		for x in range(64, 129, 8):
			var color := value.get_pixel(x, y)
			result += (color.r + color.g + color.b) / 3.0
			samples += 1
	return result / samples

func _image_difference(first: Image, second: Image) -> float:
	var result := 0.0
	for y in first.get_height():
		for x in first.get_width():
			var one := first.get_pixel(x, y)
			var two := second.get_pixel(x, y)
			result += absf(one.r - two.r) + absf(one.g - two.g) + absf(one.b - two.b) + absf(one.a - two.a)
	return result

func _alpha_metrics(value: Image) -> Dictionary:
	var mass := 0.0
	var left := value.get_width()
	var right := -1
	for y in value.get_height():
		for x in value.get_width():
			var alpha := value.get_pixel(x, y).a
			mass += alpha
			if alpha > 0.0:
				left = mini(left, x)
				right = maxi(right, x)
	return {"mass": mass, "width": maxi(0, right - left + 1)}

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

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
