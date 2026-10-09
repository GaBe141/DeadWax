extends SceneTree
## Groove pressure: the room's beat as a clock, Skip's pocket rule, counting
## foes on the beat, and Main's setting, pulse, HUD and checkpoint ownership.
## Models and figures advance with explicit steps in Main's order (clock first,
## then the actor). Main is driven through its own methods and private files.

const GrooveScript := preload("res://scripts/groove_clock.gd")
const SkipScript := preload("res://scripts/skip.gd")
const PressingScript := preload("res://scripts/test_pressing.gd")
const LooperScript := preload("res://scripts/street_looper.gd")
const TonearmScript := preload("res://scripts/tonearm.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")
const YardVoiceScript := preload("res://scripts/yard_voice.gd")
const MainScene := preload("res://scenes/main.tscn")
const SaveScript := preload("res://scripts/save_store.gd")
const STEP := 1.0 / 60.0

class GrooveProbe extends Node2D:
	func _ready() -> void: add_to_group("live_groove")
	func reach() -> float: return 20.0
	func is_echo_hot() -> bool: return false
	func ping() -> void: pass

var _checks := 0
var _failures: Array[String] = []
var _directory := ""
var _main: Node2D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_clock()
	_check_skip_rule()
	_check_pressing_count()
	_check_looper_count()
	_check_tonearm_count()
	_check_roused()
	await _check_main()
	if _failures.is_empty():
		print("DEAD WAX GROOVE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("GROOVE FAIL: " + failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func _on_beat_boundary(clock: RefCounted, tolerance: float) -> bool:
	return absf(float(clock.call("offset"))) <= tolerance + 0.0001

# -- the clock ----------------------------------------------------------------

func _check_clock() -> void:
	_check(is_equal_approx(GrooveScript.DEFAULT_PERIOD, PressingScript.TICK_GAP), "the default beat is Tick's count")
	_check(GrooveScript.POCKET_MS >= float(PressingScript.PARRY_WINDOW_MS), "the pocket is never tighter than the parry window")
	_check(GrooveScript.POCKET_LATENCY_MS >= 0.0 and GrooveScript.POCKET_LATENCY_MS < GrooveScript.POCKET_MS, "the beat itself always sits inside the pocket")
	_check(GrooveScript.POCKET_MS + GrooveScript.POCKET_LATENCY_MS < GrooveScript.DEFAULT_PERIOD * 500.0, "the pocket closes before the off-beat")
	_check(GrooveScript.POCKET_MS + GrooveScript.POCKET_LATENCY_MS < TonearmScript.TICK_GAP * 500.0, "at the Arm's tempo the pocket also closes before the off-beat")
	var clock := GrooveScript.new()
	var period: float = clock.period
	_check(clock.beat_index() == 0 and clock.in_pocket(), "time zero sits on the first beat")
	var began := 0
	for frame in 30:
		began += clock.advance(STEP)
	_check(began == 1 and clock.beat_index() == 1, "half a second at Tick's count begins exactly one beat")
	_check(clock.advance(0.0) == 0 and clock.advance(-1.0) == 0, "a zero or negative step keeps time")
	clock.time = period * 3.0 + 0.05
	_check(clock.offset() > 0.0 and clock.in_pocket(), "a late stroke inside the pocket still counts")
	clock.time = period * 3.0 - 0.05
	_check(clock.offset() < 0.0 and clock.in_pocket(), "an early stroke inside the pocket still counts")
	var late_edge := (GrooveScript.POCKET_MS + GrooveScript.POCKET_LATENCY_MS) / 1000.0
	var early_edge := (GrooveScript.POCKET_MS - GrooveScript.POCKET_LATENCY_MS) / 1000.0
	clock.time = period * 3.0 + late_edge - 0.001
	_check(clock.in_pocket(), "the pocket reaches its full late width after the beat")
	clock.time = period * 3.0 - early_edge + 0.001
	_check(clock.in_pocket(), "the pocket reaches its full early width before the beat")
	clock.time = period * 3.0 + late_edge + 0.001
	_check(not clock.in_pocket(), "just past the pocket is off the beat")
	clock.time = period * 3.0 - early_edge - 0.001
	_check(not clock.in_pocket(), "just before the pocket is off the beat")
	clock.time = period * 3.0 + period * 0.5
	_check(not clock.in_pocket(), "the off-beat is outside the pocket")
	clock.time = 0.0
	clock.advance(1.0)
	_check(is_equal_approx(clock.time, GrooveScript.MAX_STEP), "a long hitch delays the beat instead of skipping one")
	clock.time = period * 2.0 + period * 0.25
	clock.set_period(TonearmScript.TICK_GAP)
	_check(clock.beat_index() == 2 and is_equal_approx(clock.since_beat(), TonearmScript.TICK_GAP * 0.25),
		"a new tempo keeps the beat's place: a passage never jerks the pocket")
	clock.set_period(0.0)
	_check(clock.period >= 0.05, "a tempo can never collapse to zero")
	clock.set_period(period)
	for sample in [0.0, 0.03, 0.1, 0.2, 0.3, 0.41]:
		clock.time = period * 10.0 + sample
		var wait: float = clock.next_tick_wait()
		var landing := fmod(clock.time + wait, period)
		_check(wait >= period * GrooveScript.MIN_TICK_LEAD - 0.0001 and wait < period * (1.0 + GrooveScript.MIN_TICK_LEAD) + 0.0001,
			"a count's first tick waits between half and one and a half beats (%.2f)" % sample)
		_check(landing < 0.0001 or period - landing < 0.0001, "a count's first tick lands on a beat (%.2f)" % sample)
	clock.live = true
	clock.time = period * 4.0
	var snapshot: Dictionary = clock.snapshot()
	_check(snapshot.live and snapshot.in_pocket and int(snapshot.beat) == 4, "the snapshot reports the clock truthfully")

# -- Skip's rule ----------------------------------------------------------------

func _new_skip() -> CharacterBody2D:
	var skip := SkipScript.new()
	root.add_child(skip)
	skip.set_process(false)
	skip.set_physics_process(false)
	return skip

func _strikes(skip: CharacterBody2D, count: int) -> Array:
	var bigs: Array = []
	var record := func(_pos: Vector2, big: bool, _launched: bool) -> void: bigs.append(big)
	skip.struck.connect(record)
	skip.cancel_pending_strike()
	for index in count:
		skip.set("_strike_cd", 0.0)
		skip.call("_strike")
	skip.struck.disconnect(record)
	return bigs

func _check_skip_rule() -> void:
	var skip := _new_skip()
	_check(skip.groove == null, "Skip carries no beat until Main hands one over")
	_check(_strikes(skip, 3) == [false, false, true], "without a groove the Accent alone hits big")
	_check(skip.last_strike_groove == &"", "without a groove no stroke is judged")
	var clock := GrooveScript.new()
	skip.groove = clock
	clock.time = clock.period * 5.0 + clock.period * 0.5
	_check(_strikes(skip, 3) == [false, false, true], "a quiet room keeps the classic Accent")
	clock.live = true
	clock.time = clock.period * 5.0 + 0.02
	_check(_strikes(skip, 1) == [true], "a Tap in the pocket hits big")
	_check(skip.last_strike_groove == &"pocket" and float(skip.call("_animation_pose").flat) == 0.0, "a stroke in the pocket prints in colour")
	clock.time = clock.period * 5.0 + clock.period * 0.5
	_check(_strikes(skip, 3) == [false, false, false], "off the beat even the Accent lands light")
	_check(skip.last_strike_groove == &"flat" and skip.executed_strike_step == 3, "the off-beat Accent is still the third gesture")
	_check(float(skip.call("_animation_pose").flat) > 0.99, "an off-beat stroke prints grey")
	var before := Time.get_ticks_msec()
	_strikes(skip, 1)
	_check(skip.last_strike_ms >= before, "the parry clock is stamped on every stroke, on or off the beat")
	skip.call("_clear_combat_impression")
	_check(float(skip.call("_animation_pose").flat) == 0.0, "damage and parries retire the grey impression")
	skip.reset_animation()
	_check(skip.last_strike_groove == &"", "recovery forgets the last judgement")
	# A launch never reads the beat: the same groove throws Skip identically.
	var probe := GrooveProbe.new()
	root.add_child(probe)
	probe.global_position = skip.global_position + Vector2(0, 30)
	var launches: Array[Vector2] = []
	for on_beat in [false, true]:
		clock.time = clock.period * 7.0 + (0.0 if on_beat else clock.period * 0.5)
		skip.velocity = Vector2.ZERO
		var bigs := _strikes(skip, 1)
		launches.append(skip.velocity)
		_check(bigs == [on_beat], "a groove launch is big only in the pocket (%s)" % on_beat)
	_check(launches[0].is_equal_approx(launches[1]), "the pocket never changes a launch impulse")
	probe.free()
	skip.free()

# -- counting foes ----------------------------------------------------------------

## Advances in Main's order (clock, then actor). Records each tick's offset
## from the nearest beat (the swing is the fourth) and, per count, the actual
## time from the count beginning to its first tick.
func _drive_count(stand: Node2D, clock: RefCounted, seconds: float, ticks: Array, leads: Array) -> void:
	var counting := false
	var last_count := 0
	var elapsed := 0.0
	var started := 0.0
	while elapsed < seconds:
		if clock != null:
			clock.advance(STEP)
		var was_counting: bool = stand.state == PressingScript.S.COUNTING
		stand._process(STEP)
		elapsed += STEP
		var now_counting: bool = stand.state == PressingScript.S.COUNTING
		if now_counting and not was_counting:
			counting = true
			last_count = 0
			started = elapsed
		if counting and int(stand._count) > last_count:
			last_count = int(stand._count)
			ticks.append(float(clock.call("offset")) if clock != null else 0.0)
			if last_count == 1:
				leads.append(elapsed - started)
			if last_count >= 4:
				counting = false

func _check_pressing_count() -> void:
	var skip := _new_skip()
	skip.noise = 1.0
	# Classic: the stand's own count, unchanged.
	var stand := PressingScript.new()
	root.add_child(stand)
	stand.set_process(false)
	stand._player = skip
	stand.position = Vector2(100, 0)
	stand._process(STEP)
	stand._process(STEP)
	_check(stand.state == PressingScript.S.COUNTING and is_zero_approx(stand._t), "without a groove the count starts at once, as before")
	var classic_ticks: Array = []
	var classic_leads: Array = []
	stand.state = PressingScript.S.ALERT
	_drive_count(stand, null, 1.0, classic_ticks, classic_leads)
	_check(classic_leads.size() == 1 and absf(float(classic_leads[0]) - PressingScript.TICK_GAP) <= STEP + 0.0001,
		"without a groove the first tick comes one full tick gap after the count begins")
	_check(not stand.has_method("_groove") or stand.call("_groove") == null, "a stand reads no clock from an ungrooved Skip")
	stand.free()
	# Grooved: every tick and the swing fall on the room's beat.
	var clock := GrooveScript.new()
	clock.time = 0.137
	skip.groove = clock
	stand = PressingScript.new()
	root.add_child(stand)
	stand.set_process(false)
	stand._player = skip
	stand.position = Vector2(100, 0)
	var ticks: Array = []
	var leads: Array = []
	_drive_count(stand, clock, 6.0, ticks, leads)
	_check(ticks.size() >= 8, "two full counts run inside six seconds (%d ticks)" % ticks.size())
	var aligned := true
	for offset in ticks:
		aligned = aligned and float(offset) >= -0.0001 and float(offset) <= STEP + 0.0001
	_check(aligned, "each tick and swing lands on the room's beat")
	var fair := true
	for wait in leads:
		fair = fair and float(wait) >= clock.period * GrooveScript.MIN_TICK_LEAD - STEP and float(wait) <= clock.period * 1.5 + STEP
	_check(leads.size() >= 2 and fair, "every count waits half to one and a half beats before its first tick")
	_check(is_equal_approx(float(stand.call("_tick_gap")), clock.period), "the stand counts at the room's tempo")
	stand.muted = true
	stand.state = PressingScript.S.COUNTING
	_check(not stand.is_roused(), "a muted stand never asks for the room's beat")
	stand.free()
	skip.free()

func _check_looper_count() -> void:
	var skip := _new_skip()
	skip.noise = 1.0
	var clock := GrooveScript.new()
	clock.time = 0.29
	skip.groove = clock
	var looper := LooperScript.new()
	root.add_child(looper)
	looper.set_process(false)
	looper._player = skip
	looper.position = Vector2(100, 0)
	var ticks: Array = []
	var leads: Array = []
	_drive_count(looper, clock, 7.0, ticks, leads)
	var aligned := ticks.size() >= 8
	for offset in ticks:
		aligned = aligned and float(offset) >= -0.0001 and float(offset) <= STEP + 0.0001
	_check(aligned, "the High Street looper keeps the room's beat through its openings (%d ticks)" % ticks.size())
	var fair := leads.size() >= 2
	for wait in leads:
		fair = fair and float(wait) >= clock.period * GrooveScript.MIN_TICK_LEAD - STEP and float(wait) <= clock.period * 1.5 + STEP
	_check(fair, "the looper still gives half a beat or more before each count's first tick")
	looper.free()
	skip.free()

func _check_tonearm_count() -> void:
	var skip := _new_skip()
	# Classic count begins exactly when the gesture ends.
	var arm := TonearmScript.new()
	root.add_child(arm)
	arm.set_process(false)
	arm._player = skip
	skip.position = arm.position + Vector2(-80, 0)
	_check(not arm.is_roused(), "an unstruck keeper keeps the room quiet")
	arm.on_player_strike(skip.global_position, false)
	_check(arm.is_roused(), "striking the keeper rouses the room")
	var guard := 0
	while arm.state != TonearmScript.S.COUNTING and guard < 100:
		arm._process(0.05)
		guard += 1
	_check(arm.state == TonearmScript.S.COUNTING and is_zero_approx(arm._t), "without a groove the arm counts at once, as before")
	arm.free()
	# Grooved at the Arm's own tempo: ticks and sweep on the beat.
	var clock := GrooveScript.new()
	clock.set_period(TonearmScript.TICK_GAP)
	clock.time = 0.31
	skip.groove = clock
	arm = TonearmScript.new()
	root.add_child(arm)
	arm.set_process(false)
	arm._player = skip
	skip.position = arm.position + Vector2(-80, 0)
	skip.last_strike_ms = -100000
	arm.on_player_strike(skip.global_position, false)
	var tick_offsets: Array = []
	var sweep_offsets: Array = []
	var count_starts: Array = []
	var last_count := 0
	var previous: int = arm.state
	var elapsed := 0.0
	while elapsed < 14.0 and arm.outcome.is_empty():
		clock.advance(STEP)
		arm._process(STEP)
		elapsed += STEP
		if arm.state == TonearmScript.S.COUNTING and previous != TonearmScript.S.COUNTING:
			count_starts.append(clock.time)
			last_count = 0
		if arm.state == TonearmScript.S.COUNTING and arm._count > last_count:
			last_count = arm._count
			tick_offsets.append(clock.offset())
		if arm.state == TonearmScript.S.SWEEP and previous != TonearmScript.S.SWEEP:
			sweep_offsets.append(clock.offset())
		previous = arm.state
	var aligned := tick_offsets.size() >= 6 and sweep_offsets.size() >= 2
	for offset in tick_offsets + sweep_offsets:
		aligned = aligned and float(offset) >= -0.0001 and float(offset) <= STEP + 0.0001
	_check(aligned, "every tick and sweep of the keeper falls on the Arm's beat (%d ticks, %d sweeps)" % [tick_offsets.size(), sweep_offsets.size()])
	_check(count_starts.size() >= 2, "the keeper keeps counting after each sweep")
	_check(skip.last_strike_ms == -100000, "keeping time never strikes for the player")
	arm.free()
	skip.free()

func _check_roused() -> void:
	var voice := AuditionerScript.new()
	voice.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(voice)
	_check(not voice.is_roused(), "a calm Auditioner keeps the room quiet")
	for state in [AuditionerScript.S.PURSUE, AuditionerScript.S.REACH, AuditionerScript.S.STAGGER, AuditionerScript.S.RECOVER]:
		voice.state = state
		_check(voice.is_roused(), "a reaching Auditioner rouses the room (%d)" % state)
	for state in [AuditionerScript.S.FREED, AuditionerScript.S.DOWN]:
		voice.state = state
		_check(not voice.is_roused(), "a resolved Auditioner lets the room fall quiet (%d)" % state)
	voice.free()
	var yard := YardVoiceScript.new()
	yard.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(yard)
	yard.state = AuditionerScript.S.PURSUE
	_check(yard.is_roused(), "the Yard voice is an ordinary listener outside its exchange")
	yard.advance_phrase(0.01, true, true, false, false)
	_check(yard.stage == YardVoiceScript.Stage.CALLING and not yard.is_roused(), "no beat sounds over the Yard's quiet call")
	yard.free()

# -- Main: setting, tempo, pulse, judgement, HUD, checkpoint --------------------

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _clear_pool() -> void:
	for player in _main.audio._pool:
		player.stop()
		player.stream = null

func _pool_has(cue: String) -> bool:
	for player in _main.audio._pool:
		if player.stream != null and player.stream == _main.audio._sounds[cue]:
			return true
	return false

func _check_main() -> void:
	_directory = "user://deadwax-groove-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated groove fixture")
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_check(_main.player.groove == null and not _main.game_menu.settings.groove_pressure, "Groove pressure starts off")
	_main.game_menu._open_subpage("settings")
	var toggle := _main.game_menu._page.get_node_or_null("GroovePressure") as CheckButton
	_check(toggle != null and toggle.focus_mode != Control.FOCUS_NONE, "Settings offers a focusable Groove pressure toggle")
	if toggle != null:
		toggle.button_pressed = true
	_check(_main.player.groove == _main.groove, "turning it on hands Skip the room's beat")
	var config := ConfigFile.new()
	_check(config.load(_main.settings_path) == OK and config.get_value("gameplay", "groove_pressure", false) == true,
		"the setting is saved beside volume and controller layouts")
	_main.game_menu.close_menu()
	_main._new_game(false)
	_main.abilities.restore_snapshot(_main.AbilitiesScript.legacy_snapshot())
	await _frames(4)
	_check(_main.player.groove == _main.groove, "a new journey keeps the chosen setting")
	_check(is_equal_approx(_main.groove.period, GrooveScript.DEFAULT_PERIOD), "an ordinary room keeps Tick's count")
	_main._load_world_room(&"the_arm")
	await _frames(3)
	_check(is_equal_approx(_main.groove.period, TonearmScript.TICK_GAP), "the Arm keeps the keeper's own count")
	var arm := _main.room.get_node_or_null("Tonearm") as Node2D
	_check(arm != null, "the Arm's keeper is present")
	if arm == null:
		_main.queue_free()
		return
	arm.set_process(false)
	arm._player = _main.player
	_check(arm.call("_groove") == _main.groove, "the keeper hears the room's beat through Skip")
	_main._advance_groove(STEP)
	_check(not _main.groove.live, "an unstruck keeper leaves the room quiet")
	_clear_pool()
	_main.groove.time = _main.groove.period * 8.0 - 0.004
	_main._advance_groove(0.008)
	_check(not _pool_has("pulse"), "a quiet room sounds no beat")
	arm.on_player_strike(arm.global_position + Vector2(-60, 0), false)
	_main._advance_groove(STEP)
	_check(_main.groove.live, "a struck keeper rouses the room")
	_clear_pool()
	_main.groove.time = _main.groove.period * 12.0 - 0.004
	_main._advance_groove(0.008)
	_check(_pool_has("pulse"), "a roused room sounds each beat")
	_clear_pool()
	_main.groove.time = _main.groove.period * 12.5
	_main._advance_groove(0.008)
	_check(not _pool_has("pulse"), "the pulse sounds once per beat, never between")
	_clear_pool()
	_main.player.set_physics_process(false)
	_main.player.hooded = true
	_main.groove.time = _main.groove.period * 14.0 - 0.004
	_main._advance_groove(0.008)
	_check(not _pool_has("pulse"), "the Hood's silence covers the pulse")
	_main.player.hooded = false
	# Main's judgement: the pocket bites, an off-beat stroke is quieter.
	_clear_pool()
	_main.player.position = arm.global_position + Vector2(-300, 0)
	_main.groove.time = _main.groove.period * 16.0 + 0.01
	_main.player.set("_strike_cd", 0.0)
	_main.player.call("_strike")
	_check(_main.player.last_strike_groove == &"pocket" and _pool_has("pocket"), "a stroke in the pocket rings its bite")
	_clear_pool()
	_main.groove.time = _main.groove.period * 16.5
	_main.player.set("_strike_cd", 0.0)
	_main.player.call("_strike")
	_check(_main.player.last_strike_groove == &"flat" and not _pool_has("pocket"), "an off-beat stroke has no bite")
	var flat_air := false
	for player in _main.audio._pool:
		if player.stream != null and is_equal_approx(player.volume_db, _main.FLAT_AIR_DB):
			flat_air = player.pitch_scale < 1.0
	_check(flat_air, "an off-beat stroke's air is quieter and pitched down")
	_main.player.set_physics_process(true)
	# Quiet HUD marks.
	_main.groove.time = _main.groove.period * 20.0
	var beat: Dictionary = _main._beat_status()
	_check(beat.live and beat.lit, "the HUD mark lights in the pocket")
	_main.groove.time = _main.groove.period * 20.5
	_check(not bool(_main._beat_status().lit), "the HUD mark dims between beats")
	_main._update_cinematic_presentation()
	_check(bool(_main.cinematic_hud._state.get("beat", {}).get("live", false)), "the campaign HUD receives the beat")
	_check(not _main.beat_mark.visible, "the campaign keeps the classic beat mark hidden")
	_main._update_beat_mark(false)
	_check(_main.beat_mark.visible, "practice and development show the classic beat mark")
	# The checkpoint keeps its original three settings and stays valid.
	_check(bool(_main._persist_session()), "a grooved journey saves")
	var loaded: Dictionary = SaveScript.new(_main.save_path).load_game()
	_check(not loaded.is_empty(), "a grooved checkpoint loads as valid")
	_check(not loaded.is_empty() and not loaded.settings.has("groove_pressure"), "the checkpoint keeps only its original settings")
	# Turning it off restores the classic rules everywhere at once.
	_main._change_settings({"volume": 0.8, "reduced_motion": false, "fullscreen": false, "groove_pressure": false})
	_check(_main.player.groove == null and not _main.groove.live, "turning it off takes the beat back")
	_check(not bool(_main._beat_status().live), "the HUD forgets the beat when it is off")
	_check(arm.call("_groove") == null, "the keeper returns to its own count")
	_main._change_settings({"volume": 0.5, "reduced_motion": false, "fullscreen": false})
	_check(_main.player.groove == null, "an older settings dictionary keeps it off")
	# A fresh Main restores the saved choice.
	_main._change_settings({"volume": 0.8, "reduced_motion": false, "fullscreen": false, "groove_pressure": true})
	_main.queue_free()
	await _frames(3)
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_check(_main.player.groove == _main.groove and bool(_main.game_menu.settings.groove_pressure), "a fresh start restores Groove pressure")
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
	_check(SaveScript.new(_directory + "/checkpoint.json").delete_save(), "remove isolated groove checkpoint")
	for name in ["settings.cfg", "settings.cfg.tmp"]:
		if FileAccess.file_exists(_directory + "/" + name):
			DirAccess.remove_absolute(_directory + "/" + name)
	_check(DirAccess.remove_absolute(_directory) == OK, "remove isolated groove fixture")
