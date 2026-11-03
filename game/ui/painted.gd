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
## The PNGs are rendered at this many pixels per painting unit
## (tools/critters_art/render.mjs); `focus` and `px` are in painting units.
const ART_SCALE := 2.0

var texture: Texture2D
var focus := Vector2(-1, -1)
var at := Vector2(0.5, 0.5)
var px := 0.0
var _mat: ShaderMaterial


static func make(art: String, opts := {}) -> Control:
	var p := new()
	p.texture = load(ART % art)
	p.focus = opts["focus"] * ART_SCALE if opts.has("focus") else Vector2(p.texture.get_size()) / 2.0
	p.at = opts.get("at", Vector2(0.5, 0.5))
	p.px = opts.get("px", 0.0) * ART_SCALE
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p._mat = ShaderMaterial.new()
	p._mat.shader = SHADER
	var r = opts.get("radius", 0.0)
	p._mat.set_shader_parameter("radius", r if r is Vector4 else Vector4(r, r, r, r))
	for k in ["top_dark", "left_dark", "right_dark", "bottom_dark", "bottom_fade"]:
		p._mat.set_shader_parameter(k, opts.get(k, 0.0))
	p.material = p._mat
	p.resized.connect(p._on_resized)
	return p


## The painting of a critter's family home (game/ui/art/families/<family>.png),
## or "" for a critter outside every family.
static func habitat(critter_id: String) -> String:
	var fam := Families.of(critter_id)
	return "" if fam == "" or not ResourceLoader.exists(ART % ("families/" + fam)) else "families/" + fam


## A framed stage of `critter_id`'s family home with `content` on top (a
## critter on the lit left, words on the darker right), as on the critter
## page. Outside a family it's a plain panel. `opts` overrides the painting's
## crop (focus, at, right_dark, ...); "pad" sets the inner margins.
static func stage(critter_id: String, content: Control, opts := {}) -> PanelContainer:
	const Kit := preload("res://game/ui/ui_kit.gd")
	var st := PanelContainer.new()
	st.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var home := habitat(critter_id)
	if home != "":
		var o := {"focus": Vector2(200, 250), "at": Vector2(0.2, 0.5), "radius": 30.0, "right_dark": 0.8, "top_dark": 0.4}
		o.merge(opts, true)
		st.add_child(make(home, o))
	else:
		var bg := Panel.new()
		bg.add_theme_stylebox_override("panel", Kit.box(Kit.PANEL, Color(0, 0, 0, 0), 30, 0, 0))
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		st.add_child(bg)
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0), Color("3a3480"), 30, 3, 0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(frame)
	var m := MarginContainer.new()
	var pad: Vector2 = opts.get("pad", Vector2(22, 16))
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, int(pad.x if side in ["left", "right"] else pad.y))
	m.add_child(content)
	st.add_child(m)
	return st


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
