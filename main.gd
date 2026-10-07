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

	# Build Night 1 inline.
	var n := NightDef.new()
	n.index = 1
	n.real_seconds = bus_arrives_at
	n.post_arrival_seconds = post_arrival_seconds
	n.figure_cap_index = 1
	n.gaze_lethal = false
	n.sign_lethal = false
	n.breach_enabled = false
	n.beats = _build_night_1_beats()

	run_night(n)

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
			print("[main] Night %d clean. In the full build: fade to Night %d." % [def.index, def.index + 1])
			# Real version, once you have a fade + card system:
			#   await _fade_and_card("Night %d" % (def.index + 1))
			#   run_night(build_night(def.index + 1))
		3:
			Game.trigger_ending(&"still_waiting")
		_:
			push_error("No NightDef with index %d" % def.index)

func _on_ending(id: StringName, variant: StringName) -> void:
	director.stop()
	AudioHub.restore_weather(1.0)
	print("[main] ENDING: ", id, "  variant: ", variant)
	if id == &"right_bus":
		print("[main] -> credits")
		return
	await get_tree().create_timer(2.0, false).timeout
	# Every other ending restarts the SAME night (fairness rule 5, < 5 s).
	run_night(_night)

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
