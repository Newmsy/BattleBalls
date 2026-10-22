## The Piñata Titan: runs left, your coins, your fighter and one Smash
## button. It matches your fighter's power and never hits back; the coins are
## the damage you do. Rules live in meta/pinata_party.gd and sim/bosses.gd;
## this only shows them. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const PinataParty := preload("res://meta/pinata_party.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const BossArt := preload("res://game/boss_art.gd")
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
		"It's as strong as your fighter, so big hitters and fast, busy critters earn the most. Stuns stop its swing and slows drag it out.",
		"Every run pays %d to %d coins. Coins buy cosmetics in the Glow shop." % [PinataParty.coins_for(0.0, false), PinataParty.coins_for(1.0, true)],
		"%d runs a day, %d energy each." % [PinataParty.RUNS_PER_DAY, PinataParty.ENERGY_COST]]}))

	var left := PinataParty.runs_left(p, now)
	root.add_child(Kit.label("%d/%d runs left" % [left, PinataParty.RUNS_PER_DAY], 22, Kit.MUTED))

	if params.has("notice"):
		var note := Kit.vbox(12, [Kit.label(params.notice, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var bars := XpBar.rows(params.get("xp", {}), shell.sfx)
		if bars != null:
			note.add_child(bars)
		root.add_child(Kit.panel(note, Kit.box(Color("1d2a1f"), Kit.GOOD, 28, 2, 20)))

	root.add_child(BossLevelGrid.hero(shell, PinataParty.BOSS, PARTY))
	var fighter: String = Campaign.fighter_for(p)
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30), Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 92, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 14))

	var pay := Kit.vbox(4, [Kit.amount("coin", "%d to %d" % [PinataParty.coins_for(0.0, false), PinataParty.coins_for(1.0, true)], 26)])
	pay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.cost_button("Smash", PinataParty.ENERGY_COST, "energy", _fight.bind(shell, fighter), "go", 24, 72)
	fight.custom_minimum_size.x = 160
	fight.disabled = left <= 0
	if not fight.disabled and p.energy < PinataParty.ENERGY_COST:
		fight.modulate = Color(1, 1, 1, .5) # Short on energy: tapping opens the energy sheet.
	shell.mark("pinata_go", fight)
	var card := Kit.hbox(12, [BossArt.icon(PinataParty.BOSS, 96), pay, fight], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(card, Kit.box(Kit.PANEL, Color(PARTY, .5), 30, 2, 12)))
	return root


static func _fight(shell, fighter: String) -> void:
	var cfg: Dictionary = PinataParty.start(shell.profile, 0, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.refresh()
		if cfg.error == "energy":
			EnergySheet.open(shell)
			return
		shell.toast({"runs": "The piñata's packed up for today. Back tomorrow!", "no_ball": "Pick a critter that can fight first."}.get(cfg.error, "Clear stage 1-5 to open the Piñata Titan."))
		return
	shell.boss_requested.emit(cfg, 0, fighter, "pinata")


## One line summing up a smash, for the result popup.
static func result_text(r: Dictionary) -> String:
	var parts: Array[String] = ["JACKPOT! +%d coins" % r.coins if r.broken else "+%d coins · %d%%" % [r.coins, roundi(r.frac * 100.0)], "+%d XP" % r.xp]
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
