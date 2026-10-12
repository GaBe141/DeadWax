extends RefCounted
## The art-direction test (docs/README.md, canon status: "Art direction").
## One room, Horn Plaza, can be drawn in the canon's dense ink style
## (docs/art/direction.html, docs/art/cutaway.html) instead of the build's
## Quiet Wax, so the two can be judged side by side in play. Off by default:
## F9 in the campaign flips it, and `-- --ink-test` starts with it on. Nothing
## is saved. Only presentation changes; collision, routes, fixtures,
## encounters and every timer are the same in either look.

## Rooms the test covers. Everywhere else stays Quiet Wax.
const ROOMS := [&"horn_plaza"]

## The player's choice, for this run only.
static var enabled := false
## True while the current room is drawn in ink. Main sets it; the Press reads
## it to choose between the two looks for figures and fixtures.
static var active := false
## Whether that room is showing the far face of the pressing (scratchboard).
static var far_face := false
## The lamps burning in that room, in world space, for figures walking past
## them (press_ink_light.gd). The ink plate sets them and takes them away.
static var lamps: Array = []

# -- the strata palette (docs/art/direction.html, 05) --------------------------
## Crackle pink and etch gold are not repeated here: they live in press.gd,
## pink only where sound is heard, gold only for her.
const LABEL_PAPER := Color("e8e0cc")
const DUST := Color("c9bfa8")
const WAX := Color("0e0c10")
const GROOVE := Color("f2eee4")
const CANCEL_RED := Color("b8503c")
## The cutaway's own working inks (docs/art/cutaway.html).
const LINE := Color("241f1a")
const BRASS := Color("b98a4e")
const UMBER := Color("3a3128")
const STONE := Color("ddd3b8")

static func covers(room_id: StringName) -> bool:
	return room_id in ROOMS

## The page the room is printed on. Above the Scratch it is paper; the far
## face of the pressing is scratchboard, the same line reversed out of wax.
static func stock(far_face: bool) -> Color:
	return WAX if far_face else LABEL_PAPER

static func ink(far_face: bool) -> Color:
	return GROOVE if far_face else LINE
