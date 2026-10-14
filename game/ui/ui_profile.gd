## What the UI needs from the player's save: collection stacks, fusion,
## currencies and gear. This is a sample in-memory profile so the screens can
## be built and played with now; it will be backed by the PvE thread's meta/
## save once that lands, keeping this API.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")
const Analytics := preload("res://game/online/analytics.gd")

signal changed

var account_level := 7
var energy := 42
var energy_max := 60
var coins := 2480
var orbs := 14
var lineup := "vampire"
var seen: Dictionary = {}
## One entry per (type, tier): {id, tier, count, level}.
var stacks: Array[Dictionary] = []
## Gear pieces: {uid, name, slot ("Shell"/"Core"), rarity, text, on (critter id or "")}.
var gear: Array[Dictionary] = []
## Consumables: {name, count, text, color}.
var items: Array[Dictionary] = []
var free_summon := true
## Rare-or-better rolls left before a guaranteed Legendary (shared with drops).
var legendary_pity := 112
## Critters the player is chasing: they come up twice as often within their
## rarity in summons and drops (game/ui/summon.gd). Free to change any time.
var wishlist: Array[String] = []
const WISHLIST_MAX := 3


static func sample():
	var p = load("res://game/ui/ui_profile.gd").new()
	for s in [["vampire", 2, 1, 14], ["vampire", 1, 3, 6], ["juggernaut", 1, 2, 7], ["spiker", 2, 1, 12],
			["spiker", 1, 1, 3], ["speedster", 1, 3, 9], ["bomber", 1, 1, 3],
			["thorns", 1, 1, 2], ["splitter", 1, 1, 5]]:
		p.stacks.append({"id": s[0], "tier": s[1], "count": s[2], "level": s[3]})
		p.seen[s[0]] = true
	p.gear.assign([
		{"uid": 1, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "text": "Take 2 less damage per hit", "on": "vampire"},
		{"uid": 2, "name": "Leech Core", "slot": "Core", "rarity": "rare", "text": "Heal 5% of damage dealt", "on": "vampire"},
		{"uid": 3, "name": "Rubber Shell", "slot": "Shell", "rarity": "rare", "text": "+8% bounce speed", "on": "speedster"},
		{"uid": 4, "name": "Overclock Core", "slot": "Core", "rarity": "epic", "text": "Ability triggers 15% sooner", "on": ""},
		{"uid": 5, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "text": "Take 2 less damage per hit", "on": ""},
		{"uid": 6, "name": "Spiked Shell", "slot": "Shell", "rarity": "rare", "text": "Take 1 less damage; attackers take 2", "on": ""},
		{"uid": 7, "name": "Echo Core", "slot": "Core", "rarity": "legendary", "text": "8% chance the ability fires twice", "on": ""},
	])
	p.items.assign([
		{"name": "Energy Pack", "count": 3, "text": "+30 energy. Can go over the max.", "color": Color("5ce1ff")},
		{"name": "XP Chip", "count": 12, "text": "+200 XP to one critter.", "color": Color("45f5a6")},
		{"name": "Summon Orb", "count": 14, "text": "Spend at the Summon Portal. Earned by playing, never sold.", "color": Color("c86bff")},
	])
	return p


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
	_stack(id, tier).count -= 3
	var next := _stack(id, tier + 1)
	if next.is_empty():
		stacks.append({"id": id, "tier": tier + 1, "count": 1, "level": result.level})
	else:
		next.count += 1
		next.level = result.level
	changed.emit()
	return result


func set_lineup(id: String) -> void:
	if owns(id):
		lineup = id
		changed.emit()


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
	energy += 30
	Analytics.track("energy", {"delta": 30, "source": "pack"})
	changed.emit()
	return true


## Adds T1 copies from a summon (or a drop) and marks them seen.
func add_copies(ids: Array) -> void:
	for id in ids:
		var s := _stack(id, 1)
		if s.is_empty():
			stacks.append({"id": id, "tier": 1, "count": 1, "level": 1})
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
	_item("Summon Orb").count = orbs
	changed.emit()
	return true


func _gear(uid: int) -> Dictionary:
	for g in gear:
		if g.uid == uid:
			return g
	return {}


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
