extends RefCounted
## Skip's experience, owned and persisted by Main like the Shine wallet.
## Confirmed hits, rung-back parries and kills add XP; freeing a voice adds
## none. Each level waits as one choice of Ring, Body or Bite, which Main
## applies only after the choice is saved. The model reads no actors, plays
## nothing and writes no files.
##
## A story foe pays at most FOE_BUDGET XP from hits and parries over its whole
## life, and its kill pays once, so a fight cannot be farmed by striking and
## then recovering or leaving the room. Echo Trial copies are new foes every
## clear and carry no budget: the trials are the repeatable source.

const SAVE_VERSION := 1
const MAX_LEVEL := 12
const STEP_BASE := 40          # XP from level 1 to 2
const STEP_GROWTH := 20        # each later level asks this much more
const HIT_XP := 2              # a confirmed light hit
const BIG_HIT_XP := 4          # an Accent, a hot groove or a pocket hit
const PARRY_XP := 5            # a rung-back parry
const FOE_BUDGET := 40         # lifetime hit and parry XP from one story foe
const KILL_XP := {             # by kind of foe; freeing pays nothing
	&"voice": 15,              # Auditioners, the Yard voices, Addie
	&"pressing": 15,           # Test Pressings
	&"looper": 20,             # the High Street looper and its copies
	&"hush": 40,               # winning HUSH's bout
	&"tonearm": 80,            # shattering the Tonearm
}
const STATS: Array[String] = ["ring", "body", "bite"]
const RANK_CAPS := {"ring": 5, "body": 4, "bite": 4}
const RING_STEP := 0.15        # resonance from hits and parries, per rank
const BODY_STEP := 1           # needle health, per rank
const BITE_STEP := 0.25        # health damage from hits, per rank
const MAX_LEDGER := 256        # the checkpoint's encounter limit

var xp := 0
var _ranks := {"ring": 0, "body": 0, "bite": 0}
var _paid: Dictionary = {}          # story foe key -> hit/parry XP already paid
var _slain: Array[String] = []      # story foe keys whose kill has paid

## Total XP that reaches `level`; level 1 begins at zero.
static func threshold(level: int) -> int:
	var total := 0
	for step in range(1, clampi(level, 1, MAX_LEVEL)):
		total += STEP_BASE + STEP_GROWTH * (step - 1)
	return total

static func max_xp() -> int:
	return threshold(MAX_LEVEL)

static func level_for(amount: int) -> int:
	var level := 1
	while level < MAX_LEVEL and amount >= threshold(level + 1):
		level += 1
	return level

static func kill_xp(kind: StringName) -> int:
	return int(KILL_XP.get(kind, 0))

static func default_snapshot() -> Dictionary:
	return {"version": SAVE_VERSION, "xp": 0, "ranks": {"ring": 0, "body": 0, "bite": 0}, "paid": {}, "slain": []}

func reset() -> void:
	xp = 0
	_ranks = {"ring": 0, "body": 0, "bite": 0}
	_paid.clear()
	_slain.clear()

func level() -> int:
	return level_for(xp)

func rank(stat: String) -> int:
	return int(_ranks.get(stat, 0))

func picks_available() -> int:
	return maxi(level() - 1 - rank("ring") - rank("body") - rank("bite"), 0)

## Adds hit or parry XP. A story foe's key draws on its lifetime budget.
## Returns the XP actually added.
func award(amount: int, foe_key := "") -> int:
	if amount <= 0:
		return 0
	var granted := amount
	if not foe_key.is_empty():
		var paid := int(_paid.get(foe_key, 0))
		granted = mini(amount, FOE_BUDGET - paid)
		if granted <= 0 or (not _paid.has(foe_key) and _paid.size() >= MAX_LEDGER):
			return 0
		var added := _add(granted)
		if added > 0:
			_paid[foe_key] = paid + added
		return added
	return _add(granted)

## Adds a kill's XP. A story foe's kill pays once, however it returns.
func award_kill(amount: int, foe_key := "") -> int:
	if amount <= 0:
		return 0
	if not foe_key.is_empty():
		if foe_key in _slain or _slain.size() >= MAX_LEDGER:
			return 0
		_slain.append(foe_key)
	return _add(amount)

func paid_for(foe_key: String) -> int:
	return int(_paid.get(foe_key, 0))

func has_slain(foe_key: String) -> bool:
	return foe_key in _slain

func _add(amount: int) -> int:
	var before := xp
	xp = mini(xp + amount, max_xp())
	return xp - before

func can_choose(stat: String) -> bool:
	return stat in STATS and picks_available() > 0 and rank(stat) < int(RANK_CAPS[stat])

func choose(stat: String) -> bool:
	if not can_choose(stat):
		return false
	_ranks[stat] = rank(stat) + 1
	return true

func resonance_multiplier() -> float:
	return 1.0 + RING_STEP * rank("ring")

func damage_multiplier() -> float:
	return 1.0 + BITE_STEP * rank("bite")

func health_bonus() -> int:
	return BODY_STEP * rank("body")

## The derived profile Main installs on Skip (Ring, Bite) and its health cap (Body).
func profile() -> Dictionary:
	return {"resonance": resonance_multiplier(), "damage": damage_multiplier(), "health": health_bonus()}

## Presentation values for the HUD and the Book.
func progress() -> Dictionary:
	var current := level()
	var floor_xp := threshold(current)
	var next_xp := threshold(current + 1) if current < MAX_LEVEL else floor_xp
	return {
		"level": current, "xp": xp, "into": xp - floor_xp, "span": next_xp - floor_xp,
		"next": next_xp, "max": current >= MAX_LEVEL, "picks": picks_available(),
		"ranks": _ranks.duplicate(),
	}

func snapshot() -> Dictionary:
	var paid := {}
	var keys: Array = _paid.keys()
	keys.sort()
	for key in keys:
		paid[key] = int(_paid[key])
	var slain := _slain.duplicate()
	slain.sort()
	return {"version": SAVE_VERSION, "xp": xp, "ranks": _ranks.duplicate(), "paid": paid, "slain": slain}

static func valid_snapshot(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if not key is String or key not in ["version", "xp", "ranks", "paid", "slain"]:
			return false
	if not value.has("version") or not value.has("xp"):
		return false
	if not _whole(value.version, SAVE_VERSION, SAVE_VERSION) or not _whole(value.xp, 0, max_xp()):
		return false
	var ranks: Variant = value.get("ranks", {})
	if not ranks is Dictionary:
		return false
	var spent := 0
	for stat in ranks:
		if not stat is String or stat not in STATS or not _whole(ranks[stat], 0, int(RANK_CAPS[stat])):
			return false
		spent += int(ranks[stat])
	if spent > level_for(int(value.xp)) - 1:
		return false
	var paid: Variant = value.get("paid", {})
	if not paid is Dictionary or paid.size() > MAX_LEDGER:
		return false
	for key in paid:
		if not _foe_key(key) or not _whole(paid[key], 1, FOE_BUDGET):
			return false
	var slain: Variant = value.get("slain", [])
	if not slain is Array or slain.size() > MAX_LEDGER:
		return false
	var seen: Array[String] = []
	for key in slain:
		if not _foe_key(key) or key in seen:
			return false
		seen.append(key)
	return true

func restore_snapshot(value: Variant) -> bool:
	if not valid_snapshot(value):
		return false
	xp = int(value.xp)
	var ranks: Dictionary = value.get("ranks", {})
	_ranks = {"ring": 0, "body": 0, "bite": 0}
	for stat in ranks:
		_ranks[stat] = int(ranks[stat])
	_paid.clear()
	var paid: Dictionary = value.get("paid", {})
	for key in paid:
		_paid[key] = int(paid[key])
	_slain.clear()
	for key in value.get("slain", []):
		_slain.append(String(key))
	return true

static func _whole(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	return is_finite(number) and number >= minimum and number <= maximum and number == floor(number)

## The same room/encounter key shape the checkpoint uses for outcomes.
static func _foe_key(value: Variant) -> bool:
	if not value is String or value.length() > 128:
		return false
	var parts: PackedStringArray = value.split("/")
	if parts.size() != 2:
		return false
	for part in parts:
		if part.is_empty() or part.length() > 128:
			return false
		for character in part:
			if not "abcdefghijklmnopqrstuvwxyz0123456789_-".contains(character):
				return false
	return true
