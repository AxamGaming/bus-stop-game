class_name Interactable extends StaticBody3D
# player/interactable.gd -- GDD 8 "Interaction system".
# The interaction ray resolves its target with ray.get_collider(), which returns
# the BODY, so the body must be the Interactable. A Node3D here can never match
# `hit is Interactable`. Collision is created in _ready on layer 3.

signal triggered

@export var prompt := "Interact"
@export var hold_seconds := 0.0        # 0.0 = tap, 1.0 = hold for one second
@export var max_reach := 2.5           # the bus door uses 1.5
@export var distinct_style := false    # the stranger's prompt looks different
@export var enabled := true
@export var shape_size := Vector3(0.6, 0.6, 0.2)

func _ready() -> void:
	collision_layer = 1 << 2           # layer 3: interactables
	collision_mask = 0
	var col := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = shape_size
	col.shape = bs
	add_child(col)

func can_use(player_pos: Vector3) -> bool:
	return enabled and global_position.distance_to(player_pos) <= max_reach
