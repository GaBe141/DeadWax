# Dead Wax playtest

Run `.\deadwax.cmd play` for the authored opening. Start with the chapter
checklist, then use `.\deadwax.cmd dev` for focused mechanics regressions.
Runtime errors are written to `.godot/deadwax-play.log`.
Run `.\deadwax.cmd check` before handoff; the complete run contains 42 native
suites, including ability model, integration, world, Book, and Walk suites.

## Session

- Date/time:
- Commit (`git rev-parse --short HEAD`):
- Machine/display:
- Input device:
- Overall frame pacing: smooth / occasional hitch / frequent hitch
- Audio clarity and latency:

## Reverse-side exploration review — 2026-09-11

- Full `deadwax.cmd check` passed: **42 suites, 10,760 checks, exit 0**, with
  no script/runtime errors. Log: `.godot/exploration-full-check.log`.
  Existing non-fatal Godot audio teardown warnings remain.
- Native Godot 4.7.2 / GL Compatibility with a private checkpoint and injected
  keyboard events passed the separate Jump-Cut pickup, both B-side openings,
  separate-press passage use, named arrivals, and Continue on A with both
  returns retained. The real campaign checkpoint was never used.
- Reviewed reward, sealed/open return cards, all affected return arrivals,
  and map/Book guidance at 1280×720 and 960×540. Three static signs were moved
  to clear interaction cards; notification text now fits. No geometry changed.
- Captures: `.godot/exploration-review/` and
  `.godot/exploration-layout-review/`. Native log:
  `.godot/exploration-review.log`. All preview processes exited and private
  saves were cleaned. Controller feel and audio listening remain manual.

## Earlier Walk opening review — 2026-09-11

Native Godot 4.7.2 with injected keyboard events and a private checkpoint:

- Full `deadwax.cmd check` passed: 38 suites, 10,239 checks, exit 0, no
  script/runtime errors. Log: `.godot/walk-full-check.log`; existing non-fatal
  Godot teardown warnings remain.
- 15 checks passed. New Game starts at (180,554) with an empty version-two
  moveset; holding left gives one pixel, and 45 fresh presses reach the soles.
  Fresh E saves only Walk, updates the objective and movement card, and restores
  sustained movement. Continue retains walking without granting later moves.
- Reviewed the opening at 1280×720 and 960×540. The walking card stays inside
  the left edge, and only the nearest sleeve shows a prompt. Other pickup
  origins and the Stalls progression route are unchanged.
- Captures and results are in `.godot/walk-input-review/`; the native log is
  `.godot/walk-input-review-final.log`. The opening film was bypassed using the
  explicit fixture entry. This is an automated keyboard pass; controller feel
  and audio remain manual checks.

## Earlier ability progression review — 2026-09-11

This review predates the Walk pickup and records the six-move build below.

Native Godot 4.7.2 / GL Compatibility, with private checkpoints and injected
keyboard events. Reviewed the opening and ability cards at 1280×720 and
960×540; the Book's missing-move leads remain visible at both sizes.

- Full `deadwax.cmd check` passed: 37 suites, 9,757 checks, exit 0, no
  script/runtime errors. Log: `.godot/abilities-full-check.log`. Existing
  audio teardown ObjectDB warnings remain non-fatal.
- 39 native input checks passed: movement and jump from the Headshell start,
  Strike and Set collection, map pickup, passages to the plaza and High Street,
  the ordinary-jump Hood climb, raised Hood, four basic Count-In strikes,
  separate Groove collection, and the earned Stalls crossing. Health stayed
  at 3/3; all four collected abilities were verified on disk.
- Practice and Stalls segments began with direct room loads at their real
  arrivals. Other reviewed travel used passages. This is a focused opening
  pass, not a complete campaign playthrough or a human controller feel review.
- Route testing exposed two problems and verified their fixes: the western
  return tread needed to move out from under the bank, and the first upper
  platform needed 147 px clearance above the solid groove to prevent running
  and coyote jumps from bypassing Groove Riding. The 99-check world suite
  covers these approaches with stock and maximum movement equipment.
- Screenshots and the native input report are under the ignored
  `.godot/ability-input-review/`; final Book captures use
  `.godot/ability-book-960.png` and `.godot/ability-book-1280.png`.

## Recovering the moves

Use New Game for this pass. A save from before ability progression deliberately
retains the complete old moveset, so Continue cannot stand in for a fresh start.
Use isolated checkpoints for partial-save and write-failure checks.

- [ ] After the opening, ordinary jumping, E/Y interactions, and menus work.
  Horizontal movement is one pixel per fresh A/D or left/right press or stick
  flick. Holding, keyboard repeat, or changing frame rate cannot repeat it.
  J/X, Hood, and Set do nothing until their respective discoveries.
  The readout does not invite an unavailable strike or show a working chain.
- [ ] From the unchanged Headshell spawn (180,554), make 45 fresh left taps
  to reach x135 and the walking soles at (60,554). The first E/Y recovers Walk
  only when grounded within 76 px; 44 taps remain outside. The card stays on
  screen at 1280×720 and 960×540 without overlapping the needle prompt.
  The objective and movement card then update immediately. Held movement
  regains the original speed and handling, and Continue preserves it.
- [ ] Find Strike on the Headshell floor at (365,554), then Set toward the east
  at (890,554). A fresh grounded E/Y within 76 px recovers each part once.
  Passing nearby, arriving, or holding E/Y from a different interaction never
  collects it. The artwork remains at the fixed interaction origin.
- [ ] Strike initially gives single Tap attacks and the existing parry. Four
  evenly spaced Taps can solve Count-In without the chain; repeated presses
  never produce Sweep or Accent until that refinement is found. Cooldown,
  buffering, reach, and the 100 ms parry window remain readable and unchanged.
- [ ] Find the Hood on High Street's upper walk at (1100,359), safely above the
  Looper. Return to the plaza: quiet company, call-listening, and wax polishing
  now work. Set alone does not polish wax. Both encounter approaches remain
  available after finding the required moves.
- [ ] Visit the Stalls before finding Groove Riding. Ordinary jumps and any
  faster equipment cannot climb its eastern 210 px step; the quiet groove
  does not launch an untrained strike. A fall lands in the service lane.
  Use the western tread at (810,700) to jump back to the takeoff without R,
  an ability grant, a ceiling trap, or losing the entry checkpoint.
  Try running and coyote jumps from the solid groove block: the first upper
  platform at (900,415), top 397, must remain 147 px above that foothold and out
  of ordinary jump reach.
- [ ] Open Tick's Practice Count-In door, then take Groove Riding at (1320,574).
  The pickup remains unavailable until the door's saved opened outcome.
  Return to the Stalls: strike the live wax, steer onto the eastern bank,
  and reach the Yard. Miss deliberately and repeat the safe western return.
- [ ] Take Three-Strike Chain on the Yard approach at (610,574). Fresh presses
  now link Tap, Sweep, Accent; the readout reveals all three marks and link
  time. The stronger third hit changes no jump, launch, reach, or parry timing.
- [ ] Before Pogo, airborne hits damage vulnerable foes without rebounding.
  Find Pogo on the Well's lower resting shelf at (785,794), then repeat: the
  same confirmed airborne hit rebounds. Jump+strike in one tick also works.
  Guarded and muted targets remain ineligible, and grounded hits stay planted.
- [ ] Earned Groove Riding activates environmental thick-air jets. Later,
  either Tonearm outcome still offers Gather; collecting it gives one dry
  airborne Strike lift, without silently granting any missing ability.
- [ ] At each stage, inspect Journey at 1280×720 and 960×540. It names all seven
  missing moves with leads, marks only found ones, and keeps chain/Groove/Pogo
  separate from the eight core/knowledge/Refrain grooves. Walk has its own
  Movement shelf and is initially selected. Keyboard, D-pad,
  mouse, and right-stick scrolling keep selected details reachable.
- [ ] Recover, change rooms, pause, and Continue with a partial moveset. Only
  found parts remain usable, and owned pickups retire without reward cues.
  A failed pickup write grants nothing and leaves E/Y available for a retry.
- [ ] Continue an actual save with no `abilities` field: the complete legacy
  moveset remains available, with existing room, entry, balance, equipment,
  choices, and Refrains unchanged. A version-one ability snapshot adds Walk
  while preserving exactly its listed old moves. An explicit empty/partial
  version-two snapshot receives no migration grant. New Game clears all seven.
- [ ] Enter title-screen Move practice or the development rooms. All seven moves
  work there; the campaign's partial moveset and checkpoint remain unchanged
  on exit. Practice keeps stock equipment handling and its empty floor.
- [ ] Reduced motion holds pickup decoration still while fresh-input prompts
  work; pause freezes it. A/B reinking in an isolated fixture restores the
  same origins and readable cards without adding collision or granting moves.

## Equipment, echo trials, and the bestiary

Use an isolated checkpoint when seeding equipment, dry streaks, or save failures.
Run the three trial sources naturally as well; do not treat an accelerated
fixture as a measurement of completionist playtime.

- [ ] Find the trial presses beyond Tick in Tick's Practice, in the eastern
  Worn Gallery beyond the Arm's service door, and on the Deep Gallery's lower
  floor. They are clear of arrivals, do not block walking, and remain readable
  at 1280×720 and 960×540.
- [ ] Start with a fresh grounded E / Y while close. A held input, an airborne
  approach, or a nearby passage cannot create overlapping trials. The warning
  precedes each wave; new copies appear clear of Skip.
- [ ] A player without the required combat moves cannot begin an unresolvable trial. Strike allows
  all three sources; Set alone also allows the Label's peaceful recordings.
- [ ] Clear waves of one, one, then two recordings at each source. Label
  Auditioners accept ordinary sustained Set as well as strikes. Overture
  pressings retain their three-tick count and fourth-beat swing; the Deep
  Gallery includes guarded Loopers and Auditioners. Check simultaneous tells,
  parries, damage, and airborne rebounds without changing the normal timings.
- [ ] Open the Book, map, or pause during an unfinished wave. Resume: its
  copies are gone, the press offers another attempt, and no clear, material,
  equipment, or random roll was awarded. Leaving the bounds, R, and death also
  cancel an unfinished attempt.
- [ ] Finish all four recordings. Return to the press and use a fresh E / Y to
  collect once. Opening a menu before collection keeps this completed claim.
  **Collect before recovering or leaving the room:** those discard an unclaimed
  result. Holding E must not claim twice or start the next trial automatically.
- [ ] Repeat a trial after collecting. Each successful claim adds one clear
  and one Offcut; the regional mastery ledger counts up toward 100 separately
  from equipment completion. Extra clears in one region do not fill another.
- [ ] With an isolated seeded fixture, verify the 4% / 3% / 2% / 1% regional
  drops, 10% total chance, and a guaranteed drop by the twentieth dry clear.
  Missing regional items take priority for that guarantee. Duplicate equipment
  adds five extra Offcuts instead of another inventory copy.
- [ ] In the Book's Equipment page, select an unowned piece. It shows a real
  source, exact odds and trade-off. Before clearing that source, binding is
  unavailable even with enough material. After one clear, 40 Offcuts binds a
  chosen missing piece; it does not automatically equip or alter future rolls.
  Already-owned pieces and insufficient balances cannot charge again.
- [ ] Fit and replace a Needle, Lining, and Charm. Test faster running with
  weaker braking, quieter noise with slower Hood movement, and stronger air
  steering with reduced health. Each drawback is present along with its
  benefit; removing equipment restores stock behavior. Combined handling is
  bounded at 65–140%, and equipment adds at most one maximum health slot.
- [ ] Add health capacity while injured: the new slot remains empty until
  recovery. Removing and refitting it cannot heal. Glass Needle reduces the
  maximum immediately. Spare Groove still combines correctly, and Continue
  restores the fitted loadout with full derived health. Strike/parry clocks,
  jump height, reach, Gather, and route permissions remain unchanged.
- [ ] In an isolated failed-write fixture, claiming keeps the earned result
  available, with no change to equipment, Offcuts, clear count, dry streak, or
  random state. Restore saving and retry: exactly that roll commits once.
  Failed fitting or binding applies no movement/health change and spends no
  material. Feedback makes the retry clear.
- [ ] Open Journey, Equipment, and Bestiary by clicking and by Tab / Shift+Tab
  or LB / RB. Arrows, D-pad, and left stick select entries. Mouse wheel,
  PgUp / PgDn, and right stick scroll long notes. All action buttons and text
  remain reachable at both window sizes; rapid navigation and Reduced motion
  leave truthful focus and no stale transaction feedback.
- [ ] Approach the Hound, Tick or Bootlegger, a voice, and a keeper. Their
  bestiary notes appear without requiring harm. Unseen names and habits stay
  hidden, and reading a note changes no world state. The initial catalog has
  ten entries, with further content safe to add later.
- [ ] Load an old save containing freed/shattered actors: their species and
  historic counts appear even if those actors are gone. Repeat Continue and
  revisit rooms: no count repeats. HUSH's won bout records his name without a
  false freed/shattered count. Trial copies never count as restored neighbours.
- [ ] After trials, binding, and fitting, save and Continue. Owned pieces,
  fittings, Offcuts, dry streaks, regional clear counts, and bestiary notes
  survive. The nine polish patches still pay one Shine once, and the original
  shop prices, permanent encounters, and 21-room/26-pair route graph are intact.
- [ ] Enter title-screen Move practice after fitting gear. It remains empty
  with stock handling and a disposable collection. Returning to title and
  Continue restores the campaign collection; practice cannot alter its save.
  New Game clears all gear, fittings, materials, mastery, and bestiary notes.
- [ ] Time several natural clears at each source with different loadouts.
  Record average clear time, travel time, whether two-copy waves stay readable,
  and whether repetition remains enjoyable. Judge collection and 100-clear
  mastery pacing from these observations rather than a promised hour count.

## Painted world review

- [ ] Review all 21 rooms at 1280×720 and 960×540: cream faces and upper
  platform lips remain visible against the painted distance. Inspect the Well
  and Drop at top, middle and bottom; Whistlers' catch lane and the Stalls loft remain clear.
- [ ] Check the Looper's guard/open states, HUSH's count/swing and the Tonearm's
  tip contact. Brass mechanisms and strike ribbons must follow the same timing.
- [ ] Live groove housings show the returning echo; the spent face looks dormant.
  Wax medallions polish once, with a readable progress ring and lasting shine.
- [ ] Passage arches remain distinct from distant windows; nearby prompts,
  seals, lanterns and signs do not obscure a landing or alter interaction reach.
- [ ] Title, Book, map, stall, pause/settings, ending and four opening shots
  use the new cloth/brass treatment with readable text and visible focus.
- [ ] Pause holds world animation; Reduced motion holds ambient detail and
  parallax. Reink A→B→A and recover: original colours, light exposure and camera
  synchronization return without flashing a reward or revealing new routes.

## The Echo Spool and survey slip

Native development review, 2026-09-11: Godot 4.7.2 GL Compatibility fixtures
covered pickup, recording, restoration/replay, the real Gallery→South and
South→North passages, the southern upper jumps, the Landing ascent with and
without Gather, Book layouts at both window sizes, and A→B→A/reduced motion.
The northern return climb was verified with resolved encounter fixtures after
active enemies interrupted the automated jumps. Controller Y has automated
coverage; human controller feel and listening to the final mix remain manual.
At that review, `deadwax.cmd check` passed its then-current 29 suites and 7,813 checks.

- [ ] Take the spool beside Deep Gallery's empty seats with grounded E/Y.
  Its origin stays fixed; walking near it or arriving in the room collects nothing.
- [ ] Follow the lower eastern Gallery passage to South Warren, climb the upper
  walk and record at the old wire. Three visible notes match the finite phrase;
  stay nearby on the ledge for the whole two seconds. Muting remains playable.
- [ ] Leave, jump, recover, or open a menu during recording/playback: the attempt
  and its sound stop. A fresh E/Y restarts it; holding the key never repeats it.
- [ ] Carry the phrase to North Warren's western terrace. The receiver opens its
  shutters and reveals the answering discs. Replay it deliberately with E/Y;
  repeated plays grant nothing. Repeat with the resident encounters resolved
  either way; the fixture remains available.
- [ ] Return, recover, and Continue at each stage: the spool, recorded phrase,
  restored alcove and survey slip persist without another reward or opening sound.
- [ ] In the Landing, ordinary jumps cannot reach the 190 px overlook. Start
  beside its left edge, jump and strike near the crest with Gather, then steer
  onto it. Take the survey slip and read its Stalls loft clue in the Book.
- [ ] Inspect both found-item buttons and descriptions at 1280×720 and 960×540.
  They appear only once found; the eight core/knowledge/Refrain slots retain
  their existing count. Reading an item never changes it or the player's room.
- [ ] Pause freezes decoration. Reduced motion holds reels, paper and shutters
  still while the semantic note cues remain usable. A→B→A restores the fixtures'
  palettes, and the artwork stays behind Skip without hiding any platform lip.

## Opening chapter

- [ ] Boot reaches the title screen; New Game plays the four-scene opening and hands control to Skip in the Headshell after about 23 seconds. Continue is available only with a readable campaign checkpoint and restores the saved entry without the film.
- [ ] Watch opening replays from the title and returns there. An existing save, wallet, map, Refrains, and encounter choices survive the replay unchanged.
- [ ] Holding the title's confirm key or controller A does not immediately advance the first scene. Fresh Space/A or Next advances once; Escape/controller B or Skip ends it after the short fade. Holding movement, jump, strike, Hood, Set, or passage during the film does not act on the first gameplay frame; fresh direction taps shuffle one pixel and interactions work after handoff; sustained walking and combat moves still await discovery.
- [ ] The town in the record, the worn street, Skip's first feet, and the lit way down read clearly at 1280×720 and 960×540. Captions, title, and Next/Skip remain readable with no overlap; resizing leaves the current shot intact.
- [ ] Four quiet synthesized cues accompany the film while world sound and simulation remain paused. Next changes the cue; Skip stops it at handoff. Master volume/mute applies. Check a replay after using Hood: the film should not inherit a muffled filter.
- [ ] Reduced motion holds composed illustrations while the story still advances naturally. Pause, Book, map, and shop do not stack over the film. Normal and skipped endings each return control exactly once.
- [ ] Starting a new game over an existing one asks the player to confirm the replacement.
- [ ] The title, menus, room signage, player silhouette, and HUD remain legible at 1280×720 and in fullscreen.
- [ ] Headshell's shuffle/Walk/jump prompt and the first E/Y passage are understandable without external instructions.
- [ ] Horn Plaza clearly offers the west practice loop and the east market route.
- [ ] After finding Hood on High Street, return beneath the horn and hold it still for about 1.4 seconds to hear its quiet answer. Polishing there grants one Shine.
- [ ] High Street's Looper gives three ticks and swings on four; the upper route lets the player pass without fighting.
- [ ] Return after finding the chain: after an opening hit, repeated Tap/Sweep/Accent strikes meet the Looper's visible guard without damage, rebound, or an interrupted count. Step out of range, let it swing, then return during OPEN for a full combo. Parrying instead grants the same opening and existing resonance response.
- [ ] GUARD, the three ticks, the swing, and OPEN agree with contact and vulnerability at 1280×720 and 960×540. The OPEN bar remains truthful with Reduced motion. Recovery resets an unfinished Looper; a defeated one stays defeated on recovery, return, and Continue without extra Shine.
- [ ] Four evenly spaced J/X strikes open Practice's physical lock and record Count-In once. Returning through the plaza is clear.
- [ ] After earning Strike, the same four-hit Count-In pattern opens the Descent Gate; the Book's technique record itself never gates the solution.
- [ ] Return to the Stalls after recovering Groove Riding in Practice. Standing on the live groove and striking carries the player toward the eastern walkway.
- [ ] A missed launch lands safely in the service lane; the western steps return to the takeoff without a Refrain or restart. The eastern bank still requires the earned launch.
- [ ] In the Yard, approach the first voice quietly and raise Hood while standing near it. Hear two notes and notice the empty reply mark. Lower Hood and begin holding Set during the silence: one answer frees it. Try keyboard and controller. A fresh player should understand the exchange from its cues.
- [ ] Holding Set before hearing the call does not free the first voice. Releasing Hood early, starting Set too early, releasing Set before its response finishes, or missing the silence lets it try again. There is no immediate contact hit during the call, answer, or retry rest. Walking away and returning starts a fresh attempt.
- [ ] The completed engraving appears at the first voice's original place even if it moved. After a quiet wait nearby its gentle finished phrase returns. Shattering leaves a broken engraving and silence instead. Return, recover, and Continue: the same choice remains with no repeated reward, flash, or resolution sound.
- [ ] Pause freezes the first voice and its phrase. Reduced motion steadies decorative movement but preserves note/answer cues; muting still leaves a solvable exchange. Review the card, reply marks, both engraving outcomes, and nearby signs at 1280×720 and 960×540.
- [ ] Ordinary strikes and parries work on the first voice; airborne rebounds work after returning with Pogo. Striking cancels its unfinished conversation. The second voice still accepts earned Set, and both choices grant no Shine or progression.
- [ ] Neither combat nor mercy is required to leave the Yard; both choices remain readable.
- [ ] The Descent Gate blocks passage until its four-strike pattern is performed; the exit beyond it enters Overture Stair.
- [ ] Every stair can be climbed on the return trip with a normal jump.
- [ ] Overture Stair's lower passage enters the Bootlegger's stall; the return lands on its lower platform.
- [ ] No passage leads into an unfinished graybox.
- [ ] TAB and G do not activate development tools during normal chapter exploration. Tab changes pages only while the Book is open. M gives a Headshell hint before finding the map and opens it after collection.

## The Overture

- [ ] The Bootlegger's nearby E/Y conversation is readable and does not enter a passage or advance multiple lines at once.
- [ ] The Whistlers' wind/launch route is readable; a missed jump has a safe recovery path and both return exits are reachable.
- [ ] Addie can be heard or shattered. The saved choice stays consistent on return and Continue.
- [ ] The Well's descent has a legible return climb, with no hop requiring an unavailable Refrain.
- [ ] HUSH is distinct from the practice dummy. His three ticks and swing are readable; raw hits do not build resonance or count toward victory.
- [ ] Three parries win HUSH's bout, open the forward passage, and leave him resolved on return.
- [ ] Before that victory, the forward passage refuses entry; the direct Gallery→Arm shortcut is also closed.
- [ ] The Tonearm points upward and does not attack because of movement or noise alone. A nearby strike initiates its count.
- [ ] The grounded tip's sweep, recovery opening, parry, and damage all agree visually. The overhead beam does not deal invisible contact damage.
- [ ] Holding Set after its gesture offers a peaceful resolution; committed strikes in its openings offer the force outcome.
- [ ] Recovery resets an unfinished boss attempt; a completed encounter never starts fighting again.
- [ ] Reaching the Arm opens the gallery return shortcut. It stays open after Continue.
- [ ] Boss resolution alone does not open a menu. Grounded E/Y at the final listening point shows the appropriate ending once.
- [ ] The Headshell's return text/scenery match the Tonearm's saved outcome.
- [ ] An old completed eight-room demo save continues into the Overture with its Shine, room entry, Count-In, and prior choices intact.

## Beneath the seal

- [ ] Before resolving the Tonearm, the Arm's eastern passage refuses entry. Test both freed and shattered outcomes: either opens the Drop, while the final listening point remains a separate grounded E/Y choice. Entering the passage never opens an ending menu or collects Gather.
- [ ] Leave Gather where it appeared and walk Arm→Drop→Landing→Verse Hall→North Warren. Take North→Deep Gallery→South→North, then return all the way to the Arm. Every route works with ordinary jumps, with no restart needed to escape a lower floor.
- [ ] Climb the Drop's maintenance ledges from bottom to top. Takeoff edges remain visible, each upper platform can be reached without hitting the underside, and a missed jump has a usable route back up.
- [ ] Check every new passage with keyboard E and controller Y in both directions. Each arrival provides safe standing room, R returns to that named entry, and holding the entering button does not immediately send Skip back through the arrival door.
- [ ] Follow the Verse Hall's upper walk past its voice, and the southern Warren's upper walk past the pressing. The northern Warren and Gallery connect upper and lower routes without forcing an encounter or an unavailable ability.
- [ ] Hear and shatter the new voices on separate runs. Defeat the Warren pressing, leave, return, recover, and Continue: resolved encounters stay absent, unfinished attempts reset, and no encounter awards Shine or a Refrain.
- [ ] At each fixed listening post, grounded E/Y advances one line per fresh press. Its card remains readable and does not trigger a nearby passage. Holding the input, standing too far away, and opening a menu cannot advance it repeatedly.
- [ ] With Gather, reach the Landing's 190 px overlook using a jump and one airborne strike. Read its optional post and drop safely back to the floor. Without Gather, both ordinary passages remain reachable and the shelf grants nothing merely for entering the room.
- [ ] Review the violet Unplayed painting, drawn seating, architecture, lamps, and passage arches at 1280×720 and 960×540. Skip, voices, pressing tells, and platform tops remain clear; decoration does not resemble a usable ledge or cover a landing edge.
- [ ] Pause and Reduced motion settle the new scenery and lamps as in the older rooms. In an isolated visual fixture, A→B→A restores every new room's authored palette and light exposure without changing its routes or rewards.
- [ ] Save and Continue from each new room, including reverse arrivals. The same room entry, map visits, purchases, Shine, and prior outcomes return. An old completed Tonearm save can use the new passage without a new game; its recorded ending stays complete, and unfinished saves retain the separate Arm listening choice.
- [ ] Opening the map in the expansion selects the Unplayed page. Browse the other sheets, close, and reopen: it returns to the current region, while unvisited room names remain hidden on every page.

## Gather and the return journey

- [ ] Before resolving the Tonearm, there is no Gather reward or practice ledge. Both peaceful and force outcomes reveal the pressing; resolving alone does not collect it or show an ending.
- [ ] Walk to the pressing. Its impression floats but its collection reach stays fixed. Gather appears in the Book; jump then Strike near the crest to land on the nearby shelf. A missed attempt lands on the ordinary floor and landing refills one breath.
- [ ] With Gather, grounded attacks stay grounded, including beside HUSH or a closed Tonearm. Jump-and-strike works; dry air provides only one breath per landing. Live grooves and thick-air behavior still work.
- [ ] On the first visit to the Stalls, notice the upper room without reaching it by ordinary jumps or the live groove. Return with Gather, jump from the right bank beside the balcony's left edge, Strike near the crest, then steer onto it.
- [ ] Beside the loft voice, holding Set immediately does nothing. Hold Hood for all three visible/audible notes, lower it in the silence, then press and hold Set. Two answers open the Gallery passage. Test keyboard and controller; turning the volume off still leaves usable cues.
- [ ] An early or late response can be retried. Leaving resets an unfinished conversation. Pause freezes the phrase; Reduced motion steadies the sleeve while functional note and response cues continue.
- [ ] Use the loft→Gallery passage and return. Both arrivals have safe standing room; the ordinary market and Gallery routes still work.
- [ ] Return to the plaza and Headshell: the discovered phrase plays with rests and responds to Hood. Leaving fades it out; pause, Book, map, and shop suspend it. Continue restores it without restarting a reward; New Game clears it.
- [ ] An old completed save without Gather can revisit the Arm and collect it. Recovery and Continue preserve Gather, the resolved voice, its shortcut, and the same Shine balance.
- [ ] Check pickup, practice signage, loft voice cues, both nearby passage cards, and the 26-route map at 1280×720 and 960×540.

## Folded map

- [ ] New Game begins without the map. Recover Walk, then walk right in the Headshell: the folded page is visible before the first raised block, clear of both arrival positions, and collects once on approach.
- [ ] Collection announces the map without opening a panel or changing Shine, health, Refrains, or knowledge. M / D-pad Down opens the map from play, and the Book gains an Open map button.
- [ ] The map marks the current room, names explored rooms, and leaves unvisited names hidden. Its 26 passage pairs match the 21 playable rooms; dashed shortcuts do not claim to unlock a passage.
- [ ] Label, Overture, and Unplayed tabs select distinct sheets. Mouse clicks, keyboard Left/Right, and D-pad Left/Right all turn pages; controller A on a focused tab selects it without closing the guide. The selected tab and focus remain clear at both supported window sizes.
- [ ] Opening or reopening selects the player's current region. Boundary markers show the region reached by each real passage without naming an unvisited room. Paging changes no map visits, position, health, Shine, purchases, or progression.
- [ ] Closing with M, D-pad Down, Escape/Back, or the Close button returns to the same position without a jump, attack, or passage input leaking through. The map, Book, stall, and pause menu cannot overlap.
- [ ] D-pad Down still navigates the Book, including after collecting the map. Use A on its Open map button, or keyboard M, to unfold it there.
- [ ] Explore, recover, Continue, and return to the Headshell: ownership and explored marks survive and the pickup stays gone. An old save without map data still loads and can collect it; New Game restores the pickup.
- [ ] The map and pickup stay legible at 1280×720 and the supported 960×540 window. Pause freezes pickup motion; Reduced motion steadies the paper and map interface without changing collection reach.

## Interface animation

- [ ] Title, pause, settings, the Book, and the stall reveal their content quickly over a fully opaque background. Text stays readable at 1280×720 and at narrower window sizes.
- [ ] Mouse hover and keyboard/controller focus show a moving ink accent without moving the button's hitbox. Fast navigation does not leave stale highlights or steal focus.
- [ ] Open and immediately close each menu; reopen or switch pages before the animation ends. Actions still respond immediately, with no delayed close, purchase, or focus change.
- [ ] Book descriptions and stall balances update immediately. Purchases animate only after a result; silently restoring a save or reopening the shop does not replay a reward.
- [ ] Enter a room, earn Shine, or take damage: the HUD responds without hiding values. Shine receipts clear on recovery and passages. Pausing freezes the world and HUD while the active menu continues.
- [ ] Enable Reduced motion during a transition: page motion, record movement, focus effects, and HUD transforms settle immediately. The interface stays fully usable and notifications still expire during play.

## Attack feel

- [ ] From the title, choose Move practice with mouse, keyboard, and controller. The empty floor starts with Skip standing still; holding the confirming Space/A does not jump. The full title, including Continue and Quit, fits at 1280×720 and 960×540.
- [ ] Press J/X three times within the link window. Tap, Sweep, and Accent have distinct poses, directional ink, and sound; the readout marks each execution. A fourth starts Tap. Holding Strike never repeats; waiting longer than 650 ms starts a fresh chain.
- [ ] Try the chain facing both ways, running, jumping, and near the ends of the practice floor. R returns to the start and clears the chain. Hood/Set, Book, and pause cancel the chain; the next strike is Tap. Reduced motion settles the readout while its timing remains truthful.
- [ ] Pause practice and choose Return to title, then Continue. The campaign entry, Shine, purchases, map, progression, and choices are unchanged. Starting practice without a campaign save does not create Continue. Settings remain usable during practice.
- [ ] With the corresponding abilities found, campaign Accent lands harder on a vulnerable foe with the same 120 px reach. A hot-groove Accent gets the normal on-beat launch, and airborne foe/Gather rebounds do not become stronger on hit three. Muted targets retain their parry-only rules.
- [ ] Standing beside a vulnerable foe, J/X lands a hit without launching Skip. Starting or reversing a run during the short recovery stays responsive.
- [ ] Jumping into a nearby foe and striking rebounds upward; pressing jump and strike together also works. Enemy reach remains 120 px, and every enemy rebound registers a hit.
- [ ] Live grooves still launch from the ground or air and take priority when an enemy is nearby. Whistlers' directed launches and groove echoes retain their timing.
- [ ] A fresh press during the last 90 ms of the 200 ms cooldown produces one follow-up when ready. Earlier presses and holding J/X do not create repeated attacks.
- [ ] The combo's input line shows RECOVERING, J / X · PRESS, and QUEUED independently of LINK TIME. Press too early to see EARLY · WAIT, then tap during PRESS: QUEUED becomes the next executed beat. Pause freezes feedback; Reduced motion keeps it truthful and lets the early notice expire. Check both window sizes and keyboard/controller X.
- [ ] Queue a follow-up, then raise Hood, Set, take a hit, open pause/Book/shop, recover, or change rooms: no stale strike fires afterward.
- [ ] HUSH and the muted practice dummy give no enemy rebound from raw hits. Three correctly timed parries still win; the actual strike must fall within the unchanged 100 ms window.
- [ ] The immediate circular strike impression reads clearly on both sides of the wax at normal game size. Fainter groove/air echoes do not imply a larger enemy-hit radius or hide enemy tells; there is no animation delay or hitstop.

## Scenery and depth

- [ ] The 21 authored rooms have distinct distant architecture and a still field of paper light. The plaza reads as a town, the Stalls as a shuttered market, the Well and Drop as continuous descents, and the Unplayed as rooms waiting for an audience.
- [ ] Walk and jump through a wide room and descend the Well: far and middle planes move gently with the camera; recovery and room changes introduce no scenery jump after the arrival settles.
- [ ] Floor engraving stays inside real platform faces, at least 10 pixels below their tops. Check the Stalls service lane, both Whistlers return stairs, and the Well climb: landing edges, gaps, passages, and player silhouettes remain clear.
- [ ] HUSH's point and the Tonearm's gesture, counted beats, sweep, and openings remain readable against the new backgrounds at 1280×720 and in fullscreen.
- [ ] Pause, the Book, and the shop freeze decorative motion and parallax. Reduced camera motion also stops both while playing; static scenery still reflects live encounter outcomes and palette changes.
- [ ] In an isolated native preview, A→B→A reprints every layer and restores the authored palette without changing geometry or rewards. The scenery suite checks this without granting campaign Refrains; development grayboxes retain their original halftone backdrop.

## Lighting

- [ ] The 21 authored rooms have two to four fixed light sources each. Lamps, windows, and openings produce distinct pools of light without washing out print, grooves, passages, or boss tells at 1280×720 and in fullscreen.
- [ ] Walk through a wide room and descend the Well: sources stay fixed in world space while the artwork moves in parallax. Inspect the Well's top, middle, and bottom, both Whistlers banks, and the Stalls service lane for readable landings.
- [ ] In a native preview, toggle shadows on the same view: actual platform faces block light, with no false walls or dark seams across their walkable tops. Soft shadow edges remain steady without streaks or flicker. Occluders change no collision or movement.
- [ ] Pause, the Book, and the shop freeze slow light modulation. Reduced camera motion also stops it during play; Addie and Tonearm outcome changes still update their light energy and remain correct after returning or Continue.
- [ ] The sheet, HUD, Book, shop, pause, and title retain their original colours and contrast. Room changes leave one ambient modulator for the active authored room, with no lingering lights from the previous room.
- [ ] In an isolated native preview, the B-side receives extra ambient fill and returning to A restores the authored exposure. Development rooms and grayboxes create no room lighting and keep their previous appearance.

## Sprite animation

- [ ] Skip's idle breath/blink, running feet, takeoff stretch, falling pose, and landing squash read clearly at normal game size.
- [ ] Striking flicks the point immediately; Hood and Set transition smoothly without delaying either action.
- [ ] Moving left and right keeps the point and eyes facing the movement direction; a hit shows recoil and recovery clears it.
- [ ] Voices step as they creep and open their arms before contact; a freed Addie relaxes and putters beside her doorway.
- [ ] The practice pressing, HUSH, and Tonearm windups and follow-through agree with their existing audio and parry timing.
- [ ] A live victory settles into its resolved pose; Continue shows that settled pose without replaying the victory or granting rewards.
- [ ] Pausing freezes character motion. Resume continues it; room transitions and recovery clear stale landing, strike, and hit poses.

## Residents

- [ ] The Bootlegger sorts and inspects tapes, looks toward Skip, and gestures when spoken to. His words change after either Tonearm ending.
- [ ] Tick's pendulum and quiet clicks mark three beats, then pause. E/Y introduces the missing beat; four even J/X strikes still open the real Count-In door.
- [ ] Standing near either resident shows a readable conversation above them. Each fresh E/Y press advances once; holding, jumping, or pressing from far away does not advance it or take a passage.
- [ ] The Hound wanders and sniffs in the plaza. A grounded, still Hood visitor draws it close; after settling, it wags. Running or noise interrupts the quiet contact, and a nearby strike briefly startles it without hurting anyone.
- [ ] Returning after freeing voices gives the Hound more room to patrol, with its whole silhouette clear of the plaza exits.
- [ ] Freed Addie walks a small patch by her doorway and gently pats a nearby Hood or Set visitor. If freed far from home, she walks back without teleporting. Neither visit nor further strikes replay her encounter or Shine.
- [ ] A shattered Addie remains absent after leaving, returning, and Continue. Existing version-one saves preserve the same choices.
- [ ] Pause and the Book freeze every resident's animation, movement, and dialogue. Characters and cards remain readable at the usual game size.

## Shine and purchases

- [ ] Polishing a fresh patch shows `+1 SHINE` and increments the HUD and Book once. Leaving, returning, recovery, and Continue cannot pay that patch twice.
- [ ] Grounded B/D-pad Up beside the Bootlegger opens the stall; remote or airborne input does nothing. E/Y still advances his conversation.
- [ ] The counter clearly shows balance, prices, item effects, and owned or insufficient-funds states. Merely opening, holding the opening button, or selecting an item never buys it.
- [ ] Buy Spare Groove for 4 Shine: balance falls by 4, the needle gains a filled fourth slot, and a fourth hit is required to recover. Soft Lining costs 3 and visibly speeds Hood walking; ordinary walking/jumping and silence stay the same. Warm Thread costs 2 and gives the Hood an amber stitched edge.
- [ ] Bought items appear in the Book, cannot be bought again, and survive passages, recovery, quitting, and Continue. Starting a new game clears purchases and balance.
- [ ] The shop pauses the world and prevents attacks, passages, recovery, or the Book behind it. Mouse, arrows/stick, and D-pad reach the products and Buy/Leave controls. D-pad Up navigates within the shop; Escape/controller B/Back closes it without a jump or passage.
- [ ] Item descriptions, Buy/Leave controls, and notices remain readable at 1280×720 and 900×600. Returning with less than the price clearly shows how much more Shine is needed.
- [ ] An old save keeps its existing Shine and gains an empty purchase list. The automated isolated-save checks cover write-failure rollback; never sabotage a real player's save for this test.

## Recovery, saves, and settings

- [ ] The HUD starts at NEEDLE 3/3. Three hits recover at the active room entry with full health and preserved progression/outcomes.
- [ ] R and falling out of the room also recover at that entry; reverse traversal uses the correct arrival.
- [ ] Passage, lock, encounter, polishing, Book, pause, title, and quit save without a visible hitch or repeated reward.
- [ ] Leave a polished patch and opened door, return, then quit and Continue: the patch stays spent, the door stays open, and Shine/Count-In match the prior session.
- [ ] Freed and shattered Yard voices stay gone after returning and after Continue.
- [ ] Continue resumes at the saved room entry with full needle health, rather than at a mid-air position.
- [ ] Opening the Book pauses play, shows the correct Shine and learned Count-In, and keeps unknown entries unnamed.
- [ ] I/Start closes the Book; Escape closes it without immediately opening pause.
- [ ] Escape/gamepad Back pauses the chapter. Resume does not also jump or enter a passage with the confirming input.
- [ ] Returning to title and quitting preserve the checkpoint. A save failure is visible and prevents a silent departure.
- [ ] Volume including mute, fullscreen, and reduced camera motion work from settings and survive a relaunch.
- [ ] Reduced camera motion removes camera smoothing, hit shake, decorative ambient motion, scenery parallax, and slow lamp modulation; movement and passage transitions still work normally.
- [ ] Keyboard, D-pad, stick, and menu focus behave correctly with a controller, if available.

The native save suite tests malformed checkpoints and backup recovery using
isolated test paths. Do not corrupt a player's real checkpoint for this pass.

## Development mechanics route

Run `.\deadwax.cmd dev`, or launch Godot with `-- --dev-rooms`. This opens
the original five-room circuit and enables TAB/M/G in debug builds. Progression
here is session-only; the campaign checkpoint must remain unchanged.

### Cross-room checks

- [ ] The game opens at 1280×720 in **The Label** with HUD and synthesized audio.
- [ ] A/D or arrows move; Space jumps; J/X strikes; K/C holds Hood; L holds Set.
- [ ] E or gamepad Y enters a nearby passage; the five rooms form one loop.
- [ ] I or gamepad Start opens **The Book** over the full 1280×720 viewport.
- [ ] The Book pauses movement, enemies, passages, strikes, respawn, and room cycling.
- [ ] Arrows/D-pad/stick move the hot-pink focus; each entry updates the detail pane.
- [ ] I/Start toggles the Book closed; Escape also closes it and play resumes cleanly.
- [ ] Fresh inventory shows STRIKE, HOOD, and SET; the other five grooves are unnamed.
- [ ] Count-In and Gather appear live when learned/carried, without revealing future entries.
- [ ] Shine matches the HUD and the same Book state survives passages and R respawns.
- [ ] R respawns at the entry used for this visit, including when traversing backward.
- [ ] Tab cycles rooms only as a debug shortcut and is not required for normal play.
- [ ] Refrains and discovered techniques persist through passages/R, but reset on a fresh launch.
- [ ] Hood noticeably slows movement, quiets crackle, and muffles the audio bed.
- [ ] Controller mappings work, if a controller is available.

### 1. The Label

- [ ] A strike near a live groove launches Skip; a strike in dead air does not.
- [ ] On the first visit, an ordinary jump cannot reach the high shelf above the spawn.
- [ ] The nearby live groove cannot carry Skip through the baffle to that shelf.
- [ ] Striking again as the groove echo returns produces **ON BEAT** and a stronger launch.
- [ ] Four evenly spaced strikes open the unsigned groove-lock.
- [ ] The spent-wax gap and wall-groove shaft are readable without explanation.
- [ ] The summit passage enters Practice; returning from Practice lands on the summit.
- [ ] The shelf passage visibly asks for Gather and refuses entry on the first visit.

### 2. The Practice Room

- [ ] Holding Hood near dull wax for about 1.2 seconds grants one Shine.
- [ ] The dummy hears crackle, ticks three times, then swings on four.
- [ ] A mistimed defense causes knockback and increments hits taken.
- [ ] A strike in the 100 ms parry window produces **RUNG BACK**.
- [ ] Five ordinary nearby hits—or enough resonance—shatter the dummy.
- [ ] Four evenly spaced strikes open the signed count-in door.
- [ ] Opening the door adds COUNT-IN to the HUD; the pattern worked before it was recorded.
- [ ] The right passage beyond the door enters The Verse; the left passage returns to Label.

### 3. The Verse

- [ ] An Auditioner approaches and gives a readable rising reach tell.
- [ ] A strike/parry breaks the reach as expected.
- [ ] Holding L/Set nearby for about 1.2 seconds frees an Auditioner peacefully.
- [ ] Fighting another Auditioner demonstrates the contrasting shatter outcome.
- [ ] The right passage enters The Unplayed; the left passage returns to Practice.

### 4. The Unplayed

- [ ] Two directional air-strike breaths work before landing.
- [ ] Landing, groove launches, and pogo hits refill breaths.
- [ ] Air-striking a nearby enemy produces an upward-biased pogo bounce.
- [ ] Every pogo also registers a hit; striking just outside hit range does neither.
- [ ] Touching the record at the climb-out unlocks GATHER and updates the HUD once.
- [ ] Gather does not add a third breath here: The Unplayed still refills to two.
- [ ] The Smoothed passage is sealed until Gather is collected, then accepts E/Y.

### 5. The Smoothed Floor

- [ ] Raw strikes do not build resonance, remove HP, or give an enemy rebound from the muted dummy.
- [ ] Three successful parries win the bout.
- [ ] The third parry produces **the bout is yours** without shatter effects.
- [ ] The right passage returns to The Label on the far side of the dry baffle.
- [ ] The left passage returns to The Unplayed's Gather platform.

### 6. Gather return to The Label

- [ ] One dry-air strike now launches Skip; a second does not until landing or respawning.
- [ ] A jump followed by the one Gather breath reaches the high shelf above the spawn.
- [ ] R refills the one dry breath, and the room's dry look/strike wave remains dry.
- [ ] E/Y on the shelf takes the new shortcut to Smoothed's right side.
- [ ] Follow the reverse passages to The Unplayed: Gather stays gone and capacity stays two.

### 7. The B-side

Press **G** in the development rooms to carry Jump-Cut, then **F** to turn the pressing
over. This is the feel pass that matters most — twelve seconds is a guess.

- [ ] F does nothing, and says nothing, before Jump-Cut is carried.
- [ ] Flipping in The Label inverts ink and paper; the room reads as scratchboard.
- [ ] The live groove goes visibly spent, and a strike near it no longer launches.
- [ ] Dry wax now answers a strike: two breaths, and you fall more slowly.
- [ ] The HUD stays readable on the dark face.
- [ ] The runtime counts down and the readout warns in the last three seconds.
- [ ] When the side runs out the needle lifts wherever you are — including mid-air.
- [ ] Being dropped out of thick air by the timer reads as fair, not cheap.
- [ ] The A-side rewinds the far face; a nearly spent side refuses to flip.
- [ ] Flipping on The Smoothed Floor lets resonance build and raw hits land.
- [ ] Twelve seconds is enough for a round trip, and short enough to feel it.

### 8. The planned world (development mode, optional)

Scaffolding, not design — check shape and traversal, not feel.

- [ ] **M** drops you into the grayed-in Headshell; the HUD identifies its graybox index out of 53.
- [ ] Each stratum reads as its own palette, and the air changes below the Scratch.
- [ ] Passages name their destination; E/Y crosses and lands you on the near side.
- [ ] A Refrain shortcut reads SEALED until you carry it; a technique passage never seals.
- [ ] Every climb is makeable on legs alone — no passage needs a breath you lack.
- [ ] Gather, Rest, and Jump-Cut can each be reached and collected on one walk.
- [ ] **M** returns to The Label with session progression intact.

## Feel questions

- Does the 100 ms parry window feel fair after learning the three-tick tell?
- Do grounded hits and airborne rebounds feel distinct, with reliable quick follow-ups?
- Does Hood feel meaningfully quieter rather than merely slower?
- Is Set/mercy discoverable without being explained first?
- Is thick-air movement expressive or frustrating?
- Is the muted bout tense and readable, or simply empty?

## Issue record

- Short title:
- Room:
- Steps to reproduce:
- Expected:
- Actual:
- Frequency: once / intermittent / every time
- Screenshot/video/log timestamp:
- Severity: blocks play / major mechanic / feel-polish / cosmetic

## Reverse-side exploration

- [ ] Finish the Echo Spool route and follow the restored receiver's clue to the floor below. Jump-Cut requires its own grounded E/Y pickup. Returning on an old restored-phrase save also reveals it; replaying the phrase grants nothing twice.
- [ ] Turn the wax with F/RB, reach the North Warren's eastern terrace seam, and use E/Y to unseal it. The same press must not travel. Release and press again to emerge on High Street's quiet western floor.
- [ ] Return on the A-side; the opened connection works both ways permanently. The High Street end stays sealed before opening from the Warren, including on the B-side.
- [ ] Unseal the Deep Gallery's central floor seam on the B-side. Travel to the Headshell, land safely on its existing raised block, and return; no automatic map or ability pickup fires at arrival.
- [ ] Inspect reward/sealed/open cards, both room palettes, and all map pages at 1280×720 and 960×540. Sealed returns reveal no unseen room names. Opening a return changes the map's status and the Book's guidance.
- [ ] Pause, recover, reopen the Book/map, and Continue. Opened returns persist; fresh New Game closes both and removes Jump-Cut. Move practice cannot carry or save the campaign's returns.
- [ ] Check keyboard and controller feel and audio separately; automated scripted input does not assess those subjective qualities.
