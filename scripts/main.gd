extends Node2D
## DEAD WAX — campaign ownership, room transitions, menus and checkpoints.

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
const PressScript := preload("res://scripts/press.gd")
const ChapterScript := preload("res://scripts/campaign.gd")
const MenuScript := preload("res://scripts/game_menu.gd")
const SaveScript := preload("res://scripts/save_store.gd")
const EconomyScript := preload("res://scripts/economy_state.gd")
const ShopScript := preload("res://scripts/shop_menu.gd")
const HudMotionScript := preload("res://scripts/hud_motion.gd")
const MapStateScript := preload("res://scripts/map_state.gd")
const MapMenuScript := preload("res://scripts/map_menu.gd")

const MARGIN := 22.0
const NEEDLE_HEALTH := 3

var player: CharacterBody2D
var camera: Camera2D
var audio: Node
var room: Node2D
var room_idx := 0
var room_entry_id: StringName = &"default"
var progression: RefCounted
var inventory: CanvasLayer
var economy: RefCounted
var shop: CanvasLayer
var _purchasing := false
var _shop_closing := false
var map_state: RefCounted
var map_menu: CanvasLayer
var _map_closing := false
var world: RefCounted
## The authored campaign room, or a graybox id in development mode. Empty
## only while the original five-room mechanics loop is active.
var world_room_id: StringName = &""
var pressing: RefCounted
var _transition_pending := false
## Explicit opt-in only. Running from the editor is still the real game.
var development_mode := false
var save_path := "user://deadwax-save.json"
var settings_path := "user://deadwax-settings.cfg"
var game_menu: CanvasLayer
var save_store: RefCounted
var encounters: Dictionary = {}
var chapter_complete := false
var _has_session := false
var _save_queued := false
var _save_failed := false
var _last_saved_shine := 0
var _save_message := ""
var _save_message_time := 0.0
var _health := NEEDLE_HEALTH
var _respawn_pending := false
var _settings := {"volume": 0.8, "reduced_motion": false, "fullscreen": false}

var title: Label
var subtitle: Label
var title_rule: ColorRect
var controls_note: Label
var masthead: ColorRect
var footer_stock: ColorRect
var feedback: Label
var status: Label
var paper: ColorRect
var crackle_bar: ColorRect
var hud_motion: Node
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
	development_mode = development_mode or (OS.is_debug_build() and "--dev-rooms" in OS.get_cmdline_user_args())
	if not development_mode and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Dead Wax — Side One")
	_setup_input()
	progression = ProgressionScript.new()
	economy = EconomyScript.new()
	map_state = MapStateScript.new()
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
	player.economy = economy
	player.struck.connect(_on_struck)
	player.on_beat.connect(_on_beat)
	player.took_hit.connect(_on_player_hit)
	player.shine_earned.connect(_on_shine_earned)
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
	inventory.economy = economy
	inventory.map_state = map_state
	inventory.can_open = _can_open_inventory
	add_child(inventory)
	inventory.opened.connect(_on_inventory_opened)
	inventory.map_requested.connect(_open_map_from_book)
	shop = ShopScript.new()
	add_child(shop)
	shop.purchase_requested.connect(_purchase_item)
	shop.close_requested.connect(_close_shop)
	map_menu = MapMenuScript.new()
	add_child(map_menu)
	map_menu.close_requested.connect(_close_map)
	if development_mode:
		_has_session = true
		_load_room(0)
		return
	save_store = SaveScript.new(save_path)
	game_menu = MenuScript.new()
	add_child(game_menu)
	game_menu.new_game_requested.connect(_new_game)
	game_menu.continue_requested.connect(_continue_game)
	game_menu.resume_requested.connect(_resume_game)
	game_menu.title_requested.connect(_return_to_title)
	game_menu.quit_requested.connect(_quit_game)
	game_menu.settings_changed.connect(_change_settings)
	_load_settings()
	_load_world_room(ChapterScript.START_ROOM)
	get_tree().auto_accept_quit = false
	_show_title()

func _exit_tree() -> void:
	if game_menu != null and get_tree() != null:
		get_tree().paused = false
		get_tree().auto_accept_quit = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not development_mode:
		_quit_game()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map") and not event.is_echo():
		_open_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("trade") and not event.is_echo():
		_open_shop()
		if shop.is_open:
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("pause_game") and not event.is_echo():
		if game_menu != null and not game_menu.is_open and _can_open_inventory():
			_pause_game()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if room == null:
		return
	if development_mode and OS.is_debug_build() and not _transition_pending:
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
		_flash("the needle finds you again.")

	if _fb_t > 0.0:
		_fb_t -= delta
		feedback.modulate.a = clampf(_fb_t / 0.4, 0.0, 1.0)

	if bool(_settings.reduced_motion):
		_shake = 0.0
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
	if development_mode:
		status.text = "crackle   shine %d   hits taken %d   %s\n%s" % [player.shine, _hits_taken, _pressing_text(), progression.call("hud_text")]
	else:
		_save_message_time = maxf(0, _save_message_time - delta)
		var objective := String(room.get("objective_label")) if "objective_label" in room else ""
		subtitle.text = objective
		status.text = "NEEDLE %d/%d     %s   SHINE %02d%s" % [_health, _max_health(), "HUSH" if player.hooded else "CRACKLE", player.shine, "   " + _pressing_text() if not _pressing_text().is_empty() else ""]
		controls_note.text = _save_message if _save_message_time > 0 else _controls_text()
		if player.shine != _last_saved_shine:
			_queue_save()

func _controls_text() -> String:
	var note := "I / START · THE BOOK     ESC / BACK · PAUSE"
	return "M / D-PAD DOWN · MAP     " + note if map_state.owned else note

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
	if not development_mode:
		if not ChapterScript.has_room(id):
			push_error("This room is not part of the authored chapter: %s" % id)
			return
		world_room_id = id
		_swap_room(ChapterScript.create_room(id), entry_id)
		return
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
	_capture_encounters()
	room_entry_id = entry_id
	if room != null:
		remove_child(room)
		room.queue_free()
	room = next_room
	room.progression = progression
	if "session_outcomes" in room:
		room.set("session_outcomes", encounters)
	if "map_state" in room:
		room.set("map_state", map_state)
	if room.has_signal("map_collected"):
		room.connect("map_collected", _on_map_collected)
	if not development_mode:
		map_state.visit(world_room_id)
	if not development_mode and room.room_id == &"the_arm":
		encounters["the_arm/gallery_shortcut"] = "opened"
	room.refrain_collected.connect(_on_refrain_collected)
	room.route_requested.connect(_on_route_requested)
	room.route_blocked.connect(_on_route_blocked)
	add_child(room)
	if room_entry_id != &"default" and not room.entry_points.has(room_entry_id):
		room_entry_id = &"default"
	if not development_mode:
		_restore_encounters()
		if chapter_complete:
			for child in room.get_children():
				if child.is_in_group("chapter_endpoint"):
					child.set("used", true)
					room.set("objective_label", "The Tonearm is quiet. The way home is still yours.")
		if room.has_signal("chapter_completed"):
			room.connect("chapter_completed", _on_chapter_completed)
	room.call("lay_backdrop", room.cam_limits)
	room.call("apply_side", pressing.side)
	room.call("set_scenery_motion", bool(_settings.reduced_motion))
	_apply_room_air()
	_sync_home_song()

	# wire the room's listeners after they enter the tree
	call_deferred("_wire_room")

	_apply_room_palette()
	camera.limit_left = int(room.cam_limits.position.x)
	camera.limit_top = int(room.cam_limits.position.y)
	camera.limit_right = int(room.cam_limits.position.x + room.cam_limits.size.x)
	camera.limit_bottom = int(room.cam_limits.position.y + room.cam_limits.size.y)

	_respawn()
	title.text = String(room.band_name).to_upper()
	title_rule.size.x = maxf(title.get_minimum_size().x, 90.0)
	var imprint := String(room.band_desc)
	if development_mode and not world_room_id.is_empty():
		imprint = "GRAYBOX %d/%d · %s" % [
			int(world.get("room_order").find(world_room_id)) + 1,
			int(world.call("room_count")),
			imprint,
		]
	subtitle.text = imprint
	masthead.size = Vector2(
		maxf(title.get_minimum_size().x, subtitle.get_minimum_size().x) + MARGIN * 2.0,
		78.0
	)
	if development_mode and OS.is_debug_build():
		controls_note.text = (
			"[A/D] move  [SPACE] jump  [J] strike  [K] hood  [L] kneel  [F] flip"
			+ "  [E] passage  [I] book  [R] respawn  [TAB] room  [M] world  [G] refrains"
		)
	else:
		controls_note.text = _controls_text()
		masthead.size.x = 660
		_queue_save()
	hud_motion.present_room()

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
		if not development_mode and n.has_meta("chapter_state_id") and not n.has_meta("save_wired"):
			n.set_meta("save_wired", true)
			var key := "%s/%s" % [room.room_id, n.get_meta("chapter_state_id")]
			if n.has_signal("opened"):
				n.connect("opened", _remember_encounter.bind(key, "opened"))
			if n.has_signal("freed"):
				n.connect("freed", _remember_positioned.bind(key, "freed"))
			if n.has_signal("shattered"):
				n.connect("shattered", _remember_positioned.bind(key, "shattered"))
			if n.has_signal("bout_won"):
				n.connect("bout_won", _remember_encounter.bind(key, "won"))

# -- a saved pressing ---------------------------------------------------------

func _capture_encounters() -> void:
	if development_mode or room == null:
		return
	for n in room.get_children():
		if not n.has_meta("chapter_state_id"):
			continue
		var key := "%s/%s" % [room.room_id, n.get_meta("chapter_state_id")]
		if "is_open" in n and bool(n.get("is_open")):
			encounters[key] = "opened"
		elif "done" in n and bool(n.get("done")):
			encounters[key] = "polished"

func _restore_encounters() -> void:
	if room.has_method("restore_encounters"):
		room.call("restore_encounters", encounters)

func _remember_positioned(_pos: Vector2, key: String, outcome: String) -> void:
	_remember_encounter(key, outcome)

func _remember_encounter(key: String, outcome: String) -> void:
	encounters[key] = outcome
	if key == "the_stalls/loft_voice" and outcome == "freed":
		_flash("A LOST PHRASE — carried home.")
		_sync_home_song()
	_queue_save()

func _sync_home_song() -> void:
	if audio != null:
		audio.set_home_song(not development_mode and _has_session
			and world_room_id in [&"horn_plaza", &"headshell"]
			and String(encounters.get("the_stalls/loft_voice", "")) == "freed")

func _queue_save() -> void:
	if development_mode or not _has_session or _save_queued:
		return
	_save_queued = true
	call_deferred("_flush_save")

func _flush_save() -> void:
	_save_queued = false
	_persist_session()

func _persist_session() -> bool:
	if development_mode or not _has_session or save_store == null:
		return true
	_capture_encounters()
	var data := {
		"version": 1, "room_id": String(world_room_id), "entry_id": String(room_entry_id),
		"progression": progression.call("snapshot"), "shine": player.shine,
		"completed": chapter_complete, "encounters": encounters.duplicate(true),
		"settings": _settings.duplicate(true),
		"purchases": economy.call("snapshot").purchases,
		"map": map_state.snapshot(),
	}
	var saved := bool(save_store.call("save_game", data))
	if saved and _save_failed and game_menu != null:
		game_menu.call("set_notice", "")
	_save_failed = not saved
	_last_saved_shine = player.shine
	_save_message = "PRESSING SAVED" if saved else "COULD NOT SAVE · try again from the pause menu"
	_save_message_time = 2.0 if saved else 8.0
	if not saved and game_menu != null and game_menu.is_open:
		game_menu.call("set_notice", "Could not save your pressing. Resume and try again before leaving.")
	return saved

func _new_game() -> void:
	map_menu.close_map()
	_map_closing = false
	shop.call("close_shop")
	_shop_closing = false
	_has_session = false
	# The outgoing room must not copy its finished encounters into a new run.
	if room != null:
		remove_child(room)
		room.queue_free()
		room = null
	encounters.clear()
	chapter_complete = false
	progression.call("reset")
	pressing.call("reset")
	economy.call("reset")
	map_state.reset()
	_apply_purchases()
	_reset_player()
	_load_world_room(ChapterScript.START_ROOM)
	_has_session = true
	_sync_home_song()
	_resume_game()
	# Rotate this new pressing into the recovery copy too. A damaged primary
	# after starting over must never resurrect the previous playthrough.
	if _persist_session():
		_persist_session()
	_flash("something below is still playing.")

func _continue_game() -> void:
	var data: Dictionary = save_store.call("load_game")
	if data.is_empty() or not ChapterScript.has_room(StringName(data.get("room_id", ""))):
		game_menu.call("set_notice", "That pressing could not be read. You can begin a new one.")
		return
	map_menu.close_map()
	_map_closing = false
	shop.call("close_shop")
	_shop_closing = false
	_has_session = false
	if room != null:
		remove_child(room)
		room.queue_free()
		room = null
	encounters = data.get("encounters", {}).duplicate(true)
	chapter_complete = ChapterScript.saved_completion(data)
	progression.call("restore_snapshot", data.progression)
	pressing.call("reset")
	economy.call("restore", data.shine, data.get("purchases", []))
	map_state.restore_snapshot(data.get("map", {"owned": false, "visited": []}))
	_apply_purchases()
	_last_saved_shine = player.shine
	_reset_player()
	_load_world_room(StringName(data.room_id), StringName(data.entry_id))
	_has_session = true
	_sync_home_song()
	_resume_game()
	# Repair the old demo's ending flag and any obsolete arrival on disk only
	# after the saved room, progress and encounter choices have been restored.
	_queue_save()

func _reset_player() -> void:
	player.velocity = Vector2.ZERO
	player.noise = 0.0
	player.hooded = false
	player.setting = false
	player.last_strike_ms = -100000
	for key in ["_stagger", "_coyote", "_buffer", "_strike_cd", "_strike_buffer", "_recover", "_hit_flash"]:
		player.set(key, 0.0)
	_hits_taken = 0
	_shake = 0
	_fb_t = 0
	feedback.modulate.a = 0

func _show_title() -> void:
	var data: Dictionary = save_store.call("load_game")
	var valid := not data.is_empty() and ChapterScript.has_room(StringName(data.get("room_id", "")))
	var label := String(data.get("room_id", "")).replace("_", " ").to_upper()
	game_menu.call("show_title", valid, label)
	if not valid and (not data.is_empty() or not String(save_store.get("last_error")).is_empty()):
		game_menu.call("set_notice", "Your saved pressing could not be read. Begin a new game to start again.")
	get_tree().paused = true
	audio.set_crackle(0.0)

func _pause_game() -> void:
	if _transition_pending or inventory.call("is_open") or shop.is_open or _shop_closing or map_menu.is_open or _map_closing:
		return
	game_menu.call("show_pause")
	get_tree().paused = true
	audio.set_crackle(0.0)
	_persist_session()

func _resume_game() -> void:
	game_menu.call("close_menu")
	# Defer so the confirming button cannot also become a jump or passage.
	call_deferred("_unpause_game")

func _unpause_game() -> void:
	if game_menu != null and not game_menu.is_open and not shop.is_open and not inventory.call("is_open") and not map_menu.is_open and not _map_closing:
		get_tree().paused = false

func _return_to_title() -> void:
	if not _persist_session():
		return
	_has_session = false
	_show_title()

func _quit_game() -> void:
	if not _persist_session():
		if inventory.call("is_open"):
			inventory.call("close_inventory")
		shop.call("close_shop")
		map_menu.close_map()
		game_menu.call("show_pause")
		get_tree().paused = true
		game_menu.call("set_notice", "Could not save, so your game is still open. Resume and try again before leaving.")
		return
	get_tree().quit()

func _on_chapter_completed() -> void:
	if chapter_complete or not ChapterScript.encounter_resolved(encounters):
		return
	chapter_complete = true
	audio.play("freed", -8.0, 0.7)
	room.set("objective_label", "The Tonearm is quiet. The way home is still yours.")
	call_deferred("_show_chapter_ending")

func _show_chapter_ending() -> void:
	game_menu.call("show_ending", String(encounters.get(ChapterScript.FINAL_ENCOUNTER, "")))
	get_tree().paused = true
	audio.set_crackle(0.0)
	_persist_session()

func _on_inventory_opened() -> void:
	audio.set_crackle(0.0)
	_queue_save()

# -- the folded map ----------------------------------------------------------

func _on_map_collected() -> void:
	if development_mode or not _has_session or world_room_id != &"headshell" or not map_state.collect():
		return
	audio.play("freed", -11.0, 1.15)
	_flash("MAP FOUND — M / D-PAD DOWN · open")
	_queue_save()

func _open_map() -> void:
	if development_mode or not _can_open_inventory() or inventory.is_open() or get_tree().paused:
		return
	if not map_state.owned:
		_flash("A folded map waits in the Headshell.")
		return
	_show_map()

func _open_map_from_book() -> void:
	if development_mode or not map_state.owned or not inventory.is_open() or not _can_open_inventory():
		return
	inventory.close_inventory()
	_show_map()

func _show_map() -> void:
	var snapshot: Dictionary = map_state.snapshot()
	snapshot["current_room"] = String(world_room_id)
	map_menu.show_map(snapshot)
	get_tree().paused = true
	audio.set_crackle(0.0)
	_persist_session()

func _close_map() -> void:
	if not map_menu.is_open or _map_closing:
		return
	map_menu.close_map()
	_map_closing = true
	call_deferred("_finish_map_close")

func _finish_map_close() -> void:
	await get_tree().process_frame
	_map_closing = false
	if map_menu.is_open or shop.is_open or (game_menu != null and game_menu.is_open) or inventory.is_open():
		return
	player.set("_buffer", 0.0)
	get_tree().paused = false

# -- Shine and the Bootlegger -------------------------------------------------

func _max_health() -> int:
	return int(economy.call("max_health")) if economy != null else NEEDLE_HEALTH

func _apply_purchases() -> void:
	player.hood_speed_mult = float(economy.call("hood_speed_multiplier"))
	player.warm_thread = bool(economy.call("has_item", &"warm_thread"))
	player.queue_redraw()

func _shop_snapshot() -> Dictionary:
	var snapshot: Dictionary = economy.call("snapshot")
	snapshot["health"] = _health
	snapshot["max_health"] = _max_health()
	return snapshot

func _at_bootlegger() -> bool:
	if development_mode or world_room_id != &"bootlegger" or room == null or not player.is_on_floor():
		return false
	var resident := room.get_node_or_null("Bootlegger") as Node2D
	return resident != null and player.global_position.distance_to(resident.global_position) <= 140.0

func _open_shop() -> void:
	if not _can_open_inventory() or inventory.call("is_open") or get_tree().paused or not _at_bootlegger():
		return
	player.velocity = Vector2.ZERO
	player.set("_buffer", 0.0)
	shop.call("show_shop", _shop_snapshot())
	get_tree().paused = true
	audio.set_crackle(0.0)
	audio.play("tick", -17.0, 0.8)
	_persist_session()

func _close_shop() -> void:
	if not shop.is_open or _shop_closing:
		return
	shop.call("close_shop")
	_shop_closing = true
	# The closing button belongs to the stall, including controller A/Space.
	# Keep gameplay paused through this input frame before giving it back.
	call_deferred("_finish_shop_close")

func _finish_shop_close() -> void:
	await get_tree().process_frame
	_shop_closing = false
	if shop.is_open or (game_menu != null and game_menu.is_open) or inventory.call("is_open") or map_menu.is_open or _map_closing:
		return
	player.set("_buffer", 0.0)
	get_tree().paused = false

func _purchase_item(item_id: StringName) -> bool:
	if _purchasing or not _has_session or not shop.is_open or _shop_closing or _transition_pending or not _at_bootlegger():
		return false
	if not bool(economy.call("can_purchase", item_id)):
		shop.call("refresh_shop", _shop_snapshot(), "That tape is already yours, or you need more Shine.")
		return false
	_purchasing = true
	var before: Dictionary = economy.call("snapshot")
	var previous_cap := _max_health()
	economy.call("purchase", item_id)
	# The completed purchase and its debit share one validated checkpoint.
	# Effects and a success sound are offered only after that write succeeds.
	if not _persist_session():
		economy.call("restore", before.shine, before.purchases)
		_last_saved_shine = player.shine
		shop.call("refresh_shop", _shop_snapshot(), "Could not save. Your Shine is still yours. Try again.")
		_purchasing = false
		return false
	_apply_purchases()
	_health = mini(_health + _max_health() - previous_cap, _max_health())
	shop.call("refresh_shop", _shop_snapshot(), "Yours now. Worn in, and made to last.")
	audio.play("polish", -7.0, 0.85)
	_purchasing = false
	return true

func _on_shine_earned(amount: int) -> void:
	hud_motion.show_shine(amount)
	_queue_save()

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var volume: Variant = config.get_value("audio", "volume", 0.8)
		if (volume is float or volume is int) and is_finite(float(volume)):
			_settings.volume = clampf(float(volume), 0.0, 1.0)
		for key in ["reduced_motion", "fullscreen"]:
			var value: Variant = config.get_value("display", key, false)
			if value is bool:
				_settings[key] = value
	game_menu.settings = _settings.duplicate(true)
	_apply_settings()

func _change_settings(values: Dictionary) -> void:
	_settings = values.duplicate(true)
	_apply_settings()
	var config := ConfigFile.new()
	config.set_value("audio", "volume", _settings.volume)
	config.set_value("display", "reduced_motion", _settings.reduced_motion)
	config.set_value("display", "fullscreen", _settings.fullscreen)
	if config.save(settings_path) != OK:
		game_menu.call("set_notice", "These settings work now, but could not be saved for next time.")
	_queue_save()

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(_settings.volume))))
	AudioServer.set_bus_mute(0, float(_settings.volume) <= 0.0)
	camera.position_smoothing_enabled = not bool(_settings.reduced_motion)
	for interface in [game_menu, inventory, shop, map_menu, hud_motion]:
		if interface != null:
			interface.call("set_reduced_motion", bool(_settings.reduced_motion))
	if room != null:
		room.call("set_scenery_motion", bool(_settings.reduced_motion))
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if bool(_settings.fullscreen) else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)

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
	if player != null:
		player.call("set_page", paper)

## The HUD is printed in the room's own ink, on the room's own stock. Dark wax
## — The Unplayed, or any room read from its far face — inverts the plate, and
## the sheet's vignette re-inks with it.
func _apply_hud_palette(stock: Color) -> void:
	if title == null or status == null:
		return
	var dark_stock := stock.get_luminance() < 0.45
	var text := Color(0.94, 0.92, 0.88) if dark_stock else Color(0.1, 0.09, 0.09)
	title.add_theme_color_override("font_color", text)
	subtitle.add_theme_color_override("font_color", Color(text.r, text.g, text.b, 0.72))
	status.add_theme_color_override("font_color", Color(text.r, text.g, text.b, 0.85))
	controls_note.add_theme_color_override("font_color", Color(text.r, text.g, text.b, 0.4))
	masthead.color = Color(stock.r, stock.g, stock.b, 0.92)
	footer_stock.color = Color(stock.r, stock.g, stock.b, 0.96)
	feedback.add_theme_color_override(
		"font_outline_color", Color(stock.r, stock.g, stock.b, 0.9)
	)
	if paper != null:
		# Vignette in the ink of the room, so the corners darken on light stock
		# and the sheet gathers light on dark.
		PressScript.repaper(
			paper, Color(0.94, 0.92, 0.88, 1.0) if dark_stock else Color(0.10, 0.09, 0.08, 1.0)
		)

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
	if shop != null and (shop.is_open or _shop_closing):
		return
	_health = _max_health()
	_respawn_pending = false
	player.global_position = room.entry_position(room_entry_id)
	player.velocity = Vector2.ZERO
	player.cancel_pending_strike()
	hud_motion.reset_transients()
	if not development_mode:
		player.set("_stagger", 0.0)
		player.set("_buffer", 0.0)
		player.set("_recover", 0.0)
	player.refill_air_strikes()
	player.reset_animation()
	camera.reset_smoothing()
	camera.force_update_scroll()
	room.call("sync_scenery_camera")
	if not development_mode:
		for encounter in get_tree().get_nodes_in_group("chapter_boss"):
			if room.is_ancestor_of(encounter) and encounter.has_method("reset_attempt"):
				encounter.call("reset_attempt")

# -- events -------------------------------------------------------------------

func _on_struck(pos: Vector2, big: bool, launched: bool) -> void:
	var w := WaveScript.new()
	w.big = big
	w.launched = launched
	w.hit_radius = SkipScript.POGO_RANGE
	w.ink = room.call("_solid_color")
	w.stock = room.call("_stock_color")
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
	if not development_mode and world_room_id == &"the_arm":
		_flash("THE TONEARM FALLS SILENT.")
	else:
		_flash(SHATTER_LINES[_shatter_i % SHATTER_LINES.size()])
	_shatter_i += 1
	_word_splatter(pos)

func _on_bout_won() -> void:
	_flash("HUSH LOWERS THE POINT." if world_room_id == &"smoothed_floor" else "the bout is yours. he'd nod. once.")

func _on_door_opened() -> void:
	var discovered := bool(
		progression.call("discover_technique", ProgressionScript.Technique.COUNT_IN)
	)
	if not discovered:
		_flash("it was listening. it always was.")

func _on_freed(_pos: Vector2) -> void:
	_flash("IT POINTS HOME." if world_room_id == &"the_arm" else "heard at last. it goes — and stays gone.")

func _on_player_hit() -> void:
	_hits_taken += 1
	hud_motion.present_status()
	_shake = 6.0
	if not development_mode and not _respawn_pending:
		_health = maxi(0, _health - 1)
		if _health == 0:
			_respawn_pending = true
			call_deferred("_recover_needle")
		else:
			_flash("hold steady. %d left." % _health)

func _recover_needle() -> void:
	_respawn()
	_flash("the needle lifts. what you learned stays.")

func _on_refrain_collected(refrain: int) -> void:
	progression.call("unlock_refrain", refrain)

func _on_route_requested(target_room: StringName, target_entry: StringName) -> void:
	if _transition_pending or (game_menu != null and game_menu.is_open) or bool(inventory.call("is_open")) or shop.is_open or _shop_closing or map_menu.is_open or _map_closing:
		return
	if not development_mode and not ChapterScript.has_room(target_room):
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
	_queue_save()

func _on_route_blocked(message: String) -> void:
	_flash(message)

func _can_open_inventory() -> bool:
	return _has_session and not _transition_pending and not _shop_closing and not shop.is_open and not _map_closing and (map_menu == null or not map_menu.is_open) and (game_menu == null or not game_menu.is_open)

func _on_refrain_unlocked(refrain: int) -> void:
	audio.play("freed", -7.0)
	if refrain == ProgressionScript.Refrain.GATHER:
		player.refill_air_strikes()
		_flash("GATHER — a breath to carry home.")
	else:
		_flash("%s — remembered." % progression.call("refrain_label", refrain))
	_queue_save()

func _on_technique_discovered(technique: int) -> void:
	_flash("%s — a rhythm remembered." % progression.call("technique_label", technique))
	_queue_save()

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
	hud_motion.present_feedback()

# -- hud ----------------------------------------------------------------------

## The sheet, then the masthead. Paper sits over the world and under the type,
## so the HUD reads as printed ON the page rather than floating above it.
func _build_hud() -> void:
	var sheet := CanvasLayer.new()
	sheet.layer = 1
	add_child(sheet)
	paper = PressScript.paper_overlay(Color(0.10, 0.09, 0.08))
	sheet.add_child(paper)

	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)

	# The masthead is pasted onto the sheet, not floated over it: room signage
	# lives in world space and will always drift under the corner eventually.
	masthead = ColorRect.new()
	masthead.position = Vector2(0, 0)
	masthead.size = Vector2(360, 78)
	masthead.color = Color(0.85, 0.83, 0.78, 0.92)
	layer.add_child(masthead)

	# Masthead: the room's name in wood type, struck through with a rule.
	title = Label.new()
	title.position = Vector2(MARGIN, 12)
	PressScript.set_display(title, PressScript.SIZE_TITLE, Color(0.1, 0.09, 0.09))
	title.add_theme_constant_override("font_spacing_glyph", PressScript.TRACKING_DISPLAY)
	layer.add_child(title)

	title_rule = ColorRect.new()
	title_rule.position = Vector2(MARGIN, 47)
	title_rule.size = Vector2(0, 2)
	title_rule.color = PressScript.PINK
	layer.add_child(title_rule)

	subtitle = Label.new()
	subtitle.position = Vector2(MARGIN, 53)
	PressScript.set_body(subtitle, PressScript.SIZE_SMALL, Color(0.1, 0.09, 0.09, 0.72))
	layer.add_child(subtitle)

	# One word, struck large, centred. The game's only shout.
	feedback = Label.new()
	feedback.position = Vector2(0, 236)
	feedback.size = Vector2(1280, 60)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	PressScript.set_display(
		feedback, PressScript.SIZE_BANNER, PressScript.PINK, Color(0.1, 0.09, 0.08, 0.85)
	)
	feedback.add_theme_constant_override("font_spacing_glyph", PressScript.TRACKING_DISPLAY)
	feedback.modulate.a = 0.0
	layer.add_child(feedback)

	footer_stock = ColorRect.new()
	footer_stock.position = Vector2(0, 634)
	footer_stock.size = Vector2(1280, 86)
	footer_stock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_stock.visible = not development_mode
	layer.add_child(footer_stock)

	status = Label.new()
	status.position = Vector2(MARGIN, 648)
	PressScript.set_body(status, PressScript.SIZE_SMALL, Color(0.1, 0.09, 0.09, 0.85))
	layer.add_child(status)

	# The crackle smear: the noise meter, inked straight onto the sheet.
	crackle_bar = ColorRect.new()
	crackle_bar.position = Vector2(MARGIN, 700)
	crackle_bar.size = Vector2(0, 6)
	crackle_bar.color = PressScript.PINK
	layer.add_child(crackle_bar)

	# The control list is a contact sheet note, not part of the game's page.
	controls_note = Label.new()
	controls_note.position = Vector2(0, 692)
	controls_note.size = Vector2(1280 - MARGIN, 20)
	controls_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	PressScript.set_body(controls_note, PressScript.SIZE_TINY, Color(0.1, 0.09, 0.09, 0.4))
	controls_note.visible = true
	layer.add_child(controls_note)

	var shine_notice := Label.new()
	shine_notice.name = "ShineReceipt"
	shine_notice.position = Vector2(MARGIN, 618.0 if development_mode else 674.0)
	shine_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	PressScript.set_body(shine_notice, PressScript.SIZE_SMALL, PressScript.PINK)
	layer.add_child(shine_notice)
	# HUD controls never intercept the world. These impressions are cosmetic.
	for control in [masthead, title, title_rule, subtitle, feedback, status, crackle_bar, controls_note]:
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_motion = HudMotionScript.new()
	hud_motion.name = "HudMotion"
	hud_motion.title = title
	hud_motion.subtitle = subtitle
	hud_motion.title_rule = title_rule
	hud_motion.feedback = feedback
	hud_motion.status = status
	hud_motion.shine_notice = shine_notice
	layer.add_child(hud_motion)

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
	_action("trade", [KEY_B], [JOY_BUTTON_DPAD_UP])
	_action("inventory", [KEY_I], [JOY_BUTTON_START])
	_action("map", [] if development_mode else [KEY_M], [] if development_mode else [JOY_BUTTON_DPAD_DOWN])
	_action("restart", [KEY_R], [JOY_BUTTON_BACK] if development_mode else [])
	_action("switch_room", [KEY_TAB])
	_action("world_map", [KEY_M])
	_action("debug_grant", [KEY_G])
	_action("pause_game", [KEY_ESCAPE], [] if development_mode else [JOY_BUTTON_BACK])
	# Native Godot's default UI actions may only include keyboard events.
	# Give every menu the same explicit controller vocabulary as the game.
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B],
		["ui_left", JOY_BUTTON_DPAD_LEFT], ["ui_right", JOY_BUTTON_DPAD_RIGHT],
		["ui_up", JOY_BUTTON_DPAD_UP], ["ui_down", JOY_BUTTON_DPAD_DOWN]]:
		var event := InputEventJoypadButton.new()
		event.button_index = int(pair[1])
		if not InputMap.action_has_event(pair[0], event):
			InputMap.action_add_event(pair[0], event)
	for mapping in [["ui_left", JOY_AXIS_LEFT_X, -1.0], ["ui_right", JOY_AXIS_LEFT_X, 1.0],
		["ui_up", JOY_AXIS_LEFT_Y, -1.0], ["ui_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var motion := InputEventJoypadMotion.new()
		motion.axis = int(mapping[1])
		motion.axis_value = float(mapping[2])
		if not InputMap.action_has_event(mapping[0], motion):
			InputMap.action_add_event(mapping[0], motion)

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
