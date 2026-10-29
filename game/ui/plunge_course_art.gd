## A Critter Plunge course's painting for the Plunge screen's hero: the
## course's arena art and backdrop (game/arena_art.gd, game/plunge_backdrops.gd)
## painted once into a small SubViewport, kept as a texture for the course
## last shown, then drawn like a Home door painting (game/ui/home_painting.gd:
## cropped to fill, rounded corners, faded edges). Render only.
extends "res://game/ui/home_painting.gd"

const ArenaArt := preload("res://game/arena_art.gd")
const Backdrops := preload("res://game/plunge_backdrops.gd")
const PlungeCourse := preload("res://sim/plunge_course.gd")
const MatchSim := preload("res://sim/match_sim.gd")

const BAKE := 640 ## Pixels across the painted square.

## The last course painted: {id, tex}, so a screen refresh doesn't paint it again.
static var _cache := {}

var course_id := ""
var _vp: SubViewport
var _frames := 0


static func make_course(id: String, focus_at: Vector2, corner: float, fade: Vector4, fade_col: Color) -> Control:
	var p := new()
	p.course_id = id
	p.focus = focus_at
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p._mat = ShaderMaterial.new()
	p._mat.shader = LivingArt.SHADER
	p._mat.set_shader_parameter("corner", corner)
	p._mat.set_shader_parameter("fade", fade)
	p._mat.set_shader_parameter("fade_col", Vector3(fade_col.r, fade_col.g, fade_col.b))
	p.material = p._mat
	p.resized.connect(func(): p._mat.set_shader_parameter("px_size", p.size))
	if _cache.get("id", "") == id:
		p.tex = _cache.tex
	return p


func _ready() -> void:
	if tex != null or DisplayServer.get_name() == "headless":
		return
	_vp = SubViewport.new()
	_vp.size = Vector2i(BAKE, BAKE)
	_vp.disable_3d = true
	_vp.gui_disable_input = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var painter := _Painter.new()
	painter.course_id = course_id
	_vp.add_child(painter)
	add_child(_vp)
	tex = _vp.get_texture()
	queue_redraw()
	RenderingServer.frame_post_draw.connect(_keep)


## A couple of frames after the bake, copy it out and free the viewport.
func _keep() -> void:
	_frames += 1
	if _frames < 2:
		return
	RenderingServer.frame_post_draw.disconnect(_keep)
	var img := _vp.get_texture().get_image()
	if img != null and not img.is_empty():
		tex = ImageTexture.create_from_image(img)
		_cache = {"id": course_id, "tex": tex}
		_vp.queue_free()
		_vp = null
	queue_redraw()


func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_keep):
		RenderingServer.frame_post_draw.disconnect(_keep)


class _Painter extends Node2D:
	var course_id := ""

	func _draw() -> void:
		var course := PlungeCourse.find(course_id)
		var ctx := ArenaArt.make_ctx(course.art, BAKE / MatchSim.ARENA_SIZE, 0.0)
		# The floor only, as the race paints it: no walls or pieces on it.
		ctx.outline = PackedVector2Array([ctx.full.position, Vector2(ctx.full.end.x, ctx.full.position.y), ctx.full.end, Vector2(ctx.full.position.x, ctx.full.end.y)])
		ctx.centre = ctx.full.get_center()
		ctx.obstacles = []
		ctx.floors = []
		ArenaArt.paint(self, ctx, false)
		Backdrops.paint(self, ctx, course.id)
