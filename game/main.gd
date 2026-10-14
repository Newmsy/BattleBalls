## Game flow: pick balls -> aim -> watch the fight -> result.
## URL params on the web build skip straight to a fight, e.g.
## ?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2
## Share links (see fight_link.gd) open a replay (?r=) or a challenge (?c=).
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const ArenaView := preload("res://game/arena_view.gd")
const FightLink := preload("res://game/fight_link.gd")
const Sfx := preload("res://game/audio/sfx.gd")

enum State { MENU, AIM, FIGHT, RESULT }
## NORMAL: pick both balls. REPLAY: watching a shared fight. CHALLENGE: beating
## a friend's ball and shot.
enum Mode { NORMAL, REPLAY, CHALLENGE }

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const ACCENT := Color("8f7bff")
const MUTED := Color("a29fc9")

const VERSION := "0.2.0"
const ARENA_PIXELS := 680.0
const INFO_HEIGHT := 100.0
const CONTROLS_HEIGHT := 490.0 ## Tallest control panel (the menu).
const SPEEDS := [1.0, 2.0, 4.0, 0.5]
const OPPONENT_RANDOM := "random"

var state := State.MENU
var mode := Mode.NORMAL
var sim: MatchSim
var player_type := "vampire"
var opponent_choice := OPPONENT_RANDOM
var opponent_type := "laser"
var seed_value := 1
var aim := -450 ## Player launch angle, tenths of a degree.
var foe_aim = null ## Opponent launch angle, or null to let the seed pick it.
var link_error := ""
var speed_index := 0
var auto_start := false

var _accumulator := 0.0
var _dragging := false
var _rng := RandomNumberGenerator.new() ## UI-only randomness (new seeds), never used by the sim.

var arena: ArenaView
var sfx: Sfx
var ui: Control
var title_label: Label
var hud_label: Label
var info_label: Label
var stamp_label: Label
var menu_box: VBoxContainer
var player_buttons := {}
var opponent_buttons := {}
var seed_label: Label
var fight_box: HBoxContainer
var speed_button: Button
var aim_box: HBoxContainer
var result_box: VBoxContainer
var result_label: Label
var report_label: Label
var new_seed_button: Button
var again_button: Button
var share_button: Button
var challenge_button: Button
var report_row: HBoxContainer
var _share_pending := false


func _ready() -> void:
	_rng.randomize()
	seed_value = _rng.randi_range(1, 99999)
	_read_url_params()
	arena = ArenaView.new()
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_install_share_listener()
	print("BOOT_OK build=", _build_stamp())
	if auto_start:
		_start_fight()
	else:
		_show_menu()
	if link_error != "":
		info_label.text = link_error


func _process(delta: float) -> void:
	if state == State.FIGHT:
		_accumulator += delta * SPEEDS[speed_index]
		# Cap catch-up so a slow frame can't freeze the page.
		var steps := 0
		while _accumulator >= MatchSim.DT and steps < 32 and not sim.finished:
			sim.step()
			arena.consume_events(sim.events)
			sfx.consume_events(sim.events, sim)
			_accumulator -= MatchSim.DT
			steps += 1
		if sim.finished:
			_show_result()
	arena.advance_effects(delta * (SPEEDS[speed_index] if state == State.FIGHT else 1.0))
	if _share_pending:
		_poll_share_status()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if state != State.AIM:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_aim_towards(event.position)
		elif _dragging:
			_dragging = false
			_aim_towards(event.position)
			_launch()
	elif event is InputEventMouseMotion and _dragging:
		_aim_towards(event.position)


func _aim_towards(screen_pos: Vector2) -> void:
	var dir := arena.to_world(screen_pos) - sim.balls[0].pos
	if dir.length() < 10.0:
		return
	aim = roundi(rad_to_deg(dir.angle()) * 10.0)
	sfx.on_aim_drag(dir.length() / 600.0)
	_set_aim_preview()


func _set_aim_preview() -> void:
	sim = MatchSim.new(_config())
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))


# --- Flow -------------------------------------------------------------------

func _config() -> Dictionary:
	return {"seed": seed_value, "p1": player_type, "p2": opponent_type, "angles": [aim, foe_aim]}


func _show_menu() -> void:
	state = State.MENU
	sim = null
	arena.sim = null
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	sfx.on_menu()
	_refresh_menu()
	_show_only(menu_box)


func _refresh_menu() -> void:
	for id in player_buttons:
		player_buttons[id].button_pressed = id == player_type
	for id in opponent_buttons:
		opponent_buttons[id].button_pressed = id == opponent_choice
		opponent_buttons[id].disabled = mode == Mode.CHALLENGE
	new_seed_button.disabled = mode == Mode.CHALLENGE
	seed_label.text = "Seed %d" % seed_value
	var def := BallDefs.get_def(player_type)
	info_label.text = "%s: %s" % [def.display_name, def.description]
	if mode == Mode.CHALLENGE:
		info_label.text = "CHALLENGE! Your friend's %s has its shot lined up. Pick a ball and beat it." % \
			BallDefs.get_def(opponent_type).display_name
	arena.preview_types = [player_type, _pick_opponent()]
	arena.queue_redraw()


func _begin_aim() -> void:
	opponent_type = _pick_opponent()
	state = State.AIM
	aim = MatchSim.AIM_AT_CENTRE[0]
	arena.clear_effects()
	_set_aim_preview()
	info_label.text = "Drag on the arena to aim your %s, then let go to launch." % BallDefs.get_def(player_type).display_name
	_show_only(aim_box)


func _pick_opponent() -> String:
	if opponent_choice != OPPONENT_RANDOM:
		return opponent_choice
	# Derived from the seed so a seed always means the same matchup.
	return BallDefs.PLAYABLE[seed_value % BallDefs.PLAYABLE.size()]


func _launch() -> void:
	sfx.play("launch")
	_start_fight()


## Starts (or replays) the fight described by the current config.
func _start_fight() -> void:
	sim = MatchSim.new(_config())
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	_accumulator = 0.0
	state = State.FIGHT
	info_label.text = "%s vs %s" % [BallDefs.get_def(player_type).display_name, BallDefs.get_def(opponent_type).display_name]
	speed_button.text = "Speed %sx" % _speed_text()
	_show_only(fight_box)
	arena.team_tags = ["P1", "P2"] if mode == Mode.REPLAY else ArenaView.TEAM_TAGS
	if mode == Mode.REPLAY:
		info_label.text = "Shared fight: " + info_label.text
	sfx.on_fight_start(sim)
	print("FIGHT_START ", _report_code())


func _show_result() -> void:
	state = State.RESULT
	var you := sim.balls[0]
	var text := "DRAW"
	if mode == Mode.REPLAY and sim.winner >= 0:
		text = "%s WINS" % sim.balls[sim.winner].def.display_name.to_upper()
	elif sim.winner == 0:
		text = "YOU WIN!"
	elif sim.winner == 1:
		text = "YOU LOSE"
	result_label.text = text
	_label_result_buttons()
	info_label.text = "%.1fs. %s dealt %d damage%s." % [sim.time(), "P1" if mode == Mode.REPLAY else "You",
		roundi(you.damage_dealt), (" and healed %d" % roundi(you.healed)) if you.healed > 0.0 else ""]
	report_label.text = "Report code: " + _report_code()
	print("MATCH_END winner=%d reason=%s ticks=%d hash=%s" % [sim.winner, sim.end_reason, sim.tick, sim.state_hash()])
	_show_only(result_box)
	sfx.on_result(sim.winner)


func _report_code() -> String:
	return "BB1.%s.%s.%d.%d.%s" % [player_type, opponent_type, seed_value, aim, _build_stamp().replace(" ", "")]


# --- UI ---------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = _neon_theme()
	layer.add_child(ui)

	title_label = _label("BATTLE BALLS", 48)
	title_label.add_theme_color_override("font_outline_color", Color(ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	hud_label = _label("", 30)
	info_label = _label("", 26)
	info_label.add_theme_color_override("font_color", MUTED)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stamp_label = _label(_build_stamp(), 18)
	stamp_label.modulate = Color(1, 1, 1, 0.45)
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 14)
	menu_box.add_child(_label("Your ball", 26))
	menu_box.add_child(_choice_row(BallDefs.PLAYABLE, player_buttons, func(id): player_type = id; _refresh_menu()))
	menu_box.add_child(_label("Opponent", 26))
	menu_box.add_child(_choice_row(BallDefs.PLAYABLE + [OPPONENT_RANDOM], opponent_buttons, func(id): opponent_choice = id; _refresh_menu()))
	var seed_row := HBoxContainer.new()
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seed_row.add_theme_constant_override("separation", 20)
	seed_label = _label("", 26)
	seed_row.add_child(seed_label)
	new_seed_button = _button("New seed", func(): seed_value = _rng.randi_range(1, 99999); _refresh_menu())
	seed_row.add_child(new_seed_button)
	menu_box.add_child(seed_row)
	menu_box.add_child(_button("FIGHT!", _begin_aim, 40))

	aim_box = _row([
		_button("Launch", _launch),
		_button("Back", _show_menu),
	])

	speed_button = _button("Speed 1x", _cycle_speed)
	fight_box = _row([speed_button, _button("Skip to end", _skip_to_end)])

	result_box = VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	result_label = _label("", 56)
	result_box.add_child(result_label)
	report_label = _label("", 20)
	report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(report_label)
	again_button = _button("Rematch", _again)
	result_box.add_child(_row([_button("Replay", func(): _start_fight()), again_button]))
	share_button = _button("Share fight", _share.bind("r"))
	challenge_button = _button("Challenge", _on_challenge_button)
	result_box.add_child(_row([share_button, challenge_button]))
	report_row = _row([
		_button("Copy report", func(): DisplayServer.clipboard_set(_report_code()); report_label.text = "Copied: " + _report_code()),
		_button("Change balls", _play_normal),
	])
	result_box.add_child(report_row)

	for c in [title_label, hud_label, info_label, stamp_label, menu_box, aim_box, fight_box, result_box]:
		ui.add_child(c)


## Portrait stacks arena over controls; wide screens put controls beside the
## arena. Either way the arena shrinks before the controls are pushed off screen.
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var top := 190.0
	var bottom_margin := 50.0
	var panel_width := 680.0
	var landscape := size.x >= size.y
	var side: float
	var left: float
	var panel_pos: Vector2
	if landscape:
		side = minf(size.y - top - bottom_margin, size.x - panel_width - 100.0)
		left = maxf(20.0, (size.x - side - panel_width - 40.0) / 2.0)
		panel_pos = Vector2(left + side + 40.0, top)
	else:
		side = clampf(size.y - top - INFO_HEIGHT - CONTROLS_HEIGHT - bottom_margin, 300.0, minf(ARENA_PIXELS, size.x - 40.0))
		left = (size.x - side) / 2.0
		panel_width = maxf(side, minf(ARENA_PIXELS, size.x - 40.0))
		panel_pos = Vector2((size.x - panel_width) / 2.0, top + side + 20.0)
	arena.view_scale = side / MatchSim.ARENA_SIZE
	arena.position = Vector2(left, top)
	_place(title_label, Vector2(0, 30), Vector2(size.x, 60))
	_place(hud_label, Vector2(left, 110), Vector2(side, 50))
	_place(info_label, panel_pos, Vector2(panel_width, 90))
	var controls_top := panel_pos.y + INFO_HEIGHT
	for box in [menu_box, aim_box, fight_box, result_box]:
		_place(box, Vector2(panel_pos.x, controls_top), Vector2(panel_width, maxf(CONTROLS_HEIGHT, size.y - controls_top - bottom_margin)))
	_place(stamp_label, Vector2(12, size.y - 34), Vector2(size.x, 30))
	arena.queue_redraw()
	_sync_share_targets()


## Dark panels with a purple accent, matching the Neon Critters arena.
func _neon_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 30
	theme.set_color("font_color", "Label", Color("f0eeff"))
	var states := {
		"normal": [Color("1b1842"), Color("2b2760")],
		"hover": [Color("241f55"), Color("3a3480")],
		"pressed": [ACCENT, ACCENT],
		"hover_pressed": [ACCENT.lightened(0.1), ACCENT.lightened(0.1)],
		"focus": [Color(0, 0, 0, 0), Color(0, 0, 0, 0)],
	}
	for state in states:
		var box := StyleBoxFlat.new()
		box.bg_color = states[state][0]
		box.border_color = states[state][1]
		box.set_border_width_all(2)
		box.set_corner_radius_all(22)
		theme.set_stylebox(state, "Button", box)
	theme.set_color("font_color", "Button", Color("f0eeff"))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color("0b0a1f"))
	theme.set_color("font_hover_pressed_color", "Button", Color("0b0a1f"))
	theme.set_color("font_focus_color", "Button", Color("f0eeff"))
	return theme


func _place(c: Control, pos: Vector2, size: Vector2) -> void:
	c.position = pos
	c.size = size


func _show_only(box: Control) -> void:
	for b in [menu_box, aim_box, fight_box, result_box]:
		b.visible = b == box
	_sync_share_targets()


func _update_hud() -> void:
	if sim == null:
		hud_label.text = ""
		return
	var a := sim.balls[0]
	var b := sim.balls[1]
	var clock := "%.0fs" % sim.time()
	if sim.in_overtime():
		clock = "OVERTIME x%.1f" % sim.damage_multiplier()
	var tags: Array = ["P1", "P2"] if mode == Mode.REPLAY else ["You", "Foe"]
	hud_label.text = "%s %d   |   %s   |   %d %s" % [tags[0], maxi(0, ceili(a.hp)), clock, maxi(0, ceili(b.hp)), tags[1]]


func _cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()
	speed_button.text = "Speed %sx" % _speed_text()


func _speed_text() -> String:
	var v: float = SPEEDS[speed_index]
	return str(int(v)) if v == floorf(v) else str(v)


func _skip_to_end() -> void:
	while not sim.finished:
		sim.step()
	arena.clear_effects()


func _again() -> void:
	match mode:
		Mode.NORMAL:
			seed_value = _rng.randi_range(1, 99999)
			_begin_aim()
		Mode.CHALLENGE:
			_begin_aim()
		Mode.REPLAY:
			_take_challenge(player_type, seed_value, sim.launch_angles[0])


func _on_challenge_button() -> void:
	if mode == Mode.REPLAY:
		_play_normal()
	else:
		_share("c")


func _label_result_buttons() -> void:
	again_button.text = {Mode.NORMAL: "Rematch", Mode.CHALLENGE: "Try again", Mode.REPLAY: "Beat this shot"}[mode]
	challenge_button.text = "Play my own" if mode == Mode.REPLAY else "Challenge friend"
	share_button.text = "Send result" if mode == Mode.CHALLENGE else "Share fight"
	report_row.visible = mode != Mode.REPLAY


## Fight the given ball and shot from the opponent corner, on the same seed.
func _take_challenge(ball: String, challenge_seed: int, challenge_aim: int) -> void:
	mode = Mode.CHALLENGE
	opponent_choice = ball
	opponent_type = ball
	seed_value = challenge_seed
	foe_aim = FightLink.mirror_angle(challenge_aim)
	_show_menu()


## Back to picking both balls, dropping any link the page was opened with.
func _play_normal() -> void:
	if mode != Mode.NORMAL:
		opponent_choice = OPPONENT_RANDOM
	mode = Mode.NORMAL
	foe_aim = null
	if OS.has_feature("web"):
		JavaScriptBridge.eval("history.replaceState(null, '', location.pathname)")
	_show_menu()


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable, font_size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(on_press)
	return b


func _row(children: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for c in children:
		row.add_child(c)
	return row


func _choice_row(ids: Array, store: Dictionary, on_pick: Callable) -> HBoxContainer:
	var group := ButtonGroup.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for id in ids:
		var label: String = "Random" if id == OPPONENT_RANDOM else BallDefs.get_def(id).display_name
		var b := _button(label, on_pick.bind(id))
		b.toggle_mode = true
		b.button_group = group
		store[id] = b
		row.add_child(b)
	return row


# --- Share links -------------------------------------------------------------
# Browsers only let a page share or copy inside the user's own tap, and Godot
# handles taps a frame later. So the page itself watches taps on the share
# buttons (window.bbShare.targets, in canvas fractions) and shares from there;
# the Godot button only reports the outcome.

const SHARE_JS := """
if (!window.bbShare) {
	window.bbShare = { targets: [], status: "" };
	const done = (s) => { window.bbShare.status = s; };
	const copy = (t) => {
		const ask = () => { window.prompt("Copy this link:", t.url); done("shown"); };
		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard.writeText(t.text + " " + t.url).then(() => done("copied"), ask);
		} else {
			ask();
		}
	};
	window.addEventListener("pointerup", (e) => {
		const canvas = document.querySelector("canvas");
		if (!canvas) return;
		const r = canvas.getBoundingClientRect();
		const x = (e.clientX - r.left) / r.width, y = (e.clientY - r.top) / r.height;
		for (const t of window.bbShare.targets) {
			if (x < t.x || x > t.x + t.w || y < t.y || y > t.y + t.h) continue;
			console.log("SHARE " + t.kind + " " + t.url);
			done("pending");
			if (navigator.share) {
				navigator.share({ title: "Battle Balls", text: t.text, url: t.url })
					.then(() => done("shared"), (err) => err && err.name === "AbortError" ? done("cancelled") : copy(t));
			} else {
				copy(t);
			}
			return;
		}
	}, true);
}
"""


func _install_share_listener() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(SHARE_JS, true)


func _share_url(kind: String) -> String:
	var base := FightLink.HOME
	if OS.has_feature("web"):
		base = str(JavaScriptBridge.eval("location.origin + location.pathname", true))
	var angles := sim.launch_angles
	var code := FightLink.challenge_code(player_type, seed_value, angles[0]) if kind == "c" \
		else FightLink.replay_code(player_type, opponent_type, seed_value, angles[0], angles[1])
	return FightLink.url(base, kind, code)


func _share_text(kind: String) -> String:
	var mine: String = BallDefs.get_def(player_type).display_name
	var theirs: String = BallDefs.get_def(opponent_type).display_name
	if kind == "c":
		return "Can your ball beat my %s's shot in Battle Balls?" % mine
	if mode == Mode.CHALLENGE:
		return ("I beat your %s challenge with my %s!" if sim.winner == 0 else "Your %s beat my %s. Watch:") % [theirs, mine]
	return "Watch %s vs %s in Battle Balls!" % [mine, theirs]


## Tells the page where the share buttons are, once their layout has settled.
func _sync_share_targets() -> void:
	if not OS.has_feature("web"):
		return
	await get_tree().process_frame
	var targets := []
	if state == State.RESULT and result_box.visible and sim != null:
		var buttons := {"r": share_button}
		if mode != Mode.REPLAY:
			buttons["c"] = challenge_button
		var view := get_viewport().get_visible_rect().size
		for kind in buttons:
			var r: Rect2 = buttons[kind].get_global_rect()
			targets.append({"kind": kind, "url": _share_url(kind), "text": _share_text(kind),
				"x": r.position.x / view.x, "y": r.position.y / view.y, "w": r.size.x / view.x, "h": r.size.y / view.y})
	JavaScriptBridge.eval("window.bbShare && (window.bbShare.targets = %s)" % JSON.stringify(targets), true)


func _share(kind: String) -> void:
	if OS.has_feature("web"):
		# The page already started sharing on this tap; just watch how it went.
		_share_pending = true
		return
	DisplayServer.clipboard_set(_share_url(kind))
	report_label.text = "Link copied: " + _share_url(kind)


func _poll_share_status() -> void:
	var status := str(JavaScriptBridge.eval("window.bbShare ? window.bbShare.status : ''", true))
	var messages := {"shared": "Shared!", "copied": "Link copied. Paste it to a friend!", "shown": "", "cancelled": ""}
	if status in messages:
		_share_pending = false
		JavaScriptBridge.eval("window.bbShare.status = ''", true)
		if messages[status] != "":
			report_label.text = messages[status]


# --- Build info and URL params ---------------------------------------------

func _build_stamp() -> String:
	var commit := "dev"
	if FileAccess.file_exists("res://build_info.txt"):
		commit = FileAccess.get_file_as_string("res://build_info.txt").strip_edges()
	return "v%s %s" % [VERSION, commit]


func _read_url_params() -> void:
	if not OS.has_feature("web"):
		return
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	var params := {}
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	if params.get("p1", "") in BallDefs.PLAYABLE:
		player_type = params.p1
	if params.get("p2", "") in BallDefs.PLAYABLE:
		opponent_choice = params.p2
		opponent_type = params.p2
	if params.has("seed") and params.seed.is_valid_int():
		seed_value = int(params.seed)
	if params.has("aim") and params.aim.is_valid_int():
		aim = int(params.aim)
	if params.has("speed"):
		var i := SPEEDS.find(float(params.speed))
		speed_index = maxi(0, i)
	auto_start = params.get("auto", "") == "1"
	if params.has("r"):
		var r := FightLink.parse_replay(params.r)
		if r.is_empty():
			link_error = "That fight link didn't work. Pick your balls and play!"
		else:
			mode = Mode.REPLAY
			player_type = r.p1
			opponent_choice = r.p2
			opponent_type = r.p2
			seed_value = r.seed
			aim = r.angles[0]
			foe_aim = r.angles[1]
			auto_start = true
	elif params.has("c"):
		var c := FightLink.parse_challenge(params.c)
		if c.is_empty():
			link_error = "That challenge link didn't work. Pick your balls and play!"
		else:
			mode = Mode.CHALLENGE
			opponent_choice = c.ball
			opponent_type = c.ball
			seed_value = c.seed
			foe_aim = FightLink.mirror_angle(c.aim)
			auto_start = false
	if auto_start and opponent_choice == OPPONENT_RANDOM:
		opponent_type = _pick_opponent()
