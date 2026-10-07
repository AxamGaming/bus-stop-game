# Thank You for Waiting

First-person PSX psychological horror. Three nights at one bus stop, one lamp, three
rules printed on a timetable. Built solo in Godot 4.7 (GDScript).

> You wait alone for the last bus on a rainy night, and the only way to survive is to
> obey three rules printed on a timetable — while the thing in the fog moves every time
> you look away, and the lamp that keeps you safe dies every time you look at it.

## Read these, in this order

1. **`docs/GDD_v1.9.md`** — the design document. It is the single source of truth and it
   is unusually specific: exact coordinates, exact timings, exact code.
2. **`PROJECT_STRUCTURE.md`** — every folder and file this project needs, what each one
   does, which GDD section it comes from, and the week to build it in.
3. **`docs/BUILD_ORDER.md`** — the day-by-day sequence, starting with the two-day gaze
   loop that validates the whole concept.

## Quick start

```bash
godot --path . --import      # first run only: generates .godot/ and the import cache
godot --path .               # opens the editor
./tests/run_all.sh                                            # the automated checks (GDD 22)
```

The parse-all check runs **first** and covers every `.gd` in the project. Neither
`--import` (scans `class_name` only) nor `--check-only` (has no autoloads registered)
catches everything on its own.

## Non-negotiables

- **Night 1 cannot kill the player under any input.** Night 2 cannot kill by gaze.
- Gaze death needs all three gates: `NightDef.gaze_lethal` **and** `GazeMonitor.armed`
  **and** `figure.at_cap()`.
- Flicker stays under 3 Hz at the **default** setting — `MIN_CYCLE = 0.45`, measured not
  computed. Do not tighten it.
- Bus arrivals are `punctual` beats. Without that flag the bus is 15 s late, every night.
- `Interactable` extends `StaticBody3D`. `ray.get_collider()` returns the body.
- Build node subtrees **detached**, then `add_child()`. `@onready` resolves at tree entry.
- Never teleport the player out of the sign line. Displace over frames.
