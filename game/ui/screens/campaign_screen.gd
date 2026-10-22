## Campaign: the Glow Garden stage list (design/pve.md section 3). Each stage
## shows its enemy, Recommended Power and stars; Fight spends energy and
## starts the stage in the arena, Sweep replays a 3-starred stage off-screen.
## Rules live in meta/campaign.gd; this only shows them.
extends RefCounted

const ResultPopup := preload("res://game/ui/result_popup.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Intro := preload("res://game/ui/intro.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Spire := preload("res://sim/spire.gd")
const Roster := preload("res://game/ui/roster.gd")
const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const Gear := preload("res://sim/gear.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const FamilyEdge := preload("res://game/ui/family_edge.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Story := preload("res://meta/story.gd")
const StoryCards := preload("res://game/ui/story_cards.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const EnergySheet := preload("res://game/ui/energy_sheet.gd")


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var z: int = params.get("zone", 0)
	var zone := Zones.zone(z)
	var now := int(Time.get_unix_time_from_system())
	p.update_energy(now)
	var root := Kit.vbox(22)

	var back: Control = shell.back_button("back")
	var head := Kit.vbox(2, [Kit.caption(("Zone %d · Team of 3" % (z + 1)) if zone.lineup == 3 else ("Zone %d · %dv%d" % [z + 1, zone.lineup, zone.lineup]), Color("9be89a")),
		Kit.label(zone.name, 44)])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title_row := Kit.hbox(16, [back, head])
	var has_story := not Story.chapter(z).is_empty()
	if has_story:
		var replay := Kit.card_button(Kit.label("Story", 22), play_story.bind(shell, z), Kit.LINE, Kit.PANEL, 999, 14)
		replay.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		shell.mark("story", replay)
		title_row.add_child(replay)
	root.add_child(title_row)

	# The top bar shows the energy count; this only says when the next one lands.
	var wait: int = p.seconds_to_next_energy(now)
	if wait > 0:
		root.add_child(Kit.hbox(10, [Glyph.make("energy", 30), Kit.label("+1 in %d:%02d" % [wait / 60, wait % 60], 24, Kit.MUTED)]))

	if params.has("notice"):
		root.add_child(Kit.panel(Kit.label(params.notice, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true), Kit.box(Color("1d2a1f"), Kit.GOOD, 28, 2, 20)))

	# Fighter: the lineup critter, or the strongest one that can fight.
	# Pairs and trios zones bring a team: the fighter first, then the strongest others.
	var fighter: String = Campaign.fighter_for(p)
	var team: Array = Campaign.team_for(p, zone.lineup) if zone.lineup > 1 else [fighter]
	var names: Array = team.map(func(id): return Roster.get_critter(id).name)
	var team_power := 0
	for id in team:
		team_power += p.power_of(id)
	var info := Kit.vbox(4, [Kit.caption("Your fighter" if team.size() == 1 else "Your team"), _fit(Kit.label(" + ".join(names), 30 if team.size() == 1 else 24)),
		Kit.power(team_power / maxi(1, team.size()), 24)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var change := Kit.chip("Change", Kit.ACCENT)
	var icons := Kit.hbox(4 if team.size() < 3 else 10)
	for id in team:
		var tb: Dictionary = p.best(id)
		# Teams drop the level so the stars fit over each smaller icon.
		icons.add_child(FighterTag.icon(id, tb.get("tier", 1), [100, 100, 70, 56][team.size()], false, tb.get("level", 1) if team.size() == 1 else 0))
	var fighter_row := Kit.hbox(14, [icons, info, change])
	fighter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var on_pick := func(id: String) -> void:
		p.set_lineup(id)
		shell.refresh()
	var on_team := func(picks: Array) -> void:
		p.campaign_team = picks
		p.changed.emit()
		shell.refresh()
	# The stage you're on: the picker badges each critter's family edge on its foes.
	var next_foes := []
	for i in zone.stages.size():
		if Campaign.is_unlocked(p, z, i) and not Campaign.is_cleared(p, z, i):
			next_foes = Zones.enemies(Zones.stage(z, i))
			break
	var pick := func() -> void:
		var ids := CritterPicker.by_power(p, BallDefs.PLAYABLE)
		if team.size() > 1:
			CritterPicker.open_team(shell, ids, {"title": "Your team", "size": mini(zone.lineup, ids.size()), "current": team, "on_confirm": on_team, "foes": next_foes})
		else:
			CritterPicker.open(shell, ids, {"title": "Your fighter", "current": fighter, "on_pick": on_pick, "foes": next_foes})
	var change_btn := Kit.card_button(fighter_row, pick, Color("3a3480"), Kit.PANEL2, 32, 16)
	shell.mark("campaign_fighter", change_btn)
	root.add_child(change_btn)

	var list := Kit.vbox(14)
	for i in zone.stages.size():
		list.add_child(_stage_card(shell, p, z, i, fighter))
	root.add_child(list)
	# Land on the stage just played, not the top of the list.
	if params.has("focus"):
		shell.scroll_to(list.get_child(clampi(params.focus, 0, zone.stages.size() - 1)))
	# A chapter's story plays the first time you open it.
	if has_story and not params.has("result") and not Story.seen(p, zone.id):
		play_story(shell, z)
	if params.has("result"):
		_result_popup(shell, z, params.result.stage, params.result.r, params.result.get("kind", "fight"), fighter)
	return root


## Plays zone `z`'s chapter story over the screen; finishing or skipping it
## counts it as seen.
static func play_story(shell, z: int) -> void:
	var id: String = Zones.zone(z).id
	var cards: Control = StoryCards.make(Story.chapter(z), func():
		Story.mark_seen(shell.profile, id)
		shell.close_overlay())
	shell.overlay(cards, "story")
	shell.mark("story_next", cards.next_button)
	shell.mark("story_skip", cards.skip_button)


## One stage row. Locked stages are just their number, the foe's silhouette
## and a lock; the stage you're on gets the big card (foe faces, your power
## against theirs, FIGHT); cleared ones are a slim row with their result,
## replay and Sweep.
static func _stage_card(shell, p, z: int, i: int, fighter: String) -> Control:
	var st := Zones.stage(z, i)
	var boss := Zones.is_boss(st)
	if not Campaign.is_unlocked(p, z, i):
		return _locked_row(z, i, st, boss)
	var stars := Campaign.stars_of(p, z, i)
	var foes := Zones.enemies(st)
	# Named stages (bosses) keep their name; the rest show their foes' faces instead.
	var name: String = st.get("name", "")
	var rec := Campaign.enemy_rating(z, i)
	var mine: int = p.power_of(fighter)
	if foes.size() > 1:
		var team := Campaign.team_for(p, Zones.zone(z).lineup)
		mine = 0
		for id in team:
			mine += p.power_of(id)
		mine /= maxi(1, team.size())
	var power_color := Kit.GOOD if mine >= rec else (Kit.WARN if mine * 1.15 >= rec else Kit.BAD)
	var title := Kit.hbox(8, [Kit.label(Zones.stage_key(z, i), 22, Kit.MUTED)])
	if name != "":
		title.add_child(_fit(Kit.label(name, 28)))
	if boss:
		title.add_child(Kit.chip("BOSS", Kit.BAD))
	if Zones.zone(z).lineup == 3: # Trios zones mix relays, 2v2s and 3v3 brawls.
		title.add_child(Kit.chip(Zones.format_label(z, i), Kit.ACCENT))
	var border := Kit.BAD.darkened(.3) if boss else Kit.GOOD.darkened(.5)

	if not Campaign.is_cleared(p, z, i):
		# The stage you're on: foe faces, the power comparison and one big FIGHT.
		var faces := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
		var side: float = (260.0 if boss else 220.0) / sqrt(float(foes.size()))
		for id in foes:
			faces.add_child(_face(id, enemy_tier(st), side))
		var vs := Kit.hbox(10, [Kit.caption("You"), Kit.power(mine, 26, power_color), Kit.spacer(), Kit.caption("Foe"), Kit.power(rec, 26)],
			BoxContainer.ALIGNMENT_CENTER)
		var parts := [vs]
		var edge_row := _edge_row(p, z, foes, fighter)
		if edge_row != null:
			parts.append(edge_row)
		var fight := Kit.cost_button("Fight", Zones.cost(st), "energy", _fight.bind(shell, z, i, fighter), "go", 30, 84)
		_fade_if_short(fight, p, Zones.cost(st))
		shell.mark("stage_%d_%d" % [z + 1, i + 1], fight)
		var big := Kit.panel(Kit.vbox(12, [title, faces] + parts + [fight]), Kit.box(Color("17284a"), border.lightened(.2), 32, 3, 20))
		return big

	var info := Kit.vbox(4, [title, crowns(stars, 26)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var actions := Kit.hbox(8)
	if Campaign.can_sweep(p, z, i):
		var sweep := Kit.button("Sweep", _sweep.bind(shell, z, i, fighter), "ghost", 22, 60)
		_fade_if_short(sweep, p, Zones.cost(st))
		shell.mark("sweep_%d_%d" % [z + 1, i + 1], sweep)
		actions.add_child(sweep)
	var again := Kit.cost_button("", Zones.cost(st), "energy", _fight.bind(shell, z, i, fighter), "go", 22, 60)
	again.custom_minimum_size.x = 100
	_fade_if_short(again, p, Zones.cost(st))
	again.size_flags_horizontal = Control.SIZE_SHRINK_END
	shell.mark("stage_%d_%d" % [z + 1, i + 1], again)
	actions.add_child(again)
	var art := Kit.hbox(0, [], BoxContainer.ALIGNMENT_CENTER)
	for id in foes:
		art.add_child(_face(id, enemy_tier(st), [100.0, 100.0, 84.0, 70.0][mini(foes.size(), 3)]))
	var row := Kit.hbox(12, [art, info, actions])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return Kit.panel(row, Kit.box(Kit.PANEL, border, 28, 2, 12))


## Family edges for the stage you're on: your side's edge on these foes, and
## which families hit them hardest. Null when no family edge applies (bosses, Plain).
static func _edge_row(p, z: int, foes: Array, fighter: String) -> Control:
	var best := FamilyEdge.counters(foes)
	if best.is_empty():
		return null
	var mine: Array = Campaign.team_for(p, Zones.zone(z).lineup) if foes.size() > 1 else [fighter]
	var score := FamilyEdge.team(mine, foes)
	var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	if score != 0:
		row.add_child(FamilyEdge.badge(score, 24))
		row.add_child(Kit.label(FamilyEdge.words(score), 20, Kit.GOOD if score > 0 else Kit.BAD))
	row.add_child(Kit.spacer())
	row.add_child(Kit.caption("Hits them hard"))
	for f in best:
		row.add_child(FamilyIcon.make(f, 30))
	return row


## A Fight or Sweep that costs more energy than you have stays tappable (it
## opens the out-of-energy sheet) but looks short.
static func _fade_if_short(b: Control, p, cost: int) -> void:
	if p.energy < cost:
		b.modulate = Color(1, 1, 1, .5)


## A green button reading "FIGHT ⚡6" with the drawn energy bolt (the font has
## none); a `cost` of -1 leaves the number off ("OUT OF ⚡").
static func _cost_button(text: String, cost: int, on_press: Callable, size: int, height: int) -> Button:
	var b := Kit.button("", on_press, "go", size, height)
	var ink: Color = Kit.BUTTON_STYLES["go"][2]
	var parts: Array = [Glyph.make("energy", size * 1.1, ink)]
	if cost >= 0:
		parts.append(Kit.label(str(cost), size, ink))
	if text != "":
		parts.push_front(Kit.label(text.to_upper() + " ", size, ink))
	var row := Kit.hbox(2, parts, BoxContainer.ALIGNMENT_CENTER)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in row.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	return b


## A foe's face `side` wide, the ball filling its box (CritterIcon pads for effects).
static func _face(id: String, tier: int, side: float, silhouette := false) -> Control:
	var art := CritterIcon.make(id, tier, side * FighterTag.ART_SHRINK, false, silhouette)
	art.radius_frac /= FighterTag.ART_SHRINK
	return art


## A stage you can't fight yet: its number, the foe's silhouette and a lock.
static func _locked_row(z: int, i: int, st: Dictionary, boss: bool) -> Control:
	var art := Kit.hbox(0, [], BoxContainer.ALIGNMENT_CENTER)
	var foes := Zones.enemies(st)
	for id in foes:
		art.add_child(_face(id, 1, (92.0 if boss else 76.0) / sqrt(float(foes.size())), true))
	var key := Kit.label(Zones.stage_key(z, i), 24, Kit.MUTED)
	key.custom_minimum_size.x = 64
	var row := Kit.hbox(14, [key, art, Kit.spacer(), Glyph.make("lock", 26, Kit.MUTED)])
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var card := Kit.panel(row, Kit.box(Kit.PANEL, Kit.BAD.darkened(.4) if boss else Kit.LINE, 28, 2, 10))
	card.modulate = Color(1, 1, 1, .7)
	return card


## A stage's three crown slots, `won` of them gold (crowns, not stars: a
## star means tier).
static func crowns(won: int, side: float) -> Control:
	var row := Kit.hbox(int(side * .12))
	for k in 3:
		row.add_child(Glyph.make("crown", side, Kit.FG, 1 if k < won else 0))
	return row


## A label that trims with an ellipsis instead of pushing its card wider than the screen.
static func _fit(l: Label) -> Label:
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 60
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l


## The tier a stage's foes fight at (Zones.FOE_TIERS, by chapter).
static func enemy_tier(st: Dictionary) -> int:
	return st.get("tier", 1)


## "T2 Optic · 1,250 power vs T3 Chomp · 1,400 power" for a stage fight.
static func matchup_text(p, z: int, i: int, fighter: String) -> String:
	var st := Zones.stage(z, i)
	var b: Dictionary = p.best(fighter)
	return "%s vs %s" % [FighterTag.text(Roster.get_critter(fighter).name, b.get("tier", 1), p.power_of(fighter), b.get("level", 0)),
		FighterTag.text(st.get("name", Roster.get_critter(st.enemy).name), enemy_tier(st), Campaign.enemy_rating(z, i))]


## "Optic + Bolt · 2,500 power vs Pinball + Cogs · 1,550" for a 2v2 pairs stage.
static func pair_text(p, z: int, i: int, picks: Array) -> String:
	var st := Zones.stage(z, i)
	var power := 0
	for id in picks:
		power += p.power_of(id)
	var foes: Array = Zones.enemies(st).map(func(e): return Roster.get_critter(e).name)
	return "%s · %s power vs %s · %s" % [" + ".join(picks.map(func(id): return Roster.get_critter(id).name)), Kit.commas(power),
		st.get("name", " + ".join(foes)), Kit.commas(Campaign.enemy_rating(z, i) * foes.size())]


static func _fight(shell, z: int, i: int, fighter: String) -> void:
	if Zones.zone(z).lineup > 1:
		_fight_team(shell, z, i)
		return
	var cfg: Dictionary = Campaign.start(shell.profile, z, i, fighter, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		_show_error(shell, cfg.error)
		return
	shell.stage_requested.emit(cfg, z, i, fighter)


static func _sweep(shell, z: int, i: int, fighter: String) -> void:
	var r: Dictionary = Campaign.sweep(shell.profile, z, i, fighter, int(Time.get_unix_time_from_system()))
	if r.has("error"):
		_show_error(shell, r.error)
		return
	shell.refresh_with({"zone": z, "focus": i, "result": {"stage": i, "r": r, "kind": "sweep"}})


## Out of energy opens the energy sheet; anything else is a one-line toast.
static func _show_error(shell, error: String) -> void:
	shell.refresh()
	if error == "energy":
		EnergySheet.open(shell)
	else:
		shell.toast(_error_text(error))


static func _error_text(error: String) -> String:
	if error == "no_ball":
		return "Pick a critter that can fight first."
	return "That stage is locked."


## One line summing up a stage result, for the result screen and sweeps.
static func result_text(r: Dictionary) -> String:
	if not r.won:
		return "Lost · +%d XP" % r.xp
	var parts: Array[String] = ["%d/3 crowns" % r.stars]
	if not r.drops.is_empty():
		parts.append("got " + ", ".join(r.drops.map(func(id): return Roster.get_critter(id).name)))
	if r.get("orbs", 0) > 0:
		parts.append("+%d Summon Egg%s" % [r.orbs, "" if r.orbs == 1 else "s"])
	for g in r.get("gear", []):
		parts.append("found a %d-star %s" % [g.tier, g.name])
	parts.append("+%d XP" % r.xp)
	if r.levels > 0:
		parts.append("level up!")
	# An account level up shows on the results popup (energy refilled there).
	return ", ".join(parts)


## The popup after a stage fight or sweep: win or loss, stars, what dropped,
## XP and energy, with Next stage when there is one to fight.
static func _result_popup(shell, z: int, i: int, r: Dictionary, kind: String, fighter: String) -> void:
	var st := Zones.stage(z, i)
	var name: String = st.get("name", Roster.get_critter(st.enemy).name)
	var v := ResultPopup.content("%s %s · %s" % ["Sweep" if kind == "sweep" else "Stage", Zones.stage_key(z, i), name],
		ResultPopup.Outcome.WIN if r.won else ResultPopup.Outcome.LOSE)
	if r.won:
		var star_row := Kit.hbox(12, [crowns(r.stars, 52)], BoxContainer.ALIGNMENT_CENTER)
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
					_fit(Kit.label("%d Summon Egg%s" % [r.orbs, "" if r.orbs == 1 else "s"], 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))])
				orb_cell.custom_minimum_size.x = 150
				drops.add_child(Kit.panel(orb_cell, Kit.box(Kit.PANEL2, Color("c77dff"), 24, 2, 10)))
			for g in r.get("gear", []):
				var col := BagScreen.tier_color(g.tier)
				var cell := Kit.vbox(4, [Kit.hbox(0, [Glyph.make(g.type, 72, col)], BoxContainer.ALIGNMENT_CENTER),
					Kit.hbox(0, [Glyph.make("stars", 18, col, g.tier)], BoxContainer.ALIGNMENT_CENTER), _fit(Kit.label(g.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))])
				cell.custom_minimum_size.x = 150
				drops.add_child(Kit.panel(cell, Kit.box(Kit.PANEL2, Color(col, .6), 24, 2, 10)))
			v.add_child(Kit.vbox(8, [Kit.caption("Drops"), drops]))
	else:
		v.add_child(Kit.label("Try a stronger critter, or fuse one up.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	var spent := Zones.cost(st) - int(r.refund)
	var bars := XpBar.rows(r, shell.sfx)
	if bars != null:
		v.add_child(bars)
	var lines := Kit.vbox(8, [
		Kit.hbox(10, [Glyph.make("energy", 28), Kit.label("-%d%s" % [spent, ("  ·  +%d back" % r.refund) if r.refund > 0 else ""], 24, Kit.MUTED)]),
	])
	if bars == null:
		lines.add_child(Kit.label("+%d XP for %s%s" % [r.xp, Roster.get_critter(fighter).name, " · level up!" if r.levels > 0 else ""], 24, Kit.MUTED))
	if r.account_levels > 0:
		lines.add_child(Kit.label("Account level up! Energy refilled.", 24, Kit.GOOD))
	v.add_child(lines)
	var buttons := Kit.hbox(14)
	if r.has("intro"):
		# A new player's win that opens something: Continue shows what.
		var reveal := Kit.button("Continue", func():
			shell.close_overlay()
			Intro.moment(shell, r.intro), "go", 26, 84)
		reveal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("result_continue", reveal)
		v.add_child(reveal)
		shell.sheet(v)
		return
	# The first win over a chapter's boss leads on into the next chapter and its story.
	var next_zone: bool = r.won and r.first_clear and Zones.is_boss(st) and z + 1 < Zones.ZONES.size()
	var ok := Kit.button("Continue", shell.close_overlay, "ghost" if r.won and (i + 1 < Zones.zone(z).stages.size() or next_zone) else "go", 26, 84)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("result_continue", ok)
	buttons.add_child(ok)
	if next_zone:
		var chapter := Kit.button("Next chapter", func():
			shell.close_overlay()
			shell.go("campaign", {"zone": z + 1}), "go", 26, 84)
		chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("result_next_chapter", chapter)
		buttons.add_child(chapter)
	var next := i + 1 if r.won else i
	if next < Zones.zone(z).stages.size() and Campaign.is_unlocked(shell.profile, z, next):
		var p = shell.profile
		p.update_energy(int(Time.get_unix_time_from_system()))
		var again: Button
		if p.energy < Zones.cost(Zones.stage(z, next)):
			# Not enough for the next stage: say so up front; tap opens the energy sheet.
			again = _cost_button("Out of", -1, func():
				shell.close_overlay()
				EnergySheet.open(shell), 26, 84)
			again.modulate = Color(1, 1, 1, .75)
		else:
			again = Kit.button(("Next  %s" % Zones.stage_key(z, next)) if r.won else "Try again", func():
				shell.close_overlay()
				_fight(shell, z, next, Campaign.fighter_for(shell.profile)), "go", 26, 84)
		again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("result_next", again)
		buttons.add_child(again)
	v.add_child(buttons)
	shell.sheet(v)


## A pairs or trios stage: spend the energy, then fight it. A 2v2 or a 3v3
## brawl fights in the arena like a solo stage; a relay is on its own screen
## (game/campaign_relay.gd). main.gd settles either on the way back.
static func _fight_team(shell, z: int, i: int) -> void:
	var picks := Campaign.team_for(shell.profile, Zones.team_size(z, i))
	var cfg: Dictionary = Campaign.start_team(shell.profile, z, i, picks, int(Time.get_unix_time_from_system()))
	if cfg.has("error"):
		_show_error(shell, cfg.error)
		return
	if Campaign.is_pair(z, i, picks) or Campaign.is_brawl(z, i, picks):
		# All at once in the arena: a 2v2, or six balls on the zoomed-out arena.
		shell.stage_requested.emit(Campaign.team_config(shell.profile, cfg), z, i, picks[0])
		return
	var scene = load("res://game/campaign_relay.gd")
	scene.pending = {"zone": z, "stage": i, "picks": picks, "config": cfg}
	scene.done = {}
	shell.get_tree().change_scene_to_file("res://game/campaign_relay.tscn")
