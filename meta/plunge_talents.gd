## Critter Plunge medals and race talents. A podium finish wins a medal
## (gold, silver or bronze, by place and field size); medals buy race talents,
## one tree per family, that make that family's critters race better. For
## spending, 1 gold = 2 silver = 4 bronze: a price asks for a mix, and a
## higher medal can stand in for lower ones (the change comes back as lower
## medals). Your talents help your own racer, in Critter Plunge only; the
## CPU field gets its own at your league's rank (at_rank, meta/plunge_league.gd).
##
## Each tree is the three shared talents (TALENTS: HP, damage, speed) and the
## family's own signature talent (SIGNATURES), its own way to race on every
## course (sim/plunge.gd SIGNATURES has what each does at full rank).
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
## The three talents every family's tree has. `per` is what each rank adds;
## `short` is the summary's form and `race` the payoff on the course.
const TALENTS := [
	{"id": "tough", "name": "Thick Skin", "text": "+%s%% HP", "short": "+%s%% HP", "per": 0.05,
		"race": "Takes more hits before a knockout"},
	{"id": "power", "name": "Hard Hitter", "text": "+%s%% damage", "short": "+%s%% dmg", "per": 0.05,
		"race": "Its hits slow rivals down more"},
	{"id": "swift", "name": "Swift", "text": "+%s%% top speed", "short": "+%s%% spd", "per": 0.02,
		"race": "Less air drag, a faster drop"},
]
## Each family's signature talent: its own way to race, on every course. Its
## `text` shows the effect at a rank (sim/plunge.gd SIGNATURES is the full
## effect, at MAX_RANK; Plunge.shown the number in the text).
const SIGNATURES := {
	"fire": {"id": "lava", "name": "Scorch", "text": "Its bumps burn rivals %s HP/s",
		"race": "Leaves rivals burning"},
	"frost": {"id": "ice", "name": "Ice Skates", "text": "Every ramp speeds it +%s%%",
		"race": "Every ramp is slick for it"},
	"sea": {"id": "current", "name": "Wave Rider", "text": "Hits slow it %s%% less, then it surges",
		"race": "Rides the hits on down"},
	"cosmic": {"id": "orbit", "name": "Heavy Star", "text": "+%s%% gravity, hard to shove",
		"race": "Falls hard through the pack"},
	"tech": {"id": "core", "name": "Overclock", "text": "A power rush every %ss",
		"race": "Rushes on when it slows"},
	"sweet": {"id": "shield", "name": "Sugar Shell", "text": "Starts with a %s%% HP shield",
		"race": "Shielded twice, a sugar rush when it breaks"},
	"spooky": {"id": "portal", "name": "Ghost Step", "text": "Phases through a bump every %ss",
		"race": "Slips through rivals and moving parts"},
	"toybox": {"id": "spring", "name": "Spring Loaded", "text": "Hard bounces kick it on +%s%%",
		"race": "Bounces off the course faster"},
	"nature": {"id": "thorn", "name": "Regrowth", "text": "Heals and breaks free every %ss",
		"race": "Shakes off slows and stuns, rolls on"},
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


## Every rank bought in `family`'s tree (0 to 40).
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
## {tough, power, swift} as shares (0.25 = +25%) and, once it has a rank, the
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


## A talent's line at `r` ranks ("+15% HP", "A power rush every 6.5s").
static func line(talent: Dictionary, r: int) -> String:
	return _fill(talent.full if r >= MAX_RANK and talent.has("full") else talent.text, _value(talent, r))


## A talent's short form at `r` ranks, for summaries ("+15% HP", "Scorch 3/10").
static func short(talent: Dictionary, r: int) -> String:
	if talent.has("short"):
		return _fill(talent.short, _value(talent, r))
	return "%s %d/%d" % [talent.name, r, MAX_RANK]


## `family`'s talents you have, on one line ("+15% HP · +5% dmg · Scorch
## 3/10"), or "" with none.
static func summary(profile, family: String) -> String:
	var parts := []
	for tal in talents(family):
		var r := rank(profile, family, tal.id)
		if r > 0:
			parts.append(short(tal, r))
	return " · ".join(parts)


## The number a talent shows at `r` ranks: whole, or to one decimal under 10.
static func _value(talent: Dictionary, r: int) -> String:
	var v: float = talent.per * r * 100.0 if talent.has("per") else Plunge.shown(talent.id, float(r) / MAX_RANK)
	return str(roundi(v)) if absf(v - roundf(v)) < 0.05 or v >= 10.0 else "%.1f" % v


static func _fill(text: String, v: String) -> String:
	var args := []
	for k in text.count("%s"):
		args.append(v)
	return text % args if not args.is_empty() else text
