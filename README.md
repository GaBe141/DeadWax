# DEAD WAX — The Label & The Overture

A fifteen-room playable journey about a stylus, a street of worn records,
and the song still playing underneath it. Start at the Headshell, count in
the Descent Gate, then follow the Overture through wind-played grooves,
Addie's doorway, HUSH's duel, and the Tonearm. How you answer the Tonearm
changes what waits at home.

Open this folder in **Godot 4.7.x** and press **F5**, or run
`.\deadwax.cmd play`. The title screen offers **New Game** and **Continue**.
New Game opens with a 23-second illustrated prologue: a town in the grooves,
its fading song, and a little needle taking its first steps. **Space / A**
advances a scene; **Escape / B** skips to the Headshell. **Watch opening**
on the title screen replays it without replacing your save. Continue goes
straight to your saved entry. Reduced motion presents still illustrations;
the captions and original synthesized score tell the same story.

Everything is built from code at runtime, so an empty editor viewport is
expected. The Label and Overture are authored; the remainder of the planned
53-room world is still development scaffolding.

On the Dead Wax Wyse, the lightweight project commands are:

```text
.\deadwax.cmd doctor  check the local toolchain and repository
.\deadwax.cmd play    play the campaign with a local runtime log
.\deadwax.cmd dev     open the original mechanics rooms and planned-world tools
.\deadwax.cmd editor  open the project in Godot
.\deadwax.cmd check   import resources; run all twenty-two native test suites
.\deadwax.cmd vibe    start Mistral Vibe in this repository
```

See `PLAYTEST.md` for campaign and mechanics playtests, and `ROUTING.md`
for the authored route and development atlases.

## The opening chapter

```text
HEADSHELL <-> HORN PLAZA <-> STALLS <-> YARD <-> DESCENT GATE <-> OVERTURE STAIR
                 |   |
           HIGH STREET <-> PRACTICE ROOM
```

The plaza is the junction: west leads to the Looper and Tick's Count-In
lesson; east leads through the market to the way down. Practice also returns
directly to the plaza. Doors respond to four even strikes whether or not
the Book has recorded the technique. The street has room to slip past its
encounter, and the Yard's voices can be heard or shattered.

The first Yard voice carries a half-remembered name. Stand near it with
**Hood** raised for its two notes, then lower Hood and begin holding **Set**
in the silence. One answer is enough. The voice gives you time and will try
again; holding Set before the phrase does not answer it. Visible note marks
and a changing card carry the cues with sound off or Reduced motion on.

Hearing it completes a warm engraving where it stood. Stay nearby and its
finished phrase returns quietly; shattering leaves a fractured impression.
Both choices survive recovery and Continue, including old saved outcomes.
The second Yard voice retains ordinary sustained Set. The road stays open,
and neither choice grants Shine, techniques, or a Refrain.

## Into the Overture

The old listening point is now the passage into the Bootlegger's stall.
Continue an existing demo save to carry on from the room where you stopped.

```text
OVERTURE STAIR <-> BOOTLEGGER <-> WHISTLERS <-> ADDIE <-> OVERTURE WELL
                                                               |
                                                        WORN GALLERY
                                                          |      |
                                                     HUSH <-> THE ARM
```

The gallery's direct passage to the Arm opens after reaching the arena from
HUSH's side. The well and wind course have return routes, so the descent
does not strand you below the Label.

HUSH's burnished floor asks for three parries; ordinary hits do not win his
bout. The Tonearm points up once and never attacks first. Striking commits
to its measured sweeps; openings let you strike back. Staying close and
holding Set offers another answer. Both outcomes persist, and the final
listening point asks for E/Y after the encounter is resolved. The Headshell
has different words and scenery when you return.

The first descent uses grooves, wind, and ordinary jumps. After either Tonearm
outcome, a **Gather** pressing appears beside the open seal. Pick it up, jump,
then Strike near the crest to climb on one held breath. Landing refills it;
ordinary grounded attacks keep their footing. The nearby shelf offers a safe
place to try it. Jump-Cut remains a later discovery.

## A phrase to carry home

The Stalls' upper balcony is visible on the first visit, beyond the reach of
an ordinary jump. Return with Gather, jump beside its left edge, and spend
your breath to land above the shutters. A small voice is waiting there.

Stand beside it and hold Hood to hear three notes. In the silence, lower Hood
and press and hold Set. Answer twice; visible note marks and a changing card
carry the same cues as the sound. The voice opens a passage between the loft
and the Worn Gallery, and its melody joins the Horn Plaza and Headshell when
you return. The folded map includes this second dashed shortcut.

Gather, the voice, and its passage survive recovery and Continue. Players
with an already completed demo can revisit the Arm for the pressing. The
discovery grants no Shine and leaves both Tonearm endings available.

## Living ink

Skip breathes and blinks at rest, leans into a running stride, stretches on
takeoff, and compresses on landing. Strikes flick the point forward; the Hood
slides into place and Set lowers the body into a listening pose.

Voices step and reach, the practice pressing bends and springs back, and
HUSH and the Tonearm carry their windups through contact and recovery.
The animation follows the existing combat clock. It never moves collision
shapes, changes damage ranges, or delays a strike. Pause freezes the poses;
recovery clears transient player and boss motion.

The Label and Overture have company, too. Tick nods through three beats and
loses the fourth; grounded E/Y lets him talk about the nearby Count-In door.
The Bootlegger rummages through tapes, looks up at Skip, and has different
words after the Tonearm's ending. These conversations advance once per press.

The Hound patrols beneath the plaza horn. Stand still with the Hood raised
and let it come close: it settles beside Skip and wags for quiet company.
Nearby strikes startle it briefly, and each freed voice widens its patrol.
A freed Addie putters beside her doorway and pats a returning Hood or Set
visitor. These small interactions offer company without replaying rewards;
shattered Addie stays gone. Existing saves carry these choices forward.

## Shine and the stall

Hold the Hood beside worn wax to polish it and earn **1 Shine**. Each of the
campaign's nine patches pays once, with a small `+1 SHINE` impression when
collected. Your balance appears in the HUD, the Book, and the stall.

Stand beside the Bootlegger and press **B / D-pad Up** to browse. E/Y still
talks to him. Choose a piece, then use its Buy button; browsing pauses the
game. Escape, controller B/Back, or Leave closes the stall.

| Piece | Shine | What it does |
| --- | ---: | --- |
| Spare Groove | 4 | Adds one permanent needle-health slot, taking the maximum from 3 to 4. Fills the added slot when bought. |
| Soft Lining | 3 | Raises Hood walking speed from 62% to 75% of ordinary walking speed. |
| Warm Thread | 2 | Stitches an amber trim around Skip's Hood. Cosmetic. |

Every purchase is permanent, applies immediately, and appears in the Book.
Already-owned pieces cannot be bought twice. The five patches available by
the first stall visit can fund either functional upgrade; all nine fund the
whole counter. No core verb, technique, or passage requires a purchase.
Recovery preserves your Shine and items. A failed purchase save refunds its
debit and applies no effect; old saves begin with the same Shine and an empty
purchase list.

## Saving and settings

The chapter saves at passages, opened locks, resolved encounters, polishing,
the Book, pause, title, and quit. Continue starts at the entry used for the
saved room, carrying learned techniques, Shine, opened doors, encounter
outcomes, and chapter completion. Resolved voices never return to combat;
polished wax cannot pay out twice.

Earlier demo saves remain valid. Their old Overture-Stair completion flag is
reinterpreted as an unfinished extended journey; room, entry, Shine, knowledge,
and encounter choices are retained. Completion now also requires a resolved
Tonearm encounter. An unfinished HUSH or Tonearm attempt resets on recovery;
a resolved encounter stays resolved.

The checkpoint is `user://deadwax-save.json`. Writes are validated and keep a
`.bak` recovery copy of the previous valid checkpoint. Volume, fullscreen,
and reduced camera motion are saved separately in
`user://deadwax-settings.cfg`. Reduced camera motion removes camera smoothing
and shake, and freezes decorative ambient motion, parallax, and slow lamp
modulation. Escape/gamepad Back opens pause; gamepad Start keeps its role as
the Book. The needle can take three hits, or four with Spare Groove, before
recovering at the active room entry with full health and preserved progress.
Continue also starts there at full health.

## Controls

- **A/D** move · **SPACE** jump (stubby on purpose — the strike does the flying)
- **J** (or X) — **STRIKE**: hit nearby foes while keeping your footing.
  Jumping and striking a vulnerable foe gives an upward rebound; live grooves
  launch you from the ground or air and take priority over enemy rebounds.
  Thick air supplies directional jets; after finding **GATHER**, one air-strike
  breath follows you into dry rooms.
- **K hold** (or C) — **HOOD UP**: silence. Slower, softer, your crackle
  drains fast, the world goes lowpass-muffled, and things stop hearing you.
  Hold it beside dull grey wax to **polish** (mints shine).
- **L hold** — **SET / KNEEL**: listen to an Auditioner instead of breaking it.
- **W/S** (or arrows) — aim directional strikes while airborne.
- **E** (or gamepad Y) — enter a nearby passage or listen to a resident.
- **B** (or D-pad Up) — browse the Bootlegger's stall while standing nearby.
- **I** (or gamepad Start) — open **The Book**, the full-screen inventory.
- **Escape** (or gamepad Back) — pause; Escape inside the Book closes it first.
- **F** (or right shoulder) — **FLIP**: turn the pressing over. Needs the
  **Jump-Cut**. Silent until you carry it.
- **R** respawn at the current room entry.

After collecting the folded map, **M / D-pad Down** opens it while exploring.
The Book also has an **Open map** button. In the Book, keyboard M opens the map;
the controller D-pad retains its usual selection controls.
TAB and G are available only in the opt-in development rooms below; there M
continues to switch development atlases.

A ready strike answers immediately. A press in the last 90 ms of the 200 ms
cooldown queues one follow-up; holding the button does not repeat attacks.
Ground recovery lasts 100 ms and keeps 80% movement acceleration. Hood, Set,
damage, menus, recovery, and passages cancel a queued strike.

The immediate circular impression shows the 120 px enemy-hit reach; fainter
echoes show groove and air responses. Muted HUSH does not give a rebound from
raw hits. His three-parry challenge and the 100 ms parry window stay the same.

## The folded map

A folded page waits on the Headshell floor, a short walk right of the starting
point and before the first raised block. Walk close to pick it up. The map marks
your current room and remembers the rooms you explore; unvisited places stay
unnamed. It shows the connected Label and Overture, with the gallery shortcut
drawn as a dashed route. Passages may still need to be opened in the world.

Ownership and explored rooms survive recovery, Continue, and returning to the
title. Existing saves remain valid: visit the Headshell to collect the page on
an older journey. New Game clears it along with the rest of that journey.
Opening the map pauses play; closing it returns you to the same position.

## Character progression

Dead Wax uses a hybrid metroidvania progression instead of a conventional
skill tree:

- **Strike, Hood, and Set** are core verbs available from the start.
- **Count-In** and **Step-Turn** are knowledge techniques. Discovering one
  records it in the Book and save data, but never gates the input or
  solution itself. Count-In is recorded when you prove it at a groove-lock.
- **Gather, Rest, and Jump-Cut** are earned Refrains. In the development
  circuit, **Gather** waits at the end of The Unplayed. It preserves one breath in
  dry wax; rooms that already grant more keep their original capacity.
  **Jump-Cut** turns the pressing over (see The B-side); it is chalked in The
  Mispress Core, deep in the Undersong.

The opening records Count-In; the Refrain pickups and thick-air mechanics
remain available in the development rooms. Campaign progression is saved to
disk. Development-room progression lasts for that session and does not write
the campaign save. Rest is represented in progression state but does not have
a gameplay effect yet.

## The B-side

A record has two sides. **Jump-Cut** lets you turn the one you are standing on
over, and the far face is the same room read from the side nobody played:

- **The air inverts.** Spent wax reads thick — it answers a strike, and it
  holds your weight. Thick wax reads dry, and stops answering.
- **Grooves belong to a side.** Everything pressed loud on the A-side falls
  quiet when you flip. The trade is legible in one room: lose your launches,
  gain the air.
- **The ink inverts.** Paper and print trade places; the world goes
  scratchboard. Rooms are not duplicated — a room authors its A-side only.
- **Burnishing is one-sided.** HUSH smoothed the face that was up. The B-side
  of The Smoothed Floor still rings, so resonance works there.
- **A side has a runtime.** The B-side plays down in about twelve seconds, then
  the needle lifts and drops you back wherever you are standing. It rewinds
  slowly while you are on the A-side. Every flip is a round trip you have to
  plan — and the air holding you up is on a timer.

Turning over is silent until Jump-Cut is carried; an unearned Refrain is never
announced before it is found. The Bootlegger has an opinion about this:
*don't touch the B-sides.*

## The Book

The Book is a full-screen, read-only inventory. It pauses the room and records
the three always-owned core verbs, discovered knowledge techniques, carried
Refrains, current Shine, and permanent purchases. Inside the game, unknown techniques and Refrains
remain unnamed until the session records them; opening the Book never unlocks
or equips anything. Use arrows, D-pad, or the left stick to select an entry, and press
I/Start again or Escape to close it.

## Development rooms

Run `.\deadwax.cmd dev`, or pass `-- --dev-rooms` to Godot. This explicitly
enables the original five-room mechanics circuit and the full graybox atlas.
TAB cycles rooms, M switches between the two atlases, and G grants every
Refrain for feel-testing. These tools also require a debug build. Normal
chapter play never routes into an unfinished shell.

```text
LABEL <-> PRACTICE <-> VERSE <-> UNPLAYED <-> SMOOTHED <-> LABEL
  Gather opens the Label -> Smoothed shelf shortcut.
```

1. **THE LABEL** — M0's dry lessons, reskinned: groove launches, spent-wax
   gaps, the shaft, ON BEAT. It hides an **unsigned groove-lock** and a high
   dry return shelf that becomes a Smoothed shortcut after Gather.
2. **THE PRACTICE ROOM** — M1's heart. The **Test Pressing** dummy: it hears
   your crackle, ticks three times, swings on four. Strike exactly as the
   swing lands: **RUNG BACK** (parry). Fill its rim to shatter it. Also:
   polishing corner, and the **signed COUNT-IN door** (four even strikes,
   any tempo). Opening either groove-lock records Count-In as learned.
3. **THE VERSE** — Auditioners can be shattered or heard. Hold SET nearby to
   free one peacefully.
4. **THE UNPLAYED** — thick-air flight, two breaths, hot grooves, and the
   **Gather** Refrain at the climb-out. Its passage continues to Smoothed.
5. **THE SMOOTHED FLOOR** — a bout on HUSH's terms: resonance OFF, raw hits
   worthless, three rung-backs to win. Spacing and timing, nothing else.
   This room decides whether the rival duels will feel good.

## The planned world

The five development rooms above are hand-built. `data/world_map.json` plans
53 rooms across six strata, and the runtime now grays every one of them in:
correct footprint, stratum palette and air, one passage per planned route, and
Refrain seals where the plan asks for them. Press **M** in the opt-in
development rooms to walk it.

These are shells for feeling the map's shape and scale. The campaign uses
fifteen of the plan's identities through `scripts/campaign.gd`, with its own
authored geometry and passages. The complete graybox atlas remains available
unchanged for topology checks. See `ROUTING.md` for both loaders.

## What to feel for (bring notes)

- Does the parry window (100 ms) feel fair after learning the tell?
- Do grounded hits, jump rebounds, and quick follow-up presses feel deliberate?
- Does hood-stealth read — do you *feel* quieter, does the dummy calming
  down land?
- Is the count-in door forgiving enough at fast and slow tempos?
- Does bringing one breath back to The Label feel like a meaningful return?
- Is the muted room fun with everything subtracted, or just empty?

## Tuning knobs

- Movement/strike/noise: constants at the top of `scripts/skip.gd`
- Dummy timing/windows: constants atop `scripts/test_pressing.gd`
- Door strictness: `GAP_MIN/GAP_MAX/EVENNESS` in `scripts/refrain_door.gd`
- B-side length and rewind: constants atop `scripts/pressing_state.gd`
- Type, ink, plates and paper: `scripts/press.gd` and `assets/shaders/`
- Room light placement and exposure: `scripts/lighting_profiles.gd`
- All SFX are synthesized in `scripts/audio_bank.gd` — still no audio assets

## How it looks

Dead Wax is printed matter, so it is rendered as printed matter. Everything
visual lives in `scripts/press.gd` — the press — and rooms only ever say *what*
is there, never how it is inked:

- **Plates.** A platform is an inked plate, not a filled rectangle: pressure
  varies across it, the edge bites unevenly into the stock, and a second plate
  in the accent colour never quite registers with the first.
- **Stock and depth.** The fifteen authored rooms have a still field of paper
  light beneath distant architecture and a nearer layer of hanging cloth,
  shelves, record rings, and other room-specific cuts. The far artwork stays
  static; selected middle details move gently. Camera travel gives both planes
  parallax. Development rooms and grayboxes retain their halftone backdrop.
- **Exposed edges.** Lamination, scoring, and rivets are clipped to the actual
  platform faces, at least 10 pixels below their walkable tops. They never
  cover a landing or bridge a gap.
- **Lamps and shadows.** Each authored room has two to four native
  `PointLight2D` sources and one `CanvasModulate` for ambient exposure. Lights
  stay fixed in the world as the artwork moves in parallax. Real platform
  faces cast shadows through polygons inset by 2 pixels; these add no physics.
  Lighting stays on canvas layer 0, leaving the sheet, HUD, and menus unchanged.
- **The sheet.** A screen-space tooth and a pressed-in vignette sit over the
  world and under the type. It is static: paper does not swim when the camera
  pans, film grain does.
- **Type.** Big Shoulders for wood type — room names, the one word a moment is
  worth — and IBM Plex Mono for everything the world says to you. Both SIL OFL;
  licences ship beside them in `assets/fonts/`.
- **Signage.** Room text is pasted up as a card with stock, a struck rule, and a
  heading pulled from its leading ALL-CAPS line. Not a floating caption.

Ink and stock come from the room's own `ink` and `bg_color`; turning A→B→A
reprints every layer and restores the authored palette and exposure. The B-side
gets extra ambient fill to keep white ink readable. Pause freezes scenery and
lighting; reduced motion stops ambient movement, parallax, and slow lamp
modulation while encounter outcomes can still change the light's energy.
Development rooms and grayboxes have no room lighting. These layers change no
platforms, routes, encounters, or rewards.

Menus now reveal their type in short impressions, with moving ink accents for
mouse and controller focus. The sleeve's record turns gently while its label
stays upright. The Book and stall respond to selections and purchase results;
room headings, feedback, and Shine receipts animate on the HUD. Text and
balances update immediately, and closing a panel never waits for animation.
Reduced motion settles interface effects immediately. Open menus keep their
own animation while gameplay and the HUD remain paused underneath.

## Development checks

Run `.\deadwax.cmd check` before committing. It imports resources and runs the
dependency-free native smoke, save-store, campaign, Tonearm, Overture,
sprite-animation, residents, economy-state, economy integration, scenery,
lighting, attack-feel, GUI-animation, and map-item suites. These cover the original combat and
progression invariants, all planned-room routes, validated
checkpoint recovery, both chapters' room graph, boss outcomes, old-demo save
continuation, campaign state restoration, grounded conversations, resident
pause behavior, harmless petting, silent return visits, purchase transactions,
item effects, compatibility with saves made before the stall opened, scenery
clipping and lifecycle, palette restoration, parallax, native light and
occluder setup, UI isolation, reduced motion, grounded hits, airborne rebounds,
strike buffering and cancellation, unchanged parry timing, menu interruption,
focus, reduced-motion behavior, map ownership and save compatibility, the
authored map graph, and map input/pause boundaries.
GitHub runs the checks on pushes and pull requests. Gameplay feel, real audio,
rendering, and controller behavior still require `PLAYTEST.md`.

There is no `export_presets.cfg` yet; this checkout runs through Godot rather
than a configured distributable build.
