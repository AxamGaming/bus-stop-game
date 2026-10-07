# tests/

GDD §22. Run these before every build.

```bash
./tests/run_all.sh                                    # everything, one process per scene
godot --headless --path . tests/parseall.tscn         # just the parse check
GODOT=~/godot4.7 ./tests/run_all.sh                   # point it at a specific binary
```

Exit code is non-zero if anything fails, so it can go straight into a pre-build hook.

---

## Why the parse check runs first

`godot --headless --import` runs `update_scripts_classes`, which scans for **`class_name`
declarations only**. `--check-only --script <file>` would catch more, but it does not
register autoloads, so any script touching `Game` / `Save` / `Settings` / `AudioHub` fails
under it spuriously.

So `parseall.gd` does the only thing that actually works: it walks `res://` at runtime,
inside a project where the autoloads exist, and `load()`s every `.gd`, asserting each
returns a `Script` with `can_instantiate() == true`.

This is not theoretical. In GDD v1.6 the document claimed "18/18 scripts compiled" — which
was literally true and materially misleading, because the two files labelled `(excerpt)`
were the only two no scene referenced, so nothing ever loaded them. They did not compile.
They were also the first two files a developer touches.

---

## Writing a test that can fail

GDD §22's rule, learned twice the hard way: **a check that cannot fail is worse than no
check.**

- v1.1's clock test restated the definition of `start_minute()` and could not fail.
- v1.2's "Night 1 cannot kill" test stared only until the first blackout — and passed while
  the kill bug was live. It now stares for **60 s**.
- v1.4's Night 3 death window was 30–42 s and passed **three** separately-broken variants of
  the drain logic. It is now 25.5–26.6 s (cap) and 35.8–37.0 s (death).
- The flicker-rate test **measures** onsets with `Time.get_ticks_msec()`. Computing the rate
  from `MIN_CYCLE` produced a false PASS at 0.36 (measured 0.332 s = 3.01 Hz), because
  `tween_interval` quantises to frame boundaries.

Before you commit a test, break the system on purpose and confirm it goes red.

---

## Conventions

- One `tests/test_<thing>.gd` + a matching `.tscn` whose root node has that script.
  `run_all.sh` picks up `tests/test_*.tscn` automatically — no registration step.
- Use `AssertKit` from `tests/harness/assert_kit.gd`, and end with `kit.finish(self)` so the
  process exits non-zero on failure.
- Anything that needs frames must actually run frames: GDD §0 notes that a mocked
  `_process` never runs. Only tween-dependent tests need real frames — drive them with
  `Engine.time_scale`, which scales `_process` deltas, `SceneTreeTimer`s and tweens together.
- Headless note (GDD v1.8): your own CLI flags land in `OS.get_cmdline_args()`, **not**
  `get_cmdline_user_args()` — the latter only sees args after `--`.

```gdscript
extends Node
# tests/test_example.gd

var kit := AssertKit.new("example")

func _ready() -> void:
	kit.eq(2 + 2, 4, "arithmetic still works")
	kit.between(1.0, 0.9, 1.1, "value in range")
	kit.finish(self)
```

---

## The checks, and what each one protects

| Test | Protects | Week |
| --- | --- | --- |
| `parseall` | every file compiles, including the ones nothing references | 1 ✅ |
| `test_weather_bus` | the silence beat (Night 3's climax) doesn't fail silently | 1 ✅ |
| `test_layers` | no glass, thin prop or **lamp pole** on layer 6 — a false sight blocker freezes the figure for free | 1 |
| `test_clock` | fairness rule 4: the clock reads 11:47 the instant the bus arrives | 2 |
| `test_night_flags` | `gaze_lethal` [F,F,T], `sign_lethal` [F,T,T], caps [1,2,3], seconds [300,380,405] | 2 |
| `test_interaction_mask` | glass cannot block the interaction ray | 2 |
| `test_beat_ordering` | one out-of-order beat silently never plays | 3 |
| `test_cone_fov` | the FOV slider cannot widen a free-safe band | 3 |
| `test_flicker_rate` | the 3 Hz accessibility limit, **measured** | 3 |
| `test_highlight_tracks_cone` | fairness rule 10's visual layer (plus a **manual** in-engine check — no test can tell you a visual is invisible) | 3 |
| `test_same_event_exclusion` | two concurrent E1s doubling the flicker past 3 Hz | 4 |
| `test_arrival_punctuality` | the bus is not 15.02 s late every night | 4 |
| `test_stations` | all four cap stations within 32 m of the **shelter centre** | 4 |
| `test_no_free_band` | fairness rule 8: no angle where the figure is frozen for free | 4 |
| `test_night_start_state` | a night never inherits the previous night's lamp level | 4 |
| `test_night1_cannot_kill` | fairness rule 1 — **60 s stare**. This one shipped broken once | 4 |
| `test_night1_sign` | Night 1 warns, never kills | 4 |
| `test_restart` | the run-id guard; no stale coroutine resumes | 4 |
| `test_bus_door_x` | gap G3 — the door is at x = 8.5, not 1.4 m past the lethal sign line | 4 |
| `test_night2_cannot_kill` | Night 2 cannot kill by gaze | 5 |
| `test_night2_sign_lethal` | Night 2's sign line does kill | 5 |
| `test_night3_gaze_timing` | cap at 25.5–26.6 s, death at 35.8–37.0 s | 6 |
| `test_three_gates` | each of `gaze_lethal` / `armed` / `at_cap()` alone prevents death | 6 |
| `test_pause` | pausing during the silence beat restores Weather to 0 dB | 6 |
| `test_no_infinite_ending` | fairness rule 9 — `still_waiting` is terminal | 6 |
