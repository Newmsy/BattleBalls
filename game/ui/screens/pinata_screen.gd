## The Piñata Titan: runs left, your coins, your fighter and one Smash
## button. It matches your fighter's power and never hits back; the coins are
## the damage you do. Rules live in meta/pinata_party.gd and sim/bosses.gd;
## this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const Campaign := preload("res://meta/campaign.gd")
const PinataParty := preload("res://meta/pinata_party.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")

const PARTY := Color("ffb627")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Piñata Titan", {"eyebrow": "Daily boss ·", "eyebrow_color": PARTY, "eyebrow_glyphs": ["coin"], "info_mark": "pinata_info", "info": [
		"A giant party piñata swinging on its rope over Fiesta Plaza. It never hits back: you get 30 seconds to smash it.",
		"Every hit pops coins out, and a crit is a candy shower. Break it before the clock for a %d coin jackpot." % PinataParty.JACKPOT,
		"Stuns stop its swing and slows drag it out.",
		"Every run pays %d to %d coins. Coins buy cosmetics in the Glow shop." % [PinataParty.coins_for(0.0, false), PinataParty.coins_for(1.0, true)],
		"%d runs a day, %d energy each." % [PinataParty.RUNS_PER_DAY, PinataParty.ENERGY_COST]]}))

	var left := PinataParty.runs_left(p, now)
	root.add_child(Kit.label("%d/%d runs left" % [left, PinataParty.RUNS_PER_DAY], 22, Kit.MUTED))

	ResultPopup.boss_result(shell, params)

	root.add_child(BossCard.prizes(shell, "Prizes", PARTY, [BossCard.prize("coin", "%s to %s" % [Kit.commas(PinataParty.coins_for(0.0, false)), Kit.commas(PinataParty.coins_for(1.0, true))])], PinataParty.XP, "pinata"))
	root.add_child(BossLevelGrid.hero(shell, PinataParty.BOSS, PARTY))
	var fighter: String = Campaign.fighter_for(p)
	root.add_child(BossCard.fighter(shell, fighter, "pinata"))

	root.add_child(BossCard.fight(shell, {"boss": PinataParty.BOSS, "accent": PARTY,
		"cost": PinataParty.ENERGY_COST, "left": left, "on_fight": _fight.bind(shell, fighter), "label": "Smash", "mark": "pinata_go"}))
	return root


static func _fight(shell, fighter: String) -> void:
	var cfg: Dictionary = PinataParty.start(shell.profile, 0, fighter, int(Time.get_unix_time_from_system()))
	BossCard.start(shell, cfg, 0, fighter, "pinata", "The piñata's packed up for today. Back tomorrow!", "Clear stage 1-5 to open the Piñata Titan.")


## One line summing up a smash, for the result popup.
static func result_text(r: Dictionary) -> String:
	var parts: Array[String] = ["JACKPOT! +%d coins" % r.coins if r.broken else "+%d coins · %d%%" % [r.coins, roundi(r.frac * 100.0)], "+%d XP" % r.xp]
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
