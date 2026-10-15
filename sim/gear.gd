## Gear stat lines and how they reach a fight (power-progression.md section 4).
## A ball's gear is known setup, like its critter and tier, so a fight still
## replays from the seed and the launch angles alone.
##
## A gear piece is {slot, rarity, stats: {line: value}}. MatchSim takes each
## ball's gear as a list of pieces or as already summed stat totals; both go
## through totals(), which also clamps every line, so a tampered lineup can't
## bring 100% crit or full damage immunity.
extends RefCounted

## Every stat line a piece can roll. Values are what one Legendary piece with
## that line as its main stat gives; lower rarities give a share (RARITY).
## Each line is sized to be worth about +7% power, so two Legendary pieces are
## about the +15% "full best-in-slot" budget in power-progression.md section 5.
## `tools/balance.gd --gear` checks the lines against each other.
const LINES := {
	"attack": {"name": "Attack", "legendary": 0.07, "max": 0.35, "text": "+%d%% damage"},
	"health": {"name": "Health", "legendary": 0.07, "max": 0.35, "text": "+%d%% max HP"},
	"defense": {"name": "Defense", "legendary": 0.065, "max": 0.30, "text": "-%d%% damage taken"},
	"speed": {"name": "Speed", "legendary": 0.10, "max": 0.30, "text": "+%d%% move speed"},
	"crit_chance": {"name": "Crit", "legendary": 0.15, "max": 0.45, "text": "+%d%% crit chance"},
	"crit_damage": {"name": "Crit damage", "legendary": 0.6, "max": 2.0, "text": "+%d%% crit damage"},
	"cooldown": {"name": "Cooldown speed", "legendary": 0.25, "max": 0.50, "text": "+%d%% ability speed"},
}
const ORDER := ["attack", "health", "defense", "speed", "crit_chance", "crit_damage", "cooldown"]
## Share of the Legendary value each gear rarity gives.
const RARITY := {"common": 0.4, "uncommon": 0.55, "rare": 0.7, "epic": 0.85, "legendary": 1.0}
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


## A piece's value for `line` at `rarity`.
static func value(line: String, rarity: String) -> float:
	return LINES[line].legendary * RARITY.get(rarity, 1.0)


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
					# A named timer param (Wisp's phase_every) keeps its name.
					if e.secs is String:
						out[e.secs] = def[e.secs] / rate
					else:
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
