extends "res://scripts/room_base.gd"
## Chapter one: a small inhabited circuit, then a deliberate descent.
## Geometry and encounters are authored here; every surface comes from Press.

const DoorScript := preload("res://scripts/refrain_door.gd")
const StreetLooperScript := preload("res://scripts/street_looper.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")
const ResidentScript := preload("res://scripts/resident.gd")
const HoundScript := preload("res://scripts/hound.gd")
const MapPickupScript := preload("res://scripts/map_pickup.gd")
const LoftVoiceScript := preload("res://scripts/loft_voice.gd")
const YardVoiceScript := preload("res://scripts/yard_voice.gd")
const YardMemoryScript := preload("res://scripts/yard_memory.gd")
const OutcomeExitScript := preload("res://scripts/outcome_exit.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const HORN_LISTEN_TIME := 1.4
const HORN_LISTEN_RADIUS := 135.0
const HORN_POSITION := Vector2(790, 574)

signal map_collected

var objective_label := "Find a way out of the Headshell."
var session_outcomes: Dictionary = {}
var map_state: RefCounted
var _scenery: Array[Node2D] = []
var _horn_time := 0.0
var _horn_heard := false
var _yard_note: Control
var _yard_note_outcome := "unprinted"

func configure(id: StringName) -> void:
	room_id = id
	bg_color = Color("e8e0cc")
	ink = Color("26221e")
	spawn_pos = Vector2(160, 574)
	death_y = 1120.0
	cam_limits = Rect2(0, 0, 1800, 820)
	match room_id:
		&"headshell":
			band_name = "The Headshell"
			band_desc = "The grip is empty. You are still here."
			objective_label = "Follow the light into the Label."
			cam_limits = Rect2(0, 0, 1280, 720)
			spawn_pos = Vector2(180, 554)
			register_entry(&"from_horn_plaza", Vector2(1080, 554))
		&"horn_plaza":
			band_name = "The Horn Plaza"
			band_desc = "All of it. That was the length of the song."
			objective_label = "Find the Count-In west of the plaza, or follow the market east."
			register_entry(&"from_headshell", Vector2(450, 574))
			register_entry(&"from_high_street", Vector2(180, 574))
			register_entry(&"from_practice_room", Vector2(1140, 574))
			register_entry(&"from_the_stalls", Vector2(1580, 574))
		&"high_street":
			band_name = "The High Street"
			band_desc = "A street that keeps its own time."
			objective_label = "Let the Looper swing. Answer while its guard is open."
			cam_limits.size.x = 2000.0
			register_entry(&"from_horn_plaza", Vector2(180, 574))
			register_entry(&"from_practice_room", Vector2(1780, 574))
		&"practice_room":
			band_name = "The Practice Room"
			band_desc = "Three. Three. Three."
			objective_label = "Give the listening door four even strikes."
			cam_limits.size.x = 1700.0
			register_entry(&"from_high_street", Vector2(180, 574))
			register_entry(&"from_horn_plaza", Vector2(1460, 574))
		&"the_stalls":
			band_name = "The Stalls"
			band_desc = "The shutters are down. The wax is still warm."
			objective_label = "Let the live groove carry you across the market."
			cam_limits = Rect2(0, 0, 2200, 920)
			register_entry(&"from_horn_plaza", Vector2(170, 574))
			register_entry(&"from_groove_yard", Vector2(1990, 454))
			register_entry(&"from_worn_gallery", Vector2(2020, 254))
		&"groove_yard":
			band_name = "The Locked-Groove Yard"
			band_desc = "Worn names. One bar, over and over."
			objective_label = "Hear what remains. Find the Descent Gate."
			cam_limits.size.x = 2100.0
			register_entry(&"from_the_stalls", Vector2(180, 574))
			register_entry(&"from_label_descent", Vector2(1880, 574))
		&"label_descent":
			band_name = "The Descent Gate"
			band_desc = "The whole street ends on a held note."
			objective_label = "Count the gate in: four even strikes."
			cam_limits.size.x = 1700.0
			register_entry(&"from_groove_yard", Vector2(180, 574))
			register_entry(&"from_overture_stair", Vector2(1460, 574))
		&"overture_stair":
			band_name = "The Overture Stair"
			band_desc = "Below the Label, something is still singing."
			objective_label = "Follow the worn stairs to the Bootlegger's stall."
			bg_color = Color("e3bfb6")
			cam_limits = Rect2(0, 0, 1800, 1080)
			death_y = 1350.0
			spawn_pos = Vector2(160, 404)
			register_entry(&"from_label_descent", Vector2(180, 404))
			register_entry(&"from_bootlegger", Vector2(1510, 824))

func _ready() -> void:
	match room_id:
		&"headshell": _build_headshell()
		&"horn_plaza": _build_horn_plaza()
		&"high_street": _build_high_street()
		&"practice_room": _build_practice_room()
		&"the_stalls": _build_stalls()
		&"groove_yard": _build_groove_yard()
		&"label_descent": _build_descent_gate()
		&"overture_stair": _build_overture_stair()
	# The sides of the authored page are walls, not accidental death pits.
	platform(Vector2(-25, 470), Vector2(50, 1300))
	platform(Vector2(cam_limits.size.x + 25, 470), Vector2(50, 1300))
	setup_atmosphere(session_outcomes)

func _build_headshell() -> void:
	platform(Vector2(640, 620), Vector2(1280, 80))
	_impression(&"headshell", Vector2(385, 347), Vector2(480, 310))
	_impression(&"arch", Vector2(1100, 397), Vector2(190, 330))
	var arm_outcome := String(session_outcomes.get("the_arm/tonearm", ""))
	if arm_outcome == "freed":
		_impression(&"resting_arm", Vector2(355, 300), Vector2(350, 280))
		sign_label(Vector2(125, 380), "THE ARM CAME HOME\nThe grip is open. It can let go.")
		objective_label = "Home sounds different when something has come back."
	elif arm_outcome == "shattered":
		sign_label(Vector2(125, 380), "THE GRIP IS EMPTY\nNothing is holding it open.")
		objective_label = "The cradle stays empty. The street is still here."
	else:
		sign_label(Vector2(125, 380), "THE GRIP IS OPEN\nSomething let go of you.")
	sign_label(Vector2(535, 330), "A / D or left stick — move\nSPACE / A — jump")
	var folded_map := MapPickupScript.new()
	folded_map.name = "FoldedMap"
	folded_map.position = Vector2(500, 554)
	folded_map.map_state = map_state
	folded_map.ink = ink
	folded_map.stock = bg_color
	folded_map.collected.connect(map_collected.emit)
	add_child(folded_map)
	platform(Vector2(745, 550), Vector2(140, 60))
	sign_label(Vector2(915, 286), "THE LABEL\nA little daylight.\n[E / Y] at a passage")
	_exit(Vector2(1120, 554), &"horn_plaza", "THE PLAZA")

func _build_horn_plaza() -> void:
	_floor(1800)
	_impression(&"horn", Vector2(810, 350), Vector2(420, 370))
	_impression(&"facade", Vector2(220, 317), Vector2(350, 390))
	_impression(&"market", Vector2(1500, 360), Vector2(440, 330))
	_exit(Vector2(85, 574), &"high_street", "HIGH STREET")
	_exit(Vector2(375, 574), &"headshell", "HOME")
	_exit(Vector2(1190, 574), &"practice_room", "PRACTICE")
	_exit(Vector2(1680, 574), &"the_stalls", "THE STALLS")
	sign_label(Vector2(600, 242), "THE VOICE\nRuntime: all of it.")
	sign_label(Vector2(680, 424), "HOLD K / C / B — HOOD\nStand quietly beneath the horn.")
	_polish(Vector2(790, 574), &"horn_wax")
	if String(session_outcomes.get("the_stalls/loft_voice", "")) == "freed":
		sign_label(Vector2(1280, 260), "THE RETURNING NOTE\nA small song crosses the market.\nThe great horn carries it home.")
	else:
		sign_label(Vector2(1280, 260), "THE DESCENT\nEast, through the market.\nThe gate listens for a count.")
	var hound := HoundScript.new()
	hound.name = "Hound"
	hound.position = Vector2(970, 574)
	hound.home_position = hound.position
	hound.session_outcomes = session_outcomes
	hound.ink = ink
	hound.stock = bg_color
	add_child(hound)

func _build_high_street() -> void:
	_floor(2000)
	for index in range(4):
		_impression(&"facade", Vector2(330 + index * 430, 315), Vector2(340, 460))
	_exit(Vector2(85, 574), &"horn_plaza", "THE PLAZA")
	_exit(Vector2(1880, 574), &"practice_room", "PRACTICE")
	sign_label(Vector2(290, 355), "THE LOOPER\nThree ticks guarded. It swings on four.\nStep clear, or J / X as it lands.\nThen strike while it is OPEN.")
	var looper := StreetLooperScript.new()
	looper.name = "StreetLooper"
	looper.position = Vector2(940, 557)
	looper.ink = ink
	looper.stock = bg_color
	_persistent(looper, &"street_looper")
	add_child(looper)
	# A quiet upper walk gives the encounter room to breathe and a way around.
	platform(Vector2(650, 525), Vector2(180, 30))
	platform(Vector2(850, 440), Vector2(190, 30))
	platform(Vector2(1100, 400), Vector2(250, 30))
	platform(Vector2(1350, 475), Vector2(180, 30))
	sign_label(Vector2(1310, 287), "NO NEED TO WAKE EVERYTHING\nYour Hood softens your footsteps.")
	_polish(Vector2(1540, 574), &"street_wax")

func _build_practice_room() -> void:
	_floor(1700)
	_impression(&"facade", Vector2(440, 333), Vector2(650, 410))
	_impression(&"arch", Vector2(1180, 330), Vector2(260, 460))
	_exit(Vector2(85, 574), &"high_street", "HIGH STREET")
	_exit(Vector2(1560, 574), &"horn_plaza", "THE PLAZA")
	sign_label(Vector2(720, 185), "TICK'S PRACTICE\n3... 3... 3...\nThe missing beat is yours.")
	var tick := ResidentScript.new()
	tick.name = "Tick"
	tick.kind = &"tick"
	tick.position = Vector2(465, 574)
	tick.session_outcomes = session_outcomes
	tick.ink = ink
	tick.stock = bg_color
	add_child(tick)
	sign_label(Vector2(720, 335), "THE COUNT-IN\nJ / X — four even strikes.\nAny tempo. Leave a little space.")
	_listening_door(Vector2(1190, 525), &"practice_count_in")
	sign_label(Vector2(1305, 340), "YOU KNEW\nThe plaza is just outside.")
	_polish(Vector2(520, 574), &"practice_wax")

func _build_stalls() -> void:
	_refresh_stalls_objective()
	platform(Vector2(350, 630), Vector2(740, 60))
	platform(Vector2(1780, 520), Vector2(840, 80))
	for index in range(4):
		_impression(&"market", Vector2(370 + index * 500, 290), Vector2(360, 330))
	_exit(Vector2(85, 574), &"horn_plaza", "THE PLAZA")
	_exit(Vector2(2070, 454), &"groove_yard", "THE YARD")
	groove(Vector2(590, 572))
	platform(Vector2(900, 435), Vector2(260, 36))
	platform(Vector2(1200, 410), Vector2(220, 36))
	sign_label(Vector2(310, 310), "STILL HOT\nStand on the groove. STRIKE [J / X].\nSteer right as it carries you.")
	sign_label(Vector2(1430, 215), "THE UPPER ROOM\nSomeone kept a song\nabove the shutters.")
	# This shelf is too high for the legs beneath it, and too far from the
	# live groove and middle walk. A held breath gives the return its lift.
	platform(Vector2(1990, 295), Vector2(420, 30))
	get_child(get_child_count() - 1).name = "LoftBalcony"
	_impression(&"arch", Vector2(1960, 164), Vector2(460, 225))
	_impression(&"counter", Vector2(1990, 340), Vector2(410, 90))
	var loft_voice := LoftVoiceScript.new()
	loft_voice.name = "LoftVoice"
	loft_voice.position = Vector2(1870, 254)
	loft_voice.ink = ink
	loft_voice.stock = bg_color
	_persistent(loft_voice, &"loft_voice")
	add_child(loft_voice)
	var loft_passage := OutcomeExitScript.new()
	loft_passage.name = "LoftPassage"
	loft_passage.position = Vector2(2100, 254)
	loft_passage.target_room = &"worn_gallery"
	loft_passage.target_entry = &"from_the_stalls"
	loft_passage.display_name = "THE GALLERY"
	loft_passage.session_outcomes = session_outcomes
	loft_passage.required_outcome_key = "the_stalls/loft_voice"
	loft_passage.required_outcomes = ["freed"]
	loft_passage.gate_label = "A SONG STILL HELD"
	loft_passage.blocked_message = "The upper room is waiting for its last reply."
	loft_passage.route_requested.connect(_on_exit_route_requested)
	loft_passage.route_blocked.connect(_on_exit_route_blocked)
	add_child(loft_passage)
	# A missed launch lands in the service lane. Short steps return to either
	# bank, so trying the first groove does not cost a room restart.
	platform(Vector2(1010, 800), Vector2(1420, 60))
	platform(Vector2(490, 700), Vector2(190, 30))
	platform(Vector2(1470, 705), Vector2(180, 30))
	platform(Vector2(1570, 600), Vector2(180, 30))
	sign_label(Vector2(700, 655), "BACK UP\nThe steps lead to the warm wax.")
	_polish(Vector2(1850, 454), &"market_wax")

func _build_groove_yard() -> void:
	_floor(2100)
	for index in range(7):
		_impression(&"headstone", Vector2(350 + index * 240, 468), Vector2(110, 205))
	_exit(Vector2(85, 574), &"the_stalls", "THE STALLS")
	_exit(Vector2(1980, 574), &"label_descent", "THE DESCENT")
	sign_label(Vector2(285, 310), "WORN NAMES\nSomeone kept writing them\nafter the sound had gone.")
	_update_yard_note(String(session_outcomes.get("groove_yard/yard_first_voice", "")))
	var memory := YardMemoryScript.new()
	memory.name = "YardMemory"
	memory.position = Vector2(1110, 587)
	memory.ink = ink
	memory.stock = bg_color
	memory.restore_outcome(String(session_outcomes.get("groove_yard/yard_first_voice", "")))
	add_child(memory)
	var voice := YardVoiceScript.new()
	voice.name = "YardVoice"
	voice.position = Vector2(1110, 587)
	voice.ink = ink
	voice.stock = bg_color
	_persistent(voice, &"yard_first_voice")
	voice.freed.connect(_present_yard_outcome.bind("freed"))
	voice.shattered.connect(_present_yard_outcome.bind("shattered"))
	add_child(voice)
	sign_label(Vector2(1530, 324), "ONE BAR REMAINS\nThis voice still reaches.\nHold SET [L / LB] nearby to hear it.")
	_auditioner(Vector2(1640, 587), &"yard_last_voice")

func _present_yard_outcome(_pos: Vector2, outcome: String) -> void:
	get_node("YardMemory").present_outcome(outcome)
	_update_yard_note(outcome)

func _update_yard_note(outcome: String) -> void:
	if outcome == _yard_note_outcome:
		return
	_yard_note_outcome = outcome
	if is_instance_valid(_yard_note):
		_notes.erase(_yard_note)
		remove_child(_yard_note)
		_yard_note.queue_free()
	var text := "AN UNFINISHED NAME\nTwo notes. Then it falters.\nYour Hood leaves room to listen."
	if outcome == "freed":
		text = "A NAME REMEMBERED\nThe stone keeps the ending.\nStay quietly. It returns."
	elif outcome == "shattered":
		text = "A BROKEN IMPRESSION\nTwo notes, left in the stone.\nThe space between stays quiet."
	sign_label(Vector2(645, 215), text)
	_yard_note = _notes.back()

func _build_descent_gate() -> void:
	_floor(1700)
	_impression(&"arch", Vector2(1130, 328), Vector2(400, 500))
	_exit(Vector2(85, 574), &"groove_yard", "THE YARD")
	_exit(Vector2(1560, 574), &"overture_stair", "THE OVERTURE")
	sign_label(Vector2(315, 345), "A HELD NOTE\nThe way down has been\nwaiting for someone to begin.")
	sign_label(Vector2(720, 344), "COUNT IT IN\nFour even strikes. Any tempo.\nA door listens before it knows you.")
	_listening_door(Vector2(1140, 525), &"descent_count_in")

func _build_overture_stair() -> void:
	platform(Vector2(285, 460), Vector2(570, 60))
	platform(Vector2(635, 530), Vector2(170, 40))
	platform(Vector2(780, 610), Vector2(170, 40))
	platform(Vector2(925, 690), Vector2(170, 40))
	platform(Vector2(1070, 770), Vector2(170, 40))
	platform(Vector2(1215, 845), Vector2(170, 40))
	platform(Vector2(1500, 920), Vector2(600, 140))
	_exit(Vector2(85, 404), &"label_descent", "THE LABEL")
	_impression(&"stair", Vector2(910, 580), Vector2(720, 700))
	_impression(&"arch", Vector2(1580, 622), Vector2(300, 450))
	sign_label(Vector2(265, 225), "THE OVERTURE\nThe walls are worn so thin\nyou can hear the other side.")
	sign_label(Vector2(1180, 545), "THE FIRST NOTE\nYou came all this way.\nStay long enough to hear it.")
	_exit(Vector2(1590, 824), &"bootlegger", "THE BOOTLEGGER")

func _floor(width: float) -> void:
	platform(Vector2(width / 2.0, 630), Vector2(width, 60))

func _exit(pos: Vector2, target: StringName, caption: String) -> void:
	route_exit(pos, target, StringName("from_" + String(room_id)), caption)

func _listening_door(pos: Vector2, id: StringName) -> void:
	var door := DoorScript.new()
	door.position = pos
	_persistent(door, id)
	add_child(door)
	# The lintel meets the top of the 150 px lock. A launch cannot vault the
	# lesson; this is a physical rhythm puzzle, never a journal permission.
	platform(Vector2(pos.x, 190), Vector2(86, 520))

func _auditioner(pos: Vector2, id: StringName) -> void:
	var voice := AuditionerScript.new()
	voice.position = pos
	_persistent(voice, id)
	add_child(voice)

func _polish(pos: Vector2, id: StringName) -> void:
	var wax := PatchScript.new()
	wax.position = pos
	_persistent(wax, id)
	add_child(wax)

func _persistent(node: Node, id: StringName) -> void:
	node.set_meta("chapter_state_id", id)
	node.add_to_group("chapter_persistent")

func _impression(kind: StringName, pos: Vector2, size: Vector2) -> void:
	var picture := PressScript.impression(kind, size, ink, bg_color)
	picture.position = pos
	picture.z_index = -30
	if kind in [&"facade", &"market", &"stair"]:
		picture.modulate.a = 0.56
	elif kind == &"headstone":
		picture.modulate.a = 0.75
	picture.set_meta("impression_kind", kind)
	picture.set_meta("impression_size", size)
	_scenery.append(picture)
	add_child(picture)

func apply_side(next_side: int) -> void:
	super.apply_side(next_side)
	# The same scenery is reprinted in the other face's ink, like the plates.
	for index in range(_scenery.size()):
		var previous := _scenery[index]
		var next_picture := PressScript.impression(
			previous.get_meta("impression_kind"), previous.get_meta("impression_size"),
			_solid_color(), _stock_color()
		)
		next_picture.position = previous.position
		next_picture.z_index = previous.z_index
		next_picture.modulate = previous.modulate
		next_picture.set_meta("impression_kind", previous.get_meta("impression_kind"))
		next_picture.set_meta("impression_size", previous.get_meta("impression_size"))
		remove_child(previous)
		previous.queue_free()
		add_child(next_picture)
		_scenery[index] = next_picture
	for child in get_children():
		if (child.is_in_group("world_resident") or child.is_in_group("map_pickup") or child.name in [&"LoftVoice", &"YardVoice", &"YardMemory", &"StreetLooper"]) and child.has_method("reink"):
			child.call("reink", _solid_color(), _stock_color())

func set_scenery_motion(reduced: bool) -> void:
	super.set_scenery_motion(reduced)
	for child in get_children():
		if child.is_in_group("map_pickup"):
			child.call("set_reduced_motion", reduced)

func _process(delta: float) -> void:
	if room_id == &"high_street":
		var looper := get_node_or_null("StreetLooper")
		if (looper != null and looper.state == StreetLooperScript.S.DOWN) or String(session_outcomes.get("high_street/street_looper", "")) == "shattered":
			objective_label = "The street is quiet. Practice lies ahead."
		else:
			objective_label = "Let the Looper swing. Answer while its guard is open."
		return
	if room_id == &"the_stalls":
		_refresh_stalls_objective()
		return
	if room_id != &"horn_plaza" or _horn_heard:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return
	var listening: bool = (
		player.get("hooded") == true
		and player.velocity.length() < 10.0
		and player.global_position.distance_to(HORN_POSITION) < HORN_LISTEN_RADIUS
	)
	_horn_time = _horn_time + delta if listening else 0.0
	if _horn_time >= HORN_LISTEN_TIME:
		_horn_heard = true
		var bank := get_tree().get_first_node_in_group("audio_bank")
		if bank != null:
			bank.call("play", "freed", -11.0, 0.7)
		route_blocked.emit("For a moment, the great horn answers your silence.")

func _refresh_stalls_objective() -> void:
	if String(session_outcomes.get("the_stalls/loft_voice", "")) == "freed":
		objective_label = "A small song knows the way home. The gallery passage is open."
	elif progression != null and progression.has_refrain(ProgressionScript.Refrain.GATHER):
		objective_label = "The upper room is closer than it was."
	else:
		objective_label = "Let the live groove carry you across the market."

## Main keeps the outcomes. Recreating a room only applies its own stable
## entries; this method neither records completion nor unlocks knowledge.
func restore_encounters(outcomes: Dictionary) -> void:
	if room_id == &"groove_yard":
		get_node("YardMemory").restore_outcome(String(outcomes.get("groove_yard/yard_first_voice", "")))
		_update_yard_note(String(outcomes.get("groove_yard/yard_first_voice", "")))
	for child in get_children():
		if not child.has_meta("chapter_state_id"):
			continue
		var key := String(room_id) + "/" + String(child.get_meta("chapter_state_id"))
		var outcome := String(outcomes.get(key, ""))
		if outcome == "opened" and child is StaticBody2D and "is_open" in child:
			child.set("is_open", true)
			var block := child.get_node_or_null("block") as CollisionShape2D
			if block != null:
				block.set_deferred("disabled", true)
			child.queue_redraw()
		elif outcome == "polished" and "done" in child:
			child.set("done", true)
			child.set("progress", 1.0)
			child.queue_redraw()
		elif outcome in ["freed", "shattered", "won"]:
			if child.has_method("restore_outcome"):
				child.call("restore_outcome", outcome)
			else:
				remove_child(child)
				child.queue_free()
