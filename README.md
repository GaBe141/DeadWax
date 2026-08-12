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

See `PLAYTEST.md` for the repeatable five-room playtest.

## Controls

- **A/D** move · **SPACE** jump (stubby on purpose — the strike does the flying)
- **J** (or X) — **STRIKE**: near a live groove it launches you; below the
  Scratch it jets you through thick air; near the dummy it builds resonance
- **K hold** (or C) — **HOOD UP**: silence. Slower, softer, your crackle
  drains fast, the world goes lowpass-muffled, and things stop hearing you.
  Hold it beside dull grey wax to **polish** (mints shine).
- **L hold** — **SET / KNEEL**: listen to an Auditioner instead of breaking it.
- **W/S** (or arrows) — aim directional strikes while airborne.
- **R** respawn · **TAB** next room

## The rooms (TAB cycles)

1. **THE LABEL** — M0's dry lessons, reskinned: groove launches, spent-wax
   gaps, the shaft, ON BEAT. Now hides an **unsigned groove-lock** — if you
   already know the count-in, it opens in minute one. That's the law.
2. **THE PRACTICE ROOM** — M1's heart. The **Test Pressing** dummy: it hears
   your crackle, ticks three times, swings on four. Strike exactly as the
   swing lands: **RUNG BACK** (parry). Fill its rim to shatter it. Also:
   polishing corner, and the **signed COUNT-IN door** (four even strikes,
   any tempo).
3. **THE VERSE** — Auditioners can be shattered or heard. Hold SET nearby to
   free one peacefully.
4. **THE UNPLAYED** — thick-air flight, two breaths, hot grooves.
5. **THE SMOOTHED FLOOR** — a bout on HUSH's terms: resonance OFF, raw hits
   worthless, three rung-backs to win. Spacing and timing, nothing else.
   This room decides whether the rival duels will feel good.

## What to feel for (bring notes)

- Does the parry window (100 ms) feel fair after learning the tell?
- Does hood-stealth read — do you *feel* quieter, does the dummy calming
  down land?
- Is the count-in door forgiving enough at fast and slow tempos?
- Is the muted room fun with everything subtracted, or just empty?

## Tuning knobs

- Movement/strike/noise: constants at the top of `scripts/skip.gd`
- Dummy timing/windows: constants atop `scripts/test_pressing.gd`
- Door strictness: `GAP_MIN/GAP_MAX/EVENNESS` in `scripts/refrain_door.gd`
- All SFX are synthesized in `scripts/audio_bank.gd` — no assets anywhere

## Development checks

The dependency-free smoke suite validates all project resources, the 53-room
world-map data, every current prototype room, and the runtime input map. Run
`.\deadwax.cmd check` before committing. GitHub runs the same checks on pushes and
pull requests. Gameplay feel, real audio, and controller behavior still require
the manual checklist in `PLAYTEST.md`.
