# Dead Wax agent notes

Dead Wax is a Godot 4.7 2D metroidvania: 21 authored campaign rooms across the
Label, the Overture and the first loop of the Unplayed, on the GL
Compatibility renderer. Everything is built from code at runtime and all audio
is synthesized. The rest of the planned 53-room world is development
scaffolding.

Keep this file short. Coding agents only read the first part of it (Codex reads
32 KiB by default), so detail belongs in `docs/ARCHITECTURE.md`, not here.

## Read first: the design canon

- `docs/` holds the design canon the game is built from: `PITCH`, `WORLD`,
  `MAP`, `CAST`, `STORY`, `ENEMIES`, `PUZZLES`, `COMBAT_FEEL`, `PROGRESSION`,
  `BRAINSTORM` and the art direction pages in `docs/art/`. `docs/README.md`
  says which document is truth for what, lists the laws most often broken by
  accident, and keeps the **canon status table**: every known difference
  between the build and the canon, with its decision.
- Code and tests are the truth for how the game behaves today; `docs/` is the
  truth for what it is meant to be. If your change would contradict a canon
  document, or you notice a difference the status table doesn't list, stop and
  say so in your handoff. Don't quietly pick a side, and don't edit the canon
  documents to match the code unless the user asks.
- Non-negotiables. `tests/canon_test.gd` enforces the ones a script can check.
  - Nobody in-world says "needle" or "stylus". The world calls the role *the
    Player*; Skip's weapon is his *point*. Old save keys and item ids
    (`needle`, `glass_needle`, `copper_stylus`, …) stay as ids and are never
    shown to the player.
  - Skip has no mouth, ever.
  - `Press.PINK` means sound being heard right now (strikes, your noise, the
    shatter's words) and is never decoration; use `Press.ACCENT` for
    decoration. `Press.GOLD` is her, about six uses in the whole game. Only
    `scripts/press.gd` defines `PINK` or `GOLD`.
  - The parry: 100 ms window and +0.40 resonance for every enemy that rings.
    It is pure profit and must never pay less off the beat.
  - Combat is percussion. Telegraphs are heard first. Noise is aggro. Mercy
    costs time, not health. Freed and shattered stay that way. No victory
    fanfare; the shatter speaks its last words.
  - Abilities are placed, guaranteed finds. Randomness only buys optional
    expression and never blocks progress.
  - The Tonearm never swings first.
  - Register law (`CAST.md`): the Bootlegger, the liner-book, Tick and the
    Typesetter carry the mania; the Engineer, HUSH and Soon play it straight.
- Open decisions. Don't build further in these directions until the user
  settles them; the status table has details.
  - **Art direction.** The build's "Quiet Wax" look against the locked dense,
    grungy direction in `docs/art/direction.html`, to be settled by a
    side-by-side test of one room. Until then: no new panorama, material,
    lighting or atmosphere passes, and no wholesale restyle either.
  - **The beat.** Planned next: a world groove clock, Tap → Sweep → Accent on
    consecutive beats with the Accent heavy only in the pocket, and Auditioners
    that wake on noise rather than distance. Partly built on 9 October as the
    Groove pressure setting, off by default: a room beat clock, heavy strokes
    only in the pocket, counts that tick on the beat. Whether it becomes the
    default is the user's call.
  - **Progression.** Echo Trials and equipment are frozen: fix bugs, but add no
    pieces, hunts, currencies or ledgers. Cuts replace them later
    (`docs/PROGRESSION.md`).
  - **Growth.** XP and levels were added on 9 October at the user's request:
    hits, parries and kills pay XP, and each level buys Ring, Body or Bite in
    the Book. Canon growth is GAIN, fed by shine at the Bootlegger and paid for
    with a louder crackle floor (`docs/PROGRESSION.md`), and a level-up's chime
    and ring may be the fanfare law 9 rules out. Don't extend XP until the
    user reconciles the two.
- Scope: tune one enemy (the Auditioner) and one boss (the Tonearm) to the full
  `COMBAT_FEEL.md` target before adding roster.

## Work and verification

- Play with `.\deadwax.cmd play`, or open the folder in Godot 4.7.x and press
  F5. `.\deadwax.cmd dev` (Godot user argument `-- --dev-rooms`) opens the five
  original mechanics rooms and the planned-world graybox atlas.
- Before handing off code changes, run `.\deadwax.cmd check`. It imports
  resources and then runs every suite in the list in `tools/deadwax.ps1`,
  starting with `tests/canon_test.gd`. CI runs the same suites from
  `.github/workflows/godot-checks.yml` on a pinned, checksum-verified Godot
  4.7.1. When you add a suite, add it to both lists.
- Without the Windows wrapper: `godot --headless --path . --import`, then
  `godot --headless --path . --script res://tests/<suite>.gd` for each suite.
- Timing, audio, rendering and controller feel stay manual. After gameplay
  changes, follow `PLAYTEST.md`.
- Exits can warn about leaked `AudioStreamWAV` / `AudioStreamPlaybackWAV`
  instances. That is upstream
  [godotengine/godot#76745](https://github.com/godotengine/godot/issues/76745)
  and doesn't fail a suite.
- There is no `export_presets.cfg`; the project isn't set up for distributable
  builds yet.

## Conventions

- GDScript: tabs, `snake_case` names, typed signatures and variables,
  `UPPER_SNAKE_CASE` constants. Preserve the `.gd.uid` sidecars.
- Keep gameplay tuning in the constants grouped at the tops of scripts.
- Preserve the GL Compatibility renderer. Shaders stay canvas-only, with no
  screen-texture or backbuffer reads and no `TIME`.
- Presentation never drives gameplay. Animation, lighting, atmosphere and HUD
  read explicit snapshots; they never move colliders, change combat timers or
  own state. Decoration never adds collision or changes routes or rewards.
- Main owns persistence, transitions and encounter outcomes. Menus and Book
  pages emit intents only. Saves are validated, staged and rolled back on a
  failed write, restoring never replays rewards, and older saves must keep
  loading.
- Write player-facing text in the game's voice and check it against the canon
  nouns and the register law before committing.

## Where things are

- `docs/ARCHITECTURE.md`: the detailed system notes that used to live here —
  rooms, atmosphere, lighting and materials, figures and residents, saves and
  menus, abilities, collection and trials, map, controller support, B-side
  exploration, Lost Pressings, Groove pressure, levels and XP, and the small
  animated moments — and the regression-sensitive behaviour each
  suite locks. Read the section for a system before changing it.
- `scenes/main.tscn` → `scripts/main.gd` builds the input map, player, camera,
  HUD, audio, menus and rooms at runtime, so an empty editor viewport is
  expected.
- `scripts/press.gd` owns the visual language (plates, type, colours) and
  dispatches the pure `press_*.gd` drawing helpers.
- `scripts/campaign.gd` registers the 21 authored rooms through
  `chapter_one/two/three.gd` and `room_opening.gd`, `room_overture.gd` and
  `room_unplayed_campaign.gd`.
- `data/world_map.json` (schema v2) is the 53-room plan, read by
  `scripts/world_map.gd`. No tool writes it.
- `scripts/audio_bank.gd` synthesizes every sound.
- `README.md` is the player-facing overview, `PLAYTEST.md` the manual checks
  and `ROUTING.md` the routes and atlases. Controls are listed in
  `README.md` and `docs/ARCHITECTURE.md`.
