# B1–B7: Bus Rig + Night 2/3 Events

Drop-in patch for the bus-stop-game repo. Implements B6 (bus rig), B7 (passing
bus), B5 (numberless bus), B4 (bench stranger), and B3 (bin radio). B1 (night
.tres) and B2 (timetable change event) are skipped per spec — they're optional.

## Files

### New
- `world/bus_rig.gd` + `.uid` + `.tscn` — the bus: primitive-shape body, doors, destination board, headlights, interior light, 4 audio players. Methods: `set_night()`, `arrive()`, `open_doors()`, `close_doors()`, `depart()`, `pass_by()`, `reset()`, `door_world_pos()`. Uses TRANS_QUAD+EASE_OUT for arrival (decelerate), TRANS_LINEAR for pass-by, TRANS_QUAD+EASE_IN for depart.
- `events/s1_passing_bus.gd` + `.uid` + `.tscn` — B7, Night 1. Bus drives past (9s), lamp blacks out at midpoint (4.5s), figure steps 0.5s into darkness.
- `events/s2_numberless_bus.gd` + `.uid` + `.tscn` — B5, Night 2. Bus arrives, opens doors, 45s decision window. Board → `wrong_bus` ending. Ignore → bus departs.
- `events/e07_bench_stranger.gd` + `.uid` + `.tscn` — B4, Nights 2+3. Seated silhouette on bench, appears only when player looks away (dot-product gaze detection, Slender/SCP-173 pattern). Hold E → `spoke_first` ending. Night 3 variant: head tilted toward player. `visible` + `enabled` paired to prevent phantom triggers.
- `events/e06_bin_radio.gd` + `.uid` + `.tscn` — B3, Nights 2+3. Plays voice fragment from the bin. Load-bearing for Rule 2 (the player has heard a voice before the stranger appears).

### Modified
- `main.gd` — wired bus into `_apply_night_content()`, added B7/B5/B3/B4 to beat sheets (scaled proportionally with `bus_arrives_at` so debug config produces sorted beats), added `_punctual()` helper for bus arrival beats, `_on_arrived()` waits one frame then for `director.is_busy()` before starting post-arrival window.
- `main.tscn` — added BusRig instance, wired `bus` export.
- `core/director.gd` — added `is_busy()` public method (prunes dead events, returns true if any live events remain).

## How to install

Copy these files over your repo (paths match the repo layout):

    cp main.gd main.tscn /path/to/bus-stop-game/
    cp core/director.gd /path/to/bus-stop-game/core/
    cp world/bus_rig.gd world/bus_rig.gd.uid world/bus_rig.tscn /path/to/bus-stop-game/world/
    cp events/*.gd events/*.gd.uid events/*.tscn /path/to/bus-stop-game/events/

Or extract this zip on top of your checkout.

## Validation (already run, all green)

- **parseall**: 40/40 scripts compile, 0 failures (+5 new: bus_rig, s1, s2, e06, e07)
- **tests/run_all.sh**: 2/2 test scenes pass
- **Headless Night 1**: figure(4s) → engine(9s) → flicker(19s) → engine(24s) → **s1_passing_bus(30s)**: bus pass-by + lamp blackout + figure step → 10s post-arrival → Night 2
- **Headless Night 2**: figure(3.2s) → **e06_bin_radio(6.3s)**: voice plays → engine(7.1s) → **e07_bench_stranger(18.2s)**: stranger appears when player looks away → **s2_numberless_bus(30s)**: numberless bus arrives → Night 3
- **Headless Night 3**: figure(3s) → engine(4.4s) → e06_bin_radio(5.9s) → e07_bench_stranger(18s, Night 3 variant) → flicker → still_waiting terminal ending

## Design decisions (research-informed)

### Bus rig: tween on position:x, not PathFollow3D
The road is straight (road.tscn runs along x-axis at z=-8). PathFollow3D adds complexity without benefit on a straight path. TRANS_QUAD+EASE_OUT for arrival reads as braking; TRANS_LINEAR for pass-by is constant speed; TRANS_QUAD+EASE_IN for depart reads as accelerating away. (Godot Tween docs; research confirmed TRANS_QUAD "starts quickly and slows down".)

### Stranger: dot-product gaze detection (Slender/SCP-173 pattern)
The stranger only appears when `camera.forward .dot(direction_to_bench) < 0.1` — the player is looking away. A 0.1 threshold gives margin so the stranger doesn't flicker at exactly 90°. Departure is also gaze-gated (symmetry: never see it arrive, never see it leave). Audio telegraph (cloth.wav creak) plays on reveal, drawing the player's attention to look back. (Research: Amnesia Gatherer pattern.)

### visible + enabled pairing
When the stranger is hidden, BOTH `visible=false` AND `enabled=false` are set. Setting only `visible=false` leaves a phantom trigger (the interaction ray still hits the StaticBody3D). (Research: Godot Node docs confirm `visible=false` stops rendering but not processing.)

### Beat timings scaled proportionally with bus_arrives_at
GDD times (300/380/405s nights) are scaled by `bus_arrives_at/GDD_arrival` so the debug config (`bus_arrives_at=30s`) produces sorted beats at 4s, 9s, 15s, 24s, 30s instead of the unsorted 40s, 90s, 150s, 240s, 30s that triggered the assertion.

### _on_arrived() waits one frame before director.stop()
The clock's `arrived` signal and the director's `_process` both fire in the same frame. Without the one-frame wait, `director.stop()` would prevent the punctual bus beat from being queued. After the wait, the bus beat starts, then `director.stop()` prevents new beats, then `director.is_busy()` waits for the bus event to finish before starting the post-arrival window.

## What is NOT in this patch
- B1 (night_2.tres) — optional per spec, `_build_night(idx)` is functionally equivalent
- B2 (beat_timetable_change) — optional per spec, A3 hook already changes timetable at night start
- S3 (real bus with "47" board) — not yet built; Night 3 clean pass falls through to `still_waiting`
- Ending card flow for `right_bus` — still deferred
- External PSX 3D assets (elbolilloduro.itch.io) — itch.io download URLs require authenticated keys; spec says use primitives for first build anyway

## Audio credits
All audio is from the existing `audio/` folder (27 WAVs, already in the repo):
- engine_approach.wav, brake_hiss.wav, door_open.wav, door_close.wav, interior_hum.wav — bus rig
- voice_fragment_a.wav — bin radio (E6)
- cloth.wav — stranger bench creak (E7)
