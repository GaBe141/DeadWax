# Dead Wax playtest

Run `.\deadwax.cmd play` for the authored opening. Start with the chapter
checklist, then use `.\deadwax.cmd dev` for focused mechanics regressions.
Runtime errors are written to `.godot/deadwax-play.log`.

## Session

- Date/time:
- Commit (`git rev-parse --short HEAD`):
- Machine/display:
- Input device:
- Overall frame pacing: smooth / occasional hitch / frequent hitch
- Audio clarity and latency:

## Opening chapter

- [ ] Boot reaches the title screen; New Game begins at the Headshell. Continue is available only with a readable campaign checkpoint.
- [ ] Starting a new game over an existing one asks the player to confirm the replacement.
- [ ] The title, menus, room signage, player silhouette, and HUD remain legible at 1280×720 and in fullscreen.
- [ ] Headshell's movement/jump prompt and the first E/Y passage are understandable without external instructions.
- [ ] Horn Plaza clearly offers the west practice loop and the east market route.
- [ ] Holding Hood still beneath the horn for about 1.4 seconds produces its quiet answer. Polishing there grants one Shine.
- [ ] High Street's Looper gives three ticks and swings on four; the upper route lets the player pass without fighting.
- [ ] Four evenly spaced J/X strikes open Practice's physical lock and record Count-In once. Returning through the plaza is clear.
- [ ] A player who skips Practice can still open the Descent Gate with the same pattern; the Book's discovery state never gates the solution.
- [ ] In the Stalls, standing on the live groove and striking carries the player toward the upper walkway.
- [ ] A missed launch lands safely in the service lane; the steps return to either bank without a Refrain or restart.
- [ ] In the Yard, holding Set nearby for one bar frees a voice. Striking another demonstrates the distinct shatter outcome.
- [ ] Neither combat nor mercy is required to leave the Yard; both choices remain readable.
- [ ] The Descent Gate blocks passage until its four-strike pattern is performed; the exit beyond it enters Overture Stair.
- [ ] Every stair can be climbed on the return trip with a normal jump.
- [ ] Overture Stair's lower passage enters the Bootlegger's stall; the return lands on its lower platform.
- [ ] No passage leads into an unfinished graybox.
- [ ] TAB, M, and G do nothing during normal chapter play.

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

## Scenery and depth

- [ ] The fifteen authored rooms have distinct distant architecture and a still field of paper light. The plaza reads as a town, the Stalls as a shuttered market, and the Well as a continuous shaft at its top, middle, and bottom.
- [ ] Walk and jump through a wide room and descend the Well: far and middle planes move gently with the camera; recovery and room changes introduce no scenery jump after the arrival settles.
- [ ] Floor engraving stays inside real platform faces, at least 10 pixels below their tops. Check the Stalls service lane, both Whistlers return stairs, and the Well climb: landing edges, gaps, passages, and player silhouettes remain clear.
- [ ] HUSH's point and the Tonearm's gesture, counted beats, sweep, and openings remain readable against the new backgrounds at 1280×720 and in fullscreen.
- [ ] Pause, the Book, and the shop freeze decorative motion and parallax. Reduced camera motion also stops both while playing; static scenery still reflects live encounter outcomes and palette changes.
- [ ] In an isolated native preview, A→B→A reprints every layer and restores the authored palette without changing geometry or rewards. The scenery suite checks this without granting campaign Refrains; development grayboxes retain their original halftone backdrop.

## Lighting

- [ ] The fifteen authored rooms have two to four fixed light sources each. Lamps, windows, and openings produce distinct pools of light without washing out print, grooves, passages, or boss tells at 1280×720 and in fullscreen.
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

- [ ] Raw strikes do not build resonance or remove HP from the muted dummy.
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
