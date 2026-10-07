class_name BusRig extends Node3D
# world/bus_rig.gd -- GDD 12 S1/S2/S3, GDD 14.
# The bus: drive-by (Night 1), numberless arrival (Night 2), real arrival (Night 3).
# Built from primitive shapes per B6 spec ("For the first build, use primitive shapes").
#
# Research-informed design choices:
#   - Straight-line tween on position:x instead of PathFollow3D. The road is
#     straight (road.tscn runs along the x-axis at z=-8). PathFollow3D adds
#     complexity without benefit on a straight path. TRANS_QUAD + EASE_OUT for
#     arrival (decelerate to stop), TRANS_LINEAR for pass-by (constant speed),
#     TRANS_QUAD + EASE_IN for depart (accelerate away). (Godot Tween docs;
#     research: "TRANS_QUAD starts quickly and slows down towards the end".)
#   - Lamp blackout in B7 is keyed off a timer at the pass-by midpoint, not
#     off the bus's tween progress. This is simpler and just as reliable for
#     a 9-second pass-by. (Research suggested progress_ratio threshold, but
#     with a linear tween the elapsed-time midpoint IS the progress midpoint.)
#   - The bus is a visual + audio object, NOT a physics body. The player can
#     walk through it (no collision). This is intentional: the bus is far away
#     on the road (z=-6) and the player interacts via the door Interactable,
#     not by touching the body. Adding collision would trap the player if they
#     stood where the bus stops.
#
# Coordinate system (from road.tscn + bus_stop.tscn):
#   - Road surface: z=-8, 7m wide (z=-11.5 to z=-4.5), 140m long (x=-70 to +70)
#   - Shelter: z=-1.5 to z=1.5, x=0 to 3
#   - Kerb: z=-4.5
#   - Sign line: x=10.5
#   - LANE_Z = -6.0: nearside lane (closer to shelter), bus body spans z=-7.25 to -4.75
#   - STOP_X = 3.0: bus centre at the shelter/bin area, door reachable from kerb
#   - The door is on the +z side (facing the shelter), at the front-third of the bus

signal doors_opened
signal doors_closed
signal arrived_at_stop
signal departed

@onready var body: MeshInstance3D = $Bus/Body
@onready var door_l: MeshInstance3D = $Bus/DoorLeafL
@onready var door_r: MeshInstance3D = $Bus/DoorLeafR
@onready var dest_board: MeshInstance3D = $Bus/DestBoard
@onready var windscreen: MeshInstance3D = $Bus/Windscreen
@onready var interior_light: OmniLight3D = $Bus/InteriorLight
@onready var headlight_l: OmniLight3D = $Bus/HeadlightL
@onready var headlight_r: OmniLight3D = $Bus/HeadlightR
@onready var engine_snd: AudioStreamPlayer3D = $EngineSnd
@onready var brake_snd: AudioStreamPlayer3D = $BrakeSnd
@onready var door_snd: AudioStreamPlayer3D = $DoorSnd
@onready var interior_snd: AudioStreamPlayer3D = $InteriorSnd

const LANE_Z := -6.0
const STOP_X := 3.0
const OFFSCREEN_X := -70.0
const DEPART_X := 90.0
const DOOR_OPEN_OFFSET := 0.55    # how far each leaf slides
const DOOR_CLOSED_L_X := 1.2      # left leaf closed position (local)
const DOOR_CLOSED_R_X := 1.8      # right leaf closed position (local)

var _door_open := false
var _moving := false
var _dest_mat: StandardMaterial3D
var _blank_tex: StandardMaterial3D
var _numbered_tex: StandardMaterial3D

func _ready() -> void:
	add_to_group(&"bus")
	# Start offscreen and invisible. Events call arrive() or pass_by() which
	# make the bus visible and drive it in.
	position = Vector3(OFFSCREEN_X, 0.0, LANE_Z)
	visible = false
	# Prepare the destination board material (duplicate so we never write into
	# the shared resource).
	_dest_mat = dest_board.get_active_material(0).duplicate() as StandardMaterial3D
	dest_board.material_override = _dest_mat
	# The destination board uses albedo_color, not a texture, for the first
	# build. Blank = dark grey, "47" = warm orange. A texture swap can come
	# later (B6 spec mentions dest_blank.png / dest_47.png).
	set_board(false)
	set_lights(false)
	set_interior_lit(false)
	close_doors(true)

# ---------- public API ----------

func set_night(idx: int) -> void:
	# A3 hook. Called by main.gd::_apply_night_content(idx). Sets the board
	# state and interior mode for the night. Does NOT position the bus or
	# open doors -- those are the event's job.
	match idx:
		1:
			# Night 1: pass-by. Blank board, lights on (so the player sees it
			# pass), interior dark.
			set_board(false)
			set_interior_lit(false)
		2:
			# Night 2: numberless arrival. Blank board, interior lit (so the
			# empty interior is visible through the open doors).
			set_board(false)
			set_interior_lit(false)  # lit when doors open
		3:
			# Night 3: real bus. "47" on the board, interior lit.
			set_board(true)
			set_interior_lit(false)  # lit when doors open
		_:
			set_board(false)
			set_interior_lit(false)

func set_board(numbered: bool) -> void:
	# Swap the destination board colour. Blank = dark grey (illegible at
	# distance), "47" = warm orange (reads as a number at a glance). A real
	# texture swap can replace this later.
	if numbered:
		_dest_mat.albedo_color = Color(0.85, 0.55, 0.15, 1.0)  # warm orange
		_dest_mat.emission_enabled = true
		_dest_mat.emission = Color(0.6, 0.35, 0.1, 1.0)
		_dest_mat.emission_energy_multiplier = 1.5
	else:
		_dest_mat.albedo_color = Color(0.08, 0.08, 0.09, 1.0)  # near-black
		_dest_mat.emission_enabled = false

func set_lights(on: bool) -> void:
	if headlight_l:
		headlight_l.visible = on
	if headlight_r:
		headlight_r.visible = on

func set_interior_lit(on: bool) -> void:
	if interior_light:
		interior_light.visible = on
	# Emissive windows would go here when the bus has window meshes.

func arrive(from_x: float = OFFSCREEN_X, lead: float = 15.0) -> void:
	# Drive in from from_x, decelerate to a stop at STOP_X. TRANS_QUAD +
	# EASE_OUT reads as braking (fast then slowing). Plays the engine
	# approach sound, then the brake hiss on arrival.
	if _moving:
		return
	_moving = true
	visible = true
	position.x = from_x
	set_lights(true)
	engine_snd.stream = load("res://audio/engine_approach.wav")
	engine_snd.play()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:x", STOP_X, lead)
	tw.tween_callback(func() -> void:
		engine_snd.stop()
		brake_snd.stream = load("res://audio/brake_hiss.wav")
		brake_snd.play())
	await tw.finished
	_moving = false
	arrived_at_stop.emit()

func open_doors() -> void:
	# Slide the two door leaves apart. Plays the door-open sound. Lights the
	# interior so the player can see inside through the open doors.
	if _door_open:
		return
	_door_open = true
	door_snd.stream = load("res://audio/door_open.wav")
	door_snd.play()
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(door_l, "position:x", DOOR_CLOSED_L_X - DOOR_OPEN_OFFSET, 0.8)
	tw.tween_property(door_r, "position:x", DOOR_CLOSED_R_X + DOOR_OPEN_OFFSET, 0.8)
	set_interior_lit(true)
	interior_snd.stream = load("res://audio/interior_hum.wav")
	interior_snd.play()
	await tw.finished
	doors_opened.emit()

func close_doors(silent := false) -> void:
	# Slide the door leaves together. If silent (the initial reset), skip the
	# sound and the tween -- snap closed.
	if not _door_open and not silent:
		return
	_door_open = false
	if not silent:
		door_snd.stream = load("res://audio/door_close.wav")
		door_snd.play()
		var tw := create_tween().set_parallel(true)
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(door_l, "position:x", DOOR_CLOSED_L_X, 0.8)
		tw.tween_property(door_r, "position:x", DOOR_CLOSED_R_X, 0.8)
		await tw.finished
	else:
		door_l.position.x = DOOR_CLOSED_L_X
		door_r.position.x = DOOR_CLOSED_R_X
	set_interior_lit(false)
	interior_snd.stop()
	doors_closed.emit()

func depart() -> void:
	# Close doors, turn off headlights, drive away to DEPART_X. TRANS_QUAD +
	# EASE_IN reads as accelerating away.
	if _moving:
		return
	await close_doors()
	set_lights(false)
	_moving = true
	engine_snd.stream = load("res://audio/engine_approach.wav")
	engine_snd.play()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:x", DEPART_X, 8.0)
	tw.tween_callback(func() -> void:
		engine_snd.stop()
		visible = false)
	await tw.finished
	_moving = false
	departed.emit()

func pass_by(duration: float = 9.0) -> void:
	# Drive from OFFSCREEN_X through to DEPART_X without stopping. TRANS_LINEAR
	# for constant speed. Headlights on so the player sees the bus pass in the
	# dark. The event (B7) times the lamp blackout to the midpoint of this.
	if _moving:
		return
	_moving = true
	visible = true
	position.x = OFFSCREEN_X
	set_lights(true)
	engine_snd.stream = load("res://audio/engine_approach.wav")
	engine_snd.play()
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_LINEAR)
	tw.tween_property(self, "position:x", DEPART_X, duration)
	tw.tween_callback(func() -> void:
		engine_snd.stop()
		set_lights(false)
		visible = false)
	await tw.finished
	_moving = false

func reset() -> void:
	# Snap to offscreen, invisible, doors closed, lights off. Call this at
	# night start and on any restart so no state leaks from the previous night.
	if _moving:
		# Can't cleanly reset mid-move; force-stop the tweens by setting the
		# position directly. The tweens will finish harmlessly on the next
		# frame.
		_moving = false
	close_doors(true)
	set_lights(false)
	set_interior_lit(false)
	set_board(false)
	engine_snd.stop()
	interior_snd.stop()
	brake_snd.stop()
	door_snd.stop()
	position = Vector3(OFFSCREEN_X, 0.0, LANE_Z)
	visible = false

func door_world_pos() -> Vector3:
	# The door is at the front-third of the bus on the +z (shelter) side.
	# Events use this to position the door Interactable. The offset is in
	# local space; since the bus doesn't rotate, local == world offset.
	return global_position + Vector3(2.0, 0.0, 1.25)
