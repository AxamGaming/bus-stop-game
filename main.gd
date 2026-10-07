extends Node3D
# main.gd -- attach to the Main node.
# Night 1 spine: gaze loop, beats via the Director, clean night end, restart on fail.
#
# The night's beats are built inline here so no .tres is needed yet. When you add
# Night 2 and Night 3, move each night's NightDef to its own .tres and put them in
# an Array[NightDef] export; run_night() then takes the array index.

@export var director: Director
@export var figure: FogFigure
@export var gaze: GazeMonitor
@export var lamp: LampController
@export var clock: NightClock
@export var tracker: LookAtTracker
@export var player: Node3D
@export var interaction: PlayerInteraction
@export var sign_line: Area3D

# Beat sheet timings (GDD 11). Real values; use the debug kit for fast tests.
@export var figure_appears_at := 40.0     # 0:40 -- figure appears
@export var stare_lesson_at := 150.0      # 2:30 -- stare lesson beat
@export var bus_arrives_at := 300.0       # 5:00 -- the bus arrives
@export var post_arrival_seconds := 30.0  # decision window

var _night: NightDef
var _ctx: EventContext

func _ready() -> void:
	Game.ending_triggered.connect(_on_ending)
	clock.arrived.connect(_on_arrived)
	director.event_started.connect(_on_director_event_started)
	if sign_line:
		sign_line.warned.connect(_on_sign_warned)

	# The game opens on the black rectangle that fade.tscn starts with.
	# show_card fades "Night 1" in, holds, then fades text + black out together
	# and reveals the world. run_night() must be called before show_card so the
	# night is already ticking when the black fades out -- otherwise the clock
	# would start after the card and the beat sheet would be out of sync.
	run_night(_build_night(1))
	await Fade.show_card("Night 1", 2.0, 0.5, 0.8)

# ---- night lifecycle ----

func run_night(def: NightDef) -> void:
	_night = def
	Game.begin_night(def.index)

	if figure:
		figure.configure(def.figure_cap_index, def.breach_enabled)
	if gaze:
		gaze.reset()
		gaze.configure(def)
	if lamp:
		lamp.reset()
	if sign_line:
		sign_line.configure(def.sign_lethal)

	# A3: tell every world object with per-night appearance which night it
	# is. This runs AFTER the gameplay systems are configured and BEFORE
	# the clock starts -- the night's initial state (poster text, timetable
	# text, etc.) is correct before the first tick. The swap happens behind
	# the fade's black rectangle (the caller fades to black before calling
	# run_night), so the player never sees the text change.
	_apply_night_content(def.index)

	# Build the event context fresh each night so nothing leaks across restarts.
	_ctx = EventContext.new()
	_ctx.lamp = lamp
	_ctx.player = player
	_ctx.figure = figure
	_ctx.clock = clock
	_ctx.tracker = tracker
	_ctx.world = self

	clock.start(def)
	director.start_night(def, _ctx)

	print("[main] Night %d started. Bus arrives at %.0fs." % [def.index, def.real_seconds])

# ---- signal handlers ----

func _on_director_event_started(e: HorrorEvent) -> void:
	if e.intensity >= 2 and interaction != null:
		interaction.cancel_lean()
	print("[main] event started: ", e.id)

func _on_sign_warned() -> void:
	if lamp:
		lamp.set_flicker(0.2)
		await get_tree().create_timer(1.5, false).timeout
		if lamp:
			lamp.set_flicker(1.0)
	var t := player.get_node_or_null("Tether") if player else null
	if t and t.has_method("nudge_toward"):
		var centre := get_tree().get_first_node_in_group("bus_stop_centre") as Node3D
		if centre:
			t.nudge_toward(centre.global_position, 4.0, 0.6)
	print("[main] sign warning")

func _on_arrived() -> void:
	director.stop()
	print("[main] bus passes the stop -- decision window open for %.0fs" % _night.post_arrival_seconds)
	await get_tree().create_timer(_night.post_arrival_seconds, false).timeout
	if Game.state == Game.State.NIGHT:
		_window_closed(_night)

func _window_closed(def: NightDef) -> void:
	match def.index:
		1, 2:
			# Night transition. Sequence:
			#   1. fade to black (0.8 s) -- caller-driven, not inside show_card
			#   2. text fades in over 0.5 s
			#   3. mid_action fires: run_night() sets up the next night behind
			#      the black. Figure resets (invisible), clock resets to 11:3x,
			#      lamp resets to 1.0, director re-queues the new beats.
			#   4. hold 2 s with the card visible
			#   5. text + black fade out together over 0.8 s
			#      -- the world that gets revealed is the NEW night, not the old
			#         night's end state
			Game.state = Game.State.TRANSITION
			await Fade.fade_out(0.8)
			var next_idx := def.index + 1
			await Fade.show_card("Night %d" % next_idx, 2.0, 0.5, 0.8,
				func() -> void: run_night(_build_night(next_idx)))
		3:
			Game.trigger_ending(&"still_waiting")
		_:
			push_error("No NightDef with index %d" % def.index)

func _on_ending(id: StringName, variant: StringName) -> void:
	director.stop()
	AudioHub.restore_weather(1.0)
	print("[main] ENDING: ", id, "  variant: ", variant)

	# Terminal endings: the run is over. Do NOT restart the night.
	#   still_waiting  -- fairness rule 9. The next bus is at 11:47 PM.
	#   right_bus      -- the final bus. Credits / ending card flow goes here
	#                     (see GDD 10 "Ending 5"; not wired in A1).
	if id == &"still_waiting":
		print("[main] terminal ending -- run over")
		return
	if id == &"right_bus":
		print("[main] -> credits")
		return

	# Non-terminal ending: let the beat land for 2 s, fade out, restart the SAME
	# night (fairness rule 5, < 5 s), fade back in.
	await get_tree().create_timer(2.0, false).timeout
	Game.state = Game.State.TRANSITION
	await Fade.fade_out(0.8)
	run_night(_night)
	await Fade.fade_in(0.8)

# ---- night construction ----

# Per-night flags from data/night_def.gd (GDD 18). The debug-scaled timings
# (bus_arrives_at / post_arrival_seconds, exported on the Main node for fast
# testing) are reused for all three nights; swap them for the GDD values
# (300/380/405 s, 30/45/60 s) when the .tres files are authored and the debug
# kit is no longer needed. Beats: Night 1's sheet is reused for Nights 2 and 3
# as a placeholder until their authored beats exist -- the Director still has
# something to schedule, and the per-night *stakes* (cap index, lethal gates)
# are correct, which is what actually makes later nights worse.
func _build_night(idx: int) -> NightDef:
	var n := NightDef.new()
	n.index = idx
	n.real_seconds = bus_arrives_at
	n.post_arrival_seconds = post_arrival_seconds
	n.breach_enabled = false
	match idx:
		1:
			n.figure_cap_index = 1
			n.gaze_lethal = false
			n.sign_lethal = false
			n.beats = _build_night_1_beats()
		2:
			n.figure_cap_index = 2
			n.gaze_lethal = false
			n.sign_lethal = true
			n.beats = _build_night_2_beats()
		3:
			n.figure_cap_index = 3
			n.gaze_lethal = true
			n.sign_lethal = true
			n.beats = _build_night_3_beats()
		_:
			push_error("[main] no NightDef for index %d" % idx)
			n.figure_cap_index = 1
			n.gaze_lethal = false
			n.sign_lethal = false
			n.beats = _build_night_1_beats()
	return n

# ---- A3: per-night content ----

# Tell every world object with per-night appearance which night it is. Each
# object implements set_night(idx) -- synchronous, idempotent, no Game refs.
# We use get_node_or_null() + has_method() (duck typing) so main.gd compiles
# and runs even before every object exists. Add a new object's set_night call
# the moment the object exists -- nothing breaks in between.
#
# Why explicit wiring instead of call_group("night_content", ...):
#   - call_group has a documented failure mode (Godot #43362): mutating the
#     tree/group during the call can skip nodes. set_night itself doesn't
#     mutate the tree, but a future set_night that spawns/hides children
#     would hit this.
#   - Explicit wiring gives ordering control and one file to read.
#   - The list is small (poster, timetable, eventually bus + stranger). A
#     group broadcast saves nothing at this scale.
func _apply_night_content(idx: int) -> void:
	var poster := get_node_or_null("BusStop/PosterBody")
	if poster != null and poster.has_method("set_night"):
		poster.set_night(idx)

	var timetable := get_node_or_null("BusStop/TimetableBody")
	if timetable != null and timetable.has_method("set_night"):
		timetable.set_night(idx)

	# Uncomment when these objects exist (B6 bus rig, B4 stranger):
	# var bus := get_node_or_null("Bus")
	# if bus != null and bus.has_method("set_night"):
	#         bus.set_night(idx)
	# var stranger := get_node_or_null("BenchStranger")
	# if stranger != null and stranger.has_method("set_night"):
	#         stranger.set_night(idx)

# ---- beat sheet construction ----

func _build_night_1_beats() -> Array[BeatDef]:
	var out: Array[BeatDef] = []

	# 0:40 -- figure appears (structural, intensity 2)
	out.append(_authored(figure_appears_at, 2,
		_load_event("res://events/beat_figure_appear.tscn",
			&"beat_figure_appear", 2, 1, 3)))

	# 1:30 -- distant engine, no bus
	out.append(_authored(90.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))

	# 2:30 -- stare lesson (a flicker for now; a dedicated event comes later)
	out.append(_authored(stare_lesson_at, 2,
		_load_event("res://events/e01_lamp_flicker.tscn",
			&"e01_lamp_flicker", 2, 1, 3)))

	# 4:00 -- second engine approach before the bus arrives
	out.append(_authored(240.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))

	return out

func _build_night_2_beats() -> Array[BeatDef]:
	# Placeholder. Real Night 2 beats come with the bus rig (B6) and the
	# stranger (B4). For now: same shape as Night 1, but the stare-lesson
	# flicker is moved to 3:00 so you can tell the nights apart in the log
	# and confirm the per-night beat routing actually works.
	var out: Array[BeatDef] = []
	out.append(_authored(figure_appears_at, 2,
		_load_event("res://events/beat_figure_appear.tscn",
			&"beat_figure_appear", 2, 1, 3)))
	out.append(_authored(90.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))
	out.append(_authored(180.0, 2,   # 3:00, not 2:30 -- tells Night 2 from Night 1
		_load_event("res://events/e01_lamp_flicker.tscn",
			&"e01_lamp_flicker", 2, 1, 3)))
	return out

func _build_night_3_beats() -> Array[BeatDef]:
	# Placeholder. Real Night 3 beats come with the silence beat (S3) and
	# the real bus (S3). For now: a long quiet night with one early engine
	# and a late flicker, to feel different from Nights 1 and 2.
	var out: Array[BeatDef] = []
	out.append(_authored(figure_appears_at, 2,
		_load_event("res://events/beat_figure_appear.tscn",
			&"beat_figure_appear", 2, 1, 3)))
	out.append(_authored(60.0, 1,    # 1:00, earlier -- the night is worse
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))
	out.append(_authored(210.0, 2,   # 3:30
		_load_event("res://events/e01_lamp_flicker.tscn",
			&"e01_lamp_flicker", 2, 1, 3)))
	return out

func _authored(time_sec: float, intensity: int, event: HorrorEvent) -> BeatDef:
	var b := BeatDef.new()
	b.time_sec = time_sec
	b.kind = BeatDef.Kind.AUTHORED
	b.event = event
	b.max_delay = 40.0
	b.punctual = false
	return b

func _load_event(path: String, id: StringName, intensity: int, min_n: int, max_n: int) -> HorrorEvent:
	var e := HorrorEvent.new()
	e.id = id
	e.scene = load(path)
	e.intensity = intensity
	e.min_night = min_n
	e.max_night = max_n
	return e
