# A1 — Fade + Title Card System

Drop-in patch for the bus-stop-game repo. Adds the A1 fade + title-card
autoload described in the A1 spec, and wires it into main.gd so the
Night 1 → Night 2 → Night 3 spine actually transitions.

## Files

### New
- `core/fade.gd`        — the autoload script (state machine + async API)
- `core/fade.gd.uid`    — Godot UID sidecar
- `core/fade.tscn`      — CanvasLayer + BlackRect + CardLabel scene

### Modified
- `project.godot`       — registers `Fade` as the 5th autoload
- `core/game.gd`        — adds `TRANSITION` to the `State` enum
- `main.gd`             — opens from black; night transitions fade+card+set-up-behind-black+fade-in; non-terminal endings fade out → restart → fade in

## How to install

Copy these files over your repo (preserves directory structure):

    cp -r core/fade.gd core/fade.gd.uid core/fade.tscn /path/to/bus-stop-game/core/
    cp core/game.gd /path/to/bus-stop-game/core/game.gd
    cp main.gd /path/to/bus-stop-game/main.gd
    cp project.godot /path/to/bus-stop-game/project.godot

Or just extract this zip on top of your bus-stop-game checkout — the
paths inside the zip match the repo layout.

## Validation (already run, all green)

- `parseall`: 32/32 scripts compile, 0 failures (includes `core/fade.gd`)
- `tests/run_all.sh`: 1/1 test scenes pass
- Headless boot of `res://main.tscn`: Night 1 → Night 2 transition fires
  correctly (clock hits 11:47, bus arrives, card shows, Night 2 starts
  with the clock reset, zero runtime errors)

## API

    await Fade.fade_out(duration)                              # -> black
    await Fade.fade_in(duration)                               # -> visible
    await Fade.show_card(text, hold, in_d, out_d, stay_opaque) # full beat
    Fade.reset()                                               # snap to transparent

Defaults: fade 0.8 s, hold 2.0 s, opening fade-in 1.2 s (Fade.START_FADE).

## One deliberate spec deviation

`show_card()` gained a `stay_opaque: bool = false` parameter. Without it,
the fade-in (inside show_card) would reveal the *old* night's end state
before `run_night()` resets the figure/clock — a visible pop. With it, the
night setup happens behind the black and the fade-in reveals the new night
cleanly, which is how Silent Hill and Resident Evil handle chapter
transitions. See the comment block in `main.gd::_window_closed()` for the
full rationale.

## What is NOT in this patch (per spec)

- Ending card flow for `right_bus` (spec §4.7 defers this)
- Typewriter effect, sound stings, shaders, per-night fade colours
  (spec §7 explicitly forbids all of these for the night card)
