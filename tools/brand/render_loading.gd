## Renders the loading screen (game/ui/splash_art.gd) to a PNG. Since
## 2026-10-23 game/brand/loading.png is Newms's painted key art (darkened a
## touch), so this only writes previews and clips unless you pick a
## code-drawn look to replace it. Needs a real renderer, not --headless:
##   xvfb-run -s "-screen 0 1280x1800x24" godot --rendering-driver opengl3 \
##     --resolution 720x1560 --script res://tools/brand/render_loading.gd
## Optional: -- out=<path> w=<px> h=<px> t=<seconds into the loop> look=<art|sunset|meadow|sky>
## frames=<n> also writes n frames at 30 fps to <out>_000.png... (for a preview clip).
extends SceneTree

const SplashArt := preload("res://game/ui/splash_art.gd")


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var w := int(args.get("w", "720"))
	var h := int(args.get("h", "1560"))
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var art = SplashArt.new()
	art.set_process(false)
	art.look = args.get("look", art.look)
	art._t = float(args.get("t", "1.3"))
	vp.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if art.look == "art" and not args.has("out"):
		push_error("loading.png is the painted art itself: pass out=<path> for a preview")
		quit(1)
		return
	var out: String = args.get("out", "res://game/brand/loading.png")
	for i in int(args.get("frames", "0")):
		art._t += 1.0 / 30.0
		art._live.queue_redraw()
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(out.get_basename() + "_%03d.png" % i)
	var img := vp.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	print("wrote ", out, " ", img.get_size())
	quit()
