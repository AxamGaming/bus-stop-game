extends Interactable
# world/poster.gd -- the MISSING poster on the shelter pole.
# A3 (per-night content hook). Extends Interactable so the tap-to-read lean-in
# still works, and adds set_night(idx) so main.gd can swap the poster's text
# per night. The poster's *look* (modulate, font, pixel_size) is constant --
# only the text changes. The swap happens behind the fade's black rectangle, so
# no animation is needed or wanted (animating it would waste frames and risk a
# visible pop if the fade is shorter than the animation).
#
# Night 1: water-damaged, mostly unreadable (GDD 10 -- "Water-damaged, mostly
#           unreadable"). The player can tell there WAS text, but can't read it.
# Night 2: a silhouette and partial text emerge (GDD 10 -- "A silhouette,
#           partial text").
# Night 3: same as 2, plus a note that the figure wore a yellow raincoat --
#           the same as the player's sleeves (GDD 10).
#
# set_night is synchronous, idempotent, and does not read Game.night_index.
# It trusts the argument so the object is testable in isolation. main.gd calls
# it from run_night() after the figure/gaze/lamp/sign_line config and before
# the clock starts -- the night's initial state is correct before the first
# tick. On a restart (non-terminal ending), set_night is called again with the
# same index; idempotency means no stale state leaks through.

@onready var _label: Label3D = $Label3D

# Night 1: the text is water-damaged. The fragments suggest what was written,
# but the words are gone. This is the rule-teaching beat: the player learns
# there IS something to read here, but cannot read it yet. The smudge matches
# the timetable's Night 1 smudge (see timetable.gd) -- both readable objects
# withhold their content on Night 1 and reveal it on Night 2+.
const TEXT_NIGHT_1 := "MISSING\n\n(la-t s-en\n\n— text washed out —)"

# Night 2: the poster has dried enough to read. The silhouette is now visible
# and the key phrase "last seen waiting at this stop" is legible.
const TEXT_NIGHT_2 := "MISSING\n\nlast seen waiting\nat this stop"

# Night 3: the same text as Night 2, plus the payoff line. The yellow raincoat
# matches the player's sleeves -- the poster is about the player. This is the
# moment the horror lands: the MISSING person is you.
const TEXT_NIGHT_3 := "MISSING\n\nlast seen waiting\nat this stop\n\n(a figure in a\nyellow raincoat\nwas seen here)"

func set_night(idx: int) -> void:
	match idx:
		1:
			_label.text = TEXT_NIGHT_1
		2:
			_label.text = TEXT_NIGHT_2
		3:
			_label.text = TEXT_NIGHT_3
		_:
			# Defensive: an unknown night index should never reach here. Fall
			# back to the Night 1 (smudged) text rather than crash -- a wrong
			# poster is a bug, a missing poster is a showstopper.
			push_warning("[poster] unknown night index %d, falling back to Night 1" % idx)
			_label.text = TEXT_NIGHT_1
