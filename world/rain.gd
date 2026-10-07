extends GPUParticles3D
# world/rain.gd  --  GDD 15 "Rain".
#
# Technique ported from Miziziziz, "How to make it rain in Godot" (2019), to Godot 4.7.
# https://www.youtube.com/watch?v=KFDDiN2MD6g -- textures from the CC0 Kenney Particle Pack
# that the video's asset album re-hosts (trace_06.png, cropped).
# The whole trick is in the PROCESS MATERIAL, authored in rain.tscn:
#   gravity = 0, spread = 0, initial_velocity 22-28  -> perfectly straight, fast, uniform
#   emission_shape = Box, extents (12, 0.5, 12)      -> a horizontal slab above the player
#   collision_mode = Hide On Contact (2)             -> streaks DIE at the roof, they do not
#                                                       fall through it. This node has no such
#                                                       property in Godot 4; it is on the material
#   blend_mode = Add (1)                             -> his "add for blend mode"; the rain glints
#                                                       in the lamp and vanishes into the fog
#   billboard_mode = Y-Billboard (2)                 -> streaks stay VERTICAL in the world
#                                                       and still turn to face the camera
#   QuadMesh size (0.12, 1.1) + rain_streak.png      -> the streak length is the MESH height
#
# Two Godot-3-isms from that video do NOT carry over, and both are traps:
#   * He rotated the emitter 90 deg on X to make the emission box horizontal. Godot 4's
#     `emission_box_extents` is already a Vector3 -- just set Y small. No rotation needed.
#   * He used a PlaneMesh because a QuadMesh "isn't oriented right". Under Y-Billboard the
#     quad's local +Y is forced to world up, so a QuadMesh in the XY plane is correct and
#     PlaneMesh is not.
# Also note: Y-Billboard DISCARDS the Y component of node scale, which is why the streak
# length lives in the mesh size and not in a scale. That is the "can't affect the scale"
# complaint in the video's comments, and it is still true in 4.7.

@export var target: Node3D
@export var target_group := &"player"
@export var height := 7.0               # emitter height above `target`
# The video sets ADD blend on both the streak and the splash material ("add for blend mode
# so it just adds its color to whatever is behind"), and that is the default here -- it is
# what makes the rain glint in the lamp pool and disappear into the fog. Untick it for the
# flat grey-blue of GDD 15's palette instead; compare both before week 7.
@export var additive := true:
	set(value):
		additive = value
		if is_inside_tree():
			_apply_blend()

func _ready() -> void:
	top_level = true
	add_to_group(&"rain")           # DebugKit (F1) finds the emitter by group
	_apply_blend()
	_verify_collision()
	# `target` is resolved lazily in _process rather than here: rain.tscn is instanced by
	# main.tscn and the Player has not entered the tree yet when this _ready() runs.

func _process(_delta: float) -> void:
	if target == null:
		target = get_tree().get_first_node_in_group(target_group) as Node3D
	if target == null:
		return                            # v1.5 fix 12: never dereference unguarded
	global_position = target.global_position + Vector3(0, height, 0)

func _apply_blend() -> void:
	var mesh := draw_pass_1 as PrimitiveMesh
	if mesh == null:
		return
	# Cast before touching blend_mode: PrimitiveMesh.material is typed `Material`, and
	# `blend_mode` only exists on BaseMaterial3D. Reading it off the base type is a parse error.
	var mat := mesh.material as StandardMaterial3D
	if mat == null:
		return
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX

# GDD v1.9 fix 3 -- "the single most-reported visual bug of the first pass": rain falling
# through the shelter roof. Both halves of the fix are easy to lose, so check them at load.
func _verify_collision() -> void:
	var pm := process_material as ParticleProcessMaterial
	if pm == null:
		push_warning("rain.gd: no ParticleProcessMaterial on Process Material")
		return
	if pm.collision_mode != ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT:
		push_warning("rain.gd: Process Material > Collision Mode must be HIDE ON CONTACT, or the "
			+ "rain falls through the shelter roof. The flag lives on the PROCESS MATERIAL, not "
			+ "on this node -- GPUParticles3D has no collision_mode property in Godot 4.")
	if get_tree().get_nodes_in_group(&"rain_collider").is_empty():
		push_warning("rain.gd: nothing is in group 'rain_collider'. Every roof needs a "
			+ "GPUParticlesCollisionBox3D in that group (see BusStop/RoofRainCollision).")
