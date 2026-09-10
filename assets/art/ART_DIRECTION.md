# The painted world

The September 2026 graphics overhaul follows the chosen direction: a rich,
hand-drawn world with textured scenery, expressive characters, and dramatic
colour and light. Gouache-like distance and pencil contours meet cream wax,
deep petrol cloth, aged brass, copper, and warm coral notes.

## Production paintings

These original PNG assets were generated for Dead Wax using the built-in
OpenAI image generation tool on 2026-09-10. No image-generation CLI, external
asset pack, or runtime service is used. The four generated originals are
stored here at their original resolution, with Godot import settings beside
them. Font licensing remains in `assets/fonts/`.

| Asset | Resolution | Use |
| --- | --- | --- |
| `label-district.png` | 2172 × 724 | The Label, title and journal surroundings |
| `overture-interior.png` | 2172 × 724 | Overture halls, stair and stall surroundings |
| `overture-shaft.png` | 724 × 2172 | The Well and Drop's vertical distance |
| `unplayed-district.png` | 2172 × 724 | The Landing, Verse Hall, Warrens and Deep Gallery |

The runtime crops each painting to cover the room's distant plane. It never
stretches an image independently on its axes. Each room adds its own colour
glaze, drawn architectural details, cloth, fixtures, and clipped material
marks. Camera parallax moves the cached far plane. These paintings describe
distant architecture; only the crisp, outlined foreground surfaces are solid.

Gameplay distance is deliberately quiet: the paintings use 52% opacity on
dark stock, a stronger room-colour tint, and a 24% stock glaze. Light stock
uses 24% opacity and a 32% glaze. This pushes small painted details behind the
actors and walkable edges. Repeated background arches, windows, cables,
record rims and motes are sparse; the main room landmarks retain their shape.

Platform faces use subdued joints and broken brush marks, with a small
stock-coloured fade at their lower edges. Their thin walkable lips stay clear.
Only world platforms opt into the fade; shared menu plates stay opaque.
Room ambient light and all lamp outcomes are dimmed by 14%. A broad, static
vignette on the existing paper sheet joins the edges of the view; it sits
below the HUD and menus, which retain their full contrast. No screen sampling
or extra render pass is used, and geometry remains unchanged.

## Prompt set

All four used the stylized-concept use case and requested a finished game
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

**Unplayed district.** Exact production prompt:

> Use case: stylized-concept. Asset type: a finished distant panorama background painting for the 2D side-view game Dead Wax, 3:1 very wide composition. Primary request: richly hand-drawn underground record-world called The Unplayed, a new district beneath a music hall. Scene: ancient wax chambers and intimate vaulted record archives, towers of enormous worn vinyl discs, hanging copper speaking tubes, crooked empty alcoves, distant narrow stone bridges, faint blank manuscript ribbons, enormous quiet record vaults dissolving into haze. Palette: deep indigo and muted violet/plum wax, blue-grey shadow, verdigris copper, tiny amber lamps, subdued parchment highlights. Medium: tactile traditional gouache and coloured pencil illustration, visible brushed pigment, worn edges, hand-drawn contours, atmospheric depth, lovingly detailed but very low-contrast central space. Lighting: melancholy stillness, warm light pooled in distant niches and cool lavender mist; no blinding bright center. Composition: side-elevation theatre panorama with varied architecture across entire width, lower quarter dark mist; no close foreground ground, no playable-looking crisp ledges. NO characters, text, letters, UI, logos, watermark, borders, pixel art, 3D render, perspective road, or modern real-world props. This is production artwork to sit BEHIND separately drawn playable platforms and characters.

## Runtime artwork

`Press` remains the public drawing vocabulary. `press_painted_world.gd`
caches the four textures; regional depth helpers and `press_world_brush.gd`
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

The subsequent Unplayed expansion passed all 27 native suites (7,573 checks),
including the fourth painting's import, scenery, lighting, map, and checkpoint
coverage. A separate native physics fixture passed 40 traversal checks without
Gather, including the complete Drop return climb and both multilevel rooms.
Native GL Compatibility review covered all six new rooms at 1280 × 720,
the Arm's new passage and North Warren at 960 × 540, three map pages at both
sizes, and the Gallery's reduced-motion A→B→A restoration. Reviews used isolated
saves. The added painting and code-drawn landmarks remain presentation only.

The quieter-background pass also passed all 27 suites (7,573 checks). Native
review compared the old and new Verse Hall and North Warren, checked the
Headshell, Well, HUSH, title and opening, and verified reduced-motion A→B→A
restoration in the Gallery at 960 × 540. Only the presentation helpers changed.

The foreground/vignette pass passed the full 27 suites (7,573 checks) on rerun.
The initial run reported a map held-confirm check failure; an isolated map run
and the full rerun passed without input-code changes. Final scenery and GUI
checks also passed after restricting the lower-edge fade to world platforms.
Native GL review covered the Headshell, Verse Hall, Well, HUSH, North Warren,
Gallery A→B→A at 960 × 540, and the opaque title menu using isolated saves.
