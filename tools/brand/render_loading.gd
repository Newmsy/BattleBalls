## Renders the bright loading screen (game/ui/splash_art.gd) to
## game/brand/loading.png: the image the web page shows while the game
## downloads and the native boot splash. Needs a real renderer, not --headless:
##   xvfb-run -s "-screen 0 1280x1800x24" godot --rendering-driver opengl3 \
##     --resolution 720x1560 --script res://tools/brand/render_loading.gd
## Optional: -- out=<path> w=<px> h=<px> t=<seconds into the loop> look=<meadow|sunset|sky>
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
	art.look = args.get("look", "meadow")
	art._t = float(args.get("t", "0.6"))
	vp.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var out: String = args.get("out", "res://game/brand/loading.png")
	img.save_png(ProjectSettings.globalize_path(out) if out.begins_with("res://") else out)
	print("wrote ", out, " ", img.get_size())
	quit()
