## The weekly Arena chest (Newms 2026-10-26): the best league you reach in a
## week (Monday to Sunday, UTC) opens that league's chest once the week is
## over. Any week you visit the Arena counts (attacks and defence raids), and
## an unopened chest waits until the next one replaces it. Tokens go to the
## Bazaar (ArenaStore.coins); the rest are Profile.grant() rewards. Kept well
## inside the Arena's slice of the power budget: mostly coins and eggs, one
## 2-star gear piece at the top.
extends RefCounted

const Ladder := preload("res://game/pvp/ladder.gd")
const Gear := preload("res://sim/gear.gd")
const Rng := preload("res://sim/rng.gd")

## One per league (Ladder.LEAGUES order). `art` is the painted chest
## (game/bounce_run/art/chest_<art>_*.png); `tint` recolours a shared one.
const CHESTS := [
	{"art": "bronze", "rewards": [{"kind": "tokens", "n": 40}, {"kind": "coins", "n": 300}, {"kind": "orbs", "n": 1}]},
	{"art": "silver", "rewards": [{"kind": "tokens", "n": 60}, {"kind": "coins", "n": 450}, {"kind": "orbs", "n": 1}, {"kind": "hammers", "n": 1}]},
	{"art": "gold", "rewards": [{"kind": "tokens", "n": 80}, {"kind": "coins", "n": 600}, {"kind": "orbs", "n": 2}, {"kind": "hammers", "n": 1}]},
	{"art": "crystal", "tint": Color(0.75, 1.15, 0.85), "rewards": [{"kind": "tokens", "n": 100}, {"kind": "coins", "n": 800}, {"kind": "orbs", "n": 3}, {"kind": "hammers", "n": 1}, {"kind": "energy", "n": 30}]},
	{"art": "crystal", "rewards": [{"kind": "tokens", "n": 130}, {"kind": "coins", "n": 1000}, {"kind": "orbs", "n": 4}, {"kind": "hammers", "n": 2}, {"kind": "energy", "n": 40}]},
	{"art": "champion", "rewards": [{"kind": "tokens", "n": 160}, {"kind": "coins", "n": 1200}, {"kind": "orbs", "n": 5}, {"kind": "hammers", "n": 2}, {"kind": "gear", "tier": 2}]},
]


## This week's number: whole weeks since the Monday before 1970-01-01.
static func week_of(unix: float) -> int:
	return int(floor((unix / 86400.0 + 3.0) / 7.0))


static func this_week() -> int:
	return week_of(Time.get_unix_time_from_system())


## Seconds until this week's chest locks in (next Monday 00:00 UTC).
static func seconds_left(unix: float = Time.get_unix_time_from_system()) -> int:
	var end := ((week_of(unix) + 1) * 7 - 3) * 86400.0
	return maxi(0, int(end - unix))


## "3d 4h", "5h 12m" or "9m".
static func time_text(seconds: int) -> String:
	var d := seconds / 86400
	var h := (seconds % 86400) / 3600
	var m := (seconds % 3600) / 60
	if d > 0:
		return "%dd %dh" % [d, h]
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm" % maxi(1, m)


## How the chest for `league` looks, for ChestArt and the opening show.
static func look(league: int) -> Dictionary:
	var lg: Dictionary = Ladder.LEAGUES[league]
	var c: Dictionary = CHESTS[league]
	var out := {"id": c.art, "name": "%s Chest" % lg.name, "color": lg.color}
	if c.has("tint"):
		out.tint = c.tint
	return out


## What `league`'s chest from `week` holds; the gear piece's type comes from
## the week.
static func rewards(league: int, week: int) -> Array:
	var out: Array = []
	for r in CHESTS[league].rewards:
		var g: Dictionary = r.duplicate()
		if g.kind == "gear":
			var types := Gear.PIECES.keys()
			types.sort()
			g.type = types[Rng.new(week * 7919 + 3).range_int(0, types.size() - 1)]
		out.append(g)
	return out


## Opens the store's waiting chest into `profile` and the store. Returns
## the rewards given (empty when there is none).
static func open(store, profile) -> Array:
	store.roll_week()
	if store.chest.is_empty():
		return []
	var got := rewards(int(store.chest.league), int(store.chest.week))
	for r in got:
		if r.kind == "tokens":
			store.coins += int(r.n)
			store.coins_earned += int(r.n)
		elif profile != null:
			profile.grant(r)
	store.chest = {}
	store.save()
	return got
