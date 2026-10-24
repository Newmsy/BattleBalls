## The menus' shared motion: a button's squish, a pop, a cascade of cards, a
## number counting, icons flying to the top bar and screen slides. Every move
## is a short tween bound to the node it moves (freed with it), so the web
## build redraws only while something is moving. Nothing here holds input:
## a tap during a move lands on the real, already-built screen. With Reduced
## motion, slides, pops and bursts become short fades or nothing.
extends RefCounted

const A11y := preload("res://game/a11y.gd")

const PRESS_SCALE := .94
const PRESS_IN := .07
const PRESS_OUT := .22
const SLIDE_SECS := .22
const TAB_SECS := .18
const TAB_SHIFT := 36.0
const PARALLAX := .3 ## How far the screen underneath drifts during a slide (of the width).
const SHADE := .45
const CASCADE_GAP := .035
const CASCADE_MAX := 8 ## Cards after this many arrive together.


static func calm() -> bool:
	return A11y.reduced_motion


## Squish `b` while it is held and spring it back on release. The action
## itself still runs on release as before.
static func press(b: BaseButton) -> void:
	b.button_down.connect(func() -> void:
		if calm():
			return
		b.pivot_offset = b.size / 2.0
		_tween(b, "press").tween_property(b, "scale", Vector2(PRESS_SCALE, PRESS_SCALE), PRESS_IN).set_ease(Tween.EASE_OUT))
	b.button_up.connect(func() -> void:
		if b.scale == Vector2.ONE:
			return
		_tween(b, "press").tween_property(b, "scale", Vector2.ONE, PRESS_OUT).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


## Pop `c` from `from` scale to full size with an overshoot (a fade only with
## Reduced motion). `delay` waits first, invisible.
static func pop(c: Control, from := 0.0, secs := .3, delay := 0.0) -> Tween:
	var tw := _tween(c, "pop")
	if calm():
		c.modulate.a = 0.0
		tw.tween_interval(delay)
		tw.tween_property(c, "modulate:a", 1.0, .15)
		return tw
	c.scale = Vector2(from, from)
	if delay > 0.0:
		c.modulate.a = 0.0
		tw.tween_interval(delay)
		tw.tween_callback(func(): c.modulate.a = 1.0)
	tw.tween_method(func(s: float) -> void:
		c.pivot_offset = c.size / 2.0 # Laid out by now, even if it wasn't when the pop began.
		c.scale = Vector2(s, s), from, 1.0, secs).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw


## A quick swell and settle, e.g. a pill taking a coin. `base`: grow from the
## bottom edge (a tab icon hopping up) instead of the middle.
static func bump(c: Control, to := 1.18, secs := .22, base := false) -> void:
	if calm():
		return
	var tw := _tween(c, "bump")
	tw.tween_method(func(t: float) -> void:
		c.pivot_offset = Vector2(c.size.x / 2.0, c.size.y if base else c.size.y / 2.0)
		c.scale = Vector2.ONE * (1.0 + (to - 1.0) * sin(t * PI)), 0.0, 1.0, secs).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): c.scale = Vector2.ONE)


## Cards arriving one after another: each fades in from a little smaller,
## CASCADE_GAP apart. Scale and alpha only, so containers keep their layout.
static func cascade(cards: Array) -> float:
	var shown := 0
	for c in cards:
		if not (c is Control) or not c.visible:
			continue
		var delay := CASCADE_GAP * mini(shown, CASCADE_MAX)
		shown += 1
		c.modulate.a = 0.0
		var tw := _tween(c, "cascade")
		tw.tween_interval(delay)
		if calm():
			tw.tween_property(c, "modulate:a", 1.0, .12)
			continue
		c.scale = Vector2(.96, .96)
		tw.tween_method(func(t: float) -> void:
			c.pivot_offset = c.size / 2.0
			c.modulate.a = t
			c.scale = Vector2.ONE * lerpf(.96, 1.0, t), 0.0, 1.0, .2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	return CASCADE_GAP * mini(shown, CASCADE_MAX) + .2


## Count `label` from one number to another; `fmt` turns a number into its
## text (Kit.commas, "%d/%d"...).
static func count(label: Label, from: float, to: float, secs := .4, fmt := Callable()) -> void:
	var show := func(v: float) -> void:
		label.text = fmt.call(roundi(v)) if fmt.is_valid() else str(roundi(v))
	if calm() or is_equal_approx(from, to):
		show.call(to)
		return
	_tween(label, "count").tween_method(show, from, to, secs).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## A flash of colour that fades back to normal (a pill's gain, a value changing).
static func flash(c: CanvasItem, col := Color(1.6, 1.5, 1.0), secs := .35) -> void:
	c.modulate = col
	_tween(c, "flash").tween_property(c, "modulate", Color.WHITE, secs)


## `n` icons (from `make_icon`) burst out of `from` and arc into `to` (global
## positions), on `layer`. `on_land(k)` runs as icon k lands. Returns how long
## it takes. With Reduced motion one icon lands at once.
static func fly(layer: Control, make_icon: Callable, from: Vector2, to: Vector2, n: int, on_land: Callable) -> float:
	if calm():
		on_land.call(0)
		return 0.0
	var base := layer.get_global_rect().position
	var total := 0.0
	for k in n:
		var icon: Control = make_icon.call()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(icon)
		var half: Vector2 = icon.custom_minimum_size / 2.0
		var a := from - base - half
		var b := to - base - half
		var spread := Vector2(randf_range(-110.0, 110.0), randf_range(-90.0, -30.0))
		var mid := a + spread
		icon.position = a
		icon.scale = Vector2(.6, .6)
		var delay := .045 * k
		var secs := .58
		total = maxf(total, delay + secs)
		var tw := icon.create_tween()
		tw.tween_interval(delay)
		# Out to a scattered point, then curving into the pill (a quadratic arc).
		tw.tween_method(func(t: float) -> void:
			var burst := clampf(t / .3, 0.0, 1.0)
			var p := a.lerp(mid, 1.0 - pow(1.0 - burst, 2.0))
			if t > .3:
				var u := (t - .3) / .7
				var ctrl := mid + Vector2(0.0, -60.0)
				p = mid.lerp(ctrl, u).lerp(ctrl.lerp(b, u), u * u)
			icon.position = p
			icon.scale = Vector2.ONE * (lerpf(.6, 1.15, burst) if t < .3 else lerpf(1.15, .8, (t - .3) / .7)), 0.0, 1.0, secs)
		tw.tween_callback(func():
			icon.queue_free()
			on_land.call(k))
	return total


## A plain picture of part of a whole-screen texture, `rect` in screen units.
static func picture(tex: Texture2D, rect: Rect2, screen: Vector2) -> TextureRect:
	var k := Vector2(tex.get_size()) / screen
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = Rect2(rect.position * k, rect.size * k)
	var r := TextureRect.new()
	r.texture = a
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## One tween per node and purpose: a new one replaces the last (a second tap
## mid-squish restarts it instead of fighting it).
static func _tween(c: Node, key: String) -> Tween:
	var meta := "motion_" + key
	var old = c.get_meta(meta) if c.has_meta(meta) else null
	if old is Tween and old.is_valid():
		old.kill()
	var tw := c.create_tween()
	c.set_meta(meta, tw)
	return tw
