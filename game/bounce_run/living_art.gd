## A painting that idles: its critters hop, breathe and blink, scarves and
## lanterns sway, lamps flicker, gems glow and a few motes drift up. Render
## only. It redraws on the shared idle clock (CritterIcon), only while on
## screen, and holds still with Reduced motion.
##
## How the moving parts stay clean: the scene marks each one as a layer
## (tools/event_art/render.mjs, data-layer), which renders the picture's PNG
## without them plus a cut-out PNG per part. living_art.gdshader draws the
## parts back over that background plate, each moved whole, so nothing in the
## flat picture is ever warped. Any painted screen can use it: LivingArt.make()
## for a plain picture, or material_for() + animate() on your own Control
## (HomePainting does this to crop and round its corners).
extends TextureRect

const CritterIcon := preload("res://game/ui/critter_icon.gd")
const A11y := preload("res://game/a11y.gd")
const SHADER := preload("res://game/bounce_run/living_art.gdshader")
const Layers := preload("res://game/bounce_run/living_layers.gd")
const W := 720.0
const H := 440.0
const GLOW := 3.0
const FLICKER := 4.0

## Per painting: spots that light up [x, y, radius x, radius y (art pixels),
## GLOW or FLICKER, amount, speed (Hz), phase, glow colour] (at most 4), the
## motes' colour and, for a painting that isn't 720x440, its "size". Moving
## parts are layers in the scene, not spots here.
const SPECS := {
	"lost_egg": {"motes": Color("7dffb0"), "spots": [
		[328, 232, 55, 26, GLOW, 0.5, 0.8, 0.0, Color("5cff9a")]]},
	"candy_fountain": {"motes": Color("ff8fd8"), "spots": [
		[360, 160, 160, 70, GLOW, 0.25, 0.5, 0.0, Color("ff6fc8")]]},
	"training_dummy": {"motes": Color("ffd34e"), "spots": [
		[640, 215, 60, 60, GLOW, 0.35, 0.4, 0.0, Color("ffcf70")],
		[360, 40, 360, 30, FLICKER, 0.5, 0.6, 0.0, Color("ffffff")]]},
	"tide_pool_trader": {"motes": Color("7fe8ff"), "spots": [
		[360, 370, 270, 45, GLOW, 0.35, 0.35, 0.0, Color("3ee6ff")]]},
	"frozen_vault": {"motes": Color("e8f4ff"), "spots": [
		[360, 215, 80, 80, GLOW, 0.45, 0.45, 0.0, Color("c9a8ff")]]},
	"star_map": {"motes": Color("d6c4ff"), "spots": [
		[625, 105, 70, 70, GLOW, 0.5, 0.5, 0.0, Color("fff2b0")],
		[330, 190, 210, 110, FLICKER, 0.3, 0.7, 0.0, Color("b88cff")]]},
	"vending_machine": {"motes": Color("ff4fb8"), "spots": [
		[100, 95, 60, 40, FLICKER, 0.6, 1.3, 0.0, Color("3ee6ff")],
		[515, 285, 45, 40, FLICKER, 0.7, 1.7, 0.0, Color("ffd34e")]]},
	"haunted_mirror": {"motes": Color("b88cff"), "spots": [
		[215, 225, 32, 38, FLICKER, 0.6, 0.9, 0.0, Color("ffcf70")],
		[588, 240, 60, 75, FLICKER, 0.6, 0.8, 0.4, Color("ffcf70")]]},
	"lava_bridge": {"motes": Color("ff9f43"), "spots": [
		[470, 340, 310, 95, FLICKER, 0.35, 0.5, 0.0, Color("ff7a2e")]]},
	"wandering_rival": {"motes": Color("ff5a6e"), "spots": [
		[360, 355, 200, 48, GLOW, 0.4, 0.6, 0.0, Color("ff4fb8")]]},
	"sunken_wreck": {"motes": Color("bfefff"), "spots": [
		[290, 300, 95, 60, GLOW, 0.45, 0.6, 0.0, Color("ffd23f")]]},
	"beehive": {"motes": Color("d8ff7a"), "spots": [
		[360, 384, 160, 34, GLOW, 0.4, 0.5, 0.0, Color("ffc93c")]]},
	"fallen_star": {"motes": Color("fff3b0"), "spots": [
		[384, 270, 110, 95, FLICKER, 0.45, 1.2, 0.0, Color("ffd23f")],
		[384, 330, 150, 40, GLOW, 0.4, 0.5, 0.3, Color("ffd77a")], [330, 90, 280, 80, FLICKER, 0.3, 0.7, 0.0, Color("ffffff")]]},
	"ember_forge": {"motes": Color("ff9f43"), "spots": [
		[170, 225, 90, 60, FLICKER, 0.5, 0.9, 0.0, Color("ff8a3a")], [354, 240, 60, 60, GLOW, 0.45, 0.5, 0.0, Color("ffd36a")],
		[350, 292, 95, 22, GLOW, 0.35, 0.35, 0.3, Color("ff6a2e")]]},
	"snow_globe": {"motes": Color("e8f4ff"), "spots": [
		[360, 196, 115, 115, GLOW, 0.3, 0.4, 0.0, Color("8fe6ff")],
		[360, 100, 360, 70, FLICKER, 0.35, 0.3, 0.0, Color("5fffb8")], [610, 72, 40, 40, GLOW, 0.35, 0.3, 0.5, Color("e6f4ff")]]},
	"gumball_machine": {"motes": Color("ffd6f0"), "spots": [
		[360, 178, 110, 105, GLOW, 0.35, 0.5, 0.0, Color("ff7ac8")],
		[546, 402, 20, 14, GLOW, 0.4, 0.8, 0.2, Color("ffd23f")]]},
	"jack_in_the_box": {"motes": Color("ffe9a8"), "spots": [
		[382, 222, 60, 22, GLOW, 0.5, 0.6, 0.0, Color("ffc93c")]]},
	"ghost_lantern": {"motes": Color("b88cff"), "spots": [
		[364, 152, 40, 46, FLICKER, 0.5, 1.1, 0.0, Color("8fffe6")],
		[364, 170, 170, 120, GLOW, 0.3, 0.4, 0.3, Color("b07cff")]]},
	"glitch_rift": {"motes": Color("3ee6ff"), "spots": [
		[362, 240, 90, 90, GLOW, 0.45, 0.5, 0.0, Color("ffd23f")],
		[378, 258, 260, 85, FLICKER, 0.5, 1.4, 0.0, Color("ff4fb8")]]},
	"scrap_robot": {"motes": Color("3ee6ff"), "spots": [
		[410, 210, 34, 30, FLICKER, 0.6, 1.2, 0.0, Color("3ee6ff")]]},
	"shop": {"motes": Color("ffd34e"), "spots": [
		[360, 40, 360, 30, FLICKER, 0.5, 0.6, 0.0, Color("ffffff")],
		[200, 185, 140, 60, GLOW, 0.35, 0.5, 0.0, Color("b88cff")], [540, 245, 55, 60, GLOW, 0.3, 0.4, 0.5, Color("ffd34e")]]},
	"charge_pad": {"motes": Color("5cff9a"), "spots": [
		[365, 345, 160, 42, GLOW, 0.45, 0.6, 0.0, Color("5cff9a")],
		[365, 100, 225, 95, FLICKER, 0.3, 0.6, 0.0, Color("ffe2a0")]]},
	"glow_chest": {"motes": Color("ffe08a"), "spots": [
		[370, 175, 160, 150, GLOW, 0.4, 0.5, 0.0, Color("ffd34e")]]},
	"banner_draft": {"motes": Color("ffd34e"), "spots": [
		[360, 120, 210, 120, FLICKER, 0.25, 0.5, 0.0, Color("8fe8ff")]]},
	"banner_boon": {"motes": Color("8fe8ff"), "spots": [
		[370, 150, 230, 150, GLOW, 0.3, 0.45, 0.0, Color("6fe8ff")]]},
	"banner_tier_up": {"motes": Color("ffd34e"), "spots": [
		[360, 100, 180, 60, FLICKER, 0.45, 0.6, 0.0, Color("ffd34e")],
		[360, 330, 150, 38, GLOW, 0.45, 0.7, 0.0, Color("8fe8ff")]]},
	"banner_victory": {"motes": Color("ffd34e"), "spots": [
		[360, 140, 75, 75, GLOW, 0.4, 0.5, 0.0, Color("ffd34e")], [130, 90, 75, 75, FLICKER, 0.6, 0.7, 0.0, Color("ff6fc8")],
		[600, 80, 75, 75, FLICKER, 0.6, 0.6, 0.5, Color("6fe8ff")]]},
	"banner_defeat": {"motes": Color("ff9f43"), "spots": [
		[350, 320, 60, 65, FLICKER, 0.55, 0.9, 0.0, Color("ff9f43")], [566, 90, 28, 32, FLICKER, 0.6, 0.5, 0.0, Color("fff2b0")]]},
	# Home's Adventure door paintings (game/ui/home_art, HomePainting): the gate glows.
	"home_zone_glow_garden": {"motes": Color("7dffb0"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("7dffb0")]]},
	"home_zone_circuit_lab": {"motes": Color("39d7ff"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("39d7ff")]]},
	"home_zone_frostbite_caves": {"motes": Color("bfefff"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("bfefff")]]},
	"home_zone_bramble_hollow": {"motes": Color("d8ff7a"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("d8ff7a")]]},
	"home_zone_haunted_arcade": {"motes": Color("ff9ae6"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("ff9ae6")]]},
	"home_zone_starfall_rim": {"motes": Color("ffd23d"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("ffd23d")]]},
	"home_zone_magma_core": {"motes": Color("ff8a3d"), "spots": [
		[604, 186, 70, 80, GLOW, 0.35, 0.4, 0.0, Color("ff8a3d")]]},
	# The Fusion Lab (game/ui/fuse_art): reactor swirl, bubbling tubes, pads.
	"fuse_chamber": {"size": Vector2(720, 680), "motes": Color("b98cff"), "spots": [
		[360, 316, 130, 130, GLOW, 0.35, 0.4, 0.0, Color("b98cff")], [74, 330, 40, 170, FLICKER, 0.4, 0.7, 0.0, Color("5ce1ff")],
		[646, 330, 40, 170, FLICKER, 0.4, 0.6, 0.5, Color("ff7ad9")], [360, 560, 300, 80, GLOW, 0.35, 0.5, 0.2, Color("5ce1ff")]]},
	"fuse_band": {"size": Vector2(720, 220), "motes": Color("5ce1ff"), "spots": [
		[493, 110, 100, 100, GLOW, 0.35, 0.4, 0.0, Color("b98cff")], [672, 135, 30, 100, FLICKER, 0.4, 0.6, 0.0, Color("ff7ad9")],
		[318, 143, 24, 90, FLICKER, 0.4, 0.7, 0.5, Color("5ce1ff")]]},
	# The Summon tab's Portal Hall (summon_screen.gd _Hall): lanterns and the ring's gems.
	"portal_hall": {"size": Vector2(720, 760), "motes": Color("cbb8ff"), "spots": [
		[150, 180, 34, 40, FLICKER, 0.5, 0.8, 0.0, Color("ffcf7a")], [570, 180, 34, 40, FLICKER, 0.5, 0.7, 0.5, Color("ffcf7a")],
		[360, 300, 180, 180, GLOW, 0.25, 0.35, 0.0, Color("b98cff")]]},
}
const MOTES := 9

var art_id := ""
var art_size := Vector2(W, H)
var _t := 0.0
var _tick := -1
var _mat: ShaderMaterial
var _motes: Control


static func make(id: String, path: String) -> TextureRect:
	var a := new()
	a.art_id = id
	a.texture = load(path)
	a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.clip_contents = true
	a.art_size = SPECS.get(id, {}).get("size", Vector2(W, H))
	a._mat = material_for(id, path)
	if a._mat != null:
		a.material = a._mat
		a._motes = _Motes.new()
		a._motes.art = a
		a._motes.set_anchors_preset(Control.PRESET_FULL_RECT)
		a._motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a.add_child(a._motes)
	return a


## The living shader set up with a painting's glow spots and moving layers
## (`path` is the painting's PNG; its layers sit beside it), or null when it
## has neither. Drive it with animate().
static func material_for(id: String, path: String) -> ShaderMaterial:
	var spec: Dictionary = SPECS.get(id, {})
	var lays: Array = Layers.LAYERS.get(id, [])
	if spec.is_empty() and lays.is_empty():
		return null
	var m := ShaderMaterial.new()
	m.shader = SHADER
	var rects: Array[Vector4] = []
	var moves: Array[Vector4] = []
	var cols: Array[Vector4] = []
	var sz: Vector2 = spec.get("size", Vector2(W, H))
	for s in spec.get("spots", []):
		rects.append(Vector4(s[0] / sz.x, s[1] / sz.y, s[2] / sz.x, s[3] / sz.y))
		moves.append(Vector4(s[4], s[5], s[6], s[7]))
		var c: Color = s[8] if s[8] != null else Color.BLACK
		cols.append(Vector4(c.r, c.g, c.b, 1.0))
	m.set_shader_parameter("count", rects.size())
	m.set_shader_parameter("spot_rect", rects)
	m.set_shader_parameter("spot_move", moves)
	m.set_shader_parameter("glow_col", cols)
	m.set_shader_parameter("sweep", 1.0)
	var tex: Texture2D = load(path)
	m.set_shader_parameter("art_px", tex.get_size() if tex != null else Vector2(W, H))
	var lrects: Array[Vector4] = []
	var lmoves: Array[Vector4] = []
	var pivots: Array[Vector2] = []
	var parents: Array[int] = []
	var blinks := []
	for i in mini(lays.size(), 4):
		var l: Array = lays[i]
		var base: String = path.get_basename() + l[0]
		var open: Texture2D = load(base + ".png")
		m.set_shader_parameter("lay%d" % i, open)
		var r: Rect2 = l[1]
		lrects.append(Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
		lmoves.append(l[2])
		pivots.append(l[3])
		parents.append(l[5])
		if l[4]:
			var h := hash([id, i])
			# [layer, open, shut, seconds between blinks, offset]
			blinks.append([i, open, load(base + "_blink.png"), 3.2 + (h & 255) / 255.0 * 2.4, ((h >> 8) & 255) / 255.0 * 3.0])
	m.set_shader_parameter("layers", lrects.size())
	m.set_shader_parameter("lay_rect", lrects)
	m.set_shader_parameter("lay_move", lmoves)
	m.set_shader_parameter("lay_pivot", pivots)
	m.set_shader_parameter("lay_parent", parents)
	m.set_meta("blinks", blinks)
	return m


## Moves a material_for() painting to time `t` (seconds): call it on the
## shared idle clock, then redraw. Critters with eyes blink now and then.
static func animate(m: ShaderMaterial, t: float) -> void:
	m.set_shader_parameter("t", t)
	for b in m.get_meta("blinks", []):
		var shut := fmod(t + b[4], b[3]) < 0.14
		m.set_shader_parameter("lay%d" % b[0], b[2] if shut else b[1])


func _process(delta: float) -> void:
	if _mat == null or A11y.reduced_motion or not is_visible_in_tree():
		return
	_t += delta
	var tick := CritterIcon.clock()
	if tick != _tick:
		_tick = tick
		animate(_mat, _t)
		queue_redraw()
		_motes.queue_redraw()


## Motes drift up over the picture and fade, each on its own seeded lane
## (a child, so the painting's shader doesn't touch them).
class _Motes extends Control:
	var art: TextureRect

	func _draw() -> void:
		var spec: Dictionary = SPECS.get(art.art_id, {})
		if spec.is_empty() or A11y.reduced_motion:
			return
		var t: float = art._t
		var wh: Vector2 = art.art_size
		var s := maxf(size.x / wh.x, size.y / wh.y) if art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED else minf(size.x / wh.x, size.y / wh.y)
		var origin := (size - wh * s) / 2.0
		for i in MOTES:
			var h := hash([art.art_id, i])
			var f := fmod(t * (0.06 + (h & 63) / 63.0 * 0.06) + ((h >> 6) & 255) / 255.0, 1.0)
			var p := origin + Vector2(((h >> 14) & 1023) / 1023.0 * wh.x + sin(t * 0.8 + i) * 10.0, wh.y * (1.0 - f)) * s
			var a := sin(f * PI) * 0.7
			var col: Color = spec.motes
			draw_circle(p, 4.5 * s, Color(col, a * 0.25))
			draw_circle(p, 2.0 * s, Color(col, a))
