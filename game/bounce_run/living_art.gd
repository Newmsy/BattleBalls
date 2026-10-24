## A Bounce Run painting that idles: its critters bob, lamps flicker, gems
## glow (living_art.gdshader warps soft spots of the picture) and a few motes
## drift up. Render only. It redraws on the shared idle clock (CritterIcon),
## only while on screen, and holds still with Reduced motion.
extends TextureRect

const CritterIcon := preload("res://game/ui/critter_icon.gd")
const A11y := preload("res://game/a11y.gd")
const SHADER := preload("res://game/bounce_run/living_art.gdshader")
const W := 720.0
const H := 440.0
const BOB := 1.0
const SWAY := 2.0
const GLOW := 3.0
const FLICKER := 4.0

## Per painting: spots [x, y, radius x, radius y (art pixels), kind, amount,
## speed (Hz), phase, glow colour] (at most 4) and the motes' colour.
const SPECS := {
	"lost_egg": {"motes": Color("7dffb0"), "spots": [
		[365, 225, 85, 100, BOB, 0.012, 0.6, 0.0, null], [328, 232, 55, 26, GLOW, 0.5, 0.8, 0.0, Color("5cff9a")]]},
	"candy_fountain": {"motes": Color("ff8fd8"), "spots": [
		[360, 95, 70, 85, BOB, 0.012, 0.9, 0.0, null], [520, 290, 45, 45, BOB, 0.016, 0.7, 0.3, null],
		[360, 160, 160, 70, GLOW, 0.25, 0.5, 0.0, Color("ff6fc8")]]},
	"training_dummy": {"motes": Color("ffd34e"), "spots": [
		[365, 215, 95, 150, SWAY, 0.025, 0.9, 0.0, null], [640, 215, 60, 60, GLOW, 0.35, 0.4, 0.0, Color("ffcf70")],
		[360, 40, 360, 30, FLICKER, 0.5, 0.6, 0.0, Color("ffffff")]]},
	"tide_pool_trader": {"motes": Color("7fe8ff"), "spots": [
		[178, 155, 70, 70, BOB, 0.013, 0.5, 0.0, null], [552, 145, 75, 75, BOB, 0.013, 0.5, 0.5, null],
		[360, 205, 80, 70, BOB, 0.008, 0.7, 0.2, null], [360, 370, 270, 45, GLOW, 0.35, 0.35, 0.0, Color("3ee6ff")]]},
	"frozen_vault": {"motes": Color("e8f4ff"), "spots": [
		[360, 215, 80, 80, GLOW, 0.45, 0.45, 0.0, Color("c9a8ff")], [150, 325, 50, 50, BOB, 0.012, 0.6, 0.0, null]]},
	"star_map": {"motes": Color("d6c4ff"), "spots": [
		[625, 105, 70, 70, GLOW, 0.5, 0.5, 0.0, Color("fff2b0")], [130, 370, 55, 55, BOB, 0.012, 0.5, 0.0, null],
		[330, 190, 210, 110, FLICKER, 0.3, 0.7, 0.0, Color("b88cff")]]},
	"vending_machine": {"motes": Color("ff4fb8"), "spots": [
		[250, 215, 160, 205, SWAY, 0.004, 3.1, 0.0, null], [100, 95, 60, 40, FLICKER, 0.6, 1.3, 0.0, Color("3ee6ff")],
		[515, 285, 45, 40, FLICKER, 0.7, 1.7, 0.0, Color("ffd34e")]]},
	"haunted_mirror": {"motes": Color("b88cff"), "spots": [
		[365, 205, 85, 100, BOB, 0.014, 0.45, 0.0, null], [215, 225, 32, 38, FLICKER, 0.6, 0.9, 0.0, Color("ffcf70")],
		[588, 240, 60, 75, FLICKER, 0.6, 0.8, 0.4, Color("ffcf70")], [150, 345, 60, 60, BOB, 0.006, 0.4, 0.5, null]]},
	"lava_bridge": {"motes": Color("ff9f43"), "spots": [
		[470, 340, 310, 95, FLICKER, 0.35, 0.5, 0.0, Color("ff7a2e")], [205, 318, 40, 40, BOB, 0.012, 0.9, 0.0, null]]},
	"wandering_rival": {"motes": Color("ff5a6e"), "spots": [
		[355, 215, 115, 115, BOB, 0.012, 0.7, 0.0, null], [360, 355, 200, 48, GLOW, 0.4, 0.6, 0.0, Color("ff4fb8")],
		[205, 372, 90, 45, SWAY, 0.02, 1.1, 0.0, null]]},
	"sunken_wreck": {"motes": Color("bfefff"), "spots": [
		[552, 262, 110, 90, BOB, 0.01, 0.45, 0.0, null], [290, 300, 95, 60, GLOW, 0.45, 0.6, 0.0, Color("ffd23f")],
		[472, 150, 30, 120, BOB, 0.016, 0.8, 0.3, null], [40, 330, 50, 110, SWAY, 0.02, 0.5, 0.0, null]]},
	"beehive": {"motes": Color("d8ff7a"), "spots": [
		[360, 150, 125, 110, SWAY, 0.006, 0.5, 0.0, null], [360, 384, 160, 34, GLOW, 0.4, 0.5, 0.0, Color("ffc93c")],
		[220, 160, 40, 40, BOB, 0.016, 1.4, 0.0, null], [512, 136, 38, 38, BOB, 0.016, 1.3, 0.5, null]]},
	"fallen_star": {"motes": Color("fff3b0"), "spots": [
		[384, 270, 110, 95, FLICKER, 0.45, 1.2, 0.0, Color("ffd23f")], [176, 310, 60, 60, BOB, 0.012, 0.6, 0.0, null],
		[384, 330, 150, 40, GLOW, 0.4, 0.5, 0.3, Color("ffd77a")], [330, 90, 280, 80, FLICKER, 0.3, 0.7, 0.0, Color("ffffff")]]},
	"ember_forge": {"motes": Color("ff9f43"), "spots": [
		[170, 225, 90, 60, FLICKER, 0.5, 0.9, 0.0, Color("ff8a3a")], [354, 240, 60, 60, GLOW, 0.45, 0.5, 0.0, Color("ffd36a")],
		[350, 292, 95, 22, GLOW, 0.35, 0.35, 0.3, Color("ff6a2e")], [528, 300, 70, 80, BOB, 0.01, 0.6, 0.0, null]]},
	"snow_globe": {"motes": Color("e8f4ff"), "spots": [
		[356, 238, 50, 45, BOB, 0.014, 0.6, 0.0, null], [360, 196, 115, 115, GLOW, 0.3, 0.4, 0.0, Color("8fe6ff")],
		[360, 100, 360, 70, FLICKER, 0.35, 0.3, 0.0, Color("5fffb8")], [610, 72, 40, 40, GLOW, 0.35, 0.3, 0.5, Color("e6f4ff")]]},
	"gumball_machine": {"motes": Color("ffd6f0"), "spots": [
		[360, 178, 110, 105, GLOW, 0.35, 0.5, 0.0, Color("ff7ac8")], [588, 335, 60, 62, BOB, 0.012, 0.7, 0.0, null],
		[486, 388, 22, 22, BOB, 0.014, 0.9, 0.4, null], [546, 402, 20, 14, GLOW, 0.4, 0.8, 0.2, Color("ffd23f")]]},
	"jack_in_the_box": {"motes": Color("ffe9a8"), "spots": [
		[382, 222, 60, 22, GLOW, 0.5, 0.6, 0.0, Color("ffc93c")], [390, 188, 95, 22, SWAY, 0.012, 0.8, 0.0, null],
		[622, 320, 48, 48, BOB, 0.012, 0.9, 0.3, null], [282, 60, 50, 55, SWAY, 0.02, 0.4, 0.0, null]]},
	"ghost_lantern": {"motes": Color("b88cff"), "spots": [
		[364, 150, 80, 95, BOB, 0.012, 0.5, 0.0, null], [364, 152, 40, 46, FLICKER, 0.5, 1.1, 0.0, Color("8fffe6")],
		[364, 170, 170, 120, GLOW, 0.3, 0.4, 0.3, Color("b07cff")], [232, 338, 40, 40, BOB, 0.008, 0.6, 0.5, null]]},
	"glitch_rift": {"motes": Color("3ee6ff"), "spots": [
		[362, 240, 45, 45, BOB, 0.014, 0.6, 0.0, null], [362, 240, 90, 90, GLOW, 0.45, 0.5, 0.0, Color("ffd23f")],
		[378, 258, 260, 85, FLICKER, 0.5, 1.4, 0.0, Color("ff4fb8")], [572, 284, 40, 40, BOB, 0.01, 0.7, 0.4, null]]},
	"scrap_robot": {"motes": Color("3ee6ff"), "spots": [
		[410, 210, 34, 30, FLICKER, 0.6, 1.2, 0.0, Color("3ee6ff")], [384, 214, 95, 95, SWAY, 0.006, 0.5, 0.0, null],
		[214, 286, 42, 42, BOB, 0.012, 0.8, 0.0, null], [508, 380, 24, 40, SWAY, 0.02, 0.9, 0.3, null]]},
	"shop": {"motes": Color("ffd34e"), "spots": [
		[365, 250, 95, 100, BOB, 0.01, 0.6, 0.0, null], [360, 40, 360, 30, FLICKER, 0.5, 0.6, 0.0, Color("ffffff")],
		[200, 185, 140, 60, GLOW, 0.35, 0.5, 0.0, Color("b88cff")], [540, 245, 55, 60, GLOW, 0.3, 0.4, 0.5, Color("ffd34e")]]},
	"charge_pad": {"motes": Color("5cff9a"), "spots": [
		[365, 300, 95, 75, BOB, 0.007, 0.3, 0.0, null], [365, 345, 160, 42, GLOW, 0.45, 0.6, 0.0, Color("5cff9a")],
		[432, 160, 45, 60, BOB, 0.02, 0.4, 0.2, null], [365, 100, 225, 95, FLICKER, 0.3, 0.6, 0.0, Color("ffe2a0")]]},
	"glow_chest": {"motes": Color("ffe08a"), "spots": [
		[370, 175, 160, 150, GLOW, 0.4, 0.5, 0.0, Color("ffd34e")], [380, 85, 260, 85, BOB, 0.012, 0.6, 0.0, null],
		[90, 375, 60, 60, BOB, 0.012, 0.55, 0.3, null]]},
	"banner_draft": {"motes": Color("ffd34e"), "spots": [
		[360, 300, 60, 60, BOB, 0.012, 0.6, 0.0, null], [216, 296, 50, 50, BOB, 0.012, 0.6, 0.33, null],
		[500, 296, 50, 50, BOB, 0.012, 0.6, 0.66, null], [360, 120, 210, 120, FLICKER, 0.25, 0.5, 0.0, Color("8fe8ff")]]},
	"banner_boon": {"motes": Color("8fe8ff"), "spots": [
		[370, 150, 75, 75, BOB, 0.012, 0.5, 0.0, null], [370, 150, 230, 150, GLOW, 0.3, 0.45, 0.0, Color("6fe8ff")],
		[204, 330, 60, 60, BOB, 0.012, 0.6, 0.4, null], [552, 360, 32, 32, BOB, 0.015, 0.7, 0.1, null]]},
	"banner_tier_up": {"motes": Color("ffd34e"), "spots": [
		[360, 230, 65, 75, BOB, 0.014, 0.6, 0.0, null], [360, 100, 180, 60, FLICKER, 0.45, 0.6, 0.0, Color("ffd34e")],
		[360, 330, 150, 38, GLOW, 0.45, 0.7, 0.0, Color("8fe8ff")]]},
	"banner_victory": {"motes": Color("ffd34e"), "spots": [
		[360, 140, 75, 75, GLOW, 0.4, 0.5, 0.0, Color("ffd34e")], [130, 90, 75, 75, FLICKER, 0.6, 0.7, 0.0, Color("ff6fc8")],
		[600, 80, 75, 75, FLICKER, 0.6, 0.6, 0.5, Color("6fe8ff")], [360, 280, 140, 48, BOB, 0.008, 0.9, 0.0, null]]},
	"banner_defeat": {"motes": Color("ff9f43"), "spots": [
		[350, 320, 60, 65, FLICKER, 0.55, 0.9, 0.0, Color("ff9f43")], [566, 90, 28, 32, FLICKER, 0.6, 0.5, 0.0, Color("fff2b0")],
		[530, 344, 34, 34, BOB, 0.008, 0.3, 0.0, null], [610, 280, 32, 42, BOB, 0.02, 0.35, 0.2, null]]},
}
const MOTES := 9

var art_id := ""
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
	var spec: Dictionary = SPECS.get(id, {})
	if not spec.is_empty():
		a._mat = ShaderMaterial.new()
		a._mat.shader = SHADER
		var rects: Array[Vector4] = []
		var moves: Array[Vector4] = []
		var cols: Array[Vector4] = []
		for s in spec.spots:
			rects.append(Vector4(s[0] / W, s[1] / H, s[2] / W, s[3] / H))
			moves.append(Vector4(s[4], s[5], s[6], s[7]))
			var c: Color = s[8] if s[8] != null else Color.BLACK
			cols.append(Vector4(c.r, c.g, c.b, 1.0))
		a._mat.set_shader_parameter("count", rects.size())
		a._mat.set_shader_parameter("spot_rect", rects)
		a._mat.set_shader_parameter("spot_move", moves)
		a._mat.set_shader_parameter("glow_col", cols)
		a._mat.set_shader_parameter("sweep", 1.0)
		a.material = a._mat
		a._motes = _Motes.new()
		a._motes.art = a
		a._motes.set_anchors_preset(Control.PRESET_FULL_RECT)
		a._motes.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a.add_child(a._motes)
	return a


func _process(delta: float) -> void:
	if _mat == null or A11y.reduced_motion or not is_visible_in_tree():
		return
	_t += delta
	var tick := CritterIcon.clock()
	if tick != _tick:
		_tick = tick
		_mat.set_shader_parameter("t", _t)
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
		var s := maxf(size.x / W, size.y / H) if art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED else minf(size.x / W, size.y / H)
		var origin := (size - Vector2(W, H) * s) / 2.0
		for i in MOTES:
			var h := hash([art.art_id, i])
			var f := fmod(t * (0.06 + (h & 63) / 63.0 * 0.06) + ((h >> 6) & 255) / 255.0, 1.0)
			var p := origin + Vector2(((h >> 14) & 1023) / 1023.0 * W + sin(t * 0.8 + i) * 10.0, H * (1.0 - f)) * s
			var a := sin(f * PI) * 0.7
			var col: Color = spec.motes
			draw_circle(p, 4.5 * s, Color(col, a * 0.25))
			draw_circle(p, 2.0 * s, Color(col, a))
