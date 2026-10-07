extends Node
# core/save.gd  --  autoload `Save`.  GDD 18 "Save".
# Deliberately free of cross-references in _ready(): read() is called explicitly from
# Main._ready(), which keeps the autoload order irrelevant (GDD 18/19). If you ever move
# read() into _ready(), Game must be listed ABOVE Save in Project Settings.

const PATH := "user://save.cfg"

func write() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "endings", Game.endings_seen)
	cfg.save(PATH)

func read() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		Game.endings_seen.assign(cfg.get_value("progress", "endings", []))

func wipe() -> void:
	Game.endings_seen.clear()
	write()
