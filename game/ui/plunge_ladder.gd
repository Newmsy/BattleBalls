## The Plunge screen's course card with the league ladder down its left side
## (meta/plunge_league.gd): all six crests, Neon on top and Bronze at the
## bottom, each at its points. Your league's rung is the big one, on a band,
## with your points; the leagues above are dimmed and the next one is lit,
## with what it brings beside it (stronger rivals, its coins). Beside your
## rung: the league's name and the points to go. The rest of the card is the
## next course's painting, its name, and your racer, big. The rungs, rail and
## band draw in one pass; the words are labels placed on the rungs.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const PlungeLeague := preload("res://meta/plunge_league.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")

const LADDER_W := 228.0 ## The dark strip the ladder sits on.
const CREST_X := 80.0 ## Centre line of the crests and the rail.
const NUM_X := 150.0 ## Where the points start.
const PAD_Y := 14.0
const CUR := 1.5 ## Your rung's height, in rungs.
const GOLD := Color("ffc23d")
const UP := Color("ff8a5c")
const DIM := Color(.4, .4, .5) ## A league above the next one.

var points := 0
var idx := 0
var _rungs: _Rungs
var _name: Label
var _block: Control ## Your league's name over the points to go.
var _perks: Control ## What the next league brings, on its rung.
var _course: Control
var _info: Control
var _racer: Control
var _crests: Array[Texture2D] = [] ## Loaded with the card: a texture first loaded mid-draw draws blank.


## The card for `points` league points: `painting` fills it, `course` is the
## course's name, `racer` your racer's icon (or null), `rival` a face for the
## stronger-rivals pill, `info` the "i" button.
static func make(pts: int, painting: Control, course: String, racer: Control, rival: String, tier: int, info: Control) -> Control:
	var c = load("res://game/ui/plunge_ladder.gd").new()
	c.points = pts
	c.idx = PlungeLeague.index_for(pts)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c._build(painting, course, racer, rival, tier, info)
	return c


## League `i`'s crest texture (game/ui/versus_art/league_<id>_Lcrest.png).
static func crest_tex(i: int) -> Texture2D:
	return load("res://game/ui/versus_art/league_%s_Lcrest.png" % PlungeLeague.LEAGUES[i].id)


## League `i`'s crest as a control `h` tall (the crest is twice as wide).
static func crest(i: int, h: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = crest_tex(i)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(h * 2, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## What league `i` brings, as two pills: a rival's face with an up arrow
## (its field races with more talents) and its coin multiplier.
static func perks(i: int, rival: String, tier: int, size := 26) -> HBoxContainer:
	var face := Kit.hbox(2, [CritterIcon.make(rival, tier, roundf(size * 2.0)), _Up.make(roundf(size * .6), UP)])
	var coins := Kit.amount("coin", "×%s" % str(PlungeLeague.LEAGUES[i].coins), size, GOLD)
	return Kit.hbox(10, [_pill(face), _pill(coins)])


static func _pill(c: Control) -> PanelContainer:
	var st := Kit.box(Color(Kit.BG, .75), Color(GOLD, .55), 999, 3, 0)
	st.content_margin_left = 8
	st.content_margin_right = 16
	st.content_margin_top = 3
	st.content_margin_bottom = 3
	var p := Kit.panel(c, st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## The result popup's promotion: a band on the new league's stage, the old
## crest stepping up to the new one, the league's name and what it brings.
## `bleed`: how far past the content the band runs, to the card's edges.
## Its new crest is `get_meta("crest")`, for the popup to drop in.
static func promoted(from: int, to: int, rival: String, tier: int, bleed: float) -> Control:
	var col: Color = Ladder.LEAGUES[to].color
	var band := _Band.new()
	band.stage = load("res://game/ui/versus_art/league_%s.png" % PlungeLeague.LEAGUES[to].id)
	band.col = col
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.clip_contents = true
	band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band.offset_left = -bleed
	band.offset_right = bleed
	var eyebrow := Kit.label("PROMOTED", 22, col)
	var old := crest(from, 80)
	old.modulate = Color(.8, .8, .85)
	var new := crest(to, 230)
	var title := Kit.label("%s LEAGUE!" % PlungeLeague.LEAGUES[to].name.to_upper(), 54, col, HORIZONTAL_ALIGNMENT_CENTER)
	Kit.soft_shadow(title, col.darkened(.7), 5, 8)
	var pk := perks(to, rival, tier)
	pk.alignment = BoxContainer.ALIGNMENT_CENTER
	band.parts = [eyebrow, old, _Up.make(44, col, true), new, title, pk]
	for c in band.parts:
		band.add_child(c)
	band.resized.connect(band.place)
	var host := Control.new()
	host.name = "PlungePromoted"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.custom_minimum_size.y = 340
	host.add_child(band)
	host.set_meta("crest", new)
	return host


func _build(painting: Control, course: String, racer: Control, rival: String, tier: int, info: Control) -> void:
	for i in PlungeLeague.LEAGUES.size():
		_crests.append(crest_tex(i))
	painting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(painting)
	_rungs = _Rungs.new()
	_rungs.card = self
	_rungs.clip_contents = true
	_rungs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rungs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rungs)
	_racer = racer
	if racer != null:
		add_child(racer)
	var col: Color = Ladder.LEAGUES[idx].color
	_name = Kit.label(PlungeLeague.LEAGUES[idx].name.to_upper(), 44, col)
	Kit.soft_shadow(_name, Color(Kit.BG, .9), 3, 6)
	_block = Kit.vbox(0, [_name])
	if idx + 1 < PlungeLeague.LEAGUES.size():
		var gap: int = PlungeLeague.LEAGUES[idx + 1].min - points
		_block.add_child(Kit.hbox(6, [Kit.label(str(gap), 24, Kit.MUTED), crest(idx + 1, 26)]))
		_perks = perks(idx + 1, rival, tier)
		add_child(_perks)
	_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_block)
	var cname := Kit.label(course, 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	cname.add_theme_constant_override("outline_size", 10)
	cname.add_theme_color_override("font_outline_color", Color(Kit.BG, .85))
	cname.clip_text = true
	cname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_course = cname
	add_child(cname)
	_info = info
	add_child(info)
	resized.connect(_layout)


## Where each rung sits: [centre y, height] from Neon (top) down to Bronze.
func rungs() -> Array:
	var n := PlungeLeague.LEAGUES.size()
	var unit := (size.y - 2.0 * PAD_Y) / (n - 1 + CUR)
	var out := []
	out.resize(n)
	var y := PAD_Y
	for i in range(n - 1, -1, -1):
		var h := unit * (CUR if i == idx else 1.0)
		out[i] = [y + h / 2.0, h]
		y += h
	return out


func _layout() -> void:
	var r := rungs()
	var right := size.x - LADDER_W
	var isz := _info.get_combined_minimum_size()
	_info.position = Vector2(size.x - isz.x - 12, 12)
	_info.size = isz
	var csz := _course.get_combined_minimum_size()
	_course.position = Vector2(LADDER_W + 8, 14 + (isz.y - csz.y) / 2.0)
	_course.size = Vector2(right - 16 - isz.x - 12, csz.y)
	var top := _course.position.y + csz.y + 6
	var racer_x := size.x
	if _racer != null: # Big, but the rungs beside it set the card's height.
		var side := clampf(size.y * .5, 140.0, 300.0)
		_racer.custom_minimum_size = Vector2(side, side)
		racer_x = size.x - side - 10
		_racer.position = Vector2(racer_x, size.y - side - 6)
		_racer.size = _racer.custom_minimum_size
		racer_x += side * .2 # The face is smaller than its box.
	# The name shrinks to keep clear of your racer (PLATINUM is long).
	var room := racer_x + 30 - (LADDER_W + 18)
	var fs: int = A11y.font(44)
	while fs > A11y.font(28) and Kit.FONT.get_string_size(_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > room:
		fs -= 2
	_name.add_theme_font_size_override("font_size", fs)
	var bsz := _block.get_combined_minimum_size()
	var by: float = r[idx][0] - bsz.y * .45
	if _perks != null:
		var psz := _perks.get_combined_minimum_size()
		var py := clampf(r[idx + 1][0] - psz.y / 2.0, top, by - psz.y - 4)
		py = maxf(py, top)
		_perks.position = Vector2(LADDER_W + 10, py)
		_perks.size = psz
		by = maxf(by, py + psz.y + 4)
	by = clampf(by, top, maxf(top, size.y - bsz.y - 8))
	_block.position = Vector2(LADDER_W + 18, by)
	_block.size = bsz
	_rungs.queue_redraw()


## Your racer's rung climbs a bar from Bronze to here, then part of the way
## to the next by your points.
func fill_y(r: Array) -> float:
	if idx + 1 >= r.size():
		return r[idx][0]
	return lerpf(r[idx][0], r[idx + 1][0], PlungeLeague.progress(points))


## The ladder: its dark strip, the rail and how far up it you are, your
## rung's band, then the crests and their points.
class _Rungs extends Control:
	var card

	func _draw() -> void:
		var r: Array = card.rungs()
		var idx: int = card.idx
		var h := size.y
		var w := LADDER_W
		var bg := Kit.box(Color(Kit.BG, .9), Color(0, 0, 0, 0), 0, 0, 0)
		bg.corner_radius_top_left = 28
		bg.corner_radius_bottom_left = 28
		draw_style_box(bg, Rect2(0, 0, w * .8, h))
		var a := Color(Kit.BG, .9)
		var b := Color(Kit.BG, .45)
		draw_polygon(PackedVector2Array([Vector2(w * .8, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * .8, h)]), PackedColorArray([a, b, b, a]))
		var col: Color = Ladder.LEAGUES[idx].color
		var x := CREST_X
		var top: float = r[r.size() - 1][0]
		var bottom: float = r[0][0]
		draw_rect(Rect2(x - 4.5, top, 9, bottom - top), Color("2e2a5a"))
		var fy: float = card.fill_y(r)
		draw_rect(Rect2(x - 4.5, fy, 9, bottom - fy), col)
		# Your rung: a band across the strip, lines at its edges.
		var c: float = r[idx][0]
		var bh: float = r[idx][1]
		var y0 := c - bh / 2.0
		var l := Color(col, .3)
		var rr := Color(col, .06)
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y0 + bh), Vector2(0, y0 + bh)]), PackedColorArray([l, rr, rr, l]))
		draw_line(Vector2(0, y0), Vector2(w, y0), Color(col, .6), 3.0)
		draw_line(Vector2(0, y0 + bh), Vector2(w, y0 + bh), Color(col, .6), 3.0)
		var unit: float = r[0][1] if idx != 0 else r[1][1]
		for i in r.size():
			var ch := minf(unit * .86, 60.0)
			var tint := Color.WHITE
			var num := str(PlungeLeague.LEAGUES[i].min)
			var fs := A11y.font(20)
			var fc := Kit.MUTED
			if i == idx:
				ch = minf(bh * .9, 96.0)
				num = str(card.points)
				fs = A11y.font(32)
				fc = Kit.FG
			elif i == idx + 1:
				ch = minf(unit * .97, 66.0)
				fc = GOLD
			elif i > idx:
				tint = DIM
				fc = Color("6c6896")
			var tex: Texture2D = card._crests[i]
			var cw := ch * tex.get_width() / tex.get_height()
			draw_texture_rect(tex, Rect2(x - cw / 2.0, r[i][0] - ch / 2.0, cw, ch), false, tint)
			var nx := NUM_X + (16.0 if i == idx else 0.0)
			var base: float = r[i][0] + (Kit.FONT.get_ascent(fs) - Kit.FONT.get_descent(fs)) / 2.0
			draw_string(Kit.FONT, Vector2(nx, base), num, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fc)


## The promotion band: the stage, darkened at the foot and the left so the
## words read, gold lines at its edges; `parts` are placed on it.
class _Band extends Control:
	var stage: Texture2D
	var col: Color
	var parts: Array = [] ## Eyebrow, old crest, arrow, new crest, title, perks.

	func place() -> void:
		var w := size.x
		var h := size.y
		var fit := func(c: Control, at: Vector2) -> void:
			c.size = c.get_combined_minimum_size()
			c.position = at
		fit.call(parts[0], Vector2(26, 18))
		fit.call(parts[1], Vector2(18, 78))
		fit.call(parts[2], Vector2(186, 96))
		fit.call(parts[3], Vector2(w - 460 - 20, 10))
		var t: Control = parts[4]
		t.size = Vector2(w, t.get_combined_minimum_size().y)
		var p: Control = parts[5]
		var ps := p.get_combined_minimum_size()
		p.size = Vector2(w, ps.y)
		p.position = Vector2(0, h - ps.y - 16)
		t.position = Vector2(0, p.position.y - t.size.y + 2)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color("0e0c26"))
		# The stage covers the band's height, its plinth under the new crest.
		var k := h * 1.12 / stage.get_height()
		var sw := stage.get_width() * k
		draw_texture_rect(stage, Rect2(w * .76 - sw * .76, (h - stage.get_height() * k) / 2.0, sw, stage.get_height() * k), false)
		var dark := Color(Kit.BG, .92)
		var clear := Color(Kit.BG, 0)
		draw_polygon(PackedVector2Array([Vector2(0, h * .58), Vector2(w, h * .58), Vector2(w, h), Vector2(0, h)]), PackedColorArray([clear, clear, dark, dark]))
		var side := Color(Kit.BG, .7)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * .45, 0), Vector2(w * .45, h), Vector2(0, h)]), PackedColorArray([side, clear, clear, side]))
		draw_line(Vector2(0, 1), Vector2(w, 1), Color(col, .7), 3.0)
		draw_line(Vector2(0, h - 1), Vector2(w, h - 1), Color(col, .7), 3.0)


## A small arrow: up (the next league's rivals race stronger) or, `right`,
## from the old crest to the new.
class _Up extends Control:
	var col: Color
	var right := false

	static func make(side: float, color: Color, point_right := false) -> Control:
		var u := _Up.new()
		u.col = color
		u.right = point_right
		u.custom_minimum_size = Vector2(side, side)
		u.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		u.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return u

	func _draw() -> void:
		var s := size
		var pts := PackedVector2Array([Vector2(s.x / 2.0, s.y * .1), Vector2(s.x, s.y * .85), Vector2(0, s.y * .85)])
		if right:
			pts = PackedVector2Array([Vector2(s.x * .15, 0), Vector2(s.x, s.y / 2.0), Vector2(s.x * .15, s.y)])
		draw_colored_polygon(pts, col)
