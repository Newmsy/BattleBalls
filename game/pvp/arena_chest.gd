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
const ChestDrops := preload("res://meta/chest_drops.gd")

## One per league (Ladder.LEAGUES order). `art` is the painted chest
## (game/bounce_run/art/chest_<art>_*.png); `tint` recolours a shared one.
## Rewards are ChestDrops tables: ranges and chances, doubled on 2026-11-03
## because the chest only opens once a week (Newms).
const CHESTS := [
	{"art": "bronze", "rewards": [{"kind": "tokens", "lo": 50, "hi": 110, "step": 10}, {"kind": "coins", "lo": 400, "hi": 800, "step": 50}, {"kind": "orbs", "lo": 1, "hi": 3}]},
	{"art": "silver", "rewards": [{"kind": "tokens", "lo": 80, "hi": 160, "step": 10}, {"kind": "coins", "lo": 600, "hi": 1200, "step": 50}, {"kind": "orbs", "lo": 1, "hi": 3}, {"kind": "hammers", "lo": 1, "hi": 3}]},
	{"art": "gold", "rewards": [{"kind": "tokens", "lo": 120, "hi": 200, "step": 10}, {"kind": "coins", "lo": 800, "hi": 1600, "step": 50}, {"kind": "orbs", "lo": 2, "hi": 6}, {"kind": "hammers", "lo": 1, "hi": 3}]},
	{"art": "crystal", "tint": Color(0.75, 1.15, 0.85), "rewards": [{"kind": "tokens", "lo": 140, "hi": 260, "step": 10}, {"kind": "coins", "lo": 1000, "hi": 2200, "step": 50}, {"kind": "orbs", "lo": 4, "hi": 8}, {"kind": "hammers", "lo": 1, "hi": 3}, {"kind": "energy", "lo": 40, "hi": 80, "step": 10}]},
	{"art": "crystal", "rewards": [{"kind": "tokens", "lo": 180, "hi": 340, "step": 10}, {"kind": "coins", "lo": 1400, "hi": 2600, "step": 50}, {"kind": "orbs", "lo": 5, "hi": 11}, {"kind": "hammers", "lo": 2, "hi": 6}, {"kind": "energy", "lo": 50, "hi": 110, "step": 10}]},
	{"art": "champion", "rewards": [{"kind": "tokens", "lo": 220, "hi": 420, "step": 10}, {"kind": "coins", "lo": 1600, "hi": 3200, "step": 50}, {"kind": "orbs", "lo": 6, "hi": 14}, {"kind": "hammers", "lo": 2, "hi": 6}, {"kind": "gear", "n": 2, "tier": 2}]},
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


## Each Arena mode has its own weekly chest (Newms 2026-11-03): the same
## drops, a look of its own. The League's chests are cooled towards its cyan
## and both carry their mode's badge (arena_chests_screen.gd chest_art).
const MODE_LOOK := {
	"series": {"badge": "3v3", "badge_color": Color("ff4fd8"), "tint": Color(1, 1, 1)},
	"league": {"badge": "2v2", "badge_color": Color("27c8ff"), "tint": Color(0.78, 1.0, 1.22)},
}


## How `mode`'s chest for `league` looks, for ChestArt and the opening show.
static func look(league: int, mode := "series") -> Dictionary:
	var lg: Dictionary = Ladder.LEAGUES[league]
	var c: Dictionary = CHESTS[league]
	var m: Dictionary = MODE_LOOK.get(mode, MODE_LOOK.series)
	var out := {"id": c.art, "name": "%s Chest" % lg.name, "color": lg.color, "badge": m.badge, "badge_color": m.badge_color}
	var tint: Color = c.get("tint", Color(1, 1, 1)) * m.tint
	if tint != Color(1, 1, 1):
		out.tint = tint
	return out


## The week number `mode`'s rewards roll from, so the two modes' chests in
## one week roll differently (the 3v3 Series keeps the plain week).
static func roll_week(week: int, mode := "series") -> int:
	return week if mode == "series" else week + 100003


## Chance (out of 100) each league's chest also holds an Ascension Spark: up
## to 10% at the top league (Newms 2026-11-02).
const SPARK_CHANCE := [2, 4, 5, 6, 8, 10]


## The drop table `league`'s chest shows: its items, then the Spark chance.
static func odds(league: int) -> Array:
	var out: Array = CHESTS[league].rewards.duplicate()
	out.append({"kind": "spark", "n": 1, "pct": int(SPARK_CHANCE[league])})
	return out


## What `league`'s chest from `week` holds for the player with chest `salt`
## (Profile.chest_seed(); 0 = the plain roll).
static func rewards(league: int, week: int, salt := 0) -> Array:
	var out := ChestDrops.roll(odds(league), ChestDrops.salted(week * 6151 + 17, salt))
	for g in out:
		if g.kind == "gear":
			var types := Gear.PIECES.keys()
			types.sort()
			g.type = types[Rng.new(ChestDrops.salted(week * 7919 + 3, salt)).range_int(0, types.size() - 1)]
	return out


## Opens the store's waiting chest (its current mode's) into `profile` and the store. Returns
## the rewards given (empty when there is none).
static func open(store, profile) -> Array:
	store.roll_week()
	if store.chest.is_empty():
		return []
	var got := rewards(int(store.chest.league), roll_week(int(store.chest.week), store.mode), profile.chest_seed() if profile != null else 0)
	for r in got:
		if r.kind == "tokens":
			store.coins += int(r.n)
			store.coins_earned += int(r.n)
		elif profile != null:
			profile.grant(r)
	store.chest = {}
	store.save()
	return got


## The season chest (Newms 2026-11-05): when a Glow Pass season ends, each
## Arena mode you played pays the chest of the best league you reached in
## it, with twice the weekly chest's items (the Spark chance stays).
static func season_look(league: int, mode := "series") -> Dictionary:
	var out := look(league, mode)
	out.name = "%s Season Chest" % Ladder.LEAGUES[league].name
	return out


## What the season chest for `league` from `season_name` holds (`mode` and
## the player's chest `salt` make each roll its own).
static func season_rewards(league: int, season_name: String, mode := "series", salt := 0) -> Array:
	var got := rewards(league, roll_week(absi(hash("season|" + season_name)) % 1000003 + 200003, mode), salt)
	for r in got:
		if r.kind != "gear" and r.kind != "spark" and r.has("n"):
			r.n = int(r.n) * 2
	return got


## Opens the store's season chest (its current mode's) into `profile` and
## the store. Returns the rewards given (empty when there is none).
static func open_season(store, profile) -> Array:
	if store.season_chest.is_empty():
		return []
	var c: Dictionary = store.season_chest
	var got := season_rewards(int(c.league), str(c.season), store.mode, profile.chest_seed() if profile != null else 0)
	for r in got:
		if r.kind == "tokens":
			store.coins += int(r.n)
			store.coins_earned += int(r.n)
		elif profile != null:
			profile.grant(r)
	store.season_chest = {}
	store.save()
	return got
