# BUS STOP — Game Design Document

**Working title:** *Thank You for Waiting* (see §2; previously *Bus Stop*, then *Please Wait Inside the Light*)
**Genre:** First-person psychological horror, "waiting game"
**Platform:** PC (Windows first, Linux optional)
**Engine:** Godot 4.x (GDScript), checked against the 4.7 reference
**Team:** one solo developer
**Target length:** 22–26 minutes for a clean run, with 5 endings
**Visual style:** PS1-era low-poly, heavy depth fog, night rain
**Document status:** **v1.9** — single merged source. Supersedes v1.7, v1.6, v1.5, v1.4, v1.3, the *v1.2 GDD* and the standalone *Title and Premise Collision Check*; the collision findings are now §2 and Appendix A. §0 is a cumulative change log.

---

## Table of contents

0. What changed (cumulative log — v1.9 → v1.3)
1. Working understanding and success criteria
2. Title, market position and prior art
3. Concept and pitch
4. Concept stress test
5. Player experience and emotional targets
6. Design pillars and fairness rules
7. Game structure, core loop and the attention economy
8. Mechanics, controls and verbs
9. The Rules system
10. Story, lore and endings
11. Night-by-night beat sheets
12. Event catalogue
13. The Director
14. World and level design
15. Visual direction
16. Audio direction
17. UI, UX and accessibility
18. Technical architecture
19. Godot project settings
20. Production plan
21. Risk register
22. Testing plan
23. Release plan
24. Asset sourcing and licensing
25. Decisions log and open questions
26. References
A. Appendix A — competitor detail and research method

---

## 0. What changed

Cumulative change log. Every item was traced to code, arithmetic, the Godot source or a live page before being applied. Items are separated into correctness, design, market and editorial — a design decision is not a bug fix and should not be filed as one.

---

### v1.9 (this revision — the v2 build)

A second, playable build now exists at `bus-stop-game/` (archive of the first pass at
`archive/v1-first-pass/`). It is the reference implementation of this document and it is
what the four corrections below were learned from.

| # | Change | Why |
| --- | --- | --- |
| 1 | `FogFigure.seen_material` is typed `Material`, not `StandardMaterial3D` | The shipped highlight runs on the PSX `ShaderMaterial`; `albedo_color` does not exist there. The script now branches on `is ShaderMaterial` and sets `albedo_tint`. |
| 2 | Post-processing must use `uniform sampler2D screen_tex : hint_screen_texture`, **not** `SCREEN_TEXTURE` | `SCREEN_TEXTURE` was removed in Godot 4; the builtin now errors at shader compile. |
| 3 | Rain needs `GPUParticlesCollisionBox3D` on every roof | Without it rain falls through the shelter roof — the single most-reported visual bug of the first pass. |
| 4 | The PSX look is two shaders, not a third-party pack | `psx.gdshader` (per-vertex one-lamp lighting, clip-space vertex snapping, texel-snapped UVs, depth fog) and `post.gdshader` (15-bit quantisation, ordered dither, vignette). Self-contained, no licence review, and it is what makes the 320x180 framebuffer read as PS1. §15's pack list remains valid if you prefer a pack. |

The first pass's failures are recorded here because they are the cheapest lessons in this
document: **a world with no collision**, **input actions referenced but never defined**,
**particle systems with nothing to collide against**, and **a UI assembled in code with no
font and no styling**. None were visible in review. All were visible in the first sixty
seconds of play. Build early, play early.

---

### v1.8 (this revision — a playable reference implementation now exists)

`bus-stop-game/` (also `bus-stop-game.zip`) is a full Godot 4.7 project implementing this document: all §18 scripts, the generated models (`models/*.tscn` + `*.glb`), generated diegetic textures, 27 synthesized WAVs, and the three-night spine. **42/42 scripts compile; the headless spine test runs Night 1 → 2 → 3 → terminal `still_waiting` with zero script errors.** Building it surfaced four corrections, applied below.

| # | Correction | Detail |
| --- | --- | --- |
| 1 | **`Interactable` must extend `StaticBody3D`, not `Node3D`.** | The interaction ray resolves its target with `ray.get_collider()`, which returns the *body* — so the body has to be the Interactable. As a `Node3D` it could only ever work if the collider were a child, and then `hit is Interactable` is false. §18 corrected. |
| 2 | **`EventContext` needs more than four fields.** | Events legitimately need the tracker, the bus rig, the HUD and the world root. Added `tracker`, `bus`, `hud`, `world`. §18 corrected. |
| 3 | **`for k, v in dict:` is not valid GDScript.** | Two-variable dictionary iteration is a parse error ("Expected `in` or `:` after for variable name"). Iterate `dict.keys()` and index. |
| 4 | **`@onready` resolves at tree entry.** | Building a node's children *after* `add_child()` leaves every `@onready` var null — this broke the bus rig and player on first run. Build subtrees **detached**, then add the root. Worth knowing before week 1. |

Two environment notes from the build, for whoever runs it: user CLI flags like `--autostart` are in `OS.get_cmdline_args()`, not `get_cmdline_user_args()` (the latter is only args after `--`); and `Engine.time_scale` scales `_process` deltas, SceneTreeTimers and tweens together, which is what makes a headless three-night run take ~2 minutes instead of ~20.

### v1.7 (this revision — the two "excerpt" scripts did not compile)

A reader pasted the code into a real project and got parse errors. They were right, and v1.6's verification claim was misleading.

#### The defect

§18 contained two blocks labelled `(excerpt)`: `main.gd` and `player/interaction.gd`. Neither had an `extends` line, neither declared the members it used, and `interaction.gd` called a function (`_current_interactable()`) that was never defined. Pasted into a project they produce exactly the errors reported:

```
res://player/interaction.gd:5 - Parse Error: Function "_current_interactable()" not found in base self.
res://player/interaction.gd:8 - Parse Error: Identifier "ui" not declared in the current scope.
res://main.gd:7  - Parse Error: Identifier "figure" not declared in the current scope.
res://main.gd:19 - Parse Error: Function "get_tree()" not found in base self.
res://main.gd:22 - Parse Error: Function "_window_closed()" not found in base self.
```

A document marked "ready to build from" should not contain code that cannot be pasted. That is the whole value proposition of putting code in a GDD.

#### Why v1.6's verification missed it

v1.6 claimed "18/18 complete scripts imported and compiled with zero script errors." That was literally true and materially misleading, because of a hole in the method:

- `godot --headless --import` runs `update_scripts_classes`, which scans for **`class_name` declarations only**. Neither excerpt has one.
- The test scenes never referenced either file, so nothing ever loaded them.
- `--check-only --script <file>` *would* have caught it — and did, in an earlier pass, where both files were correctly reported as failing. That result was then set aside as "they're excerpts" and never revisited.

So the two files that a developer touches **first** were the only two never compiled.

#### Fix

Both are now complete scripts and both compile:

| File | Lines | Now implements |
| --- | --- | --- |
| `main.gd` | 90 | `extends Node3D`; exported node refs matching the §18 scene tree; `ctx` construction; `run_night()` with the run-id guard; **`_window_closed()` for all three nights** (Nights 1–2 advance, Night 3 → terminal `still_waiting`); `_on_ending()` with same-night restart under fairness rule 5; `_on_sign_warned()` (lamp to 20%, drone, and a comment forbidding teleport push-back); `Director.event_started → cancel_lean()` for intensity ≥ 2, which §18 previously only described in prose. |
| `player/interaction.gd` | 76 | `class_name PlayerInteraction extends Node`; tap vs hold dispatch; `_current_interactable()` with the ray hit **and** `can_use()` reach check; lean-in for anything in the `readable` group; `cancel_lean()`; `is_leaning()`; sets `ray.collision_mask = 1 << 2` (layer 3 only) and a 2.5 m target in `_ready()`. |

The HUD is coupled by **signal** (`prompt_changed`, `hold_progress_changed`, `lean_changed`) rather than by a direct `ui` reference, so no HUD class has to exist for these to compile. §17 should note that the HUD connects to those three.

#### New check — parse every script

§22 gains a check that closes the method hole:

> **Every script compiles.** At runtime, inside a project where autoloads exist, walk `res://` and `load()` every `.gd`, asserting each returns a `Script` with `can_instantiate() == true`.

Neither `--import` (scans `class_name` only) nor `--check-only` (does not register autoloads, so anything touching `Game` / `Save` / `AudioHub` fails spuriously) is sufficient on its own. Running it: **26/26 scripts, 0 failures.**

The harness in `bus-stop-tests/` ships this as `tests/parseall.tscn`. **Run it before believing any other result.**

---

### v1.6 (this revision — the code was executed, not just read)

Godot **4.7.stable.official** was installed and all 20 GDScript blocks from §18 were extracted verbatim into a real project (autoloads, six physics layers, the eight-bus `default_bus_layout.tres`) and **run**. 18/18 complete scripts imported and compiled with **zero script errors**; the 2 documented excerpts were wrapped in harness stubs.

> **Correction (v1.7):** that claim was misleading. The import pass only scans for `class_name` declarations and the test scenes never referenced the two excerpts, so they were never compiled — and they do not compile as written. See the v1.7 section above.

**Final tally after both fixes: 66 assertions across 16 test groups, 0 failures** (raised to **69 across 17 groups** in v1.7 once the two excerpt scripts were completed and the same-event exclusion was added) — re-run against scripts extracted verbatim from *this* document, not from an intermediate draft.

Two defects were found that static review had missed. One of them the document's own arithmetic actively concealed; the other affected **every night including the finale**.

#### Defect 1 — the bus arrived 15 seconds late, every night

The §11 beat sheets schedule an "engine approaches" beat (intensity 2) ~15 s before each **Arrival** beat (intensity 3), and §18 requires the arrival tween to end exactly when `clock.arrived` fires. Those are incompatible with the Director as written: when the approach ends, `_on_finished` sets `_calm_until = _t + 15`, and the arrival — due at that same instant — is blocked by the calm window.

Measured per night, with each night's real 15 s approach lead and `max_delay = 40`:

| Night | `real_seconds` | Arrival due | Arrival fired | Late by |
| --- | --- | --- | --- | --- |
| 1 | 300.0 | 300.0 | 315.00 | **+15.00 s** |
| 2 | 380.0 | 380.0 | 395.02 | **+15.02 s** |
| 3 | 405.0 | 405.0 | 420.02 | **+15.02 s** |

A tighter `max_delay = 20` gives the same +15.02 s, because the calm window expires first either way.

`max_delay` never rescued it, because the calm window (15 s) expires before `max_delay` elapses. **The clock reads 11:47 and the bus is not there for another quarter of a minute** — in all three nights, including the finale. Fairness rule 4 ("the clock reads 11:47 at the moment the bus arrives") was violated by the pacing system the document itself specified.

**Fix:** `BeatDef.punctual` — a structural beat that fires at `time_sec` and ignores the pacing rules entirely. Measured after the fix:

| Night | Arrival fired | Late by |
| --- | --- | --- |
| 1 | 300.00 | **+0.00 s** |
| 2 | 380.02 | **+0.02 s** (one physics frame) |
| 3 | 405.02 | **+0.02 s** |

Also verified with a 10 s approach lead: +0.02 s. The fix is insensitive to the approach beat's length.

All three arrival beats (S1, S2, S3) are marked punctual in §11 and §13. Conceptually: the Director paces *scares*; the night's *spine* belongs to `main.gd` and the clock. New §22 check asserts arrival punctuality to ±0.1 s.

#### Defect 2 — the flicker clamp had no headroom and breached the limit at runtime

v1.5 clamped the cycle to 0.36–0.70 s and asserted "1.43–2.78 Hz, under the limit with margin." That arithmetic is correct for the *nominal* interval and wrong for the *observed* rate: `tween_interval` lands on frame boundaries, and frame-time jitter shifts each detected transition by up to a full frame in either direction.

Measured over 23 real cycles with `MIN_CYCLE = 0.36`, timed by `Time.get_ticks_msec()` (a later 21-cycle run reproduced the same failure):

> cycle min **0.332 s**, max 0.670 s → peak **3.01 Hz** against a 3.00 Hz limit. **FAIL.**

Re-measured over 51 cycles with `MIN_CYCLE = 0.45`, `MAX_CYCLE = 0.80`:

> cycle min **0.455 s**, max 0.794 s → peak **2.20 Hz**, floor 1.26 Hz. **PASS, 27% headroom.**

Re-measured against this document's shipped constants over 39 cycles: min **0.442 s**, max 0.794 s → **1.26–2.26 Hz**. **PASS.**

Constants changed to **0.45 / 0.80** throughout, and §22's flicker check is now specified as a **runtime measurement**, not a computation from constants — computing it from constants is precisely what produced the false PASS in v1.5.

#### What execution confirmed (previously asserted from source reading only)

| Claim | Result |
| --- | --- |
| Night 1 cannot kill: 95 s of continuous staring | **PASS** — no death, `armed` set, figure parked at cap |
| Night 2 cannot kill by gaze, 95 s | **PASS** |
| Night 3 cap at ~26.03 s, death at ~36.37 s | **PASS** — measured 26.03 s and 36.37 s in-engine |
| `gaze_lethal = false` survives 60 s at cap | **PASS** |
| `start_minute()` → 11:35 / 11:32 / 11:31 | **PASS** |
| Tempo 25.00 / 25.33 / 25.31 s per in-game minute | **PASS** |
| Clock frozen at 11:47; `arrived` fires exactly once | **PASS**, all three nights |
| `start()` emits the initial minute (v1.5 fix) | **PASS** |
| `LampController.reset()` restores level / flicker / blackout (v1.5 fix) | **PASS** |
| `_move_to()` inherits neither marker rotation nor scale (v1.5 fix) | **PASS** |
| `EventBase._ended`: `finished` once across `_done()` ×2 + `abort()` | **PASS** |
| `AudioHub` resolves the Weather bus; `reset()` → 0 dB | **PASS** |
| Director: intensity-3 hard rule; authored beats wait rather than drop; `_live` pruned on finish | **PASS** |
| Director: freed-without-`finished` instance pruned, intensity-3 not permanently blocked (v1.5 fix) | **PASS** |
| Sign line: Night 1 warns once and does not end the run; Night 2+ ends it; non-player bodies ignored | **PASS** |
| `StandardMaterial3D` has **no** `set_shader_parameter`; `ShaderMaterial` does | **PASS** — confirms v1.4's code was a hard runtime error |
| `albedo_color` exists on `StandardMaterial3D` (the v1.5 replacement) | **PASS** |
| `for i in 3:` bare-int iteration | **PASS** |
| Cross-object `target.triggered.emit()` | **PASS** |
| One-line `class_name X extends Y` | **PASS** — 18/18 scripts imported and ran |

#### Method note

Reproduce with `godot --headless --path <proj> --import`, then run a test scene as the main scene. Two GDScript gotchas cost more debugging time than the code under test, and both are worth knowing before you write your own suite: **lambdas capture by value** (`var n := 0; sig.connect(func(): n += 1)` never updates the outer `n` — use an array), and **`--check-only` does not register autoloads**, so any script referencing `Game` / `Save` / `AudioHub` fails to compile under it even though it is correct at runtime. Drive `_physics_process(DT)` manually for deterministic timing tests, and step the Director's live event instances manually too — otherwise their own `_process` never runs. Only tween-dependent tests need real frames.

**Keep this project.** It is ~2 hours of setup and it is the only thing that caught either defect. Fold it into the real repo as `res://tests/` in week 1, not week 9.

---

### v1.5 (this revision — full audit of every code block against the Godot 4.7 API)

#### Correctness — would break at runtime, or ship visibly broken

| # | Problem | Verdict | Fix |
| --- | --- | --- | --- |
| 1 | **The cone highlight could not have worked at all.** `seen_material.set_shader_parameter("rim_tint", …)` on a `StandardMaterial3D` is a hard runtime error — `set_shader_parameter` is bound only to `ShaderMaterial` (`ClassDB::bind_method(…, &ShaderMaterial::set_shader_parameter)`). `rim_tint` is also the wrong property: the docs define it as *"the amount to blend light and albedo color"*, while `rim` is *"the strength of the rim lighting effect."* And decisively, `BaseMaterial3D.rim_enabled` carries the note *"Rim lighting is not visible if the material's `shading_mode` is `SHADING_MODE_UNSHADED`"* — which is exactly what a PS1 fog silhouette should be. | **Real, three ways, and it was fairness rule 10's primary visual layer.** It would have passed every automated check in §22, because the boolean driving it was correct. | Replaced with a flat **`albedo_color` swap** on the figure's own material, change-guarded so it only writes on transition. Works unshaded, costs nothing, is PS1-appropriate. §8, §14, §17, §20, §21, §22 and §25 all updated. New §22 **manual in-engine** check and new **risk 16** for the general class: *correct in code, invisible in game*. |
| 2 | **The lamp was never reset between nights.** `LampController.level` persists, so a night could begin at 0.5 after a blackout and be one stare from a second — and a Night 3 that started dim would reach the cap drain almost immediately. | Real bug. | `LampController.reset()` (level 1.0, flicker 1.0, `scripted_blackout` false), called from `run_night()`. New §22 night-start-state check. |
| 3 | **`GazeMonitor._stare` carried across nights**, skipping the 2 s grace at the start of a new night. | Real bug. | Cleared in `configure()`. `armed` still deliberately persists. |
| 4 | **The autoload-order note was backwards.** It claimed "`Save` must be above `Game`, since `Game.trigger_ending()` calls `Save.write()`." That call happens at runtime, when both exist, so order is irrelevant. Autoloads enter the tree in listed order, so an autoload's `_ready()` can only reference ones **above** it — meaning if `Save.read()` ever moves into `Save._ready()`, the required order is **`Game` above `Save`**, the opposite of what was written. | Real error, and the kind that bites only after a later refactor. | Corrected in §18 and §19, with the order-independent option: call `Save.read()` from `Main._ready()`. |
| 5 | **`_move_to()` copied `global_transform`** from the `Marker3D`, inheriting its rotation and scale. A marker rotated to face the road would silently rotate or scale the figure. | Real latent bug. | Copies `global_position` only; comment explains why. Same for the breach step. |

#### Robustness — fails only under specific conditions

| # | Problem | Fix |
| --- | --- | --- |
| 6 | **The Director assumes `beats` is sorted ascending.** It queues with a single forward `while` cursor, so one out-of-order beat is never queued, never plays and never warns. | `_assert_beats_sorted()` in `start_night()`, plus a §22 check. |
| 7 | **`_live` could leak a freed instance** if an event node were freed without emitting `finished`. A stale intensity-3 entry would then permanently block every authored climax for the rest of the night. | `_can_start()` prunes keys failing `is_instance_valid()`. |
| 8 | **`_start()` didn't validate the instantiate cast.** `as EventBase` returns null on a wrong scene root, and `add_child(null)` crashes. | Asserts for both a missing `scene` and a non-`EventBase` root. |
| 9 | **`AudioHub` didn't guard a missing `Weather` bus.** `get_bus_index()` returns −1, so `set_bus_volume_db(-1, …)` errors and the silence beat — the game's climax — fails silently. | `_weather_bus()` with an assert naming `default_bus_layout.tres`. |
| 10 | **Overlapping weather fades fought over the bus** (e.g. `restore_weather()` during `silence_beat()`). | `_tw` tracked and killed before each new fade, including in `reset()`. |
| 11 | **`NightClock.current_minute()` divided by `_total` with no zero guard**, and `start()` didn't emit the initial minute, so the HUD showed nothing for a frame. | Zero guard returns `ARRIVAL_MINUTE`; `start()` emits immediately; `assert` on `real_seconds > 0`. |
| 12 | **`rain.gd` dereferenced `target` unguarded.** | Null check. |

#### Documentation

| # | Change |
| --- | --- |
| 13 | `_window_closed()` was specified only for Night 3. **Nights 1 and 2 reaching it is the clean path**, not a failure — now a per-night table in §18. |
| 14 | The Night 1 sign push-back must be a **displacement over frames, not a teleport**: a teleport can deposit the player past a ~1 m wall, which in Night 2+ is an instant ending they never chose. |
| 15 | `check_initial_overlap()` and `body_entered` can both fire for one crossing on restart. Benign (both guards catch it) — documented so it isn't "fixed" by deleting either path. |
| 16 | `Interactable.hold_seconds` comment read like an enum; it is a duration. |

#### Audited and found NOT to be problems

Recorded so they are not re-raised or "fixed."

- **`for i in n:` with a bare int is valid Godot 4.** The GDScript reference documents `for i in 3:` as *"Similar to range(3)"* and `for i in 2.2:` as *"Similar to range(ceil(2.2))"*. Used in `LookAtTracker.seen()` and `e01_lamp_flicker.gd`. `range()` still gets a compiler fast path that a bare int does not, so prefer `range()` in hot loops — `_physics_process` at 3 rays is not hot enough to matter.
- **`target.triggered.emit()` from another object is valid.** There is no cross-object emit restriction anywhere in the GDScript analyzer, parser, compiler or VM; `Signal` is a value type holding an object id and a name.
- **One-line `class_name X extends Y` remains valid** in all of Godot 4 (v1.4 item A).
- **`create_tween()` on a node is bound to that node** and follows its process mode — confirmed correct in `e01_lamp_flicker.gd` and `audio_hub.gd`.
- **`create_timer(seconds, false)` respects pause** — the second parameter is `process_always`, confirmed in the 4.7 source.

---

### v1.4

#### Correctness

| # | Problem | Verdict | Fix |
| --- | --- | --- | --- |
| 1 | **The lamp flicker ran at 3.1-11.1 Hz.** `e01_lamp_flicker.gd` used intervals of 0.04-0.12 s and 0.05-0.20 s, so a full cycle was 0.09-0.32 s. §17 promised "no more than three flashes per second." **Every possible roll violated it**, including the slowest (3.12 Hz). | Real bug, confirmed by computing the cycle range. A store-page photosensitivity warning does not cover a *default* setting — the default has to respect the limit. | Cycle clamped to **0.45-0.80 s** via `MIN_CYCLE` / `MAX_CYCLE` (measured peak 2.20 Hz). §17 rewritten to state the limit is enforced in code. New automated check samples 1000 rolls. *(§17, §18, §22)* |
| 2 | **§22's Night 3 death-timing window was too wide to catch a regression.** 30-42 s passed three separately-broken variants of the drain logic. | Real weakness. | Tightened to **25.5-26.6 s** (cap) and **35.8-37.0 s** (death). §18 gains an authoritative frame-accurate phase trace so the numbers are read, not re-derived. *(§18, §22)* |
| 3 | §20's Definition of Done claimed "Nights 1 and 2 cannot kill the player under any input." | False — Night 2's sign line is lethal by design. | Scoped to "Night 1 cannot kill under any input; Night 2 cannot kill **by gaze**." |
| 4 | Night-length sum stated as 20.25 min. | Arithmetic slip. | 330 + 425 + 465 = 1220 s = **20.33 min**. *(§11)* |

#### Design

| # | Change | Reason |
| --- | --- | --- |
| 5 | **Gaze-cone legibility promoted from polish to a fairness system.** Rim highlight on the figure while it is in the cone (default on), a hum partial so it is audible with your eyes down at the watch (default on), and a cone-matched vignette as an accessibility toggle (default off). New **fairness rule 10**. | The unified cone means the outer **59% of horizontal view** counts as unwatched. Players assume anything on screen is watched, so an invisible boundary reads as cheating. This **deliberately overrules** v1.0's "the player should never be sure how fast it moves": dread here comes from the lamp draining, not from uncertainty about the rule. It is a design decision, and v1.3 wrongly filed it under correctness. *(§8, §16, §17)* |
| 6 | **Rule 2's voice dependency made explicit.** E6 + ~3 short lines are load-bearing for **Rule 2**, not only for Ending 3. A non-verbal fallback is specified. Open question 2 promoted from preference to **blocking**. | Rule 2 reads as the generic don't-talk-to-strangers beat unless the E6 → E7 → Ending 3 chain lands. Cutting voice silently collapses the rule back into a prohibition. *(§9, §20, §25)* |

#### Documentation

| # | Change |
| --- | --- |
| 7 | `figure_cap` → **`figure_cap_index`**, `cap_station` → **`cap_index`**, plus a 0-based/1-based mapping table in §14. The field was internally consistent but had to be re-derived from scratch on every edit. |
| 8 | §0 restructured into Correctness / Design / Market / Editorial, and v1.3's claim "Nothing here changes the concept" **removed** — it was false (item 5 above is a concept-level design decision). |
| 9 | Version bumped to v1.4; §0 is now cumulative so the audit trail survives. |

#### Reviewed and NOT changed — with evidence

Two items were raised in review, checked, and found not to be defects. Recorded here so they are not re-litigated or "fixed" later.

**A. `class_name X extends Y` on one line is valid GDScript.** It is *not* a parse error, and every script in §18 will paste and run.

`GDScriptParser::parse_class_name()` handles a trailing `EXTENDS` token explicitly, with the source comment *"Allow extends on the same line"* — [gdscript_parser.cpp, 4.7-stable](https://github.com/godotengine/godot/blob/4.7-stable/modules/gdscript/gdscript_parser.cpp):

```cpp
if (match(GDScriptTokenizer::Token::EXTENDS)) {
    // Allow extends on the same line.
    parse_extends();
    end_statement("superclass");
}
```

Verified present in **4.0, 4.1, 4.2, 4.3, 4.5 and 4.7 stable** — the whole of Godot 4. The two-line form also works and is the more common tutorial style; §18 carries a note so nobody splits twelve files for no reason. Preferring two lines is house style, not a fix.

**B. The Night 3 death timings (26.03 s to cap, 36.37 s to death) are correct as written.** Review proposed 32.7 s / 43.0 s. Re-simulated frame-accurately at 60 Hz against the code:

| Blackout | At | Rate | Why |
| --- | --- | --- | --- |
| 1 | 12.00 s | 0.10 | `station_index` 0 < cap 3, so `at_cap()` is false |
| 2 | 19.02 s | 0.10 | index 1 < 3 |
| 3 | 26.03 s | 0.10 | index 2 < 3 |
| 4 | 36.37 s | **0.06** | index 3 = cap, so `at_cap()` is now true |

The review was right that **grace is reapplied after every blackout** (`_on_gaze_blackout()` resets `_stare`) — the simulation already accounted for that. The divergence is the *rate*: `drain_per_sec_at_cap` keys off `at_cap()`, which is false until the figure reaches index 3. Applying 0.06 from blackout 2 reproduces the review's 43.00 s exactly, which confirms the diagnosis. Two other variants also fail to produce 26/36: grace applied once gives 22.03 / 30.37; a cap rate equal to 0.10 gives 26.03 / 33.05. Only the code as written gives 26.03 / 36.37. All three regressions now fall outside the tightened §22 window — which was the useful half of the note.

---

### v1.3

#### The one real bug: v1.2 let Night 1 kill the player

Introduced in v1.2, not present in v1.1. **Cause:** v1.2 added a fifth station and correctly capped `configure()` at `stations.size() - 2`, but then redefined `at_last_station()` as `station_index >= cap_station`. That silently changed the method's meaning from "at the physical last station" to "at tonight's cap" — while `GazeMonitor._on_gaze_blackout()` still used it as the lethal condition, and `armed` persists across the whole session. There was no night check anywhere.

Simulated with the exact v1.2 constants (`grace 2.0`, `drain 0.10`, `drain_at_cap 0.06`, relight `0.5`), continuous staring from the figure's appearance:

| Night | Cap | v1.2 result | v1.3 result |
| --- | --- | --- | --- |
| 1 | station 2 | **DEATH at 22.3 s** | survives indefinitely |
| 2 | station 3 | **DEATH at 29.3 s** | survives indefinitely |
| 3 | station 4 | DEATH at 36.3 s | DEATH at 36.3 s (unchanged, correct) |

This contradicted fairness rule 1, §6 ("Night 1 has no fail states"), §7 ("a stare-death is only possible in Night 3") and §10. It also **passed v1.2's own automated check**, because that check stared only to the *first* blackout — and the first blackout is always survivable by design. The test was too weak to see the bug it existed to catch.

**Fix, applied in three places:**

1. `NightDef.gaze_lethal` (true only for Night 3), read into `GazeMonitor.lethal_tonight` by `configure(def)`.
2. Death requires **all three** gates: `lethal_tonight and armed and figure.at_cap()`.
3. `at_last_station()` **renamed to `at_cap()`** with a comment naming the bug, so the ambiguity can't be reintroduced by a rename.
4. The Night 1 / Night 2 safety checks now **stare continuously for 60 s**, not to the first blackout (§22).

#### Market corrections (all verified against live pages, 5 Oct 2026)

| v1.2 claim | Correction |
| --- | --- |
| *Last Bus Home* is a recent collision, "updated ~19 days ago" | **Released 18 June 2022** (RAWG). The itch "Updated" field is not a release date and I read it as one. It is a four-year-old game with a still-active comment corpus — which makes it *more* valuable as research and removes any "someone just did this" urgency. Also: macOS as well as Windows, ~16 min. |
| 4.0/5 from 335 ratings | ≈331 at live check. Counts drift; verify at release. |
| *The Fields* is name-your-own-price | **$2, currently 100% off.** The itch page header displays "Name your own price," which is where the error came from. |
| "Stay in the light" is unclaimed framing | **It isn't.** Steam's *Into The Light* (2L Games, demo live) uses *"Stay in the light, beware of the dark… a strange world with **new rules**."* *Those Who Remain* (2020) built a whole game on light-as-sanity. *The last passenger* uses it too. |
| The lamp-pool rule is a differentiator | **Overstated.** Light-as-safety is well-trodden. See the corrected differentiator in §2 and §4. |
| Space is less crowded than reported | Added *The Cornfield Road* (PSX, multiple endings, ~Aug 2026, 162 comments) and *The stranger from the bus stop* (Ren'Py VN, tagged Psychological Horror). |
| *Please Wait Inside the Light* is clear | Clear as a **title**, but the phrase is contested (above) and it is 28 characters, which truncates on store pages. Recommendation changed — see §2. |

#### Editorial and other v1.3 changes

| # | Change |
| --- | --- |
| 1 | **§23 tense error fixed.** v1.2 said Next Fest October 2026 and Scream V Fest "ran" — as of 5 Oct 2026 both are still upcoming. Rewritten with correct dates and reachability. |
| 2 | **Gaze-cone legibility** added as a designed feature, not left to playtest. The unified cone means the outer **59% of horizontal view** counts as unwatched; players will assume anything on screen is watched and read the result as cheating. Silhouette albedo highlight + audio tell + optional cone vignette (§8, §17). |
| 3 | **Rule 2 strengthened.** "Do not speak first" reads as the generic don't-talk-to-strangers beat. The stranger now leaves after 60 s having said nothing, so breaking the rule is the *only* way to get information (§9). |
| 4 | §7's death-window paragraph corrected: reaches cap at ~26 s (≈1:06), dies at ~36 s (≈1:16). v1.2's "1:13" sat imprecisely between the two. |
| 5 | New fairness rule 10: the gaze cone's boundary must be perceivable. |
| 6 | Debug keys extended: F9 forces `armed` **and** `lethal_tonight`. |
| 7 | New risk 14: gaze-cone legibility reads as cheating. |
| 8 | Collision material merged into §2 with full detail preserved in Appendix A. Nothing from the standalone report was dropped. |

**Note on injected content:** one scraped forum page surfaced during research contained a stray embedded test string. It was not treated as instruction and nothing in this document derives from it.

---

## 1. Working understanding and success criteria

**Given:** solo developer, no team, building this game in Godot, publishing on itch.io.

**Assumed (correct any of these):**

- Scope is the top constraint; finishing beats ambition.
- Roughly 8–10 hours per week.
- Comfortable with Godot basics, not expert in shaders or audio.
- First-person 3D, PC, mouse and keyboard first.

**Success criteria:**

1. A complete, releasable game. §20 has the honest hour estimate: 137–204 hours of scope, i.e. **15–23 weeks** at 8–10 h/week, not 12.
2. A player who finishes can describe at least one moment that scared them.
3. Every ending is reachable; no run can soft-lock or loop forever; **Night 1 cannot kill the player under any input**.
4. At least three moments are strong enough to be shared as clips (§4, §23).
5. The Horror Core is reusable for the next game.
6. **Week 4 is a hard go/no-go on the attention economy.** If the glance rhythm doesn't work for three fresh players, redesign before any art is made.

---

## 2. Title, market position and prior art

Collision check run 5 October 2026 against itch.io, Steam, RAWG and web search, then re-verified against live pages. Full detail and method in Appendix A.

### The headline

**The premise is validated, not stolen — and it is not new either.** A close version of this game has been on itch since June 2022 with ~331 ratings and ~474 comments. That is good news: the audience exists, the format converts, and nobody has to be educated. It also means the bare premise cannot be your hook.

### Direct competitors

| Game | Overlap | Facts (verified 5 Oct 2026) |
| --- | --- | --- |
| **Last Bus Home** — majik | Late night, bus stop, last bus, **a stranger appears**, multiple endings incl. a secret, low-poly first-person, short | Released **18 Jun 2022**. Unreal. **4.0/5, ≈331 ratings, 474 comments.** Windows + macOS, ~16 min. Name-your-own-price. `No generative AI was used`. YouTube "all endings" coverage. Comments still arriving (most recent ~2 weeks ago). RAWG aggregated sentiment: "Meh" — a real divergence from its itch score. |
| **The Fields** — Fenixapple | Missed last bus, **PSX**, **voice-acted Stranger**, 3 endings | **$2, currently 100% off.** 48 MB, Windows. **4.3/5, 59 ratings, 80 comments.** Made in one day. Tags `PSX`, `Psychological Horror`, `Retro`, `No AI`. Same dev now on Steam with *Fractured: Snowpine Strangers*. |
| **The Cornfield Road** — shadow | Short PSX-style horror, **multiple endings**, 5–10 min | Published ~Aug 2026, 162 comments, YouTube playthroughs. The most recent genuine PSX neighbour. |
| **Last Bus Stop** — martinmakes | **Title only** — a reporter explores an abandoned city, "stay alive and reach the bus" | ~Jun 2026. 10–15 min, PWYW, 185 MB. Small audience but has YouTube coverage. |
| **Night Bus** — GURDE | Tagline literally **"Can you survive waiting for the bus?"** | PWYW. Appears on itch's `no-AI` + `PSX` browse pages — your exact neighbourhood. |
| **The last passenger** — byronrosas | **"Survive the night bus ride by staying in the light"** | LumenJam entry. Jam-scale. **AI-tagged**, which in this community is a negative filter. |
| **The stranger from the bus stop** — Daijubudef | Occupies the "stranger at the bus stop" phrase | Ren'Py browser VN. Tagged Creepy / Dating Sim / **Psychological Horror**. Different medium and audience; a phrase collision, not a competitor. |
| Also present | — | *The Midnight Bus* (itandfeel), *Waiting For The Bus* (lostwaysclub), *Night Bus* ($4.99, different dev), *Speed Dating (on) the Night Bus*, *The Last Passenger* (VoidFlare). |

### Prior art on "light is safe" — this changes the differentiator

v1.2 claimed the lamp-pool rule as a differentiator. **That was overstated.** Light-as-safety is established:

- **Those Who Remain** (2020, first-person psychological horror) — stay in the light or lose your sanity. Well known.
- **Into The Light** (Steam, 2L Games, unreleased, demo live for Scream Fest) — *"Stay in the light, beware of the dark. Survive as Damien in a strange world with **new rules** and horrific residents."* Note: "stay in the light" **and** "rules," in the same genre, actively marketed on Steam right now.
- **The last passenger** — "survive by staying in the light," jam-scale.

**What is still novel, stated precisely:**

1. **The light is a resource you spend by looking.** Not "stay in the light" — *staring at the Thing consumes the light that protects you.* No competitor found does this. This is the actual mechanic and it is the one to protect, market and playtest.
2. **The rules are printed on a timetable in bureaucratic transit language.** A route number, a last-service time, a destination board, an "END OF SERVICE" sign, a "Thank you for waiting." The horror is administrative. *Into The Light* has "new rules"; nobody found has a *timetable*.

Lead all marketing with those two. Do not lead with "person at a bus stop at night" (generic since 2022) or "stay in the light" (contested).

### Title decision

| Candidate | Verdict |
| --- | --- |
| *Bus Stop* | **Rejected.** Exact-title itch game (PistolSol, IF), plus *Last Bus Stop*, plus a dense `tag-bus` neighbourhood. Also unsearchable as a phrase. |
| *Last Bus* | **Rejected.** Collides with *Last Bus Home*, *Last Bus Stop* and two *Night Bus* titles. |
| *End of Service* | **Rejected as a title.** Exact-title itch game exists (MichelleS, IF) and the phrase is dominated by gacha/MMO shutdown terminology. **Keep it as the signpost text** — excellent diegetic copy. |
| *Please Wait Inside the Light* | **Demoted from v1.2's recommendation.** Clear as a title, but 28 characters (truncates in itch browse grids and some Steam list views) and the "inside/into the light" phrase is actively contested by *Into The Light*, *Those Who Remain* and *The last passenger*. |
| ***Thank You for Waiting*** | **Recommended.** Apparently unclaimed as a title (only incidental use in dev announcements). 21 characters. It is the timetable's closing line **and** the end card, so the title pays off in the final frame. Bureaucratic-transit register with no contested phrase. |
| *Route 47* | **Short-form alternative.** 8 characters, cleanest on any store page, already in the game. No *game* found with this title, but "Route 47" is live in creepypasta/ARG space ("Route 47 Public Access"; *"If a Gas Station Is Open on Route 47 After Midnight… DON'T STOP"*), so it may read as derivative. Manual check required. |

**Regardless of title, keep *"Please wait inside the light"* as the timetable header line.** That is where it belongs and where it works.

**Before committing:** manual search on itch.io (title + tags `psx`, `horror`, `short`), Steam, YouTube and the Haunted PS1 community pages. Ten minutes each. Search engines do not index itch reliably.

### Positioning consequences

1. **Do not lead with the bus stop.** Lead with the **timetable** or the **numberless bus** — both unclaimed images.
2. **Play *Last Bus Home* before building.** Two hours, PWYW, ~16 minutes of game. Its 474 comments spanning four years are a free corpus of what this audience notices, complains about and clips. That is better market research than this document.
3. **Carry the "No generative AI was used" tag.** Both closest competitors advertise it; the AI-tagged entry in the space is the jam one.
4. **Rule 2 needs help.** "Do not speak first" will read to players as the familiar don't-talk-to-strangers beat. §9 gives it a reason to exist; the voice payoff has to carry the rest.
5. **The RAWG "Meh" vs itch 4.0 divergence on *Last Bus Home* is worth reading as data,** not noise: aggregator audiences and itch short-horror audiences score the same game very differently. Optimise for the itch/YouTube audience, which is where this format lives.

---

## 3. Concept and pitch

> **You wait alone for the last bus on a rainy night, and the only way to survive is to obey three rules printed on a timetable — while the thing in the fog moves every time you look away, and the lamp that keeps you safe dies every time you look at it.**

**Longer pitch.** It is late. Rain. A single lamp lights a tiny shelter. The timetable says the last bus, Route 47, arrives at 11:47, and beneath it: *Please wait inside the light.* There is nowhere else to go. Over three nights that repeat, the road becomes more wrong. Something stands in the fog and only moves when you look away — but stare at it and the lamp begins to die. A stranger sits on the bench and will not speak first. A bus comes with no number. The rules tell you what is safe, and the scariest part is that following them works.

**Insight statement:**

> The player wants to get home, but the only way home is a bus that can't be trusted, because the stop itself decides who gets to leave.

**The tension this game lives in:** wanting to leave versus what leaving costs — and, moment to moment, needing to look versus being punished for looking. The first resolves only at the final bus; the second never resolves, which is what keeps the player's eyes moving.

**Why this is a good solo project:** one location, ~14 short content pieces, no combat or pathfinding, fog and a PS1 look hide missing detail, and sound does most of the scaring.

---

## 4. Concept stress test

**Self-assessment (judgement, not data):**

| Criterion | /10 | Why |
| --- | --- | --- |
| Simplicity | 9 | One-sentence pitch above. |
| Fit for solo dev | 8 | Single location, small asset list. |
| Emotional specificity | 7 | Lonely, exposed dread rather than generic fear. |
| Originality — premise | **3** | Shipped since 2022 by *Last Bus Home*; PSX version by *The Fields*. Effectively a genre convention. |
| Originality — mechanic | **7** | "The light is a resource you spend by looking" has no found competitor. "The rules are a timetable" has none either. |
| Replayability | **4** | Four of five endings are one-mistake endings reachable in under a minute once known. Fine for a free 25-minute release. |
| Shareability | 7 | Three clip moments designed in. |

v1.2 scored originality as a single 5→7. Splitting it is more honest and more useful: **the premise is a 3 and the mechanic is a 7, and only one of those belongs on the store page.**

**Design for shareability, not replay.** ~40% of art and audio polish goes to these three:

1. **The rain stops.** Night 3: weather fades to near-silence.
2. **The stranger answers.** Ending 3: the figure on the bench replies in the voice you already heard on the radio.
3. **The numberless bus.** Night 2: doors open on a lit, empty interior, and nothing is inside.

**Anti-cliché test, re-run.** "Replace bus stop with empty mall and the structure still works" — v1.2 claimed this was now false because of the lamp pool. **It isn't false for that reason**; a mall has lights too, and *Those Who Remain* and *Into The Light* already own light-as-safety. It is false because of two things a mall genuinely cannot have: **a timetable that tells you the rules**, and **a last service you can miss**. Those are transit-specific, bureaucratic, and unclaimed. The lamp *economy* (spending light by looking) is the third leg, and it is mechanic rather than setting.

**Objections:**

| Objection | Response in the design |
| --- | --- |
| Waiting is boring; no agency. | Looking is a decision with a two-way cost (§7). Verified in week 4, not argued on paper. |
| Players won't read the rules and will fail unfairly. | Sign legible from Night 1; Night 1 cannot kill under any input; rules readable from Night 2; every rule break is a 1 s hold; the first gaze blackout is always survivable **and** gaze death is night-gated. |
| Three repeated nights feel repetitive. | Each night changes events, poster, the figure's cap and the lures; the clock starts earlier and the wait gets longer (§10). Night 1 is deliberately gentle so repetition reads as escalation. |
| Too quiet, not scary. | The Director alternates noise and silence; the attention economy keeps the eyes busy. |
| The creature can't hurt you, so nothing is at stake. | It can — but only in Night 3, only at the cap, and only after a survivable demonstration. Three independent gates (§18). |
| The premise is crowded. | True and verified (§2). Compete on the gaze economy and the timetable, never on the bus stop. |
| The cone boundary will feel arbitrary. | True risk. Made perceivable by design (§8, fairness rule 10), and A/B tested in week 4. |

---

## 5. Player experience and emotional targets

| Phase | Feeling | How it's created |
| --- | --- | --- |
| First minute | Calm, curious, lonely | Rain, warm lamp, readable shelter, no events |
| Night 1 | Unease — "was that something?" | Small sounds, a distant figure, a bus that doesn't stop, **the first survivable lamp death** |
| Night 2 | Suspicion, testing | Rules become readable, then are tested one at a time |
| Night 3 | Dread, temptation | Stronger lures, the rain stops, the figure at the edge of the light |
| Final bus | Doubt even when things are right | A clean ending that is the strangest one |

**Emotion hierarchy:** dread of being watched while helpless, with isolation underneath. Avoid cheap startle as the main tool. Tension is the pressure felt *after* the problem is understood and *before* it is solved — so the rules must be established early and the bus must stay uncertain.

---

## 6. Design pillars and fairness rules

### Pillars

1. **Waiting is the gameplay.**
2. **Attention is the currency.** Stare and the light dies; look away and the Thing moves.
3. **One place, small radius.** Never more than ~14 m from the shelter.
4. **Rules you can read and still fail.** Failing is always a choice, never a surprise.
5. **Sound first.**
6. **The clean ending is the strangest.** Obeying works, and that is unsettling.
7. **The rules are bureaucratic.** A timetable, a route number, a destination board and an END OF SERVICE sign decide whether you get home.

### Fairness rules (testable assertions — enforced in code where noted)

1. **No rule can end a run until the game has shown it or demonstrated it non-lethally.** Night 1 cannot kill the player **under any input**. Gaze death requires `NightDef.gaze_lethal` (Night 3 only) **and** `GazeMonitor.armed` (set only by surviving a blackout) **and** the figure at the cap. *(§18, §22)*
2. **Every rule break is a deliberate act:** crossing the sign line (Night 2+), a 1 s hold to speak, a 1 s hold to board.
3. **Every dangerous moment has a tell at least 2 s ahead:** the lamp dims, its hum drops in pitch, the watch changes, a heartbeat joins.
4. **The clock is exact.** It reads 11:47 at the moment the bus arrives, every night.
5. **A restart takes under 5 seconds.**
6. **The player never dies to something they could not see.** Sight is checked against real blockers only, with a ray fan, never beyond the fog end (32 m). *(§18)*
7. **Scripted blackouts never kill.** Only a blackout the player caused by staring can.
8. **"Watched" and "stared at" are the same test.** There is no angle at which the figure is frozen for free. *(§18)*
9. **No ending loops forever.** *(§10)*
10. **The gaze cone's boundary must be perceivable.** The outer 59% of horizontal view counts as unwatched; a player who cannot tell where that boundary is will read the result as cheating. Silhouette albedo highlight + audio tell by default, optional cone vignette. **Not rim lighting** — rim is invisible on an unshaded material. *(§8, §17)*

---

## 7. Game structure, core loop and the attention economy

### Structure

- **Three nights**, each a wait ending at 11:47 PM.
- Each night is **5–7 minutes of real time** before the bus, plus a short decision window after arrival.
- A **rule break or a lost stare ends the night immediately** with an ending, and the night restarts. Failure is content.
- **Night 1 and Night 2 have no fail states from the gaze.** Only the sign line can end a run, and only from Night 2.

### Core loop

1. **Wait** in the lamp's light. Look around, read the timetable, check the watch.
2. **The Director plays a beat** on a designed schedule with deliberate quiet gaps.
3. **Spend attention.** Decide where to look and for how long.
4. **Test.** Each night ends with a bus. Decide whether to commit.
5. **Consequence.** A rule break or lost stare gives an ending; a clean night moves on.

### The attention economy

The Fog Figure advances only when outside the gaze cone, and keeping it inside the cone has a cost. Both use **the same cone** (fairness rule 8).

| Player action | Cost |
| --- | --- |
| **Look away** (anywhere, including down at the watch) | The figure may step toward the light, up to that night's cap. |
| **Raise the watch** (hold Q) | You look down — counts as looking away. |
| **Keep the figure in the gaze cone** | After a 2 s grace, the lamp loses **10%/s** — **6%/s** once the figure is at the cap. |
| **Look away briefly** | The lamp recovers **20%/s** (full recovery in 2.5 s from 0.5). |
| **Lamp reaches 0 from staring** | The figure steps closer in the dark; the lamp relights at 50%. **The first time this ever happens it is survivable.** If *and only if* it is Night 3, the mechanic has been demonstrated, and the figure is at the cap — you lose (Ending 1, gaze variant). |

**Intended play:** a rhythm of short glances. Never a long stare, never a long look away.

**Safety rails:**

- Scripted blackouts never kill. They advance the figure one station, within the cap.
- **Figure cap by night** (`figure_cap_index`, 0-based — see the mapping table in §14): Night 1 → index 1 = station 2 of 5 (19 m). Night 2 → index 2 = station 3 (13 m). Night 3 → index 3 = station 4 (9 m). Index 4 = station 5 (5 m, *inside* the light) is reachable only by the breach rule below, and `configure()` clamps the cap so it can never be selected.
- **`gaze_lethal` is true for Night 3 only.** In Nights 1–2 a player can stare forever; the lamp cycles 0.5 → 0 → 0.5 and the figure parks at the cap. This is safe by construction, not by tuning.
- **Corrected Night 3 death window.** The figure appears at 0:40. Continuous staring reaches the cap at ~26 s (**≈1:06**) and kills at ~36 s (**≈1:16**). That is acceptable *only* because reaching the cap by staring requires three prior survivable blackouts, each of which is the demonstration fairness rule 1 demands. A player who never stared cannot die before the authored 5:30 beat plus one survivable blackout (~10 s of clearly dying lamp at the cap rate).
- **The breach (build-time test, debug-gated, F8):** at the cap, cumulative unwatched time above `inner_unseen_required` (start 6 s) moves the figure to station 5, *inside* the lamp pool. This breaks the unwritten rule at the worst possible moment and removes the one-sided endgame.
  - **Worth testing alongside it:** once breached, let sustained watching push it *back* to station 4. That makes the last minute a genuine dilemma — the only way to get it out of the light is to stare, and staring is killing the lamp. Do not commit on paper; week-10 question.
- **Tells:** the lamp visibly dims, its hum falls in pitch, and a faint heartbeat joins at 30% light — or **50%** when the figure is at the cap.

### Session flow

```
Menu → Night 1 → Night 2 → Night 3 → Final bus
   (gaze cannot kill)  │         │
                 fail → ending  fail → ending
                    └──── restart this night ────┘
                       (Ending 4 is terminal, not a loop)
```

---

## 8. Mechanics, controls and verbs

| Verb | Control | Notes |
| --- | --- | --- |
| Look | Mouse | FOV ~75° vertical, adjustable. The gaze cone scales with it (§18). |
| Walk | WASD | Slow, no sprint. **Start 1.8 m/s**, tune 1.5–2.2. |
| Interact | E (tap) | Timetable lean-in, bench, payphone, bin. |
| Hold actions | E (hold, ring) | Speak to the stranger (1 s), board the bus (1 s). |
| Watch | Q (hold) | Raises the forearm, looks down, slows movement. Counts as looking away. |
| Pause | Esc | Allowed. Freezes the whole night including the clock (§18). |

**Stretch (only if ahead of schedule):** hold breath, watch backlight, gamepad support.

### Making the cone perceivable (fairness rule 10)

`CONE_FRAC = 0.41` means the gaze cone covers 41% of horizontal FOV, so the **outer 59% of the horizontal view counts as unwatched.** At 75° vertical on 16:9 that is ~108° of view and a ~44° cone. Players will assume anything on screen is watched. Three layers, cheapest first:

1. **The silhouette lightens slightly while it is inside the cone** — a flat `albedo_color` swap on the figure's own `StandardMaterial3D`, driven by the same boolean the gaze monitor uses. Reads as "your eyes are on it," costs nothing, works at every FOV. **Default on.**
   > **Do not use rim lighting for this.** `BaseMaterial3D.rim` is invisible when `shading_mode = SHADING_MODE_UNSHADED` (an explicit note in the Godot docs), and an unshaded black silhouette is exactly what a PS1 fog figure should be. `rim_tint` is also the wrong property — it blends light against albedo, it is not a strength control. A `set_shader_parameter()` call on `StandardMaterial3D` is a hard runtime error; that method exists only on `ShaderMaterial`. If you want a true rim, the figure must be `SHADING_MODE_PER_PIXEL` with a near-black albedo, or use a `next_pass` fresnel overlay — both cost more than the albedo swap and neither is needed.
2. **Audio tell:** the lamp hum gains a faint upper partial while the figure is held in the cone. Fits "sound first," and works when your eyes are down at the watch. **Default on.**
3. **Cone-matched screen vignette** — a subtle darkening outside the cone boundary, behind an accessibility toggle. **Default off**, for players who still can't read the boundary.

**This trades away some ambiguity.** v1.0's note that "the player should never be sure how fast it moves" is deliberately overruled: dread here comes from the lamp draining, not from uncertainty about the cone, and an invisible core rule reads as cheating. A/B test layers 1+2 against 1+2+3 in week 4 and pick on the metric in §22.

### Movement and boundaries

- `CharacterBody3D`, subtle head bob, footsteps that change between concrete (shelter) and gravel (verge).
- **Soft limit:** gentle push-back from 12 m. **Hard limit:** invisible wall at 14 m from the shelter centre.
- **The sign line** is a full-width wall at the east edge; it spans the whole corridor so it can't be walked around.

### Interaction system

- `RayCast3D` on the camera, 2.5 m default, with **per-object reach** (the bus door uses 1.5 m so you must walk to it).
- **Collision mask: layer 3 (interactables) only.** Glass is on layer 1 and must not block interaction.
- Interactables share an `Interactable` component: `prompt`, `hold_seconds`, `max_reach`, `distinct_style`, `enabled`, signal `triggered`.
- Hold actions show a filling ring. Releasing early cancels. A tap does nothing. An accessibility option swaps hold-to-confirm for press-to-confirm (open question 8).
- **Reading** the timetable or poster is a diegetic **lean-in**: FOV narrows, movement locks while E is held, the world keeps running so you can still hear it. **Any event of intensity ≥ 2, and every bus beat, cancels the lean-in automatically.**

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

### Look-at detection

- Cone check + distance check + **3-ray fan** against `sight_blockers` only.
- Must run in `_physics_process` — direct space state access is only guaranteed safe there.
- `VisibleOnScreenNotifier3D` is not used for gameplay decisions; its approximation ignores walls and it reports a frame late after entering the tree.
- Code in §18.

---

## 9. The Rules system

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

Use `Label3D` (or a swap of pre-rendered text layers) rather than baking text into one texture, so localisation stays possible. Note that the header and the closing line are both candidate titles (§2) — keep them prominent in the layout.

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
3. **The voice payoff carries the rest.** Ending 3's answer is the *same processed voice* as the bin radio and the payphone (§16). It must land before E7 in Night 2 — the beat sheet already orders it 1:20 → 3:00.

**This chain is load-bearing, and it depends on recorded voice.** Rule 2's weight comes from three links in order: **E6** introduces the voice (bin radio, Night 2 at 1:20) → **E7** tempts you with the stranger (3:00) → **Ending 3** pays it off (the stranger answers in that voice). Break any link and Rule 2 collapses back into the generic don't-talk-to-strangers beat that §2 warns about.

So: **E6 plus roughly three short voice lines are now required for Rule 2, not merely for Ending 3.** That is why they are on the never-cut list and why E9 — not E6 — is the cuttable payphone (§20).

**If you do not record voice** (open question 2), use this fallback rather than dropping the chain: make it one *non-verbal* processed voice — a breath, a hummed two-note figure, a mouthed word — used identically in all three places. It is still recognisably the same entity, it costs one short session instead of twelve lines, and Ending 3 keeps its payoff. What you must **not** do is use text captions in one place and audio in another; the identity of the voice *is* the point.

### Rule visibility

| Night | Timetable | Sign |
| --- | --- | --- |
| 1 | Header and time readable; rules smudged | Legible, **non-lethal** |
| 2 | All three rules readable (Event 5) | Legible, lethal |
| 3 | Same text; stronger lures | Legible, lethal |

### The unwritten rule

*Please wait inside the light.* The Thing never enters the light — **unless the light is gone, or unless the breach rule is enabled and you stopped paying attention.** Boarding the bus is the only legitimate reason to leave it. Note that light-as-safety has prior art (§2); the novel part is that the light is *spent by looking*.

---

## 10. Story, lore and endings

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

Every voice in the game is the **same processed voice**: bin radio, payphone, stranger. It is one entity. Record ~12 short lines yourself and process them (pitch, low-pass, light distortion). This gives Ending 3 its payoff and makes E6 load-bearing even if E9 is cut.

### Endings (five)

| # | ID | How | What happens |
| --- | --- | --- | --- |
| 1 | `out_of_the_light` | Cross the sign line (Night 2+), **or** let the lamp die by staring while the figure is at the cap **in Night 3** | Two vignettes under one card — below |
| 2 | `wrong_bus` | Board the numberless bus (Night 2) | A silent ride into fog; the stop's lamp goes out behind you |
| 3 | `spoke_first` | Hold to speak to the stranger | The stranger answers in the voice from the radio, repeating your own "Hello?" |
| 4 | `still_waiting` | Night 3: don't board the real bus within 60 s | **Terminal.** The bus leaves, the rain returns, the lamp goes out. End card: *The next bus is at 11:47 PM.* |
| 5 | `right_bus` | Break no rules; board the real bus | The final beat below |

**Ending 1 variants.** `trigger_ending(id, variant)` selects the vignette: `sign` (you walk into the fog, the lamp dies behind you) or `gaze` (the lamp dies with the figure at the edge of the light, and it is suddenly much closer). One menu slot, two experiences. Splitting into six slots is a ~20-minute upgrade — do it if week 11 has slack.

**Ending 4 is terminal.** It guarantees no run loops forever (fairness rule 9). It must not restart Night 3.

### Ending 5 — the final ten seconds

The numberless bus is **empty**. The real bus is **full**, and that is the point.

1. You hold E on the door and walk out of the lamp's light into the dark between it and the bus's light.
2. Inside, every seat but one holds a still silhouette in dim yellow light, all facing forward, each in a different coloured raincoat.
3. You sit. The destination board above the driver reads the name of the stop you just left.
4. A notice inside reads **BOARDED 11:47 PM**, with a column of earlier passengers' times above yours.
5. Through the window the shelter shrinks. The poster flutters, the lamp goes out. End card: *Thank you for waiting.*

If the title is *Thank You for Waiting*, step 5 is the title paying off. Protect it.

---

## 11. Night-by-night beat sheets

Times are real seconds from the start of the night. Starting values to tune in playtests.

### The clock (single source of truth)

`NightDef.real_seconds` is the moment the bus **arrives**. The clock reaches 11:47 exactly then and freezes. Tempo is ~25 real seconds per in-game minute, so the start time is derived: `start_minute() = 47 − round(real_seconds / 25)`.

| Night | Bus arrives (real s) | Clock starts | In-game minutes waited | Decision window | `gaze_lethal` |
| --- | --- | --- | --- | --- | --- |
| 1 | 300 (5:00) | 11:35 | 12 | 30 s (bus passes, fade) | **false** |
| 2 | 380 (6:20) | 11:32 | 15 | 45 s | **false** |
| 3 | 405 (6:45) | 11:31 | 16 | 60 s | **true** |

Total night time 330 + 425 + 465 = 1220 s = **20.33 min** (5.50 + 7.08 + 7.75), plus cards, fades and the Ending 5 beat → **22–26 min**, inside target. `roundi` makes the true tempo 25.00 / 25.33 / 25.31 s per in-game minute; imperceptible, and constant tempo is still right because the watch is a telegraph device.

### Night 1 — "Wait" (~5.5 min, cannot kill)

| Time | Beat | Kind | Int |
| --- | --- | --- | --- |
| 0:00 | Fade in. Rain, lamp hum, shelter. Title card. | — | 0 |
| 0:00–0:40 | Quiet. Prompts for look, walk, E, Q. | — | 0 |
| 0:40 | **The Fog Figure appears at station 1.** | authored | 2 |
| 0:45 | Gravel footsteps (E3) or lamp flicker (E1) | fill | 1 |
| 1:30 | Distant engine, no bus (E2) | authored | 1 |
| 2:30 | **The stare lesson (authored — see below).** | authored | 2 |
| 3:30 | Lamp flicker or footsteps. Figure steps if unwatched (cap: station 2). | fill | 1–2 |
| 4:15 | Calm: rain only | — | 0 |
| 4:45 | Engine rises (S1 approach) | authored | 2 |
| 5:00 | **Arrival.** A lit bus with no number passes without stopping. Scripted blackout 4 s; the figure steps once in the dark. Clock reads 11:47. | **authored + punctual** | 3 |
| 5:30 | Fade to black, "Night 2" | — | — |

**The stare lesson (do not leave this emergent).** At 2:30 the figure is visible and stationary. If the player stares, the silhouette highlight holds, the lamp dims, the hum drops in pitch, and at ~30% a heartbeat joins. If they keep staring, the lamp dies at ~12 s: the figure takes one step closer in the dark and the lamp relights at 50%. **This cannot kill** — `gaze_lethal` is false and `armed` was false. This is the demonstration fairness rule 1 requires, and it is the single most important thing to test in week 4.

Rule state: unreadable. Only the sign line can end a run — and in Night 1 it doesn't.

### Night 2 — "Test" (~7 min, cannot kill by gaze)

| Time | Beat | Kind | Int |
| --- | --- | --- | --- |
| 0:00 | Fade in. Poster partly readable. | — | 0 |
| 0:30 | Timetable text changes (E5). All three rules readable. | authored | 1 |
| 1:20 | Bin radio (E6). **The voice is introduced.** | authored | 1–2 |
| 2:10 | Figure step (E4, cap: station 3) | authored | 2 |
| 3:00 | **The Bench Stranger** (E7). Rule 2 test, 45–60 s. **If you never speak, it leaves and you learn nothing.** | authored | 3 |
| 4:15 | Calm | — | 0 |
| 4:40 | Glass reflection (E8) or footsteps or flicker | fill | 1–2 |
| 5:30 | **Signpost lure** (E10). Rule 3 test, ~30 s. | authored | 3 |
| 6:05 | Engine approaches (S2 approach) | authored | 2 |
| 6:20 | **Arrival.** The numberless bus stops; doors open on a lit, empty interior. Rule 1 test, 45 s. Clock reads 11:47. | **authored + punctual** | 3 |
| 7:05 | The bus leaves. Fade, "Night 3". | — | — |

Authoring note: rule tests are ≥ 30 s apart (3:00 / 5:30 / 6:20) so they never wait on `max_delay`.

### Night 3 — "Decide" (~7.75 min)

| Time | Beat | Kind | Int |
| --- | --- | --- | --- |
| 0:00 | Fade in. The poster silhouette now wears a yellow raincoat. | — | 0 |
| 0:40 | **The figure appears.** Lamp blackout (E1 long, scripted, safe); the figure advances one station in the dark. | authored | 2 |
| 1:30 | Payphone rings (E9) | authored | 2 |
| 2:30 | The stranger returns, seated closer, head turned toward you (E7) | authored | 3 |
| 3:40 | Calm | — | 0 |
| 4:10 | Glass reflection, wrong version (E8), or footsteps or flicker | fill | 1–2 |
| 4:30 | Signpost lure, stronger (E10) | authored | 3 |
| 5:30 | **The figure reaches its cap**, just outside the light (E4). From here a gaze blackout can end the run *if the mechanic has been demonstrated*. | authored | 2 |
| 6:00 | **The silence beat.** Rain and wind fade over 6 s, then near-silence. | authored | 3 |
| 6:30 | Engine returns (S3 approach) | authored | 2 |
| 6:45 | **Arrival.** The real bus, "47" visible, readable destination board. Clock reads 11:47. 60 s to board. | **authored + punctual** | 3 |
| 7:45 | Board = Ending 5. Don't board = **Ending 4 (terminal)**. | — | — |

**The boarding walk:** the door is at x = 8.5, outside the 6.5 m light, with a 1.5 m reach and a 1 s hold. The player must walk out of the light to go home. When they step out during the final window the figure takes one audible step — a warning, never a kill.

---

## 12. Event catalogue

**Intensity:** 1 = ambient wrongness, 2 = direct presence, 3 = rule test or climax. **Cost:** S ≤ 1 day, M = a few days, L ≈ 1 week.

| ID | Event | Nights | Int | What happens | Implementation | Cost |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | **Lamp flicker** | 1–3 | 1 | Stutters for 3–6 cycles (~1.4–4.8 s) with a buzz, **clamped to ≤ 2.22 Hz nominal (2.20 Hz measured)**. Night 3's long version is a separate scripted blackout (≥ 3 s). | Drives `LampController.set_flicker()`. Scripted versions set `scripted_blackout` so they can never kill. "Reduce flicker" swaps in one slow dim. | S |
| E2 | **Distant engine** | 1–2 | 1 | Engine approaches and fades; no bus. | `AudioStreamPlayer3D` along the road path. | S |
| E3 | **Gravel footsteps** | 1–3 | 1 | Steps circle behind the shelter, stop when you turn. | 3D audio on a short path + look-direction check. | S |
| E4 | **The Fog Figure** | 1–3 | 2 | Advances only when outside the gaze cone; staring drains the lamp. | Persistent node, **5 stations** (26, 19, 13, 9, 5 m), per-night cap, breach rule behind F8. **Albedo highlight driven by `in_gaze_cone`** (not rim — invisible when unshaded). §7, §8, §18. | M |
| E5 | **Timetable change** | 2+ | 1 | Rules become legible. Paper creak. | Swap `Label3D` text. | S |
| E6 | **Bin radio** | 2+ | 1–2 | Faint static; up close a muffled voice says two or three words. | Positional audio + proximity trigger. **Establishes the one voice before the stranger. Never cut.** | S |
| E7 | **The Bench Stranger** | 2–3 | 3 | A seated silhouette appears while you look away. Prompt: "Say something…" (hold E). **Leaves after 45–60 s if you never speak.** | Look-away spawn, timed lifetime. 1 s hold → Ending 3. Night 3: closer, head turned. Prompt uses `distinct_style`. | M |
| E8 | **Glass reflection** | 2+ | 2 | In the shelter glass a figure mimics you with a delay. Night 3: it stays still when you move. | Ring buffer of player transforms on a ghost mesh. **Cuttable** — nothing depends on it. | M |
| E9 | **Payphone** | 3 | 2 | Rings six times. Answering: breathing, then the voice reading the time. | Interactable + two clips. No rule consequence. **Cuttable**, but it carries the "loop is tightening" lore line. | S |
| E10 | **Signpost lure** | 2–3 | 3 | Past the sign the fog thins: a warm light, an idling engine. | Lure scene beyond the sign line. Crossing → Ending 1 (sign variant). | M |
| S1 | **Passing bus** | 1 | 3 | A lit bus with no number passes without stopping. Lamp dies 4 s. | Bus on `Path3D`/`PathFollow3D`. Scripted blackout, safe. | M |
| S2 | **Numberless bus** | 2 | 3 | Stops, doors open, blank destination board, **lit and empty** interior. 45 s. | Reuse the bus. Hold E on door → Ending 2. | S |
| S3 | **Silence and the real bus** | 3 | 3 | Weather fades, near-silence, then the real bus with "47". | Fade the `Weather` bus, then restore. Reuse the bus with a readable board. | S–M |
| S4 | **Bus interior** | 3 | — | Dim interior, seated silhouettes, destination board, the notice. | Box seats + the silhouette mesh instanced ~10×. **Protect this: it is the payoff.** | M |

**Total:** 10 deck events, 4 scripted beats, 5 endings. S2's empty interior and S4's full interior are deliberate opposites.

---

## 13. The Director

A scheduler, not an AI. Reads a `NightDef` and plays from it.

### Two kinds of beat

| Kind | Behaviour |
| --- | --- |
| **Authored** | Always plays. If a pacing rule blocks it at its start time it **waits** (up to `max_delay`) rather than being dropped. All rule tests are authored. |
| **Fill** | Optional ambience; picks from a weighted pool with cooldowns. If blocked, skipped quietly. |

**There is no tension budget.** v1.0's budget silently removed a rule test; that failure mode is designed out, not tuned around.

### Pacing rules (starting values)

| Rule | Value |
| --- | --- |
| **Never two instances of the same event id** | **Hard rule** — protects E1's flicker clamp from concurrency |
| Never two intensity-3 events live | **Hard rule, no exceptions** |
| Never two intensity-2+ events live | Soft; an authored beat may override after `max_delay` |
| Calm window after an intensity-2+ event **ends** | 15 s, no new intensity-2+ |
| Never the same fill event twice in a row | Yes |
| Fill events obey `cooldown` | Yes, per event |
| Authored `max_delay` | 20 s default, 40 s for rule tests |
| Gaps measured from event **end**, not start | Yes |
| **`punctual` beats bypass every pacing rule** | The three bus arrivals only — see below |

**Punctual beats.** The three bus arrivals are structural, not scares: they must fire at exactly `real_seconds`, because that is the instant the clock reads 11:47 and the arrival tween must land on `clock.arrived`. Without `punctual`, the preceding "engine approaches" beat (intensity 2) ends on that same instant and its 15 s calm window delays the arrival by **+15.02 s — measured, in all three nights**. `max_delay` does not rescue it, because the calm window always expires first. Mark all three arrival beats `punctual = true`; measured delay then drops to +0.02 s (one physics frame).

Authoring tip: keep ≥ 30 s between rule tests so they never wait.

### Debug tools (build early; they save days)

| Key | Action |
| --- | --- |
| F1 | Pending and live beats, lamp level, figure station and cap, `armed`, `lethal_tonight` |
| F2 | Force-play a chosen event |
| F3 | Jump to Night 1 / 2 / 3 |
| F4 | Draw the gaze cone, sight rays, stations, sign line, sight blockers |
| F5 | Skip to the final bus |
| F6 | Noclip |
| F7 | Set the figure's station |
| F8 | Toggle the **breach rule** (fifth station) |
| F9 | Force `armed = true` **and** `lethal_tonight = true` (test the gaze death without earning it) |
| F10 | Toggle the cone vignette / silhouette-highlight layers (§8) |

---

## 14. World and level design

### Layout (metres; +x is east; the lamp is the origin)

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
| Lamp | Shelter's west corner. `OmniLight3D` range **6.5 m**. The only safe place. |
| Shelter | South verge, ~3 m from the road edge. Open front, glass side panel, bench, timetable board, poster on the pole. |
| Payphone | x = −4, inside the light. |
| Bin | x = 3.5, inside the light. |
| **Bus door** | x = 8.5 — **just outside the light**, so boarding means stepping out of it. Reach 1.5 m, hold 1 s. |
| **Signpost / sign line** | x = 10.5, legible "END OF SERVICE". The line is a thin wall (~1 m thick, 24 m wide, 6 m tall) across the corridor, both ends buried inside the tether wall. |
| Fog Figure stations | x = −26, −19, −13, −9, and **−5 (breach, inside the light)** along the verge/road diagonal, west side. See the indexing table below. |
| Lure | East of the sign line, where the bus comes from. |
| Tether | Soft push-back from 12 m; hard wall at 14 m from the shelter centre. |
| Treeline | Billboard cards 30–45 m out, mostly lost in fog. |

**Station indexing** — spelled out because 0-based code and 1-based prose are easy to cross, and every edit otherwise re-derives it:

| `figure_cap_index` | Prose name | x (m) | From lamp | Inside light? | Cap in |
| --- | --- | --- | --- | --- | --- |
| 0 | station 1 | −26 | 26 m | no | never |
| 1 | station 2 | −19 | 19 m | no | **Night 1** |
| 2 | station 3 | −13 | 13 m | no | **Night 2** |
| 3 | station 4 | −9 | 9 m | no | **Night 3** |
| 4 | station 5 (breach) | −5 | 5 m | **yes** | never — `configure()` clamps to `size() - 2` |

`FogFigure.station_index` starts at **−1** (not yet appeared). `at_cap()` is `station_index >= cap_index`, so a Night 1 cap index of 1 stops the figure at 19 m — which the prose calls "station 2 of 5". The cap rate in `GazeMonitor` keys off `at_cap()`, **not** off "has moved at all"; that distinction is what §18's phase trace pins down.

**Geometry notes (all verified):**

- The figure lives west, the bus comes from east: the player walks *away* from the Thing to board.
- Station 4 (9 m) is just outside the light's edge (6.5 m). Station 5 (5 m) is inside it.
- The bus door sits 2 m before the sign line, so boarding never conflicts with Rule 3.
- The sign wall spans ±12 m at x = 10.5; the 14 m tether from x ≈ 1.5 puts its boundary at z ≈ ±10.7 there, so the wall's ends are genuinely buried.
- All stations are within the 32 m fog end; station 1 (26 m) is ~27.5 m from the shelter centre and must be *barely* readable. If it vanishes, move it to 24 m rather than thinning the fog.

### Physics layers

| Layer | Name | Contains |
| --- | --- | --- |
| 1 | world | Ground and movement collision, **including glass** |
| 2 | player | The player |
| 3 | interactables | Objects the interaction ray can hit |
| 4 | entities | Fog Figure, Stranger |
| 5 | triggers | Sign line, shelter reverb |
| 6 | **sight_blockers** | Only large opaque surfaces: shelter walls and roof, bench back. **Not glass. Not the lamp pole. Not thin props.** |

### Level design principles

- **Sightlines are the design:** one long empty road, one wall of fog.
- **One safe place.** Everything outside the lamp is where the Thing lives.
- **Hide the edges with fog,** not with walls the player notices.
- **Give the eyes something to do:** timetable, poster, bench, road, sign.

### Asset list (all low-poly)

| Asset | Count | Notes |
| --- | --- | --- |
| Shelter, bench, bin, payphone, lamp post, sign | 6 | Boxes and simple extrusions |
| Timetable, poster | 2 | `Label3D` or texture-swap quads |
| Road and verge tiles | 3–4 | Tile and reuse |
| Tree billboards | 2–3 | Reuse everywhere |
| Bus exterior | 1 | ~600–1000 triangles |
| Bus interior | 1 | Box seats, destination board, notice |
| Silhouette (stranger, figure, passengers) | 1 | One mesh; different poses, scales, materials. **Unshaded, near-black albedo; the figure's material needs two albedo colours for the gaze highlight (§8). No rim lighting — it is invisible when unshaded.** |
| Forearms and watch | 1 | Two low-poly forearms + an LCD texture |
| Rain particle texture | 1 | |
| Font | 1 | Pixel or typewriter |

---

## 15. Visual direction

### Look

Low-resolution PS1-style 3D: vertex snapping, affine texture warping, limited texture detail, dither, heavy depth fog. Pixelated imperfection makes shapes ambiguous, which helps horror.

### Palette

| Element | Direction |
| --- | --- |
| Night ambient | Very dark blue, ~`#0b1220` |
| Fog | Cold blue-grey, ~`#101820` |
| Lamp | Warm sodium orange-yellow |
| **Player's raincoat** | **Pale yellow** — reads in fog, suits the rain, gives the poster its payoff |
| Bus interior (real bus) | Dim, sickly yellow-green |
| Rain | Faint grey-blue streaks |

Cold dark surroundings plus one warm light make the lamp feel like the only safe place.

### Fog

- **Depth fog** (`Environment.fog_mode = Depth`) — verified present in Godot 4.7 source with `fog_depth_begin`, `fog_depth_end`, `fog_depth_curve`. Available since 4.3.
- **Volumetric fog** is Forward+ only, costs more and bands. Skip for v1.
- **Start:** 4 m → **32 m**, curve ~1.2, fog colour matching the background.
- **Godot's fog does not dither.** At a low render scale the gradients will band, and those gradients are your whole atmosphere. Budget a dither pass in the PSX work (week 7), not a surprise in week 10.
- Tune the figure's visibility by eye at station 1. `LookAtTracker.max_distance` is **32.0**, matching the fog end exactly, so the player is never "watching" something they cannot see.

### PS1 shaders

Don't write these from scratch first.

| Option | Notes |
| --- | --- |
| Godot PSX style demo | Free reference project: vertex snapping + affine textures for Godot 4. |
| PSX Visuals, GD4 port | Vertex snapping, affine mapping, distance fog, screen-space dither via global shader uniforms. Check licence. |
| Ultimate Retro Shader Collection | Depth-based fog and dithering; described as working on all backends. |
| Retro Shaders Pro | Paid. PS1, N64, CRT, VHS. Optional. |

Tips: add edge loops to limit texture warping, lean on vertex colours over detailed textures, reduce texture colour depth before import, consider white ambient + vertex colours to fake lighting. Typical PS1 resolutions: 256×240, 320×240, 512×240.

**Also:** kill TAA and MSAA — both fight vertex snapping and produce shimmer that reads as broken rather than retro. Project-wide `TEXTURE_FILTER_NEAREST`.

### Resolution

- **Option A (default):** stretch mode `viewport`, base size ~640×360, integer scale. UI pixelates too, so use a pixel font.
- **Option B (later):** low-res `SubViewport` for 3D, full-res UI. Crisper text, more plumbing.
- Alternatively `Viewport.scaling_3d_scale` gives a low-res framebuffer with no SubViewport wiring; set `scaling_3d_mode` off for nearest-neighbour upscale.
- **Check the title at this width.** A 21-character title in a pixel font must fit the main menu and the ending card at 640×360 (§2).

### Lighting

One `OmniLight3D` (the lamp, range 6.5 m), low ambient, no baked lighting, shadows off or simple. The bus has its own interior `OmniLight3D` — the real bus's light is what the player walks toward after leaving the lamp.

### Rain

One `GPUParticles3D`, `top_level = true`, following the player, not parented to the camera. Modest particle count; test on a low-end machine early. Rain streaks alias badly at 640×360 — if they do, fall back to streaked quads or a screen-space overlay plus audio.

---

## 16. Audio direction

Sound should do most of the scaring. One source credits Frictional Games' design notes with ~70% of fear coming from sound — a rule of thumb, not a measurement, but the direction is right.

### Principles

1. **Start from silence, not music.** No score except possibly a faint drone in the endings.
2. **Layer, don't loop one track.** Rain, wind, lamp hum, road tone, spot sounds and foley on separate buses.
3. **Alternate noise and silence.** Sudden quiet after a spike beats constant noise.
4. **Never go truly dead.** In the silence beat, fade weather but keep faint room tone plus the player's footsteps and cloth.
5. **Positional audio carries the Fog Figure.**
6. **The lamp's hum is a gauge.** Its pitch falls as the lamp dims — the audio tell for the attention economy.
7. **The hum also reports the cone.** A faint upper partial joins while the figure is held inside the gaze cone (§8). This is the audio half of fairness rule 10 and it works with your eyes down at the watch.

### Bus layout

| Bus | Contents | Effects |
| --- | --- | --- |
| Master | Everything | Limiter |
| **Weather** | Parent of Rain and Wind. **Only the silence beat touches it.** | none |
| Rain | Rain loop | Low-pass (muffled moments) |
| Wind | Wind loop | Optional slight low-pass |
| Ambience | Lamp hum, road room tone, and the Weather bus | Compressor sidechained from SFX (ducks the bed under events) |
| SFX | Events, bus, footsteps | Light reverb |
| Voice | The one processed voice | Light distortion + low-pass |
| ShelterVerb | Sounds under the roof | Reverb, via an `Area3D` |
| UI | Menu clicks | none |

**Why a Weather bus:** the options sliders control Master, Ambience, SFX and Voice. The silence beat fades only Weather, so player settings are never overwritten and restoring is simply returning Weather to 0 dB.

Note that "Ambience" now parents the weather. Players who turn ambience down lose the rain — acceptable since there's no music, but label the slider "Ambience & weather" so it isn't mistaken for a music channel.

**Reverb zone:** a small `Area3D` around the shelter with reverb bus `ShelterVerb`. Outdoors stays dry.

### The one voice (~12 short lines)

Record and process them yourself.

- **Radio (E6):** fragments — "…still waiting?", "…nearly time."
- **Payphone (E9):** breathing, then "It's already 11:47."
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

### Volume control

Godot audio buses are in decibels. Use `AudioServer.set_bus_volume_db()` with a dB value, never 0–1.

---

## 17. UI, UX and accessibility

### In-game UI (deliberately minimal)

| Element | Description |
| --- | --- |
| Crosshair | A single tiny dot |
| Interaction prompt | Small text under the dot, e.g. "Read timetable" |
| Hold ring | Fills during hold actions (speak, board). Driven by `PlayerInteraction.hold_progress_changed`. |
| Interaction prompt source | `PlayerInteraction.prompt_changed(text, distinct)` — `distinct` is true for the stranger |
| Lean-in | `PlayerInteraction.lean_changed(active)` — the camera narrows FOV, the player controller locks movement |
| Watch | **Diegetic**: forearm raised on Q, LCD shows the time. No overlay. |
| Timetable / poster | Diegetic lean-in (hold E), cancelled automatically by any big event |
| Title cards | "Night 1/2/3" for 3 s |
| Ending card | One or two lines |

**The gaze cone is communicated diegetically** (the silhouette lightening + the hum partial), not with HUD. The cone vignette is an accessibility option, off by default (§8).

### Menus

- **Main:** Start, Endings (five slots that fill in), Options, Quit.
- **Pause:** Resume, Options, Restart Night, Quit to Menu.
- **Content note on first launch:** flashing light, dark imagery, loud sudden audio.

### Options

- Master, SFX, and ambience & weather volume
- Mouse sensitivity, invert Y, field of view *(the gaze cone scales with FOV — §18)*
- Head bob on/off
- **Reduce flicker** (one slow dim instead of fast stutter)
- **Show gaze boundary** (cone-matched screen vignette) — fairness rule 10
- **Captions** for audio-only events — "[distant engine]", "[footsteps behind you, left]"
- PSX intensity (dither and vertex snapping on/off)
- Fullscreen and resolution
- **Press instead of hold** for confirm actions (open question 8)

### Accessibility checklist

- **No more than three flashes per second — enforced in code, not by a store-page warning.** `e01_lamp_flicker.gd` clamps its cycle to 0.45–0.80 s (measured peak 2.20 Hz against a 3.00 Hz limit); scripted blackouts are ≥ 3 s. A store-page warning does not cover a default setting, so the default itself must respect the limit. Plus a **reduce-flicker** option that replaces the stutter with one slow dim.
- Captions for every important sound cue, **including direction**. The figure advances when unwatched and footsteps tell you where, so directional captions are load-bearing.
- Optional audio cue when the figure moves, for players who can't run the look-away loop.
- **The gaze-cone boundary is perceivable without vision** — the hum partial is the audio channel for it.
- All text readable at the base resolution.
- Rebindable keys. Pausing allowed. No timed button-mashing anywhere.

---

## 18. Technical architecture

### Folder structure

```
res://
├─ addons/               # PSX shader pack
├─ core/                 # autoloads and shared scripts
│   ├─ game.gd           # state machine, endings
│   ├─ save.gd           # ConfigFile save
│   ├─ audio_hub.gd      # Weather bus helpers
│   ├─ director.gd
│   ├─ look_at_tracker.gd
│   └─ event_context.gd
├─ player/               # player, interaction, forearms, watch
├─ world/                # bus_stop, road, bus, lamp, fog_figure, sign_line, gaze_monitor
├─ events/               # event scenes (e01_lamp_flicker.tscn …)
├─ data/                 # HorrorEvent, BeatDef, NightDef resources (.tres)
├─ ui/                   # hud, menus, hold ring
├─ audio/                # sfx, ambience, voice
├─ tests/                # the automated checks from §22
└─ art/                  # models, textures, shaders
```

### Autoloads

| Autoload | Responsibility |
| --- | --- |
| `Game` | State, current night, endings seen, triggers endings |
| `Save` | Reads/writes endings seen and settings |
| `AudioHub` | Weather bus fade and restore |

**Autoload order does not matter for the code as written**, because neither autoload touches the other during `_ready()` — `Game.trigger_ending()` calls `Save.write()` at runtime, when both exist. (v1.3/v1.4 claimed the opposite; the reasoning was wrong.)

Order *does* matter if you later move `Save.read()` into `Save._ready()`, because `read()` writes to `Game.endings_seen`. Autoloads enter the tree in the order listed in Project Settings, so an autoload's `_ready()` can only reference ones listed **above** it — which would require **`Game` above `Save`**, the reverse of what v1.4 said. Simplest way to stay order-independent: call `Save.read()` explicitly from `Main._ready()` and keep both autoloads free of cross-references at startup.

### Main scene tree

```
Main (Node3D)
├─ WorldEnvironment        # depth fog 4–32 m, dark ambient
├─ BusStop (instance)
│   ├─ Lamp (LampController)
│   ├─ Interactables
│   ├─ SignLine (Area3D wall, trigger layer)
│   └─ ShelterReverb (Area3D)
├─ Road (instance)
├─ Player (instance)       # camera, InteractRay (mask layer 3), PlayerInteraction, forearms, watch
├─ FogFigure
├─ LookAtTracker
├─ GazeMonitor
├─ Director
├─ NightClock
├─ Rain (GPUParticles3D)
└─ UI (CanvasLayer)
PauseMenu (CanvasLayer, process_mode = When Paused)
```

> **Syntax note — checked against the parser, do not "fix" this.** The one-line form `class_name Foo extends Bar` is **valid GDScript in every Godot 4.x release.** `GDScriptParser::parse_class_name()` explicitly handles a trailing `EXTENDS` token, with the source comment *"Allow extends on the same line."* Verified in 4.0, 4.1, 4.2, 4.3, 4.5 and 4.7 stable. The two-line form also works and is the more common tutorial style; use whichever you prefer, but the one-line form is not a parse error and will not fail on paste.

### Data model

```gdscript
# data/horror_event.gd
class_name HorrorEvent extends Resource

@export var id: StringName
@export var scene: PackedScene
@export_range(1, 3) var intensity := 1
@export var min_night := 1
@export var max_night := 3
@export var weight := 1.0
@export var cooldown := 60.0      # read by the Director for fill picks
```

```gdscript
# data/beat_def.gd
class_name BeatDef extends Resource

enum Kind { AUTHORED, FILL }

@export var time_sec := 0.0
@export var kind := Kind.AUTHORED
@export var event: HorrorEvent            # AUTHORED
@export var pool: Array[HorrorEvent]      # FILL
@export var max_delay := 20.0
@export var punctual := false             # structural beat: fires at time_sec, ignores pacing rules
```

```gdscript
# data/night_def.gd
class_name NightDef extends Resource

@export var index := 1
@export var real_seconds := 300.0          # the moment the bus ARRIVES
@export var post_arrival_seconds := 30.0   # decision window after arrival
@export var figure_cap_index := 1          # highest STATION INDEX allowed tonight (0-based; see §14)
@export var gaze_lethal := false           # TRUE FOR NIGHT 3 ONLY — see GazeMonitor
@export var sign_lethal := false
@export var breach_enabled := false        # fifth station, debug-gated (F8)
@export var beats: Array[BeatDef]

const SECONDS_PER_MINUTE := 25.0
const ARRIVAL_MINUTE := 47                 # 11:47 PM

func start_minute() -> int:
	return ARRIVAL_MINUTE - roundi(real_seconds / SECONDS_PER_MINUTE)
```

Per-night values: `real_seconds` 300 / 380 / 405, `post_arrival_seconds` 30 / 45 / 60, `figure_cap_index` 1 / 2 / 3, `gaze_lethal` **false / false / true**, `sign_lethal` **false / true / true**.

```gdscript
# core/event_context.gd — typed, so a missing reference fails loudly
class_name EventContext extends RefCounted

var lamp: LampController
var player: Node3D
var figure: FogFigure
var clock: NightClock
var tracker: LookAtTracker     # events need the cone (e.g. look-away spawns)
var bus: BusRig                # arrivals, doors, destination board
var hud: Node                  # captions and cards
var world: Node3D              # marks, props, poster
```

### Game state and endings

```gdscript
# core/game.gd (autoload)
extends Node

enum State { MENU, NIGHT, ENDING }

signal night_started(index: int)
signal ending_triggered(id: StringName, variant: StringName)

var state := State.MENU
var night_index := 1
var endings_seen: Array[StringName] = []

func begin_night(index: int) -> void:
	night_index = index
	state = State.NIGHT
	AudioHub.reset()
	night_started.emit(index)

func trigger_ending(id: StringName, variant: StringName = &"") -> void:
	if state != State.NIGHT:      # ignores duplicates and out-of-night calls
		return
	state = State.ENDING
	if id not in endings_seen:
		endings_seen.append(id)
		Save.write()
	ending_triggered.emit(id, variant)
```

Ending IDs: `out_of_the_light` (variants `sign`, `gaze`), `wrong_bus`, `spoke_first`, `still_waiting`, `right_bus`.

**`still_waiting` is terminal.** It does not restart Night 3 (fairness rule 9).

### Save

```gdscript
# core/save.gd (autoload)
extends Node

const PATH := "user://save.cfg"

func write() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "endings", Game.endings_seen)
	cfg.save(PATH)

func read() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		Game.endings_seen.assign(cfg.get_value("progress", "endings", []))
```

### Night clock

```gdscript
# world/night_clock.gd
class_name NightClock extends Node

signal minute_changed(minute: int)
signal arrived                      # exactly 11:47

var running := false
var _elapsed := 0.0
var _total := 300.0
var _start_minute := 35
var _last_minute := -1

func start(def: NightDef) -> void:
	assert(def.real_seconds > 0.0, "NightDef.real_seconds must be > 0")
	_total = def.real_seconds
	_start_minute = def.start_minute()
	_elapsed = 0.0
	_last_minute = -1
	running = true
	minute_changed.emit(current_minute())   # otherwise the HUD is blank for one frame

func current_minute() -> int:
	if _total <= 0.0:
		return NightDef.ARRIVAL_MINUTE
	var t := clampf(_elapsed / _total, 0.0, 1.0)
	return mini(int(lerpf(_start_minute, NightDef.ARRIVAL_MINUTE, t)), NightDef.ARRIVAL_MINUTE)

func _process(delta: float) -> void:
	if not running:
		return
	_elapsed += delta
	var m := current_minute()
	if m != _last_minute:
		_last_minute = m
		minute_changed.emit(m)
	if _elapsed >= _total:
		running = false
		arrived.emit()              # the clock now stays frozen at 11:47
```

### Look-at detection

Runs in `_physics_process` only — direct space state access is only guaranteed safe there.

```gdscript
# core/look_at_tracker.gd
class_name LookAtTracker extends Node

@export var camera: Camera3D
@export_flags_3d_physics var sight_mask := 32    # layer 6 only: sight_blockers
@export var max_distance := 32.0                  # matches the fog end exactly
@export_range(1, 5) var ray_count := 3            # fan, so a thin edge can't fake occlusion
@export var fan_spread := 0.35                    # metres, minimum half-extent
@export var fan_angle_deg := 3.0                  # fan also scales with distance

# ONE boundary for "watched" and "stared at" (fairness rule 8).
# Scales with horizontal FOV so the watched fraction of the screen is constant
# and the FOV slider cannot widen a free-safe band.
const CONE_FRAC := 0.41        # 44 deg full cone at 75 deg vertical FOV on 16:9

func horizontal_fov() -> float:
	# assumes camera.keep_aspect == KEEP_HEIGHT (Godot's default)
	var vp := camera.get_viewport().get_visible_rect().size
	var aspect := float(vp.x) / maxf(float(vp.y), 1.0)
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(camera.fov) * 0.5) * aspect))

func gaze_half_angle() -> float:
	return deg_to_rad(horizontal_fov() * CONE_FRAC * 0.5)

func in_gaze_cone(target: Vector3) -> bool:
	var fwd := -camera.global_transform.basis.z
	var to := (target - camera.global_position).normalized()
	if fwd.dot(to) < cos(gaze_half_angle()):
		return false
	return seen(target)

# Any one clear ray in the fan counts as seen.
func seen(target: Vector3) -> bool:
	var origin := camera.global_position
	if origin.distance_to(target) > max_distance:
		return false
	var spread := maxf(fan_spread, origin.distance_to(target) * tan(deg_to_rad(fan_angle_deg)))
	var up := camera.global_transform.basis.y
	var n := maxi(ray_count, 1)
	for i in n:
		var frac := 0.0 if n == 1 else (float(i) / float(n - 1)) - 0.5
		var p := target + up * (frac * 2.0 * spread)
		if not camera.is_position_in_frustum(p):
			continue
		var q := PhysicsRayQueryParameters3D.create(origin, p, sight_mask)
		if camera.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			return true
	return false
```

The mask is layer 6 only (value 32), so glass on layer 1 can never block the check. The figure and stranger stay on layer 4, which is not in the mask. **The lamp pole and thin props must not be on layer 6** — the fan is a second line of defence, not the first.

`VisibleOnScreenNotifier3D` is not used for gameplay: its approximation ignores walls and it reports a frame late after being added to the tree.

### The Fog Figure

```gdscript
# world/fog_figure.gd
class_name FogFigure extends Node3D

@export var stations: Array[Marker3D]        # 5: 26, 19, 13, 9 and 5 m (last is INSIDE the light)
@export var tracker: LookAtTracker
@export var seen_material: Material             # ShaderMaterial (psx) or StandardMaterial3D
@export var base_albedo := Color(0.03, 0.03, 0.04)
@export var watched_albedo := Color(0.17, 0.18, 0.21)   # subtle, but must read in fog at 26 m
@export var unseen_required := 1.5
@export var inner_unseen_required := 6.0     # cumulative unwatched seconds at cap before the breach
@export var breach_enabled := false          # debug-gated (F8)

var cap_index := 1
var station_index := -1
var step_requested := false
var breached := false
var watched := false                         # drives the albedo highlight (fairness rule 10)
var _was_watched := false
var _unseen := 0.0
var _inner_unseen := 0.0

func configure(cap_index_tonight: int, allow_breach: bool) -> void:
	cap_index = clampi(cap_index_tonight, 0, stations.size() - 2)   # NEVER includes the breach station
	breach_enabled = allow_breach
	station_index = -1
	step_requested = false
	breached = false
	watched = false
	_was_watched = false
	if seen_material:
		seen_material.albedo_color = base_albedo
	_unseen = 0.0
	_inner_unseen = 0.0
	visible = false

func head_position() -> Vector3:
	return global_position + Vector3.UP * 1.5

# "At tonight's cap" — NOT "at the physical last station".
# Conflating these two was the v1.2 Night 1 kill bug. Do not rename loosely.
func at_cap() -> bool:
	return station_index >= cap_index

func in_the_light() -> bool:
	return breached

func request_step() -> void:
	step_requested = true

func force_step() -> void:                    # used when staring kills the lamp
	_move_to(station_index + 1)

func _physics_process(delta: float) -> void:
	watched = visible and tracker.in_gaze_cone(head_position())
	# Albedo swap, NOT rim: BaseMaterial3D.rim is invisible under SHADING_MODE_UNSHADED,
	# and StandardMaterial3D has no set_shader_parameter() (that is ShaderMaterial only).
	if seen_material and watched != _was_watched:
		_was_watched = watched
		seen_material.albedo_color = watched_albedo if watched else base_albedo
	if station_index >= cap_index:
		_process_breach(delta)
		return
	if not step_requested or watched:
		_unseen = 0.0
		return
	var next := stations[station_index + 1].global_position + Vector3.UP * 1.5
	if tracker.in_gaze_cone(next):
		_unseen = 0.0
		return
	_unseen += delta
	if _unseen >= unseen_required:
		_move_to(station_index + 1)

func _process_breach(delta: float) -> void:
	if not breach_enabled or breached or not visible:
		return
	if watched:
		_inner_unseen = maxf(_inner_unseen - delta * 2.0, 0.0)
		return
	_inner_unseen += delta
	if _inner_unseen >= inner_unseen_required:
		breached = true
		station_index = stations.size() - 1
		global_position = stations[station_index].global_position   # position only; see _move_to
		_inner_unseen = 0.0

func _move_to(i: int) -> void:
	if i > cap_index:
		return
	station_index = i
	# Position only. Copying global_transform would also inherit the Marker3D's rotation
	# and scale, so a marker rotated to face the road would silently rotate/scale the figure.
	global_position = stations[i].global_position
	visible = true
	step_requested = false
	_unseen = 0.0
```

It checks both the current and the next position, so the figure never pops into view.

### The lamp and the attention economy

```gdscript
# world/lamp_controller.gd
class_name LampController extends Node3D

@export var light: OmniLight3D
@export var hum: AudioStreamPlayer3D
@export var base_energy := 1.6

var level := 1.0                       # 0..1, drained by staring
var scripted_blackout := false         # scripted blackouts can never kill
var _flicker := 1.0                    # multiplier set by flicker events

func _process(_delta: float) -> void:
	light.light_energy = base_energy * level * _flicker
	hum.pitch_scale = lerpf(0.7, 1.0, level)      # the audio tell

func drain(rate: float, delta: float) -> void:
	level = maxf(level - rate * delta, 0.0)

func recover(rate: float, delta: float) -> void:
	level = minf(level + rate * delta, 1.0)

func relight(to: float) -> void:
	level = to

# Called at every night start. Without it a night can begin at whatever level the
# previous one ended on (e.g. 0.5 after a blackout) and be one stare from a second.
func reset() -> void:
	level = 1.0
	_flicker = 1.0
	scripted_blackout = false

func set_flicker(multiplier: float) -> void:
	_flicker = multiplier

func scripted_dark(seconds: float) -> void:
	scripted_blackout = true
	var saved := level
	level = 0.0
	await get_tree().create_timer(seconds, false).timeout   # false = respects pause
	level = saved
	scripted_blackout = false
```

```gdscript
# world/gaze_monitor.gd
class_name GazeMonitor extends Node

@export var tracker: LookAtTracker
@export var figure: FogFigure
@export var lamp: LampController
@export var grace_sec := 2.0
@export var drain_per_sec := 0.10
@export var drain_per_sec_at_cap := 0.06    # ~19 s from full, ~10 s from a 0.5 relight
@export var recover_per_sec := 0.20

var armed := false            # set ONLY after a survived blackout   (fairness rule 1, gate 2)
var lethal_tonight := false   # from NightDef.gaze_lethal            (fairness rule 1, gate 1)
var _stare := 0.0

func configure(def: NightDef) -> void:
	lethal_tonight = def.gaze_lethal
	_stare = 0.0        # a stare carried over from the previous night would skip the grace period
	# `armed` deliberately NOT reset: it records what the player has been shown this session.

func _physics_process(delta: float) -> void:
	if lamp.scripted_blackout:
		return
	var staring := figure.visible and tracker.in_gaze_cone(figure.head_position())
	if staring:
		_stare += delta
		if _stare > grace_sec:
			var rate := drain_per_sec_at_cap if figure.at_cap() else drain_per_sec
			lamp.drain(rate, delta)
	else:
		_stare = 0.0
		lamp.recover(recover_per_sec, delta)
	if lamp.level <= 0.0:
		_on_gaze_blackout()

func _on_gaze_blackout() -> void:
	_stare = 0.0
	# ALL THREE GATES. Removing any one lets Night 1 or Night 2 kill the player.
	# v1.2 had only two of them and Night 1 killed at 22.3 s of continuous staring.
	if lethal_tonight and armed and figure.at_cap():
		Game.trigger_ending(&"out_of_the_light", &"gaze")
		return
	figure.force_step()          # no-op if already at the cap
	lamp.relight(0.5)
	armed = true                 # the demonstration fairness rule 1 requires
```

**Authoritative phase trace** — 60 Hz fixed physics tick, frame-accurate, Night 3 (`figure_cap_index = 3`, `gaze_lethal = true`), continuous staring from the figure's appearance. Grace **is** reapplied after every blackout, because `_on_gaze_blackout()` resets `_stare`. The cap rate applies only while `at_cap()` is true, i.e. from blackout 4 onward — not from the first move.

| Blackout | At | Phase | Rate | `station_index` after |
| --- | --- | --- | --- | --- |
| 1 | **12.00 s** | 2.00 grace + 10.00 drain (1.0 ÷ 0.10) | 0.10 | 1 |
| 2 | **19.02 s** | 2.00 + 5.00 (0.5 ÷ 0.10) | 0.10 | 2 |
| 3 | **26.03 s** | 2.00 + 5.00 (0.5 ÷ 0.10) | 0.10 | **3 = cap** |
| 4 | **36.37 s** | 2.00 + 8.33 (0.5 ÷ 0.06) | 0.06 | **DEATH** |

From the 0:40 appearance: cap at ≈1:06, death at ≈1:16. Nights 1 and 2 run the same phases but never die, because `gaze_lethal` is false — they cycle indefinitely (8 blackouts in 90 s, figure parked at the cap).

Do not re-derive these by hand. If you change `grace_sec`, either drain rate, or `relight`, re-run the simulation and update this table and the §22 window together.

Timing summary, from the figure's appearance, continuous staring:

| Night | Cap | Reaches cap | Result |
| --- | --- | --- | --- |
| 1 | 1 | 12 s | **Survives indefinitely** (`gaze_lethal` false) |
| 2 | 2 | 19 s | **Survives indefinitely** (`gaze_lethal` false) |
| 3 | 3 | 26 s (≈1:06) | **Dies at 36 s (≈1:16)** |

Tuning: the heartbeat tell fires at 30% normally and **50%** when `figure.at_cap()`.

### Interactables, holds and per-object reach

```gdscript
# player/interactable.gd
class_name Interactable extends StaticBody3D
# The interaction ray resolves its target with ray.get_collider(), which returns
# the BODY -- so the body must be the Interactable. A Node3D here can never match
# `hit is Interactable`. Collision is created in _ready on layer 3.

signal triggered

@export var prompt := "Interact"
@export var hold_seconds := 0.0        # a DURATION in seconds, not an enum: 0.0 = tap, 1.0 = hold for 1 s
@export var max_reach := 2.5           # the bus door uses 1.5
@export var distinct_style := false    # the stranger's prompt looks different
@export var enabled := true
@export var shape_size := Vector3(0.6, 0.6, 0.2)

func _ready() -> void:
	collision_layer = 1 << 2             # layer 3: interactables
	collision_mask = 0
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new(); bs.size = shape_size
	col.shape = bs
	add_child(col)

func can_use(player_pos: Vector3) -> bool:
	return enabled and global_position.distance_to(player_pos) <= max_reach
```

```gdscript
# player/interaction.gd
# Attach to the Player, as a sibling of the camera. The RayCast3D child must have
# collision_mask = layer 3 (interactables) ONLY, so glass on layer 1 cannot block it.
class_name PlayerInteraction extends Node

signal prompt_changed(text: String, distinct: bool)
signal hold_progress_changed(value: float)     # 0..1; the HUD draws the ring
signal lean_changed(active: bool)              # the camera narrows FOV, movement locks

@export var ray: RayCast3D
@export var interact_action := &"interact"
@export var readable_group := &"readable"      # timetable and poster: tap opens a lean-in

var _hold := 0.0
var _target: Interactable = null
var _leaning := false

func _ready() -> void:
	assert(ray != null, "PlayerInteraction.ray is not assigned")
	ray.collision_mask = 1 << 2                  # layer 3: interactables only
	ray.target_position = Vector3(0, 0, -2.5)    # default reach; per-object max_reach also applies

func _process(delta: float) -> void:
	_target = _current_interactable()
	if _target == null:
		_clear()
		return
	prompt_changed.emit(_target.prompt, _target.distinct_style)
	if not Input.is_action_pressed(interact_action):
		_clear()
		return
	if _target.hold_seconds <= 0.0:              # tap action
		if Input.is_action_just_pressed(interact_action):
			if _target.is_in_group(readable_group):
				_set_leaning(true)
			_target.triggered.emit()
		return
	_hold += delta                               # hold action
	hold_progress_changed.emit(clampf(_hold / _target.hold_seconds, 0.0, 1.0))
	if _hold >= _target.hold_seconds:
		_hold = 0.0
		hold_progress_changed.emit(0.0)
		_set_leaning(false)
		_target.triggered.emit()

func _current_interactable() -> Interactable:
	if not ray.is_colliding():
		return null
	var hit := ray.get_collider()
	if not (hit is Interactable):
		return null
	var it := hit as Interactable
	if not it.can_use(ray.global_position):
		return null
	return it

# Called by Main on Director.event_started for any intensity >= 2, and on every bus beat.
func cancel_lean() -> void:
	_set_leaning(false)
	_clear()

func is_leaning() -> bool:
	return _leaning

func _set_leaning(v: bool) -> void:
	if _leaning == v:
		return
	_leaning = v
	lean_changed.emit(v)

func _clear() -> void:
	if _hold != 0.0:
		_hold = 0.0
		hold_progress_changed.emit(0.0)
	_set_leaning(false)
	prompt_changed.emit("", false)
```



`Main._on_event_started` calls `interaction.cancel_lean()` for any event of intensity ≥ 2, so a modal lean-in can never hide a bus. The HUD connects to `prompt_changed`, `hold_progress_changed` and `lean_changed` — signals rather than a direct reference, so no HUD class has to exist before this script compiles.

### Event base class and an example

```gdscript
# events/event_base.gd
class_name EventBase extends Node3D

signal finished(event_id: StringName)

@export var event_id: StringName
var ctx: EventContext
var _ended := false                    # guard: abort() and a natural finish can both fire

func run(p_ctx: EventContext) -> void:
	ctx = p_ctx
	_start()

func abort() -> void:
	_done()

func _start() -> void:
	pass

func _cleanup() -> void:
	pass

func _done() -> void:
	if _ended:
		return
	_ended = true
	_cleanup()
	finished.emit(event_id)
	queue_free()
```

```gdscript
# events/e01_lamp_flicker.gd
extends EventBase

# ACCESSIBILITY, ENFORCED IN CODE (§17). One full cycle is dim + lit.
# v1.3 used 0.04-0.12 s + 0.05-0.20 s, i.e. 0.09-0.32 s cycles = 3.1-11.1 Hz,
# which broke the "no more than three flashes per second" limit at EVERY roll.
# 0.45-0.80 s cycles = 1.25-2.22 Hz nominal, 2.20 Hz measured peak. Do NOT tighten:
# tween_interval lands on frame boundaries, so measured cycles come in SHORTER than
# nominal. MIN_CYCLE 0.36 measured a 0.332 s cycle = 3.01 Hz, over the limit.
const MIN_CYCLE := 0.45                    # measured peak 2.20 Hz; 0.36 measured 3.01 Hz and FAILED
const MAX_CYCLE := 0.80

var _lamp: LampController

func _start() -> void:
	_lamp = ctx.lamp
	assert(_lamp != null, "EventContext.lamp is not set")
	var tw := create_tween()           # bound to this node, so it pauses with the tree
	for i in randi_range(3, 6):
		var cycle := randf_range(MIN_CYCLE, MAX_CYCLE)
		var dim_t := cycle * randf_range(0.25, 0.45)      # the dim phase is the shorter half
		tw.tween_callback(_lamp.set_flicker.bind(randf_range(0.10, 0.55)))
		tw.tween_interval(dim_t)
		tw.tween_callback(_lamp.set_flicker.bind(1.0))
		tw.tween_interval(cycle - dim_t)                  # cycle total is always >= MIN_CYCLE
	tw.finished.connect(_done)         # "reduce flicker": one slow dim instead

func _cleanup() -> void:
	if _lamp != null:
		_lamp.set_flicker(1.0)
```

### The Director

```gdscript
# core/director.gd
class_name Director extends Node

signal event_started(e: HorrorEvent)
signal event_ended(e: HorrorEvent)

var ctx: EventContext
var night: NightDef
var running := false

var _t := 0.0
var _next := 0
var _pending: Array[BeatDef] = []
var _live: Dictionary = {}              # EventBase instance -> HorrorEvent  (NOT keyed by resource)
var _last_start: Dictionary = {}        # StringName -> float
var _calm_until := 0.0
var _last_id: StringName = &""

func start_night(n: NightDef, c: EventContext) -> void:
	night = n
	ctx = c
	_assert_beats_sorted()                   # _process queues with a while-loop and one cursor
	_t = 0.0
	_next = 0
	_pending.clear()
	_live.clear()
	_last_start.clear()
	_calm_until = 0.0
	_last_id = &""
	running = true

func stop() -> void:
	running = false

# The scheduler walks beats with a single forward cursor, so an out-of-order beat
# is never queued and silently never plays. Fail loudly in the editor instead.
func _assert_beats_sorted() -> void:
	for i in range(1, night.beats.size()):
		assert(night.beats[i].time_sec >= night.beats[i - 1].time_sec,
			"NightDef %d: beats must be sorted ascending by time_sec (index %d)" % [night.index, i])

func _process(delta: float) -> void:
	if not running:
		return
	_t += delta
	while _next < night.beats.size() and night.beats[_next].time_sec <= _t:
		_pending.append(night.beats[_next])
		_next += 1
	for b in _pending.duplicate():
		if _try_beat(b):
			_pending.erase(b)

func _try_beat(b: BeatDef) -> bool:
	var e: HorrorEvent = b.event
	if b.kind == BeatDef.Kind.FILL:
		e = _pick(b.pool)
		if e == null or not _can_start(e, false):
			return true                          # optional beat: skip quietly
	elif b.punctual:
		pass                                     # structural beat: NEVER delayed by pacing
	elif not _can_start(e, _t - b.time_sec >= b.max_delay):
		return false                             # authored: wait for a clear window
	_start(e)
	return true

func _can_start(e: HorrorEvent, force: bool) -> bool:
	for live_res in _live.values():
		if live_res.id == e.id:
			# Never two instances of the SAME event. Two overlapping E1s would each
			# drive the lamp and could double the flicker rate past the 3 Hz limit.
			# No event in this game benefits from overlapping itself.
			return false
	for live_inst in _live.keys():
		if not is_instance_valid(live_inst):       # freed without emitting `finished`
			_live.erase(live_inst)            # a stale intensity-3 entry would block
			continue                          # every authored climax for the night
	for live_res in _live.values():
		if e.intensity >= 3 and live_res.intensity >= 3:
			return false                         # hard rule
		if not force and e.intensity >= 2 and live_res.intensity >= 2:
			return false
	if not force and e.intensity >= 2 and _t < _calm_until:
		return false
	return true

func _pick(pool: Array[HorrorEvent]) -> HorrorEvent:
	var valid: Array[HorrorEvent] = []
	for e in pool:
		if night.index < e.min_night or night.index > e.max_night:
			continue
		if e.id == _last_id:
			continue
		if _t - _last_start.get(e.id, -9999.0) < e.cooldown:
			continue
		valid.append(e)
	if valid.is_empty():
		return null
	var total := 0.0
	for e in valid:
		total += e.weight
	var roll := randf() * total
	for e in valid:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return valid.back()

func _start(e: HorrorEvent) -> void:
	_last_id = e.id
	_last_start[e.id] = _t
	assert(e.scene != null, "HorrorEvent '%s' has no scene" % e.id)
	var inst := e.scene.instantiate() as EventBase
	assert(inst != null, "Root of '%s' is not an EventBase" % e.scene.resource_path)
	_live[inst] = e                              # keyed by INSTANCE
	add_child(inst)
	inst.finished.connect(_on_finished.bind(inst, e))
	inst.run(ctx)
	event_started.emit(e)

func _on_finished(_id: StringName, inst: EventBase, e: HorrorEvent) -> void:
	_live.erase(inst)
	if e.intensity >= 2:
		_calm_until = _t + 15.0                  # measured from the END of the event
	event_ended.emit(e)
```

### Sign line (Rule 3)

A `BoxShape3D` ~1 m thick, 24 m wide, 6 m tall, on the trigger layer, scanning only the player layer.

```gdscript
# world/sign_line.gd  (Area3D)
extends Area3D

signal warned                       # Night 1: dim the lamp, drone, nudge the player

var lethal := false
var _warn_cooldown := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1         # layer 2: the player
	body_entered.connect(_on_body_entered)

func configure(is_lethal: bool) -> void:
	lethal = is_lethal

func _process(delta: float) -> void:
	_warn_cooldown = maxf(_warn_cooldown - delta, 0.0)

# body_entered does not fire for bodies already inside. Overlap lists update once
# per physics step, so wait two steps.
func check_initial_overlap() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for b in get_overlapping_bodies():
		_on_body_entered(b)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if lethal:
		Game.trigger_ending(&"out_of_the_light", &"sign")
	elif _warn_cooldown <= 0.0:
		_warn_cooldown = 5.0
		warned.emit()               # Main: lamp to 20%, low drone, push back. NO figure advance.
```

**Two implementation notes:**

- `check_initial_overlap()` and `body_entered` can both fire for the same crossing on a night restart (the player spawns inside the zone, so the overlap set changes on the first physics step). That is benign — Night 1's `_warn_cooldown` swallows the second warning, and `Game.trigger_ending`'s `state != NIGHT` guard swallows the second ending — but do not "fix" it by removing either path, because each covers a case the other misses.
- The Night 1 push-back must be a **displacement over several frames, not a teleport**. The sign wall is only ~1 m thick; teleporting the player out of it can deposit them on the far side, which in Night 2+ is an instant ending they did not choose.

Rules 1 and 2: the bus door and the stranger are `Interactable`s with `hold_seconds = 1.0`. On `triggered` they call `Game.trigger_ending(&"wrong_bus")`, `&"spoke_first"`, or `&"right_bus"` for the real bus.

### Running a night

Every `await` can outlive its night if the player fails and restarts, so each run carries an id and exits if it is stale.

```gdscript
# main.gd — the night's spine. Attach to the Main node (see the scene tree in §18).
extends Node3D

@export var nights: Array[NightDef]           # [night_1, night_2, night_3]
@export var player: Node3D
@export var figure: FogFigure
@export var gaze: GazeMonitor
@export var lamp: LampController
@export var sign_line: Area3D
@export var clock: NightClock
@export var director: Director
@export var interaction: PlayerInteraction
@export var title_card_seconds := 3.0

var ctx: EventContext
var _run_id := 0

func _ready() -> void:
	ctx = EventContext.new()
	ctx.lamp = lamp
	ctx.player = player
	ctx.figure = figure
	ctx.clock = clock
	Game.ending_triggered.connect(_on_ending)
	sign_line.warned.connect(_on_sign_warned)
	director.event_started.connect(_on_event_started)
	run_night(nights[0])

func _on_event_started(e: HorrorEvent) -> void:
	if e.intensity >= 2 and interaction != null:
		interaction.cancel_lean()               # a modal lean-in must never hide a bus

func run_night(def: NightDef) -> void:
	_run_id += 1
	var my_id := _run_id
	Game.begin_night(def.index)                 # also calls AudioHub.reset()
	figure.configure(def.figure_cap_index, def.breach_enabled)
	gaze.configure(def)                         # sets lethal_tonight, clears _stare
	lamp.reset()                                # level 1.0, flicker 1.0, blackout flag off
	sign_line.configure(def.sign_lethal)
	clock.start(def)
	director.start_night(def, ctx)
	await sign_line.check_initial_overlap()
	await clock.arrived                         # exactly 11:47, exactly the bus's arrival
	if my_id != _run_id:
		return
	director.stop()                             # no new fill beats after arrival
	await get_tree().create_timer(def.post_arrival_seconds, false).timeout
	if my_id != _run_id or Game.state != Game.State.NIGHT:
		return
	_window_closed(def)

# Nights 1 and 2 reaching this point IS the clean path, not a failure.
func _window_closed(def: NightDef) -> void:
	match def.index:
		1, 2:
			await _fade_and_card("Night %d" % (def.index + 1))
			if Game.state == Game.State.NIGHT:
				run_night(nights[def.index])     # nights[] is 0-based, index is 1-based
		3:
			Game.trigger_ending(&"still_waiting")   # terminal (fairness rule 9)
		_:
			push_error("No NightDef with index %d" % def.index)

func _on_ending(id: StringName, variant: StringName) -> void:
	director.stop()
	AudioHub.restore_weather(1.0)               # never leave the weather muted
	await _show_ending_card(id, variant)
	if id == &"right_bus":
		await _fade_and_card("")                # to the credits
		return
	# Every other ending restarts the SAME night, in under 5 s (fairness rule 5).
	run_night(nights[clampi(Game.night_index - 1, 0, nights.size() - 1)])

func _on_sign_warned() -> void:
	lamp.set_flicker(0.2)                       # dims to 20%
	# Play the low drone, then push the player back toward the shelter over several
	# frames. NEVER teleport: the wall is only ~1 m thick and a teleport can deposit
	# the player on the far side, which in Night 2+ is an ending they did not choose.
	var tween := create_tween()
	tween.tween_callback(lamp.set_flicker.bind(1.0)).set_delay(1.5)

func _fade_and_card(text: String) -> void:
	# Placeholder for the real UI: fade to black, show the title card, fade in.
	if text.is_empty():
		return
	await get_tree().create_timer(title_card_seconds, false).timeout

func _show_ending_card(_id: StringName, _variant: StringName) -> void:
	await get_tree().create_timer(title_card_seconds, false).timeout
```


`_window_closed(def)` is per-night, not Night 3 only:

| Night | Behaviour |
| --- | --- |
| 1 | The bus has already passed (S1 is a pass-by, not a stop). Fade to black, title card, `run_night(night_2)`. **No ending.** |
| 2 | The numberless bus pulls away. Fade, title card, `run_night(night_3)`. **No ending.** |
| 3 | `Game.trigger_ending(&"still_waiting")` — **terminal** (§10). |

Nights 1 and 2 reaching this point *is* the clean path, so it must not be treated as a failure. Write it as an explicit switch on `def.index` rather than reusing a boolean flag, so the three cases stay readable.

### Pause and process modes

| Node | `process_mode` | Why |
| --- | --- | --- |
| Main, world, Director, NightClock, FogFigure, GazeMonitor, LampController | Inherit (pausable) | Pausing must freeze the whole night, including the clock |
| PauseMenu `CanvasLayer` | When Paused | Must work while the tree is paused |
| `AudioHub` autoload | Inherit (pausable) | So its fades freeze with the game |

- Create gameplay tweens with `create_tween()` **on the node that owns them** — bound to that node, following its process mode. (`SceneTree.create_tween()` is bound to the tree; don't use it for gameplay.)
- Use `get_tree().create_timer(seconds, false)`. The second argument is `process_always`; `false` makes it respect pause. Verified against the 4.7 source.
- Don't call `play()` on an audio player from an always-processing node while paused.
- Pausing during the 45 s / 60 s decision windows freezes the window. Intended, and an accessibility feature.

### The silence beat

```gdscript
# core/audio_hub.gd (autoload)
extends Node

func silence_beat(duration := 6.0) -> void:
	_fade_weather(-60.0, duration)

func restore_weather(duration := 2.0) -> void:
	_fade_weather(0.0, duration)

var _tw: Tween

func reset() -> void:                          # called from Game.begin_night
	_kill_fade()
	AudioServer.set_bus_volume_db(_weather_bus(), 0.0)

func _weather_bus() -> int:
	var idx := AudioServer.get_bus_index("Weather")
	assert(idx >= 0, "Audio bus 'Weather' is missing - check default_bus_layout.tres")
	return idx

func _kill_fade() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()                             # two overlapping fades would fight over the bus
	_tw = null

func _fade_weather(target_db: float, duration: float) -> void:
	_kill_fade()
	var idx := _weather_bus()
	var from := AudioServer.get_bus_volume_db(idx)      # read, never hardcode
	_tw = create_tween()
	_tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v), from, target_db, duration)
```

The options sliders never touch Weather, so the fade can't fight them, and `reset()` at every night start means an ending during the silence beat never leaves the weather muted.

### The bus rig

The bus is structural, not a scare, so its arrival is owned here and by the clock —
not by the Director's pacing rules (§13, `punctual`).

```gdscript
class_name BusRig extends Node3D
# The bus: drive-by, arrival, doors, destination board, interior light.
# Arrival timing is owned by main.gd / the clock, not the Director (punctual).

signal doors_opened
signal doors_closed

@onready var bus: Node3D = $Bus
@onready var door_l: MeshInstance3D = $Bus/DoorLeafL
@onready var door_r: MeshInstance3D = $Bus/DoorLeafR
@onready var dest: MeshInstance3D = $Bus/DestBoard
@onready var engine: AudioStreamPlayer3D = $Engine
@onready var brakes: AudioStreamPlayer3D = $Brakes
@onready var doors_snd: AudioStreamPlayer3D = $DoorsSnd
@onready var interior: AudioStreamPlayer3D = $Interior

var _door_open := false
var _dest_mat: StandardMaterial3D

const LANE_Z := -1.5

func _ready() -> void:
	bus.position = Vector3(-90.0, 0.0, LANE_Z)
	_dest_mat = dest.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	dest.set_surface_override_material(0, _dest_mat)
	set_lights(false)
	close_doors(true)

func set_board(numbered: bool) -> void:
	_dest_mat.albedo_texture = load("res://textures/%s.png" % ("dest_47" if numbered else "dest_blank"))

func set_lits_windows(on: bool) -> void:
	for n in bus.get_children():
		if n.name.begins_with("Win") or n.name == "Windscreen":
			var m := (n as MeshInstance3D).mesh.surface_get_material(0)
			if m: m.emission_enabled = on

func set_lights(on: bool) -> void:
	engine.stream = load("res://audio/engine_idle.wav")
	for n in ["Headlight-1", "Headlight1"]:
		var h := bus.get_node_or_null(n)
		if h: (h as MeshInstance3D).visible = on

func pass_by(duration := 9.0) -> void:
	engine.stream = load("res://audio/engine_approach.wav"); engine.play()
	var tw := create_tween()
	tw.tween_property(bus, "position:x", 90.0, duration).set_trans(Tween.TRANS_LINEAR)
	tw.tween_callback(func(): engine.stop())

func arrive(from_x := -70.0, lead := 15.0) -> void:
	bus.position.x = from_x
	engine.stream = load("res://audio/engine_approach.wav"); engine.play()
	var tw := create_tween()
	tw.tween_property(bus, "position:x", 8.5, lead).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func():
		engine.stop(); brakes.play())

func open_doors() -> void:
	if _door_open: return
	_door_open = true
	doors_snd.stream = load("res://audio/door_open.wav"); doors_snd.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(door_l, "position:x", door_l.position.x - 0.5, 0.8)
	tw.tween_property(door_r, "position:x", door_r.position.x + 0.5, 0.8)
	set_lits_windows(true)
	interior.stream = load("res://audio/interior_hum.wav"); interior.play()
	doors_opened.emit()

func close_doors(silent := false) -> void:
	if not _door_open and not silent:
		return
	_door_open = false
	if not silent:
		doors_snd.stream = load("res://audio/door_close.wav"); doors_snd.play()
	door_l.position.x = 3.12; door_r.position.x = 3.68
	set_lits_windows(false)
	interior.stop()
	doors_closed.emit()

func depart() -> void:
	close_doors()
	engine.stream = load("res://audio/engine_approach.wav"); engine.play()
	var tw := create_tween()
	tw.tween_property(bus, "position:x", 110.0, 8.0)
	tw.tween_callback(func(): engine.stop())

func reset() -> void:
	close_doors(true)
	bus.position = Vector3(-90.0, 0.0, LANE_Z)
	set_board(false)
	set_lits_windows(false)
	engine.stop(); interior.stop()

func door_world_pos() -> Vector3:
	return bus.global_position + Vector3(3.4, 1.2, 1.35)
```

### Rain

```gdscript
# world/rain.gd  (GPUParticles3D)
extends GPUParticles3D

@export var target: Node3D

func _ready() -> void:
	top_level = true

func _process(_delta: float) -> void:
	if target == null:
		return
	global_position = target.global_position + Vector3(0, 6, 0)
```

The rig carries the bus mesh, the engine/brake/door/interior players, the door leaves and the destination board. `arrive()`-side placement, `open_doors()` / `close_doors()` / `depart()` are the only entry points events use, and `reset()` returns everything to the pre-night state. **The punctual arrival beat drives these at exactly `real_seconds`**, which is the instant `clock.arrived` fires — the approach *sound* is a separate authored beat ~15 s earlier, so nothing pacing-related can delay the bus.

---

## 19. Godot project settings

| Setting | Recommendation |
| --- | --- |
| Renderer | Forward+ for development. Test Compatibility early if weaker machines matter. |
| Window / stretch | Base size ~640×360, stretch mode `viewport`, integer scale for crisp pixels. |
| Texture filter | Nearest, textures and UI. |
| TAA / MSAA | **Off.** Both fight vertex snapping. |
| Fog | Environment depth fog, 4 m → 32 m, curve ~1.2. No volumetric fog. |
| Physics layers | 1 world, 2 player, 3 interactables, 4 entities, 5 triggers, 6 sight_blockers (§14). |
| Look-at sight mask | Layer 6 only (value 32). Glass and thin props are never on it. |
| Interaction ray mask | **Layer 3 only** (value 4). |
| `LookAtTracker.max_distance` | **32.0** — exactly the fog end. |
| `NightDef.gaze_lethal` | **false, false, true.** Verify in the automated checks. |
| Input map | `move_*`, `interact` (tap and hold), `watch` (hold), `pause`, debug keys F1–F10. |
| Audio buses | Master, Weather (Rain, Wind), Ambience, SFX, Voice, ShelterVerb, UI. |
| Autoload order | Irrelevant as written (no cross-references in `_ready()`). If `Save.read()` ever moves into `Save._ready()`, it becomes **`Game` above `Save`**. Preferred: call `Save.read()` from `Main._ready()`. |
| Process modes | §18. |
| Version control | Git with a Godot `.gitignore`. Commit at the end of every session. |

---

## 20. Production plan

Assumes ~8–10 h/week. Every week ends with a **playable build**; the exit criteria are the definition of done.

### The honest arithmetic

An itemized estimate for this scope is **137–204 hours**. At 8–10 h/week that is **15–23 weeks**, not 12. Three ways to close the gap, in order of preference:

1. **Execute cut-list items 1–2 now, not in week 8.** Dropping E8 and E9 up front saves ~2–3 days and removes the two most fiddly systems (the reflection ring buffer especially).
2. **Raise weekly hours for weeks 1–4 only.** Front-loading the core is where the estimate is most forgiving.
3. **Extend the calendar.** Treat this as 12 weeks of *scope* and 16 weeks of *calendar*.

The plan below is 12 weeks of scope with weeks 11–12 as buffer. **Plan the release around week 14–16.**

### Resequenced phase overview

The concept-validating mechanic comes **first**; the PSX art pass comes **after** the week-4 gate. If the glance rhythm doesn't work, no look-dev is wasted.

| Week | Focus | Exit criteria |
| --- | --- | --- |
| **1** | Project setup, **the headless test project (§22) — ~2 h, and the only thing that caught both v1.6 defects**, greybox at the §14 coordinates, player at 1.8 m/s, depth fog, rain, lamp, audio buses, all six physics layers. **2 h PSX pack compatibility check only** — does it coexist with depth fog and an `OmniLight3D`? No look-dev. **Days 1–2: the gaze loop** — capsule figure, dimming lamp, `LookAtTracker`, `GazeMonitor`. | You can walk the greybox, and **staring at a capsule dims the lamp while looking away lets it advance.** The whole concept in two days. |
| **2** | `NightDef` (incl. `gaze_lethal`) + clock, interactables with holds, lean-in, forearms and watch (time only), Weather bus | The clock reaches exactly 11:47 at arrival; a 1 s hold works; the lean-in cancels on a big event |
| **3** | Director (authored/fill), `EventContext`, `LookAtTracker` (cone + fan + physics callback), `LampController`, silhouette highlight, E1–E3 | Night 1's beats run and feel fair; **the highlight is visibly confirmable in-engine** (not just that the boolean is correct) |
| **4** | `FogFigure` (5 stations, cap, breach behind F8), `GazeMonitor` (**three gates**), S1 passing bus, scripted blackout, sign line, restart flow, run-id guard | **VERTICAL SLICE + HARD GO/NO-GO.** Night 1 playable start to finish. **Run the 60 s stare test on all three nights (§22).** Three fresh people test the glance rhythm and the cone legibility. If it isn't fun or reads as cheating, stop and redesign before making art. |
| **5** | Night 2: E5, E6, E7 (hold to speak, leaves if ignored), sign line lethal, S2 numberless bus, endings 1-sign / 2 / 3, ending card, endings menu | Night 2 playable, three endings reachable |
| **6** | Night 3: E10, silence beat, real bus, **Ending 4 (terminal)**, bus interior S4 and the Ending 5 beat, gaze death (`gaze_lethal` + `armed` + cap) | The full game is completable, all five endings reachable |
| **7** | **PSX look-dev:** shader pack, resolution/stretch, palette, dither pass (Godot's fog doesn't dither), TAA/MSAA off | The game looks like the reference screenshots you want |
| **8** | Art pass: textures, vertex colours, poster ×3, UI, lighting. **The three clip moments first** (~40% of the week) | Cohesive; the three clip moments excellent |
| **9** | Audio pass: foley, the one voice (~12 lines), mix, the hum's pitch gauge **and gaze partial**, tune the silence beat | The game sounds finished |
| **10** | Playtest round 2, tuning (gaze numbers, breach on/off, cap drain, cone legibility A/B), options, accessibility, save, credits | No known soft-locks; options and captions work |
| **11** | Build, export, second-machine test, store page, trailer GIFs, `LICENSES.md` audit | Release candidate |
| **12** | Buffer, final playtest, release | Released |

### First three days

1. Project, repo, folder structure. Renderer, stretch mode, input map, **all six physics layers**.
2. Greybox the shelter, road and signpost at the §14 coordinates. Depth fog 4–32 m, dark ambient, the lamp (range 6.5 m), rain.
3. Player controller with the tether and footsteps at 1.8 m/s. **PSX pack compatibility check only (2 h).**
4. **The gaze loop:** a capsule at 26 m, `LookAtTracker`, `LampController`, `GazeMonitor` with all three gates. Stare → lamp dims, hum drops. Look away 1.5 s → capsule steps to 19 m. **Set `gaze_lethal = false` and confirm you cannot die. Set it true with `armed` forced and confirm you can.**
5. Audio buses and a looping rain sound.

**Goal for day 3:** you can stand in a grey box in the rain and be afraid of a capsule — and the box cannot kill you when it shouldn't. If that works, everything else is decoration.

### Definition of done

- A clean run takes 22–26 minutes.
- All five endings reachable; **Night 1 cannot kill the player under any input, and Night 2 cannot kill by gaze** (its sign line is lethal by design); no ending loops forever.
- No soft-locks; a failed night restarts in under 5 seconds.
- The clock reads 11:47 when the bus arrives, every night.
- Stable 60 fps on the target hardware.
- Every asset has a named licence in `LICENSES.md`.
- Options (incl. show-gaze-boundary and press-instead-of-hold), directional captions and a content note are in.
- Credits screen in.
- **"No generative AI was used" tag set on the store page** (§2).

### Cut list (in this order)

1. **E8 glass reflection.** Nothing depends on it — the jacket payoff comes from the forearms. *(Recommended: cut now, not in week 8.)*
2. **E9 payphone.** Keep E6 — it is load-bearing for **Rule 2** as well as Ending 3 (§9). Losing E9 also loses the "It's already 11:47" lore line; acceptable. *(Recommended: cut now.)*
3. The stranger's return in Night 3.
4. Watch telegraphs (keep the raise and the time).
5. Stretch verbs.
6. The breach rule (fifth station). Debug-gated; shipping without it is legitimate.
7. The cone vignette accessibility option (keep the silhouette highlight and hum partial — those are fairness rule 10, not optional).
8. Passenger silhouettes in the real bus. Fallback: a dim interior with the destination board and the **BOARDED 11:47 PM** notice — that notice is the essential beat.
9. Ending 1's second variant (ship one card, one vignette).

### Never cut

The Fog Figure and the attention economy · **the three gaze gates** · the three-night structure · the legible sign and timetable · the numberless bus · the silence beat · **Ending 4** (~30 minutes of work and your soft-lock guarantee) · the Ending 5 notice beat · **E6 and the one voice** (~3 lines minimum — load-bearing for Rule 2, not just Ending 3, §9) · the Night 1 stare lesson · **the silhouette highlight or the hum partial** (at least one; fairness rule 10).

---

## 21. Risk register

| # | Risk | L | I | Mitigation |
| --- | --- | --- | --- | --- |
| 1 | The waiting feels boring | Med | High | Attention economy; nights under 8 min; track idle time. **Answered in week 4, not week 10.** |
| 2 | Look-at detection misfires | Med | High | One cone for watched and stared, distance + fan ray against sight blockers only, `_physics_process`, F4 debug draw, test with walls and glass in the way. |
| 3 | The PSX look is inconsistent | Low | Med | Compatibility check in week 1; look-dev in week 7 with the pack already known-good. |
| 4 | Audio quality is poor | Med | High | Plan sourcing in week 1; record your own foley and voice. |
| 5 | Scope creep | High | High | Cut list; never add an event without removing one. **Execute cuts 1–2 up front.** |
| 6 | Performance on weaker machines | Low | Med | Test Compatibility early; modest rain particles. |
| 7 | Soft-locks and state bugs | Med | High | One state machine, run id on every night, debug keys, Ending 4 terminal, test every ending. |
| 8 | Burnout | Med | High | Playable build weekly, short milestones, protect rest days. |
| 9 | Players miss the rules | Med | Med | Legible sign from Night 1, readable timetable from Night 2, ask playtesters to state the rules. |
| 10 | The gaze cost feels unfair or annoying | Med | High | Tells at 60%/30% (50% at cap), 2 s grace, three gates, slower cap drain, exported tuning values, **tested in week 4**. |
| 11 | Calendar slip | **High** | Med | 137–204 h of scope against 96–120 h of capacity. Cut now; plan release for week 14–16. |
| 12 | **The premise reads as derivative** | **High** | Med | Verified (§2). Lead with the gaze economy and the timetable, never with the bus stop or "stay in the light." Play *Last Bus Home* first. |
| 13 | **The title collides** | High | Low | Three of four original candidates rejected; recommendation changed to *Thank You for Waiting* (§2). Manual search before committing. |
| 14 | **The cone boundary reads as cheating** | Med | High | Fairness rule 10: silhouette highlight + hum partial by default, optional vignette. Metric in §22; A/B in weeks 4 and 10. |
| 16 | **The highlight is correct in code but invisible in game** | Med | High | Already happened once (rim lighting on an unshaded material). §22's check is a *manual in-engine* check, not an automated one — no automated test can tell you a visual is invisible. |
| 15 | **A safety rule is broken by a future edit** | Med | High | The Night 1 / Night 2 60 s stare tests are automated and run before every build (§22). v1.2 proved a weaker version of this test passes while the bug is live. |

---

## 22. Testing plan

### Automated checks (`res://tests/`, run before every build)

**Run the parse-all check first.** It is the only one that covers every file: `godot --headless --import` scans `class_name` declarations only, and `--check-only` does not register autoloads, so scripts referencing `Game` / `Save` / `AudioHub` fail under it spuriously. Load every `.gd` at runtime instead and assert `can_instantiate()`. Last run: **26/26, 0 failures** (`bus-stop-tests/tests/parseall.tscn`).

| Check | Pass condition |
| --- | --- |
| **Every script compiles** | Walk `res://`, `load()` every `.gd`, assert a non-null `Script` with `can_instantiate() == true`. Covers files no scene references — which is exactly where the v1.6 excerpts hid. |
| **Clock reaches arrival** | For each `NightDef`: run the clock headless to `_elapsed == real_seconds`; assert `current_minute() == 47`, `arrived` fired **exactly once**, and `start_minute()` is in 25..46. *(v1.1's version restated the definition of `start_minute()` and could not fail.)* |
| **Clock tempo** | For each `NightDef`, `real_seconds / (47 - start_minute())` is within 24.0–26.0 s per in-game minute. Expected: 25.00 / 25.33 / 25.31. |
| **Night flags** | `gaze_lethal` is `[false, false, true]`; `sign_lethal` is `[false, true, true]`; `figure_cap_index` is `[1, 2, 3]`; `real_seconds` is `[300, 380, 405]`. |
| **Beat ordering** | No authored beat has `time_sec > real_seconds` unless flagged post-arrival; rule tests are ≥ 30 s apart. |
| **Layer audit** | No glass, transparent or thin prop is on layer 6. **The lamp pole is not on layer 6.** |
| **Interaction mask** | The interaction `RayCast3D`'s mask is exactly layer 3 (value 4). |
| **Station reachability** | Each of stations 1–4 is within `max_distance` (32 m) of the **shelter centre** — not of the tether extreme, which is 41.5 m from station 1 and would fail. *(v1.1's version failed as written.)* |
| **Cone/FOV scaling** | At vertical FOV 75 and 90 on 16:9, the cone is 41% ± 1% of `horizontal_fov()`. |
| **No free band** | Across sample angles of the horizontal FOV, `FogFigure.watched` and `GazeMonitor`'s staring boolean are **identical** at every angle. |
| **NIGHT 1 CANNOT KILL (60 s stare)** | From the figure's appearance, hold the gaze cone continuously for **60 s**. Assert `Game.state == NIGHT` throughout, `armed == true` after the first blackout, and the figure reached the Night 1 cap and stopped. *(v1.2's version stared only to the first blackout and passed while the bug was live.)* |
| **NIGHT 1 CANNOT KILL (sign)** | Crossing the sign line in Night 1 emits `warned`, never an ending. |
| **NIGHT 2 CANNOT KILL (60 s stare)** | Same as above with the Night 2 cap. |
| **Night 2 sign is lethal** | Crossing ends the run with variant `sign`. |
| **Night 3 gaze death timing** | From the figure's appearance, continuous staring reaches the cap at **25.5–26.6 s** and kills at **35.8–37.0 s** (nominal 26.03 s and 36.37 s at 60 Hz — see §18's phase trace). Deliberately tight: the previous 24–28 / 30–42 window passed three separate regressions. Applying the cap rate early gives 43.00 s; setting it equal to 0.10 gives 33.05 s; applying grace only once gives 30.37 s. All three now fail. |
| **All three gates required** | With `gaze_lethal == false`, **or** `armed == false`, **or** the figure below cap, a blackout never ends the run. Test each independently (F9 helps). |
| **Beats sorted** | For every `NightDef`, `beats[i].time_sec >= beats[i-1].time_sec`. The Director queues with a single forward cursor, so one out-of-order beat silently never plays. `Director._assert_beats_sorted()` also checks this at runtime. |
| **Weather bus exists** | `AudioServer.get_bus_index("Weather") >= 0` in the exported build. A missing bus makes the silence beat — the game's climax — fail silently. |
| **Night start state** | After `run_night()` for any night: `lamp.level == 1.0`, `lamp._flicker == 1.0`, `lamp.scripted_blackout == false`, `gaze._stare == 0.0`, `figure.station_index == -1`, `figure.visible == false`, Weather bus at 0 dB. A night must never inherit the previous night's lamp level. |
| **Arrival punctuality** | For each night, drive the Director with the real beat list and assert the arrival beat's `event_started` fires within **±0.1 s** of `real_seconds`. Requires `punctual = true` on all three arrivals. *Without it this measured +15.02 s in all three nights.* |
| **Same-event exclusion** | With two authored beats carrying the same event id, `cooldown = 0` and intensity 1, only one instance ever starts. A *different* intensity-1 id is still allowed alongside. This is what keeps E1's flicker clamp true under concurrency. |
| **Flicker rate — MEASURED, not computed** | Run E1 for ≥ 10 cycles, timestamp each dim onset with `Time.get_ticks_msec()`, assert the shortest measured cycle is ≥ 0.40 s (≤ 2.50 Hz). **Do not compute this from `MIN_CYCLE`** — `tween_interval` quantises to frame boundaries and jitter makes observed cycles shorter than nominal; computing from the constant produced a false PASS at `MIN_CYCLE = 0.36` (measured 0.332 s = 3.01 Hz). Also assert no scripted blackout is shorter than 3 s. |
| **Highlight tracks the cone** (automated) | `FogFigure.watched` equals `in_gaze_cone(head_position())` and `albedo_color` follows it. |
| **Highlight is VISIBLE** (manual, in-engine) | Stand at station 1 distance in fog, sweep the cone on and off the figure, and confirm the change is perceptible on your actual material. **This cannot be automated** — the rim-lighting version of this feature was boolean-correct and invisible, because rim is not rendered for `SHADING_MODE_UNSHADED`. |
| **Spawn overlap** | Spawning inside the sign line is handled by `check_initial_overlap()`. |
| **Pause** | Pausing during the silence beat and resuming restores Weather to 0 dB; pausing during a decision window freezes the window. |
| **Restart** | Failing and restarting does not resume a stale night coroutine (run-id guard); `lethal_tonight` is re-read for the new night. |
| **No infinite ending** | Triggering `still_waiting` reaches an end card and does not call `run_night()`. |

### Self-testing (weekly)

- Play the current night from the start, headphones, in the dark.
- Run every ending after each major change.
- **Stare at the figure for a full minute in Nights 1 and 2 after any change to the gaze, lamp or figure code.** This is the regression that shipped once already.
- Use F1–F10 to test any event, station, gate and the breach rule on demand.

### External playtests — weeks 4 and 10

Five people who haven't seen the game. Don't explain it. Watch silently.

**Observe:**

- Where do they look when nothing is happening?
- Do they stare at the figure, and for how long? Do they find the glance rhythm unaided?
- **Do they understand where the gaze cone's boundary is, without being told?**
- Do they read the sign and the timetable, and when?
- Do they raise the watch? Do the telegraphs register?
- When do they get bored?
- What do they think the rules are?
- In Night 2, do they let the stranger leave — and do they then *want* to speak?

**Ask afterwards:**

1. What was the scariest moment?
2. Was there a moment you felt cheated? **(Probe specifically: did the figure ever move while you were looking at it?)**
3. Did looking feel like a decision?
4. What did you think the bus was?
5. Which ending did you get, and did you want to see others?
6. Would you send a clip of any moment to a friend? Which one?

### Metrics

| Metric | Target |
| --- | --- |
| Time to first reaction | Under 2 minutes |
| Players who notice the lamp dimming while staring | 4 / 5 |
| Players who find the glance rhythm without being told | 3 / 5 |
| **Players who can state where the gaze boundary is** | **4 / 5** |
| **Players who report the figure moving while watched** | **0 / 5** |
| Players who read the timetable by Night 2 | 4 / 5 |
| Players who feel a fail was unfair | **0** |
| Idle stretches over 20 s with nothing to look at | none |
| Clean-run completion | 3 / 5 |
| Players who would clip or share a moment | 3 / 5 |

---

## 23. Release plan

Built around §4's conclusion: this game is discovered through clips, not through replay.

### Positioning

- **Lead with the gaze economy and the timetable, not the bus stop.** Store-page hero image: the timetable, or the numberless bus with its doors open on an empty lit interior. Not a silhouette at a bus stop (generic since 2022) and not a "stay in the light" framing (contested — §2).
- **One-line pitch** uses the mechanic half of §3.
- State the length (~25 minutes), the headphones requirement, and the three-night structure.
- Set the **"No generative AI was used"** tag. Both closest competitors advertise it; the AI-tagged entry in the space is the jam one.
- **Warnings:** flashing light, dark imagery, loud sudden audio.

### The three clip moments

~40% of weeks 7–9 go here. Each must work as a 6–10 second GIF with no context:

1. **The rain stops.** Weather fades over 6 s to near-silence. Cut it so the viewer's own room feels too loud.
2. **The stranger answers.** Ending 3. One held shot, one voice line.
3. **The numberless bus.** Doors open, lit interior, nothing inside. Hold longer than is comfortable.

Deliverables per moment: one 1080p GIF under 8 MB, one 6–10 s vertical crop for short-form, one still.

### Channels, in order

1. **itch.io**, free or pay-what-you-want (both closest competitors are PWYW or discounted). Primary. Tag `psx`, `horror`, `psychological-horror`, `short`, `atmospheric`, `first-person`, `multiple-endings`, `no-ai`, `low-poly`.
2. **The Haunted PS1 / PSX-horror itch community.** Real, active, runs jams and demo-disc compilations, precisely this game's aesthetic. **No open submission window was found on 5 Oct 2026 — check at release time.** Shipping into or adjacent to a jam window is the highest-leverage distribution move available.
3. **Creators.** Short horror is the most-covered indie genre on YouTube. Build a key/download list from week 8 and a **60–90 s trailer cut around one clip moment** (not a montage). Send in week 11 with a short note and a direct download — no keys needed for a free game, which removes all friction.
4. **Community posts** in release week: r/horror_games, r/itchio, r/IndieDev, r/godot (the Godot angle — a PS1-look game in Godot 4.7 with a documented attention economy — is its own post).
5. **Devlogs** at the end of weeks 4, 8 and 11. An hour each; they seed the itch page before launch.

### Steam — a decision, not a deadline

**Dates as of 5 October 2026:**

| Event | Dates | Reachable? |
| --- | --- | --- |
| Steam Next Fest, October 2026 | **19–26 Oct 2026** (upcoming, 14 days away) | **No.** |
| Steam Scream V Fest | **26 Oct – 2 Nov 2026** (upcoming, 3 weeks away) | **No.** |
| Steam Next Fest, February 2027 | **22 Feb – 1 Mar 2027**; registration closes **~10 Jan 2027**; demo build due **~25 Jan 2027** | First reachable window. |
| Steam Next Fest, June 2027 | ~Jun 2027 (three editions a year: Feb, Jun, Oct) | Comfortable. |
| Steam Scream Fest 2027 | ~late Oct 2027 (unconfirmed) | Comfortable. |

Twelve weeks from 5 Oct 2026 is **28 Dec 2026**; the realistic completion given §20's hours is **mid-Jan to mid-Feb 2027**. That makes the February Next Fest registration deadline (~10 Jan) effectively unreachable and the demo deadline (~25 Jan) very tight.

**Three constraints that change the calculus regardless:**

- A game may enter **Next Fest only once**. Spending the single entry on a 25-minute free-tier horror game is a real cost if you later expand it or ship your next title on Steam.
- The game must **not release on Steam before the fest ends.**
- Next Fest needs a **separate demo build** — roughly four weeks of additional work after the game is finished.

**Recommendation:** launch on itch and target the PS1-horror community. **Revisit Steam in December 2026** with a finished build and real itch numbers. If traction is strong and you intend to expand this game or ship a second title on Steam, spend the Next Fest entry on *that* — most likely the **June 2027** edition. Do not build toward 25 January as a deadline.

### Page assets

Looping hero GIF (clip moment 3), 5 screenshots — the lamp pool, the timetable, the fog figure at the edge of the light with its cone highlight, the numberless bus with its doors open, the poster in Night 3 state — plus the trailer and a short description leading with the pitch. **Check how the title renders truncated in itch's browse grid before committing** (§2).

### Builds and feedback

Export Windows first. Test the exported build on a second machine before release. Keep a link to a simple form or the itch comment thread for bugs.

---

## 24. Asset sourcing and licensing

| Need | Approach | Check |
| --- | --- | --- |
| Shaders | A PSX pack from §15 | Read the licence; some permissive, some paid |
| 3D models | Build the shelter and props from simple shapes | Keep source files |
| Textures | Hand-painted low-res, or free CC0 | Credit if required |
| Sounds | Record your own foley and voice; free libraries for beds | Licence per file, keep a spreadsheet |
| Fonts | A free pixel or typewriter font | Embedding allowed? |

**Rule:** if you cannot name the licence for an asset, do not ship it. Maintain a single `LICENSES.md` from day one and audit it in week 11.

**The "No generative AI was used" tag is a claim about your pipeline.** Keep the licence spreadsheet detailed enough to back it.

---

## 25. Decisions log and open questions

### Decisions in this document

| Decision | Reason |
| --- | --- |
| Working title *Thank You for Waiting* | Unclaimed, 21 characters (fits a store page), bureaucratic-transit register, no contested phrase, and it is the end card so the title pays off in the final frame. *Route 47* is the short-form alternative. "Please wait inside the light" stays as the timetable header line. (§2) |
| Differentiator is the gaze economy and the timetable, **not** light-as-safety | *Those Who Remain* (2020) and *Into The Light* (Steam, demo live) already own "stay in the light." Corrected from v1.2, which overstated it. (§2, §4) |
| Originality scored as premise 3 / mechanic 7, not one number | Only the mechanic belongs on the store page. (§4) |
| **Gaze death requires three gates: `gaze_lethal`, `armed`, `at_cap()`** | v1.2 had two and Night 1 killed at 22.3 s. Fairness rule 1 must be enforced in code. (§7, §18) |
| `at_last_station()` renamed `at_cap()` | The ambiguous name caused the bug. A name that can be misread will be misread again. (§18) |
| Night 1 / Night 2 safety tests stare for **60 s**, not to the first blackout | The weaker version passed while the bug was live. (§22) |
| "Watched" and "stared at" use one FOV-scaled cone | Closes the peripheral-vision exploit; keeps the watched fraction constant across the FOV slider. (§18) |
| **The cone boundary is made perceivable** (silhouette albedo highlight + hum partial, optional vignette) | The outer 59% of horizontal view counts as unwatched; an invisible core rule reads as cheating. Fairness rule 10. (§8) |
| Legibility beats ambiguity for the cone | Overrules v1.0's "never sure how fast it moves." Dread comes from the lamp draining, not from uncertainty about the boundary. (§8) |
| **The stranger leaves if you never speak** | Turns Rule 2 from an arbitrary prohibition into withheld information, so breaking it is a real temptation. (§9) |
| Slower drain at the cap (0.06/s) | The only creature-kill shouldn't take 7 s. (§18) |
| Fifth station inside the light, debug-gated (F8) | Fixes the one-sided endgame; ships only if playtest says dread, not unfair. (§7) |
| Ending 4 is terminal | Fairness rule 9: no ending may loop forever. (§10) |
| Ending 1 has two variants under one card | Two different deaths deserve two images; six slots is a cheap upgrade if week 11 has slack. (§10) |
| Night 1's sign warning does not advance the figure | Otherwise an early mistake exhausts Night 1's cap and neuters the 5:00 climax. (§9) |
| The stare lesson is an authored Night 1 beat at 2:30 | The week-4 gate tests the glance rhythm; it must be designed, not emergent. (§11) |
| Gaze loop in days 1–2; PSX look-dev in week 7 | Concept risk before art risk. A 2 h pack compatibility check stays in week 1 so the deferral isn't a late surprise. (§20) |
| Arriving earlier and waiting longer each night is intentional | Free lore: the loop is tightening. Do not align the start times. (§10) |
| No tension budget; authored beats always play | A budget could silently remove a rule test. (§13) |
| The bus arrival defines `real_seconds`; the clock hits 11:47 exactly then | The premise is that the bus comes at 11:47. (§11) |
| Constant clock tempo (~25 s per in-game minute) | The watch is a telegraph device, so the tick rate must be stable. (§11) |
| `max_distance = 32`, matching the fog end | Never "watch" something you cannot see. (§18) |
| Sight layer excludes glass, the pole and thin props; 3-ray fan | A thin edge must not fake occlusion. (§14, §18) |
| `_live` keyed by the event instance | Two instances of one resource can't collide and defeat intensity-2 exclusivity. (§18) |
| Interaction ray masks layer 3 only | Glass has collision and must not block interaction. (§8) |
| `BusRig` is in §18 and `EventContext.bus` is typed to it | The reference build showed `EventContext` referencing a class the document never defined — a compile error the moment anyone built it. (§18) |
| `Interactable` extends `StaticBody3D` | `ray.get_collider()` returns the body, so the body must be the Interactable. Found by building the game, not by reading. (§18) |
| Build node subtrees detached, then add the root | `@onready` resolves at tree entry; adding children afterwards nulls every `@onready` var. (§18) |
| A dedicated Weather bus is faded for the silence beat | Never overrides the player's volume settings. (§16, §18) |
| Forearms in a yellow raincoat; diegetic digital watch | Gives the poster payoff a visible jacket and the watch a cost. (§8) |
| The bus door is just outside the light, 1.5 m reach, 1 s hold | Boarding becomes a deliberate walk into the dark. (§14) |
| The numberless bus is empty; the real bus is full | The clean ending becomes the scariest. (§10) |
| One processed voice for radio, payphone and stranger | Cheaper, and gives Ending 3 its payoff. (§16) |
| Design for shareable moments, not replay | Replayability is honestly 4/10. (§4) |
| itch + the PS1-horror community first; Steam is a December 2026 decision, most likely June 2027 | One Next Fest entry only; October 2026's windows are 14 and 21 days away and unreachable. (§23) |
| Depth fog, not volumetric | Better fit for the PS1 look, cheaper, available since 4.3. Verified in 4.7 source. (§15) |
| Whole game at low resolution (Option A) | Simpler than a sub-viewport pipeline. (§15) |
| Walk speed 1.8 m/s | 1.4 is realistic but too slow for a game. (§8) |
| **Lamp flicker clamped to 0.36–0.70 s per cycle (1.43–2.78 Hz)** | The accessibility limit has to hold in the *default* setting, not only behind an option or a store-page warning. v1.3's 0.09–0.32 s cycles breached it on every roll. (§17, §18) |
| **§22's death-timing windows are deliberately tight (±0.6 s)** | A 30–42 s window passed three separate broken variants of the drain logic. A check that can't fail is worse than no check — that is the same failure mode as v1.2's first-blackout stare test. (§22) |
| `figure_cap_index` / `cap_index`, with a mapping table in §14 | 0-based code and 1-based prose in the same system invite an off-by-one on every edit. Spell the mapping out once. (§14) |
| **No code block in this document may be labelled "excerpt"** | Two such blocks did not compile, and they were the first files a developer touches. Everything in §18 is complete and parse-checked. (§18, §22) |
| **The HUD couples to `PlayerInteraction` by signal, not by reference** | No HUD class has to exist for the interaction script to compile, and it keeps §17's minimal-UI rule honest. (§17, §18) |
| **No event may overlap an instance of itself** | Two concurrent E1s would each drive the lamp and could double the flicker rate past the 3 Hz accessibility limit — the clamp inside E1 cannot defend against it alone. Verified: 3 assertions. (§13, §18, §22) |
| **Parse-all is the first automated check** | `--import` scans `class_name` only and `--check-only` lacks autoloads; neither covers every file. (§22) |
| **Bus arrivals are `punctual` beats that bypass all pacing rules** | Measured +15.02 s late without it, in every night, because the approach beat's calm window covers the arrival instant. Fairness rule 4 depends on it. (§11, §13, §18) |
| **`MIN_CYCLE = 0.45`, not 0.36** | 0.36 measured a 0.332 s cycle = 3.01 Hz at runtime, over the 3.00 Hz limit. Nominal arithmetic hid it; execution found it. (§17, §18) |
| **The flicker check measures, it does not compute** | Computing the rate from the constants is what produced the false PASS. Same failure mode as v1.2's first-blackout stare test. (§22) |
| **A headless Godot test project ships with the repo from week 1** | It is the only thing that caught either v1.6 defect, and it costs ~2 h. Static review of this document missed both. (§0, §20, §22) |
| One-line `class_name X extends Y` retained | Valid in all of Godot 4 (parser comment: "Allow extends on the same line"). Recorded in §0 so it isn't "fixed" later. (§18) |
| E6 + ~3 voice lines are load-bearing for **Rule 2**, not just Ending 3 | Without the E6 → E7 → Ending 3 chain, Rule 2 collapses into a generic don't-talk-to-strangers prohibition. Non-verbal fallback specified rather than dropping the chain. (§9) |

### Open questions

1. **Title** — confirm *Thank You for Waiting* after a manual itch/Steam/YouTube search; *Route 47* is the fallback if its creepypasta adjacency checks out clean. Check truncation in itch's browse grid.
2. **Voice** — record your own ~12 lines, or use the non-verbal fallback in §9? **This is now a blocking question, not a preference:** E6 and ~3 lines are load-bearing for Rule 2 as well as Ending 3, so if you are not recording voice, build the fallback into week 5 rather than discovering the gap in week 9.
3. **Region and period** — unnamed, or commit? "END OF SERVICE" and a route-number blind read UK/Commonwealth; a destination board naming a stop reads North American. Pick one — it drives the bus model.
4. **Gamepad support** — needed for release, or keyboard and mouse only?
5. **Price** — free, PWYW, or a small fixed price? Both closest competitors are PWYW or discounted.
6. **Localisation** — `Label3D` for the timetable and sign, never baked texture text.
7. **Hardware target** — weakest machine you want supported? Drives the Compatibility-renderer decision in week 1.
8. **Hold-to-confirm accessibility** — is press-instead-of-hold worth the work for release? It's in §17's options; confirm or cut.
9. **The breach rule** — ship the fifth station or cut it? Decide from week-4 and week-10 playtest, not now. Debug-gated either way.
10. **Cone legibility layers** — does the silhouette highlight + hum partial suffice, or does the vignette need to be default-on? Week-4 A/B, judged in-engine, not from the code.
11. **Six ending slots or five with variants?** ~20 minutes of work; decide in week 11.

---

## 26. References

**Godot and technical**

- Ray-casting; why direct space state access belongs in `_physics_process`: https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
- Pausing games and `process_mode`: https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
- `Camera3D` (`is_position_in_frustum`, `fov`, `keep_aspect`): https://docs.godotengine.org/en/latest/classes/class_camera3d.html
- `Area3D` (overlap lists update once per physics step): https://docs.godotengine.org/en/stable/classes/class_area3d.html
- Resolution scaling (`Viewport.scaling_3d_scale`, `scaling_3d_mode`): https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html
- Depth fog (fog modes added in Godot 4.3): https://github.com/godotengine/godot/pull/84792
- `Environment` fog properties verified in source (`fog_mode` Exponential/Depth, `fog_depth_begin/end/curve`): https://github.com/godotengine/godot/blob/4.7-stable/scene/resources/environment.cpp
- Volumetric fog and fog volumes (Forward+ only): https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html
- `VisibleOnScreenNotifier3D`: https://docs.godotengine.org/en/latest/classes/class_visibleonscreennotifier3d.html
- Audio effects (low-pass, reverb, compressor, Area3D reverb buses): https://docs.godotengine.org/en/stable/tutorials/audio/audio_effects.html
- 3D audio and spatial sound guide: https://uhiyama-lab.com/en/notes/godot/3d-audio-spatial-sound/
- `SceneTree.create_timer(delay, process_always, …)` verified in source: https://github.com/godotengine/godot/blob/4.7-stable/scene/main/scene_tree.cpp
- `Node.find_children` resolves global script class names via `ScriptServer::is_global_class`: https://github.com/godotengine/godot/blob/4.7-stable/scene/main/node.cpp
- Godot 4.7-stable released 18 June 2026: https://godotengine.org/download/archive/

**PS1 look**

- Godot PSX style demo: https://github.com/MenacingMecha/godot-psx-style-demo
- PSX Visuals, GD4 port: https://www.godotengine.org/asset-library/asset/4687
- Ultimate Retro Shader Collection: https://store.godotengine.org/asset/zorochase/ultimate-retro-shader-collection/
- Retro Shaders Pro: https://danielilett.itch.io/retro-shaders-pro-for-godot

**Market and release**

- *Last Bus Home*: https://majikdev.itch.io/last-bus-home · RAWG (release date 18 Jun 2022): https://rawg.io/games/last-bus-home
- *The Fields*: https://fenixapple.itch.io/the-fields
- *The Cornfield Road*: https://eerie-shadow.itch.io/the-cornfield-road
- *Last Bus Stop*: https://martinmakes.itch.io/last-bus-stop
- *Night Bus* (GURDE): https://gurd62.itch.io/night-bus
- *The stranger from the bus stop*: https://daijubudef.itch.io/the-stranger-from-the-bus-stop
- *Into The Light* (Steam, "stay in the light… new rules"): https://store.steampowered.com/app/1427040/Into_The_Light/
- Haunted PS1 community: https://hauntedps1.itch.io/
- Steam Next Fest February 2027 (22 Feb – 1 Mar; registration ~10 Jan; demo due ~25 Jan): https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027
- Steam Next Fest October 2026 (19–26 Oct): https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/2026october
- Steam Next Fest hub (Feb/Jun/Oct each year): https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest
- Steam Scream V Fest (26 Oct – 2 Nov 2026): https://www.steampageanalyzer.com/blog/steam-halloween-sale-2026

**Horror design**

- P.T. and designing with limited assets (loops, walking speed, constraint): https://www.kokutech.com/blog/gamedev/design-patterns/unique-mechanics/pt-silent-hills
- Psychological horror, silence and atmosphere: https://altheragames.com/en/blog/psychological-horror-game-design
- Horror level design, tension and gameplay loops: https://www.gamedeveloper.com/design/creating-horror-through-level-design-tension-jump-scares-and-chase-sequences
- Horror design, noise versus silence, pausing: https://gamedesignskills.com/game-design/horror/
- Pacing and building tension: https://www.gamedev.net/blogs/entry/2274395-how-to-use-pacing-and-build-tension-in-a-horror-game/
- Level design, fear loops and sound: https://www.algoryte.com/blogs/the-art-of-fear-secrets-of-horror-game-level-design/
- *The Exit 8* and the anomaly-game genre context: https://en.wikipedia.org/wiki/The_Exit_8

**Process**

- Concept stress test adapted from the creative-director skill (insight statement, one-sentence idea, anti-cliché and "kill your darlings" tests).
- Title and premise collision check run 5 October 2026, re-verified against live pages the same day (Appendix A).

---

## Appendix A — competitor detail and research method

**Method.** Web search plus direct fetches of itch.io, Steam and RAWG pages, 5 October 2026. All figures re-verified against live pages after an initial draft. itch's search is poor and Steam's is worse for short free games, so this is a strong sample, not an exhaustive census.

**Known limits.** Rating and comment counts drift between fetches (e.g. *Last Bus Home* showed 335 ratings on first fetch, ≈331 on re-check). itch's "Updated" field is **not** a release date — reading it as one produced a wrong "recent release" claim in the v1.2 report. Where a release date mattered it was taken from RAWG. One scraped forum page in the results contained a stray embedded test string; it was not treated as instruction and nothing here derives from it.

### Last Bus Home — majik

[majikdev.itch.io/last-bus-home](https://majikdev.itch.io/last-bus-home)

> "You find yourself approaching a bus stop; it's late at night and the next bus to arrive is also the last one for today, and you don't want to miss it."

Released **18 June 2022** (RAWG). Unreal Engine + Blender + GIMP + Audacity. Windows and macOS, 82 MB, ~16 min. Name your own price. **4.0/5, ≈331 ratings, 474 comments.** Tags: 3D, Atmospheric, Creepy, First-Person, Horror, Low-poly, Multiple Endings, Short, Singleplayer, Spooky. Content tag: *No generative AI was used*. YouTube coverage includes an "ALL ENDINGS" walkthrough.

Representative comments: *"The very real horror of waiting for the bus next to a creep… achieved all three endings + the secret one within like fifteen minutes"*; *"I think I was weirder to the stranger than the stranger was to me, but hey, I got all the endings!"*; *"im surprised i was patient enough to stay."*

RAWG's aggregated user sentiment is "Meh" — a notable divergence from its 4.0 on itch. Read as: aggregator audiences and itch short-horror audiences score the same game very differently.

**Why it matters:** closest premise match, four years of comment history, and direct evidence that "waiting for the last bus while a stranger appears" is an audience-validated shape. It does not have a multi-night loop, written rules, a gaze economy or a silence beat.

### The Fields — Fenixapple

[fenixapple.itch.io/the-fields](https://fenixapple.itch.io/the-fields)

> "This game is about a man who missed his last bus while trying to get home. What he will do?" · "You can get 3 different endings!"

**$2, currently 100% off** (the page header displays "Name your own price"). Windows, 48 MB. **4.3/5, 59 ratings, 80 comments.** Made in one day as a self-challenge. Tags: 3D, Atmospheric, First-Person, Horror, **PSX (PlayStation)**, **Psychological Horror**, Retro, Scary, **No AI**. Voice acting credited: Main Character (AngrierTravis), **Stranger** (Evan Packard). Features listed as voice acting, 3 endings, "Atmospheric PSX environment", "Old sound design". Same developer now has *Fractured: Snowpine Strangers* on Steam.

**Why it matters:** the PSX intersection specifically — missed last bus, PSX look, voice-acted stranger, multiple endings. Jam-scale (one day, 48 MB), so it competes on premise rather than depth.

### Others

| Game | Detail |
| --- | --- |
| **The Cornfield Road** — shadow | Short PSX-style horror, multiple endings, 5–10 min. Published ~Aug 2026, 162 comments, YouTube playthroughs. The most recent genuine PSX neighbour. |
| **Last Bus Stop** — martinmakes | Released ~Jun 2026. "A reporter curious about a bus stop in the middle of nowhere"; explores an abandoned city; "stay alive and reach the bus." 10–15 min, PWYW, 185 MB, Psychological Horror / Short. Sprint + flashlight. Title collision, different premise. |
| **Night Bus** — GURDE | Tagline: "Can you survive waiting for the bus?" PWYW. Surfaces on itch's `no-AI` + `PSX` browse pages. |
| **The last passenger** — byronrosas | LumenJam entry. "Survive the night bus ride **by staying in the light**. But beware… not everything on this route is what it seems." AI-assisted / AI-generated tags. |
| **The stranger from the bus stop** — Daijubudef | Ren'Py browser VN. Tags include Creepy, Dating Sim, **Psychological Horror**, Romance. Phrase collision, not a competitor. |
| **Bus Stop** — PistolSol | Interactive fiction: "People Tend to Open up to Strangers at Bus Stops." Exact-title collision, different medium. |
| **End Of Service** — MichelleS | Interactive fiction: "Optimise a world out of existence." Exact-title collision; phrase also dominated by gacha/MMO shutdown usage. |
| **Into The Light** — 2L Games (Steam) | Unreleased, demo live. "Stay in the light, beware of the dark. Survive as Damien in a strange world with **new rules** and horrific residents." The most important prior-art find: light-as-safety **plus** rules, actively marketed on Steam. |
| **Those Who Remain** (2020) | First-person psychological horror built on staying in the light or losing sanity. Established prior art for the mechanic. |
| Also present | *The Midnight Bus* (itandfeel), *Waiting For The Bus* (lostwaysclub), *Night Bus* ($4.99, different dev), *Speed Dating (on) the Night Bus*, *The Last Passenger* (VoidFlare Studio). |

### Search queries used

itch/Steam PSX horror bus stop and last-bus premises · exact-title searches for *Bus Stop*, *Route 47*, *Last Bus*, *End of Service*, *Thank You for Waiting*, *Please Wait Inside the Light* · itch tag browse (`psx` + `horror`, `no-AI` + `PSX`, `bus`, `multiple-endings` + `simulation`) · "stay in the light" horror prior art · Haunted PS1 community and jam windows · Steam Next Fest and Scream Fest 2026–27 dates.

### Still to do manually before committing to a title

1. itch.io search: title + tags `psx`, `horror`, `short`.
2. Steam store search: title.
3. YouTube search: title.
4. Haunted PS1 community pages and any current jam entry lists.
5. Render the title in your pixel font at 640×360 and in itch's browse grid to check truncation.

---

*End of document — v1.9. Next step: §20 "First three days" — greybox, fog, rain, and the gaze loop against a capsule, with all three gates wired, the three arrival beats marked `punctual`, and the §22 checks — including the measured flicker rate and arrival punctuality — passing in a headless run. Then play Last Bus Home. Then bring back what the greybox and three playtesters tell you.*
