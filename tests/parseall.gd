extends Node
# tests/parseall.gd  --  GDD 22. **RUN THIS BEFORE BELIEVING ANY OTHER RESULT.**
#
# Why this exists: `godot --headless --import` runs update_scripts_classes, which scans for
# `class_name` declarations ONLY, and `--check-only --script <file>` does not register
# autoloads, so anything touching Game / Save / Settings / AudioHub fails under it
# spuriously. Neither catches every file. Loading every .gd at runtime, inside a project
# where the autoloads exist, does.
#
# The two scripts that did not compile in GDD v1.7 were the two no scene referenced --
# exactly the hole this closes.
#
# Run:  godot --path . --headless tests/parseall.tscn

var _total := 0
var _failed := 0
var _failures: Array[String] = []

func _ready() -> void:
	print("parseall: walking res:// for .gd files ...")
	_walk("res://")
	print("")
	if _total == 0:
		printerr("parseall: found NO .gd files -- the directory walk is broken, this is not a pass")
		get_tree().quit(1)
		return
	print("parseall: %d/%d scripts compiled, %d failures" % [_total - _failed, _total, _failed])
	for f in _failures:
		printerr("  FAIL  ", f)
	get_tree().quit(1 if _failed > 0 else 0)

func _walk(dir_path: String) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		push_warning("parseall: cannot open %s" % dir_path)
		return
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if d.current_is_dir():
			if not entry.begins_with("."):      # skips .godot, .import, .git
				_walk(full)
		elif entry.get_extension() == "gd":
			_check(full)
		entry = d.get_next()
	d.list_dir_end()

func _check(path: String) -> void:
	_total += 1
	var res: Resource = load(path)
	if res == null:
		_fail(path, "load() returned null")
		return
	if not (res is Script):
		_fail(path, "loaded a %s, not a Script" % res.get_class())
		return
	var script := res as Script
	if not script.can_instantiate():
		_fail(path, "can_instantiate() == false (parse error, or abstract/incomplete)")
		return
	print("  ok    ", path)

func _fail(path: String, reason: String) -> void:
	_failed += 1
	_failures.append("%s -- %s" % [path, reason])
