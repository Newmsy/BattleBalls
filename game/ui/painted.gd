## A painting (game/ui/art) shown in a rounded frame: the Den band over My
## critters, a family's home on each critter card and behind the critter page
## hero. It draws once (again only on resize): static art, free on battery.
## `focus` is a point in the painting that lands at `at` (a fraction of the
## frame) and `px` caps how many painting pixels one frame pixel shows (so a
## critter painted at a size matches the icon on it); by default the painting
## just covers the frame. The crop never leaves the painting.
extends Control

const SHADER := preload("res://game/ui/painted.gdshader")
const Families := preload("res://sim/families.gd")
const ART := "res://game/ui/art/%s.png"

var texture: Texture2D
var focus := Vector2(-1, -1)
var at := Vector2(0.5, 0.5)
var px := 0.0
var _mat: ShaderMaterial


static func make(art: String, opts := {}) -> Control:
	var p := new()
	p.texture = load(ART % art)
	p.focus = opts.get("focus", Vector2(p.texture.get_width(), p.texture.get_height()) / 2.0)
	p.at = opts.get("at", Vector2(0.5, 0.5))
	p.px = opts.get("px", 0.0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p._mat = ShaderMaterial.new()
	p._mat.shader = SHADER
	var r = opts.get("radius", 0.0)
	p._mat.set_shader_parameter("radius", r if r is Vector4 else Vector4(r, r, r, r))
	for k in ["top_dark", "right_dark", "bottom_dark", "bottom_fade"]:
		p._mat.set_shader_parameter(k, opts.get(k, 0.0))
	p.material = p._mat
	p.resized.connect(p._on_resized)
	return p


## The painting of a critter's family home (game/ui/art/families/<family>.png),
## or "" for a critter outside every family.
static func habitat(critter_id: String) -> String:
	var fam := Families.of(critter_id)
	return "" if fam == "" or not ResourceLoader.exists(ART % ("families/" + fam)) else "families/" + fam


func _on_resized() -> void:
	_mat.set_shader_parameter("size", size)
	queue_redraw()


func _draw() -> void:
	if texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var tex := Vector2(texture.get_width(), texture.get_height())
	var per := _per(tex)
	var src := size * per
	var origin := (focus - at * src).clamp(Vector2.ZERO, tex - src)
	draw_texture_rect_region(texture, Rect2(Vector2.ZERO, size), Rect2(origin, src))


## Painting pixels per frame pixel: just covering the frame, or closer in with `px`.
func _per(tex: Vector2) -> float:
	var cover := minf(tex.x / size.x, tex.y / size.y)
	return minf(cover, px) if px > 0.0 else cover
