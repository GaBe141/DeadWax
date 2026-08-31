# Dead Wax agent notes

## Project

- This is a Godot 4.7 2D prototype using the GL Compatibility renderer.
- `scenes/main.tscn` is the entry point. `scripts/main.gd` creates the input map, player, camera, HUD, audio, and five rooms at runtime, so an empty editor viewport is expected.
- Existing audio is synthesized in `scripts/audio_bank.gd`; there are no external audio assets or third-party dependencies.
- `scripts/press.gd` owns the entire visual language — plates, stock, the paper sheet, the type case, and signage cards. Rooms author `ink` and `bg_color` and nothing else about how they look; anything that needs a new surface or a new size of type adds it to the press rather than styling in place. The press reads no gameplay state: colours arrive as arguments.
- `assets/fonts/` (Big Shoulders for display, IBM Plex Mono for body) and `assets/shaders/` are the project's only non-code assets. Both fonts are SIL OFL and their licences ship beside them; keep those files together. Audio remains fully synthesized.
- Shaders must stay GL Compatibility-safe: canvas shaders with UV/FRAGCOORD maths only, no `hint_screen_texture` or backbuffer reads. Plates carry ink, stock, and accent as shader parameters rather than a flat fill, so tests read colour via `get_shader_parameter`, not `ColorRect.color`.
- `data/world_map.json` version 2 separates notable route `kind`, progression `requires`, and `direction`. Keep planned rooms non-overlapping and the contact/special graph connected; routing health is locked by smoke tests.
- `scripts/world_map.gd` is the runtime reader for that plan: topology and presentation only, no gameplay. Its contact resolution mirrors the model the smoke suite locks — a declared special replaces the open contact for that pair, and a one-way special is never walked back from its target.
- `scripts/room_graybox.gd` builds a traversable shell for any planned room: 600x360 px per grid cell, stratum palette and air, one passage per planned route, one `from_<room>` arrival per inbound route. Climb rungs are sized under `SkipScript.JUMP_VELOCITY`'s rise so no graybox needs a Refrain to cross itself; keep that property when tuning either side.
- Main owns two atlases. `_load_room(index)` keeps the five hand-built prototype rooms; `_load_world_room(id)` grays in a planned room, and `world_room_id` is non-empty exactly while one is live. Hand-authored rooms always win — replace a graybox by writing a room script that claims its id. Planned ids must never shadow a prototype id.
- Refrains are the only reward a graybox grants, and they sit on a plinth clear of the spawn and of every arrival anchor. A pickup within `COLLECT_RADIUS` of an arrival would hand over a permission for merely entering and unseal the shortcuts leading there.
- `scripts/progression_state.gd` is a Main-owned, session-only progression model. Main injects it into rooms and the player; do not replace it with an Autoload until real scene transitions or disk saves require longer-lived ownership.
- Core verbs are never permission-gated. Knowledge techniques are journal/discovery state only. Earned Refrains may alter traversal; Gather derives an effective breath capacity with `max(room capacity, 1)` and must not mutate room `air_density`.
- `scripts/pressing_state.gd` is a Main-owned, session-only model of which side of the wax is face-up and how much of that side is left. Rooms author their A-side only; the B-side is the same room re-presented, never a duplicate. On the A-side every derived value must equal the room's authored value, so nothing changes for a player who never flips. Turning over must not mutate a room's authored `air_density`, `bg_color`, or `ink`.
- Flipping is gated by the Jump-Cut Refrain and is silent without it — an unearned Refrain is never announced before it is found. A groove carries a `side` and leaves the `live_groove` group entirely when its face is down, so no strike path has to re-check sides. `muted` is one-sided: HUSH only burnished the face that was up.
- `scripts/room_exit.gd` presents passages, and rooms forward semantic target/entry IDs through `room_base.gd`. `main.gd` alone performs deferred transitions and stores the active entry for R/death respawns. Preserve that ownership boundary.
- `scripts/inventory_menu.gd` is a full-screen, read-only view over Main's progression/player state. It may pause the tree but must never own or mutate progression, Shine, rooms, or saves. Refresh on open because snapshot restoration intentionally emits no signals.

## Work and verification

- Open this directory as a Godot project and press F6/F5 as appropriate. Use F5 for the full prototype.
- Before handing off code changes, run `.\deadwax.cmd check`. It imports resources and runs the dependency-free native smoke suite in `tests/smoke_test.gd`.
- The smoke suite covers resource loading, world-map invariants, all five room boots, and required inputs. After gameplay changes, also follow `PLAYTEST.md`; timing, audio, rendering, and controller feel remain manual.
- There is no `export_presets.cfg`; this repository is not yet configured for distributable builds.
- Runtime controls are defined in `scripts/main.gd`: A/D or arrows move, Space jumps, J/X strikes, hold K/C raises the Hood, hold L kneels/Sets, F/right shoulder flips the pressing, E/gamepad Y enters passages, I/gamepad Start opens The Book, and R respawns at the active entry. Tab cycles rooms, M toggles the grayed-in planned world, and G grants every Refrain for feel-testing — all three only in debug builds.
- Follow the existing GDScript conventions: tabs, `snake_case` names, typed signatures and variables, and `UPPER_SNAKE_CASE` constants. Preserve `.gd.uid` sidecars.
- Keep gameplay tuning in the constants already grouped near the tops of the relevant scripts.
- Preserve the GL Compatibility renderer unless a task specifically requires a renderer change.

## Handoff caveats

- The transferred README says M1, four rooms, and a 130 ms parry window. The implementation includes partial M2 tuning, five rooms (including The Verse), and a 100 ms parry window. Treat code as the current behavior and call out this drift when editing documentation or tuning.
- `ENEMIES.md` is referenced in `scripts/auditioner.gd` and `scripts/room_verse.gd`, but it was not included in the transferred archive. Do not invent rules attributed to it; recover it from the former workspace or remote if it exists.
- Git history, Claude workspace instructions/history, license information, and export settings were not present in the transferred archive.
- Godot 4.7.1 command-line exits can warn about one leaked `AudioStreamWAV` and one `AudioStreamPlaybackWAV` while the crackle loop is active. This matches confirmed upstream issue [godotengine/godot#76745](https://github.com/godotengine/godot/issues/76745) and does not fail the smoke suite.

## Regression-sensitive behavior

- The muted dummy never builds resonance. Its third successful parry emits `bout_won` without also emitting `shattered`.
- Player pogo reach intentionally matches enemy strike-hit reach at 120 px, so every pogo is also a confirmed hit.
- The native smoke suite locks both invariants; keep those regression checks when tuning combat ranges or outcomes.
- Progression regressions cover idempotent unlocks, snapshot restore, Gather's one dry breath, environmental capacity preservation, pickup persistence, and room recreation. Keep the distinction between environmental air and Gather when extending Refrains.
- Routing regressions cover the five-room bidirectional loop, Gather gate, named-entry respawns, transition ownership, world-map overlap/connectivity, route schema, dead-end budget, and stratum packing density.
- Inventory regressions cover full-screen anchoring, truthful slot counts, hidden names, live/silent refresh, unique input bindings, pause restoration, transition exclusion, gameplay suppression, and room-to-room persistence.
- B-side regressions cover the A-side presenting rooms exactly as authored, density and breaths inverting on the far face, a nearly spent side refusing to be turned, a spent side lifting the needle once by itself, grooves leaving and rejoining `live_groove` per side, ink and paper trading places and back, the burnished floor ringing only on its far face, and Main's flip staying inert without the Jump-Cut.
- Grayed-in world regressions cover the loader's contact model (one route per neighbour, canonical sides, real shared edges, one-way asymmetry, no id shadowing), every planned room booting with passages matching the plan and arrivals resolving on the far side, Refrain seals present and technique requirements never sealing, plinths clear of every arrival, climbs reachable on legs alone, and a Headshell walk that still reaches all 53 rooms and earns every Refrain.
