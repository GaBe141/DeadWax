extends SceneTree
## Quiet world fixtures still expose truthful actions, retain their fixed
## collection rules, and never mutate carried models when presenting cues.

const Ability := preload("res://scripts/ability_pickup.gd")
const Lost := preload("res://scripts/lost_pressing.gd")
const Exploration := preload("res://scripts/exploration_fixture.gd")
const Echo := preload("res://scripts/echo_station.gd")
const Trial := preload("res://scripts/echo_trial.gd")
const Map := preload("res://scripts/map_pickup.gd")
const Refrain := preload("res://scripts/refrain_pickup.gd")
const Marker := preload("res://scripts/chapter_marker.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Collection := preload("res://scripts/collection_state.gd")
const Progression := preload("res://scripts/progression_state.gd")
const Discoveries := preload("res://scripts/discoveries_state.gd")
const ExplorationState := preload("res://scripts/exploration_state.gd")
const Pressing := preload("res://scripts/pressing_state.gd")
var checks := 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var abilities := Abilities.new()
	var progression := Progression.new()
	var discoveries := Discoveries.new()
	var collection := Collection.new()
	var before := {"abilities": abilities.snapshot(), "progression": progression.snapshot(),
		"discoveries": discoveries.snapshot(), "collection": collection.snapshot()}
	var nodes: Array[Node2D] = []
	var ability := Ability.new()
	ability.abilities = abilities
	ability.ability = &"walk"
	ability.definition = {"name": "Walk"}
	nodes.append(ability)
	var lost := Lost.new()
	lost.collection = collection
	lost.abilities = abilities
	lost.definition = {"id": "copper_stylus", "requirement": "groove"}
	nodes.append(lost)
	var exploration := Exploration.new()
	exploration.progression = progression
	exploration.discoveries = discoveries
	exploration.exploration = ExplorationState.new()
	exploration.pressing = Pressing.new()
	exploration.definition = {"id": "warren_return", "far_end": true}
	nodes.append(exploration)
	var echo := Echo.new()
	echo.discoveries = discoveries
	nodes.append(echo)
	var trial := Trial.new()
	trial.abilities = abilities
	nodes.append(trial)
	var marker := Marker.new()
	nodes.append(marker)
	var refrain := Refrain.new()
	refrain.progression = progression
	nodes.append(refrain)
	var map := Map.new()
	nodes.append(map)
	for node in nodes:
		root.add_child(node)
		node.set_process(false)
		node.set_physics_process(false)
		_check(not node.cinematic_mode, "%s default guidance remains enabled" % node.get_script().resource_path)
		var state: Dictionary = node.cinematic_snapshot()
		_check(not state.is_empty() and not String(state.text).contains("\n"), "compact single-line prompt")
		_check(float(state.radius) > 0.0, "real interaction reach")
		node.set_cinematic_mode(true)
		if node.get("_card") != null:
			_check(not node._card.visible, "enabling mode hides existing card immediately")
		if node.get("_label") != null:
			_check(not node._label.visible, "enabling mode hides existing heading immediately")
		var prompt_before: Dictionary = node.cinematic_snapshot()
		if node.has_method("set_reduced_motion"):
			node.set_reduced_motion(true)
		_check(node.cinematic_snapshot() == prompt_before, "reduced motion keeps actionable cues available")
		for method in [&"refresh", &"refresh_discoveries", &"refresh_abilities", &"_refresh_card"]:
			if node.has_method(method): node.call(method)
		if node.get("_card") != null:
			_check(not node._card.visible, "card rebuild stays hidden")
			node._near = true
			node.set_cinematic_mode(false)
			_check(node._card.visible, "default mode restores local guidance")
			node.set_cinematic_mode(true)
			_check(not node._card.visible, "switching back hides local guidance")
	_check(before == {"abilities": abilities.snapshot(), "progression": progression.snapshot(),
		"discoveries": discoveries.snapshot(), "collection": collection.snapshot()}, "all presentation reads leave carried models unchanged")
	_check(not map.cinematic_snapshot().grounded and not refrain.cinematic_snapshot().grounded,
		"automatic contact pickups retain airborne collection rules")
	_check(ability.cinematic_snapshot().text == "E / Y · Recover Walk", "missing move has concise acquisition action")
	_check(lost.cinematic_snapshot().text == "Sealed sleeve", "equipment gate remains truthful")
	abilities.unlock_ability(&"groove")
	_check(lost.cinematic_snapshot().text == "E / Y · Take Copper Tip", "earned equipment action names item")
	collection.claim_exploration_item("copper_stylus")
	_check(lost.cinematic_snapshot().is_empty(), "collected equipment yields no prompt")
	discoveries.apply(&"collect_spool")
	echo.refresh_discoveries()
	_check(echo.cinematic_snapshot().is_empty(), "collected spool yields no prompt")
	echo.action = &"record_phrase"
	_check(echo.cinematic_snapshot().text == "E / Y · Record", "empty spool permits recording action")
	echo._stage = &"recording"
	_check(echo.cinematic_snapshot().text == "Recording…", "live recording cue remains present")
	trial._state = &"active"
	trial._wave = 2
	trial._warning = 1.0
	_check(trial.cinematic_snapshot().text == "Wave 2 / 3 · Forming", "trial warning remains legible")
	_check(trial.cinematic_snapshot().presentation_bounds == trial.trial_bounds()
		and not trial.cinematic_snapshot().grounded, "active wave cue spans the arena while airborne")
	trial._state = &"claim"
	_check(trial.cinematic_snapshot().text == "E / Y · Collect pressing", "trial claim remains available")
	marker.used = true
	_check(marker.cinematic_snapshot().is_empty(), "used endpoint yields no prompt")
	for node in nodes: node.queue_free()
	await process_frame
	if failures.is_empty():
		print("DEAD WAX CINEMATIC FIXTURES PASS (%d checks)" % checks)
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures.append(message)
