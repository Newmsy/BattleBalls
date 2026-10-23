## The bright loading screen: a sunny sky over rolling grass, light rays
## fanning out from a BATTLE BALLS badge, and our own critters flying around
## it with spinning coins (Newms 2026-10-23, "a fun, bright loading screen").
## The same drawing makes the boot image (tools/brand/render_loading.gd ->
## game/brand/loading.png, which the web shell and the native boot splash
## show) and the live version main.gd fades out at start-up, so the hand-off
## from the page to the game is seamless.
##
## Cheap on battery: the scenery and the badge are drawn once on layers that
## never redraw; only the rays, the flyers and the coins move, at 30 fps,
## and only for the second or two the screen is up. Render-only.
extends Control

const CritterArt := preload("res://game/ui/critter_art.gd")
const Dot := preload("res://game/dot.gd")
const A11y := preload("res://game/a11y.gd")
const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")

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

## The flyers: [critter, tier, x, y, radius, heading (rad), streaks]
## (x, y from the badge centre in design units). One or two per family.
const FLYERS := [
	["drako", 5, -235, -330, 56, -0.5, true],
	["laser", 4, 238, -375, 46, 3.6, true],
	["kraken", 5, 252, -120, 58, 3.3, false],
	["sprout", 3, -258, -95, 46, 0.2, false],
	["ghost", 4, -140, -470, 38, -0.9, true],
	["comet", 5, 140, -485, 36, 3.9, true],
	["sundae", 5, -232, 318, 54, 0.0, false],
	["yeti", 4, 226, 330, 56, 3.14, false],
	["yoyo", 3, -40, 470, 38, 0.0, false],
	["phoenix", 5, 0, -548, 42, -1.57, true],
]
## Spinning coins: [x, y, radius, phase]
const COINS := [[-300, -215, 24, 0.0], [318, 215, 22, 1.7], [-305, 205, 18, 3.1], [165, -255, 16, 4.4], [312, -470, 20, 2.2], [-292, -560, 18, 5.0], [92, 255, 15, 0.9]]
## Twinkles: [x, y, size, phase]
const SPARKS := [[-150, -260, 14, 0.0], [190, -200, 12, 1.4], [-60, -380, 10, 2.6], [300, -300, 11, 3.8], [-310, 70, 12, 4.9], [140, -610, 10, 0.7]]

## Seconds the live screen stays up before it fades into the game, and the fade.
const HOLD := 1.1
const FADE := .4

## Shown once per run: coming back to the menu from a mode doesn't replay it.
static var played := false

## Which scene: "meadow" (sunny grass), "sunset" (a glowing arena stage at
## sunset) or "sky" (a rainbow over a sea of clouds).
var look := "meadow"

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
	add_child(_Layer.new(self, _draw_badge))
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


func _horizon() -> float:
	return _centre().y + 150.0 * _k()


# --- Scenery (drawn once) ----------------------------------------------------

func _draw_back(ci: CanvasItem) -> void:
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
		Dot.circle(ci, c, (520 - i * 70) * k, Color(1, .98, .85, .07 + i * .02))
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
		Dot.circle(ci, c + Vector2(0, 40) * k, (470 - i * 60) * k, Color(1, .95, .7, .1 + i * .03))
	Dot.circle(ci, c + Vector2(0, 40) * k, 220 * k, Color("fff2b8"))
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
		Dot.circle(ci, c, (520 - i * 70) * k, Color(1, 1, 1, .06 + i * .02))
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
	var k := _k()
	var c := _centre()
	var t := _t
	# Light rays fanning out from the badge, turning slowly.
	var reach := size.length()
	for i in 16:
		var a := TAU * i / 16.0 + t * .06
		var half := 0.07 if i % 2 == 0 else 0.04
		Dot.poly(ci, PackedVector2Array([c, c + Vector2.from_angle(a - half) * reach, c + Vector2.from_angle(a + half) * reach]),
			(Color(1, .96, .8) if look == "sunset" else Color(1, 1, .92)) * Color(1, 1, 1, .16 if i % 2 == 0 else .1))
	for s in SPARKS:
		var tw := .5 + .5 * sin(t * 3.0 + s[3])
		_twinkle(ci, c + Vector2(s[0], s[1]) * k, s[2] * k * (.5 + tw * .7), Color(1, 1, 1, .5 + tw * .5))
	for f in FLYERS:
		var ph: float = f[2] * .013 + f[3] * .007
		var bob := Vector2(sin(t * 1.6 + ph) * 8, cos(t * 2.1 + ph) * 12)
		var p := c + (Vector2(f[2], f[3]) + bob) * k
		var r: float = f[4] * k
		var head: float = f[5]
		if f[6]:
			var back := -Vector2.from_angle(head)
			var side := back.orthogonal()
			for j in 3:
				var o: Vector2 = side * (j - 1) * r * .45
				var a0: Vector2 = p + back * r * 1.05 + o
				var a1: Vector2 = a0 + back * r * (1.1 - absf(j - 1) * .35) * (1.0 + .15 * sin(t * 8.0 + j))
				ci.draw_line(a0, a1, Color(1, 1, 1, .7), r * .13, true)
		else:
			# A soft shadow on the grass for the ones on the ground.
			if p.y > _horizon() and look != "sky":
				CritterArt._ell(ci, Vector2(p.x, p.y + r * 1.05), r * .9, r * .22, Color(.1, .3, .12, .35))
		var look := Vector2.from_angle(head)
		CritterArt.draw_critter(ci, f[0], p, r, {"t": t + ph, "tier": f[1], "look": look,
			"blink": 1.0 if fmod(t + ph * 3.0, 3.4) < .12 else 0.0})
	for co in COINS:
		_coin(ci, c + Vector2(co[0], co[1] + sin(t * 1.8 + co[3]) * 8) * k, co[2] * k, t * 2.4 + co[3])


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


# --- The badge (drawn once) --------------------------------------------------

func _draw_badge(ci: CanvasItem) -> void:
	var k := _k()
	var c := _centre()
	# Wings of ribbon behind the shield.
	for sgn in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(150, -40), Vector2(300, -10), Vector2(262, 50), Vector2(312, 110), Vector2(150, 90)])
		var outline := PackedVector2Array([Vector2(140, -54), Vector2(326, -18), Vector2(284, 50), Vector2(340, 124), Vector2(140, 104)])
		Dot.poly(ci, _place(outline, c, k, sgn), INK)
		Dot.poly(ci, _place(wing, c, k, sgn), Color("e8325c"))
		Dot.poly(ci, _place(PackedVector2Array([Vector2(150, -40), Vector2(300, -10), Vector2(290, 6), Vector2(150, -18)]), c, k, sgn), Color("ff6b8c"))
	# The shield: ink outline, gold rim, violet face with a lit top.
	Dot.poly(ci, _place(_shield(1.08), c + Vector2(0, 10) * k, k), Color(0.1, 0.05, 0.2, .35))
	Dot.poly(ci, _place(_shield(1.06), c, k), INK)
	Dot.poly(ci, _place(_shield(1.0), c, k), GOLD)
	Dot.poly(ci, _place(_shield(.98), c + Vector2(0, 6) * k, k), Color("d98a12"))
	var face := _place(_shield(.86), c + Vector2(0, 6) * k, k)
	var cols := PackedColorArray()
	for q in face:
		cols.append(Color("8f6bff").lerp(Color("c42a8a"), clampf((q.y - (c.y - 180 * k)) / (420 * k), 0, 1)))
	ci.draw_polygon(face, cols)
	Dot.poly(ci, _place(_shield(.86).slice(0, 13), c + Vector2(0, 6) * k, k), Color(1, 1, 1, .1))
	# The mascot perched on top, crowned.
	var m := c + Vector2(0, -232) * k
	CritterArt.draw_critter(ci, "vampire", m, 74 * k, {"tier": 5, "look": Vector2(0.3, 0.6).normalized()})
	var crown := PackedVector2Array([Vector2(-42, 0), Vector2(-50, -46), Vector2(-22, -22), Vector2(0, -58), Vector2(22, -22), Vector2(50, -46), Vector2(42, 0)])
	var cp := m + Vector2(0, -66) * k
	Dot.poly(ci, _place(_grow(crown, 7), cp, k), INK)
	Dot.poly(ci, _place(crown, cp, k), Color("ffd23f"))
	for g in [Vector2(0, -12), Vector2(-26, -10), Vector2(26, -10)]:
		Dot.circle(ci, cp + g * k, 6 * k, Color("ff4f9a") if g.x == 0 else Color("4fd8ff"))
	# The title on a banner across the shield.
	var band := PackedVector2Array([Vector2(-236, -30), Vector2(236, -30), Vector2(226, 158), Vector2(-226, 158)])
	Dot.poly(ci, _place(_grow(band, 8), c, k), INK)
	Dot.poly(ci, _place(band, c, k), Color("ff3d6e"))
	Dot.poly(ci, _place(PackedVector2Array([Vector2(-236, -30), Vector2(236, -30), Vector2(234, 0), Vector2(-234, 0)]), c, k), Color("ff7a96"))
	Dot.poly(ci, _place(PackedVector2Array([Vector2(-228, 130), Vector2(228, 130), Vector2(226, 158), Vector2(-226, 158)]), c, k), Color("c21f4c"))
	_title(ci, "BATTLE", c + Vector2(0, 52) * k, 92 * k, Color.WHITE, Color("dcd2ff"))
	_title(ci, "BALLS", c + Vector2(0, 150) * k, 120 * k, Color("ffe066"), Color("ffab1f"))


## The shield outline, `s` times full size, top edge first (13 points), centred on (0, 0).
func _shield(s: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13: # A shallow arch across the top.
		var u := i / 12.0
		pts.append(Vector2(lerpf(-200, 200, u), -168 - sin(u * PI) * 34))
	for i in 10: # Right side bowing down to the point.
		var u := (i + 1) / 10.0
		pts.append(Vector2(200 * (1.0 - u * u) + 6 * sin(u * PI), lerpf(-168, 268, u) - 40 * sin(u * PI)))
	for i in range(8, -1, -1): # And the left side back up.
		var q: Vector2 = pts[13 + i]
		pts.append(Vector2(-q.x, q.y))
	for i in pts.size():
		pts[i] *= s
	return pts


func _grow(pts: PackedVector2Array, by: float) -> PackedVector2Array:
	var mid := Vector2.ZERO
	for q in pts:
		mid += q
	mid /= pts.size()
	var out := PackedVector2Array()
	for q in pts:
		out.append(q + (q - mid).normalized() * by)
	return out


func _place(pts: PackedVector2Array, at: Vector2, k: float, flip := 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(at + Vector2(q.x * flip, q.y) * k)
	return out


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
