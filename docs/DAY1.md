# DAY 1

Goal, from GDD §20: **you can walk the greybox.** Fog, rain, one lamp, correct distances,
collision on everything, and a project that boots with no errors in the output panel.

The greybox is **already built as real scenes** — every wall, post, bench and marker is a
node you can select, move and inspect in the editor. Nothing is generated at runtime, so
what you see in the viewport is what you get. Today is *verification and orientation*, not
modelling.

Budget: **4–6 hours**, of which 2 h is the PSX compatibility check.

---

## What's in the project already

| Scene | Contents |
| --- | --- |
| **`main.tscn`** | `WorldEnvironment` + instances of Road, BusStop, FigureStations, FogFigure, Rain, Player + `DebugKit`. This is the main scene |
| **`world/road.tscn`** | Ground (infinite `WorldBoundaryShape3D` collider at y=0), road surface 7 m wide at z −11.5…−4.5, kerb, 14 centre-line dashes, 16 billboard trees 32–46 m out |
| **`world/bus_stop.tscn`** | Shelter (roof, back wall, two posts, glass panel, bench seat + back), `RoofRainCollision`, the **Lamp** (pole, head, `OmniLight3D` range 6.5, Hum, Heartbeat), Bin, Payphone, Timetable + Poster `Label3D`s, SignPost, **SignLine** Area3D + a faint red debug wall, ShelterReverb Area3D, `BusStopCentre` marker |
| **`world/figure_stations.tscn`** | The five `Marker3D` stations at x = −26/−19/−13/−9/−5 (z = −2), each with a debug sphere and a billboarded `Label3D` naming its cap |
| **`world/fog_figure.tscn`** | A capsule placeholder in near-black unshaded material. `fog_figure.gd` attaches tomorrow |
| **`world/rain.tscn`** | `GPUParticles3D` (1200, `collision_mode` on) + `rain.gd` |
| **`world/world_environment.tres`** | Depth fog 4→32 m, curve 1.2, fog = background = `#101820`, ambient `#0b1220`, linear tonemap, no glow |
| **`player/player.tscn`** | `CharacterBody3D` + capsule, `Head`/`Camera3D`, `InteractRay` (disabled until week 2), `Tether` |

Coordinates are GDD §14 exactly: **the lamp is the origin**, +x is east, so +z is south.
The road is north of the shelter, the figure lives west, the bus comes from the east — the
player walks *away* from the Thing to board.

---

## Step 0 — Install and open (15 min)

1. Install **Godot 4.7 stable** (the standard build, not .NET — this project is GDScript).
2. Godot → **Import** → select `bus-stop-game/project.godot` → Open.
3. Let it import. The output panel should be quiet.
4. Double-click `main.tscn`. You should see the shelter, the lamp, the road and the fog in
   the 3D viewport **without pressing Play**.

---

## Step 1 — Verify the four things your first pass shipped without (20 min)

GDD §0 v1.9 lists the failures of the first build. Three are configuration, and all three
are visible in Project Settings in five minutes.

| Check | Where | Expect |
| --- | --- | --- |
| **Autoloads resolve** | Project Settings → Autoload | `Game`, `Save`, `Settings`, `AudioHub` — no red icons |
| **Input actions exist** | Project Settings → Input Map | 17 actions: `move_*` ×4, `interact`, `watch`, `pause`, `debug_f1`…`debug_f10`. *Failure #2 was actions referenced but never defined* |
| **Physics layers named** | Project Settings → Layer Names → 3D Physics | 1 `world` · 2 `player` · 3 `interactables` · 4 `entities` · 5 `triggers` · 6 `sight_blockers` |
| **The 9 audio buses** | Bottom panel → Audio | Master ← Ambience ← Weather ← Rain/Wind, plus SFX, Voice, ShelterVerb, UI |

Then, from a terminal in the project folder:

```bash
godot --headless --path . tests/parseall.tscn
```

Expect `parseall: 15/15 scripts compiled, 0 failures`, exit code 0.
**If this fails, stop and fix it** — every later result is untrustworthy otherwise.

---

## Step 2 — Check the layer assignments in the editor (15 min)

This is the check that is expensive to retrofit and cheap today. Click each node and read
`collision_layer` in the inspector:

| Node | Layer | Why |
| --- | --- | --- |
| `Shelter/Roof`, `BackWall`, `WestPost`, `EastPost`, `BenchBack` | **1 + 6** | Large opaque surfaces are sight blockers |
| `Shelter/GlassPanel` | **1 only** | Glass blocks movement, never sight (GDD 14) |
| `Lamp/Pole`, `Lamp/Head` | **1 only** | *Failure mode:* a pole on layer 6 fakes occlusion and freezes the figure for free. `tests/test_layers.gd` checks this |
| `Ground`, `Kerb`, `Bin`, `Payphone`, `SignPost/*`, `BenchSeat` | 1 | Movement collision |
| `SignLine` (Area3D) | layer **0**, mask **2** | It only ever looks for the player |
| `ShelterReverb` (Area3D) | layer **5**, mask **2** | Trigger |
| `Player` | layer **2**, mask **1** | |
| `FogFigure` | *none — it has no collider at all* | See gap G2 in `PROJECT_STRUCTURE.md` |

Nothing in the scene is on layer 6 except the five surfaces in the first row.

---

## Step 3 — Look at it in the editor (20 min)

Two things make the greybox readable without playing:

1. **Turn on the light preview.** Select `BusStop/Lamp/Light`, then click the little
   lightbulb icon at the top of the 3D viewport ("Preview" → the sun/bulb toggle). The
   editor now renders lighting live, and you can see the 6.5 m pool: the **Bin at x = 3.5 is
   lit, the SignPost at x = 10.5 is not**. That gap is the whole game.
2. **Read the station tags.** `FigureStations/Markers/Tag0…Tag4` are billboarded labels
   naming each station, its `cap_index` and which night caps there. They are debug
   furniture — delete the whole `Markers` node in week 8.

Then move something, to prove the scenes are really yours to edit: select `BusStop/Bin`,
drag it 2 m east in the viewport, and confirm the light no longer reaches it. Undo.

---

## Step 4 — Press F5 and walk it (45 min)

You spawn under the shelter at (1.5, 0, 0.2), in the rain, in the lamp pool, facing a wall
of blue fog to the west and a faint red rectangle 9 m to the east.

| # | Do this | Correct result |
| --- | --- | --- |
| 1 | Walk west along the verge | You slow at ~12 m from the shelter centre and cannot pass ~14 m. That is `player/tether.gd`, not a wall mesh |
| 2 | Walk east into the red rectangle | You stop at the sign line, x = 10.5. Nothing happens yet — `world/sign_line.gd` arrives in week 4 |
| 3 | Look at the bin, then the sign | Bin lit, sign not. Pool edge = 6.5 m |
| 4 | Look west into the fog | The treeline is a suggestion, not a shape. If you can see detail at 40 m, `fog_depth_end` is wrong |
| 5 | Stand under the roof | **The rain must not fall through it.** *Failure #3 of your first pass.* If it does, `collision_mode` didn't take on the Rain node, or `RoofRainCollision` was moved off the roof |
| 6 | Look at the capsule 26 m west | It should be barely there — a darker-than-fog shape. That is tomorrow's antagonist |
| 7 | Press **F1**, **F6**, **Esc** | F1 dumps state (only the lamp exists yet, that's expected). F6 = noclip. Esc pauses and frees the mouse; Esc again resumes |

Confirm there are **no errors** in the output panel.

---

## Step 5 — The PSX compatibility check (2 h, timeboxed)

GDD §20 week 1: *"2 h PSX pack compatibility check only — does it coexist with depth fog and
an `OmniLight3D`? No look-dev."*

This is a spike, not a task. Timebox it hard and write down the answer.

1. Pick one approach from GDD §15: the Godot PSX style demo, PSX Visuals (GD4 port),
   Ultimate Retro Shader Collection, or write `shaders/psx.gdshader` yourself. GDD v1.9
   item 4 recommends two own shaders (`psx.gdshader` + `post.gdshader`) — no licence
   review, and it's what makes a low-res framebuffer read as PS1.
2. Apply it to **one** box in `bus_stop.tscn`.
3. Answer exactly three questions:
   - Does vertex snapping survive `fog_mode = DEPTH`?
   - Does an `OmniLight3D` still light the surface correctly through the shader?
   - Does it survive the 640×360 viewport stretch with integer scaling?
4. Write the three answers into `docs/TUNING.md` and **stop**. Look-dev is week 7, after the
   week-4 go/no-go, so no art work is wasted if the concept fails.

Not comfortable with shaders yet? **Skip step 5 today** and spend the two hours on day 2 or
3. It must happen in week 1, but it is the least urgent thing on this list.

---

## Step 6 — Commit (5 min)

```bash
git add -A
git commit -m "Day 1: greybox scenes at GDD 14 coordinates, fog, rain, lamp, player, tether, debug kit"
```

---

## Day 1 acceptance criteria

- [ ] `tests/parseall.tscn` reports 15/15, exit code 0
- [ ] `main.tscn` shows the shelter, road, lamp and fog in the editor viewport
- [ ] F5 boots with no errors in the output panel
- [ ] You can walk, and the mouse looks around
- [ ] The tether stops you at 14 m from the shelter centre
- [ ] The lamp pool is visibly ~6.5 m: bin lit, sign not
- [ ] Rain does not pass through the shelter roof
- [ ] Fog hides the treeline; nothing readable beyond ~32 m
- [ ] Layer assignments match the Step 2 table
- [ ] F1 / F6 / Esc all work
- [ ] Committed

---

## Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| "Cannot autoload script res://core/game.gd" | File missing or won't parse | Run `tests/parseall.tscn`; it names the failing file |
| Black screen, no errors | `main.tscn` isn't the main scene | Project Settings → Application → Run → Main Scene = `res://main.tscn` |
| Editor viewport is black but Play works | Lighting preview is off | Step 3's lightbulb toggle |
| You fall through the floor forever | `Road/Ground/Collision` lost its `WorldBoundaryShape3D` | Re-add the shape; the plane is at y = 0 |
| Can't look around | The mouse isn't captured | Click the game window once; `player_camera.gd` captures on `_ready` |
| Rain falls through the roof | `collision_mode` off, or `RoofRainCollision` moved | Select `Rain` → check Collision Mode; select `BusStop/RoofRainCollision` → it must sit at (1.5, 2.45, 0) |
| Everything is bright and flat | `WorldEnvironment` missing or its `environment` is null | `main.tscn` → `WorldEnvironment` → `world_environment.tres` |
| Sign text reads backwards | `Label3D` facing | `SignPost/SignText` should be `rotation_degrees = (0, -90, 0)` — Label3D faces +Z, so −90° about Y turns it west, toward the player |
| Timetable/poster text is huge or tiny | `pixel_size` vs `font_size` | Height in metres ≈ `font_size × pixel_size`. Timetable is 32 × 0.0035 ≈ 11 cm caps |
| F1 does nothing | `debug_f1` action missing, or `DebugKit` not in `main.tscn` | Step 1's input-map check |
| `tether.gd` asserts about `bus_stop_centre` | `BusStopCentre` marker lost its group | Select it → Node dock → Groups → add `bus_stop_centre` |
| You spawn stuck in the bench | Player transform moved | `main.tscn` → `Player` → position (1.5, 0, 0.2) |

---

## What's temporary, and when it's replaced

| Today | Replaced by | Week |
| --- | --- | --- |
| Box-mesh shelter, bench, bin, payphone, sign | `models/*.glb` in `world/bus_stop.tscn` (same node names, same transforms) | 4, art in 8 |
| `SignLine/DebugWall` (faint red box) | delete — `world/sign_line.gd` makes it lethal, not visible | 4 |
| `FigureStations/Markers` (spheres + tags) | delete — the silhouette mesh replaces them | 8 |
| `fog_figure.tscn` capsule placeholder | `models/silhouette.glb`, unshaded, two albedo colours | 2 |
| `Timetable` / `Poster` as raw `Label3D` | `world/timetable.gd` (smudged in Night 1) + `world/poster.gd` (3 states) | 2 / 5 |
| `main.tscn` with 8 children | the full GDD §18 tree, with `main.gd` on the root | 4 |
| `road.tscn` centre-line dashes | keep or cut; they are a depth cue, not set dressing | — |

Because these are real scenes, "replacing" a box with a model is: drag the `.glb` in, copy
the transform, delete the box. No code changes.

---

## Day 2 preview

Four scripts, and then you have the entire concept:

`core/look_at_tracker.gd` → `world/fog_figure.gd` → `world/gaze_monitor.gd`, wired to the
capsule that is already standing at station 1.

Stare at it: the lamp dims and the hum pitch falls. Look away for 1.5 s: it steps to 19 m.
Set `gaze_lethal = false` and confirm **you cannot die**. Then set it true with F9 and
confirm you can. GDD §20: *"you can stand in a grey box in the rain and be afraid of a
capsule — and the box cannot kill you when it shouldn't."*
