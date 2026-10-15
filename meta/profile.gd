## The player's progress: collection stacks, fusion, energy, account level,
## currencies, gear and campaign stars. This is the save behind every menu
## (game/ui keeps the same API) and the campaign rules (meta/campaign.gd).
##
## Pure logic, no nodes: the clock is passed in as unix seconds so tests can
## drive it. It is stored inside the SaveGame (user:// plus cloud sync) as
## data.profile; `changed` fires after every change so the owner can persist.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")
const Power := preload("res://sim/power.gd")
const Gear := preload("res://sim/gear.gd")
const Lineup := preload("res://sim/lineup.gd")
const Analytics := preload("res://game/online/analytics.gd")
const Economy := preload("res://meta/economy.gd")
const Talents := preload("res://sim/talents.gd")

signal changed

const FORMAT := 1
const ENERGY_MAX := 60
const ENERGY_REGEN_SECONDS := 300 ## One energy every 5 minutes.
const ENERGY_PACK := 30
const STARTER := "vampire"
const STARTER_ORBS := 10
const PITY_START := 50 ## Matches Summon.PITY_RESET.
## The gear type (sim/gear.gd PIECES) an old named piece becomes, for pieces
## saved before gear had types (design/gear.md section 7). Anything else gets
## its slot's type: Shells keep you alive, Cores hit.
const GEAR_TYPES := {"Iron Shell": "iron_shell", "Spiked Shell": "iron_shell", "Spire Shell": "iron_shell",
	"Rubber Shell": "jet_charm", "Leech Core": "bubble_shell", "Overclock Core": "overclock_charm",
	"Spire Core": "overclock_charm", "Summit Core": "spike_core", "Echo Core": "echo_core"}
const SLOT_TYPES := {"Shell": "bubble_shell", "Core": "spike_core", "Charm": "jet_charm"}

var account_level := 1
var account_xp := 0
var energy := ENERGY_MAX
var energy_max := ENERGY_MAX
## Unix time the energy count was last brought up to date.
var energy_time := 0
var coins := 0
var orbs := STARTER_ORBS
var lineup := STARTER
var seen: Dictionary = {}
## One entry per (type, tier): {id, tier, count, level, xp}. The copies in a
## stack share its level; fusing 3 makes one copy of the next tier's stack.
var stacks: Array[Dictionary] = []
## Gear pieces: {uid, type, tier, on (critter id or "")} plus, filled in by
## gear_piece(), name, slot ("Shell"/"Core"/"Charm"), stats (the sim/gear.gd
## lines it fights with) and text. Three of a type and tier merge into one of
## the next tier (merge_gear).
var gear: Array[Dictionary] = []
## Consumables: {name, count, text, color}.
var items: Array[Dictionary] = []
var free_summon := true
## Rare-or-better rolls left before a guaranteed Legendary (shared with drops).
var legendary_pity := PITY_START
## Critters the player is chasing: they come up twice as often within their
## rarity in summons and drops (game/ui/summon.gd). Free to change any time.
var wishlist: Array[String] = []
const WISHLIST_MAX := 3
## Campaign stage key ("1-3") -> best star count.
var stars: Dictionary = {}
## Finished campaign runs; feeds fight and drop seeds so every run differs.
var runs := 0
## Gear Vault runs used today: {day (unix day), runs} (meta/gear_vault.gd).
var vault := {}
## Faction talent trees (sim/talents.gd): faction -> {xp, picks: {node: rank}}.
## Points come only from play: Faction XP from progression fights, plus one
## point for each of T2-T5 that any of the faction's critters has reached
## (worked out from the stacks, so it counts critters fused before trees existed).
## Respecs are free.
var factions := {}


static func new_game(now: int, starter := STARTER):
	var p = load("res://meta/profile.gd").new()
	p.setup_new_game(now, starter)
	return p


## Fills a blank profile as a brand-new player with one T1 `starter`.
func setup_new_game(now: int, starter := STARTER) -> void:
	energy_time = now
	coins = 200
	lineup = starter
	stacks.assign([{"id": starter, "tier": 1, "count": 1, "level": 1, "xp": 0}])
	seen = {starter: true}
	items.assign([
		{"name": "Energy Pack", "count": 1, "text": "+30 energy. Can go over the max.", "color": Color("5ce1ff")},
		{"name": "Summon Orb", "count": STARTER_ORBS, "text": "Spend at the Summon Portal. Earned by playing, never sold.", "color": Color("c86bff")},
	])


# --- Collection (the UI's API) ------------------------------------------------

func owns(id: String) -> bool:
	return not copies(id).is_empty()


## Owned stacks of one critter, lowest tier first.
func copies(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in stacks:
		if s.id == id and s.count > 0:
			out.append(s)
	out.sort_custom(func(a, b): return a.tier < b.tier)
	return out


## The highest-tier stack of a critter: the one that fights and shows in lists.
func best(id: String) -> Dictionary:
	var c := copies(id)
	return c[-1] if not c.is_empty() else {}


func total_copies(id: String) -> int:
	var n := 0
	for s in copies(id):
		n += s.count
	return n


func gear_on(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in gear:
		if g.on == id:
			out.append(g)
	return out


## What a critter's worn gear adds to its Power Rating, as a fraction.
func gear_power(id: String) -> float:
	return Gear.gear_power(gear_on(id))


func power_of(id: String) -> int:
	var b := best(id)
	if b.is_empty():
		return 0
	var t := Lineup.talent_power(slot_of(id))
	return Roster.power(id, b.tier, b.level, (1.0 + gear_power(id)) * (1.0 + t) - 1.0)


## The fight multiplier for a critter's best stack: the same number as
## power_of, as a multiple of a T1 level 1 Common.
func fight_power(id: String) -> float:
	var b := best(id)
	if b.is_empty():
		return 1.0
	return Power.multiplier(Roster.get_critter(id).rarity, b.tier, b.level) * (1.0 + gear_power(id)) * (1.0 + Lineup.talent_power(slot_of(id)))


## The critter's best stack as a lineup slot (sim/lineup.gd): what it brings
## to a progression fight. Empty when the player doesn't own it.
func slot_of(id: String) -> Dictionary:
	var b := best(id)
	if b.is_empty():
		return {}
	var pieces: Array = gear_on(id).map(func(g): return gear_piece(g))
	return Lineup.make(id, b.tier, b.level, pieces, talent_picks(Talents.faction_of(id)))


func found_count() -> int:
	var n := 0
	for id in Roster.ids():
		if owns(id):
			n += 1
	return n


## Stacks with 3+ copies below the top tier.
func ready_to_fuse() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in Roster.ids():
		for s in copies(id):
			if s.count >= 3 and s.tier < Roster.MAX_TIER:
				out.append(s)
	return out


func can_fuse(id: String, tier: int) -> bool:
	var s := _stack(id, tier)
	return not s.is_empty() and s.count >= 3 and tier < Roster.MAX_TIER


## What fusing 3 copies would give, without changing anything.
func fuse_preview(id: String, tier: int) -> Dictionary:
	var s := _stack(id, tier)
	var level: int = s.get("level", 1)
	var next := _stack(id, tier + 1)
	if not next.is_empty():
		level = maxi(level, next.level)
	return {"id": id, "tier": tier + 1, "level": level,
		"cap_before": Roster.level_cap(tier), "cap_after": Roster.level_cap(tier + 1),
		"power_before": Roster.power(id, tier, s.get("level", 1)), "power_after": Roster.power(id, tier + 1, level)}


## 3 copies of type+tier become 1 of the next tier, keeping the highest level.
func fuse(id: String, tier: int) -> Dictionary:
	if not can_fuse(id, tier):
		return {}
	var result := fuse_preview(id, tier)
	var from := _stack(id, tier)
	from.count -= 3
	var next := _stack(id, tier + 1)
	if next.is_empty():
		stacks.append({"id": id, "tier": tier + 1, "count": 1, "level": result.level, "xp": from.get("xp", 0)})
	else:
		next.count += 1
		if result.level > next.level:
			next.xp = from.get("xp", 0)
		next.level = result.level
	changed.emit()
	return result


func set_lineup(id: String) -> void:
	if owns(id):
		lineup = id
		changed.emit()


## Adds an unequipped piece of a gear type (sim/gear.gd PIECES) and returns it.
func add_gear(type: String, tier := 1) -> Dictionary:
	var piece := gear_piece({"uid": _next_gear_uid(), "type": type, "tier": tier, "on": ""})
	gear.append(piece)
	changed.emit()
	return piece


## A gear piece with its name, slot, stat lines and text filled in from its
## type and tier. Pieces saved before types (a name and a rarity) become the
## closest type, their rarity a tier (design/gear.md section 7).
static func gear_piece(g: Dictionary) -> Dictionary:
	var type := str(g.get("type", ""))
	if not Gear.PIECES.has(type):
		type = GEAR_TYPES.get(str(g.get("name", "")), SLOT_TYPES.get(str(g.get("slot", "")), "bubble_shell"))
	var tier := Gear.tier_of(g.get("tier", g.get("rarity", 1)))
	var def: Dictionary = Gear.PIECES[type]
	var stats := Gear.stats_for(type, tier)
	return {"uid": int(g.get("uid", 0)), "type": type, "tier": tier, "name": def.name, "slot": def.slot,
		"stats": stats, "text": _gear_text(stats), "on": str(g.get("on", ""))}


static func _gear_text(stats: Dictionary) -> String:
	var t := Gear.describe(stats)
	return t.left(1).to_upper() + t.substr(1)


## True when `id` can wear a piece in `slot`: the Charm slot opens at 3 stars.
func slot_open(id: String, slot: String) -> bool:
	return slot != "Charm" or int(best(id).get("tier", 0)) >= Gear.CHARM_TIER


## Put a gear piece on a critter, replacing whatever it wore in that slot.
## False (and nothing changes) when the critter's slot isn't open yet.
func equip(uid: int, id: String) -> bool:
	var piece := _gear(uid)
	if piece.is_empty() or not slot_open(id, piece.slot):
		return false
	for g in gear:
		if g.on == id and g.slot == piece.slot:
			g.on = ""
	piece.on = id
	changed.emit()
	return true


# --- Gear merging (design/gear.md section 3) ------------------------------------

## Pieces of one type and tier, unworn first, so merging touches as few
## lineups as it can.
func gear_of(type: String, tier: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in gear:
		if g.type == type and g.tier == tier:
			out.append(g)
	out.sort_custom(func(a, b): return a.on == "" and b.on != "")
	return out


## Coins to merge three `tier` pieces into one of the next tier.
static func merge_cost(tier: int) -> int:
	return Economy.GEAR_MERGE_COST[clampi(tier, 1, Gear.MAX_TIER - 1)]


## True when three pieces of type+tier exist below the top tier. Coins are
## checked by merge_gear, so the Bag can show "150 coins" on a set you can't
## afford yet.
func has_gear_set(type: String, tier: int) -> bool:
	return tier < Gear.MAX_TIER and gear_of(type, tier).size() >= 3


func can_merge_gear(type: String, tier: int) -> bool:
	return has_gear_set(type, tier) and coins >= merge_cost(tier)


## Every [type, tier] with a full set, lowest tier first.
func gear_sets() -> Array:
	var out := []
	for tier in range(1, Gear.MAX_TIER):
		for type in Gear.TYPES:
			if has_gear_set(type, tier):
				out.append([type, tier])
	return out


## 3 pieces of type+tier become 1 of the next tier, for coins. The new piece
## goes on whichever critter wore one of the three (the strongest, if more
## than one did). Returns the new piece, or {} when it can't merge.
func merge_gear(type: String, tier: int) -> Dictionary:
	if not can_merge_gear(type, tier):
		return {}
	coins -= merge_cost(tier)
	var used := gear_of(type, tier).slice(0, 3)
	var wearer := ""
	for g in used:
		if g.on != "" and (wearer == "" or power_of(g.on) > power_of(wearer)):
			wearer = g.on
		gear.erase(g)
	var piece := gear_piece({"uid": _next_gear_uid(), "type": type, "tier": tier + 1, "on": wearer})
	gear.append(piece)
	Analytics.track("gear_merge", {"type": type, "tier": tier + 1})
	changed.emit()
	return piece


## What merge_all_gear would do: {merges, coins} with merges as [type, tier]
## in order. Lower tiers merge first, so their results can complete sets above.
func merge_all_plan() -> Dictionary:
	var counts := {}
	for g in gear:
		var k := "%s/%d" % [g.type, g.tier]
		counts[k] = counts.get(k, 0) + 1
	var plan := {"merges": [], "coins": 0}
	var budget := coins
	for tier in range(1, Gear.MAX_TIER):
		for type in Gear.TYPES:
			var k := "%s/%d" % [type, tier]
			while counts.get(k, 0) >= 3 and budget >= merge_cost(tier):
				counts[k] -= 3
				budget -= merge_cost(tier)
				var up := "%s/%d" % [type, tier + 1]
				counts[up] = counts.get(up, 0) + 1
				plan.merges.append([type, tier])
				plan.coins += merge_cost(tier)
	return plan


## Merges every set the player can afford, lowest tier first. Returns the new
## pieces that weren't merged again.
func merge_all_gear() -> Array[Dictionary]:
	var made: Array[Dictionary] = []
	for m in merge_all_plan().merges:
		var piece := merge_gear(m[0], m[1])
		if piece.is_empty():
			break
		for g in made.duplicate():
			if not gear.has(g):
				made.erase(g)
		made.append(piece)
	return made


func _next_gear_uid() -> int:
	var uid := 1
	for g in gear:
		uid = maxi(uid, int(g.uid) + 1)
	return uid


func unequip(uid: int) -> void:
	_gear(uid).on = ""
	changed.emit()


func use_energy_pack() -> bool:
	var pack := _item("Energy Pack")
	if pack.get("count", 0) <= 0:
		return false
	pack.count -= 1
	energy += ENERGY_PACK
	Analytics.track("energy", {"delta": ENERGY_PACK, "source": "pack"})
	changed.emit()
	return true


## Adds T1 copies from a summon (or a drop) and marks them seen.
func add_copies(ids: Array) -> void:
	for id in ids:
		var s := _stack(id, 1)
		if s.is_empty():
			stacks.append({"id": id, "tier": 1, "count": 1, "level": 1, "xp": 0})
		else:
			s.count += 1
		seen[id] = true
	changed.emit()


func on_wishlist(id: String) -> bool:
	return id in wishlist


## Adds or removes a wishlist pick. Returns false (and changes nothing) when
## adding to a full wishlist.
func toggle_wishlist(id: String) -> bool:
	if on_wishlist(id):
		wishlist.erase(id)
	elif wishlist.size() >= WISHLIST_MAX:
		return false
	else:
		wishlist.append(id)
	changed.emit()
	return true


func spend_orbs(n: int) -> bool:
	if orbs < n:
		return false
	orbs -= n
	var item := _item("Summon Orb")
	if not item.is_empty():
		item.count = orbs
	changed.emit()
	return true


# --- Levels -------------------------------------------------------------------

## XP needed to go from `level` to `level + 1`.
static func xp_to_next(level: int) -> int:
	return 10 * level


## Adds XP to a critter's best stack, levelling it up to its tier's cap.
## Returns levels gained.
func add_xp(id: String, amount: int) -> int:
	var b := best(id)
	if b.is_empty():
		return 0
	add_faction_xp(Talents.faction_of(id), amount)
	var gained := 0
	b.xp = b.get("xp", 0) + amount
	var cap := Roster.level_cap(b.tier)
	while b.level < cap and b.xp >= xp_to_next(b.level):
		b.xp -= xp_to_next(b.level)
		b.level += 1
		gained += 1
	if b.level >= cap:
		b.xp = 0
	return gained


# --- Faction talent trees ------------------------------------------------------

## Faction XP needed to go from rank `rank` to `rank + 1` (design/talents.md).
static func faction_xp_to_next(rank: int) -> int:
	return 20 + 20 * (rank + 1)


func _faction(f: String) -> Dictionary:
	if not factions.has(f):
		factions[f] = {"xp": 0, "picks": {}}
	return factions[f]


## Ranks from Faction XP alone, and the XP into the next one: {rank, xp, need}.
func faction_xp_rank(f: String) -> Dictionary:
	var xp := int(factions.get(f, {}).get("xp", 0))
	var rank := 0
	while xp >= faction_xp_to_next(rank) and rank < Talents.MAX_POINTS:
		xp -= faction_xp_to_next(rank)
		rank += 1
	return {"rank": rank, "xp": xp, "need": faction_xp_to_next(rank)}


## Points from tier milestones: one for each of T2-T5 any of the faction's critters has reached.
func faction_marks(f: String) -> int:
	var top := 1
	for s in stacks:
		if s.count > 0 and Talents.faction_of(s.id) == f:
			top = maxi(top, s.tier)
	return top - 1


## Faction Rank: talent points earned in that tree (XP ranks + tier milestones), max 30.
func faction_rank(f: String) -> int:
	return mini(Talents.MAX_POINTS, faction_xp_rank(f).rank + faction_marks(f))


func talent_picks(f: String) -> Dictionary:
	return factions.get(f, {}).get("picks", {}).duplicate()


func talent_points_free(f: String) -> int:
	return faction_rank(f) - Talents.spent(f, talent_picks(f))


func add_faction_xp(f: String, amount: int) -> void:
	if f == "" or amount <= 0:
		return
	var fd := _faction(f)
	fd.xp = int(fd.xp) + amount


## True when one more rank can go into `node` now.
func can_add_talent(f: String, node: String) -> bool:
	var n := Talents.node(f, node)
	if n.is_empty():
		return false
	var picks := talent_picks(f)
	return int(picks.get(node, 0)) < int(n.max) and talent_points_free(f) >= int(n.cost) and Talents.row_open(f, picks, n.row)


## Spends points on one rank of `node`. Returns true if it went in.
func add_talent(f: String, node: String) -> bool:
	if not can_add_talent(f, node):
		return false
	var fd := _faction(f)
	fd.picks[node] = int(fd.picks.get(node, 0)) + 1
	changed.emit()
	return true


## Takes one rank back out, unless rows above still need those points.
func remove_talent(f: String, node: String) -> bool:
	var picks := talent_picks(f)
	if int(picks.get(node, 0)) <= 0:
		return false
	picks[node] = int(picks[node]) - 1
	if picks[node] == 0:
		picks.erase(node)
	if Talents.clean(f, picks) != picks:
		return false
	_faction(f).picks = picks
	changed.emit()
	return true


## Free respec: every point back.
func reset_talents(f: String) -> void:
	if factions.has(f):
		factions[f].picks = {}
		changed.emit()


## Drops picks beyond the points owned (e.g. a save edited by hand).
func _trim_picks(f: String) -> void:
	if Talents.spent(f, talent_picks(f)) > faction_rank(f):
		factions[f].picks = {}


# --- Energy and account level ---------------------------------------------------

## Brings regeneration up to `now`. Regen stops at the max; energy above it
## (packs, level-up refills) is kept.
func update_energy(now: int) -> void:
	if energy >= energy_max:
		energy_time = now
		return
	var ticks := (now - energy_time) / ENERGY_REGEN_SECONDS
	if ticks <= 0:
		return
	energy = mini(energy_max, energy + ticks)
	energy_time = now if energy >= energy_max else energy_time + ticks * ENERGY_REGEN_SECONDS


## Seconds until the next energy point, or 0 when full.
func seconds_to_next_energy(now: int) -> int:
	if energy >= energy_max:
		return 0
	return maxi(0, ENERGY_REGEN_SECONDS - (now - energy_time))


func spend_energy(amount: int, now: int) -> bool:
	update_energy(now)
	if energy < amount:
		return false
	if energy >= energy_max and energy - amount < energy_max:
		energy_time = now # Regen counts from the moment we drop below max.
	energy -= amount
	changed.emit()
	return true


func refund_energy(amount: int) -> void:
	energy += amount
	changed.emit()


## Account XP comes from energy used on finished runs (meta/campaign.gd), so a
## cancelled, refunded run earns nothing. Each level-up refills energy.
func add_account_xp(amount: int) -> int:
	account_xp += amount
	var gained := 0
	while account_xp >= account_xp_to_next():
		account_xp -= account_xp_to_next()
		account_level += 1
		gained += 1
	if gained > 0:
		energy = maxi(energy, energy_max)
	return gained


func account_xp_to_next() -> int:
	return 20 + 10 * account_level


# --- Save ---------------------------------------------------------------------

const _SAVED := ["account_level", "account_xp", "energy", "energy_time", "coins", "orbs", "lineup",
	"seen", "stacks", "gear", "items", "free_summon", "legendary_pity", "stars", "runs", "wishlist", "vault", "factions"]


func to_dict() -> Dictionary:
	var d := {"format": FORMAT}
	for k in _SAVED:
		d[k] = get(k)
	# Colours don't survive JSON; store them as html strings.
	d.items = items.map(func(i): var c: Dictionary = i.duplicate(); c.color = (i.color as Color).to_html(); return c)
	return JSON.parse_string(JSON.stringify(d))


## Rebuilds a profile from to_dict() output, including after a JSON round trip
## (numbers come back as floats).
static func from_dict(d: Dictionary, now: int):
	var p = new_game(now)
	if not d.get("stacks", []) is Array or d.get("stacks", []).is_empty():
		return p
	for k in ["account_level", "account_xp", "energy", "energy_time", "coins", "orbs", "legendary_pity", "runs"]:
		if d.has(k):
			p.set(k, int(d[k]))
	p.lineup = str(d.get("lineup", STARTER))
	p.free_summon = bool(d.get("free_summon", true))
	p.seen = d.get("seen", {})
	p.wishlist.clear()
	for id in d.get("wishlist", []):
		if p.wishlist.size() < WISHLIST_MAX:
			p.wishlist.append(str(id))
	var v = d.get("vault", {})
	if v is Dictionary and v.has("day"):
		p.vault = {"day": int(v.day), "runs": int(v.get("runs", 0))}
	p.stars.clear()
	for k in d.get("stars", {}):
		p.stars[str(k)] = int(d.stars[k])
	p.stacks.clear()
	for s in d.stacks:
		p.stacks.append({"id": str(s.id), "tier": int(s.tier), "count": int(s.count), "level": int(s.level), "xp": int(s.get("xp", 0))})
	p.gear.clear()
	for g in d.get("gear", []):
		var piece := gear_piece(g)
		if piece.uid <= 0 or p._gear(piece.uid).size() > 0:
			piece.uid = p._next_gear_uid()
		p.gear.append(piece)
	p.factions.clear()
	var fs = d.get("factions", {})
	if fs is Dictionary:
		for f in fs:
			if f in Talents.FACTIONS and fs[f] is Dictionary:
				p.factions[f] = {"xp": maxi(0, int(fs[f].get("xp", 0))), "picks": {}}
				p.factions[f].picks = Talents.clean(f, fs[f].get("picks", {}))
				p._trim_picks(f)
	if d.has("items"):
		p.items.clear()
		for i in d.items:
			p.items.append({"name": str(i.name), "count": int(i.count), "text": str(i.text), "color": Color(str(i.color))})
	if not p.owns(p.lineup):
		p.lineup = p.stacks[0].id
	# A converted Charm on a critter under 3 stars goes back to the Bag.
	for g in p.gear:
		if g.on != "" and not p.slot_open(g.on, g.slot):
			g.on = ""
	return p


# --- Internals ------------------------------------------------------------------

func _gear(uid: int) -> Dictionary:
	for g in gear:
		if g.uid == uid:
			return g
	return {}


func spend_coins(n: int) -> bool:
	if coins < n:
		return false
	coins -= n
	changed.emit()
	return true


## An earned reward (Glow Pass free track, bounties): {kind, n} with kind
## orbs, coins, energy, xp_chip, copies (with id) or gear (type and tier).
func grant(r: Dictionary) -> void:
	var n := int(r.get("n", 1))
	match r.kind:
		"orbs":
			orbs += n
			_item("Summon Orb").count = orbs
		"coins":
			coins += n
		"energy":
			energy += n
		"xp_chip":
			_item("XP Chip").count = int(_item("XP Chip").get("count", 0)) + n
		"copies":
			if str(r.id) in Roster.ids():
				for i in n:
					add_copies([r.id])
		"gear":
			if Gear.PIECES.has(str(r.get("type", ""))):
				for i in n:
					add_gear(str(r.type), int(r.get("tier", 1)))
	changed.emit()


func _item(name: String) -> Dictionary:
	for i in items:
		if i.name == name:
			return i
	return {}


func _stack(id: String, tier: int) -> Dictionary:
	for s in stacks:
		if s.id == id and s.tier == tier:
			return s
	return {}
