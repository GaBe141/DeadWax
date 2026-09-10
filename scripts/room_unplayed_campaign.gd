extends "res://scripts/room_base.gd"
## A complete, reversible slice of the Unplayed. Rooms own geometry and local
## presentation; Main owns passage transitions, encounter outcomes, and saves.

const AuditionerScript := preload("res://scripts/auditioner.gd")
const TestPressingScript := preload("res://scripts/test_pressing.gd")
const ListeningPostScript := preload("res://scripts/listening_post.gd")
const EchoStationScript := preload("res://scripts/echo_station.gd")
const OVERLOOK_POSITION := Vector2(980, 384)
const OVERLOOK_LEDGE_POSITION := Vector2(980, 426)
const OVERLOOK_LEDGE_SIZE := Vector2(270, 32)
const DROP_STEP_RISE := 100.0
const SPOOL_POSITION := Vector2(340, 834)
const PHRASE_POSITION := Vector2(1010, 554)
const RECEIVER_POSITION := Vector2(350, 454)

signal discovery_requested(action: StringName, source: Node2D)
signal discovery_cue(cue: StringName)

# The shared encounters retain their exact strike, reach and mercy rules.
# Only their campaign lifetime differs from the reforming prototype dummy.
class CampaignAuditioner extends AuditionerScript:
	var _origin := Vector2.ZERO

	func _ready() -> void:
		super._ready()
		_origin = position
		add_to_group("reset_on_recovery")

	func reset_attempt() -> void:
		if state in [S.FREED, S.DOWN]:
			return
		position = _origin
		state = S.CALM
		hp = HP_MAX
		resonance = 0.0
		_set = 0.0
		_t = 0.0
		_reach_t = 0.0
		_face = -1.0
		_boil = 0.0
		_jit = Vector2.ZERO
		_print_time = 0.0
		_print_stride = 0.0
		_print_recoil = 0.0
		queue_redraw()

class CampaignPressing extends TestPressingScript:
	const DEFEAT_SETTLE_TIME := 0.55
	var _origin := Vector2.ZERO

	func _ready() -> void:
		super._ready()
		_origin = position
		add_to_group("reset_on_recovery")

	func _process(delta: float) -> void:
		if state == S.DOWN:
			if delta <= 0.0 or get_tree().paused:
				return
			_t += delta
			_advance_print(delta)
			queue_redraw()
			if _t >= DEFEAT_SETTLE_TIME:
				queue_free()
			return
		super._process(delta)

	func reset_attempt() -> void:
		if state == S.DOWN:
			return
		position = _origin
		state = S.CALM
		hp = HP_MAX
		resonance = 0.0
		parry_count = 0
		_t = 0.0
		_count = 0
		_face = -1.0
		_print_time = 0.0
		_print_recoil = 0.0
		_print_swing_tail = 0.0
		queue_redraw()

var discoveries: RefCounted
var session_outcomes: Dictionary = {}
var objective_label := "Follow the rooms beneath the seal."

func configure(id: StringName) -> void:
	room_id = id
	bg_color = Color("302b46")
	ink = Color("ded0bc")
	spawn_pos = Vector2(220, 574)
	cam_limits = Rect2(0, 0, 1900, 850)
	death_y = 1200.0
	match room_id:
		&"the_drop":
			band_name = "The Drop"
			band_desc = "The scratch was deeper than the song."
			objective_label = "Follow the cut down. The maintenance ledges also lead home."
			bg_color = Color("302832")
			ink = Color("e9b89e")
			cam_limits = Rect2(0, 0, 1600, 1500)
			death_y = 1850.0
			spawn_pos = Vector2(180, 254)
			register_entry(&"from_the_arm", spawn_pos)
			register_entry(&"from_the_landing", Vector2(1370, 1294))
		&"the_landing":
			band_name = "The Landing"
			band_desc = "A quiet place on the far side of a mistake."
			objective_label = "The Verse Hall lies west. The ledges behind you lead back to the seal."
			bg_color = Color("252638")
			ink = Color("e2cfae")
			spawn_pos = Vector2(1680, 574)
			register_entry(&"from_the_drop", spawn_pos)
			register_entry(&"from_verse_hall", Vector2(220, 574))
		&"verse_hall":
			band_name = "The Verse Hall"
			band_desc = "Every room was meant to be heard."
			objective_label = "The Warren lies west. Listen close, or give its voice the upper walk."
			bg_color = Color("29283c")
			ink = Color("e2cfae")
			cam_limits = Rect2(0, 0, 2400, 900)
			death_y = 1250.0
			spawn_pos = Vector2(2190, 654)
			register_entry(&"from_the_landing", spawn_pos)
			register_entry(&"from_verse_warren_n", Vector2(220, 654))
		&"verse_warren_n":
			band_name = "Auditioner Warren — North"
			band_desc = "They have kept a little room for an audience."
			objective_label = "The Gallery is west. The lower road joins the southern Warren."
			bg_color = Color("2b2638")
			ink = Color("ddc3a5")
			cam_limits = Rect2(0, 0, 1700, 1050)
			death_y = 1400.0
			spawn_pos = Vector2(1500, 454)
			register_entry(&"from_verse_hall", spawn_pos)
			register_entry(&"from_deep_gallery", Vector2(200, 454))
			register_entry(&"from_verse_warren_s", Vector2(1480, 834))
		&"verse_warren_s":
			band_name = "Auditioner Warren — South"
			band_desc = "Two old bars, still keeping time."
			objective_label = "The Gallery lies west. The upper walk leaves the pressing room to swing."
			bg_color = Color("302637")
			ink = Color("ddc3a5")
			cam_limits = Rect2(0, 0, 1850, 1000)
			death_y = 1350.0
			spawn_pos = Vector2(1640, 734)
			register_entry(&"from_verse_warren_n", spawn_pos)
			register_entry(&"from_deep_gallery", Vector2(220, 734))
		&"deep_gallery":
			band_name = "The Deep Gallery"
			band_desc = "An answer, with no one left to interrupt it."
			objective_label = "Listen at the empty seats. Both eastern doors lead back through the Warren."
			bg_color = Color("242739")
			ink = Color("e2cfae")
			cam_limits = Rect2(0, 0, 1900, 1050)
			death_y = 1400.0
			spawn_pos = Vector2(1680, 454)
			register_entry(&"from_verse_warren_n", spawn_pos)
			register_entry(&"from_verse_warren_s", Vector2(1680, 834))

func _ready() -> void:
	match room_id:
		&"the_drop": _build_drop()
		&"the_landing": _build_landing()
		&"verse_hall": _build_verse()
		&"verse_warren_n": _build_north()
		&"verse_warren_s": _build_south()
		&"deep_gallery": _build_gallery()
	platform(Vector2(-25, cam_limits.size.y / 2.0), Vector2(50, cam_limits.size.y + 400))
	platform(Vector2(cam_limits.size.x + 25, cam_limits.size.y / 2.0), Vector2(50, cam_limits.size.y + 400))
	setup_atmosphere(session_outcomes)
	refresh_discoveries()
	_reink_children()

func _build_drop() -> void:
	_ledge(240, 280, 480, 60)
	_floor(1600, 1320)
	# Successive ledges rise only 100 px. Alternating banks leave an open
	# approach to each upper edge; Gather is a shortcut, never the way out.
	for index in range(10):
		var x := 620.0 if index % 2 == 0 else 900.0
		_ledge(x, 380.0 + index * DROP_STEP_RISE, 260, 36)
	_exit(Vector2(85, 254), &"the_arm", "THE OPEN SEAL")
	_exit(Vector2(1480, 1294), &"the_landing", "THE LANDING")
	sign_label(Vector2(255, 95), "INSIDE THE SCRATCH\nA cut, all the way through.\nThe town is still above you.")
	sign_label(Vector2(1110, 535), "THE MAINTENANCE WAY\nEach ledge is a jump from the next.\nThe return was built by hand.")
	_listening_post(Vector2(270, 1294), "A CUT THROUGH THE SONG", [
		"The sound did not end here.\nIt fell through.",
		"Under the broken edge,\nthere are rooms that never played.",
	])

func _build_landing() -> void:
	_floor(1900, 600)
	_exit(Vector2(1780, 574), &"the_drop", "BACK TO THE CUT")
	_exit(Vector2(100, 574), &"verse_hall", "THE VERSE HALL")
	# The overlook is optional. No intermediate steps or passage require its
	# 190 px ascent. The surveyor's keepsake changes no traversal or income.
	platform(OVERLOOK_LEDGE_POSITION, OVERLOOK_LEDGE_SIZE)
	get_child(-1).name = "GatherOverlook"
	sign_label(Vector2(1330, 290), "THE UNPLAYED\nNo footprints on this side.\nOnly the mark where you landed.")
	sign_label(Vector2(285, 270), "WEST — THE VERSE HALL\nSomeone left the seats out.\nSomeone still expects a song.")
	_echo_station(OVERLOOK_POSITION, &"collect_survey", "SurveyorsSlip")

func _build_verse() -> void:
	_floor(2400, 680)
	_exit(Vector2(2300, 654), &"the_landing", "THE LANDING")
	_exit(Vector2(100, 654), &"verse_warren_n", "THE NORTH WARREN")
	_ledge(650, 590, 220)
	_ledge(900, 500, 230)
	_ledge(1160, 420, 250)
	_ledge(1450, 500, 230)
	_ledge(1700, 590, 220)
	_auditioner(Vector2(1260, 667), &"hall_voice", "HallVoice")
	sign_label(Vector2(1790, 340), "A ROOM FOR A VOICE\nHold the Hood [K / C] to approach.\nKneel [L] close by to hear it out.")
	sign_label(Vector2(385, 300), "THE UPPER WALK\nLeave room for an unfinished song.\nThe arches carry you around it.")
	_listening_post(Vector2(335, 654), "IN THE MARGIN", [
		"The same word, in different hands:\nsoon.",
		"Every seat faces a different doorway.\nNobody wanted to miss the entrance.",
	])

func _build_north() -> void:
	_floor(1700, 860)
	_ledge(240, 480, 480, 50)
	_ledge(1460, 480, 480, 50)
	# This upper shelf stops short of the lower step's takeoff edge. A wide
	# overhang here catches Skip's head before the middle ledge can be reached.
	_ledge(590, 570, 160)
	_ledge(865, 660, 250)
	_ledge(1110, 570, 240)
	_ledge(590, 760, 250)
	_exit(Vector2(1600, 454), &"verse_hall", "THE VERSE HALL")
	_exit(Vector2(85, 454), &"deep_gallery", "THE DEEP GALLERY")
	_exit(Vector2(1590, 834), &"verse_warren_s", "THE SOUTH WARREN")
	_auditioner(Vector2(730, 847), &"north_voice", "NorthVoice")
	_auditioner(Vector2(1280, 847), &"lower_voice", "LowerVoice")
	_echo_station(RECEIVER_POSITION, &"restore_warren", "WarrenReceiver")
	sign_label(Vector2(1220, 160), "TWO WAYS THROUGH\nThe Gallery lies across the upper walk.\nThe lower door joins the southern road.")
	sign_label(Vector2(60, 585), "ROOM ENOUGH\nA patient voice waits below.\nYou can listen, or leave it its space.")

func _build_south() -> void:
	_floor(1850, 760)
	_exit(Vector2(1750, 734), &"verse_warren_n", "THE NORTH WARREN")
	_exit(Vector2(100, 734), &"deep_gallery", "THE DEEP GALLERY")
	_ledge(520, 670, 220)
	_ledge(760, 580, 230)
	_ledge(1010, 580, 250)
	_ledge(1260, 670, 220)
	var pressing := CampaignPressing.new()
	pressing.name = "WarrenPressing"
	pressing.position = Vector2(950, 717)
	_persistent(pressing, &"warren_pressing")
	add_child(pressing)
	_echo_station(PHRASE_POSITION, &"record_phrase", "WarrenPhrase")
	sign_label(Vector2(1370, 380), "THE OLD COUNT\nThree ticks. The swing comes on four.\nStep clear, or strike [J / X] as it lands.")
	sign_label(Vector2(260, 350), "A ROAD UNDER THE ROAD\nWest: the quiet Gallery.\nEast: the northern rooms.")

func _build_gallery() -> void:
	_floor(1900, 860)
	_ledge(1660, 480, 480, 50)
	_ledge(1300, 570, 240)
	_ledge(1040, 660, 240)
	_ledge(780, 760, 250)
	_exit(Vector2(1800, 454), &"verse_warren_n", "THE NORTH WARREN")
	_exit(Vector2(1800, 834), &"verse_warren_s", "THE SOUTH WARREN")
	sign_label(Vector2(1450, 185), "THE DEEP GALLERY\nThe voices stop at the door.\nThe stairs meet the road below.")
	sign_label(Vector2(210, 440), "TWO EMPTY SEATS\nAn answer was kept here.\nThere is time to hear it.")
	_echo_station(SPOOL_POSITION, &"collect_spool", "EchoSpool")
	_listening_post(Vector2(560, 834), "AN UNPLAYED ANSWER", [
		"Two seats.\nOne turned toward the other.",
		"The first groove is worn almost flat.\nThe answering groove is untouched.",
		"The little reel can hold an answer.\nTry the old wire in the southern Warren.",
		"Above you, the road forks and returns.\nYou can take the other way home.",
	])

func _floor(width: float, top: float) -> void:
	_ledge(width / 2.0, top, width, 60)

func _ledge(x: float, top: float, width: float, depth := 36.0) -> void:
	platform(Vector2(x, top + depth / 2.0), Vector2(width, depth))

func _exit(pos: Vector2, target: StringName, caption: String) -> void:
	route_exit(pos, target, StringName("from_" + String(room_id)), caption)

func _listening_post(pos: Vector2, heading: String, lines: Array[String]) -> void:
	var post := ListeningPostScript.new()
	post.position = pos
	post.heading = heading
	post.lines = lines
	post.ink = ink
	post.stock = bg_color
	add_child(post)

func _auditioner(pos: Vector2, id: StringName, actor_name: String) -> void:
	var voice := CampaignAuditioner.new()
	voice.name = actor_name
	voice.position = pos
	_persistent(voice, id)
	add_child(voice)

func _persistent(node: Node, id: StringName) -> void:
	node.set_meta("chapter_state_id", id)
	node.add_to_group("chapter_persistent")

func apply_side(next_side: int) -> void:
	super.apply_side(next_side)
	_reink_children()

func _reink_children() -> void:
	for child in get_children():
		if child != atmosphere and child != lighting and child.has_method("reink"):
			child.call("reink", _solid_color(), _stock_color())

func restore_encounters(outcomes: Dictionary) -> void:
	session_outcomes = outcomes
	for child in get_children():
		if not child.has_meta("chapter_state_id"):
			continue
		var key := String(room_id) + "/" + String(child.get_meta("chapter_state_id"))
		if String(outcomes.get(key, "")) in ["freed", "shattered", "won"]:
			remove_child(child)
			child.queue_free()


func _echo_station(pos: Vector2, action: StringName, station_name: String) -> void:
	var station := EchoStationScript.new()
	station.name = station_name
	station.position = pos
	station.action = action
	station.discoveries = discoveries
	station.ink = ink
	station.stock = bg_color
	station.requested.connect(_on_discovery_requested)
	station.cue_requested.connect(_on_discovery_cue)
	add_child(station)

func _on_discovery_requested(action: StringName, source: Node2D) -> void:
	discovery_requested.emit(action, source)

func _on_discovery_cue(cue: StringName) -> void:
	discovery_cue.emit(cue)

func refresh_discoveries() -> void:
	# Open the engraving in place; existing walks, collisions and encounter
	# outcomes never change. Saved restoration arrives as a settled scene.
	for child in get_children():
		if child is EchoStationScript:
			child.discoveries = discoveries
			child.refresh_discoveries()
	var held := "missing"
	var slip := false
	if discoveries != null:
		var state: Dictionary = discoveries.call("snapshot")
		held = String(state.get("echo_spool", "missing"))
		slip = bool(state.get("survey_slip", false))
	match room_id:
		&"deep_gallery":
			objective_label = "A little reel waits by the empty seats. Take it with E / Y."
			if held != "missing":
				objective_label = "The Echo Spool can carry a phrase from the southern Warren's upper walk."
		&"verse_warren_s":
			if held == "empty":
				objective_label = "Record the three notes on the upper walk. Stay close until the phrase ends."
			elif held == "recorded":
				objective_label = "Carry the recorded phrase to the northern Warren's western terrace."
		&"verse_warren_n":
			if held == "recorded":
				objective_label = "The horn on the western terrace has been waiting for your phrase."
			elif held == "restored":
				objective_label = "The Warren has its answer. The little audience will sing it again."
		&"the_landing":
			if slip:
				objective_label = "The surveyor marked a voice above the Stalls. Carry your borrowed breath home."
	if held == "restored" and room_id in [&"deep_gallery", &"verse_warren_s"]:
		objective_label = "The Warren has its answer. Visit the northern alcove, or follow the road home."
