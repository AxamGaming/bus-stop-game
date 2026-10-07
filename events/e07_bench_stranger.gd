extends EventBase
# events/e07_bench_stranger.gd -- GDD 12 E7. Night 2 at 3:00, Night 3 at 2:30.
# A seated silhouette appears on the bench. Hold E -> Ending 3 (spoke_first).
# If ignored for `lifetime` seconds, it leaves and the event finishes.
#
# Design:
#   - "Appears while you look away" (Slender/SCP-173 pattern): the stranger
#     only becomes visible when the player is NOT looking at the bench. We use
#     dot-product detection: the bench must be outside a wide field of view
#     (dot < 0.35, i.e. more than ~70 degrees off the player's forward axis).
#   - visible + enabled paired: when the stranger is hidden, BOTH visible=false
#     AND enabled=false are set. Setting only visible=false leaves a phantom
#     trigger (the interaction ray still hits the StaticBody3D). The base
#     Interactable class uses `enabled` to gate can_use().
#   - Audio telegraph: a bench creak (cloth.wav) plays when the stranger
#     appears. The player hears the bench before they see the figure.
#   - Departure is gaze-gated (symmetry: never see it arrive, never see it
#     leave).
#   - Night 3 variant: seated closer, head tilted toward the player.

@onready var stranger: Interactable = $Stranger
@onready var creak: AudioStreamPlayer3D = $Creak
@export var lifetime := 50.0
@export var bench_pos := Vector3(1.5, 0.6, 1.05)

var night_3 := false

var _appeared := false
var _departed := false
var _camera: Camera3D

# A dot < this means "the player is looking away from the bench."
# Camera forward is a unit vector; direction-to-bench is a unit vector.
# dot = cos(angle between them).
#   dot = 1.0  -> bench straight ahead
#   dot = 0.0  -> bench at 90 degrees
#   dot = -1.0 -> bench directly behind
# The gaze cone is roughly 22 deg half-angle (cos 22 ~= 0.93), but we want
# the stranger to spawn only when the bench is unambiguously outside the
# player's *effective* vision, including their peripheral awareness.
# 0.35 is ~70 degrees off-axis: outside the cone with comfortable margin.
# Tune in playtest between 0.25 (harder to spawn) and 0.45 (easier).
const LOOK_AWAY_DOT := 0.35

func _start() -> void:
	if stranger == null:
		print("[e07] no stranger assigned -- skipping")
		_done()
		return
	night_3 = (Game.night_index == 3)
	if ctx.player:
		_camera = ctx.player.get_node_or_null("Head/Camera3D") as Camera3D
		if _camera == null:
			_camera = get_viewport().get_camera_3d()
	stranger.global_position = bench_pos
	stranger.visible = false
	stranger.enabled = false
	if night_3:
		stranger.rotation_degrees.x = 15.0
	print("[e07] stranger event started -- waiting for player to look away")
	while not _appeared and not _ended:
		await get_tree().create_timer(0.2, false).timeout
		if _is_looking_away():
			_reveal()
	if _appeared and not _ended:
		await get_tree().create_timer(lifetime, false).timeout
		if _ended:
			return
		print("[e07] stranger lifetime expired -- waiting for player to look away to depart")
		while not _departed and not _ended:
			await get_tree().create_timer(0.2, false).timeout
			if _is_looking_away():
				_depart()
				break
	_done()

func _is_looking_away() -> bool:
	if _camera == null or not is_instance_valid(_camera):
		return true
	var cam_pos := _camera.global_position
	var cam_fwd := -_camera.global_transform.basis.z
	var to_bench := (bench_pos - cam_pos).normalized()
	var dot := cam_fwd.dot(to_bench)
	return dot < LOOK_AWAY_DOT

func _reveal() -> void:
	if _appeared:
		return
	_appeared = true
	stranger.visible = true
	stranger.enabled = true
	stranger.prompt = "Say something…"
	stranger.hold_seconds = 1.0
	stranger.distinct_style = true
	if not stranger.triggered.is_connected(_on_spoke):
		stranger.triggered.connect(_on_spoke)
	if creak and creak.stream:
		creak.play()
	print("[e07] stranger revealed on bench")

func _on_spoke() -> void:
	if _ended:
		return
	print("[e07] player spoke first -> spoke_first ending")
	Game.trigger_ending(&"spoke_first")
	_done()

func _depart() -> void:
	if _departed:
		return
	_departed = true
	stranger.visible = false
	stranger.enabled = false
	print("[e07] stranger departed")

func _cleanup() -> void:
	if stranger and is_instance_valid(stranger):
		stranger.visible = false
		stranger.enabled = false
