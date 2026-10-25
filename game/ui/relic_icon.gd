## A Bounce Run relic's badge (sim/relics.gd): its painted keepsake
## (tools/event_art/scenes/relics.mjs) on a disc in its critter's family
## colour, with that critter's face in the corner so you can tell whose
## ability it is. The keepsake is a static texture and the face a still
## CritterIcon, so neither costs anything per frame. Render-only.
extends Control

const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Families := preload("res://sim/families.gd")
const ART := "res://game/bounce_run/art/relics/relic_%s.png"

var relic := "fin"
var _tex: Texture2D


## The badge, `side` px square. `face` false leaves the corner face out
## (tiny strips where it would be a smudge).
static func make(id: String, side: float, face := true) -> Control:
	var g = load("res://game/ui/relic_icon.gd").new()
	g.relic = id
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.custom_minimum_size = Vector2(side, side)
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if face:
		var f := CritterIcon.face(id, side * 0.44)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		f.position = Vector2(side * 0.6, side * 0.6)
		f.size = Vector2(side * 0.44, side * 0.44)
		g.add_child(f)
	return g


## Its family's colour, for rims and names.
static func color_of(id: String) -> Color:
	return Color(str(Families.info(Families.of(id)).get("color", "ffc23d")))


func _ready() -> void:
	if ResourceLoader.exists(ART % relic):
		_tex = load(ART % relic)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := Vector2(s, s) / 2.0
	var col := color_of(relic)
	draw_circle(c, s * .48, col.darkened(.7))
	draw_arc(c, s * .45, 0, TAU, 32, col, maxf(2.0, s * .05), true)
	if _tex != null:
		draw_texture_rect(_tex, Rect2(Vector2(s * .02, s * .0), Vector2(s * .96, s * .96)), false)
