## Faction talent trees (design/talents.md in the project files). Every critter
## belongs to one of nine factions (roster.md's theme families). Each faction
## has one account-wide tree: 30 points over 12 nodes (3 ranks each) and a
## 4-point capstone, with rows opened by points spent lower down. A critter
## only uses the rows its tier unlocks (T1 row 1 ... T4 row 4, T5 the capstone).
##
## A slot carries its tree as `talents: {node_id: rank}` (sim/lineup.gd), so a
## fight replays from the slots, the seed and the launch angles alone. Every
## effect is deterministic: timers, HP lines and counters, never its own
## random numbers. Gear owns the flat stat lines; talents are conditional or
## faction flavour, and anything touching a gear stat stays under Gear's caps.
extends RefCounted

const Gear := preload("res://sim/gear.gd")

const MAX_POINTS := 30
const MAX_RANK := 3
const CAPSTONE_COST := 4
## Points spent in the rows below that open a row (index = row - 1; row 5 is the capstone).
const ROW_GATE := [0, 5, 12, 20, 26]
## Power Rating per active point (a full active tree is about +10%).
const POINT_POWER := 0.0033
## Every scaled node's `per` is multiplied by this (tools/talent_check.gd tunes
## it so a full tree fights like about +10% power).
const STRENGTH := 0.25
## Relay bonus from a capstone: per other same-faction critter in the team.
const BOND_POWER := 0.02
const BOND_MAX := 2

const FACTIONS := ["fire", "frost", "nature", "sea", "tech", "spooky", "cosmic", "sweet", "toybox"]
const NAMES := {"fire": "Fire", "frost": "Frost", "nature": "Nature", "sea": "Sea", "tech": "Tech",
	"spooky": "Spooky", "cosmic": "Cosmic", "sweet": "Sweet", "toybox": "Toybox"}
const COLORS := {"fire": Color("ff7a3d"), "frost": Color("8fe3ff"), "nature": Color("6ee36b"), "sea": Color("3db8ff"),
	"tech": Color("ffd84a"), "spooky": Color("b07bff"), "cosmic": Color("ff6bd6"), "sweet": Color("ff9ec4"), "toybox": Color("ff5a5a")}
const MEMBERS := {
	"fire": ["bomber", "drako", "magmo", "phoenix", "sooty", "speedster", "supernova"],
	"frost": ["blizz", "drizzle", "frost", "frostfang", "glacia", "gust", "mammoth", "narwhal", "pounce", "yeti"],
	"nature": ["glowbug", "ivy", "juggernaut", "mole", "mossy", "old_oak", "pip", "pollen", "spiker", "sprout", "swarm", "thorns", "tumble", "whiff", "zing"],
	"sea": ["beacon", "bubbles", "clam", "fin", "hook", "ink", "kraken", "leviathan", "minnow", "puff", "ripple", "shelly"],
	"tech": ["bolt", "clockwork", "cogs", "gearbox", "laser", "magnet", "megabot", "mirror", "static", "wrecker", "zapper", "zigzag"],
	"spooky": ["brewster", "flicker", "foxfire", "ghost", "puppeteer", "sonar", "totem", "vampire"],
	"cosmic": ["blackhole", "comet", "eclipse", "gravity", "prism", "quasar", "stormwing"],
	"sweet": ["bonbon", "crumb", "fizz", "gumdrop", "honey", "jawbreaker", "munch", "pucker", "splitter", "sundae"],
	"toybox": ["disco", "drum", "jackpot", "kaleido", "mortar", "painter", "pinball", "pixel", "yoyo"],
}

## Nodes every tree shares. Column 0 is Core, column 2 Ability; column 1 is
## the faction's own (FACTION_NODES). `per` is the effect value per rank;
## `text` takes that value (as a % where `pct`).
const SHARED := [
	{"id": "launch_kick", "row": 1, "col": 0, "name": "Launch Kick", "per": 0.03, "text": "+%s damage in the first 4s"},
	{"id": "spark", "row": 1, "col": 2, "name": "Spark", "per": 0.03, "text": "+%s ability damage"},
	{"id": "rebound", "row": 2, "col": 0, "name": "Rebound", "per": 0.04, "text": "+%s on your first contact hit after a wall bounce"},
	{"id": "charged", "row": 2, "col": 2, "name": "Charged", "per": 0.04, "text": "+%s ability damage above 50%% HP"},
	{"id": "last_stand", "row": 3, "col": 0, "name": "Last Stand", "per": 0.04, "text": "-%s damage taken below 35%% HP"},
	{"id": "ward", "row": 3, "col": 2, "name": "Ward", "per": 0.03, "text": "-%s ability damage taken"},
	{"id": "comeback", "row": 4, "col": 0, "name": "Comeback", "per": 0.04, "text": "+%s dmg while behind on HP"},
	{"id": "overcharge", "row": 4, "col": 2, "name": "Overcharge", "per": 0.04, "text": "+%s ability damage to foes below 50%% HP"},
]

## Each faction's column 1 (rows 1-4) and capstone (row 5, one rank).
const FACTION_NODES := {
	"fire": [
		{"id": "kindling", "name": "Kindling", "per": 1.0, "unit": "dps", "text": "Contact hits burn %s for 1.5s"},
		{"id": "hot_start", "name": "Hot Start", "per": 0.03, "text": "+%s damage in the first 8s"},
		{"id": "flashpoint", "name": "Flashpoint", "per": 0.04, "text": "+%s damage to burning foes"},
		{"id": "heatproof", "name": "Heatproof", "per": 0.12, "text": "-%s burn damage taken"},
		{"id": "wildfire", "name": "Wildfire", "per": 1.0, "unit": "x", "text": "Kindling burns x2"},
	],
	"frost": [
		{"id": "frostbite", "name": "Frostbite", "per": 0.07, "text": "Contact hits slow the foe %s for 1s"},
		{"id": "thick_fur", "name": "Thick Fur", "per": 0.025, "text": "-%s contact damage taken"},
		{"id": "shatter", "name": "Shatter", "per": 0.06, "text": "+%s damage to slowed foes"},
		{"id": "thaw", "name": "Thaw", "per": 0.15, "text": "Slows on you are %s weaker"},
		{"id": "deep_freeze", "name": "Deep Freeze", "per": 1.0, "unit": "x", "text": "Shatter bonus x2"},
	],
	"nature": [
		{"id": "photosynth", "name": "Photosynth", "per": 0.0012, "text": "Regrow %s of max HP each second (not while burning)"},
		{"id": "bark", "name": "Bark", "per": 0.03, "text": "-%s ability damage taken"},
		{"id": "bloom", "name": "Bloom", "per": 0.08, "text": "Your heals are %s bigger"},
		{"id": "deep_roots", "name": "Deep Roots", "per": 0.03, "text": "-%s damage taken below 50%% HP"},
		{"id": "overgrowth", "name": "Overgrowth", "per": 1.0, "unit": "x", "text": "Photosynth x2 below 50%% HP"},
	],
	"sea": [
		{"id": "undertow", "name": "Undertow", "per": 0.06, "text": "+%s speed for 1s after you land a contact hit"},
		{"id": "slick", "name": "Slick", "per": 0.05, "text": "+%s speed for 1s after you're hit"},
		{"id": "tidal", "name": "Tidal", "per": 0.05, "text": "+%s on your next hit after you're hit"},
		{"id": "brine", "name": "Brine", "per": 0.12, "text": "-%s burn damage taken"},
		{"id": "riptide", "name": "Riptide", "per": 0.12, "text": "Undertow also slows the foe %s for 1s"},
	],
	"tech": [
		{"id": "overclock", "name": "Overclock", "per": 0.015, "text": "+%s damage for every 10s of fight (up to 3 times)"},
		{"id": "firmware", "name": "Firmware", "per": 0.03, "text": "+%s ability damage"},
		{"id": "capacitor", "name": "Capacitor", "per": 0.12, "text": "Every 4th contact hit deals +%s"},
		{"id": "shielding", "name": "Shielding", "per": 0.03, "text": "-%s ability damage taken"},
		{"id": "overdrive", "name": "Overdrive", "per": 2.0, "unit": "stacks", "text": "Overclock builds up to 5 times"},
	],
	"spooky": [
		{"id": "siphon", "name": "Siphon", "per": 0.04, "text": "Heal %s of the contact damage you deal (not while burning)"},
		{"id": "haunt", "name": "Haunt", "per": 0.025, "text": "Foes you hit deal -%s damage for 1.5s"},
		{"id": "fright", "name": "Fright", "per": 0.05, "text": "+%s damage on backstabs"},
		{"id": "ectoplasm", "name": "Ectoplasm", "per": 0.02, "text": "Heal %s of the ability damage you deal"},
		{"id": "undying", "name": "Undying", "per": 0.10, "text": "Once, below 15%% HP: heal %s of max HP"},
	],
	"cosmic": [
		{"id": "starlight", "name": "Starlight", "per": 0.025, "text": "+%s crit chance"},
		{"id": "nova", "name": "Nova", "per": 0.08, "text": "+%s crit damage"},
		{"id": "comet_tail", "name": "Comet Tail", "per": 0.06, "text": "Your crits slow the foe %s for 1s"},
		{"id": "stardust", "name": "Stardust", "per": 0.08, "text": "-%s damage from crits"},
		{"id": "supernova_cap", "name": "Supernova", "per": 1.0, "unit": "x", "text": "Your first crit each fight deals x2"},
	],
	"sweet": [
		{"id": "sugar_shell", "name": "Sugar Shell", "per": 0.02, "text": "Start with a shield of %s max HP"},
		{"id": "sticky", "name": "Sticky", "per": 0.04, "text": "Contact hits slow the foe %s for 0.5s"},
		{"id": "sugar_rush", "name": "Sugar Rush", "per": 0.03, "text": "+%s damage while shielded"},
		{"id": "refill", "name": "Refill", "per": 0.015, "text": "Gain a shield of %s max HP every 10s"},
		{"id": "candy_coat", "name": "Candy Coat", "per": 1.0, "unit": "x", "text": "Sugar Shell x2"},
	],
	"toybox": [
		{"id": "bouncy", "name": "Bouncy", "per": 0.03, "text": "+%s speed for 1s after each wall bounce"},
		{"id": "combo", "name": "Combo", "per": 0.015, "text": "+%s on a contact hit within 2s of your last one"},
		{"id": "trick_shot", "name": "Trick Shot", "per": 0.025, "text": "+%s damage within 0.5s of a wall bounce"},
		{"id": "spring", "name": "Spring", "per": 0.03, "text": "-%s damage taken within 1s of a wall bounce"},
		{"id": "jackpot_cap", "name": "Jackpot", "per": 1.0, "unit": "x", "text": "Bouncy and Trick Shot x1.5"},
	],
}

static var _faction_of := {}
static var _trees := {}


## The faction a critter belongs to, or "" for none (Plain, test balls).
static func faction_of(critter: String) -> String:
	if _faction_of.is_empty():
		for f in MEMBERS:
			for id in MEMBERS[f]:
				_faction_of[id] = f
	return _faction_of.get(critter, "")


## A faction's 13 nodes, each {id, row, col, name, per, text, max, cost}.
static func tree(faction: String) -> Array:
	if _trees.has(faction):
		return _trees[faction]
	var out: Array = []
	if not FACTION_NODES.has(faction):
		return out
	for n in SHARED:
		var d: Dictionary = n.duplicate()
		d.max = MAX_RANK
		d.cost = 1
		out.append(d)
	var own: Array = FACTION_NODES[faction]
	for i in own.size():
		var d: Dictionary = own[i].duplicate()
		d.row = i + 1
		d.col = 1
		d.max = MAX_RANK if i < 4 else 1
		d.cost = 1 if i < 4 else CAPSTONE_COST
		out.append(d)
	out.sort_custom(func(a, b): return a.row < b.row or (a.row == b.row and a.col < b.col))
	_trees[faction] = out
	return out


static func node(faction: String, id: String) -> Dictionary:
	for n in tree(faction):
		if n.id == id:
			return n
	return {}


## Points a set of picks costs.
static func spent(faction: String, picks: Dictionary, below_row := 99) -> int:
	var total := 0
	for n in tree(faction):
		if n.row < below_row:
			total += int(picks.get(n.id, 0)) * int(n.cost)
	return total


## True when `row` is open for these picks (enough points spent below it).
static func row_open(faction: String, picks: Dictionary, row: int) -> bool:
	return spent(faction, picks, row) >= ROW_GATE[row - 1]


## Highest row a critter at `tier` uses: T1 row 1 ... T4 row 4, T5 the capstone.
static func rows_for_tier(tier: int) -> int:
	return clampi(tier, 1, 5)


## Picks inside the rules for `faction`: known nodes, ranks within max, rows
## only when open, at most MAX_POINTS. With `tier`, rows above it are dropped
## (they still count as spent for opening rows, so a full tree on a low-tier
## critter just has its top idle). Order is fixed (row by row) so a tampered
## save can't change which points survive the cap.
static func clean(faction: String, picks, tier := 5) -> Dictionary:
	var out := {}
	if not picks is Dictionary or tree(faction).is_empty():
		return out
	var budget := MAX_POINTS
	var kept := {}
	for n in tree(faction):
		var r := clampi(int(picks.get(n.id, 0)), 0, int(n.max))
		if r <= 0 or not row_open(faction, kept, n.row):
			continue
		r = mini(r, budget / int(n.cost))
		if r <= 0:
			continue
		budget -= r * int(n.cost)
		kept[n.id] = r
	for id in kept:
		if node(faction, id).row <= rows_for_tier(tier):
			out[id] = kept[id]
	return out


## A sensible full 30-point build: rows 1-2 full, Core and the faction node in
## row 3, two ranks of the faction's row 4 node, and the capstone. Used by the
## talent check (tools/talent_check.gd), tests and as a "Suggested" fill.
static func suggested(faction: String) -> Dictionary:
	var picks := {}
	for n in tree(faction):
		if n.row <= 2 or (n.row == 3 and n.col <= 1):
			picks[n.id] = MAX_RANK
		elif n.row == 4 and n.col == 1:
			picks[n.id] = 2
		elif n.row == 5:
			picks[n.id] = 1
	return clean(faction, picks)


## Effect values from cleaned picks: {node_id: rank * per}.
static func effects(faction: String, picks: Dictionary) -> Dictionary:
	var out := {}
	for id in picks:
		var n := node(faction, id)
		if not n.is_empty():
			out[id] = float(picks[id]) * value_per_rank(n)
	return out


## Power a slot's active talents add, as a fraction (Power Rating only; fights
## use the effects themselves).
static func power(faction: String, picks: Dictionary) -> float:
	return minf(POINT_POWER * spent(faction, picks), POINT_POWER * MAX_POINTS)


## A node's effect per rank: `per`, scaled by STRENGTH unless it's a switch
## or a count (capstones like Wildfire, Overdrive, Jackpot).
static func value_per_rank(n: Dictionary) -> float:
	if n.has("unit") and n.unit != "dps":
		return float(n.per)
	return float(n.per) * STRENGTH


## One line describing a node at `rank` (rank 0 shows rank 1's numbers).
static func describe(n: Dictionary, rank: int) -> String:
	var v: float = value_per_rank(n) * maxi(1, rank)
	if n.has("unit"):
		if n.unit == "dps":
			return n.text % ("%s/s" % String.num(v, 2))
		return n.text
	var pct := 100.0 * v
	var s := ("%d%%" % roundi(pct)) if absf(pct - roundf(pct)) < 0.05 else ("%.1f%%" % pct)
	return n.text % s


# --- Fight hooks (sim/match_sim.gd calls these; t = the ball's effects) -------

const KICK_SECS := 4.0
const HOT_SECS := 8.0


## At fight start: crit lines (under Gear's caps) and starting shield.
static func setup(sim, b) -> void:
	var t: Dictionary = b.tal
	if t.is_empty():
		return
	if t.has("starlight"):
		b.crit_chance = minf(b.crit_chance + t.starlight, sim.BASE_CRIT_CHANCE + float(Gear.LINES.crit_chance.max))
	if t.has("nova"):
		b.crit_mult = minf(b.crit_mult + t.nova, sim.BASE_CRIT_MULT + float(Gear.LINES.crit_damage.max))
	if t.has("sugar_shell"):
		b.shield += b.max_hp * t.sugar_shell * (2.0 if t.has("candy_coat") else 1.0)


## Damage multiplier from the source's and target's talents for one hit,
## before rolls. Reads (never changes) state, except one-shot flags.
static func hit_mult(sim, source, target, h: Dictionary) -> float:
	var m := 1.0
	var s: Dictionary = source.tal
	var now: float = sim.time()
	var contact: bool = h.kind == "contact"
	if not s.is_empty():
		if now < KICK_SECS:
			m *= 1.0 + s.get("launch_kick", 0.0)
		if now < HOT_SECS:
			m *= 1.0 + s.get("hot_start", 0.0)
		if contact and source.banked:
			m *= 1.0 + s.get("rebound", 0.0)
		if not contact:
			m *= 1.0 + s.get("spark", 0.0) + s.get("firmware", 0.0)
			if source.hp > 0.5 * source.max_hp:
				m *= 1.0 + s.get("charged", 0.0)
			if target.hp < 0.5 * target.max_hp:
				m *= 1.0 + s.get("overcharge", 0.0)
		if s.has("comeback") and source.hp / source.max_hp < target.hp / target.max_hp:
			m *= 1.0 + s.comeback
		if s.has("flashpoint") and not target.dots.is_empty():
			m *= 1.0 + s.flashpoint
		if s.has("shatter") and target.slow > 0.0:
			m *= 1.0 + s.shatter * (2.0 if s.has("deep_freeze") else 1.0)
		if s.has("overclock"):
			var cap := 3 + int(s.get("overdrive", 0.0))
			m *= 1.0 + s.overclock * mini(cap, int(now / 10.0))
		if s.has("capacitor") and contact and (int(source.tal_state.get("contacts", 0)) + 1) % 4 == 0:
			m *= 1.0 + s.capacitor
		if s.has("fright") and h.get("backstab", false):
			m *= 1.0 + s.fright
		if s.has("sugar_rush") and source.shield > 0.0:
			m *= 1.0 + s.sugar_rush
		if s.has("combo") and contact and sim.tick - int(source.tal_state.get("last_contact", -100000)) <= 2 * sim.TICK_RATE:
			m *= 1.0 + s.combo
		if s.has("trick_shot") and sim.tick - int(source.tal_state.get("bounce_tick", -100000)) <= sim.TICK_RATE / 2:
			m *= 1.0 + s.trick_shot * (1.5 if s.has("jackpot_cap") else 1.0)
		if s.has("tidal") and source.tal_state.get("tidal", false):
			source.tal_state.tidal = false
			m *= 1.0 + s.tidal
	var hs: Dictionary = source.tal_state.get("haunted", {})
	if not hs.is_empty() and sim.tick < int(hs.until):
		m *= 1.0 - float(hs.amount)
	var t: Dictionary = target.tal
	if not t.is_empty():
		if target.hp < 0.35 * target.max_hp:
			m *= 1.0 - t.get("last_stand", 0.0)
		if target.hp < 0.5 * target.max_hp:
			m *= 1.0 - t.get("deep_roots", 0.0)
		if contact:
			m *= 1.0 - t.get("thick_fur", 0.0)
		else:
			m *= 1.0 - t.get("ward", 0.0) - t.get("bark", 0.0) - t.get("shielding", 0.0)
		if h.kind == "burn":
			m *= 1.0 - t.get("heatproof", 0.0) - t.get("brine", 0.0)
		if t.has("spring") and sim.tick - int(target.tal_state.get("bounce_tick", -100000)) <= sim.TICK_RATE:
			m *= 1.0 - t.spring
	return maxf(0.0, m)


## Crit damage after the roll: Supernova and Stardust (and Comet Tail's slow).
static func crit_mult(sim, source, target, crit: bool) -> Dictionary:
	var s: Dictionary = source.tal
	var mult := 1.0
	if crit:
		mult = source.crit_mult
		if s.has("supernova_cap") and not source.tal_state.get("crit_done", false):
			mult *= 2.0
		source.tal_state.crit_done = true
		mult = 1.0 + (mult - 1.0) * (1.0 - target.tal.get("stardust", 0.0))
		if s.has("comet_tail"):
			slow(sim, target, s.comet_tail, 1.0)
	return {"crit": crit, "mult": mult}


## After damage lands: contact riders (burn, slow, heal, haunt, speed) and
## ability-damage heals. `heals` is the tick's heal queue.
static func after_hit(sim, source, target, amount: float, kind: String, heals: Array) -> void:
	var s: Dictionary = source.tal
	if not s.is_empty():
		if kind == "contact":
			source.tal_state.contacts = int(source.tal_state.get("contacts", 0)) + 1
			source.tal_state.last_contact = sim.tick
			if s.has("kindling"):
				sim.add_burn(source, target, s.kindling * (2.0 if s.has("wildfire") else 1.0), 1.5)
			if s.has("frostbite"):
				slow(sim, target, s.frostbite, 1.0)
			if s.has("sticky"):
				slow(sim, target, s.sticky, 0.5)
			if s.has("siphon") and source.dots.is_empty():
				heals.append({"ball": source.index, "amount": amount * s.siphon})
			if s.has("haunt"):
				target.tal_state.haunted = {"amount": s.haunt, "until": sim.tick + int(1.5 * sim.TICK_RATE)}
			if s.has("undertow"):
				sim.set_mod(source, "t_undertow", {"speed": 1.0 + s.undertow}, 1.0)
				if s.has("riptide"):
					slow(sim, target, s.riptide, 1.0)
		elif s.has("ectoplasm") and source.dots.is_empty():
			heals.append({"ball": source.index, "amount": amount * s.ectoplasm})
	var t: Dictionary = target.tal
	if not t.is_empty() and target.alive():
		if t.has("slick"):
			sim.set_mod(target, "t_slick", {"speed": 1.0 + t.slick}, 1.0)
		if t.has("tidal"):
			target.tal_state.tidal = true


## Every tick, after zones set slows: Thaw, regrowth, shields.
static func tick(sim, b) -> void:
	var t: Dictionary = b.tal
	if not b.alive():
		return
	if t.has("thaw"):
		b.slow *= 1.0 - t.thaw
	if t.has("photosynth") and b.dots.is_empty() and b.hp < b.max_hp:
		var rate: float = t.photosynth * (2.0 if t.has("overgrowth") and b.hp < 0.5 * b.max_hp else 1.0)
		var gained := minf(b.max_hp * rate * sim.DT * (1.0 + t.get("bloom", 0.0)), b.max_hp - b.hp)
		b.hp += gained
		b.healed += gained
	if t.has("refill") and sim.tick > 0 and sim.tick % (10 * sim.TICK_RATE) == 0:
		b.shield += b.max_hp * t.refill
		sim.events.append({"type": "shield", "target": b.index, "amount": b.max_hp * t.refill, "pos": b.pos})
	if t.has("undying") and not b.tal_state.get("undying", false) and b.hp < 0.15 * b.max_hp:
		b.tal_state.undying = true
		var gained := minf(b.max_hp * t.undying, b.max_hp - b.hp)
		b.hp += gained
		b.healed += gained
		sim.events.append({"type": "heal", "target": b.index, "amount": gained, "pos": b.pos})


static func on_bounce(sim, b) -> void:
	var t: Dictionary = b.tal
	if t.is_empty():
		return
	b.tal_state.bounce_tick = sim.tick
	if t.has("bouncy"):
		sim.set_mod(b, "t_bouncy", {"speed": 1.0 + t.bouncy * (1.5 if t.has("jackpot_cap") else 1.0)}, 1.0)


## Heal multiplier for a ball's own heals (Bloom).
static func heal_mult(b) -> float:
	return 1.0 + b.tal.get("bloom", 0.0)


## Slows `target` by `amount` for `secs`, through the sim's own slow (the
## strongest current slow wins), capped at half speed.
static func slow(sim, target, amount: float, secs: float) -> void:
	sim.slow_for(target, minf(amount, 0.5), secs)
