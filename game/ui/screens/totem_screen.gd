## The Totem of Nine: today's family, runs left, your fighter (and whether
## it's of today's family) and three difficulties, each with the totem's
## power and the Family Sigils it pays. Rules live in meta/totem_shrine.gd and
## sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const TotemShrine := preload("res://meta/totem_shrine.gd")
const Talents := preload("res://sim/talents.gd")
const Bosses := preload("res://sim/bosses.gd")
const BossArt := preload("res://game/boss_art.gd")
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
	var b: Dictionary = p.best(fighter)
	var match := Talents.faction_of(fighter) == family
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30)])
	if match:
		info.add_child(Kit.label("+%d%% today" % roundi(Bosses.DEFS[TotemShrine.BOSS].family_bonus * 100.0), 20, Kit.GOOD))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 92, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 14))

	var level := BossLevelGrid.picked(p, TotemShrine.KEY, params)
	root.add_child(BossLevelGrid.grid(shell, p, TotemShrine.KEY, level, SHRINE, "totem"))
	root.add_child(_card(shell, p, level, fighter, left, family))
	return root


static func _card(shell, p, d: int, fighter: String, left: int, family: String) -> Control:
	var diff: Dictionary = TotemShrine.DIFFICULTIES[d]
	var rec := TotemShrine.enemy_rating(d)
	var mine: int = p.power_of(fighter)
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var info := Kit.vbox(4, [Kit.label(diff.name, 28), Kit.hbox(8, [Glyph.make("sparkle", 22, Talents.COLORS[family]), Kit.label("%d" % diff.sigils, 20)], BoxContainer.ALIGNMENT_CENTER),
		Kit.label("You're stronger" if mine >= rec else ("Close fight" if mine * 1.15 >= rec else "It's stronger"), 20, power_color)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.cost_button("Fight", TotemShrine.ENERGY_COST, "energy", _fight.bind(shell, d, fighter), "go", 24, 72)
	fight.custom_minimum_size.x = 150
	fight.disabled = left <= 0
	if not fight.disabled and p.energy < TotemShrine.ENERGY_COST:
		fight.modulate = Color(1, 1, 1, .5) # Short on energy: tapping opens the energy sheet.
	shell.mark("totem_go", fight)
	var p_tag := Kit.power(rec, 20, power_color)
	p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := Kit.vbox(0, [BossArt.icon(TotemShrine.BOSS, 76), p_tag])
	var row := Kit.hbox(12, [icon, info, fight], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(SHRINE, .5), 30, 2, 12))


static func _fight(shell, d: int, fighter: String) -> void:
	var cfg: Dictionary = TotemShrine.start(shell.profile, d, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.refresh()
		if cfg.error == "energy":
			EnergySheet.open(shell)
			return
		shell.toast({"runs": "The totem is resting for today. Back tomorrow!", "no_ball": "Pick a critter that can fight first.", "level": "Beat the level before it first."}.get(cfg.error, "Beat the Zone 3 boss to face the Totem of Nine."))
		return
	shell.boss_requested.emit(cfg, d, fighter, "totem")


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
