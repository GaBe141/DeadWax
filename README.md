# DEAD WAX — Quiet Wax

[![Godot checks](https://github.com/GaBe141/DeadWax/actions/workflows/godot-checks.yml/badge.svg)](https://github.com/GaBe141/DeadWax/actions/workflows/godot-checks.yml)

A playable journey through 21 authored rooms about a small Player, a street of worn records,
and the song still playing underneath it. Start at the Headshell, count in
the Descent Gate, then follow the Overture through wind-played grooves,
Addie's doorway, HUSH's duel, and the Tonearm. How you answer the Tonearm
changes what waits at home and opens the way into the six rooms beneath its seal.

The campaign now leaves more room for the world: ambient tutorial and sign
plates are kept in **Book → Journey → This Place**. Room names appear for
3.6 seconds on arrival, then fade. Small health diamonds, a quiet noise line,
and the B-side's remaining-time ring replace the permanent status paragraphs.
One nearby action cue appears at a time; deliberate E / Y conversations use
brief subtitles. The Book and pause menu keep the full guidance, while Move
practice and development rooms retain their detailed readouts.

All 21 demo rooms use shaded wax, stone and aged metal surfaces, with soft
light shafts and sparse dust around their local lamps. Daylight gives the
Label streets a cooler fill; the Overture keeps warmer interiors, and the
Unplayed carries violet and copper light. Small shadows beneath Skip and
the standing figures follow real platforms and fade during jumps. Pause
freezes the effects; Reduced motion holds decorative haze and parallax still.

The **Lost Pressings** equipment finds add three guaranteed rewards to the
return journey: a cabinet beyond the Stalls' groove, a high balcony in Horn
Plaza, and a sleeve on Addie's reverse face. Existing saves can collect them.
The Book carries their leads, and the folded map counts finds by region.

Open this folder in **Godot 4.7.x** and press **F5**, or run
`.\deadwax.cmd play`. The title screen offers **New Game** and **Continue**.
New Game opens with a 23-second illustrated prologue: a town in the grooves,
its fading song, and a little point taking its first steps. **Space / A**
advances a scene; **Escape / B** skips to the Headshell. **Watch opening**
on the title screen replays it without replacing your save. Continue goes
straight to your saved entry. Reduced motion presents still illustrations;
the captions and original synthesized score tell the same story.

A new journey begins with **a one-pixel shuffle per fresh direction press**.
Tap A / D or flick the left stick to inch left toward the walking soles behind
the cradle. Holding a direction does not keep moving. Recover **Walk** with
E / Y to restore ordinary movement; jumping and interaction stay available
throughout. Recover Strike in Horn Plaza, Hood on High Street, and Groove Riding
in Practice. Set waits in the Yard, the chain on the Overture Stair, and Pogo
in the Well. Earlier saves keep their existing walking and moves; choose New
Game to play this progression.

Each introduction room holds one new move. The Stalls applies Groove Riding;
the Descent repeats Count-In before combos arrive on the quiet stairs. Tick's
equipment trial appears on the return journey after opening the Descent Gate,
giving the first Practice visit room for its rhythm lesson. Existing journeys
that already discovered the trial retain access. Movement and combat speed
are unchanged.

After Walk, Skip builds into a run and carries a brief coast when you release
the direction. Reversing takes a little commitment; Set plants more firmly.
Top speed, jumping, airborne steering, and combat timing remain familiar.

Everything is built from code at runtime, so an empty editor viewport is
expected. The Label, Overture, and first stretch of the Unplayed are authored;
the remainder of the planned 53-room world is still development scaffolding.

The lightweight project commands are:

```text
.\deadwax.cmd doctor  check the local toolchain and repository
.\deadwax.cmd play    play the campaign with a local runtime log
.\deadwax.cmd dev     open the original mechanics rooms and planned-world tools
.\deadwax.cmd editor  open the project in Godot
.\deadwax.cmd check   import resources; run all sixty-one native test suites
.\deadwax.cmd vibe    start Mistral Vibe in this repository
```

See `PLAYTEST.md` for campaign and mechanics playtests, and `ROUTING.md`
for the authored route and development atlases.

## The opening chapter

```text
HEADSHELL <-> HORN PLAZA <-> STALLS <-> YARD <-> DESCENT GATE <-> OVERTURE STAIR
                 |   |
           HIGH STREET <-> PRACTICE ROOM
```

The plaza is the junction: west leads to the Looper and Tick's Count-In
lesson; east leads to the market's first movement gate. Practice also returns
directly to the plaza. Find Strike, then open Tick's listening door with four
even strikes and recover **Groove Riding** beyond it. Return to the Stalls
and strike its live groove to reach the eastern bank. A missed launch has a
low western route back to the takeoff; ordinary jumps cannot cross the tall
eastern step. Count-In works before the Book has recorded its name.

High Street's upper walk holds the **Hood** and avoids its Looper. The
**Set** waits on the Yard's western approach, before its first voice. Its
voices can be heard or shattered with the moves you have recovered. The
**Three-Strike Chain** waits further down, on the Overture Stair's middle landing.

The first Yard voice carries a half-remembered name. Stand near it with
**Hood** raised for its two notes, then lower Hood and begin holding **Set**
in the silence. One answer is enough. The voice gives you time and will try
again; holding Set before the phrase does not answer it. Visible note marks
and a short nearby cue carry the exchange with sound off or Reduced motion on.

Hearing it completes a warm engraving where it stood. Stay nearby and its
finished phrase returns quietly; shattering leaves a fractured impression.
Both choices survive recovery and Continue, including old saved outcomes.
The second Yard voice retains ordinary sustained Set. The road stays open,
and neither choice grants Shine, techniques, or a Refrain.

## Into the Overture

The old listening point is now the passage into the Bootlegger's stall.
Continue an existing demo save to carry on from the room where you stopped.

```text
OVERTURE STAIR <-> BOOTLEGGER <-> WHISTLERS <-> ADDIE <-> OVERTURE WELL
                                                               |
                                                        WORN GALLERY
                                                          |      |
                                                     HUSH <-> THE ARM
```

The gallery's direct passage to the Arm opens after reaching the arena from
HUSH's side. The well and wind course have return routes, so the descent
does not strand you below the Label.

HUSH's burnished floor asks for three parries; ordinary hits do not win his
bout. The Tonearm points up once and never attacks first. Striking commits
to its measured sweeps; openings let you strike back. Staying close and
holding Set offers another answer. Both outcomes persist, and the final
listening point asks for E/Y after the encounter is resolved. The Headshell
has different words and scenery when you return.

The first descent uses earned Groove Riding, wind, and ordinary jumps.
The Well's lower resting shelf holds **Pogo**, which adds airborne rebounds
from vulnerable foes. After either Tonearm
outcome, a **Gather** pressing appears beside the open seal. Pick it up, jump,
then Strike near the crest to climb on one held breath. Landing refills it;
ordinary grounded attacks keep their footing. The nearby shelf offers a safe
place to try it. Jump-Cut waits in the restored North Warren.

## Beneath the seal

After freeing or shattering the Tonearm, the eastern passage in the Arm opens
into **The Drop**. The final listening point remains a separate choice: entering
the new region does not show an ending or collect Gather for you. Old completed
saves can return to the Arm and continue through the same passage.

```text
THE ARM <-> THE DROP <-> THE LANDING <-> VERSE HALL <-> NORTH WARREN
NORTH WARREN <-> DEEP GALLERY <-> SOUTH WARREN <-> NORTH WARREN
```

Maintenance ledges make the Drop a climb home as well as a descent. Beyond the
Landing, the Verse Hall and Warren offer upper walks around waiting voices and
an old pressing. The Deep Gallery has a quiet answer and two ways back through
the Warren. Every passage in this loop is usable in both directions with
ordinary jumps; the Landing's 190 px overlook offers an optional use for Gather.

Listen at the fixed posts with grounded **E / Y**. Voices retain their familiar
Set and strike choices, and the pressing can be fought or passed on the upper
walk. Resolved encounters stay resolved on return, recovery, and Continue.
The nine polish patches still fund the three optional shop purchases; these
rooms add no Shine. Restoring the lost phrase reveals a separate Refrain pickup.

An **Echo Spool** waits on the Deep Gallery floor. Stand beside it and press
**E / Y** to take it, then find the three-note pipe on the **South Warren's
upper walk**. Press E/Y and stay close for its two-second phrase. Carry the
recording to the receiver on the **North Warren's western terrace** and play
it there. The shutter opens onto a little listening alcove, and three answering
discs wake together. Return and press E/Y to hear it again. The spool stays
with you, and either encounter choice leaves the whole discovery available.

The restored receiver reveals **Jump-Cut** on the floor directly below it.
Take it with a separate **E / Y** press, then use **F / RB** to turn the record
over for up to twelve seconds. On the far face, two sealed returns can be
opened from deep within the world:

| Unseal from | Returns to |
| --- | --- |
| North Warren, upper eastern terrace | High Street, western floor |
| Deep Gallery, central lower floor | The Headshell |

Stand at the seam on the B-side and press **E / Y** to unseal it. A second
fresh press enters. Once opened, either end works on either side permanently.
Existing saves with the phrase already restored can return for Jump-Cut;
listening again is unnecessary. The map shows sealed/open returns once both
ends have been visited or the return is opened, and the Book keeps their leads.

The Landing's raised overlook holds a **Surveyor's Slip**. Reach it with
Gather, then press E/Y to keep its sketch of the Stalls balcony. The Book
retains the clue for the return journey. The slip changes no route or ability;
the waiting voice above the Stalls still asks for its own answer.

Both discoveries survive recovery and Continue. Recording and playback need
one fresh press and two uninterrupted seconds nearby on the ground; leaving,
opening a menu, or recovering cancels the attempt. Visible note marks carry
the sequence with sound off or Reduced motion on.

## A phrase to carry home

The Stalls' upper balcony is visible on the first visit, beyond the reach of
an ordinary jump. Return with Gather, jump beside its left edge, and spend
your breath to land above the shutters. A small voice is waiting there.

Stand beside it and hold Hood to hear three notes. In the silence, lower Hood
and press and hold Set. Answer twice; visible note marks and a short nearby cue
carry the same cues as the sound. The voice opens a passage between the loft
and the Worn Gallery, and its melody joins the Horn Plaza and Headshell when
you return. The folded map includes this second dashed shortcut.

Gather, the voice, and its passage survive recovery and Continue. Players
with an already completed demo can revisit the Arm for the pressing. The
discovery grants no Shine and leaves both Tonearm endings available.

## Living ink

Skip breathes and blinks at rest, leans into a running stride, stretches on
takeoff, and compresses on landing. Strikes flick the point forward; the Hood
slides into place and Set lowers the body into a listening pose.

Voices step and reach, the practice pressing bends and springs back, and
HUSH and the Tonearm carry their windups through contact and recovery.
The animation follows the existing combat clock. It never moves collision
shapes, changes damage ranges, or delays a strike. Pause freezes the poses;
recovery clears transient player and boss motion.

The Label and Overture have company, too. Tick nods through three beats and
loses the fourth; grounded E/Y lets him talk about the nearby Count-In door.
The Bootlegger rummages through tapes, looks up at Skip, and has different
words after the Tonearm's ending. These conversations advance once per press.

The Hound patrols beneath the plaza horn. Stand still with the Hood raised
and let it come close: it settles beside Skip and wags for quiet company.
Nearby strikes startle it briefly, and each freed voice widens its patrol.
A freed Addie putters beside her doorway and pats a returning Hood or Set
visitor. These small interactions offer company without replaying rewards;
shattered Addie stays gone. Existing saves carry these choices forward.

## Shine and the stall

Hold the Hood beside worn wax to polish it and earn **1 Shine**. Each of the
campaign's nine patches pays once, with a short `+1 Shine` receipt when
collected. Your full balance appears in the Book and the stall.

Stand beside the Bootlegger and press **B / D-pad Up** to browse. E/Y still
talks to him. Choose a piece, then use its Buy button; browsing pauses the
game. Escape, controller B/Back, or Leave closes the stall.

| Piece | Shine | What it does |
| --- | ---: | --- |
| Spare Groove | 4 | Adds one permanent health slot, taking the maximum from 3 to 4. Fills the added slot when bought. |
| Soft Lining | 3 | Raises Hood walking speed from 62% to 75% of ordinary walking speed. |
| Warm Thread | 2 | Stitches an amber trim around Skip's Hood. Cosmetic. |

Every purchase is permanent, applies immediately, and appears in the Book.
Already-owned pieces cannot be bought twice. The five patches available by
the first stall visit can fund either functional upgrade; all nine fund the
whole counter. No core verb, technique, or passage requires a purchase.
Recovery preserves your Shine and items. A failed purchase save refunds its
debit and applies no effect; old saves begin with the same Shine and an empty
purchase list.

## Rare pressings and echo trials

Three optional **Echo Trials** offer repeatable equipment hunts:

| Source | Where to find it | What answers |
| --- | --- | --- |
| Label | Tick's Practice, after opening the Descent Gate | Auditioner recordings; listening or striking both count. |
| Overture | Eastern Worn Gallery, beyond the Arm's service door | Test Pressing recordings. |
| Unplayed | Deep Gallery's lower floor | A mixture of Looper and Auditioner recordings. |

After recovering Strike, stand beside a trial press and use **E / Y** to
begin. The Label trial also accepts a Set-only player. Clear three waves,
containing one, one, and two echoes, then return to the press and use a fresh
**E / Y** to collect the result. The echoes use familiar combat rules. They
are recordings and never restore a resolved neighbour. Trial rewards grant
equipment and Offcuts; they do not grant story choices, Refrains, routes, or
Shine. Ordinary nearby wax and Count-In interactions still work during play.

There are **12 trial pieces**, four in each regional pool, fitted into
three slots: **Point**, **Sleeve**, and **Charm**. Every piece has a benefit
and a cost. Quicksilver Tip runs faster but brakes more slowly; Felt Cuff
quiets lingering noise faster but slows Hood movement; Glass Tip improves
air steering at the cost of one maximum health slot. Select a piece in
the Book to read its exact trade-off and source, then fit or remove it.

A claimed clear has a **10% chance of equipment**: the four regional pieces
have individual **4%, 3%, 2%, and 1%** chances. If 19 clears give no equipment,
the **twentieth clear guarantees a drop**, with missing pieces preferred.
Every clear also gives **1 Offcut**. Duplicate equipment becomes **5 additional
Offcuts**. After clearing a source once, the Book can **bind a chosen missing
piece for 40 Offcuts**, giving you a way to finish a collection without relying
entirely on chance. Offcuts are separate from the Bootlegger's Shine.

Equipment changes movement speed, ground acceleration, braking, air steering,
Hood speed, noise fading, or health capacity. Combined handling values stay
between 65% and 140% of their stock value; equipment's total health adjustment
stays between -1 and +1. Strike and parry timing, jump height, hit reach, and
Refrain permissions stay the same. Fitting extra health capacity does not heal
Skip; recovery fills it. Benefits apply only after the change has been saved.

Each source also has an optional **100-clear mastery ledger**, tracked
separately from finding all 12 trial pieces. These are completion goals, with actual
playtime depending on route, combat approach, and pace.

Opening a menu, leaving the trial bounds, or recovering ends an unfinished
attempt without spending a roll. A completed claim waits through menus, but
**collect it before recovering or leaving the room**. A failed claim save keeps
the claim available and restores the same roll for a retry.

## Lost Pressings

Three more pieces bring the equipment collection to **15**. These guaranteed
finds reward exploration with earned moves; each has a benefit and a cost.

| Pressing | Return route | Benefit and cost |
| --- | --- | --- |
| Copper Tip — Point | Ride the Stalls' groove to the first eastern shutter. Requires Groove Riding. | +15% ground acceleration; 10% less braking. |
| Seam Lining — Sleeve | Return to Horn Plaza with Gather and climb the high balcony above the homeward door. | +20% Hood movement speed; 10% less air steering. |
| Dusk Seal — Charm | Return beyond Addie's door with Jump-Cut and turn to the B-side. | +1 maximum health; 10% less running speed. |

Stand beside a sleeve and use a fresh **E / Y** to collect it. Collection saves
before showing success and leaves an empty sleeve behind. Fit it separately
in **Book → Equipment**; finding gear neither auto-equips nor heals. These
pieces have their own Book group and regional map counts. They cannot drop
from trials or be bound with Offcuts, and leave trial odds and pity unchanged.
All 21 campaign rooms and 26 passage pairs remain intact.

## Groove pressure

**Settings → Groove pressure** (off by default) makes the world keep time.
Each room has one beat: Tick's count (0.42 s) everywhere except the Arm,
which keeps the Tonearm's own count (0.46 s). While something in the room
is roused, a soft, even pulse marks every beat (the foes' own ticks carry the
phrase), and a small ring beside the health diamonds fills in the pocket.

- The pocket runs from 60 ms before a beat to 140 ms after it: 100 ms either
  side of a centre set 40 ms late, because the pulse, the screen and the pad
  all reach you late. A strike in the pocket hits big (the two-HP hit and the
  heavier resonance), rings a bright bite, and prints in colour.
- Off the beat, a strike is quieter, pitched down, and printed grey. The
  Accent keeps its gesture and follow-through but hits big only on the beat.
- Counting foes (Test Pressings, the High Street looper, HUSH and the
  Tonearm) begin each count on the room's beat, half a beat to a beat and a
  half after they decide to, so every tick and swing falls on it.
- The parry window, launches, breaths, reach and jumps never read the beat.
  The Hood silences the pulse; HUSH's muted floor and the Yard's quiet call
  never sound it.

Turn it off and everything returns to the classic rules at once: the Accent
alone hits big and every foe keeps its own count. The choice is stored in the
settings file beside volume and controller layouts, never in a checkpoint.
To compare, fight the Tonearm or a few Wax Palace floors with it on, then off.

## Levels and XP

Every confirmed hit, rung-back parry and kill earns XP. Freeing a voice earns
none.

| Earns | XP |
| --- | --- |
| A light hit | 2 |
| An Accent, hot-groove or pocket hit | 4 |
| A rung-back parry | 5 |
| Shattering a voice or a Test Pressing | 15 |
| Shattering the High Street looper | 20 |
| Winning HUSH's bout | 40 |
| Shattering the Tonearm | 80 |

A story foe's hits and parries pay at most 40 XP over its whole life, and its
kill pays once, so you can't farm a fight by striking and then recovering or
leaving the room. Echo Trial copies are new foes every time, so the trials
are the place to grind. Move practice earns nothing and always plays at
level 1.

Level 2 takes 40 XP, and each level after asks 20 more than the last; level
12 (1,540 XP) is the cap. Each level gives one choice, made on the Book's
**Level** page:

- **Ring** (5 ranks): +15% resonance from your strikes and rung-backs, so
  voices and stands peak and shatter sooner. The Tonearm has no resonance.
- **Body** (4 ranks): one more health notch, arriving filled.
- **Bite** (4 ranks): +25% health damage per hit, on every foe.

The caps add up to more than the eleven choices, so a build has to pick. The
parry window, reach, timing, launches and jumps never change. A choice is
saved before it applies; if the save fails, nothing changes. XP is saved with
the next checkpoint (passages, outcomes, the Book, pause, quit). An older
checkpoint without XP continues at level 1.

## Small moments

Skip and the interface now move in the small places between fights:

- **The Book** swings open like a cover, and its pages turn when you change
  tabs. Closing it folds the Book shut into Skip's hands; back in play he
  snaps it shut and tucks it into his coat.
- **Finds** — a move, a Lost Pressing, the map, a Refrain, the Echo Spool,
  the surveyor's slip, trial gear — are raised overhead once they are yours.
  A find whose save fails is never raised.
- **Left alone**, Skip taps along (to the room's beat when Groove pressure is
  playing), looks around, and polishes his point. Hard turns skid up dust and
  jumps kick up puffs.
- **Talking**: Skip turns to face Tick, the Bootlegger and listening posts, and
  nods as each line arrives.
- **Passages** brush the old room away in ink; the next room loads exactly as
  fast as before and is live underneath.
- **The map** unfolds along its creases.
- **The HUD**: a lost health diamond cracks and falls away, a restored one
  re-inks, the XP line fills smoothly, and a new level rings out.

None of it waits: menus take input and focus at once, and Skip's moves,
timing and reach never change. Pausing freezes the world's motion.
**Reduced motion** keeps the Book, map and HUD still and dissolves passages
instead of wiping.

## Saving and settings

The chapter saves at ability discoveries, passages, opened locks, resolved encounters, polishing,
discoveries, claimed trial rewards, equipment changes, the Book, pause, title,
and quit. Continue starts at the entry used
for the saved room, carrying recovered abilities, learned techniques, Shine, opened doors, encounter
outcomes, carried discoveries, equipment, Offcuts, bestiary notes, trial records,
and chapter completion. Resolved voices never
return to combat; polished wax cannot pay out twice.

Earlier demo saves remain valid. Their old Overture-Stair completion flag is
reinterpreted as an unfinished extended journey; room, entry, Shine, knowledge,
and encounter choices are retained. Completion now also requires a resolved
Tonearm encounter. An unfinished HUSH or Tonearm attempt resets on recovery;
a resolved encounter stays resolved.

The optional `abilities` object now uses internal **version 2** and records
the exact seven moves found. If it is absent in an older save, Continue retains
the complete legacy moveset. A version-one ability snapshot gains **Walk**
while keeping exactly its six previously listed move permissions; a partial
old journey never loses walking or gains other missing moves. New Game
explicitly saves an empty version-two list. Finding a part updates it only
after a successful write; explicit version-two partial lists restore exactly
without replaying pickups. The enclosing checkpoint remains version 1.

The version-one checkpoint accepts an optional `discoveries` object containing
the spool's stage and the survey slip. Older saves start with both uncollected
and retain their existing progress and balance. A failed discovery save leaves
the previous stage intact so the interaction can be tried again.

Its optional `collection` object keeps equipment ownership and fittings,
Offcuts, each trial's clear count and dry streak, the saved random stream, and
the bestiary. Older saves start with no equipment or materials; their existing
encounter choices fill the corresponding bestiary notes once. A failed equip,
binding, or reward save leaves the previous collection and effects intact.

The checkpoint is `user://deadwax-save.json`. Writes are validated and keep a
`.bak` recovery copy of the previous valid checkpoint. Volume, fullscreen,
reduced camera motion, and calibrated controller layouts are saved separately in
`user://deadwax-settings.cfg`. Reduced camera motion removes camera smoothing
and shake, and freezes decorative ambient motion, parallax, and slow lamp
modulation. A standard gamepad uses Back to pause and Start for the Book;
a calibrated GameCube controller uses Start to pause and Z for the Book.
Skip has three health slots, or four with Spare Groove;
fitted equipment can adjust that capacity by one in either direction. Losing
them recovers Skip at the active room entry with full health and preserved progress.
Continue also starts there at full health.

## USB GameCube controller setup

Connect the controller or adapter, then use the mouse or keyboard to open
**Settings → Controller setup** from the title or pause menu. Choose the
controller if more than one is connected. Let both sticks, triggers, and
buttons rest, choose **Ready**, then follow all **18 prompts**. Move sticks
fully in the requested direction and squeeze L/R fully. Release every control
between prompts. **Retry** corrects the previous capture; **Start over** begins
again, and Escape cancels. Review the layout, then choose **Save layout**.

This learns the adapter's buttons and axes, including analog triggers and
D-pad axes. Your previous layout stays active until saving succeeds. The layout
belongs to settings rather than a campaign checkpoint and remains available
after New Game or Continue.

| Physical GameCube control | Campaign action |
| --- | --- |
| Main stick | Shuffle before Walk; run after Walk; navigate menus |
| A | Jump / confirm |
| X | Strike |
| Hold B | Raise Hood; B goes back in menus |
| Y | Interact / enter / listen |
| Hold L | Set; previous Book page while reading |
| R | Flip with Jump-Cut; next Book page while reading |
| Z | Open The Book |
| Start | Pause |
| D-pad Up / Down | Browse the nearby stall / open the collected map |
| C stick Up / Down | Scroll Book notes |

Unplugging releases held controls. After reconnecting or leaving setup, let
the controls return to rest before pressing again. On Windows, controller
input is ignored while the game window is unfocused; click back into the game
before testing. If the adapter is missing from the picker, reconnect it and
reopen the setup sheet.

## Controls

Jumping, interaction, and menus work from the start. Each fresh direction
press shuffles one pixel until Walk is recovered. Strike, Hood, Set, and the
attack refinements below also wait for their discoveries.

The gamepad names below describe a standard pad; a calibrated GameCube
controller uses the physical layout above.

- **A/D** or left stick: fresh taps/flicks shuffle; holding walks after **Walk**.
- **SPACE** jumps (stubby on purpose — the strike does the flying).
- **J** (or X) — **STRIKE**: hit nearby foes while keeping your footing.
  Strike can also parry. With **POGO**, jumping and striking a vulnerable foe
  gives an upward rebound. **GROOVE RIDING** enables live-groove launches and
  thick-air directional jets; live grooves take priority over foe rebounds.
  After finding **GATHER**, one air-strike breath follows you into dry rooms.
- **K hold** (or C) — **HOOD UP**: silence. Slower, softer, your crackle
  drains fast, the world goes lowpass-muffled, and things stop hearing you.
  Hold it beside dull grey wax to **polish** (mints shine).
- **L hold** — **SET / KNEEL**: listen to an Auditioner instead of breaking it.
- **W/S** (or arrows) — aim directional strikes while airborne.
- **E** (or gamepad Y) — recover a nearby ability, enter a passage, listen, use a discovery fixture,
  or start and claim a nearby Echo Trial.
- **B** (or D-pad Up) — browse the Bootlegger's stall while standing nearby.
- **I** (or gamepad Start) — open **The Book**, the full-screen inventory.
- **Escape** (or gamepad Back) — pause; Escape inside the Book closes it first.
- **F** (or right shoulder) — **FLIP**: turn the pressing over. Needs the
  **Jump-Cut**. Silent until you carry it.
- **R** respawn at the current room entry.

After collecting the folded map, **M / D-pad Down** opens it while exploring.
The Book also has an **Open map** button. **Journey → This Place** holds the
current room's objective and printed notes; reading it grants no moves or items.
In the Book, keyboard M opens the map;
the controller D-pad retains its usual selection controls.
Inside the Book, **Tab / Shift+Tab** or **LB / RB** changes pages. **PgUp /
PgDn**, the mouse wheel, or the right stick scrolls Journey, equipment, and bestiary notes.
During exploration, Tab's room cycling and G remain exclusive to the opt-in
development rooms below; there M continues to switch development atlases.

A ready strike answers immediately. Tap and Sweep are ready again after 200 ms;
Accent takes 320 ms with a little more follow-through. A press in the last 90 ms
of either cooldown queues one follow-up; holding the button does not repeat
attacks. Ground recovery lasts 100 ms at 80% movement acceleration for basic
strokes, or 160 ms at 60% for Accent. Turning and air steering stay responsive.
Hood, Set, damage, menus, recovery, and passages cancel a queued strike and its combo.

Ground run acceleration is **1900 px/s²**, release braking **2400 px/s²**,
and Set braking **3800 px/s²**. At 60 physics ticks, reaching the unchanged
**340 px/s** top speed takes about 0.18 seconds; a full-speed release coasts
about 21 pixels before settling. Air steering remains **1170 px/s²** with
**760 px/s²** neutral drag. Equipment still applies its stated handling
benefits and costs. Jump height, gravity, coyote time, hit reach, basic strike
cadence, and the 100 ms parry window are unchanged.

Before finding the chain, every attack is a single Tap. After recovering
**Three-Strike Chain**, connected hits link **Tap → Sweep → Accent**. Execute
the next strike within 650 ms to keep the chain; a fourth begins another Tap.
A miss or closed guard breaks the chain. Each stroke has its own jab, sweep,
or downstroke, with a light air sound. Actual hits add wax impact, sparks at
the target, and a short camera impulse; guards give a dry clack. Accent deals
two damage, finishing an ordinary four-health voice in three hits, without
increasing reach, launch speed, or the parry window. Its strength does not stack
with an on-beat groove strike. **Move practice** and development rooms allow
all three gestures in empty air. There, the three marks at the top right show the
current stroke and remaining **LINK TIME**.
The input line shows **RECOVERING**, **J / X · PRESS**, or **QUEUED** separately
from that chain timer. An early press briefly shows **EARLY · WAIT**; a queued
press executes once when recovery ends.

Skip's figure also carries the result: confirmed hits briefly hold the extended
point, closed guards kick the arm back, and successful parries brace the body
behind a raised brass point. Damage interrupts the old attack with an immediate
directional flinch. Pogo rebounds tuck the legs and turn the point down; ordinary
jumps and Gather retain their own poses. These short impressions pause with play
and change no attack, parry, movement, or damage timing.

High Street's **Looper** guards while counting three ticks, then swings on four.
Strikes cannot damage or rebound from its guard. Step outside its reach, or
parry as the swing lands, then use the one-second **OPEN** window to land a
strike. Its first unguarded hit starts the count. The upper route still passes
without fighting, and recovery resets an unfinished encounter.

Choose **Move practice** on the title screen to enter **The Wax Palace**, a
twenty-floor combat arena with all seven moves and stock equipment. The floor
stays empty until a fresh grounded **E / Y** at its central dial starts a run.
Auditioners, Test Pressings and guarded Loopers arrive in increasingly mixed
groups of one to four, with marked arrival warnings and room to move.
Listening or striking can clear an Auditioner; other opponents retain their
usual combat rules. Each clear restores health and gives you a breather;
return to the dial and press **E / Y** for the next floor. Clearing floor twenty
lets the same action start another run. There is no time limit.

Floor eight introduces the **Backcutter** alone. Its front guard holds while
it winds up; jump behind it, turn toward it and strike to break the guard.
It alternates a frontal swing with a marked vault over Skip, then attacks
back toward the place you occupied when it committed. The landing mark stays
fixed, so you can evade it or turn and parry the incoming side. Its parry
checks the direction of your executed strike as well as the usual 100 ms
timing. Every completed swing leaves a one-second punish opening; a rear
counter interrupts into one too. Later floors mix one Backcutter with ordinary
foes; their existing rules remain unchanged.

The Palace is a dim vaulted hall, with warm light at the central dial and
cooler lamps on either side. Stone and wax surfaces catch subtle light;
soft shafts, sparse dust and grounded contact shadows give the chamber
depth without obscuring guards or arrival marks. Shadows shrink and fade
as figures jump. Pause freezes the room, and Reduced motion holds the haze
and scenery still while combat and foot shadows continue to follow play.

**R**, falling, or defeat clears the current attempt and restores Skip at the
dial to retry that floor. **Esc / Back** pauses the run, and the Book also freezes
it; **Return to title** takes you back to the sleeve. Before starting, the open
floor still supports empty-air movement and combo drills. Practice has no
pickups, campaign exits or collection rewards. It uses temporary models and
never writes your campaign checkpoint, unlocks
progression, spends Shine, or records map visits. Continue resumes your journey.
Abilities, carried discoveries, and collections use disposable practice state, leaving
the campaign's recovered moves, spool, slip, equipment, materials, trial records, and bestiary
untouched. Equipment effects return to stock throughout practice.

Faint perimeter cuts acknowledge the immediate 120 px enemy-hit reach; the
forward gesture and actual contact marks carry the emphasis. Fainter echoes
show groove and air responses. Muted HUSH does not give a rebound from
raw hits. His three-parry challenge and the 100 ms parry window stay the same.

## The folded map

A folded page waits on the Headshell floor, a short walk right of the starting
point and before the first raised block. Walk close to pick it up. The map marks
your current room and remembers the rooms you explore; unvisited places stay
unnamed. Three pages cover **The Label**, **The Overture**, and **The Unplayed**,
including the Drop on the Unplayed sheet. The guide contains all 21 rooms and
26 real passage pairs, including the two permanent wax returns. Passages may still
need to be opened in the world.

Opening the guide selects your current region. Click a region tab or use
**Left / Right** on the keyboard or D-pad to turn pages. Border markers show
where a real passage continues onto another sheet without revealing an
unvisited room's name. Browsing pages never moves Skip or changes a route.

Ownership and explored rooms survive recovery, Continue, and returning to the
title. Existing saves remain valid: visit the Headshell to collect the page on
an older journey. New Game clears it along with the rest of that journey.
Opening the map pauses play; closing it returns you to the same position.

## Character progression

Explore to recover seven moves. Stand on the ground beside each lost part and
use a fresh **E / Y**; arrival or walking past never collects it automatically.
The Book names each missing ability and keeps a lead to its location.

| Ability | Discovery | What changes |
| --- | --- | --- |
| Walk | Behind the Headshell cradle, at (60,554) | Restores sustained walking after the initial one-pixel shuffle. |
| Strike | Beneath Horn Plaza's horn, at (650,574) | Basic Tap attacks and parries. |
| Set | Groove Yard's western approach, at (610,574) | Kneeling and peaceful responses. |
| Hood | High Street's upper walk | Quiet movement, listening calls, and polishing wax. |
| Groove Riding | Beyond Tick's Count-In door in Practice | Live-groove launches and thick-air jets; opens the Stalls crossing. |
| Three-Strike Chain | Overture Stair's middle landing, at (925,644) | Links connected Tap and Sweep hits into a heavier Accent. |
| Pogo | Overture Well's lower resting shelf | Airborne rebounds from vulnerable foes. |

Walk restores the existing running speed, acceleration, braking, and air
steering. Before it is found, every fresh direction press moves one pixel;
held input, keyboard repeat, or faster equipment cannot create continuous
travel. Jump height stays unchanged. The remaining abilities preserve their
existing tuning, and equipment never substitutes for an unearned move.
Knowledge and Refrains remain separate:

- **Count-In** and **Step-Turn** are knowledge techniques. Discovering one
  records it in the Book and save data. Once Strike is found, Count-In can be
  performed before its name is recorded; four even strikes prove it at a lock.
- **Gather** waits beyond either Tonearm resolution. It preserves one airborne
  Strike breath in dry wax; rooms that already grant more keep their capacity.
- **Jump-Cut** is earned below the North Warren receiver after restoring its
  lost phrase. It flips the wax and lets you unseal two permanent return routes.
- **Rest** remains planned and has no gameplay effect yet. The development
  atlas retains its separate Jump-Cut pickup in the Mispress Core.

Campaign discoveries persist on disk. Development rooms start with all seven
moves and retain their separate Refrain pickups and session-only progression;
they never write the campaign checkpoint. Title-screen Move practice also
supplies all seven moves without changing what the campaign has earned.

## The B-side

A record has two sides. **Jump-Cut** lets you turn the one you are standing on
over, and the far face is the same room read from the side nobody played:

- **The air inverts.** Spent wax reads thick — it answers a strike, and it
  holds your weight. Thick wax reads dry, and stops answering.
- **Grooves belong to a side.** Everything pressed loud on the A-side falls
  quiet when you flip. The trade is legible in one room: lose your launches,
  gain the air.
- **The ink inverts.** Paper and print trade places, so the dark A-side
  turns to paper. Rooms are not duplicated — a room authors its A-side only.
- **Burnishing is one-sided.** HUSH smoothed the face that was up. The B-side
  of The Smoothed Floor still rings, so resonance works there.
- **A side has a runtime.** The B-side plays down in about twelve seconds, then
  drops you back to the A-side wherever you are standing. It rewinds
  slowly while you are on the A-side. Every flip is a round trip you have to
  plan — and the air holding you up is on a timer.

Turning over is silent until Jump-Cut is carried; an unearned Refrain is never
announced before it is found. The Bootlegger has an opinion about this:
*don't touch the B-sides.*

## The Book

The Book pauses the room and has **Journey**, **Equipment**, **Bestiary** and
**Level** pages. Journey records found and missing moves, discovered knowledge,
carried Refrains, current Shine, permanent purchases, and discoveries. The
Echo Spool and Surveyor's Slip have separate item buttons; they do not add to
the eight groove slots for core moves, techniques, and Refrains. A separate
Movement shelf holds Walk; the refinement shelf holds the chain, Groove Riding,
and Pogo. The ability counter tracks all seven moves, with Walk initially
selected for a new journey. New Game starts with none filled. Missing abilities
show names and leads; found-item entries retain the next lead and survey clue.
Inside the game, unknown techniques and Refrains
remain unnamed until the session records them. Equipment lists all 15 pieces,
separates three Lost Pressings from twelve trial finds, and shows their
sources, exact trade-offs and trial chances, your fittings, Offcuts, and regional
mastery. Its buttons explicitly fit, remove, or bind equipment; merely opening
the Book or reading a description changes nothing.

The Bestiary has **10 entries** for the campaign's voices, keepers, and harmless
residents. Approaching someone records their name, habitat, and a practical
listening note; unseen entries remain unnamed. Saved freed and shattered
outcomes fill their counters without repeating them. A won HUSH bout records
his entry without calling it a shattering, and trial copies never add story
counts. The catalog can gain further entries while older saves keep working.

The Level page shows your level, XP toward the next one, and the three gains.
Each card gives its rank, what the next rank changes, and what that means in a
fight. Its tab reads **LEVEL •** while a choice waits.

Use arrows, D-pad, or the left stick to select an entry. Change pages with
Tab / Shift+Tab or LB / RB; scroll long notes with the mouse wheel, PgUp / PgDn,
or right stick. Press I/Start again or Escape to close the Book.

## Development rooms

Run `.\deadwax.cmd dev`, or pass `-- --dev-rooms` to Godot. This explicitly
enables the original five-room mechanics circuit and the full graybox atlas.
TAB cycles rooms, M switches between the two atlases, and G grants every
Refrain for feel-testing. These tools also require a debug build. Normal
chapter play never routes into an unfinished shell.

```text
LABEL <-> PRACTICE <-> VERSE <-> UNPLAYED <-> SMOOTHED <-> LABEL
  Gather opens the Label -> Smoothed shelf shortcut.
```

1. **THE LABEL** — M0's dry lessons, reskinned: groove launches, spent-wax
   gaps, the shaft, ON BEAT. It hides an **unsigned groove-lock** and a high
   dry return shelf that becomes a Smoothed shortcut after Gather.
2. **THE PRACTICE ROOM** — M1's heart. The **Test Pressing** dummy: it hears
   your crackle, ticks three times, swings on four. Strike exactly as the
   swing lands: **RUNG BACK** (parry). Fill its rim to shatter it. Also:
   polishing corner, and the **signed COUNT-IN door** (four even strikes,
   any tempo). Opening either groove-lock records Count-In as learned.
3. **THE VERSE** — Auditioners can be shattered or heard. Hold SET nearby to
   free one peacefully.
4. **THE UNPLAYED** — thick-air flight, two breaths, hot grooves, and the
   **Gather** Refrain at the climb-out. Its passage continues to Smoothed.
5. **THE SMOOTHED FLOOR** — a bout on HUSH's terms: resonance OFF, raw hits
   worthless, three rung-backs to win. Spacing and timing, nothing else.
   This room decides whether the rival duels will feel good.

## The planned world

The five development rooms above are hand-built. `data/world_map.json` plans
53 rooms across six strata, and the runtime now grays every one of them in:
correct footprint, stratum palette and air, one passage per planned route, and
Refrain seals where the plan asks for them. Press **M** in the opt-in
development rooms to walk it.

These are shells for feeling the map's shape and scale. The campaign uses
21 of the plan's identities through `scripts/campaign.gd`, with its own
authored geometry and passages. The complete graybox atlas remains available
unchanged for topology checks. See `ROUTING.md` for both loaders.

## What to feel for (bring notes)

- Does the parry window (100 ms) feel fair after learning the tell?
- Do grounded hits, jump rebounds, and quick follow-up presses feel deliberate?
- Does hood-stealth read — do you *feel* quieter, does the dummy calming
  down land?
- Is the count-in door forgiving enough at fast and slow tempos?
- Does bringing one breath back to The Label feel like a meaningful return?
- Is the muted room fun with everything subtracted, or just empty?
- With Groove pressure on, does playing on the beat feel better than mashing? Does the
  Tonearm fight feel like music or like a metronome? Which way do you want it?

## Tuning knobs

- Movement/strike/noise: constants at the top of `scripts/skip.gd`
- Dummy timing/windows: constants atop `scripts/test_pressing.gd`
- XP, the level curve and Ring/Body/Bite steps and caps: atop `scripts/xp_state.gd`
- Groove pressure: pocket width and count lead atop `scripts/groove_clock.gd`;
  pulse, bite and off-beat volumes atop `scripts/main.gd`; a room's tempo is
  its `beat_period` (0 keeps Tick's count), set where the room is configured
- Door strictness: `GAP_MIN/GAP_MAX/EVENNESS` in `scripts/refrain_door.gd`
- B-side length and rewind: constants atop `scripts/pressing_state.gd`
- Type, ink, plates and paper: `scripts/press.gd` and `assets/shaders/`
- Room light placement and exposure: `scripts/lighting_profiles.gd`
- All SFX are synthesized in `scripts/audio_bank.gd` — still no audio assets

## How it looks

Dead Wax uses a quiet illustrated world: broad architectural silhouettes,
soft colour washes, cream wax faces, petrol cloth, aged brass and warm coral
notes. `scripts/press.gd` remains its central drawing vocabulary; rooms supply
their palette and subject.

- **Drawn distance.** Sparse authored roofs, chambers, vaults and shaft faces
  replace the detailed generated panoramas. Broad colour washes leave room for
  each area's horn, cradle, spindle or empty seats to carry its identity. The
  21 rooms retain their palettes, cached far plane, gentle middle motion and
  camera parallax. The original paintings remain archived in `assets/art/`.
- **Characters.** Layered clothes, wax masks, articulated limbs and worn brass
  give Skip, the voices, residents, Hound and bosses distinct silhouettes.
  The figure refinement adds broad mask shadows, quiet angular eyes, clearer
  feet and coat folds, and broken metal highlights that suit the dim world.
  Their existing animation poses follow the original combat clocks.
- **Solid surfaces.** Dark textured cutaways have crisp illuminated upper lips.
  Wood grain, scoring and rivets are clipped to actual platform faces, at least
  10 pixels below walkable tops. They never cover a landing or bridge a gap.
- **Light.** Two to four native lamps per authored room cast soft shadows from
  real platform interiors. Cool ambient fill and amber fixtures keep cream
  faces readable. Lights stay fixed in world space and affect canvas layer 0;
  HUD, menus and journals retain their colours.
- **Objects and interface.** Brass-framed groove housings, wax medallions and
  lanterns share the palette with dark cloth journal covers and signage.
  Big Shoulders and IBM Plex Mono remain the display and body faces; their
  SIL OFL licences ship beside them in `assets/fonts/`.

Ink and stock come from each room's `ink` and `bg_color`. Turning A→B→A
reinks every layer and restores the authored exposure exactly. The actual
reversed palette receives extra ambient fill. Pause freezes scenery and lights;
reduced motion holds ambient movement, parallax and slow lamp modulation while
live encounter outcomes can still update. Development rooms and grayboxes retain
their halftone backdrop and have no campaign atmosphere or room lighting.

See [the art direction and production prompts](assets/art/ART_DIRECTION.md) for
asset provenance, dimensions and the rendering approach. Rendering remains
Godot GL Compatibility, with no external runtime dependencies.

Menus now reveal their type in short impressions, with moving ink accents for
mouse and controller focus. The sleeve's record turns gently while its label
stays upright. The Book and stall respond to selections and purchase results.
Campaign room names fade on arrival, and short receipts acknowledge discoveries
and Shine. Detailed HUD impressions remain available in practice and development.
Text and balances update immediately, and closing a panel never waits for animation.
Reduced motion settles interface effects immediately. Open menus keep their
own animation while gameplay and the HUD remain paused underneath.

## Development checks

Run `.\deadwax.cmd check` before committing. It imports resources and runs 58
dependency-free native suites, including smoke, save-store, campaign, Tonearm, Overture,
sprite-animation, residents, economy-state, economy integration, scenery,
lighting, attack-feel, GUI-animation, and map-item suites. These cover the original combat and
progression invariants, all planned-room routes, validated
checkpoint recovery, all three chapter registries, boss outcomes, old-demo save
continuation, campaign state restoration, grounded conversations, resident
pause behavior, harmless petting, silent return visits, purchase transactions,
item effects, compatibility with saves made before the stall opened, scenery
clipping and lifecycle, palette restoration, parallax, native light and
occluder setup, UI isolation, reduced motion, grounded hits, airborne rebounds,
strike buffering and cancellation, unchanged parry timing, menu interruption,
focus, reduced-motion behavior, map ownership and save compatibility, the
authored map graph, and map input/pause boundaries. Combo and practice suites
also cover fresh-input chains, expiry and cancellation, finisher strength,
unchanged launch/parry rules, and isolation of the title's empty practice floor.
The Unplayed suite covers the six-room extension, both Tonearm entry outcomes,
reversible routes without Gather, encounter persistence, and save continuity.
Map checks cover all 21 places and 26 passage pairs across the three region pages.
Discovery checks cover ordered spool use, fixed interaction reach, cancellation,
save validation and rollback, silent restoration, the optional Gather keepsake,
and practice isolation. Echo audio checks cover lazy finite synthesis, matching
record/playback notes, pause behavior, and cancellation without stopping other sounds.
Collection-state, collection integration, collection-Book, and Echo-Trial suites
cover strict save validation, deterministic rewards and pity, duplicate salvage,
binding, equipment trade-offs, failed-write rollback, historical bestiary notes,
temporary echo combat, wave ownership, repeated claims, menu navigation, and
practice isolation. Five ability suites cover strict move snapshots, the one-pixel opening,
held/repeated input suppression, frame-rate independence, empty New Game,
legacy migration, earned-input behavior, fixed pickups and
failed writes, the Stalls gate and safe western return, and Book/readout
permission cues. The pacing checks cover one discovery per introduction room,
the later Set and chain leads, dormant first-visit recordings, saved return
availability, and preserved trial access for existing collections.
Native playtests still check the readability and pace of
repeated hunts and equipment handling.
Controller profile, setup-menu, and integration checks cover the 18 physical
captures, buttons and axes, neutral gating, saved settings, reconnects, menu
isolation, and translated gameplay actions. Movement checks exercise run-up,
coast, reversal, Set/Hood handling, preserved air steering, equipment trade-offs,
and the exact one-pixel shuffle.
GitHub runs the checks on pushes and pull requests. Gameplay feel, real audio,
rendering, and controller behavior still require `PLAYTEST.md`.

There is no `export_presets.cfg` yet; this checkout runs through Godot rather
than a configured distributable build.

The exploration suites cover strict optional shortcut saves, old restored-phrase
checkpoints, grounded fresh-input rewards, far-end B-side opening, permanent
return travel, safe arrivals, failed-write rollback, and practice isolation.
The Lost Pressings suites cover deliberate one-time equipment claims, saved
ownership and fitting, rollback, unchanged trial pools, physically earned
balcony access, separate interaction reaches, and Book/map readability.
The cinematic suites cover presentation-only snapshots, one nearby cue,
deliberate subtitles, hidden world plates, live earned fixtures, room-note
refresh, compact-window focus and scrolling, pause and Reduced motion,
save-error visibility, and preserved practice/development guidance.
