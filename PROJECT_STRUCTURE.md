# PROJECT STRUCTURE — *Thank You for Waiting*

Every folder and file this game needs, derived from **`docs/GDD_v1.9.md`**. Each entry
carries the GDD section it comes from and the week to build it in (GDD §20).

Legend: **[DONE]** = already created in this repo · **W1…W12** = build week ·
**CUT** = on the cut list, don't build it unless you're ahead of schedule.

**Status right now:** the project boots, and **day 1 is built**. `project.godot`, the 9-bus
audio layout, the three `data/` resource classes, all four autoloads, `debug_kit.gd`, the
lamp, the rain, the player (body + camera + tether), the parse-all test and `tests/run_all.sh`
are written — and the greybox exists as **seven authored scenes** (`main`, `road`,
`bus_stop`, `figure_stations`, `fog_figure`, `rain`, `player`) with every wall, post, bench
and marker a real node you can select and move in the editor. Nothing is generated at
runtime. **Start at `docs/DAY1.md`.**

---

## 1. The tree

```
bus-stop-game/                              # res:// — the Godot project root
│
├─ project.godot                            [DONE]  GDD 19 — renderer, 640x360 viewport stretch,
│                                                   full input map, 6 named physics layers, 4 autoloads
├─ icon.svg                                 [DONE]
├─ .gitignore                               [DONE]  GDD 19
├─ .editorconfig                            [DONE]  .gd and .gdshader are TAB-indented
├─ README.md                                [DONE]
├─ LICENSES.md                              [DONE]  GDD 24 — one row per asset, from day 1
├─ PROJECT_STRUCTURE.md                     [DONE]  this file
│
├─ main.tscn                                [DONE]  day-1 stub: Greybox + Player + DebugKit.
│                                                   Grows into the full GDD 18 tree in W4
├─ main.gd                                  W4      GDD 18 "Running a night" — complete in the doc
│
├─ docs/
│  ├─ GDD_v1.9.md                           [DONE]  the single source of truth
│  ├─ BUILD_ORDER.md                        [DONE]  week-by-week sequence
│  ├─ DAY1.md                               [DONE]  **start here** — today's checklist
│  └─ TUNING.md                             W4      every number you will change in playtests
│
├─ addons/                                  empty unless you install a PSX pack (GDD 15).
│                                           GDD v1.9 item 4 replaces the pack with two own shaders.
│
├─ core/                                    autoloads + shared systems
│  ├─ game.gd                     (Game)    [DONE] GDD 18 — State{MENU,NIGHT,ENDING}, endings_seen,
│  │                                              trigger_ending(); ignores duplicate/out-of-night calls
│  ├─ save.gd                     (Save)    [DONE] GDD 18 — ConfigFile at user://save.cfg
│  ├─ audio_hub.gd                (AudioHub)[DONE] GDD 16/18 — silence_beat(), restore_weather(), reset();
│  │                                              asserts the Weather bus exists, kills overlapping fades
│  ├─ settings.gd                 (Settings)[DONE] ADDITION (D3) — every option in GDD 17 needs a home
│  ├─ look_at_tracker.gd   (LookAtTracker)  W1   GDD 18 — the cone + 3-ray fan. ONE boundary for
│  │                                              "watched" and "stared at" (fairness rule 8)
│  ├─ event_context.gd        (EventContext)W3   GDD 18 — typed refs: lamp, player, figure, clock,
│  │                                              tracker, bus, hud, world. Missing ref = loud failure
│  ├─ director.gd                  (Director)W3  GDD 13/18 — authored vs fill, pacing rules,
│  │                                              _live keyed by INSTANCE, punctual beats
│  └─ debug_kit.gd                 (DebugKit)[DONE] ADDITION (D4) — F1…F10 from GDD 13. Week 1, not week 9
│
├─ data/                                    Resource classes + all authored content
│  ├─ horror_event.gd            HorrorEvent [DONE] W1   GDD 18
│  ├─ beat_def.gd                BeatDef      [DONE] W1   GDD 18 — Kind{AUTHORED,FILL}, punctual
│  ├─ night_def.gd               NightDef     [DONE] W1   GDD 18 — real_seconds, caps, lethal flags,
│  │                                                       start_minute(); station mapping in the comments
│  ├─ ending_def.gd              EndingDef    W5   ADDITION (D5) — id, variant, card lines, vignette
│  ├─ events/                                W3   14 .tres: e01…e10, s1…s4
│  ├─ nights/                                W2   night_1.tres, night_2.tres, night_3.tres
│  ├─ pools/                                 W3   fill_night1/2/3.tres — Array[HorrorEvent]
│  └─ endings/                               W5   5 .tres: out_of_the_light, wrong_bus, spoke_first,
│                                                      still_waiting, right_bus
│
├─ player/
│  ├─ player.tscn                           W1   see §4
│  ├─ player.gd                             [DONE] GDD 8 — CharacterBody3D, 1.8 m/s, no sprint,
│  │                                              group "player", collision layer 2, mask 1
│  ├─ player.tscn                           [DONE] see §4
│  ├─ player_camera.gd                      [DONE] GDD 8/17 — mouse look, FOV 75 (adjustable, the cone
│  │                                              scales with it), lean-in narrows FOV, locks movement
│  ├─ head_bob.gd                           W2   GDD 8/17 — optional, toggled from Settings
│  ├─ footsteps.gd                          W2   GDD 8 — concrete under the shelter, gravel on the verge
│  ├─ tether.gd                             [DONE] GDD 8 — soft push-back from 12 m, hard wall at 14 m
│  │                                              from the shelter centre. ALSO owns the sign-line
│  │                                              push-back, which must displace over frames (never teleport)
│  ├─ interaction.gd          PlayerInteraction W2 GDD 18 — tap vs hold dispatch, lean-in for group
│  │                                              "readable", cancel_lean(), 3 signals to the HUD
│  ├─ interactable.gd           Interactable W2   GDD 18 — extends **StaticBody3D**, layer 3, per-object
│  │                                              max_reach, hold_seconds is a DURATION not an enum
│  └─ watch.gd                              W2   GDD 8 — pale-yellow raincoat forearms + LCD time from
│                                                 NightClock; 3 telegraph states (colon blink/stop/flicker)
│
├─ world/
│  ├─ world_environment.tres                [DONE] GDD 15/19 — depth fog 4→32 m, curve 1.2,
│  │                                              fog #101820, ambient #0b1220, NO volumetric fog
│  ├─ bus_stop.tscn                         [DONE] GDD 14 — authored greybox: shelter (roof, back
│  │                                              wall, posts, glass, bench) with walls+roof+bench
│  │                                              back on layers 1 AND 6 and glass on layer 1 ONLY;
│  │                                              RoofRainCollision; the Lamp rig; Bin; Payphone;
│  │                                              Timetable + Poster Label3Ds; SignPost; the SignLine
│  │                                              Area3D + debug wall; ShelterReverb; BusStopCentre.
│  │                                              bus_stop.gd (props/state) arrives in W2
│  ├─ road.tscn                             [DONE] GDD 14 — ground collider, 7 m road, kerb,
│  │                                              centre-line dashes, 16 treeline billboards 32–46 m out
│  ├─ lamp_controller.gd      LampController [DONE] GDD 18 — level, drain/recover/relight/reset,
│  │                                              set_flicker(), scripted_dark(); hum pitch = the audio tell
│  ├─ figure_stations.tscn                  [DONE] GDD 14 — the five station Marker3Ds at
│  │                                              x = −26/−19/−13/−9/−5 (z = −2), group
│  │                                              "figure_station", + debug spheres and billboarded
│  │                                              tags naming each cap. Delete the Markers node in W8.
│  │                                              Lives in the WORLD, not under FogFigure: the
│  │                                              figure moves, the anchors must not
│  ├─ fog_figure.tscn                       [DONE] capsule placeholder at station 1, near-black
│  │                                              UNSHADED material (GDD 18 base_albedo). The
│  │                                              silhouette mesh replaces it in W2
│  ├─ fog_figure.gd               FogFigure  W1  GDD 18 — stations, cap, unwatched timer, breach,
│  │                                              albedo highlight (NOT rim — invisible when unshaded)
│  ├─ gaze_monitor.gd            GazeMonitor W1  GDD 18 — grace 2 s, 0.10/s, 0.06/s at cap,
│  │                                              recover 0.20/s, and the THREE gates
│  ├─ night_clock.gd              NightClock W2  GDD 18 — minute_changed, arrived, freezes at 11:47
│  ├─ sign_line.tscn / sign_line.gd         W4   GDD 18 — Area3D at x=10.5, ~1 m thick, 24 m wide,
│  │                                              6 m tall, layer 0 / mask layer 2; warned vs lethal;
│  │                                              check_initial_overlap() waits two physics frames
│  ├─ rain.tscn                             [DONE] GDD 15 — GPUParticles3D, 1200 particles,
│  │                                              collision_mode ON, process material + streak quad
│  ├─ rain.gd                               [DONE] GDD 15/18 — top_level = true,
│  │                                              follows the PLAYER (not the camera), target null-guarded
│  ├─ bus_rig.tscn / bus_rig.gd     (BusRig) W4  GDD 18 — pass_by, arrive, open/close_doors, depart,
│  │                                              reset, set_board, interior light. @onready paths below
│  ├─ stranger.tscn / stranger.gd           W5   GDD 9/12 E7 — spawns on look-away, 45–60 s lifetime,
│  │                                              leaves SILENTLY if you never speak, hold E → Ending 3,
│  │                                              distinct_style prompt. Never cut
│  ├─ lure.tscn / lure.gd                   W5   GDD 12 E10 — beyond the sign line: thinning fog,
│  │                                              warm light, idling engine
│  ├─ timetable.gd                          W2   GDD 9 — Label3D (never baked text, GDD 25 Q6);
│  │                                              smudged rules in Night 1, full from Night 2 (E5)
│  ├─ poster.gd                             W5   GDD 10 — 3 states: water damage → silhouette →
│  │                                              silhouette in a yellow raincoat
│  ├─ shelter_reverb.gd                     W2   GDD 16 — Area3D on layer 5; toggles reverb bus
│  │                                              "ShelterVerb" on AudioStreamPlayer3Ds inside
│  └─ payphone.gd                           W6   GDD 12 E9 — **CUT #2**, build only if ahead
│
├─ events/
│  ├─ event_base.gd                EventBase W3  GDD 18 — run/abort/_start/_cleanup/_done,
│  │                                              finished signal, _ended guard (abort + natural finish)
│  ├─ e01_lamp_flicker.gd/.tscn            W3   GDD 12/18 — MIN_CYCLE 0.45, MAX_CYCLE 0.80.
│  │                                              Do NOT tighten: 0.36 measured 3.01 Hz and FAILED
│  ├─ e02_distant_engine.gd/.tscn          W3   engine approaches and fades; no bus
│  ├─ e03_gravel_footsteps.gd/.tscn        W3   steps circle behind the shelter, stop when you turn
│  ├─ e04_figure_step.gd/.tscn             W4   calls figure.request_step()
│  ├─ e05_timetable_change.gd/.tscn        W5   swaps Label3D text + paper creak
│  ├─ e06_bin_radio.gd/.tscn               W5   **NEVER CUT** — introduces the one voice before E7
│  ├─ e07_bench_stranger.gd/.tscn          W5   **NEVER CUT** — Rule 2's test
│  ├─ e08_glass_reflection.gd/.tscn        —    **CUT #1** — ring buffer of player transforms
│  ├─ e09_payphone.gd/.tscn                —    **CUT #2**
│  ├─ e10_signpost_lure.gd/.tscn           W5   Rule 3's test, ~30 s
│  ├─ s1_passing_bus.gd/.tscn              W4   Night 1, punctual at 300 s, scripted blackout 4 s
│  ├─ s2_numberless_bus.gd/.tscn           W5   Night 2, punctual at 380 s, lit EMPTY interior, 45 s
│  ├─ s3_silence_real_bus.gd/.tscn         W6   Night 3, silence beat → punctual at 405 s, 60 s to board
│  └─ s4_bus_interior.gd/.tscn             W6   **PROTECT THIS** — Ending 5's payoff
│
├─ ui/
│  ├─ hud.tscn / hud.gd                     W2   GDD 17 — see §4. Connects to PlayerInteraction's
│  │                                              prompt_changed / hold_progress_changed / lean_changed
│  ├─ hold_ring.gd                          W2   fills during hold actions
│  ├─ prompt.gd                             W2   small text under the crosshair; distinct style for E7
│  ├─ caption.gd                            W9   GDD 17 — DIRECTIONAL captions ("[footsteps behind
│  │                                              you, left]"). Load-bearing, not polish
│  ├─ title_card.gd                         W2   "Night 1/2/3" for 3 s + fade
│  ├─ ending_card.gd                        W5   reads an EndingDef; one or two lines
│  ├─ cone_vignette.gd                      W10  GDD 8 layer 3 — accessibility toggle, default OFF
│  ├─ menus/main_menu.tscn/.gd              W5   Start · Endings · Options · Quit
│  ├─ menus/pause_menu.tscn/.gd             W2   process_mode = **When Paused**
│  ├─ menus/options_menu.tscn/.gd           W10  GDD 17 option list
│  ├─ menus/endings_menu.tscn/.gd           W5   five slots that fill in from Save.endings_seen
│  ├─ menus/content_note.tscn/.gd           W5   flashing light, dark imagery, loud sudden audio
│  ├─ menus/credits.tscn/.gd                W10
│  └─ theme/theme.tres + pixel_font.ttf     W2   ADDITION (D7) — v1.9 first-pass failure #4 was
│                                                 "a UI assembled in code with no font and no styling"
│
├─ audio/
│  ├─ default_bus_layout.tres               [DONE] GDD 16 — 9 buses, Master + 8:
│  │                                              Master ← Ambience ← Weather ← Rain, Wind
│  │                                              Master ← SFX, Voice, ShelterVerb, UI
│  ├─ beds/     rain_loop, wind_loop, lamp_hum, lamp_hum_gaze, road_room_tone
│  ├─ foley/    footstep_gravel_01..03, footstep_concrete_01..03, cloth_01..02,
│  │            breath, watch_raise, paper_creak
│  ├─ sfx/      distant_engine, gravel_steps, bin_radio_static, glass_tap
│  ├─ bus/      engine_idle, engine_approach, brake_hiss, door_open, door_close,
│  │            interior_hum, payphone_ring, payphone_pickup
│  ├─ voice/    ~12 short lines — ONE processed voice for radio, payphone and stranger
│  └─ stingers/ drone_low, heartbeat
│
├─ models/       GDD 14 asset list — .glb + a matching .tscn wrapper per asset:
│                shelter, bench, bin, payphone, lamp_post, sign, timetable_board,
│                road_tile, verge_tile, tree_billboard (×2–3), bus_exterior,
│                bus_interior, silhouette, forearms_watch
│
├─ textures/     dest_47.png, dest_blank.png, poster_n1/n2/n3.png, watch_lcd.png,
│                notice_boarded.png, rain_streak.png  — root-level ON PURPOSE, see D1
│
├─ shaders/      psx.gdshader   per-vertex one-lamp lighting, clip-space vertex snapping,
│                               texel-snapped UVs, depth fog
│                post.gdshader  15-bit quantisation, ordered dither, vignette
│
├─ tests/                                    GDD 22 — run before every build
│  ├─ README.md                       [DONE] how to run them, what each one protects
│  ├─ run_all.sh                      [DONE] runs parseall, then every test_*.tscn
│  ├─ parseall.gd / parseall.tscn     [DONE] **RUN FIRST.** Walk res://, load() every .gd,
│  │                                          assert a non-null Script with can_instantiate().
│  │                                          --import scans class_name only; --check-only has
│  │                                          no autoloads. Neither is sufficient alone
│  ├─ harness/assert_kit.gd           [DONE] tiny pass/fail counter + tally printer
│  ├─ harness/night_sim.gd            W1     headless night driver (Engine.time_scale)
│  ├─ test_weather_bus.gd             W1     get_bus_index("Weather") >= 0
│  ├─ test_layers.gd                  W1     no glass / thin prop / lamp pole on layer 6
│  ├─ test_clock.gd                   W2     arrives at minute 47, `arrived` fires exactly once,
│  │                                          start_minute() in 25..46, tempo 24–26 s/min
│  ├─ test_night_flags.gd             W2     gaze_lethal [F,F,T] · sign_lethal [F,T,T] ·
│  │                                          figure_cap_index [1,2,3] · real_seconds [300,380,405]
│  ├─ test_interaction_mask.gd        W2     the InteractRay mask is EXACTLY layer 3 (value 4)
│  ├─ test_beat_ordering.gd           W3     beats sorted ascending; rule tests ≥ 30 s apart
│  ├─ test_cone_fov.gd                W3     cone is 41% ± 1% of horizontal_fov() at FOV 75 and 90
│  ├─ test_flicker_rate.gd            W3     **MEASURED** with Time.get_ticks_msec(), ≥ 10 cycles,
│  │                                          shortest cycle ≥ 0.40 s. Never computed from MIN_CYCLE
│  ├─ test_highlight_tracks_cone.gd   W3     FogFigure.watched == in_gaze_cone(head_position())
│  │                                          and albedo_color follows it
│  ├─ test_same_event_exclusion.gd    W4     two beats with the same id → only one instance starts
│  ├─ test_arrival_punctuality.gd     W4     event_started within ±0.1 s of real_seconds
│  ├─ test_stations.gd                W4     stations 1–4 within 32 m of the SHELTER CENTRE
│  ├─ test_no_free_band.gd            W4     figure.watched and GazeMonitor's staring bool identical
│  │                                          at every sampled angle
│  ├─ test_night_start_state.gd       W4     lamp 1.0 / flicker 1.0 / no blackout / _stare 0.0 /
│  │                                          station_index -1 / invisible / Weather at 0 dB
│  ├─ test_night1_cannot_kill.gd      W4     **60 s continuous stare**, Game.state stays NIGHT
│  ├─ test_night1_sign.gd             W4     crossing emits `warned`, never an ending
│  ├─ test_restart.gd                 W4     run-id guard; no stale coroutine; lethal re-read
│  ├─ test_bus_door_x.gd              W4     gap G3 — the door is at x=8.5, ≥1 m west of the sign
│  ├─ test_night2_cannot_kill.gd      W5     60 s stare at the Night 2 cap
│  ├─ test_night2_sign_lethal.gd      W5     crossing ends the run with variant `sign`
│  ├─ test_night3_gaze_timing.gd      W6     cap at 25.5–26.6 s, death at 35.8–37.0 s. Deliberately
│  │                                          tight: a 30–42 s window passed three broken variants
│  ├─ test_three_gates.gd             W6     each gate alone prevents death (F9 helps)
│  ├─ test_pause.gd                   W6     pause during the silence beat restores Weather to 0 dB
│  └─ test_no_infinite_ending.gd      W6     still_waiting reaches a card and never calls run_night()
│
├─ tools/                                    OPTIONAL — asset generation scripts (models, textures,
│                                            WAV synthesis). GDD v1.8 generated 27 WAVs this way
└─ archive/v1-first-pass/                    your first build, kept for GDD 0's v1.9 lessons
```

**Totals:** ~85 scripts · ~30 scenes · 14 event resources · 3 night resources ·
5 ending resources · ~45 audio files · 14 models · ~10 textures · 2 shaders · 27 tests.

---

## 2. Deviations from the GDD §18 sketch (and why)

GDD §18's folder block is a 10-line sketch. These are the places the real tree has to
differ, because the document's own code disagrees with its own sketch.

| # | Deviation | Reason |
| --- | --- | --- |
| **D1** | `res://textures/`, `res://models/`, `res://shaders/` are **root-level**, not under `art/` | §18's sketch says `art/`, but §18's own `BusRig` hardcodes `res://textures/dest_47.png`, and v1.8 describes the reference build as `models/*.tscn + *.glb`. **Code wins over the sketch.** If you prefer `art/`, change the two `load()` calls in `bus_rig.gd` |
| **D2** | `res://audio/` is subfoldered, but the doc's `bus_rig.gd` loads `res://audio/engine_idle.wav` **flat** | Pick one. **(a)** Keep the doc's code verbatim → the six bus files sit flat in `res://audio/`. **(b) Recommended** → subfolder them and replace the `load()` calls with `@export var` `AudioStream` fields assigned in `bus_rig.tscn`. Fewer string paths, typos become visible in the Inspector instead of failing silently at runtime |
| **D3** | Added `core/settings.gd` as a fourth autoload | GDD §17 lists ten options and §18 never gives them a home. Without an autoload they end up duplicated across the options menu, the HUD and the shaders |
| **D4** | Added `core/debug_kit.gd` | GDD §13 says "build early; they save days." A single node owning F1–F10 keeps debug code out of `main.gd` |
| **D5** | Added `data/ending_def.gd` + `data/endings/*.tres` | Ending card copy as data, not `match` branches. Needed for localisation (GDD §25 Q6) and it's where Ending 1's two variants live |
| **D6** | `addons/` stays empty | GDD v1.9 item 4: the PSX look is two own shaders, not a third-party pack. Delete the folder if you never install one |
| **D7** | `ui/theme/` exists in **W2**, not W8 | v1.9 first-pass failure #4 was "a UI assembled in code with no font and no styling." A `Theme` with a pixel font is 20 minutes in week 2 and prevents a week-8 rewrite |

---

## 3. Two gaps in the GDD to fix as you write the code

Found while mapping the document's code onto a tree. Both are small, both are silent.

**G1 — `main.gd` fills only 4 of `EventContext`'s 8 fields.**
v1.8 correction #2 added `tracker`, `bus`, `hud` and `world` to `EventContext` because
"events legitimately need" them — but §18's `main.gd` still exports only
`player / figure / lamp / clock` and assigns only those four in `_ready()`. So
`ctx.tracker`, `ctx.bus`, `ctx.hud` and `ctx.world` are **null at runtime**, and the
first event that touches them (E3's look-direction check, E7's spawn, S2's door, any
caption) crashes or no-ops. Fix: add `@export var tracker: LookAtTracker`,
`bus: BusRig`, `hud: Node`, `world: Node3D` to `main.gd` and assign all eight in `_ready()`.

**G2 — physics layer 4 ("entities") is assigned to nothing.**
§14 puts the Fog Figure and the Stranger on layer 4. But `FogFigure extends Node3D`, which
has no `collision_layer` property at all, and the Stranger is an `Interactable`, whose
`_ready()` hard-sets `collision_layer = 1 << 2` (layer 3). Nothing masks layer 4 either —
the sight mask is layer 6 only and the interaction mask is layer 3 only. Keep the name in
`project.godot` as reserved, but **do not give `FogFigure` a collider**: any body on it
would either block the interaction ray or, worse, land on layer 6 and fake occlusion.

**G3 — `BusRig`'s door lands 1.4 m past the sign line.**
§14 puts the bus door at **x = 8.5**, "2 m before the sign line", so boarding never
conflicts with Rule 3. But §18's `arrive()` tweens `bus.position.x` to **8.5**, and
`door_world_pos()` returns `bus.global_position + Vector3(3.4, 1.2, 1.35)` — so the door the
player actually reaches for is at **x = 11.9**, i.e. 1.4 m *past* the lethal sign wall at
10.5. In Nights 2–3, holding E to board the real bus would trigger Ending 1 first.
Two fixes, take the second:
- tween `arrive()` to `8.5 - 3.4 = 5.1`, or
- **derive the door position from the door node** (`door_l.global_position + Vector3(0, 1.2, 1.35)`)
  and tween to whatever x puts *that* at 8.5. Then add `tests/test_bus_door_x.gd`:
  assert `door_world_pos().x` is within 0.2 m of 8.5 and at least 1.0 m west of the sign line.

Related: `LANE_Z = -1.5` is the **Bus node's local** z, so the lane's world z is
`BusRig.global_position.z - 1.5`. `world/road.tscn` puts the road centre at z = −8.0, so place
`BusRig` at **z = −6.5** and the bus drives down the middle of the road.

Also worth knowing before you write `main.gd`: `_on_sign_warned()` in the doc only dims
the lamp — the drone and the multi-frame push-back are prose, not code (and the push-back
belongs in `player/tether.gd` so it can never be a teleport). `_fade_and_card()` and
`_show_ending_card()` are explicitly placeholders for the real `ui/title_card.gd` and
`ui/ending_card.gd`.

---

## 4. Scene trees to build in the editor

### `main.tscn` — GDD §18, plus the two nodes the code actually requires

```
Main (Node3D)                          main.gd
├─ WorldEnvironment                    world_environment.tres
├─ World (Node3D)                      → ctx.world: marks, props, poster
│  ├─ BusStop (world/bus_stop.tscn)
│  │  ├─ Shelter (StaticBody3D)        layers 1 + 6 (walls and roof are sight blockers)
│  │  │  ├─ Roof / BackWall / SideWall (MeshInstance3D)
│  │  │  ├─ RoofRainCollision (GPUParticlesCollisionBox3D)   ← v1.9 fix #3: without this
│  │  │  │                                                     rain falls through the roof
│  │  │  ├─ GlassPanel (StaticBody3D) layer 1 ONLY — never 6, never in the sight mask
│  │  │  └─ BenchBack (StaticBody3D)  layers 1 + 6
│  │  ├─ LampPole (StaticBody3D)       layer 1 ONLY — §22 layer audit checks this
│  │  ├─ Lamp (LampController)         at x=0, the origin
│  │  │  ├─ Light (OmniLight3D)        range 6.5 m, warm sodium
│  │  │  ├─ Hum (AudioStreamPlayer3D)  → Ambience; pitch_scale = lerpf(0.7, 1.0, level)
│  │  │  ├─ GazePartial (AudioStreamPlayer3D) → Ambience; fairness rule 10, layer 2
│  │  │  └─ Heartbeat (AudioStreamPlayer3D)   → SFX; fires at 30%, or 50% at the cap
│  │  ├─ Interactables (Node3D)
│  │  │  ├─ Timetable (Interactable)  group "readable", tap → lean-in
│  │  │  ├─ Poster (Interactable)     group "readable"
│  │  │  ├─ Bench (Interactable)      x ≈ 1.5
│  │  │  ├─ Bin (Interactable)        x = 3.5
│  │  │  └─ Payphone (Interactable)   x = −4        [CUT #2]
│  │  ├─ SignPost (MeshInstance3D + Label3D "END OF SERVICE")  x = 10.5
│  │  ├─ SignLine (Area3D)             sign_line.gd — layer 0, mask layer 2
│  │  └─ ShelterReverb (Area3D)        layer 5, mask layer 2
│  ├─ Road (world/road.tscn)
│  ├─ Lure (world/lure.tscn)           disabled until E10
│  └─ BusStopCentre (Marker3D)         x ≈ 1.5 — the tether and the §22 station-reachability
│                                                 test both measure from HERE, not from the lamp
├─ BusRig (world/bus_rig.tscn)         → ctx.bus. Missing from §18's tree but EventContext
│                                         is typed to BusRig, so it must be a real node
├─ Player (player/player.tscn)         → ctx.player
├─ FogFigure (world/fog_figure.tscn)   → ctx.figure
├─ LookAtTracker (Node)                → ctx.tracker; camera = Player/Head/Camera3D
├─ GazeMonitor (Node)
├─ Director (Node)
├─ NightClock (Node)
├─ Rain (GPUParticles3D)               rain.gd; target = Player
├─ DebugKit (Node)                     debug_kit.gd
└─ UI (CanvasLayer)                    ui/hud.tscn → ctx.hud
PauseMenu (CanvasLayer)                process_mode = **When Paused**, sibling of Main
```

Process modes (GDD §18): everything above is **Inherit** (pausable) except `PauseMenu`
(**When Paused**) — pausing must freeze the clock, the Director and the figure.

### `player/player.tscn`

```
Player (CharacterBody3D)               player.gd — group "player", layer 2, mask 1
├─ CollisionShape3D                    CapsuleShape3D, radius 0.35, height 1.8
├─ Head (Node3D)                       y = 1.62 — player_camera.gd (yaw here, pitch on Camera3D)
│  └─ Camera3D                         fov 75, keep_aspect KEEP_HEIGHT, near 0.05, far 60
├─ InteractRay (RayCast3D)             mask = **layer 3 only** (value 4), target_position z = −2.5
├─ PlayerInteraction (Node)            interaction.gd; ray = InteractRay
├─ Watch (Node3D)                      watch.gd — forearm mesh + LCD, hidden until Q
├─ Footsteps (AudioStreamPlayer3D)     → SFX; reverb_bus_name = "ShelterVerb" when inside
├─ Tether (Node)                       tether.gd — soft 12 m, hard 14 m, sign-line push-back
└─ HeadBob (Node)                      head_bob.gd
```

`InteractRay` must be a **sibling** of the camera, not a child of it, or the ray origin
moves with pitch. `PlayerInteraction._ready()` re-sets the mask anyway, so a wrong value
in the scene is caught — but set it right so the §22 mask test passes.

### `world/fog_figure.tscn`

```
FogFigure (Node3D)                     fog_figure.gd — NO collider (see gap G2)
├─ Mesh (MeshInstance3D)               models/silhouette.glb; unshaded, near-black albedo;
│                                      material must allow TWO albedo colours (base + watched)
├─ Stations (Node3D)
│  ├─ Station0 (Marker3D)              x = −26   station 1 — barely readable in fog
│  ├─ Station1 (Marker3D)              x = −19   station 2 — Night 1 cap
│  ├─ Station2 (Marker3D)              x = −13   station 3 — Night 2 cap
│  ├─ Station3 (Marker3D)              x = −9    station 4 — Night 3 cap, just outside the light
│  └─ Station4 (Marker3D)              x = −5    station 5 — breach, INSIDE the light
└─ Steps (AudioStreamPlayer3D)         → SFX; positional, so footsteps tell you where it is
```

Export `stations` as an `Array[Marker3D]` in that order. `_move_to()` copies
`global_position` **only** — never `global_transform`, or a marker rotated to face the road
silently rotates and scales the figure.

### `world/bus_rig.tscn` — the `@onready` paths are fixed by `bus_rig.gd`

```
BusRig (Node3D)                        bus_rig.gd
├─ Bus (Node3D)                        local x drives everything; LANE_Z = −1.5
│  ├─ Body (MeshInstance3D)
│  ├─ Windscreen (MeshInstance3D)      emission toggled by set_lits_windows()
│  ├─ Win1 … Win8 (MeshInstance3D)     names MUST begin with "Win" — the code globs on that
│  ├─ DoorLeafL (MeshInstance3D)       direct child of Bus; closed x = 3.12
│  ├─ DoorLeafR (MeshInstance3D)       direct child of Bus; closed x = 3.68
│  ├─ DestBoard (MeshInstance3D)       quad; surface material swapped to dest_47 / dest_blank
│  ├─ Headlight-1 (MeshInstance3D)     NOTE the code looks for "Headlight-1" THEN "Headlight1";
│  │                                   pick one and delete the fallback
│  └─ InteriorLight (OmniLight3D)      the light the player walks toward after leaving the lamp
├─ Engine (AudioStreamPlayer3D)        direct child of BusRig
├─ Brakes (AudioStreamPlayer3D)
├─ DoorsSnd (AudioStreamPlayer3D)
└─ Interior (AudioStreamPlayer3D)
```

Build this subtree **detached** and `add_child()` the root last — `@onready` resolves at
tree entry, so adding children after the fact nulls every one of those vars (v1.8 #4).

### `ui/hud.tscn`

```
HUD (CanvasLayer)                      hud.gd
├─ Crosshair (TextureRect)             one tiny dot, nothing else
├─ Prompt (Label)                      prompt.gd — under the dot; distinct style for the stranger
├─ HoldRing (Control)                  hold_ring.gd — arc fill 0..1
├─ Captions (VBoxContainer)            caption.gd — bottom-centre stack
├─ ConeVignette (ColorRect)            cone_vignette.gd — hidden unless the option is on
├─ TitleCard (Control)                 title_card.gd
└─ EndingCard (Control)                ending_card.gd
```

GDD §17: no health bar, no objective list, no minimap, no timer. The watch is diegetic and
the gaze cone is communicated by the silhouette and the hum, never by the HUD.

---

## 5. Reference cards

### Physics layers (GDD §14, already named in `project.godot`)

| Layer | Bit value | Name | Occupied by | Masked by |
| --- | --- | --- | --- | --- |
| 1 | 1 | `world` | ground, shelter, bench, glass, lamp pole | Player (mask 1) |
| 2 | 2 | `player` | the Player body | SignLine (mask 2), ShelterReverb (mask 2) |
| 3 | 4 | `interactables` | every `Interactable` | **InteractRay, mask exactly 4** |
| 4 | 8 | `entities` | *reserved* — see gap G2 | nothing yet |
| 5 | 16 | `triggers` | SignLine, ShelterReverb | — |
| 6 | 32 | `sight_blockers` | shelter walls, roof, bench back **only** | **LookAtTracker, mask exactly 32** |

Never on layer 6: glass, the lamp pole, thin props, the Fog Figure. The 3-ray fan is a
second line of defence, not the first.

### Autoloads (already registered in `project.godot`)

| Autoload | File | Order-sensitive? |
| --- | --- | --- |
| `Game` | `core/game.gd` | No — as written |
| `Save` | `core/save.gd` | Only if you move `Save.read()` into `Save._ready()`; then **Game above Save** |
| `Settings` | `core/settings.gd` | No |
| `AudioHub` | `core/audio_hub.gd` | No |

Preferred, and order-independent: call `Save.read()` and `Settings.load()` explicitly from
`Main._ready()`.

### Naming conventions

| Thing | Convention | Example |
| --- | --- | --- |
| Script / scene files | `snake_case` | `fog_figure.gd`, `bus_rig.tscn` |
| `class_name` | `PascalCase` | `FogFigure`, `LookAtTracker` |
| Deck events | `eNN_snake_name` | `e07_bench_stranger.gd` |
| Scripted beats | `sN_snake_name` | `s2_numberless_bus.gd` |
| Event resources | `eNN.tres` / `sN.tres` | `data/events/e07.tres` |
| Signals | past tense, no `on_` prefix | `arrived`, `doors_opened`, `prompt_changed` |
| Private members | leading underscore | `_stare`, `_live`, `_calm_until` |
| Audio | `snake_case.wav`; loops `.ogg` | `beds/rain_loop.ogg` |
| Input actions | verb, lowercase | `interact`, `watch`, `move_forward`, `debug_f4` |

Use `.ogg` for the beds and voice (a looping rain WAV is megabytes) and `.wav` for short
foley and stingers. Set loop mode in the **import dock**, not in code.

---

## 6. The 26-file spine (weeks 1–4)

This is the subset that produces the week-4 vertical slice — Night 1 playable start to
finish. Nothing else matters until it does.

```
core/game.gd            core/audio_hub.gd      core/look_at_tracker.gd
core/event_context.gd   core/director.gd       core/debug_kit.gd
data/horror_event.gd ✓  data/beat_def.gd ✓     data/night_def.gd ✓
main.gd                 main.tscn
player/player.gd        player/player_camera.gd  player/interaction.gd
player/interactable.gd  player/tether.gd         player/player.tscn
world/lamp_controller.gd  world/fog_figure.gd    world/gaze_monitor.gd
world/night_clock.gd      world/sign_line.gd     world/rain.gd
world/bus_rig.gd          world/world_environment.tres  world/bus_stop.tscn  world/road.tscn
events/event_base.gd      events/e01_lamp_flicker.gd    events/s1_passing_bus.gd
ui/hud.gd  ui/theme/theme.tres
```

Of these, only **days 1–2** matter first: `look_at_tracker.gd`, `lamp_controller.gd`,
`gaze_monitor.gd`, `fog_figure.gd` and a capsule. GDD §20: *"you can stand in a grey box
in the rain and be afraid of a capsule — and the box cannot kill you when it shouldn't."*

---

## 7. Before you press Play (the four first-pass failures, GDD v1.9)

None of these were visible in review. All were visible in the first sixty seconds of play.

1. **A world with no collision.** Every floor, wall, roof and the bench needs a
   `StaticBody3D` + `CollisionShape3D` on layer 1. Greybox it in week 1, not week 8.
2. **Input actions referenced but never defined.** `project.godot` now defines all 17.
   If you add an action in a script, add it here in the same commit.
3. **Particle systems with nothing to collide against.** Rain needs a
   `GPUParticlesCollisionBox3D` on *every* roof — the single most-reported visual bug of
   the first pass.
4. **A UI assembled in code with no font and no styling.** `ui/theme/theme.tres` + a pixel
   font in week 2. At 640×360 the default font is unreadable, and §2 requires the 21-character
   title to fit the menu and the ending card at that width.

Then run `tests/parseall.tscn` before believing any other result.

---

## 8. Authoring rules

**Scenes and UI are authored in the editor, never generated by code.** This is a rule for
the whole project, not a preference — a node you cannot select is a node you cannot
iterate on, and iterating on placement, scale and timing is most of the work in a game
whose only location is one bus stop.

| Authored as nodes in a `.tscn` | May be created at runtime |
| --- | --- |
| All world geometry, collision, lights, markers, Areas | Instancing an **event scene** the Director spawns (`events/e*.tscn`) |
| All meshes, materials, particles and their process materials | The HUD's **caption stack** (a pooled row per caption) |
| Every `Label3D`: sign, timetable, poster, notice board | **Debug drawing** (`ImmediateMesh` for the F4 cone) |
| The whole UI: HUD, menus, cards, options rows | Nothing else. If you find yourself writing `MeshInstance3D.new()` outside a test, stop |

Consequences worth knowing before you rename anything:

- **Exported node references are stored as `NodePath` in the `.tscn`** — e.g. the Lamp node
  carries `light = NodePath("Light")`. Renaming a node in the editor updates every reference
  to it automatically. Editing the `.tscn` as text does not, so rename in the editor.
- **Node names are load-bearing in four places:**
  - `BusRig`'s `@onready` paths: `$Bus`, `$Bus/DoorLeafL`, `$Bus/DoorLeafR`,
    `$Bus/DestBoard`, `$Engine`, `$Brakes`, `$DoorsSnd`, `$Interior`
  - `set_lits_windows()` globs on names beginning with **`Win`** (plus `Windscreen`)
  - The groups: `player`, `readable`, `lamp`, `gaze`, `figure`, `clock`, `director`,
    `bus_stop_centre`, `figure_station`, `debug`
  - `main.gd`'s `@export` refs, assigned by dragging nodes in the inspector
- **One scene per thing, instanced into the parent.** `road`, `bus_stop`,
  `figure_stations`, `fog_figure`, `rain`, `player`, `hud`, every event, every menu. A scene
  that is only ever used once still earns its file: it is the unit you open to change one thing.
- **When you do instance at runtime, build the subtree detached and `add_child()` the root
  last** — `@onready` resolves at tree entry, so adding children afterwards nulls every
  `@onready` var (GDD v1.8 #4).
- **Anchors live in the world, not on the thing that moves.** The five station `Marker3D`s
  are in `figure_stations.tscn`, not under `FogFigure`, because the figure's
  `global_position` is rewritten on every step.
