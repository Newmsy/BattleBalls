## The Daily board: today's Trick Shot and Bounce Run, the Fight of the Day,
## the Bracket of Legends when one is on, and the Quests door, all from the
## live-ops schedule (game/liveops.gd). Opened from the Daily door on the Play
## tab. Every card wears a painted fair stall (game/ui/home_art/daily_*.png,
## tools/event_art/scenes/daily_*.mjs).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const LiveOps := preload("res://game/liveops.gd")
const TrickShot := preload("res://sim/trick_shot.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const BracketScreen := preload("res://game/ui/screens/bracket_screen.gd")
const HomePainting := preload("res://game/ui/home_painting.gd")
const BounceRun := preload("res://sim/bounce_run.gd")
const BounceChest := preload("res://meta/bounce_chest.gd")
const BounceChestOpen := preload("res://game/ui/bounce_chest_open.gd")
const ChestArt := preload("res://game/ui/chest_art.gd")

const SAVE_PATH := "user://this_week.cfg"
const TRICK_SAVE := "user://trick_shot.cfg"
const TRICK_TRIES := 3
const QUESTS := Color("ffd36b")
## Painted header height on a card.
const ART_H := 132


static func build(shell, _params: Dictionary) -> Control:
	var t := LiveOps.now()
	var root := Kit.vbox(14)
	var season := LiveOps.season(t)
	root.add_child(shell.title_row("Daily", {"back_mark": "week_back", "info_mark": "week_info", "info": _info_text(),
		"eyebrow": "" if season.is_empty() else "%s · week %d of %d" % [season.name, season.week, season.weeks]}))
	var tiles: Array = [_trick_shot(shell), _bounce_run(shell), _fight(shell, t)]
	var bracket := BracketScreen.board_card(shell, t, tile)
	if bracket != null:
		tiles.append(bracket)
	# Two cards a row; an odd one out takes the whole row.
	for i in range(0, tiles.size(), 2):
		var row := Kit.hbox(12, tiles.slice(i, i + 2))
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		root.add_child(row)
	root.add_child(_quests(shell))
	return root


## The long-form rules behind the board's "i" button.
static func _info_text() -> Array:
	return [
		"Trick Shot: one called bank shot, %d tries, the same puzzle for everyone. A new one lands at midnight." % TRICK_TRIES,
		"Bounce Run: draft a trio and climb %d floors, as many runs as you like. Your best floor each day opens a chest the next day." % BounceRun.FLOORS,
		"Fight of the Day: tap who you think wins, then watch. Correct calls in a row build your streak.",
		"Quests: three a day and three a week, paying energy, eggs, coins and more.",
	]


## One card of the board: a painted stall with the caption on it, then a
## body and the card's action at the bottom, lined up with its neighbour's.
## `art` names the painting (game/ui/home_art/<art>.png); `over` sits on the
## painting above the caption (Fight of the Day's critters). `border` and `bg`
## are kept for callers but no longer change the card.
## A tap anywhere on the card presses `door` (by default `action`, if a button).
static func tile(caption: String, accent: Color, _border: Color, _bg: Color, body: Array, action: Control = null, badge: Control = null, art := "", over: Control = null, art_h := ART_H, door: BaseButton = null) -> Control:
	var head := Kit.hbox(6, [line(caption.to_upper(), 18, accent)])
	if badge != null:
		head.add_child(badge)
	var v := Kit.vbox(8, [])
	for c in body:
		v.add_child(c)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(gap)
	if action != null:
		v.add_child(action)
	var p: PanelContainer
	if art == "":
		v.add_child(head)
		v.move_child(head, 0)
		p = Kit.panel(v, Kit.box(Kit.PANEL, Kit.LINE, 30, 2, 18))
	else:
		var st := Kit.box(Kit.PANEL, Kit.LINE, 30, 2, 18)
		st.set_content_margin_all(2)
		p = Kit.panel(Kit.vbox(6, [painted(art, head, over, art_h), _pad(v)]), st)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.x = 0
	if door == null and action is BaseButton:
		door = action
	if door == null:
		return p
	var b := Kit.tap_card(p, func():
		if not door.disabled:
			door.pressed.emit(), 30)
	b.custom_minimum_size.x = 0
	return b


## A painted band with `head` on its bottom edge and `over` above it. The
## painting fades into the card at the bottom, so its lower corners vanish.
static func painted(art: String, head: Control, over: Control = null, height := ART_H) -> Control:
	var band := MarginContainer.new()
	band.custom_minimum_size.y = height
	band.add_child(HomePainting.make(art, Vector2(.5, .6), 28.0, Vector4(0, 0, .5, 1.0), Kit.PANEL))
	_shadowed(head)
	var on := Kit.vbox(2, [])
	var room := Control.new()
	room.size_flags_vertical = Control.SIZE_EXPAND_FILL
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	on.add_child(room)
	if over != null:
		on.add_child(over)
	on.add_child(head)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 2)
	m.add_child(on)
	band.add_child(m)
	return band


## Text on a painting gets a soft dark shadow so it reads on any colour.
static func _shadowed(n: Node) -> void:
	if n is Label:
		Kit.soft_shadow(n, Color(0, 0, 0, .7), 2, 6)
	for c in n.get_children():
		_shadowed(c)


## A card's body under its painting: the card's 18px sides and bottom.
static func _pad(c: Control) -> MarginContainer:
	var m := MarginContainer.new()
	m.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	m.add_child(c)
	return m


## A one-line label that trims with an ellipsis instead of widening its tile.
static func line(text: String, size := 22, color := Kit.FG) -> Label:
	var l := Kit.label(text, size, color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.clip_text = true
	return l


## Up to two lines of text in a tile.
static func lines(text: String, size := 21, color := Kit.FG) -> Label:
	var l := Kit.label(text, size, color, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.max_lines_visible = 2
	l.custom_minimum_size.x = 200
	return l


static func _action(text: String, on_press: Callable, kind := "go") -> Button:
	return Kit.button(text, on_press, kind, 22, 64)


# --- Daily Trick Shot --------------------------------------------------------------

static func _trick_shot(shell) -> Control:
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var s := trick_status(day)
	var status := "%d tries" % TRICK_TRIES
	var label := "Play"
	if s.solved:
		status = "Solved in %d %s. Streak %d." % [s.tries, "try" if s.tries == 1 else "tries", s.streak]
		label = "Result"
	elif s.tries >= TRICK_TRIES:
		status = "Out of tries. New shot at midnight."
		label = "Result"
	elif s.tries > 0:
		status = "%d %s left." % [TRICK_TRIES - s.tries, "try" if TRICK_TRIES - s.tries == 1 else "tries"]
		label = "Keep trying"
	var play := _action(label, func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn"))
	shell.mark("week_trickshot", play)
	var done: bool = s.solved or s.tries >= TRICK_TRIES
	return tile("Trick Shot", Color("9be89a"), Kit.LINE, Kit.PANEL,
		[line("Daily #%d" % day, 26), lines(status, 20)], play, Kit.chip("Done" if done else "New", Kit.GOOD if done else Kit.WARN, 16), "daily_trick")


## Bounce Run: roguelike runs with a drafted trio. The best floor of a day
## opens a chest the next day: then the card's button opens it first.
static func _bounce_run(shell) -> Control:
	var day := BounceRun.day_number(Time.get_unix_time_from_system())
	var best := BounceChest.best_floors()
	var chest := BounceChest.pending(best, int(shell.profile.bounce_chest), day) if shell.profile != null else {}
	if not chest.is_empty():
		var t: Dictionary = BounceChest.TIERS[int(chest.tier)]
		var open := _action("Open", func(): BounceChestOpen.show_on(shell, chest))
		shell.mark("week_bounce_chest", open)
		var art := CenterContainer.new()
		art.add_child(ChestArt.make(str(t.id), 84.0))
		return tile("Bounce Run", Color("ffc23d"), Kit.LINE, Kit.PANEL, [art, lines(t.name, 22)], open, Kit.chip("Chest", Kit.WARN, 16), "daily_bounce")
	var play := _action("Play", func(): shell.get_tree().change_scene_to_file("res://game/bounce_run.tscn"))
	shell.mark("week_bouncerun", play)
	var today := int(best.get(day, 0))
	var t := BounceChest.tier_for(today)
	var body: Array = [line("Best today: floor %d" % today if today > 0 else "Climb %d floors" % BounceRun.FLOORS, 26)]
	if t >= 0:
		body.append(lines("%s tomorrow" % BounceChest.TIERS[t].name, 20))
	else:
		body.append(lines("Reach floor %d for a chest." % int(BounceChest.TIERS[0].floor), 20))
	return tile("Bounce Run", Color("ffc23d"), Kit.LINE, Kit.PANEL, body, play, null, "daily_bounce")


## { tries, solved, streak } for Trick Shot `day`, from its save file.
static func trick_status(day: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(TRICK_SAVE) != OK:
		return {"tries": 0, "solved": false, "streak": 0}
	var tries: Array = cfg.get_value("days", str(day), [])
	return {"tries": tries.size(), "solved": tries.any(func(x): return x.result == TrickShot.SOLVED),
		"streak": cfg.get_value("stats", "streak", 0)}


# --- Fight of the Day ----------------------------------------------------------------

## Today's two critters stand in the painted ring; before the call, tapping
## one picks it and starts the fight.
static func _fight(shell, t: int) -> Control:
	var f := LiveOps.fight_of_the_day(t)
	var names := [BallDefs.get_def(f.p1).display_name, BallDefs.get_def(f.p2).display_name]
	var pick := pick_for(f.date)
	var ring := Kit.hbox(0, [], BoxContainer.ALIGNMENT_CENTER)
	for i in 2:
		var id: String = f.p1 if i == 0 else f.p2
		var side: Control = CritterIcon.make(id, 1, 84)
		if pick < 0:
			side = Kit.card_button(side, func(): call_fight(shell, f, i), Color(0, 0, 0, 0), Color(0, 0, 0, 0), 40, 0)
			shell.mark("fotd_pick%d" % i, side)
		elif pick != i:
			side.modulate = Color(1, 1, 1, .55)
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ring.add_child(side)
	var vs := line("%s vs %s" % names, 20)
	var body: Array = [vs]
	var action: Control = null
	if pick < 0:
		body.append(lines("Tap who wins, then watch.", 20, Kit.MUTED))
	else:
		var right: bool = pick == f.winner
		body.append(lines("%s Streak %d." % ["Called it!" if right else "Not this time.", fight_streak(t)], 20, Kit.GOOD if right else Kit.FG))
		action = _action("Watch again", func(): shell.watch(f.merged({"pick": pick})), "ghost")
		shell.mark("fotd_watch", action)
	return tile("Fight of the Day", Color("ffc23d"), Color("5a4a1e"), Kit.PANEL, body, action, null, "daily_fotd", ring)


## Locks in the pick for today and starts the fight in the arena.
static func call_fight(shell, f: Dictionary, pick: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("fotd", f.date, [pick, pick == f.winner])
	cfg.save(SAVE_PATH)
	shell.glow.record("fotd")
	shell.watch(f.merged({"pick": pick}))


## The side picked on `date` ("YYYY-MM-DD"), or -1.
static func pick_for(date: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return -1
	return cfg.get_value("fotd", date, [-1])[0]


## Correct calls in a row, ending today (or yesterday, before today's call).
static func fight_streak(t: int) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	var day := LiveOps.day_start(t)
	if not cfg.has_section_key("fotd", Time.get_date_string_from_unix_time(day)):
		day -= LiveOps.DAY
	var n := 0
	while cfg.get_value("fotd", Time.get_date_string_from_unix_time(day), [-1, false])[1]:
		n += 1
		day -= LiveOps.DAY
	return n


# --- Quests ---------------------------------------------------------------------

## The wide Quests door along the bottom: today's quests done, what they
## pay, and the way in. A chip says when something is ready to claim.
static func _quests(shell) -> Control:
	var q: Dictionary = shell.glow.quests(LiveOps.now())
	var ready: int = shell.glow.quests_ready()
	var rewards := Kit.hbox(14, [Kit.glyph("energy", 34, Color.WHITE), Kit.glyph("egg", 34, Color.WHITE), Kit.glyph("coin", 34, Color.WHITE)], BoxContainer.ALIGNMENT_CENTER)
	var words := lines("%d/3 done today" % q.chest.done if not (q.daily as Array).is_empty() else "Three new quests", 20)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var open := _action("Quests", func(): shell.go("quests"))
	open.custom_minimum_size.x = 180
	shell.mark("week_quests", open)
	var body := Kit.hbox(14, [words, rewards, open], BoxContainer.ALIGNMENT_CENTER)
	var badge: Control = Kit.chip("Claim", Kit.GOOD, 16) if ready > 0 else null
	return tile("Quests", QUESTS, Kit.LINE, Kit.PANEL, [body], null, badge, "daily_quests", null, 112, open)
