extends SceneTree
## Collections are a campaign-owned transaction: a reward cannot outlive its
## saved roll, and equipment never changes the core attack or traversal verbs.
const Collection := preload("res://scripts/collection_state.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")

var _checks := 0
var _failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_catalog()
	_check_schema()
	_check_rolls()
	_check_equipment()
	_check_crafting()
	_check_bestiary()
	_check_mastery()
	if _failures.is_empty():
		print("DEAD WAX COLLECTION STATE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("COLLECTION STATE FAIL: " + failure)
	quit(1)

func _check_catalog() -> void:
	_check(Catalog.ITEMS.size() == 12 and Catalog.SPECIES.size() == 10, "twelve equipment choices and ten grounded bestiary entries")
	var ids: Array[String] = []
	var slots := {"needle": 0, "lining": 0, "charm": 0}
	for item in Catalog.items():
		_check(item.id not in ids and item.slot in Catalog.SLOTS and not Catalog.hunt(item.source).is_empty(), "each equipment item has a unique ID, slot and real source: " + item.id)
		ids.append(item.id)
		slots[item.slot] += 1
		var upside := false
		var downside := false
		for key in item.modifiers:
			_check(key in Collection.MULTIPLIERS or key == "health", "equipment cannot change reach, timings, jump or permissions: " + item.id)
			var neutral := 0.0 if key == "health" else 1.0
			upside = upside or item.modifiers[key] > neutral
			downside = downside or item.modifiers[key] < neutral
		_check(upside and downside and not item.tradeoff.is_empty(), "every item has an explicit benefit and cost: " + item.id)
	for slot in slots:
		_check(slots[slot] == 4, "four alternatives in the " + slot + " slot")
	for hunt in Catalog.hunts():
		var chance := 0
		var count := 0
		for item in Catalog.items():
			if item.source == hunt.id:
				chance += int(item.drop_chance)
				count += 1
		_check(count == 4 and chance == 10 and hunt.mastery_wins == 100, "source has four drops totaling ten percent and its own mastery: " + hunt.id)
	var copy := Catalog.item("glass_needle")
	copy.modifiers.health = 99
	_check(Catalog.item("glass_needle").modifiers.health == -1, "catalog callers cannot rewrite nested tuning")
	_check(Catalog.item("invented").is_empty() and Catalog.hunt("invented").is_empty() and Catalog.species_entry("invented").is_empty(), "unknown catalog IDs have no fabricated content")

func _check_schema() -> void:
	var state := Collection.new()
	var empty := Collection.default_snapshot()
	_check(state.snapshot() == empty and Collection.valid_snapshot(empty), "fresh model and legacy default carry nothing")
	var json: Variant = JSON.parse_string(JSON.stringify(empty))
	_check(state.restore_snapshot(json) and state.snapshot() == empty, "JSON numeric values normalize into the same state")
	var invalid: Array = [null, false, 0, [], {}, "collection"]
	for key in Collection.ROOT_KEYS:
		var absent := empty.duplicate(true)
		absent.erase(key)
		invalid.append(absent)
	var extra := empty.duplicate(true)
	extra.reward = true
	invalid.append(extra)
	for field in ["version", "offcuts", "rng_state"]:
		for bad in [true, "1", null, -1, 0.5, INF, NAN, 1e30]:
			var sample := empty.duplicate(true)
			sample[field] = bad
			invalid.append(sample)
	for bad in [[], null, false, {"needle": ""}, {"needle": "", "lining": "", "charm": "", "fourth": ""}]:
		var sample := empty.duplicate(true)
		sample.equipped = bad
		invalid.append(sample)
	for bad in [["invented"], [true], ["glass_needle", "glass_needle"], "glass_needle", null]:
		var sample := empty.duplicate(true)
		sample.owned = bad
		invalid.append(sample)
	var not_owned := empty.duplicate(true)
	not_owned.equipped.needle = "glass_needle"
	invalid.append(not_owned)
	var wrong_slot := empty.duplicate(true)
	wrong_slot.owned = ["glass_needle"]
	wrong_slot.equipped.charm = "glass_needle"
	invalid.append(wrong_slot)
	for field in ["wins", "dry", "discovered"]:
		for bad in [null, "1", -1, 0.25, INF, NAN, 1e30]:
			var sample := empty.duplicate(true)
			sample.hunts.label[field] = bad
			invalid.append(sample)
	for field in ["freed", "shattered", "seen"]:
		for bad in [null, "1", -1, 0.25, INF, NAN, 1e30]:
			var sample := empty.duplicate(true)
			sample.bestiary.auditioner[field] = bad
			invalid.append(sample)
	var unseen := empty.duplicate(true)
	unseen.bestiary.auditioner.freed = 1
	invalid.append(unseen)
	var undiscovered := empty.duplicate(true)
	undiscovered.hunts.label.wins = 1
	invalid.append(undiscovered)
	var dry_without_wins := empty.duplicate(true)
	dry_without_wins.hunts.label.discovered = true
	dry_without_wins.hunts.label.dry = 1
	invalid.append(dry_without_wins)
	for field in ["hunts", "bestiary"]:
		var missing := empty.duplicate(true)
		missing[field].erase(missing[field].keys()[0])
		_check(Collection.valid_snapshot(missing) and state.restore_snapshot(missing) and state.snapshot() == empty, "future catalog additions backfill unseen defaults: " + field)
		var unknown := empty.duplicate(true)
		unknown[field].invented = {}
		invalid.append(unknown)
	for index in invalid.size():
		_check(not Collection.valid_snapshot(invalid[index]), "malformed collection rejected %d" % index)
		_check(not state.restore_snapshot(invalid[index]) and state.snapshot() == empty, "invalid restore never partly mutates collection %d" % index)
	var boundary := empty.duplicate(true)
	boundary.offcuts = Collection.MAX_OFFCUTS
	boundary.rng_state = Collection.RNG_MODULUS - 1
	boundary.hunts.label = {"discovered": true, "wins": Collection.MAX_COUNT, "dry": 19}
	boundary.bestiary.auditioner = {"seen": true, "freed": Collection.MAX_COUNT, "shattered": Collection.MAX_COUNT}
	_check(state.restore_snapshot(boundary), "bounded integer limits roundtrip")
	var before := state.snapshot()
	_check(state.finish_hunt("label").is_empty() and state.snapshot() == before, "exhausted counter cannot overflow or spend a roll")
	state.reset()
	_check(Collection.valid_snapshot(state.snapshot()) and state.snapshot().owned.is_empty() and state.snapshot().offcuts == 0, "New Game resets ownership, wallet and ledger with a valid campaign seed")
	var exposed := state.snapshot()
	exposed.hunts.label.discovered = true
	_check(not state.snapshot().hunts.label.discovered, "nested snapshot cannot mutate campaign ledger")

func _check_rolls() -> void:
	var state := Collection.new()
	var before := state.snapshot()
	_check(state.finish_hunt("label").is_empty() and state.finish_hunt("invented").is_empty() and state.snapshot() == before, "unknown or undiscovered sources cannot roll")
	_check(state.discover_hunt("label") and not state.discover_hunt("label") and not state.discover_hunt("invented"), "source discovery is ordered and idempotent")
	var twin := Collection.new()
	_check(twin.restore_snapshot(state.snapshot()), "copy full chance state before trial")
	for index in 150:
		var receipt := state.finish_hunt("label")
		_check(receipt == twin.finish_hunt("label") and state.snapshot() == twin.snapshot(), "saved chance stream reproduces complete reward %d" % index)
		_check(receipt.offcuts in [1, 6] and receipt.dry < 20 and receipt.wins == index + 1, "each win advances once, supplies material and bounds dry streak %d" % index)
		_check(Collection.valid_snapshot(state.snapshot()), "rolled state remains serializable %d" % index)
		if not receipt.item_id.is_empty():
			_check(Catalog.item(receipt.item_id).source == "label", "random reward belongs to the completed region")
	var rolled_back := state.snapshot()
	var future := state.finish_hunt("label")
	_check(state.restore_snapshot(rolled_back) and state.finish_hunt("label") == future, "failed-save rollback restores the reward and RNG together")
	var pity := Collection.default_snapshot()
	pity.rng_state = _seed_for_roll(99)
	pity.hunts.label = {"discovered": true, "wins": 19, "dry": 19}
	pity.owned = ["quicksilver_tip", "blunt_stylus", "felt_cuff"]
	_check(state.restore_snapshot(pity), "seed nineteenth dry win and one missing regional item")
	var guaranteed := state.finish_hunt("label")
	_check(guaranteed.pity and guaranteed.item_id == "counterweight" and not guaranteed.duplicate and guaranteed.dry == 0, "twentieth dry win guarantees the only missing regional item despite a miss roll")
	for roll in [0, 3, 4, 6, 7, 8, 9, 10, 99]:
		var sample := Collection.default_snapshot()
		sample.rng_state = _seed_for_roll(roll)
		sample.hunts.label.discovered = true
		_check(state.restore_snapshot(sample), "seed exact percentage boundary %d" % roll)
		var receipt := state.finish_hunt("label")
		var expected := "quicksilver_tip" if roll < 4 else ("blunt_stylus" if roll < 7 else ("felt_cuff" if roll < 9 else ("counterweight" if roll < 10 else "")))
		_check(receipt.item_id == expected and receipt.offcuts == 1, "four/three/two/one-percent bands and ninety-percent miss are explicit %d" % roll)
	var duplicate := Collection.default_snapshot()
	duplicate.hunts.label.discovered = true
	duplicate.rng_state = _seed_for_roll(0)
	duplicate.owned = ["quicksilver_tip"]
	_check(state.restore_snapshot(duplicate), "seed an already-owned roll")
	var salvage := state.finish_hunt("label")
	_check(salvage.duplicate and salvage.offcuts == 6 and state.snapshot().owned == ["quicksilver_tip"], "duplicate becomes five bonus offcuts without a second inventory copy")
	duplicate.offcuts = Collection.MAX_OFFCUTS - 3
	_check(state.restore_snapshot(duplicate), "seed wallet near upper bound")
	salvage = state.finish_hunt("label")
	_check(salvage.offcuts == 3 and salvage.total_offcuts == Collection.MAX_OFFCUTS, "receipt reports only material actually carried when wallet saturates")

func _check_equipment() -> void:
	var state := Collection.new()
	var neutral := {"speed": 1.0, "accel": 1.0, "friction": 1.0, "air_control": 1.0, "hood_speed": 1.0, "noise_decay": 1.0, "health": 0}
	_check(state.modifiers() == neutral and not state.equip("glass_needle") and not state.unequip("needle"), "stock equipment is neutral and missing gear cannot equip")
	var everything := Collection.default_snapshot()
	for item in Catalog.items():
		everything.owned.append(item.id)
	_check(state.restore_snapshot(everything), "seed the complete collection")
	for item in Catalog.items():
		_check(state.equip(item.id) and not state.equip(item.id), "equip succeeds exactly once until changed: " + item.id)
		_check(state.snapshot().equipped[item.slot] == item.id, "item uses its authored slot: " + item.id)
		_check(state.unequip(item.slot) and state.modifiers() == neutral, "removing item restores every stock value: " + item.id)
	_check(state.equip("glass_needle") and state.equip("padded_sleeve") and state.equip("ballast_seal"), "three equipment slots coexist")
	_check(state.modifiers().health == 1 and is_equal_approx(state.modifiers().air_control, 1.0), "trade-offs combine before aggregate limits")
	_check(state.equip("quicksilver_tip") and state.modifiers().health == 1, "two health benefits do not stack beyond one additional hit")
	_check(state.equip("glass_needle") and state.equip("feather_seal") and is_equal_approx(state.modifiers().air_control, 1.4), "stacked air steering is capped at forty percent")
	_check(not state.unequip("invented") and Collection.valid_snapshot(state.snapshot()), "invalid slots cannot modify a valid loadout")

func _check_crafting() -> void:
	var state := Collection.new()
	var material := Collection.default_snapshot()
	material.offcuts = 100
	material.hunts.label.discovered = true
	_check(state.restore_snapshot(material) and not state.can_craft("counterweight") and not state.craft("counterweight"), "discovering a source alone cannot craft its equipment")
	material.hunts.label.wins = 1
	_check(state.restore_snapshot(material), "one trial win unlocks that source's crafting")
	_check(not state.can_craft("ballast_seal") and not state.craft("invented"), "material cannot bypass an uncleared source")
	_check(state.can_craft("counterweight") and state.craft("counterweight"), "a specific missing item may be crafted after its source is cleared")
	_check(state.has_item("counterweight") and state.snapshot().offcuts == 60 and state.snapshot().equipped.charm == "", "crafting spends exactly forty without silently equipping")
	var before := state.snapshot()
	_check(not state.can_craft("counterweight") and not state.craft("counterweight") and state.snapshot() == before, "crafting an owned item neither duplicates nor charges")
	_check(state.craft("felt_cuff") and not state.craft("quicksilver_tip") and state.snapshot().offcuts == 20, "insufficient material cannot overdraw wallet")
	_check(state.snapshot().hunts.label.wins == 1 and state.snapshot().rng_state == material.rng_state, "crafting changes neither trial wins nor future chance")

func _check_bestiary() -> void:
	var state := Collection.new()
	_check(state.record_species("hound") and not state.record_species("hound"), "seeing a resident is idempotent")
	_check(not state.record_species("invented") and not state.record_species("hound", "won"), "unknown species and non-resolution outcome cannot increment counts")
	var historic := {"groove_yard/yard_first_voice": "freed", "groove_yard/yard_last_voice": "shattered",
		"worn_gallery/gallery_near_voice": "freed", "worn_gallery/gallery_far_voice": "freed", "smoothed_floor/hush": "won",
		"the_arm/tonearm": "shattered", "the_stalls/loft_voice": "freed", "headshell/invented_voice": "freed", "high_street/street_wax": "polished"}
	_check(state.backfill(historic), "old campaign outcomes fill known species without replaying encounters")
	var book: Dictionary = state.snapshot().bestiary
	_check(book.auditioner.seen and book.auditioner.freed == 2 and book.auditioner.shattered == 1, "historical shared species aggregates distinct real actors")
	_check(book.hush.seen and book.hush.freed == 0 and book.hush.shattered == 0, "a won HUSH bout is not mislabeled freed or shattered")
	_check(book.yard_voice.freed == 1 and book.tonearm.shattered == 1 and book.loft_voice.freed == 1, "special voices retain their own truthful entries")
	var before := state.snapshot()
	_check(not state.backfill(historic) and state.snapshot() == before, "repeated Continue does not count saved resolutions again")
	historic["verse_warren_n/north_voice"] = "freed"
	_check(state.backfill(historic) and state.snapshot().bestiary.auditioner.freed == 3, "one newly saved actor increases the historical minimum once")
	_check(not state.backfill(historic), "the same live outcome is idempotent on subsequent checkpoint reads")
	_check(state.record_species("test_pressing", "shattered") and state.snapshot().bestiary.test_pressing.seen, "an explicit future resolution both discovers and records its species")
	var earned := state.snapshot()
	_check(state.restore_snapshot(JSON.parse_string(JSON.stringify(earned))) and state.snapshot() == earned, "bestiary counters restore silently through JSON")
	_check(state.snapshot().owned.is_empty() and state.snapshot().offcuts == 0, "bestiary knowledge does not grant equipment or currency")

func _check_mastery() -> void:
	var state := Collection.new()
	var empty := state.completion_snapshot()
	_check(empty.gear_found == 0 and empty.gear_total == 12 and empty.species_seen == 0 and empty.species_total == 10, "completion starts honestly empty")
	_check(empty.mastery_wins == 0 and empty.mastery_total == 300 and empty.hunts_mastered == 0, "three one-hundred-win ledgers are separate from drop ownership")
	var sample := Collection.default_snapshot()
	sample.hunts.label = {"discovered": true, "wins": 150, "dry": 0}
	sample.hunts.overture = {"discovered": true, "wins": 99, "dry": 0}
	sample.hunts.unplayed = {"discovered": true, "wins": 2, "dry": 0}
	_check(state.restore_snapshot(sample), "seed varied regional mastery")
	var completion := state.completion_snapshot()
	_check(completion.mastery_wins == 201 and completion.hunts_mastered == 1 and completion.gear_found == 0, "extra farming cannot replace another region's mastery or invent collected gear")

func _seed_for_roll(roll: int) -> int:
	for seed in range(1, 10001):
		if (seed * 48271) % Collection.RNG_MODULUS % 100 == roll:
			return seed
	return Collection.DEFAULT_SEED

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
