class_name PlayerInteraction extends Node
# player/player_interaction.gd -- GDD 8.
# Attach to the Player as a sibling of the camera. The RayCast3D child must have
# collision_mask = layer 3 (interactables) ONLY, so glass on layer 1 cannot block it.

signal prompt_changed(text: String, distinct: bool)
signal hold_progress_changed(value: float)     # 0..1; the HUD draws the ring
signal lean_changed(active: bool)              # the camera narrows FOV, movement locks

@export var ray: RayCast3D
@export var interact_action := &"interact"
@export var readable_group := &"readable"      # timetable and poster: hold E to lean in

var _hold := 0.0
var _target: Interactable = null
var _leaning := false
var _reading := false      
var _last_prompt := ""
var _last_distinct := false                    # continuous lean while E is held on a readable

func _ready() -> void:
	assert(ray != null, "PlayerInteraction.ray is not assigned")
	ray.collision_mask = 1 << 2                # layer 3: interactables only
	ray.target_position = Vector3(0, 0, -2.5)

func _process(delta: float) -> void:
	_target = _current_interactable()
	if _target == null:
		if _reading:
			_stop_reading()
		_clear()
		return

	if _target.prompt != _last_prompt or _target.distinct_style != _last_distinct:
		_last_prompt = _target.prompt
		_last_distinct = _target.distinct_style
		prompt_changed.emit(_target.prompt, _target.distinct_style)

	var pressed := Input.is_action_pressed(interact_action)
	var just_pressed := Input.is_action_just_pressed(interact_action)

	if _target.is_in_group(readable_group):
		if pressed:
			if not _reading:
				_reading = true
				_set_leaning(true)
		else:
			if _reading:
				_stop_reading()
		return

	if _reading:
		_stop_reading()

	if not pressed:
		_clear()
		return

	if _target.hold_seconds <= 0.0:
		if just_pressed:
			_target.triggered.emit()
		return

	_hold += delta
	hold_progress_changed.emit(clampf(_hold / _target.hold_seconds, 0.0, 1.0))
	if _hold >= _target.hold_seconds:
		_hold = 0.0
		hold_progress_changed.emit(0.0)
		_target.triggered.emit()

func _current_interactable() -> Interactable:
	if not ray.is_colliding():
		return null
	var hit := ray.get_collider()
	if not (hit is Interactable):
		return null
	var it := hit as Interactable
	if not it.can_use(ray.global_position):
		return null
	return it

func cancel_lean() -> void:
	_stop_reading()
	_clear()

func is_leaning() -> bool:
	return _leaning

func _stop_reading() -> void:
	_reading = false
	_set_leaning(false)

func _set_leaning(v: bool) -> void:
	if _leaning == v:
		return
	_leaning = v
	lean_changed.emit(v)

func _clear() -> void:
	if _hold != 0.0:
		_hold = 0.0
		hold_progress_changed.emit(0.0)
	if _last_prompt != "":
		_last_prompt = ""
		_last_distinct = false
		prompt_changed.emit("", false)
