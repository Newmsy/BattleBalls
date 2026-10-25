## The Anvil King (was the Gear Vault): today's slot, runs left, your hammers
## and three difficulties, each with the boss's power, the gear tier and the
## hammers it drops. Fight spends energy and a run and starts the boss fight
## on The Forge. Rules live in meta/gear_vault.gd and sim/bosses.gd; this
## only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const GearArt := preload("res://game/ui/gear_art.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Campaign := preload("res://meta/campaign.gd")
const GearVault := preload("res://meta/gear_vault.gd")
const Gear := preload("res://sim/gear.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")

const VAULT := Color("ff8a3d")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(20)
	var slot: String = GearVault.today(now).slot
	root.add_child(shell.title_row("Anvil King", {"eyebrow": "Daily boss", "eyebrow_color": VAULT, "eyebrow_glyphs": ["shell" if slot == "" else slot.to_lower(), "hammer"], "info_mark": "vault_info", "info": [
		"A forge golem rooted in the middle of The Forge. It slams its hammer where you're heading (dodge the ring), leaves embers burning, and every fourth swing quakes the floor around it: get to the edge.",
		"Stun it to cancel a swing. Slows make it swing less often. Its magnet core drags your mines and trails into it.",
		"Win gear + Hammers. 15 levels; every 3 levels the gear gets a star.",
		"The slot changes daily: Shells Monday and Thursday, Cores Tuesday and Friday, Charms Wednesday and Saturday, anything on Sunday.",
		"%d runs a day, %d energy each. A loss gives back all but 1 energy." % [GearVault.RUNS_PER_DAY, GearVault.ENERGY_COST]]}))

	var names: Array = GearVault.types_today(now).map(func(t): return Gear.PIECES[t].name)
	# "Cores: Spike, Echo, Leech or Ricochet", not "Spike Core or Echo Core or ...".
	var short: Array = names.map(func(n: String): return n.trim_suffix(" " + slot))
	var listed: String = short[0] if short.size() == 1 else ", ".join(short.slice(0, -1)) + " or " + short[-1]
	var today := "Today: " + ("any gear" if slot == "" else "%ss: %s" % [slot, listed])
	root.add_child(Kit.label(today, 26, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true))
	var left := GearVault.runs_left(p, now)
	root.add_child(Kit.hbox(10, [Kit.label("%d/%d runs" % [left, GearVault.RUNS_PER_DAY], 22, Kit.MUTED),
		Kit.spacer(), Kit.amount("hammer", p.hammers)], BoxContainer.ALIGNMENT_CENTER))

	if params.has("notice"):
		var r: Dictionary = params.get("xp", {})
		ResultPopup.boss_result(shell, params, result_row(r) if r.has("won") else null)

	root.add_child(BossLevelGrid.hero(shell, GearVault.BOSS, VAULT))
	var fighter: String = Campaign.fighter_for(p)
	root.add_child(BossCard.fighter(shell, fighter, "vault"))

	var level := BossLevelGrid.picked(p, GearVault.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, GearVault.KEY, level, VAULT, "vault"))
	root.add_child(_card(shell, p, level, fighter, now, left))
	return root


static func _card(shell, p, d: int, fighter: String, now: int, left: int) -> Control:
	var diff: Dictionary = GearVault.DIFFICULTIES[d]
	var col := BagScreen.tier_color(diff.tier)
	return BossCard.fight(shell, {"boss": GearVault.BOSS, "accent": col, "rec": GearVault.enemy_rating(d, now), "mine": p.power_of(fighter), "foe": "They're",
		"title": diff.name, "pay": [Kit.hbox(8, [Glyph.make("stars", 20, col, diff.tier), Kit.label("+", 20, Kit.MUTED), Kit.amount("hammer", diff.hammers, 20)], BoxContainer.ALIGNMENT_CENTER)],
		"cost": GearVault.ENERGY_COST, "left": left, "on_fight": _fight.bind(shell, d, fighter), "mark": "vault_go"})


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = GearVault.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	BossCard.start(shell, cfg, d, fighter, "vault", "The Anvil King is done for today. Back tomorrow!", "Beat the Zone 1 boss to face the Anvil King.")


## One line summing up an Anvil King result, for the fight's result text.
## Hammers show as an icon on the Anvil King screen (result_row), not here.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost · %d energy back · +%d XP" % [r.refund, r.xp]
	var parts: Array[String] = []
	for g in r.gear:
		parts.append(BagScreen.piece_name(g))
	parts.append("+%d XP" % r.xp)
	var t := " · ".join(parts)
	if r.levels > 0:
		t += ". LEVEL UP!"
	if r.account_levels > 0:
		t += " Energy refilled!"
	return t


## The result as icons: the piece (its glyph and stars), +hammers, +XP. The
## XP bars under it pop LEVEL UP on their own.
static func result_row(r: Dictionary) -> Control:
	var row := Kit.hbox(10, [], BoxContainer.ALIGNMENT_BEGIN)
	if not r.won:
		row.add_child(Kit.label("Lost · %d" % r.refund, 24))
		row.add_child(Kit.glyph("energy", 26, Kit.FG))
		row.add_child(Kit.label("back · +%d XP" % r.xp, 24))
		return row
	for g in r.gear:
		var col := BagScreen.tier_color(g.tier)
		row.add_child(GearArt.piece(g.type, g.tier, 40, col))
		row.add_child(Kit.glyph("stars", 20, col, g.tier))
	if r.get("hammers", 0) > 0:
		row.add_child(Kit.label("+%d" % r.hammers, 24))
		row.add_child(Kit.glyph("hammer", 28, Kit.FG))
	row.add_child(Kit.label("+%d XP" % r.xp, 24))
	if r.get("account_levels", 0) > 0:
		row.add_child(Kit.label("Energy refilled!", 22, Kit.GOOD))
	return row
