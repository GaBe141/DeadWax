# DEAD WAX — The Label

An authored eight-room opening chapter about a stylus, a street of worn
records, and the song still playing underneath it. Start at the Headshell,
learn to launch from live wax, choose what to do with the voices in the Yard,
and count in the Descent Gate. The chapter ends at the listening point in
the Overture Stair.

Open this folder in **Godot 4.7.x** and press **F5**, or run
`.\deadwax.cmd play`. The title screen offers **New Game** and **Continue**.
Everything is built from code at runtime, so an empty editor viewport is
expected. The current playable build is this first chapter; the larger 53-room map
remains development scaffolding.

On the Dead Wax Wyse, the lightweight project commands are:

```text
.\deadwax.cmd doctor  check the local toolchain and repository
.\deadwax.cmd play    play the opening chapter with a local runtime log
.\deadwax.cmd dev     open the original mechanics rooms and planned-world tools
.\deadwax.cmd editor  open the project in Godot
.\deadwax.cmd check   import resources; run smoke, save, and campaign suites
.\deadwax.cmd vibe    start Mistral Vibe in this repository
```

See `PLAYTEST.md` for the opening and mechanics playtests, and `ROUTING.md`
for the chapter route and development atlases.

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

## Saving and settings

The chapter saves at passages, opened locks, resolved encounters, polishing,
the Book, pause, title, and quit. Continue starts at the entry used for the
saved room, carrying learned techniques, Shine, opened doors, encounter
outcomes, and chapter completion. Freed and shattered voices stay gone;
polished wax cannot pay out twice.

The checkpoint is `user://deadwax-save.json`. Writes are validated and keep a
`.bak` recovery copy of the previous valid checkpoint. Volume, fullscreen,
and reduced camera motion are saved separately in
`user://deadwax-settings.cfg`. Reduced camera motion removes camera smoothing
and shake. Escape/gamepad Back opens pause; gamepad Start keeps its role as
the Book. The needle can take three hits before recovering at the active room
entry with full health and preserved progress. Continue also starts there at
full health.

## Controls

- **A/D** move · **SPACE** jump (stubby on purpose — the strike does the flying)
- **J** (or X) — **STRIKE**: near a live groove it launches you; below the
  Scratch it jets you through thick air; near the dummy it builds resonance.
  After finding **GATHER**, one air-strike breath follows you into dry rooms.
- **K hold** (or C) — **HOOD UP**: silence. Slower, softer, your crackle
  drains fast, the world goes lowpass-muffled, and things stop hearing you.
  Hold it beside dull grey wax to **polish** (mints shine).
- **L hold** — **SET / KNEEL**: listen to an Auditioner instead of breaking it.
- **W/S** (or arrows) — aim directional strikes while airborne.
- **E** (or gamepad Y) — enter a nearby room passage.
- **I** (or gamepad Start) — open **The Book**, the full-screen inventory.
- **Escape** (or gamepad Back) — pause; Escape inside the Book closes it first.
- **F** (or right shoulder) — **FLIP**: turn the pressing over. Needs the
  **Jump-Cut**. Silent until you carry it.
- **R** respawn at the current room entry.

TAB, M, and G are available only in the opt-in development rooms below.

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
Refrains, and current Shine. Inside the game, unknown techniques and Refrains
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

These are shells for feeling the map's shape and scale. The opening uses
eight of the plan's identities through `scripts/chapter_one.gd`, with its own
authored geometry and passages. The complete graybox atlas remains available
unchanged for topology checks. See `ROUTING.md` for both loaders.

## What to feel for (bring notes)

- Does the parry window (100 ms) feel fair after learning the tell?
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
- All SFX are synthesized in `scripts/audio_bank.gd` — still no audio assets

## How it looks

Dead Wax is printed matter, so it is rendered as printed matter. Everything
visual lives in `scripts/press.gd` — the press — and rooms only ever say *what*
is there, never how it is inked:

- **Plates.** A platform is an inked plate, not a filled rectangle: pressure
  varies across it, the edge bites unevenly into the stock, and a second plate
  in the accent colour never quite registers with the first.
- **Stock.** Each room is printed over a halftone tint block in its own ink, so
  the space behind the platforms is a page rather than a void.
- **The sheet.** A screen-space tooth and a pressed-in vignette sit over the
  world and under the type. It is static: paper does not swim when the camera
  pans, film grain does.
- **Type.** Big Shoulders for wood type — room names, the one word a moment is
  worth — and IBM Plex Mono for everything the world says to you. Both SIL OFL;
  licences ship beside them in `assets/fonts/`.
- **Signage.** Room text is pasted up as a card with stock, a struck rule, and a
  heading pulled from its leading ALL-CAPS line. Not a floating caption.

Ink and stock come from the room's own `ink` and `bg_color`, so all six strata
palettes and both faces of the pressing flow through the same press unchanged.

## Development checks

Run `.\deadwax.cmd check` before committing. It imports resources and runs the
dependency-free native smoke, save-store, and campaign suites. These cover the
original combat and progression invariants, all planned-room routes, validated
checkpoint recovery, the opening's room graph, and campaign state restoration.
GitHub runs the checks on pushes and pull requests. Gameplay feel, real audio,
rendering, and controller behavior still require `PLAYTEST.md`.

There is no `export_presets.cfg` yet; this checkout runs through Godot rather
than a configured distributable build.
