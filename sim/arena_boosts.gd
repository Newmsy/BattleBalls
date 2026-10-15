## Arena Boosts: small per-family stat upgrades bought with Arena Points, which
## come only from trophies won in the Ghost Arena (game/pvp/arena_store.gd).
## Never sold. Each family (sim/families.gd) has four lines of five levels;
## a fully boosted family is worth about +6% power, so a higher tier still
## wins (BALANCE.md).
##
## A boost reaches a fight as `boost` in the lineup slot (sim/lineup.gd): the
## stat lines it adds, in sim/gear.gd's line names. MatchSim sums them with
## the ball's gear, so fights still replay from the slots, the seed and the
## launch angles. Practice modes and Even Arena never carry it.
extends RefCounted

const Families := preload("res://sim/families.gd")

const MAX_LEVEL := 5
## What level 5 of each line gives (gear.gd line names), and the share of
## Power it is worth at level 5. Each line is about +1.5% power at full.
const LINES := {
	"health": {"name": "Health", "max": 0.015, "text": "+%s%% max HP", "short": "HP"},
	"attack": {"name": "Attack", "max": 0.015, "text": "+%s%% damage", "short": "ATK"},
	"defense": {"name": "Defense", "max": 0.014, "text": "-%s%% damage taken", "short": "DEF"},
	"speed": {"name": "Speed", "max": 0.021, "text": "+%s%% move speed", "short": "SPD"},
}
const ORDER := ["health", "attack", "defense", "speed"]
const LINE_POWER := 0.015 ## Power one line adds at level 5.
## Arena Points for the next level: level 1 costs 20, level 5 costs 100, so a
## line is 300 points and a family 1,200. A win is 18 to 35 trophies.
const COST_STEP := 20


static func cost(next_level: int) -> int:
	return COST_STEP * next_level


## The stat lines one family's levels ({line: level}) add.
static func stats(levels: Dictionary) -> Dictionary:
	var out := {}
	for line in ORDER:
		var lv := clampi(int(levels.get(line, 0)), 0, MAX_LEVEL)
		if lv > 0:
			out[line] = LINES[line].max * (float(lv) / MAX_LEVEL)
	return out


## A boost read from a slot, every line clamped to its level-5 value, so a
## tampered lineup can't bring more than a fully boosted family.
static func clean(boost) -> Dictionary:
	var out := {}
	if boost is Dictionary:
		for line in ORDER:
			if boost.has(line):
				var v := clampf(float(boost[line]), 0.0, float(LINES[line].max))
				if v > 0.0:
					out[line] = v
	return out


## Power share a boost adds (0.06 at full), for the Power Rating.
static func power(boost: Dictionary) -> float:
	var p := 0.0
	for line in boost:
		if LINES.has(line):
			p += LINE_POWER * float(boost[line]) / float(LINES[line].max)
	return p


## "+0.9%" style text for a line at a level.
static func text(line: String, level: int) -> String:
	var pct: float = 100.0 * LINES[line].max * (float(level) / MAX_LEVEL)
	return LINES[line].text % String.num(pct, 1).trim_suffix(".0")


static func family_level(levels: Dictionary) -> int:
	var n := 0
	for line in ORDER:
		n += clampi(int(levels.get(line, 0)), 0, MAX_LEVEL)
	return n
