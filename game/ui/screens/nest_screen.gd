## The Brood Queen: runs left, your eggs and three difficulties, each with the
## boss's power and the eggs it pays. Fight spends energy and a run and starts
## the boss fight on The Nest. Rules live in meta/brood_nest.gd and
## sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const Campaign := preload("res://meta/campaign.gd")
const BroodNest := preload("res://meta/brood_nest.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")

const NEST := Color("ff6fae")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Brood Queen", {"eyebrow": "Daily boss ·", "eyebrow_color": NEST, "eyebrow_glyphs": ["egg"], "info_mark": "nest_info", "info": [
		"A great neon hen gliding round The Nest. She lays eggs that hatch into darting chicks, and flings feathers at you.",
		"Crack eggs before they hatch: every %d eggs cracked adds an egg to a win, up to +%d. Stuns freeze her in place." % [BroodNest.EGGS_PER_BONUS, BroodNest.BONUS_MAX],
		"Win for Summon Eggs: %d at level 1 up to %d at level 15. Each level is stronger; beat one to open the next." % [BroodNest.DIFFICULTIES[0].orbs, BroodNest.DIFFICULTIES[-1].orbs],
		"%d runs a day, %d energy each. A loss gives back all but 1 energy." % [BroodNest.RUNS_PER_DAY, BroodNest.ENERGY_COST]]}))

	var left := BroodNest.runs_left(p, now)
	root.add_child(Kit.label("%d/%d runs left" % [left, BroodNest.RUNS_PER_DAY], 22, Kit.MUTED))

	ResultPopup.boss_result(shell, params)

	root.add_child(BossLevelGrid.hero(shell, BroodNest.BOSS, NEST))
	var fighter: String = Campaign.fighter_for(p)
	root.add_child(BossCard.fighter(shell, fighter, "nest"))

	var level := BossLevelGrid.picked(p, BroodNest.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, BroodNest.KEY, level, NEST, "nest"))
	root.add_child(_card(shell, p, level, fighter, left))
	return root


static func _card(shell, p, d: int, fighter: String, left: int) -> Control:
	return BossCard.fight(shell, {"boss": BroodNest.BOSS, "accent": NEST, "rec": BroodNest.enemy_rating(d), "mine": p.power_of(fighter), "foe": "She's",
		"title": "Lv %d" % (d + 1), "pay": [Kit.amount("orb", "%d+" % BroodNest.DIFFICULTIES[d].orbs, 20)],
		"cost": BroodNest.ENERGY_COST, "left": left, "on_fight": _fight.bind(shell, d, fighter), "mark": "nest_go"})


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = BroodNest.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	BossCard.start(shell, cfg, d, fighter, "nest", "The Brood Queen is done for today. Back tomorrow!", "Beat the Zone 2 boss to face the Brood Queen.")


## One line summing up a Brood Queen result, for the result screen.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost · +%d XP. Crack eggs early!" % r.xp
	var parts: Array[String] = ["+%d Summon Eggs" % r.orbs]
	if r.bonus > 0:
		parts.append("%d eggs cracked (+%d)" % [r.cracked, r.bonus])
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
