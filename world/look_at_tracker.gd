class_name LookAtTracker extends Node
# world/look_at_tracker.gd -- GDD 18
# The ONE cone. "Watched" and "stared at" use the same test (fairness rule 8).
# Direct space state access is only guaranteed safe in _physics_process.

@export var camera: Camera3D
@export_flags_3d_physics var sight_mask := 32    # layer 6 only (sight_blockers)
@export var max_distance := 32.0                  # matches the fog end
@export_range(1, 5) var ray_count := 3
@export var fan_spread := 0.35
@export var fan_angle_deg := 3.0

const CONE_FRAC := 0.41    # 44 deg full cone at 75 deg vertical on 16:9

func _ready() -> void:
	add_to_group(&"tracker")
	if camera == null:
		push_warning("LookAtTracker: camera is not assigned")

func horizontal_fov() -> float:
	if camera == null:
		return 75.0
	var vp := camera.get_viewport().get_visible_rect().size
	var aspect := float(vp.x) / maxf(float(vp.y), 1.0)
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(camera.fov) * 0.5) * aspect))

func gaze_half_angle() -> float:
	return deg_to_rad(horizontal_fov() * CONE_FRAC * 0.5)

func in_gaze_cone(target: Vector3) -> bool:
	if camera == null:
		return false
	var fwd := -camera.global_transform.basis.z
	var to := (target - camera.global_position).normalized()
	if fwd.dot(to) < cos(gaze_half_angle()):
		return false
	return seen(target)

# Any one clear ray in the fan counts as seen. 3 rays, not 1: a thin edge
# (a post, the lamp pole) must not fake occlusion.
func seen(target: Vector3) -> bool:
	if camera == null:
		return false
	var origin := camera.global_position
	if origin.distance_to(target) > max_distance:
		return false
	var spread := maxf(fan_spread, origin.distance_to(target) * tan(deg_to_rad(fan_angle_deg)))
	var up := camera.global_transform.basis.y
	var n := maxi(ray_count, 1)
	for i in n:
		var frac := 0.0 if n == 1 else (float(i) / float(n - 1)) - 0.5
		var p := target + up * (frac * 2.0 * spread)
		if not camera.is_position_in_frustum(p):
			continue
		var q := PhysicsRayQueryParameters3D.create(origin, p, sight_mask)
		if camera.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			return true
	return false
