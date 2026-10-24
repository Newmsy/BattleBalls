## Living paintings (game/bounce_run/living_art.gd): every moving layer the
## renderer wrote is there, fits its painting and moves sensibly, so a
## painting never shows its background plate with a critter missing.
extends "res://tests/test_case.gd"

const LivingArt := preload("res://game/bounce_run/living_art.gd")
const Layers := preload("res://game/bounce_run/living_layers.gd")
const DIRS := ["res://game/bounce_run/art/%s.png", "res://game/ui/home_art/%s.png", "res://game/ui/versus_art/%s.png"]


func _path(id: String) -> String:
	for d in DIRS:
		if ResourceLoader.exists(d % id):
			return d % id
	return ""


func test_every_layer_is_there_and_fits_its_painting() -> void:
	check(not Layers.LAYERS.is_empty(), "some paintings have living layers")
	for id in Layers.LAYERS:
		var path := _path(id)
		check(path != "", "%s: painting not found" % id)
		if path == "":
			continue
		var size: Vector2 = load(path).get_size()
		var lays: Array = Layers.LAYERS[id]
		check(lays.size() <= 4, "%s: at most 4 layers (the shader's limit)" % id)
		for i in lays.size():
			var l: Array = lays[i]
			var base: String = path.get_basename() + l[0]
			check(ResourceLoader.exists(base + ".png"), "%s: missing %s.png" % [id, base])
			if l[4]:
				check(ResourceLoader.exists(base + "_blink.png"), "%s: missing %s_blink.png" % [id, base])
			var r: Rect2 = l[1]
			check(Rect2(Vector2.ZERO, size).encloses(r), "%s%s: rect %s outside the painting" % [id, l[0], r])
			var move: Vector4 = l[2]
			check(move.x >= 0 and move.x <= 4, "%s%s: unknown move kind" % [id, l[0]])
			check(move.z > 0.0 and move.z <= 4.0, "%s%s: speed %s Hz" % [id, l[0], move.z])
			check(l[5] < lays.size() and l[5] != i, "%s%s: rides along with a missing layer" % [id, l[0]])


func test_living_paintings_get_their_layers() -> void:
	for id in Layers.LAYERS:
		var m := LivingArt.material_for(id, _path(id))
		check(m != null, "%s: no living material" % id)
		if m == null:
			continue
		check_eq(m.get_shader_parameter("layers"), mini(Layers.LAYERS[id].size(), 4), "%s layers" % id)
		LivingArt.animate(m, 1.7)
		check(m.get_shader_parameter("lay0") != null, "%s: first layer texture set" % id)


func test_glow_spots_only_light_up() -> void:
	# Moving parts are layers now: a spot that warped the picture would smear it again.
	for id in LivingArt.SPECS:
		for s in LivingArt.SPECS[id].get("spots", []):
			check(s[4] == LivingArt.GLOW or s[4] == LivingArt.FLICKER, "%s: spot kind %s" % [id, s[4]])
		check(LivingArt.SPECS[id].get("spots", []).size() <= 4, "%s: at most 4 spots" % id)
