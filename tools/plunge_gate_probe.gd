## Where does a gate gain or lose? For each course, races --races seeds and
## reports each gate pair's mean time (s) to pass the end of each section,
## relative to the field's mean there, so a gate bias can be traced to the
## section that makes it. Racers knocked out before a line are left out.
## godot --headless --script res://tools/plunge_gate_probe.gd -- --races=60 --n=6 --courses=lava --upto=3
extends SceneTree

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")


func _init() -> void:
	var races := 60
	var n := 6
	var upto := 3
	var base := 1
	var courses: Array = PlungeCourse.COURSES.map(func(c): return c.id)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--races="):
			races = int(a.get_slice("=", 1))
		if a.begins_with("--n="):
			n = int(a.get_slice("=", 1))
		if a.begins_with("--upto="):
			upto = int(a.get_slice("=", 1))
		if a.begins_with("--base="):
			base = int(a.get_slice("=", 1))
		if a.begins_with("--courses="):
			courses = Array(a.get_slice("=", 1).split(","))
	for id in courses:
		var sum := [] # [line][gate] -> total seconds
		var cnt := []
		var kinds := []
		for seed in range(base, base + races):
			var field: Array = Plunge.draw_field(seed, n)
			var p := Plunge.new({"seed": seed, "racers": field, "tiers": field.map(func(_x): return 1), "course": id})
			var lines: Array = []
			for k in mini(upto, p.course.sections.size()):
				lines.append(p.course.sections[k].y1)
				if kinds.size() <= k:
					kinds.append(p.course.sections[k].kind)
			lines.append(p.finish_y)
			while sum.size() < lines.size():
				var z := []
				z.resize(n)
				z.fill(0.0)
				sum.append(z)
				cnt.append(z.duplicate())
			var passed := []
			for i in n:
				passed.append(0)
			while not p.finished:
				p.step()
				for i in p.starters:
					var b = p.balls[i]
					while passed[i] < lines.size() and (b.pos.y >= lines[passed[i]] or p.places[i] > 0) and p.ko_ticks[i] < 0:
						sum[passed[i]][p.lanes[i]] += p.time()
						cnt[passed[i]][p.lanes[i]] += 1
						passed[i] += 1
		var out := []
		for k in sum.size():
			var mean := 0.0
			var c := 0.0
			for g in n:
				mean += sum[k][g]
				c += cnt[k][g]
			mean /= maxf(c, 1.0)
			var pairs := []
			for g in n / 2:
				var t: float = (sum[k][g] + sum[k][n - 1 - g]) / maxf(cnt[k][g] + cnt[k][n - 1 - g], 1.0)
				pairs.append("%+.2f" % (t - mean))
			out.append("%s@%.1f [%s]" % [kinds[k] if k < kinds.size() else "finish", mean, " ".join(pairs)])
		print("%-9s outer->inner: %s" % [id, "  ".join(out)])
	quit(0)
