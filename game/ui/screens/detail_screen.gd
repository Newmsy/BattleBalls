## One critter on one phone screen (its best copy, or the tier in params.tier): power, stats, level against the tier
## cap, this tier's ability and the next, gear and copies. The whole T1-T5
## ladder and the flavour text sit behind the "i"; Pick (your fighter) and Fuse are pinned.
extends RefCounted

const Talents := preload("res://sim/talents.gd")
const Intro := preload("res://game/ui/intro.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Gear := preload("res://sim/gear.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")


static func header(shell, title: String, extra: Control = null) -> Control:
	var back: Control = shell.back_button("back")
	var row := Kit.hbox(18, [back, Kit.label(title, 40)])
	row.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if extra:
		row.add_child(extra)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	return row


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var c := Roster.get_critter(params.id)
	var b: Dictionary = p.best(c.id)
	var is_best := true
	for s in p.copies(c.id):
		if s.tier == params.get("tier", b.tier) and s != b:
			b = s # A lower-tier copy tapped on My critters.
			is_best = false
	var power: int = p.power_of(c.id) if is_best else Roster.power(c.id, b.tier, b.level)
	var rcol: Color = Roster.RARITY_COLORS[c.rarity]
	var root := Kit.vbox(18)
	var cap := Roster.level_cap(b.tier)
	var more := [c.vibe, AbilityText.full(c.id)]
	for t in range(2, Roster.MAX_TIER + 1):
		more.append("T%d: %s%s" % [t, AbilityText.change(c.id, t), "  (now)" if t == b.tier else ""])
	more.append("3 of the same tier fuse into 1 of the next tier. Wishlisted critters come up twice as often in summons and drops.")
	var info: Control = shell.info_button(c.name, more, "detail_info")
	root.add_child(header(shell, c.name, Kit.hbox(12, [Kit.chip(Roster.RARITY_NAMES[c.rarity], rcol), info], BoxContainer.ALIGNMENT_CENTER)))

	# Hero: the critter on the left, its numbers on the right.
	var hp := roundi(120.0 * (1.0 + .03 * (b.level - 1)))
	var dmg := roundi(10.0 * (1.0 + .03 * (b.level - 1)))
	var speed: String = {"juggernaut": "Slow", "speedster": "Fast", "ghost": "Fast", "splitter": "Fast"}.get(c.id, "Normal")
	var stats := Kit.hbox(18)
	for st in [["HP", str(hp)], ["DMG", str(dmg)], ["SPEED", speed]]:
		stats.add_child(Kit.vbox(0, [Kit.label(st[0], 19, Kit.MUTED), Kit.label(st[1], 28)]))
	var side := Kit.vbox(8, [Glyph.make("stars", 30, Kit.FG, b.tier, Roster.MAX_TIER), Kit.label("%s · %s" % [c.type, c.role], 22, Kit.MUTED),
		Kit.power(power, 36), stats])
	var faction := Talents.faction_of(c.id)
	if faction != "":
		# Its faction's talent tree, one tap away.
		var fchip := Kit.card_button(Kit.chip(Talents.NAMES[faction] + " talents", Talents.COLORS[faction]), func(): shell.go("faction", {"id": faction}), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 0)
		fchip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		shell.mark("detail_faction", fchip)
		side.add_child(fchip)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(Kit.hbox(16, [CritterIcon.make(c.id, b.tier, 220, true), side], BoxContainer.ALIGNMENT_CENTER))

	var how_level: Control = shell.info_button("How to level", [
		"Your critter earns XP when it fights in campaign stages.",
		"XP Chips in your Bag give 200 XP each.",
		"Fuse to raise the max level."], "level_info")
	root.add_child(Kit.panel(Kit.vbox(8, [Kit.hbox(8, [Kit.caption("Level"), how_level, Kit.spacer(), Kit.label("%d / %d" % [b.level, cap], 24)], BoxContainer.ALIGNMENT_CENTER),
		Kit.bar(float(b.level) / cap, Kit.GOOD)]), Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 18)))

	# Ability: what it does at this tier, then what the next tier adds; the whole ladder is behind the "i".
	var ladder := Kit.vbox(8, [Kit.caption("Ability")])
	for i in range(b.tier - 1, mini(b.tier + 1, Roster.MAX_TIER)):
		var have: bool = i < b.tier
		var tag := Kit.panel(Kit.label("T%d" % (i + 1), 22, Kit.BG if have else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.ACCENT if have else Color("221e4f"), Color(0, 0, 0, 0), 14, 0, 4))
		tag.custom_minimum_size = Vector2(62, 0)
		var l := Kit.label(AbilityText.now(c.id, b.tier) if have else "Next: " + AbilityText.change(c.id, i + 1), 23, Kit.FG if have else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(14, [tag, l])
		if i == 4:
			row.add_child(Kit.chip("Special", Glyph.GOLD, 16))
		ladder.add_child(row)
	root.add_child(Kit.panel(ladder, Kit.box(Kit.PANEL, Kit.LINE, 28, 2, 18)))

	var gear: Array = p.gear_on(c.id)
	var slots := Kit.hbox(12)
	for slot in Gear.SLOTS:
		var g: Dictionary = {}
		for x in gear:
			if x.slot == slot:
				g = x
		var open: bool = p.slot_open(c.id, slot)
		var col: Color = BagScreen.tier_color(g.tier) if not g.is_empty() else Kit.MUTED
		var head := Kit.hbox(6, [Glyph.make(Gear.PIECES[g.type].glyph if not g.is_empty() else slot.to_lower(), 26, col if open else Glyph.OFF),
			Kit.label(slot, 20, col)], BoxContainer.ALIGNMENT_CENTER)
		var line: Control
		if not open:
			line = Kit.hbox(6, [Glyph.make("lock", 20, Kit.MUTED), Kit.label("3 stars", 19, Kit.MUTED)])
		elif g.is_empty():
			line = Kit.label("+", 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		else:
			line = Glyph.make("stars", 18, col, g.tier)
		var v := Kit.vbox(4, [head, line])
		var tap: Callable = _slot_sheet.bind(shell, c.id, slot) if open else shell.toast.bind("Charms unlock when %s reaches 3 stars." % c.name)
		var card := Kit.card_button(v, tap, Color(col, .5) if not g.is_empty() else Kit.LINE, Kit.PANEL2, 24, 12)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("slot_" + slot.to_lower(), card)
		slots.add_child(card)
	root.add_child(Kit.vbox(10, [Kit.caption("Gear"), slots]))

	var chips := Kit.hbox(10, [Kit.caption("Copies")], BoxContainer.ALIGNMENT_BEGIN)
	for s in p.copies(c.id):
		chips.add_child(Kit.panel(Kit.label("T%d  x%d" % [s.tier, s.count], 22), Kit.box(Kit.PANEL2, Kit.LINE, 16, 2, 8)))
	chips.add_child(Kit.spacer())
	var wished: bool = p.on_wishlist(c.id)
	var wish := Kit.card_button(Kit.chip("Wishlisted" if wished else "+ Wishlist", Color("ff5fc8")), func():
		if p.toggle_wishlist(c.id):
			shell.toast("%s %s your wishlist." % [c.name, "left" if wished else "is on"])
		else:
			shell.toast("Wishlist full (3/3).")
		shell.refresh(), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 999, 4)
	shell.mark("wish_this", wish)
	chips.add_child(wish)
	root.add_child(chips)

	var ready: Dictionary = {}
	for s in p.copies(c.id):
		if ready.is_empty() and s.count >= 3 and s.tier < Roster.MAX_TIER:
			ready = s
	# Picking a fighter means you want to fight with it: back to Play, where Quick fight is.
	var lineup := Kit.button("Your fighter" if p.lineup == c.id else "Pick", func():
		p.set_lineup(c.id)
		shell.show_tab("play")
		if Intro.step(p) == Intro.FIGHTER and Intro.reach(p, Intro.FIGHT_2):
			Intro.to_campaign(shell)
		shell.toast("%s is now your fighter." % c.name), "ghost", 26, 90)
	shell.mark("detail_fighter", lineup)
	var fuse := Kit.button("Fuse T%d" % ready.get("tier", b.tier), func(): shell.open_tab("fuse", {"id": c.id, "tier": ready.tier}), "go", 26, 90)
	fuse.disabled = ready.is_empty()
	shell.mark("fuse_this", fuse)
	shell.pin(Kit.hbox(16, [lineup, fuse]))
	return root


## Pick a piece for one of a critter's gear slots: every piece that fits,
## best first, plus Unequip when it wears one.
static func _slot_sheet(shell, id: String, slot: String) -> void:
	var p = shell.profile
	var worn: Dictionary = {}
	for g in p.gear_on(id):
		if g.slot == slot:
			worn = g
	var v := Kit.vbox(16, [Kit.label("%s · %s" % [Roster.get_critter(id).name, slot], 34)])
	var pieces: Array = p.gear.filter(func(g): return g.slot == slot)
	pieces.sort_custom(func(a, b): return a.tier > b.tier if a.tier != b.tier else (a.on == "" and b.on != ""))
	var seen := {}
	var list := Kit.vbox(10)
	for g in pieces:
		# One row per type, tier and wearer: identical spares are the same choice.
		var k := "%s/%d/%s" % [g.type, g.tier, g.on]
		if seen.has(k) or list.get_child_count() >= 5:
			continue
		seen[k] = true
		var col: Color = BagScreen.tier_color(g.tier)
		var who: String = "" if g.on == "" else "On " + Roster.get_critter(g.on).name
		var info := Kit.vbox(2, [Kit.label(g.name, 24), Kit.label(g.text + ("  ·  " + who if who != "" else ""), 19, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(12, [Glyph.make(Gear.PIECES[g.type].glyph, 56, col), info, Glyph.make("stars", 18, col, g.tier)], BoxContainer.ALIGNMENT_CENTER)
		var card := Kit.card_button(row, func():
			p.equip(g.uid, id)
			shell.close_overlay()
			shell.refresh()
			if Intro.step(p) == Intro.EQUIP and Intro.reach(p, Intro.FIGHT_3):
				Intro.to_campaign(shell),
			Kit.GOOD if g.on == id else Kit.LINE, Kit.PANEL2, 24, 10)
		shell.mark("pick_%d" % g.uid, card)
		list.add_child(card)
	if list.get_child_count() == 0:
		list.add_child(Kit.label("No %ss yet. Beat the Anvil King." % slot, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	v.add_child(list)
	if not worn.is_empty():
		v.add_child(Kit.button("Unequip", func(): p.unequip(worn.uid); shell.close_overlay(); shell.refresh(), "ghost", 26, 80))
	shell.sheet(v)


static func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc
