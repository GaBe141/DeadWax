# DEAD WAX — game prototype

Open this folder in **Godot 4.7.1** and press **F5**. Everything is built from
code at runtime — the editor viewport is supposed to look empty.

On the Dead Wax Wyse, the lightweight project commands are:

```text
.\deadwax.cmd doctor  check the local toolchain and repository
.\deadwax.cmd play    run the prototype with a local runtime log
.\deadwax.cmd editor  open the project in Godot
.\deadwax.cmd check   import resources and run the smoke suite
.\deadwax.cmd vibe    start Mistral Vibe in this repository
```

See `PLAYTEST.md` for the repeatable five-room playtest and `ROUTING.md` for
the compact traversal layout.

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
- **F** (or right shoulder) — **FLIP**: turn the pressing over. Needs the
  **Jump-Cut**. Silent until you carry it.
- **R** respawn at the current entry · **TAB** debug-build room cycle
- **M** (debug builds) — walk the **planned world**: all 53 rooms of
  `data/world_map.json`, grayed in. TAB then cycles that atlas instead.
- **G** (debug builds) — grant every Refrain, for feel-testing.

## Character progression

Dead Wax uses a hybrid metroidvania progression instead of a conventional
skill tree:

- **Strike, Hood, and Set** are core verbs available from the start.
- **Count-In** and **Step-Turn** are knowledge techniques. Discovering one
  records it in the HUD and future save data, but never gates the input or
  solution itself. Count-In is recorded when you prove it at a groove-lock.
- **Gather, Rest, and Jump-Cut** are earned Refrains. The first playable slice
  is **Gather**, waiting at the end of The Unplayed. It preserves one breath in
  dry wax; rooms that already grant more keep their original capacity.
  **Jump-Cut** turns the pressing over (see The B-side); it is chalked in The
  Mispress Core, deep in the Undersong.

Progression currently lasts for the running session: it survives R respawns
and physical room transitions, then resets on a fresh launch. Rest is
represented in progression state but does not have a gameplay effect yet.

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

## The playable route

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

The five rooms above are hand-built. Behind them, `data/world_map.json` plans
53 rooms across six strata, and the runtime now grays every one of them in:
correct footprint, stratum palette and air, one passage per planned route, and
Refrain seals where the plan asks for them. Press **M** in a debug build to
walk it.

These are shells, not designed rooms — structure to build into, and a way to
feel the shape and scale of the full map before it is authored. A graybox is
replaced by writing a room script that claims its id; hand-authored rooms
always win. See `ROUTING.md` for how the plan becomes geometry.

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
- All SFX are synthesized in `scripts/audio_bank.gd` — no assets anywhere

## Development checks

The dependency-free smoke suite validates all project resources, compact-map
topology, every current prototype passage, named arrivals, the runtime input
map, and the grayed-in world: every planned room boots, its passages match the
plan, its arrivals resolve, its climbs fit a plain jump, and a walk from the
Headshell still reaches all 53 rooms and every Refrain. Run
`.\deadwax.cmd check` before committing. GitHub runs the same checks on pushes and
pull requests. Gameplay feel, real audio, and controller behavior still require
the manual checklist in `PLAYTEST.md`.
