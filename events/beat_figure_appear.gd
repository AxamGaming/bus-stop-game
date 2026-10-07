extends EventBase
# events/beat_figure_appear.gd -- GDD 11, Night 1's 0:40 beat.
# Steps the Fog Figure into existence at station 0 and finishes immediately.
# This is a structural beat, not a scare. It exists so the figure appears on a
# scheduled cue instead of being hardcoded in main.gd.

func _start() -> void:
	if ctx == null or ctx.figure == null:
		_done()
		return
	if ctx.figure.station_index < 0:
		ctx.figure.force_step()
		print("[figure] appears at station %d" % ctx.figure.station_index)
	_done()
