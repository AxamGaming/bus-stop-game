extends CanvasLayer
# core/fade.gd -- autoload `Fade`. A1 (Fade + Title Card System).
#
# Owns ONE full-screen black ColorRect and ONE centred Label. Four public
# methods, nothing else. Sits above the HUD (layer 10) and the pause menu on
# layer 100, runs while paused (process_mode = ALWAYS) so a fade started from
# the pause menu still completes, and uses TRANS_SINE / EASE_IN_OUT so the
# fade reads as the light draining rather than a hard cut.
#
# Public API (every method is awaitable via `await Fade.<method>(...)`):
#   await Fade.fade_out(duration)                  -> screen is black
#   await Fade.fade_in(duration)                   -> screen is visible
#   await Fade.show_card(text, hold, in_d, out_d)  -> fade out, hold text, fade in
#   Fade.reset()                                   -> kill any tween, go transparent
#
# State machine:
#   IDLE      -- rect transparent, label hidden
#   OPAQUE    -- rect opaque, label hidden
#   ANIMATING -- a tween is running (either direction); label state is caller-driven
#
#   IDLE  -- fade_out()  -->  ANIMATING  --finished-->  OPAQUE
#   OPAQUE -- fade_in()  -->  ANIMATING  --finished-->  IDLE
#   OPAQUE -- show_card() --> (hold) --> fade_in() --> IDLE
#
# Guards:
#   - fade_out() while OPAQUE     -> no-op
#   - fade_in()  while IDLE        -> no-op
#   - show_card() while not OPAQUE -> fades out first, then shows
#   - any method mid-tween         -> kill the tween, start the new one (no queueing)
#   - reset() at any time          -> tween killed, snap to transparent, state IDLE
#
# Mouse: BlackRect is MOUSE_FILTER_STOP while opaque (blocks clicks on the world
# behind the fade) and MOUSE_FILTER_IGNORE while transparent. CardLabel is
# always IGNORE. The HUD crosshair therefore disappears behind the fade, which
# is correct: there is nothing to click during a transition.
#
# Pause: process_mode = ALWAYS, so a fade triggered from the pause menu runs.
# The caller is responsible for unpausing first if they want the world to be
# visible behind the fade. The hold timer inside show_card() uses
# create_timer(hold, false) -- process_always = false -- so it freezes with the
# game when paused and resumes from where it was (matches AudioHub's pattern and
# the GDD rule for create_timer throughout the codebase).

const STATE_IDLE := 0
const STATE_OPAQUE := 1
const STATE_ANIMATING := 2
const DUCK_DB := -20.0    # world is audible but held back during a transition
const DEFAULT_FADE := 0.8
const DEFAULT_HOLD := 2.0
const START_FADE := 1.2          # main.gd::_ready() uses this for the opening fade-in

@onready var _rect: ColorRect = $BlackRect
@onready var _label: Label = $CardLabel

var _tween: Tween
var _state := STATE_IDLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	# The scene starts with BlackRect opaque, so the very first frame the game
	# renders is black. State is OPAQUE, not IDLE -- show_card() will fade the
	# text in on the black and then fade text + black out together.
	_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_label.visible = false
	_label.modulate.a = 0.0
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state = STATE_OPAQUE

# ---------- public API ----------

func fade_out(duration: float = DEFAULT_FADE) -> void:
	if _state == STATE_OPAQUE:
		return
	_kill_tween()
	_state = STATE_ANIMATING
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	# Duck the master bus. Duration matches the fade so the audio and the
	# visual fall together; the design does not want silence (GDD 16 #4).
	if AudioHub:
		AudioHub.duck(DUCK_DB, maxf(duration, 0.1))
	if duration <= 0.0:
		_rect.modulate.a = 1.0
		_state = STATE_OPAQUE
		return
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_rect, "modulate:a", 1.0, duration)
	await _tween.finished
	if _state == STATE_ANIMATING:
		_state = STATE_OPAQUE


func fade_in(duration: float = DEFAULT_FADE) -> void:
	if _state == STATE_IDLE:
		return
	_kill_tween()
	_state = STATE_ANIMATING
	_label.visible = false
	_label.modulate.a = 0.0
	# Restore the master bus. Also matches the fade duration.
	if AudioHub:
		AudioHub.unduck(maxf(duration, 0.1))
	if duration <= 0.0:
		_rect.modulate.a = 0.0
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_state = STATE_IDLE
		return
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_rect, "modulate:a", 0.0, duration)
	await _tween.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _state == STATE_ANIMATING:
		_state = STATE_IDLE

func show_card(text: String, hold: float = DEFAULT_HOLD,
		text_fade: float = 0.5,
		out_duration: float = DEFAULT_FADE,
		mid_action: Callable = Callable()) -> void:
	# The night-card beat, restructured:
	#   1. assume the screen is black (fade_out first if it isn't)
	#   2. text fades IN over `text_fade`
	#   3. `mid_action.call()` -- the caller's hook for setting up the next
	#      night behind the black (run_night). Optional; skipped if invalid.
	#   4. hold the card for `hold` seconds
	#   5. text AND the black rectangle fade OUT together over `out_duration`
	#      -- the world is revealed at the same moment the text disappears
	#
	# The old "text appears instantly, text disappears instantly, then the
	# screen fades" sequence is gone. If you need it back, keep a separate
	# method; don't add flags to this one.
	if _state != STATE_OPAQUE:
		await fade_out(DEFAULT_FADE)
		if _state != STATE_OPAQUE:
			return

	_kill_tween()

	# Step 2: text fades in.
	_label.text = text
	_label.visible = true
	_label.modulate.a = 0.0
	if text_fade > 0.0:
		_tween = create_tween()
		_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_label, "modulate:a", 1.0, text_fade)
		await _tween.finished
	else:
		_label.modulate.a = 1.0

	# Step 3: caller hook. Use this to run_night() behind the black.
	if mid_action.is_valid():
		mid_action.call()

	# Step 4: hold. process_always = false so the hold freezes with the game.
	if hold > 0.0:
		await get_tree().create_timer(hold, false).timeout

	# reset() during the hold -> bail.
	if _state == STATE_IDLE:
		return

	# Step 5: fade the text AND the black rect out together. Restore the audio
	# as the world is revealed.
	if AudioHub:
		AudioHub.unduck(maxf(out_duration, 0.1))
	if out_duration > 0.0:
		_tween = create_tween()
		_tween.set_parallel(true)
		_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_label, "modulate:a", 0.0, out_duration)
		_tween.tween_property(_rect, "modulate:a", 0.0, out_duration)
		await _tween.finished
	else:
		_label.modulate.a = 0.0
		_rect.modulate.a = 0.0

	_label.visible = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state = STATE_IDLE

func reset() -> void:
	# Kill any in-flight tween and snap to transparent. Use this any time you
	# jump backwards -- restarting Night 1 from the menu, wiping the save, etc.
	# Without it a stray tween from a previous night could still be running when
	# the new night starts, causing a flicker.
	_kill_tween()
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	_label.modulate.a = 0.0
	_state = STATE_IDLE


# ---------- internals ----------

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
