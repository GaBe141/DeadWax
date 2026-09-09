extends SceneTree
## Pure purse rules and the v1 purchases field. Disk fixtures use an isolated
## directory and never touch the player's checkpoint or settings.

const EconomyScript := preload("res://scripts/economy_state.gd")
const SaveScript := preload("res://scripts/save_store.gd")

var _checks := 0
var _failures: Array[String] = []
var _directory: String
var _path: String

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_directory = "user://deadwax-economy-state-test-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_path = _directory + "/checkpoint.json"
	_check(DirAccess.make_dir_absolute(_directory) == OK, "create isolated economy directory")
	_check_catalog()
	_check_credits()
	_check_purchases()
	_check_restore()
	_check_save_schema()
	_check_save_recovery()
	_check(SaveScript.new(_path).delete_save(), "delete isolated economy checkpoint and backups")
	_check(DirAccess.remove_absolute(_directory) == OK, "delete isolated economy directory")
	if _failures.is_empty():
		print("DEAD WAX ECONOMY STATE PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("ECONOMY STATE FAIL: " + failure)
	quit(1)

func _check_catalog() -> void:
	var catalog := EconomyScript.catalog()
	_check(catalog.size() == 3, "the opening shop offers exactly three items")
	_check(EconomyScript.item(&"spare_groove").price == 4 and EconomyScript.item(&"spare_groove").name == "Spare Groove", "Spare Groove costs four Shine")
	_check(EconomyScript.item(&"soft_lining").price == 3 and EconomyScript.item(&"soft_lining").name == "Soft Lining", "Soft Lining costs three Shine")
	_check(EconomyScript.item(&"warm_thread").price == 2 and EconomyScript.item(&"warm_thread").name == "Warm Thread", "Warm Thread costs two Shine")
	_check(EconomyScript.item(&"unknown").is_empty(), "unknown catalog lookup is empty")
	catalog[0].price = 0
	catalog.clear()
	var entry := EconomyScript.item(&"spare_groove")
	entry.price = 1
	_check(EconomyScript.catalog().size() == 3 and EconomyScript.item(&"spare_groove").price == 4, "catalog and item views cannot change actual prices")

func _check_credits() -> void:
	var purse := EconomyScript.new()
	_check(purse.balance == 0 and purse.snapshot().purchases.is_empty(), "a fresh purse has no balance or purchases")
	_check(purse.max_health() == 3 and is_equal_approx(purse.hood_speed_multiplier(), 0.62), "a fresh purse preserves the existing health and Hood speed")
	for amount in [0, -1, -2147483648, EconomyScript.MAX_BALANCE + 1]:
		_check(not purse.credit(amount) and purse.balance == 0, "invalid credit %s leaves the purse unchanged" % amount)
	_check(purse.credit(EconomyScript.MAX_BALANCE) and purse.balance == EconomyScript.MAX_BALANCE, "the full supported Shine balance is representable")
	_check(not purse.credit(1) and purse.balance == EconomyScript.MAX_BALANCE, "a positive credit cannot overflow the balance")
	purse.reset()
	_check(purse.balance == 0 and purse.credit(1) and purse.balance == 1, "reset permits ordinary polish credit again")

func _check_purchases() -> void:
	for entry in EconomyScript.catalog():
		var purse := EconomyScript.new()
		purse.credit(int(entry.price) - 1)
		var before := purse.snapshot()
		_check(not purse.can_purchase(entry.id) and not purse.purchase(entry.id), "%s requires its full price" % entry.id)
		_check(purse.snapshot() == before, "unaffordable %s purchase changes neither balance nor ownership" % entry.id)
		purse.credit(1)
		_check(purse.can_purchase(entry.id) and purse.purchase(entry.id), "exact change buys %s" % entry.id)
		_check(purse.balance == 0 and purse.has_item(entry.id), "%s purchase commits debit and ownership together" % entry.id)
		purse.credit(10)
		before = purse.snapshot()
		_check(not purse.can_purchase(entry.id) and not purse.purchase(entry.id) and purse.snapshot() == before, "%s can never be bought twice" % entry.id)
	var orders := [
		["spare_groove", "soft_lining", "warm_thread"], ["spare_groove", "warm_thread", "soft_lining"],
		["soft_lining", "spare_groove", "warm_thread"], ["soft_lining", "warm_thread", "spare_groove"],
		["warm_thread", "spare_groove", "soft_lining"], ["warm_thread", "soft_lining", "spare_groove"],
	]
	for order in orders:
		var purse := EconomyScript.new()
		purse.credit(9)
		for id in order:
			_check(purse.purchase(StringName(id)), "nine campaign polish credits can buy %s in order %s" % [id, order])
		_check(purse.balance == 0 and purse.max_health() == 4 and is_equal_approx(purse.hood_speed_multiplier(), 0.75) and purse.has_item(&"warm_thread"), "every purchase order yields the same bounded effects")
		var before := purse.snapshot()
		_check(not purse.has_item(&"invented") and not purse.can_purchase(&"invented") and not purse.purchase(&"invented") and purse.snapshot() == before, "unknown items never debit the purse")
		purse.reset()
		_check(purse.snapshot() == {"shine": 0, "purchases": []} and purse.max_health() == 3 and is_equal_approx(purse.hood_speed_multiplier(), 0.62), "New Game clears every purchased effect")
	var cosmetic := EconomyScript.new()
	cosmetic.credit(2)
	cosmetic.purchase(&"warm_thread")
	_check(cosmetic.max_health() == 3 and is_equal_approx(cosmetic.hood_speed_multiplier(), 0.62), "Warm Thread remains a cosmetic purchase")

func _check_restore() -> void:
	var purse := EconomyScript.new()
	_check(purse.restore(9), "an old Shine-only snapshot restores without purchases")
	_check(purse.snapshot() == {"shine": 9, "purchases": []}, "old restoration does not infer any ownership")
	_check(purse.restore(7.0, ["warm_thread"]), "JSON whole-number Shine and known purchases restore")
	var before := purse.snapshot()
	for amount in [-1, 0.25, true, false, "3", null, INF, NAN, EconomyScript.MAX_BALANCE + 1]:
		_check(not purse.restore(amount, ["spare_groove"]) and purse.snapshot() == before, "invalid restored Shine is rejected before changing purchases: %s" % amount)
	for purchases in _bad_purchases():
		_check(not purse.restore(100, purchases) and purse.snapshot() == before, "malformed restored purchases are atomic: %s" % str(purchases))
	var source := ["spare_groove", "soft_lining"]
	_check(purse.restore(2, source), "a valid complete purchase list restores")
	source.append("warm_thread")
	_check(not purse.has_item(&"warm_thread"), "restore does not retain a mutable caller-owned purchase array")
	var snapshot := purse.snapshot()
	snapshot.purchases.clear()
	snapshot.shine = 999
	_check(purse.balance == 2 and purse.has_item(&"spare_groove") and purse.has_item(&"soft_lining"), "editing a snapshot never changes the live purse")
	_check(purse.restore(EconomyScript.MAX_BALANCE, []) and purse.balance == EconomyScript.MAX_BALANCE, "restoration accepts the upper balance boundary")

func _bad_purchases() -> Array:
	return [
		null, {}, "warm_thread", PackedStringArray(["warm_thread"]),
		[true], [1], [null], [&"warm_thread"], [""], ["invented"],
		["warm_thread", "warm_thread"],
		["spare_groove", "soft_lining", "warm_thread", "spare_groove"],
	]

func _check_save_schema() -> void:
	var store := SaveScript.new(_path)
	var legacy := _fixture(9)
	_check(store.save_game(legacy), "v1 checkpoints lacking purchases still save")
	var saved := store.load_game()
	_check(saved.version == 1 and saved.shine == 9 and saved.purchases == [], "v1 normalization supplies an empty purchase list")
	var bought := _fixture(2)
	bought["purchases"] = ["spare_groove", "soft_lining"]
	var purchase_saved := store.save_game(bought)
	_check(purchase_saved, "save remaining Shine and two purchases: " + store.last_error)
	saved = SaveScript.new(_path).load_game()
	_check(saved.version == 1 and saved.shine == 2 and saved.purchases == bought.purchases, "purchase roundtrip preserves v1 and the actual remaining balance")
	var purse := EconomyScript.new()
	_check(purse.restore(saved.shine, saved.purchases) and purse.max_health() == 4 and is_equal_approx(purse.hood_speed_multiplier(), 0.75), "saved purchases restore both gameplay effects")
	for purchases in _bad_purchases():
		var malformed := bought.duplicate(true)
		malformed["purchases"] = purchases
		_check(not store.save_game(malformed) and not store.last_error.is_empty(), "save rejects malformed purchase input: %s" % str(purchases))
		_check(store.load_game() == saved, "rejected purchase data leaves the installed checkpoint intact")

func _check_save_recovery() -> void:
	var store := SaveScript.new(_path)
	store.delete_save()
	var before := _fixture(9)
	var after := _fixture(5)
	after["purchases"] = ["spare_groove"]
	_check(store.save_game(before) and store.save_game(after), "a purchase save keeps the prior validated checkpoint as backup")
	_write_raw(_path, JSON.stringify({"version": 1, "room_id": "bootlegger", "entry_id": "from_overture_stair", "progression": before.progression, "shine": 5, "purchases": ["spare_groove", "spare_groove"]}))
	var recovered := store.load_game()
	_check(recovered.get("shine") == 9 and recovered.get("purchases") == [], "duplicate purchases on disk recover the last valid v1 checkpoint")
	_check(store.save_game(after), "valid purchase checkpoint replaces an invalid primary")
	_check(DirAccess.make_dir_absolute(_path + ".tmp") == OK, "block a purchase's staged write")
	var next := _fixture(2)
	next["purchases"] = ["spare_groove", "soft_lining"]
	_check(not store.save_game(next), "a failed staged purchase write reports failure")
	recovered = store.load_game()
	_check(recovered.get("shine") == 5 and recovered.get("purchases") == ["spare_groove"], "failed purchase save never installs a partial debit or ownership list")
	DirAccess.remove_absolute(_path + ".tmp")
	store.delete_save()
	for purchases in [["unknown"], ["warm_thread", "warm_thread"], [true], "warm_thread", null]:
		var invalid := _fixture(2)
		invalid["purchases"] = purchases
		_write_raw(_path, JSON.stringify(invalid))
		_check(store.load_game().is_empty() and not store.last_error.is_empty(), "malformed disk purchase data fails closed without backup")

func _fixture(shine: int) -> Dictionary:
	return {
		"version": 1, "room_id": "bootlegger", "entry_id": "from_overture_stair", "shine": shine,
		"progression": {"version": 1, "refrains": [], "techniques": []},
	}

func _write_raw(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "write isolated malformed economy fixture")
		return
	file.store_string(contents)
	file.close()

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
