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

## Trade-offs and next pass

- The planning map is still data-only; the runtime prototype does not load its
  53 rooms yet.
- Encounter completion is not persistent, so the Smoothed passage is placed
  past the bout but is not locked to victory. Add world-state persistence
  before making that gate mandatory.
- The three Spindle junctions should eventually become a separate fast-travel
  network. That is the next large reduction in cross-act retraversal.
