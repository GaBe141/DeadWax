# Dead Wax playtest

Use this checklist for a 10–15 minute prototype pass. Run `.\deadwax.cmd play` from the project root; runtime errors are written to `.godot/deadwax-play.log`.

## Session

- Date/time:
- Commit (`git rev-parse --short HEAD`):
- Machine/display:
- Input device:
- Overall frame pacing: smooth / occasional hitch / frequent hitch
- Audio clarity and latency:

## Cross-room checks

- [ ] The game opens at 1280×720 in **The Label** with HUD and synthesized audio.
- [ ] A/D or arrows move; Space jumps; J/X strikes; K/C holds Hood; L holds Set.
- [ ] R respawns the player. Tab advances rooms and wraps after room five.
- [ ] Refrains and discovered techniques persist through R/Tab, but reset on a fresh launch.
- [ ] Hood noticeably slows movement, quiets crackle, and muffles the audio bed.
- [ ] Controller mappings work, if a controller is available.

## 1. The Label

- [ ] A strike near a live groove launches Skip; a strike in dead air does not.
- [ ] On the first visit, an ordinary jump cannot reach the high shelf above the spawn.
- [ ] The nearby live groove cannot carry Skip through the baffle to that shelf.
- [ ] Striking again as the groove echo returns produces **ON BEAT** and a stronger launch.
- [ ] Four evenly spaced strikes open the unsigned groove-lock.
- [ ] The spent-wax gap and wall-groove shaft are readable without explanation.

## 2. The Practice Room

- [ ] Holding Hood near dull wax for about 1.2 seconds grants one Shine.
- [ ] The dummy hears crackle, ticks three times, then swings on four.
- [ ] A mistimed defense causes knockback and increments hits taken.
- [ ] A strike in the 100 ms parry window produces **RUNG BACK**.
- [ ] Five ordinary nearby hits—or enough resonance—shatter the dummy.
- [ ] Four evenly spaced strikes open the signed count-in door.
- [ ] Opening the door adds COUNT-IN to the HUD; the pattern worked before it was recorded.

## 3. The Verse

- [ ] An Auditioner approaches and gives a readable rising reach tell.
- [ ] A strike/parry breaks the reach as expected.
- [ ] Holding L/Set nearby for about 1.2 seconds frees an Auditioner peacefully.
- [ ] Fighting another Auditioner demonstrates the contrasting shatter outcome.

## 4. The Unplayed

- [ ] Two directional air-strike breaths work before landing.
- [ ] Landing, groove launches, and pogo hits refill breaths.
- [ ] Air-striking a nearby enemy produces an upward-biased pogo bounce.
- [ ] Every pogo also registers a hit; striking just outside hit range does neither.
- [ ] Touching the record at the climb-out unlocks GATHER and updates the HUD once.
- [ ] Gather does not add a third breath here: The Unplayed still refills to two.

## 5. The Smoothed Floor

- [ ] Raw strikes do not build resonance or remove HP from the muted dummy.
- [ ] Three successful parries win the bout.
- [ ] The third parry produces **the bout is yours** without shatter effects.
- [ ] Tab returns to The Label.

## 6. Gather return to The Label

- [ ] One dry-air strike now launches Skip; a second does not until landing or respawning.
- [ ] A jump followed by the one Gather breath reaches the high shelf above the spawn.
- [ ] R refills the one dry breath, and the room's dry look/strike wave remains dry.
- [ ] Tab around to The Unplayed again: the Gather pickup stays gone and capacity stays two.

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
