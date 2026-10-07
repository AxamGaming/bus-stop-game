class_name HUD extends CanvasLayer

@export var interaction: PlayerInteraction
@export var crosshair: Control
@export var prompt_label: Label
@export var hold_ring: Control
@export var hold_ring_fill: Control

var _prompt := ""
var _distinct := false
var _ring_v := 0.0
var _leaning := false

func _ready() -> void:
	if interaction == null:
		push_warning("HUD.interaction is not assigned")
		return
	interaction.prompt_changed.connect(_on_prompt_changed)
	interaction.hold_progress_changed.connect(_on_hold_progress)
	interaction.lean_changed.connect(_on_lean_changed)
	_refresh_all()

func _on_prompt_changed(text: String, distinct: bool) -> void:
	_prompt = text
	_distinct = distinct
	_refresh_all()

func _on_hold_progress(value: float) -> void:
	_ring_v = clampf(value, 0.0, 1.0)
	_refresh_all()

func _on_lean_changed(active: bool) -> void:
	_leaning = active
	_refresh_all()

func _refresh_all() -> void:
	if crosshair != null:
		crosshair.visible = not _leaning

	if prompt_label != null:
		prompt_label.text = _prompt
		prompt_label.modulate = Color(1.0, 0.85, 0.55) if _distinct else Color(0.92, 0.92, 0.9)
		prompt_label.visible = (not _leaning) and _prompt != ""

	if hold_ring != null and hold_ring_fill != null:
		hold_ring.visible = (not _leaning) and _ring_v > 0.001
		hold_ring_fill.anchor_right = _ring_v
