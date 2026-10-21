## The Spire (design/spire.md): this week's next floor (enemy lineup, power
## and reward), your critters with their Stamina, and the climb button.
## Picks go in order into params.picks; the fight runs in game/spire.tscn,
## which records the result in the climb file and comes back here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const LiveOps := preload("res://game/liveops.gd")

const TOWER := Color("ffc23d")
const Gear := preload("res://sim/gear.gd")

## Set by the fight scene so the home screen opens back on the Spire.
static var reopen := false
static var _url_opened := false


## True when the home screen should open on the Spire: coming back from a
## climb, or ?mode=spire on the first load.
static func should_open(url_params: Dictionary) -> bool:
	if reopen:
		reopen = false
		return true
	if url_params.get("mode", "") == "spire" and not _url_opened:
		_url_opened = true
		return true
	return false


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var now := LiveOps.now()
	var climb = SpireClimb.load_file(now)
	if not climb.pending.is_empty():
		climb.abandon()
		climb.save_file()
	_collect(shell, climb)
	var root := Kit.vbox(22)

	var how: Control = shell.info_button("How the Spire works", [
		"One %d-floor tower for everyone, rebuilt every Monday. Pick your lineup for each floor; they fight in the order you pick them, and a winner stays in with the HP it has left." % Spire.FLOORS,
		"Boss floors: the boss is huge and takes on your whole lineup alone.",
		"Every critter that comes out to fight spends 1 of its %d Stamina, win or lose. Tired critters rest until Monday, so spread the climb across your whole collection." % SpireClimb.STAMINA,
		"Coming up: " + _upcoming_text(climb),
	], "spire_info")
	var back: Control = shell.back_button("spire_back")
	root.add_child(Kit.hbox(18, [back, Kit.label("The Spire", 40), Kit.spacer(), how], BoxContainer.ALIGNMENT_CENTER))
	var sub := "Floor %d of %d cleared. Resets in %s." % [climb.cleared, Spire.FLOORS, LiveOps.countdown(now, Spire.week_end(climb.week))]
	if climb.last_week_best > 0:
		sub += " Last week: floor %d." % climb.last_week_best
	root.add_child(Kit.label(sub, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(Kit.bar(float(climb.cleared) / Spire.FLOORS, TOWER, 16))
	if climb.finished():
		root.add_child(Kit.panel(Kit.vbox(10, [Kit.label("Summit reached!", 40, TOWER),
			Kit.label("You cleared all %d floors. The tower rebuilds on Monday." % Spire.FLOORS, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)]),
			Kit.box(Color("2a2210"), TOWER.darkened(.4), 40, 2, 30)))
		return root
	var spec: Dictionary = climb.floor_spec()
	var picks: Array = params.get("picks", [])
	root.add_child(_floor_card(spec))
	root.add_child(_picker(shell, climb, spec, picks))
	return root


## Critters the sim can field, best first, as {id, power, stamina, slot}:
## `power` is the Power Rating shown, `slot` what fights (Profile.slot_of).
static func fighters(p, climb) -> Array:
	var out: Array = []
	for id in BallDefs.PLAYABLE:
		if p.owns(id):
			out.append({"id": id, "power": p.power_of(id) / 1000.0, "stamina": climb.stamina(id), "slot": p.slot_of(id)})
	out.sort_custom(func(a, b): return a.power > b.power)
	return out


static func _floor_card(spec: Dictionary) -> Control:
	var n: int = spec.floor
	var title := "Floor %d" % n + (" · Boss" if spec.boss else "")
	var foes := Kit.hbox(14, [], BoxContainer.ALIGNMENT_CENTER)
	for e in spec.enemies:
		var tier := Spire.display_tier(e.power, Roster.rarity_base(Roster.get_critter(e.id).rarity) / 100.0)
		var side := 150.0 if spec.boss else 104.0
		foes.add_child(Kit.vbox(4, [FighterTag.make(e.id, tier, roundi(e.power * 1000.0), side),
			Kit.label(BallDefs.get_def(e.id).display_name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)]))
	var r := Spire.reward(n)
	var bits := ["%d coins" % r.coins]
	if r.xp_chips > 0:
		bits.append("XP Chip")
	if r.orbs > 0:
		bits.append("Summon Egg")
	if not r.gear.is_empty():
		bits.append(gear_name(r.gear))
	var v := Kit.vbox(12, [
		Kit.caption("Next floor · plain arena · %d vs %d" % [spec.lineup, spec.enemies.size()], TOWER),
		Kit.label(title, 36),
		foes,
		Kit.label("First clear: " + ", ".join(bits), 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	return Kit.panel(v, Kit.box(Color("221a0c"), TOWER.darkened(.45), 36, 2, 22))


static func _picker(shell, climb, spec: Dictionary, picks: Array) -> Control:
	var p = shell.profile
	var list := fighters(p, climb)
	var v := Kit.vbox(12)
	v.add_child(Kit.hbox(0, [Kit.caption("Your lineup · pick %d in order" % spec.lineup), Kit.spacer(),
		Kit.label("%d/%d" % [picks.size(), spec.lineup], 22, Kit.MUTED)]))
	if list.is_empty():
		v.add_child(Kit.label("None of your critters can fight in the arena yet.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		return v
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for f in list:
		var order: int = picks.find(f.id)
		var tired: bool = f.stamina <= 0
		var col := Kit.MUTED if tired else Kit.FG
		var tag := Kit.label("#%d" % (order + 1) if order >= 0 else ("Tired" if tired else ""), 20, TOWER if order >= 0 else Kit.BAD, HORIZONTAL_ALIGNMENT_CENTER)
		var icon := FighterTag.icon(f.id, p.best(f.id).tier, 96, false, p.best(f.id).level)
		if tired:
			icon.modulate = Color(1, 1, 1, 0.35)
		var cell := Kit.vbox(4, [
			icon,
			Kit.label(Roster.get_critter(f.id).name, 20, col, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.power(roundi(f.power * 1000.0), 18, col),
			_pips(f.stamina),
			tag,
		])
		var on_tap := func():
			var next := picks.duplicate()
			if order >= 0:
				next.erase(f.id)
			elif tired:
				shell.toast("%s is tired until Monday." % Roster.get_critter(f.id).name)
				return
			elif next.size() >= spec.lineup:
				shell.toast("This floor takes %d. Tap a pick to take it out." % spec.lineup)
				return
			else:
				next.append(f.id)
			shell.refresh_with({"picks": next})
		var card := Kit.card_button(cell, on_tap, TOWER if order >= 0 else Kit.LINE, Kit.PANEL2 if order >= 0 else Kit.PANEL, 28, 10)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("spire_pick_" + f.id, card)
		grid.add_child(card)
	v.add_child(grid)
	# The climb button stays put under the list, however many critters it holds.
	var climb_btn := Kit.button("Climb floor %d" % spec.floor, func(): _climb(shell, climb, picks), "go" if not picks.is_empty() else "ghost", 32, 96)
	shell.mark("spire_climb", climb_btn)
	var actions := Kit.hbox(12, [climb_btn])
	if picks.is_empty() and spec.lineup > 1:
		var auto := Kit.button("Suggest", func(): shell.refresh_with({"picks": suggest(list, spec)}), "ghost", 26, 96)
		auto.size_flags_horizontal = Control.SIZE_SHRINK_END
		auto.custom_minimum_size.x = 200
		shell.mark("spire_suggest", auto)
		actions.add_child(auto)
	shell.pin(actions)
	return v


## Fresh critters closest to the floor's power, weakest first, so the best
## ones are saved for the floors above.
static func suggest(list: Array, spec: Dictionary) -> Array:
	var need: float = Spire.power_at(spec.floor) * 0.95
	var fresh := list.filter(func(f): return f.stamina > 0)
	fresh.sort_custom(func(a, b): return a.power < b.power)
	var strong := fresh.filter(func(f): return f.power >= need)
	var pool: Array = strong if strong.size() >= spec.lineup else fresh.slice(maxi(0, fresh.size() - spec.lineup))
	return pool.slice(0, spec.lineup).map(func(f): return f.id)


static func _pips(left: int) -> Control:
	var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for i in SpireClimb.STAMINA:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.color = Kit.GOOD if i < left else Color("3b3770")
		row.add_child(dot)
	return row


## The next few floors in one line each, for the info sheet.
static func _upcoming_text(climb) -> String:
	var out := []
	var start: int = climb.next_floor() + 1
	for n in range(start, mini(start + 4, Spire.FLOORS + 1)):
		var r := Spire.reward(n)
		var extra := []
		if r.orbs > 0:
			extra.append("Summon Egg")
		if not r.gear.is_empty():
			extra.append(gear_name(r.gear))
		var name := "floor %d" % n + (" (boss)" if Spire.is_boss(n) else "")
		var line := "%s, %d vs %d, power %s" % [name, Spire.lineup_size(n), Spire.lineup_size(n), Kit.commas(roundi(Spire.power_at(n) * 1000.0))]
		if not extra.is_empty():
			line += ", " + ", ".join(extra)
		out.append(line)
	return "; ".join(out) + "." if not out.is_empty() else "the summit."


static func _climb(shell, climb, picks: Array) -> void:
	var list := fighters(shell.profile, climb)
	var chosen: Array = []
	for id in picks:
		for f in list:
			if f.id == id:
				chosen.append({"id": id, "power": f.power, "slot": f.slot})
	var why: String = climb.check_picks(chosen)
	if why != "":
		shell.toast(why)
		return
	climb.begin(chosen)
	climb.save_file()
	shell.get_tree().change_scene_to_file("res://game/spire.tscn")


## Adds rewards from floors cleared since the last visit to the profile.
static func _collect(shell, climb) -> void:
	if climb.unclaimed.is_empty():
		return
	var t: Dictionary = climb.take_rewards()
	grant(shell.profile, t)
	climb.save_file()
	var bits := ["%d coins" % t.coins]
	if t.orbs > 0:
		bits.append("%d Summon Egg%s" % [t.orbs, "" if t.orbs == 1 else "s"])
	if t.xp_chips > 0:
		bits.append("%d XP Chip%s" % [t.xp_chips, "" if t.xp_chips == 1 else "s"])
	for g in t.gear:
		bits.append(gear_name(g))
	shell.toast("Spire rewards: " + ", ".join(bits))


## Puts a reward bundle (SpireClimb.take_rewards) into the profile.
static func grant(p, t: Dictionary) -> void:
	p.coins += int(t.coins)
	p.orbs += int(t.orbs)
	_add_item(p, "Summon Egg", 0, "", Color("c86bff")).count = p.orbs
	if t.xp_chips > 0:
		_add_item(p, "XP Chip", t.xp_chips, "+200 XP to one critter.", Color("45f5a6"))
	for g in t.gear:
		p.add_gear(g.type, g.tier)
	p.changed.emit()


## "3-star Iron Shell" for a gear reward {type, tier}.
static func gear_name(g: Dictionary) -> String:
	return "%d-star %s" % [g.tier, Gear.PIECES[g.type].name]


static func _add_item(p, name: String, n: int, text: String, color: Color) -> Dictionary:
	for i in p.items:
		if i.name == name:
			i.count += n
			return i
	var item := {"name": name, "count": n, "text": text, "color": color}
	p.items.append(item)
	return item
