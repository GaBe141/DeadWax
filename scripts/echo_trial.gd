extends Node2D
## Optional repeatable recordings. Copies own no campaign identity, inventory,
## currency, or save data. Main approves a start and persists each earned claim.

signal start_requested(source: Node)
signal completed(source: Node)

const Press := preload("res://scripts/press.gd")
const INTERACT_RADIUS := 76.0
const WAVE_WARNING := 1.0
const SPAWN_CLEARANCE := 220.0
const COPY_SPACING := 130.0
const WAVE_COUNTS: Array[int] = [1, 1, 2]
const PROFILES := {
	&"label": {"name": "THE FIRST IMPRESSION", "position": Vector2(850, 574), "bounds": Rect2(530, 260, 620, 340), "kind": &"voice"},
	&"overture": {"name": "THE WORN IMPRESSION", "position": Vector2(2180, 574), "bounds": Rect2(1840, 260, 660, 340), "kind": &"pressing"},
	&"unplayed": {"name": "THE DEEP IMPRESSION", "position": Vector2(1300, 834), "bounds": Rect2(990, 520, 650, 340), "kind": &"looper"},
}

class EchoVoice extends "res://scripts/auditioner.gd":
	var trial_ink := Color("ddc3a5")
	var trial_stock := Color("2b2638")
	var reduced_motion := false
	var left_edge := 0.0
	var right_edge := 0.0
	func _creep(speed: float, delta: float) -> void:
		super._creep(speed, delta)
		global_position.x = clampf(global_position.x, left_edge, right_edge)
	func _advance_print(delta: float) -> void:
		if not reduced_motion: super._advance_print(delta)
	func _draw() -> void:
		var pose := {"phase": S.keys()[state].to_lower(), "clock": _print_time,
			"stride": 0.0 if reduced_motion else _print_stride, "recoil": _print_recoil, "face": _face,
			"jitter": Vector2.ZERO if reduced_motion else _jit * 0.25, "state_time": _t,
			"reach": clampf(_reach_t / REACH_WIND, 0.0, 1.0), "recover": clampf(_t / RECOVER_TIME, 0.0, 1.0),
			"leave": 0.0, "burst": 0.0, "held": false, "resonance": resonance,
			"listening": clampf(_set / SET_FREE_TIME, 0.0, 1.0), "hp": hp, "hp_total": int(HP_MAX)}
		PrintPress.draw_auditioner(self, pose, trial_ink, trial_stock.lerp(trial_ink, 0.17), trial_ink,
			PrintPress.BRASS, trial_ink.lerp(trial_stock, 0.40), PrintPress.BRASS)
	func reink(next_ink: Color, next_stock: Color) -> void:
		trial_ink = next_ink
		trial_stock = next_stock
		queue_redraw()
	func set_reduced_motion(enabled: bool) -> void:
		reduced_motion = enabled
		if enabled: _print_recoil = 0.0
		queue_redraw()

class EchoPressing extends "res://scripts/test_pressing.gd":
	var trial_ink := Color("ddc3a5")
	var trial_stock := Color("2b2638")
	var reduced_motion := false
	func _advance_print(delta: float) -> void:
		if not reduced_motion: super._advance_print(delta)
	func _draw() -> void:
		var pose := {"phase": S.keys()[state].to_lower(), "clock": _print_time, "seed": _sid,
			"face": _face, "muted": muted, "recoil": _print_recoil, "follow_through": _print_swing_tail,
			"count": _count, "beat": clampf(_t / TICK_GAP, 0.0, 1.0),
			"swing": clampf(_t / 0.12, 0.0, 1.0), "state_time": _t, "reform": 0.0,
			"resonance": resonance, "hp": hp, "hp_total": int(HP_MAX)}
		PrintPress.draw_pressing(self, pose, trial_ink, trial_stock.lerp(trial_ink, 0.17), trial_ink,
			PrintPress.BRASS, trial_ink.lerp(trial_stock, 0.40))
	func reink(next_ink: Color, next_stock: Color) -> void:
		trial_ink = next_ink
		trial_stock = next_stock
		queue_redraw()
	func set_reduced_motion(enabled: bool) -> void:
		reduced_motion = enabled
		if enabled:
			_print_recoil = 0.0
			_print_swing_tail = 0.0
		queue_redraw()

class EchoLooper extends "res://scripts/street_looper.gd":
	func _advance_print(delta: float) -> void:
		if not reduced_motion: super._advance_print(delta)
	func _draw() -> void:
		var pose := {"phase": S.keys()[state].to_lower(), "clock": _print_time, "seed": _sid,
			"face": _face, "muted": muted, "recoil": _print_recoil, "follow_through": _print_swing_tail,
			"count": _count, "beat": clampf(_t / TICK_GAP, 0.0, 1.0),
			"swing": clampf(_t / 0.12, 0.0, 1.0), "state_time": _t, "reform": 0.0,
			"resonance": resonance, "hp": hp, "hp_total": int(HP_MAX)}
		PrintPress.draw_pressing(self, pose, ink, stock.lerp(ink, 0.17), ink, PrintPress.BRASS, ink.lerp(stock, 0.40))
		PrintPress.draw_looper_cue(self, encounter_snapshot(), ink, stock)

var hunt_id: StringName = &"label"
var ink := Color("ddc3a5")
var stock := Color("2b2638")
var _state: StringName = &"idle"
var _wave := 0
var _warning := 0.0
var _clock := 0.0
var _near := false
var _reduced_motion := false
var _copies: Array[Node2D] = []
var _resolved: Dictionary = {}
var _receipt: Dictionary = {}
var _save_failed := false
var _card: Control
var _card_text := ""

func _ready() -> void:
	add_to_group("echo_trial")
	z_index = 4
	_refresh_card()

func _physics_process(delta: float) -> void:
	if get_tree().paused or delta <= 0.0: return
	_near = _player_is_near()
	if _state == &"active":
		var player := _player()
		if player == null or not trial_bounds().has_point(player.global_position):
			cancel_trial()
		elif _warning > 0.0:
			_warning = maxf(_warning - delta, 0.0)
			if _warning <= 0.0: _spawn_wave()
	if _near and Input.is_action_just_pressed("enter_passage"): try_interact()
	if not _reduced_motion: _clock += delta
	_refresh_card()
	queue_redraw()

func _player() -> CharacterBody2D:
	if not is_inside_tree(): return null
	return get_tree().get_first_node_in_group("player") as CharacterBody2D

func _player_is_near() -> bool:
	var player := _player()
	return player != null and player.is_on_floor() and player.global_position.distance_to(global_position) <= INTERACT_RADIUS

func trial_bounds() -> Rect2:
	return PROFILES.get(hunt_id, {}).get("bounds", Rect2())

func can_start() -> bool:
	return is_inside_tree() and not get_tree().paused and PROFILES.has(hunt_id) and _state == &"idle" and _player_is_near()

func can_claim() -> bool:
	return is_inside_tree() and not get_tree().paused and _state == &"claim" and _player_is_near()

func try_interact() -> bool:
	if can_start():
		start_requested.emit(self)
		return true
	if can_claim():
		completed.emit(self)
		return true
	return false

func begin_trial() -> bool:
	if not can_start(): return false
	_state = &"active"
	_wave = 1
	_warning = WAVE_WARNING
	_save_failed = false
	_receipt.clear()
	_resolved.clear()
	_refresh_card()
	queue_redraw()
	return true

func _spawn_wave() -> void:
	if _state != &"active" or not _copies.is_empty(): return
	var player := _player()
	if player == null:
		cancel_trial()
		return
	var bounds := trial_bounds()
	var count := WAVE_COUNTS[_wave - 1]
	var locations: Array[float] = []
	var candidates: Array[float] = []
	candidates.append(bounds.position.x + 24.0 + COPY_SPACING)
	candidates.append(bounds.end.x - 24.0 - COPY_SPACING)
	for index in range(13):
		candidates.append(lerpf(bounds.position.x + 24.0, bounds.end.x - 24.0, index / 12.0))
	candidates.sort_custom(func(a: float, b: float) -> bool: return absf(a - player.global_position.x) > absf(b - player.global_position.x))
	for candidate in candidates:
		if absf(candidate - player.global_position.x) < SPAWN_CLEARANCE: continue
		var clear := true
		for existing in locations:
			if absf(existing - candidate) < COPY_SPACING: clear = false
		if clear: locations.append(candidate)
		if locations.size() == count: break
	# Authored bounds always have room; if a future profile does not, decline
	# that start instead of materialising an unfair copy on top of the player.
	if locations.size() != count:
		cancel_trial()
		return
	for index in count:
		var kind: StringName = PROFILES[hunt_id].kind
		if hunt_id == &"unplayed" and _wave == 2: kind = &"voice"
		if hunt_id == &"unplayed" and _wave == 3 and index == 1: kind = &"voice"
		var copy: Node2D
		match kind:
			&"voice":
				copy = EchoVoice.new()
				copy.left_edge = bounds.position.x + 18.0
				copy.right_edge = bounds.end.x - 18.0
			&"looper": copy = EchoLooper.new()
			_: copy = EchoPressing.new()
		copy.name = "EchoCopy%d_%d" % [_wave, index]
		copy.add_to_group("echo_trial_actor")
		copy.set_meta("echo_species", kind)
		copy.position = Vector2(locations[index], global_position.y + (13.0 if kind == &"voice" else -17.0)) - global_position
		copy.reink(ink, stock)
		copy.set_reduced_motion(_reduced_motion)
		copy.shattered.connect(func(_pos: Vector2) -> void: _resolve_copy(copy))
		copy.bout_won.connect(func() -> void: _resolve_copy(copy))
		if copy.has_signal("freed"):
			copy.freed.connect(func(_pos: Vector2) -> void: _resolve_copy(copy))
		add_child(copy)
		copy.z_index = 5
		_copies.append(copy)
	_refresh_card()

func _resolve_copy(copy: Node2D) -> void:
	if _state != &"active" or not is_instance_valid(copy) or not _copies.has(copy): return
	var id := copy.get_instance_id()
	if _resolved.has(id): return
	_resolved[id] = true
	_copies.erase(copy)
	_retire_copy(copy)
	if _copies.is_empty():
		if _wave >= WAVE_COUNTS.size():
			_state = &"claim"
			_warning = 0.0
		else:
			_wave += 1
			_warning = WAVE_WARNING
	_refresh_card()
	queue_redraw()

func _retire_copy(copy: Node2D) -> void:
	if not is_instance_valid(copy): return
	copy.remove_from_group("hears_strikes")
	copy.remove_from_group("strikable")
	copy.remove_from_group("reset_on_recovery")
	copy.set_process(false)
	copy.set_physics_process(false)
	copy.queue_free()

func cancel_trial(discard_claim: bool = false) -> void:
	if _state == &"claim" and not discard_claim: return
	for copy in _copies: _retire_copy(copy)
	_copies.clear()
	_resolved.clear()
	_state = &"idle"
	_wave = 0
	_warning = 0.0
	_save_failed = false
	_refresh_card()
	queue_redraw()

func accept_reward(receipt: Dictionary) -> void:
	if _state != &"claim": return
	_receipt = receipt.duplicate(true)
	_state = &"idle"
	_wave = 0
	_save_failed = false
	_refresh_card()
	queue_redraw()

func reward_failed() -> void:
	if _state != &"claim": return
	_save_failed = true
	_refresh_card()
	queue_redraw()

func reink(next_ink: Color, next_stock: Color) -> void:
	ink = next_ink
	stock = next_stock
	_card_text = ""
	for copy in _copies:
		if is_instance_valid(copy): copy.reink(ink, stock)
	_refresh_card()
	queue_redraw()

func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	for copy in _copies:
		if is_instance_valid(copy): copy.set_reduced_motion(enabled)
	queue_redraw()

func _prompt() -> String:
	if _state == &"claim":
		return "Your pressing is waiting.\n[E / Y]  Retry saving the claim" if _save_failed else "All three waves are complete.\n[E / Y]  Collect your pressing"
	if _state == &"active":
		if _warning > 0.0: return "WAVE %d / 3  —  GET READY\nThe next impression is forming." % _wave
		return "WAVE %d / 3  —  %d REMAIN\nClear every copy. Leaving ends the trial." % [_wave, _copies.size()]
	var receipt := ""
	if not _receipt.is_empty():
		receipt = String(_receipt.get("message", "Pressing collected. Check your Book.")) + "\n"
	return receipt + "[E / Y]  Play three waves for rare gear\nRecordings, never returned neighbours.\nLeaving or opening a menu ends an unfinished trial."

func _refresh_card() -> void:
	if not is_inside_tree(): return
	var text := _prompt()
	if _card == null or _card_text != text:
		_card_text = text
		if _card != null:
			remove_child(_card)
			_card.queue_free()
		_card = Press.card(text, ink, stock, Press.BRASS, Press.SIZE_SMALL, String(PROFILES.get(hunt_id, {}).get("name", "ECHO TRIAL")))
		_card.position = Vector2(-_card.size.x / 2.0, -_card.size.y - 105.0)
		_card.material = Press.unshaded_material()
		_card.z_index = 22
		add_child(_card)
	_card.visible = _near or _state == &"active"

func snapshot() -> Dictionary:
	return {"hunt": hunt_id, "state": _state, "wave": _wave, "remaining": _copies.size(), "warning": _warning,
		"near": _near, "clock": 0.0 if _reduced_motion else _clock, "reduced_motion": _reduced_motion,
		"save_failed": _save_failed, "receipt": _receipt.duplicate(true), "prompt": _prompt()}

func _draw() -> void:
	Press.draw_echo_trial(self, snapshot(), ink, stock)
