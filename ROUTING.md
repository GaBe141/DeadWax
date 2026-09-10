# Dead Wax routing

## The authored opening

Normal play starts at a title screen, then loads the Headshell. The opening
registry contains eight rooms through the Overture Stair, followed by seven
more Overture rooms and six rooms beneath the Tonearm's seal. Every passage
stays inside the campaign's 21 authored rooms.

```text
HEADSHELL <-> HORN PLAZA <-> STALLS <-> YARD <-> DESCENT GATE <-> OVERTURE STAIR
                 |   |
           HIGH STREET <-> PRACTICE ROOM
```

The west branch returns through Practice to the plaza; the east route crosses
the market and the Yard before reaching the descent. The chapter uses exact
planned IDs: `headshell`, `horn_plaza`, `high_street`, `practice_room`,
`the_stalls`, `groove_yard`, `label_descent`, and `overture_stair`. The room
connections follow contacts in the plan, while their geometry is authored for
this opening rather than expanded from a grid cell.

`scripts/campaign.gd` combines the three chapter registries and rejects unfinished
destinations. `scripts/chapter_one.gd` owns the Label registry and factory;
`scripts/chapter_two.gd` owns the Overture registry and factory;
`scripts/chapter_three.gd` owns the six-room extension beneath the seal.
`scripts/room_opening.gd` authors geometry, encounters, named arrivals, and
the `objective_label` shown in the HUD. Its doorways emit semantic route
intent through `room_base.gd`. `Main` performs deferred transitions and keeps
`room_entry_id` for respawn and Continue. The former Overture endpoint now
leads into the Bootlegger's stall with a supported `from_bootlegger` return.
The final listening point is in the Arm, available after resolving the boss;
grounded E/Y emits `chapter_completed`. Main saves completion and presents the
ending matching the force or listening outcome.

Count-In locks are physical listening doors. Knowing the technique does not
open a door by itself, and an unrecorded player can still prove the pattern.
The High Street encounter has a quiet upper route, and the Yard's encounters
do not seal the passage. A missed market launch lands in a service lane with
short recovery steps. Every return staircase can be climbed with a plain jump.

## Campaign continuity

The Overture follows planned contacts:
`overture_stair ↔ bootlegger ↔ whistlers ↔ addie ↔ overture_well ↔ worn_gallery ↔ smoothed_floor ↔ the_arm`.
The additional `worn_gallery ↔ the_arm` contact is a shortcut released from
the Arm side. Forward access through HUSH requires `smoothed_floor/hush=won`;
the gallery shortcut requires `the_arm/gallery_shortcut=opened`. These are
encounter outcomes, never knowledge or Refrain permissions. Reverse passages
remain usable. Either Tonearm resolution also opens the Arm's eastern passage
into the authored Drop.

The authored return route adds `the_stalls ↔ worn_gallery`, using a loft
inside the existing Stalls room. Both ends require `the_stalls/loft_voice=freed`.
The loft's `from_worn_gallery` arrival is on the balcony; the Gallery's
`from_the_stalls` arrival is on its first arcade step. This campaign shortcut
is independent of the development atlas. The carried chart has 21 rooms and
24 undirected passage pairs; both shortcuts remain dashed. Its Label, Overture,
and Unplayed pages retain the full graph, with labeled region markers wherever
a real passage leaves the current sheet. Unvisited room names stay hidden.

Either Tonearm resolution reveals Gather at (1465,554), alongside an optional
practice shelf. Collection remains a deliberate world encounter, separate
from the ending marker. The Stalls balcony rises 200px above the right bank,
requires an airborne Gather strike, and has a safe floor below. The main
campaign route and its return stairs, including the new Unplayed loop, remain
traversable without Gather; the optional loft shortcut keeps its earned access.

`loft_voice.gd` presents a three-note call through Hood and accepts a fresh,
held Set during its silence. Two answers emit its single `freed` outcome.
Main saves that choice and enables the matching synthesized home melody in
the plaza and Headshell. Restoring a voice never replays the unlock or adds
currency. New Game clears the phrase with the other encounter choices.

`scripts/room_overture.gd` authors the seven new rooms. Both boss attempts
reset when Main recovers the player, while saved resolutions restore silently.
The Tonearm's strike, contact, and pogo origin is its grounded tip; its overhead
beam is visual architecture.

Main owns the progression model, checkpoint location, Shine, and encounter
outcome map. Chapter entities carry a stable `chapter_state_id`; saved keys
combine `room_id/encounter_id`. Opened doors, heard or shattered voices,
won encounters, and polished wax restore when a room is recreated.
`room_opening.gd::restore_encounters` applies these outcomes silently, without
granting knowledge or emitting fresh rewards.

`scripts/save_store.gd` validates the versioned checkpoint, installs completed
writes, and retains the previous valid checkpoint as a recovery backup.
Continue returns to the saved room entry, not an arbitrary mid-jump position.
The chapter persists across launches; the development atlases remain
session-only and do not overwrite its checkpoint.

## Beyond the open seal

The authored extension follows this reversible route:

```text
the_arm <-> the_drop <-> the_landing <-> verse_hall <-> verse_warren_n
verse_warren_n <-> deep_gallery <-> verse_warren_s <-> verse_warren_n
```

The lower loop has all three pairs: `verse_warren_n ↔ deep_gallery`,
`deep_gallery ↔ verse_warren_s`, and `verse_warren_s ↔ verse_warren_n`.
The Arm→Drop passage accepts either saved `the_arm/tonearm=freed` or
`the_arm/tonearm=shattered`. Its return arrives at `from_the_drop` in the Arm.
Neither this passage nor any new room requires Gather or the ending's
`completed` flag. The Arm's explicit listening marker still owns chapter
completion; traveling beyond the seal never shows that ending automatically.

`scripts/chapter_three.gd` registers the six new IDs and delegates their
construction to `scripts/room_unplayed_campaign.gd`. Each passage has a matching
`from_<room>` arrival. The Drop's maintenance steps rise 100 px, and the Warren
and Gallery stairs return to their upper doors on ordinary jumps. The Landing's
190 px Gather overlook is optional, with a listening post and no passage or
reward on its shelf.

The Hall and northern Warren use ordinary Auditioner encounters; the southern
Warren has a Test Pressing with a route above it. Their existing combat and
listening rules remain intact. Main persists their stable encounter keys;
recovery resets unfinished attempts and resolved actors retire silently.
Fixed listening posts own only their current line and give no progression or
Shine. The expansion introduces no checkpoint fields or Refrain pickup, and
the campaign's nine polish patches remain its income source.

The Drop retains its Scratch stratum heading while sharing the carried guide's
Unplayed page as the region's approach. This campaign route does not change
`data/world_map.json`: the 53-room development atlas keeps its original graph,
including its one-way Arm→Drop special.

## Development prototype loop

Run `.\deadwax.cmd dev` or pass `-- --dev-rooms` to Godot to enable these
mechanics rooms. They are separate from the 21-room campaign.

The five runtime rooms form one compact circuit:

```text
THE LABEL <-> PRACTICE <-> VERSE <-> UNPLAYED <-> SMOOTHED <-> THE LABEL
     \______________________________________________________________/
                 Label -> Smoothed requires GATHER
```

Every room has two physical passages and named arrival anchors. Press E or
gamepad Y while close to a passage. R returns to the entry used for the current
visit, so reverse traversal does not send the player back to an unrelated
default spawn. TAB is retained only as a debug-build room cycle.

`Main` owns transitions and preserves the player, camera, audio, and progression
state. A room describes its exits and entries, then emits route intent through
`room_base.gd`; it never loads another room itself. Only the old room is
recreated, which keeps the current prototype lightweight without introducing an
Autoload prematurely.

## Route placement

| Room | Forward passage | Reverse passage |
|---|---|---|
| The Label | Summit to Practice | Gather shelf to Smoothed |
| Practice | Beyond the Count-In door to Verse | Left runout to Label summit |
| The Verse | Past the final trio to Unplayed | Left runout to Practice |
| The Unplayed | Beyond the Gather pickup to Smoothed | Lower-left runout to Verse |
| The Smoothed Floor | Right runout to Label | Left runout to Unplayed |

The loop makes existing space do double duty: every lesson room is also a
return route, while Gather turns The Label's visible shelf into a genuine
shortcut instead of a detached reward platform.

## Planned 53-room map

`data/world_map.json` version 2 separates route topology from traversal
requirements:

- `kind`: gate, shortcut, story, or secret;
- `requires`: canonical technique/Refrain IDs;
- `direction`: bidirectional or one-way.

A technique requirement names the move the route asks the player to perform;
it does not check whether that knowledge has been recorded in the journal.

The packing pass keeps all 53 rooms connected with no overlaps while reducing
dead ends from 11 to 7 and bridge connections from 27 to 18. The Unplayed now
uses 48.2% of its bounds and The Undersong 63.0%. The main savings come from
linking Walt directly to Gather, giving Rest a short Mispress route, and
turning Jump-Cut into a breakout toward The Crates instead of another
cul-de-sac.

## The grayed-in runtime

`scripts/world_map.gd` reads the plan at boot and resolves its contact graph;
`scripts/room_graybox.gd` builds one traversable shell per planned room. All 53
are walkable today — as structure, not as design.

- One grid cell is 600 x 360 px, so a room's planned footprint is its real
  footprint. The Undercross really is a 6000 px corridor.
- Each stratum supplies its palette and its air. The Scratch remains the
  boundary the fiction names: dry above it, thick enough to swim below.
- A room opens one passage per planned route and anchors one `from_<room>`
  arrival per inbound route. A one-way plan route is a door on one side and an
  anchor on the other, so the Arm's seal still only falls one way.
- Refrain requirements seal a passage. Technique requirements are printed on
  the plaque and gate nothing, because knowledge is journal state.
- Refrains are the only reward a graybox grants, on a plinth two rungs up.
  That keeps the sealed shortcuts honest: a walk of the whole world can earn
  everything the walk itself asks for.
- Climbs are ladders of two alternating columns, sized so every hop fits inside
  Skip's plain jump. No graybox needs a Refrain to cross itself.

In development mode, Main loads the original five rooms with `_load_room`
and planned shells with `_load_world_room`. Prototype IDs and planned IDs
remain disjoint. M toggles these atlases; TAB cycles whichever is live.
In normal play, `_load_world_room` resolves only the authored chapter registry
and refuses any room outside it. An authored chapter room and its planned
graybox therefore share an identity without replacing the development shell.

## Scope

- Grayboxes carry topology, air, and gating, with no authored encounters or
  lessons. They are not the finished 53-room game.
- Development progression resets on relaunch. Its Smoothed passage remains
  unlocked to support combat testing; campaign outcome persistence does not
change that circuit.
- The three planned Spindle junctions do not provide fast travel yet.
