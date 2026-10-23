## Bag tab: gear (Shells, Cores and Charms, with who wears each) and items.
## Gear is a compact list: one row per type and tier, with its effect in words,
## who wears it and a Merge button once three match. Tap a row to move it to
## another critter (swapping is always free) or merge (design/gear.md).
extends RefCounted

const Intro := preload("res://game/ui/intro.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Gear := preload("res://sim/gear.gd")
const CritterPicker := preload("res://game/ui/critter_picker.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const XpBar := preload("res://game/ui/xp_bar.gd")
const Profile := preload("res://meta/profile.gd")
const UpgradePopup := preload("res://game/ui/upgrade_popup.gd")

static var section := "gear"
static var slot_filter := "" ## "" = all slots, else "Shell", "Core" or "Charm".

const GEAR_INFO := ["3 of a kind → 1 with a star more (max 5). Costs Hammers.",
	"Shells keep you alive, Cores hit harder, Charms (from 3-star critters) speed you or your ability up.",
	"Get gear from the Anvil King, campaign wins, Spire boss floors and the Glow Pass free track."]


static func build(shell, _params: Dictionary) -> Control:
	var p = shell.profile
	var root := Kit.vbox(22)
	root.add_child(shell.title_row("Bag", {"back": false, "extra": [Kit.amount("hammer", p.hammers)],
		"info_title": "Gear", "info_mark": "bag_info", "info": GEAR_INFO}))

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
		if not p.gear.is_empty():
			root.add_child(_filters(shell, p))
		for slot in Gear.SLOTS:
			if slot_filter != "" and slot != slot_filter:
				continue
			var list := Kit.vbox(8)
			for r in rows(p, slot):
				list.add_child(_gear_row(shell, r))
			if list.get_child_count() > 0:
				if slot_filter == "":
					var head := Kit.hbox(10, [Glyph.make(slot.to_lower(), 22, Kit.MUTED), Kit.caption("%ss" % slot), _Rule.new()], BoxContainer.ALIGNMENT_CENTER)
					root.add_child(Kit.vbox(8, [head, list]))
				else:
					root.add_child(list)
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


## All / Shells / Cores / Charms, each with how many pieces you own.
static func _filters(shell, p) -> Control:
	var row := Kit.hbox(8)
	for f in [["", "All"], ["Shell", "Shells"], ["Core", "Cores"], ["Charm", "Charms"]]:
		var n := 0
		for g in p.gear:
			if f[0] == "" or g.slot == f[0]:
				n += 1
		var on: bool = slot_filter == f[0]
		var b := Kit.card_button(Kit.label("%s %d" % [f[1], n], 20, Kit.FG if on else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
			func(): slot_filter = f[0]; shell.refresh(), Kit.ACCENT if on else Kit.LINE, Kit.PANEL2 if on else Kit.PANEL, 999, 8)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("gear_filter_" + (f[0].to_lower() if f[0] != "" else "all"), b)
		row.add_child(b)
	return row


## One slot's gear as rows, best first: every piece of one type and tier in one
## row ({piece, pieces, count, wearers}). `piece` is what a tap opens: a spare
## if there is one (so Equip to is the next step), else the worn one.
static func rows(p, slot: String) -> Array:
	var out := []
	var by := {}
	for g in p.gear:
		if g.slot != slot:
			continue
		var k := "%s/%d" % [g.type, g.tier]
		if not by.has(k):
			by[k] = {"piece": g, "pieces": [], "count": 0, "wearers": []}
			out.append(by[k])
		var r: Dictionary = by[k]
		r.pieces.append(g)
		r.count += 1
		if g.on != "":
			r.wearers.append(g.on)
		elif r.piece.on != "":
			r.piece = g
	out.sort_custom(func(a, b):
		if a.piece.tier != b.piece.tier:
			return a.piece.tier > b.piece.tier
		return Gear.TYPES.find(a.piece.type) < Gear.TYPES.find(b.piece.type))
	return out


## A gear row: icon, name, stars and count, the effect in words, then Merge
## (with its cost) once three match, and who wears it or "Spare".
static func _gear_row(shell, r: Dictionary) -> Control:
	var p = shell.profile
	var g: Dictionary = r.piece
	var col := tier_color(g.tier)
	var name := Kit.label(g.name, 24)
	var top := Kit.hbox(8, [name, Glyph.make("stars", 18, col, g.tier)], BoxContainer.ALIGNMENT_BEGIN)
	if r.count > 1:
		top.add_child(Kit.label("x%d" % r.count, 19, Kit.MUTED))
	var effect := Kit.label(g.text, 19, Kit.MUTED)
	effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	effect.clip_text = true
	var words := Kit.vbox(0, [top, effect])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(12, [Glyph.make(g.type, 60, col), words], BoxContainer.ALIGNMENT_CENTER)
	if g.tier < Gear.MAX_TIER and p.has_gear_set(g.type, g.tier):
		var merge := Kit.cost_button("Merge", p.merge_cost(g.tier), "hammer", _merge.bind(shell, g), "go", 19, 56)
		merge.disabled = p.hammers < p.merge_cost(g.tier)
		merge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		merge.size_flags_horizontal = Control.SIZE_SHRINK_END
		merge.custom_minimum_size.x = 150
		shell.mark("gear_row_merge_%s_%d" % [g.type, g.tier], merge)
		row.add_child(merge)
	if r.wearers.is_empty():
		row.add_child(Kit.label("Spare", 19, Kit.MUTED))
	else:
		var faces := Kit.hbox(-10, [], BoxContainer.ALIGNMENT_END)
		for id in r.wearers.slice(0, 3):
			faces.add_child(CritterIcon.face(id, 44))
		row.add_child(faces)
	var card := Kit.card_button(row, func(): _gear_sheet(shell, g), Color(col, .45), Kit.PANEL, 22, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for piece in r.pieces:
		shell.mark("gear_%d" % piece.uid, card)
	return card


## "3-star Iron Shell".
static func piece_name(g: Dictionary) -> String:
	return "%d-star %s" % [g.tier, g.name]


static func _equip(shell, g: Dictionary, c: Dictionary) -> void:
	if not shell.profile.equip(g.uid, c.id):
		shell.toast("Charm slot unlocks when %s reaches %d stars." % [c.name, Gear.CHARM_TIER], c.id)
		return
	shell.close_overlay()
	shell.toast("%s equipped to %s." % [g.name, c.name], c.id)
	shell.refresh()
	if Intro.step(shell.profile) == Intro.EQUIP and Intro.reach(shell.profile, Intro.FIGHT_3):
		Intro.to_campaign(shell)


## Picks who wears a gear piece with the shared critter grid. Critters whose
## slot is still locked (Charms need 3 stars) come last, dimmed with a lock.
static func _equip_pick(shell, g: Dictionary) -> void:
	var p = shell.profile
	var ids: Array = CritterPicker.by_power(p, Roster.CRITTERS.map(func(c): return c.id))
	var locked := {}
	for id in ids:
		if not p.slot_open(id, g.slot):
			locked[id] = true
	var open_ids := ids.filter(func(id): return not locked.has(id))
	var opts := {"title": "Equip %s to" % g.name, "current": g.on, "locked": locked,
		"locked_toast": "Charm slot unlocks when %%s reaches %d stars." % Gear.CHARM_TIER,
		"on_pick": func(id): _equip(shell, g, Roster.get_critter(id))}
	CritterPicker.open(shell, open_ids + ids.filter(func(id): return locked.has(id)), opts)


static func _merge(shell, g: Dictionary) -> void:
	var cost: int = shell.profile.merge_cost(g.tier)
	var made: Dictionary = shell.profile.merge_gear(g.type, g.tier)
	shell.close_overlay()
	shell.refresh()
	if made.is_empty():
		shell.toast("Need more Hammers.")
		return
	print("UI_MERGED %s T%d" % [made.type, made.tier])
	UpgradePopup.gear(shell, made, tier_color(made.tier), cost)


static func _merge_all(shell) -> void:
	var cost: int = shell.profile.merge_all_plan().hammers
	var made: Array = shell.profile.merge_all_gear()
	shell.refresh()
	if made.size() == 1:
		UpgradePopup.gear(shell, made[0], tier_color(made[0].tier), cost)
	elif not made.is_empty():
		UpgradePopup.gear_list(shell, made, tier_color, cost)


static func _gear_sheet(shell, g: Dictionary) -> void:
	var p = shell.profile
	var col := tier_color(g.tier)
	var info := Kit.vbox(6, [Kit.label(g.name, 36), Kit.hbox(10, [Glyph.make("stars", 26, col, g.tier), Kit.chip(g.slot, col)], BoxContainer.ALIGNMENT_CENTER)])
	var wearer: Control = Kit.label("Not equipped", 22, Kit.MUTED)
	if g.on != "":
		wearer = Kit.hbox(8, [Kit.label("Worn by", 22, Kit.MUTED), FighterTag.named(g.on, 44, 22, Kit.FG)], BoxContainer.ALIGNMENT_BEGIN)
	var v := Kit.vbox(18, [Kit.hbox(18, [Glyph.make(g.type, 110, col), info]), Kit.label(g.text, 28, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		wearer])
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


## The line after a gear section's name: fades out toward the right edge,
## with a small diamond where it starts. Drawn once.
class _Rule extends Control:
	const Dot := preload("res://game/dot.gd")
	const Kit := preload("res://game/ui/ui_kit.gd")

	func _init() -> void:
		custom_minimum_size = Vector2(0, 12)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var y := size.y / 2.0
		var n := 8
		for k in n:
			var x0 := 10.0 + (size.x - 10.0) * k / n
			var x1 := 10.0 + (size.x - 10.0) * (k + 1) / n
			draw_line(Vector2(x0, y), Vector2(x1, y), Color(Kit.LINE.lightened(.25), .9 * (1.0 - float(k) / n)), 2.0)
		Dot.poly(self, PackedVector2Array([Vector2(0, y), Vector2(5, y - 5), Vector2(10, y), Vector2(5, y + 5)]), Kit.LINE.lightened(.35))
