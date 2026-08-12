extends Node2D
## DEAD WAX — M1 bootstrap.
## Builds everything from code: input map, player, camera, HUD, audio, rooms.
## [TAB] cycles rooms, [R] restarts.

const SkipScript := preload("res://scripts/skip.gd")
const WaveScript := preload("res://scripts/strike_wave.gd")
const AudioScript := preload("res://scripts/audio_bank.gd")
const ROOM_SCRIPTS := [
	preload("res://scripts/room_label.gd"),
	preload("res://scripts/room_dojo.gd"),
	preload("res://scripts/room_verse.gd"),
	preload("res://scripts/room_unplayed.gd"),
	preload("res://scripts/room_smoothed.gd"),
]

var player: CharacterBody2D
var camera: Camera2D
var audio: Node
var room: Node2D
var room_idx := 0

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

	audio = AudioScript.new()
	add_child(audio)

	player = SkipScript.new()
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
	_load_room(0)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_room"):
		_load_room((room_idx + 1) % ROOM_SCRIPTS.size())
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
	status.text = "crackle %s   shine %d   hits taken %d%s" % [
		"·" if player.noise < 0.05 else "",
		player.shine,
		_hits_taken,
		"   [HOODED]" if player.hooded else "",
	]

# -- rooms --------------------------------------------------------------------

func _load_room(i: int) -> void:
	room_idx = i
	if room != null:
		room.queue_free()
	room = ROOM_SCRIPTS[i].new()
	add_child(room)

	player.air_density = room.air_density
	player.gravity_mult = room.gravity_mult
	player.fall_cap_mult = room.fall_cap_mult
	player.groove_mult = room.groove_mult
	player.air_strikes_max = room.air_strikes_max
	player.air_strikes_left = room.air_strikes_max

	# wire the room's listeners after they enter the tree
	call_deferred("_wire_room")

	RenderingServer.set_default_clear_color(room.bg_color)
	camera.limit_left = int(room.cam_limits.position.x)
	camera.limit_top = int(room.cam_limits.position.y)
	camera.limit_right = int(room.cam_limits.position.x + room.cam_limits.size.x)
	camera.limit_bottom = int(room.cam_limits.position.y + room.cam_limits.size.y)

	_respawn()
	info.text = "DEAD WAX — M1\nROOM: %s\n%s\n[A/D] move  [SPACE] jump  [J] strike  [K hold] hood  [L hold] kneel  [R] restart  [TAB] next room" % [room.band_name, room.band_desc]

func _wire_room() -> void:
	for n in get_tree().get_nodes_in_group("hears_strikes"):
		if n is Node and n.has_signal("parried") and not n.parried.is_connected(_on_parried):
			n.parried.connect(_on_parried)
			n.shattered.connect(_on_shattered)
			n.bout_won.connect(_on_bout_won)
		if n.has_signal("opened") and not n.opened.is_connected(_on_door_opened):
			n.opened.connect(_on_door_opened)
		if n.has_signal("freed") and not n.freed.is_connected(_on_freed):
			n.freed.connect(_on_freed)

func _respawn() -> void:
	player.global_position = room.spawn_pos
	player.velocity = Vector2.ZERO
	player.air_strikes_left = room.air_strikes_max
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
	_flash("it was listening. it always was.")

func _on_freed(_pos: Vector2) -> void:
	_flash("heard at last. it goes — and stays gone.")

func _on_player_hit() -> void:
	_hits_taken += 1
	_shake = 6.0

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
	status.position = Vector2(14, 668)
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color(0.1, 0.09, 0.09))
	status.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.55))
	status.add_theme_constant_override("outline_size", 5)
	layer.add_child(status)

	crackle_bar = ColorRect.new()
	crackle_bar.position = Vector2(14, 692)
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
	_action("restart", [KEY_R], [JOY_BUTTON_BACK])
	_action("switch_room", [KEY_TAB], [JOY_BUTTON_Y])

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
