extends Node
# core/audio_hub.gd  --  autoload `AudioHub`.  GDD 16 "The silence beat", GDD 18.
# Owns ONE bus: Weather. The options sliders never touch it, so the silence beat can fade
# the weather without ever overwriting a player setting, and restoring is just "Weather
# back to 0 dB".

var _tw: Tween


var _pre_duck_master_db := 0.0
var _master_ducked := false

# Duck the Master bus to `target_db` over `duration`. The world becomes
# quiet but is never silenced -- the design (GDD 16 principle 4) requires
# faint room tone and the player's footsteps to persist through transitions.
func duck(target_db: float = -20.0, duration: float = 0.8) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	if not _master_ducked:
		_pre_duck_master_db = AudioServer.get_bus_volume_db(idx)
		_master_ducked = true
	_fade_bus(idx, target_db, duration)

# Restore the Master bus to whatever it was before the last duck().
func unduck(duration: float = 0.8) -> void:
	if not _master_ducked:
		return
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	_fade_bus(idx, _pre_duck_master_db, duration)
	_master_ducked = false

var _master_tw: Tween

func _fade_bus(idx: int, target_db: float, duration: float) -> void:
	if _master_tw != null and _master_tw.is_valid():
		_master_tw.kill()
	_master_tw = create_tween()
	var from := AudioServer.get_bus_volume_db(idx)
	_master_tw.tween_method(
		func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v),
		from, target_db, duration)


func silence_beat(duration := 6.0) -> void:
	_fade_weather(-60.0, duration)

func restore_weather(duration := 2.0) -> void:
	_fade_weather(0.0, duration)

func reset() -> void:                          # called from Game.begin_night
	if _master_tw != null and _master_tw.is_valid(): _master_tw.kill()
	_master_ducked = false
	var midx := AudioServer.get_bus_index("Master")
	if midx >= 0: AudioServer.set_bus_volume_db(midx, 0.0)

func _weather_bus() -> int:
	var idx := AudioServer.get_bus_index("Weather")
	assert(idx >= 0, "Audio bus 'Weather' is missing - check audio/default_bus_layout.tres")
	return idx

func _kill_fade() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()                             # two overlapping fades would fight over the bus
	_tw = null

func _fade_weather(target_db: float, duration: float) -> void:
	_kill_fade()
	var idx := _weather_bus()
	var from := AudioServer.get_bus_volume_db(idx)      # read, never hardcode
	_tw = create_tween()
	_tw.tween_method(func(v: float) -> void: AudioServer.set_bus_volume_db(idx, v), from, target_db, duration)

# Process mode is Inherit (pausable) on purpose, GDD 18: the fade must freeze with the
# game, and resuming must restore Weather to 0 dB (tests/test_pause.gd).
