extends Interactable
# world/timetable.gd -- the Route 47 timetable on the shelter wall.
# A3 (per-night content hook). Extends Interactable so the tap-to-read lean-in
# still works, and adds set_night(idx) so main.gd can swap the timetable's text
# per night. The timetable's *look* (modulate, font, pixel_size, position) is
# constant -- only the text changes. The swap happens behind the fade's black
# rectangle, so no animation is needed or wanted.
#
# Night 1: the header and time are readable, but the three rules are smudged
#           (GDD 9 -- "Header and time readable; rules smudged"). This is the
#           rule-teaching beat: the player fails Night 1 without knowing the
#           rules, then Night 2 reveals them. The smudge is the teaching
#           device -- "there is something to read here, but not yet."
# Night 2: all three rules are legible (GDD 9 -- "All three rules readable").
# Night 3: same text as Night 2 (GDD 9 -- "Same text; stronger lures"). The
#           rules don't change again; the world just gets worse.
#
# set_night is synchronous, idempotent, and does not read Game.night_index.
# See poster.gd for the full design rationale.

@onready var _label: Label3D = $Label3D

# Night 1: the rules exist but are illegible. The header and time are clear so
# the player knows WHERE they are and WHEN the bus comes, but the three rules
# that would have kept them safe are gone. The "[illegible — water damage]"
# tags tell the player "there were rules here" -- the absence is the lesson.
const SMUDGED := "ROUTE 47
LAST BUS  11:47 PM

Please wait inside the light.

  1. [illegible — water damage]
  2. [illegible — water damage]
  3. [illegible — water damage]

Thank you for waiting."

# Night 2+: the full text. The three rules are now readable. The player has
# already failed Night 1 without them; now they get to try again, armed with
# the knowledge they were denied. This is the core teaching loop of the game
# (GDD 9 rule visibility table).
const FULL := "ROUTE 47
LAST BUS  11:47 PM

Please wait inside the light.

  1. Do not board a bus
     that has no number.
  2. If someone is waiting
     with you, do not
     speak first.
  3. Never walk past
     the sign.

Thank you for waiting."

func set_night(idx: int) -> void:
	# Night 1 is smudged; Nights 2 and 3 are full. The match is explicit even
	# though 2 and 3 share the same text -- spec 3.1 rule 4: "Even if a Night 3
	# change is identical to Night 2, the match should have a case for it.
	# Explicit > implicit." If Night 3 ever diverges (e.g. a lure event smudges
	# one rule again), this is where it goes.
	match idx:
		1:
			_label.text = SMUDGED
		2:
			_label.text = FULL
		3:
			_label.text = FULL
		_:
			push_warning("[timetable] unknown night index %d, falling back to Night 1" % idx)
			_label.text = SMUDGED
