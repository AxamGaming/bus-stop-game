class_name FogFigure extends Node3D
# world/fog_figure.gd -- GDD 18
# The Thing. Advances only when unwatched; freezes in the cone; drains the lamp while watched.
# The highlight (fairness rule 10) is a flat ALBEDO swap, NOT rim lighting -- rim is
# invisible when the material is unshaded, which is exactly what a PS1 fog figure is.

@export var stations: Array[Marker3D]
@export var tracker: LookAtTracker
@export var lamp: LampController
@export var seen_material: Material      # auto-wired from Placeholder in _ready if null
@export var base_albedo := Color(0.03, 0.03, 0.04)
@export var watched_albedo := Color(0.17, 0.18, 0.21)
@export var unseen_required := 1.5       # seconds unwatched before one step
@export var inner_unseen_required := 6.0 # cumulative seconds at cap before the breach
@export var breach_enabled := false      # debug-gated (F8)
@export var step_sound: AudioStreamPlayer3D
@export var step_sound_variation := 0.08
@export var tell_flicker_enabled := true # fire the realistic stutter on the first move only

var cap_index := 1
var station_index := -1
var step_requested := false
var breached := false
var watched := false
var _was_watched := false
var _unseen := 0.0
var _inner_unseen := 0.0
var _sliding := false
var hold_station := false            # set by main.gd during the stare lesson
var _slide_tween: Tween
var _flicker_tween: Tween
var _first_move_flicker_played := false

func _ready() -> void:
	add_to_group(&"figure")             # DebugKit F1 finds the figure by group
	if seen_material == null:
		var mesh_inst := get_node_or_null("Placeholder") as MeshInstance3D
		if mesh_inst and mesh_inst.material_override:
			# Duplicate so we never write into the .tscn's shared material.
			seen_material = mesh_inst.material_override.duplicate()
			mesh_inst.material_override = seen_material
	_apply_albedo(base_albedo)
	visible = false

func configure(cap_index_tonight: int, allow_breach: bool) -> void:
	cap_index = clampi(cap_index_tonight, 0, maxi(stations.size() - 2, 0))
	breach_enabled = allow_breach
	station_index = -1
	step_requested = false
	breached = false
	watched = false
	hold_station = false
	_was_watched = false
	_unseen = 0.0
	_inner_unseen = 0.0
	_first_move_flicker_played = false
	_apply_albedo(base_albedo)

	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.kill()
	if lamp != null:
		lamp.set_flicker(1.0)

	_sliding = false
	visible = false

func head_position() -> Vector3:
	return global_position + Vector3.UP * 1.5

# "At tonight's cap" -- NOT "at the physical last station". The v1.2 Night 1 kill bug
# was exactly this conflation. Do not rename loosely.
func at_cap() -> bool:
	return station_index >= cap_index

func in_the_light() -> bool:
	return breached

func request_step() -> void:
	step_requested = true

func force_step() -> void:
	_move_to(station_index + 1)

func _physics_process(delta: float) -> void:
	if tracker == null:
		return
	watched = visible and tracker.in_gaze_cone(head_position())
	if watched != _was_watched:
		_was_watched = watched
		_apply_albedo(watched_albedo if watched else base_albedo)

	if _sliding:
		return                          # a step in progress -- let it finish

	if station_index >= cap_index:
		_process_breach(delta)
		return

	if not visible:
		return

	if hold_station:
		_unseen = 0.0                   # frozen in place; only the highlight updates
		return

	if watched:
		_unseen = 0.0
		return

	var next_idx := station_index + 1
	if next_idx >= stations.size():
		_unseen = 0.0
		return
	var next := stations[next_idx].global_position + Vector3.UP * 1.5
	if tracker.in_gaze_cone(next):
		_unseen = 0.0
		return

	_unseen += delta
	if _unseen >= unseen_required:
		_move_to(next_idx)

func _process_breach(delta: float) -> void:
	if not breach_enabled or breached or not visible:
		return
	if watched:
		_inner_unseen = maxf(_inner_unseen - delta * 2.0, 0.0)
		return
	_inner_unseen += delta
	if _inner_unseen >= inner_unseen_required and stations.size() > 0:
		breached = true
		station_index = stations.size() - 1
		global_position = stations[station_index].global_position
		_inner_unseen = 0.0

func _move_to(i: int) -> void:
	if i > cap_index or i < 0 or i >= stations.size():
		return
	station_index = i
	if step_sound and step_sound.stream:
		step_sound.pitch_scale = 1.0 + randf_range(-step_sound_variation, step_sound_variation)
		step_sound.play()
	visible = true
	step_requested = false
	_unseen = 0.0

	var target := stations[i].global_position
	var from := global_position

	# A step, not a slide: tween the position so a fast look-back catches motion.
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_sliding = true
	_slide_tween = create_tween()
	_slide_tween.tween_method(
		func(t: float) -> void: global_position = from.lerp(target, t),
		0.0, 1.0, 0.6)
	_slide_tween.finished.connect(func() -> void:
		global_position = target
		_sliding = false)

	# The tell flicker fires ONLY on the first move of the night. Every subsequent
	# move relies on the step sound alone. This is a one-time language lesson for
	# the player: "this is what it looks like when the figure moves."
	if tell_flicker_enabled and not _first_move_flicker_played:
		_first_move_flicker_played = true
		_play_tell_flicker()

func _play_tell_flicker() -> void:
	if lamp == null:
		return
	if _flicker_tween != null and _flicker_tween.is_valid():
		_flicker_tween.kill()

	# Accessibility: if the player has asked for reduced flicker, one clean dip.
	var reduce := false
	if Engine.has_singleton("Settings"):
		var s := Engine.get_singleton("Settings")
		if s != null and "reduce_flicker" in s:
			reduce = s.reduce_flicker
	if reduce:
		_flicker_tween = create_tween()
		_flicker_tween.tween_callback(lamp.set_flicker.bind(0.35))
		_flicker_tween.tween_interval(0.25)
		_flicker_tween.tween_callback(lamp.set_flicker.bind(1.0))
		return

	# Real electrical stutter: 4 sharp, irregular off-blips over ~0.35 s.
	# Deep dips (5-25%), short on-gaps. Not a smooth pulse.
	_flicker_tween = create_tween()
	_flicker_tween.tween_callback(lamp.set_flicker.bind(0.15))
	_flicker_tween.tween_interval(0.04)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(1.0))
	_flicker_tween.tween_interval(0.05)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(0.05))
	_flicker_tween.tween_interval(0.03)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(1.0))
	_flicker_tween.tween_interval(0.08)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(0.25))
	_flicker_tween.tween_interval(0.05)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(1.0))
	_flicker_tween.tween_interval(0.04)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(0.10))
	_flicker_tween.tween_interval(0.06)
	_flicker_tween.tween_callback(lamp.set_flicker.bind(1.0))

# v1.9: branch on material type. StandardMaterial3D uses albedo_color;
# ShaderMaterial (the PSX shader) uses albedo_tint.
func _apply_albedo(c: Color) -> void:
	if seen_material == null:
		return
	if seen_material is StandardMaterial3D:
		(seen_material as StandardMaterial3D).albedo_color = c
	elif seen_material is ShaderMaterial:
		(seen_material as ShaderMaterial).set_shader_parameter(&"albedo_tint", c)
