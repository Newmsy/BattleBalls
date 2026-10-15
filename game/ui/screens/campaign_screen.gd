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
	shell.refresh_with({"zone": z, "notice": "Sweep %s: %s" % [Zones.stage_key(z, i), result_text(r)]})


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
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	if r.account_levels > 0:
		parts.append("account level up, energy refilled!")
	return ", ".join(parts)
