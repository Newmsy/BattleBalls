## Renders a contact sheet of cosmetics (game/glow/catalog.gd) to a PNG: hats on
## a critter, trails behind one, hit sparks and KO effects frozen mid-play.
## Needs a display, e.g. xvfb-run.
## Usage: godot --script res://tools/cosmetic_sheet.gd -- --out=/tmp/cos.png
##   --season=s1_neon_nights  only that season's pass cosmetics (game/glow/seasons.gd)
##   --ids=hat_party,ko_disco only those; --critter=vampire; --cols=6; --cell=180
extends SceneTree

const CritterArt := preload("res://game/ui/critter_art.gd")
const CosmeticArt := preload("res://game/glow/cosmetic_art.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const Seasons := preload("res://game/glow/seasons.gd")

var CELL := 180.0
const LABEL := 24.0


func _initialize() -> void:
	var a := {"out": "user://cosmetic_sheet.png", "ids": "", "season": "", "critter": "vampire", "cols": "6", "cell": "180", "t": "0.35"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and "=" in arg:
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	CELL = float(a.cell)
	var ids: Array = Catalog.ITEMS.map(func(it): return it.id)
	if a.season != "":
		ids = Seasons.cosmetic_ids(a.season)
	if a.ids != "":
		ids = Array(a.ids.split(","))
	var cols := mini(int(a.cols), ids.size())
	var rows := ceili(ids.size() / float(cols))
	var size := Vector2i(int(CELL * cols + 20), int((CELL + LABEL) * rows + 20))
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
	var critter: String = a.critter
	canvas.draw.connect(func():
		var font := ThemeDB.fallback_font
		for i in ids.size():
			var it := Catalog.item(ids[i])
			var gx := 10.0 + (i % cols) * CELL
			var gy := 10.0 + floorf(i / float(cols)) * (CELL + LABEL)
			canvas.draw_rect(Rect2(gx + 3, gy + 3, CELL - 6, CELL + LABEL - 6), Color(1, 1, 1, .05))
			canvas.draw_string(font, Vector2(gx + 8, gy + 18), "%s · %s" % [it.get("name", ids[i]), it.get("where", "")], HORIZONTAL_ALIGNMENT_LEFT, CELL - 12, 13, Color(1, 1, 1, .8))
			if it.is_empty():
				continue
			var c := Vector2(gx + CELL / 2.0, gy + LABEL + CELL / 2.0)
			var s := CELL
			match it.slot:
				"skin":
					CritterArt.draw_critter(canvas, str(it.critter), c + Vector2(0, s * .05), s * .28, {"t": t, "look": Vector2(.3, .2), "skin": it})
				"hat":
					var r := s * .24
					var at := c + Vector2(0, s * .14)
					CritterArt.draw_critter(canvas, critter, at, r, {"t": t, "look": Vector2(.3, .2)})
					CosmeticArt.draw_hat(canvas, it, at, r, t)
				"trail":
					var r := s * .14
					var pts := []
					for k in 18:
						var f := k / 17.0
						pts.append(c + Vector2(-s * .4 + f * s * .64, sin(f * 5.0 + t * 3.0) * s * .12 * (1.0 - f)))
					CosmeticArt.draw_trail(canvas, it, pts, r, t)
					CritterArt.draw_critter(canvas, critter, pts[-1], r, {"t": t, "look": Vector2.RIGHT})
				"spark":
					CosmeticArt.draw_spark(canvas, it, c, .3, s / 140.0, 1.0)
				"ko":
					CosmeticArt.draw_ko(canvas, it, c, s * .16, .35, 2.0)
	)
	canvas.queue_redraw()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(a.out)
	print("saved ", a.out)
	quit()
