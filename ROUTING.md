# Dead Wax routing

## Playable prototype loop

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

Hand-authored rooms always win: Main only grays in ids the prototype loop does
not claim, and the five-room circuit is untouched. In debug builds `M` toggles
between the prototype loop and the planned world, and `TAB` cycles whichever
atlas is live.

## Trade-offs and next pass

- Grayboxes are shells. They carry topology, air, and gating — no encounters,
  no lessons, no hand-placed grooves. Replacing one means writing a room script
  that claims its id, exactly as the current five do.
- Progression is still session-only, so a world walk resets on relaunch.
- Encounter completion is not persistent, so the Smoothed passage is placed
  past the bout but is not locked to victory. Add world-state persistence
  before making that gate mandatory.
- The three Spindle junctions should eventually become a separate fast-travel
  network. That is the next large reduction in cross-act retraversal.
