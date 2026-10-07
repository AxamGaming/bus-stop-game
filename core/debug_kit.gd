extends Node
# core/debug_kit.gd  --  ADDITION (PROJECT_STRUCTURE.md D4). GDD 13: "Debug tools (build
# early; they save days)." Everything here is duck-typed through groups and has_method(),
# so this script compiles and runs on day 1, before FogFigure and GazeMonitor exist.
#
# Delete the Escape block in week 2 when ui/menus/pause_menu.tscn takes it over.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # has to work while the tree is paused
	add_to_group(&"debug")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_F1:  dump()
		KEY_F6:  _toggle_noclip()
		KEY_F7:  _cycle_station()
		KEY_F8:  _toggle_breach()
		KEY_F9:  _force_gates()
		KEY_ESCAPE: _toggle_pause()

# ---- F1: pending and live beats, lamp level, figure station and cap, armed, lethal ----
func dump() -> void:
	print("---- F1 state dump ----")
	print("  Game.state      : ", Game.state, "   night ", Game.night_index)
	print("  endings seen    : ", Game.endings_seen)
	var lamp := _first(&"lamp")
	if lamp != null:
		print("  lamp.level      : %.3f   flicker %.2f   scripted_blackout %s   at_cap %s" % [
			lamp.level, lamp.get("_flicker"), lamp.scripted_blackout, lamp.at_cap])
		print("  lamp.light_energy : ", lamp.light.light_energy if lamp.light != null else "NULL")
	var fig := _first(&"figure")
	if fig != null:
		print("  figure          : station %d / cap %d   visible %s   watched %s   breached %s   step_requested %s" % [
			fig.station_index, fig.cap_index, fig.visible, fig.watched, fig.breached, fig.step_requested])
	var gaze := _first(&"gaze")
	if gaze != null:
		print("  gaze            : armed %s   lethal_tonight %s   _stare %.2f" % [
			gaze.armed, gaze.lethal_tonight, gaze.get("_stare")])
	var clock := _first(&"clock")
	if clock != null and clock.has_method("current_minute"):
		print("  clock           : minute %d   running %s" % [clock.current_minute(), clock.running])
	var dir := _first(&"director")
	if dir != null:
		print("  director        : running %s   pending %d   live %d   calm_until %.1f" % [
			dir.running, dir.get("_pending").size() if dir.get("_pending") != null else -1,
			dir.get("_live").size() if dir.get("_live") != null else -1, dir.get("_calm_until")])
	print("-----------------------")

func _toggle_noclip() -> void:
	var p := _first(&"player")
	if p == null:
		return
	p.noclip = not p.noclip
	print("noclip: ", p.noclip)

func _cycle_station() -> void:
	var fig := _first(&"figure")
	if fig == null or not fig.has_method("_move_to"):
		return
	var n: int = fig.stations.size()
	var next := wrapi(fig.station_index + 1, 0, n)
	fig.cap_index = n - 1          # let it walk all the way to the breach station
	fig._move_to(next)
	print("figure station -> ", next, " (x = %.1f)" % fig.global_position.x)

func _toggle_breach() -> void:
	var fig := _first(&"figure")
	if fig == null:
		return
	fig.breach_enabled = not fig.breach_enabled
	print("breach_enabled: ", fig.breach_enabled)

# Test the gaze death without earning it (GDD 13 F9). Both flags, or nothing happens:
# the kill needs lethal_tonight AND armed AND at_cap().
func _force_gates() -> void:
	var gaze := _first(&"gaze")
	var fig := _first(&"figure")
	if gaze != null:
		gaze.armed = true
		gaze.lethal_tonight = true
	if fig != null:
		fig.cap_index = fig.stations.size() - 2
	print("forced: armed + lethal_tonight = true, cap_index = ", fig.cap_index if fig != null else -1)

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

func _first(group: StringName) -> Node:
	return get_tree().get_first_node_in_group(group)
