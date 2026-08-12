# DEAD WAX — game prototype (M1)

Open this folder in **Godot 4.x** and press **F5**. Everything is built from
code at runtime — the editor viewport is supposed to look empty.

## Controls

- **A/D** move · **SPACE** jump (stubby on purpose — the strike does the flying)
- **J** (or X) — **STRIKE**: near a live groove it launches you; below the
  Scratch it jets you through thick air; near the dummy it builds resonance
- **K hold** (or C) — **HOOD UP**: silence. Slower, softer, your crackle
  drains fast, the world goes lowpass-muffled, and things stop hearing you.
  Hold it beside dull grey wax to **polish** (mints shine).
- **R** restart room · **TAB** next room

## The rooms (TAB cycles)

1. **THE LABEL** — M0's dry lessons, reskinned: groove launches, spent-wax
   gaps, the shaft, ON BEAT. Now hides an **unsigned groove-lock** — if you
   already know the count-in, it opens in minute one. That's the law.
2. **THE PRACTICE ROOM** — M1's heart. The **Test Pressing** dummy: it hears
   your crackle, ticks three times, swings on four. Strike exactly as the
   swing lands: **RUNG BACK** (parry). Fill its rim to shatter it. Also:
   polishing corner, and the **signed COUNT-IN door** (four even strikes,
   any tempo).
3. **THE UNPLAYED** — thick-air flight, two breaths, hot grooves.
4. **THE SMOOTHED FLOOR** — a bout on HUSH's terms: resonance OFF, raw hits
   worthless, three rung-backs to win. Spacing and timing, nothing else.
   This room decides whether the rival duels will feel good.

## What to feel for (bring notes)

- Does the parry window (130 ms) feel generous or cruel?
- Does hood-stealth read — do you *feel* quieter, does the dummy calming
  down land?
- Is the count-in door forgiving enough at fast and slow tempos?
- Is the muted room fun with everything subtracted, or just empty?

## Tuning knobs

- Movement/strike/noise: constants at the top of `scripts/skip.gd`
- Dummy timing/windows: constants atop `scripts/test_pressing.gd`
- Door strictness: `GAP_MIN/GAP_MAX/EVENNESS` in `scripts/refrain_door.gd`
- All SFX are synthesized in `scripts/audio_bank.gd` — no assets anywhere

## Housekeeping

M0's bell-era files (`clapper.gd`, `toll_wave.gd`, `resonant_plate.gd`,
`room_dry.gd`, `room_waist.gd`) were moved to `mtrdvn/_to_delete/` — delete
that folder whenever. Their replacements live here under Dead Wax names.
