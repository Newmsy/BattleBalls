## Arena Bazaar: spend Tokens, won only in the Ghost Arena, on a daily
## stock of gear at your league's tier, a Summon Egg and an energy top-up.
## Tokens are never sold for money. Reached from the Arena hub.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Gear := preload("res://sim/gear.gd")

const COIN := Color("ff4fd8")


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var root := Kit.vbox(12)
	var how := [
		"Tokens come only from the Ghost Arena, never for money: about 15 for a win (more against a team above you), %d for a loss, %d for each raid your Defence holds." % [
			ArenaStore.COINS_LOSS, ArenaStore.COINS_DEFENCE],
		"The stock changes every day and each item sells once. Gear gets better as your league climbs.",
	]
	root.add_child(shell.title_row("Bazaar", {"info_mark": "bazaar_info", "info": how}))
	var bank := Kit.hbox(10, [Glyph.make("token", 34), Kit.label(Kit.commas(store.coins), 34), Kit.spacer(), Kit.label("New stock tomorrow", 20, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	root.add_child(Kit.panel(bank, Kit.box(Color("17143e"), COIN, 28, 2, 16)))
	var stock: Array = store.bazaar()
	for i in stock.size():
		root.add_child(_item(shell, store, stock[i], i))
	return root


static func _item(shell, store, item: Dictionary, i: int) -> Control:
	var glyph := "orb" if item.kind == "orbs" else ("energy" if item.kind == "energy" else str(item.type))
	var sub := ""
	match item.kind:
		"gear":
			sub = "%d-star %s gear" % [item.tier, Gear.PIECES[item.type].slot]
	var sold: bool = store.is_bought(i)
	var afford: bool = store.coins >= int(item.price)
	var price := Kit.hbox(6, [Glyph.make("token", 24), Kit.label(Kit.commas(item.price), 26, Kit.FG if afford else Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)
	var info := Kit.vbox(2, [Kit.label(str(item.name), 28)])
	if sub != "":
		info.add_child(Kit.label(sub, 20, Kit.MUTED))
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(14, [Glyph.make(glyph, 56), info, Kit.label("Sold", 24, Kit.MUTED) if sold else price], BoxContainer.ALIGNMENT_CENTER)
	var btn := Kit.card_button(row, func():
		if store.buy(shell.profile, i):
			shell.toast("Bought %s." % item.name)
			shell.refresh_with({"store": store})
		elif sold:
			shell.toast("Sold out until tomorrow.")
		else:
			shell.toast("Need %d more Tokens" % (int(item.price) - store.coins)), Kit.LINE if sold else Color(COIN, .7), Kit.PANEL, 24, 12)
	if sold:
		btn.modulate = Color(1, 1, 1, .5)
	shell.mark("bazaar_item_%d" % i, btn)
	return btn
