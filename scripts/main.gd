extends Node2D
## DEAD WAX — M1 bootstrap.
## Builds everything from code: input map, player, camera, HUD, audio, rooms.
## In-world passages connect rooms. [TAB] remains a debug cycle; [R] respawns.

const SkipScript := preload("res://scripts/skip.gd")
const WaveScript := preload("res://scripts/strike_wave.gd")
const AudioScript := preload("res://scripts/audio_bank.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const InventoryMenuScript := preload("res://scripts/inventory_menu.gd")
const ROOM_SCRIPTS := [
	preload("res://scripts/room_label.gd"),
	preload("res://scripts/room_dojo.gd"),
	preload("res://scripts/room_verse.gd"),
	preload("res://scripts/room_unplayed.gd"),
	preload("res://scripts/room_smoothed.gd"),
]
const ROOM_IDS := [&"label", &"practice", &"verse", &"unplayed", &"smoothed"]
const WorldMapScript := preload("res://scripts/world_map.gd")
const GrayboxScript := preload("res://scripts/room_graybox.gd")
const PressingScript := preload("res://scripts/pressing_state.gd")

var player: CharacterBody2D
var camera: Camera2D
var audio: Node
var room: Node2D
var room_idx := 0
var room_entry_id: StringName = &"default"
var progression: RefCounted
var inventory: CanvasLayer
var world: RefCounted
## The planned room currently grayed in, or empty while the hand-built
## prototype loop is running. Exactly one of the two is live at a time.
var world_room_id: StringName = &""
var pressing: RefCounted
var _transition_pending := false

var info: Label
var feedback: Label
var status: Label
var crackle_bar: ColorRect
var _fb_t := 0.0
var _shake := 0.0
var _hits_taken := 0

const SHATTER_LINES := [
	"SHATTERED — it was going to say: BRIGHTLY",
	"SHATTERED — it was going to say: OH",
	"SHATTERED — it was going to say: STAY",
]
var _shatter_i := 0

func _ready() -> void:
	randomize()
	_setup_input()
	progression = ProgressionScript.new()
	progression.connect("refrain_unlocked", _on_refrain_unlocked)
	progression.connect("technique_discovered", _on_technique_discovered)

	pressing = PressingScript.new()
	pressing.connect("side_changed", _on_side_changed)
	pressing.connect("side_ended", _on_side_ended)

	world = WorldMapScript.new()
	if not bool(world.call("load_from")):
		world = null

	audio = AudioScript.new()
	add_child(audio)

	player = SkipScript.new()
	player.progression = progression
	player.struck.connect(_on_struck)
	player.on_beat.connect(_on_beat)
	player.took_hit.connect(_on_player_hit)
	add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	player.add_child(camera)
	camera.make_current()

	_build_hud()
	inventory = InventoryMenuScript.new()
	inventory.progression = progression
	inventory.shine_source = player
	inventory.can_open = _can_open_inventory
	add_child(inventory)
	_load_room(0)

func _process(delta: float) -> void:
	if OS.is_debug_build() and not _transition_pending:
		if Input.is_action_just_pressed("switch_room"):
			_debug_cycle_room()
		if Input.is_action_just_pressed("world_map"):
			_debug_toggle_world()
		if Input.is_action_just_pressed("debug_grant"):
			_debug_grant_refrains()
	if Input.is_action_just_pressed("flip"):
		_try_flip()
	pressing.call("advance", delta)
	if Input.is_action_just_pressed("restart"):
		_respawn()
	if player.global_position.y > room.death_y:
		_respawn()
		_flash("the deep keeps what falls. (respawned)")

	if _fb_t > 0.0:
		_fb_t -= delta
		feedback.modulate.a = clampf(_fb_t / 0.4, 0.0, 1.0)

	if _shake > 0.0:
		_shake = maxf(_shake - delta * 26.0, 0.0)
		camera.offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	else:
		camera.offset = Vector2.ZERO

	# living HUD + audio beds
	audio.set_crackle(player.noise if not player.hooded else 0.0)
	audio.set_hooded(player.hooded)
	crackle_bar.size.x = 140.0 * clampf(player.noise, 0.0, 1.0)
	crackle_bar.color = Color(0.9, 0.25, 0.5) if not player.hooded else Color(0.55, 0.52, 0.58)
	status.text = "crackle %s   shine %d   hits taken %d%s   %s\n%s" % [
		"·" if player.noise < 0.05 else "",
		player.shine,
		_hits_taken,
		"   [HOODED]" if player.hooded else "",
		_pressing_text(),
		progression.call("hud_text"),
	]

func _pressing_text() -> String:
	if not bool(progression.call("has_refrain", ProgressionScript.Refrain.JUMP_CUT)):
		return ""
	if not bool(pressing.call("on_b_side")):
		return "side A   (rewound %d%%)" % int(float(pressing.call("runtime_ratio")) * 100.0)
	var warning := " !!" if bool(pressing.call("is_running_out")) else ""
	return "SIDE B — %.1fs left%s" % [float(pressing.get("runtime_left")), warning]

# -- rooms --------------------------------------------------------------------

func _load_room(i: int, entry_id: StringName = &"default") -> void:
	if i < 0 or i >= ROOM_SCRIPTS.size():
		push_error("Unknown prototype room index: %d" % i)
		return
	room_idx = i
	world_room_id = &""
	_swap_room(ROOM_SCRIPTS[i].new(), entry_id)

## Grays in one room of the planned world. Hand-built rooms always win: Main
## only reaches here for ids the prototype loop does not claim.
func _load_world_room(id: StringName, entry_id: StringName = &"default") -> void:
	if world == null or not bool(world.call("has_room", id)):
		push_error("Unknown world room: %s" % id)
		return
	var graybox := GrayboxScript.new()
	graybox.progression = progression
	if not graybox.configure(world, id):
		graybox.free()
		return
	world_room_id = id
	_swap_room(graybox, entry_id)

func _swap_room(next_room: Node2D, entry_id: StringName) -> void:
	room_entry_id = entry_id
	if room != null:
		remove_child(room)
		room.queue_free()
	room = next_room
	room.progression = progression
	room.refrain_collected.connect(_on_refrain_collected)
	room.route_requested.connect(_on_route_requested)
	room.route_blocked.connect(_on_route_blocked)
	add_child(room)
	room.call("apply_side", pressing.side)
	_apply_room_air()

	# wire the room's listeners after they enter the tree
	call_deferred("_wire_room")

	_apply_room_palette()
	camera.limit_left = int(room.cam_limits.position.x)
	camera.limit_top = int(room.cam_limits.position.y)
	camera.limit_right = int(room.cam_limits.position.x + room.cam_limits.size.x)
	camera.limit_bottom = int(room.cam_limits.position.y + room.cam_limits.size.y)

	_respawn()
	var controls := "[A/D] move  [SPACE] jump  [J] strike  [K hold] hood  [L hold] kneel  [E/Y] passage  [I/START] book  [R] respawn"
	if OS.is_debug_build():
		controls += "  [TAB] debug room  [M] planned world  [G] grant refrains"
	var banner := "DEAD WAX — M1"
	if not world_room_id.is_empty():
		banner = "DEAD WAX — planned world (graybox %d/%d)" % [
			int(world.get("room_order").find(world_room_id)) + 1,
			int(world.call("room_count")),
		]
	info.text = "%s\nROOM: %s\n%s\n%s" % [banner, room.band_name, room.band_desc, controls]

func _wire_room() -> void:
	for n in get_tree().get_nodes_in_group("hears_strikes"):
		if not room.is_ancestor_of(n):
			continue
		if n is Node and n.has_signal("parried") and not n.parried.is_connected(_on_parried):
			n.parried.connect(_on_parried)
			n.shattered.connect(_on_shattered)
			n.bout_won.connect(_on_bout_won)
		if n.has_signal("opened") and not n.opened.is_connected(_on_door_opened):
			n.opened.connect(_on_door_opened)
		if n.has_signal("freed") and not n.freed.is_connected(_on_freed):
			n.freed.connect(_on_freed)

# -- the pressing -------------------------------------------------------------

## The air a room presents is its authored A-side read through the current
## side. On the A-side these are exactly the room's own values, so nothing
## about the prototype loop changes until the player turns the wax over.
func _apply_room_air() -> void:
	var density: float = pressing.call("effective_density", room.air_density)
	player.air_density = density
	player.air_strikes_max = pressing.call(
		"effective_air_strikes", room.air_strikes_max, room.air_density
	)
	if bool(pressing.call("on_b_side")):
		# Weight follows the air it is read through, landing on The Unplayed's
		# thick profile wherever the far face is fully unplayed.
		player.gravity_mult = lerpf(1.0, 0.8, density)
		player.fall_cap_mult = lerpf(1.0, 0.62, density)
		player.groove_mult = lerpf(1.0, 1.3, density)
	else:
		player.gravity_mult = room.gravity_mult
		player.fall_cap_mult = room.fall_cap_mult
		player.groove_mult = room.groove_mult
	player.refill_air_strikes()

func _apply_room_palette() -> void:
	var paper: Color = room.ink if bool(pressing.call("on_b_side")) else room.bg_color
	RenderingServer.set_default_clear_color(paper)
	_apply_hud_palette(paper)

## The HUD is printed on whatever the room is printed on. Dark wax — The
## Unplayed, or any room read from its far face — needs the plate inverted or
## the readout sinks into the background.
func _apply_hud_palette(paper: Color) -> void:
	if info == null or status == null:
		return
	var dark_paper := paper.get_luminance() < 0.45
	var text := Color(0.94, 0.92, 0.88) if dark_paper else Color(0.1, 0.09, 0.09)
	var outline := Color(0.06, 0.05, 0.07, 0.75) if dark_paper else Color(1, 1, 1, 0.55)
	for plate in [info, status]:
		plate.add_theme_color_override("font_color", text)
		plate.add_theme_color_override("font_outline_color", outline)

## Turning the pressing over is a Jump-Cut. Without it the input is inert and
## says nothing: an unearned Refrain is never announced before it is found.
func _try_flip() -> void:
	if _transition_pending:
		return
	if not bool(progression.call("has_refrain", ProgressionScript.Refrain.JUMP_CUT)):
		return
	if not bool(pressing.call("flip")):
		_flash("not enough side left to turn.")

func _on_side_changed(side: int) -> void:
	room.call("apply_side", side)
	_apply_room_air()
	_apply_room_palette()
	audio.play("flip", -8.0, 1.0 if side == PressingScript.Side.B else 1.18)
	_shake = 6.0
	if side == PressingScript.Side.B:
		_flash("THE B-SIDE — nobody played this.")
	else:
		_flash("back to the side that got played.")

func _on_side_ended() -> void:
	_flash("the side ran out. the needle lifts.")

# -- debug traversal ----------------------------------------------------------

## Cycles whichever atlas is live: the five prototype rooms, or the planned
## world in map order. Debug builds only — normal play uses passages.
func _debug_cycle_room() -> void:
	if world_room_id.is_empty():
		_load_room((room_idx + 1) % ROOM_SCRIPTS.size(), &"default")
		return
	var order: Array = world.get("room_order")
	_load_world_room(order[(order.find(world_room_id) + 1) % order.size()], &"default")

## Debug builds only. The Refrains are scattered deep in the planned world, so
## reaching one to feel-test it costs more than the test is worth.
func _debug_grant_refrains() -> void:
	var granted := 0
	for refrain in ProgressionScript.REFRAIN_ORDER:
		if bool(progression.call("unlock_refrain", refrain)):
			granted += 1
	_apply_room_air()
	if granted == 0:
		_flash("every Refrain is already carried.")

func _debug_toggle_world() -> void:
	if not world_room_id.is_empty():
		_load_room(0, &"default")
		_flash("back to the prototype loop.")
		return
	if world == null:
		_flash("the planned world did not load.")
		return
	_load_world_room(world.call("spawn_room_id"), &"default")
	_flash("the planned world, grayed in.")

func _respawn() -> void:
	player.global_position = room.entry_position(room_entry_id)
	player.velocity = Vector2.ZERO
	player.refill_air_strikes()
	camera.reset_smoothing()

# -- events -------------------------------------------------------------------

func _on_struck(pos: Vector2, big: bool, launched: bool) -> void:
	var w := WaveScript.new()
	w.big = big
	w.max_r = 190.0 * (0.55 + 0.6 * player.air_density) * (1.35 if big else 1.0)
	w.life = 0.26 + 0.18 * player.air_density
	add_child(w)
	w.global_position = pos
	audio.play("strike", -8.0, randf_range(0.96, 1.05))
	if big:
		_shake = 7.0
	elif launched:
		_shake = 3.5
	# everything with ears gets told
	for n in get_tree().get_nodes_in_group("hears_strikes"):
		n.on_player_strike(pos, big)

func _on_beat() -> void:
	audio.play("onbeat", -6.0)
	_flash("ON BEAT !!")

func _on_parried() -> void:
	_shake = 9.0
	_flash("RUNG BACK !!")

func _on_shattered(pos: Vector2) -> void:
	_shake = 11.0
	_flash(SHATTER_LINES[_shatter_i % SHATTER_LINES.size()])
	_shatter_i += 1
	_word_splatter(pos)

func _on_bout_won() -> void:
	_flash("the bout is yours. he'd nod. once.")

func _on_door_opened() -> void:
	var discovered := bool(
		progression.call("discover_technique", ProgressionScript.Technique.COUNT_IN)
	)
	if not discovered:
		_flash("it was listening. it always was.")

func _on_freed(_pos: Vector2) -> void:
	_flash("heard at last. it goes — and stays gone.")

func _on_player_hit() -> void:
	_hits_taken += 1
	_shake = 6.0

func _on_refrain_collected(refrain: int) -> void:
	progression.call("unlock_refrain", refrain)

func _on_route_requested(target_room: StringName, target_entry: StringName) -> void:
	if _transition_pending:
		return
	if ROOM_IDS.find(target_room) < 0 and (
		world == null or not bool(world.call("has_room", target_room))
	):
		push_error("Unknown route target: %s" % target_room)
		return
	_transition_pending = true
	audio.play("door", -10.0)
	call_deferred("_complete_route_transition", target_room, target_entry)

func _complete_route_transition(target_room: StringName, target_entry: StringName) -> void:
	var target_index := ROOM_IDS.find(target_room)
	if target_index >= 0:
		_load_room(target_index, target_entry)
	else:
		_load_world_room(target_room, target_entry)
	_transition_pending = false

func _on_route_blocked(message: String) -> void:
	_flash(message)

func _can_open_inventory() -> bool:
	return not _transition_pending

func _on_refrain_unlocked(refrain: int) -> void:
	audio.play("freed", -7.0)
	if refrain == ProgressionScript.Refrain.GATHER:
		player.refill_air_strikes()
		_flash("GATHER — one breath follows you into the dry.")
	else:
		_flash("%s — remembered." % progression.call("refrain_label", refrain))

func _on_technique_discovered(technique: int) -> void:
	_flash("%s — learned, never locked." % progression.call("technique_label", technique))

func _word_splatter(pos: Vector2) -> void:
	var words := ["BRIGHT", "LY", "OH", "!!"]
	for i in words.size():
		var l := Label.new()
		l.text = words[i]
		l.add_theme_font_size_override("font_size", 22)
		l.add_theme_color_override("font_color", Color(0.9, 0.25, 0.5))
		l.position = pos + Vector2(randf_range(-30, 30), randf_range(-60, -10))
		add_child(l)
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(l, "position", l.position + Vector2(randf_range(-90, 90), randf_range(-140, -40)), 0.9)
		tw.tween_property(l, "modulate:a", 0.0, 0.9)
		tw.chain().tween_callback(l.queue_free)

func _flash(text: String) -> void:
	feedback.text = text
	feedback.modulate.a = 1.0
	_fb_t = 1.4

# -- hud ----------------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	info = Label.new()
	info.position = Vector2(14, 10)
	info.add_theme_font_size_override("font_size", 15)
	info.add_theme_color_override("font_color", Color(0.1, 0.09, 0.09))
	info.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.55))
	info.add_theme_constant_override("outline_size", 6)
	layer.add_child(info)

	feedback = Label.new()
	feedback.position = Vector2(460, 250)
	feedback.add_theme_font_size_override("font_size", 34)
	feedback.add_theme_color_override("font_color", Color(0.95, 0.25, 0.55))
	feedback.add_theme_color_override("font_outline_color", Color(0.1, 0.09, 0.09, 0.8))
	feedback.add_theme_constant_override("outline_size", 8)
	feedback.modulate.a = 0.0
	layer.add_child(feedback)

	status = Label.new()
	status.position = Vector2(14, 654)
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color(0.1, 0.09, 0.09))
	status.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.55))
	status.add_theme_constant_override("outline_size", 5)
	layer.add_child(status)

	crackle_bar = ColorRect.new()
	crackle_bar.position = Vector2(14, 702)
	crackle_bar.size = Vector2(0, 8)
	crackle_bar.color = Color(0.9, 0.25, 0.5)
	layer.add_child(crackle_bar)

# -- input --------------------------------------------------------------------

func _setup_input() -> void:
	_action("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("move_up", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("move_down", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("jump", [KEY_SPACE], [JOY_BUTTON_A])
	_action("strike", [KEY_J, KEY_X], [JOY_BUTTON_X])
	_action("lift", [KEY_K, KEY_C], [JOY_BUTTON_B])
	_action("set", [KEY_L], [JOY_BUTTON_LEFT_SHOULDER])
	_action("flip", [KEY_F], [JOY_BUTTON_RIGHT_SHOULDER])
	_action("enter_passage", [KEY_E], [JOY_BUTTON_Y])
	_action("inventory", [KEY_I], [JOY_BUTTON_START])
	_action("restart", [KEY_R], [JOY_BUTTON_BACK])
	_action("switch_room", [KEY_TAB])
	_action("world_map", [KEY_M])
	_action("debug_grant", [KEY_G])

func _action(action_name: String, keys: Array, pad_buttons: Array = [], axes: Array = []) -> void:
	if InputMap.has_action(action_name):
		InputMap.erase_action(action_name)
	InputMap.add_action(action_name, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action_name, e)
	for b in pad_buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action_name, j)
	for ax in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = ax[0]
		m.axis_value = ax[1]
		InputMap.action_add_event(action_name, m)
