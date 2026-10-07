extends Node3D
# main.gd -- attach to the Main node.
# Night 1 spine: gaze loop, beats via the Director, clean night end, restart on fail.

@export var director: Director
@export var figure: FogFigure
@export var gaze: GazeMonitor
@export var lamp: LampController
@export var clock: NightClock
@export var tracker: LookAtTracker
@export var player: Node3D
@export var interaction: PlayerInteraction
@export var sign_line: Area3D
@export var bus: Node3D
@export var player_spawn: Node3D

# Beat sheet timings. Real values; use the debug kit for fast tests.
@export var figure_appears_at := 40.0     # 0:40 -- figure appears
@export var stare_lesson_at := 150.0      # 2:30 -- stare lesson beat
@export var bus_arrives_at := 300.0       # 5:00 -- the bus arrives
@export var post_arrival_seconds := 30.0  # decision window

var _night: NightDef
var _ctx: EventContext
var _run_id := 0

func _ready() -> void:
	Game.ending_triggered.connect(_on_ending)
	clock.arrived.connect(_on_arrived)
	director.event_started.connect(_on_director_event_started)
	if sign_line:
		sign_line.warned.connect(_on_sign_warned)

	run_night(_build_night(1))
	await Fade.show_card("Night 1", 2.0, 0.5, 0.8)

# ---- night lifecycle ----

func run_night(def: NightDef) -> void:
	_run_id += 1
	_night = def
	Game.begin_night(def.index)

	# Reset player to the shelter so a night restart does not leave them
	# standing past the sign line (which would fire the sign ending again
	# on the very first frame of the new night).
	_reset_player_position()

	if figure:
		figure.configure(def.figure_cap_index, def.breach_enabled)
	if gaze:
		gaze.reset()
		gaze.configure(def)
	if lamp:
		lamp.reset()
	if sign_line:
		sign_line.configure(def.sign_lethal)

	_apply_night_content(def.index)

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
	
func _reset_player_position() -> void:
	if player == null:
		return
	var spawn := player_spawn
	if spawn == null:
		spawn = get_tree().get_first_node_in_group("bus_stop_centre") as Node3D
	if spawn == null:
		return
	(player as Node3D).global_position = spawn.global_position + Vector3(0, 0.1, 0)
	if player.has_method("stop_motion"):
		player.stop_motion()      # only if player.gd has this; optional

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
	var my_id := _run_id

	await get_tree().create_timer(0.1, false).timeout
	if my_id != _run_id:
		return
	director.stop()
	print("[main] bus arrival signal -- waiting for bus event to finish")

	# Wait ONLY for the bus event for this night, not for any event still
	# lingering (e.g. a stranger that hasn't departed yet). On Night 1 the
	# bus is s1_passing_bus, on Night 2 it's s2_numberless_bus, on Night 3
	# it's s3_real_bus.
	var bus_event_id: StringName = &""
	match _night.index:
		1: bus_event_id = &"s1_passing_bus"
		2: bus_event_id = &"s2_numberless_bus"
		3: bus_event_id = &"s3_real_bus"

	while director.is_busy(bus_event_id):
		await get_tree().create_timer(0.5, false).timeout
		if my_id != _run_id:
			return
	print("[main] bus event done")

	# Only Night 1 runs a post-arrival window from main. Nights 2 and 3 own
	# their decision windows inside the bus event.
	if _night.index != 2 and _night.index != 3:
		print("[main] decision window open for %.0fs" % _night.post_arrival_seconds)
		await get_tree().create_timer(_night.post_arrival_seconds, false).timeout
		if my_id != _run_id:
			return

	if Game.state == Game.State.NIGHT:
		_window_closed(_night)

func _window_closed(def: NightDef) -> void:
	match def.index:
		1, 2:
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
	var my_id := _run_id
	director.stop()
	AudioHub.restore_weather(1.0)
	print("[main] ENDING: ", id, "  variant: ", variant)

	if id == &"still_waiting":
		print("[main] terminal ending -- run over")
		return
	if id == &"right_bus":
		print("[main] -> credits")
		return

	await get_tree().create_timer(2.0, false).timeout
	if my_id != _run_id:
		return
	Game.state = Game.State.TRANSITION
	await Fade.fade_out(0.8)
	if my_id != _run_id:
		return
	run_night(_night)
	await Fade.fade_in(0.8)
	
# ---- night construction ----

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

func _apply_night_content(idx: int) -> void:
	var poster := get_node_or_null("BusStop/PosterBody")
	if poster != null and poster.has_method("set_night"):
		poster.set_night(idx)

	var timetable := get_node_or_null("BusStop/TimetableBody")
	if timetable != null and timetable.has_method("set_night"):
		timetable.set_night(idx)

	if bus != null and bus.has_method("set_night"):
		bus.set_night(idx)
	if bus != null and bus.has_method("reset"):
		bus.reset()

# ---- beat sheet construction ----

func _build_night_1_beats() -> Array[BeatDef]:
	var t := bus_arrives_at / 300.0
	var out: Array[BeatDef] = []
	out.append(_authored(t * 40.0, 2,
		_load_event("res://events/beat_figure_appear.tscn",
			&"beat_figure_appear", 2, 1, 3)))
	out.append(_authored(t * 90.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))
	out.append(_authored(t * 150.0, 2,
		_load_event("res://events/e01_lamp_flicker.tscn",
			&"e01_lamp_flicker", 2, 1, 3)))
	out.append(_authored(t * 240.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))
	out.append(_punctual(bus_arrives_at, 2,
		_load_event("res://events/s1_passing_bus.tscn",
			&"s1_passing_bus", 2, 1, 1)))
	return out

func _build_night_2_beats() -> Array[BeatDef]:
	var t := bus_arrives_at / 380.0
	var out: Array[BeatDef] = []
	out.append(_authored(t * 40.0, 2,
		_load_event("res://events/beat_figure_appear.tscn",
			&"beat_figure_appear", 2, 1, 3)))
	out.append(_authored(t * 80.0, 1,
		_load_event("res://events/e06_bin_radio.tscn",
			&"e06_bin_radio", 1, 2, 3)))
	out.append(_authored(t * 90.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))
	out.append(_authored(t * 180.0, 2,
		_load_event("res://events/e07_bench_stranger.tscn",
			&"e07_bench_stranger", 2, 2, 3)))
	out.append(_punctual(bus_arrives_at, 2,
		_load_event("res://events/s2_numberless_bus.tscn",
			&"s2_numberless_bus", 2, 2, 2)))
	return out

func _build_night_3_beats() -> Array[BeatDef]:
	var t := bus_arrives_at / 405.0
	var out: Array[BeatDef] = []
	out.append(_authored(t * 40.0, 2,
		_load_event("res://events/beat_figure_appear.tscn",
			&"beat_figure_appear", 2, 1, 3)))
	out.append(_authored(t * 60.0, 1,
		_load_event("res://events/e02_distant_engine.tscn",
			&"e02_distant_engine", 1, 1, 3)))
	out.append(_authored(t * 80.0, 1,
		_load_event("res://events/e06_bin_radio.tscn",
			&"e06_bin_radio", 1, 2, 3)))
	out.append(_authored(t * 150.0, 2,
		_load_event("res://events/e07_bench_stranger.tscn",
			&"e07_bench_stranger", 2, 3, 3)))
	out.append(_authored(t * 210.0, 2,
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

# A punctual beat fires at exactly time_sec with no delay. The `punctual`
# flag is checked BEFORE max_delay in Director._try_beat, so setting
# max_delay here would be dead code -- it is left at its Resource default.
func _punctual(time_sec: float, intensity: int, event: HorrorEvent) -> BeatDef:
	var b := BeatDef.new()
	b.time_sec = time_sec
	b.kind = BeatDef.Kind.AUTHORED
	b.event = event
	b.punctual = true
	return b

func _load_event(path: String, id: StringName, intensity: int, min_n: int, max_n: int) -> HorrorEvent:
	var e := HorrorEvent.new()
	e.id = id
	e.scene = load(path)
	e.intensity = intensity
	e.min_night = min_n
	e.max_night = max_n
	return e
