## Critter Plunge medals and race talents. A podium finish wins a medal
## (gold, silver or bronze, by place and field size); medals buy race talents,
## one tree per family, that make that family's critters race better. For
## spending, 1 gold = 2 silver = 4 bronze: a price asks for a mix, and a
## higher medal can stand in for lower ones (the change comes back as lower
## medals). Your talents help your own racer, in Critter Plunge only; the
## CPU field gets its own at your league's rank (at_rank, meta/plunge_league.gd).
##
## Each tree is the two shared stat talents (TALENTS) and the family's own
## signature talent (SIGNATURES), which changes how one course piece treats
## its racers (sim/plunge.gd SIGNATURES has what each does at full rank).
##
## Saved in Profile.plunge: {medals: {gold, silver, bronze}, talents:
## {family: {talent id: rank}}, points: every medal ever won, in bronze (the
## league's points; spending medals never lowers it)}.
extends RefCounted

const Families := preload("res://sim/families.gd")
const Plunge := preload("res://sim/plunge.gd")

const MEDALS := ["gold", "silver", "bronze"]
const MEDAL_NAMES := {"gold": "Gold", "silver": "Silver", "bronze": "Bronze"}
const VALUE := {"gold": 4, "silver": 2, "bronze": 1} ## In bronze.
const MAX_RANK := 10
## The price of each rank, 1 to 10.
const PRICES := [
	{"bronze": 3},
	{"silver": 1, "bronze": 2},
	{"gold": 1, "silver": 1, "bronze": 2},
	{"gold": 1, "silver": 2, "bronze": 4},
	{"gold": 2, "silver": 3, "bronze": 4},
	{"gold": 2, "silver": 4, "bronze": 4},
	{"gold": 3, "silver": 4, "bronze": 4},
	{"gold": 4, "silver": 4, "bronze": 4},
	{"gold": 5, "silver": 5, "bronze": 4},
	{"gold": 6, "silver": 6, "bronze": 6},
]
## The two talents every family's tree has. `per` is what each rank adds;
## `short` is the summary's form and `race` the payoff on the course.
const TALENTS := [
	{"id": "tough", "name": "Thick Skin", "text": "+%d%% HP", "short": "+%d%% HP", "per": 0.05,
		"race": "Takes more hits before a knockout"},
	{"id": "power", "name": "Hard Hitter", "text": "+%d%% damage", "short": "+%d%% dmg", "per": 0.05,
		"race": "Its hits slow rivals down more"},
]
## Each family's signature talent, tied to one course piece. Its `text` shows
## the effect at a rank (sim/plunge.gd SIGNATURES is the full effect, at
## MAX_RANK); `full` replaces the text at MAX_RANK.
const SIGNATURES := {
	"fire": {"id": "lava", "name": "Lava-proof", "text": "Lava burns it %d%% less", "full": "Lava can't burn it",
		"race": "Rolls through lava pools"},
	"frost": {"id": "ice", "name": "Ice Skates", "text": "Ice and belts speed it +%d%%",
		"race": "Faster down icy ramps and belts"},
	"sea": {"id": "current", "name": "Riptide", "text": "Goo and wind slow it %d%% less",
		"race": "Swims through goo and currents"},
	"cosmic": {"id": "orbit", "name": "Star Anchor", "text": "Gravity wells pull it %d%% less",
		"race": "Drops straight past gravity wells"},
	"tech": {"id": "core", "name": "Overclock", "text": "Power-core rush +%d%%",
		"race": "Power cores fire it down faster"},
	"sweet": {"id": "shield", "name": "Sugar Shell", "text": "Starts with a %d%% HP shield",
		"race": "Shielded from the gate"},
	"spooky": {"id": "portal", "name": "Phantom Exit", "text": "Portals fling it on +%d%% speed",
		"race": "Shoots out of portals"},
	"toybox": {"id": "spring", "name": "Spring Loaded", "text": "Pads and bumpers kick it +%d%%",
		"race": "Flies further off pads and bumpers"},
	"nature": {"id": "thorn", "name": "Thornproof", "text": "Thorns hurt %d%% less, heals +%d%%",
		"full": "Thorns can't hurt it, heals +%d%%", "race": "Shrugs off thorns, heals more"},
}


## `family`'s tree: the shared talents, then its signature.
static func talents(family: String) -> Array:
	return TALENTS + ([SIGNATURES[family]] if SIGNATURES.has(family) else [])


static func signature(family: String) -> Dictionary:
	return SIGNATURES.get(family, {})


## A save's Plunge data with every key there and nothing that isn't. Old
## saves' Steady ranks (a retired talent) become the signature's.
static func clean(d) -> Dictionary:
	var out := {"medals": {"gold": 0, "silver": 0, "bronze": 0}, "talents": {}, "points": 0}
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
				var sig := signature(str(fam))
				var ranks := {}
				for tal in talents(str(fam)):
					var r := int(t[fam].get(tal.id, 0))
					if tal == sig:
						r += int(t[fam].get("steady", 0))
					r = clampi(r, 0, MAX_RANK)
					if r > 0:
						ranks[tal.id] = r
				if not ranks.is_empty():
					out.talents[str(fam)] = ranks
	# Saves from before the league: what the medals in hand and the talents
	# bought are worth.
	out.points = maxi(0, int(d.points)) if d.has("points") else worth(out.medals) + _spent(out.talents)
	return out


## What `m` ({gold, silver, bronze}) is worth in bronze.
static func worth(m: Dictionary) -> int:
	var n := 0
	for k in MEDALS:
		n += int(m.get(k, 0)) * VALUE[k]
	return n


## Every medal ever won, in bronze: the league's points.
static func points(profile) -> int:
	return int(profile.plunge.get("points", 0))


## What every rank in `talents` ({family: {talent id: rank}}) cost, in bronze.
static func _spent(talents: Dictionary) -> int:
	var n := 0
	for fam in talents:
		for id in talents[fam]:
			for r in int(talents[fam][id]):
				n += worth(PRICES[r])
	return n


static func medals(profile) -> Dictionary:
	return profile.plunge.get("medals", {"gold": 0, "silver": 0, "bronze": 0})


static func add_medal(profile, medal: String) -> void:
	if medal == "":
		return
	profile.plunge = clean(profile.plunge)
	profile.plunge.medals[medal] += 1
	profile.plunge.points += VALUE[medal]


static func rank(profile, family: String, talent: String) -> int:
	return int(profile.plunge.get("talents", {}).get(family, {}).get(talent, 0))


## Every rank bought in `family`'s tree (0 to 30).
static func ranks(profile, family: String) -> int:
	var n := 0
	for tal in talents(family):
		n += rank(profile, family, tal.id)
	return n


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
	if not talents(family).any(func(t): return t.id == talent):
		return false
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


## What `critter`'s family talents give it in a race (sim/plunge.gd boosts):
## {tough, power} as shares (0.25 = +25%) and, once it has a rank, the
## family's signature id as a share of its full effect (rank / MAX_RANK).
static func effects(profile, critter: String) -> Dictionary:
	var fam := Families.of(critter)
	var out := {}
	for tal in TALENTS:
		out[tal.id] = tal.per * rank(profile, fam, tal.id)
	var sig := signature(fam)
	if not sig.is_empty() and rank(profile, fam, sig.id) > 0:
		out[sig.id] = float(rank(profile, fam, sig.id)) / MAX_RANK
	return out


## What a racer of `critter`'s family gets with every talent of its tree at
## rank `r` (effects()' form): the CPU field's talents in a league.
static func at_rank(critter: String, r: int) -> Dictionary:
	var out := {}
	for tal in TALENTS:
		out[tal.id] = tal.per * r
	var sig := signature(Families.of(critter))
	if not sig.is_empty() and r > 0:
		out[sig.id] = float(r) / MAX_RANK
	return out


## A talent's line at `r` ranks ("+15% HP", "Lava burns it 60% less").
static func line(talent: Dictionary, r: int) -> String:
	return _fill(talent.full if r >= MAX_RANK and talent.has("full") else talent.text, _value(talent, r))


## A talent's short form at `r` ranks, for summaries ("+15% HP", "Lava-proof 3/10").
static func short(talent: Dictionary, r: int) -> String:
	if talent.has("short"):
		return _fill(talent.short, _value(talent, r))
	return "%s %d/%d" % [talent.name, r, MAX_RANK]


## `family`'s talents you have, on one line ("+15% HP · +5% dmg · Lava-proof
## 3/10"), or "" with none.
static func summary(profile, family: String) -> String:
	var parts := []
	for tal in talents(family):
		var r := rank(profile, family, tal.id)
		if r > 0:
			parts.append(short(tal, r))
	return " · ".join(parts)


## The percent a talent shows at `r` ranks.
static func _value(talent: Dictionary, r: int) -> int:
	if talent.has("per"):
		return roundi(talent.per * r * 100.0)
	return roundi(Plunge.SIGNATURES[talent.id] * r * 100.0 / MAX_RANK)


static func _fill(text: String, v: int) -> String:
	var args := []
	for k in text.count("%d"):
		args.append(v)
	return text % args if not args.is_empty() else text
