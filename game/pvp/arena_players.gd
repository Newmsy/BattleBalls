## Real players in the Ghost Arena (Newms 2026-10-26): your Defence trio is
## saved online (public.arena_defences, with your Arena trophies) for others
## to fight, and other players' squads near your trophies are fetched to mix
## in with the seeded teams, under their own names. A squad is a full lineup,
## so a fight against it replays like any team. Offline, or before anyone
## else has a squad, the list is all seeded teams (never labelled as CPU).
extends RefCounted

const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const MatchSim := preload("res://sim/match_sim.gd")
const Lineup := preload("res://sim/lineup.gd")
const Families := preload("res://sim/families.gd")
const ArenaTeams := preload("res://game/pvp/arena_teams.gd")

## Opponents on the Arena list, and at most how many of them are players.
const LIST_SIZE := ArenaTeams.OFFER_COUNT
const MAX_PLAYERS := 6

## Fetched squads as Arena teams (squad()), nearest your trophies first.
static var pool: Array = []
## What pool was fetched for: "day|refresh|trophies to the nearest 50".
static var _key := ""
static var _busy := false
## The last defence saved online this session (so an Arena visit with
## nothing changed sends nothing).
static var _saved := ""


## The Arena list: today's seeded teams with the fetched players in among
## them, LIST_SIZE in all, weakest (fewest trophies) first.
static func offers(trophies: int, day: int, refresh: int, players = null) -> Array[Dictionary]:
	var mine: Array = (pool if players == null else players).slice(0, MAX_PLAYERS)
	var out: Array[Dictionary] = ArenaTeams.offers(trophies, day, refresh, LIST_SIZE - mine.size())
	if mine.is_empty():
		return out
	for p in mine:
		out.append({"card": "seeded", "bot": (p as Dictionary).duplicate(true)})
	out.sort_custom(func(a, b): return int(a.bot.trophies) < int(b.bot.trophies))
	return out


## One player's squad from an arena_opponents row, as an Arena team, or {}
## when this client can't fight it.
static func squad(row) -> Dictionary:
	if not row is Dictionary or not GhostLineup.is_playable(row.get("lineup")):
		return {}
	var lineup: Dictionary = row.lineup
	if (lineup.slots as Array).size() != 3:
		return {}
	var slots: Array = []
	var aims: Array = []
	for s in lineup.slots:
		var c := Lineup.clean(s)
		c.aim = clampi(int(s.get("aim", 0)), -GhostLineup.MAX_AIM_OFFSET, GhostLineup.MAX_AIM_OFFSET)
		aims.append(c.aim)
		slots.append(c)
	var name := str(row.get("name", "")).strip_edges().left(20)
	return {
		"id": "player-" + str(row.get("id", "")),
		"name": name if name.length() >= 2 else "Player",
		"family": main_family(slots),
		"player": true,
		"trophies": clampi(int(row.get("trophies", 0)), 0, 20000),
		"lineup": {"v": 1, "slots": slots, "aim": aims},
	}


## The family most of a squad comes from (the first critter's on a tie), for
## its colour and home painting.
static func main_family(slots: Array) -> String:
	var count := {}
	var best := ""
	for s in slots:
		var f := Families.of(str(s.critter))
		count[f] = int(count.get(f, 0)) + 1
		if best == "" or count[f] > count[best]:
			best = f
	return best


## Saves your Defence trio online (once you have fought in the Arena) and
## fetches squads near your trophies; `on_new` runs when the list changed.
static func sync(backend, store, profile, on_new: Callable) -> void:
	if backend == null or not backend.enabled() or _busy:
		return
	var day: int = store.today()
	var refresh: int = store.refreshes if store.refresh_day == day else 0
	var key := "%d|%d|%d" % [day, refresh, int(store.trophies) / 50]
	var lineup: Dictionary = store.lineup(profile, "defence")
	lineup.rules = MatchSim.RULES_VERSION
	var saved := JSON.stringify([lineup, store.trophies], "", true)
	var publish: bool = int(store.wins) + int(store.losses) > 0 and saved != _saved
	if key == _key and not publish:
		return
	_busy = true
	if not await backend.ensure_session():
		_busy = false
		return
	if publish:
		var row := {"user_id": backend.user_id(), "lineup": lineup, "rules_version": MatchSim.RULES_VERSION,
			"trophies": clampi(int(store.trophies), 0, 20000), "power": store.power(profile, "defence"),
			"updated_at": Time.get_datetime_string_from_system(true) + "Z"}
		var res: Dictionary = await backend.rest("POST", "/rest/v1/arena_defences", row,
			["Prefer: resolution=merge-duplicates,return=minimal"])
		if res.ok:
			_saved = saved
	var changed := false
	if key != _key:
		var res: Dictionary = await backend.call_rpc("arena_opponents",
			{"p_trophies": int(store.trophies), "p_rules": MatchSim.RULES_VERSION, "p_count": MAX_PLAYERS})
		if res.ok and res.data is Array:
			_key = key
			var got: Array = []
			for r in res.data:
				var t := squad(r)
				if not t.is_empty():
					got.append(t)
			changed = got != pool
			pool = got
	_busy = false
	if changed and on_new.is_valid():
		on_new.call()
