## Renders whole Critter Plunge courses, top to bottom, as tall PNGs (needs a
## display, e.g. xvfb-run), with the race `--secs` seconds in so the moving
## pieces sit where they would. Usage: godot --path . --script
## res://tools/plunge_course_shot.gd -- --course=gumdrop (or all) --seed=3
## --secs=6 --width=300 --out=/tmp/plunge (writes <out>/<course>.png)
extends SceneTree

const Plunge := preload("res://sim/plunge.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const PlungeView := preload("res://game/plunge_view.gd")

const SLICE := 900 ## Screen px rendered per pass.


func _initialize() -> void:
	var a := {"course": "all", "seed": "3", "secs": "6", "width": "300", "out": "user://plunge_courses"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	DirAccess.make_dir_recursive_absolute(a.out)
	var ids: Array = PlungeCourse.COURSES.map(func(c): return c.id) if a.course == "all" else a.course.split(",")
	var w := int(a.width)
	root.size = Vector2i(w, SLICE)
	for id in ids:
		var sim := Plunge.new({"seed": int(a.seed), "racers": Plunge.draw_field(int(a.seed), 8), "course": id})
		for k in int(float(a.secs) * Plunge.TICK_RATE):
			sim.step()
		var bg := ColorRect.new()
		bg.color = Color("0b0920")
		bg.size = Vector2(w, SLICE)
		root.add_child(bg)
		var view := PlungeView.new()
		root.add_child(view)
		view.set_race(sim, -1)
		view.view_size = Vector2(w, SLICE)
		view.view_scale = float(w) / Plunge.WIDTH
		var total := int((sim.finish_y + 200.0) * view.view_scale)
		var out := Image.create(w, total, false, Image.FORMAT_RGBA8)
		var y := 0
		while y < total:
			view.camera_y = y / view.view_scale
			view.position = Vector2(0.0, -view.camera_y * view.view_scale)
			view.queue_redraw()
			await process_frame
			await process_frame
			await process_frame
			var img := root.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			out.blit_rect(img, Rect2i(0, 0, w, mini(SLICE, total - y)), Vector2i(0, y))
			y += SLICE
		out.save_png("%s/%s.png" % [a.out, id])
		print("%s: finish %.0f, %d movers" % [id, sim.finish_y, sim.arena.obstacles.size()])
		view.queue_free()
		bg.queue_free()
		await process_frame
	quit()
