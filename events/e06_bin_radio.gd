extends EventBase
# events/e06_bin_radio.gd -- GDD 12 E6. Night 2 at 1:20, Night 3 at 1:20.
# Plays static then a short voice fragment from the bin. Establishes "the
# voice" that E7 (the stranger) and Ending 3 (spoke_first) pay off.
# Load-bearing for Rule 2 ("do not speak first") -- the player has heard a
# voice before the stranger appears, so speaking to the stranger feels like
# a response, not an initiation.
#
# Design:
#   - The bin is at (3.5, 0.45, 0.4). The AudioStreamPlayer3D is positioned
#     there so the voice comes from the bin's direction.
#   - The WAV has static baked in (radio_static.wav is a pure static loop;
#     for the first build we use voice_fragment_a.wav which is a processed
#     voice clip). A future version can chain static -> voice with two
#     players and a delay.
#   - Duration: the event waits for the audio to finish, then _done(). If
#     the clip is 6s, the event runs ~6s. The Director's calm-window logic
#     (15s after intensity >= 2) prevents overlapping events.
#   - Night 3: same event, same position. GDD says "2+" so it plays on both
#     Night 2 and Night 3. The beat sheet controls when it fires.

@onready var radio: AudioStreamPlayer3D = $Radio

func _start() -> void:
	if radio == null or radio.stream == null:
		print("[e06] no radio stream assigned -- skipping")
		_done()
		return
	radio.play()
	await radio.finished
	_done()

func _cleanup() -> void:
	if radio and is_instance_valid(radio):
		radio.stop()
