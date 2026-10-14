## The Spire (design/spire.md): this week's next floor (enemy lineup, power
## and reward), your critters with their Stamina, and the climb button.
## Picks go in order into params.picks; the fight runs in game/spire.tscn,
## which records the result in the climb file and comes back here.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Spire := preload("res://sim/spire.gd")
const SpireClimb := preload("res://meta/spire_climb.gd")
const LiveOps := preload("res://game/liveops.gd")

const TOWER := Color("ffc23d")
const GEAR := {
	"rare": ["Spire Shell", "Shell", "Take 2 less damage per hit"],
	"epic": ["Spire Core", "Core", "Ability triggers 10% sooner"],
	"legendary": ["Summit Core", "Core", "+6% damage after a wall bounce"],
}

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
	var back := Kit.button("Back", shell.back, "ghost", 24, 64)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 150
	shell.mark("spire_back", back)
	root.add_child(Kit.hbox(16, [back, Kit.spacer(), Kit.label("Resets in " + LiveOps.countdown(now, Spire.week_end(climb.week)), 22, Kit.MUTED)]))
	root.add_child(Kit.label("The Spire", 48))
	var sub := "Floor %d of %d cleared this week." % [climb.cleared, Spire.FLOORS]
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
	root.add_child(_upcoming(climb))
	root.add_child(Kit.label("Every critter that comes out to fight spends 1 of its %d Stamina, win or lose. Tired critters rest until Monday, so spread the climb across your whole collection." % SpireClimb.STAMINA,
		22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	return root


## Critters the sim can field, best first, as {id, power, stamina}.
static func fighters(p, climb) -> Array:
	var out: Array = []
	for id in BallDefs.PLAYABLE:
		if p.owns(id):
			out.append({"id": id, "power": p.power_of(id) / 1000.0, "stamina": climb.stamina(id)})
	out.sort_custom(func(a, b): return a.power > b.power)
	return out


static func _floor_card(spec: Dictionary) -> Control:
	var n: int = spec.floor
	var title := "Floor %d" % n + (" · Boss" if spec.boss else "")
	var foes := Kit.hbox(14, [], BoxContainer.ALIGNMENT_CENTER)
	for e in spec.enemies:
		var rarity := String(BallDefs.get_def(e.id).get("rarity", "common"))
		var tier := Spire.display_tier(e.power, Roster.RARITY_BASE.get(rarity, 100.0) / 100.0)
		var side := 190.0 if spec.boss else 130.0
		foes.add_child(Kit.vbox(4, [CritterIcon.make(e.id, tier, side), Kit.label(BallDefs.get_def(e.id).display_name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.power(roundi(e.power * 1000.0), 22)]))
	var r := Spire.reward(n)
	var bits := ["%d coins" % r.coins]
	if r.xp_chips > 0:
		bits.append("XP Chip")
	if r.orbs > 0:
		bits.append("Summon Orb")
	if r.gear != "":
		bits.append("%s gear" % Roster.RARITY_NAMES[r.gear])
	var v := Kit.vbox(12, [
		Kit.caption("Next floor · plain arena · %d vs %d" % [spec.lineup, spec.enemies.size()], TOWER),
		Kit.label(title, 44),
		Kit.label("They fight in this order. The boss is huge and takes on your whole lineup alone." if spec.boss else "They fight in this order. Winners stay in with the HP they have left.",
			22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		foes,
		Kit.label("First clear: " + ", ".join(bits), 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	return Kit.panel(v, Kit.box(Color("221a0c"), TOWER.darkened(.45), 40, 2, 28))


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
		var icon := CritterIcon.make(f.id, p.best(f.id).tier, 96)
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
	var climb_btn := Kit.button("Climb floor %d" % spec.floor, func(): _climb(shell, climb, picks), "primary" if not picks.is_empty() else "ghost", 32, 96)
	shell.mark("spire_climb", climb_btn)
	v.add_child(climb_btn)
	if picks.is_empty() and spec.lineup > 1:
		var auto := Kit.button("Suggest a lineup", func(): shell.refresh_with({"picks": suggest(list, spec)}), "ghost", 24, 72)
		shell.mark("spire_suggest", auto)
		v.add_child(auto)
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


static func _upcoming(climb) -> Control:
	var v := Kit.vbox(8, [Kit.caption("Coming up")])
	var start: int = climb.next_floor() + 1
	for n in range(start, mini(start + 4, Spire.FLOORS + 1)):
		var r := Spire.reward(n)
		var extra := []
		if r.orbs > 0:
			extra.append("Summon Orb")
		if r.gear != "":
			extra.append("%s gear" % Roster.RARITY_NAMES[r.gear])
		var name := "Floor %d" % n + (" · Boss" if Spire.is_boss(n) else "")
		v.add_child(Kit.hbox(12, [Kit.label(name, 24, TOWER if Spire.is_boss(n) else Kit.FG), Kit.spacer(),
			Kit.label("%d vs %d" % [Spire.lineup_size(n), Spire.lineup_size(n)], 22, Kit.MUTED),
			Kit.power(roundi(Spire.power_at(n) * 1000.0), 22, Kit.MUTED),
			Kit.label(", ".join(extra), 20, Kit.GOOD)]))
	return Kit.panel(v, Kit.box(Kit.PANEL, Kit.LINE, 32, 2, 22))


static func _climb(shell, climb, picks: Array) -> void:
	var list := fighters(shell.profile, climb)
	var chosen: Array = []
	for id in picks:
		for f in list:
			if f.id == id:
				chosen.append({"id": id, "power": f.power})
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
		bits.append("%d Summon Orb%s" % [t.orbs, "" if t.orbs == 1 else "s"])
	if t.xp_chips > 0:
		bits.append("%d XP Chip%s" % [t.xp_chips, "" if t.xp_chips == 1 else "s"])
	for g in t.gear:
		bits.append(GEAR[g][0])
	shell.toast("Spire rewards: " + ", ".join(bits))


## Puts a reward bundle (SpireClimb.take_rewards) into the profile.
static func grant(p, t: Dictionary) -> void:
	p.coins += int(t.coins)
	p.orbs += int(t.orbs)
	_add_item(p, "Summon Orb", 0, "", Color("c86bff")).count = p.orbs
	if t.xp_chips > 0:
		_add_item(p, "XP Chip", t.xp_chips, "+200 XP to one critter.", Color("45f5a6"))
	for g in t.gear:
		var uid := 1
		for piece in p.gear:
			uid = maxi(uid, int(piece.uid) + 1)
		p.gear.append({"uid": uid, "name": GEAR[g][0], "slot": GEAR[g][1], "rarity": g, "text": GEAR[g][2], "on": ""})
	p.changed.emit()


static func _add_item(p, name: String, n: int, text: String, color: Color) -> Dictionary:
	for i in p.items:
		if i.name == name:
			i.count += n
			return i
	var item := {"name": name, "count": n, "text": text, "color": color}
	p.items.append(item)
	return item
