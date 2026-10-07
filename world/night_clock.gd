class_name NightClock extends Node
# world/night_clock.gd -- GDD 18
# Counts real seconds to the bus's arrival. Reads 11:47 exactly when the bus arrives,
# then freezes. The bus arrives at real_seconds, and the clock stops there.

signal minute_changed(minute: int)
signal arrived

var running := false
var _elapsed := 0.0
var _total := 300.0
var _start_minute := 35
var _last_minute := -1

func _ready() -> void:
	add_to_group(&"clock")

func start(def: NightDef) -> void:
	assert(def.real_seconds > 0.0, "NightDef.real_seconds must be > 0")
	_total = def.real_seconds
	_start_minute = def.start_minute()
	_elapsed = 0.0
	_last_minute = -1
	running = true
	minute_changed.emit(current_minute())
	print("[clock] start: 11:%02d  ->  11:47 in %.1fs" % [_start_minute, _total])

func current_minute() -> int:
	if _total <= 0.0:
		return NightDef.ARRIVAL_MINUTE
	var t := clampf(_elapsed / _total, 0.0, 1.0)
	return mini(int(lerpf(_start_minute, NightDef.ARRIVAL_MINUTE, t)), NightDef.ARRIVAL_MINUTE)

func _process(delta: float) -> void:
	if not running:
		return
	_elapsed += delta
	var m := current_minute()
	if m != _last_minute:
		_last_minute = m
		minute_changed.emit(m)
		print("[clock] 11:%02d" % m)
	if _elapsed >= _total:
		running = false
		print("[clock] 11:47 -- ARRIVED")
		arrived.emit()
