## A small still of one cosmetic for shop tiles and pass rewards: a hat on
## your critter, or a trail, spark or KO frozen mid-play.
extends Control

const CritterArt := preload("res://game/ui/critter_art.gd")
const CosmeticArt := preload("res://game/glow/cosmetic_art.gd")
const Catalog := preload("res://game/glow/catalog.gd")

var item_id := ""
var critter_id := "vampire"
var _t := 0.0


static func make(id: String, critter: String, side: float) -> Control:
	var c = load("res://game/glow/cosmetic_icon.gd").new()
	c.item_id = id
	c.critter_id = critter
	c.custom_minimum_size = Vector2(side, side)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_t += delta
		queue_redraw()


func _draw() -> void:
	var it := Catalog.item(item_id)
	if it.is_empty():
		return
	var s := minf(size.x, size.y)
	var c := Vector2(size.x / 2.0, size.y / 2.0)
	match it.slot:
		"hat":
			var r := s * .26
			var at := c + Vector2(0, s * .14)
			CritterArt.draw_critter(self, critter_id, at, r, {"t": _t, "look": Vector2(.3, .2)})
			CosmeticArt.draw_hat(self, it, at, r, _t)
		"trail":
			var r := s * .17
			var pts := []
			for i in 16:
				var f := i / 15.0
				pts.append(c + Vector2(-s * .38 + f * s * .62, sin(f * 5.0 + _t * 3.0) * s * .12 * (1.0 - f)))
			CosmeticArt.draw_trail(self, it, pts, r, _t)
			CritterArt.draw_critter(self, critter_id, pts[-1], r, {"t": _t, "look": Vector2.RIGHT})
		"spark":
			CosmeticArt.draw_spark(self, it, c, .1 + fmod(_t * .8, 1.0) * .6, s / 140.0, 1.0)
		"ko":
			CosmeticArt.draw_ko(self, it, c, s * .16, .12 + fmod(_t * .5, 1.0) * .7, 2.0)
