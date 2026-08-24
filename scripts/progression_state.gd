extends RefCounted
## Session-owned character progression.
##
## Core verbs (Strike, Hood, Set) are always available and intentionally do
## not live here. Techniques are player knowledge: discovery affects feedback
## and saves, never whether the input works. Refrains are earned permissions
## that can change traversal or world interactions.

signal refrain_unlocked(refrain: int)
signal technique_discovered(technique: int)

enum Refrain { GATHER, REST, JUMP_CUT }
enum Technique { COUNT_IN, STEP_TURN }

const SAVE_VERSION := 1
const REFRAIN_ORDER := [Refrain.GATHER, Refrain.REST, Refrain.JUMP_CUT]
const TECHNIQUE_ORDER := [Technique.COUNT_IN, Technique.STEP_TURN]
const REFRAIN_KEYS := {
	Refrain.GATHER: "gather",
	Refrain.REST: "rest",
	Refrain.JUMP_CUT: "jump-cut",
}
const TECHNIQUE_KEYS := {
	Technique.COUNT_IN: "count-in",
	Technique.STEP_TURN: "step-turn",
}

var _refrains: Dictionary = {}
var _techniques: Dictionary = {}

func _init() -> void:
	reset()

func reset() -> void:
	_refrains.clear()
	_techniques.clear()
	for refrain in REFRAIN_ORDER:
		_refrains[refrain] = false
	for technique in TECHNIQUE_ORDER:
		_techniques[technique] = false

func has_refrain(refrain: int) -> bool:
	return bool(_refrains.get(refrain, false))

func unlock_refrain(refrain: int) -> bool:
	if not REFRAIN_KEYS.has(refrain) or has_refrain(refrain):
		return false
	_refrains[refrain] = true
	refrain_unlocked.emit(refrain)
	return true

func knows_technique(technique: int) -> bool:
	return bool(_techniques.get(technique, false))

func discover_technique(technique: int) -> bool:
	if not TECHNIQUE_KEYS.has(technique) or knows_technique(technique):
		return false
	_techniques[technique] = true
	technique_discovered.emit(technique)
	return true

func unlocked_refrains() -> Array[int]:
	var result: Array[int] = []
	for refrain in REFRAIN_ORDER:
		if has_refrain(refrain):
			result.append(refrain)
	return result

func discovered_techniques() -> Array[int]:
	var result: Array[int] = []
	for technique in TECHNIQUE_ORDER:
		if knows_technique(technique):
			result.append(technique)
	return result

func snapshot() -> Dictionary:
	var refrain_keys: Array[String] = []
	for refrain in unlocked_refrains():
		refrain_keys.append(String(REFRAIN_KEYS[refrain]))
	var technique_keys: Array[String] = []
	for technique in discovered_techniques():
		technique_keys.append(String(TECHNIQUE_KEYS[technique]))
	return {
		"version": SAVE_VERSION,
		"refrains": refrain_keys,
		"techniques": technique_keys,
	}

func restore_snapshot(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != SAVE_VERSION:
		return false
	var refrain_value: Variant = data.get("refrains", [])
	var technique_value: Variant = data.get("techniques", [])
	if not (refrain_value is Array) or not (technique_value is Array):
		return false
	reset()
	for key_value in refrain_value:
		var refrain := _id_for_key(REFRAIN_KEYS, String(key_value))
		if refrain >= 0:
			_refrains[refrain] = true
	for key_value in technique_value:
		var technique := _id_for_key(TECHNIQUE_KEYS, String(key_value))
		if technique >= 0:
			_techniques[technique] = true
	return true

func refrain_label(refrain: int) -> String:
	match refrain:
		Refrain.GATHER:
			return "GATHER"
		Refrain.REST:
			return "REST"
		Refrain.JUMP_CUT:
			return "JUMP-CUT"
	return "UNKNOWN REFRAIN"

func technique_label(technique: int) -> String:
	match technique:
		Technique.COUNT_IN:
			return "COUNT-IN"
		Technique.STEP_TURN:
			return "STEP-TURN"
	return "UNKNOWN TECHNIQUE"

func hud_text() -> String:
	var known: Array[String] = []
	for technique in discovered_techniques():
		known.append(technique_label(technique))
	var refrains: Array[String] = []
	for refrain in unlocked_refrains():
		refrains.append(refrain_label(refrain))
	return "known %s   refrains %s" % [
		", ".join(known) if not known.is_empty() else "—",
		", ".join(refrains) if not refrains.is_empty() else "—",
	]

func _id_for_key(keys: Dictionary, wanted: String) -> int:
	for id in keys:
		if String(keys[id]) == wanted:
			return int(id)
	return -1
