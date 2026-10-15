## Campaign: the Glow Garden stage list (design/pve.md section 3). Each stage
## shows its enemy, Recommended Power and stars; Fight spends energy and
## starts the stage in the arena, Sweep replays a 3-starred stage off-screen.
## Rules live in meta/campaign.gd; this only shows them.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Spire := preload("res://sim/spire.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const Gear := preload("res://sim/gear.gd")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var z: int = params.get("zone", 0)
	var zone := Zones.zone(z)
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(22)

	var back: Control = shell.back_button("back")
	var head := Kit.vbox(2, [Kit.caption("Zone %d · The Neon Circuit · %s" % [z + 1, "1v1" if zone.lineup == 1 else "%d vs %d" % [zone.lineup, zone.lineup]], Color("9be89a")),
		Kit.label(zone.name, 44)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [back, head]))

	var wait: int = p.seconds_to_next_energy(now)
	var energy_line := "Energy %d/%d" % [p.energy, p.energy_max] + ("  ·  +1 in %d:%02d" % [wait / 60, wait % 60] if wait > 0 else "")
	root.add_child(Kit.hbox(10, [Glyph.make("energy", 30), Kit.label(energy_line, 24, Kit.MUTED)]))

	if params.has("notice"):
		root.add_child(Kit.panel(Kit.label(params.notice, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true), Kit.box(Color("1d2a1f"), Kit.GOOD, 28, 2, 20)))

	# Fighter: the lineup critter, or the strongest one that can fight.
	var fighter: String = Campaign.fighter_for(p)
	var b: Dictionary = p.best(fighter)
	var info := Kit.vbox(4, [Kit.caption("Your fighter"), _fit(Kit.label(Roster.get_critter(fighter).name, 30)),
		Kit.power(p.power_of(fighter), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var change := Kit.chip("Change", Kit.ACCENT)
	var fighter_row := Kit.hbox(14, [FighterTag.icon(fighter, b.tier, 100, false, b.level), info, change])
	fighter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(Kit.card_button(fighter_row, func(): shell.open_tab("critters", {}), Color("3a3480"), Kit.PANEL2, 32, 16))

	var list := Kit.vbox(14)
	for i in zone.stages.size():
		list.add_child(_stage_card(shell, p, z, i, fighter))
	root.add_child(list)
	# Land on the stage just played, not the top of the list.
	if params.has("focus"):
		shell.scroll_to(list.get_child(clampi(params.focus, 0, zone.stages.size() - 1)))
	if params.has("result"):
		_result_popup(shell, z, params.result.stage, params.result.r, params.result.get("kind", "fight"), fighter)
	return root


static func _stage_card(shell, p, z: int, i: int, fighter: String) -> Control:
	var st := Zones.stage(z, i)
	var boss := Zones.is_boss(st)
	var unlocked := Campaign.is_unlocked(p, z, i)
	var stars := Campaign.stars_of(p, z, i)
	var name: String = st.get("name", Roster.get_critter(st.enemy).name)
	var rec := Campaign.enemy_rating(z, i)
	var mine: int = p.power_of(fighter)

	var title := Kit.hbox(8, [Kit.label(Zones.stage_key(z, i), 22, Kit.MUTED), _fit(Kit.label(name, 28))])
	if boss:
		title.add_child(Kit.chip("BOSS", Kit.BAD))
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var info := Kit.vbox(6, [title, Kit.label("You're stronger" if mine >= rec else ("Close fight" if mine * 1.15 >= rec else "They're stronger"), 20, power_color),
		Glyph.make("stars", 26, Kit.FG, stars, 3)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var actions := Kit.vbox(8)
	if not unlocked:
		actions.add_child(Kit.hbox(6, [Glyph.make("lock", 26, Kit.MUTED), Kit.label("Locked", 22, Kit.MUTED)]))
	else:
		var fight := Kit.button("Fight  %d" % Zones.cost(st), _fight.bind(shell, z, i, fighter), "go", 24, 72)
		fight.custom_minimum_size.x = 150
		shell.mark("stage_%d_%d" % [z + 1, i + 1], fight)
		actions.add_child(fight)
		if Campaign.can_sweep(p, z, i):
			var sweep := Kit.button("Sweep", _sweep.bind(shell, z, i, fighter), "ghost", 22, 60)
			shell.mark("sweep_%d_%d" % [z + 1, i + 1], sweep)
			actions.add_child(sweep)

	var icon := FighterTag.make(st.enemy, enemy_tier(st), rec, 108 if boss else 92, power_color, not unlocked)
	var row := Kit.hbox(12, [icon, info, actions])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var border := Kit.BAD.darkened(.3) if boss else (Kit.GOOD.darkened(.5) if stars > 0 else Kit.LINE)
	var card := Kit.panel(row, Kit.box(Kit.PANEL, border, 30, 2, 14))
	if not unlocked:
		card.modulate = Color(1, 1, 1, .55)
	return card


## A label that trims with an ellipsis instead of pushing its card wider than the screen.
static func _fit(l: Label) -> Label:
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 60
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l


## The tier shown for a stage's enemy. It fights at T1 abilities with a power
## boost, so this is the tier that power matches, as on Spire floors.
static func enemy_tier(st: Dictionary) -> int:
	return Spire.display_tier(st.power, Roster.rarity_base(Roster.get_critter(st.enemy).rarity) / 100.0)


## "T2 Optic · 1,250 power vs T3 Chomp · 1,400 power" for a stage fight.
static func matchup_text(p, z: int, i: int, fighter: String) -> String:
	var st := Zones.stage(z, i)
	var b: Dictionary = p.best(fighter)
	return "%s vs %s" % [FighterTag.text(Roster.get_critter(fighter).name, b.get("tier", 1), p.power_of(fighter), b.get("level", 0)),
		FighterTag.text(st.get("name", Roster.get_critter(st.enemy).name), enemy_tier(st), Campaign.enemy_rating(z, i))]


static func _fight(shell, z: int, i: int, fighter: String) -> void:
	var cfg: Dictionary = Campaign.start(shell.profile, z, i, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		shell.toast(_error_text(cfg.error))
		shell.refresh()
		return
	shell.stage_requested.emit(cfg, z, i, fighter)


static func _sweep(shell, z: int, i: int, fighter: String) -> void:
	var r: Dictionary = Campaign.sweep(shell.profile, z, i, fighter, int(Time.get_unix_time_from_system()))
	if r.has("error"):
		shell.toast(_error_text(r.error))
		shell.refresh()
		return
	shell.refresh_with({"zone": z, "focus": i, "result": {"stage": i, "r": r, "kind": "sweep"}})


static func _error_text(error: String) -> String:
	match error:
		"energy":
			return "Not enough energy. It refills 1 every 5 minutes, or use an Energy Pack from your Bag."
		"no_ball":
			return "Pick a critter that can fight first."
	return "That stage is locked."


## One line summing up a stage result, for the result screen and sweeps.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost. %d energy back, +%d XP. Try a stronger critter, or fuse one up." % [r.refund, r.xp]
	var parts: Array[String] = ["%d of 3 stars" % r.stars]
	if not r.drops.is_empty():
		parts.append("got " + ", ".join(r.drops.map(func(id): return Roster.get_critter(id).name)))
	if r.get("orbs", 0) > 0:
		parts.append("+%d Summon Orb%s" % [r.orbs, "" if r.orbs == 1 else "s"])
	for g in r.get("gear", []):
		parts.append("found a %d-star %s" % [g.tier, g.name])
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)


## The popup after a stage fight or sweep: win or loss, stars, what dropped,
## XP and energy, with Next stage when there is one to fight.
static func _result_popup(shell, z: int, i: int, r: Dictionary, kind: String, fighter: String) -> void:
	var st := Zones.stage(z, i)
	var name: String = st.get("name", Roster.get_critter(st.enemy).name)
	var v := Kit.vbox(18)
	var title := "Victory!" if r.won else "Defeated"
	v.add_child(Kit.vbox(2, [Kit.caption("%s %s · %s" % ["Sweep" if kind == "sweep" else "Stage", Zones.stage_key(z, i), name]),
		Kit.label(title, 52, Kit.GOOD if r.won else Kit.BAD)]))
	if r.won:
		var star_row := Kit.hbox(12, [Glyph.make("stars", 48, Kit.FG, r.stars, 3)], BoxContainer.ALIGNMENT_CENTER)
		v.add_child(star_row)
		if not r.drops.is_empty() or not r.get("gear", []).is_empty() or r.get("orbs", 0) > 0:
			var drops := GridContainer.new()
			drops.columns = 3
			drops.add_theme_constant_override("h_separation", 14)
			drops.add_theme_constant_override("v_separation", 14)
			for id in r.drops:
				var c := Roster.get_critter(id)
				var cell := Kit.vbox(4, [CritterIcon.make(id, 1, 96), _fit(Kit.label(c.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))])
				cell.custom_minimum_size.x = 150
				drops.add_child(Kit.panel(cell, Kit.box(Kit.PANEL2, Kit.LINE, 24, 2, 10)))
			if r.get("orbs", 0) > 0:
				var orb_cell := Kit.vbox(4, [Kit.hbox(0, [Glyph.make("orb", 84)], BoxContainer.ALIGNMENT_CENTER),
					_fit(Kit.label("%d Summon Orb%s" % [r.orbs, "" if r.orbs == 1 else "s"], 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))])
				orb_cell.custom_minimum_size.x = 150
				drops.add_child(Kit.panel(orb_cell, Kit.box(Kit.PANEL2, Color("c77dff"), 24, 2, 10)))
			for g in r.get("gear", []):
				var col := BagScreen.tier_color(g.tier)
				var cell := Kit.vbox(4, [Kit.hbox(0, [Glyph.make(Gear.PIECES[g.type].glyph, 72, col)], BoxContainer.ALIGNMENT_CENTER),
					Kit.hbox(0, [Glyph.make("stars", 18, col, g.tier)], BoxContainer.ALIGNMENT_CENTER), _fit(Kit.label(g.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))])
				cell.custom_minimum_size.x = 150
				drops.add_child(Kit.panel(cell, Kit.box(Kit.PANEL2, Color(col, .6), 24, 2, 10)))
			v.add_child(Kit.vbox(8, [Kit.caption("Drops"), drops]))
	else:
		v.add_child(Kit.label("Try a stronger critter, or fuse one up.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var spent := Zones.cost(st) - int(r.refund)
	var lines := Kit.vbox(8, [
		Kit.hbox(10, [Glyph.make("energy", 28), Kit.label("%d energy spent%s" % [spent, (" · %d back" % r.refund) if r.refund > 0 else ""], 24, Kit.MUTED)]),
		Kit.label("+%d XP for %s%s" % [r.xp, Roster.get_critter(fighter).name, " · level up!" if r.levels > 0 else ""], 24, Kit.MUTED),
	])
	if r.account_levels > 0:
		lines.add_child(Kit.label("Account level up! Energy refilled.", 24, Kit.GOOD))
	v.add_child(lines)
	var buttons := Kit.hbox(14)
	var ok := Kit.button("Continue", shell.close_overlay, "ghost" if r.won and i + 1 < Zones.zone(z).stages.size() else "go", 26, 84)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("result_continue", ok)
	buttons.add_child(ok)
	var next := i + 1 if r.won else i
	if next < Zones.zone(z).stages.size() and Campaign.is_unlocked(shell.profile, z, next):
		var again := Kit.button(("Next  %s" % Zones.stage_key(z, next)) if r.won else "Try again", func():
			shell.close_overlay()
			_fight(shell, z, next, Campaign.fighter_for(shell.profile)), "go", 26, 84)
		again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("result_next", again)
		buttons.add_child(again)
	v.add_child(buttons)
	shell.sheet(v)
