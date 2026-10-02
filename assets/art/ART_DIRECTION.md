# The drawn world

The current direction is a quiet illustrated world with expressive characters
and dramatic colour and light. Broad, authored architectural shapes and soft
colour washes meet cream wax, deep petrol cloth, aged brass, copper and warm
coral notes. Distance has generous negative space; texture and fine outlines
belong mainly to the nearby characters and usable surfaces.

## Quiet distance

The October 2026 background pass replaces the detailed generated panoramas
with authored Canvas drawing in `scripts/press_distance.gd`. The Label has
uneven roof groups and empty acoustic chambers; Overture has broad hall piers
and vaults; the Well and Drop have continuous shaft faces; the Unplayed has
low, wide chambers. Verse Hall's single recessed bay gives the long walk scale
without a highlighted rim, sill or apparent playable edge.

Each composition uses a handful of filled shapes and continuous vertex-colour
washes. Values derive from the supplied room ink and stock, with no fixed
raster tint. Regional helpers retain only a few room landmarks and remove
repeated windows, masonry joints, pipe collars and small ornaments. Existing
horns, cradles, doorways, the Landing spindle and the Gallery's empty chairs
carry the identity of the space. The organ impressions use five broad pipes.

`press_painted_world.gd` keeps its shared entry point for rooms, menus and the
opening, delegating drawing to the new helper. Runtime distance never loads a
painting. The far plane remains cached, with the existing middle-plane motion,
parallax, palette restoration, pause and Reduced motion rules. The still room
air, dim lighting and vignette continue to join the layers. There is no new
shader, collision, background floor, gameplay state or runtime dependency.

## Archived production paintings

These original PNG assets were generated for Dead Wax using the built-in
OpenAI image generation tool on 2026-09-10. No image-generation CLI, external
asset pack, or runtime service is used. The four generated originals are
stored here at their original resolution, with Godot import settings beside
them. Font licensing remains in `assets/fonts/`.

| Asset | Resolution | Original use, now archived |
| --- | --- | --- |
| `label-district.png` | 2172 × 724 | The Label, title and journal surroundings |
| `overture-interior.png` | 2172 × 724 | Overture halls, stair and stall surroundings |
| `overture-shaft.png` | 724 × 2172 | The Well and Drop's vertical distance |
| `unplayed-district.png` | 2172 × 724 | The Landing, Verse Hall, Warrens and Deep Gallery |

The September implementation cropped these paintings into the distant plane,
then reduced their opacity and added room-colour glazes. Their small details
still dominated the game view, prompting the replacement above. The original
files and Godot import settings remain together for provenance; the import
checks continue to validate them as an archive.

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

`Press` remains the public drawing vocabulary. `press_distance.gd` draws the
authored far compositions; regional depth helpers and `press_world_brush.gd`
draw the room-specific middle distance and platform faces. `figure_paint.gd`
provides rounded limbs, coloured planes, and brush marks for the animated
cast. The original poses and combat clocks remain authoritative.

The Quiet Wax figure refinement keeps the same cast and drawn animation.
Broader wax shadows, worn cloth planes, restrained edge light, and broken
brass highlights join the figures to the dim rooms. Skip's angular
mask and quieter eyes sit above exposed, shaped feet; the raised Hood keeps
a shaped face opening. Residents have clearer coat folds and grounded joints,
the Hound has layered wax and mechanism planes, and enemy/boss materials use
the same subdued contours. Fine texture stays secondary to the silhouette at
normal game size. These are draw-only changes: colliders, reach, pose clocks,
combat tells, rewards, and interaction origins retain their existing rules.

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

The Quiet Wax figure refinement passed all 49 native suites (11,834 checks)
on 2026-10-02. Native GL captures reviewed the player at rest, running,
jumping, Set, Hood and all three strikes at 1280 × 720 and 960 × 540,
with separate cast sheets on light and dark stock. World captures used
isolated checkpoints; both-direction player detail sheets used explicit
poses. No character assets, physics, combat clocks, or save fields changed.

The October quiet-distance replacement passed all 49 native suites (11,834
checks) on 2026-10-02. Native GL captures reviewed all 21 rooms at 1280 × 720,
the Well and Drop at three heights, and selected streets, bosses and the Gallery
through A→B→A at 960 × 540. Title and all four opening shots were reviewed at
both sizes; the Book and restored Addie doorway were checked at 960 × 540.
World reviews used isolated checkpoint paths. The changes are confined to
pure drawing helpers; geometry, lighting placement, save schema and gameplay
timing are unchanged.
