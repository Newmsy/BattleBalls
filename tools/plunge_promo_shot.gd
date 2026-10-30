## Renders a Critter Plunge result popup with a promotion to a PNG (needs a
## display, e.g. xvfb-run): a race your racer wins with `--points` just under
## the next league. Usage: godot --path . --resolution 390x844 --script
## res://tools/plunge_promo_shot.gd -- --points=99 --out=/tmp/x.png
extends SceneTree

const CritterPlunge := preload("res://meta/critter_plunge.gd")
const Plunge := preload("res://sim/plunge.gd")
const Profile := preload("res://meta/profile.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const A11y := preload("res://game/a11y.gd")


func _initialize() -> void:
	var a := {"points": "99", "racer": "laser", "course": "storm", "large": "0", "secs": "3", "out": "user://promo.png"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	A11y.large_text = a.large == "1"
	var now := int(Time.get_unix_time_from_system())
	var p = Profile.new_game(now)
	p.stacks.append({"id": a.racer, "tier": 3, "count": 1, "level": 1})
	p.plunge.points = int(a.points)
	# A seed your racer wins on, so the popup reads 1st like the mock.
	var cfg := {}
	for s in range(int(a.get("seed", "1")), 200):
		cfg = CritterPlunge.race_for(p, a.racer, 6, s)
		cfg.course = a.course
		var sim := Plunge.new(cfg)
		while not sim.finished:
			sim.step()
		if sim.places[0] == 1:
			break
	CritterPlunge.pending = {"cfg": cfg, "fighter": a.racer}
	var scene = load("res://game/plunge.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene._racing = false # Hold the race: it is played out here.
	while not scene.sim.finished:
		scene.sim.step()
	scene._done = true
	scene.result = CritterPlunge.finish(p, a.racer, 1, 6, false, true, str(a.course), now)
	var gains: Array = p.take_faction_gains()
	var card: Control = scene._result_card(1, false, gains)
	ResultPopup.show_over(scene.ui_root, card)
	for i in int(float(a.secs) * 60):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(a.out)
	print("saved ", a.out, " promoted=", scene.result.get("promoted", false))
	quit()
