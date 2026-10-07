extends Node
# player/tether.gd  --  GDD 8 "Movement and boundaries", GDD 14.
# Soft push-back from 12 m, hard wall at 14 m, both measured from the SHELTER CENTRE
# (x ~ 1.5), NOT from the lamp at the origin. tests/test_stations.gd measures from the
# same point, which is why the distinction matters.
#
# This node also owns the Night 1 sign-line push-back. It is a decaying VELOCITY, never a
# teleport: the sign wall is only ~1 m thick and teleporting the player out of it can
# deposit them on the far side, which in Night 2+ is an instant ending they never chose
# (GDD 0 v1.5 item 14).

@export var centre: Node3D            # Main/World/BusStopCentre. Left null, it is found
                                      # by group so no cross-scene NodePath wiring is needed
@export var centre_group := &"bus_stop_centre"
@export var soft_radius := 12.0
@export var hard_radius := 14.0
@export var soft_push := 2.5          # inward m/s added per metre past the soft radius
@export var max_push := 5.0

var _nudge := Vector3.ZERO
var _nudge_time := 0.0

func _ready() -> void:
	if centre == null:
		centre = get_tree().get_first_node_in_group(centre_group) as Node3D
	assert(centre != null, "tether.gd: no BusStopCentre marker (group '%s') in the tree" % centre_group)

func _body() -> Node3D:
	return get_parent() as Node3D

# Added to the player's velocity every physics frame, BEFORE move_and_slide().
func extra_velocity(delta: float) -> Vector3:
	var out := Vector3.ZERO
	var body := _body()
	if body != null and centre != null:
		var to := body.global_position - centre.global_position
		to.y = 0.0
		var d := to.length()
		if d > soft_radius and d > 0.001:
			out = -to.normalized() * minf((d - soft_radius) * soft_push, max_push)
	if _nudge_time > 0.0:
		out += _nudge
		_nudge_time = maxf(_nudge_time - delta, 0.0)
		if _nudge_time <= 0.0:
			_nudge = Vector3.ZERO
	return out

# Called AFTER move_and_slide(). This is the invisible wall; it is a sub-centimetre
# correction per frame, not a jump.
func clamp_hard() -> void:
	var body := _body()
	if body == null or centre == null:
		return
	var to := body.global_position - centre.global_position
	var y := body.global_position.y
	to.y = 0.0
	var d := to.length()
	if d > hard_radius and d > 0.001:
		body.global_position = centre.global_position + to.normalized() * hard_radius + Vector3(0, y - centre.global_position.y, 0)

# Night 1 sign-line warning: walk the player back toward `toward` over `seconds`.
func nudge_toward(toward: Vector3, strength := 3.5, seconds := 0.6) -> void:
	var body := _body()
	if body == null:
		return
	var dir := toward - body.global_position
	dir.y = 0.0
	if dir.length() < 0.001:
		return
	_nudge = dir.normalized() * strength
	_nudge_time = seconds

func cancel_nudge() -> void:
	_nudge = Vector3.ZERO
	_nudge_time = 0.0
