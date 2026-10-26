## Bakes game/dot_atlas.png, the one texture every Dot shape draws from
## (see game/dot.gd). Run after changing a generator in Dot.bake:
##   godot --headless --script res://tools/dot_atlas.gd
extends SceneTree

const Dot := preload("res://game/dot.gd")


func _init() -> void:
	var img := Dot.make_atlas()
	var err := img.save_png(ProjectSettings.globalize_path(Dot.ATLAS_PATH))
	print("dot atlas %dx%d -> %s (%s)" % [img.get_width(), img.get_height(), Dot.ATLAS_PATH, error_string(err)])
	quit()
