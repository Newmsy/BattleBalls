## The Glow Pass: one per season, 50 levels, a free track for everyone and a
## premium track of cosmetics and gems (design/monetisation.md §4).
##
## Pass XP comes from play only (fights, daily bounties, the weekly chest,
## Trick Shot). Levels are never sold. Every power reward (orbs, coins,
## energy, XP chips, the debut critter's copies) is on the free track; the
## premium track has none, so paying never makes anyone stronger.
extends RefCounted

const LEVELS := 50
const XP_PER_LEVEL := 1000
## After level 50: a bonus box every 2,000 XP, at most 10 a season.
const BONUS_XP := 2000
const BONUS_MAX := 10
const BONUS_BOX := [{"kind": "coins", "n": 500}, {"kind": "gems", "n": 5}]

## Pass XP for a fight, by result (design: any fight 10-30).
const FIGHT_XP := {"win": 30, "draw": 20, "loss": 10}
const TRICK_XP := 150

## Daily bounties (3 a day, 00:00 UTC) and the weekly chest. Each bounty is
## {id, kind, goal, xp, text}; kinds are counted by GlowState.record().
const BOUNTY_XP := 300
const BOUNTIES_PER_DAY := 3
const CHEST_XP := 1500
const CHEST_AFTER := 12 ## Bounties done in a week to open the chest.
const BOUNTY_POOL := [
	{"id": "play5", "kind": "fight", "goal": 5, "text": "Play 5 fights"},
	{"id": "win3", "kind": "win", "goal": 3, "text": "Win 3 fights"},
	{"id": "dmg600", "kind": "damage", "goal": 600, "text": "Deal 600 damage"},
	{"id": "trick", "kind": "trick", "goal": 1, "text": "Solve the Daily Trick Shot"},
	{"id": "play8", "kind": "fight", "goal": 8, "text": "Play 8 fights"},
	{"id": "win5", "kind": "win", "goal": 5, "text": "Win 5 fights"},
	{"id": "dmg1000", "kind": "damage", "goal": 1000, "text": "Deal 1,000 damage"},
]

## Premium cosmetics by level: the headline at level 1, the showpiece at 50.
const PREMIUM_COSMETICS := {1: "hat_halo", 10: "spark_neon", 20: "trail_synth", 30: "hat_visor", 40: "hat_horns", 50: "ko_fireworks"}
const FREE_COSMETICS := {5: "hat_cap", 15: "trail_comet", 30: "ko_stars"}
const DEBUT_LEVELS := [10, 25, 40]


## The free-track reward at `level` (1-50). `debut` is the season's debut
## critter id, or "" (then those levels give Summon Orbs instead).
static func free_reward(level: int, debut := "") -> Dictionary:
	if FREE_COSMETICS.has(level):
		return {"kind": "cosmetic", "id": FREE_COSMETICS[level]}
	if level in DEBUT_LEVELS:
		return {"kind": "copies", "id": debut, "n": 1} if debut != "" else {"kind": "orbs", "n": 3}
	if level in [20, 35, 45, 50]:
		return {"kind": "gems", "n": 25}
	if level == 1:
		return {"kind": "orbs", "n": 2}
	match level % 4:
		0:
			return {"kind": "xp_chip", "n": 2}
		1:
			return {"kind": "energy", "n": 20}
		2:
			return {"kind": "coins", "n": 300}
	return {"kind": "orbs", "n": 3}


## The premium-track reward at `level`, or {} for none. Cosmetics and gems only.
static func premium_reward(level: int) -> Dictionary:
	if PREMIUM_COSMETICS.has(level):
		return {"kind": "cosmetic", "id": PREMIUM_COSMETICS[level]}
	if level % 2 == 0:
		return {"kind": "gems", "n": 20}
	return {}


static func level_for(xp: int) -> int:
	return mini(LEVELS, xp / XP_PER_LEVEL)


## XP into the current level and the size of the level (for the bar).
static func progress(xp: int) -> Vector2i:
	if level_for(xp) >= LEVELS:
		var over := xp - LEVELS * XP_PER_LEVEL
		return Vector2i(over % BONUS_XP, BONUS_XP)
	return Vector2i(xp % XP_PER_LEVEL, XP_PER_LEVEL)


## Bonus boxes earned past level 50 (capped).
static func bonus_boxes(xp: int) -> int:
	return clampi((xp - LEVELS * XP_PER_LEVEL) / BONUS_XP, 0, BONUS_MAX)


## Today's bounties, picked from the pool by the day number so everyone gets
## the same three. "Play" always comes first; the other two rotate.
static func bounties_for(day: int) -> Array:
	var out := [BOUNTY_POOL[0] if day % 2 == 0 else BOUNTY_POOL[4]]
	var rest := [1, 2, 3, 5, 6]
	var a: int = rest[posmod(day, rest.size())]
	var b: int = rest[posmod(day * 3 + 2, rest.size())]
	if b == a or BOUNTY_POOL[b].kind == BOUNTY_POOL[a].kind:
		b = rest[posmod(rest.find(a) + 1, rest.size())]
	out.append(BOUNTY_POOL[a])
	out.append(BOUNTY_POOL[b])
	return out


## 2 in the finale weekend (last week of the season, Friday on), else 1.
static func xp_multiplier(season: Dictionary, t: int) -> int:
	if season.is_empty() or int(season.week) < int(season.weeks):
		return 1
	return 2 if t >= int(season.ends) - 3 * 86400 else 1
