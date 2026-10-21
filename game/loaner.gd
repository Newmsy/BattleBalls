## Try-a-Critter days: each day one critter is lent to every player who
## doesn't own it, for the casual modes only. The pick comes from the live-ops
## schedule (LiveOps.loaner(), with a clock rotation offline), so everyone gets
## the same critter on the same day.
##
## A loaner is practice: it never counts for ranked Ghost Arena (it is never
## published as your ghost and its fights don't touch your record) or for
## campaign progress. Modes ask can_use() before letting a critter in.
extends RefCounted

const LiveOps := preload("res://game/liveops.gd")
const Roster := preload("res://game/ui/roster.gd")

## Modes a loaner may play. Anything else (ghost_arena, campaign, ...) needs a
## critter you own.
const MODES := ["quick", "challenge", "trickshot", "bounce_run"]
## Shown on the board, one per entry in MODES.
const MODE_NAMES := ["Quick fight", "Challenges", "Critter Shot", "Bounce Run"]
## Loaners fight at T1 level 1, like every fresh drop.
const TIER := 1
const LEVEL := 1


## Today's loaner for this player: { critter, name, rarity, blurb, date, ends,
## owned, on_loan }. `on_loan` is false when they already own it.
static func today(profile, t := -1) -> Dictionary:
	var l := LiveOps.loaner(LiveOps.now() if t < 0 else t)
	var c := Roster.get_critter(l.critter)
	var owned: bool = profile != null and profile.owns(l.critter)
	return l.merged({"name": c.name, "rarity": c.rarity, "owned": owned, "on_loan": not owned})


## True if `id` is today's loaner and this player doesn't own it.
static func is_loan(profile, id: String, t := -1) -> bool:
	var l := today(profile, t)
	return l.on_loan and l.critter == id


## Whether this player may use `id` in `mode`: anything they own, plus
## today's loaner in the loaner modes.
static func can_use(profile, id: String, mode: String, t := -1) -> bool:
	if profile != null and profile.owns(id):
		return true
	return mode in MODES and today(profile, t).critter == id


## "Quick fight, Challenges, Critter Shot and Bounce Run".
static func modes_text() -> String:
	return ", ".join(MODE_NAMES.slice(0, -1)) + " and " + MODE_NAMES[-1]
