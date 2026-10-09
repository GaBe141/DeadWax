extends SceneTree
## XP and levels: the model's curve, budgets and choices; the checkpoint field;
## Ring and Bite on real foes; and Main's awards, practice isolation, Book
## choices with rollback, Continue, and HUD receipts in private files.

const XpScript := preload("res://scripts/xp_state.gd")
const SaveScript := preload("res://scripts/save_store.gd")
const SkipScript := preload("res://scripts/skip.gd")
const PressingScript := preload("res://scripts/test_pressing.gd")
const AuditionerScript := preload("res://scripts/auditioner.gd")
const TonearmScript := preload("res://scripts/tonearm.gd")
const LooperScript := preload("res://scripts/street_looper.gd")
const ProgressionScript := preload("res://scripts/progression_state.gd")
const AbilitiesScript := preload("res://scripts/abilities_state.gd")
const MainScene := preload("res://scenes/main.tscn")

var _checks := 0
var _failures: Array[String] = []
var _directory := ""
var _main: Node2D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-xp-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create private XP fixture")
	_check_curve()
	_check_awards()
	_check_choices()
	_check_snapshots()
	_check_schema()
	_check_foes()
	await _check_main()
	for name in ["checkpoint.json", "schema.json"]:
		_check(SaveScript.new(_directory + "/" + name).delete_save(), "remove private " + name)
	for name in ["settings.cfg", "settings.cfg.tmp"]:
		if FileAccess.file_exists(_directory + "/" + name):
			DirAccess.remove_absolute(_directory + "/" + name)
	_check(DirAccess.remove_absolute(_directory) == OK, "remove private XP fixture")
	if _failures.is_empty():
		print("DEAD WAX XP PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("XP FAIL: " + failure)
	quit(1)

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

# -- the model -----------------------------------------------------------------

func _check_curve() -> void:
	_check(XpScript.threshold(1) == 0 and XpScript.threshold(2) == 40 and XpScript.threshold(3) == 100, "the first levels need 40, then 60 more")
	_check(XpScript.threshold(12) == 1540 and XpScript.max_xp() == 1540, "level 12 is the cap at 1540 XP")
	_check(XpScript.threshold(99) == XpScript.max_xp() and XpScript.threshold(0) == 0, "thresholds clamp outside the level range")
	_check(XpScript.level_for(0) == 1 and XpScript.level_for(39) == 1 and XpScript.level_for(40) == 2, "a level begins exactly at its threshold")
	_check(XpScript.level_for(1539) == 11 and XpScript.level_for(1540) == 12 and XpScript.level_for(999999) == 12, "level 12 is the ceiling")
	var rising := true
	for level in range(2, XpScript.MAX_LEVEL + 1):
		rising = rising and XpScript.threshold(level) - XpScript.threshold(level - 1) == XpScript.STEP_BASE + XpScript.STEP_GROWTH * (level - 2)
	_check(rising, "each level asks 20 XP more than the last")
	var picks := 0
	for stat in XpScript.STATS:
		picks += int(XpScript.RANK_CAPS[stat])
	_check(picks > XpScript.MAX_LEVEL - 1, "the caps outnumber the eleven choices, so a build must choose")
	_check(XpScript.kill_xp(&"voice") == 15 and XpScript.kill_xp(&"looper") == 20 and XpScript.kill_xp(&"hush") == 40
		and XpScript.kill_xp(&"tonearm") == 80 and XpScript.kill_xp(&"unknown") == 0, "kills pay by kind of foe")

func _check_awards() -> void:
	var model := XpScript.new()
	_check(model.level() == 1 and model.xp == 0 and model.picks_available() == 0, "a fresh needle is level 1 with nothing waiting")
	_check(model.award(0) == 0 and model.award(-5) == 0 and model.xp == 0, "zero and negative awards add nothing")
	_check(model.award(10) == 10 and model.xp == 10, "an unkeyed hit adds its XP")
	_check(model.award(30, "the_arm/tonearm") == 30 and model.paid_for("the_arm/tonearm") == 30, "a story foe's first XP draws on its budget")
	_check(model.award(30, "the_arm/tonearm") == 10 and model.paid_for("the_arm/tonearm") == XpScript.FOE_BUDGET, "a story foe stops paying at its lifetime budget")
	_check(model.award(5, "the_arm/tonearm") == 0 and model.xp == 50, "a spent foe pays nothing more")
	_check(model.award(5, "groove_yard/yard_last_voice") == 5, "another foe keeps its own budget")
	_check(model.award_kill(80, "the_arm/tonearm") == 80 and model.has_slain("the_arm/tonearm"), "a story kill pays once")
	_check(model.award_kill(80, "the_arm/tonearm") == 0 and model.xp == 135, "the same story kill never pays twice")
	_check(model.award_kill(15) == 15 and model.award_kill(15) == 15, "unkeyed kills (trial copies) pay every time")
	_check(model.level() == 3 and model.picks_available() == 2, "165 XP is level 3 with two choices waiting")
	model.xp = XpScript.max_xp() - 3
	_check(model.award(10) == 3 and model.xp == XpScript.max_xp() and model.level() == XpScript.MAX_LEVEL, "XP stops at the level cap")
	_check(model.award(10) == 0, "a capped needle earns nothing more")
	var capped := XpScript.new()
	capped.xp = XpScript.max_xp() - 1
	_check(capped.award(10, "verse_hall/hall_voice") == 1 and capped.paid_for("verse_hall/hall_voice") == 1, "a budget records only XP actually added")
	model.reset()
	_check(model.xp == 0 and model.paid_for("the_arm/tonearm") == 0 and not model.has_slain("the_arm/tonearm") and model.rank("ring") == 0, "reset clears XP, ranks and ledgers")

func _check_choices() -> void:
	var model := XpScript.new()
	_check(not model.can_choose("ring") and not model.choose("ring"), "level 1 has no choice to spend")
	model.award(XpScript.threshold(3))
	_check(model.picks_available() == 2 and not model.can_choose("speed"), "only Ring, Body and Bite exist")
	_check(model.choose("ring") and model.choose("body") and model.picks_available() == 0, "each level spends one choice")
	_check(not model.choose("bite"), "a spent level cannot be chosen again")
	_check(is_equal_approx(model.resonance_multiplier(), 1.15) and model.health_bonus() == 1 and is_equal_approx(model.damage_multiplier(), 1.0),
		"one Ring rings 15% harder and one Body adds a notch")
	var profile: Dictionary = model.profile()
	_check(is_equal_approx(float(profile.resonance), 1.15) and is_equal_approx(float(profile.damage), 1.0) and int(profile.health) == 1, "the profile carries every gain")
	model.award(XpScript.max_xp())
	for rank in 5:
		model.choose("bite")
	_check(model.rank("bite") == XpScript.RANK_CAPS.bite and not model.can_choose("bite"), "Bite stops at its cap")
	_check(is_equal_approx(model.damage_multiplier(), 2.0), "four Bites double a hit's damage")
	for rank in 6:
		model.choose("ring")
	_check(model.rank("ring") == 5 and is_equal_approx(model.resonance_multiplier(), 1.75), "Ring stops at five ranks")
	var progress: Dictionary = model.progress()
	_check(int(progress.level) == 12 and bool(progress.max) and int(progress.picks) == 1 and int(progress.span) == 0, "the cap's progress reports truthfully")

func _check_snapshots() -> void:
	var model := XpScript.new()
	model.award(XpScript.threshold(4) - 20)
	model.award(20, "the_arm/tonearm")
	model.award_kill(15, "verse_hall/hall_voice")
	model.choose("bite")
	var snapshot := model.snapshot()
	_check(snapshot.keys() == ["version", "xp", "ranks", "paid", "slain"], "the snapshot keeps a fixed shape")
	var restored := XpScript.new()
	_check(restored.restore_snapshot(JSON.parse_string(JSON.stringify(snapshot))), "a JSON round trip restores")
	_check(restored.snapshot() == snapshot and restored.level() == model.level() and restored.rank("bite") == 1, "restoring keeps XP, ranks and ledgers")
	_check(XpScript.valid_snapshot(XpScript.default_snapshot()) and XpScript.valid_snapshot({"version": 1, "xp": 0}), "defaults and minimal snapshots are valid")
	var invalid: Array = [null, [], true, {}, {"version": 1}, {"xp": 0},
		{"version": 2, "xp": 0}, {"version": 1, "xp": -1}, {"version": 1, "xp": 1.5}, {"version": 1, "xp": XpScript.max_xp() + 1},
		{"version": 1, "xp": 0, "extra": true}, {"version": 1, "xp": 0, "ranks": []},
		{"version": 1, "xp": 0, "ranks": {"speed": 1}}, {"version": 1, "xp": 0, "ranks": {"ring": 1}},
		{"version": 1, "xp": XpScript.max_xp(), "ranks": {"ring": 6}}, {"version": 1, "xp": XpScript.max_xp(), "ranks": {"body": -1}},
		{"version": 1, "xp": 100, "ranks": {"ring": 1, "body": 1, "bite": 1}},
		{"version": 1, "xp": 0, "paid": {"no-slash": 4}}, {"version": 1, "xp": 0, "paid": {"Upper/key": 4}},
		{"version": 1, "xp": 0, "paid": {"a/b": 0}}, {"version": 1, "xp": 0, "paid": {"a/b": XpScript.FOE_BUDGET + 1}},
		{"version": 1, "xp": 0, "paid": []}, {"version": 1, "xp": 0, "slain": ["a/b", "a/b"]},
		{"version": 1, "xp": 0, "slain": [3]}, {"version": 1, "xp": 0, "slain": {}}]
	var all_rejected := true
	for value in invalid:
		all_rejected = all_rejected and not XpScript.valid_snapshot(value)
	_check(all_rejected, "malformed experience is rejected")
	var kept := restored.snapshot()
	_check(not restored.restore_snapshot({"version": 1, "xp": -4}) and restored.snapshot() == kept, "a rejected restore changes nothing")

func _sample() -> Dictionary:
	return {
		"version": 1, "room_id": "headshell", "entry_id": "default",
		"progression": ProgressionScript.new().snapshot(), "abilities": AbilitiesScript.legacy_snapshot(),
		"shine": 3, "completed": false, "encounters": {"the_arm/tonearm": "shattered"},
		"settings": {"volume": 0.5, "reduced_motion": false, "fullscreen": false},
	}

func _check_schema() -> void:
	var store := SaveScript.new(_directory + "/schema.json")
	var old := _sample()
	_check(store.save_game(old), "a checkpoint without XP stays valid")
	var old_loaded := store.load_game()
	_check(not old_loaded.has("xp"), "an older checkpoint stays without invented XP")
	var model := XpScript.new()
	model.award(150)
	model.award(12, "the_arm/tonearm")
	model.choose("body")
	var current := _sample()
	current["xp"] = model.snapshot()
	_check(store.save_game(current), "a checkpoint with XP saves")
	var loaded := store.load_game()
	_check(loaded.has("xp") and loaded.xp == model.snapshot(), "XP, ranks and ledgers round trip through the checkpoint")
	_check(loaded.shine == 3 and loaded.encounters == current.encounters, "adding XP changes no other field")
	for malformed in [null, {}, {"version": 1, "xp": -1}, {"version": 1, "xp": 40, "ranks": {"ring": 2}}]:
		var sample := _sample()
		sample["xp"] = malformed
		_check(not store.save_game(sample) and store.load_game() == loaded, "malformed XP cannot replace a checkpoint")
	var raw := _sample()
	raw["xp"] = {"version": 1, "xp": 10, "paid": {"Bad Key": 3}}
	var file := FileAccess.open(_directory + "/schema.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(raw))
	file.close()
	store = SaveScript.new(_directory + "/schema.json")
	_check(store.load_game() == old_loaded, "malformed raw XP falls back to the last valid backup")

# -- Ring and Bite on real foes ------------------------------------------------

func _new_skip() -> CharacterBody2D:
	var skip := SkipScript.new()
	root.add_child(skip)
	skip.set_process(false)
	skip.set_physics_process(false)
	return skip

func _stand(script: Script, skip: Node2D) -> Node2D:
	var foe: Node2D = script.new()
	root.add_child(foe)
	foe.set_process(false)
	foe.set("_player", skip)
	foe.position = skip.position + Vector2(60, 0)
	return foe

func _check_foes() -> void:
	var skip := _new_skip()
	_check(is_equal_approx(skip.resonance_mult, 1.0) and is_equal_approx(skip.damage_mult, 1.0), "Skip starts stock")
	var stand := _stand(PressingScript, skip)
	stand.on_player_strike(stand.global_position, false)
	_check(stand.hp == 4.0 and stand.resonance == PressingScript.RES_HIT, "a stock strike takes exactly one health and the classic resonance")
	stand.free()
	skip.apply_growth({"resonance": 1.5, "damage": 1.5})
	_check(is_equal_approx(skip.resonance_mult, 1.5) and is_equal_approx(skip.damage_mult, 1.5), "Main's profile installs on Skip")
	stand = _stand(PressingScript, skip)
	stand.on_player_strike(stand.global_position, false)
	_check(is_equal_approx(stand.hp, 3.5) and is_equal_approx(stand.resonance, PressingScript.RES_HIT * 1.5), "Bite and Ring scale a stand's light hit")
	stand.on_player_strike(stand.global_position, true)
	_check(is_equal_approx(stand.hp, 0.5) and is_equal_approx(stand.resonance, (PressingScript.RES_HIT + PressingScript.RES_HIT_BIG) * 1.5), "and its heavy hit")
	stand.free()
	stand = _stand(PressingScript, skip)
	stand._gain(PressingScript.RES_PARRY)
	_check(is_equal_approx(stand.resonance, PressingScript.RES_PARRY * 1.5), "Ring scales a rung-back parry's resonance")
	stand.free()
	var voice := _stand(AuditionerScript, skip)
	voice.on_player_strike(voice.global_position, false)
	_check(is_equal_approx(voice.hp, AuditionerScript.HP_MAX - 1.5) and is_equal_approx(voice.resonance, AuditionerScript.RES_HIT * 1.5), "Ring and Bite reach the Auditioner")
	voice._gain(AuditionerScript.RES_PARRY)
	_check(is_equal_approx(voice.resonance, (AuditionerScript.RES_HIT + AuditionerScript.RES_PARRY) * 1.5), "including its rung-back parries")
	voice.free()
	var looper := _stand(LooperScript, skip)
	looper.on_player_strike(looper.global_position, false)
	_check(is_equal_approx(looper.hp, LooperScript.HP_MAX - 1.5), "the looper inherits Bite through its opening hit")
	looper.free()
	var arm := _stand(TonearmScript, skip)
	arm.on_player_strike(arm.global_position, false)
	arm.state = TonearmScript.S.RECOVERY
	arm.on_player_strike(arm.global_position, false)
	_check(is_equal_approx(arm.hp, TonearmScript.HP_MAX - 1.5), "Bite reaches the Tonearm in its opening")
	arm.free()
	skip.apply_growth({})
	stand = _stand(PressingScript, skip)
	stand.on_player_strike(stand.global_position, true)
	_check(stand.hp == 3.0 and stand.resonance == PressingScript.RES_HIT_BIG, "an empty profile returns every foe to stock exactly")
	stand.free()
	_check(PressingScript.PARRY_WINDOW_MS == 100 and AuditionerScript.PARRY_WINDOW_MS == 100 and TonearmScript.PARRY_WINDOW_MS == 100
		and PressingScript.STRIKE_HIT_RANGE == 120.0, "levels never touch the parry window or reach")
	skip.free()

# -- Main ------------------------------------------------------------------------

func _persistent(id: StringName) -> Node:
	for child in _main.room.get_children():
		if child.get_meta("chapter_state_id", &"") == id:
			return child
	return null

func _strike_at(target: Node2D) -> void:
	_main.player.cancel_pending_strike()
	_main.player.global_position = target.global_position + Vector2(-80, 0)
	_main.player.set("_strike_cd", 0.0)
	_main.player.call("_strike")

func _open_arm(arm: Node2D) -> void:
	arm.state = TonearmScript.S.RECOVERY
	arm.set("_opening_hit", false)

func _check_main() -> void:
	_main = MainScene.instantiate()
	_main.save_path = _directory + "/checkpoint.json"
	_main.settings_path = _directory + "/settings.cfg"
	root.add_child(_main)
	await _frames(3)
	_main._new_game(false)
	_main.abilities.restore_snapshot(AbilitiesScript.legacy_snapshot())
	_main._apply_purchases()
	await _frames(4)
	var model: RefCounted = _main.experience
	_check(model.level() == 1 and model.xp == 0 and _main._max_health() == 3, "a new journey starts at level 1 with three notches")
	_check(is_equal_approx(_main.player.resonance_mult, 1.0) and is_equal_approx(_main.player.damage_mult, 1.0), "and a stock needle")
	# The Tonearm: guard, hits, a parry, the lifetime budget, recovery and the kill.
	_main._load_world_room(&"the_arm")
	await _frames(4)
	var arm := _main.room.get_node_or_null("Tonearm") as Node2D
	_check(arm != null, "the Arm's keeper is present")
	if arm == null:
		return
	arm.set_process(false)
	_main.player.set_physics_process(false)
	_strike_at(arm)
	_check(model.xp == 0, "the first strike only wakes the keeper: a guard earns nothing")
	_open_arm(arm)
	_strike_at(arm)
	_check(model.xp == XpScript.HIT_XP and model.paid_for("the_arm/tonearm") == XpScript.HIT_XP, "a confirmed hit earns XP against the keeper's budget")
	_check(_main.cinematic_hud.xp_text() == "+%d XP" % XpScript.HIT_XP, "the HUD shows the gain")
	arm.parried.emit()
	_check(model.xp == XpScript.HIT_XP + XpScript.PARRY_XP, "a rung-back parry earns XP")
	_check(_main.cinematic_hud.xp_text() == "+%d XP" % (XpScript.HIT_XP + XpScript.PARRY_XP), "quick gains read as one running total")
	_main.player.global_position = arm.global_position + Vector2(-600, 0)
	_main.player.set("_strike_cd", 0.0)
	_main.player.call("_strike")
	_check(model.xp == XpScript.HIT_XP + XpScript.PARRY_XP, "a whiff earns nothing")
	for attempt in 30:
		arm.hp = 50.0
		_open_arm(arm)
		_strike_at(arm)
	_check(model.paid_for("the_arm/tonearm") == XpScript.FOE_BUDGET and model.xp == XpScript.FOE_BUDGET, "hits stop paying at the keeper's lifetime budget")
	await _frames(2)
	_check(model.level() == 2 and _main.cinematic_hud.xp_text().begins_with("LEVEL 2"), "reaching 40 XP announces level 2")
	_main._respawn()
	await _frames(2)
	_check(arm.hp == TonearmScript.HP_MAX and model.paid_for("the_arm/tonearm") == XpScript.FOE_BUDGET, "recovery resets the attempt but never the budget")
	_strike_at(arm)
	_open_arm(arm)
	_strike_at(arm)
	_check(arm.hp == TonearmScript.HP_MAX - 1.0 and model.xp == XpScript.FOE_BUDGET, "a fresh attempt's real hit on a spent keeper earns nothing")
	arm.hp = 1.0
	_open_arm(arm)
	_strike_at(arm)
	_check(arm.outcome == "shattered" and model.has_slain("the_arm/tonearm"), "shattering the keeper records its kill")
	_check(model.xp == XpScript.FOE_BUDGET + XpScript.kill_xp(&"tonearm"), "the kill pays the keeper's 80 XP")
	_check(String(_main.encounters.get("the_arm/tonearm", "")) == "shattered", "the outcome is remembered as before")
	await _frames(2)
	_check(model.level() == 3 and model.picks_available() == 2 and _main.cinematic_hud.xp_text().begins_with("LEVEL 3"), "120 XP reaches level 3 with two choices")
	_main._update_cinematic_presentation()
	var status: Dictionary = _main.cinematic_hud._state.get("xp", {})
	_check(int(status.get("level", 0)) == 3 and int(status.get("picks", 0)) == 2 and float(status.get("ratio", -1.0)) >= 0.0, "the HUD status carries level and waiting choices")
	_main.player.set_physics_process(true)
	# Freeing earns nothing.
	var before: int = model.xp
	_main._load_world_room(&"groove_yard")
	await _frames(4)
	var voice := _persistent(&"yard_last_voice")
	_check(voice != null, "the Yard's ordinary voice is present")
	if voice != null:
		voice.set_process(false)
		voice.call("_free")
		_check(model.xp == before and String(_main.encounters.get("groove_yard/yard_last_voice", "")) == "freed", "freeing a voice earns no XP")
	# HUSH's bout.
	_main._load_world_room(&"smoothed_floor")
	await _frames(4)
	var hush := _persistent(&"hush")
	_check(hush != null, "HUSH is present")
	if hush != null:
		hush.set_process(false)
		hush.bout_won.emit()
		_check(model.xp == before + XpScript.kill_xp(&"hush") and model.has_slain("smoothed_floor/hush"), "winning HUSH's bout pays 40 XP")
		hush.bout_won.emit()
		_check(model.xp == before + XpScript.kill_xp(&"hush"), "the bout pays once")
	# Echo Trial copies are fresh foes every clear.
	before = model.xp
	_main._load_world_room(&"worn_gallery")
	await _frames(4)
	var trial: Node = _main.room.get_node_or_null("EchoTrial")
	_check(trial != null, "the Overture trial is installed")
	if trial != null:
		_main.player.global_position = trial.global_position + Vector2(0, -20)
		trial.set("_state", &"active")
		trial.set("_wave", 1)
		trial.call("_spawn_wave")
		var copies: Array = trial.get("_copies")
		_check(copies.size() == 1, "the first wave arrives")
		if copies.size() == 1:
			var copy: Node2D = copies[0]
			copy.set_process(false)
			_main._on_struck(copy.global_position, false, false)
			_check(model.xp == before + XpScript.HIT_XP, "a hit on a trial copy earns XP")
			copy.parried.emit()
			_check(model.xp == before + XpScript.HIT_XP + XpScript.PARRY_XP, "a parried copy earns XP")
			copy.call("_down", true)
			_check(model.xp == before + XpScript.HIT_XP + XpScript.PARRY_XP + XpScript.kill_xp(&"pressing"), "a shattered copy pays its kill")
			_check(model.snapshot().paid.size() == 1 and model.snapshot().slain.size() == 2, "copies leave no ledger entries")
		trial.call("cancel_trial", true)
	await _frames(2)
	# Practice earns nothing and stays stock; leaving restores the campaign.
	var campaign_xp: int = model.xp
	_check(_main._persist_session(), "save before the title")
	_main._return_to_title()
	await _frames(3)
	_main._start_practice()
	await _frames(4)
	_check(_main.practice_mode and _main.experience != model and _main.experience.xp == 0, "Move practice swaps in a stock, disposable level")
	_main._award_xp(50, null)
	_check(_main.experience.xp == 0 and is_equal_approx(_main.player.damage_mult, 1.0), "practice earns no XP")
	_main._continue_game()
	await _frames(4)
	model = _main.experience
	_check(not _main.practice_mode and model.xp == campaign_xp and model.has_slain("the_arm/tonearm"), "Continue restores XP and its ledgers")
	_check(model.paid_for("the_arm/tonearm") == XpScript.FOE_BUDGET, "the keeper's spent budget survives Continue")
	# The Book's LEVEL page.
	_main.inventory.open_inventory()
	await _frames(2)
	_main.inventory.select_page("level", true)
	await _frames(1)
	var page: Control = _main.inventory.level_page()
	_check(page.visible and _main.inventory.current_page() == "level", "the Book opens its LEVEL page")
	_check(page.waiting_text().contains("WAITING") and _main.inventory._page_buttons.level.text == "LEVEL •", "a waiting choice is marked on the page and its tab")
	# 120 from the keeper, 40 from HUSH, 22 from one trial copy: level 4.
	_check(model.xp == 182 and model.level() == 4 and model.picks_available() == 3, "three choices wait at level 4")
	var health_before: int = _main._health
	page.choice_button("body").pressed.emit()
	await _frames(1)
	_check(model.rank("body") == 1 and _main._max_health() == 4 and _main._health == health_before + 1, "Body adds a filled notch")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(_main.save_path))
	_check(saved is Dictionary and saved.xp.ranks.body == 1, "the choice is saved before it applies")
	_check(DirAccess.make_dir_absolute(_main.save_path + ".tmp") == OK, "block the private checkpoint")
	page.choice_button("ring").pressed.emit()
	await _frames(1)
	_check(model.rank("ring") == 0 and is_equal_approx(_main.player.resonance_mult, 1.0), "a failed save rolls the choice back")
	_check(page._notice.text.contains("Could not save"), "and says so on the page")
	_check(DirAccess.remove_absolute(_main.save_path + ".tmp") == OK, "unblock the private checkpoint")
	page.choice_button("ring").pressed.emit()
	await _frames(1)
	_check(model.rank("ring") == 1 and is_equal_approx(_main.player.resonance_mult, 1.0 + XpScript.RING_STEP), "Ring installs on Skip once saved")
	_check(model.picks_available() == 1 and not page.choice_button("bite").disabled, "one choice still waits")
	page.choice_button("bite").pressed.emit()
	await _frames(1)
	_check(model.rank("bite") == 1 and is_equal_approx(_main.player.damage_mult, 1.0 + XpScript.BITE_STEP), "Bite installs on Skip once saved")
	var all_disabled := true
	for stat in XpScript.STATS:
		all_disabled = all_disabled and page.choice_button(stat).disabled
	_check(model.picks_available() == 0 and all_disabled, "spent choices disable the page")
	_check(not _main._choose_growth("bite"), "Main refuses a choice that is not waiting")
	_check(_main.inventory._page_buttons.level.text == "LEVEL", "the tab clears once every choice is made")
	_main.inventory.close_inventory()
	await _frames(2)
	# Continue reapplies the saved profile.
	_check(_main._persist_session(), "save the chosen gains")
	_main._return_to_title()
	await _frames(2)
	_main._continue_game()
	await _frames(4)
	model = _main.experience
	_check(model.rank("body") == 1 and model.rank("ring") == 1 and model.rank("bite") == 1 and _main._max_health() == 4 and _main._health == 4, "Continue fills the derived health")
	_check(is_equal_approx(_main.player.resonance_mult, 1.0 + XpScript.RING_STEP) and is_equal_approx(_main.player.damage_mult, 1.0 + XpScript.BITE_STEP), "Continue reinstalls Ring and Bite")
	# Caps, and the needle ceiling.
	_check(model.restore_snapshot({"version": 1, "xp": XpScript.max_xp(), "ranks": {"ring": 5, "body": 4, "bite": 1}}), "a high-level fixture restores")
	_main._apply_purchases()
	_check(model.picks_available() == 1, "the fixture has one choice waiting")
	_check(_main._max_health() == 7 and _main.MAX_NEEDLE >= 3 + 1 + XpScript.RANK_CAPS.body + 1, "four Body levels reach seven notches, within the needle's ceiling")
	_check(is_equal_approx(_main.player.damage_mult, 1.25) and is_equal_approx(_main.player.resonance_mult, 1.75), "Bite and Ring follow their ranks")
	_main.inventory.open_inventory()
	await _frames(2)
	_main.inventory.select_page("level", true)
	await _frames(1)
	_check(page.choice_button("ring").text == "FULL" and page.choice_button("ring").disabled and page.choice_button("body").disabled, "full gains say so")
	_check(not page.choice_button("bite").disabled and _main._choose_growth("bite") and not _main._choose_growth("bite"), "the last waiting choice spends once")
	_main.inventory.close_inventory()
	await _frames(2)
	# An older checkpoint without XP continues at level 1.
	_main._return_to_title()
	await _frames(2)
	var legacy: Variant = JSON.parse_string(FileAccess.get_file_as_string(_main.save_path))
	legacy.erase("xp")
	var file := FileAccess.open(_main.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	_main._continue_game()
	await _frames(4)
	model = _main.experience
	_check(model.xp == 0 and model.level() == 1 and _main._max_health() == 3 and is_equal_approx(_main.player.damage_mult, 1.0), "an older checkpoint continues at level 1, stock")
	# New Game clears it.
	model.award(200)
	_main._new_game(false)
	await _frames(3)
	_check(_main.experience.xp == 0 and _main.experience.rank("ring") == 0, "New Game starts a fresh needle")
	_main.queue_free()
	await _frames(3)
	paused = false
	await create_timer(0.15).timeout
