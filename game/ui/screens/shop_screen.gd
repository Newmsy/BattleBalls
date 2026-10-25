## The cosmetics shop (design/monetisation.md §3): Featured bundles that change
## weekly, six Daily items that rotate at 00:00 UTC, the Coin-priced
## Collection, and your wardrobe with its Spark Dyes (earned colours for what
## you own, never sold). Everything is cosmetic and shown before you buy it at
## a fixed price; every item has a try-on preview.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Roster := preload("res://game/ui/roster.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const CosmeticIcon := preload("res://game/glow/cosmetic_icon.gd")
const TryOn := preload("res://game/glow/try_on.gd")
const LiveOps := preload("res://game/liveops.gd")
const Dyes := preload("res://game/glow/dyes.gd")

const GEM := Color("5ce1ff")
const DAILY_SLOTS := 6
const FEATURED := 2


static func build(shell, _params: Dictionary) -> Control:
	var glow = shell.glow
	var t := LiveOps.now()
	var root := Kit.vbox(24)
	var gems_btn := Kit.card_button(Kit.hbox(8, [Kit.amount("gem", glow.gems(), 28), Kit.chip("+", GEM, 22)]),
		func(): gem_sheet(shell), Color(GEM, .6), Kit.PANEL, 999, 10)
	shell.mark("get_gems", gems_btn)
	root.add_child(shell.title_row("Shop", {"back_mark": "shop_back", "eyebrow": "Looks only", "extra": [gems_btn]}))

	# Featured bundles, this week.
	var week_ends := LiveOps.week_start(t) + LiveOps.WEEK
	var featured := Kit.vbox(14, [Kit.hbox(0, [Kit.caption("Featured", Color("ffd36b")), Kit.spacer(), Kit.label("New in " + LiveOps.countdown(t, week_ends), 20, Kit.MUTED)])])
	for b in featured_bundles(t):
		featured.add_child(_bundle_card(shell, b))
	root.add_child(featured)

	# Daily items.
	var day_ends := LiveOps.day_start(t) + LiveOps.DAY
	root.add_child(Kit.vbox(14, [Kit.hbox(0, [Kit.caption("Daily"), Kit.spacer(), Kit.label("New in " + LiveOps.countdown(t, day_ends), 20, Kit.MUTED)]),
		_grid(shell, daily_items(t))]))

	# Collection: Coin-priced basics, always here.
	var basics := Catalog.ITEMS.filter(func(it): return it.where == "basic")
	root.add_child(Kit.vbox(14, [Kit.caption("Collection"), _grid(shell, basics)]))

	# Wardrobe.
	var ward := Kit.vbox(12, [Kit.caption("Wearing")])
	for slot in Catalog.SLOTS:
		var id: String = glow.equipped(slot)
		var name: String = Catalog.item(id).name if id != "" else "Nothing"
		var count := Catalog.items_in(slot).filter(func(it): return glow.owns(it.id)).size()
		var text := Kit.vbox(2, [Kit.label(Catalog.SLOT_NAMES[slot], 22, Kit.MUTED), Kit.label(name, 28)])
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var row := Kit.hbox(14, [CosmeticIcon.make(id, _critter(shell), 76) if id != "" else _empty_icon(), text, Kit.chip("%d owned" % count, Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER)
		var card := Kit.card_button(row, func(): _wardrobe_sheet(shell, slot), Kit.LINE, Kit.PANEL, 28, 12)
		shell.mark("wear_" + slot, card)
		ward.add_child(card)
	ward.add_child(_dyes_card(shell))
	root.add_child(ward)
	if shell.glow.store and shell.glow.store.is_test():
		root.add_child(Kit.label("Test store: free in playtest.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true))
	return root


## This week's bundles: everyone sees the same ones.
static func featured_bundles(t: int) -> Array:
	var week := floori(float(LiveOps.week_start(t) - LiveOps.EPOCH) / LiveOps.WEEK)
	var out := []
	for i in FEATURED:
		out.append(Catalog.BUNDLES[posmod(week * FEATURED + i, Catalog.BUNDLES.size())])
	return out


## Today's six gem items, the same for everyone, at least one per slot.
static func daily_items(t: int) -> Array:
	var day := floori(float(LiveOps.day_start(t) - LiveOps.EPOCH) / LiveOps.DAY)
	var pool := Catalog.ITEMS.filter(func(it): return it.where == "shop")
	var out := []
	for slot in Catalog.SLOTS:
		var in_slot := pool.filter(func(it): return it.slot == slot)
		out.append(in_slot[posmod(day, in_slot.size())])
	var k := 0
	while out.size() < DAILY_SLOTS and k < pool.size():
		var it: Dictionary = pool[posmod(day * 5 + k * 3, pool.size())]
		if it not in out:
			out.append(it)
		k += 1
	return out


static func _critter(shell) -> String:
	return shell.profile.lineup


static func _grid(shell, items: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for it in items:
		grid.add_child(_tile(shell, it))
	return grid


static func _tile(shell, it: Dictionary) -> Control:
	var owned: bool = shell.glow.owns(it.id)
	var v := Kit.vbox(4, [_center(CosmeticIcon.make(it.id, _critter(shell), 120)), Kit.label(it.name, 21, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true),
		_center(_price(it, owned, shell.glow.equipped(it.slot) == it.id))])
	var rarity := look_rarity(it)
	var card := Kit.card_button(v, func(): item_sheet(shell, it.id), Roster.rarity_border(rarity, Kit.LINE), Roster.rarity_bg(rarity, Kit.PANEL, .16), 28, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.mark("item_" + it.id, card)
	return card


## A look's frame, from its gem price (looks have no rarity of their own):
## coin basics and cheap looks are plain, then rare, epic and legendary.
static func look_rarity(it: Dictionary) -> String:
	var gems := int(it.get("gems", 0))
	if gems <= 300:
		return "common"
	if gems <= 450:
		return "rare"
	return "epic" if gems <= 700 else "legendary"


static func _price(it: Dictionary, owned: bool, worn := false) -> Control:
	if worn:
		return Kit.chip("Wearing", Kit.GOOD)
	if owned:
		return Kit.chip("Owned", Kit.GOOD)
	if it.has("coins"):
		return Kit.amount("coin", it.coins, 22)
	return Kit.amount("gem", it.gems, 22)


static func _bundle_card(shell, b: Dictionary) -> Control:
	var glow = shell.glow
	var icons := Kit.hbox(24, [], BoxContainer.ALIGNMENT_CENTER)
	for id in b.items:
		icons.add_child(CosmeticIcon.make(id, _critter(shell), 96))
	var shelf := _Shelf.new()
	shelf.add_child(icons)
	icons.sort_children.connect(shelf.queue_redraw)
	var full := Catalog.bundle_full_price(b)
	var price: int = glow.bundle_price(b)
	var saving := roundi(100.0 * (1.0 - float(b.gems) / full))
	var btn: Button
	if price == 0:
		btn = Kit.button("Owned", func(): pass, "ghost", 26, 80)
		btn.disabled = true
	else:
		btn = Kit.cost_button("Buy", price, "gem", func():
			var err: String = glow.buy_bundle(b.id)
			shell.toast(err if err != "" else "%s unlocked!" % b.name)
			shell.refresh(), "primary", 26, 80)
	shell.mark("buy_" + b.id, btn)
	# The saving is a gold ribbon by the name rather than a line of small print.
	var ribbon := Kit.chip("SAVE %d%%" % saving, Glyph.GOLD)
	var head := Kit.hbox(10, [Kit.label(b.name, 34), Kit.spacer(), ribbon], BoxContainer.ALIGNMENT_CENTER)
	var v := Kit.vbox(10, [head, shelf, btn])
	if price > 0 and price < int(b.gems):
		v.add_child(Kit.label("Owned items taken off.", 20, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true))
	return Kit.panel(v, Kit.box(Color("221a3a"), Color("6b5520"), 36, 2, 24))


## One item: try-on preview, what it is, and buy / equip.
static func item_sheet(shell, id: String) -> void:
	var glow = shell.glow
	var it := Catalog.item(id)
	var look: Dictionary = glow.loadout().duplicate()
	look[it.slot] = id
	look["dye_" + it.slot] = glow.dye_of(id)
	var p = shell.profile
	var tier: int = p.best(p.lineup).get("tier", 1)
	var v := Kit.vbox(16, [
		Kit.hbox(12, [Kit.label(it.name, 36), Kit.spacer(), Kit.chip(Catalog.SLOT_NAMES[it.slot], Kit.ACCENT)], BoxContainer.ALIGNMENT_CENTER),
		TryOn.make(p.lineup, tier, look, 320.0),
	])
	var where := _where_text(it)
	if where != "":
		v.add_child(Kit.label(where, 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	if glow.owns(id):
		v.add_child(_swatches(shell, id))
	var btn: Button
	if glow.owns(id):
		var worn: bool = glow.equipped(it.slot) == id
		btn = Kit.button("Take off" if worn else "Wear it", func():
			if worn:
				glow.unequip(it.slot)
			else:
				glow.equip(id)
			shell.close_overlay()
			shell.toast("%s %s." % [it.name, "taken off" if worn else "on"])
			shell.refresh(), "ghost" if worn else "go", 28, 90)
	elif it.where in ["shop", "basic"]:
		btn = Kit.cost_button("Buy", it.coins if it.has("coins") else it.gems, "coin" if it.has("coins") else "gem", func():
			var err: String = glow.buy_item(id)
			if err == "":
				glow.equip(id)
				shell.close_overlay()
				shell.toast("%s unlocked and on!" % it.name)
				shell.refresh()
			elif err == "Not enough Glow Gems.":
				shell.close_overlay()
				gem_sheet(shell)
			else:
				shell.toast(err), "primary", 28, 90)
	else:
		btn = Kit.button("Not sold", func(): pass, "ghost", 28, 90)
		btn.disabled = true
	shell.mark("item_action", btn)
	v.add_child(btn)
	shell.sheet(v)


static func _where_text(it: Dictionary) -> String:
	match it.where:
		"pass_free":
			return "From the Glow Pass free track."
		"pass_premium":
			return "On this season's Glow Pass."
		"founder":
			return "Part of the Founder Pack."
	return ""


static func _wardrobe_sheet(shell, slot: String) -> void:
	var glow = shell.glow
	var v := Kit.vbox(14, [Kit.label(Catalog.SLOT_NAMES[slot] + "s", 36)])
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var any := false
	for it in Catalog.items_in(slot):
		if not glow.owns(it.id):
			continue
		any = true
		var on: bool = glow.equipped(slot) == it.id
		var card := Kit.card_button(Kit.vbox(4, [_center(CosmeticIcon.make(it.id, _critter(shell), 110)), Kit.label(it.name, 20, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)]),
			func():
				if on:
					glow.unequip(slot)
				else:
					glow.equip(it.id)
				shell.close_overlay()
				shell.refresh(), Kit.GOOD if on else Kit.LINE, Kit.PANEL2, 24, 8)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("wear_" + it.id, card)
		grid.add_child(card)
	if any:
		v.add_child(grid)
	else:
		v.add_child(Kit.label("None yet. Find them in the shop or on the Glow Pass.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	shell.sheet(v)


## Spark Dyes in the wardrobe: how many colours you've unlocked, a row of
## the first few swatches, tap for every dye and its bar.
static func _dyes_card(shell) -> Control:
	var p = shell.profile
	var row := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for d in Dyes.DYES.slice(0, 9):
		row.add_child(_Swatch.make(d.id, 34, not Dyes.unlocked(p, d.id)))
	var text := Kit.vbox(4, [Kit.hbox(8, [Glyph.make("dye", 30, Color("ff6fd0")), Kit.label("Spark Dyes", 28)], BoxContainer.ALIGNMENT_CENTER), row])
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var count := Kit.chip("%d/%d" % [Dyes.unlocked_count(p), Dyes.DYES.size()], Color("ff6fd0"))
	var card := Kit.card_button(Kit.hbox(14, [text, count], BoxContainer.ALIGNMENT_CENTER), func(): dyes_sheet(shell), Kit.LINE, Kit.PANEL, 28, 12)
	shell.mark("wear_dyes", card)
	return card


## Every Spark Dye with its bar: earned in Rifts, from boss wins and from a
## stage's first three crowns; a full bar unlocks the colour.
static func dyes_sheet(shell) -> void:
	var p = shell.profile
	var v := Kit.vbox(12, [Kit.label("Spark Dyes", 36),
		Kit.label("Recolour the looks you own. Drops come from Rifts, boss wins and a stage's first three crowns; a full bar unlocks the colour.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	for grade in ["basic", "bright", "prism"]:
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		for d in Dyes.DYES.filter(func(x): return x.grade == grade):
			var have := Dyes.unlocked(p, d.id)
			var name := Kit.label(d.name, 20, Kit.FG if have else Kit.MUTED)
			name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			name.clip_text = true
			var info := Kit.vbox(4, [name, Kit.bar(float(Dyes.drops(p, d.id)) / Dyes.need(d.id), Color(d.colors[0]), 10)])
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var cell := Kit.hbox(8, [_Swatch.make(d.id, 44, not have), info], BoxContainer.ALIGNMENT_CENTER)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(cell)
		v.add_child(Kit.vbox(8, [Kit.caption("%s · %d drops each" % [Dyes.GRADE_NAMES[grade], Dyes.NEED[grade]]), grid]))
	shell.sheet(v)


## Under an owned cosmetic's try-on: its own colours first, then every Spark
## Dye. Tap an unlocked one to wear it; a locked one says how far along it is.
static func _swatches(shell, id: String) -> Control:
	var glow = shell.glow
	var p = shell.profile
	var on: String = glow.dye_of(id)
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var original := Kit.card_button(_center(_Swatch.make("", 52, false, id)), func():
		glow.set_dye(id, "")
		shell.close_overlay()
		item_sheet(shell, id), Kit.FG if on == "" else Color(0, 0, 0, 0), Kit.PANEL2, 999, 4)
	shell.mark("dye_original", original)
	grid.add_child(original)
	for d in Dyes.DYES:
		var have := Dyes.unlocked(p, d.id)
		var pick := func():
			if not have:
				shell.toast("%s: %d/%d drops. Find them in Rifts and boss wins." % [d.name, Dyes.drops(p, d.id), Dyes.need(d.id)])
				return
			glow.set_dye(id, d.id)
			shell.close_overlay()
			item_sheet(shell, id)
		var b := Kit.card_button(_center(_Swatch.make(d.id, 52, not have)), pick, Kit.FG if on == d.id else Color(0, 0, 0, 0), Kit.PANEL2, 999, 4)
		shell.mark("dye_" + d.id, b)
		grid.add_child(b)
	var name: String = Dyes.dye(on).get("name", "Original colours")
	return Kit.vbox(8, [Kit.hbox(8, [Kit.caption("Dye"), Kit.label(name, 20, Kit.FG)], BoxContainer.ALIGNMENT_CENTER), grid])


## Glow Gem packs and the Founder Pack, through the store.
static func gem_sheet(shell) -> void:
	var glow = shell.glow
	var store = glow.store
	var v := Kit.vbox(14, [Kit.hbox(10, [Glyph.make("gem", 44), Kit.label("Glow Gems", 36), Kit.spacer(), Kit.label("You have %s" % Kit.commas(glow.gems()), 24, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)])
	if not store.available():
		v.add_child(Kit.label("Gem packs are in the iPhone and Android apps.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		shell.sheet(v)
		return
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	var base := 80.0 / 0.99
	for p in Catalog.PRODUCTS:
		if p.kind != "gems":
			continue
		var bonus := roundi(100.0 * (p.gems / (base * float(p.usd)) - 1.0))
		var inner := Kit.vbox(4, [_center(Glyph.make("gem", 50)), Kit.label(Kit.commas(p.gems), 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label("+%d%%" % bonus if bonus > 1 else " ", 18, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER), Kit.label(store.price(p.id), 22, GEM, HORIZONTAL_ALIGNMENT_CENTER)])
		var card := Kit.card_button(inner, func(): _buy(shell, p.id), Color(GEM, .4), Kit.PANEL2, 24, 10)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shell.mark("buy_" + p.id, card)
		grid.add_child(card)
	v.add_child(grid)
	var founder := Catalog.product("founder")
	if "founder" not in glow.g().unlocks:
		var fb := Kit.button("Founder Pack · %s" % store.price("founder"), func(): _buy(shell, "founder"), "primary", 26, 84)
		shell.mark("buy_founder", fb)
		v.add_child(Kit.hbox(6, [Kit.label("One time: %s" % Kit.commas(founder.gems), 22), Kit.glyph("gem", 26, Kit.FG), Kit.label("+ Founder Crown", 22)]))
		v.add_child(fb)
	var restore := Kit.button("Restore purchases", func(): store.restore(); shell.close_overlay(); shell.toast("Purchases restored."), "ghost", 24, 72)
	v.add_child(restore)
	if store.is_test():
		v.add_child(Kit.label("Test store: free in playtest.", 20, Kit.WARN, HORIZONTAL_ALIGNMENT_CENTER, true))
	shell.sheet(v)


## Asks the store; GlowState reports the result (shell shows it), so a real
## store's slower, out-of-app purchase flow works the same way.
static func _buy(_shell, product_id: String) -> void:
	_shell.glow.store.purchase(product_id)


static func _empty_icon() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(76, 76)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


## A round Spark Dye swatch: its two colours split down the middle (a Prism
## one with a sparkle), dimmed with a lock while it's still a bar. With no dye
## it shows cosmetic `item`'s own colours. Drawn once.
class _Swatch extends Control:
	const Dot := preload("res://game/dot.gd")
	const DyesData := preload("res://game/glow/dyes.gd")
	const CatalogData := preload("res://game/glow/catalog.gd")
	const CritterArt := preload("res://game/ui/critter_art.gd")
	var cols: Array = [Color.WHITE, Color.WHITE]
	var locked := false
	var prism := false

	static func make(dye: String, side: float, locked_: bool, item := "") -> Control:
		var w := _Swatch.new()
		var d: Dictionary = DyesData.dye(dye)
		var src: Dictionary = d if not d.is_empty() else CatalogData.item(item)
		var c: Array = src.get("colors", ["8f7bff", "f0eeff"])
		w.cols = [Color(c[0]), Color(c[mini(1, c.size() - 1)])]
		w.prism = d.get("shimmer", false)
		w.locked = locked_
		w.custom_minimum_size = Vector2(side, side)
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		w.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return w

	func _draw() -> void:
		var r := minf(size.x, size.y) / 2.0
		var c := size / 2.0
		var a: Color = cols[0].darkened(.45) if locked else cols[0]
		var b: Color = cols[1].darkened(.45) if locked else cols[1]
		Dot.circle(self, c, r, Color("0b0a1f"))
		Dot.circle(self, c, r * .86, a)
		draw_colored_polygon(_half(c, r * .86), b)
		draw_circle(c + Vector2(-r * .3, -r * .32), r * .14, Color(1, 1, 1, .25 if locked else .6))
		if prism and not locked:
			draw_colored_polygon(CritterArt.star_pts(c + Vector2(r * .45, -r * .45), r * .3, r * .1, 4), Color("fff2b0"))
		if locked:
			draw_arc(c + Vector2(0, -r * .14), r * .2, PI, TAU, 10, Color(1, 1, 1, .8), r * .1, true)
			draw_rect(Rect2(c + Vector2(-r * .27, -r * .08), Vector2(r * .54, r * .42)), Color(1, 1, 1, .8))

	## The lower-right half of the disc, for the second colour.
	func _half(c: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 13:
			var ang := -PI / 4.0 + i * PI / 12.0
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		return pts


## The display under a Featured bundle's items: a soft spotlight above each
## and a small velvet stand under it, on one gold-edged shelf. Drawn whenever
## the row lays out, never per frame.
class _Shelf extends MarginContainer:
	const Dot := preload("res://game/dot.gd")
	const GOLD := Color("ffd36b")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override("margin_bottom", 14)

	func _draw() -> void:
		var row: Control = get_child(0) if get_child_count() > 0 else null
		if row == null:
			return
		var y := size.y - 8.0
		draw_rect(Rect2(size.x * .06, y, size.x * .88, 6), Color("3a2a52"))
		draw_line(Vector2(size.x * .06, y), Vector2(size.x * .94, y), Color(GOLD, .55), 2.0)
		for icon in row.get_children():
			var r: Rect2 = (icon as Control).get_rect()
			var c := row.position + r.get_center()
			Dot.circle(self, c, r.size.x * .55, Color(1, .95, .8, .035))
			draw_set_transform(Vector2(c.x, y), 0.0, Vector2(1.0, .28))
			Dot.circle(self, Vector2.ZERO, r.size.x * .42, Color("2a1c40"))
			Dot.circle(self, Vector2(0, -4), r.size.x * .36, Color("4b2f6e"))
			draw_set_transform_matrix(Transform2D.IDENTITY)
