extends RefCounted
## Printed facts and equipment values only. No rooms, actors or save ownership.

const SLOTS: Array[String] = ["needle", "lining", "charm"]
const CRAFT_COST := 40
const PITY_WINS := 20
const MASTERY_WINS := 100
const ITEMS: Array[Dictionary] = [
	{"id": "quicksilver_tip", "name": "Quicksilver Tip", "slot": "needle", "source": "label", "rarity": "Uncommon", "drop_chance": 4,
		"description": "A light stylus that likes the long straight streets.", "tradeoff": "+12% running speed; 20% less braking.", "modifiers": {"speed": 1.12, "friction": 0.8}},
	{"id": "blunt_stylus", "name": "Blunt Stylus", "slot": "needle", "source": "label", "rarity": "Rare", "drop_chance": 3,
		"description": "A short point that finds its footing quickly.", "tradeoff": "+20% ground acceleration; 8% less running speed.", "modifiers": {"accel": 1.2, "speed": 0.92}},
	{"id": "felt_cuff", "name": "Felt Cuff", "slot": "lining", "source": "label", "rarity": "Scarce", "drop_chance": 2,
		"description": "Soft lining that swallows the noise you leave behind.", "tradeoff": "+30% noise fading; 10% slower movement under the Hood.", "modifiers": {"noise_decay": 1.3, "hood_speed": 0.9}},
	{"id": "counterweight", "name": "Counterweight", "slot": "charm", "source": "label", "rarity": "Singular", "drop_chance": 1,
		"description": "A brass weight for a player who likes to stop on a mark.", "tradeoff": "+30% braking; 15% less steering in the air.", "modifiers": {"friction": 1.3, "air_control": 0.85}},
	{"id": "spring_stylus", "name": "Spring Stylus", "slot": "needle", "source": "overture", "rarity": "Uncommon", "drop_chance": 4,
		"description": "A sprung stem, eager to move and reluctant to settle.", "tradeoff": "+25% ground acceleration; 15% less braking.", "modifiers": {"accel": 1.25, "friction": 0.85}},
	{"id": "silk_hood", "name": "Silk Hood", "slot": "lining", "source": "overture", "rarity": "Rare", "drop_chance": 3,
		"description": "Fine cloth that slips along the quiet road.", "tradeoff": "+18% movement under the Hood; noise fades 20% slower.", "modifiers": {"hood_speed": 1.18, "noise_decay": 0.8}},
	{"id": "padded_sleeve", "name": "Padded Sleeve", "slot": "lining", "source": "overture", "rarity": "Scarce", "drop_chance": 2,
		"description": "Thick packing from a record that survived the journey.", "tradeoff": "+1 maximum needle health; 8% less running speed.", "modifiers": {"health": 1, "speed": 0.92}},
	{"id": "metronome", "name": "Pocket Metronome", "slot": "charm", "source": "overture", "rarity": "Singular", "drop_chance": 1,
		"description": "It carries momentum better than it starts it.", "tradeoff": "+10% running speed; 20% less ground acceleration.", "modifiers": {"speed": 1.1, "accel": 0.8}},
	{"id": "glass_needle", "name": "Glass Needle", "slot": "needle", "source": "unplayed", "rarity": "Uncommon", "drop_chance": 4,
		"description": "A clear, fragile point that follows the smallest turn.", "tradeoff": "+25% steering in the air; -1 maximum needle health.", "modifiers": {"air_control": 1.25, "health": -1}},
	{"id": "stillwater_wrap", "name": "Stillwater Wrap", "slot": "lining", "source": "unplayed", "rarity": "Rare", "drop_chance": 3,
		"description": "Heavy quiet cloth from the rooms below the record.", "tradeoff": "+25% noise fading; 15% less ground acceleration.", "modifiers": {"noise_decay": 1.25, "accel": 0.85}},
	{"id": "feather_seal", "name": "Feather Seal", "slot": "charm", "source": "unplayed", "rarity": "Scarce", "drop_chance": 2,
		"description": "An almost weightless seal with a stubborn drift.", "tradeoff": "+20% steering in the air; 20% less braking.", "modifiers": {"air_control": 1.2, "friction": 0.8}},
	{"id": "ballast_seal", "name": "Ballast Seal", "slot": "charm", "source": "unplayed", "rarity": "Singular", "drop_chance": 1,
		"description": "A dense wax seal, kept whole through years of pressure.", "tradeoff": "+1 maximum needle health; 20% less steering in the air.", "modifiers": {"health": 1, "air_control": 0.8}},
]
const HUNTS: Array[Dictionary] = [
	{"id": "label", "name": "Label Echo Trial", "room_id": "practice_room", "position": Vector2(850, 574), "description": "Find the trial stand beyond Tick in Tick's Practice. Hear or shatter four echo copies across three waves.", "mastery_wins": MASTERY_WINS},
	{"id": "overture", "name": "Overture Echo Trial", "room_id": "worn_gallery", "position": Vector2(2180, 574), "description": "Find the trial stand in the eastern Worn Gallery, beyond the Arm's service door. Face four pressing echoes across three waves.", "mastery_wins": MASTERY_WINS},
	{"id": "unplayed", "name": "Unplayed Echo Trial", "room_id": "deep_gallery", "position": Vector2(1300, 834), "description": "Find the trial stand on the Deep Gallery's lower floor. Face four mixed echoes across three waves.", "mastery_wins": MASTERY_WINS},
]
const SPECIES: Array[Dictionary] = [
	{"id": "auditioner", "name": "Auditioner", "description": "An unfinished voice that reaches toward the player. Its opening arms precede contact.", "habitat": "The Yard, Worn Gallery and Unplayed warrens", "tip": "Kneel nearby and hold Set to hear it through. Strikes or a well-timed parry can shatter it."},
	{"id": "test_pressing", "name": "Test Pressing", "description": "A disc on a stand that hears crackle. Three ticks lead to a swing on the fourth beat.", "habitat": "The South Warren", "tip": "Step clear of the swing or strike as it lands. A vulnerable pressing can take an airborne rebound."},
	{"id": "street_looper", "name": "Street Looper", "description": "The High Street's guarded pressing keeps its count even when struck.", "habitat": "High Street", "tip": "Its swing leaves a one-second opening. Striking the guard will not hurt it or restart the count."},
	{"id": "hush", "name": "HUSH", "description": "The keeper of the smoothed floor has burnished away its resonance.", "habitat": "The Smoothed Floor", "tip": "Three clean parries win the bout. Ordinary strikes do not count."},
	{"id": "tonearm", "name": "The Tonearm", "description": "The first keeper points home and waits. It does not attack until it is struck.", "habitat": "The Arm", "tip": "Kneeling close by can resolve the encounter peacefully. Once engaged, listen for its count and use the recovery opening."},
	{"id": "yard_voice", "name": "The Yard's First Voice", "description": "A voice with a missing last note. A complete Hood call opens a brief silence.", "habitat": "The Groove Yard", "tip": "Hear both notes under the Hood, then start a fresh Set in the silence. An early held Set is not an answer."},
	{"id": "loft_voice", "name": "The Loft Voice", "description": "A lost phrase waits above the market shutters, listening for two replies.", "habitat": "The Stalls loft", "tip": "Let each Hood call finish. Begin a fresh held Set in each silent window."},
	{"id": "addie", "name": "Addie", "description": "Adagio in C, still beside her own doorway. An ending heard in peace can bring her home.", "habitat": "Addie's Door", "tip": "Hold Set nearby to let her hear the last bar. Freed Addie remains a harmless resident."},
	{"id": "hound", "name": "The Hound", "description": "A harmless plaza resident with a small patrol and an ear for quiet company.", "habitat": "Horn Plaza", "tip": "Stand still under the Hood nearby. Sudden noise startles it."},
	{"id": "resident", "name": "The Residents", "description": "Tick keeps time. The Bootlegger keeps the stall. Both have something to say.", "habitat": "Tick's Practice and the Bootlegger's stall", "tip": "Use E / Y while grounded nearby to talk. The Bootlegger's wares use B / D-pad Up."},
]
const ENCOUNTER_SPECIES := {
	"groove_yard/yard_first_voice": "yard_voice", "groove_yard/yard_last_voice": "auditioner",
	"high_street/street_looper": "street_looper", "the_stalls/loft_voice": "loft_voice",
	"addie/addie": "addie", "worn_gallery/gallery_near_voice": "auditioner",
	"worn_gallery/gallery_far_voice": "auditioner", "smoothed_floor/hush": "hush",
	"the_arm/tonearm": "tonearm", "verse_hall/hall_voice": "auditioner",
	"verse_warren_n/north_voice": "auditioner", "verse_warren_n/lower_voice": "auditioner",
	"verse_warren_s/warren_pressing": "test_pressing",
}

static func items() -> Array[Dictionary]:
	return ITEMS.duplicate(true)

static func item(id: String) -> Dictionary:
	return _find(ITEMS, id)

static func hunts() -> Array[Dictionary]:
	return HUNTS.duplicate(true)

static func hunt(id: String) -> Dictionary:
	return _find(HUNTS, id)

static func species() -> Array[Dictionary]:
	return SPECIES.duplicate(true)

static func species_entry(id: String) -> Dictionary:
	return _find(SPECIES, id)

static func species_for_encounter(key: String) -> String:
	return String(ENCOUNTER_SPECIES.get(key, ""))

static func _find(entries: Array[Dictionary], id: String) -> Dictionary:
	for entry in entries:
		if entry.id == id:
			return entry.duplicate(true)
	return {}
