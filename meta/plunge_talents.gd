## Critter Plunge medals and race talents. A podium finish wins a medal
## (gold, silver or bronze, by place and field size); medals buy race talents,
## one tree per family, that make that family's critters race better. For
## spending, 1 gold = 2 silver = 4 bronze: a price asks for a mix, and a
## higher medal can stand in for lower ones (the change comes back as lower
## medals). Talents only help your own racer, in Critter Plunge only.
##
## Saved in Profile.plunge: {medals: {gold, silver, bronze}, talents:
## {family: {talent id: rank}}}.
extends RefCounted

const Families := preload("res://sim/families.gd")

const MEDALS := ["gold", "silver", "bronze"]
const MEDAL_NAMES := {"gold": "Gold", "silver": "Silver", "bronze": "Bronze"}
const VALUE := {"gold": 4, "silver": 2, "bronze": 1} ## In bronze.
## Medal by place, per field size: bigger fields give more and better ones.
const PODIUM := {
	4: ["silver", "bronze"],
	6: ["gold", "silver", "bronze"],
	8: ["gold", "silver", "bronze", "bronze"],
}
const MAX_RANK := 5
## The price of each rank, 1 to 5.
const PRICES := [
	{"bronze": 3},
	{"silver": 1, "bronze": 2},
	{"gold": 1, "silver": 1, "bronze": 2},
	{"gold": 1, "silver": 2, "bronze": 4},
	{"gold": 2, "silver": 3, "bronze": 4},
]
## Every family's tree has the same three talents. `per` is what each rank adds.
const TALENTS := [
	{"id": "tough", "name": "Thick Skin", "text": "+%d%% HP", "per": 0.05},
	{"id": "power", "name": "Hard Hitter", "text": "+%d%% damage", "per": 0.05},
	{"id": "steady", "name": "Steady", "text": "Hits slow it %d%% less", "per": 0.1},
]


## The medal for `place` (1 = winner) in a field of `n`, or "" for none.
static func medal_for(place: int, n: int) -> String:
	var row: Array = PODIUM.get(n, PODIUM[6])
	return row[place - 1] if place >= 1 and place <= row.size() else ""


## A save's Plunge data with every key there and nothing that isn't.
static func clean(d) -> Dictionary:
	var out := {"medals": {"gold": 0, "silver": 0, "bronze": 0}, "talents": {}}
	if not (d is Dictionary):
		return out
	var m = d.get("medals", {})
	if m is Dictionary:
		for k in MEDALS:
			out.medals[k] = maxi(0, int(m.get(k, 0)))
	var t = d.get("talents", {})
	if t is Dictionary:
		for fam in t:
			if Families.MEMBERS.has(str(fam)) and t[fam] is Dictionary:
				var ranks := {}
				for tal in TALENTS:
					var r := clampi(int(t[fam].get(tal.id, 0)), 0, MAX_RANK)
					if r > 0:
						ranks[tal.id] = r
				if not ranks.is_empty():
					out.talents[str(fam)] = ranks
	return out


static func medals(profile) -> Dictionary:
	return profile.plunge.get("medals", {"gold": 0, "silver": 0, "bronze": 0})


static func add_medal(profile, medal: String) -> void:
	if medal == "":
		return
	profile.plunge = clean(profile.plunge)
	profile.plunge.medals[medal] += 1


static func rank(profile, family: String, talent: String) -> int:
	return int(profile.plunge.get("talents", {}).get(family, {}).get(talent, 0))


## The price of the next rank of a talent at `current` rank, or {} at max.
static func price(current: int) -> Dictionary:
	return PRICES[current] if current < MAX_RANK else {}


## What paying `cost` out of `have` leaves, or {} when it can't be paid. Each
## medal pays for its own kind first; a higher medal breaks into two of the
## next one down to cover the rest, and the change stays.
static func pay(have: Dictionary, cost: Dictionary) -> Dictionary:
	var left := {"gold": int(have.get("gold", 0)), "silver": int(have.get("silver", 0)), "bronze": int(have.get("bronze", 0))}
	for k in MEDALS:
		var need := int(cost.get(k, 0))
		var i := MEDALS.find(k)
		while left[k] < need:
			# Break the nearest higher medal that's there.
			var up := i - 1
			while up >= 0 and left[MEDALS[up]] == 0:
				up -= 1
			if up < 0:
				return {}
			left[MEDALS[up]] -= 1
			for j in range(up + 1, i):
				left[MEDALS[j]] += 1 # Breaking two steps down leaves one of the middle kind.
			left[k] += 2
		left[k] -= need
	return left


static func can_buy(profile, family: String, talent: String) -> bool:
	var cost := price(rank(profile, family, talent))
	return not cost.is_empty() and not pay(medals(profile), cost).is_empty()


## Buys the next rank. Returns false (and changes nothing) when it can't.
static func buy(profile, family: String, talent: String) -> bool:
	if not can_buy(profile, family, talent):
		return false
	profile.plunge = clean(profile.plunge)
	profile.plunge.medals = pay(profile.plunge.medals, price(rank(profile, family, talent)))
	if not profile.plunge.talents.has(family):
		profile.plunge.talents[family] = {}
	profile.plunge.talents[family][talent] = rank(profile, family, talent) + 1
	profile.changed.emit()
	return true


## What `critter`'s family talents give it in a race: {tough, power, steady}
## as shares (0.25 = +25%).
static func effects(profile, critter: String) -> Dictionary:
	var fam := Families.of(critter)
	var out := {}
	for tal in TALENTS:
		out[tal.id] = tal.per * rank(profile, fam, tal.id)
	return out


## A talent's line at `r` ranks ("+15% HP").
static func line(talent: Dictionary, r: int) -> String:
	return talent.text % roundi(talent.per * r * 100.0)
