extends SceneTree
## Presentation cues exercise the existing actors without any player save.

const Post := preload("res://scripts/listening_post.gd")
const Resident := preload("res://scripts/resident.gd")
const Passage := preload("res://scripts/room_exit.gd")
const OutcomePassage := preload("res://scripts/outcome_exit.gd")
const Loft := preload("res://scripts/loft_voice.gd")
const Yard := preload("res://scripts/yard_voice.gd")
const Tonearm := preload("res://scripts/tonearm.gd")
const Skip := preload("res://scripts/skip.gd")
var _checks := 0
var _failures: Array[String] = []
var _player: CharacterBody2D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for action in ["lift", "set", "move_left", "move_right", "move_up", "move_down", "jump", "strike", "enter_passage"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var floor := StaticBody2D.new()
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2200, 40)
	floor_shape.shape = rectangle
	floor.position.y = 46.0
	floor.add_child(floor_shape)
	root.add_child(floor)
	_player = Skip.new()
	root.add_child(_player)
	for index in range(8):
		await physics_frame
		await process_frame
	_player.set_physics_process(false)
	_player.set_process(false)
	_check(_player.is_on_floor(), "dialogue fixture has a grounded player")
	_check_conversation()
	_check_passages()
	_check_phrase_cues()
	_check_keeper()
	_player.free()
	floor.free()
	if _failures.is_empty():
		print("DEAD WAX CINEMATIC ACTORS PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("CINEMATIC ACTORS FAIL: " + failure)
	quit(1)

func _check_conversation() -> void:
	var post := Post.new()
	post.heading = "THE OLD VOICE"
	post.lines = ["A small song.\nOnly for you.", "The next line."]
	root.add_child(post)
	post.set_process(false)
	post._process(0.0)
	_check(post._card.visible, "legacy presentation keeps its nearby listening card")
	post.set_cinematic_mode(true)
	_check(not post._card.visible, "cinematic listening hides the world card immediately")
	_check(not post.cinematic_snapshot().has("dialogue"), "proximity alone never shows spoken text")
	_check(post.cinematic_snapshot().text == "E / Y · Listen", "an idle post supplies a single short listening cue")
	_check(post.try_listen(), "the existing grounded interaction starts a spoken line")
	var spoken := post.cinematic_snapshot()
	_check(spoken.dialogue == post.lines[0] and spoken.speaker == post.heading and spoken.priority == 100,
		"only requested dialogue is supplied with the real speaker and priority")
	_check(not String(spoken.dialogue).contains("[E") and not post._card.visible,
		"spoken text has no appended controls or floating card")
	post._process(7.5)
	_check(post.cinematic_snapshot().has("dialogue"), "a spoken line remains available for its reading time")
	paused = true
	var remaining: float = post._dialogue_remaining
	post._process(2.0)
	_check(post._dialogue_remaining == remaining and not post.try_listen(), "pause freezes dialogue and ignores direct listening intent")
	paused = false
	post._process(0.6)
	_check(not post.cinematic_snapshot().has("dialogue"), "a spoken line expires after eight gameplay seconds")
	_check(post.try_listen() and post.cinematic_snapshot().dialogue == post.lines[1], "a new interaction advances the conversation")
	_player.position.x = Post.LISTEN_RADIUS + 1.0
	post._process(0.01)
	_check(post._line == -1 and not post.cinematic_snapshot().has("dialogue"), "walking away closes and resets the conversation")
	_player.position.x = 0.0
	post._process(0.01)
	_check(not post.cinematic_snapshot().has("dialogue"), "returning nearby never replays a closed line")
	post.set_cinematic_mode(false)
	_check(post._card.visible, "returning to legacy presentation restores the nearby card")
	_check(post.try_listen(), "legacy dialogue remains available")
	post.cancel_dialogue()
	_check(post._line == 0 and post._card.visible, "presentation cancellation leaves legacy dialogue unchanged")
	post.set_cinematic_mode(true)
	post.cancel_dialogue()
	_check(post._line == -1 and post._dialogue_remaining == 0.0 and not post._card.visible,
		"cinematic cancellation closes the actor's line and timer without restoring a world card")
	post.free()
	var resident := Resident.new()
	root.add_child(resident)
	resident.set_process(false)
	resident.set_cinematic_mode(true)
	resident._process(0.0)
	_check(resident.cinematic_snapshot().text.contains("Browse"), "the Bootlegger retains a concise shop cue")
	resident.kind = &"tick"
	_check(resident.cinematic_snapshot().text == "E / Y · Talk", "other residents retain a concise talk cue")
	resident.free()

func _check_passages() -> void:
	var passage := Passage.new()
	passage.target_room = &"horn_plaza"
	passage.display_name = "Horn Plaza"
	root.add_child(passage)
	passage.set_process(false)
	_check(passage._label.visible, "legacy passage keeps its destination label")
	passage.set_cinematic_mode(true)
	passage._refresh_label()
	_check(not passage._label.visible, "cinematic passages hide labels on refresh as well as mode changes")
	_check(passage.cinematic_snapshot().text == "E / Y · Enter Horn Plaza" and passage.cinematic_snapshot().radius == Passage.ACTIVATE_RADIUS,
		"passage cues use the authored destination and existing reach")
	passage.required_refrain = 0
	_check(passage.cinematic_snapshot().text == "Sealed" and passage.is_locked(), "missing permissions remain sealed with one short cue")
	_check(not passage.try_enter(), "presentation never bypasses passage permission")
	passage.free()
	var outcome := OutcomePassage.new()
	outcome.required_outcome_key = "held/door"
	outcome.required_outcomes = ["opened"]
	root.add_child(outcome)
	outcome.set_process(false)
	outcome.set_cinematic_mode(true)
	outcome._refresh_label()
	_check(not outcome._label.visible and outcome.cinematic_snapshot().text == "Sealed", "outcome passages inherit cinematic presentation without exposing their gate")
	outcome.session_outcomes["held/door"] = "opened"
	outcome._refresh_label()
	_check(not outcome.is_locked() and not outcome._label.visible, "the existing outcome opens its passage without restoring floating text")
	outcome.free()

func _check_phrase_cues() -> void:
	var loft := Loft.new()
	root.add_child(loft)
	loft.set_process(false)
	loft.set_physics_process(false)
	loft.set_cinematic_mode(true)
	loft._near = true
	loft._refresh_card()
	_check(not loft._card.visible and loft.cinematic_snapshot().text.is_empty(), "the idle loft retains its visual notes without an explanation card")
	loft.advance_phrase(0.01, true, true, false, false)
	_check(loft.cinematic_snapshot().text == "Listen · One", "the first complete Hood call has a short note cue")
	loft.set_reduced_motion(true)
	loft.advance_phrase(Loft.CALL_TIME, true, true, false, false)
	_check(loft.stage == Loft.Stage.ANSWERING and loft.cinematic_snapshot().text == "L / LB · Answer", "reduced motion retains the exact fresh response window and cue")
	loft._refresh_card()
	_check(not loft._card.visible, "changing phrase stage cannot restore a floating card")
	loft.advance_phrase(0.01, false, false, false, false)
	_check(loft.cinematic_snapshot().text.is_empty(), "leaving the loft cancels its response cue")
	loft.free()
	var yard := Yard.new()
	root.add_child(yard)
	yard.set_process(false)
	yard.set_physics_process(false)
	yard.set_cinematic_mode(true)
	yard._noticed = true
	yard._refresh_card()
	_check(not yard._card.visible and yard.cinematic_snapshot().text.is_empty(), "an idle Yard voice carries no floating tutorial")
	yard.advance_phrase(0.01, true, true, false, false)
	yard.advance_phrase(Yard.CALL_TIME, true, true, false, false)
	_check(yard.stage == Yard.Stage.ANSWERING and yard.cinematic_snapshot().text == "L / LB · Answer", "the Yard response still opens exactly after its complete call")
	yard._refresh_card()
	_check(not yard._card.visible, "the Yard response cue does not restore its old card")
	yard.advance_phrase(0.01, false, false, false, false)
	_check(yard.cinematic_snapshot().text.is_empty(), "leaving the Yard cancels its response cue")
	yard.free()

func _check_keeper() -> void:
	var keeper := Tonearm.new()
	root.add_child(keeper)
	keeper.set_process(false)
	keeper.set_cinematic_mode(true)
	_check(keeper.cinematic_mode and keeper.cinematic_snapshot().text.is_empty(), "the sleeping keeper presents no explanatory text")
	keeper.state = Tonearm.S.WAITING
	_check(keeper.cinematic_snapshot().text == "L / LB · Answer" and keeper.cinematic_snapshot().radius == Tonearm.SET_RANGE,
		"the waiting keeper retains its peaceful response within the actual Set reach")
	keeper.state = Tonearm.S.COUNTING
	_check(keeper.cinematic_snapshot().text.is_empty(), "the keeper's count remains a graphic and audio tell")
	_check(keeper.hp == Tonearm.HP_MAX and not keeper._engaged, "changing presentation never starts combat or deals damage")
	keeper.free()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
