extends Area3D
# world/sign_line.gd -- GDD 18, Rule 3.
# Night 1: warning only. Night 2+: crossing ends the run with variant "sign".

signal warned

var lethal := false
var _warn_cooldown := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1         # layer 2: the player
	body_entered.connect(_on_body_entered)

func configure(is_lethal: bool) -> void:
	lethal = is_lethal

func _process(delta: float) -> void:
	_warn_cooldown = maxf(_warn_cooldown - delta, 0.0)

func check_initial_overlap() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	for b in get_overlapping_bodies():
		_on_body_entered(b)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if lethal:
		Game.trigger_ending(&"out_of_the_light", &"sign")
	elif _warn_cooldown <= 0.0:
		_warn_cooldown = 5.0
		warned.emit()
