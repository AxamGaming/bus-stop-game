extends CharacterBody3D
# player/player.gd  --  GDD 8 "Movement and boundaries".
# Slow. No sprint. 1.8 m/s to start, tune 1.5-2.2 in playtests.
#
# Untyped node lookups on purpose: on day 1 PlayerInteraction / Watch / Footsteps do not
# exist yet, and a typed reference to a class_name that has not been written is a PARSE
# error, not a null. Duck-type with has_method() so this script compiles all week.

@export var speed := 1.8
@export var watch_speed_mult := 0.5
@export var gravity := 9.8
@export var turn_speed := 10.0        # velocity smoothing, per second
@export var step_distance := 1.9      # metres between footsteps
@export var head_path := NodePath("Head")

var noclip := false                   # DebugKit F6
var _walked := 0.0

@onready var head: Node3D = get_node_or_null(head_path) as Node3D
@onready var camera: Camera3D = get_node_or_null(NodePath(String(head_path) + "/Camera3D")) as Camera3D
@onready var tether: Node = get_node_or_null("Tether")
@onready var interaction: Node = get_node_or_null("PlayerInteraction")
@onready var watch: Node = get_node_or_null("Watch")
@onready var footsteps: AudioStreamPlayer3D = get_node_or_null("Footsteps") as AudioStreamPlayer3D

func _ready() -> void:
	add_to_group(&"player")             # sign_line.gd and E3 both look for this group
	collision_layer = 1 << 1            # layer 2: player
	collision_mask = 1 << 0             # layer 1: world (including glass)
	assert(head != null, "player.gd: Head node not found at %s" % head_path)

func _physics_process(delta: float) -> void:
	if noclip:
		_noclip(delta)
		return
	if not is_on_floor():
		velocity.y -= gravity * delta

	var mult := 1.0
	if _watch_raised():
		mult = watch_speed_mult
	if _leaning():
		mult = 0.0                       # the lean-in locks movement (GDD 8); the world keeps running

	var wish := _yaw_basis() * Vector3(_axis_x(), 0.0, _axis_z())
	wish.y = 0.0
	var target := Vector3.ZERO
	if wish.length_squared() > 0.0001:
		target = wish.normalized() * speed * mult

	var k := clampf(turn_speed * delta, 0.0, 1.0)
	velocity.x = lerpf(velocity.x, target.x, k)
	velocity.z = lerpf(velocity.z, target.z, k)

	if tether != null and tether.has_method("extra_velocity"):
		velocity += tether.extra_velocity(delta)

	var before := global_position
	move_and_slide()
	_walked += Vector2(global_position.x - before.x, global_position.z - before.z).length()
	if _walked >= step_distance:
		_walked = 0.0
		_step()

	if tether != null and tether.has_method("clamp_hard"):
		tether.clamp_hard()

func _noclip(delta: float) -> void:
	var wish := _yaw_basis() * Vector3(_axis_x(), 0.0, _axis_z())
	if Input.is_physical_key_pressed(KEY_SHIFT):
		wish *= 4.0
	if Input.is_physical_key_pressed(KEY_SPACE):
		wish.y += 1.0
	if Input.is_physical_key_pressed(KEY_CTRL):
		wish.y -= 1.0
	global_position += wish * speed * 3.0 * delta

# ---- input ----
func _axis_x() -> float:
	return Input.get_axis(&"move_left", &"move_right")

# Sign convention: get_axis(negative, positive) = positive - negative, so this returns -1
# when W is held -- which is correct, because -Z is forward in Godot. Do not "fix" the sign.
func _axis_z() -> float:
	return Input.get_axis(&"move_forward", &"move_back")

# Yaw only. Reading the camera's full basis would make looking down at the watch tilt the
# movement plane, and the player would slide when they raise their arm.
func _yaw_basis() -> Basis:
	var yaw := head.rotation.y if head != null else rotation.y
	return Basis(Vector3.UP, yaw)

func _watch_raised() -> bool:
	return Input.is_action_pressed(&"watch")

func _leaning() -> bool:
	return interaction != null and interaction.has_method("is_leaning") and interaction.is_leaning()

func _step() -> void:
	if footsteps == null or footsteps.stream == null:
		return
	footsteps.pitch_scale = randf_range(0.92, 1.08)
	footsteps.play()
	# Surface (concrete under the shelter, gravel on the verge) arrives with
	# player/footsteps.gd in week 2. Day 1 just needs the rhythm to exist.
