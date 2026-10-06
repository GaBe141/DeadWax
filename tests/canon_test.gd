extends SceneTree
## The design canon (docs/README.md) as checks a script can make. Each check
## names the canon rule it protects. If one fails, the change broke canon:
## fix the change, or raise it with the user. Don't loosen the check.

const MainScene := preload("res://scenes/main.tscn")
const Press := preload("res://scripts/press.gd")
const Catalog := preload("res://scripts/collection_catalog.gd")
const Economy := preload("res://scripts/economy_state.gd")
const Abilities := preload("res://scripts/abilities_state.gd")
const Opening := preload("res://scripts/opening_cutscene.gd")
const LostPressings := preload("res://scripts/lost_pressings_catalog.gd")
const Save := preload("res://scripts/save_store.gd")

## docs/art/direction.html: CRACKLE and ETCH GOLD.
const CANON_PINK := Color("e5407f")
const CANON_GOLD := Color("d9a441")
const GOLD_BUDGET := 6
## docs/COMBAT_FEEL.md: the parry.
const CANON_PARRY_RESONANCE := 0.40
const CANON_PARRY_WINDOW_MS := 100
## The only things equipment may change (docs/PROGRESSION.md: traversal is
## never random, so no drop or find may carry a move, Refrain or technique).
const EQUIPMENT_EFFECTS := ["speed", "accel", "friction", "air_control", "hood_speed", "noise_decay", "health"]
const EQUIPMENT_FIELDS := ["id", "name", "slot", "source", "rarity", "drop_chance", "description", "tradeoff", "modifiers"]

var _checks := 0
var _failures: Array[String] = []
var _banned := RegEx.create_from_string("(?i)\\b(needles?|stylus(es)?|styli)\\b")
var _identifier := RegEx.create_from_string("^[a-z][a-z0-9_]*$")

func _init() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		DisplayServer.window_set_position(Vector2i(-16000, -16000))
	call_deferred("_run")

func _run() -> void:
	_check_in_world_nouns()
	_check_displayed_names()
	_check_parry()
	_check_colours()
	_check_equipment_never_carries_moves()
	await _check_shatter_speaks()
	if _failures.is_empty():
		print("DEAD WAX CANON PASS (%d checks)" % _checks)
		quit(0)
		return
	for failure in _failures:
		push_error("CANON FAIL: " + failure)
	quit(1)

# -- nobody in-world says needle or stylus (docs/CAST.md, docs/PITCH.md) -----

func _check_in_world_nouns() -> void:
	var scanned := 0
	for path in _scripts():
		var source := FileAccess.get_file_as_string(path)
		for literal in _string_literals(source):
			scanned += 1
			var text := String(literal.text)
			if _banned.search(text) != null and _identifier.search(text) == null:
				_check(false, "%s:%d says \"%s\" — nobody in-world says needle or stylus; the role is the Player and Skip's weapon is his point" % [path, literal.line, text])
	_check(scanned > 1000, "the in-world noun scan read the game's string literals (%d)" % scanned)
	var plan: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_map.json"))
	_check(plan is Dictionary, "the planned world parses for the noun scan")
	_scan_json(plan, "data/world_map.json")

func _scan_json(value: Variant, where: String) -> void:
	if value is Dictionary:
		for key in value:
			_scan_json(value[key], where + "." + str(key))
	elif value is Array:
		for index in value.size():
			_scan_json(value[index], "%s[%d]" % [where, index])
	elif value is String and _banned.search(value) != null and _identifier.search(value) == null:
		_check(false, "%s says \"%s\" — nobody in-world says needle or stylus" % [where, value])

func _check_displayed_names() -> void:
	for slot in Catalog.SLOTS:
		var label := Catalog.slot_label(slot)
		_check(Catalog.SLOT_LABELS.has(slot), "equipment slot %s has a display label, so its save key is never shown" % slot)
		_check(_clean(label), "equipment slot %s reads \"%s\" on screen" % [slot, label])
	for item in Catalog.items():
		for field in ["name", "description", "tradeoff"]:
			_check(_clean(String(item[field])), "equipment %s %s is clean: %s" % [item.id, field, item[field]])
	for item in Economy.catalog():
		_check(_clean(String(item.name)) and _clean(String(item.description)), "shop item %s reads in canon terms" % item.id)
	for ability in Abilities.catalog():
		for field in ["name", "description", "lead"]:
			_check(_clean(String(ability[field])), "ability %s %s reads in canon terms" % [ability.id, field])
	for text in Opening.CAPTIONS + Opening.IMPRINTS:
		_check(_clean(String(text)), "the opening says \"%s\"" % text)
	for entry in LostPressings.entries():
		_check(_clean(String(entry.clue)), "Lost Pressing %s clue reads in canon terms" % entry.id)

# -- the parry: 100 ms and +0.40 for every enemy that rings (COMBAT_FEEL) -----

func _check_parry() -> void:
	var payoffs := 0
	var windows := 0
	for path in _scripts():
		var source := _code_only(FileAccess.get_file_as_string(path))
		var defines_payoff := RegEx.create_from_string("(?m)^\\s*const\\s+RES_PARRY\\b").search(source) != null
		var defines_window := RegEx.create_from_string("(?m)^\\s*const\\s+PARRY_WINDOW_MS\\b").search(source) != null
		if not defines_payoff and not defines_window:
			continue
		var constants: Dictionary = (load(path) as Script).get_script_constant_map()
		if defines_payoff:
			payoffs += 1
			_check(is_equal_approx(float(constants.RES_PARRY), CANON_PARRY_RESONANCE),
				"%s pays %.2f resonance for a parry; canon is +%.2f for every enemy that rings" % [path, float(constants.RES_PARRY), CANON_PARRY_RESONANCE])
		if defines_window:
			windows += 1
			_check(int(constants.PARRY_WINDOW_MS) == CANON_PARRY_WINDOW_MS,
				"%s parries in %d ms; canon is %d ms" % [path, int(constants.PARRY_WINDOW_MS), CANON_PARRY_WINDOW_MS])
	_check(payoffs >= 2 and windows >= 3, "the parry check found the enemies that define it (%d payoffs, %d windows)" % [payoffs, windows])

# -- pink is sound being heard; gold is her (docs/art/direction.html) ---------

func _check_colours() -> void:
	_check(Press.PINK.is_equal_approx(CANON_PINK), "Press.PINK is canon crackle pink #E5407F (is %s)" % Press.PINK.to_html(false))
	_check(Press.GOLD.is_equal_approx(CANON_GOLD), "Press.GOLD is canon etch gold #D9A441 (is %s)" % Press.GOLD.to_html(false))
	_check(not Press.ACCENT.is_equal_approx(Press.PINK) and not Press.ACCENT.is_equal_approx(Press.GOLD),
		"decoration has its own ACCENT, distinct from pink and gold")
	var definition := RegEx.create_from_string("(?m)^\\s*const\\s+(PINK|GOLD)\\b")
	var gold_use := RegEx.create_from_string("\\bGOLD\\b")
	var gold_uses := 0
	for path in _scripts():
		var code := _code_only(FileAccess.get_file_as_string(path))
		for found in definition.search_all(code):
			if path != "res://scripts/press.gd":
				_check(false, "%s defines its own %s; only press.gd defines PINK and GOLD, so each keeps one meaning" % [path, found.get_string(1)])
		gold_uses += gold_use.search_all(code).size()
	gold_uses -= 1 # press.gd's own definition
	_check(gold_uses <= GOLD_BUDGET, "etch gold appears %d times in code; canon rations her to about %d" % [gold_uses, GOLD_BUDGET])

# -- traversal is never random (docs/PROGRESSION.md) --------------------------

func _check_equipment_never_carries_moves() -> void:
	var ability_ids: Array[String] = []
	for ability in Abilities.catalog():
		ability_ids.append(String(ability.id))
	for item in Catalog.items():
		for field in item:
			_check(String(field) in EQUIPMENT_FIELDS, "equipment %s field %s is one equipment may have" % [item.id, field])
		for effect in item.modifiers:
			_check(String(effect) in EQUIPMENT_EFFECTS, "equipment %s changes only handling or health, not %s" % [item.id, effect])
		_check(not (String(item.id) in ability_ids), "equipment %s is not a move" % item.id)

# -- the shatter speaks, in pink (COMBAT_FEEL.md) ------------------------------

func _check_shatter_speaks() -> void:
	var directory := "user://deadwax-canon-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(directory) == OK, "create a private canon checkpoint directory")
	var main := MainScene.instantiate()
	main.save_path = directory + "/checkpoint.json"
	main.settings_path = directory + "/settings.cfg"
	root.add_child(main)
	for frame in 3:
		await process_frame
	main._new_game(false)
	for frame in 3:
		await physics_frame
	main._has_session = false
	var before := _labels(main)
	main._word_splatter(Vector2(640, 360))
	var words: Array[Label] = []
	for label in _labels(main):
		if not label in before:
			words.append(label)
	_check(words.size() == 4, "a campaign shatter scatters its last words (%d)" % words.size())
	for word in words:
		_check(word.get_theme_color("font_color").is_equal_approx(Press.PINK), "the shatter's word %s is heard, so it is pink" % word.text)
	main.queue_free()
	for frame in 3:
		await process_frame
	_check(Save.new(directory + "/checkpoint.json").delete_save(), "remove the private canon checkpoint")
	if FileAccess.file_exists(directory + "/settings.cfg"):
		DirAccess.remove_absolute(directory + "/settings.cfg")
	_check(DirAccess.remove_absolute(directory) == OK, "remove the private canon directory")

# -- helpers -------------------------------------------------------------------

func _scripts() -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at("res://scripts"):
		if file.ends_with(".gd"):
			paths.append("res://scripts/" + file)
	paths.sort()
	return paths

func _labels(node: Node) -> Array[Label]:
	var found: Array[Label] = []
	for child in node.get_children():
		if child is Label:
			found.append(child)
	return found

func _clean(text: String) -> bool:
	return _banned.search(text) == null

## Every string literal in a GDScript source with the line it starts on.
## Comments are skipped; quotes, escapes and triple quotes are honoured.
func _string_literals(source: String) -> Array[Dictionary]:
	var literals: Array[Dictionary] = []
	var index := 0
	var line := 1
	var length := source.length()
	while index < length:
		var c := source[index]
		if c == "\n":
			line += 1
			index += 1
		elif c == "#":
			while index < length and source[index] != "\n":
				index += 1
		elif c == "\"" or c == "'":
			var quote := c.repeat(3) if source.substr(index, 3) == c.repeat(3) else c
			var start := index + quote.length()
			var start_line := line
			var cursor := start
			while cursor < length and source.substr(cursor, quote.length()) != quote:
				if source[cursor] == "\\":
					cursor += 1
				elif source[cursor] == "\n":
					line += 1
				cursor += 1
			literals.append({"text": source.substr(start, cursor - start), "line": start_line})
			index = cursor + quote.length()
		else:
			index += 1
	return literals

## The source with comments and string contents blanked out, line breaks kept.
func _code_only(source: String) -> String:
	var out := PackedStringArray()
	var index := 0
	var length := source.length()
	while index < length:
		var c := source[index]
		if c == "#":
			while index < length and source[index] != "\n":
				index += 1
		elif c == "\"" or c == "'":
			var quote := c.repeat(3) if source.substr(index, 3) == c.repeat(3) else c
			var cursor := index + quote.length()
			while cursor < length and source.substr(cursor, quote.length()) != quote:
				if source[cursor] == "\\":
					cursor += 1
				elif source[cursor] == "\n":
					out.append("\n")
				cursor += 1
			out.append("\"\"")
			index = cursor + quote.length()
		else:
			out.append(c)
			index += 1
	return "".join(out)

func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)
