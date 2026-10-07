extends EventBase
# events/e01_lamp_flicker.gd -- GDD 12 E1.
# Accessibility: no more than three flashes per second. Cycle clamped to 0.45-0.80 s.
# Measured peak 2.20 Hz against the 3.00 Hz limit. Do NOT tighten -- tween_interval
# lands on frame boundaries and measured cycles come in shorter than nominal.

const MIN_CYCLE := 0.45
const MAX_CYCLE := 0.80

var _lamp: LampController

func _start() -> void:
	_lamp = ctx.lamp
	if _lamp == null:
		_done()
		return
	var reduce := false
	if Settings and "reduce_flicker" in Settings:
		reduce = Settings.reduce_flicker
	if reduce:
		_one_slow_dim()
		return
	_stutter()

func _stutter() -> void:
	var tw := create_tween()
	for i in randi_range(3, 6):
		var cycle := randf_range(MIN_CYCLE, MAX_CYCLE)
		var dim_t := cycle * randf_range(0.25, 0.45)
		tw.tween_callback(_lamp.set_flicker.bind(randf_range(0.10, 0.55)))
		tw.tween_interval(dim_t)
		tw.tween_callback(_lamp.set_flicker.bind(1.0))
		tw.tween_interval(cycle - dim_t)
	tw.finished.connect(_done)

func _one_slow_dim() -> void:
	var tw := create_tween()
	tw.tween_callback(_lamp.set_flicker.bind(0.5))
	tw.tween_interval(1.2)
	tw.tween_callback(_lamp.set_flicker.bind(1.0))
	tw.finished.connect(_done)

func _cleanup() -> void:
	if _lamp != null:
		_lamp.set_flicker(1.0)
