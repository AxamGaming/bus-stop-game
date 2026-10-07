extends Node
# core/game.gd  --  autoload `Game`.  GDD 18 "Game state and endings".
# The single state machine. Everything that ends a night goes through trigger_ending(),
# which is what makes fairness rule 9 ("no ending loops forever") enforceable in one place.

enum State { MENU, TRANSITION, NIGHT, ENDING }

signal night_started(index: int)
signal ending_triggered(id: StringName, variant: StringName)

var state := State.MENU
var night_index := 1
var endings_seen: Array[StringName] = []

func begin_night(index: int) -> void:
	night_index = index
	state = State.NIGHT
	AudioHub.reset()
	night_started.emit(index)

func trigger_ending(id: StringName, variant: StringName = &"") -> void:
	if state != State.NIGHT:      # ignores duplicates and out-of-night calls
		return
	state = State.ENDING
	if id not in endings_seen:
		endings_seen.append(id)
		Save.write()
	ending_triggered.emit(id, variant)

# ---- Ending ids (GDD 10) ----
#   out_of_the_light   variants: "sign" (crossed the line) | "gaze" (lamp died at the cap)
#   wrong_bus          boarded the numberless bus
#   spoke_first        spoke to the stranger
#   still_waiting      Night 3, did not board  -- TERMINAL, never restarts
#   right_bus          broke no rules, boarded the real bus
