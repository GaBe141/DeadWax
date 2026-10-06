# MTRDVN — Concept Brainstorm

*Session 1 — 2026-08-08. Working notes, nothing sacred. React, cross out, remix.*

## The compass

Decisions locked in so far — every idea below is measured against these:

- **Engine:** Godot 4 (GDScript, 2D)
- **Tone:** dark & melancholic — sorrow with beauty, not grimdark shock
- **Hooks:** traversal with a real skill ceiling + progression gated by *understanding*, not just items
- **Scope:** small & finishable, ~2–4 hours of play, one strong verb executed well

## Principles for a small knowledge-vania

1. **One verb, deep.** One core movement mechanic; upgrades *modify* that verb instead of adding new buttons. Celeste is a dash. Ori's identity is the bash. Small games die from eight shallow abilities.
2. **Knowledge gates are almost free content.** A door the player could technically open in minute one — if they knew how — costs nothing to build but multiplies the value of every room. This is Animal Well's whole trick, and it's the best scope-lever we have.
3. **Dense beats big.** Target a map you can cross in ~2 minutes once mastered. Every screen should earn at least two visits: once on the way through, once when you understand what you're looking at.
4. **The mechanics carry the sadness.** Melancholy shouldn't live only in the palette and soundtrack — the *verbs* should mean something. What the player does all game should be the theme.
5. **Feel first.** The prototype is one graybox room and the core verb. If it isn't fun to just move around for 10 minutes, no map will save it.
6. **Secrets in layers.** Layer 1: the main path. Layer 2: secrets a curious player finds. Layer 3: a small number of things almost nobody finds alone. Layer 3 is cheap when gates are knowledge.

---

## Concept 1 — KNELL *(working title)*

*You are the last ringer of a kingdom that went silent.*

**Premise.** Sound was the life of the bell-city: peals kept time, healed, held the walls up. Then the Great Bell cracked, and silence fell like ash. Everyone who could hear it died or froze mid-gesture. You are a small ringer carrying a hand bell — climbing, descending, crossing the dead city to ring the funeral peal that was never rung.

**The verb: TOLL.** One button. Ring your bell mid-air near a resonant surface and the returning wave flings you. The whole traversal language is sound:

- **Bronze plates** — launch pads; the angle of the plate shapes your arc
- **Singing stones** — sustain; hold the toll to hover or ride a slow current of sound
- **Chains and taut wires** — your toll travels down them as a visible wave; jump on and ride it
- **Glass** — shatters when tolled: one-time gates, shortcuts, secrets behind the pane
- **Moss, ash, deep water** — dead zones that swallow sound; no tolling here, plan your route
- **The dead** — toll softly near the frozen and their last moment flickers visible: part lore, part hint system

Skill ceiling: toll again exactly as your echo returns and the wave amplifies — bigger launch, chained bounces. Rhythm as mastery.

**Knowledge: PEALS.** The progression "items" are *songs* — tolling patterns like short-short-long. Mute seals on doors listen for them; certain peals still ash-falls, harden water, wake the frozen for a moment. You find peals engraved in murals, hummed by dying echoes, hidden in the tolling of far-off broken towers. The player physically inputs them — meaning someone who *knows* a peal can use it from minute one. Sequence-breaking is a feature. Four to six peals is a whole game.

**The melancholy.** You ring for the dead — every area ends with a toll for what was lost there, not a victory fanfare. And the ending writes itself: the funeral peal needs a whole bell, and the Great Bell is cracked. Your little hand bell is the right size to be a clapper. What you carry — maybe *who* you carry — completes it.

**Scope & Godot notes.** One input, physics impulses, raycast/area detection for surfaces — all bread-and-butter Godot. The art budget shifts hard toward *audio*, which is a much fairer fight for a tiny team than out-animating Hollow Knight. Combat can stay light: tolls knock back and deflect; two or three "broken instrument" bosses.

**Risks.** Rhythm-timing must feel generous, not strict. Audio design is now load-bearing — it has to be excellent. Needs a quick prior-art pass (bell motifs are common; a bell *as the whole movement system* is not, as far as I know — worth verifying).

---

## Concept 2 — CINDER & STONE *(working title)*

*The last unfinished statue, animated by a stray ember, in a kingdom that grief turned to stone.*

**Premise.** Sorrow petrifies — literally. The kingdom mourned something so hard it turned to stone mid-weeping. You are the one statue never finished, animated by an ember from the last kiln, and the only thing left that can still move — or burn.

**The verb: SHIFT.** One toggle between two states, and the whole world reads differently:

- **Stone** — heavy: fast falls that smash brittle floors, sink through water to walk its bed, immune to wind and ash-storms, slow crushing strikes
- **Cinder** — ash-light: drift on updrafts, get carried by wind currents, burn ropes/webs/thorns on contact, can't press plates or break anything

The depth is in the transition: momentum carries across the toggle. Fall heavy, shift light at the bottom of the arc into an updraft — slingshot. Sink to a lake bed, shift light — cork-launch. Every room with wind, water, or brittle ground is a puzzle *and* a tech playground.

**Knowledge.** Thinner here, honestly — the natural layer is *reading the world*: epitaphs on statues that teach hidden properties, wind schedules you learn by observation, which statues ring hollow. Workable, but it's bolted on rather than fused.

**The melancholy.** Grief as weight; letting go as burning. Mechanically loud, thematically clean.

**Scope & Godot notes.** The cheapest of the three to build — one boolean drives gravity scale, buoyancy, wind response, break force. A graybox prototype of SHIFT could exist in a day or two.

**Risks.** Weakest on your "knowledge" hook. Also the closest to existing weight-toggle games, so it needs a strong identity elsewhere.

---

## Concept 3 — WICK *(working title)*

*A lamplighter's ghost, carrying the last lantern through a kingdom the sun forgot.*

**Premise.** The sun went out — or this kingdom is so deep it never had one. The world only *exists* where light has touched it. You are the ghost of a lamplighter with one lantern, walking the old rounds one last time.

**The verb: CAST.** Throw the lantern. Pale-stone — half the architecture — is only *solid while lit*, so you throw light ahead of you to create your own footing, then recall the lantern and get a short pull toward it (a soft grapple). Braziers hold light you can leave burning; the map literally draws itself only where light has been, so cartography is the reward for thoroughness.

**Knowledge: THE DARK TELLS THE TRUTH.** The fused twist — some things are only visible when you *douse your only light*: truth-script on the walls, spirit doors, the paths of cold things. Every secret is a nerve check: stand in absolute dark, footing gone soft, and read. Light is safety and footing; darkness is knowledge. Choosing darkness is the game.

**The melancholy.** Tending lights for a world that's already gone. The courage mechanic *is* the grief mechanic — you learn the truth by letting the light go out.

**Scope & Godot notes.** Godot's 2D lighting and occluders handle this natively; the render trick is mid-cost, not scary. Tuning is the real cost.

**Risks.** Darkness frustrates when mistuned — players must never feel blind against their will, only by choice. Middle build cost of the three.

---

## My honest recommendation

**Knell.** It's the only concept where your two chosen hooks are *one system* — the same bell moves you (tolls) and unlocks the world (peals), so movement mastery and knowledge mastery reinforce each other instead of living in separate menus. It also repositions the art fight onto sound design, where a small game can be genuinely world-class. **Cinder & Stone** is the fastest to prototype and the safest feel-bet, but knowledge is bolted on. **Wick** is the most atmospheric and has the single best "secrets" mechanic (douse to read), but it's movement-lighter and tuning-heavier.

A remix worth naming: Wick's "douse your light" nerve-check could live inside Knell as *silence* — kneel, still your bell entirely, and in true silence the dead speak. Same emotional trick, zero extra systems.

## Open questions for Gabe

- Solo dev, or is anyone else involved (art? music?)
- Your art comfort zone — pixel art, vector, hand-drawn, "programmer art until it hurts"?
- Combat appetite: nearly none (Animal Well), light (Ori), or central (Hollow Knight)?
- Platform target — PC/Steam first?

## Next steps

1. Pick a direction (or remix) →
2. One-page pitch: fantasy, verb, 6-peal/6-gate progression skeleton, map sketch →
3. Graybox prototype in Godot: one room, the core verb, tuned until it's fun naked →
4. Quick prior-art pass on the chosen concept before we fall in love.

---
---

# ROUND 2 — Combat goes central

*Gabe's calls after round 1: remix / keep riffing, and combat should be CENTRAL — the Hollow Knight lane, not a garnish.*

**What this changes.** The core verb now has to be a weapon as much as a way to move — combat and traversal should share one input vocabulary, or we're building two games. And the knowledge hook gets its best job yet: gating *combat* itself, not just doors.

**Scope reality check.** Central combat at 2–4 hours = the Momodora: Reverie Under the Moonlight shape. Fewer bosses (4–6), each deep; a modest enemy roster (8–12 types) with real interplay; combat feel owns the first stretch of prototyping. Doable — but bosses are now the most expensive thing we make.

## Remix A — WAR-KNELL

*Knell, rebuilt so the bell is the weapon.*

- **Swing & toll.** The hand bell is a flail-weight melee weapon; ringing it mid-swing releases the shockwave. Same button grammar as traversal tolls — the fling that launches you off a bronze plate is the same wave that staggers a knight.
- **The parry is the soul of it: ring the blow back.** Toll at the exact moment an attack lands — catch it on the bell's mouth — and the force reflects as sound. Projectiles return as waves; melee attackers stagger. Crucially it's the *same timing muscle* as the echo-amplify traversal tech, so getting better at fighting makes you better at moving and vice versa.
- **Resonance as posture.** Enemies have a resonance meter (their crack, their flaw). Hits build it, parries spike it; at full resonance they *ring out* — shattered, vulnerable. You are a tuning fork looking for every creature's breaking frequency.
- **Combat peals = knowledge as combat depth.** Learnable input patterns usable mid-fight: a War-Peal that shatters guards, a Still-Peal that freezes projectiles in the air, and rarer, crueler ones hidden deep. Nothing stops a player who *knows* a peal from using it in the first fight — combat sequence-breaking as a feature.
- **The enemies are the Choir.** Broken instruments, hollow singers, things that kept performing after the silence. They telegraph in *sound* — a distinctive identity (and eventually you can read a fight with your eyes closed), with the accessibility flipside noted.

## Remix B — STONE & CINDER, STANCE-DANCE

*Cinder & Stone, rebuilt as a stance-combat game.*

- **Two stances, one toggle.** Stone: slow crushing arcs, hyper-armor, guard-crush, the drop-slam. Cinder: fast scorching flurries, and the ash-dash — dissolve through an enemy's body (i-frames) and reform behind it, burning.
- **The tech is the cancel.** Momentum carries across the toggle in combat too: heavy slam canceled into cinder flurry, flurry ender hardening into a stone counter. Stance-switching mid-combo is the skill ceiling, and it's the same muscle as the traversal slingshots.
- **Status pair.** Cinder ignites; Stone staggers; shatter = burn a staggered foe. Simple grid, deep interplay.
- **Knowledge: TRUE GRIEFS.** Every boss is a mourner — petrified or animated around a specific sorrow. The world's epitaphs, letters, and murals teach you *what each one mourns*. Knowing it unlocks the Rite (below).

## The cross-cutting idea — RITES *(works with either remix)*

Every major fight has two resolutions. **Force:** beat them down with pure combat skill. **The Rite:** end the fight through knowledge — perform, mid-battle and under pressure, the specific act that nothing but understanding would suggest: carry the thing they lost into the arena, stand where their beloved stood, still your bell into total silence at the right moment. No prompt, no quest marker — if you know, you know.

This is the full fusion of Gabe's pillars: combat is central, knowledge gates the *fights themselves*, and the melancholy lives in the mechanic — your weapon ends fights; your understanding lays them to rest. Cost: each boss is designed ~1.5×, so we buy it by making fewer bosses. Rites are also the perfect Layer-3 secret: force always works, so nobody is blocked, but the player who reads the world gets to be merciful.

## Open for Gabe's riff

- Which base verb feels like *your* game to swing for months: bell, density toggle, or something from Wick still calling?
- Gut reaction to Rites — core promise of the game, or optional garnish?
- What resonated / what left you cold in round 1? Name names, be brutal.

---
---

# ROUND 3 — UNDERTOLL: Knell, re-cast away from Silksong

*Gabe's call: loves Knell, but it pulls too hard from Silksong's first half. Verified the overlap (2026-08-08): Bellhart (town under a great bell), Bell Beast bellways (ring-to-summon transport), the ascent to the Citadel of Song through Pharloom "kingdom of silk and song," and the Needolin — a hold-button instrument that reveals secrets/opens doors/stuns. The collision is fiction and silhouette. The verbs — toll-propulsion, performed peals, resonance combat, Rites — have no Silksong equivalent. So: keep the systems, re-cast the world.*

## The conceit that changes everything

**In this world, sound has weight. It sinks. And it never dies.**

Every word, song, scream, and toll ever made slid downhill like water and pooled in the deep. The kingdom above is bone-dry silent — not cursed, *drained*. The deeper you go, the thicker the air gets with old sound, until at the bottom everything ever said is still playing, all at once, forever. The dead aren't gone; they're *audible* — you just have to dive.

## The five flips

1. **Descend, don't ascend.** Silksong climbs to a singing citadel. We dive into the Undertoll — the abyss where all sound drained. The Great Bell isn't the destination; it's the architecture you start under, cracked and mute over the shaft. The holy place is the bottom.

2. **You are heavy.** Not a graceful little ringer — you are the *clapper*, pulled from the cracked Great Bell and set walking. An iron pendulum with a body. Movement is momentum and arc — swings, weight, crash-through — a deliberately un-Hornet silhouette and feel. Tolls still launch you, but as *displacement*: your ring pushes against the sound-thick air like a jet.

3. **Sound is matter, and you can see it.** Waves render visibly, pool in basins, drip from ceilings, flow through sluices. Traversal changes by depth band, not by items: in the dry city tolls are short and dead (pure melee, brutal platforming); mid-depths, waves carry and launches bloom; in the deep you're swimming through liquid sound — slow, muffled, dreamlike. Understanding how depth changes your own body IS the ability system. Nothing is unlocked; everything is learned.

4. **The people were bells.** Hollow bronze-bodied folk whose speech was ringing; the Great Bell was the keynote the whole kingdom tuned to. When it cracked, they went out of tune — dissonance, madness — and then their voices drained into the deep with everything else. Enemies: detuned citizens ringing wrong, sound-starved things prowling the dry city, sound-gorged things wallowing below. Aesthetic: bronze, verdigris, foundry brutalism, abyssal dark — zero silk, zero bone, zero bug.

5. **Knowledge is heard, not read.** No lore tablets. The deep *preserves*: sunken conversations still playing at depth, a lullaby-peal a mother rang once, held forty fathoms down. The listening verb: damp your own bell — total stillness — to hear what's preserved nearby. Peals are learned by ear and performed by hand, usable from minute one by anyone who knows them. And Rites plug straight in: what every boss lost is down there, still audible, if you dove deep enough to find it.

## Noise as the economy

You are the loudest thing alive in a world that hunts by ear. Every toll spends secrecy — ripples spread, and things turn toward them. Silence conceals; ringing empowers. Traversal power and stealth trade against each other constantly, and going still to *listen* (the knowledge verb) means going defenseless in the dark. One diegetic system carries movement, combat, stealth, and knowledge. Silksong has nothing shaped like this.

## The ending image

At the very bottom, standing in the pooled voice of everyone who ever lived, the clapper does the only thing a clapper can do: strike. The deepest toll. The whole abyss rings like one great bell — the funeral peal performed with the world itself, and you as its tongue.

## Combat notes (still central)

- Resonance/ring-out posture system and ring-the-blow-back parry carry over from Round 2 unchanged.
- Depth bands re-tune combat the way they re-tune movement: dry city = dead air, short brutal melee; the deep = slow blooming shockwaves, spacing warfare. Same enemy, different fight at different depths — roster multiplier for free.
- Aggro-by-noise layers a stealth option under every encounter without building a stealth system.

## What we deliberately keep, and why it's safe

Bells and melancholy stay — that's what Gabe loves, and neither is ownable. What made it feel Silksong was *sacred-bell infrastructure + song-kingdom + ascent + graceful heroine*. All four are now inverted: profane drained bells, a kingdom that lost sound as a substance, a descent, and a heavy iron pendulum of a protagonist.

## Working titles

UNDERTOLL (strong), Knell (round-1 holdover), Deadbell, Fathom & Bronze.

## Open questions

- Does the clapper-protagonist / descent / sound-as-sea frame land?
- Undertoll as title direction?
- How stealth-flavored should noise-aggro get — light seasoning or a real pillar?
- Next step when ready: one-page pitch + graybox the toll in Godot (one dry room, one mid-depth room).

---
---

# ROUND 5 — THE SKIN DECISION: bells retired, DEAD WAX chosen

*Gabe flagged the bell motif twice — once pre-Undertoll, once after. Twice-flagged doubt on a years-long project is load-bearing. Principle applied: perception judges nouns and screenshots, not systems docs. Fix: change the nouns, keep the verbs.*

**Skins pitched:** the pit (Tommyknocker mine, counterweight protagonist, knock-codes, bell-pit reveal), Dead Wax (world-as-recording, needle protagonist), the Sounding (drowned harbor, anchor protagonist, fog codes), Rodwalker (buried storm, lightning-rod protagonist). **Gabe chose DEAD WAX.**

**What survived unchanged:** every system (strike/lift/set née toll/still/listen, noise-aggro, refrains née peals, Rites, resonance combat, depth-density traversal), the map skeleton, act structure, the M0 prototype's physics, the tone dials, the scope guardrails.

**What the reskin upgraded, for free:**
- The Scratch = the Act 1 boundary — the air-density seam now has a diegetic cause (above: played and spent; below: never played, pooled thick), and crossing it means crossing the wound you personally made.
- Grief is a skip; mourning is the next bar — the Rite system became literal to the world's physics.
- The Unplayed attack to be heard for one second — aggro as longing.
- B5 difficulty = your kindness audited (the Unheard shrinks by everything you played on the way down).
- The scene aesthetic became native: liner notes, bootlegs, dead-wax etchings, crackle-as-noise-meter. Music culture is the world now, not paint on it.

**Docs re-founded:** PITCH.md v2, WORLD.md v1, CAST.md v1. **Queued:** MAP.md + map.html reskin (structure identical, nouns new), game/ code renames (cosmetic), title screen thinking. UNDERTOLL retired as title; DEAD WAX is the working title.

---
---

# ROUND 6 — the protagonist re-skinned: enter SKIP

*Gabe's calls: keep the cutesy aesthetic; "the Needle" as a name is Silksong-adjacent (Hornet's weapon IS the Needle — verified, dodged); direction for the new look: "Nomura Kingdom Hearts-esque edgy, think Invader Zim." Also picked dust bunnies & polishing from the new-mechanics menu.*

**The universal fix:** nobody in-world says needle/stylus, ever. The Unplayed call the protagonist **the Player** — the one who makes grooves heard, and also literally the person holding the controller; the fourth wall carries grief for free. "Stylus" survives only in technical design docs.

**The name: SKIP** *(proposed this round)*. Her worn name for you from before — you hopped everywhere, it was cute — and then you skipped, and now your name and the world's wound share a word. Everyone who says "the skip" is saying your name without knowing it. Consequence: the secret sequence-break refrain renames the Skip → **the Jump-Cut**.

**The look (art v2 brief) — mall-goth cute, Zim × Nomura in OUR nouns:**
- Zim proportions: huge angular head, jagged crack-edges, big void-almond eyes w/ pinprick pupils. NO MOUTH — the muteness rule survives every restyle.
- Nomura kit translated: oversized stylus-lance wrapped in unspooled cassette tape (their chains/zippers → our tape); one chunky asymmetric boot; a worn 45 record sleeve as a hood/poncho.
- **Hood up = LIFT.** The stealth verb is pulling your hood up.
- **Pink accents = the crackle meter on the body.** Glow when loud, drain grey when hooded. Costume is the HUD; semantic-pink rule intact.
- 16px silhouette rule still binding. Palette unchanged (Zim's black/magenta/violet was already ours).
- Note: Invader Zim's palette convergence is free thematic gravity — lean in, don't cosplay it. Avoid KH nouns (keys, crowns, hearts) and Zim props (antennae, robot sidekick).

**Mechanics locked this round:** dust bunnies (the world's killer as adorable basic enemies; the Hound sneezes) + **polishing** (LIFT-hold near surfaces = buff shine back into the wax; restores small sounds; shine feeds Bootlegger trades).
**Parked, not deleted:** Everything Bops (per-band world-tempo idle bobbing), the Band (freed Stuck accumulate as a street band w/ real audio stems), B-Sides NG+ (flipped record, remixed score, worn names known). Revisit post-M2.

**Outcome:** SKIP adopted as the *working* name — Gabe wants a Hollow Knight-style late-game name-reveal twist, so the true name stays an open design slot (natural home: the [etched] layer, next to the etching-signature mystery — "the signature isn't hers alone"). Until the reveal ships, all docs and UI say Skip. Art sheet v2 redrawn in the Zim×Nomura style same day (art/direction.html §02).

---
---

# ROUND 7 — THE BIG BAD: pitching THE FERMATA *(pending Gabe's verdict)*

*Constraint: the disaster stays accidental and Skip's guilt stays whole — the antagonist must not have caused anything. The right big bad doesn't break the world; it NEEDS the world to stay broken.*

**THE FERMATA** — the hold-mark the Engineer wrote over the Last Bar, given a body. One job, one moment: hold the final note beautifully, then release on the conductor's cue. The conductor died mid-hold; her hand never fell. Post-skip it chose: the eternal almost over mattering once — if the song never finishes, its moment never comes; if it finishes, its moment comes AND ENDS.

- **The kingdom = the green room.** False-hope king of the deep: tells the Unplayed "your moment is coming, soon, stay ready" — forever. Doesn't erase (Hush), doesn't silence; HOLDS. Hook Pools = its opiate; Earworms = its heralds; Act-2 dust graffiti reads only "soon."
- **The stutter recontextualized:** it savors the world catching on the Scratch — the almost, on loop. It caused none of it: an opportunist of the wound. Guilt preservation intact.
- **The gratitude scene:** the only character who THANKS Skip. Undersong gate, non-fight: "Little father. You gave me forever. Nothing can be lost in a world where nothing ends. Stay. Be held." Absolution from the wrong mouth — the anti-Rite.
- **Thesis triangle:** Hush = never play them (erasure as mercy) · Fermata = never finish (suspension as self-preservation) · Skip = let it end.
- **Zero new boss budget: B5 recast** as the Fermata conducting the Unheard. Kindness audit unchanged but gains a face — every passage played on descent = a hostage freed; mercy starves the king. Full-Rites: it stands nearly alone, thin and terrified, holding an enormous baton.
- **Its Rite = THE CUE.** It is Stuck at the highest level — holding for a dead conductor. The next bar of a fermata is release; learn her conducting gesture (the hand-fall) from the deep and give the cue mid-fight. It holds. It looks. It releases — the most beautiful single note in the game, generations late — bows, spent, grateful, gone. **Force path:** its hold breaks and it dies mid-almost, never having mattered. Cruelest force-kill in the game.
- **Art:** face = the fermata mark itself (a vast heavy-lidded eye); conductor silhouette, baton as scepter. **Its boil LIES** — performs freed 4f grace, slips to 2f under stress: Stuck all along; the framerate law always tells the truth.
- **Alternates set aside:** the Dust as entity (pure, but entropy can't scheme); the living Scratch (potent, faceless, risks re-blaming the world's state on Skip's act instead of on a choice someone keeps making).

**VERDICT (same day):** Gabe: "right idea, push the design." Push-pass offered plain-English names (the Almost / Soon) over the theory-term, plus form options. **Gabe chose: SOON** (its graffiti as its name — the player reads it on walls for an act before learning it's a name) **+ sketch-and-Green-Room form** (unfinished drawing that refuses inking, one perfect lidded fermata eye, construction lines showing; the deep approach as its place-body, NOW SERVING: ∞; point of no return = a waiting room you cross by choosing to stop waiting). Added in the push: the HOLD (it can suspend your jump mid-arc — the Welcome: catches Skip mid-fall, examines, sets down gently, thanks him), the congregation (unfreed named Stuck can vanish under "soon." chalk — kindness-backlog becomes its choir), Hush history ("finish or free them"), the unfinished-sentence voice, and "There." — its only complete sentence, spoken at release. Fully canonized in CAST/WORLD/MAP/STORY same day. Fermata survives as its SIGIL only.

**Round 7.6 — THE TRUE NAME riff (pending Gabe's verdict):** Reveals stay separate (Threshold = role-dread, etching = name-grace). Lead pitch: **"Skip" is a real music-theory term** — melodic motion by leap (vs. step; disjunct vs. conjunct). The wound-word is also the word for how melodies move forward. Reveal at the etching: she named him for the interval, not the disaster — and the co-signature resolves: her final movement needs a closing interval no wax can hold (a leap can't press itself; it needs a player) — **she composed one more passage and cast it in iron.** Skip = the ending's final interval; no runtime because his timestamp is after the runout; "he hopped everywhere" = disjunct motion with eyes (no retcon — her cute nickname was a composer's pun all along). Consequence: the hold-and-release final input = choosing which name to answer to — the seat's (Soon) or hers (the leap). Alternates: the duet credit ("— & skip", quieter, maybe too small); the source-merge (REJECTED — the Voice's source stays the forever-unsolved layer).
**VERDICT: placeholder.** Gabe's call — the Leap stands as the *leading candidate*, not canon. The true-name slot stays officially open at the [etched] layer; nothing downstream may depend on the Leap being the answer. Revisit when the ending is closer to buildable.

**Round 7.5 — THE SINKING FEELING (Gabe's pitch, same day):** "Soon" upgraded from name to TITLE — the word for whoever holds the ending and can't let it end, and the player discovers THEY are next (House/Amber-assembly technique: all evidence pre-shown — graffiti addressed-not-signed, the Welcome as recognition, NEXT:________ ticket, Skip's blank name from the naming canon, the book's margin-copying tic — reveal = the re-ordering, staged at the Green Room threshold: the waiting ones STAND, the crackle stops (the game's only total silence — distinct from Hush's music-only dropout), the book assembles: "the ticket's blank because my name is." / "we are not taking the seat."). PAYOFF = the final input: the Last Bar is a HOLD-AND-RELEASE — press does nothing (the book auto-writes "soon" in Skip's hand), hold swells the note as long as the player dares, release ends the world; Rite path breaks the hold with the learned cue (free the villain with the gesture, then yourself), force path gets released BY the world after 10s + shakier final page. Ripples (no retcons): Hush's note third reading, the etching's "kept playing" = the antidote, Soon's Rite = rehearsal for your own. Canonized in STORY/WORLD/CAST. OPEN: does this merge with the reserved true-name reveal, or stay a separate second twist?

**Round 6.5 — HUSH adopted as the Protoman rival** (Gabe's call, same day). Reframed from debate-partner to wounded older brother: Hush = the FIRST STYLUS — wore everything he played, retired himself into the veil and the burnisher; his creed is autobiography. Protoman kit in our nouns: the whistle → THE DROPOUT (music cuts mid-bar = he's here); the shield → the burnisher deflects strikes flat (duels mute your whole combat language — win on naked spacing); sometimes-saves → 3 scripted deniable assists; the finale → only his burnisher can smooth THE SCRATCH so the Run plays through the wound (Rites done: beside you; Rites raced: with the Unheard). [played] secret: he still practices one bar, alone, nightly. Budget: 2 duels + 3 assists + finale ≈ the promised 1.5 bosses. Pronouns: he/him.

---
---

# ROUND 4 — THE LOOK: Undertoll goes Newgrounds

*Gabe's call: aesthetically differentiate with a scratchy mid-2000s scene style — "something made by an over-caffeinated preteen on Newgrounds." Quick prior-art check: the lane is open. Pizza Tower proved the NG revival sells, but it's a Wario-like; no major metroidvania owns this look.*

## Why this is the right kind of ugly

- **Differentiation, terminally.** Every post-Hollow-Knight metroidvania chases painterly gothic elegance. Silksong cannot be a scribble. This look ends the comparison conversation permanently.
- **Scratchy can be sad — it's proven.** Salad Fingers carried genuine dread and loneliness in wobbly Flash linework. LISA and OMORI hide devastating cores under crude surfaces. The register changes; the funeral stays real.
- **It's a scope gift.** Boil animation (2–4 alternating frames, 8–12 fps on 60 fps gameplay) is radically cheaper than Silksong-grade animation, forgives imperfection by design, and makes programmer-art-to-final a smooth gradient — the graybox can *become* the game.

## The big fusion: sound = ink

The art direction becomes diegetic. **Sound is the color, energy, and scrawl of the world** — so the aesthetic follows the conceit down the shaft:

- **The dry city (drained):** near-monochrome pencil on dirty paper. Sparse, still, dead air. Lines barely move. In true silence, the line boil *freezes* — the world holds its breath, and it's deeply wrong-feeling.
- **The mid-depths (sound pooling):** color bleeds in — marker over pencil, stickers, checkerboards, glitter-graphic shimmer. Line boil picks up. Everything vibrates a little, like the world is humming.
- **The deep (everything ever said, all at once):** full scene maximalism. MySpace-wall-of-noise. Saturated, seething, gorgeous, too much — because it literally is everyone's voices.
- **Line boil is the noise readout.** Loud things wobble hard; quiet things sit still; your own recent tolling visibly shakes YOU — the aggro system rendered in linework, no UI needed. (Also a huge accessibility win: all audio information has a visual form for free.)

## Visual vocabulary

- **The clapper:** a kid's OC made real — heavy iron teardrop body, side-swept sweep of hair-stuff, a studded strap, a skull drawn on in marker by someone who loved it. The coolest character a 12-year-old ever designed, mourning something real.
- **Bell-folk:** stark Madness-Combat-adjacent silhouettes with crack-mouths. True ringing renders as clean concentric rings; detuned ringing as jagged scribble-bursts. When enemies shatter, they spill their *voice* — a scribble-splatter of everything they ever said. Gore, but made of words.
- **Peals as TABS.** Knowledge notated like guitar tablature scrawled in a notebook — period-perfect, and it solves rhythm notation diegetically. The pause map IS the notebook: graph paper, doodles, tally marks, x_X in the margins, coffee rings.
- **UI: Flash-game chrome.** Chunky beveled buttons, a preloader-gag loading screen, options menu with cheat-code-menu energy ("quality: LOW"). Sincere in its insincerity.

## Audio direction: Audio Portal-core

Bells stay the spine, but arranged through the 2006 Audio Portal: MIDI-metal and breakcore in combat, trance loops pooling in the mid-depths, drum'n'bass, bell-sampled post-hardcore. The deep is a mashup of every genre at once — it's all sound ever made, of course it's breakcore. Then the ending: everything drops out to one true, clean bell tone. The one fully sincere moment in the game, earned by two hours of noise.

## Tone amendment to the compass

The melancholic CORE stays; the REGISTER changes — from hushed gothic to loud, scrappy, unhinged-on-the-surface (the LISA/OMORI model). The game is allowed to be funny now. The funeral is not.

**Dials for Gabe to set:**
- Humor level: deadpan-sad with occasional mania ←→ fully comedic surface, sad underneath
- Edge/gore level: suggestive scribbles ←→ full 2006 casual splatter (made of words, per above)

## Production notes

- Draw in Krita (scratchy raster brushes, pencil texture) — no rigging, no tweening; pure frame-by-frame boils in Godot AnimatedSprite2D.
- Visible construction as style: pencil ghosting, white-out corrections, paper grain, the notebook conceit everywhere.
- Hard art rules required or "crude" reads as "unfinished": one line-weight logic, one palette per depth band, silhouette-contrast rules for readability in the maximalist deep.

## Risks

- Readability in the loud zones — maximalism needs discipline (enemy silhouettes always win the contrast fight).
- Sincerity budget — comedy must never touch the Rites or the ending.
- Nostalgia-bait hollowness if the style is only references; ours is load-bearing (boil = noise, color = sound), which is the defense.

---
---

# CONVERGED — Dials set (2026-08-08)

- **Title:** UNDERTOLL (locked as working title)
- **Humor:** deadpan-sad with bursts of mania — the Salad Fingers lane. Quiet sorrow as baseline; the world occasionally erupts.
- **Edge:** word-splatter only — shattered enemies spill scribbled voices. Visceral, abstract, ours.
- **The Stealth Rule (Gabe's):** noise-stealth is a *non-negotiable mechanic in select mid-game boss fights* — those fights teach it under pressure. But stillness is never an unlock: it works from minute one, so second-run players (or anyone who knows) can use it from the very first encounter. Same law as peals and Rites: **the only gate is knowing.**

Brainstorm closed. Distilled into PITCH.md — that's the reference doc now; this file is the archaeology.
