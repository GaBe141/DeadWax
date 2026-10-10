# Dead Wax — design canon

These are the design documents the game is built from. They were written in
August 2026, before and alongside the first prototype, and were left out of
the original repository handoff, which is why older agent notes said
`ENEMIES.md` was missing. They are here now. Read the relevant one before you
build instead of guessing.

**Code and tests are the truth for how the game behaves today. These documents
are the truth for what it is meant to be.** When the two disagree, check the
status table at the bottom. A difference is either already known, with a
decision attached, or it is new — in which case say so in your handoff rather
than quietly picking a side. Don't edit these documents to match the code
unless the user asks for it.

## Which document is truth for what

| Question | Document |
|---|---|
| What is this game, in one page? | `PITCH.md` |
| What is the world, its physics, its vocabulary? | `WORLD.md` |
| Where does a room sit, and what gates what? | `MAP.md` and `map.html` (the lore map). `../data/world_map.json` is the room truth. |
| Who is anyone, how do they talk, what do they want? | `CAST.md` |
| What happens, in what order, and what may be spoiled when? | `STORY.md` |
| How does an enemy behave, and how is it beaten *or freed*? | `ENEMIES.md` |
| What may a puzzle ask of the player? | `PUZZLES.md` |
| How is fighting supposed to *feel*, and to what numbers? | `COMBAT_FEEL.md` |
| How does the player grow, and what may be random? | `PROGRESSION.md` |
| What does it look like, and why? | `art/direction.html`, with the proofs `art/cutaway.html`, `art/style_compare.html` and `art/tier_compare.html` |
| Why is anything the way it is? | `BRAINSTORM.md` (raw notes, lowest authority) |

`COMBAT_FEEL.md` owns combat identity and tuning targets; `ENEMIES.md` owns
per-enemy behaviour and the four combat laws. Where they disagree on a number,
the combat-feel value is the later one.

`PROGRESSION.md` was rebuilt on 2026-08-25 from the decision record after the
2026-08-09 original was lost. Its provenance and six open questions are stated
inside it. Don't infer answers to those questions.

## The laws most likely to be broken by accident

1. **Nobody in-world says "needle" or "stylus".** The world calls the role
   *the Player*; Skip's weapon is his *point* ("Hold still, little point").
   "Needle" is Hornet's weapon in Silksong, dodged on purpose. Old save keys
   may keep their ids; nothing the player reads may. (`CAST.md`, `PITCH.md`,
   `BRAINSTORM.md` round 6; enforced by `../tests/canon_test.gd`)
2. **Skip has no mouth, ever.** Freed people get mouths; Skip doesn't.
   (`CAST.md`, `art/direction.html`)
3. **Combat is percussion.** On-beat hits land harder; off-beat is about 0.6×
   and *sounds* flat. "If a fight could be muted and play identically, we've
   lost the identity." (`COMBAT_FEEL.md`)
4. **The parry is the heart.** 100 ms window, +0.40 resonance, pure profit.
   Never make it pay less, and never gate it on the beat. (`COMBAT_FEEL.md`;
   enforced by `canon_test.gd`)
5. **Telegraphs are heard first, seen second.** (`ENEMIES.md`, law 1)
6. **Noise is the aggro economy.** Enemies wake on crackle inside a hearing
   radius, not on distance alone. (`ENEMIES.md`, law 2)
7. **Mercy costs time, not health.** (`ENEMIES.md`, law 3)
8. **Cleared or freed rooms stay clear.** (`ENEMIES.md`)
9. **Winning is never triumphant.** No fanfare. The shatter speaks its last
   words, and that is all. (`COMBAT_FEEL.md`)
10. **Traversal is never random.** Abilities are placed, guaranteed finds.
    Randomness only buys optional expression and never blocks progress.
    (`PROGRESSION.md`)
11. **Pink means sound being heard right now. Gold means her.** Pink is never
    decorative; etch gold appears about six times in the whole game.
    (`art/direction.html`; `Press.PINK` and `Press.GOLD` in
    `../scripts/press.gd`; enforced by `canon_test.gd`)
12. **Boil is state.** Freed 4 frames, Stuck 2, machines 0. (`art/direction.html`)
13. **The Tonearm never swings first.** (`CAST.md`; locked by
    `../tests/tonearm_test.gd`)
14. **Register law.** The Bootlegger, the liner-book, Tick and the Typesetter
    carry the mania; the Engineer, HUSH, Soon and everything inside a Rite
    play it straight. Comedy never touches the last bar. (`CAST.md`)

## Scope reminder

`COMBAT_FEEL.md` closes with a scope flag: tune exactly **one enemy (the
Auditioner) and one boss (the Tonearm)** to the full feel target before
building more roster. Both exist now. Neither has the beat by default yet;
with the opt-in Groove pressure setting, the Tonearm's count ticks on the room
beat.

## Canon status — where the build differs

As of 2026-10-10, when the canon pass from branch `claude/canon-step-1` was
merged onto `main` together with the work of 9–10 October.

| Area | Canon | Build | Status |
|---|---|---|---|
| In-world nouns | Nobody says needle or stylus | 27 player-facing strings did | **Fixed.** Locked by `canon_test.gd`. |
| Equipment slots | Cut homes are POINT / SLEEVE / PARRY | Needle / Lining / Charm | **Renamed on screen** to Point / Sleeve / Charm. Save keys (`needle`, `lining`, `charm`) and item ids are unchanged. |
| Skip's face | No mouth | A mouth line | **Fixed.** |
| Parry payoff | +0.40 resonance | Auditioner 0.40, Test Pressing 0.35 | **Fixed:** 0.40 for every enemy that rings. Locked by `canon_test.gd`. |
| Shatter-words | The shatter speaks | Hidden in the campaign since 2026-10-02 | **Fixed:** back in the campaign (still off in Move practice). |
| Colour meaning | Pink = heard; gold = her | Several "PINK" constants held copper or gold | **Fixed:** one `PINK` (#E5407F) only where sound is heard; decoration uses `Press.ACCENT`; one `GOLD` (#D9A441) with a budget of six. Locked by `canon_test.gd`. |
| Art direction | Dense and grungy, scratchy boil, ink on paper above the Scratch, scratchboard below | "Quiet Wax": sparse, dark, soft washes, material shaders and light shafts | **Open decision.** To be settled by a side-by-side test of one room. Until then, push the look no further in either direction. |
| Boil is state | 4 / 2 / 0 frames by soul state | A uniform ~10 fps jitter on Auditioners and Test Pressings only | Open; follows the art decision. |
| Two-world ink | Paper above the Scratch, scratchboard below | The Label is dark; the B-side flips to paper | Open; follows the art decision. |
| Skip's silhouette | Jagged head, void-almond eyes, one chunky boot, tape-wrapped point, 45-sleeve hood | A teardrop hood figure | Open; follows the art decision. |
| The beat | A world tempo; off-beat about 0.6× | By default none: a heavy hit is the third strike of Tap → Sweep → Accent. The Groove pressure setting (9 Oct, off by default) adds a room beat clock while a foe is roused: strokes in the pocket (100 ms either side of a centre set 40 ms after the beat) are heavy, the Accent only there, others flat and quieter, and counting foes tick on the beat. | **Next.** Groove clock, with the chain on consecutive beats and the Accent heavy only in the pocket. The chain's 650 ms link window is already one beat at 92 bpm. Groove pressure covers the clock and the pocket, not the chain on consecutive beats; whether it becomes the default is open. |
| Hearing | Noise wakes enemies | Auditioners wake on distance (shorter when hooded) | **Next**, with the beat. |
| Telegraph lead | Heard first | Per-enemy tells, no shared lead time | Open. |
| Combat constants | One source of truth | Auditioner heavy-hit resonance is `RES_HIT × 1.6` (0.224); Test Pressing uses 0.24 | Open; unify with the beat work. |
| Progression | Cuts: skill-scaled odds, the audit, three homes | Echo Trials: flat 4/3/2/1 % odds, hard pity at 20 clears, Offcuts, a 100-clear mastery ledger per region | **Frozen.** Fix bugs only; add no pieces, hunts, currencies or ledgers. Convert to Cuts after the fight feels right (M3). The saved RNG, pity and rollback plumbing is reusable. |
| Growth | GAIN: about 12 notches fed by shine and spent at the Bootlegger, buying Ring, Body, Breadth and Bite (capped); it raises the crackle floor, and taking souls is audited | XP and levels (9 Oct, at the user's request): hits, parries and kills pay XP (freeing pays nothing; story foes have a lifetime budget, Echo Trial copies don't); eleven picks of Ring, Body or Bite in the Book; no Breadth, no crackle-floor cost, no audit | **Open.** New since the canon pass; for the user to reconcile with GAIN. Don't extend it meanwhile. |
| Winning | No fanfare; the shatter speaks its last words, and that is all | A level-up, often straight after a shatter, plays a quiet freed chime and rings out around Skip and on the HUD (10 Oct, at the user's request) | **Open.** Whether a level-up counts as fanfare is the user's call. |
| Register | The Bootlegger, Tick and the liner-book carry the mania | Everyone speaks in the same quiet voice | Open. Rewrite lines from the voice samples in `CAST.md`. |
| The Hound | Death itself: carries Skip back to the last cue point | A friendly patroller; a plain respawn | Planned (small). The recovery messages already credit the Hound. |
| Opening | — | 45 one-pixel taps before Walk | Playtest with someone who hasn't seen it. |

## Holes that remain

- **The atlas tooling lives outside this repo.** `../data/world_map.json`
  (schema v2) is the room truth, and no tool may write it. The read-only
  renderer prepared in August (`tools/render_atlas.py`) has not landed here.
- **`art/cutaway.html` is generated.** Its source, `tools/build_cutaway.py`,
  lives in the original design folder, not in this repo.

`docs/.gdignore` keeps Godot from importing this folder.
