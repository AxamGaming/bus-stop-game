extends Node3D
# player/player_camera.gd  --  attach to the Player's HEAD node (yaw here, pitch on the
# Camera3D child).  GDD 8, GDD 17, GDD 18.
#
# FOV is read from Settings every frame on purpose: the gaze cone scales with horizontal
# FOV (LookAtTracker.gaze_half_angle()), so the FOV slider cannot widen a free-safe band.

@export var camera: Camera3D
@export var base_fov := 75.0          # the reference vertical FOV the cone fraction was tuned at
@export var lean_fov := 55.0          # the diegetic lean-in narrows the view
@export var fov_lerp := 10.0
@export var pitch_limit_deg := 80.0

var _pitch := 0.0
var _interaction: Node

func _ready() -> void:
	if camera == null:
		camera = get_node_or_null("Camera3D") as Camera3D
	assert(camera != null, "player_camera.gd needs a Camera3D child")
	_interaction = get_parent().get_node_or_null("PlayerInteraction") if get_parent() != null else null
	camera.fov = base_fov
	camera.keep_aspect = Camera3D.KEEP_HEIGHT   # LookAtTracker.horizontal_fov() assumes this
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := Settings.mouse_sensitivity * 0.0022
		rotate_y(-event.relative.x * sens)
		var dir := -1.0 if Settings.invert_y else 1.0
		var lim := deg_to_rad(pitch_limit_deg)
		_pitch = clampf(_pitch + event.relative.y * sens * dir, -lim, lim)
		camera.rotation.x = -_pitch
	# Mouse-up on release: GDD 17 -- releasing early cancels a hold. Handled by
	# PlayerInteraction (week 2); nothing to do here.

func _process(delta: float) -> void:
	if get_tree().paused:
		return                                  # this node is pausable; the PauseMenu owns the cursor
	var target := Settings.fov
	if _interaction != null and _interaction.has_method("is_leaning") and _interaction.is_leaning():
		target *= lean_fov / base_fov
	camera.fov = lerpf(camera.fov, target, clampf(fov_lerp * delta, 0.0, 1.0))

# Sign convention note: rotating the Camera3D by -pitch means mouse-up looks up.
# Positive rotation.x on a Camera3D looks UP in Godot (-Z forward, right-handed about +X),
# so the negation here is what makes it feel right, not a bug.
