## How a gear tier looks and reads everywhere: 1-5 stars climb the rarity
## ladder (grey to gold), then Emberforged 1-5 (tiers 6-10) each get their own
## look, up to a rainbow (Newms 2026-11-05): ruby, sunset (ruby-topaz), ocean
## (jade-sky), blossom (rose-sun), then rainbow bands. An Emberforged piece shows five stars, each forged one
## (from the left) in its level's colour, so Emberforged 5 shows a rainbow
## row. The painted pieces use the same colours
## (tools/event_art/scenes/gear_pieces.mjs FORGE).
extends RefCounted

const Gear := preload("res://sim/gear.gd")
const Roster := preload("res://game/ui/roster.gd")

const RUBY := Color("e8203e")
const TOPAZ := Color("ff9a1a")
const SUN := Color("ffe14a")
const JADE := Color("1ee0a8")
const SKY := Color("4fc3ff")
const ROSE := Color("ff6ad0")
## Each forged level's colours (its gradient or bands), then a rainbow.
const LADDER := [[RUBY], [RUBY, TOPAZ], [JADE, SKY], [ROSE, SUN], [RUBY, TOPAZ, SUN, JADE, SKY, ROSE]]
## The star each forged level lights, from the left (an Emberforged 5 row is a rainbow).
const STAR_COLORS := [RUBY, TOPAZ, SKY, ROSE, SUN]
## Rims and names: the colour a level added; the rainbow level reads near-white.
const COLORS := [RUBY, TOPAZ, SKY, ROSE, Color("fff2fb")]
const NAME := "Emberforged"


## True for tiers past 5 stars.
static func forged(tier: int) -> bool:
	return tier > Gear.STAR_TIERS


## Forged level 1-5 (0 below it).
static func level(tier: int) -> int:
	return maxi(0, tier - Gear.STAR_TIERS)


## The rim and text colour of a tier: the rarity ladder, then each forged level's colour.
static func color(tier: int) -> Color:
	if forged(tier):
		return COLORS[clampi(level(tier), 1, 5) - 1]
	return Roster.RARITY_COLORS[Gear.RARITY_TIERS.keys()[clampi(tier, 1, Gear.STAR_TIERS) - 1]]


## The colours a forged tier's gradient runs through (one for star tiers).
static func colors(tier: int) -> Array:
	return LADDER[clampi(level(tier), 1, 5) - 1] if forged(tier) else [color(tier)]


## The bright core of a forged tier's stars and sparks.
static func hot(tier: int) -> Color:
	return color(tier).lerp(Color.WHITE, .6)


## "3-star" or "Emberforged 2".
static func label(tier: int) -> String:
	return "%s %d" % [NAME, level(tier)] if forged(tier) else "%d-star" % tier


## "3-star Iron Shell" or "Emberforged 2 Iron Shell".
static func piece_name(tier: int, name: String) -> String:
	return "%s %s" % [label(tier), name]
