## Shows one living painting at 2x so its idle can be recorded:
## xvfb-run godot --rendering-driver opengl3 --path . -s tools/event_art/preview.gd --write-movie out.png --fixed-fps 15 --quit-after 90 -- wandering_rival
extends SceneTree

const LivingArt := preload("res://game/bounce_run/living_art.gd")


func _initialize() -> void:
	var id: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "wandering_rival"
	var path := "res://game/bounce_run/art/%s.png" % id
	if not ResourceLoader.exists(path):
		path = "res://game/ui/home_art/%s.png" % id
	root.size = Vector2i(720, 440)
	var art := LivingArt.make(id, path)
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(art)
