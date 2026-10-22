## The Brood Queen: runs left, your eggs and three difficulties, each with the
## boss's power and the eggs it pays. Fight spends energy and a run and starts
## the boss fight on The Nest. Rules live in meta/brood_nest.gd and
## sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const BroodNest := preload("res://meta/brood_nest.gd")
const BossArt := preload("res://game/boss_art.gd")
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
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30), Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 92, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 14))

	var level := BossLevelGrid.picked(p, BroodNest.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, BroodNest.KEY, level, NEST, "nest"))
	root.add_child(_card(shell, p, level, fighter, left))
	return root


static func _card(shell, p, d: int, fighter: String, left: int) -> Control:
	var diff: Dictionary = BroodNest.DIFFICULTIES[d]
	var rec := BroodNest.enemy_rating(d)
	var mine: int = p.power_of(fighter)
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var info := Kit.vbox(4, [Kit.label("Lv %d" % (d + 1), 28), Kit.amount("orb", "%d+" % diff.orbs, 20),
		Kit.label("You're stronger" if mine >= rec else ("Close fight" if mine * 1.15 >= rec else "She's stronger"), 20, power_color)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.cost_button("Fight", BroodNest.ENERGY_COST, "energy", _fight.bind(shell, d, fighter), "go", 24, 72)
	fight.custom_minimum_size.x = 150
	fight.disabled = left <= 0
	if not fight.disabled and p.energy < BroodNest.ENERGY_COST:
		fight.modulate = Color(1, 1, 1, .5) # Short on energy: tapping opens the energy sheet.
	shell.mark("nest_go", fight)
	var p_tag := Kit.power(rec, 20, power_color)
	p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Kit.vbox(0, [BossArt.icon(BroodNest.BOSS, 76), p_tag])
	var row := Kit.hbox(12, [icon, info, fight], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(NEST, .5), 30, 2, 12))


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = BroodNest.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.refresh()
		if cfg.error == "energy":
			EnergySheet.open(shell)
			return
		shell.toast({"runs": "The Brood Queen is done for today. Back tomorrow!", "no_ball": "Pick a critter that can fight first.", "level": "Beat the level before it first."}.get(cfg.error, "Beat the Zone 2 boss to face the Brood Queen."))
		return
	shell.boss_requested.emit(cfg, d, fighter, "nest")


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
