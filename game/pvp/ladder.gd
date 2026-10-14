## Ghost Arena ladder rules (design/pvp.md section 3): leagues, divisions,
## trophy changes per opponent card, league floors and the season reset.
## Pure functions, so the server's trophy function can mirror them exactly.
extends RefCounted

const LEAGUES := [
	{"id": "bronze", "name": "Bronze", "min": 0, "color": Color("d08a4e")},
	{"id": "silver", "name": "Silver", "min": 400, "color": Color("c9d3e0")},
	{"id": "gold", "name": "Gold", "min": 1000, "color": Color("ffc23d")},
	{"id": "platinum", "name": "Platinum", "min": 1800, "color": Color("6ff0d8")},
	{"id": "diamond", "name": "Diamond", "min": 2800, "color": Color("7aa8ff")},
	{"id": "neon", "name": "Neon", "min": 4000, "color": Color("ff4fd8")},
]
const DIVISIONS := ["III", "II", "I"]

## Opponent cards: how far the opponent sits from you, and what a win or loss
## on attack is worth.
const CARDS := {
	"easier": {"name": "Easier", "offset": -150, "win": 18, "loss": -20},
	"even": {"name": "Even", "offset": 0, "win": 25, "loss": -15},
	"harder": {"name": "Harder", "offset": 150, "win": 35, "loss": -10},
}
const CARD_ORDER := ["easier", "even", "harder"]

const DEFENCE_WIN := 5
const DEFENCE_LOSS_CAP := 10 ## Most a single lost defence can cost.
const DEFENCE_DAILY_CAP := 40 ## Most lost defences can cost in a day.
const SEASON_PIVOT := 1000 ## Trophies above this are halved at a season reset.


static func league_index(trophies: int) -> int:
	var idx := 0
	for i in LEAGUES.size():
		if trophies >= LEAGUES[i].min:
			idx = i
	return idx


static func league(trophies: int) -> Dictionary:
	return LEAGUES[league_index(trophies)]


## Division inside a league: "III" in its bottom third, "I" in its top third.
## The top league has no divisions.
static func division(trophies: int) -> String:
	var idx := league_index(trophies)
	if idx == LEAGUES.size() - 1:
		return ""
	var lo: int = LEAGUES[idx].min
	var span: int = LEAGUES[idx + 1].min - lo
	return DIVISIONS[clampi((trophies - lo) * 3 / span, 0, 2)]


static func league_label(trophies: int) -> String:
	var div := division(trophies)
	return league(trophies).name + ("" if div == "" else " " + div)


## Lowest trophy count a player can fall to this season: the floor of the
## best league they reached (no demotion out of a league).
static func floor_for_peak(peak_trophies: int) -> int:
	return league(peak_trophies).min


## Trophy change for the attacker. Never takes them below their season floor.
static func attack_delta(trophies: int, peak_trophies: int, card: String, won: bool) -> int:
	assert(CARDS.has(card), "Unknown card: %s" % card)
	var delta: int = CARDS[card].win if won else CARDS[card].loss
	var floor_trophies := floor_for_peak(maxi(peak_trophies, trophies))
	return maxi(delta, mini(0, floor_trophies - trophies))


## Trophy change for the defender. A lost defence costs half what the
## attacker won, capped per defence and per day, and respects the floor.
static func defence_delta(trophies: int, peak_trophies: int, card: String, attacker_won: bool, lost_today: int) -> int:
	if not attacker_won:
		return DEFENCE_WIN
	var loss := mini(DEFENCE_LOSS_CAP, int(ceil(CARDS[card].win / 2.0)))
	loss = mini(loss, maxi(0, DEFENCE_DAILY_CAP - lost_today))
	var floor_trophies := floor_for_peak(maxi(peak_trophies, trophies))
	return -mini(loss, maxi(0, trophies - floor_trophies))


static func season_reset(trophies: int) -> int:
	if trophies <= SEASON_PIVOT:
		return trophies
	return SEASON_PIVOT + (trophies - SEASON_PIVOT) / 2
