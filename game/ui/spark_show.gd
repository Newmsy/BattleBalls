## The Ascension Spark moment (Newms 2026-11-03: "ensure there's an
## animation for it when you get the spark"): whenever Sparks arrive (a
## chest, a Spire boss floor, a family talent level past 30), the shell
## plays this once over whatever screen you land on. A violet glow blooms,
## the four-point Spark spins in big, a ring of little sparks bursts out,
## then "+1 ASCENSION SPARK" and how far you are to the next Ascension.
## Over the shell's fx layer: taps pass straight through, it fades itself
## out after about 2.5s and frees itself. One Control drawn with plain
## shapes; it stops redrawing once it's gone.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Motion := preload("res://game/ui/motion.gd")
const AscendShow := preload("res://game/ui/ascend_show.gd")

const LIFE := 2.6
const IN := .45 ## The big Spark lands.
const BURST := .8

var t := 0.0
var n := 1
var have := 0
var need := 10
var _words: Control


## Plays the moment for `count` new Sparks over `shell`. `have`: Sparks held now.
static func play(shell, count: int, have_: int, need_: int) -> Control:
	var s = load("res://game/ui/spark_show.gd").new()
	s.n = count
	s.have = have_
	s.need = need_
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell._fx.add_child(s)
	s._build()
	print("SPARK_SHOW n=%d have=%d" % [count, have_])
	if shell.sfx != null:
		shell.sfx.play("summon_pop", 0.0, 1.25)
		shell.sfx.play("twinkle", -4.0, 1.1)
	return s


func _build() -> void:
	var title := Kit.label("+%d ASCENSION SPARK%s" % [n, "" if n == 1 else "S"], 40, Glyph.PURPLE.lightened(.35), HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color("1a0b33"))
	var sub := Kit.label("%d / %d to ascend" % [have, need] if have < need else "Ready to ascend!", 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	sub.add_theme_constant_override("outline_size", 8)
	sub.add_theme_color_override("font_outline_color", Color("1a0b33"))
	_words = Kit.vbox(4, [title, sub])
	_words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_words.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_words.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_words.grow_vertical = Control.GROW_DIRECTION_BOTH
	_words.position.y += 150
	_words.modulate.a = 0.0
	add_child(_words)
	if Motion.calm():
		t = IN + BURST
		_words.modulate.a = 1.0


func _process(delta: float) -> void:
	t += delta
	if t >= IN * .8 and _words.modulate.a == 0.0:
		var tw := _words.create_tween()
		tw.tween_property(_words, "modulate:a", 1.0, .25)
		_words.pivot_offset = _words.size / 2.0
		_words.scale = Vector2(.6, .6)
		tw.parallel().tween_property(_words, "scale", Vector2.ONE, .35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if t >= LIFE:
		queue_free()
		return
	modulate.a = clampf((LIFE - t) / .4, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0 - Vector2(0, 40)
	var p := clampf(t / IN, 0.0, 1.0)
	var land := 1.0 - pow(1.0 - p, 3.0)
	var over := sin(p * PI) * .18 # A little overshoot as it lands.
	# A dark violet wash under it so it reads over any screen, then the glow.
	draw_rect(Rect2(Vector2.ZERO, size), Color(.03, .01, .08, .55 * land))
	AscendShow._glow(self, c, 520.0 * land, Color(.05, .02, .12, .7))
	AscendShow._glow(self, c, 300.0 * land + 20.0 * sin(t * 6.0), Color(Glyph.PURPLE, .55))
	# The burst ring of little sparks.
	var b := clampf((t - IN * .7) / BURST, 0.0, 1.0)
	if b > 0.0 and b < 1.0:
		for k in 14:
			var a := TAU * k / 14.0 + .3
			var d := 90.0 + 230.0 * (1.0 - pow(1.0 - b, 2.0))
			var s := (1.0 - b) * (16.0 if k % 2 else 10.0) + 2.0
			draw_colored_polygon(AscendShow._star(c + Vector2(cos(a), sin(a)) * d, s, 4, a), Color("ffd25a") if k % 3 == 0 else Glyph.PURPLE.lightened(.4))
	# The big Spark: spins in, then breathes.
	var size_ := 110.0 * (land + over) * (1.0 + .04 * sin(t * 5.0))
	var rot := (1.0 - land) * PI * 1.5
	draw_colored_polygon(AscendShow._star(c, size_ * 1.15, 4, rot), Color(Glyph.PURPLE.darkened(.3), .9))
	draw_colored_polygon(AscendShow._star(c, size_, 4, rot), Glyph.PURPLE.lightened(.25))
	draw_colored_polygon(AscendShow._star(c, size_ * .45, 4, rot), Color(1, 1, 1, .9))
