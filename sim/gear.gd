## Gear stat lines and how they reach a fight (power-progression.md section 4).
## A ball's gear is known setup, like its critter and tier, so a fight still
## replays from the seed and the launch angles alone.
##
## Pieces come in six types over three slots (PIECES) and five tiers. Three
## of the same type and tier merge into the next tier (meta/profile.gd), like
## critters (design/gear.md). In a fight a piece is {slot, tier, stats:
## {line: value}}. MatchSim takes each
## ball's gear as a list of pieces or as already summed stat totals; both go
## through totals(), which also clamps every line, so a tampered lineup can't
## bring 100% crit or full damage immunity.
extends RefCounted

## Every stat line a piece can carry. `t5` is what one 5-star piece with that
## line gives; lower tiers give a share (TIER_SHARE). Each line is sized to be
## worth about +5% power (PIECE_POWER), so three 5-star pieces (Shell, Core,
## Charm) are about the +15% "full best-in-slot" budget in
## power-progression.md section 5. `tools/balance.gd --gear` checks the lines
## against each other.
const LINES := {
	"attack": {"name": "Attack", "t5": 0.05, "max": 0.35, "text": "+%d%% damage"},
	"health": {"name": "Health", "t5": 0.05, "max": 0.35, "text": "+%d%% max HP"},
	"defense": {"name": "Defense", "t5": 0.046, "max": 0.30, "text": "-%d%% damage taken"},
	"speed": {"name": "Speed", "t5": 0.07, "max": 0.30, "text": "+%d%% move speed"},
	"crit_chance": {"name": "Crit", "t5": 0.105, "max": 0.45, "text": "+%d%% crit chance"},
	"crit_damage": {"name": "Crit damage", "t5": 0.43, "max": 2.0, "text": "+%d%% crit damage"},
	"cooldown": {"name": "Cooldown speed", "t5": 0.18, "max": 0.50, "text": "+%d%% ability speed"},
}
const ORDER := ["attack", "health", "defense", "speed", "crit_chance", "crit_damage", "cooldown"]
const MAX_TIER := 5
## Share of the 5-star value each tier gives (index 0 is 1 star).
const TIER_SHARE := [0.35, 0.5, 0.65, 0.8, 1.0]
## Power one 5-star piece adds to the Power Rating (+5%).
const PIECE_POWER := 0.05
const SLOTS := ["Shell", "Core", "Charm"]
## The Charm slot opens when the critter reaches this tier.
const CHARM_TIER := 3
## The six gear types: slot, and each line's share of its t5 value. Shares on
## a piece add up to 1, so every piece is worth the same power at a tier.
const PIECES := {
	"iron_shell": {"name": "Iron Shell", "slot": "Shell", "lines": {"defense": 1.0}, "glyph": "shell"},
	"bubble_shell": {"name": "Bubble Shell", "slot": "Shell", "lines": {"health": 1.0}, "glyph": "shell"},
	"spike_core": {"name": "Spike Core", "slot": "Core", "lines": {"attack": 1.0}, "glyph": "core"},
	"echo_core": {"name": "Echo Core", "slot": "Core", "lines": {"crit_chance": 0.5, "crit_damage": 0.5}, "glyph": "core"},
	"overclock_charm": {"name": "Overclock Charm", "slot": "Charm", "lines": {"cooldown": 1.0}, "glyph": "charm"},
	"jet_charm": {"name": "Jet Charm", "slot": "Charm", "lines": {"speed": 1.0}, "glyph": "charm"},
}
## Gear rarity before tiers (saves, old ghost lineups), as tiers.
const RARITY_TIERS := {"common": 1, "uncommon": 2, "rare": 3, "epic": 4, "legendary": 5}
const TYPES := ["iron_shell", "bubble_shell", "spike_core", "echo_core", "overclock_charm", "jet_charm"]
## Def keys that are ability timers; cooldown speed divides them, and the
## `secs` of "every" triggers.
const TIMER_SUFFIXES := ["_cooldown"]


## Summed, clamped stat lines for a ball's gear: a list of pieces, a totals
## dictionary, or null / empty for none. Unknown lines are dropped.
static func totals(gear) -> Dictionary:
	var sum := {}
	if gear is Array:
		for piece in gear:
			if piece is Dictionary:
				_add(sum, piece.get("stats", {}))
	elif gear is Dictionary:
		_add(sum, gear.get("stats", gear))
	for line in sum.keys():
		sum[line] = clampf(sum[line], 0.0, float(LINES[line].max))
	return sum


## A piece's value for `line` at `tier` (1-5), as its only line. An old gear
## rarity name works too (Common is 1 star up to Legendary 5 stars).
static func value(line: String, tier) -> float:
	return LINES[line].t5 * TIER_SHARE[tier_of(tier) - 1]


## A tier from a tier number or an old gear rarity name.
static func tier_of(tier) -> int:
	if tier is String:
		return RARITY_TIERS.get(tier, 1)
	return clampi(int(tier), 1, MAX_TIER)


## The stat lines a piece of `type` fights with at `tier`, rounded so they
## survive a save unchanged.
static func stats_for(type: String, tier: int) -> Dictionary:
	var out := {}
	var lines: Dictionary = PIECES[type].lines
	for line in lines:
		out[line] = roundf(value(line, tier) * float(lines[line]) * 10000.0) / 10000.0
	return out


## Power a piece adds at `tier`, as a fraction (+1.75% to +5%).
static func tier_power(tier: int) -> float:
	return PIECE_POWER * TIER_SHARE[tier_of(tier) - 1]


## Power some stat lines add, as a fraction: each line's share of its 5-star
## value times PIECE_POWER. Works for any pieces (an enemy's bare stats too),
## so the Power Rating always matches what fights.
static func stats_power(stats) -> float:
	var p := 0.0
	if stats is Dictionary:
		for line in stats:
			if LINES.has(line):
				p += PIECE_POWER * maxf(0.0, float(stats[line])) / float(LINES[line].t5)
	return p


## Power a worn gear list adds (pieces with `stats`), as a fraction.
static func gear_power(pieces: Array) -> float:
	var p := 0.0
	for piece in pieces:
		if piece is Dictionary:
			p += stats_power(piece.get("stats", {}))
	return p


## The def with gear's stat-sheet lines applied: health, speed and ability
## timers. Attack, defense and crit are per-hit and live on the Ball.
static func apply_def(def: Dictionary, t: Dictionary) -> Dictionary:
	if t.is_empty():
		return def
	var out := def.duplicate()
	out.hp = def.hp * (1.0 + t.get("health", 0.0))
	out.speed = def.speed * (1.0 + t.get("speed", 0.0))
	var rate: float = 1.0 + t.get("cooldown", 0.0)
	if rate != 1.0:
		for key in def:
			for suffix in TIMER_SUFFIXES:
				if String(key).ends_with(suffix):
					out[key] = def[key] / rate
		# "every" triggers (sim/abilities.gd) fire sooner too.
		if def.has("effects"):
			var effects: Array = def.effects.duplicate(true)
			for e in effects:
				if e.get("on") == "every":
					e.secs = float(e.secs) / rate
			out.effects = effects
	return out


## One line of shop/bag text for a piece's stats, e.g. "+7% damage, +12% crit chance".
static func describe(stats: Dictionary) -> String:
	var parts: Array[String] = []
	for line in ORDER:
		if stats.has(line):
			parts.append(LINES[line].text % roundi(100.0 * float(stats[line])))
	return ", ".join(parts)


static func _add(sum: Dictionary, stats) -> void:
	if not stats is Dictionary:
		return
	for line in stats:
		if LINES.has(line):
			sum[line] = sum.get(line, 0.0) + maxf(0.0, float(stats[line]))
