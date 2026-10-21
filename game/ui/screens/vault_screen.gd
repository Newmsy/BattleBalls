## The Anvil King (was the Gear Vault): today's slot, runs left, your hammers
## and three difficulties, each with the boss's power, the gear tier and the
## hammers it drops. Fight spends energy and a run and starts the boss fight
## on The Forge. Rules live in meta/gear_vault.gd and sim/bosses.gd; this
## only shows them. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const GearVault := preload("res://meta/gear_vault.gd")
const Gear := preload("res://sim/gear.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const BossArt := preload("res://game/boss_art.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")

const VAULT := Color("ff8a3d")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(20)
	var head := Kit.vbox(2, [Kit.hbox(6, [Kit.caption("Daily boss · gear ·", VAULT), Kit.glyph("hammer", 22, VAULT)]), Kit.label("Anvil King", 40)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [shell.back_button("back"), head, shell.info_button("Anvil King", [
		"A forge golem rooted in the middle of The Forge. It slams its hammer where you're heading (dodge the ring), leaves embers burning, and every fourth swing quakes the floor around it: get to the edge.",
		"Stun it to cancel a swing. Slows make it swing less often. Its magnet core drags your mines and trails into it.",
		"Win to take one gear piece and Hammers. Hammers merge gear. 15 levels, each stronger: levels 1-3 drop 1-star gear, 4-6 two stars, up to 5 stars at 13-15, with more Hammers every level. Beat a level to open the next.",
		"The slot changes daily: Shells Monday and Thursday, Cores Tuesday and Friday, Charms Wednesday and Saturday, anything on Sunday.",
		"%d runs a day, %d energy each. A loss gives back all but 1 energy." % [GearVault.RUNS_PER_DAY, GearVault.ENERGY_COST]], "vault_info")],
		BoxContainer.ALIGNMENT_CENTER))

	var slot: String = GearVault.today(now).slot
	var names: Array = GearVault.types_today(now).map(func(t): return Gear.PIECES[t].name)
	var today := "Today: " + ("any gear" if slot == "" else "%ss (%s)" % [slot, " or ".join(names)])
	root.add_child(Kit.label(today, 26, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true))
	var left := GearVault.runs_left(p, now)
	root.add_child(Kit.hbox(10, [Glyph.make("energy", 30), Kit.label("%d/%d  ·  %d of %d runs left" % [p.energy, p.energy_max, left, GearVault.RUNS_PER_DAY], 22, Kit.MUTED),
		Kit.spacer(), Glyph.make("hammer", 30), Kit.label(Kit.commas(p.hammers), 24)], BoxContainer.ALIGNMENT_CENTER))

	if params.has("notice"):
		var note := Kit.vbox(12, [Kit.label(params.notice, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var bars := XpBar.rows(params.get("xp", {}), shell.sfx)
		if bars != null:
			note.add_child(bars)
		root.add_child(Kit.panel(note, Kit.box(Color("1d2a1f"), Kit.GOOD, 28, 2, 20)))

	root.add_child(BossLevelGrid.hero(shell, GearVault.BOSS, VAULT))
	var fighter: String = Campaign.fighter_for(p)
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30), Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 92, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 14))

	var level := BossLevelGrid.picked(p, GearVault.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, GearVault.KEY, level, VAULT, "vault"))
	root.add_child(_card(shell, p, level, fighter, now, left))
	return root


static func _card(shell, p, d: int, fighter: String, now: int, left: int) -> Control:
	var diff: Dictionary = GearVault.DIFFICULTIES[d]
	var rec := GearVault.enemy_rating(d, now)
	var mine: int = p.power_of(fighter)
	var col := BagScreen.tier_color(diff.tier)
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var info := Kit.vbox(4, [Kit.label(diff.name, 28), Kit.hbox(8, [Glyph.make("stars", 20, col, diff.tier), Kit.label("+", 20, Kit.MUTED),
		Glyph.make("hammer", 22), Kit.label("%d" % diff.hammers, 20)], BoxContainer.ALIGNMENT_CENTER),
		Kit.label("You're stronger" if mine >= rec else ("Close fight" if mine * 1.15 >= rec else "They're stronger"), 20, power_color)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.cost_button("Fight", GearVault.ENERGY_COST, "energy", _fight.bind(shell, d, fighter), "go", 24, 72)
	fight.custom_minimum_size.x = 150
	fight.disabled = left <= 0
	shell.mark("vault_go", fight)
	var p_tag := Kit.power(rec, 20, power_color)
	p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Kit.vbox(0, [BossArt.icon(GearVault.BOSS, 76), p_tag])
	var row := Kit.hbox(12, [icon, info, fight], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(col, .5), 30, 2, 12))


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = GearVault.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.toast({"energy": "Not enough energy. It refills 1 every 5 minutes, or use an Energy Pack from your Bag.",
			"runs": "The Anvil King is done for today. Back tomorrow!", "no_ball": "Pick a critter that can fight first.", "level": "Beat the level before it first."}.get(cfg.error, "Beat the Zone 1 boss to face the Anvil King."))
		shell.refresh()
		return
	shell.boss_requested.emit(cfg, d, fighter, "vault")


## One line summing up an Anvil King result, for the result screen.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost. %d energy back, +%d XP. Try a lower level, or bring a stronger critter." % [r.refund, r.xp]
	var parts: Array[String] = []
	for g in r.gear:
		parts.append("found a %s" % BagScreen.piece_name(g))
	if r.get("hammers", 0) > 0:
		parts.append("+%d hammers" % r.hammers)
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	var t := ", ".join(parts)
	return t.left(1).to_upper() + t.substr(1)
