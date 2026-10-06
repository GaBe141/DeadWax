# DEAD WAX — Puzzle Grammar & Placed Catalog (v1, 2026-08-08)

*Puzzles are built from the same three verbs as everything else — STRIKE, LIFT (hood/polish), SET — plus the refrains. Nothing here needs a bespoke mechanic; a puzzle is just a room that asks a verb a harder question. Room ids reference the atlas (`game/data/world_map.json`).*

## The one principle

**Every puzzle is a question about sound.** Not blocks and switches wearing a coat — the fiction and the mechanic are the same object. If a puzzle could be reskinned into a generic dungeon, it's wrong for this game. The player should never think "find the switch"; they should think "make the room hear me" or "hear what the room is saying."

## The six puzzle verbs (what the toolkit can ask)

1. **ON-BEAT (rhythm gates).** Doors, plates, and brittle wax that respond only to strikes *on the world's tempo*. The Count-In door is the teaching case: four even strikes, any tempo (M1's refrain_door.gd). Advanced: patterns (long-short-long), moving beats (a tempo that accelerates), and split-timing (two gates on offset beats).
2. **LISTEN (SET puzzles).** The answer is audible if you go still and defenseless. A locked groove hums the combination; a wall's true seam only shows when you hear where it's hollow. The cost is always the same: you can't act while you listen. Pure knowledge-gating — a player who knows the answer skips the listen.
3. **HUSH (LIFT/silence puzzles).** Some things only happen when *you* are silent. Sound-shy mechanisms that flee your crackle and settle when hooded; the Worn as moving cover; and the darkest version — surfaces that are only solid/visible when the room is quiet, so you must cross them making no sound. The stealth verb as a platforming verb.
4. **POLISH (restoration puzzles).** Hood-hold near dull wax buffs sound *back in*. Restore a dead groove and it starts playing — becoming a moving platform (a wave you can ride), a light source, or the missing note in a sequence. Polishing is the only *constructive* verb; it's how you fix a room rather than solve it.
5. **DENSITY (air/traversal puzzles).** Above the Scratch, strikes die in dead air; below, they jet you through thick air; GATHER thickens dead air anywhere. Whole rooms are gated on *where sound carries* — a gap you can't cross until you Gather the air in it, a chamber where the density changes as you drain it. Traversal-as-puzzle, the metroidvania backbone.
6. **DRAIN / FLOW (sound-as-liquid puzzles).** In the pools and the Undersong, sound *pools and flows*. Open sluices to drain a chamber (changing its floor, its density, and what its emptied walls reveal); redirect a current to carry something (or you) somewhere; flood a dead groove to make it sing. The Hook Pools are the tutorial; the Undersong is the exam.

## Difficulty & fairness laws

- **Teach dry, test wet.** Every puzzle verb debuts as a one-room gimme with the answer nearly visible, then recurs combined and unmarked. (ON-BEAT: the Count-In door → later, an on-beat gate *inside* a fight.)
- **The solution is always audible before it's visible.** A puzzle you can't yet solve should still *sound* solvable — the hum of the hidden groove, the wrong-density silence of an ungathered gap — so being stuck feels like "I don't know the word yet," never "I didn't see the pixel."
- **Knowledge-gates over item-gates.** Most locks open to a refrain or a rhythm the player could, in principle, perform from minute one. Sequence-breaking is a feature (MAP.md). The only hard walls are density (honest geography) and the two story seals.
- **No moon-logic, no mandatory grinding, no timed pixel-perfection outside optional secrets.** Frustration is never the goal; *tension* is. The nerve-check puzzles (crossing in silence, listening while hunted) are tense by stakes, not by twitch.
- **Anti-frustration net.** Any puzzle unsolved for ~90 seconds gets a diegetic nudge: the book scrawls a hint in its own voice (never a UI popup), escalating from oblique to plain on repeat failures. The Typesetter also sells "margin-markers" (shine) that annotate a stuck room's map cell with what verb it wants. Hints cost nothing but pride.

## The mercy thread (puzzles that are secretly people)

Half the deep's "puzzles" are Stuck who can be freed — the Rite loop (hear the loop → find who loved them → learn the next bar → give it back) is itself a puzzle template. The named micro-Rites (Addie, the Postie, Walt, Tick) are the taught cases; the roster's mercy exits (Auditioners, Feral Chords) are the freeform ones. **A puzzle whose solution is kindness should never *look* like a puzzle** — no prompt, no marker, no fanfare. The player who treats a grieving thing as a lock to pick has already lost the room's real question.

---

## PLACED CATALOG (by room, atlas ids)

### Act 1 — the taught verbs

- **practice_room — the Count-In (ON-BEAT, teaching).** Four even strikes open the signed door. The whole point is that the *unsigned* version (unsigned_alcove) has no instructions — you're meant to try the Count-In there on a hunch, and be right. Teaches: rhythm gates, and that knowledge travels.
- **the_stalls / stall_cache — the Glass (ON-BEAT, secret).** Display glass only shatters on an on-beat strike (a normal strike bounces off, comically). The cache behind it is a ribbon. Teaches: on-beat as a *key*, not just a door.
- **whistlers — the Wind-Jets (HUSH + DENSITY, traversal).** One-way sound-jets carry you up; going *down* against them requires hooding (silence drops you through). First HUSH-as-platforming beat. Return with Gather to ride them both ways.
- **groove_yard — the Chorus of Names (LISTEN, teaching + gated).** Most graves are silent; a few hum. SET at a humming grave to hear a worn name or a next-bar (Addie's answer lives here). Under REST-quiet (Act 2 return), three *more* graves become audible — one says "Vess." Teaches: listen, and that listening deepens with tools.
- **overture_well — the Climb (POLISH, light).** The shaft is dark on the way up; polish dull grooves on the walls to light footholds that then play faint platform-notes. First POLISH-as-construction beat, and the well's crack hides a bootleg only reachable by the lit path.
- **label_balcony — the Stared-At Balcony (DENSITY, Act-1-visible/Act-2-solved).** Seen from below all of Act 1, unreachable: the gap's air is dead. GATHER (Act 2) thickens it; the strike-jet crosses. The archetype "promise now, keep later" room; pays a fragment and the town-from-above.

### Act 2 — the combined verbs

- **hook_pools — the Soak & the Sluices (DRAIN/FLOW, marquee puzzle).** Two entangled systems: (a) **the soak timer** — standing in a trance-loop pool too long drifts you and breeds Earworms (enemy↔puzzle link, ENEMIES.md #6), so the pools are a hazard you route *through*, not rest in; (b) **three sluices** that drain the chamber in sequence. Drained, the floor changes and the emptied basin walls reveal tab-glyphs. Draining in the *right order* (a sequence learned by SETting the pool's own overflow) opens **drain_tab** (a fragment). The Chorus's centerpiece; teaches DRAIN fully.
- **welcome_gate — the Held Air (DENSITY, post-scene traversal).** After the Welcome, Soon's lingering hold-pockets hang in the air as free suspension-stalls — step into one and your jump *holds* at its apex until you strike out of it. The villain's touch, repurposed as a traversal grid: chain held-pockets to cross a chamber with no floor. Uniquely uses the antagonist's own mechanic as your tool.
- **the_mechanism (post-B3) — the Corpse Ladder (POLISH + traversal, shortcut).** The dead Changer's arms are dull, frozen mid-reach. Polish them and they twitch back to a slow cycle — becoming a rising platform-ladder that opens the welcome_gate ↔ undercross shortcut. A boss arena that becomes a fast-travel node by restoration. Teaches: even the unmournable machine can be *useful* dead.
- **verse_crawl — the Crushed Passage (ON-BEAT, secret).** A collapsed wall that only cracks to an on-beat charged strike, and only while a Last-Bar fragment inside is humming (so you hear it's there before you can reach it). A one-screen "I hear something behind this wall" itch.
- **bassline_w side gallery — the Stilled Current (DRAIN/FLOW + REST, gated).** A current too strong to swim runs across the only path; REST (learned deeper, so this is a return-trip solve) freezes it mid-flow into a walkable ribbon of suspended sound. Teaches REST as a traversal tool, not just a combat cleanse; pays a bootleg.

### Act 2/3 — the mastery rooms

- **whisper_strata — the Column (LISTEN, mastery + story).** The deepest listening puzzle: a vertical column where different heights, in full stillness, play different memories — but the currents and the Feral Chords mean *staying* still is the challenge. You must create pockets of safety (clear or free the room) to hear the full lore, including the cue ("...and there.") and the Last Playback approach. Listening as the reward for combat mastery. Where REST is learned.
- **mispress — the Wrong Room (multi-verb, secret + tech).** A pocket of misbehaving physics: gravity stutters, the beat runs backward, strikes echo before you throw them. Navigable normally only in confusion; **carrying the Jump-Cut makes the wrongness resonate** and momentarily *corrects* the room in pulses you must move through. The game's one "broken on purpose" space; hides the Jump-Cut's own home (mispress_core) and a ribbon.
- **the Run (Act 3 finale — not a puzzle, the anti-puzzle).** Deliberately noted here: the finale asks *nothing* of the player's problem-solving. After a game of thinking about sound, the Run is pure flow — every verb you learned, performed at speed with no lock in sight, because the world is finally solving *itself*. The absence of puzzle is the reward for all of them.

## Boss puzzles (cross-ref CAST.md — the fights that are also riddles)

- **B1 Tonearm:** the Rite is a LISTEN puzzle (her charge in the Yard) performed under combat pressure.
- **B2 Duet:** the whole fight is a HUSH puzzle — the arena is his hearing; you solve it by controlling your own noise, and the Rite is a LISTEN find (Vess's answer) played on-beat in the hand-off gap.
- **B3 Changer:** the *only* pure-combat boss — no puzzle, on purpose. The exam room. Its puzzle comes *after*, dead (the Corpse Ladder).
- **B4 Digger:** the Rite is a LISTEN puzzle with a twist — its runtime is chalked on a grave *below* it, so you must have explored past the boss to solve the boss mercifully.
- **B5 Soon:** the Rite is the CUE — a gesture (hold-and-release), not a refrain — learned in the Whisper Strata and performed in the fight's held moment. The final puzzle is a single input you were taught to make on someone else first.
