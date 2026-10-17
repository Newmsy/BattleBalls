## The Brood Queen: runs left, your eggs and three difficulties, each with the
## boss's power and the eggs it pays. Fight spends energy and a run and starts
## the boss fight on The Nest. Rules live in meta/brood_nest.gd and
## sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const BroodNest := preload("res://meta/brood_nest.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const BossArt := preload("res://game/boss_art.gd")

const NEST := Color("ff6fae")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(20)
	var head := Kit.vbox(2, [Kit.caption("Daily boss · summon eggs", NEST), Kit.label("Brood Queen", 44)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [shell.back_button("back"), head, shell.info_button("Brood Queen", [
		"A great neon hen gliding round The Nest. She lays eggs that hatch into darting chicks, and flings feathers at you.",
		"Crack eggs before they hatch: every %d eggs cracked adds an egg to a win, up to +%d. Stuns freeze her in place." % [BroodNest.EGGS_PER_BONUS, BroodNest.BONUS_MAX],
		"Win for Summon Eggs: Easy %d, Hard %d, Elite %d." % [BroodNest.DIFFICULTIES[0].orbs, BroodNest.DIFFICULTIES[1].orbs, BroodNest.DIFFICULTIES[2].orbs],
		"%d runs a day, %d energy each. A loss gives back all but 1 energy." % [BroodNest.RUNS_PER_DAY, BroodNest.ENERGY_COST]], "nest_info")],
		BoxContainer.ALIGNMENT_CENTER))

	var left := BroodNest.runs_left(p, now)
	root.add_child(Kit.hbox(10, [Glyph.make("energy", 30), Kit.label("Energy %d/%d  ·  %d of %d runs left" % [p.energy, p.energy_max, left, BroodNest.RUNS_PER_DAY], 22, Kit.MUTED),
		Kit.spacer(), Glyph.make("orb", 30), Kit.label(Kit.commas(p.orbs), 24)], BoxContainer.ALIGNMENT_CENTER))

	if params.has("notice"):
		var note := Kit.vbox(12, [Kit.label(params.notice, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var bars := XpBar.rows(params.get("xp", {}), shell.sfx)
		if bars != null:
			note.add_child(bars)
		root.add_child(Kit.panel(note, Kit.box(Color("1d2a1f"), Kit.GOOD, 28, 2, 20)))

	var fighter: String = Campaign.fighter_for(p)
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30), Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 92, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 14))

	for d in BroodNest.DIFFICULTIES.size():
		root.add_child(_card(shell, p, d, fighter, left))
	return root


static func _card(shell, p, d: int, fighter: String, left: int) -> Control:
	var diff: Dictionary = BroodNest.DIFFICULTIES[d]
	var rec := BroodNest.enemy_rating(d)
	var mine: int = p.power_of(fighter)
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var info := Kit.vbox(4, [Kit.label(diff.name, 28), Kit.hbox(8, [Glyph.make("orb", 22), Kit.label("%d + bonus" % diff.orbs, 20)], BoxContainer.ALIGNMENT_CENTER),
		Kit.label("You're stronger" if mine >= rec else ("Close fight" if mine * 1.15 >= rec else "She's stronger"), 20, power_color)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.button("Fight  %d" % BroodNest.ENERGY_COST, _fight.bind(shell, d, fighter), "go", 24, 72)
	fight.custom_minimum_size.x = 150
	fight.disabled = left <= 0
	shell.mark("nest_%d" % (d + 1), fight)
	var p_tag := Kit.power(rec, 20, power_color)
	p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Kit.vbox(0, [BossArt.icon(BroodNest.BOSS, 76), p_tag])
	var row := Kit.hbox(12, [icon, info, fight], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(NEST, .5), 30, 2, 12))


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = BroodNest.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.toast({"energy": "Not enough energy. It refills 1 every 5 minutes, or use an Energy Pack from your Bag.",
			"runs": "The Brood Queen is done for today. Back tomorrow!", "no_ball": "Pick a critter that can fight first."}.get(cfg.error, "Beat the Zone 2 boss to face the Brood Queen."))
		shell.refresh()
		return
	shell.boss_requested.emit(cfg, d, fighter, "nest")


## One line summing up a Brood Queen result, for the result screen.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost. %d energy back, +%d XP. Crack her eggs early, or try Easy." % [r.refund, r.xp]
	var parts: Array[String] = ["+%d Summon Eggs" % r.orbs]
	if r.bonus > 0:
		parts.append("%d eggs cracked (+%d)" % [r.cracked, r.bonus])
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
