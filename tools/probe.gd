## Prints the determinism probe hash (sim/probe.gd) the way the web build's
## ?probe=1 does, so CI can compare the two.
## godot --headless --script res://tools/probe.gd [-- --fights=200]
extends SceneTree

const Probe := preload("res://sim/probe.gd")


func _init() -> void:
	var fights := Probe.DEFAULT_FIGHTS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fights="):
			fights = int(arg.split("=")[1])
	var t0 := Time.get_ticks_msec()
	var r := Probe.run(fights)
	print("PROBE %s %d %dms" % [r.hash, r.fights, Time.get_ticks_msec() - t0])
	quit()
