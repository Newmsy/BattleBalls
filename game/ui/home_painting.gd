## A painting that fills a Home door (or the top band of one, or a Versus card), cropped to fill
## its box around a focus point, with rounded corners and darkened edges under
## the door's words (living_art.gdshader). Paintings with LivingArt glow spots
## or moving layers idle like the Bounce Run events: they redraw on the shared idle clock, only
## while on screen, and hold still with Reduced motion. Render only.
extends Control

const LivingArt := preload("res://game/bounce_run/living_art.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const A11y := preload("res://game/a11y.gd")
const DIR := "res://game/ui/home_art/%s.png"

var tex: Texture2D
## Which part of the painting stays in view when it's cropped (0-1 each way).
var focus := Vector2(0.5, 0.5)
var _mat: ShaderMaterial
var _living := false
var _t := 0.0
var _tick := -1


## `fade` is [top fade end, its strength, bottom fade start, its strength]
## (fractions of the height), towards `fade_col`. `dir` is where the painting
## lives (the Versus hub's are in game/ui/versus_art).
static func make(id: String, focus_at: Vector2, corner: float, fade: Vector4, fade_col: Color, dir := DIR) -> Control:
	var p := new()
	p.tex = load(dir % id)
	p.focus = focus_at
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p._mat = LivingArt.material_for(id, dir % id)
	p._living = p._mat != null
	if p._mat == null:
		p._mat = ShaderMaterial.new()
		p._mat.shader = LivingArt.SHADER
	p._mat.set_shader_parameter("corner", corner)
	p._mat.set_shader_parameter("fade", fade)
	p._mat.set_shader_parameter("fade_col", Vector3(fade_col.r, fade_col.g, fade_col.b))
	p.material = p._mat
	p.resized.connect(func(): p._mat.set_shader_parameter("px_size", p.size))
	return p


func _draw() -> void:
	if tex == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var t := tex.get_size()
	var s := maxf(size.x / t.x, size.y / t.y)
	var r := size / s
	draw_texture_rect_region(tex, Rect2(Vector2.ZERO, size), Rect2((t - r) * focus, r))


func _process(delta: float) -> void:
	if not _living or A11y.reduced_motion or not is_visible_in_tree():
		return
	_t += delta
	var tick := CritterIcon.clock()
	if tick != _tick:
		_tick = tick
		LivingArt.animate(_mat, _t)
		queue_redraw()
