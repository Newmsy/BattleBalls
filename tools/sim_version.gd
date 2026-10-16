## Writes res://sim_version.txt for an export (see sim/sim_version.gd).
## godot --headless --script res://tools/sim_version.gd
extends SceneTree

const SimVersion := preload("res://sim/sim_version.gd")


func _init() -> void:
	var v := SimVersion.from_source()
	var f := FileAccess.open(SimVersion.FILE, FileAccess.WRITE)
	f.store_string(v + "\n")
	f.close()
	print("sim_version ", v)
	quit()
