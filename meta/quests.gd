## Daily and weekly Quests (the Quests door on the Daily board). Pure data and
## rules: which quests exist, what they pay, and which ones a day or week rolls.
## Progress and claims live in game/glow/glow_state.gd (save.data.quests).
##
## Every day rolls one quest from each daily slot and every week one from each
## weekly list. The roll is seeded by the day (or week), so everyone gets the
## same quests, except where a quest needs something the player doesn't have
## yet (bosses still locked, no critter of that family): then the next quest in
## the day's order takes its place. One free swap a day rolls the next one.
##
## Progress is counted by kind ("win", "trick", "win_fam:frost", ...) for the
## whole day or week, so whatever was played before the quests were rolled
## still counts. Kinds in MAX_KINDS keep the best value instead of a sum.
extends RefCounted

const Rng := preload("res://sim/rng.gd")
const Families := preload("res://sim/families.gd")
const Gear := preload("res://sim/gear.gd")

## Pass XP for each daily quest claimed (what a bounty gave), and how many
## daily quests in a week open the Glow Pass weekly chest.
const PASS_XP := 300

const ENERGY := {"kind": "energy", "n": 15}
const EGG := {"kind": "orbs", "n": 1}
const COINS := {"kind": "coins", "n": 300}
## Hammers, not XP Chips (Newms 2026-10-25, progression check): levels are
## capped by tier, so chips piled up unused while Hammers hold gear back.
const HAMMERS := {"kind": "hammers", "n": 2}
const WEEKLY_HAMMERS := {"kind": "hammers", "n": 3}
const DAILY_CHEST := [{"kind": "orbs", "n": 2}, {"kind": "energy", "n": 20}]
const WEEKLY_CHEST := [{"kind": "orbs", "n": 5}, {"kind": "coins", "n": 500}]

## The three daily slots, in screen order. `needs` names a check in eligible().
const DAILY := {
	"warmup": [
		{"id": "play4", "kind": "fight", "goal": 4, "text": "Play 4 fights"},
		{"id": "win2", "kind": "win", "goal": 2, "text": "Win 2 fights"},
		{"id": "dmg800", "kind": "damage", "goal": 800, "text": "Deal 800 damage"},
		{"id": "stage2", "kind": "stage", "goal": 2, "text": "Clear 2 campaign stages"},
	],
	"mode": [
		{"id": "trick", "kind": "trick", "goal": 1, "text": "Solve the Trick Shot"},
		{"id": "bounce6", "kind": "bounce_floor", "goal": 6, "text": "Reach floor 6 in Bounce Run"},
		{"id": "fotd", "kind": "fotd", "goal": 1, "text": "Call the Fight of the Day"},
		{"id": "boss1", "kind": "boss", "goal": 1, "text": "Beat a boss", "needs": "bosses"},
		{"id": "spire2", "kind": "spire", "goal": 2, "text": "Climb 2 Spire floors"},
		{"id": "arena2", "kind": "arena_win", "goal": 2, "text": "Win 2 Ghost Arena fights"},
		{"id": "stars6", "kind": "stars", "goal": 6, "text": "Earn 6 campaign stars"},
	],
	"critters": [
		{"id": "fam3", "kind": "win_fam", "goal": 3, "text": "Win 3 fights with a %s critter", "needs": "family"},
		{"id": "rare2", "kind": "win_rare", "goal": 2, "text": "Win 2 fights with a Rare or better", "needs": "rare"},
		{"id": "tier3", "kind": "win_t3", "goal": 1, "text": "Win with a T3 or higher critter", "needs": "t3"},
		{"id": "fuse1", "kind": "fuse", "goal": 1, "text": "Fuse a critter", "needs": "fuse"},
		{"id": "level1", "kind": "level", "goal": 1, "text": "Level up a critter"},
		{"id": "hatch1", "kind": "hatch", "goal": 1, "text": "Hatch an egg", "needs": "egg"},
	],
}
const WEEKLY := {
	"grind": [
		{"id": "w_win15", "kind": "win", "goal": 15, "text": "Win 15 fights"},
		{"id": "w_play25", "kind": "fight", "goal": 25, "text": "Play 25 fights"},
		{"id": "w_dmg6000", "kind": "damage", "goal": 6000, "text": "Deal 6,000 damage"},
	],
	"challenge": [
		{"id": "w_boss3", "kind": "boss", "goal": 3, "text": "Beat 3 bosses", "needs": "bosses"},
		{"id": "w_bounce12", "kind": "bounce_floor", "goal": 12, "text": "Reach floor 12 in Bounce Run"},
		{"id": "w_spire8", "kind": "spire", "goal": 8, "text": "Climb 8 Spire floors"},
		{"id": "w_arena8", "kind": "arena_win", "goal": 8, "text": "Win 8 Ghost Arena fights"},
		{"id": "w_trick4", "kind": "trick", "goal": 4, "text": "Solve 4 Trick Shots"},
	],
	"habit": [
		{"id": "w_chest5", "kind": "chest", "goal": 5, "text": "Clear 5 daily chests"},
		{"id": "w_fotd5", "kind": "fotd", "goal": 5, "text": "Call 5 Fights of the Day"},
		{"id": "w_crit5", "kind": "critters", "goal": 5, "text": "Win with 5 different critters"},
	],
}
const DAILY_SLOTS := ["warmup", "mode", "critters"]
const WEEKLY_SLOTS := ["grind", "challenge", "habit"]
const MAX_KINDS := ["bounce_floor"]


## What a daily quest in `slot` pays on `day`. "Go somewhere" pays coins and
## Hammers on alternate days.
static func daily_reward(slot: String, day: int) -> Array:
	match slot:
		"warmup":
			return [ENERGY]
		"mode":
			return [COINS] if posmod(day, 2) == 0 else [HAMMERS]
	return [EGG]


## What a weekly quest in `slot` pays in `week`. The gear piece is a random
## type at T2, picked by the week.
static func weekly_reward(slot: String, week: int) -> Array:
	match slot:
		"grind":
			return [WEEKLY_HAMMERS]
		"challenge":
			var types: Array = Gear.PIECES.keys()
			types.sort()
			return [{"kind": "gear", "type": types[posmod(week * 7 + 3, types.size())], "tier": 2}]
	return [WEEKLY_HAMMERS]


## The day's order of quests for one slot: the whole pool, shuffled by the
## day. A roll takes the first eligible one; a swap takes the next.
static func order(pool: Array, seed_value: int) -> Array:
	var out := pool.duplicate()
	var rng := Rng.new(seed_value)
	for i in range(out.size() - 1, 0, -1):
		var j := rng.range_int(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## The family a "win with a family" quest asks for: the day's pick from the
## families the player owns, or "" when they own none.
static func family_for(seed_value: int, owned: Array) -> String:
	var fams := Families.ids().filter(func(f): return f in owned)
	if fams.is_empty():
		return ""
	return fams[posmod(seed_value, fams.size())]


## Whether a quest can roll for this player. `ctx` comes from the game:
## {bosses: bool, families: [ids], rare: bool, t3: bool, fuse: bool, egg: bool}.
static func eligible(q: Dictionary, ctx: Dictionary) -> bool:
	match str(q.get("needs", "")):
		"":
			return true
		"bosses":
			return bool(ctx.get("bosses", false))
		"family":
			return not (ctx.get("families", []) as Array).is_empty()
		"rare":
			return bool(ctx.get("rare", false))
		"t3":
			return bool(ctx.get("t3", false))
		"fuse":
			return bool(ctx.get("fuse", false))
		"egg":
			return bool(ctx.get("egg", false))
	return false


## One rolled quest, ready to store: {id, slot, kind, goal, text, rewards}
## (plus `family` for a family quest). `skip` holds ids already used today
## (the swap's old quest), which roll past.
static func roll_one(pool: Array, slot: String, seed_value: int, ctx: Dictionary, rewards: Array, skip := []) -> Dictionary:
	for q in order(pool, seed_value):
		if q.id in skip or not eligible(q, ctx):
			continue
		var out: Dictionary = q.duplicate()
		out.erase("needs")
		out.slot = slot
		out.rewards = rewards.duplicate(true)
		if q.kind == "win_fam":
			var fam := family_for(seed_value, ctx.get("families", []))
			out.family = fam
			out.kind = "win_fam:" + fam
			out.text = str(q.text) % Families.info(fam).name
		return out
	return {}


## The day's three daily quests, in slot order.
static func roll_day(day: int, ctx: Dictionary) -> Array:
	var out := []
	for i in DAILY_SLOTS.size():
		var slot: String = DAILY_SLOTS[i]
		out.append(roll_one(DAILY[slot], slot, day_seed(day, i), ctx, daily_reward(slot, day)))
	return out


## The week's three weekly quests, in list order.
static func roll_week(week: int, ctx: Dictionary) -> Array:
	var out := []
	for i in WEEKLY_SLOTS.size():
		var slot: String = WEEKLY_SLOTS[i]
		out.append(roll_one(WEEKLY[slot], slot, day_seed(week * 31 + 7, i), ctx, weekly_reward(slot, week)))
	return out


## The replacement for a daily quest: the next eligible one in the slot.
static func swap(q: Dictionary, day: int, ctx: Dictionary) -> Dictionary:
	var i := DAILY_SLOTS.find(str(q.slot))
	if i < 0:
		return {}
	return roll_one(DAILY[q.slot], q.slot, day_seed(day, i), ctx, q.rewards, [q.id])


static func day_seed(day: int, slot_index: int) -> int:
	return posmod(day * 7919 + slot_index * 104729 + 17, 0x7FFFFFFF)


## Progress of a stored quest against a progress table, capped at its goal.
static func progress(q: Dictionary, table: Dictionary) -> int:
	return mini(int(q.goal), int(table.get(q.kind, 0)))


static func done(q: Dictionary, table: Dictionary) -> bool:
	return not q.is_empty() and progress(q, table) >= int(q.goal)
