# data/night_def.gd  --  GDD 18 "Data model", GDD 11, GDD 14
# One .tres per night in res://data/nights/. main.gd exports an Array[NightDef].
class_name NightDef extends Resource

@export var index := 1
@export var real_seconds := 300.0          # the moment the bus ARRIVES
@export var post_arrival_seconds := 30.0   # decision window after arrival
@export var figure_cap_index := 1          # highest STATION INDEX allowed tonight (0-based; see GDD 14)
@export var gaze_lethal := false           # TRUE FOR NIGHT 3 ONLY -- see GazeMonitor
@export var sign_lethal := false
@export var breach_enabled := false        # fifth station, debug-gated (F8)
@export var beats: Array[BeatDef]

const SECONDS_PER_MINUTE := 25.0
const ARRIVAL_MINUTE := 47                 # 11:47 PM

func start_minute() -> int:
	return ARRIVAL_MINUTE - roundi(real_seconds / SECONDS_PER_MINUTE)

# ---- Per-night values (GDD 18). tests/test_night_flags.gd asserts these exactly. ----
# index                    1      2      3
# real_seconds           300    380    405
# post_arrival_seconds    30     45     60
# figure_cap_index         1      2      3
# gaze_lethal          false  false   true
# sign_lethal          false   true   true
#
# Station indexing (GDD 14) -- 0-based code vs 1-based prose, spelled out on purpose:
#   cap_index 0 = station 1 = x -26 m = 26 m from lamp = outside light = never a cap
#   cap_index 1 = station 2 = x -19 m = 19 m from lamp = outside light = NIGHT 1 cap
#   cap_index 2 = station 3 = x -13 m = 13 m from lamp = outside light = NIGHT 2 cap
#   cap_index 3 = station 4 = x  -9 m =  9 m from lamp = outside light = NIGHT 3 cap
#   cap_index 4 = station 5 = x  -5 m =  5 m from lamp = INSIDE light  = breach only
# FogFigure.configure() clamps the cap to stations.size() - 2, so index 4 can never be
# selected as a cap.
