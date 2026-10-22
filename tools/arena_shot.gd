## Renders one frame of a fight on an arena to a PNG (needs a display, e.g. xvfb-run).
## Usage: godot --script res://tools/arena_shot.gd -- --arena=wells --p1=bubbles --p2=juggernaut --seed=3 --secs=6 --out=/tmp/x.png
extends SceneTree

const MatchSim := preload("res://sim/match_sim.gd")
const ArenaView := preload("res://game/arena_view.gd")


func _initialize() -> void:
	var a := {"arena": "square", "p1": "vampire", "p2": "laser", "seed": "1", "secs": "5", "out": "user://arena.png"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	root.size = Vector2i(700, 700)
	var bg := ColorRect.new()
	bg.color = Color("0b0920")
	bg.size = Vector2(700, 700)
	root.add_child(bg)
	var view := ArenaView.new()
	root.add_child(view)
	view.fit(Vector2(10, 10), 680.0)
	var sim := MatchSim.new({"seed": int(a.seed), "p1": a.p1, "p2": a.p2, "angles": [null, null], "arena": a.arena})
	view.sim = sim
	var ticks := int(float(a.secs) * MatchSim.TICK_RATE)
	for i in ticks:
		view.snapshot_positions()
		sim.step()
		view.consume_events(sim.events)
		view.advance_effects(MatchSim.DT)
		if sim.finished:
			break
	view.queue_redraw()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(a.out)
	print("saved ", a.out)
	quit()
