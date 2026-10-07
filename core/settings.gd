extends Node
# core/settings.gd  --  autoload `Settings`.  ADDITION to GDD 18 (PROJECT_STRUCTURE.md D3).
# GDD 17 lists ten options and GDD 18 never gives them a home; without this they end up
# duplicated across the options menu, the HUD and the shaders.
#
# VOLUME RULE (GDD 16): these sliders touch Master, SFX, Ambience and Voice ONLY. They
# must NEVER touch Weather -- AudioHub owns that bus for the silence beat. Note that
# Ambience *parents* Weather in default_bus_layout.tres, so the ambience slider does move
# the rain. That is intended; label the slider "Ambience & weather" in the options menu.

signal settings_changed

const PATH := "user://settings.cfg"
const MIN_DB := -80.0

# ---- audio (stored linear 0..1, applied as dB -- GDD 16: never pass 0..1 to AudioServer)
var volume_master := 1.0
var volume_sfx := 0.9
var volume_ambience := 0.9
var volume_voice := 1.0

# ---- look
var mouse_sensitivity := 1.0        # multiplier, 0.2 .. 3.0
var invert_y := false
var fov := 75.0                     # 60 .. 100. The gaze cone SCALES with this (GDD 18),
                                    # so widening the FOV cannot create a free-safe band
var head_bob := true

# ---- accessibility (GDD 17)
var reduce_flicker := false         # one slow dim instead of the stutter
var show_gaze_boundary := false     # cone-matched vignette, default OFF
var captions := true                # DIRECTIONAL captions, load-bearing not polish
var press_instead_of_hold := false  # swaps hold-to-confirm for press-to-confirm

# ---- presentation
var psx_snap := true                # vertex snapping
var psx_dither := true              # ordered dither (Godot's fog does not dither, GDD 15)
var fullscreen := false
var window_scale := 3               # integer scale of the 640x360 base

const BASE_WIDTH := 640
const BASE_HEIGHT := 360

func _ready() -> void:
	# No cross-references to other autoloads here: keep the autoload order irrelevant.
	apply_all()

# Call explicitly from Main._ready() (GDD 18's order-independent pattern).
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		apply_all()
		return
	volume_master = cfg.get_value("audio", "master", volume_master)
	volume_sfx = cfg.get_value("audio", "sfx", volume_sfx)
	volume_ambience = cfg.get_value("audio", "ambience", volume_ambience)
	volume_voice = cfg.get_value("audio", "voice", volume_voice)
	mouse_sensitivity = cfg.get_value("look", "sensitivity", mouse_sensitivity)
	invert_y = cfg.get_value("look", "invert_y", invert_y)
	fov = cfg.get_value("look", "fov", fov)
	head_bob = cfg.get_value("look", "head_bob", head_bob)
	reduce_flicker = cfg.get_value("access", "reduce_flicker", reduce_flicker)
	show_gaze_boundary = cfg.get_value("access", "show_gaze_boundary", show_gaze_boundary)
	captions = cfg.get_value("access", "captions", captions)
	press_instead_of_hold = cfg.get_value("access", "press_instead_of_hold", press_instead_of_hold)
	psx_snap = cfg.get_value("video", "psx_snap", psx_snap)
	psx_dither = cfg.get_value("video", "psx_dither", psx_dither)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	window_scale = cfg.get_value("video", "window_scale", window_scale)
	apply_all()

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", volume_master)
	cfg.set_value("audio", "sfx", volume_sfx)
	cfg.set_value("audio", "ambience", volume_ambience)
	cfg.set_value("audio", "voice", volume_voice)
	cfg.set_value("look", "sensitivity", mouse_sensitivity)
	cfg.set_value("look", "invert_y", invert_y)
	cfg.set_value("look", "fov", fov)
	cfg.set_value("look", "head_bob", head_bob)
	cfg.set_value("access", "reduce_flicker", reduce_flicker)
	cfg.set_value("access", "show_gaze_boundary", show_gaze_boundary)
	cfg.set_value("access", "captions", captions)
	cfg.set_value("access", "press_instead_of_hold", press_instead_of_hold)
	cfg.set_value("video", "psx_snap", psx_snap)
	cfg.set_value("video", "psx_dither", psx_dither)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "window_scale", window_scale)
	cfg.save(PATH)

func apply_all() -> void:
	_set_bus_db("Master", volume_master)
	_set_bus_db("SFX", volume_sfx)
	_set_bus_db("Ambience", volume_ambience)
	_set_bus_db("Voice", volume_voice)
	# NEVER Weather. AudioHub owns it.
	_apply_window()
	settings_changed.emit()

func _set_bus_db(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		push_warning("Settings: audio bus '%s' is missing" % bus_name)
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0, 1.0)) if linear > 0.001 else MIN_DB)

func _apply_window() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
	if not fullscreen:
		var s := clampi(window_scale, 1, 6)
		DisplayServer.window_set_size(Vector2i(BASE_WIDTH * s, BASE_HEIGHT * s))

# Convenience for the options menu: set + apply + persist in one call.
func set_and_save(property: String, value: Variant) -> void:
	set(property, value)
	apply_all()
	save()
