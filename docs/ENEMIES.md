# DEAD WAX — Bestiary & Combat Specs (v1, 2026-08-08)

*Full combat design for the 8-type roster named in CAST.md. Numbers are in M1's units — see `game/scripts/`: strike reach 190px, parry window 130ms, resonance +0.14/hit and +0.35/parry, player hearing/aggro at crackle > 0.25 within 520px. Every value here is a starting knob, not a law.*

## The four combat laws (bind every enemy below)

1. **Telegraphs are heard first, seen second.** Every attack has a distinct pre-sound — a wind-up note — that lands 4-8 frames before the visual commits. A blind player should survive on audio alone (accessibility *and* theme: this is a world you fight by ear). The visual tell is confirmation, not the warning.
2. **Noise is the aggro economy.** Enemies wake at crackle > 0.25 within their hearing radius. Hooded (LIFT) you are near-silent and most enemies idle. **Every fight is optional to *start*; not every fight is optional to *finish*.** Striking is loud — the moment you commit to combat you announce yourself to the whole room.
3. **Mercy is a real option, and it always costs time, not health.** Wherever an enemy has a grief, SET-playing its next bar resolves it non-violently but slowly and defenselessly. The roster is secretly half puzzle: "how do I *not* fight this" is a design question we answer per enemy, not a blanket toggle.
4. **Depth re-tunes, it doesn't replace.** The same enemy in the dry Label vs. the thick Undersong is a different fight (shorter/longer telegraphs, dead vs. blooming shockwaves) — the roster multiplies for free. Depth deltas are listed per enemy.

## Damage model — HP + resonance (two bars, Sekiro-shaped)

*Locked in COMBAT_FEEL.md: "Sekiro in a music box." Every enemy has **HP** and a **resonance** meter, and you can win either way.*

- **HP** is the slow, safe, patient road: chip it with committed grounded strikes. On-beat hits meaningfully harder; **off-beat ~0.6×** (groove pressure — the accents don't glow pink off-beat, and it sounds flat).
- **Resonance** is the posture layer and the fast, spectacular road: hits +0.14, big/on-beat +0.24, **RUNG-BACK parries +0.40** and full stagger. Decays ~0.045/sec. At 1.0 the enemy **shatters — an execute from any remaining HP** (Sekiro deathblow), not merely bonus damage. Parry chains are the fastest route to a shatter.
- So skilled/aggressive/on-beat/parry-heavy play kills *fast and beautifully*; careful play kills *slow and safe*. Both valid. (Numbers are M1-unit starting knobs; parry window tightens 130ms → ~100ms for the hard target.)

**Shatter is not gore** — the enemy bursts into a scribble-splatter of the words it was mid-saying (word-splatter rule). Every shattered enemy says one last thing; the words are cheap, plentiful, and occasionally land like a knife. Even a flawless execute carries a hair of sorrow: combat here is *good to be good at* and *never triumphant* — the parry is the only pure-joy release, because it doesn't kill.

---

## 1 · DUST BUNNIES — *the world's killer, adorable*

**Where:** everywhere above the Scratch; drifting stragglers below. **Boil:** 2 frames (they're not alive, they're *accumulation*). **Threat:** trivial alone, oppressive in numbers.

**Behavior.** Hop in lazy arcs (no player tracking — pure Brownian drift). Their menace is a **muffle aura**: within ~140px of 3+ bunnies, your crackle *and* your strike shockwave radius drop ~40% — a mobile dead-zone. They don't attack; they *smother*. In a swarm your launches fall short and your parries go quiet (resonance gains halved inside the aura).

**Tell / counter.** No attack to telegraph — the design problem is *positioning*. A single on-beat strike pops a whole cluster in reach (they have no resonance; they just burst). The lesson they teach: sound is a resource the world can *take from you*.

**Mercy:** none needed — they're not grieving, they're dust. But the **polish verb clears them permanently**: hood-up near a bunny-nest wipes the wax, and the room stays clean on return. Cleaning house is the mercy; the Hound sneezes each time a nest pops.

**Depth delta.** Label: sluggish, easy to herd. Undersong: they clump into drifting *balls* that must be broken with a charged strike before they smother a whole gallery.

---

## 2 · THE WORN — *played-out ghosts; noise hurts them*

**Where:** the Overture (worn_gallery, overture_stair). **Boil:** flickering, translucent, thin as run-off ink. **Threat:** low, but they invert the combat premise.

**Behavior.** Drift along fixed paths, repeating a faded gesture (a wave, a bow, a step). **Harmless until you're loud.** Your crackle *wounds* them — a strike near a Worn makes it recoil and flail, and a flailing Worn lashes blindly at whatever hurt it. They are the game's first lesson that **fighting is sometimes the thing that makes a room dangerous.**

**Tell.** The recoil-shriek — a thin descending whine — precedes the blind lash by ~6 frames. Predictable, but you caused it.

**Counter / mercy.** Pass hooded and they never wake; a quiet player walks straight through. If provoked, they can be shattered (they have a small resonance pool) — but the book scolds you for it, gently, every time: *"they weren't doing anything. they were just remembering."* The intended solve is **don't** — the Worn Gallery is a stealth-teaching room disguised as a combat room.

**Depth delta.** N/A (Overture-only), but a handful drift down to the Landing post-Drop as a callback: the first thing the Unplayed teaches is that the Worn followed you down, still bowing.

---

## 3 · LOOPERS — *the honest rhythm teachers*

**Where:** near the Scratch both sides; verse_warren_s; high_street (the parry-tutorial Looper). **Boil:** 2 frames — Stuck gone feral. **Threat:** low-moderate; perfectly fair.

**Behavior.** Their **2-bar loop IS their attack pattern**, and it never lies. A Looper telegraphs on beat 1, winds on beat 2, strikes on beat 3, is open on beat 4 — forever, metronomic. The whole enemy is a teaching tool: it turns the player's on-beat strike / parry timing into muscle memory against a foe that literally cannot surprise you.

**Tell.** The count itself — you can hear the bar. Parry lands on the beat-3 strike (RUNG BACK), and because the timing is fixed, the Looper is where players *learn* the 130ms window before anything punishes mistakes hard.

**Mercy:** each Looper is a broken Stuck. Its **next bar** (a simple 2-note completion, learnable from a nearby Yard groove) frees it — it stops looping, stands, wanders off. A merciful player empties the warren without a single shatter. (The first Looper, in high_street, cannot be freed — its next-bar groove is behind the Count-In gate you don't have yet — so its ONLY resolution on the tutorial pass is the parry. Teaching by constraint.)

**Depth delta.** Undersong Loopers loop *slower and heavier* — same fairness, more commitment per swing; the blooming shockwave means spacing matters more than timing.

---

## 4 · SKIPPERS — *crackle-mites that move like your worst mistake*

**Where:** the Scratch's edges; undercross (densest). **Boil:** strobing. **Threat:** moderate; the first genuinely twitchy enemy.

**Behavior.** Tiny pink sparks that **jump-cut** — short teleports, always landing *on the beat*. They close distance in stuttering blinks and bite (chip damage, high frequency). Because they move on the world's tempo, a player who's internalized the beat can *predict* where a Skipper will be — off-beat panic gets punished, on-beat reads win. They are the Jump-Cut refrain, weaponized against you before you can earn it yourself.

**Tell.** A rising *tick-tick-tick* accelerando that resolves on the blink — the closer the ticks, the sooner the teleport. Read the accelerando, strike the landing spot.

**Counter.** On-beat strikes catch them mid-materialize (they have 1 hp but tiny hurtboxes; the beat is the aim assist). Hooded, they lose your position between blinks and scatter — **stealth is a legitimate anti-Skipper tool**, not just an approach.

**Mercy:** none — they're not people, they're the wound's static. But once the player *has* the Jump-Cut (Act 2 secret), striking with it out reflects a Skipper's own teleport back onto it: a small, satisfying "now you know how it feels."

**Depth delta.** They only exist near the Scratch — they ARE the Scratch's spillover. Density rises approaching the Drop, foreshadowing.

---

## 5 · AUDITIONERS — *the baseline Unplayed; not attacking, auditioning*

**Where:** the Unplayed everywhere (verse_warren_n/s, verse_hall). **Boil:** 4 frames — they're alive, unheard, longing. **Threat:** moderate, and the emotional heart of the roster.

**Behavior.** They **reach for you.** Slow, open-armed pursuit; contact drains a chunk of your crackle-buffer *and plays them a syllable of themselves* — being touched by the Player is the only time they've ever been heard. They are not malicious. They are auditioning, and you are the audience, and the audition hurts you a little.

**Tell.** The reach-hum — a swelling open vowel — as arms extend; contact lands at the hum's peak. Sidestep the peak or strike the reaching arm to interrupt.

**The mercy is the design:** **SET-play any Auditioner for one bar and it leaves, satisfied — heard at last.** This is Combat Law 3 in its purest form: every basic fight in the deep has a nonviolent exit that costs *time* (you're defenseless while set) instead of *health*. A gentle player crosses the Unplayed slowly, kneeling, one soul at a time. An impatient player shatters them and the book notes the difference without judging it aloud: *"faster. sure."* The B5 audit remembers.

**Depth delta.** Undersong Auditioners reach through the swim-current — harder to sidestep, and SET takes a full extra beat underwater. The Green Room is full of them, seated, waiting; there they cannot be fought at all, only freed.

---

## 6 · EARWORMS — *the hook, weaponized*

**Where:** the Chorus (hook_pools, chorus_hall). **Boil:** smug 4-frame wiggle. **Threat:** moderate; a debuff enemy, not a damage enemy.

**Behavior.** Burrow into your *audio*: on hit they infect you with a looping jingle debuff that **forces your crackle meter up** on a timer, no matter what you do — you get *louder* against your will, waking everything nearby. An Earworm doesn't kill you; it *exposes* you, turning a stealth room loud. The counter is thematic: you shake it by **striking exactly on-beat** three times — you have to out-rhythm the hook stuck in your head.

**Tell.** The infection lands on a distinctive two-note sting; while infected, a faint spiral SFX loops under everything (and the boil on Skip's own accents won't settle). Miss the on-beat and the timer resets — panic makes it worse, which is the joke and the lesson.

**Counter / mercy.** No grief, no Rite — an Earworm is a parasite, not a person. But **REST (the Undersong refrain) silences an infection instantly** once you have it: hush the world, and the hook stops. Retroactively makes the Chorus a farmable stealth lane on the way back through.

**Depth delta.** Chorus-only. In the Hook Pools, soaking (standing in trance-loops too long) spawns them — the environment breeds them, tying enemy to puzzle (see PUZZLES.md, the soak timer).

---

## 7 · FERAL CHORDS — *three bodies attacking in harmony*

**Where:** the Undersong (bassline_e, the deep galleries). **Boil:** 4 frames, synchronized across all three. **Threat:** high; the roster's first real execution check.

**Behavior.** Three linked bodies — root, third, fifth — that attack *in harmony*: staggered strikes voiced as a chord, so hits arrive in a rolling arpeggio you must weave through. **Break the root note first** or the chord *re-voices* — the surviving two re-tune and a new root spawns, reforming. Kill order is literally music theory; a player who strikes the nearest body instead of the root fights forever.

**Tell.** Each body sounds its note before its strike; the root is the *lowest* pitch and pulses a fraction ahead of the other two (it leads the chord). Listen for the bass. The visual tell — the root's outline is fractionally thicker — confirms what the ear already found.

**Counter.** On-beat charged strike on the root collapses the whole chord at once (the satisfying solve). Parrying any single note staggers all three (they're linked — RUNG BACK ripples through the harmony). Hooded approach lets you pick the root before they voice up.

**Mercy:** the Chord is a trio of Unplayed who found each other in the dark and clung together — the closest thing to comfort the deep offers. SET-playing the *root* frees all three at once (they were only ever one grief in three voices). The book, if you do: *"they were holding onto each other. i get it."* Force-killing them one body at a time is the game quietly asking if you noticed they were friends.

**Depth delta.** Undersong-native; no shallower version. A late-Act-2 variant adds a fourth voice (a seventh) for dissonance — telegraphs get denser, the root harder to isolate in the mix.

---

## 8 · THE PRESSED — *what the never-played become when they stop hoping*

**Where:** Dead Wax (runout approach, locked_grooves). **Boil:** 0-1 frame — barely animate. **Threat:** high; slow, dense, final.

**Behavior.** Heavy fused clusters of the never-played, pressed together by decades of waiting. They don't reach, don't audition, don't loop — **they've stopped.** Slow advance, enormous poise; only a **fully-charged on-beat strike** cracks their crust, and inside is more of the same. They are what Auditioners become after the congregation's promise curdles — the Pressed are Soon's oldest disciples, past longing, past mercy's easy reach.

**Tell.** A low grinding pre-rumble before each slow slam — plenty of warning, no forgiveness on the punish (a Pressed hit is the hardest single hit outside a boss). The fight is spacing and patience, not reflex.

**Counter.** Charge (hold-strike partial) to full, land it on-beat, repeat. Parrying a slam is possible but brutal-tight (their wind-up is long, the strike-frame narrow) — a RUNG-BACK Pressed cracks wide, the high-risk high-reward line.

**Mercy — and the cruelty of it:** a Pressed *can* still be freed, but its next bar is buried so deep in itself that SET takes **three full bars** defenseless, in the hardest room in the game, to reach one soul. The game makes late mercy *expensive on purpose* — this is what the congregation costs, and it's the mechanical argument for freeing people earlier, higher up, while it was cheap. The B5 audit counts every Pressed you took the time for.

**Depth delta.** Dead Wax only. They are the floor of the world, in every sense.

---

## Encounter design rules (how these get placed)

- **One new idea per introduction room.** A type debuts alone, in a safe room, doing exactly one thing, before it's ever combined. (Loopers in high_street; Auditioners in verse_warren_n; Feral Chords in a wide bassline_e pocket with nothing else.)
- **Combinations are questions.** Dust Bunnies + anything = "can you fight with your sound muffled?" Earworm + a stealth lane = "can you stay hidden while something forces you loud?" Skippers + Loopers = "can you read two tempos at once?" Never combine two types the player met in the same hour.
- **The mercy budget.** Every combat room in the deep has at least one enemy that *could* be freed instead of fought — the player who never tries never knows, the player who always tries pays in time. Neither is wrong; the ending weighs it.
- **No arenas without exits.** Because every fight is startable-but-not-always-finishable, no encounter locks the door behind you except the five bosses and the two story seals. If a room can be fled, it can be fled — respect the noise economy the player is managing.
- **Silence is the reward.** Clearing (or freeing) a room *stays* clear on return — the deep gets quieter as you master it, so late-game backtracking through conquered territory feels like the world calming down. The soundtrack thins as you win. The quietest the game ever gets, before the ending, is a fully-pacified map.

## Encounter recipes (starter set, by room)

- **high_street:** 1 Looper (unfreeable — parry-only tutorial). Teaches the window.
- **worn_gallery:** 4-5 Worn on fixed paths, zero other threats. Teaches "don't."
- **undercross:** Skippers + drifting Dust Bunnies. Teaches beat-reading under muffle.
- **verse_warren_n/s:** Auditioner clusters + 1 Looper. Teaches the SET-mercy exit.
- **chorus_hall / hook_pools:** Earworms bred by the soak timer. Teaches REST as a cleanse.
- **bassline_e:** a lone Feral Chord in open water. Teaches root-first.
- **runout approach:** the Pressed, sparse and slow, between listening spots. Teaches the cost of waiting.
