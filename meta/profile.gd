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

signal changed

const FORMAT := 1
const ENERGY_MAX := 60
const ENERGY_REGEN_SECONDS := 300 ## One energy every 5 minutes.
const ENERGY_PACK := 30
const STARTER := "vampire"
const STARTER_ORBS := 10
const PITY_START := 50 ## Matches Summon.PITY_RESET.
## The stat line a named piece fights with, for pieces saved before gear had
## stats. Anything else gets its slot's line: Shells guard, Cores hit.
const GEAR_LINES := {"Iron Shell": "defense", "Spiked Shell": "defense", "Spire Shell": "defense",
	"Rubber Shell": "speed", "Leech Core": "health", "Overclock Core": "cooldown", "Spire Core": "cooldown",
	"Summit Core": "attack", "Echo Core": "crit_chance"}
const SLOT_LINES := {"Shell": "health", "Core": "attack"}

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
## Gear pieces: {uid, name, slot ("Shell"/"Core"), rarity, stats, text, on
## (critter id or "")}. `stats` are the sim/gear.gd lines the piece fights
## with; `text` describes them.
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


func power_of(id: String) -> int:
	var b := best(id)
	if b.is_empty():
		return 0
	return Roster.power(id, b.tier, b.level, gear_on(id).size())


## The fight multiplier for a critter's best stack: the same number as
## power_of, as a multiple of a T1 level 1 Common.
func fight_power(id: String) -> float:
	var b := best(id)
	if b.is_empty():
		return 1.0
	return Power.multiplier(Roster.get_critter(id).rarity, b.tier, b.level) * (1.0 + Power.GEAR_STEP * gear_on(id).size())


## The critter's best stack as a lineup slot (sim/lineup.gd): what it brings
## to a progression fight. Empty when the player doesn't own it.
func slot_of(id: String) -> Dictionary:
	var b := best(id)
	if b.is_empty():
		return {}
	var pieces: Array = gear_on(id).map(func(g): return gear_piece(g))
	return Lineup.make(id, b.tier, b.level, pieces)


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


## Adds an unequipped piece and returns it. Without `stats` it fights with
## its name's (or slot's) main line at its rarity.
func add_gear(name: String, slot: String, rarity: String, stats := {}) -> Dictionary:
	var uid := 1
	for g in gear:
		uid = maxi(uid, int(g.uid) + 1)
	var piece := gear_piece({"uid": uid, "name": name, "slot": slot, "rarity": rarity, "stats": stats, "on": ""})
	gear.append(piece)
	changed.emit()
	return piece


## A gear piece with its stat lines filled in (and its text saying what they
## do), from a saved or hand-written piece.
static func gear_piece(g: Dictionary) -> Dictionary:
	var stats := {}
	var saved = g.get("stats", {})
	if saved is Dictionary:
		for line in saved:
			if Gear.LINES.has(line):
				stats[line] = float(saved[line])
	if stats.is_empty():
		var line: String = GEAR_LINES.get(str(g.name), SLOT_LINES.get(str(g.slot), "health"))
		stats[line] = roundf(Gear.value(line, str(g.rarity)) * 1000.0) / 1000.0
	return {"uid": int(g.uid), "name": str(g.name), "slot": str(g.slot), "rarity": str(g.rarity), "stats": stats,
		"text": _gear_text(stats), "on": str(g.get("on", ""))}


static func _gear_text(stats: Dictionary) -> String:
	var t := Gear.describe(stats)
	return t.left(1).to_upper() + t.substr(1)


## Put a gear piece on a critter, replacing whatever it wore in that slot.
func equip(uid: int, id: String) -> void:
	var piece := _gear(uid)
	for g in gear:
		if g.on == id and g.slot == piece.slot:
			g.on = ""
	piece.on = id
	changed.emit()


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
	"seen", "stacks", "gear", "items", "free_summon", "legendary_pity", "stars", "runs", "wishlist"]


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
	p.stars.clear()
	for k in d.get("stars", {}):
		p.stars[str(k)] = int(d.stars[k])
	p.stacks.clear()
	for s in d.stacks:
		p.stacks.append({"id": str(s.id), "tier": int(s.tier), "count": int(s.count), "level": int(s.level), "xp": int(s.get("xp", 0))})
	p.gear.clear()
	for g in d.get("gear", []):
		p.gear.append(gear_piece(g))
	if d.has("items"):
		p.items.clear()
		for i in d.items:
			p.items.append({"name": str(i.name), "count": int(i.count), "text": str(i.text), "color": Color(str(i.color))})
	if not p.owns(p.lineup):
		p.lineup = p.stacks[0].id
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
## orbs, coins, energy, xp_chip, or copies (with id).
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
