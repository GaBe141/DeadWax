# DEAD WAX — One-Page Pitch (v2, 2026-08-08)

*(Formerly UNDERTOLL. Same systems, new skin — decision record in BRAINSTORM.md, Round 5.)*

**Logline.** You are SKIP — the little player who gouged a scratch across the world's master recording — descending the groove to play everything that never got heard, all the way to the dead wax, where the Engineer etched the ending. *(Skip is a working name; the true name is a late-game reveal. In-world, the role is called the Player — nobody in the game ever says "needle.")*

**In one breath.** A short, loud, scratchy metroidvania about grief, noise, and letting the song finish. Looks like a 2006 Newgrounds fever dream; sounds like the Audio Portal; ends on the last bar, played clean.

## The conceit

**The world is a recording.** A colossal wax cylinder, standing on end, its groove winding down the inside like a stairwell. The Engineer cut it long ago — pressed the Voice, her master song, into the deep — and the people are its tracks, given bodies. Then she died, dust gathered, and her stylus — you, Skip — skipped. The gouge is called **the Scratch**, and it cut the world in half: above it the song already played, long ago, and the grooves sit spent and silent; below it, *nothing has ever been played*. Decades of pressed sound waiting in the dark, pooled thick enough to swim in. The things down there aren't dead. They're **unheard**.

**Sound = ink.** The Label (the paper town at the top) is faded print and empty flyers; below the Scratch, scratchboard white-on-black scribble thickens with depth; the runout is a seething wall-of-noise, because it is literally everyone who never got played. **Crackle is the loudness readout** — line boil and vinyl crackle density instead of UI.

## The three verbs

- **STRIKE** — move and fight with one input. Drop your point into the wax and a burst of whatever's pressed there *plays* — recoil launches you, shockwaves hit, and every blow speaks a syllable of the world. Your strike spawns a brief loop; strike again **on beat** and it amplifies. The parry: catch a blow on your point and play it back.
- **LIFT** — hood up. A lifted point is silence itself: your 45-sleeve hood goes up, your pink accents drain grey (costume is the crackle meter — no HUD needed). You are playback incarnate in a world that hunts the sound of being heard; lifting conceals, and every strike spends secrecy. Never an unlock — works from minute one. **LIFT-held near a surface polishes:** shine buffed back into worn wax restores small sounds, heals the world in inches, and mints the shine the Typesetter trades in.
- **SET** — lower your point gently into a groove and play it soft: the listening verb. Above the Scratch you hear worn memories; below it, things no one has ever heard. Defenseless while set. Knowledge is played, not read.

## The one law

**The only gate is knowing.**
- **Refrains:** progression "items" are musical phrases, notated as guitar tabs in your liner-notes book, learned from bootlegs and etchings, performable anywhere by anyone who knows them — from minute one. (The Count-In, the Gather, the Rest, the Jump-Cut, the Last Bar.)
- **Stealth:** mandatory in select mid-game boss fights; available from the first room to anyone who already knows.
- **Rites:** grief is a skip — every boss is stuck looping its worst moment. Force shatters the loop. But a player who learned **the next bar** of their moment can play it mid-fight, no prompt: the loop completes, advances once, and ends. Force always works; knowledge is mercy.

## Combat (central)

Resonance as posture: hits and parries overdrive an enemy until it *peaks* and shatters — spilling a scribble-splatter of everything it ever said (word-splatter only; no gore). Depth re-tunes every fight: the spent grooves are dead-air knife fights; the Undersong is slow, blooming spacing warfare. The Unplayed attack because touching the Player means being heard for one second. They're not hunting. They're auditioning — and the basic Auditioner can always be resolved by SET-playing it a moment instead: mercy costs time, not health. Dust bunnies — adorable lint, the actual killer of the world — muffle sound in numbers. Full roster of 8 in CAST.md.

## The map is a record

Descent follows the groove. Six strata, small and dense (crossable ~2 minutes mastered):

1. **The Label** — printed-paper town at the top. Faded type, empty flyers. Strikes die in spent wax.
2. **The Overture** — the played grooves. Worn music, ghost-thin. First murmurs below.
3. **THE SCRATCH** — the Act 1 boundary and the Drop: crossing the wound you made. The reveal: the walls are groove-walls, the book sketches the helix — *"it's a record. this is the scratch. it's mine."* Below it, the air answers your strikes for the first time — because below it, the sound was never spent.
4. **The Unplayed** — two lobes, the Verse and the Chorus (the Chorus pools loop like trance). The mandatory-stealth boss lives here.
5. **The Undersong** — liquid unplayed sound; you swim through it. Maximalist, gorgeous, too much.
6. **Dead Wax** — the runout. Locked-groove graveyard, the bent Spindle, and the Engineer's etching — because engineers sign the dead wax.

The geography is the ending: traversal is playback. The finale is **the Run** — ride the groove from the Scratch to the runout at full speed, playing everything unheard as you pass, through your own scratch, to the etched last bar. The song finishes. The quiet afterward is the good kind.

## Tone & style (locked dials)

- Melancholic core, scrappy register: deadpan-sad with bursts of mania. The book is liner notes now — track listings, defaced flyers, chalk on wax. Comedy never touches the Rites or the ending.
- Scratchy mid-2000s Newgrounds scene style: boil animation (2–4 frames, 8–12 fps), visible construction, Flash-game UI chrome. Music culture is native, not decoration.
- Audio Portal-core soundtrack, now half-diegetic: the world IS the record. MIDI-metal and breakcore above; the Chorus pools loop trance hooks; the runout is every genre at once. The final bar: one clean, true note — the only sincere sound in the game.

## Scope guardrails

~2–4 hours. Six strata (five playable bands + the Scratch as a boundary set-piece). 5 bosses + a recurring rival (HUSH: two duels, three silent assists, the finale — see CAST.md). 5 refrains. 8–12 enemy types (depth re-tuning multiplies for free). One movement verb, deepened — never widened. Godot 4, GDScript. Art pipeline: Krita frame-by-frame → AnimatedSprite2D; graybox is allowed to become final art.

## Top risks

1. Strike feel — if playing yourself through the air isn't fun naked in a graybox room, nothing above matters. (M0 says it already is.)
2. Readability in the loud bands — maximalism needs silhouette discipline.
3. Sincerity budget — the register is allowed to be unhinged; the funeral is not.

## Milestones

- **M0 — Graybox strike. DONE** (built as "toll"; physics unchanged, rename cosmetic).
- **M1 — Feel-complete verbs.** Parry + resonance dummy, lift/aggro, tab-input refrain.
- **M2 — Vertical slice.** One chunk of the Unplayed, one boss with force path + Rite, one refrain learned by setting, first boil art test.
- Re-scope after M2. Nothing else gets detailed until the strike is fun.

*Full design archaeology: BRAINSTORM.md (rounds 1–5). World canon: WORLD.md. Cast: CAST.md.*
