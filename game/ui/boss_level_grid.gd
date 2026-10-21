## The 15 boss levels (meta/boss_levels.gd) as a compact 5 x 3 grid: beaten
## levels starred, the next one open, the rest locked. Tapping an open level
## picks it (the screen rebuilds with params.level); the screen shows one card
## for the picked level with its single Fight button. Fits with the rest of a
## boss screen on one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const BossLevels := preload("res://meta/boss_levels.gd")


## Below this screen height (an iPhone SE) the boss screen has no room for a hero.
const HERO_MIN_HEIGHT := 1400.0


## The boss itself, big, at the top of its screen: the reason to visit. Left
## out on short phones so the Fight button stays on screen.
static func hero(shell, boss_id: String, accent: Color) -> Control:
	if shell.size.y < HERO_MIN_HEIGHT:
		return Control.new()
	var c := CenterContainer.new()
	c.add_child(load("res://game/boss_art.gd").icon(boss_id, 230))
	return Kit.panel(c, Kit.box(Color(accent, .08), Color(accent, .25), 40, 2, 6))


## The level a boss screen shows: params.level if it's open, else the highest open one.
static func picked(profile, key: String, params: Dictionary) -> int:
	var d := int(params.get("level", -1))
	return d if BossLevels.is_open(profile, key, d) else BossLevels.top_open(profile, key)


## The grid; marks each cell `<prefix>_lv<N>`.
static func grid(shell, profile, key: String, picked_level: int, accent: Color, prefix: String) -> Control:
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	var beaten := BossLevels.beaten(profile, key)
	for d in BossLevels.COUNT:
		var open := BossLevels.is_open(profile, key, d)
		var on := d == picked_level
		var face: Control
		if open:
			face = Kit.label("%d" % (d + 1), 26, Kit.FG if on or d >= beaten else Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			face = Glyph.make("lock", 22, Kit.MUTED)
		var cell := Kit.hbox(4, [face], BoxContainer.ALIGNMENT_CENTER)
		cell.custom_minimum_size.y = 44.0 ## Locked and open cells the same height.
		if d < beaten:
			cell.add_child(Glyph.make("stars", 14, Kit.GOOD, 1))
		var bg := accent.darkened(0.45) if on else (Kit.PANEL2 if open else Kit.PANEL)
		var border := accent if on else (Color(accent, 0.4) if open else Kit.PANEL2)
		var tap := (func(): shell.refresh_with({"level": d})) if open else (func(): shell.toast("Beat level %d to open level %d." % [d, d + 1]))
		var b := Kit.card_button(cell, tap, border, bg, 20, 8)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("%s_lv%d" % [prefix, d + 1], b)
		g.add_child(b)
	return g
