# The painted world

The September 2026 graphics overhaul follows the chosen direction: a rich,
hand-drawn world with textured scenery, expressive characters, and dramatic
colour and light. Gouache-like distance and pencil contours meet cream wax,
deep petrol cloth, aged brass, copper, and warm coral notes.

## Production paintings

These original PNG assets were generated for Dead Wax using the built-in
OpenAI image generation tool on 2026-09-10. No image-generation CLI, external
asset pack, or runtime service is used. The three generated originals are
stored here at their original resolution, with Godot import settings beside
them. Font licensing remains in `assets/fonts/`.

| Asset | Resolution | Use |
| --- | --- | --- |
| `label-district.png` | 2172 × 724 | The Label, title and journal surroundings |
| `overture-interior.png` | 2172 × 724 | Overture halls, stair and stall surroundings |
| `overture-shaft.png` | 724 × 2172 | The Well's vertical distance |

The runtime crops each painting to cover the room's distant plane. It never
stretches an image independently on its axes. Each room adds its own colour
glaze, drawn architectural details, cloth, fixtures, and clipped material
marks. Camera parallax moves the cached far plane. These paintings describe
distant architecture; only the crisp, outlined foreground surfaces are solid.

## Prompt set

All three used the stylized-concept use case and requested a finished game
background rather than a screenshot. These are the production art briefs:

**Label district.** A wide 3:1, side-view distant panorama for a 2D game set
inside an enormous vinyl record. A crooked old town of stone and timber
record shops, shuttered arcades, wax roofs, brass gramophone towers and pipes.
Rich gouache and coloured pencil, tactile handmade contours, blue-green and
slate mist, sage, copper roofs, warm amber windows and a cream sky. Quiet and
melancholy. Varied silhouettes; flat side elevation, no perspective street.
Leave the bottom quarter in dark mist. No characters, UI, text, watermarks,
foreground floor, crisp playable ledges, pixel art or 3D rendering.

**Overture interior.** A wide 3:1 distant panorama of an abandoned underground
music hall inside an ancient record player. Immense stone vaults and acoustic
chambers, organ pipes, gramophone horns, copper machinery, distant balconies
and tiny lamps. Gouache and pencil with petrol teal, slate, verdigris, bronze
and honey gold. Varied arches and dusty roof beams; a flat theatre-set side
elevation and a dark misty bottom quarter. No foreground ground, characters,
text, UI, pixel art or 3D rendering.

**Overture shaft.** A tall 1:3 distant tapestry of a deep acoustic well,
presented in side elevation across many levels. Dark stone, copper organ
pipes, broken arches, record discs, moss seams and tiny honey lanterns.
Gouache and pencil texture. Keep the central third quiet and low contrast;
move from brass and pale upper glow toward navy haze below. Do not look up
or down a perspective hole. No foreground floor, ledges, characters, UI,
text or borders.

## Runtime artwork

`Press` remains the public drawing vocabulary. `press_painted_world.gd`
caches the three textures; regional depth helpers and `press_world_brush.gd`
draw the room-specific middle distance and platform faces. `figure_paint.gd`
provides rounded limbs, coloured planes, and brush marks for the animated
cast. The original poses and combat clocks remain authoritative.

Journal covers, signage and HUD use dark cloth, cream type and brass inlay.
Small groove housings, wax medallions, lanterns and passage arches use the
same palette. A/B reinking changes presentation without changing authored
colours, physics or rewards. Reduced motion holds ambient decoration and
parallax, while functional combat and conversation cues continue.

## Verification

The overhaul passed `deadwax.cmd check`: 26 native suites, 6,772 checks.
The final static-doorway redraw cleanup also passed the scenery and campaign
suites (342 and 422 checks). Native GL Compatibility captures covered all
fifteen authored rooms, the Well at several heights, the Stalls loft, both
palettes, and the new character poses. Menus and all four opening shots were
reviewed at 1280 × 720 and 960 × 540 using isolated saves. Timing and input
contracts are covered by the existing regression suites; controller and audio
feel remain part of the human checklist in `PLAYTEST.md`.
