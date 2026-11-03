## Weekly Arena chests for one Arena mode (params.mode; each mode has its
## own, game/pvp/arena_chest.gd): last week's chest to open (or this week's
## so far and the time left), then every league's chest and what it holds,
## as icons and numbers. Opened from a mode page's league banner and the
## chest tiles on the Arena hub.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Idle := preload("res://game/ui/idle.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaChest := preload("res://game/pvp/arena_chest.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")
const BounceChestOpen := preload("res://game/ui/bounce_chest_open.gd")
const PassScreen := preload("res://game/ui/screens/pass_screen.gd")
const ChestDrops := preload("res://meta/chest_drops.gd")
const Gear := preload("res://sim/gear.gd")


static func build(shell, params: Dictionary) -> Control:
	var store = params.get("store", null)
	if store == null:
		store = ArenaStore.open()
	store.use(str(params.get("mode", store.mode)))
	_mode = store.mode
	var ready: bool = store.chest_ready()
	store.save()
	var root := Kit.vbox(14)
	var m: Dictionary = ArenaStore.MODES[store.mode]
	root.add_child(shell.title_row("Weekly Chests", {"eyebrow": str(m.name).to_upper(), "eyebrow_color": m.color, "info_mark": "chests_info", "info": [
		"The best league you reach in %s each week (Monday to Sunday) opens that league's chest when the week ends. The other mode has its own." % m.name,
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
	if ready:
		Idle.breathe(art, .1, .6) # Waiting to be opened.
	var words := Kit.vbox(6)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if ready:
		words.add_child(Kit.caption("Last week"))
		words.add_child(Kit.label(look.name, 30, look.color))
		var open := Kit.button("Open", func():
			var shown := look.duplicate()
			shown = ArenaChest.look(league, store.mode)
			shown.caption = "%s · WEEKLY CHEST" % str(ArenaStore.MODES[store.mode].name).to_upper()
			BounceChestOpen.show_custom(shell, shown, ArenaChest.rewards(league, ArenaChest.roll_week(int(store.chest.week), store.mode), shell.profile.chest_seed()), func():
				ArenaChest.open(store, shell.profile)), "go", 28, 80)
		shell.mark("chest_open", open)
		Idle.breathe(open, .05)
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
	var words := Kit.vbox(2, [head, drops_row(shell, ArenaChest.odds(league), 36.0)])
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var art := _art(look, 64.0)
	if mine:
		Idle.breathe(art, .06, .5) # The chest you're on course for this week.
	var row := Kit.hbox(12, [art, words], BoxContainer.ALIGNMENT_CENTER)
	var st := Kit.box(Color(lg.color, .14) if mine else Kit.PANEL, Color(lg.color, .9) if mine else Kit.LINE, 22, 3 if mine else 1, 8)
	var p := Kit.panel(row, st)
	shell.mark("chest_%s" % lg.id, p)
	return p


## The mode whose chests this screen shows (set by build()).
static var _mode := "series"

## A chest's drop table as icons with their ranges and chances ("200-400",
## "50%"); the Ascension Spark chance sits last, in purple. Shared with the
## Bounce Run rules.
static func drops_row(shell, table: Array, side: float) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 2)
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for e in table:
		var r: Dictionary = e.duplicate()
		if r.kind == "gear" and not r.has("type"):
			r.type = "iron_shell"
		var bits: Array = [PassScreen.reward_icon(shell, r, side)]
		var words := ChestDrops.text(e, Kit.commas)
		if r.kind == "gear":
			words = ("%d-star" % int(r.tier)) + ("" if int(e.get("n", 1)) == 1 else " x%d" % int(e.n))
		bits.append(Kit.label(words, roundi(side * .5), Glyph.PURPLE if r.kind == "spark" else Kit.FG))
		flow.add_child(Kit.hbox(2, bits, BoxContainer.ALIGNMENT_CENTER))
	return flow


static func _art(look: Dictionary, height: float) -> Control:
	return chest_art(look, height, _mode)


## A weekly chest in `mode`'s look: the league's painted chest, tinted
## for the mode, with the mode's badge on its front.
static func chest_art(look: Dictionary, height: float, mode := "series") -> Control:
	var art := ChestArt.make(str(look.id), height)
	var m: Dictionary = ArenaChest.MODE_LOOK.get(mode, ArenaChest.MODE_LOOK.series)
	var tint: Color = look.get("tint", Color(1, 1, 1))
	if not look.has("badge"):
		tint *= m.tint # A look made without the mode.
	if tint != Color(1, 1, 1):
		art.modulate = tint
	var badge := Kit.chip(str(m.badge), m.badge_color, maxi(12, roundi(height * .16)))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st = badge.get_theme_stylebox("panel")
	if st is StyleBoxFlat:
		st.bg_color = Color(Kit.BG, .88)
	var holder := Control.new()
	holder.custom_minimum_size = art.custom_minimum_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(art)
	holder.add_child(badge)
	# Bottom right of the chest, drawn untinted.
	badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	badge.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	badge.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return holder
