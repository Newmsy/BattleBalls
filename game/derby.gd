## Bounce Derby: pick the critter you think wins today's marble race, then
## watch and cheer. No combat and nothing to stake: picking is free, a
## correct call earns Derby Stars (earned only, never sold), and the race is
## the same for everyone on the same day, so a Discord watch party can all
## call it together. Events (a holiday theme, a pinned line-up) come from
## liveops.json's `derbies` (see liveops/README.md).
##
## URL params: ?mode=derby&day=12 (an earlier day's race), &race=123 (a
## practice race, as in a shared link), &pick=2&auto=1 (call racer 2 and
## start), &speed=4 (watch faster), &today=YYYY-MM-DD (pin the date).
extends Node2D

const Derby := preload("res://sim/derby.gd")
const DerbyView := preload("res://game/derby_view.gd")
const LiveOps := preload("res://game/liveops.gd")
const Roster := preload("res://game/ui/roster.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const A11y := preload("res://game/a11y.gd")
const Sfx := preload("res://game/audio/sfx.gd")

enum State { PICK, RACE, RESULT }

const SAVE_PATH := "user://derby.cfg"
const SHARE_URL := "https://battleballs.vercel.app/?mode=derby"
const STARS_FOR_PICK := 1 ## Calling the daily race at all.
const STARS_FOR_WIN := 5 ## Calling it right.
const PLACE_MEDALS := ["🥇", "🥈", "🥉"] ## Share text only: the game font has no emoji.
const TOP := 200.0 ## Title, caption and standings sit above the course.

var state := State.PICK
var race: Dictionary ## LiveOps.derby() for the day, or a practice race.
var practice := false
var sim: Derby
var pick := -1
var speed := 1.0
var stats := {"played": 0, "correct": 0, "stars": 0, "last_day": 0, "days_in_row": 0}
var today := 1

var _accumulator := 0.0
var _auto := false
var _save := ConfigFile.new()
var _cheers := 0
var _last_order: Array[int] = []

var view: DerbyView
var frame: Control
var sfx: Sfx
var title_label: Label
var caption_label: Label
var info_label: Label
var standings: HBoxContainer
var panel: VBoxContainer


func _ready() -> void:
	var params := _url_params()
	if LiveOps.date_unix(params.get("today", "")) >= 0:
		LiveOps.now_override = LiveOps.date_unix(params.today) + 12 * 3600
	var now := LiveOps.now()
	today = LiveOps.derby(now).number
	race = LiveOps.derby(now)
	if params.get("day", "").is_valid_int() and int(params.day) >= 1 and int(params.day) < today:
		race = LiveOps.derby(LiveOps.DERBY_EPOCH + (int(params.day) - 1) * LiveOps.DAY)
	if params.get("race", "").is_valid_int():
		_use_practice(int(params.race))
	if params.get("speed", "").is_valid_float():
		speed = clampf(float(params.speed), 0.25, 8.0)
	_load()
	sfx = Sfx.new()
	add_child(sfx)
	# The course is clipped to its frame so pegs never draw over the UI.
	frame = Control.new()
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	view = DerbyView.new()
	view.theme_id = race.theme
	frame.add_child(view)
	_build_ui()
	if is_inside_tree():
		get_viewport().size_changed.connect(_layout)
	_new_sim()
	print("DERBY_READY number=%d seed=%d practice=%s racers=%s" % [race.number, race.seed, practice, ",".join(race.racers)])
	var saved := _saved_day()
	if params.get("pick", "").is_valid_int() and int(params.pick) >= 0 and int(params.pick) < race.racers.size() and saved.is_empty():
		pick = int(params.pick)
	elif not saved.is_empty():
		pick = int(saved.pick)
	_auto = params.get("auto", "") == "1" and pick >= 0
	_show_pick()
	if _auto:
		_start.call_deferred()


func _use_practice(seed_value: int) -> void:
	practice = true
	race = race.duplicate()
	race.seed = seed_value
	race.racers = Derby.draw_racers(seed_value)
	race.title = "Practice race"
	race.event = false


func _new_sim() -> void:
	sim = Derby.new({"seed": race.seed, "racers": race.racers})
	view.set_sim(sim)
	view.pick = pick


func _process(delta: float) -> void:
	if state == State.RACE:
		_accumulator += delta * speed
		var steps := 0
		while _accumulator >= Derby.DT and steps < 64 and not sim.finished:
			_accumulator -= Derby.DT
			steps += 1
			sim.step()
			view.consume_events(sim.events)
			_sounds(sim.events)
		_refresh_standings()
		if sim.finished:
			_finish()
	view.advance(delta)


func _unhandled_input(event: InputEvent) -> void:
	# Tapping the course cheers too.
	if state == State.RACE and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cheer()


func _sounds(events: Array) -> void:
	for e in events:
		match e.type:
			"bumper":
				sfx.play("hit", -6.0, 1.3)
			"peg":
				sfx.play("wall", 0.0, 1.4)
			"bump":
				sfx.play("hit", -10.0, 1.1)
			"trick":
				sfx.play("zap" if e.trick == "phase" else "launch", -4.0, 1.2)
			"finish":
				if e.place == 1:
					sfx.play("ko")


# --- Flow ---------------------------------------------------------------------

func _show_pick() -> void:
	state = State.PICK
	title_label.text = race.title.to_upper() if race.event or practice else "BOUNCE DERBY #%d" % race.number
	caption_label.text = "Seed %d" % race.seed if practice else ("Derby #%d · %s" % [race.number, race.date] if race.event else "Same race for everyone today")
	if race.number < today and not practice:
		caption_label.text = "Derby #%d · %s" % [race.number, race.date]
	_new_sim()
	view.follow = "leader"
	var locked := not practice and not _saved_day().is_empty()
	if practice:
		info_label.text = "Practice race: just for fun, no stars."
	elif locked:
		info_label.text = "You called %s for today. Watch it again, or try a practice race." % _name(pick)
	elif race.number < today:
		info_label.text = "An earlier day's race. Calls only count on the day."
	else:
		info_label.text = race.blurb if race.blurb != "" else "Six critters, one bouncy course. Pick who you think wins, then cheer them home."
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for i in race.racers.size():
		grid.add_child(_racer_card(i, locked))
	var go := Kit.button("Start the race" if not locked else "Watch again", _start, "go", 32, 90)
	go.disabled = pick < 0
	go.name = "Go"
	_set_panel([grid, go, Kit.button("Back", _go_menu, "ghost", 26, 72)])
	_layout()


func _racer_card(i: int, locked: bool) -> Control:
	var id: String = race.racers[i]
	var c := Roster.get_critter(id)
	var trick := Derby.trick_of(id)
	var picked := i == pick
	var col := Kit.vbox(2, [CritterIcon.make(id, 1, 84), Kit.label(c.name, 22, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("✓ PICKED" if picked else Derby.TRICK_NAMES[trick], 18, DerbyView.PICK_COLOR if picked else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for child in col.get_children():
		child.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var card := Kit.card_button(col, func():
		if locked:
			return
		pick = i
		view.pick = i
		_show_pick(), DerbyView.PICK_COLOR if picked else Kit.LINE, Kit.PANEL2 if picked else Kit.PANEL, 24, 6)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.tooltip_text = Derby.TRICK_TEXT[trick]
	return card


func _start() -> void:
	if pick < 0:
		return
	state = State.RACE
	_new_sim()
	_accumulator = 0.0
	_cheers = 0
	view.follow = "leader"
	info_label.text = "Go %s! Tap anywhere to cheer." % _name(pick)
	var follow := Kit.button("Follow: leader", func(): pass, "ghost", 24, 76)
	follow.pressed.connect(func():
		view.follow = "pick" if view.follow == "leader" else "leader"
		follow.text = ("Follow: %s" % ("your pick" if view.follow == "pick" else "leader")).to_upper())
	_set_panel([Kit.button("Cheer!", _cheer, "go", 34, 96), Kit.hbox(12, [follow, Kit.button("Skip", _skip, "ghost", 24, 76)])])
	_layout()
	sfx.play("go")
	sfx.play_music("fight")
	print("DERBY_START number=%d pick=%d (%s) practice=%s" % [race.number, pick, race.racers[pick], practice])


func _cheer() -> void:
	if state != State.RACE:
		return
	_cheers += 1
	view.cheer()
	sfx.play("click", 0.0, 1.5)


func _skip() -> void:
	while not sim.finished:
		sim.step()
	_finish()


func _finish() -> void:
	if state != State.RACE:
		return
	state = State.RESULT
	_refresh_standings()
	var winner := sim.winner()
	var correct := winner == pick
	var counts: bool = not practice and race.number == today and _saved_day().is_empty()
	var earned := 0
	if counts:
		earned = STARS_FOR_PICK + (STARS_FOR_WIN if correct else 0)
		_record(correct, earned)
	print("DERBY_RESULT number=%d winner=%d (%s) pick=%d correct=%s counted=%s time=%.1f cheers=%d" % [
		race.number, winner, race.racers[winner], pick, correct, counts, sim.run().win_time, _cheers])
	sfx.on_result(0 if correct else 1)
	var place: int = sim.racers[pick].place
	var head := Kit.label("You called it!" if correct else "%s wins!" % _name(winner), 44, Color("ffd36b") if correct else Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	var podium := []
	for k in mini(3, sim.order.size()):
		podium.append("%s %s" % [_ordinal(k + 1), _name(sim.order[k])])
	info_label.text = "   ".join(podium)
	var line := "%s finished %s." % [_name(pick), _ordinal(place)] if not correct else "%s crossed the line first." % _name(pick)
	if counts:
		line += " +%d Derby Stars (%d total)." % [earned, stats.stars]
	elif not practice and race.number == today:
		line += " Today's call was already counted."
	var share := Kit.button("Share", func(): pass, "primary", 26, 80)
	share.pressed.connect(func(): share.text = _share().to_upper())
	var again := Kit.button("Watch again", _show_pick, "ghost", 26, 80)
	var practice_btn := Kit.button("Practice race", func():
		_use_practice(randi_range(1, 999999))
		pick = -1
		print("DERBY_READY number=%d seed=%d practice=true racers=%s" % [race.number, race.seed, ",".join(race.racers)])
		_show_pick(), "ghost", 26, 80)
	_set_panel([head, Kit.label(line, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true), Kit.hbox(12, [share, again]),
		Kit.hbox(12, [practice_btn, Kit.button("Back", _go_menu, "ghost", 26, 80)])])
	_layout()


func _go_menu() -> void:
	get_tree().change_scene_to_file("res://game/main.tscn")


# --- Saving -------------------------------------------------------------------

func _saved_day() -> Dictionary:
	return _save.get_value("days", str(race.number), {}) if not practice else {}


func _record(correct: bool, earned: int) -> void:
	stats.played += 1
	if correct:
		stats.correct += 1
	stats.stars += earned
	stats.days_in_row = stats.days_in_row + 1 if stats.last_day == today - 1 else 1
	stats.last_day = today
	_save.set_value("days", str(race.number), {"pick": pick, "winner": sim.winner()})
	for key in stats:
		_save.set_value("stats", key, stats[key])
	_save.save(SAVE_PATH)


func _load() -> void:
	if _save.load(SAVE_PATH) != OK:
		return
	for key in stats:
		stats[key] = _save.get_value("stats", key, stats[key])


## Stars and calls so far, for the Play tab card.
static func load_stats() -> Dictionary:
	var cfg := ConfigFile.new()
	var out := {"stars": 0, "correct": 0, "picked_today": false}
	if cfg.load(SAVE_PATH) == OK:
		out.stars = cfg.get_value("stats", "stars", 0)
		out.correct = cfg.get_value("stats", "correct", 0)
		out.picked_today = cfg.has_section_key("days", str(LiveOps.derby(LiveOps.now()).number))
	return out


func share_text() -> String:
	var winner := sim.winner()
	var place: int = sim.racers[pick].place
	var medal: String = PLACE_MEDALS[place - 1] if place <= 3 else "🏁"
	var link := SHARE_URL + ("&race=%d" % race.seed if practice else "&day=%d" % race.number)
	var called := "called it!" if winner == pick else "%s won" % _name(winner)
	return "Bounce Derby %s\nI picked %s %s %s\n%s" % ["practice" if practice else "#%d" % race.number, _name(pick), medal, called, link]


func _share() -> String:
	var text := share_text()
	if OS.has_feature("web"):
		var how = JavaScriptBridge.eval("""(function (t) {
			if (navigator.share) { navigator.share({ text: t }).catch(function () { navigator.clipboard && navigator.clipboard.writeText(t); }); return 'share'; }
			if (navigator.clipboard) { navigator.clipboard.writeText(t); return 'copy'; }
			return '';
		})(%s)""" % JSON.stringify(text), true)
		if how == "share":
			return "Shared!"
		if how == "copy":
			return "Copied!"
	DisplayServer.clipboard_set(text)
	return "Copied!"


# --- UI -----------------------------------------------------------------------

func _name(i: int) -> String:
	return Roster.get_critter(race.racers[i]).name


static func _ordinal(n: int) -> String:
	return str(n) + ("st" if n == 1 else "nd" if n == 2 else "rd" if n == 3 else "th")


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = Kit.theme()
	layer.add_child(ui)
	title_label = Kit.label("", 44, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_color_override("font_outline_color", Color(Kit.ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	caption_label = Kit.label("", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	standings = Kit.hbox(6, [], BoxContainer.ALIGNMENT_CENTER)
	info_label = Kit.label("", 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	panel = Kit.vbox(12)
	for c in [title_label, caption_label, standings, info_label, panel]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE if c is Label else c.mouse_filter
		ui.add_child(c)


## Live order: one icon per racer, place number above, your pick marked.
func _refresh_standings(force := false) -> void:
	var order := sim.standings()
	if order == _last_order and not force:
		return
	_last_order = order
	for c in standings.get_children():
		standings.remove_child(c)
		c.queue_free()
	for k in order.size():
		var i: int = order[k]
		var tag := Kit.label(("%d" % (k + 1)) + (" PICK" if i == pick else ""), 16, DerbyView.PICK_COLOR if i == pick else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		standings.add_child(Kit.vbox(0, [tag, CritterIcon.make(race.racers[i], 1, 56)]))


## Portrait: course over the panel. Wide: course on the left, panel beside it.
func _layout() -> void:
	# Outside the tree (tests) lay out for the 720x1280 design size.
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(720, 1280)
	var panel_h := panel.get_combined_minimum_size().y
	var vw: float
	var vh: float
	var left: float
	var panel_pos: Vector2
	var panel_w: float
	if size.x >= size.y:
		vh = size.y - TOP - 30.0
		vw = minf(vh * 0.75, size.x - 700.0)
		left = maxf(20.0, (size.x - vw - 660.0) / 2.0)
		panel_w = 620.0
		panel_pos = Vector2(left + vw + 30.0, TOP + 110.0)
	else:
		panel_w = minf(680.0, size.x - 40.0)
		vw = panel_w
		vh = maxf(260.0, size.y - TOP - panel_h - 110.0 - 90.0)
		left = (size.x - vw) / 2.0
		panel_pos = Vector2((size.x - panel_w) / 2.0, TOP + vh + 110.0)
	frame.position = Vector2(left, TOP)
	frame.size = Vector2(vw, vh)
	view.view_size = Vector2(vw, vh)
	view.view_scale = vw / Derby.WIDTH
	_place(title_label, Vector2(0, 20), Vector2(size.x, 56))
	_place(caption_label, Vector2(0, 76), Vector2(size.x, 30))
	_place(standings, Vector2(left, 112), Vector2(vw, 84))
	_place(info_label, panel_pos - Vector2(0, 100), Vector2(panel_w, 90))
	_place(panel, panel_pos, Vector2(panel_w, panel_h))
	_refresh_standings(true)
	view.queue_redraw()


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _set_panel(children: Array) -> void:
	for c in panel.get_children():
		panel.remove_child(c)
		c.queue_free()
	for c in children:
		panel.add_child(c)
	# Minimum sizes settle a frame later; lay out again then.
	_layout.call_deferred()


func _url_params() -> Dictionary:
	var params := {}
	if not OS.has_feature("web"):
		return params
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	return params
