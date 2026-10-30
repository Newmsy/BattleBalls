## Renders the Critter Plunge screen to a PNG at a league's points (needs a
## display, e.g. xvfb-run). Usage: godot --path . --resolution 390x844 --script
## res://tools/plunge_shot.gd -- --points=78 --prize=5 --large=0 --out=/tmp/x.png
extends SceneTree

const CritterPlunge := preload("res://meta/critter_plunge.gd")
const A11y := preload("res://game/a11y.gd")
const BossRuns := preload("res://meta/boss_runs.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const Families := preload("res://sim/families.gd")


func _initialize() -> void:
	var a := {"points": "78", "prize": "5", "large": "0", "racer": "laser", "out": "user://plunge.png"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	A11y.large_text = a.large == "1"
	var shell = load("res://game/ui/shell.gd").new()
	root.add_child(shell)
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.build()
	var p = shell.profile
	p.stacks.append({"id": a.racer, "tier": 3, "count": 1, "level": 1})
	p.lineup = a.racer
	CritterPlunge.racer = a.racer
	if a.has("course"): # The next race on this course (by its name), as the mocks show.
		while CritterPlunge.course_for(CritterPlunge.next_seed(p)).name != a.course and p.runs < 5000:
			p.runs += 1
	CritterPlunge.demo(p)
	for tal in PlungeTalents.TALENTS.slice(0, 2): # Some of your racer's family's talents, for the medal row.
		for k in 3:
			PlungeTalents.buy(p, Families.of(a.racer), tal.id)
	PlungeTalents.add_medal(p, "gold")
	PlungeTalents.add_medal(p, "silver")
	p.plunge.points = int(a.points)
	var now := int(Time.get_unix_time_from_system())
	BossRuns.use(p, CritterPlunge.PRIZE_KEY, CritterPlunge.PRIZE_RACES, now, CritterPlunge.PRIZE_RACES - int(a.prize))
	shell.go("plunge")
	for i in 30:
		await process_frame
	if a.has("tap"): # --tap=plunge_league_info: press that marked button first.
		shell._marks[a.tap].pressed.emit()
		for i in 40:
			await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(a.out)
	print("saved ", a.out)
	quit()
