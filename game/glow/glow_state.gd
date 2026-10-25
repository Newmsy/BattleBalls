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
const Dyes := preload("res://game/glow/dyes.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const LiveOps := preload("res://game/liveops.gd")

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
		"dyed": {}, ## Cosmetic id -> the Spark Dye it wears (game/glow/dyes.gd).
		"unlocks": [], ## Non-consumable products owned (e.g. "founder").
		"txns": [], ## Store transactions already granted (last 100).
		"ledger": [], ## {t, what, n, why}: newest last.
		"pass": {"season": "", "xp": 0, "premium": false, "free": [], "paid": [], "boxes": 0},
		"bounties": {"day": -1, "progress": {}, "done": []},
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


## Equipped cosmetic ids by slot, e.g. {"hat": "hat_crown"}, plus
## "dye_<slot>" for a worn cosmetic that has a Spark Dye on. This is what the
## arena draws for you (Catalog.worn); it never goes into a fight config.
func loadout() -> Dictionary:
	var out := {}
	for slot in Catalog.SLOTS:
		var id: String = str(g().equipped.get(slot, ""))
		if id != "" and owns(id):
			out[slot] = id
			if dye_of(id) != "":
				out["dye_" + slot] = dye_of(id)
	return out


## The Spark Dye cosmetic `id` wears, or "" for its own colours. A dye the
## profile no longer has unlocked (a reset save) reads as "".
func dye_of(id: String) -> String:
	var d := str(g().dyed.get(id, ""))
	if d == "" or Dyes.dye(d).is_empty() or (profile != null and not Dyes.unlocked(profile, d)):
		return ""
	return d


## Puts Spark Dye `dye` on cosmetic `id` ("" takes it off). False when the
## cosmetic isn't owned or the dye isn't unlocked.
func set_dye(id: String, dye: String) -> bool:
	if not owns(id):
		return false
	if dye == "":
		g().dyed.erase(id)
	elif Dyes.dye(dye).is_empty() or (profile != null and not Dyes.unlocked(profile, dye)):
		return false
	else:
		g().dyed[id] = dye
	_commit()
	return true


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
	if apply_purchase(product_id, txn):
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


# --- Bounties and play ------------------------------------------------------------

## Today's bounties with progress: [{id, text, goal, progress, done, xp}].
func bounties(t := -1) -> Array:
	var b := _bounty_day(t)
	var out := []
	for d in GlowPass.bounties_for(_day(t)):
		out.append({"id": d.id, "text": d.text, "goal": d.goal, "xp": GlowPass.BOUNTY_XP,
			"progress": mini(int(d.goal), int(b.progress.get(d.kind, 0))), "done": d.id in b.done})
	return out


## Bounties done this week, and whether the weekly chest is open/claimed.
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


## A finished fight: pass XP and bounty progress. Returns the XP added.
func record_fight(winner: int, damage: float, t := -1) -> int:
	var result := "draw"
	if winner == 0:
		result = "win"
	elif winner == 1:
		result = "loss"
	_count("fight", 1, t)
	if result == "win":
		_count("win", 1, t)
	_count("damage", roundi(damage), t)
	var xp := add_xp(GlowPass.FIGHT_XP[result], "fight " + result, t)
	return xp + _finish_bounties(t)


## Solved the Daily Trick Shot.
func record_trick(t := -1) -> int:
	_count("trick", 1, t)
	return add_xp(GlowPass.TRICK_XP, "trick shot", t) + _finish_bounties(t)


func _count(kind: String, n: int, t: int) -> void:
	var b := _bounty_day(t)
	b.progress[kind] = int(b.progress.get(kind, 0)) + n


func _finish_bounties(t: int) -> int:
	var b := _bounty_day(t)
	var xp := 0
	for d in GlowPass.bounties_for(_day(t)):
		if d.id not in b.done and int(b.progress.get(d.kind, 0)) >= int(d.goal):
			b.done.append(d.id)
			var w := week_state(t)
			w.count = int(w.count) + 1
			xp += add_xp(GlowPass.BOUNTY_XP, "bounty " + d.id, t)
	_commit()
	return xp


func _bounty_day(t: int) -> Dictionary:
	var b: Dictionary = g().bounties
	if int(b.day) != _day(t):
		b.day = _day(t)
		b.progress = {}
		b.done = []
	return b


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
