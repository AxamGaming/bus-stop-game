class_name EventBase extends Node3D
# events/event_base.gd -- GDD 18 "Event base class".
# Every event scene's root has this script. The Director instantiates an event's
# PackedScene, checks the root is an EventBase, calls run(ctx), and waits for `finished`.

signal finished(event_id: StringName)

@export var event_id: StringName
var ctx: EventContext
var _ended := false

func run(p_ctx: EventContext) -> void:
	ctx = p_ctx
	_start()

func abort() -> void:
	_done()

func _start() -> void:
	pass

func _cleanup() -> void:
	pass

func _done() -> void:
	if _ended:
		return
	_ended = true
	_cleanup()
	finished.emit(event_id)
	queue_free()
