## Your racer's race in a Critter Plunge race (game/plunge.gd), read from the
## sim's events after every step: the callouts while it runs ("+1 place!",
## "KO by you!") and the one-line race story on the result. Render only: it
## reads the sim and never changes it.
extends RefCounted

const Roster := preload("res://game/ui/roster.gd")

const STABLE_TICKS := 24 ## A place has to hold this long to count (jams swap places every tick).
const HIT_GAP := 24 ## Ticks between hits that count apart (a beam is one hit).
const KO_CREDIT := 180 ## A knockout this soon after your hit is yours.

var you := 0
var hits_taken := 0
var places_gained := 0
var passed_by := {} ## racer index -> times it took a place off you
var knocked := [] ## racer indexes you knocked out
var ko_by := -1 ## Who knocked you out (-1: the course, or not knocked out)

var _place := 0 ## Your place now, by standings.
var _stable := 0 ## Your place once it held for STABLE_TICKS.
var _since := 0
var _ahead := [] ## Who was ahead of you at the last stable place.
var _last_taken := -1000
var _last_hit := {} ## racer index -> [source racer, tick] of the last hit on it


func _init(your_index := 0) -> void:
	you = your_index


## Reads one step's events. Returns this step's callouts for your racer:
## [{text, big}] ("+2 places!", "KO by you!", a race talent firing).
func watch(sim) -> Array:
	var out := []
	if you < 0 or you >= sim.starters:
		return out
	for e in sim.events:
		match e.type:
			"damage":
				var src := _racer_of(sim, int(e.get("source", -1)))
				var target: int = e.target
				if src < 0 or src == target:
					continue
				_last_hit[target] = [src, sim.tick]
				if target == you and sim.tick - _last_taken >= HIT_GAP:
					hits_taken += 1
					_last_taken = sim.tick
			"talent": # Your family's signature race talent fired ("Lava-proof!").
				if int(e.get("ball", -1)) == you:
					var word := str(e.get("name", str(e.get("talent", "")).capitalize()))
					if word != "":
						out.append({"text": word if word.ends_with("!") else word + "!", "big": false})
			"race_ko":
				var hit: Array = _last_hit.get(e.racer, [-1, -1000])
				var by: int = hit[0] if sim.tick - int(hit[1]) <= KO_CREDIT else -1
				if e.racer == you:
					ko_by = by
				elif by == you:
					knocked.append(e.racer)
					out.append({"text": "KO by you!", "big": true})
	if sim.racing(you):
		var order: Array = sim.standings()
		var now := order.find(you) + 1
		if _stable == 0:
			_stable = now
			_ahead = order.slice(0, now - 1)
		if now != _place:
			_place = now
			_since = 0
		_since += 1
		if _since >= STABLE_TICKS and now != _stable:
			var gained := _stable - now
			if gained > 0:
				places_gained += gained
				out.append({"text": "+%d place%s!" % [gained, "" if gained == 1 else "s"], "big": false})
			for j in order.slice(0, now - 1):
				if not j in _ahead:
					passed_by[j] = int(passed_by.get(j, 0)) + 1
			_stable = now
			_ahead = order.slice(0, now - 1)
	return out


## A minion or shot names its owner's racer; summoned balls belong to their team.
func _racer_of(sim, i: int) -> int:
	if i < 0 or i >= sim.balls.size():
		return -1
	if i < sim.starters:
		return i
	var team: int = sim.balls[i].team
	for k in sim.starters:
		if sim.balls[k].team == team:
			return k
	return -1


## The race in one line, for the result: "Took 3 hits · dealt 41 damage ·
## lost a place to Ripple". "" when nothing happened worth a line.
func line(sim) -> String:
	if you < 0:
		return ""
	var parts: Array[String] = []
	if not knocked.is_empty():
		parts.append("knocked out " + (_name(sim, knocked[0]) if knocked.size() == 1 else "%d racers" % knocked.size()))
	if sim.ko_ticks[you] >= 0:
		parts.append("knocked out by " + _name(sim, ko_by) if ko_by >= 0 else "knocked out on the course")
	elif hits_taken == 0:
		parts.append("dodged every hit")
	else:
		parts.append("took %d hit%s" % [hits_taken, "" if hits_taken == 1 else "s"])
	var dealt := roundi(sim.balls[you].damage_dealt)
	if dealt > 0:
		parts.append("dealt %d damage" % dealt)
	var rival := -1
	for j in passed_by:
		if rival < 0 or passed_by[j] > passed_by[rival]:
			rival = j
	if places_gained >= 2:
		parts.append("gained %d places" % places_gained)
	elif rival >= 0 and parts.size() < 3:
		parts.append("lost a place to " + _name(sim, rival))
	parts = parts.slice(0, 3)
	if parts.is_empty():
		return ""
	var text := " · ".join(parts)
	return text.left(1).to_upper() + text.substr(1)


static func _name(sim, i: int) -> String:
	return str(Roster.get_critter(sim.balls[i].type_id).get("name", sim.balls[i].type_id))
