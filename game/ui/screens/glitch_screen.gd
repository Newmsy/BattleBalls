## The Glitch: the weekly story boss. Tries left this week, the bundle a win
## pays, your fighter and one Fight button. Rules live in meta/glitch_core.gd
## and sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const GlitchCore := preload("res://meta/glitch_core.gd")
const BossArt := preload("res://game/boss_art.gd")
const BossLevelGrid := preload("res://game/ui/boss_level_grid.gd")

const CORE := Color("7cff4f")
## Glyph and word per reward; currencies show only their icon and number.
## The third entry is for plain-text lines, where there's no icon.
const NAMES := {"orbs": ["egg", "", "Summon Eggs"], "lures": ["target", "", "Lures"], "hammers": ["hammer", "", "Hammers"]}


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(20)
	var head := Kit.vbox(2, [Kit.caption("Weekly boss", CORE), Kit.label("The Glitch", 40)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [shell.back_button("back"), head, shell.info_button("The Glitch", [
		"The bug behind everything, in the Corrupted Core. Every 10 seconds it rewrites the rules:",
		"Static: it fires pairs of glitch bolts at you. Warp: it blinks round the core (watch the flicker) and leaves corrupted floor behind. Pull: it drags you in and pulses: get out of the ring.",
		"Stun it to cancel a warp or a pulse. Portals on both sides throw you across.",
		"%d tries a week, %d energy each. Your first win pays the bundle and ends its week." % [GlitchCore.RUNS_PER_DAY, GlitchCore.ENERGY_COST]], "glitch_info")],
		BoxContainer.ALIGNMENT_CENTER))

	var left := GlitchCore.runs_left(p, now)
	var tries := ("%d/%d tries" % [left, GlitchCore.RUNS_PER_DAY]) if left > 0 else "Done this week"
	root.add_child(Kit.label(tries, 22, Kit.MUTED))

	ResultPopup.boss_result(shell, params)

	root.add_child(BossLevelGrid.hero(shell, GlitchCore.BOSS, CORE))
	var fighter: String = Campaign.fighter_for(p)
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), Kit.label(Roster.get_critter(fighter).name, 30), Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 92, false, b.level), info, Kit.chip("Change", Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.card_button(row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 14))

	var rec := GlitchCore.enemy_rating(0)
	var mine: int = p.power_of(fighter)
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var loot := Kit.vbox(4, [Kit.label("Win this week", 26)])
	for r in GlitchCore.BUNDLE:
		loot.add_child(Kit.hbox(8, [Glyph.make(NAMES[r.kind][0], 22), Kit.label(("%d %s" % [r.n, NAMES[r.kind][1]]).strip_edges(), 20)], BoxContainer.ALIGNMENT_BEGIN))
	loot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fight := Kit.cost_button("Fight", GlitchCore.ENERGY_COST, "energy", _fight.bind(shell, fighter), "go", 24, 72)
	fight.custom_minimum_size.x = 150
	fight.disabled = left <= 0
	if not fight.disabled and p.energy < GlitchCore.ENERGY_COST:
		fight.modulate = Color(1, 1, 1, .5) # Short on energy: tapping opens the energy sheet.
	shell.mark("glitch_go", fight)
	var p_tag := Kit.power(rec, 20, power_color)
	p_tag.alignment = BoxContainer.ALIGNMENT_CENTER
	var card := Kit.hbox(12, [Kit.vbox(0, [BossArt.icon(GlitchCore.BOSS, 88), p_tag]), loot, fight], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(card, Kit.box(Kit.PANEL, Color(CORE, .5), 30, 2, 12)))
	return root


static func _fight(shell, fighter: String) -> void:
	var cfg: Dictionary = GlitchCore.start(shell.profile, 0, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.refresh()
		if cfg.error == "energy":
			EnergySheet.open(shell)
			return
		shell.toast({"runs": "The Glitch is done for this week. It's back on Thursday!", "no_ball": "Pick a critter that can fight first."}.get(cfg.error, "Beat the Zone 5 boss to face The Glitch."))
		return
	shell.boss_requested.emit(cfg, 0, fighter, "glitch")


## One line summing up a Glitch result, for the result popup.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost · +%d XP. Bring a stunner!" % r.xp
	var parts: Array[String] = ["Glitch beaten!"]
	for b in r.bundle:
		parts.append("+%d %s" % [b.n, NAMES[b.kind][2]])
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
