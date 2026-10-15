## Plays simulated players through the economy in meta/economy.gd, day by day,
## and records when each pacing milestone first happens. Pure logic with the
## deterministic sim/rng.gd, so the same seed gives the same report.
##
## Sources of copies are the ones the game has: campaign wins (meta/campaign.gd
## rules: a featured copy per win, a small next-rarity-up chance, the beaten
## enemy and the boss reward on first clears) and the Summon Portal, fed by
## the Summon Orb income in meta/economy.gd. Energy follows meta/profile.gd:
## a 60 bar, losses cost 1, and every account level refills the bar.
##
## What a player does each session: x10 summons while they have 10 orbs, then
## spends energy pushing the next campaign stage while it is winnable, else
## farming (sweeping) the highest stage they win comfortably, and fuses every
## stack of 3 as soon as it is ready. Critters are the launch set in
## meta/economy.gd; only their rarity matters to the economy.
##
## Zone 1 is the built Glow Garden (meta/zones.gd). Zones 2-7 are an assumed
## curve until they are built: each starts at 90% of the last boss and climbs
## 40% to its own boss, with pairs in zone 2 and trios after.
extends RefCounted

const Economy := preload("res://meta/economy.gd")
const Rng := preload("res://sim/rng.gd")

## Sessions a day, minutes a session and the chance of playing on a given
## day. Sessions are at least 5 hours apart, so each starts on a full bar, and
## ends when the energy or the minutes run out. The regular player is pve.md's
## "~15-20 minutes a day".
const ARCHETYPES := {
	"casual": {"sessions": 1, "minutes": 10.0, "play_chance": 0.7},
	"regular": {"sessions": 2, "minutes": 9.0, "play_chance": 1.0},
	"heavy": {"sessions": 4, "minutes": 15.0, "play_chance": 1.0},
}
const FIGHT_MINUTES := 1.0 ## A watched fight (~45 s) plus the screens around it.
const SWEEP_MINUTES := 0.1 ## A 3-starred stage swept off-screen.

const ENERGY_MAX := 60
const ENERGY_PACK := 30 ## The one Energy Pack every new save starts with.
const STAGE_COST := 6
const BOSS_COST := 10
const LOSS_COST := 1
const WIN_XP_BASE := 10
const WIN_XP_PER_STAGE := 4
const LOSS_XP := 3

## Win chance against a stage: 60% at Recommended Power, ~85% one tier
## above (pve.md section 3).
const WIN_SLOPE := 6.0
const WIN_BIAS := 0.4
const PUSH_MIN := 0.45 ## Players try the next stage at this win chance or better.
const FARM_MIN := 0.75 ## And farm stages they win at least this often.

const ZONE_STAGES := 10 ## Then a boss.
const LATER_ZONES := 6
const ZONE_DIP := 0.9
const ZONE_CLIMB := 1.4

const ZONE1_POWER := [0.75, 0.82, 0.89, 0.97, 1.06, 1.15, 1.26, 1.37, 1.49, 1.63, 1.75]

const MILESTONES := ["first_fusion", "t2_uncommon", "t3_common", "t2_rare", "legendary", "t4", "t5_common"]

var cfg: Dictionary
var rng
var zones: Array = []
var pools := {}
var _rank_of := {}

# Player state.
var day := 0
var session := 0
var energy := 0
var minutes := 0.0
var account_level := 1
var account_xp := 0
var orbs := 0
var pity := 0
var streak := 0
var zone := 0
var stage := 0
var cleared := {}
## id -> {tiers: [count at T1..T5], best: best tier, level, xp}
var owned := {}
var wishlist: Array = []
var use_wishlist := false
## Average power of the best 1, 2 and 3 critters; rebuilt after a change.
var _team: Array = []
var _team_ids: Array = []
## Milestone -> day, plus "first_fusion_session".
var hit := {}
## Totals for the report.
var stats := {"energy": 0, "wins": 0, "copies": 0, "orbs": 0, "summons": 0, "zone": 0, "days_played": 0}


func _init(config: Dictionary, seed_value: int, wishlist_on := false) -> void:
	cfg = config
	rng = Rng.new(seed_value)
	use_wishlist = wishlist_on
	_build_zones()
	for r in Economy.RARITIES:
		pools[r] = Economy.LAUNCH[r]
		for id in pools[r]:
			_rank_of[id] = Economy.RARITIES.find(r)


func _build_zones() -> void:
	var powers: Array = ZONE1_POWER.duplicate()
	zones.append({"powers": powers, "lineup": 1})
	for z in LATER_ZONES:
		var start: float = powers[-1] * ZONE_DIP
		powers = []
		for s in ZONE_STAGES + 1:
			powers.append(start * pow(ZONE_CLIMB, float(s) / ZONE_STAGES))
		zones.append({"powers": powers, "lineup": 2 if z == 0 else 3})


## Plays `days` days as `archetype` and returns {milestone: day}. A milestone
## not reached is left out.
func play(archetype: String, days: int) -> Dictionary:
	var a: Dictionary = ARCHETYPES[archetype]
	_new_game()
	var played_yesterday := false
	for d in range(1, days + 1):
		day = d
		if d > 1 and rng.next_float() >= a.play_chance:
			played_yesterday = false
			continue
		streak = streak + 1 if played_yesterday else 1
		played_yesterday = true
		stats.days_played += 1
		_orbs(cfg.orbs_daily + (cfg.orbs_streak if streak % 7 == 0 else 0))
		for s in a.sessions:
			session += 1
			energy = maxi(energy, ENERGY_MAX)
			if session == 1:
				energy += ENERGY_PACK
			minutes = a.minutes
			_play_session()
		if hit.size() > MILESTONES.size():
			break
	return hit


func _new_game() -> void:
	orbs = cfg.starter_orbs
	pity = cfg.pity
	# Onboarding (design/onboarding.md): the starter is fused to T2 in the
	# tutorial, then one free summon.
	owned["vampire"] = {"tiers": [0, 1, 0, 0, 0], "best": 2, "level": 1, "xp": 0}
	_add(_roll(false))
	_team = []


func _play_session() -> void:
	_summon_all()
	while energy >= LOSS_COST and minutes > 0.0:
		var played := false
		if zone < zones.size() and _win_chance(_stage_power(zone, stage), zones[zone].lineup) >= PUSH_MIN:
			played = _run_stage(zone, stage)
		else:
			played = _farm()
		if not played:
			return
		_summon_all()


## Plays one stage; returns false when energy is short.
func _run_stage(z: int, s: int) -> bool:
	var boss := s == ZONE_STAGES
	var cost := BOSS_COST if boss else STAGE_COST
	if energy < cost:
		return false
	var lineup: int = zones[z].lineup
	var team := _lineup(lineup)
	var p := _win_chance(_stage_power(z, s), lineup)
	# A cleared stage won comfortably stands in for 3 stars: it is swept.
	minutes -= SWEEP_MINUTES if cleared.has(z * 100 + s) and p >= FARM_MIN else FIGHT_MINUTES * lineup
	if rng.next_float() >= p:
		energy -= LOSS_COST
		stats.energy += LOSS_COST
		_account_xp(LOSS_COST)
		for id in team:
			_xp(id, LOSS_XP)
		return true
	energy -= cost
	stats.energy += cost
	stats.wins += 1
	for id in team:
		_xp(id, WIN_XP_BASE + WIN_XP_PER_STAGE * s)
	var drops: Array = []
	var zd: Dictionary = cfg.zone_drops[z]
	if rng.next_float() < cfg.campaign_drop:
		if rng.next_float() < cfg.campaign_bonus:
			drops.append(_pick(zd.bonus))
		else:
			drops.append(_pick(zd.featured))
	else:
		_orbs(cfg.get("orbs_win", 0))
	var key := z * 100 + s
	if not cleared.has(key):
		cleared[key] = true
		drops.append(zd.enemies[s] if zd.has("enemies") else zd.featured[s % zd.featured.size()])
		if boss:
			drops.append(zd.boss)
			_orbs(cfg.orbs_boss)
		if z == zone and s == stage:
			stage += 1
			if stage > ZONE_STAGES:
				zone += 1
				stage = 0
	for id in drops:
		_add(id)
	_account_xp(cost)
	return true


## Replays (sweeps) a cleared stage the player wins comfortably, in the zone
## that drops the critter they are furthest along with (pve.md: "I need 2 more
## T2 Optics" is a goal you farm), the highest such stage.
func _farm() -> bool:
	var best_z := -1
	var best_s := 0
	var best_score := -1
	for z in range(mini(zone, zones.size() - 1), -1, -1):
		var p: float = _team_power(zones[z].lineup)
		for s in range(ZONE_STAGES, -1, -1):
			if cleared.has(z * 100 + s) and _win_chance(_stage_power(z, s), zones[z].lineup, p) >= FARM_MIN:
				var score := 0
				for id in cfg.zone_drops[z].featured:
					if owned.has(id):
						score = maxi(score, _copies(id))
				if score > best_score:
					best_score = score
					best_z = z
					best_s = s
				break
	if best_z < 0:
		return _run_stage(0, 0)
	return _run_stage(best_z, best_s)


# --- Summons --------------------------------------------------------------------

func _summon_all() -> void:
	while orbs >= 10:
		orbs -= 10
		stats.summons += 10
		var got: Array = []
		for i in 10:
			var need_rare := i == 9 and not got.any(func(id): return _rank(id) >= 2)
			got.append(_roll(need_rare))
		for id in got:
			_add(id)


func _roll(rare_plus: bool) -> String:
	var r: float = rng.next_float() * 100.0
	var rarity := "common"
	var acc := 0.0
	for k in range(Economy.RARITIES.size() - 1, -1, -1):
		acc += cfg.odds[Economy.RARITIES[k]]
		if r < acc:
			rarity = Economy.RARITIES[k]
			break
	if rare_plus and Economy.RARITIES.find(rarity) < 2:
		rarity = "rare"
	if Economy.RARITIES.find(rarity) >= 2:
		pity -= 1
		if pity <= 0:
			rarity = "legendary"
	if rarity == "legendary":
		pity = cfg.pity
	return _pick_in(rarity)


## A critter of `rarity`, wishlisted ones counting double (Summon.WISHLIST_WEIGHT).
func _pick_in(rarity: String) -> String:
	var pool: Array = pools[rarity]
	if wishlist.is_empty():
		return _pick(pool)
	var total := 0.0
	for id in pool:
		total += 2.0 if id in wishlist else 1.0
	var r: float = rng.next_float() * total
	for id in pool:
		r -= 2.0 if id in wishlist else 1.0
		if r < 0.0:
			return id
	return pool[-1]


func _orbs(n: int) -> void:
	orbs += n
	stats.orbs += n


# --- Collection -----------------------------------------------------------------

func _add(id: String) -> void:
	stats.copies += 1
	if not owned.has(id):
		owned[id] = {"tiers": [0, 0, 0, 0, 0], "best": 1, "level": 1, "xp": 0}
	var o: Dictionary = owned[id]
	var t: Array = o.tiers
	t[0] += 1
	# Fuse every ready stack of 3; the result keeps the highest level.
	for tier in Economy.MAX_TIER - 1:
		while t[tier] >= 3:
			t[tier] -= 3
			t[tier + 1] += 1
			o.best = maxi(o.best, tier + 2)
			if not hit.has("first_fusion"):
				hit.first_fusion = day
				hit.first_fusion_session = session
	_team = []
	var tier: int = o.best
	var rank := _rank(id)
	_mark("t2_uncommon", tier >= 2 and rank >= 1)
	_mark("t3_common", tier >= 3 and rank == 0)
	_mark("t2_rare", tier >= 2 and rank >= 2)
	_mark("legendary", rank == 4)
	_mark("t4", tier >= 4)
	_mark("t5_common", tier >= 5 and rank == 0)
	if use_wishlist and rank >= 2:
		_update_wishlist()


func _mark(name: String, reached: bool) -> void:
	if reached and not hit.has(name):
		hit[name] = day


## Wishlist the three Rare-or-better critters with the most copies.
func _update_wishlist() -> void:
	var ids: Array = owned.keys().filter(func(id): return _rank(id) >= 2)
	ids.sort_custom(func(a, b): return _copies(a) > _copies(b))
	wishlist = ids.slice(0, 3)


func _copies(id: String) -> int:
	var t: Array = owned[id].tiers
	return t[0] + 3 * t[1] + 9 * t[2] + 27 * t[3] + 81 * t[4]


# --- Power, levels and account --------------------------------------------------

func _power_of(id: String) -> float:
	var o: Dictionary = owned[id]
	return Economy.power(_rarity(id), o.best, o.level)


## The strongest `n` critters, best first.
func _lineup(n: int) -> Array:
	_rebuild_team()
	return _team_ids.slice(0, n)


## Average power of the best `n` critters; a missing ball counts as zero.
func _team_power(n: int) -> float:
	_rebuild_team()
	return _team[n - 1]


func _rebuild_team() -> void:
	if not _team.is_empty():
		return
	var ids: Array = owned.keys()
	ids.sort_custom(func(a, b): return _power_of(a) > _power_of(b))
	_team_ids = ids.slice(0, 3)
	var sum := 0.0
	for i in 3:
		sum += _power_of(_team_ids[i]) if i < _team_ids.size() else 0.0
		_team.append(sum / (i + 1))


func _win_chance(enemy: float, lineup: int, player := -1.0) -> float:
	if player < 0.0:
		player = _team_power(lineup)
	if player <= 0.0:
		return 0.0
	var x := WIN_SLOPE * log(player / enemy) + WIN_BIAS
	return clampf(1.0 / (1.0 + exp(-x)), 0.02, 0.98)


func _stage_power(z: int, s: int) -> float:
	return zones[z].powers[s]


func _xp(id: String, amount: int) -> void:
	var o: Dictionary = owned[id]
	var cap: int = o.best * 10
	if o.level >= cap:
		return
	o.xp += amount
	while o.level < cap and o.xp >= 10 * o.level:
		o.xp -= 10 * o.level
		o.level += 1
		_team = []
	if o.level >= cap:
		o.xp = 0


func _account_xp(amount: int) -> void:
	account_xp += amount
	while account_xp >= 20 + 10 * account_level:
		account_xp -= 20 + 10 * account_level
		account_level += 1
		energy = maxi(energy, ENERGY_MAX)
		_orbs(cfg.orbs_level)


# --- Helpers --------------------------------------------------------------------

func _pick(list: Array):
	return list[rng.range_int(0, list.size() - 1)]


func _rarity(id: String) -> String:
	return Economy.RARITIES[_rank_of[id]]


func _rank(id: String) -> int:
	return _rank_of[id]


## Runs `players` players of each archetype for `days` days. Returns
## {archetype: {milestone: sorted days (unreached = days + 1), "per_day": {stat: average per day played}}}.
static func report(config: Dictionary, players: int, days: int, seed_value := 1, wishlist_on := false, archetypes := ARCHETYPES.keys()) -> Dictionary:
	var out := {}
	var n := 0
	for archetype in archetypes:
		var rows := {"first_fusion_session": []}
		for m in MILESTONES:
			rows[m] = []
		var totals := {}
		for i in players:
			n += 1
			var model = load("res://meta/economy_model.gd").new(config, seed_value * 1000003 + n, wishlist_on)
			var h: Dictionary = model.play(archetype, days)
			for m in MILESTONES:
				rows[m].append(h.get(m, days + 1))
			rows.first_fusion_session.append(h.get("first_fusion_session", 999))
			model.stats.zone = model.zone * model.stats.days_played # Reported as the zone reached.
			for k in model.stats:
				if k != "days_played":
					totals[k] = totals.get(k, 0.0) + float(model.stats[k]) / model.stats.days_played / players
		for m in rows:
			rows[m].sort()
		rows["per_day"] = totals
		out[archetype] = rows
	return out


static func median(sorted: Array) -> float:
	var n := sorted.size()
	return sorted[n / 2] if n % 2 == 1 else (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0


static func percentile(sorted: Array, p: float) -> float:
	return sorted[clampi(int(p * (sorted.size() - 1) + 0.5), 0, sorted.size() - 1)]
