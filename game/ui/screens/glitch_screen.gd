## The Glitch: the weekly story boss. Tries left this week, the bundle a win
## pays, your fighter and one Fight button. Rules live in meta/glitch_core.gd
## and sim/bosses.gd; this only shows them. Fits one phone screen.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const BossCard := preload("res://game/ui/boss_card.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Campaign := preload("res://meta/campaign.gd")
const GlitchCore := preload("res://meta/glitch_core.gd")
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
	root.add_child(shell.title_row("The Glitch", {"eyebrow": "Weekly boss", "eyebrow_color": CORE, "info_mark": "glitch_info", "info": [
		"The bug behind everything, in the Corrupted Core. Every 10 seconds it rewrites the rules:",
		"Static: it fires pairs of glitch bolts at you. Warp: it blinks round the core (watch the flicker) and leaves corrupted floor behind. Pull: it drags you in and pulses: get out of the ring.",
		"Stun it to cancel a warp or a pulse. Portals on both sides throw you across.",
		"%d tries a week, %d energy each. Your first win pays the bundle and ends its week." % [GlitchCore.RUNS_PER_DAY, GlitchCore.ENERGY_COST]]}))

	var left := GlitchCore.runs_left(p, now)
	var tries := ("%d/%d tries" % [left, GlitchCore.RUNS_PER_DAY]) if left > 0 else "Done this week"
	root.add_child(Kit.label(tries, 22, Kit.MUTED))

	ResultPopup.boss_result(shell, params)

	root.add_child(BossLevelGrid.hero(shell, GlitchCore.BOSS, CORE))
	var fighter: String = Campaign.fighter_for(p)
	root.add_child(BossCard.fighter(shell, fighter, "glitch"))

	var loot := []
	for r in GlitchCore.BUNDLE:
		loot.append(Kit.hbox(8, [Glyph.make(NAMES[r.kind][0], 22), Kit.label(("%d %s" % [r.n, NAMES[r.kind][1]]).strip_edges(), 20)], BoxContainer.ALIGNMENT_BEGIN))
	root.add_child(BossCard.fight(shell, {"boss": GlitchCore.BOSS, "accent": CORE, "rec": GlitchCore.enemy_rating(0), "mine": p.power_of(fighter),
		"title": "Win this week", "pay": loot, "cost": GlitchCore.ENERGY_COST, "left": left, "on_fight": _fight.bind(shell, fighter), "mark": "glitch_go"}))
	return root


static func _fight(shell, fighter: String) -> void:
	var cfg: Dictionary = GlitchCore.start(shell.profile, 0, fighter, int(Time.get_unix_time_from_system()))
	BossCard.start(shell, cfg, 0, fighter, "glitch", "The Glitch is done for this week. It's back on Thursday!", "Beat the Zone 4 boss to face The Glitch.")


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
