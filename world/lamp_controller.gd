extends Node3D
# world/lamp_controller.gd  --  class LampController.  GDD 18 "The lamp and the attention
# economy". The lamp is the game's health bar, its clock and its audio gauge at once.
class_name LampController

@export var light: OmniLight3D
@export var hum: AudioStreamPlayer
@export var base_energy := 1.6
# ADDITION (GDD 7 "Tells"), optional: a faint heartbeat that joins when the light is low,
# earlier when the figure is at tonight's cap. Assign nothing and this all no-ops.
@export var heartbeat: AudioStreamPlayer3D
@export var heartbeat_threshold := 0.30
@export var heartbeat_threshold_at_cap := 0.50

var level := 1.0                       # 0..1, drained by staring
var scripted_blackout := false         # scripted blackouts can never kill
var at_cap := false                    # written by GazeMonitor, read only for the heartbeat tell
var _flicker := 1.0                    # multiplier set by flicker events
var _heartbeat_on := false

func _ready() -> void:
	add_to_group(&"lamp")                # DebugKit (F1) finds the lamp by group, no wiring needed

func _process(_delta: float) -> void:
	light.light_energy = base_energy * level * _flicker
	hum.pitch_scale = lerpf(0.7, 1.0, level)      # the audio tell
	_update_heartbeat()

func drain(rate: float, delta: float) -> void:
	level = maxf(level - rate * delta, 0.0)

func recover(rate: float, delta: float) -> void:
	level = minf(level + rate * delta, 1.0)

func relight(to: float) -> void:
	level = to

# Called at every night start. Without it a night can begin at whatever level the
# previous one ended on (e.g. 0.5 after a blackout) and be one stare from a second.
func reset() -> void:
	level = 1.0
	_flicker = 1.0
	scripted_blackout = false
	at_cap = false

func set_flicker(multiplier: float) -> void:
	_flicker = multiplier

func scripted_dark(seconds: float) -> void:
	scripted_blackout = true
	var saved := level
	level = 0.0
	await get_tree().create_timer(seconds, false).timeout   # false = respects pause
	level = saved
	scripted_blackout = false

func _update_heartbeat() -> void:
	if heartbeat == null:
		return
	var want := level <= (heartbeat_threshold_at_cap if at_cap else heartbeat_threshold)
	if want == _heartbeat_on:
		return
	_heartbeat_on = want
	if want:
		heartbeat.play()
	else:
		heartbeat.stop()
