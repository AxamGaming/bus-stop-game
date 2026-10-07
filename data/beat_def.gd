# data/beat_def.gd  --  GDD 18 "Data model"
# A beat is one row of a night's beat sheet (GDD 11). Beats inside a NightDef MUST be
# sorted ascending by time_sec: the Director queues them with a single forward cursor,
# so one out-of-order beat is silently never played. Director._assert_beats_sorted()
# fails loudly at runtime instead.
class_name BeatDef extends Resource

enum Kind { AUTHORED, FILL }

@export var time_sec := 0.0
@export var kind := Kind.AUTHORED
@export var event: HorrorEvent            # AUTHORED
@export var pool: Array[HorrorEvent]      # FILL
@export var max_delay := 20.0             # 40.0 for rule tests
# Structural beat: fires at time_sec and ignores EVERY pacing rule. The three bus
# arrivals only. Without it the arrival measured +15.02 s late in all three nights,
# because the preceding "engine approaches" beat's calm window covers the arrival
# instant and max_delay never rescues it (GDD 13).
@export var punctual := false
