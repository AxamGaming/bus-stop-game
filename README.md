# A2 + A3 — Per-Night Beats + Content Hook

Drop-in patch for the bus-stop-game repo. Implements:
- **A2**: per-night beat builders (Night 2 and Night 3 no longer play Night 1's beats)
- **A3**: the `set_night(idx)` interface for per-night world content (poster + timetable)

## Files

### New
- `world/poster.gd` — extends `Interactable`, adds `set_night(idx)`. Night 1: water-damaged. Night 2: partial text. Night 3: the yellow-raincoat payoff.
- `world/poster.gd.uid` — Godot UID sidecar
- `world/timetable.gd` — extends `Interactable`, adds `set_night(idx)`. Night 1: rules smudged. Night 2+: rules legible.
- `world/timetable.gd.uid` — Godot UID sidecar
- `tests/test_a3_content.gd` — unit test: instantiates bus_stop, calls `set_night(1/2/3)` on both objects, asserts the Label3D text matches the expected strings. Also checks idempotency.
- `tests/test_a3_content.tscn` — the test scene

### Modified
- `world/bus_stop.tscn` — PosterBody and TimetableBody now use `poster.gd` / `timetable.gd` instead of the base `interactable.gd`. The Label3D text defaults are set to Night 1 content (smudged timetable, water-damaged poster) so the scene is correct even before `set_night` runs.
- `main.gd` — three additions:
  1. `_apply_night_content(idx)` function: explicit duck-typed wiring to every per-night object
  2. Call to `_apply_night_content(def.index)` inside `run_night()`, after the gameplay systems are configured and before the clock starts
  3. `_build_night_2_beats()` and `_build_night_3_beats()`, routed in the `_build_night(idx)` match

## How to install

Copy these files over your repo (paths match the repo layout):

    cp main.gd /path/to/bus-stop-game/
    cp world/poster.gd world/poster.gd.uid world/timetable.gd world/timetable.gd.uid world/bus_stop.tscn /path/to/bus-stop-game/world/
    cp tests/test_a3_content.gd tests/test_a3_content.tscn /path/to/bus-stop-game/tests/

Or extract this zip on top of your checkout — the paths inside match the repo.

## Validation (already run, all green)

- `parseall`: **34/34** scripts compile, 0 failures (was 32, +2 for the new scripts)
- `tests/run_all.sh`: **2/2** test scenes pass
- `test_a3_content`: **8/8** assertions pass (poster × 3 nights + idempotent, timetable × 3 nights + idempotent)
- Headless run of `res://main.tscn`: Night 1 (4 beats) → Night 2 (3 beats, flicker at 3:00 not 2:30) → Night 3 (3 beats, engine at 1:00) → `still_waiting` terminal ending. Zero runtime errors.

## Design rationale (informed by horror-game research)

### Why `extends Interactable` (script inheritance) instead of composition
- Godot forums endorse **script** inheritance (`extends Interactable`); only **scene** inheritance / editable-children is discouraged.
- The poster and timetable need BOTH the Interactable behaviour (tap-to-read lean-in) AND the per-night text swap. Script inheritance gives both in one node.
- For pure-data swaps (no behaviour change), composition with a `NightContent` Resource would be more idiomatic — but that's a refactor for later, not now.

### Why `set_night(idx)` is synchronous, not a signal broadcast
- **Signal-based broadcast for initial state is an anti-pattern** (Bugnet 2026, KidsCanCode, Godot #72024): a parent emitting `night_changed` in `_ready()` can fire before child listeners connect or before their `@onready` vars resolve. Result: missed updates, null refs.
- `set_night` is the analogue of Amnesia's `OnEnter` callback — synchronous, re-runnable, called by the coordinator. The coordinator (`main.gd`) is the common parent, which (per KidsCanCode's "call down, signal up" rule) is the correct place to wire children.

### Why explicit wiring in `main.gd` instead of `call_group("night_content", ...)`
- `call_group` has a **documented failure mode** (Godot GitHub issue, Dec 2020): mutating the tree/group during the call can skip nodes. `set_night` itself doesn't mutate the tree today, but a future `set_night` that spawns/hides children (e.g. the stranger appearing on Night 2) would hit this.
- Explicit wiring gives ordering control and one file to read. The list is small (poster, timetable, eventually bus + stranger) — a group broadcast saves nothing at this scale.

### Why the swap happens behind the fade (no animation)
- The night transition fades to black, then `run_night()` (passed as `mid_action` to `Fade.show_card`) sets up the new night behind the black, then the fade reveals the new night. The player never sees the text change.
- Animating the swap would waste frames and risk a visible pop if the fade is shorter than the animation. Silent Hill's Otherworld transition is the reference: the world changes while you can't see it, then is revealed.

### Why the Night 1 timetable is smudged
- GDD §9: Night 1 shows the header and time but smudges the three rules. The player fails Night 1 without knowing the rules; Night 2 reveals them. The smudge is the **teaching device** — "there is something to read here, but not yet." This is the core rule-learning loop of the game.

### Horror-game references that informed this design
- **Silent Hill Otherworld** (Silent Hill Wiki): same geometry, state-swapped in place. The bus-stop = the persistent geometry; `set_night` = the state swap.
- **FNAF nights** (FNAF Wiki): same office scene, different params per night. The "Night X" card is a UI overlay, not a scene boundary. Direct precedent for `set_night(idx)` as a parameter application, not a scene change.
- **Amnesia HPL2 `OnEnter`** (Frictional Games Wiki): synchronous re-configuration callback on every (re)entry. Direct analogue of `set_night` — re-runnable, called by the engine/coordinator, not signal-driven.
- **Resident Evil RDT** (ArchiveTeam): one data file per room + runtime flags selecting active content. Validates "same scene + flag-driven content" architecture.

## What is NOT in this patch

- The bus rig (B6) and stranger (B4) — their `set_night` calls are commented out in `_apply_night_content` until those objects exist.
- The ending card flow for `right_bus` (still deferred from A1).
- A `.tres` per-night refactor — the spec explicitly says skip this; `_build_night(idx)` is functionally equivalent.

## API summary

    # In any world object with per-night appearance:
    extends Interactable
    func set_night(idx: int) -> void:
        match idx:
            1: ...
            2: ...
            3: ...

    # In main.gd::run_night(), after gameplay config, before clock.start:
    _apply_night_content(def.index)

    # The wiring is explicit and duck-typed:
    var poster := get_node_or_null("BusStop/PosterBody")
    if poster != null and poster.has_method("set_night"):
        poster.set_night(idx)
