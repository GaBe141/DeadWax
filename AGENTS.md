# Dead Wax agent notes

## Project

- This is a Godot 4.7 2D prototype using the GL Compatibility renderer.
- `scenes/main.tscn` is the entry point. `scripts/main.gd` creates the input map, player, camera, HUD, audio, and five rooms at runtime, so an empty editor viewport is expected.
- Existing audio is synthesized in `scripts/audio_bank.gd`; there are no external audio assets or third-party dependencies.
- `data/world_map.json` contains valid world-planning data for 53 rooms, but the current runtime does not load it.

## Work and verification

- Open this directory as a Godot project and press F6/F5 as appropriate. Use F5 for the full prototype.
- Before handing off code changes, run `godot --headless --editor --path . --quit` to import assets and catch script parse/load errors.
- There is no automated test harness or `export_presets.cfg`. After gameplay changes, manually smoke-test all five rooms with Tab and use R to restart each room.
- Runtime controls are defined in `scripts/main.gd`: A/D or arrows move, Space jumps, J/X strikes, hold K/C raises the Hood, hold L kneels/Sets, R restarts, and Tab changes rooms. Gamepad mappings are defined there too.
- Follow the existing GDScript conventions: tabs, `snake_case` names, typed signatures and variables, and `UPPER_SNAKE_CASE` constants. Preserve `.gd.uid` sidecars.
- Keep gameplay tuning in the constants already grouped near the tops of the relevant scripts.
- Preserve the GL Compatibility renderer unless a task specifically requires a renderer change.

## Handoff caveats

- The transferred README says M1, four rooms, and a 130 ms parry window. The implementation includes partial M2 tuning, five rooms (including The Verse), and a 100 ms parry window. Treat code as the current behavior and call out this drift when editing documentation or tuning.
- `ENEMIES.md` is referenced in `scripts/auditioner.gd` and `scripts/room_verse.gd`, but it was not included in the transferred archive. Do not invent rules attributed to it; recover it from the former workspace or remote if it exists.
- Git history, Claude workspace instructions/history, license information, and export settings were not present in the transferred archive.

## Known baseline issues

- In `scripts/test_pressing.gd`, the muted dummy's third successful parry can reach full resonance and emit `shattered`, then also emit `bout_won`. Keep muted-room victory and shatter outcomes mutually exclusive when this is fixed.
- `scripts/skip.gd` searches 150 px for pogo targets, while the enemy hit handlers accept strikes only within 120 px. At 121–150 px, the player can bounce without the target receiving the strike.
