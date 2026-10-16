## Result screen wording for a finished MatchSim, shared by every mode.
## A double knockout (both critters out on the same hit) goes to whoever had
## more HP going into that hit; equal HP, or equal HP at the time limit, is a
## draw. Either way the screen says what happened instead of a bare WIN.
extends RefCounted

const WIN := Color("45f5a6")
const LOSE := Color("ff5a7a")
const DRAW := Color("ffd84a")


## { headline, detail, tone ("win" | "lose" | "draw"), color }. `names` are what
## to call each side (["You", "The foe"] or the critter names in a replay), by
## sim side. `you`: the side the player is on (1 in half of live matches).
static func describe(sim, names: Array, replay := false, you := 0) -> Dictionary:
	var w: int = sim.winner
	var out := {"tone": "draw", "color": DRAW}
	if w >= 0 and not replay:
		out.tone = "win" if w == you else "lose"
		out.color = WIN if w == you else LOSE
	elif w >= 0:
		out.color = WIN
	match sim.end_reason:
		"double_knockout":
			if w < 0:
				out.headline = "DRAW"
				out.detail = "Double KO! Both went down on the same hit with the same HP."
			else:
				var hp := _hp_pair(sim.ko_hp)
				out.headline = "DOUBLE KO!"
				out.detail = "Both went down on the same hit. %s had %s HP going in, %s had %s, so %s." % [
					names[0], hp[0], names[1].to_lower() if not replay else names[1], hp[1], _takes_it(names, w, replay, you)]
		"time_limit":
			if w < 0:
				out.headline = "DRAW"
				out.detail = "Time's up with both on the same HP."
			else:
				out.headline = _plain_headline(sim, names, replay, you)
				out.detail = "Time's up. %s had more HP left." % names[w]
		_:
			out.headline = _plain_headline(sim, names, replay, you)
			out.detail = ""
	return out


static func _plain_headline(sim, names: Array, replay: bool, you := 0) -> String:
	if replay:
		return "%s WINS" % sim.balls[sim.winner].def.display_name.to_upper()
	return "YOU WIN!" if sim.winner == you else "YOU LOSE"


static func _takes_it(names: Array, w: int, replay: bool, you := 0) -> String:
	if replay:
		return names[w] + " takes it"
	return "you take it" if w == you else "they take it"


## HP values as text, with a decimal when rounding would make them look equal.
static func _hp_pair(hp: Array) -> Array:
	if hp.size() < 2:
		return ["?", "?"]
	var a := ceili(hp[0])
	var b := ceili(hp[1])
	if a != b:
		return [str(a), str(b)]
	return ["%.1f" % hp[0], "%.1f" % hp[1]]
