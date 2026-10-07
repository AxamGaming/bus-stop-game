extends Node
# tests/test_a3_content.gd -- A3 per-night content hook test.
# Verifies that poster.gd and timetable.gd respond to set_night(idx) with the
# correct text for each night. Run headless:
#   godot --path . --headless tests/test_a3_content.tscn
#
# This is an isolated unit test: it instantiates the bus_stop scene, grabs the
# PosterBody and TimetableBody nodes, calls set_night() on each, and asserts the
# Label3D text matches the expected const strings. No main.gd, no Fade, no
# Director -- just the A3 contract.

var _pass := 0
var _fail := 0
var _failures: Array[String] = []

func _ready() -> void:
	print("test_a3_content: loading bus_stop scene ...")
	var scene := load("res://world/bus_stop.tscn") as PackedScene
	if scene == null:
		_record_fail("load bus_stop.tscn", "returned null")
		_done()
		return
	var bus_stop := scene.instantiate()
	add_child(bus_stop)

	# Give the tree one frame so @onready vars resolve.
	await get_tree().process_frame

	var poster := bus_stop.get_node_or_null("PosterBody")
	var timetable := bus_stop.get_node_or_null("TimetableBody")
	if poster == null:
		_record_fail("find PosterBody", "node is null")
	if timetable == null:
		_record_fail("find TimetableBody", "node is null")
	if poster == null or timetable == null:
		_done()
		return

	# Verify the scripts are the new ones (not the base Interactable).
	if not poster.has_method("set_night"):
		_record_fail("poster.has_method(set_night)", "missing -- poster.gd not attached?")
	if not timetable.has_method("set_night"):
		_record_fail("timetable.has_method(set_night)", "missing -- timetable.gd not attached?")

	# --- Poster text per night ---
	var poster_label := poster.get_node("Label3D") as Label3D
	poster.set_night(1)
	_check("poster night 1", poster_label.text, "MISSING\n\n(la-t s-en\n\n— text washed out —)")
	poster.set_night(2)
	_check("poster night 2", poster_label.text, "MISSING\n\nlast seen waiting\nat this stop")
	poster.set_night(3)
	_check("poster night 3", poster_label.text, "MISSING\n\nlast seen waiting\nat this stop\n\n(a figure in a\nyellow raincoat\nwas seen here)")

	# Idempotency: calling set_night(2) twice produces the same state.
	poster.set_night(2)
	poster.set_night(2)
	_check("poster idempotent night 2", poster_label.text, "MISSING\n\nlast seen waiting\nat this stop")

	# --- Timetable text per night ---
	var tt_label := timetable.get_node("Label3D") as Label3D
	var smudged := """ROUTE 47
LAST BUS  11:47 PM

Please wait inside the light.

  1. [illegible — water damage]
  2. [illegible — water damage]
  3. [illegible — water damage]

Thank you for waiting."""
	var full := """ROUTE 47
LAST BUS  11:47 PM

Please wait inside the light.

  1. Do not board a bus
     that has no number.
  2. If someone is waiting
     with you, do not
     speak first.
  3. Never walk past
     the sign.

Thank you for waiting."""
	timetable.set_night(1)
	_check("timetable night 1 (smudged)", tt_label.text, smudged)
	timetable.set_night(2)
	_check("timetable night 2 (full)", tt_label.text, full)
	timetable.set_night(3)
	_check("timetable night 3 (full, same as 2)", tt_label.text, full)

	# Idempotency.
	timetable.set_night(1)
	timetable.set_night(1)
	_check("timetable idempotent night 1", tt_label.text, smudged)

	_done()

func _check(label: String, actual: String, expected: String) -> void:
	if actual == expected:
		_pass += 1
		print("  ok    %s" % label)
	else:
		_record_fail(label, "text mismatch.\n    expected: %s\n    actual:   %s" % [expected, actual])

func _record_fail(label: String, reason: String) -> void:
	_fail += 1
	_failures.append("%s -- %s" % [label, reason])
	print("  FAIL  %s -- %s" % [label, reason])

func _done() -> void:
	print("")
	print("test_a3_content: %d passed, %d failed" % [_pass, _fail])
	for f in _failures:
		printerr("  FAIL  ", f)
	get_tree().quit(1 if _fail > 0 else 0)
