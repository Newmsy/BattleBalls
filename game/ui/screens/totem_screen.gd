## The Totem of Nine: today's family, runs left, your fighter (and whether
## it's of today's family) and three difficulties, each with the totem's
## power and the Family Sigils it pays. Rules live in meta/totem_shrine.gd and
## sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Campaign := preload("res://meta/campaign.gd")
const TotemShrine := preload("res://meta/totem_shrine.gd")
const Talents := preload("res://sim/talents.gd")
const Bosses := preload("res://sim/bosses.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")

const SHRINE := Color("c9a6ff")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var family := TotemShrine.family_today(now)
	var fam_name: String = Talents.NAMES[family]
	var root := Kit.vbox(20)
	root.add_child(shell.title_row("Totem of Nine", {"eyebrow": "Daily boss ·", "eyebrow_color": SHRINE, "eyebrow_glyphs": ["sparkle"], "info_mark": "totem_info", "info": [
		"A spirit totem of nine family heads in the Spirit Shrine. Its heads glow, then ring out spirit orbs with one gap to slip through. Every other volley is a fan aimed at you.",
		"Today's family head is lit: %s critters hit it %d%% harder. The family changes every day." % [fam_name, roundi(Bosses.DEFS[TotemShrine.BOSS].family_bonus * 100.0)],
		"Stun it while the heads glow to cancel the volley. Its pull drags your mines and trails toward it.",
		"Sigils level up today's family's talents: %d at Lv 1 up to %d at Lv 15. Each level is stronger; beat one to open the next." % [TotemShrine.DIFFICULTIES[0].sigils, TotemShrine.DIFFICULTIES[-1].sigils],
		"%d runs a day, %d energy each. A loss gives back all but 1 energy." % [TotemShrine.RUNS_PER_DAY, TotemShrine.ENERGY_COST]]}))

	root.add_child(Kit.label("Today: %s family" % fam_name, 26, Talents.COLORS[family], HORIZONTAL_ALIGNMENT_LEFT, true))
	var left := TotemShrine.runs_left(p, now)
	root.add_child(Kit.label("%d/%d runs left" % [left, TotemShrine.RUNS_PER_DAY], 22, Kit.MUTED))

	ResultPopup.boss_result(shell, params)

	root.add_child(BossLevelGrid.hero(shell, TotemShrine.BOSS, SHRINE))
	var fighter: String = Campaign.fighter_for(p)
	var lines := []
	if Talents.faction_of(fighter) == family:
		lines.append(Kit.label("+%d%% today" % roundi(Bosses.DEFS[TotemShrine.BOSS].family_bonus * 100.0), 20, Kit.GOOD))
	root.add_child(BossCard.fighter(shell, fighter, "totem", lines))

	var level := BossLevelGrid.picked(p, TotemShrine.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, TotemShrine.KEY, level, SHRINE, "totem"))
	root.add_child(_card(shell, p, level, fighter, left, family))
	return root


static func _card(shell, p, d: int, fighter: String, left: int, family: String) -> Control:
	var diff: Dictionary = TotemShrine.DIFFICULTIES[d]
	return BossCard.fight(shell, {"boss": TotemShrine.BOSS, "accent": SHRINE, "rec": TotemShrine.enemy_rating(d), "mine": p.power_of(fighter),
		"title": diff.name, "pay": [Kit.hbox(8, [Glyph.make("sparkle", 22, Talents.COLORS[family]), Kit.label("%d" % diff.sigils, 20)], BoxContainer.ALIGNMENT_CENTER)],
		"cost": TotemShrine.ENERGY_COST, "left": left, "on_fight": _fight.bind(shell, d, fighter), "mark": "totem_go"})


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = TotemShrine.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	BossCard.start(shell, cfg, d, fighter, "totem", "The totem is resting for today. Back tomorrow!", "Beat the Zone 3 boss to face the Totem of Nine.")


## One line summing up a Totem result, for the result popup.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost · +%d XP. Slip through the gap!" % r.xp
	var parts: Array[String] = ["+%d %s Sigils" % [r.sigils, Talents.NAMES[r.family]], "+%d XP" % r.xp]
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
