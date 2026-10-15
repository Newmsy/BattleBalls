## This Week board: today's Trick Shot, the Fight of the Day, the
## Try-a-Critter loaner, the Critter Spotlight and the next Chaos Weekend, all from the live-ops schedule
## (game/liveops.gd). Opened from the banner on the Play tab.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const LiveOps := preload("res://game/liveops.gd")
const TrickShot := preload("res://sim/trick_shot.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Legends := preload("res://game/legends.gd")
const BracketScreen := preload("res://game/ui/screens/bracket_screen.gd")
const Loaner := preload("res://game/loaner.gd")

const SAVE_PATH := "user://this_week.cfg"
const TRICK_SAVE := "user://trick_shot.cfg"
const TRICK_TRIES := 3
const CHAOS := Color("ff6fae")
const TRY := Color("5ce1ff")
const DAYS := ["M", "T", "W", "T", "F", "S", "S"]


static func build(shell, _params: Dictionary) -> Control:
	var t := LiveOps.now()
	var root := Kit.vbox(16)
	var back: Control = shell.back_button("week_back")
	var season := LiveOps.season(t)
	var title := Kit.vbox(0, [Kit.label("This Week", 40)])
	if not season.is_empty():
		title.add_child(Kit.label("%s · week %d of %d" % [season.name, season.week, season.weeks], 20, Kit.MUTED))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(Kit.hbox(16, [back, title, shell.info_button("This Week", _info_text(shell, t), "week_info")]))
	root.add_child(_strip(t))
	var counters := []
	var tiles: Array = [_trick_shot(shell), _fight(shell, t)]
	var bracket := BracketScreen.board_card(shell, t, tile)
	if bracket != null:
		tiles.append(bracket)
	tiles.append_array([_try_critter(shell, t, counters), _spotlight(shell, t, counters), _chaos(shell, t, counters)])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for tile in tiles:
		grid.add_child(tile)
	root.add_child(grid)
	# Keep the countdowns ticking while the board is open.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func():
		var now := LiveOps.now()
		for c in counters:
			if is_instance_valid(c[0]):
				c[0].text = c[1] % LiveOps.countdown(now, c[2]))
	root.add_child(timer)
	return root


## The long-form rules behind the board's "i" button.
static func _info_text(shell, t: int) -> Array:
	var l := Loaner.today(shell.profile, t)
	var loan := Roster.get_critter(l.critter)
	var spot := Roster.get_critter(LiveOps.spotlight(t).critter)
	var loan_note := "%s is on loan to you today in %s. Practice only: it won't count for Ghost Arena or the campaign. Its Critter Shot is a bonus bank shot with it." % [loan.name, Loaner.modes_text()]
	if l.owned:
		loan_note = "You already own %s. Today it's on loan to everyone who doesn't. The Critter Shot is open to all." % loan.name
	return [
		"Trick Shot: one called bank shot, %d tries, the same puzzle for everyone. A new one lands at midnight." % TRICK_TRIES,
		"Fight of the Day: call who wins, then watch. Correct calls in a row build your streak.",
		"Try-a-Critter: " + loan_note,
		"Critter Spotlight: %s gets half of all %s rolls in the Summon Portal this week." % [spot.name, Roster.RARITY_NAMES[spot.rarity]],
		"Chaos Weekend: one rule twist for every fight from Friday to Sunday, the same for both balls.",
	]


## Mon..Sun with today lit and the Chaos Weekend days tinted.
static func _strip(t: int) -> Control:
	var row := Kit.hbox(8)
	var today := LiveOps.day_start(t)
	var monday := LiveOps.week_start(t)
	for i in 7:
		var day := monday + i * LiveOps.DAY
		var weekend := i >= 4
		var col: Color = CHAOS if weekend else Kit.MUTED
		var bg := Color("2a1236") if weekend else Kit.PANEL
		var border: Color = Kit.ACCENT if day == today else (Color("5a2550") if weekend else Kit.LINE)
		var date := Time.get_date_dict_from_unix_time(day)
		var cell := Kit.panel(Kit.hbox(6, [Kit.label(DAYS[i], 20, col), Kit.label(str(date.day), 22, Kit.FG if day >= today else Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER),
			Kit.box(bg, border, 16, 3 if day == today else 2, 6))
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cell)
	return row


## One half-width tile of the board: a caption row, a body and the tile's
## action at the bottom, lined up with its neighbour's.
static func tile(caption: String, accent: Color, border: Color, bg: Color, body: Array, action: Control = null, badge: Control = null) -> Control:
	var head := Kit.hbox(6, [line(caption.to_upper(), 18, accent)])
	if badge != null:
		head.add_child(badge)
	var v := Kit.vbox(8, [head])
	for c in body:
		v.add_child(c)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(gap)
	if action != null:
		v.add_child(action)
	var p := Kit.panel(v, Kit.box(bg, border, 30, 2, 18))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


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


static func _action(text: String, on_press: Callable, kind := "primary") -> Button:
	return Kit.button(text, on_press, kind, 22, 64)


# --- Daily Trick Shot --------------------------------------------------------------

static func _trick_shot(shell) -> Control:
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var s := trick_status(day)
	var status := "%d tries. Same shot for everyone." % TRICK_TRIES
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
		[line("Daily #%d" % day, 28), lines(status)], play, Kit.chip("Done" if done else "New", Kit.GOOD if done else Kit.WARN, 16))


## { tries, solved, streak } for Trick Shot `day`, from its save file, or for
## that day's Critter Shot with `shooter`.
static func trick_status(day: int, shooter := "") -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(TRICK_SAVE) != OK:
		return {"tries": 0, "solved": false, "streak": 0}
	var tries: Array = cfg.get_value("days" if shooter == "" else "critter_" + shooter, str(day), [])
	return {"tries": tries.size(), "solved": tries.any(func(x): return x.result == TrickShot.SOLVED),
		"streak": cfg.get_value("stats", "streak", 0)}


# --- Fight of the Day ----------------------------------------------------------------

static func _fight(shell, t: int) -> Control:
	var f := LiveOps.fight_of_the_day(t)
	var names := [BallDefs.get_def(f.p1).display_name, BallDefs.get_def(f.p2).display_name]
	var pick := pick_for(f.date)
	var sides := Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	for i in 2:
		var id: String = f.p1 if i == 0 else f.p2
		var v := Kit.vbox(0, [CritterIcon.make(id, 1, 76), line(names[i], 18, Kit.MUTED)])
		(v.get_child(1) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var side: Control = v
		if pick < 0:
			side = Kit.card_button(v, func(): call_fight(shell, f, i), Color("5a4a1e"), Kit.PANEL2, 22, 6)
			shell.mark("fotd_pick%d" % i, side)
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side.custom_minimum_size.x = 0
		sides.add_child(side)
		if i == 0:
			sides.add_child(Kit.label("VS", 20, Kit.MUTED))
	var body: Array = [sides]
	var action: Control = null
	if pick < 0:
		body.append(lines("Tap who wins, then watch.", 20, Kit.FG))
	else:
		var right: bool = pick == f.winner
		body.append(lines("%s Streak %d." % ["Called it!" if right else "Not this time.", fight_streak(t)], 20, Kit.GOOD if right else Kit.FG))
		action = _action("Watch again", func(): shell.watch(f.merged({"pick": pick})), "ghost")
		shell.mark("fotd_watch", action)
	return tile("Fight of the Day", Color("ffc23d"), Color("5a4a1e"), Kit.PANEL, body, action)


## Locks in the pick for today and starts the fight in the arena.
static func call_fight(shell, f: Dictionary, pick: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("fotd", f.date, [pick, pick == f.winner])
	cfg.save(SAVE_PATH)
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


# --- Try-a-Critter -------------------------------------------------------------------

static func _try_critter(shell, t: int, counters: Array) -> Control:
	var l := Loaner.today(shell.profile, t)
	var c := Roster.get_critter(l.critter)
	var ends := line("", 18, Kit.MUTED)
	counters.append([ends, "Ends in %s", l.ends])
	ends.text = "Ends in %s" % LiveOps.countdown(t, l.ends)
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var s := trick_status(day, l.critter)
	var shot_label := "Shot"
	if s.solved:
		shot_label = "Solved"
	elif s.tries >= TRICK_TRIES:
		shot_label = "Done"
	var shot := _action(shot_label, func(): open_critter_shot(shell, l.critter))
	shell.mark("try_shot", shot)
	var fight := _action("Fight", func(): shell.request_play(l.critter), "ghost")
	shell.mark("try_fight", fight)
	var who := Kit.vbox(0, [line(c.name, 26), line("Owned" if l.owned else "On loan today", 18, Kit.MUTED if l.owned else TRY), ends])
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return tile("Try-a-Critter", TRY, Color("1f5a6b"), Color("0e1f33"),
		[Kit.hbox(10, [CritterIcon.make(c.id, Loaner.TIER, 76), who])], Kit.hbox(8, [shot, fight]))


## Opens today's Critter Shot: a bonus bank shot with the loaner.
static func open_critter_shot(shell, id: String) -> void:
	load("res://game/trick_shot.gd").critter_shot = id
	shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn")


# --- Spotlight and Chaos -----------------------------------------------------------

static func _spotlight(shell, t: int, counters: Array) -> Control:
	var s := LiveOps.spotlight(t)
	var c := Roster.get_critter(s.critter)
	var col: Color = Roster.RARITY_COLORS[c.rarity]
	var ends := line("", 18, Kit.MUTED)
	counters.append([ends, "Ends in %s", s.ends])
	ends.text = "Ends in %s" % LiveOps.countdown(t, s.ends)
	var who := Kit.vbox(0, [line(c.name, 26), line("Half of %s rolls" % Roster.RARITY_NAMES[c.rarity], 18, col), ends])
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var summon := _action("Summon", func(): shell.show_tab("summon"), "ghost")
	shell.mark("week_summon", summon)
	return tile("Spotlight", Color("e8c8ff"), Color("6b3fb0"), Color("1c1040"),
		[Kit.hbox(10, [CritterIcon.make(c.id, 1, 76), who])], summon)


## The weekend's rule twist; the tile opens its full description.
static func _chaos(shell, t: int, counters: Array) -> Control:
	var c := LiveOps.chaos(t)
	var until: int = c.ends if c.live else c.starts
	var fmt := "Ends in %s" if c.live else "Starts in %s"
	var when := line(fmt % LiveOps.countdown(t, until), 20, CHAOS)
	counters.append([when, fmt, until])
	var more := _action("What it does", func(): shell.info(c.name, [c.description, "One rule twist for every fight from Friday to Sunday, the same for both balls."]), "ghost")
	shell.mark("week_chaos", more)
	return tile("Chaos Weekend", CHAOS, Color("5a2550"), Color("1e0f2c"),
		[lines(c.name, 26), when], more, Kit.chip("Live" if c.live else "Next", CHAOS, 16))


## The banner on the Play tab that opens this board.
static func banner(shell) -> Control:
	var t := LiveOps.now()
	var season := LiveOps.season(t)
	var c := LiveOps.chaos(t)
	var s := Roster.get_critter(LiveOps.spotlight(t).critter)
	var loan := Roster.get_critter(LiveOps.loaner(t).critter)
	var top := "This week" + (" · %s week %d" % [season.name, season.week] if not season.is_empty() else "")
	var chaos := ("Chaos Weekend: %s, live for %s" if c.live else "Chaos Weekend: %s in %s") % [c.name, LiveOps.countdown(t, c.ends if c.live else c.starts)]
	var v := Kit.vbox(6, [
		Kit.hbox(8, [Kit.caption(top, Color("e8c8ff")), Kit.spacer(), Kit.label("Open ›", 22, Kit.ACCENT)]),
		Kit.label(chaos, 24, CHAOS, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.label("Fight of the Day · Try %s · %s" % [loan.name, "Bracket of Legends" if not Legends.current(t).is_empty() else "%s Spotlight" % s.name], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	var b := Kit.card_button(v, func(): shell.go("week"), Color("6b3fb0"), Color("1c1040"), 32, 18)
	shell.mark("thisweek", b)
	return b
