## The loading screen: a painted scene in the Home / Bounce Run event-art
## style (tools/brand/loading_painted.mjs renders game/brand/loading.png).
## The live version main.gd fades out at start-up shows the same picture as
## the web page and the native boot splash, so the hand-off from the page to
## the game is seamless, then adds light movement on top: the moon's halo
## breathing, lamps flickering, the clash spark pulsing, stars twinkling and
## fireflies drifting. game/web/shell.html moves the same spots on the page.
##
## Cheap on battery: the picture is drawn once on a layer that never
## redraws; only the overlay moves, at 30 fps, and only for the second or
## two the screen is up. Render-only.
extends Control

const Dot := preload("res://game/dot.gd")
const A11y := preload("res://game/a11y.gd")
const ART := preload("res://game/brand/loading.png")
## Spots on the painting, in its own pixels (keep in step with
## loading_painted.mjs and shell.html). Glows: [spot, radius, colour, speed
## (Hz), flicker?]. A flicker glow wavers unevenly like a flame; the others
## breathe.
const GLOWS := [[Vector2(426, 740), 330.0, Color(.85, .95, 1), .35, false],
	[Vector2(426, 1000), 120.0, Color(1, .95, .7), 1.6, false],
	[Vector2(216, 1117), 46.0, Color(1, .83, .42), 2.3, true], [Vector2(636, 1117), 46.0, Color(1, .83, .42), 2.9, true],
	[Vector2(76, 1358), 64.0, Color(1, .83, .42), 2.6, true], [Vector2(776, 1358), 64.0, Color(1, .83, .42), 2.1, true]]
const TWINKLES := [Vector2(96, 560), Vector2(760, 520), Vector2(300, 610), Vector2(640, 600), Vector2(70, 160),
	Vector2(800, 200), Vector2(170, 860), Vector2(700, 880)]
## Fireflies rise through this band of the meadow.
const FIREFLY_BAND := [1040.0, 1700.0]
const FIREFLY := [Color("d8ff7a"), Color("7dffb0"), Color("ffe9a8")]
const FPS := 30
const HOLD := 1.1
const FADE := .4

## Shown once per run: coming back to the menu from a mode doesn't replay it.
static var played := false

var _t := 0.0
var _tick := -1
var _live: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_Layer.new(self, _draw_back))
	_live = _Layer.new(self, _draw_live)
	add_child(_live)
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


# The painting fills the screen like CSS object-fit: cover (as on the web
# page), cropped at the sides or ends.
func _art_scale() -> float:
	return maxf(size.x / ART.get_width(), size.y / ART.get_height())


## Screen position of a point on the painting.
func _art_at(q: Vector2) -> Vector2:
	var sc := _art_scale()
	return (size - ART.get_size() * sc) / 2.0 + q * sc


func _draw_back(ci: CanvasItem) -> void:
	ci.draw_texture_rect(ART, Rect2(_art_at(Vector2.ZERO), ART.get_size() * _art_scale()), false)


func _draw_live(ci: CanvasItem) -> void:
	var sc := _art_scale()
	var t := _t
	for g in GLOWS:
		var s: float = g[3]
		var pulse := .5 + .5 * sin(t * TAU * s)
		if g[4]: # A flame wavers: two beats out of step.
			pulse = clampf(.55 + .3 * sin(t * TAU * s) + .2 * sin(t * TAU * s * 2.7 + 1.3), 0.0, 1.0)
		var gc: Color = g[2]
		Dot.glow(ci, _art_at(g[0]), g[1] * sc * (.92 + .1 * pulse), Color(gc, .1 + .14 * pulse), .3)
	for i in TWINKLES.size():
		var tw := sin(t * 2.1 + i * 1.9)
		if tw > .35:
			_twinkle(ci, _art_at(TWINKLES[i]), 13 * sc * tw, Color(1, 1, .95, tw * .9))
	for i in 16:
		var f := fposmod(t * .1 + i * .137, 1.0)
		var x := fposmod(i * 131.0 + sin(t * .8 + i) * 24.0, ART.get_width())
		var at := _art_at(Vector2(x, lerpf(FIREFLY_BAND[1], FIREFLY_BAND[0], f)))
		var c: Color = FIREFLY[i % FIREFLY.size()]
		var a := sin(f * PI) * (.6 + .4 * sin(t * 5.0 + i))
		Dot.glow(ci, at, 14 * sc, Color(c, .35 * a), .2)
		Dot.circle(ci, at, (2.5 + i % 3) * sc, Color(c, .9 * a))


func _twinkle(ci: CanvasItem, p: Vector2, s: float, col: Color) -> void:
	Dot.poly(ci, PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * .22, -s * .22), p + Vector2(s, 0), p + Vector2(s * .22, s * .22),
		p + Vector2(0, s), p + Vector2(-s * .22, s * .22), p + Vector2(-s, 0), p + Vector2(-s * .22, -s * .22)]), col)


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
