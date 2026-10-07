class_name GazeMonitor extends Node
# world/gaze_monitor.gd -- GDD 18
# The lamp drains while you stare. A blackout is survivable UNLESS all three gates are true:
#   lethal_tonight (Night 3 only)  AND  armed (survived a prior blackout)  AND  at_cap().
# Night 1 cannot kill the player under any input. Fairness rule 1.

@export var tracker: LookAtTracker
@export var figure: FogFigure
@export var lamp: LampController
@export var grace_sec := 2.0
@export var drain_per_sec := 0.10
@export var drain_per_sec_at_cap := 0.06
@export var recover_per_sec := 0.20

var armed := false            # set ONLY after a survived blackout
var lethal_tonight := false   # from NightDef.gaze_lethal
var _stare := 0.0
var _ended := false
var _immunity_until := 0.0

func _ready() -> void:
	add_to_group(&"gaze")

func configure(def: NightDef) -> void:
	lethal_tonight = def.gaze_lethal
	_stare = 0.0
	# `armed` deliberately NOT reset: it records what the player has been shown this session.

func reset() -> void:
	_ended = false
	_stare = 0.0           # a fresh run means the demonstration must be earned again

func _physics_process(delta: float) -> void:
	if Game.state != Game.State.NIGHT:
		return
	if Time.get_ticks_msec() / 1000.0 < _immunity_until:
		return
	if _ended:
		return
	if tracker == null or figure == null or lamp == null:
		return
	if lamp.scripted_blackout:
		return

	lamp.at_cap = figure.at_cap()

	var staring := figure.visible and tracker.in_gaze_cone(figure.head_position())
	if staring:
		_stare += delta
		if _stare > grace_sec:
			var rate := drain_per_sec_at_cap if figure.at_cap() else drain_per_sec
			lamp.drain(rate, delta)
	else:
		_stare = 0.0
		lamp.recover(recover_per_sec, delta)

	if lamp.level <= 0.0:
		_on_gaze_blackout()

func _on_gaze_blackout() -> void:
	_stare = 0.0
	_immunity_until = Time.get_ticks_msec() / 1000.0 + 1.5 
	if lethal_tonight and armed and figure.at_cap():
		_ended = true                  # stop processing -- the night is over
		print("[gaze] DEATH -- all three gates true")
		Game.trigger_ending(&"out_of_the_light", &"gaze")
		return
	figure.force_step()
	lamp.relight(0.5)
	armed = true
	print("[gaze] survived blackout; armed=true; figure station=", figure.station_index)
	
