## The Prism Wyrm: runs left, your Lures and what they'll buy (a copy of each
## wishlisted critter, priced by rarity), your fighter and three
## difficulties. Rules live in meta/wyrm_rift.gd, Profile.use_lure and
## sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const WyrmRift := preload("res://meta/wyrm_rift.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const BossArt := preload("res://game/boss_art.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")
const Economy := preload("res://meta/economy.gd")

const RIFT := Color("7af0ff")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(18)
	var head := Kit.vbox(2, [Kit.caption("Daily boss · lures", RIFT), Kit.label("Prism Wyrm", 40)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var costs: Array = Economy.LURE_COST.keys().map(func(r): return "%s %d" % [r.capitalize(), Economy.LURE_COST[r]])
	root.add_child(Kit.hbox(16, [shell.back_button("back"), head, shell.info_button("Prism Wyrm", [
		"A crystal serpent snaking figure-eights through the Crystal Rift. Only its glowing scale can be hurt; the rest of it is armour. The glow runs from its head down to its tail.",
		"Its tail lashes where it's heading: get clear of the ring. Stun it to cancel a lash. Precise and homing critters do best.",
		"Win for Lures: %d at level 1 up to %d at level 15; each level is stronger and beating one opens the next. A Lure buys a copy of a critter on your wishlist, for sure. Lures per copy: %s." % [WyrmRift.DIFFICULTIES[0].lures, WyrmRift.DIFFICULTIES[-1].lures, ", ".join(costs)],
		"%d runs a day, %d energy each. A loss gives back all but 1 energy." % [WyrmRift.RUNS_PER_DAY, WyrmRift.ENERGY_COST]], "wyrm_info")],
		BoxContainer.ALIGNMENT_CENTER))

	var left := WyrmRift.runs_left(p, now)
	root.add_child(Kit.hbox(10, [Glyph.make("energy", 30), Kit.label("%d/%d  ·  %d of %d runs left" % [p.energy, p.energy_max, left, WyrmRift.RUNS_PER_DAY], 22, Kit.MUTED),
		Kit.spacer(), Glyph.make("target", 30, RIFT), Kit.label("%d Lures" % p.lures, 24)], BoxContainer.ALIGNMENT_CENTER))

	if params.has("notice"):
		var note := Kit.vbox(12, [Kit.label(params.notice, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
		var bars := XpBar.rows(params.get("xp", {}), shell.sfx)
		if bars != null:
			note.add_child(bars)
		root.add_child(Kit.panel(note, Kit.box(Color("1d2a1f"), Kit.GOOD, 28, 2, 20)))

	root.add_child(_lures_row(shell, p))

	root.add_child(BossLevelGrid.hero(shell, WyrmRift.BOSS, RIFT))
	var fighter: String = Campaign.fighter_for(p)
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30), Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 80, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 12))

	var level := BossLevelGrid.picked(p, WyrmRift.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, WyrmRift.KEY, level, RIFT, "wyrm"))
	root.add_child(_card(shell, p, level, fighter, left))
	return root


## Your wishlist with each critter's Lure price: tap one you can afford to
## lure a copy in. An empty wishlist points to the Summon tab, where it's set.
static func _lures_row(shell, p) -> Control:
	if p.wishlist.is_empty():
		var hint := Kit.label("Wishlist critters on the Summon tab to spend Lures on them.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		return Kit.card_button(hint, func(): shell.open_tab("summon", {}), Kit.PANEL2, Kit.PANEL, 24, 12)
	var row := Kit.hbox(10, [], BoxContainer.ALIGNMENT_CENTER)
	for id in p.wishlist:
		var cost: int = p.lure_cost(id)
		var can: bool = p.lures >= cost
		var cell := Kit.vbox(2, [FighterTag.icon(id, 1, 64), Kit.label("%d Lures" % cost, 18, RIFT if can else Kit.MUTED)])
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card := Kit.card_button(cell, _lure.bind(shell, id), RIFT.darkened(.5) if can else Kit.PANEL2, Kit.PANEL, 22, 8)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("lure_" + id, card)
		row.add_child(card)
	return row


static func _lure(shell, id: String) -> void:
	var p = shell.profile
	var name: String = Roster.get_critter(id).name
	if not p.use_lure(id):
		shell.toast("A %s copy takes %d Lures. You have %d." % [name, p.lure_cost(id), p.lures])
		return
	shell.toast("Lured in a %s! It's in your Critters." % name)
	shell.refresh()


static func _card(shell, p, d: int, fighter: String, left: int) -> Control:
	var diff: Dictionary = WyrmRift.DIFFICULTIES[d]
	var rec := WyrmRift.enemy_rating(d)
	var mine: int = p.power_of(fighter)
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var info := Kit.vbox(2, [Kit.label(diff.name, 26), Kit.hbox(8, [Glyph.make("target", 20, RIFT), Kit.label("%d Lure%s" % [diff.lures, "" if diff.lures == 1 else "s"], 20)], BoxContainer.ALIGNMENT_CENTER),
		Kit.label("You're stronger" if mine >= rec else ("Close fight" if mine * 1.15 >= rec else "It's stronger"), 20, power_color)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.cost_button("Fight", WyrmRift.ENERGY_COST, "energy", _fight.bind(shell, d, fighter), "go", 24, 64)
	fight.custom_minimum_size.x = 150
	fight.disabled = left <= 0
	shell.mark("wyrm_go", fight)
	var p_tag := Kit.power(rec, 20, power_color)
	p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Kit.vbox(0, [BossArt.icon(WyrmRift.BOSS, 68), p_tag])
	var row := Kit.hbox(12, [icon, info, fight], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(RIFT, .5), 30, 2, 10))


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = WyrmRift.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.toast({"energy": "Not enough energy. It refills 1 every 5 minutes, or use an Energy Pack from your Bag.",
			"runs": "The wyrm has slithered off for today. Back tomorrow!", "no_ball": "Pick a critter that can fight first.", "level": "Beat the level before it first."}.get(cfg.error, "Beat the Zone 4 boss to face the Prism Wyrm."))
		shell.refresh()
		return
	shell.boss_requested.emit(cfg, d, fighter, "wyrm")


## One line summing up a Wyrm result, for the result popup.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost. %d energy back, +%d XP. Hit the glowing scale, or try a lower level." % [r.refund, r.xp]
	var parts: Array[String] = ["+%d Lure%s" % [r.lures, "" if r.lures == 1 else "s"], "+%d XP" % r.xp]
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
