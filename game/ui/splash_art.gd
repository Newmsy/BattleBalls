## The bright loading screen (Newms 2026-10-23, "a fun, bright loading screen").
## The live version main.gd fades out at start-up shows the same picture as
## the web page and the native boot splash (game/brand/loading.png), so the
## hand-off from the page to the game is seamless.
##
## "art" (the default) is Newms's painted key art (the toned-down cut), with
## light movement on top: turning sun rays, a glint racing round the arena
## ring, a shimmer sweeping down the grid, twinkles and rising glow motes.
## The other looks are the code-drawn versions it was painted from: a sunset
## arena, a sunny meadow and a rainbow sky, with every critter playing its
## own fight effect (tools/brand/render_loading.gd renders them).
##
## Cheap on battery: the picture is drawn once on a layer that never
## redraws; only the overlay moves, at 30 fps, and only for the second or
## two the screen is up. Render-only.
extends Control

const CritterArt := preload("res://game/ui/critter_art.gd")
const BattleFx := preload("res://game/battle_fx.gd")
const CritterFx := preload("res://game/critter_fx.gd")
const Dot := preload("res://game/dot.gd")
const A11y := preload("res://game/a11y.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const ART := preload("res://game/brand/loading.png")
## Spots on the painting, in its own pixels: the sun behind the title, the
## arena ring (centre and radii) and the coins and sparkles that twinkle.
const ART_SUN := Vector2(426, 330)
const ART_RING := [Vector2(432, 1262), 330.0, 58.0]
const ART_HORIZON := 1062.0
const ART_TWINKLES := [Vector2(57, 630), Vector2(790, 870), Vector2(62, 1150), Vector2(782, 1153), Vector2(568, 778), Vector2(770, 438),
	Vector2(300, 1560), Vector2(600, 1640), Vector2(260, 600), Vector2(810, 1050), Vector2(170, 330), Vector2(700, 474)]
## Glows that pulse on the painted effects: [spot, radius, colour, beat]: Drako's
## and the phoenix's flame jets, the laser's spark, the phoenix, Count Nibbles'
## shield, the frost.
const ART_GLOWS := [[Vector2(320, 808), 80.0, Color(1, .6, .15), 3.1], [Vector2(300, 668), 70.0, Color(1, .55, .15), 3.7],
	[Vector2(505, 818), 60.0, Color(.5, .9, 1), 4.3], [Vector2(432, 545), 90.0, Color(1, .7, .2), 2.2],
	[Vector2(428, 1068), 190.0, Color(1, .2, .35), 1.6], [Vector2(690, 1300), 90.0, Color(.7, .9, 1), 2.6]]

## The composition is laid out on a 720 x 1280 portrait card centred on the
## screen; the sky and the grass stretch to fill whatever is around it.
const DESIGN := Vector2(720, 1280)
const FPS := 30
const INK := Color("2a1748")
const GOLD := Color("ffc23d")
const SKY_TOP := Color("2f86ff")
const SKY_MID := Color("6cc6ff")
const SKY_LOW := Color("d2f3ff")
const GRASS := Color("4cbc4f")
const GRASS_LIGHT := Color("8be36f")

## The cast: [critter, tier, x, y, radius, heading (rad), effect]
## (x, y from the screen centre in design units). Each plays a loop of its
## own fight effect, from game/battle_fx.gd and game/critter_fx.gd where one
## exists. Count Nibbles takes centre stage on the arena ring.
const CAST := [
	["drako", 5, -245, -140, 56, 0.35, "fire"],
	["laser", 4, 250, -150, 48, 2.75, "laser"],
	["phoenix", 5, 0, -270, 46, -1.57, "flames"],
	["ghost", 4, -235, -295, 38, -0.4, "ghost"],
	["comet", 5, 240, -300, 36, 3.6, "comet"],
	["sprout", 3, -258, 15, 48, 0.0, "leaves"],
	["kraken", 5, 255, 25, 58, 3.14, "tentacles"],
	["sundae", 5, -235, 330, 54, 0.0, "scoops"],
	["yeti", 4, 232, 345, 56, 3.14, "frost"],
	["yoyo", 3, 0, 470, 34, 0.0, "yoyo"],
	["vampire", 5, 0, 165, 100, 1.57, "blood"],
]
## Spinning coins: [x, y, radius, phase]
const COINS := [[-310, -230, 22, 0.0], [318, 215, 22, 1.7], [-305, 205, 18, 3.1], [130, -110, 16, 4.4], [-110, -60, 15, 2.2], [318, -30, 18, 5.0], [140, 420, 15, 0.9]]
## Twinkles: [x, y, size, phase]
const SPARKS := [[-150, -260, 14, 0.0], [170, -300, 12, 1.4], [-80, -20, 10, 2.6], [100, -40, 11, 3.8], [-310, 120, 12, 4.9], [300, -330, 10, 0.7]]

## Seconds the live screen stays up before it fades into the game, and the fade.
const HOLD := 1.1
const FADE := .4

## Shown once per run: coming back to the menu from a mode doesn't replay it.
static var played := false

## Which scene: "art" (Newms's painted key art), or a code-drawn one:
## "sunset" (a glowing arena stage at sunset, what the art was painted from),
## "meadow" (sunny grass) or "sky" (a rainbow over a sea of clouds).
var look := "art"

var _t := 0.0
var _tick := -1
var _live: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var back := _Layer.new(self, _draw_back)
	add_child(back)
	_live = _Layer.new(self, _draw_live)
	add_child(_live)
	add_child(_Layer.new(self, _draw_title))
	resized.connect(func():
		for c in get_children():
			c.queue_redraw())


## Puts the live loading screen over `host` at start-up and fades it into the
## game; a tap skips it. With `show` false (links, tests, a second visit) it
## only tells the web page the game is up. Either way the page's own loading
## screen (game/web/shell.html) stays until this says the game has drawn,
## so the page hands over to the same picture with no flash in between.
static func boot(host: Node, show: bool) -> void:
	if not show or played or DisplayServer.get_name() == "headless":
		page_ready.call_deferred()
		return
	played = true
	var layer := CanvasLayer.new()
	layer.layer = 120
	host.add_child(layer)
	var art: Control = load("res://game/ui/splash_art.gd").new()
	art.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await RenderingServer.frame_post_draw
	page_ready()
	var tw: Tween = art.create_tween()
	tw.tween_interval(HOLD)
	tw.tween_property(art, "modulate:a", 0.0, FADE)
	tw.tween_callback(layer.queue_free)
	art.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed and is_instance_valid(tw):
			tw.kill()
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var out: Tween = art.create_tween()
			out.tween_property(art, "modulate:a", 0.0, FADE * .5)
			out.tween_callback(layer.queue_free))


## Tells the web page (game/web/shell.html) to fade its loading screen.
static func page_ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.bbGameReady && window.bbGameReady()", true)


func _process(delta: float) -> void:
	if A11y.reduced_motion or not is_visible_in_tree():
		return
	_t += delta
	var k := int(_t * FPS)
	if k != _tick:
		_tick = k
		_live.queue_redraw()


## Scale and centre of the design card on this screen.
func _k() -> float:
	return minf(size.x / DESIGN.x, size.y / DESIGN.y)


func _centre() -> Vector2:
	return size / 2.0 + Vector2(0, -40) * _k()


## Where the title sits and the light rays fan out from.
func _sun() -> Vector2:
	return _centre() + Vector2(0, -480) * _k()


func _horizon() -> float:
	return _centre().y + 150.0 * _k()


# --- Scenery (drawn once) ----------------------------------------------------

func _draw_back(ci: CanvasItem) -> void:
	if look == "art":
		var sc := _art_scale()
		ci.draw_texture_rect(ART, Rect2(_art_at(Vector2.ZERO), ART.get_size() * sc), false)
		return
	if look == "sunset":
		_back_sunset(ci)
		return
	if look == "sky":
		_back_sky(ci)
		return
	var k := _k()
	var c := _centre()
	var w := size.x
	var hz := _horizon()
	# Sky: deep blue at the top to a pale haze at the horizon.
	_vgrad(ci, 0, c.y - 300 * k, w, [SKY_TOP, SKY_MID])
	_vgrad(ci, c.y - 300 * k, hz + 4, w, [SKY_MID, SKY_LOW])
	# The sun behind the badge.
	for i in 6:
		Dot.circle(ci, _sun(), (520 - i * 70) * k, Color(1, .98, .85, .07 + i * .02))
	# Clouds.
	for cl in [[-250, -470, 1.0], [270, -600, .8], [-40, -700, .6], [330, -250, .7], [-330, -150, .55]]:
		_cloud(ci, c + Vector2(cl[0], cl[1]) * k, 70 * cl[2] * k)
	# Far hills (hazy blue-green), then nearer rolling hills.
	_hills(ci, hz - 70 * k, 60 * k, 0.006 / k, 1.3, Color("8fd3c0"), w)
	_hills(ci, hz - 26 * k, 44 * k, 0.009 / k, 4.0, Color("6ccf78"), w)
	# The meadow down to the bottom of the screen.
	_vgrad(ci, hz, size.y, w, [GRASS_LIGHT, GRASS, Color("2f9a43")])
	# A shadow and a glowing arena ring where the badge "lands".
	var ring := Vector2(c.x, hz + 140 * k)
	CritterArt._ell(ci, ring, 250 * k, 50 * k, Color(.12, .35, .15, .35))
	_ellipse_line(ci, ring, 262 * k, 56 * k, Color("e8e2ff"), 5 * k)
	_ellipse_line(ci, ring, 262 * k, 56 * k, Color(.76, .71, 1, .35), 14 * k)
	# Grass tufts and flowers, seeded so every boot looks the same.
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var flowers := [Color.WHITE, Color("ffd23f"), Color("ff8fc8"), Color("9fd8ff")]
	var n := int(w / (18 * k)) + 30
	for i in n:
		var p := Vector2(rng.randf() * w, hz + 30 * k + pow(rng.randf(), 0.8) * (size.y - hz))
		if absf(p.x - ring.x) < 280 * k and absf(p.y - ring.y) < 70 * k:
			continue
		var depth := clampf((p.y - hz) / maxf(1.0, size.y - hz), 0.2, 1.0)
		if rng.randf() < .55:
			var h := (10 + rng.randf() * 10) * k * (0.6 + depth)
			Dot.poly(ci, PackedVector2Array([p + Vector2(-5 * k, 0), p + Vector2(rng.randf_range(-4, 4) * k, -h), p + Vector2(5 * k, 0)]), Color("2f8f3e"))
		else:
			_flower(ci, p, (5 + rng.randf() * 4) * k * (0.6 + depth), flowers[rng.randi() % flowers.size()])


func _back_sunset(ci: CanvasItem) -> void:
	var k := _k()
	var c := _centre()
	var w := size.x
	var hz := _horizon()
	_vgrad(ci, 0, c.y - 250 * k, w, [Color("ff6fb0"), Color("ff8f7a")])
	_vgrad(ci, c.y - 250 * k, hz + 4, w, [Color("ff8f7a"), Color("ffc46b"), Color("ffe9a0")])
	# A big low sun behind the badge.
	for i in 5:
		Dot.circle(ci, _sun(), (470 - i * 60) * k, Color(1, .95, .7, .1 + i * .03))
	Dot.circle(ci, _sun(), 200 * k, Color("fff2b8"))
	for cl in [[-260, -470, .9], [280, -590, .7], [330, -230, .6], [-320, -150, .5]]:
		_cloud(ci, c + Vector2(cl[0], cl[1]) * k, 70 * cl[2] * k, Color("ffe1ef"), Color(1, .55, .6, .35))
	_hills(ci, hz - 70 * k, 70 * k, 0.006 / k, 1.3, Color("e0609a"), w)
	_hills(ci, hz - 24 * k, 46 * k, 0.009 / k, 4.0, Color("a64aa8"), w)
	# The arena stage: a glowing violet floor with a perspective grid.
	_vgrad(ci, hz, size.y, w, [Color("7a46d8"), Color("4a2a9e"), Color("2c1a6e")])
	var vp := Vector2(c.x, hz - 60 * k)
	for i in range(-14, 15):
		var bx := c.x + i * 90 * k
		var a := vp.lerp(Vector2(bx, size.y), (hz - vp.y) / (size.y - vp.y))
		ci.draw_line(a, Vector2(bx * 1.0 + (bx - c.x) * 1.4, size.y + 200 * k), Color(1, .45, .85, .35), 2.5 * k, true)
	var y := hz
	var step := 10.0 * k
	while y < size.y:
		ci.draw_line(Vector2(0, y), Vector2(w, y), Color(1, .45, .85, .3), 2.5 * k, true)
		y += step
		step *= 1.45
	var ring := Vector2(c.x, hz + 140 * k)
	CritterArt._ell(ci, ring, 250 * k, 50 * k, Color(.08, .02, .2, .4))
	_ellipse_line(ci, ring, 262 * k, 56 * k, Color("7ff6ff"), 5 * k)
	_ellipse_line(ci, ring, 262 * k, 56 * k, Color(.5, .95, 1, .35), 16 * k)


func _back_sky(ci: CanvasItem) -> void:
	var k := _k()
	var c := _centre()
	var w := size.x
	_vgrad(ci, 0, size.y, w, [Color("4fb4ff"), Color("8fd6ff"), Color("cfe9ff"), Color("f1dcff")])
	for i in 6:
		Dot.circle(ci, _sun(), (520 - i * 70) * k, Color(1, 1, 1, .06 + i * .02))
	# A rainbow arching behind the badge.
	var rc := c + Vector2(0, 260) * k
	var bands := [Color("ff5a7a"), Color("ffa24a"), Color("ffe066"), Color("6fe07a"), Color("4fc8ff"), Color("9a7bff")]
	for i in bands.size():
		var col: Color = bands[i]
		col.a = .85
		ci.draw_arc(rc, (520 - i * 26) * k, PI, TAU, 64, col, 27 * k, true)
	for cl in [[-270, -480, .9], [280, -610, .7], [-60, -700, .55], [330, -260, .6]]:
		_cloud(ci, c + Vector2(cl[0], cl[1]) * k, 70 * cl[2] * k)
	# A sea of clouds from the badge's feet to the bottom, back rows bluer.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var y := _horizon() + 30 * k
	var row := 0
	while y < size.y + 120 * k:
		var tint := Color("dcecff").lerp(Color.WHITE, minf(1.0, row * .25))
		var x := -rng.randf() * 80 * k
		while x < w + 80 * k:
			var r := (60 + rng.randf() * 40) * k * (1.0 + row * .12)
			Dot.circle(ci, Vector2(x, y + r * .25), r, Color(.55, .7, .95, .35))
			Dot.circle(ci, Vector2(x, y), r, tint)
			x += r * 1.3
		y += 90 * k * (1.0 + row * .15)
		row += 1


func _vgrad(ci: CanvasItem, y0: float, y1: float, w: float, cols: Array) -> void:
	var steps := cols.size() - 1
	for i in steps:
		var a := lerpf(y0, y1, float(i) / steps)
		var b := lerpf(y0, y1, float(i + 1) / steps)
		ci.draw_polygon(PackedVector2Array([Vector2(0, a), Vector2(w, a), Vector2(w, b), Vector2(0, b)]),
			PackedColorArray([cols[i], cols[i], cols[i + 1], cols[i + 1]]))


func _cloud(ci: CanvasItem, p: Vector2, r: float, col := Color.WHITE, shade := Color(.62, .82, 1, .45)) -> void:
	for b in [[-1.0, .2, .6], [-.45, -.15, .8], [.2, -.3, .95], [.85, .05, .7], [.0, .25, .75]]:
		Dot.circle(ci, p + Vector2(b[0], b[1]) * r + Vector2(0, r * .12), r * b[2], shade)
	for b in [[-1.0, .2, .6], [-.45, -.15, .8], [.2, -.3, .95], [.85, .05, .7], [.0, .25, .75]]:
		Dot.circle(ci, p + Vector2(b[0], b[1]) * r, r * b[2], col)


func _hills(ci: CanvasItem, y: float, amp: float, freq: float, phase: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var steps := 48
	for i in steps + 1:
		var x := w * i / steps
		pts.append(Vector2(x, y - amp * (0.55 + 0.45 * sin(x * freq + phase)) - amp * 0.3 * sin(x * freq * 2.7 + phase * 2.0)))
	pts.append(Vector2(w, y + amp * 3))
	pts.append(Vector2(0, y + amp * 3))
	Dot.poly(ci, pts, col)


func _ellipse_line(ci: CanvasItem, p: Vector2, rx: float, ry: float, col: Color, wd: float) -> void:
	var pts := CritterArt.ellipse_pts(p, rx, ry, 0.0, 0.0, TAU, 48)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, wd, true)


func _flower(ci: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	for i in 5:
		Dot.circle(ci, p + Vector2.from_angle(TAU * i / 5.0 - PI / 2) * r * .62, r * .5, col)
	Dot.circle(ci, p, r * .38, Color("ffb020") if col != Color("ffd23f") else Color("ff7a2a"))


# --- Moving parts (redrawn at 30 fps while shown) ---------------------------

func _draw_live(ci: CanvasItem) -> void:
	if look == "art":
		_art_live(ci)
		return
	var k := _k()
	var c := _centre()
	var t := _t
	# Light rays fanning out from behind the title, turning slowly.
	var sun := _sun()
	var reach := size.length()
	for i in 16:
		var a := TAU * i / 16.0 + t * .06
		var half := 0.07 if i % 2 == 0 else 0.04
		Dot.poly(ci, PackedVector2Array([sun, sun + Vector2.from_angle(a - half) * reach, sun + Vector2.from_angle(a + half) * reach]),
			(Color(1, .96, .8) if look == "sunset" else Color(1, 1, .92)) * Color(1, 1, 1, .16 if i % 2 == 0 else .1))
	for s in SPARKS:
		var tw := .5 + .5 * sin(t * 3.0 + s[3])
		_twinkle(ci, c + Vector2(s[0], s[1]) * k, s[2] * k * (.5 + tw * .7), Color(1, 1, 1, .5 + tw * .5))
	for f in CAST:
		var ph: float = 20.0 + f[2] * .013 + f[3] * .007 # Kept positive: the effects loop with fmod.
		var bob := Vector2(sin(t * 1.6 + ph) * 8, cos(t * 2.1 + ph) * 12) * (.3 if f[0] == "vampire" else 1.0)
		var p := c + (Vector2(f[2], f[3]) + bob) * k
		var r: float = f[4] * k
		var dir := Vector2.from_angle(f[5])
		if f[6] == "yoyo": # Loop-the-loops round its spot.
			p += Vector2.from_angle(t * 4.0) * r * 1.3
		if p.y > _horizon() and look != "sky": # A soft shadow on the ground.
			CritterArt._ell(ci, Vector2(p.x, c.y + (f[3] + r / k * 1.02) * k), r * .9, r * .22, Color(.1, .3, .12, .35))
		_effect(ci, f[6], true, p, r, dir, t + ph, c + Vector2(f[2], f[3]) * k)
		CritterArt.draw_critter(ci, f[0], p, r, {"t": t + ph, "tier": f[1], "look": dir,
			"blink": 1.0 if fmod(t + ph * 3.0, 3.4) < .12 else 0.0})
		ci.draw_set_transform_matrix(Transform2D.IDENTITY) # Critter art can leave its own set.
		_effect(ci, f[6], false, p, r, dir, t + ph, c + Vector2(f[2], f[3]) * k)
	for co in COINS:
		_coin(ci, c + Vector2(co[0], co[1] + sin(t * 1.8 + co[3]) * 8) * k, co[2] * k, t * 2.4 + co[3])


# --- The painted art: fills the screen, cropped at the sides or ends ---------

func _art_scale() -> float:
	return maxf(size.x / ART.get_width(), size.y / ART.get_height())


## Screen position of a point on the painting.
func _art_at(q: Vector2) -> Vector2:
	var sc := _art_scale()
	return (size - ART.get_size() * sc) / 2.0 + q * sc


func _art_live(ci: CanvasItem) -> void:
	var sc := _art_scale()
	var t := _t + 20.0
	# Soft rays turning slowly from the sun behind the title.
	var sun := _art_at(ART_SUN)
	var reach := size.length()
	for i in 12:
		var a := TAU * i / 12.0 + t * .05
		Dot.poly(ci, PackedVector2Array([sun, sun + Vector2.from_angle(a - .06) * reach, sun + Vector2.from_angle(a + .06) * reach]),
			Color(1, .95, .8, .07 + .03 * sin(t * 1.3 + i)))
	# A shimmer sweeping down the grid floor, its lines closer near the horizon.
	var hz := _art_at(Vector2(0, ART_HORIZON)).y
	for j in 2:
		var f := fposmod(t * .35 + j * .5, 1.0)
		var y := lerpf(hz, size.y + 40 * sc, f * f)
		ci.draw_line(Vector2(0, y), Vector2(size.x, y), Color(1, .5, .95, .28 * sin(f * PI)), (3 + 10 * f) * sc, true)
	for g in ART_GLOWS:
		var pulse := .5 + .5 * sin(t * g[3])
		var gc: Color = g[2]
		for k in 3:
			Dot.circle(ci, _art_at(g[0]), g[1] * sc * (.55 + k * .25) * (.9 + .15 * pulse), Color(gc, .07 * pulse))
	# A bright glint racing round the arena ring, with a short tail.
	var rc := _art_at(ART_RING[0])
	for k in 8:
		var a := t * 2.2 - k * .07
		var at := rc + Vector2(cos(a) * ART_RING[1], sin(a) * ART_RING[2]) * sc
		Dot.circle(ci, at, (16 - k * 1.5) * sc, Color(.8, .98, 1, .75 - k * .09))
	# Coins and sparkles catch the light in turn.
	for i in ART_TWINKLES.size():
		var tw := sin(t * 2.3 + i * 1.7)
		if tw > 0.3:
			_twinkle(ci, _art_at(ART_TWINKLES[i]) + Vector2(8, -8) * sc, 15 * sc * tw, Color(1, 1, .95, tw))
	# Little glow motes drifting up from the arena.
	for i in 14:
		var f := fposmod(t * .12 + i * .137, 1.0)
		var x := fposmod(i * 97.0 + sin(t * .7 + i) * 20.0, ART.get_width())
		var at := _art_at(Vector2(x, lerpf(1700, 500, f)))
		Dot.circle(ci, at, (3 + i % 3) * sc, Color(1, .8, .95, .6 * sin(f * PI)))


## One critter's signature effect, behind it (`back`) or in front.
func _effect(ci: CanvasItem, kind: String, back: bool, p: Vector2, r: float, dir: Vector2, t: float, home: Vector2) -> void:
	match kind:
		"fire": # Drako breathes a stream of fireballs.
			if not back:
				BattleFx.draw_fireballs(ci, p + dir * r * 1.0, p + dir * r * 3.3, 1.0, t, r * .42)
		"laser": # Laser fires a pulsing beam with a spark where it lands.
			if back:
				var a := p + dir * r * .9
				var b := p + dir * r * 3.6
				var pulse := .7 + .3 * sin(t * 9.0)
				ci.draw_line(a, b, Color(.15, .8, 1, .25), r * .95 * pulse, true)
				ci.draw_line(a, b, Color("27c8ff"), r * .42 * pulse, true)
				ci.draw_line(a, b, Color(1, 1, 1, .95), r * .15, true)
				_twinkle(ci, b, r * (.45 + .25 * sin(t * 13.0)), Color(.85, .97, 1, .95))
		"flames": # Phoenix burns, embers rising.
			if not back:
				BattleFx._flames(ci, p, r, t)
		"ghost": # Ghost leaves fading copies of itself.
			if back:
				for i in range(3, 0, -1):
					BattleFx.draw_afterimage(ci, p - dir * r * .75 * i, r * (1.0 - .08 * i), 1.0 - i * .25, Color("e3d6ff"))
		"comet": # Comet streaks past.
			if back:
				BattleFx.draw_speed_blur(ci, Color("ff5ad1"), p, r, dir, 1.9, t)
		"tentacles": # Kraken's arms wave out below it.
			if back:
				for i in 3:
					var d := Vector2.from_angle(PI * .5 + (i - 1) * .75 + sin(t * 1.3 + i) * .15)
					BattleFx.draw_tentacle(ci, p + d * r * .5, p + d * r * 2.1, r * .2, Color("8e3bbd"), t, i * 2.0)
		"leaves": # Sprout's leaves swirl round it.
			if not back:
				for i in 6:
					var a := t * 1.4 + i * TAU / 6.0
					var at := p + Vector2(cos(a), sin(a) * .55) * r * 1.55
					BattleFx._leaf(ci, at, a + PI * .5, r * (.6 if sin(a) > 0 else .45), CritterFx.LEAF if i % 2 else CritterFx.LEAF.lightened(.25))
		"scoops": # Sundae flings scoops that arc up and drop.
			if not back:
				for i in 3:
					var f := fmod(t * .6 + i / 3.0, 1.0)
					var at := p + Vector2((i - 1) * r * 1.9 * f, -r * 1.1 - sin(f * PI) * r * 2.2 + f * r * .6)
					CritterFx.draw_scoop(ci, at, r * .3 * (1.0 - .3 * f), i)
		"frost": # Yeti's icy breath and falling snow.
			if back:
				BattleFx.draw_frost_breath(ci, p, r * 1.4, -dir, t)
			else:
				for i in 6:
					var f := fmod(t * .35 + i / 6.0, 1.0)
					var at := p + Vector2(sin(i * 2.4 + t) * r * 1.4, -r * 1.8 + f * r * 3.0)
					_twinkle(ci, at, r * .12, Color(1, 1, 1, .9 * sin(f * PI)))
		"yoyo": # Yoyo's loop trail.
			if back:
				var a0 := t * 4.0
				for i in 8:
					var a := a0 - i * .28
					Dot.circle(ci, home + Vector2.from_angle(a) * r * 1.3, r * (.9 - i * .09), Color(.6, .95, 1, .5 - i * .055))
		"blood": # Count Nibbles' blood shield.
			if not back:
				BattleFx.draw_blood_shield(ci, p, r, t)


func _twinkle(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	Dot.poly(ci, PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * .22, -s * .22), p + Vector2(s, 0), p + Vector2(s * .22, s * .22),
		p + Vector2(0, s), p + Vector2(-s * .22, s * .22), p + Vector2(-s, 0), p + Vector2(-s * .22, -s * .22)]), col)


## A gold coin seen spinning: its width follows the turn.
func _coin(ci: CanvasItem, p: Vector2, r: float, a: float) -> void:
	var sx := maxf(.12, absf(cos(a)))
	CritterArt._ell(ci, p + Vector2(r * .12, r * .1), r * sx, r, Color("b07a12"))
	CritterArt._ell(ci, p, r * sx, r, Color("ffd45c"))
	CritterArt._ell(ci, p, r * .7 * sx, r * .7, Color("f0b532"))
	if sx > .35:
		var star := CritterArt.star_pts(Vector2.ZERO, r * .42, r * .19, 5)
		for i in star.size():
			star[i] = p + Vector2(star[i].x * sx, star[i].y)
		Dot.poly(ci, star, Color("fff0b0"))
	Dot.circle(ci, p + Vector2(-r * .4 * sx, -r * .45), r * .14, Color(1, 1, 1, .8))


# --- The title (drawn once) --------------------------------------------------

func _draw_title(ci: CanvasItem) -> void:
	if look == "art":
		return
	var k := _k()
	var sun := _sun()
	_title(ci, "BATTLE", sun + Vector2(0, -12) * k, 112 * k, Color.WHITE, Color("dcd2ff"))
	_title(ci, "BALLS", sun + Vector2(0, 112) * k, 150 * k, Color("ffe066"), Color("ffab1f"))


## A chunky outlined word with a two-tone fill (light top, deeper bottom), centred on `base`.
func _title(ci: CanvasItem, text: String, base: Vector2, fs: float, top: Color, bottom: Color) -> void:
	var sz := int(fs)
	var w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var p := base - Vector2(w / 2.0, 0)
	ci.draw_string_outline(FONT, p + Vector2(0, fs * .07), text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(fs * .26), INK)
	ci.draw_string_outline(FONT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(fs * .2), INK)
	# A deeper copy underneath peeks out at the bottom edge: a bevel.
	ci.draw_string(FONT, p + Vector2(0, fs * .035), text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, bottom)
	ci.draw_string(FONT, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, top)


## One layer of the screen, drawn by `fn` on the owner.
class _Layer:
	extends Control
	var fn: Callable

	func _init(owner_: Control, fn_: Callable) -> void:
		fn = fn_
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		fn.call(self)
