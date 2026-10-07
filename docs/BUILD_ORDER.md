# BUILD ORDER

How to actually build this, file by file, from an empty project to a shipped game.
Derived from GDD §20 (production plan), §22 (testing) and the v1.9 lessons in GDD §0.

**The one rule that overrides everything else: a playable build at the end of every week.**
GDD §0 records four defects that were invisible in review and obvious in the first sixty
seconds of play. You cannot review your way to a working game; you have to press Play.

---

## Phase 0 — before you write a line of code (~1 evening)

| # | Task | Why |
| --- | --- | --- |
| 1 | Install **Godot 4.7 stable** (or the newest 4.x you have). Open `bus-stop-game/` with `project.godot` | The GDD is checked against the 4.7 API. Depth fog needs 4.3+ |
| 2 | `git init && git add -A && git commit -m "project skeleton"` | GDD 19: commit at the end of every session |
| 3 | Confirm Project Settings shows **6 named physics layers**, **17 input actions**, **4 autoloads**, and the 9-bus layout in the Audio bus editor | These are the two things the first pass shipped without |
| 4 | **Play *Last Bus Home*** (majik, itch, PWYW, ~16 min) and read its 474 comments | GDD 2: better market research than the document itself |
| 5 | **Decide the voice question (GDD 25 Q2)** — record ~12 lines, or the non-verbal fallback | It is **blocking**, not a preference. E6 + ~3 lines are load-bearing for Rule 2. If you're not recording, build the fallback in week 5 |
| 6 | Decide region/period (GDD 25 Q3) — UK/Commonwealth vs North American | It drives the bus model. Cheaper to decide now than in week 8 |

Then run the parse-all test on the empty project to prove the harness works:
it should report 3/3 (`data/*.gd`) and exit clean.

---

## The compile order

Write scripts in **dependency order** so the project is never broken between saves.
`class_name` types must exist before anything references them.

```
1.  data/horror_event.gd          ✓ done     (no deps)
2.  data/beat_def.gd              ✓ done     (no deps)
3.  data/night_def.gd             ✓ done     (no deps)
4.  world/lamp_controller.gd                 (no class deps)
5.  core/look_at_tracker.gd                  (no class deps)
6.  world/fog_figure.gd                      → LookAtTracker
7.  world/night_clock.gd                     → NightDef
8.  world/gaze_monitor.gd                    → LookAtTracker, FogFigure, LampController, Game
9.  world/bus_rig.gd                         (no class deps)
10. player/interactable.gd                   (no class deps)
11. player/interaction.gd                    → Interactable
12. core/event_context.gd                    → LampController, FogFigure, NightClock,
                                               LookAtTracker, BusRig   ← must come AFTER all five
13. events/event_base.gd                     → EventContext
14. core/game.gd, save.gd, settings.gd, audio_hub.gd    (autoloads)
15. core/director.gd                         → HorrorEvent, BeatDef, NightDef, EventBase, EventContext
16. world/sign_line.gd, rain.gd, night_clock scene wiring
17. player/player.gd, player_camera.gd, tether.gd, footsteps.gd
18. ui/hud.gd, hold_ring.gd, prompt.gd
19. main.gd                                  → everything
```

Note step 12: `EventContext` is the single file that ties the whole architecture together,
which is why v1.8's reference build hit a compile error the moment it referenced a class
the document hadn't defined. Create the five world/player classes first, then `EventContext`.

---

## Week 1 — the concept, in two days

**Already written:** `core/game.gd` · `core/save.gd` · `core/settings.gd` ·
`core/audio_hub.gd` · `core/debug_kit.gd` · `world/lamp_controller.gd` · `world/rain.gd` ·
`player/player.gd` · `player/player_camera.gd` · `player/tether.gd` · `data/*.gd` ·
`tests/parseall` · `tests/harness/assert_kit.gd` · all seven greybox scenes.

**Still to write this week:** `core/look_at_tracker.gd` · `world/fog_figure.gd` ·
`world/gaze_monitor.gd` · `tests/test_weather_bus.gd` · `tests/test_layers.gd`

### Day 1 — a grey box you can stand in  *(already authored — see `docs/DAY1.md`)*
Items 1–6 below exist as real scenes: `main.tscn`, `world/road.tscn`, `world/bus_stop.tscn`,
`world/figure_stations.tscn`, `world/fog_figure.tscn`, `world/rain.tscn`, `player/player.tscn`.
Day 1 is therefore **verification**, not construction: check the layers, walk it, fix what
feels wrong by dragging nodes in the viewport.
1. Greybox the shelter, road and signpost at the **GDD §14 coordinates** (lamp at origin,
   shelter 0→3 m, bin 3.5, bus door 8.5, sign line 10.5, stations −26/−19/−13/−9/−5).
   Boxes only. **With collision** — `StaticBody3D` on layer 1 for every surface.
2. `world_environment.tres`: depth fog 4→32 m, curve 1.2, fog `#101820`, ambient `#0b1220`.
3. The lamp: one `OmniLight3D`, range 6.5 m, warm sodium. `lamp_controller.gd` on it.
4. `rain.tscn` + a `GPUParticlesCollisionBox3D` on the shelter roof.
5. `player.gd`: `CharacterBody3D`, 1.8 m/s, no sprint, group `player`, layer 2 / mask 1.
   `tether.gd`: soft push from 12 m, hard wall at 14 m.
6. All six physics layers named and assigned. **2 h PSX pack compatibility check only** —
   does your shader approach coexist with depth fog and an `OmniLight3D`? No look-dev.

### Day 2 — the gaze loop (this is the entire game)
7. `look_at_tracker.gd` — cone (`CONE_FRAC 0.41`), distance 32 m, 3-ray fan, mask 32.
8. A **capsule** at station 0 (x = −26) standing in for the figure. `fog_figure.gd`.
9. `gaze_monitor.gd` with all **three gates**.
10. Test by hand: stare → lamp dims, hum pitch falls. Look away 1.5 s → the capsule steps
    to 19 m. Set `gaze_lethal = false` and confirm **you cannot die**. Set it true with
    `armed` forced (F9) and confirm you can.

### Day 3
11. Audio buses live; a looping rain sound on the Rain bus.
12. `debug_kit.gd` — at minimum F1 (state dump), F4 (draw the cone and the sight rays),
    F7 (set the figure's station), F9 (force the gates).
13. `tests/parseall`, `tests/test_weather_bus`, `tests/test_layers`.

> **Week-1 exit criteria:** you can walk the greybox, and staring at a capsule dims the
> lamp while looking away lets it advance. **The whole concept in two days.**

---

## Week 2 — the clock, the hands and the HUD

**Files:** `world/night_clock.gd` · `data/nights/*.tres` · `player/interactable.gd` ·
`player/interaction.gd` · `player/player_camera.gd` · `player/watch.gd` ·
`player/footsteps.gd` · `player/head_bob.gd` · `world/timetable.gd` ·
`world/shelter_reverb.gd` · `core/save.gd` · `ui/hud.gd` · `ui/hold_ring.gd` ·
`ui/prompt.gd` · `ui/title_card.gd` · `ui/theme/theme.tres` + `pixel_font.ttf` ·
`ui/menus/pause_menu.tscn` · `tests/test_clock` · `test_night_flags` · `test_interaction_mask`

> **Exit:** the clock reaches exactly 11:47 at arrival; a 1 s hold works; the lean-in
> cancels on a big event; the HUD has a real font.

---

## Week 3 — the Director and the first three events

**Files:** `core/event_context.gd` · `core/director.gd` · `events/event_base.gd` ·
`e01_lamp_flicker` · `e02_distant_engine` · `e03_gravel_footsteps` ·
`data/events/e01..e03.tres` · `data/pools/fill_night1.tres` ·
`tests/test_beat_ordering` · `test_cone_fov` · `test_flicker_rate` · `test_highlight_tracks_cone`

The silhouette highlight goes in this week and **must be confirmed in-engine, not in code**
(GDD risk 16: the rim-lighting version was boolean-correct and invisible).

> **Exit:** Night 1's beats run and feel fair; the highlight is visibly confirmable.

---

## Week 4 — VERTICAL SLICE, and the hard go/no-go

**Files:** `world/sign_line.gd` · `world/bus_rig.gd` · `events/e04_figure_step` ·
`events/s1_passing_bus` · `data/events/e04,s1.tres` · `data/nights/night_1.tres` (complete) ·
`main.gd` · `main.tscn` · the 5 stations + breach behind F8 ·
`tests/test_night1_cannot_kill` · `test_night1_sign` · `test_stations` · `test_no_free_band` ·
`test_arrival_punctuality` · `test_same_event_exclusion` · `test_night_start_state` · `test_restart`

> **Exit:** Night 1 playable start to finish. Run the **60 s stare test on all three nights.**
> Three fresh people test the glance rhythm and the cone legibility. **If it isn't fun or it
> reads as cheating, stop and redesign before making any art.**

Mark every bus arrival beat `punctual = true` or it lands +15.02 s late, every night.

---

## Weeks 5–12

| Week | Files | Exit |
| --- | --- | --- |
| **5** | `world/stranger.gd` · `events/e05_timetable_change`, `e06_bin_radio`, `e07_bench_stranger`, `e10_signpost_lure`, `s2_numberless_bus` · `world/lure.gd` · `world/poster.gd` · `data/endings/*` · `data/ending_def.gd` · `ui/ending_card.gd` · `ui/menus/main_menu`, `endings_menu`, `content_note` · `tests/test_night2_*` | Night 2 playable; Endings 1-sign / 2 / 3 reachable |
| **6** | `events/s3_silence_real_bus`, `s4_bus_interior` · `models/bus_interior` · `textures/notice_boarded.png` · Night 3 beats + `gaze_lethal` · `tests/test_night3_gaze_timing`, `test_three_gates`, `test_pause`, `test_no_infinite_ending` | **The full game is completable, all five endings reachable** |
| **7** | `shaders/psx.gdshader`, `shaders/post.gdshader` · resolution/stretch check · palette · dither pass (Godot's fog doesn't dither) · TAA/MSAA confirmed off | It looks like the reference screenshots you want |
| **8** | `models/*` · `textures/*` · poster ×3 · UI art · lighting. **The three clip moments first (~40% of the week):** the rain stops · the stranger answers · the numberless bus | Cohesive; the three clip moments excellent |
| **9** | `audio/*` — foley, **the one voice (~12 lines)**, mix, the hum's pitch gauge **and the gaze partial**, tune the silence beat · `ui/caption.gd` (directional) | It sounds finished |
| **10** | `core/settings.gd` · `ui/menus/options_menu` · `ui/cone_vignette.gd` · credits · save · playtest round 2 · tuning (`docs/TUNING.md`) | No known soft-locks; options and captions work |
| **11** | Export presets · second-machine test · store page · trailer GIFs · `LICENSES.md` audit | Release candidate |
| **12** | Buffer · final playtest · release | Released |

**Honest arithmetic (GDD §20):** 137–204 h of scope at 8–10 h/week is **15–23 weeks**, not 12.
Close the gap by executing cut-list items 1–2 (**E8 glass reflection**, **E9 payphone**)
**now, not in week 8**, and plan the release around week 14–16.

---

## Every session, without exception

```bash
# 1. the parse-all check — run it before believing any other result
godot --path . tests/parseall.tscn --headless

# 2. the whole suite
./tests/run_all.sh

# 3. press Play and stand in the light for two minutes

# 4. commit
git add -A && git commit -m "..."
```

And after **any** change to the gaze, lamp or figure code: stare at the figure for a full
minute in Nights 1 and 2. That is the regression that shipped once already.
