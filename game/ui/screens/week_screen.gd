## This Week board: today's Trick Shot, the Fight of the Day, the
## Try-a-Critter loaner, the Critter Spotlight and the next Chaos Weekend, all from the live-ops schedule
## (game/liveops.gd). Opened from the banner on the Play tab.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
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
	var root := Kit.vbox(22)
	var back := Kit.button("Back", shell.back, "ghost", 24, 64)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size.x = 150
	shell.mark("week_back", back)
	var season := LiveOps.season(t)
	var season_text := "%s · week %d of %d" % [season.name, season.week, season.weeks] if not season.is_empty() else ""
	root.add_child(Kit.hbox(16, [back, Kit.spacer(), Kit.label(season_text, 22, Kit.MUTED)]))
	root.add_child(Kit.label("This Week", 48))
	root.add_child(_strip(t))
	root.add_child(_trick_shot(shell))
	root.add_child(_fight(shell, t))
	var bracket := BracketScreen.board_card(shell, t)
	if bracket != null:
		root.add_child(bracket)
	var counters := []
	root.add_child(_try_critter(shell, t, counters))
	root.add_child(_spotlight(shell, t, counters))
	root.add_child(_chaos(t, counters))
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
		var cell := Kit.panel(Kit.vbox(0, [Kit.label(DAYS[i], 20, col, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label(str(date.day), 28, Kit.FG if day >= today else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)]),
			Kit.box(bg, border, 18, 3 if day == today else 2, 8))
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(cell)
	return Kit.vbox(8, [row, Kit.label("Trick Shot and Fight of the Day every day. Chaos rules Friday to Sunday.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)])


static func _card(children: Array, border := Kit.LINE, bg := Kit.PANEL) -> Control:
	return Kit.panel(Kit.vbox(12, children), Kit.box(bg, border, 36, 2, 26))


# --- Daily Trick Shot --------------------------------------------------------------

static func _trick_shot(shell) -> Control:
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var s := trick_status(day)
	var status := "One called bank shot, %d tries. Same puzzle for everyone today." % TRICK_TRIES
	var label := "Play"
	if s.solved:
		status = "Solved in %d %s. Streak %d." % [s.tries, "try" if s.tries == 1 else "tries", s.streak]
		label = "See result"
	elif s.tries >= TRICK_TRIES:
		status = "Out of tries today. A new shot lands at midnight."
		label = "See result"
	elif s.tries > 0:
		status = "%d %s left." % [TRICK_TRIES - s.tries, "try" if TRICK_TRIES - s.tries == 1 else "tries"]
		label = "Keep trying"
	var play := Kit.button(label, func(): shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn"), "primary", 26, 80)
	shell.mark("week_trickshot", play)
	var done: bool = s.solved or s.tries >= TRICK_TRIES
	return _card([
		Kit.hbox(8, [Kit.caption("Daily Trick Shot · #%d" % day, Color("9be89a")), Kit.spacer(), Kit.chip("Done" if done else "New", Kit.GOOD if done else Kit.WARN)]),
		Kit.label(status, 24, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		play,
	])


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
	var vs := Kit.hbox(10, [_side(f.p1, "P1", names[0]), Kit.label("VS", 30, Kit.MUTED), _side(f.p2, "P2", names[1])], BoxContainer.ALIGNMENT_CENTER)
	var children: Array = [
		Kit.hbox(8, [Kit.caption("Fight of the Day", Color("ffc23d")), Kit.spacer(), Kit.label(f.title, 22, Kit.MUTED)]),
		vs,
	]
	if pick < 0:
		children.append(Kit.label("Who wins? Call it, then watch.", 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true))
		var buttons := Kit.hbox(14)
		for i in 2:
			var b := Kit.button("P%d %s" % [i + 1, names[i]], func(): call_fight(shell, f, i), "ghost", 24, 80)
			shell.mark("fotd_pick%d" % i, b)
			buttons.add_child(b)
		children.append(buttons)
	else:
		var right: bool = pick == f.winner
		children.append(Kit.label("You called %s. %s Streak %d." % [names[pick], "Correct!" if right else "Not this time.", fight_streak(t)],
			24, Kit.GOOD if right else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true))
		var again := Kit.button("Watch again", func(): shell.watch(f.merged({"pick": pick})), "ghost", 24, 80)
		shell.mark("fotd_watch", again)
		children.append(again)
	return _card(children, Color("5a4a1e"))


static func _side(id: String, tag: String, name: String) -> Control:
	var v := Kit.vbox(2, [CritterIcon.make(id, 1, 130), Kit.label("%s · %s" % [tag, name], 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v


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
	var ends := Kit.label("", 20, Kit.MUTED)
	counters.append([ends, "Ends in %s", l.ends])
	ends.text = "Ends in %s" % LiveOps.countdown(t, l.ends)
	var info := Kit.vbox(4, [Kit.label(c.name, 34), Kit.chip(Roster.RARITY_NAMES[c.rarity], Roster.RARITY_COLORS[c.rarity]),
		Kit.label(l.blurb if l.blurb != "" else c.vibe, 22, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(info.get_child(1) as Control).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var note := "On loan to you today in %s. Practice only: it won't count for Ghost Arena or the campaign." % Loaner.modes_text()
	if l.owned:
		note = "You already own %s. Today it's on loan to everyone who doesn't. The Critter Shot is open to all." % c.name
	var day := maxi(1, TrickShot.day_number(Time.get_date_dict_from_system()))
	var s := trick_status(day, l.critter)
	var shot_label := "Critter Shot"
	if s.solved:
		shot_label = "Shot solved"
	elif s.tries >= TRICK_TRIES:
		shot_label = "Shot done"
	var shot := Kit.button(shot_label, func(): open_critter_shot(shell, l.critter), "primary", 24, 80)
	shell.mark("try_shot", shot)
	var fight := Kit.button("Quick fight", func(): shell.request_play(l.critter), "ghost", 24, 80)
	shell.mark("try_fight", fight)
	return _card([
		Kit.hbox(8, [Kit.caption("Try-a-Critter", TRY), Kit.spacer(), ends]),
		Kit.hbox(16, [CritterIcon.make(c.id, Loaner.TIER, 140), info]),
		Kit.label(note, 21, TRY if l.on_loan else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.hbox(14, [shot, fight]),
	], Color("1f5a6b"), Color("0e1f33"))


## Opens today's Critter Shot: a bonus bank shot with the loaner.
static func open_critter_shot(shell, id: String) -> void:
	load("res://game/trick_shot.gd").critter_shot = id
	shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn")


# --- Spotlight and Chaos -----------------------------------------------------------

static func _spotlight(shell, t: int, counters: Array) -> Control:
	var s := LiveOps.spotlight(t)
	var c := Roster.get_critter(s.critter)
	var col: Color = Roster.RARITY_COLORS[c.rarity]
	var ends := Kit.label("", 20, Kit.MUTED)
	counters.append([ends, "Ends in %s", s.ends])
	ends.text = "Ends in %s" % LiveOps.countdown(t, s.ends)
	var info := Kit.vbox(4, [Kit.label(c.name, 34), Kit.chip(Roster.RARITY_NAMES[c.rarity], col),
		Kit.label(s.blurb if s.blurb != "" else c.vibe, 22, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(info.get_child(1) as Control).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var summon := Kit.button("Summon Portal", func(): shell.show_tab("summon"), "ghost", 24, 80)
	shell.mark("week_summon", summon)
	return _card([
		Kit.hbox(8, [Kit.caption("Critter Spotlight", Color("e8c8ff")), Kit.spacer(), ends]),
		Kit.hbox(16, [CritterIcon.make(c.id, 1, 140), info]),
		Kit.label("Featured in the Summon Portal: %s gets half of all %s rolls this week." % [c.name, Roster.RARITY_NAMES[c.rarity]], 21, Color("e8c8ff"), HORIZONTAL_ALIGNMENT_LEFT, true),
		summon,
	], Color("6b3fb0"), Color("1c1040"))


static func _chaos(t: int, counters: Array) -> Control:
	var c := LiveOps.chaos(t)
	var until: int = c.ends if c.live else c.starts
	var fmt := "Live now · ends in %s" if c.live else "Starts Friday · in %s"
	var when := Kit.label(fmt % LiveOps.countdown(t, until), 26, CHAOS)
	counters.append([when, fmt, until])
	return _card([
		Kit.hbox(8, [Kit.caption("Chaos Weekend", CHAOS), Kit.spacer(), Kit.chip("Live" if c.live else "Next", CHAOS)]),
		Kit.label(c.name, 40),
		Kit.label(c.description, 22, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		when,
		Kit.label("One rule twist for every fight, the same for both balls.", 20, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	], Color("5a2550"), Color("1e0f2c"))


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
		Kit.label(chaos, 26, CHAOS, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.label("Trick Shot · Fight of the Day · Try %s · %s" % [loan.name, "Bracket of Legends" if not Legends.current(t).is_empty() else "%s Spotlight" % s.name], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
	])
	var b := Kit.card_button(v, func(): shell.go("week"), Color("6b3fb0"), Color("1c1040"), 36, 24)
	shell.mark("thisweek", b)
	return b
