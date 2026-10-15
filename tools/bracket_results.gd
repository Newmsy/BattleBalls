## Fights out every scheduled Bracket of Legends and writes the results to
## res://liveops/bracket_results.json, which the export bundles so the bracket
## screen opens with every match already decided (a phone would take minutes).
## The results are exactly what the device would get itself; any bracket the
## file doesn't match (a schedule changed after the build) is fought out on
## the device as before. Run by tools/ci/export_web.sh before exporting.
## Usage: godot --headless --script res://tools/bracket_results.gd
extends SceneTree

const Legends := preload("res://game/legends.gd")
const LiveOps := preload("res://game/liveops.gd")


func _init() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	var out := {}
	for ev in Legends.events():
		var t0 := Time.get_ticks_msec()
		var b := Legends.Bracket.new({"seed": ev.seed, "entrants": ev.entrants})
		b.work(b.rounds - 1, Callable())
		out[ev.id] = b.results()
		print("%s: %d entrants, champion %s (%d ms)" % [ev.id, ev.entrants.size(), b.champion(), Time.get_ticks_msec() - t0])
	var f := FileAccess.open(Legends.BUNDLED_RESULTS, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	quit(0)
