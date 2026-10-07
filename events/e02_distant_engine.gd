extends EventBase
# events/e02_distant_engine.gd -- GDD 12 E2.
# An engine approaches along the road and fades. No bus appears.

@export var duration := 8.0
@export var engine_sound: AudioStreamPlayer3D

func _start() -> void:
	if engine_sound == null:
		# look for one in the context world; otherwise synthesize silently
		_done()
		return
	engine_sound.play()
	var tw := create_tween()
	tw.tween_interval(duration)
	tw.finished.connect(_done)

func _cleanup() -> void:
	if engine_sound:
		engine_sound.stop()
