## Bracket of Legends (game/legends.gd): pick a champion before the lock, then
## follow the bracket one round a day and watch any game of any series.
## Params: { round } picks the round shown (default: the latest one out).
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Legends := preload("res://game/legends.gd")
const LiveOps := preload("res://game/liveops.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Bracket := preload("res://sim/bracket.gd")

const GOLD := Color("ffc23d")
const WEEKDAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]


static func build(shell, params: Dictionary) -> Control:
	var t := LiveOps.now()
	var ev := Legends.current(t)
	var root := Kit.vbox(16)
	var back: Control = shell.back_button("bracket_back")
	var titles := Legends.oracle_titles(t)
	var badge := "Oracle x%d" % titles.size() if not titles.is_empty() else "Cosmetic rewards only"
	var name: String = ev.name if not ev.is_empty() else "Bracket of Legends"
	var title := Kit.vbox(0, [Kit.label(name, 32, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true), Kit.label(badge, 18, GOLD if not titles.is_empty() else Kit.MUTED)])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(title.get_child(0) as Label).custom_minimum_size.x = 300
	var about := ["Once a season every critter enters one bracket at equal power.",
		"Pick your champion before the first round. Call it right and you earn the Oracle title for that bracket. Rewards are cosmetic only."]
	if not ev.is_empty():
		about[0] = _blurb(ev, Legends.bracket(ev))
	root.add_child(Kit.hbox(14, [back, title, shell.info_button("Bracket of Legends", about, "bracket_info")]))
	if ev.is_empty():
		var nxt := Legends.next_event(t)
		var when := "The next one is announced %s." % _date(Legends.opens(nxt)) if not nxt.is_empty() else "The next one is announced with the next season."
		root.add_child(Kit.label("Once a season every critter enters one bracket at equal power. " + when, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
		return root
	var b := Legends.bracket(ev)
	var phase := Legends.phase(ev, t)
	root.add_child(_status(ev, t, phase))
	if phase == "picks":
		root.add_child(_pick_grid(shell, ev, t))
	else:
		root.add_child(_your_pick(ev, b, t))
	var out := Legends.rounds_out(ev, t)
	var r: int = clampi(int(params.get("round", maxi(0, out - 1))), 0, b.rounds - 1)
	root.add_child(_round_tabs(shell, b, r, out))
	root.add_child(_round(shell, ev, b, r, t))
	return root


static func _blurb(ev: Dictionary, b) -> String:
	var n: int = ev.entrants.size()
	var byes: int = b.size - n
	var text := "%d critters, all at equal power, in a %d-slot bracket" % [n, b.size]
	if byes > 0:
		text += " (the top %d %s a bye)" % [byes, "seed gets" if byes == 1 else "seeds get"]
	text += ". Each match is first to 2 wins, the final first to 3. One round comes out every day at 00:00 UTC; the final lands on Sunday."
	return text


static func _status(ev: Dictionary, t: int, phase: String) -> Control:
	var text := ""
	var col := Kit.ACCENT
	match phase:
		"picks":
			text = "Picks lock in %s, when the first round comes out." % LiveOps.countdown(t, Legends.locks(ev))
			col = Kit.GOOD
		"live":
			var out := Legends.rounds_out(ev, t)
			var b := Legends.bracket(ev)
			text = "%s: out now. %s comes out in %s." % [b.round_name(out - 1), b.round_name(out), LiveOps.countdown(t, Legends.reveal_at(ev, out))]
			col = GOLD
		"done":
			if Legends.champion_known(ev, t):
				text = "Champion: %s." % _name(Legends.bracket(ev).champion())
			else:
				text = "The final is out. Open it to see who won."
			col = GOLD
	return Kit.label(text, 23, col, HORIZONTAL_ALIGNMENT_LEFT, true)


# --- Picks ----------------------------------------------------------------------

static func _pick_grid(shell, ev: Dictionary, t: int) -> Control:
	var pick := Legends.pick_of(ev)
	var b := Legends.bracket(ev)
	var shares: Dictionary = shell.get_meta("bracket_shares", {}).get(ev.id, {})
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for id in b.draw:
		var nm := Kit.label(_name(id), 18, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.clip_text = true
		var lines := [CritterIcon.make(id, 1, 72), nm,
			Kit.label("%d%% picked" % roundi(shares[id] * 100.0) if shares.has(id) else "Seed %d" % b.seed_of(id), 16, Kit.ACCENT if shares.has(id) else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)]
		var card := Kit.card_button(Kit.vbox(0, lines), func(): _choose(shell, ev, id), GOLD if id == pick else Kit.LINE,
			Color("2a2208") if id == pick else Kit.PANEL, 22, 6)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.x = 0
		shell.mark("champ_" + id, card)
		grid.add_child(card)
	var head := "Your champion: %s. Tap another to change." % _name(pick) if pick != "" else "Who goes all the way? Tap your champion."
	_load_shares(shell, ev)
	return Kit.vbox(10, [Kit.label(head, 22, GOLD, HORIZONTAL_ALIGNMENT_LEFT, true), grid])


static func _choose(shell, ev: Dictionary, id: String) -> void:
	if not Legends.set_pick(ev, id, LiveOps.now()):
		shell.toast("Picks are locked.")
		shell.refresh()
		return
	shell.toast("%s is your champion." % _name(id))
	Legends.submit_pick(shell.backend, ev, id)
	shell.refresh()


## Fetches everyone's pick shares once per visit and redraws when they land.
static func _load_shares(shell, ev: Dictionary) -> void:
	if shell.backend == null or not shell.backend.enabled() or shell.has_meta("bracket_shares_loading"):
		return
	shell.set_meta("bracket_shares_loading", true)
	var shares: Dictionary = await Legends.pick_shares(shell.backend, ev)
	if not is_instance_valid(shell):
		return
	var all: Dictionary = shell.get_meta("bracket_shares", {})
	all[ev.id] = shares
	shell.set_meta("bracket_shares", all)
	if not shares.is_empty() and shell.current == "bracket":
		shell.refresh()


static func _your_pick(ev: Dictionary, b, t: int) -> Control:
	var pick := Legends.pick_of(ev)
	if pick == "":
		return Kit.label("No champion picked for this one. Picks for the next bracket open the week before it.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	# Follow the pick through the rounds that are out and seen: today's round
	# stays a surprise until the player opens it.
	var text := "Still in. Every round they win is one closer."
	var col := Kit.FG
	for r in Legends.rounds_out(ev, t):
		var i := _match_index(b, r, pick)
		if i < 0 or not Legends.shows_result(ev, r, i, t):
			break
		if b.get_match(r, i).winner != pick:
			text = "Out in the %s. Better luck next season." % b.round_name(r)
			col = Kit.MUTED
			break
		if r == b.rounds - 1:
			text = "CHAMPION! You called it: the Oracle title is yours."
			col = GOLD
	var info := Kit.vbox(2, [Kit.caption("Your champion · " + _name(pick), GOLD), Kit.label(text, 22, col, HORIZONTAL_ALIGNMENT_LEFT, true)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return _card([Kit.hbox(14, [CritterIcon.make(pick, 1, 80), info])], Color("5a4a1e"))


## The match `id` plays in round `r`, or -1 (out before it).
static func _match_index(b, r: int, id: String) -> int:
	for m in b.round_matches(r):
		if m.a == id or m.b == id:
			return m.index
	return -1


# --- Rounds ---------------------------------------------------------------------

static func _round_tabs(shell, b, selected: int, out: int) -> Control:
	var scroll := ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var row := Kit.hbox(10)
	for r in b.rounds:
		var col: Color = Kit.ACCENT if r == selected else (Kit.FG if r < out else Kit.MUTED)
		var tab := Kit.card_button(Kit.label(b.round_name(r), 20, col, HORIZONTAL_ALIGNMENT_CENTER), func(): shell.refresh_with({"round": r}),
			Kit.ACCENT if r == selected else Kit.LINE, Kit.PANEL2 if r == selected else Kit.PANEL, 999, 14)
		shell.mark("round_%d" % r, tab)
		row.add_child(tab)
	scroll.add_child(row)
	scroll.custom_minimum_size.y = row.get_combined_minimum_size().y
	return scroll


static func _round(shell, ev: Dictionary, b, r: int, t: int) -> Control:
	var out := Legends.rounds_out(ev, t)
	var v := Kit.vbox(8)
	if r >= out:
		var when := Legends.reveal_at(ev, r)
		v.add_child(Kit.label("Comes out %s at 00:00 UTC." % _date(when), 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	elif r == out - 1:
		v.add_child(Kit.label("Today's round: tap a match to see how it went.", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	for i in b.matches_in(r):
		if r >= out:
			# Not out yet: nothing is simulated. Round 1 shows the draw; later
			# rounds are only known once the round before them is out.
			var a := _feeder(ev, b, r, i * 2, out, t)
			var c := _feeder(ev, b, r, i * 2 + 1, out, t)
			v.add_child(_row(shell, ev, b, {"index": i, "a": a, "b": c, "bye": r == 0 and (a == "" or c == "")}, r, false, false))
			continue
		v.add_child(_row(shell, ev, b, b.get_match(r, i), r, true, Legends.shows_result(ev, r, i, t)))
	return v


## Who fills slot `k` of round `r` while that round isn't out: the draw for
## round 1, a winner the player has already seen, or "" (to be decided).
static func _feeder(ev: Dictionary, b, r: int, k: int, out: int, t: int) -> String:
	if r == 0:
		return b.slots[k]
	if r == out and Legends.shows_result(ev, r - 1, k, t):
		return b.get_match(r - 1, k).winner
	return ""


## One match on one line: seed, icon and name each side, the score between.
static func _row(shell, ev: Dictionary, b, m: Dictionary, r: int, played: bool, show: bool) -> Control:
	var line := Kit.hbox(8)
	for k in 2:
		var id: String = m.a if k == 0 else m.b
		var side := Kit.hbox(6, [], BoxContainer.ALIGNMENT_END if k == 0 else BoxContainer.ALIGNMENT_BEGIN)
		side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if id == "":
			side.add_child(Kit.label("Bye" if m.bye else "TBD", 20, Kit.MUTED))
		else:
			var won: bool = show and m.winner == id
			var lost: bool = show and m.winner != id
			var nm := Kit.label("%s %d" % [_name(id), b.seed_of(id)] if k == 0 else "%d %s" % [b.seed_of(id), _name(id)], 20, Kit.MUTED if lost else (GOLD if won else Kit.FG))
			nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			nm.clip_text = true
			nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if k == 0 else HORIZONTAL_ALIGNMENT_LEFT
			var icon := CritterIcon.make(id, 1, 44)
			if k == 0:
				side.add_child(nm)
				side.add_child(icon)
			else:
				side.add_child(icon)
				side.add_child(nm)
		line.add_child(side)
		if k == 0:
			var mid := "vs"
			if show and not m.bye:
				mid = "%d-%d" % [m.wins[0], m.wins[1]]
			elif played and not m.bye:
				mid = "Watch"
			var score := Kit.label(mid, 20, GOLD if played and not show and not m.bye else (Kit.FG if show else Kit.MUTED), HORIZONTAL_ALIGNMENT_CENTER)
			score.custom_minimum_size.x = 76
			line.add_child(score)
	if m.bye or not played:
		return Kit.panel(line, Kit.box(Kit.PANEL, Kit.LINE, 22, 2, 8))
	var card := Kit.card_button(line, func(): _series_sheet(shell, ev, b, r, m.index), GOLD if not show else Kit.LINE, Kit.PANEL, 22, 8)
	shell.mark("match_%d_%d" % [r, m.index], card)
	return card


## The games of one series, each with a Watch button. Opening it counts as
## seeing the result.
static func _series_sheet(shell, ev: Dictionary, b, r: int, i: int) -> void:
	var m: Dictionary = b.get_match(r, i)
	if not Legends.shows_result(ev, r, i, LiveOps.now()):
		# Not seen yet: watch it unspoiled, or just reveal the result.
		var watch := Kit.button("Watch game 1", func(): Legends.mark_seen(ev, r, i); _watch(shell, ev, b, r, m.games[0]), "primary", 26, 84)
		var reveal := Kit.button("Just show the result", func(): Legends.mark_seen(ev, r, i); _series_sheet(shell, ev, b, r, i), "ghost", 24, 76)
		shell.mark("game_0", watch)
		shell.mark("reveal", reveal)
		shell.sheet(Kit.vbox(16, [Kit.caption(b.round_name(r), GOLD),
			Kit.label("%s vs %s" % [_name(m.a), _name(m.b)], 32, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
			Kit.label("First to %d wins goes through." % (Bracket.FINAL_WINS_NEEDED if r == b.rounds - 1 else Bracket.WINS_NEEDED), 22, Kit.MUTED),
			watch, reveal]))
		return
	shell.refresh() # Show the result behind the sheet.
	var v := Kit.vbox(14, [Kit.caption(b.round_name(r), GOLD),
		Kit.label("%s %d - %d %s" % [_name(m.a), m.wins[0], m.wins[1], _name(m.b)], 32, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
		Kit.label("%s goes through." % _name(m.winner), 24, GOLD)])
	for g in m.games.size():
		var game: Dictionary = m.games[g]
		var res := "Draw, replayed" if game.winner == "" else "%s wins in %ds" % [_name(game.winner), roundi(game.time)]
		var info := Kit.vbox(2, [Kit.label("Game %d" % (g + 1), 24), Kit.label(res, 20, Kit.MUTED)])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var watch := Kit.button("Watch", func(): _watch(shell, ev, b, r, game), "ghost", 22, 64)
		watch.custom_minimum_size.x = 160
		watch.size_flags_horizontal = Control.SIZE_SHRINK_END
		shell.mark("game_%d" % g, watch)
		v.add_child(Kit.hbox(12, [info, watch]))
	shell.sheet(v)


static func _watch(shell, ev: Dictionary, b, r: int, game: Dictionary) -> void:
	shell.close_overlay()
	shell.watch({"p1": game.p1, "p2": game.p2, "seed": game.seed, "angles": game.angles, "pick": -1,
		"board_title": "%s · %s" % [ev.name.replace(" Bracket of Legends", ""), b.round_name(r)], "return_to": "bracket", "return_params": {"round": r}})


# --- Helpers --------------------------------------------------------------------

static func _card(children: Array, border := Kit.LINE, bg := Kit.PANEL) -> Control:
	return Kit.panel(Kit.vbox(10, children), Kit.box(bg, border, 30, 2, 18))


static func _name(id: String) -> String:
	return BallDefs.get_def(id).display_name if BallDefs.DEFS.has(id) else id


## "Friday 23 Oct".
static func _date(t: int) -> String:
	var d := Time.get_date_dict_from_unix_time(t)
	var months := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %d %s" % [WEEKDAYS[LiveOps._weekday(t)], d.day, months[d.month - 1]]


## The bracket tile on the This Week board, built with WeekScreen.tile.
static func board_card(shell, t: int, tile: Callable) -> Control:
	var ev := Legends.current(t)
	if ev.is_empty():
		return null
	var b := Legends.bracket(ev)
	var phase := Legends.phase(ev, t)
	var pick := Legends.pick_of(ev)
	var text := ""
	var button := "Open"
	match phase:
		"picks":
			text = "Picks lock in %s." % LiveOps.countdown(t, Legends.locks(ev))
			button = "Change pick" if pick != "" else "Pick"
		"live":
			text = "%s out today." % b.round_name(Legends.rounds_out(ev, t) - 1)
			button = "Watch"
		"done":
			text = "Champion: %s." % _name(b.champion()) if Legends.champion_known(ev, t) else "The final is out."
			button = "See the final" if not Legends.champion_known(ev, t) else button
	if pick != "" and phase != "done":
		text += " Yours: %s." % _name(pick)
	var icons := Kit.hbox(-22)
	for id in b.draw.slice(0, 4):
		icons.add_child(CritterIcon.make(id, 1, 64))
	var go := Kit.button(button, func(): shell.go("bracket"), "primary", 22, 64)
	shell.mark("week_bracket", go)
	var words := Kit.label(text, 20, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
	words.max_lines_visible = 2
	words.custom_minimum_size.x = 200
	return tile.call("Bracket", GOLD, Color("7a5a12"), Color("1f1806"), [icons, words], go,
		Kit.chip({"picks": "Picks", "live": "Live", "done": "Final"}[phase], GOLD, 16))
