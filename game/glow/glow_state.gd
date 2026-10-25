## The player's Glow Gems, cosmetics and Glow Pass, kept in the save file
## (save.data.glow) so they sync with the cloud save like everything else.
##
## Every grant and spend is written to a ledger (the audit trail for support
## and cheat checks). Power rewards from the free track (orbs, coins, energy,
## XP chips, copies) go to the profile (game/ui/ui_profile.gd); this file only
## ever gives gems and cosmetics for money.
##
## Nothing here is read by the fight sim: cosmetics are drawn by
## game/glow/cosmetic_art.gd and never change a fight.
extends RefCounted

const Catalog := preload("res://game/glow/catalog.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const LiveOps := preload("res://game/liveops.gd")
const Quests := preload("res://meta/quests.gd")
const Families := preload("res://sim/families.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const BossesScreen := preload("res://game/ui/screens/bosses_screen.gd")

const LEDGER_MAX := 300

signal changed
## A store purchase finished: ok, and a line to show the player.
signal purchase_finished(product_id: String, ok: bool, message: String)

var save ## SaveGame (or anything with `data` and `commit()`).
var profile ## UiProfile: where free-track power rewards land. May be null.
var store ## Store (game/glow/store.gd). May be null.


func _init(save_, profile_ = null, store_ = null) -> void:
	save = save_
	profile = profile_
	set_store(store_)
	g()


static func defaults() -> Dictionary:
	return {
		"gems": 0,
		"owned": [],
		"equipped": {},
		"unlocks": [], ## Non-consumable products owned (e.g. "founder").
		"txns": [], ## Store transactions already granted (last 100).
		"ledger": [], ## {t, what, n, why}: newest last.
		"pass": {"season": "", "xp": 0, "premium": false, "free": [], "paid": [], "boxes": 0},
		"quest_day": {"day": -1, "list": [], "progress": {}, "claimed": [], "chest": false, "swapped": false, "counted": false},
		"quest_week": {"week": -1, "list": [], "progress": {}, "claimed": [], "chest": false, "won_with": []},
		"quest_carry": [], ## Finished, unclaimed quest rewards from a day or week gone by.
		"week": {"week": -1, "count": 0, "chest": false},
	}


func set_store(s) -> void:
	if store and store.purchased.is_connected(_on_purchased):
		store.purchased.disconnect(_on_purchased)
	if store and store.failed.is_connected(_on_failed):
		store.failed.disconnect(_on_failed)
	store = s
	if store:
		store.purchased.connect(_on_purchased)
		store.failed.connect(_on_failed)


var _checked = null

## The glow part of the save. Filled in with defaults whenever the save's data
## is new (first run, an older save, or a cloud copy just adopted).
func g() -> Dictionary:
	var cur = save.data.get("glow")
	if cur is Dictionary and is_same(cur, _checked):
		return cur
	if not cur is Dictionary:
		cur = {}
	var d := defaults()
	for k in d:
		if not cur.has(k) or not _same_type(cur[k], d[k]):
			cur[k] = d[k]
		elif d[k] is Dictionary:
			for kk in d[k]:
				if not cur[k].has(kk):
					cur[k][kk] = d[k][kk]
	for track in ["free", "paid"]: # Claimed levels: ints again after a JSON trip.
		cur["pass"][track] = cur["pass"][track].map(func(v): return int(v))
	save.data["glow"] = cur
	_checked = cur
	return cur


## JSON turns ints into floats, so numbers count as one type.
static func _same_type(a, b) -> bool:
	var num := [TYPE_INT, TYPE_FLOAT]
	return typeof(a) == typeof(b) or (typeof(a) in num and typeof(b) in num)


func gems() -> int:
	return int(g().gems)


func owns(id: String) -> bool:
	return id in g().owned


## Equipped cosmetic ids by slot, e.g. {"hat": "hat_crown"}. This is what
## the arena draws for you; it never goes into a fight config.
func loadout() -> Dictionary:
	var out := {}
	for slot in Catalog.SLOTS:
		var id: String = str(g().equipped.get(slot, ""))
		if id != "" and owns(id):
			out[slot] = id
	return out


func equipped(slot: String) -> String:
	return str(loadout().get(slot, ""))


func equip(id: String) -> bool:
	var it := Catalog.item(id)
	if it.is_empty() or not owns(id):
		return false
	g().equipped[it.slot] = id
	_commit()
	return true


func unequip(slot: String) -> void:
	g().equipped.erase(slot)
	_commit()


# --- Shop ------------------------------------------------------------------------

## Buys one cosmetic with gems or coins. Returns "" or why it failed.
func buy_item(id: String) -> String:
	var it := Catalog.item(id)
	if it.is_empty() or it.where not in ["shop", "basic"]:
		return "That isn't for sale."
	if owns(id):
		return "You already own it."
	if it.has("coins"):
		if profile == null or not profile.spend_coins(int(it.coins)):
			return "Not enough coins."
		_log("coins", -int(it.coins), "buy " + id)
	else:
		var cost := int(it.gems)
		if gems() < cost:
			return "Not enough Glow Gems."
		_spend_gems(cost, "buy " + id)
	_give_cosmetic(id, "shop")
	_commit()
	return ""


## Buys a bundle at its bundle price; items already owned are skipped, and the
## price drops by their full price so nobody pays twice.
func buy_bundle(id: String) -> String:
	var b := Catalog.bundle(id)
	if b.is_empty():
		return "That isn't for sale."
	var cost := bundle_price(b)
	if cost <= 0:
		return "You already own everything in it."
	if gems() < cost:
		return "Not enough Glow Gems."
	_spend_gems(cost, "buy " + id)
	for item_id in b.items:
		if not owns(item_id):
			_give_cosmetic(item_id, id)
		var slot: String = Catalog.item(item_id).slot
		if equipped(slot) == "":
			g().equipped[slot] = item_id # Fill empty slots so the bundle shows at once.
	_commit()
	return ""


## What a bundle costs you now: its price minus the full price of anything
## in it you already own (never below 0).
func bundle_price(b: Dictionary) -> int:
	var owned_value := 0
	var missing := 0
	for item_id in b.items:
		if owns(item_id):
			owned_value += int(Catalog.item(item_id).get("gems", 0))
		else:
			missing += 1
	return 0 if missing == 0 else maxi(0, int(b.gems) - owned_value)


# --- Store (real money, or the fake store) ----------------------------------------

func _on_purchased(product_id: String, txn: String) -> void:
	var granted := apply_purchase(product_id, txn)
	# Granted now or before: either way the store may finish the transaction.
	store.finish(product_id, txn)
	if granted:
		purchase_finished.emit(product_id, true, _thanks(product_id))


func _on_failed(product_id: String, reason: String) -> void:
	purchase_finished.emit(product_id, false, reason)


static func _thanks(product_id: String) -> String:
	var p := Catalog.product(product_id)
	match p.get("kind", ""):
		"gems":
			return "+%d Glow Gems. Thank you!" % int(p.gems)
		"pass":
			return "Glow Pass unlocked!"
	return "%s unlocked. Thank you!" % p.get("name", product_id)


## Grants a store purchase once per transaction. Returns true if it granted.
func apply_purchase(product_id: String, txn: String, t := -1) -> bool:
	var p := Catalog.product(product_id)
	if p.is_empty() or txn in g().txns:
		return false
	if p.kind == "unlock" and product_id in g().unlocks:
		return false
	if p.kind == "pass" and (season(t).is_empty() or pass_state(t).premium):
		return false
	g().txns.append(txn)
	while g().txns.size() > 100:
		g().txns.pop_front()
	match p.kind:
		"gems":
			_add_gems(int(p.gems), "store " + product_id)
		"pass":
			_unlock_premium("store " + product_id, t)
		"unlock":
			g().unlocks.append(product_id)
			if p.has("gems"):
				_add_gems(int(p.gems), "store " + product_id)
			for id in p.get("items", []):
				_give_cosmetic(id, product_id)
	_commit()
	return true


## Unlocks the premium track with gems instead of money.
func buy_pass_with_gems(t := -1) -> String:
	if season(t).is_empty():
		return "No season is running."
	if pass_state(t).premium:
		return "You already have this season's Glow Pass."
	if gems() < Catalog.PASS_GEMS:
		return "Not enough Glow Gems."
	_spend_gems(Catalog.PASS_GEMS, "glow pass")
	_unlock_premium("gems", t)
	_commit()
	return ""


func _unlock_premium(why: String, t: int) -> void:
	var ps := pass_state(t)
	ps.premium = true
	_log("premium", 1, why + " " + str(ps.season))


# --- Glow Pass ----------------------------------------------------------------

func season(t := -1) -> Dictionary:
	return LiveOps.season(_now(t))


## This season's pass progress. A new season starts a fresh pass (cosmetics,
## gems and everything else you earned stay).
func pass_state(t := -1) -> Dictionary:
	var ps: Dictionary = g()["pass"]
	var name: String = str(season(t).get("name", ""))
	if str(ps.season) != name:
		ps.season = name
		ps.xp = 0
		ps.premium = false
		ps.free = []
		ps.paid = []
		ps.boxes = 0
	return ps


func pass_xp(t := -1) -> int:
	return int(pass_state(t).xp)


func pass_level(t := -1) -> int:
	return GlowPass.level_for(pass_xp(t))


## Adds pass XP (doubled in the finale weekend). Returns the XP added.
func add_xp(n: int, why: String, t := -1) -> int:
	var s := season(t)
	if s.is_empty() or n <= 0:
		return 0
	var ps := pass_state(t)
	var add := n * GlowPass.xp_multiplier(s, _now(t))
	ps.xp = int(ps.xp) + add
	_log("pass_xp", add, why)
	_commit()
	return add


func reward(level: int, track: String, t := -1) -> Dictionary:
	if track == "free":
		return GlowPass.free_reward(level, str(season(t).get("debut", "")))
	return GlowPass.premium_reward(level)


func claimed(level: int, track: String, t := -1) -> bool:
	return level in pass_state(t)["free" if track == "free" else "paid"]


func can_claim(level: int, track: String, t := -1) -> bool:
	if reward(level, track, t).is_empty() or claimed(level, track, t) or level > pass_level(t):
		return false
	return track == "free" or pass_state(t).premium


func claim(level: int, track: String, t := -1) -> Dictionary:
	if not can_claim(level, track, t):
		return {}
	var r := reward(level, track, t)
	pass_state(t)["free" if track == "free" else "paid"].append(level)
	grant(r, "pass %s L%d" % [track, level])
	_commit()
	return r


## Claims every reward reached (both tracks, plus bonus boxes). Returns them.
func claim_all(t := -1) -> Array:
	var out := []
	for level in range(1, pass_level(t) + 1):
		for track in ["free", "premium"]:
			var r := claim(level, track, t)
			if not r.is_empty():
				out.append(r)
	while boxes_ready(t) > 0:
		out.append_array(open_box(t))
	return out


func claimable_count(t := -1) -> int:
	var n := boxes_ready(t)
	for level in range(1, pass_level(t) + 1):
		for track in ["free", "premium"]:
			if can_claim(level, track, t):
				n += 1
	return n


func boxes_ready(t := -1) -> int:
	return GlowPass.bonus_boxes(pass_xp(t)) - int(pass_state(t).boxes)


func open_box(t := -1) -> Array:
	if boxes_ready(t) <= 0:
		return []
	pass_state(t).boxes = int(pass_state(t).boxes) + 1
	for r in GlowPass.BONUS_BOX:
		grant(r, "pass bonus box")
	_commit()
	return GlowPass.BONUS_BOX.duplicate()


# --- Quests and play --------------------------------------------------------------

## Today's quests, this week's, and both chests (design: meta/quests.gd):
## {daily: [q], weekly: [q], chest: {ready, claimed, done}, week_chest: {...},
## swap: bool, day_ends, week_ends}. Each q is the stored quest plus
## {progress, done, claimed}. The day's and week's quests are rolled the first
## time they're asked for with a profile; a scene with no profile only counts
## progress.
func quests(t := -1) -> Dictionary:
	var d := _quest_day(t)
	var w := _quest_week(t)
	if profile != null:
		var ctx := quest_ctx()
		if (d.list as Array).is_empty():
			d.list = Quests.roll_day(_day(t), ctx)
		if (w.list as Array).is_empty():
			w.list = Quests.roll_week(_week(t), ctx)
	settle()
	var out := {"daily": _views(d), "weekly": _views(w), "swap": not d.swapped,
		"day_ends": LiveOps.day_start(_now(t)) + LiveOps.DAY, "week_ends": LiveOps.week_start(_now(t)) + LiveOps.WEEK}
	out.chest = _chest_view(d, Quests.DAILY_CHEST)
	out.week_chest = _chest_view(w, Quests.WEEKLY_CHEST)
	return out


## Quests and chests finished but not claimed yet (the Daily door's dot).
func quests_ready(t := -1) -> int:
	var q := quests(t)
	var n := 0
	for v in q.daily + q.weekly:
		if v.done and not v.claimed:
			n += 1
	return n + int(q.chest.ready) + int(q.week_chest.ready)


## Claims a finished quest: its rewards, and pass XP for a daily one (which
## also counts toward the pass's weekly chest). Returns the rewards given, or
## [] when it isn't done or was already claimed.
func claim_quest(id: String, t := -1) -> Array:
	for weekly in [false, true]:
		var b := _quest_week(t) if weekly else _quest_day(t)
		for q in b.list:
			if q.get("id", "") != id:
				continue
			if id in b.claimed or not Quests.done(q, b.progress):
				return []
			b.claimed.append(id)
			_pay({"rewards": q.rewards, "xp": 0 if weekly else Quests.PASS_XP, "count": 0 if weekly else 1}, "quest " + id, t)
			_commit()
			return q.rewards
	return []


## Opens the daily (or weekly) chest once all three quests are done.
func claim_quest_chest(weekly := false, t := -1) -> Array:
	var b := _quest_week(t) if weekly else _quest_day(t)
	var rewards: Array = Quests.WEEKLY_CHEST if weekly else Quests.DAILY_CHEST
	if b.chest or not _all_done(b):
		return []
	b.chest = true
	_pay({"rewards": rewards}, "weekly quest chest" if weekly else "daily quest chest", t)
	_commit()
	return rewards


## Today's free swap: an unfinished daily quest becomes the next one in its
## slot. Returns the new quest, or {} when the swap is used or not allowed.
func swap_quest(id: String, t := -1) -> Dictionary:
	var d := _quest_day(t)
	if d.swapped or profile == null:
		return {}
	for i in d.list.size():
		var q: Dictionary = d.list[i]
		if q.get("id", "") != id or Quests.done(q, d.progress):
			continue
		var next := Quests.swap(q, _day(t), quest_ctx())
		if next.is_empty():
			return {}
		d.list[i] = next
		d.swapped = true
		_commit()
		return next
	return {}


## Daily quests claimed this week, and whether the weekly chest is open/claimed.
func week_state(t := -1) -> Dictionary:
	var w: Dictionary = g().week
	var idx := _week(t)
	if int(w.week) != idx:
		w.week = idx
		w.count = 0
		w.chest = false
	return w


func chest_ready(t := -1) -> bool:
	var w := week_state(t)
	return int(w.count) >= GlowPass.CHEST_AFTER and not w.chest and not season(t).is_empty()


func open_chest(t := -1) -> bool:
	if not chest_ready(t):
		return false
	week_state(t).chest = true
	add_xp(GlowPass.CHEST_XP, "weekly chest", t)
	return true


## Counts progress toward today's and this week's quests. MAX_KINDS keep the
## best value (Bounce Run floor) instead of adding up.
func record(kind: String, n := 1, t := -1) -> void:
	_count(kind, n, t)
	_commit()


func _count(kind: String, n: int, t: int) -> void:
	for b in [_quest_day(t), _quest_week(t)]:
		if kind in Quests.MAX_KINDS:
			b.progress[kind] = maxi(int(b.progress.get(kind, 0)), n)
		else:
			b.progress[kind] = int(b.progress.get(kind, 0)) + n
	var d := _quest_day(t)
	if not d.counted and _all_done(d):
		d.counted = true # A finished day counts once for "Clear 5 daily chests".
		var w := _quest_week(t)
		w.progress.chest = int(w.progress.get("chest", 0)) + 1


## A finished fight: pass XP and quest progress. `ctx` says who fought:
## {critter: id, tier: int, duo: bool, mode: "arena"/"spire"/...}. Returns the
## pass XP added.
func record_fight(winner: int, damage: float, t := -1, ctx := {}) -> int:
	var result := "draw"
	if winner == 0:
		result = "win"
	elif winner == 1:
		result = "loss"
	_count("fight", 1, t)
	_count("damage", roundi(damage), t)
	if result == "win":
		_count("win", 1, t)
		_record_win(ctx, t)
	_commit()
	return add_xp(GlowPass.FIGHT_XP[result], "fight " + result, t)


## A campaign stage, sweep or boss run's result (meta/campaign.gd and the
## boss rules): a win counts as a stage (or boss) and its stars, and every
## critter level gained counts.
func record_result(kind: String, r: Dictionary, t := -1) -> void:
	if r.get("won", false):
		_count(kind, 1, t)
		if int(r.get("stars", 0)) > 0:
			_count("stars", int(r.stars), t)
	if int(r.get("levels", 0)) > 0:
		_count("level", int(r.levels), t)
	_commit()


## Solved the Daily Trick Shot.
func record_trick(t := -1) -> int:
	record("trick", 1, t)
	return add_xp(GlowPass.TRICK_XP, "trick shot", t)


func _record_win(ctx: Dictionary, t: int) -> void:
	var id := str(ctx.get("critter", ""))
	if ctx.get("duo", false):
		_count("duo_win", 1, t)
	if id == "" or not id in BallDefs.PLAYABLE:
		return
	var fam := Families.of(id)
	if fam != "":
		_count("win_fam:" + fam, 1, t)
	if CritterDb.RARITIES.find(str(CritterDb.get_critter(id).rarity)) >= 2:
		_count("win_rare", 1, t)
	if int(ctx.get("tier", 1)) >= 3:
		_count("win_t3", 1, t)
	var w := _quest_week(t)
	if not id in w.won_with:
		w.won_with.append(id)
		w.progress.critters = w.won_with.size()


## What the player has, for which quests can roll (Quests.eligible).
func quest_ctx() -> Dictionary:
	var fams := {}
	var rare := false
	var t3 := false
	for s in profile.stacks:
		if int(s.count) <= 0 or not str(s.id) in BallDefs.PLAYABLE:
			continue
		var f := Families.of(str(s.id))
		if f != "":
			fams[f] = true
		if CritterDb.RARITIES.find(str(CritterDb.get_critter(s.id).rarity)) >= 2:
			rare = true
		if int(s.tier) >= 3:
			t3 = true
	return {"bosses": BossesScreen.any_open(profile), "families": fams.keys(), "rare": rare, "t3": t3,
		"fuse": not profile.ready_to_fuse().is_empty(), "egg": int(profile.orbs) > 0 or bool(profile.free_summon)}


## Rewards from quests finished but never claimed before their day or week
## ended. They wait here and go to the profile the next time there is one.
func settle() -> void:
	var carry: Array = g().quest_carry
	if carry.is_empty() or profile == null:
		return
	g().quest_carry = []
	for c in carry:
		_pay(c, str(c.get("why", "quest")), -1)
	_commit()


func _pay(c: Dictionary, why: String, t: int) -> void:
	if profile == null:
		g().quest_carry.append(c.merged({"why": why}))
		return
	for r in c.get("rewards", []):
		grant(r, why)
	if int(c.get("count", 0)) > 0:
		var w := week_state(t)
		w.count = int(w.count) + int(c.count)
	add_xp(int(c.get("xp", 0)), why, t)


func _views(b: Dictionary) -> Array:
	var out := []
	for q in b.list:
		if q.is_empty():
			continue
		out.append(q.merged({"progress": Quests.progress(q, b.progress), "done": Quests.done(q, b.progress), "claimed": q.id in b.claimed}))
	return out


func _chest_view(b: Dictionary, rewards: Array) -> Dictionary:
	var done := 0
	for q in b.list:
		done += int(Quests.done(q, b.progress))
	var all := _all_done(b)
	return {"done": done, "of": (b.list as Array).size(), "ready": all and not b.chest, "claimed": b.chest, "rewards": rewards}


func _all_done(b: Dictionary) -> bool:
	var list: Array = b.list
	return not list.is_empty() and list.all(func(q): return Quests.done(q, b.progress))


## Today's quest state; a new day carries over whatever was finished and not
## claimed, then starts fresh.
func _quest_day(t: int) -> Dictionary:
	var d: Dictionary = g().quest_day
	if int(d.day) != _day(t):
		_carry_over(d, Quests.DAILY_CHEST, Quests.PASS_XP, 1)
		d.merge({"day": _day(t), "list": [], "progress": {}, "claimed": [], "chest": false, "swapped": false, "counted": false}, true)
	return d


func _quest_week(t: int) -> Dictionary:
	var w: Dictionary = g().quest_week
	if int(w.week) != _week(t):
		_carry_over(w, Quests.WEEKLY_CHEST, 0, 0)
		w.merge({"week": _week(t), "list": [], "progress": {}, "claimed": [], "chest": false, "won_with": []}, true)
	return w


func _carry_over(b: Dictionary, chest: Array, xp: int, count: int) -> void:
	for q in b.list:
		if not q.is_empty() and Quests.done(q, b.progress) and not q.id in b.claimed:
			g().quest_carry.append({"rewards": q.rewards, "xp": xp, "count": count, "why": "quest " + q.id})
	if not b.chest and _all_done(b):
		g().quest_carry.append({"rewards": chest, "why": "quest chest"})


# --- Grants and the ledger --------------------------------------------------------

## Gives one reward: gems and cosmetics here, power items to the profile.
func grant(r: Dictionary, why: String) -> void:
	match r.kind:
		"gems":
			_add_gems(int(r.n), why)
		"cosmetic":
			_give_cosmetic(r.id, why)
		_:
			_log(r.kind, int(r.get("n", 1)), why)
			if profile:
				profile.grant(r)
	changed.emit()


func _give_cosmetic(id: String, why: String) -> void:
	if not owns(id):
		g().owned.append(id)
		_log("cosmetic " + id, 1, why)


func _add_gems(n: int, why: String) -> void:
	g().gems = gems() + n
	_log("gems", n, why)


func _spend_gems(n: int, why: String) -> void:
	g().gems = gems() - n
	_log("gems", -n, why)


func _log(what: String, n: int, why: String) -> void:
	var l: Array = g().ledger
	l.append({"t": LiveOps.now(), "what": what, "n": n, "why": why})
	while l.size() > LEDGER_MAX:
		l.pop_front()


func _commit() -> void:
	save.commit()
	changed.emit()


func _now(t: int) -> int:
	return t if t >= 0 else LiveOps.now()


func _day(t: int) -> int:
	return floori(float(LiveOps.day_start(_now(t)) - LiveOps.EPOCH) / LiveOps.DAY)


func _week(t: int) -> int:
	return floori(float(LiveOps.week_start(_now(t)) - LiveOps.EPOCH) / LiveOps.WEEK)


## Quest progress from a scene that has no shell (Trick Shot, Bounce Run, the
## Ghost Arena, the Spire): loads the local save, counts, saves.
static func note(kind: String, n := 1) -> void:
	_local().record(kind, n)


static func note_fight(winner: int, damage: float, ctx := {}) -> int:
	return _local().record_fight(winner, damage, -1, ctx)


static func _local():
	var save = load("res://game/online/save_game.gd").new()
	save.load_local()
	return load("res://game/glow/glow_state.gd").new(save)
