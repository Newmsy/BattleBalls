## Bag tab: gear (Shells, Cores and Charms, with who wears each) and items.
## Tap gear to move it to another critter (swapping is always free) or merge
## three of a kind into the next tier (design/gear.md).
extends RefCounted

const Intro := preload("res://game/ui/intro.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Gear := preload("res://sim/gear.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const Profile := preload("res://meta/profile.gd")

static var section := "gear"

const GEAR_INFO := ["3 of a kind → 1 with a star more (max 5). Costs Hammers.",
	"Shells keep you alive, Cores hit harder, Charms (from 3-star critters) speed you or your ability up.",
	"Get gear from the Anvil King, campaign wins, Spire boss floors and the Glow Pass free track."]


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(22)
	root.add_child(Kit.hbox(12, [Kit.label("Bag", 40), Kit.spacer(),
		Glyph.make("hammer", 30), Kit.label(Kit.commas(p.hammers), 24),
		shell.info_button("Gear", GEAR_INFO, "bag_info")], BoxContainer.ALIGNMENT_CENTER))

	var seg := Kit.hbox(8)
	for s in [["gear", "Gear"], ["items", "Items"]]:
		var on: bool = section == s[0]
		var b := Kit.card_button(Kit.label(s[1].to_upper(), 24, Kit.FG if on else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			func(): section = s[0]; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.PANEL2 if on else Kit.PANEL, 22, 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("bag_" + s[0], b)
		seg.add_child(b)
	root.add_child(seg)

	if section == "gear":
		for slot in Gear.SLOTS:
			var grid := _grid()
			var pieces := 0
			for g in stacks(p, slot):
				grid.add_child(_gear_tile(shell, g))
				pieces += g.count
			if grid.get_child_count() > 0:
				root.add_child(Kit.vbox(12, [Kit.caption("%ss (%d)" % [slot, pieces]), grid]))
		if p.gear.is_empty():
			root.add_child(Kit.label("No gear yet.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		_pin_merge_all(shell, p)
	else:
		var grid := _grid()
		for it in p.items:
			var v := Kit.vbox(6, [_center(_item_icon(it)), Kit.label(it.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true), Kit.label("x%d" % it.count, 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
			var card := Kit.card_button(v, func(): _item_sheet(shell, it), Kit.LINE, Kit.PANEL, 28, 14)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			shell.mark("item_" + it.name.replace(" ", "_"), card)
			grid.add_child(card)
		root.add_child(grid)
	return root


## The rim and star colour of a gear tier: the rarity ladder, grey to gold.
static func tier_color(tier: int) -> Color:
	return Roster.RARITY_COLORS[Gear.RARITY_TIERS.keys()[clampi(tier, 1, Gear.MAX_TIER) - 1]]


## One slot's gear as tiles, best first: each worn piece on its own, unworn
## pieces of the same type and tier stacked into one ({piece, count}).
static func stacks(p, slot: String) -> Array:
	var out := []
	var free := {}
	for g in p.gear:
		if g.slot != slot:
			continue
		if g.on != "":
			out.append({"piece": g, "count": 1})
			continue
		var k := "%s/%d" % [g.type, g.tier]
		if free.has(k):
			free[k].count += 1
		else:
			free[k] = {"piece": g, "count": 1}
			out.append(free[k])
	out.sort_custom(func(a, b):
		if a.piece.tier != b.piece.tier:
			return a.piece.tier > b.piece.tier
		if a.piece.type != b.piece.type:
			return Gear.TYPES.find(a.piece.type) < Gear.TYPES.find(b.piece.type)
		return a.piece.on != "" and b.piece.on == "")
	return out


## Merge all, pinned under the grid while any set is complete.
static func _pin_merge_all(shell, p) -> void:
	if p.gear_sets().is_empty():
		return
	var plan: Dictionary = p.merge_all_plan()
	var n: int = plan.merges.size()
	var b: Button
	if n == 0:
		b = Kit.cost_button("Merge all", p.merge_cost(p.gear_sets()[0][1]), "hammer", func(): pass, "go", 28, 90)
		b.disabled = true
	else:
		b = Kit.cost_button("Merge all (%d)" % n, plan.hammers, "hammer", _merge_all.bind(shell), "go", 28, 90)
	shell.mark("merge_all", b)
	shell.pin(b)


## "3-star Iron Shell".
static func piece_name(g: Dictionary) -> String:
	return "%d-star %s" % [g.tier, g.name]


static func _gear_tile(shell, st: Dictionary) -> Control:
	var p = shell.profile
	var g: Dictionary = st.piece
	var col := tier_color(g.tier)
	var status: String = ("x%d" % st.count if st.count > 1 else "Spare") if g.on == "" else "On " + Roster.get_critter(g.on).name
	var status_label := Kit.label(status, 19, Kit.GOOD if g.on != "" else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	var status_row: Control = status_label
	if g.on != "":
		# The wearer's face beside "On Optic": drawn once, so a long bag stays cheap.
		var face := CritterIcon.make(g.on, 1, 34)
		face.still = true
		face.radius_frac = .44
		status_label.text = Roster.get_critter(g.on).name
		status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		status_label.custom_minimum_size.x = 0
		status_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		status_row = Kit.hbox(6, [face, status_label], BoxContainer.ALIGNMENT_CENTER)
	var v := Kit.vbox(4, [_center(Glyph.make(Gear.PIECES[g.type].glyph, 84, col)), Kit.label(g.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true),
		_center(Glyph.make("stars", 20, col, g.tier)), status_row])
	if p.has_gear_set(g.type, g.tier):
		v.add_child(_center(Kit.chip("MERGE", Kit.GOOD, 16)))
	var card := Kit.card_button(v, func(): _gear_sheet(shell, g), Color(col, .55), Kit.PANEL, 28, 12)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("gear_%d" % g.uid, card)
	return card


static func _equip(shell, g: Dictionary, c: Dictionary) -> void:
	if not shell.profile.equip(g.uid, c.id):
		shell.toast("Charms unlock when %s reaches 3 stars." % c.name)
		return
	shell.close_overlay()
	shell.toast("%s equipped to %s." % [g.name, c.name])
	shell.refresh()
	if Intro.step(shell.profile) == Intro.EQUIP and Intro.reach(shell.profile, Intro.FIGHT_3):
		Intro.to_campaign(shell)


## Picks who wears a gear piece with the shared critter grid. Critters whose
## slot is still locked (Charms need 3 stars) say so under their tile.
static func _equip_pick(shell, g: Dictionary) -> void:
	var p = shell.profile
	var ids: Array = CritterPicker.by_power(p, Roster.CRITTERS.map(func(c): return c.id))
	var tags := {}
	for id in ids:
		if not p.slot_open(id, g.slot):
			tags[id] = "3 stars"
	CritterPicker.open(shell, ids, {"title": "Equip %s to" % g.name, "current": g.on, "tags": tags,
		"on_pick": func(id): _equip(shell, g, Roster.get_critter(id))})


static func _merge(shell, g: Dictionary) -> void:
	var made: Dictionary = shell.profile.merge_gear(g.type, g.tier)
	shell.close_overlay()
	shell.toast("Made a %s." % piece_name(made) if not made.is_empty() else "Need more Hammers.")
	shell.refresh()


static func _merge_all(shell) -> void:
	var made: Array = shell.profile.merge_all_gear()
	shell.toast("Merged: " + ", ".join(made.map(func(g): return piece_name(g))))
	shell.refresh()


static func _gear_sheet(shell, g: Dictionary) -> void:
	var p = shell.profile
	var col := tier_color(g.tier)
	var info := Kit.vbox(6, [Kit.label(g.name, 36), Kit.hbox(10, [Glyph.make("stars", 26, col, g.tier), Kit.chip(g.slot, col)], BoxContainer.ALIGNMENT_CENTER)])
	var wearer: String = "Not equipped" if g.on == "" else "Worn by " + Roster.get_critter(g.on).name
	var v := Kit.vbox(18, [Kit.hbox(18, [Glyph.make(Gear.PIECES[g.type].glyph, 110, col), info]), Kit.label(g.text, 28, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.label(wearer, 22, Kit.MUTED)])
	var buttons := Kit.hbox(12)
	var equip := Kit.button("Equip to" if g.on == "" else "Move to", _equip_pick.bind(shell, g), "primary", 26, 84)
	equip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("gear_equip", equip)
	buttons.add_child(equip)
	v.add_child(buttons)
	buttons = Kit.hbox(12)
	if g.tier < Gear.MAX_TIER:
		var have: int = p.gear_of(g.type, g.tier).size()
		var cost: int = p.merge_cost(g.tier)
		var merge := Kit.cost_button("Merge 3", cost, "hammer", _merge.bind(shell, g), "go", 26, 84) if have >= 3 else Kit.button("%d of 3 to merge" % have, _merge.bind(shell, g), "go", 26, 84)
		merge.disabled = have < 3 or p.hammers < cost
		merge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("gear_merge", merge)
		buttons.add_child(merge)
	if g.on != "":
		var off := Kit.button("Unequip", func(): p.unequip(g.uid); shell.close_overlay(); shell.refresh(), "ghost", 26, 84)
		off.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons.add_child(off)
	if buttons.get_child_count() > 0:
		v.add_child(buttons)
	shell.sheet(v)


static func _item_sheet(shell, it: Dictionary) -> void:
	var p = shell.profile
	var v := Kit.vbox(18, [Kit.hbox(18, [_item_icon(it), Kit.label("%s  x%d" % [it.name, it.count], 34)]), Kit.label(it.text, 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	var act: Button
	match it.name:
		"Energy Pack":
			act = Kit.button("Use 1", func(): shell.close_overlay(); if p.use_energy_pack(): shell.toast("+30 energy"); shell.refresh(), "primary", 28, 90)
			act.disabled = it.count <= 0
		"Summon Egg":
			act = Kit.button("Summon", func(): shell.show_tab("summon"), "primary", 28, 90)
		_:
			act = Kit.button("Use", func(): shell.close_overlay(); _chip_pick(shell), "primary", 28, 90)
			act.disabled = it.count <= 0
	shell.mark("item_use", act)
	v.add_child(act)
	shell.sheet(v)


## XP Chips: pick a critter below its level cap, then watch its bar fill.
static func _chip_pick(shell) -> void:
	var p = shell.profile
	var ids: Array = CritterPicker.by_power(p, BallDefs.PLAYABLE).filter(func(id):
		var b: Dictionary = p.best(id)
		return int(b.level) < Roster.level_cap(b.tier))
	if ids.is_empty():
		shell.toast("All critters are max level.")
		return
	CritterPicker.open(shell, ids, {"title": "Give +%d XP to" % Profile.XP_CHIP_XP,
		"on_pick": func(id): _use_chip(shell, id)})


static func _use_chip(shell, id: String) -> void:
	var p = shell.profile
	var g: Dictionary = p.use_xp_chip(id)
	if g.is_empty():
		shell.toast("No XP Chips left.")
		return
	var left: int = p.xp_chips()
	var v := Kit.vbox(20, [Kit.label("XP Chip used", 34), XpBar.make(g, shell.sfx)])
	var buttons := Kit.hbox(14)
	var done := Kit.button("Done", func(): shell.close_overlay(); shell.refresh(), "ghost", 26, 84)
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("chip_done", done)
	buttons.add_child(done)
	var b: Dictionary = p.best(id)
	if left > 0 and int(b.level) < Roster.level_cap(b.tier):
		var again := Kit.button("Another  x%d" % left, func(): shell.close_overlay(); _use_chip(shell, id), "go", 26, 84)
		again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("chip_again", again)
		buttons.add_child(again)
	v.add_child(buttons)
	shell.sheet(v)


static func _item_icon(it: Dictionary) -> Control:
	var kind: String = {"Energy Pack": "energy", "Summon Egg": "orb"}.get(it.name, "bolt")
	var g := Glyph.make(kind, 80, it.color)
	var box := Kit.panel(g, Kit.box(Color(it.color, .15), Color(it.color, .5), 24, 2, 12))
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return box


static func _grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	return grid


static func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc
