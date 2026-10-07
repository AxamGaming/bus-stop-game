class_name Director extends Node
# core/director.gd -- GDD 13 "The Director".
# A scheduler, not an AI. Reads a NightDef and plays from it.

signal event_started(e: HorrorEvent)
signal event_ended(e: HorrorEvent)

var ctx: EventContext
var night: NightDef
var running := false

var _t := 0.0
var _next := 0
var _pending: Array[BeatDef] = []
var _live: Dictionary = {}         # EventBase -> HorrorEvent
var _last_start: Dictionary = {}   # StringName -> float
var _calm_until := 0.0
var _last_id: StringName = &""

func _ready() -> void:
	add_to_group(&"director")

func start_night(n: NightDef, c: EventContext) -> void:
	# Free any events from a previous night before starting a new one.
	# Without this, a night restart leaves orphaned events running: an
	# e07_bench_stranger from the previous attempt reveals a second stranger,
	# an s2_numberless_bus keeps driving a bus that has no business being there.
	kill_all()

	night = n
	ctx = c
	_assert_beats_sorted()
	_t = 0.0
	_next = 0
	_pending.clear()
	_last_start.clear()
	_calm_until = 0.0
	_last_id = &""
	running = true
	print("[director] night %d started, %d beats, arrival %.0fs" % [n.index, n.beats.size(), n.real_seconds])

# Abort every live event and clear tracking. Called at the top of
# start_night() so no state leaks across a night restart.
func kill_all() -> void:
	for inst in _live.keys():
		if is_instance_valid(inst):
			inst.abort()
	_live.clear()
	_pending.clear()

# is_busy(id) -- with no argument, returns true if ANY event is live.
# With an id, returns true only if that specific event is live. main.gd
# uses the id form so the bus-arrival wait is not blocked by an unrelated
# event (e.g. a stranger still lingering on the bench).
func is_busy(id_filter: StringName = &"") -> bool:
	for inst in _live.keys():
		if not is_instance_valid(inst):
			_live.erase(inst)
	if id_filter == &"":
		return _live.size() > 0
	for res in _live.values():
		if res.id == id_filter:
			return true
	return false
	
func stop() -> void:
	running = false

func _assert_beats_sorted() -> void:
	for i in range(1, night.beats.size()):
		assert(night.beats[i].time_sec >= night.beats[i - 1].time_sec,
			"NightDef %d: beats must be sorted ascending (index %d)" % [night.index, i])

func _process(delta: float) -> void:
	if not running:
		return
	_t += delta
	while _next < night.beats.size() and night.beats[_next].time_sec <= _t:
		_pending.append(night.beats[_next])
		_next += 1
	for b in _pending.duplicate():
		if _try_beat(b):
			_pending.erase(b)

func _try_beat(b: BeatDef) -> bool:
	var e: HorrorEvent = b.event
	if b.kind == BeatDef.Kind.FILL:
		e = _pick(b.pool)
		if e == null or not _can_start(e, false):
			return true           # optional: skip quietly
	elif b.punctual:
		pass                       # structural: never delayed
	elif not _can_start(e, _t - b.time_sec >= b.max_delay):
		return false               # authored: wait for a clear window
	_start(e)
	return true

func _can_start(e: HorrorEvent, force: bool) -> bool:
	# prune dead entries
	for inst in _live.keys():
		if not is_instance_valid(inst):
			_live.erase(inst)
	# never two of the same id
	for live_res in _live.values():
		if live_res.id == e.id:
			return false
	# hard: never two intensity-3
	for live_res in _live.values():
		if e.intensity >= 3 and live_res.intensity >= 3:
			return false
		if not force and e.intensity >= 2 and live_res.intensity >= 2:
			return false
	# calm window after intensity-2+ ends
	if not force and e.intensity >= 2 and _t < _calm_until:
		return false
	return true

func _pick(pool: Array[HorrorEvent]) -> HorrorEvent:
	var valid: Array[HorrorEvent] = []
	for e in pool:
		if night.index < e.min_night or night.index > e.max_night:
			continue
		if e.id == _last_id:
			continue
		if _t - _last_start.get(e.id, -9999.0) < e.cooldown:
			continue
		valid.append(e)
	if valid.is_empty():
		return null
	var total := 0.0
	for e in valid:
		total += e.weight
	var roll := randf() * total
	for e in valid:
		roll -= e.weight
		if roll <= 0.0:
			return e
	return valid.back()

func _start(e: HorrorEvent) -> void:
	_last_id = e.id
	_last_start[e.id] = _t
	assert(e.scene != null, "HorrorEvent '%s' has no scene" % e.id)
	var inst := e.scene.instantiate() as EventBase
	assert(inst != null, "Root of '%s' is not an EventBase" % e.scene.resource_path)
	_live[inst] = e
	add_child(inst)
	inst.finished.connect(_on_finished.bind(inst, e))
	inst.run(ctx)
	event_started.emit(e)
	print("[director] started '%s' (intensity %d) at %.1fs" % [e.id, e.intensity, _t])

func _on_finished(_id: StringName, inst: EventBase, e: HorrorEvent) -> void:
	_live.erase(inst)
	if e.intensity >= 2:
		_calm_until = _t + 15.0
	event_ended.emit(e)
	print("[director] finished '%s' at %.1fs" % [e.id, _t])
