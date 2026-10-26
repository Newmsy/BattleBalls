## How a fight looks before it starts, in one word: Easy, Close or Tough.
## Fights stay hands-off after the launch (Newms 2026-10-26, review choice
## 1D), so the screens before a fight say how power and family edges stack up
## and players can tell when to fuse up instead. Render-only: never read by
## the sim.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")

enum { TOUGH = -1, CLOSE = 0, EASY = 1 }

## One family edge step counts as this much power.
const EDGE_STEP := 0.12
## Power ahead (after edges) by this factor reads Easy; behind by it, Tough.
const MARGIN := 1.2

const WORDS := {TOUGH: "Tough", CLOSE: "Close", EASY: "Easy"}


## EASY, CLOSE or TOUGH for `mine` against `foe` power, with your family
## edge score (FamilyEdge.team, -2 to 2).
static func rate(mine: float, foe: float, edge := 0) -> int:
	if foe <= 0.0:
		return EASY
	var r := mine / foe * (1.0 + EDGE_STEP * clampi(edge, -2, 2))
	if r >= MARGIN:
		return EASY
	if r <= 1.0 / MARGIN:
		return TOUGH
	return CLOSE


static func word(rating: int) -> String:
	return WORDS[rating]


static func color(rating: int) -> Color:
	return {TOUGH: Kit.BAD, CLOSE: Kit.WARN, EASY: Kit.GOOD}[rating]


## A small pill with the word, in its colour.
static func chip(rating: int, font_size := 18) -> Control:
	var c := Kit.chip(word(rating), color(rating), font_size)
	# Solid fill so the word stays readable over painted rows.
	var st: StyleBoxFlat = (c.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	st.bg_color = Color(Kit.BG, .85)
	c.add_theme_stylebox_override("panel", st)
	return c
