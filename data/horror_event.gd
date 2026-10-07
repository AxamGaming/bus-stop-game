# data/horror_event.gd  --  GDD 18 "Data model"
# One .tres per event in res://data/events/. The Director reads these; it never
# hardcodes an event id.
class_name HorrorEvent extends Resource

@export var id: StringName
@export var scene: PackedScene
@export_range(1, 3) var intensity := 1
@export var min_night := 1
@export var max_night := 3
@export var weight := 1.0
@export var cooldown := 60.0      # read by the Director for fill picks
