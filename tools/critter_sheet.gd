## Renders a contact sheet of critters side by side at several tiers to a PNG,
## to check critter art (game/ui/critter_art.gd). Needs a display, e.g. xvfb-run.
## Usage: godot --script res://tools/critter_sheet.gd -- --tiers=1,3,5 --page=0 --per=30 --cols=5 --t=0.7 --out=/tmp/sheet.png
## --ids=vampire,laser draws just those critters (page/per then apply to that list); --cell=200 draws them bigger.
extends SceneTree

const CritterArt := preload("res://game/ui/critter_art.gd")
const CritterDb := preload("res://sim/critter_db.gd")

var CELL := 116.0
const LABEL := 22.0


func _initialize() -> void:
	var a := {"tiers": "1,3,5", "page": "0", "per": "30", "cols": "5", "t": "0.7", "out": "user://critter_sheet.png", "ids": "", "cell": "116"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	CELL = float(a.cell)
	var tiers: Array = Array(a.tiers.split(",")).map(func(x): return int(x))
	var ids: Array = CritterDb.ids().filter(func(id): return id != "plain")
	if a.ids != "":
		ids = Array(a.ids.split(","))
	var per := int(a.per)
	var page := int(a.page)
	ids = ids.slice(page * per, (page + 1) * per)
	var cols := mini(int(a.cols), ids.size())
	var rows := ceili(ids.size() / float(cols))
	var group := CELL * tiers.size() + 14.0
	var size := Vector2i(int(group * cols + 10), int((CELL + LABEL) * rows + 10))
	var vp := SubViewport.new()
	vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color("0b0920")
	bg.size = Vector2(size)
	vp.add_child(bg)
	var canvas := Node2D.new()
	vp.add_child(canvas)
	var t := float(a.t)
	canvas.draw.connect(func():
		var font := ThemeDB.fallback_font
		for i in ids.size():
			var gx := 10.0 + (i % cols) * group
			var gy := 10.0 + floorf(i / float(cols)) * (CELL + LABEL)
			canvas.draw_rect(Rect2(gx - 4, gy - 4, group - 6, CELL + LABEL - 2), Color(1, 1, 1, .04))
			var d := CritterDb.get_critter(ids[i])
			canvas.draw_string(font, Vector2(gx, gy + 12), "%s (%s)" % [d.name, ids[i]], HORIZONTAL_ALIGNMENT_LEFT, group - 10, 13, Color(1, 1, 1, .8))
			for k in tiers.size():
				var c := Vector2(gx + CELL * (k + .5), gy + LABEL + CELL * .55)
				canvas.draw_string(font, Vector2(gx + CELL * k + 4, gy + LABEL + 12), "T%d" % tiers[k], HORIZONTAL_ALIGNMENT_LEFT, 40, 11, Color(1, .85, .4, .7))
				CritterArt.draw_critter(canvas, ids[i], c, CELL * .24, {"t": t, "tier": tiers[k], "look": Vector2(.6, .2)})
	)
	canvas.queue_redraw()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(a.out)
	print("saved ", a.out)
	quit()
