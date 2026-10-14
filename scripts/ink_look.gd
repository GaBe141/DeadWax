extends RefCounted
## The game's look (docs/README.md, canon status: "Art direction"): the canon's
## dense ink (docs/art/direction.html, docs/art/cutaway.html). Black line on
## aged label paper above the Scratch, the same line reversed out of wax on the
## far face of the pressing, figures included. On by default. F9 in the
## campaign flips back to "Quiet Wax", the build's earlier look, for this run
## only, so the two can still be judged side by side; `-- --quiet-wax` starts
## there. Nothing is saved. Only presentation changes: collision, routes,
## fixtures, encounters and every timer are the same in either look.
##
## Horn Plaza has its own hand-drawn plate (press_ink_plaza.gd). Every other
## campaign room is drawn by press_ink_room.gd from the room's own geometry:
## its platforms, passages, landmarks and lamps.

## Rooms with a plate composed by hand. Everywhere else is drawn generically.
const HAND_DRAWN := [&"horn_plaza"]

## The player's choice, for this run only: ink (true) or Quiet Wax.
static var enabled := true
## True while the current room is drawn in ink. Main sets it; the Press reads
## it to choose between the two looks for figures and fixtures.
static var active := false
## Whether that room is showing the far face of the pressing.
static var far_face := false
## Whether the page is scratchboard: white line out of wax. That is the far
## face of the pressing, and everywhere below the Scratch (the Unplayed) on
## either face; the two cancel, so the Unplayed's far face is paper.
static var scratchboard := false
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

static func hand_drawn(room_id: StringName) -> bool:
	return room_id in HAND_DRAWN

## Rooms below the Scratch: the Unplayed, printed as scratchboard on the
## near face of the pressing.
const BELOW_SCRATCH := [&"the_drop", &"the_landing", &"verse_hall", &"verse_warren_n", &"verse_warren_s", &"deep_gallery"]

static func below_scratch(room_id: StringName) -> bool:
	return room_id in BELOW_SCRATCH

## Which page a room shows on a face of the pressing.
static func page_is_scratchboard(room_id: StringName, on_far_face: bool) -> bool:
	return on_far_face != below_scratch(room_id)

## The page the room is printed on: paper, or scratchboard, the same line
## reversed out of wax.
static func stock(on_scratchboard: bool) -> Color:
	return WAX if on_scratchboard else LABEL_PAPER

static func ink(on_scratchboard: bool) -> Color:
	return GROOVE if on_scratchboard else LINE
