extends Node3D
# world/rain_splashes.gd
#
# A Godot 4.7 port of the script from the video description:
#     https://pastebin.com/tQCtHiyu   --  Miziziziz, "How to make it rain in Godot" (2019)
#
# His structure, his variable names, his spawn loop, unchanged. Where the Godot 4 API
# differs, the line carries a PORT comment so you can diff it against the pastebin.
#
# The technique, in his words: most games don't check raindrop collision to see when they
# hit the ground. They randomly generate splashes all over, raycast down, and it looks good
# enough. It is also automatically correct on every surface -- roof, road, kerb, bench --
# with nothing to maintain when the geometry changes.

@export var splash_area := 50.0            # his default. main.tscn sets 14.0: our whole
                                           # playable radius is 14 m (GDD 8), so +/-14 covers
                                           # everything the player can see. His demo was open ground
@export var splashes_per_second := 300.0   # his value, verbatim
@export var splash_pool_size := 200        # his value, verbatim
@export var drop_from := 9.0               # PORT: his script raycast from the emitter, which sat
                                           # high in the air. Ours follows the player at y ~ 0, so
                                           # the ray has to start above the 2.45 m shelter roof
@export var ray_length := 400.0            # his 400, verbatim
@export_flags_3d_physics var mask := 1     # PORT: Godot 4's intersect_ray takes a mask. Layer 1
                                           # (world) only: never the player, triggers or the figure
@export var follow: Node3D                 # PORT: see drop_from. Left null -> found by group
@export var follow_group := &"player"

# var splash_obj = preload("./RainSplash.tscn")
var splash_obj := preload("res://world/rain_splash.tscn")
var splashes: Array[Sprite3D] = []

var time_since_splash := 0.0
var splash_rate := 1.0 / 300.0             # PORT: he computed this as a field initialiser, which
                                           # silently ignores whatever the scene sets on
                                           # splashes_per_second. Computed in _ready() instead
var cur_splash_ind := 0

func _ready() -> void:
	splash_rate = 1.0 / splashes_per_second
	for i in range(splash_pool_size):
		var s := splash_obj.instantiate() as Sprite3D
		assert(s != null, "world/rain_splash.tscn must instance to a Sprite3D")
		add_child(s)
		splashes.append(s)
		s.hide()
		# Loud, not silent: if the splash scene's AnimationPlayer or its "splash" animation is
		# missing, every splash would be invisible and nothing would ever tell you.
		var ap := s.get_node_or_null("AnimationPlayer") as AnimationPlayer
		assert(ap != null and ap.has_animation(&"splash"),
			"rain_splash.tscn needs an AnimationPlayer child with an animation named 'splash'")
		# Track paths are relative to AnimationPlayer.root_node, which defaults to ".." = this
		# node's PARENT = the Sprite3D. So a track must be ".:visible", NOT "..:visible": the
		# latter resolves one level too high, animates the POOL node, and every splash stays
		# hidden forever. This assert exists because that exact bug shipped once and looked
		# exactly like "the splash animation does nothing".
		var anim := ap.get_animation(&"splash")
		for tr in range(anim.get_track_count()):
			var tp := anim.track_get_path(tr)
			assert(tp.get_name_count() == 0,
				"rain_splash.tscn: track %d is '%s'. The AnimationPlayer is a CHILD of the Sprite3D, "
				+ "so its tracks must be '.:property' -- '%s' animates something above the sprite "
				+ "and the splash never appears." % [tr, str(tp), str(tp)])

func _physics_process(delta: float) -> void:
	# PORT: he ran this in _process(). Godot 4 only guarantees direct space state access in
	# _physics_process (GDD 18 makes the same rule for LookAtTracker), so it moved.
	if follow == null:
		follow = get_tree().get_first_node_in_group(follow_group) as Node3D
	if follow == null:
		return
	time_since_splash += delta
	while time_since_splash >= splash_rate:
		make_splash()
		cur_splash_ind += 1
		cur_splash_ind %= splashes.size()
		time_since_splash -= splash_rate
	# NOTE the `while`, not an `if`: with an `if` you could only ever make one splash per
	# frame, capping the rate at the frame rate. That is his point and it is correct.

func make_splash() -> void:
	var x_pos := randf_range(-splash_area, splash_area)        # PORT: rand_range -> randf_range
	var z_pos := randf_range(-splash_area, splash_area)
	var start_pos := follow.global_transform.origin + Vector3(x_pos, drop_from, z_pos)

	var space_state := get_world_3d().direct_space_state       # PORT: get_world() -> get_world_3d()
	var q := PhysicsRayQueryParameters3D.create(
		start_pos, start_pos - Vector3(0, ray_length, 0), mask)  # PORT: 4 takes query parameters
	var result := space_state.intersect_ray(q)
	if result.size() > 0:
		# PORT: his offset was 0.5 in a scene measured in tens of metres with no shelter. Here
		# half a metre puts the splash visibly FLOATING above the road; 5 cm sits it on the hit.
		splashes[cur_splash_ind].global_transform.origin = result.position + Vector3(0, 0.05, 0)
		splashes[cur_splash_ind].get_node("AnimationPlayer").play("splash")
