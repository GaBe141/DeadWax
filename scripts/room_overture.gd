extends "res://scripts/room_base.gd"
## Seven authored rooms below the Label: wind, a doorway, a long return climb,
## HUSH's floor, and the arm that has been pointing home.

signal chapter_completed

const AddieScript := preload("res://scripts/addie.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")
const HushScript := preload("res://scripts/hush.gd")
const TonearmScript := preload("res://scripts/tonearm.gd")
const OutcomeExitScript := preload("res://scripts/outcome_exit.gd")
const ListeningPostScript := preload("res://scripts/listening_post.gd")
const WindScript := preload("res://scripts/wind_groove.gd")
const MarkerScript := preload("res://scripts/chapter_marker.gd")

var session_outcomes: Dictionary = {}
var objective_label := "Follow the worn song below the Label."
var _scenery: Array[Node2D] = []
var _endpoint: Node2D
var _seal_note: Control

func configure(id: StringName) -> void:
	room_id = id
	bg_color = Color("e3bfb6")
	ink = Color("362b30")
	spawn_pos = Vector2(160, 574)
	death_y = 1180.0
	cam_limits = Rect2(0, 0, 1800, 800)
	match room_id:
		&"bootlegger":
			band_name = "The Bootlegger's Stall"
			band_desc = "A little warmth, unfolded from the wall."
			objective_label = "The whistling comes from the west."
			cam_limits.size.x = 1700.0
			spawn_pos = Vector2(1490, 574)
			register_entry(&"from_overture_stair", spawn_pos)
			register_entry(&"from_whistlers", Vector2(185, 574))
		&"whistlers":
			band_name = "The Whistlers"
			band_desc = "So little wax left, the wind can play it."
			objective_label = "Strike the whistles to ride west. The lower steps catch a missed note."
			cam_limits = Rect2(0, 0, 2600, 1080)
			death_y = 1380.0
			spawn_pos = Vector2(2400, 574)
			register_entry(&"from_bootlegger", spawn_pos)
			register_entry(&"from_addie", Vector2(190, 574))
		&"addie":
			band_name = "Addie's Doorway"
			band_desc = "Adagio in C. A door left open at the last bar."
			objective_label = "Addie is still waiting to be heard. The well is through her doorway."
			bg_color = Color("e7c9bd")
			spawn_pos = Vector2(1580, 574)
			register_entry(&"from_whistlers", spawn_pos)
			register_entry(&"from_overture_well", Vector2(180, 574))
		&"overture_well":
			band_name = "The Overture Well"
			band_desc = "The song gets farther away. Its echo does not."
			objective_label = "Follow the well down. Its staggered ledges also lead home."
			bg_color = Color("d6b1ad")
			cam_limits = Rect2(0, 0, 1350, 1570)
			death_y = 1900.0
			spawn_pos = Vector2(180, 254)
			register_entry(&"from_addie", spawn_pos)
			register_entry(&"from_worn_gallery", Vector2(1150, 1334))
		&"worn_gallery":
			band_name = "The Worn Gallery"
			band_desc = "A procession, almost rubbed away."
			objective_label = "Find HUSH beyond the gallery. Keep your Hood up to soften your approach."
			bg_color = Color("d9bcb7")
			cam_limits.size.x = 2600.0
			register_entry(&"from_overture_well", Vector2(180, 574))
			register_entry(&"from_smoothed_floor", Vector2(2380, 574))
			register_entry(&"from_the_arm", Vector2(1930, 574))
		&"smoothed_floor":
			band_name = "The Smoothed Floor"
			band_desc = "Someone has burnished every last ring away."
			objective_label = "HUSH asks for three rung-backs. Strike as each swing lands."
			bg_color = Color("ded5df")
			ink = Color("494450")
			muted = true
			cam_limits.size.x = 2200.0
			register_entry(&"from_worn_gallery", Vector2(180, 574))
			register_entry(&"from_the_arm", Vector2(1960, 574))
		&"the_arm":
			band_name = "The Arm"
			band_desc = "The empty grip remembers what it was holding."
			objective_label = "It points home. It will not swing first."
			bg_color = Color("cfaea9")
			ink = Color("302631")
			cam_limits = Rect2(0, 0, 2250, 850)
			register_entry(&"from_smoothed_floor", Vector2(185, 574))
			register_entry(&"from_worn_gallery", Vector2(2020, 574))

func _ready() -> void:
	match room_id:
		&"bootlegger": _build_bootlegger()
		&"whistlers": _build_whistlers()
		&"addie": _build_addie()
		&"overture_well": _build_well()
		&"worn_gallery": _build_gallery()
		&"smoothed_floor": _build_smoothed_floor()
		&"the_arm": _build_arm()
	platform(Vector2(-25, cam_limits.size.y / 2.0), Vector2(50, cam_limits.size.y + 400))
	platform(Vector2(cam_limits.size.x + 25, cam_limits.size.y / 2.0), Vector2(50, cam_limits.size.y + 400))

func _build_bootlegger() -> void:
	_floor(1700)
	_impression(&"overture", Vector2(860, 365), Vector2(1250, 470))
	_impression(&"counter", Vector2(760, 442), Vector2(550, 300))
	_impression(&"organ", Vector2(300, 345), Vector2(200, 470))
	_exit(Vector2(85, 574), &"whistlers", "THE WHISTLERS")
	_exit(Vector2(1590, 574), &"overture_stair", "THE STAIR")
	sign_label(Vector2(1100, 310), "BELOW THE LABEL\nThe wall has opened\njust enough for a stall.")
	sign_label(Vector2(475, 185), "WORN NAMES ONLY\nThe Bootlegger is listening.\n[E / Y] by the counter")
	_listening_post(Vector2(760, 574), "THE BOOTLEGGER", [
		"The whistles only know one way.\nWest. Let them carry you.",
		"Addie's door is still open.\nShe has been waiting at the last bar.",
		"Below her, someone swept the floor.\nBelow him, something points home.",
	])
	_polish(Vector2(1200, 574), &"stall_wax")
	platform(Vector2(1320, 535), Vector2(180, 30))

func _build_whistlers() -> void:
	# The played route follows the wind west over a set of high islands. Both
	# banks are connected on legs as well: the floor below is a recovery path.
	platform(Vector2(285, 630), Vector2(570, 60))
	platform(Vector2(2345, 630), Vector2(510, 60))
	platform(Vector2(1300, 910), Vector2(2120, 60))
	platform(Vector2(1740, 525), Vector2(280, 40))
	platform(Vector2(1360, 445), Vector2(260, 40))
	platform(Vector2(980, 420), Vector2(280, 40))
	platform(Vector2(650, 500), Vector2(240, 40))
	# Return steps climb through the open shaft, then meet each bank's edge.
	# Placing them below the banks would leave only 30 px of headroom above
	# the upper tread: a drawn staircase that the player's body cannot climb.
	platform(Vector2(1850, 795), Vector2(220, 30))
	platform(Vector2(2015, 705), Vector2(220, 30))
	platform(Vector2(830, 795), Vector2(220, 30))
	platform(Vector2(665, 705), Vector2(200, 30))
	_exit(Vector2(85, 574), &"addie", "ADDIE'S DOOR")
	_exit(Vector2(2505, 574), &"bootlegger", "THE STALL")
	for index in range(5):
		_impression(&"organ", Vector2(440 + index * 420, 356), Vector2(245, 520))
	_wind(Vector2(2160, 572))
	_wind(Vector2(1420, 397))
	sign_label(Vector2(1965, 242), "WEST, WITH THE WIND\nSTRIKE [J / X] the whistle.\nIt throws one way.  ←")
	sign_label(Vector2(1150, 188), "A SECOND BREATH OF WIND\nThe whistle answers again.  ←\nThe air between stays dry.")
	sign_label(Vector2(1120, 700), "THE WAY BACK\nA missed note lands here.\nTake either set of steps.")
	_polish(Vector2(390, 574), &"whistler_wax")

func _build_addie() -> void:
	_floor(1800)
	_impression(&"overture", Vector2(910, 360), Vector2(1520, 450))
	_impression(&"arch", Vector2(835, 360), Vector2(435, 445))
	_impression(&"column", Vector2(350, 352), Vector2(110, 440))
	_impression(&"column", Vector2(1460, 352), Vector2(110, 440))
	_exit(Vector2(85, 574), &"overture_well", "THE WELL")
	_exit(Vector2(1690, 574), &"whistlers", "THE WHISTLERS")
	var addie := AddieScript.new()
	addie.name = "Addie"
	addie.position = Vector2(850, 587)
	_persistent(addie, &"addie")
	add_child(addie)
	sign_label(Vector2(1165, 185), "ADAGIO IN C\nA name worn into the door.\nAddie.")
	sign_label(Vector2(500, 287), "ONE LAST BAR\nHold L / left shoulder nearby.\nLet her hear the end.")
	_listening_post(Vector2(1310, 574), "AT THE DOOR", [
		"The handle has been polished\nby the same hand, waiting.",
		"A held note is still a note.\nThere is time enough to listen.",
	])
	_polish(Vector2(330, 574), &"doorstep_wax")

func _build_well() -> void:
	platform(Vector2(230, 310), Vector2(460, 60))
	platform(Vector2(675, 1390), Vector2(1350, 60))
	for index in range(11):
		var top := 370.0 + index * 90.0
		var x := 540.0 if index % 2 == 0 else 785.0
		platform(Vector2(x, top + 18), Vector2(250, 36))
	_impression(&"column", Vector2(185, 855), Vector2(220, 1140))
	_impression(&"column", Vector2(1110, 795), Vector2(180, 1140))
	_impression(&"overture", Vector2(655, 817), Vector2(950, 1110))
	_exit(Vector2(85, 254), &"addie", "ADDIE'S DOOR")
	_exit(Vector2(1240, 1334), &"worn_gallery", "THE GALLERY")
	groove(Vector2(575, 522))
	groove(Vector2(575, 1062))
	sign_label(Vector2(205, 98), "DOWN THE WELL\nThe ledges remember\nthe way back.")
	sign_label(Vector2(895, 500), "WAX IN THE WALL\nA strike climbs faster.\nA jump is enough.")
	sign_label(Vector2(80, 960), "WELL ECHO\nEvery note comes back\na little thinner.")
	_listening_post(Vector2(340, 1334), "THE WELL ANSWERS", [
		"Someone played up there.\nSomeone down here answered.",
		"The echo is not another voice.\nIt was the same one, returning.",
	])
	_polish(Vector2(1010, 1334), &"well_wax")

func _build_gallery() -> void:
	_floor(2600)
	for index in range(7):
		_impression(&"column", Vector2(260 + index * 335, 348), Vector2(125, 465))
	_impression(&"overture", Vector2(1140, 320), Vector2(1700, 530))
	_impression(&"arch", Vector2(1840, 385), Vector2(285, 420))
	_exit(Vector2(85, 574), &"overture_well", "THE WELL")
	_exit(Vector2(2480, 574), &"smoothed_floor", "THE SMOOTHED FLOOR")
	_outcome_exit(
		Vector2(1840, 574), &"the_arm", "THE ARM", "the_arm/gallery_shortcut", ["opened"],
		"OPEN FROM BELOW", "A latch holds this way from the Arm's side. HUSH is farther along the gallery."
	)
	# The raised arcade keeps an ordinary jump route over the voices. Quiet
	# ground travel, listening, fighting and climbing remain genuine choices.
	platform(Vector2(455, 540), Vector2(200, 40))
	platform(Vector2(710, 450), Vector2(210, 40))
	platform(Vector2(980, 370), Vector2(240, 40))
	platform(Vector2(1260, 450), Vector2(220, 40))
	platform(Vector2(1515, 540), Vector2(200, 40))
	_auditioner(Vector2(900, 587), &"gallery_near_voice")
	_auditioner(Vector2(1340, 587), &"gallery_far_voice")
	sign_label(Vector2(215, 287), "ALMOST RUBBED AWAY\nThe Hood softens your approach.\nThe arcade leaves them room.")
	sign_label(Vector2(1740, 257), "AN OLD SERVICE WAY\nThe latch opens from below.")
	sign_label(Vector2(2115, 313), "NO RING BEYOND HERE\nSomeone has smoothed\nthe next floor by hand.")
	_polish(Vector2(2240, 574), &"gallery_wax")

func _build_smoothed_floor() -> void:
	_floor(2200)
	_impression(&"overture", Vector2(1100, 330), Vector2(1750, 520))
	_impression(&"column", Vector2(230, 322), Vector2(120, 510))
	_impression(&"column", Vector2(1930, 322), Vector2(120, 510))
	_exit(Vector2(85, 574), &"worn_gallery", "THE GALLERY")
	_outcome_exit(
		Vector2(2090, 574), &"the_arm", "THE ARM", "smoothed_floor/hush", ["won"],
		"HUSH HOLDS THE WAY", "HUSH waits for three clean rung-backs. Strike as his swing lands."
	)
	var hush := HushScript.new()
	hush.name = "Hush"
	hush.position = Vector2(1100, 557)
	hush.print_ink = ink
	hush.print_stock = bg_color
	_persistent(hush, &"hush")
	add_child(hush)
	sign_label(Vector2(300, 293), "HUSH\nNo grooves. No resonance.\nOnly what you catch counts.")
	sign_label(Vector2(715, 222), "THREE CLEAN RUNG-BACKS\nThree ticks, then the swing.\nStrike [J / X] as it lands.")
	sign_label(Vector2(1490, 305), "GO HOME.\nA note, under fresh burnish.")

func _build_arm() -> void:
	_floor(2250)
	_impression(&"overture", Vector2(1170, 315), Vector2(1920, 550))
	_impression(&"column", Vector2(340, 308), Vector2(160, 555))
	_impression(&"arch", Vector2(1820, 345), Vector2(350, 490))
	_exit(Vector2(85, 574), &"smoothed_floor", "HUSH'S FLOOR")
	_exit(Vector2(2150, 574), &"worn_gallery", "GALLERY SHORTCUT")
	var arm := TonearmScript.new()
	arm.name = "Tonearm"
	arm.position = Vector2(1260, 574)
	arm.ink = ink
	arm.stock = bg_color
	_persistent(arm, &"tonearm")
	add_child(arm)
	sign_label(Vector2(445, 275), "THE ARM\nIt points home.\nIt will not swing first.")
	sign_label(Vector2(670, 408), "AN OPEN HAND\nYou can kneel beside it.\nYou can choose to strike.")
	_seal_note = _note(Vector2(1645, 195), "THE SEAL", "The arm has held this way\nfor a very long time.")

func _floor(width: float) -> void:
	platform(Vector2(width / 2.0, 630), Vector2(width, 60))

func _exit(pos: Vector2, target: StringName, caption: String) -> void:
	route_exit(pos, target, StringName("from_" + String(room_id)), caption)

func _outcome_exit(
	pos: Vector2, target: StringName, caption: String, key: String,
	outcomes: Array[String], gate_caption: String, message: String
) -> void:
	var passage := OutcomeExitScript.new()
	passage.position = pos
	passage.target_room = target
	passage.target_entry = StringName("from_" + String(room_id))
	passage.display_name = caption
	passage.session_outcomes = session_outcomes
	passage.required_outcome_key = key
	passage.required_outcomes = outcomes
	passage.gate_label = gate_caption
	passage.blocked_message = message
	passage.route_requested.connect(_on_exit_route_requested)
	passage.route_blocked.connect(_on_exit_route_blocked)
	add_child(passage)

func _wind(pos: Vector2) -> void:
	var whistle := WindScript.new()
	whistle.position = pos
	whistle.side = PressingScript.Side.A
	whistle.set_current_side(side)
	_grooves.append(whistle)
	add_child(whistle)

func _listening_post(pos: Vector2, heading: String, lines: Array[String]) -> void:
	var post := ListeningPostScript.new()
	post.position = pos
	post.heading = heading
	post.lines = lines
	post.ink = ink
	post.stock = bg_color
	add_child(post)

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
	picture.set_meta("impression_kind", kind)
	picture.set_meta("impression_size", size)
	_scenery.append(picture)
	add_child(picture)

func _note(pos: Vector2, heading: String, body: String) -> Control:
	var note := PressScript.card(body, _solid_color(), _stock_color(), PressScript.PINK, PressScript.SIZE_BODY, heading)
	note.position = pos
	_notes.append(note)
	add_child(note)
	return note

func apply_side(next_side: int) -> void:
	super.apply_side(next_side)
	for picture in _scenery:
		picture.set("ink", _solid_color())
		picture.set("stock", _stock_color())
		picture.queue_redraw()
	for child in get_children():
		if child.has_method("reink"):
			child.call("reink", _solid_color(), _stock_color())
		if child.get_script() == HushScript:
			child.set("print_ink", _solid_color())
			child.set("print_stock", _stock_color())
			child.queue_redraw()
		elif child.get_script() == TonearmScript:
			child.set("ink", _solid_color())
			child.set("stock", _stock_color())
			child.queue_redraw()

func _process(_delta: float) -> void:
	if room_id == &"the_arm":
		_ensure_endpoint()
	elif room_id == &"smoothed_floor" and String(session_outcomes.get("smoothed_floor/hush", "")) == "won":
		objective_label = "HUSH bows. The way to the Arm stands open."
	elif room_id == &"addie":
		var outcome := String(session_outcomes.get("addie/addie", ""))
		if outcome == "freed":
			objective_label = "Addie has heard the end. The well waits through the doorway."
		elif outcome == "shattered":
			objective_label = "The doorway is quiet. The well waits below."

func _ensure_endpoint() -> void:
	if room_id != &"the_arm" or _endpoint != null:
		return
	var outcome := String(session_outcomes.get("the_arm/tonearm", ""))
	if outcome not in ["freed", "shattered"]:
		return
	objective_label = "The seal is open. Reach it and listen beyond."
	if _seal_note != null:
		_notes.erase(_seal_note)
		remove_child(_seal_note)
		_seal_note.queue_free()
		_seal_note = null
	_endpoint = MarkerScript.new()
	_endpoint.position = Vector2(1820, 574)
	_endpoint.ink = _solid_color()
	_endpoint.stock = _stock_color()
	_endpoint.heading = "THE OPEN SEAL"
	_endpoint.prompt = "[E / Y]  Listen beyond"
	_endpoint.activated.connect(_on_chapter_completed)
	add_child(_endpoint)

func _on_chapter_completed() -> void:
	chapter_completed.emit()

func restore_encounters(outcomes: Dictionary) -> void:
	session_outcomes = outcomes
	for child in get_children():
		if child.get_script() == OutcomeExitScript:
			child.set("session_outcomes", outcomes)
		if not child.has_meta("chapter_state_id"):
			continue
		var key := String(room_id) + "/" + String(child.get_meta("chapter_state_id"))
		var outcome := String(outcomes.get(key, ""))
		if child.has_method("restore_outcome"):
			child.call("restore_outcome", outcome)
		elif outcome == "polished" and "done" in child:
			child.set("done", true)
			child.set("progress", 1.0)
			child.queue_redraw()
		elif outcome in ["freed", "shattered", "won"]:
			remove_child(child)
			child.queue_free()
	_ensure_endpoint()
