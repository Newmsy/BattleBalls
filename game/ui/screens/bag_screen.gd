## Bag tab: gear (Shells, Cores and Charms, with who wears each) and items.
## Gear is a 3-column grid, one tile per piece: its painting, stars, effect in
## words and the face of who wears it. Tap a tile to move it to another critter
## (swapping is always free) or merge; every merge asks first, showing which
## pieces combine, what they make and the Hammers (design/gear.md).
## Each section opens with a painted band and every piece is its painting
## (game/ui/gear_art, from tools/event_art/scenes/gear_*.mjs).
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
const GearArt := preload("res://game/ui/gear_art.gd")
const LivingArt := preload("res://game/bounce_run/living_art.gd")
const A11y := preload("res://game/a11y.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const Dyes := preload("res://game/glow/dyes.gd")
const CosmeticIcon := preload("res://game/glow/cosmetic_icon.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const PlungeTalents := preload("res://meta/plunge_talents.gd")
const ShopScreen := preload("res://game/ui/screens/shop_screen.gd")

static var section := "gear"
## What each section band says under its title.
const SLOT_LINES := {"Shell": "Keep you alive", "Core": "Hit harder", "Charm": "Speed and tricks · 3★ critters"}
const BAND_H := 140.0

const GEAR_INFO := ["3 of a kind → 1 with a star more (max 5). Costs Hammers.",
	"Shells keep you alive, Cores hit harder, Charms (from 3-star critters) speed you or your ability up.",
	"Get gear from the Anvil King, campaign wins, Spire boss floors and the Glow Pass free track."]


static func build(shell, params: Dictionary) -> Control:
	if params.has("section"):
		section = str(params.section)
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
		for slot in Gear.SLOTS:
			var list := pieces(p, slot)
			if list.is_empty():
				continue
			var grid := _grid(10)
			for g in list:
				grid.add_child(_gear_tile(shell, g))
			root.add_child(Kit.vbox(10, [_band(slot, list.size()), grid]))
		if p.gear.is_empty():
			root.add_child(Kit.label("No gear yet.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		_pin_merge_all(shell, p)
	else:
		_items_tab(shell, root)
	return root


## Items: everything the save tracks, one section each, every tile a 3-column
## card that opens an info sheet. Consumables, then currencies, Arena and
## Plunge spends, chests waiting, Spark Dyes and owned cosmetics.
static func _items_tab(shell, root: VBoxContainer) -> void:
	var p = shell.profile
	var tiles := []
	for it in p.items:
		tiles.append(_item_tile(shell, it))
	root.add_child(_section("Items", tiles))

	var glow = shell.glow
	var cur := [
		_stat_tile(shell, "coin", Glyph.GOLD, "Coins", p.coins, "Spend in the Shop and on fusing, levels and talents."),
		_stat_tile(shell, "gem", Color("5ce1ff"), "Glow Gems", glow.gems() if glow else 0, "Buy looks in the Shop and the Glow Pass.", "shop"),
		_stat_tile(shell, "hammer", Color("c9d3e0"), "Hammers", p.hammers, "Merge three gear pieces into one with a star more. From the Anvil King."),
		_stat_tile(shell, "spark", Color("b07cff"), "Ascension Sparks", p.sparks, "%d Sparks ascend a 5-star critter one level (up to 5). From weekly Arena chests, the daily Bounce Run chest, Spire boss floors and talent ranks past 30." % Profile.ASCEND_COST),
		_stat_tile(shell, "target", Color("7af0ff"), "Lures", p.lures, "Buy a copy of a wishlisted critter. From the Prism Wyrm.", "wyrm"),
	]
	root.add_child(_section("Currencies", cur))

	var store = ArenaStore.open()
	root.add_child(_section("Arena", [
		_stat_tile(shell, "points", Color("ffd23f"), "Arena Points", store.points, "Spend on Arena boosts for a family.", "boosts"),
		_stat_tile(shell, "arena_coin", Color("ffb13d"), "Arena Coins", store.coins, "Spend in the Arena Bazaar.", "bazaar"),
		_stat_tile(shell, "token", Color("5ce1ff"), "Arena Tokens", "%d/%d" % [store.tokens_now(), ArenaStore.TOKEN_MAX], "One Arena fight each. One comes back every hour, up to %d." % ArenaStore.TOKEN_MAX, "arena"),
	]))

	var medals: Dictionary = PlungeTalents.medals(p)
	var med := []
	for m in ["gold", "silver", "bronze"]:
		med.append(_stat_tile(shell, "medal_" + m, Color.WHITE, "%s Medals" % m.capitalize(), int(medals.get(m, 0)), "Won in Critter Plunge races. Spend on Plunge talents.", "plunge"))
	root.add_child(_section("Plunge Medals", med))

	var chests := []
	if store.any_chest_ready():
		chests.append(_stat_tile(shell, "trophy", Color("ffd23f"), "Arena Chest", "Ready", "Last week's best league chest is waiting.", "arena_chests"))
	var boxes: int = glow.boxes_ready() if glow else 0
	if boxes > 0:
		chests.append(_stat_tile(shell, "pass", Color("ff6fd0"), "Pass Bonus Box", boxes, "Glow Pass bonus boxes to open.", "pass"))
	if not chests.is_empty():
		root.add_child(_section("Chests waiting", chests))

	var dyes := []
	for d in Dyes.DYES:
		dyes.append(_dye_tile(shell, d))
	root.add_child(_section("Spark Dyes", dyes, "%d/%d" % [Dyes.unlocked_count(p), Dyes.DYES.size()]))

	var looks := []
	if glow:
		for slot in Catalog.SLOTS + [Catalog.SKIN]:
			for it in Catalog.items_in(slot):
				if glow.owns(it.id):
					looks.append(_look_tile(shell, it))
	if looks.is_empty():
		root.add_child(Kit.vbox(10, [Kit.caption("Cosmetics"), Kit.label("None yet. Find looks in the Shop and on the Glow Pass.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)]))
	else:
		root.add_child(_section("Cosmetics", looks, str(looks.size())))


## A section: caption (with an optional count on the right) over a 3-column grid.
static func _section(title: String, tiles: Array, count := "") -> Control:
	var head := Kit.hbox(0, [Kit.caption(title)])
	if count != "":
		head.add_child(Kit.spacer())
		head.add_child(Kit.label(count, 20, Kit.MUTED))
	var grid := _grid()
	for t in tiles:
		grid.add_child(t)
	return Kit.vbox(10, [head, grid])


## The tile every Items card shares: an icon, the name and a count line.
static func _tile(shell, icon: Control, name: String, line: String, mark: String, on_tap: Callable, dim := false) -> Control:
	var title := Kit.label(name, 20, Kit.MUTED if dim else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	title.custom_minimum_size.y = roundf(A11y.font(20) * 2.4) # Two lines, so tiles line up.
	var v := Kit.vbox(4, [_center(icon), title, Kit.label(line, 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
	var card := Kit.card_button(v, on_tap, Kit.LINE, Kit.PANEL, 24, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.x = 0
	shell.mark(mark, card)
	return card


static func _item_tile(shell, it: Dictionary) -> Control:
	return _tile(shell, _item_icon(it), it.name, "x%d" % it.count, "item_" + it.name.replace(" ", "_"), func(): _item_sheet(shell, it))


## A currency or count: its glyph, name and amount; tap for what it's for
## and, when it has one, a button to where it's spent.
static func _stat_tile(shell, kind: String, col: Color, name: String, value, text: String, go_to := "") -> Control:
	var amount: String = Kit.commas(value) if value is int else str(value)
	var open := func(): _stat_sheet(shell, kind, col, name, amount, text, go_to)
	return _tile(shell, _icon_box(Glyph.make(kind, 64, col), col), name, amount, "stat_" + name.to_lower().replace(" ", "_"), open)


static func _stat_sheet(shell, kind: String, col: Color, name: String, amount: String, text: String, go_to: String) -> void:
	var v := Kit.vbox(18, [Kit.hbox(18, [_icon_box(Glyph.make(kind, 80, col), col), Kit.label(name, 34, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)]),
		Kit.amount(kind, amount, 30, Kit.FG, col),
		Kit.label(text, 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	if go_to != "":
		var b := Kit.button("Go", func(): shell.close_overlay(); shell.go(go_to), "primary", 28, 90)
		shell.mark("stat_go", b)
		v.add_child(b)
	shell.sheet(v)


static func _dye_tile(shell, d: Dictionary) -> Control:
	var p = shell.profile
	var have := Dyes.unlocked(p, d.id)
	var col := Color(d.colors[0])
	var icon := _icon_box(Glyph.make("dye", 64, col if have or Dyes.drops(p, d.id) > 0 else Color(col, .35)), col)
	var line := "Unlocked" if have else "%d/%d" % [Dyes.drops(p, d.id), Dyes.need(d.id)]
	return _tile(shell, icon, d.name, line, "dye_" + d.id, func(): ShopScreen.dyes_sheet(shell), not have)


static func _look_tile(shell, it: Dictionary) -> Control:
	var icon := CosmeticIcon.make(it.id, shell.profile.lineup, 80, shell.glow.dye_of(it.id))
	return _tile(shell, icon, it.name, Catalog.SLOT_NAMES.get(it.slot, ""), "look_" + it.id, func(): _look_sheet(shell, it))


static func _look_sheet(shell, it: Dictionary) -> void:
	var worn: bool = shell.glow.equipped(Catalog.wear_key(it)) == it.id
	var v := Kit.vbox(18, [_center(CosmeticIcon.make(it.id, shell.profile.lineup, 180, shell.glow.dye_of(it.id))),
		Kit.label(it.name, 34, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label(Catalog.SLOT_NAMES.get(it.slot, "") + (" · Wearing" if worn else ""), 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
	var b := Kit.button("Wardrobe", func(): shell.close_overlay(); shell.go("shop"), "primary", 28, 90)
	shell.mark("look_wardrobe", b)
	v.add_child(b)
	shell.sheet(v)


static func _icon_box(g: Control, col: Color) -> Control:
	var box := Kit.panel(g, Kit.box(Color(col, .15), Color(col, .5), 22, 2, 10))
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return box


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
		b = Kit.cost_button("Merge all (%d)" % n, plan.hammers, "hammer", _confirm_merge_all.bind(shell), "go", 28, 90)
	shell.mark("merge_all", b)
	shell.pin(b)


## A gear section's painted band: the slot's arena painting with its name,
## how many pieces you hold and what that slot does on the calm left side.
static func _band(slot: String, n: int) -> Control:
	var art := LivingArt.make("gear_band_%ss" % slot.to_lower(), "res://game/ui/gear_art/gear_band_%ss.png" % slot.to_lower())
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	var title := Kit.hbox(8, [Kit.label("%sS" % slot.to_upper(), 32), Kit.label(str(n), 22, Kit.MUTED)], BoxContainer.ALIGNMENT_BEGIN)
	var words := Kit.vbox(0, [title, Kit.label(SLOT_LINES[slot], 18, Color("cfcbe8"))])
	words.position = Vector2(20, 14)
	var rim := Panel.new()
	rim.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0), Kit.LINE, 22, 2, 0))
	rim.set_anchors_preset(Control.PRESET_FULL_RECT)
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var band := Control.new()
	band.custom_minimum_size.y = BAND_H
	band.clip_contents = true
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in [art, words, rim]:
		band.add_child(c)
	return band


## One slot's gear, one entry per piece, best first: higher stars, then the
## type order, then worn before spare.
static func pieces(p, slot: String) -> Array:
	var out: Array = p.gear.filter(func(g): return g.slot == slot)
	out.sort_custom(func(a, b):
		if a.tier != b.tier:
			return a.tier > b.tier
		if a.type != b.type:
			return Gear.TYPES.find(a.type) < Gear.TYPES.find(b.type)
		return a.on != "" and b.on == "")
	return out


## A piece's painting with who wears it in the corner (nothing when spare).
static func _piece_art(g: Dictionary, side: float, face := 0.0) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(side, side)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := GearArt.tile(g.type, g.tier, side, tier_color(g.tier))
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_child(art)
	if g.on != "" and face > 0:
		var f := CritterIcon.face(g.on, face)
		f.position = Vector2(side - face * .7, side - face * .7)
		box.add_child(f)
	return box


## A gear tile: the painting (with the wearer's face), stars and the effect.
static func _gear_tile(shell, g: Dictionary) -> Control:
	var col := tier_color(g.tier)
	var effect := Kit.label(g.text, 17, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	# At least two lines tall, so one-line effects keep tiles the same size.
	effect.custom_minimum_size.y = roundf(A11y.font(17) * 2.6)
	var stars := Glyph.make("stars", 18, col, g.tier)
	stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var v := Kit.vbox(6, [_piece_art(g, 84, 40), stars, effect])
	var card := Kit.card_button(v, func(): _gear_sheet(shell, g), Color(col, .45), Kit.PANEL, 20, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.x = 0
	shell.mark("gear_%d" % g.uid, card)
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
	# The piece hops off its Bag card into the Critters tab, where it's now worn.
	var card: Control = shell._marks.get("gear_%d" % g.uid)
	if is_instance_valid(card):
		shell.fly_to_tab(func(): return _piece_art(g, 56, 28), card.get_global_rect().get_center(), "critters")
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
	# Who already wears something in this slot: named under the tile, its
	# piece in the corner (equipping swaps it off).
	var worn := {}
	var tags := {}
	for w in p.gear:
		if w.on != "" and w.slot == g.slot and w.uid != g.uid:
			worn[w.on] = w
			tags[w.on] = "Has " + w.name
	if g.on != "":
		tags[g.on] = "Wearing it"
	var opts := {"title": "Equip %s to" % g.name, "current": g.on, "locked": locked, "tags": tags,
		"locked_toast": "Charm slot unlocks when %%s reaches %d stars." % Gear.CHARM_TIER,
		"on_pick": func(id): _equip(shell, g, Roster.get_critter(id)),
		# What each critter already wears in this slot (equipping swaps it off).
		"corner": func(id): return GearArt.tile(worn[id].type, worn[id].tier, 40, tier_color(worn[id].tier)) if worn.has(id) else null}
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
	UpgradePopup.slam(shell, made.type, tier_color(made.tier), UpgradePopup.gear.bind(shell, made, tier_color(made.tier), cost), made.tier - 1)


static func _merge_all(shell) -> void:
	var cost: int = shell.profile.merge_all_plan().hammers
	var made: Array = shell.profile.merge_all_gear()
	shell.close_overlay()
	shell.refresh()
	if made.size() == 1:
		UpgradePopup.slam(shell, made[0].type, tier_color(made[0].tier), UpgradePopup.gear.bind(shell, made[0], tier_color(made[0].tier), cost), made[0].tier - 1)
	elif not made.is_empty():
		UpgradePopup.gear_list(shell, made, tier_color, cost)


## Asks before a merge: the three pieces that combine (with who wears them),
## the piece they make and its effect, who keeps it, then Merge for its cost.
static func _confirm_merge(shell, type: String, tier: int) -> void:
	var p = shell.profile
	var used: Array = p.merge_pieces(type, tier)
	var made := Profile.gear_piece({"type": type, "tier": tier + 1, "on": p.merge_wearer(used)})
	var ins := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for g in used:
		ins.add_child(_piece_art(g, 64, 32))
	var out := _piece_art(made, 96)
	var flow := Kit.hbox(10, [ins, Kit.label("→", 32, Kit.MUTED), out], BoxContainer.ALIGNMENT_CENTER)
	var col := tier_color(made.tier)
	var body: Array = [Kit.label("Merge?", 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), flow,
		Kit.hbox(10, [Kit.label(made.name, 28, col), UpgradePopup.stars(tier, made.tier, col)], BoxContainer.ALIGNMENT_CENTER),
		Kit.label(made.text, 24, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER, true)]
	if made.on != "":
		body.append(Kit.hbox(8, [Kit.label("Stays on", 22, Kit.MUTED), FighterTag.named(made.on, 40, 22)], BoxContainer.ALIGNMENT_CENTER))
	var cost: int = p.merge_cost(tier)
	body.append(_confirm_buttons(shell, cost, _merge.bind(shell, {"type": type, "tier": tier})))
	shell.sheet(Kit.vbox(18, body))


## Asks before Merge all: each merge as "3 of these → 1 of those" (repeats
## counted), the most rows that fit, then Merge all for the total.
static func _confirm_merge_all(shell) -> void:
	var p = shell.profile
	var plan: Dictionary = p.merge_all_plan()
	var groups := []
	for m in plan.merges:
		if not groups.is_empty() and groups[-1].type == m[0] and groups[-1].tier == m[1]:
			groups[-1].n += 1
		else:
			groups.append({"type": m[0], "tier": m[1], "n": 1})
	var list := Kit.vbox(10)
	for gr in groups.slice(0, 6):
		var from := Profile.gear_piece({"type": gr.type, "tier": gr.tier})
		var to := Profile.gear_piece({"type": gr.type, "tier": gr.tier + 1})
		var name := Kit.label(to.name, 22)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_child(Kit.hbox(10, [
			_piece_art(from, 52), Kit.label("x%d" % (3 * gr.n), 22, Kit.MUTED), Kit.label("→", 24, Kit.MUTED),
			_piece_art(to, 52), Kit.label("x%d" % gr.n, 22, Kit.MUTED), name,
			Glyph.make("stars", 18, tier_color(to.tier), to.tier)], BoxContainer.ALIGNMENT_CENTER))
	if groups.size() > 6:
		list.add_child(Kit.label("+%d more" % (groups.size() - 6), 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	var title := "Merge all?" if plan.merges.size() == 1 else "Merge all %d?" % plan.merges.size()
	shell.sheet(Kit.vbox(18, [Kit.label(title, 36, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER), list,
		_confirm_buttons(shell, plan.hammers, _merge_all.bind(shell))]))


## Cancel and Merge (with its Hammers) under a merge confirm.
static func _confirm_buttons(shell, cost: int, on_yes: Callable) -> Control:
	var no := Kit.button("Cancel", func(): shell.close_overlay(), "ghost", 26, 84)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("merge_cancel", no)
	var yes := Kit.cost_button("Merge", cost, "hammer", on_yes, "go", 26, 84)
	yes.disabled = shell.profile.hammers < cost
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("merge_confirm", yes)
	return Kit.hbox(12, [no, yes])


## The gear sheet's header: the piece standing big on a spotlit pedestal.
static func _pedestal(g: Dictionary) -> Control:
	var art := LivingArt.make("gear_plinth", "res://game/ui/gear_art/gear_plinth.png")
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.soften(40.0) # No hard edge onto the sheet.
	var piece := GearArt.piece(g.type, g.tier, 170, tier_color(g.tier))
	piece.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	piece.offset_left = -85
	piece.offset_right = 85
	piece.offset_top = -214
	piece.offset_bottom = -44
	var box := Control.new()
	box.custom_minimum_size.y = 260
	box.clip_contents = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)
	box.add_child(piece)
	return box


static func _gear_sheet(shell, g: Dictionary) -> void:
	var p = shell.profile
	var col := tier_color(g.tier)
	var info := Kit.vbox(6, [Kit.label(g.name, 36), Kit.hbox(10, [Glyph.make("stars", 26, col, g.tier), Kit.chip(g.slot, col)], BoxContainer.ALIGNMENT_BEGIN)])
	var wearer: Control = Kit.label("Not equipped", 22, Kit.MUTED)
	if g.on != "":
		wearer = Kit.hbox(8, [Kit.label("Worn by", 22, Kit.MUTED), FighterTag.named(g.on, 44, 22, Kit.FG)], BoxContainer.ALIGNMENT_BEGIN)
	var v := Kit.vbox(18, [_pedestal(g), info, Kit.label(g.text, 28, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true), wearer])
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
		var merge := Kit.cost_button("Merge 3", cost, "hammer", _confirm_merge.bind(shell, g.type, g.tier), "go", 26, 84) if have >= 3 else Kit.button("%d of 3 to merge" % have, func(): pass, "go", 26, 84)
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
			act = Kit.button("Use 1", func():
				shell.reward_from(shell._marks.get("item_use", shell), "energy") # The bolts fly up from the button.
				shell.close_overlay()
				if p.use_energy_pack():
					shell.toast("+30 energy")
				shell.refresh(), "primary", 28, 90)
			act.disabled = it.count <= 0
		"Summon Egg":
			act = Kit.button("Summon", func(): shell.show_tab("summon"), "primary", 28, 90)
		Profile.RIFT_KEY:
			act = Kit.button("Open a Rift", func(): shell.close_overlay(); shell.go("rift"), "primary", 28, 90)
			act.disabled = it.count <= 0
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
	if int(g.get("levels", 0)) > 0:
		shell.glow.record("level", int(g.levels))
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
	var kind: String = {"Energy Pack": "energy", "Summon Egg": "orb", Profile.RIFT_KEY: "key"}.get(it.name, "bolt")
	return _icon_box(Glyph.make(kind, 64, it.color), it.color)


static func _grid(gap := 14) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", gap)
	grid.add_theme_constant_override("v_separation", gap)
	return grid


static func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc
