extends EventBase
# events/s2_numberless_bus.gd -- GDD 12 S2. Night 2 at 6:20 (bus_arrives_at).
# The numberless bus stops, opens its doors on a lit empty interior.
# Hold E on the door -> Ending 2 (wrong_bus). If ignored for 45s, it departs.
#
# Design (research-informed):
#   - The door is an Interactable child of the event scene, positioned at the
#     bus's door_world_pos() when the bus arrives. The Interactable is disabled
#     until the doors open -- the player cannot board a closed bus.
#   - The Interactable's `triggered` signal connects to _on_board() which fires
#     Game.trigger_ending("wrong_bus"). The event finishes immediately after.
#   - If the 45s decision window expires, the door is disabled, doors close,
#     bus departs, event finishes. Night 2 then proceeds to _window_closed()
#     (clean pass -> Night 3).
#   - visible + process_mode pairing (research: Slender/SCP-173 pattern): the
#     door Interactable is disabled (process_mode = DISABLED) when not boardable,
#     not just invisible. This prevents phantom triggers.

@export var decision_window := 45.0

@onready var door: Interactable = $Door

func _start() -> void:
	var bus := get_tree().get_first_node_in_group(&"bus")
	if bus == null:
		print("[s2] no bus rig found -- skipping arrival")
		_done()
		return
	# Night 2: numberless (blank board), interior will light when doors open.
	if bus.has_method("set_night"):
		bus.set_night(2)
	# Drive in and stop. arrive() emits arrived_at_stop when finished.
	if bus.has_method("arrive"):
		await bus.arrive()
	# Open the doors. open_doors() emits doors_opened when finished.
	if bus.has_method("open_doors"):
		await bus.open_doors()
	# Enable the door Interactable at the bus's door position.
	if door:
		door.global_position = bus.door_world_pos() if bus.has_method("door_world_pos") else bus.global_position + Vector3(2.0, 0.0, 1.25)
		door.prompt = "Board"
		door.hold_seconds = 1.0
		door.max_reach = 2.0
		door.enabled = true
		if not door.triggered.is_connected(_on_board):
			door.triggered.connect(_on_board)
	print("[s2] numberless bus stopped -- %.0fs window" % decision_window)
	# Wait for the decision window. If the player boards, _on_board fires and
	# _done() is called. If the window expires, the bus departs.
	await get_tree().create_timer(decision_window, false).timeout
	if _ended:
		return
	if door:
		door.enabled = false
	if bus.has_method("depart"):
		await bus.depart()
	_done()

func _on_board() -> void:
	if _ended:
		return
	print("[s2] player boarded the numberless bus -> wrong_bus ending")
	Game.trigger_ending(&"wrong_bus")
	_done()

func _cleanup() -> void:
	if door and is_instance_valid(door):
		door.enabled = false
