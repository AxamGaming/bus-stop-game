# BUS STOP — Game Design Document

**Working title:** *Thank You for Waiting*
**Genre:** First-person psychological horror, "waiting game"
**Platform:** PC
**Target length:** 22–26 minutes for a clean run, with 5 endings
**Visual style:** PS1-era low-poly, heavy depth fog, night rain
**Document status:** Story-and-design edition — concept, mechanics, rules, story, structure and reasoning. Technical implementation is maintained separately.

---

## Table of contents

1. Concept and pitch
2. Title and positioning
3. Design pillars
4. Player experience and emotional targets
5. Game structure and core loop
6. The attention economy
7. Mechanics, controls and verbs
8. The Rules system
9. Story, lore and endings
10. Night-by-night beat sheets
11. Event catalogue
12. World and level design
13. Visual direction
14. Audio direction
15. UI and accessibility
16. Fairness rules
17. Design reasoning — the stress test
18. Decisions log and open questions

---

## 1. Concept and pitch

> **You wait alone for the last bus on a rainy night, and the only way to survive is to obey three rules printed on a timetable — while the thing in the fog moves every time you look away, and the lamp that keeps you safe dies every time you look at it.**

**Longer pitch.** It is late. Rain. A single lamp lights a tiny shelter. The timetable says the last bus, Route 47, arrives at 11:47, and beneath it: *Please wait inside the light.* There is nowhere else to go. Over three nights that repeat, the road becomes more wrong. Something stands in the fog and only moves when you look away — but stare at it and the lamp begins to die. A stranger sits on the bench and will not speak first. A bus comes with no number. The rules tell you what is safe, and the scariest part is that following them works.

**Insight statement:**

> The player wants to get home, but the only way home is a bus that can't be trusted, because the stop itself decides who gets to leave.

**The tension this game lives in:** wanting to leave versus what leaving costs — and, moment to moment, needing to look versus being punished for looking. The first resolves only at the final bus; the second never resolves, which is what keeps the player's eyes moving.

**Why this is a good solo project:** one location, a small number of short content pieces, no combat or pathfinding, fog and a PS1 look hide missing detail, and sound does most of the scaring.

---

## 2. Title and positioning

**Recommended: *Thank You for Waiting*.** It is the timetable's closing line **and** the end card, so the title pays off in the final frame. It sits in a bureaucratic-transit register with no contested phrase, and it is short enough to survive store-page truncation.

*Route 47* is a short-form alternative — cleaner on a store page, already in the game.

**Regardless of title, keep *"Please wait inside the light"* as the timetable header line.** That is where it belongs and where it works.

### What the game is competing on

The **premise** (a night bus stop, a stranger, multiple endings) is a genre convention — a close version of it has existed since 2022. The premise is validated, not novel. Two things are genuinely unclaimed, and they are what the game should be known for:

1. **The light is a resource you spend by looking.** Not "stay in the light" — *staring at the Thing consumes the light that protects you.*
2. **The rules are printed on a timetable in bureaucratic transit language.** A route number, a last-service time, a destination board, an "END OF SERVICE" sign, a "Thank you for waiting." The horror is administrative.

Lead everything with those two. Never lead with "person at a bus stop at night" or "stay in the light."

### Title candidates considered

| Candidate | Verdict |
| --- | --- |
| *Bus Stop* | **Rejected.** Exact-title collisions and unsearchable as a phrase. |
| *Last Bus* | **Rejected.** Collides with several existing titles. |
| *End of Service* | **Rejected as a title.** Exact-title collision, and the phrase is dominated by shutdown terminology. **Keep it as the signpost text** — excellent diegetic copy. |
| *Please Wait Inside the Light* | **Rejected.** Clear as a title, but long (truncates on store grids) and the "inside/into the light" phrase is actively contested. |
| ***Thank You for Waiting*** | **Recommended.** Apparently unclaimed, short, bureaucratic-transit register, and it pays off as the end card. |
| *Route 47* | **Short-form alternative.** Cleanest on a store page, already in the game. Manual check required for creepypasta adjacency. |

**Before committing:** manual search on itch.io (title + tags `psx`, `horror`, `short`), Steam, YouTube and the Haunted PS1 community pages. Search engines do not index itch reliably.

---

## 3. Design pillars

1. **Waiting is the gameplay.**
2. **Attention is the currency.** Stare and the light dies; look away and the Thing moves.
3. **One place, small radius.** Never more than ~14 m from the shelter.
4. **Rules you can read and still fail.** Failing is always a choice, never a surprise.
5. **Sound first.**
6. **The clean ending is the strangest.** Obeying works, and that is unsettling.
7. **The rules are bureaucratic.** A timetable, a route number, a destination board and an END OF SERVICE sign decide whether you get home.

---

## 4. Player experience and emotional targets

| Phase | Feeling | How it's created |
| --- | --- | --- |
| First minute | Calm, curious, lonely | Rain, warm lamp, readable shelter, no events |
| Night 1 | Unease — "was that something?" | Small sounds, a distant figure, a bus that doesn't stop, the first survivable lamp death |
| Night 2 | Suspicion, testing | Rules become readable, then are tested one at a time |
| Night 3 | Dread, temptation | Stronger lures, the rain stops, the figure at the edge of the light |
| Final bus | Doubt even when things are right | A clean ending that is the strangest one |

**Emotion hierarchy:** dread of being watched while helpless, with isolation underneath. Avoid cheap startle as the main tool. Tension is the pressure felt *after* the problem is understood and *before* it is solved — so the rules must be established early and the bus must stay uncertain.

---

## 5. Game structure and core loop

### Structure

- **Three nights**, each a wait ending at 11:47 PM.
- Each night is **5–7 minutes of real time** before the bus, plus a short decision window after arrival.
- A **rule break or a lost stare ends the night immediately** with an ending, and the night restarts. Failure is content.
- **Night 1 and Night 2 have no fail states from the gaze.** Only the sign line can end a run, and only from Night 2.

### Core loop

1. **Wait** in the lamp's light. Look around, read the timetable, check the watch.
2. **A beat plays** on a designed schedule with deliberate quiet gaps.
3. **Spend attention.** Decide where to look and for how long.
4. **Test.** Each night ends with a bus. Decide whether to commit.
5. **Consequence.** A rule break or lost stare gives an ending; a clean night moves on.

### Session flow

```
Menu → Night 1 → Night 2 → Night 3 → Final bus
   (gaze cannot kill)  │         │
                 fail → ending  fail → ending
                    └──── restart this night ────┘
                       (Ending 4 is terminal, not a loop)
```

---

## 6. The attention economy

The Fog Figure advances only when outside the gaze cone, and keeping it inside the cone has a cost. Both use **the same cone** — there is no angle at which the figure is frozen for free.

| Player action | Cost |
| --- | --- |
| **Look away** (anywhere, including down at the watch) | The figure may step toward the light, up to that night's cap. |
| **Raise the watch** (hold Q) | You look down — counts as looking away. |
| **Keep the figure in the gaze cone** | After a 2 s grace, the lamp loses **10%/s** — **6%/s** once the figure is at the cap. |
| **Look away briefly** | The lamp recovers **20%/s** (full recovery in 2.5 s from 0.5). |
| **Lamp reaches 0 from staring** | The figure steps closer in the dark; the lamp relights at 50%. **The first time this ever happens it is survivable.** If *and only if* it is Night 3, the mechanic has been demonstrated, and the figure is at the cap — you lose (Ending 1, gaze variant). |

**Intended play:** a rhythm of short glances. Never a long stare, never a long look away.

### Safety rails

- Scripted blackouts never kill. They advance the figure one station, within the cap.
- **Figure cap by night** (0-based station index): Night 1 → station 2 of 5 (19 m). Night 2 → station 3 (13 m). Night 3 → station 4 (9 m). The fifth station (5 m, *inside* the light) is reachable only by the breach rule below.
- **Gaze death is Night 3 only.** In Nights 1–2 a player can stare forever; the lamp cycles 0.5 → 0 → 0.5 and the figure parks at the cap. This is safe by construction, not by tuning.
- **Night 3 death window.** The figure appears at 0:40. Continuous staring reaches the cap at ~26 s (**≈1:06**) and kills at ~36 s (**≈1:16**). That is acceptable only because reaching the cap by staring requires three prior survivable blackouts, each of which is the demonstration fairness demands. A player who never stared cannot die before the authored 5:30 beat plus one survivable blackout.
- **The breach (build-time test, debug-gated):** at the cap, sustained unwatched time moves the figure to station 5, *inside* the lamp pool. This breaks the unwritten rule at the worst possible moment and removes the one-sided endgame.
  - **Worth testing alongside it:** once breached, let sustained watching push it *back* to station 4. That makes the last minute a genuine dilemma — the only way to get it out of the light is to stare, and staring is killing the lamp. Not committed on paper; a late-stage question.
- **Tells:** the lamp visibly dims, its hum falls in pitch, and a faint heartbeat joins at 30% light — or **50%** when the figure is at the cap.

---

## 7. Mechanics, controls and verbs

| Verb | Control | Notes |
| --- | --- | --- |
| Look | Mouse | FOV ~75° vertical, adjustable. The gaze cone scales with it. |
| Walk | WASD | Slow, no sprint. ~1.8 m/s. |
| Interact | E (tap) | Timetable lean-in, bench, payphone, bin. |
| Hold actions | E (hold, ring) | Speak to the stranger (1 s), board the bus (1 s). |
| Watch | Q (hold) | Raises the forearm, looks down, slows movement. Counts as looking away. |
| Pause | Esc | Allowed. Freezes the whole night including the clock. |

**Stretch (only if ahead of schedule):** hold breath, watch backlight, gamepad support.

### Making the cone perceivable

The gaze cone covers 41% of horizontal FOV, so the **outer 59% of the horizontal view counts as unwatched.** Players will assume anything on screen is watched. Three layers, cheapest first:

1. **The silhouette lightens slightly while it is inside the cone** — a flat colour swap on the figure's own material, driven by the same boolean the gaze monitor uses. Reads as "your eyes are on it," costs nothing, works at every FOV. **Default on.** (Not rim lighting — rim is invisible on an unshaded black silhouette, which is exactly what a PS1 fog figure should be.)
2. **Audio tell:** the lamp hum gains a faint upper partial while the figure is held in the cone. Fits "sound first," and works when your eyes are down at the watch. **Default on.**
3. **Cone-matched screen vignette** — a subtle darkening outside the cone boundary, behind an accessibility toggle. **Default off**, for players who still can't read the boundary.

**This trades away some ambiguity.** The original design note "the player should never be sure how fast it moves" is deliberately overruled: dread here comes from the lamp draining, not from uncertainty about the cone, and an invisible core rule reads as cheating.

### Movement and boundaries

- Subtle head bob, footsteps that change between concrete (shelter) and gravel (verge).
- **Soft limit:** gentle push-back from 12 m. **Hard limit:** invisible wall at 14 m from the shelter centre.
- **The sign line** is a full-width wall at the east edge; it spans the whole corridor so it can't be walked around.

### Interaction

- Interactables have a prompt, a hold duration (0 = tap, 1 s = hold), and per-object reach (the bus door uses 1.5 m so you must walk to it).
- Hold actions show a filling ring. Releasing early cancels. A tap does nothing. An accessibility option swaps hold-to-confirm for press-to-confirm.
- **Reading** the timetable or poster is a diegetic **lean-in**: FOV narrows, movement locks while E is held, the world keeps running so you can still hear it. Any big event, and every bus beat, cancels the lean-in automatically.

### Forearms and the watch

- Low-poly forearms in **pale yellow raincoat sleeves**, visible when the watch is raised or the player reaches. This is the jacket the poster later matches.
- 1990s digital LCD on the left wrist. Holding Q raises it; you look down; movement slows.
- Watch telegraphs (cuttable — the watch still shows the time without them):

| Display | Meaning |
| --- | --- |
| Colon blinks steadily | Normal |
| Colon stops blinking | Figure at station 3+, or the stranger is present |
| Digits flicker | A rule test is active |

The telegraphs are fair warnings with a price: your eyes leave the road.

---

## 8. The Rules system

The timetable and the sign are the rulebook. They are world objects, not menus.

### Timetable text (final copy)

```
ROUTE 47
LAST BUS  11:47 PM

Please wait inside the light.

  1. Do not board a bus that has no number.
  2. If someone is waiting with you, do not speak first.
  3. Never walk past the sign.

Thank you for waiting.
```

### The sign

Legible from Night 1: **END OF SERVICE**, with a smaller line beneath: *No pedestrians beyond this point.* The boundary is understandable without reading the timetable.

### Rule table

| Rule | Test | Trigger | Result |
| --- | --- | --- | --- |
| 1. Do not board a bus with no number | Night 2, the numberless bus opens its doors | Hold E on the door, 1 s | Ending 2, *Wrong Bus* |
| 2. Do not speak first | The Bench Stranger (Nights 2–3) | Hold E on the stranger, 1 s | Ending 3, *Spoke First* |
| 3. Never walk past the sign | Signpost lure (Nights 2–3); curiosity always | Crossing the sign line | **Night 1:** warning. **Night 2+:** Ending 1, sign variant |

**Night 1 warning behaviour:** the lamp dims to 20%, a low drone plays, and the player is pushed back toward the shelter. **It does not advance the figure** — that would exhaust Night 1's cap and neuter the 5:00 climax. Warning cooldown 5 s.

### Making Rule 2 carry its weight

"Do not speak first" will read as the generic don't-talk-to-strangers beat. Three changes, in order of cost:

1. **The stranger never speaks first, and then leaves.** If the player waits out the full 45–60 s, the stranger stands, walks into the fog and is gone — having said nothing and given nothing. This converts Rule 2 from "obey an arbitrary prohibition" into "**the game is withholding something and breaking the rule is the only way to get it**." That is a real temptation rather than a rule to follow.
2. **Make the stranger specific, not generic.** Cheapest options: it is holding the same timetable; its prompt "Say something…" is in the same hand as the poster's; it is wearing a raincoat of a different colour, which sets up Ending 5's passengers.
3. **The voice payoff carries the rest.** Ending 3's answer is the *same processed voice* as the bin radio and the payphone. It must land before the stranger beat in Night 2 — the beat sheet already orders it 1:20 → 3:00.

**This chain is load-bearing, and it depends on recorded voice.** Rule 2's weight comes from three links in order: **the bin radio** introduces the voice (Night 2 at 1:20) → **the stranger** tempts you (3:00) → **Ending 3** pays it off (the stranger answers in that voice). Break any link and Rule 2 collapses back into the generic don't-talk-to-strangers beat.

So: the bin radio plus roughly three short voice lines are now required for Rule 2, not merely for Ending 3.

**If you do not record voice,** use this fallback rather than dropping the chain: make it one *non-verbal* processed voice — a breath, a hummed two-note figure, a mouthed word — used identically in all three places. It is still recognisably the same entity, it costs one short session instead of twelve lines, and Ending 3 keeps its payoff. What you must **not** do is use text captions in one place and audio in another; the identity of the voice *is* the point.

### Rule visibility

| Night | Timetable | Sign |
| --- | --- | --- |
| 1 | Header and time readable; rules smudged | Legible, **non-lethal** |
| 2 | All three rules readable | Legible, lethal |
| 3 | Same text; stronger lures | Legible, lethal |

### The unwritten rule

*Please wait inside the light.* The Thing never enters the light — **unless the light is gone, or unless the breach rule is enabled and you stopped paying attention.** Boarding the bus is the only legitimate reason to leave it. The novel part of this is not "light is safe" (that is well-trodden) — it is that the light is *spent by looking*.

---

## 9. Story, lore and endings

### Premise

You are an unnamed person in a yellow raincoat who missed your ride home. The last bus is the only way out. You never learn how long the stop has been waiting for someone.

### What is really going on

The stop is a loop that collects people who wait. It tolerates those who wait correctly and takes the rest. The *MISSING* poster on the shelter pole shows previous people.

**The loop is tightening, and the clock says so.** You arrive earlier each night (11:35, 11:32, 11:31) and are made to wait longer (12, 15 then 16 in-game minutes). This is intentional. Do not "fix" it by aligning the start times. A player who checks the watch across nights can notice; the payphone line *"It's already 11:47"* is the only acknowledgement the game gives.

Reveal everything through objects: the timetable, the poster, the bin radio, the payphone, the bus interior. No exposition dialogue.

### Poster states

| Night | Poster |
| --- | --- |
| 1 | Water-damaged, mostly unreadable |
| 2 | A silhouette, partial text: "last seen waiting at this stop" |
| 3 | The silhouette wears **a yellow raincoat** — the same as your sleeves |

### One voice

Every voice in the game is the **same processed voice**: bin radio, payphone, stranger. It is one entity. Record ~12 short lines yourself and process them (pitch, low-pass, light distortion). This gives Ending 3 its payoff and makes the bin radio load-bearing even if the payphone is cut.

### Endings (five)

| # | ID | How | What happens |
| --- | --- | --- | --- |
| 1 | `out_of_the_light` | Cross the sign line (Night 2+), **or** let the lamp die by staring while the figure is at the cap **in Night 3** | Two vignettes under one card — below |
| 2 | `wrong_bus` | Board the numberless bus (Night 2) | A silent ride into fog; the stop's lamp goes out behind you |
| 3 | `spoke_first` | Hold to speak to the stranger | The stranger answers in the voice from the radio, repeating your own "Hello?" |
| 4 | `still_waiting` | Night 3: don't board the real bus within 60 s | **Terminal.** The bus leaves, the rain returns, the lamp goes out. End card: *The next bus is at 11:47 PM.* |
| 5 | `right_bus` | Break no rules; board the real bus | The final beat below |

**Ending 1 variants.** One menu slot, two experiences: `sign` (you walk into the fog, the lamp dies behind you) or `gaze` (the lamp dies with the figure at the edge of the light, and it is suddenly much closer). Splitting into six slots is a cheap upgrade — do it if there is slack.

**Ending 4 is terminal.** It guarantees no run loops forever. It must not restart Night 3.

### Ending 5 — the final ten seconds

The numberless bus is **empty**. The real bus is **full**, and that is the point.

1. You hold E on the door and walk out of the lamp's light into the dark between it and the bus's light.
2. Inside, every seat but one holds a still silhouette in dim yellow light, all facing forward, each in a different coloured raincoat.
3. You sit. The destination board above the driver reads the name of the stop you just left.
4. A notice inside reads **BOARDED 11:47 PM**, with a column of earlier passengers' times above yours.
5. Through the window the shelter shrinks. The poster flutters, the lamp goes out. End card: *Thank you for waiting.*

If the title is *Thank You for Waiting*, step 5 is the title paying off. Protect it.

---

## 10. Night-by-night beat sheets

Times are real seconds from the start of the night. Starting values to tune in playtests.

### The clock

The bus **arrives** at the moment the clock reaches 11:47, and the clock then freezes. Tempo is ~25 real seconds per in-game minute, so the start time is derived from the night's length.

| Night | Bus arrives | Clock starts | In-game minutes waited | Decision window | Gaze can kill? |
| --- | --- | --- | --- | --- | --- |
| 1 | 5:00 | 11:35 | 12 | 30 s (bus passes, fade) | **No** |
| 2 | 6:20 | 11:32 | 15 | 45 s | **No** |
| 3 | 6:45 | 11:31 | 16 | 60 s | **Yes** |

Total night time is about 20.33 minutes, plus cards, fades and the Ending 5 beat → **22–26 min**, inside target.

### Night 1 — "Wait" (~5.5 min, cannot kill)

| Time | Beat | Kind | Int |
| --- | --- | --- | --- |
| 0:00 | Fade in. Rain, lamp hum, shelter. Title card. | — | 0 |
| 0:00–0:40 | Quiet. Prompts for look, walk, E, Q. | — | 0 |
| 0:40 | **The Fog Figure appears at station 1.** | authored | 2 |
| 0:45 | Gravel footsteps or lamp flicker | fill | 1 |
| 1:30 | Distant engine, no bus | authored | 1 |
| 2:30 | **The stare lesson (authored — see below).** | authored | 2 |
| 3:30 | Lamp flicker or footsteps. Figure steps if unwatched (cap: station 2). | fill | 1–2 |
| 4:15 | Calm: rain only | — | 0 |
| 4:45 | Engine rises (approach) | authored | 2 |
| 5:00 | **Arrival.** A lit bus with no number passes without stopping. Scripted blackout 4 s; the figure steps once in the dark. Clock reads 11:47. | **authored + punctual** | 3 |
| 5:30 | Fade to black, "Night 2" | — | — |

**The stare lesson (do not leave this emergent).** At 2:30 the figure is visible and stationary. If the player stares, the silhouette highlight holds, the lamp dims, the hum drops in pitch, and at ~30% a heartbeat joins. If they keep staring, the lamp dies at ~12 s: the figure takes one step closer in the dark and the lamp relights at 50%. **This cannot kill** — the night is not lethal and the mechanic has not been demonstrated yet. This is the demonstration fairness requires, and it is the single most important thing to test early.

Rule state: unreadable. Only the sign line can end a run — and in Night 1 it doesn't.

### Night 2 — "Test" (~7 min, cannot kill by gaze)

| Time | Beat | Kind | Int |
| --- | --- | --- | --- |
| 0:00 | Fade in. Poster partly readable. | — | 0 |
| 0:30 | Timetable text changes. All three rules readable. | authored | 1 |
| 1:20 | Bin radio. **The voice is introduced.** | authored | 1–2 |
| 2:10 | Figure step (cap: station 3) | authored | 2 |
| 3:00 | **The Bench Stranger.** Rule 2 test, 45–60 s. **If you never speak, it leaves and you learn nothing.** | authored | 3 |
| 4:15 | Calm | — | 0 |
| 4:40 | Glass reflection or footsteps or flicker | fill | 1–2 |
| 5:30 | **Signpost lure.** Rule 3 test, ~30 s. | authored | 3 |
| 6:05 | Engine approaches | authored | 2 |
| 6:20 | **Arrival.** The numberless bus stops; doors open on a lit, empty interior. Rule 1 test, 45 s. Clock reads 11:47. | **authored + punctual** | 3 |
| 7:05 | The bus leaves. Fade, "Night 3". | — | — |

Rule tests are ≥ 30 s apart (3:00 / 5:30 / 6:20) so they never collide.

### Night 3 — "Decide" (~7.75 min)

| Time | Beat | Kind | Int |
| --- | --- | --- | --- |
| 0:00 | Fade in. The poster silhouette now wears a yellow raincoat. | — | 0 |
| 0:40 | **The figure appears.** Lamp blackout (scripted, safe); the figure advances one station in the dark. | authored | 2 |
| 1:30 | Payphone rings | authored | 2 |
| 2:30 | The stranger returns, seated closer, head turned toward you | authored | 3 |
| 3:40 | Calm | — | 0 |
| 4:10 | Glass reflection, wrong version, or footsteps or flicker | fill | 1–2 |
| 4:30 | Signpost lure, stronger | authored | 3 |
| 5:30 | **The figure reaches its cap**, just outside the light. From here a gaze blackout can end the run *if the mechanic has been demonstrated*. | authored | 2 |
| 6:00 | **The silence beat.** Rain and wind fade over 6 s, then near-silence. | authored | 3 |
| 6:30 | Engine returns | authored | 2 |
| 6:45 | **Arrival.** The real bus, "47" visible, readable destination board. Clock reads 11:47. 60 s to board. | **authored + punctual** | 3 |
| 7:45 | Board = Ending 5. Don't board = **Ending 4 (terminal)**. | — | — |

**The boarding walk:** the door is outside the light, with a 1.5 m reach and a 1 s hold. The player must walk out of the light to go home. When they step out during the final window the figure takes one audible step — a warning, never a kill.

---

## 11. Event catalogue

**Intensity:** 1 = ambient wrongness, 2 = direct presence, 3 = rule test or climax.

| ID | Event | Nights | Int | What happens |
| --- | --- | --- | --- | --- |
| E1 | **Lamp flicker** | 1–3 | 1 | Stutters for 3–6 cycles (~1.4–4.8 s) with a buzz, capped at the accessibility limit. Night 3's long version is a scripted blackout (≥ 3 s). "Reduce flicker" swaps in one slow dim. |
| E2 | **Distant engine** | 1–2 | 1 | Engine approaches and fades; no bus. |
| E3 | **Gravel footsteps** | 1–3 | 1 | Steps circle behind the shelter, stop when you turn. |
| E4 | **The Fog Figure** | 1–3 | 2 | Advances only when outside the gaze cone; staring drains the lamp. Five stations (26, 19, 13, 9 and 5 m), per-night cap, breach rule debug-gated. Albedo highlight driven by the cone. |
| E5 | **Timetable change** | 2+ | 1 | Rules become legible. Paper creak. |
| E6 | **Bin radio** | 2+ | 1–2 | Faint static; up close a muffled voice says two or three words. **Establishes the one voice before the stranger. Never cut.** |
| E7 | **The Bench Stranger** | 2–3 | 3 | A seated silhouette appears while you look away. Prompt: "Say something…" (hold E). **Leaves after 45–60 s if you never speak.** Night 3: closer, head turned. |
| E8 | **Glass reflection** | 2+ | 2 | In the shelter glass a figure mimics you with a delay. Night 3: it stays still when you move. **Cuttable** — nothing depends on it. |
| E9 | **Payphone** | 3 | 2 | Rings six times. Answering: breathing, then the voice reading the time. No rule consequence. **Cuttable**, but it carries the "loop is tightening" lore line. |
| E10 | **Signpost lure** | 2–3 | 3 | Past the sign the fog thins: a warm light, an idling engine. Crossing ends the run (sign variant). |
| S1 | **Passing bus** | 1 | 3 | A lit bus with no number passes without stopping. Lamp dies 4 s. |
| S2 | **Numberless bus** | 2 | 3 | Stops, doors open, blank destination board, **lit and empty** interior. 45 s. Board → Ending 2. |
| S3 | **Silence and the real bus** | 3 | 3 | Weather fades, near-silence, then the real bus with "47". |
| S4 | **Bus interior** | 3 | — | Dim interior, seated silhouettes, destination board, the notice. **Protect this: it is the payoff.** |

S2's empty interior and S4's full interior are deliberate opposites.

---

## 12. World and level design

### Layout (metres; the lamp is the origin)

```
 WEST                                                                       EAST
 FIGURE STATIONS          PAYPHONE   LAMP   SHELTER    BIN    BUS DOOR   SIGN LINE
 -26  -19  -13  -9  (-5)     -4       0     0 ──── 3    3.5      8.5        10.5 ║
  ·    ·    ·    ·   ·                 ◄── lamp light, range 6.5 m ──►            ║
                                                                    (wall spans the corridor)
 ────────────────────────────────── road, 7 m wide ────────────────────────────────
```

| Element | Position / notes |
| --- | --- |
| Lamp | Shelter's west corner. Range 6.5 m. The only safe place. |
| Shelter | South verge, ~3 m from the road edge. Open front, glass side panel, bench, timetable board, poster on the pole. |
| Payphone | x = −4, inside the light. |
| Bin | x = 3.5, inside the light. |
| **Bus door** | x = 8.5 — **just outside the light**, so boarding means stepping out of it. Reach 1.5 m, hold 1 s. |
| **Signpost / sign line** | x = 10.5, legible "END OF SERVICE". The line is a thin wall across the corridor. |
| Fog Figure stations | x = −26, −19, −13, −9, and **−5 (breach, inside the light)** along the verge/road diagonal, west side. |
| Lure | East of the sign line, where the bus comes from. |
| Tether | Soft push-back from 12 m; hard wall at 14 m from the shelter centre. |
| Treeline | Billboard cards 30–45 m out, mostly lost in fog. |

### Station indexing

| Station | x (m) | From lamp | Inside light? | Cap in |
| --- | --- | --- | --- | --- |
| 1 | −26 | 26 m | no | never |
| 2 | −19 | 19 m | no | **Night 1** |
| 3 | −13 | 13 m | no | **Night 2** |
| 4 | −9 | 9 m | no | **Night 3** |
| 5 (breach) | −5 | 5 m | **yes** | never — debug-gated |

### Geometry notes

- The figure lives west, the bus comes from east: the player walks *away* from the Thing to board.
- Station 4 (9 m) is just outside the light's edge (6.5 m). Station 5 (5 m) is inside it.
- The bus door sits 2 m before the sign line, so boarding never conflicts with Rule 3.
- All stations are within the fog end; station 1 (26 m) must be *barely* readable. If it vanishes, move it closer rather than thinning the fog.

### Level design principles

- **Sightlines are the design:** one long empty road, one wall of fog.
- **One safe place.** Everything outside the lamp is where the Thing lives.
- **Hide the edges with fog,** not with walls the player notices.
- **Give the eyes something to do:** timetable, poster, bench, road, sign.

### Asset list (all low-poly)

| Asset | Count | Notes |
| --- | --- | --- |
| Shelter, bench, bin, payphone, lamp post, sign | 6 | Boxes and simple extrusions |
| Timetable, poster | 2 | Readable text objects, not baked textures |
| Road and verge tiles | 3–4 | Tile and reuse |
| Tree billboards | 2–3 | Reuse everywhere |
| Bus exterior | 1 | ~600–1000 triangles |
| Bus interior | 1 | Box seats, destination board, notice |
| Silhouette (stranger, figure, passengers) | 1 | One mesh; different poses, scales, materials. Unshaded, near-black albedo; the figure needs two albedo colours for the gaze highlight. |
| Forearms and watch | 1 | Two low-poly forearms + an LCD texture |
| Rain particle texture | 1 | |
| Font | 1 | Pixel or typewriter |

---

## 13. Visual direction

### Look

Low-resolution PS1-style 3D: vertex snapping, affine texture warping, limited texture detail, dither, heavy depth fog. Pixelated imperfection makes shapes ambiguous, which helps horror.

### Palette

| Element | Direction |
| --- | --- |
| Night ambient | Very dark blue |
| Fog | Cold blue-grey |
| Lamp | Warm sodium orange-yellow |
| **Player's raincoat** | **Pale yellow** — reads in fog, suits the rain, gives the poster its payoff |
| Bus interior (real bus) | Dim, sickly yellow-green |
| Rain | Faint grey-blue streaks |

Cold dark surroundings plus one warm light make the lamp feel like the only safe place.

### Fog

- Depth fog, starting at 4 m → 32 m, curve ~1.2, fog colour matching the background.
- Volumetric fog is Forward+ only, costs more and bands. Skip for v1.
- Godot's fog does not dither. At a low render scale the gradients will band, and those gradients are the whole atmosphere. Budget a dither pass.
- Tune the figure's visibility by eye at station 1. The player should never be "watching" something they cannot see.

### Resolution

- Default: stretch mode `viewport`, base size ~640×360, integer scale. UI pixelates too, so use a pixel font.
- Alternatively, a low-res 3D viewport with full-res UI — crisper text, more plumbing.
- **Check the title at this width.** A 21-character title in a pixel font must fit the main menu and the ending card at 640×360.

### Lighting

One omnidirectional lamp (range 6.5 m), low ambient, no baked lighting, shadows off or simple. The bus has its own interior light — the real bus's light is what the player walks toward after leaving the lamp.

### Rain

Modest particle count; test on a low-end machine early. Rain streaks alias badly at 640×360 — if they do, fall back to streaked quads or a screen-space overlay plus audio.

---

## 14. Audio direction

Sound should do most of the scaring. One source credits Frictional Games' design notes with ~70% of fear coming from sound — a rule of thumb, not a measurement, but the direction is right.

### Principles

1. **Start from silence, not music.** No score except possibly a faint drone in the endings.
2. **Layer, don't loop one track.** Rain, wind, lamp hum, road tone, spot sounds and foley on separate buses.
3. **Alternate noise and silence.** Sudden quiet after a spike beats constant noise.
4. **Never go truly dead.** In the silence beat, fade weather but keep faint room tone plus the player's footsteps and cloth.
5. **Positional audio carries the Fog Figure.**
6. **The lamp's hum is a gauge.** Its pitch falls as the lamp dims — the audio tell for the attention economy.
7. **The hum also reports the cone.** A faint upper partial joins while the figure is held inside the gaze cone. This is the audio half of the cone-legibility system and it works with your eyes down at the watch.

### Bus layout

| Bus | Contents |
| --- | --- |
| Master | Everything (limiter) |
| **Weather** | Parent of Rain and Wind. **Only the silence beat touches it.** |
| Rain | Rain loop (low-pass for muffled moments) |
| Wind | Wind loop |
| Ambience | Lamp hum, road room tone, and the Weather bus. Compressor sidechained from SFX. |
| SFX | Events, bus, footsteps (light reverb) |
| Voice | The one processed voice (light distortion + low-pass) |
| ShelterVerb | Sounds under the roof (reverb, via a small trigger area) |
| UI | Menu clicks |

**Why a Weather bus:** the options sliders control Master, Ambience, SFX and Voice. The silence beat fades only Weather, so player settings are never overwritten and restoring is simply returning Weather to 0 dB.

Note that "Ambience" parents the weather. Players who turn ambience down lose the rain — acceptable since there's no music, but label the slider "Ambience & weather" so it isn't mistaken for a music channel.

### The one voice (~12 short lines)

Record and process them yourself.

- **Radio:** fragments — "…still waiting?", "…nearly time."
- **Payphone:** breathing, then "It's already 11:47."
- **Stranger (Ending 3):** repeats your own "Hello?"
- **Player:** a single "Hello?" when you speak.
- **End card:** no voice.

### Audio asset list (~25)

| Group | Items |
| --- | --- |
| Beds | Rain loop, wind loop, lamp hum (**pitch-mappable, plus a gaze partial**), faint road room tone |
| Foley | Footsteps on gravel and concrete, cloth, breath, watch raise, paper creak |
| Events | Distant engine, gravel steps, bin radio static, payphone ring + pickup, glass tap |
| Bus | Engine approach, brake hiss, door open/close, interior hum |
| Voice | ~12 short lines, one processed voice |
| Stingers | One low drone for the final ending; a faint heartbeat for low lamp light |

---

## 15. UI and accessibility

### In-game UI (deliberately minimal)

| Element | Description |
| --- | --- |
| Crosshair | A single tiny dot |
| Interaction prompt | Small text under the dot, e.g. "Read timetable" |
| Hold ring | Fills during hold actions (speak, board) |
| Watch | **Diegetic**: forearm raised on Q, LCD shows the time. No overlay. |
| Timetable / poster | Diegetic lean-in (hold E), cancelled automatically by any big event |
| Title cards | "Night 1/2/3" for 3 s |
| Ending card | One or two lines |

**The gaze cone is communicated diegetically** (the silhouette lightening + the hum partial), not with HUD. The cone vignette is an accessibility option, off by default.

### Menus

- **Main:** Start, Endings (five slots that fill in), Options, Quit.
- **Pause:** Resume, Options, Restart Night, Quit to Menu.
- **Content note on first launch:** flashing light, dark imagery, loud sudden audio.

### Options

- Master, SFX, and ambience & weather volume
- Mouse sensitivity, invert Y, field of view *(the gaze cone scales with FOV)*
- Head bob on/off
- **Reduce flicker** (one slow dim instead of fast stutter)
- **Show gaze boundary** (cone-matched screen vignette)
- **Captions** for audio-only events — "[distant engine]", "[footsteps behind you, left]"
- PSX intensity (dither and vertex snapping on/off)
- Fullscreen and resolution
- **Press instead of hold** for confirm actions

### Accessibility checklist

- **No more than three flashes per second — enforced by the default, not by a store-page warning.** The lamp flicker's fastest cycle stays well under the limit, and scripted blackouts are ≥ 3 s. Plus a **reduce-flicker** option that replaces the stutter with one slow dim.
- Captions for every important sound cue, **including direction**. The figure advances when unwatched and footsteps tell you where, so directional captions are load-bearing.
- Optional audio cue when the figure moves, for players who can't run the look-away loop.
- **The gaze-cone boundary is perceivable without vision** — the hum partial is the audio channel for it.
- All text readable at the base resolution.
- Rebindable keys. Pausing allowed. No timed button-mashing anywhere.

---

## 16. Fairness rules

Testable assertions the design commits to.

1. **No rule can end a run until the game has shown it or demonstrated it non-lethally.** Night 1 cannot kill the player **under any input**. Gaze death requires all three of: the night is lethal, the player has survived a blackout (the mechanic has been demonstrated), and the figure is at the cap.
2. **Every rule break is a deliberate act:** crossing the sign line (Night 2+), a 1 s hold to speak, a 1 s hold to board.
3. **Every dangerous moment has a tell at least 2 s ahead:** the lamp dims, its hum drops in pitch, the watch changes, a heartbeat joins.
4. **The clock is exact.** It reads 11:47 at the moment the bus arrives, every night.
5. **A restart takes under 5 seconds.**
6. **The player never dies to something they could not see.** Sight is checked against real blockers only, never beyond the fog end.
7. **Scripted blackouts never kill.** Only a blackout the player caused by staring can.
8. **"Watched" and "stared at" are the same test.** There is no angle at which the figure is frozen for free.
9. **No ending loops forever.**
10. **The gaze cone's boundary must be perceivable.** The outer 59% of horizontal view counts as unwatched; a player who cannot tell where that boundary is will read the result as cheating. Silhouette highlight + audio tell by default, optional cone vignette. (Not rim lighting — rim is invisible on an unshaded material.)

---

## 17. Design reasoning — the stress test

**Self-assessment (judgement, not data):**

| Criterion | /10 | Why |
| --- | --- | --- |
| Simplicity | 9 | One-sentence pitch. |
| Fit for solo dev | 8 | Single location, small asset list. |
| Emotional specificity | 7 | Lonely, exposed dread rather than generic fear. |
| Originality — premise | **3** | The night-bus-stop premise is effectively a genre convention. |
| Originality — mechanic | **7** | "The light is a resource you spend by looking" has no found competitor. "The rules are a timetable" has none either. |
| Replayability | **4** | Four of five endings are one-mistake endings reachable in under a minute once known. Fine for a free 25-minute release. |
| Shareability | 7 | Three clip moments designed in. |

**The premise is a 3 and the mechanic is a 7, and only one of those belongs on the store page.**

**Design for shareability, not replay.** ~40% of art and audio polish goes to these three:

1. **The rain stops.** Night 3: weather fades to near-silence.
2. **The stranger answers.** Ending 3: the figure on the bench replies in the voice you already heard on the radio.
3. **The numberless bus.** Night 2: doors open on a lit, empty interior, and nothing is inside.

**Anti-cliché test.** "Replace bus stop with empty mall and the structure still works" is false — not because of the lamp pool (a mall has lights too, and light-as-safety is established prior art), but because of two things a mall genuinely cannot have: **a timetable that tells you the rules**, and **a last service you can miss**. Those are transit-specific, bureaucratic, and unclaimed. The lamp *economy* (spending light by looking) is the third leg, and it is mechanic rather than setting.

**Objections and responses:**

| Objection | Response in the design |
| --- | --- |
| Waiting is boring; no agency. | Looking is a decision with a two-way cost. Verified in early testing, not argued on paper. |
| Players won't read the rules and will fail unfairly. | Sign legible from Night 1; Night 1 cannot kill under any input; rules readable from Night 2; every rule break is a 1 s hold; the first gaze blackout is always survivable **and** gaze death is night-gated. |
| Three repeated nights feel repetitive. | Each night changes events, poster, the figure's cap and the lures; the clock starts earlier and the wait gets longer. Night 1 is deliberately gentle so repetition reads as escalation. |
| Too quiet, not scary. | The pacing alternates noise and silence; the attention economy keeps the eyes busy. |
| The creature can't hurt you, so nothing is at stake. | It can — but only in Night 3, only at the cap, and only after a survivable demonstration. |
| The premise is crowded. | True. Compete on the gaze economy and the timetable, never on the bus stop. |
| The cone boundary will feel arbitrary. | True risk. Made perceivable by design, and A/B tested early. |

---

## 18. Decisions log and open questions

### Decisions in this document

| Decision | Reason |
| --- | --- |
| Title *Thank You for Waiting* | It is the end card, so the title pays off in the final frame. Bureaucratic-transit register with no contested phrase. |
| Differentiator is the gaze economy and the timetable, **not** light-as-safety | Light-as-safety is well-trodden; "staring spends the light" is not. |
| Originality scored as premise 3 / mechanic 7, not one number | Only the mechanic belongs on the store page. |
| **Gaze death requires three gates** (lethal night + demonstrated mechanic + figure at cap) | Night 1 must be unable to kill under any input. |
| **The cone boundary is made perceivable** (silhouette highlight + hum partial, optional vignette) | The outer 59% of horizontal view counts as unwatched; an invisible core rule reads as cheating. |
| Legibility beats ambiguity for the cone | Dread comes from the lamp draining, not from uncertainty about the boundary. |
| **The stranger leaves if you never speak** | Turns Rule 2 from an arbitrary prohibition into withheld information, so breaking it is a real temptation. |
| Slower drain at the cap | The only creature-kill shouldn't take 7 s. |
| Fifth station inside the light, debug-gated | Fixes the one-sided endgame; ships only if playtest says dread, not unfair. |
| Ending 4 is terminal | No ending may loop forever. |
| Ending 1 has two variants under one card | Two different deaths deserve two images. |
| Night 1's sign warning does not advance the figure | Otherwise an early mistake exhausts Night 1's cap and neuters the 5:00 climax. |
| The stare lesson is an authored Night 1 beat at 2:30 | It must be designed, not emergent. |
| Arriving earlier and waiting longer each night is intentional | Free lore: the loop is tightening. Do not align the start times. |
| No tension budget; authored beats always play | A budget could silently remove a rule test. |
| The bus arrival defines the clock; it hits 11:47 exactly then | The premise is that the bus comes at 11:47. |
| Constant clock tempo (~25 s per in-game minute) | The watch is a telegraph device, so the tick rate must be stable. |
| Forearms in a yellow raincoat; diegetic digital watch | Gives the poster payoff a visible jacket and the watch a cost. |
| The bus door is just outside the light, 1.5 m reach, 1 s hold | Boarding becomes a deliberate walk into the dark. |
| The numberless bus is empty; the real bus is full | The clean ending becomes the scariest. |
| One processed voice for radio, payphone and stranger | Cheaper, and gives Ending 3 its payoff. |
| Design for shareable moments, not replay | Replayability is honestly 4/10. |
| Depth fog, not volumetric | Better fit for the PS1 look, cheaper. |
| Walk speed 1.8 m/s | 1.4 is realistic but too slow for a game. |
| The bin radio + ~3 voice lines are load-bearing for **Rule 2**, not just Ending 3 | Without the chain, Rule 2 collapses into a generic don't-talk-to-strangers prohibition. Non-verbal fallback specified rather than dropping the chain. |
| E8 (glass reflection) and E9 (payphone) are the first cuts | Nothing depends on E8; E9 only carries one lore line, and E6 already carries the voice. |
| Ending 4 costs almost nothing and guarantees no soft-lock | It is the cheapest safety feature in the game. |
| The boarding walk deliberately leaves the light | Leaving is the last decision the game asks you to make. |

### Open questions

1. **Title** — confirm *Thank You for Waiting* after a manual search; *Route 47* is the fallback.
2. **Voice** — record your own ~12 lines, or use the non-verbal fallback? **This is blocking:** the bin radio and ~3 lines are load-bearing for Rule 2 as well as Ending 3.
3. **Region and period** — unnamed, or commit? "END OF SERVICE" and a route-number blind read UK/Commonwealth; a destination board naming a stop reads North American. Pick one — it drives the bus model.
4. **Gamepad support** — needed for release, or keyboard and mouse only?
5. **Price** — free, PWYW, or a small fixed price?
6. **Hardware target** — weakest machine you want supported?
7. **Hold-to-confirm accessibility** — is press-instead-of-hold worth the work for release?
8. **The breach rule** — ship the fifth station or cut it? Decide from playtest, not now.
9. **Cone legibility layers** — does the silhouette highlight + hum partial suffice, or does the vignette need to be default-on? A/B test in-engine, not from the code.
10. **Six ending slots or five with variants?** Cheap either way; decide late.

---

*End of document — story-and-design edition.*
