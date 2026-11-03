## How a gear tier looks and reads everywhere: 1-5 stars climb the rarity
## ladder (grey to gold), then Emberforged 1-5 (tiers 6-10) run hot ember red,
## a colour of their own (not the purple of critter Ascension). An
## Emberforged piece shows five stars with its forged ones lit ember from the
## left, like Ascension does for critters (Glyph "stars" past 5).
extends RefCounted

const Gear := preload("res://sim/gear.gd")
const Roster := preload("res://game/ui/roster.gd")

## The forged colour: tier rims, names and the ember stars.
const EMBER := Color("ff5a36")
## The white-hot core of an ember star and the forge sparks.
const HOT := Color("ffe39a")
const NAME := "Emberforged"


## True for tiers past 5 stars.
static func forged(tier: int) -> bool:
	return tier > Gear.STAR_TIERS


## Forged level 1-5 (0 below it).
static func level(tier: int) -> int:
	return maxi(0, tier - Gear.STAR_TIERS)


## The rim and text colour of a tier: the rarity ladder, then ember.
static func color(tier: int) -> Color:
	if forged(tier):
		return EMBER
	return Roster.RARITY_COLORS[Gear.RARITY_TIERS.keys()[clampi(tier, 1, Gear.STAR_TIERS) - 1]]


## "3-star" or "Emberforged 2".
static func label(tier: int) -> String:
	return "%s %d" % [NAME, level(tier)] if forged(tier) else "%d-star" % tier


## "3-star Iron Shell" or "Emberforged 2 Iron Shell".
static func piece_name(tier: int, name: String) -> String:
	return "%s %s" % [label(tier), name]
