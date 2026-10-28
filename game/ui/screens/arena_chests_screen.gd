## Weekly Arena chests (game/pvp/arena_chest.gd): last week's chest to open
## (or this week's so far and the time left), then every league's chest and
## what it holds, as icons and numbers. Opened from the league banner in the
## Ghost Arena and the chest tile on the Versus hub.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaChest := preload("res://game/pvp/arena_chest.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")
const BounceChestOpen := preload("res://game/ui/bounce_chest_open.gd")
const PassScreen := preload("res://game/ui/screens/pass_screen.gd")


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	var ready: bool = store.chest_ready()
	store.save()
	var root := Kit.vbox(14)
	root.add_child(shell.title_row("Weekly Chests", {"info_mark": "chests_info", "info": [
		"The best league you reach each week (Monday to Sunday) opens that league's chest when the week ends.",
		"Attacks and defence raids both count. An unopened chest waits until next week's replaces it.",
	]}))
	root.add_child(_now_card(shell, store, ready))
	var mine: int = int(store.chest.league) if ready else maxi(store.week_best, Ladder.league_index(store.trophies))
	var list := Kit.vbox(8)
	for i in range(Ladder.LEAGUES.size() - 1, -1, -1):
		list.add_child(_chest_row(shell, i, i == mine))
	root.add_child(list)
	return root


## The chest that matters now: last week's to open, else this week's so far.
static func _now_card(shell, store, ready: bool) -> Control:
	var league: int = int(store.chest.league) if ready else maxi(store.week_best, Ladder.league_index(store.trophies))
	var look := ArenaChest.look(league)
	var art := _art(look, 120.0)
	var words := Kit.vbox(6)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ready:
		words.add_child(Kit.caption("Last week"))
		words.add_child(Kit.label(look.name, 30, look.color))
		var open := Kit.button("Open", func():
			var shown := look.duplicate()
			shown.caption = "GHOST ARENA · WEEKLY CHEST"
			BounceChestOpen.show_custom(shell, shown, ArenaChest.rewards(league, int(store.chest.week)), func():
				ArenaChest.open(store, shell.profile)), "go", 28, 80)
		shell.mark("chest_open", open)
		words.add_child(open)
	else:
		words.add_child(Kit.caption("This week"))
		words.add_child(Kit.label(look.name, 30, look.color))
		words.add_child(Kit.label("Ends in " + ArenaChest.time_text(ArenaChest.seconds_left()), 22, Kit.MUTED))
	var row := Kit.hbox(16, [art, words], BoxContainer.ALIGNMENT_CENTER)
	return Kit.panel(row, Kit.box(Kit.PANEL, Color(look.color, .7), 28, 3, 14))


## One league's chest: its picture, the league and where it starts, and
## what's inside. Yours this week stands out.
static func _chest_row(shell, league: int, mine: bool) -> Control:
	var lg: Dictionary = Ladder.LEAGUES[league]
	var look := ArenaChest.look(league)
	var head := Kit.hbox(8, [Kit.label(lg.name, 24, lg.color), Kit.amount("trophy", "%s+" % Kit.commas(int(lg.min)), 18, Kit.MUTED, Glyph.GOLD)], BoxContainer.ALIGNMENT_BEGIN)
	var stuff := Kit.hbox(10, [], BoxContainer.ALIGNMENT_BEGIN)
	for r in ArenaChest.rewards(league, ArenaChest.this_week()):
		var bits: Array = [PassScreen.reward_icon(shell, r, 40.0)]
		if r.kind != "gear":
			bits.append(Kit.label(Kit.commas(int(r.get("n", 1))), 20, Kit.FG))
		stuff.add_child(Kit.hbox(2, bits, BoxContainer.ALIGNMENT_CENTER))
	var words := Kit.vbox(2, [head, stuff])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(12, [_art(look, 64.0), words], BoxContainer.ALIGNMENT_CENTER)
	var st := Kit.box(Color(lg.color, .14) if mine else Kit.PANEL, Color(lg.color, .9) if mine else Kit.LINE, 22, 3 if mine else 1, 8)
	var p := Kit.panel(row, st)
	shell.mark("chest_%s" % lg.id, p)
	return p


static func _art(look: Dictionary, height: float) -> Control:
	var art := ChestArt.make(str(look.id), height)
	if look.has("tint"):
		art.modulate = look.tint
	return art
