extends EventBase
# events/s1_passing_bus.gd -- GDD 12 S1. Night 1 at bus_arrives_at.
# The bus drives past without stopping. A scripted lamp blackout fires at the
# midpoint; the fog figure takes one step in the dark. Night 1's arrival.
#
# Timing is driven by SceneTreeTimers connected to callbacks, NOT by an
# internal await chain. If the event is aborted mid-flight (kill_all, night
# restart), the timers still fire but their callbacks check _ended and return
# without doing damage. The event cannot report "finished" until the final
# 9-second timer fires -- which means the Director's is_busy() check behaves
# correctly and main.gd's decision window opens at the right moment.

@export var blackout_seconds := 4.0
@export var pass_by_duration := 9.0

func _start() -> void:
	var bus := get_tree().get_first_node_in_group(&"bus")
	if bus == null:
		print("[s1] no bus rig found in group 'bus' -- check BusRig node + add_to_group")
		_done()
		return

	if bus.has_method("set_night"):
		bus.set_night(1)
	if bus.has_method("pass_by"):
		bus.pass_by(pass_by_duration)

	var mid := get_tree().create_timer(pass_by_duration * 0.5, false)
	mid.timeout.connect(_on_midpoint)

	var end := get_tree().create_timer(pass_by_duration, false)
	end.timeout.connect(_on_end)

func _on_midpoint() -> void:
	if _ended:
		return
	if ctx == null or ctx.lamp == null:
		return
	if ctx.lamp.has_method("scripted_dark"):
		ctx.lamp.scripted_dark(blackout_seconds)
	var step := get_tree().create_timer(0.5, false)
	step.timeout.connect(_on_step)

func _on_step() -> void:
	if _ended:
		return
	if ctx == null or ctx.figure == null:
		return
	if ctx.figure.has_method("force_step"):
		ctx.figure.force_step()

func _on_end() -> void:
	_done()

func _cleanup() -> void:
	var bus := get_tree().get_first_node_in_group(&"bus")
	if bus and is_instance_valid(bus) and bus.has_method("reset"):
		bus.reset()
