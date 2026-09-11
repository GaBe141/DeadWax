extends "res://scripts/listening_post.gd"
## A resident with a small routine and a grounded conversation. The campaign
## lends its existing outcomes; this actor never awards, saves, or seals a route.

const NOTICE_RANGE := 380.0
const STARTLE_RANGE := 230.0
const TICK_GAP := 0.54
const TALK_TIME := 1.25

var kind: StringName = &"bootlegger"
var session_outcomes: Dictionary = {}
var _clock := 0.0
var _face := -1.0
var _talk := 0.0
var _startle := 0.0
var _greeting := 0.0
var _previous_near := false
var _last_beat := -1
var _story_key := ""

func _ready() -> void:
	add_to_group("world_resident")
	add_to_group("hears_strikes")
	card_clearance = 178.0
	if kind == &"bootlegger":
		extra_hint = "[B / D-PAD UP]  Browse tapes"
	_refresh_story()
	super._ready()
	# Skip can pass in front of the coat. Only the conversation card sits above.
	z_index = 7
	_card.z_index = 32

func _process(delta: float) -> void:
	if delta <= 0 or get_tree().paused:
		return
	var step := minf(delta, 0.1)
	_clock += step
	_talk = maxf(_talk - step, 0)
	_startle = maxf(_startle - step * 1.7, 0)
	_greeting = maxf(_greeting - step * 1.2, 0)
	_refresh_story()
	super._process(delta)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player != null and player.global_position.distance_to(global_position) < NOTICE_RANGE:
		var target := -1.0 if player.global_position.x < global_position.x else 1.0
		_face = lerpf(_face, target, 1.0 - exp(-step * 8.0))
	if _near and not _previous_near:
		_greeting = 1.0
	_previous_near = _near
	if kind == &"tick":
		var beat := int(floor(_clock / TICK_GAP))
		if beat != _last_beat and beat % 4 < 3 and player != null:
			if player.global_position.distance_to(global_position) < NOTICE_RANGE and _talk <= 0:
				_sound("tick", -23.0, 1.18 + (beat % 4) * 0.055)
		_last_beat = beat
	queue_redraw()

func try_listen() -> bool:
	if not super.try_listen():
		return false
	_talk = TALK_TIME
	_sound("tick", -24.0, 0.82 if kind == &"bootlegger" else 1.35)
	queue_redraw()
	return true

func on_player_strike(pos: Vector2, _big: bool) -> void:
	if get_tree().paused or global_position.distance_to(pos) > STARTLE_RANGE:
		return
	_startle = 1.0
	_talk = 0.0
	queue_redraw()

func _sound(id: String, volume: float, pitch: float) -> void:
	var bank := get_tree().get_first_node_in_group("audio_bank")
	if bank != null:
		bank.call("play", id, volume, pitch)

func _refresh_story() -> void:
	var key := String(session_outcomes.get(
		"practice_room/practice_count_in" if kind == &"tick" else "the_arm/tonearm", ""
	))
	# A first visit has an empty outcome too, so also initialize the spoken lines.
	if key == _story_key and not lines.is_empty():
		return
	_story_key = key
	_line = -1
	if kind == &"tick":
		heading = "TICK"
		if key == "opened":
			lines = [
				"The door heard you.\nI keep coming back to three.",
				"Your Groove is in the sleeve.\nTake its lift back to the Stalls.",
				"Another door may be listening.\nIt can learn the same count.",
			]
		else:
			lines = [
				"One. Two. Three.\nThen it gets away from me.",
				"That door needs four even strikes.\nYou can give it the missing beat.",
				"Pick your own pace.\nLeave a little room between them.",
				"The sleeve keeps a missing Groove.\nThe market span needs its lift.",
			]
	else:
		heading = "THE BOOTLEGGER"
		if key == "freed":
			lines = [
				"Something heavy lifted.\nYou can hear the space it left.",
				"Go back to the Headshell.\nSome things sound different at home.",
				"Worn names only.\nI leave the quiet on the tape.",
			]
		elif key == "shattered":
			lines = [
				"The floor carried that sound\nall the way to my counter.",
				"The way home is still open.\nTake your time on the stairs.",
				"Worn names only.\nEven when the song has stopped.",
			]
		else:
			lines = [
				"The whistles only know one way.\nWest. Let them carry you.",
				"Addie's door is still open.\nShe waits at the last bar.",
				"Below her, someone swept the floor.\nBelow him, something points home.",
			]
	if _card != null:
		_rebuild_card()

func _rebuild_card() -> void:
	super._rebuild_card()
	z_index = 7
	_card.z_index = 32

func reink(next_ink: Color, next_stock: Color) -> void:
	super.reink(next_ink, next_stock)
	queue_redraw()

func resident_pose() -> Dictionary:
	return {
		"clock": _clock, "face": _face, "near": _near,
		"talking": _talk / TALK_TIME, "startle": _startle, "greeting": _greeting,
		"beat": int(floor(_clock / TICK_GAP)) % 4,
		"beat_phase": fmod(_clock, TICK_GAP) / TICK_GAP,
		"opened": String(session_outcomes.get("practice_room/practice_count_in", "")) == "opened",
	}

func _draw() -> void:
	PressScript.draw_resident(self, kind, resident_pose(), ink, stock)
