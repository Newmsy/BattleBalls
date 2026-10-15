## Game flow: pick balls -> aim -> watch the fight -> result.
## URL params on the web build skip straight to a fight, e.g.
## ?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2
## Share links (see fight_link.gd) open a replay (?r=) or a challenge (?c=).
## ?pve=1-3 plays campaign stage 1-3 on a fresh, unsaved profile (with auto=1, unaimed).
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const ArenaView := preload("res://game/arena_view.gd")
const Backend := preload("res://game/online/backend.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const FightLink := preload("res://game/fight_link.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const A11y := preload("res://game/a11y.gd")
const Shell := preload("res://game/ui/shell.gd")
const LiveOps := preload("res://game/liveops.gd")
const Loaner := preload("res://game/loaner.gd")
const Friends := preload("res://game/online/friends.gd")
const Profile := preload("res://meta/profile.gd")
const Campaign := preload("res://meta/campaign.gd")
const Zones := preload("res://meta/zones.gd")
const CampaignScreen := preload("res://game/ui/screens/campaign_screen.gd")
const Account := preload("res://game/online/account.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const ResultText := preload("res://game/result_text.gd")

enum State { MENU, AIM, FIGHT, RESULT }
## NORMAL: pick your ball, the opponent is random. REPLAY: watching a shared fight. CHALLENGE: beating
## a friend's ball and shot. RIVAL: an unranked rematch against a friend's
## saved team (their Ghost Arena lineup, aimed the way they usually aim).
## CAMPAIGN: a campaign stage (energy already spent).
enum Mode { NORMAL, REPLAY, CHALLENGE, RIVAL, CAMPAIGN }

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const ACCENT := Color("8f7bff")
const MUTED := Color("a29fc9")

const VERSION := "0.2.0"
const ARENA_PIXELS := 680.0
const INFO_HEIGHT := 100.0
const CONTROLS_HEIGHT := 490.0 ## Tallest control panel (the menu).
const SPEEDS := [1.0, 2.0, 4.0, 0.5]
const OPPONENT_RANDOM := "random"
const PICK_COLUMNS := 3
const PICK_TILE_HEIGHT := 112.0
const PICK_ROWS_SHOWN := 2 ## More rows than this scroll.

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
var url_picks := false ## URL params chose the balls: don't overwrite them from the save.

var backend: Backend
var save := SaveGame.new()
var account_text := "" ## Guest name and trophies once signed in.
var friends: Friends
var account: Account
var _retry_timer: Timer ## Retries the cloud save while it has unsynced changes.
var rival := {} ## The friend entry a RIVAL fight is against.
var link_friend := "" ## Friend code from the link the page was opened with (&f=).
var _count_fight := false ## The running fight came from the menu, not a replay or URL.

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
var pick_scroll: ScrollContainer
var fight_button: Button
var launch_button: Button
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
var friend_row: HBoxContainer
var friend_button: Button
var _share_pending := false
var shell_layer: CanvasLayer ## Home screen and menus (game/ui), drawn over the arena.
var shell: Shell
var _board_pick := -1 ## The side the player called for the Fight of the Day being watched, or -1.
var campaign_row: HBoxContainer
## The player's collection, energy and campaign progress, kept in save.data.profile.
var profile
## The campaign stage being fought: {config, zone, stage, fighter, result?}.
var pve := {}
var pve_param := ""
## ?demo=1 (smoke tests, previews): a filled-in sample profile that is never saved.
var demo_profile := false
var profile_unsaved := false

static var _mode_redirected := false


func _ready() -> void:
	_rng.randomize()
	seed_value = _rng.randi_range(1, 99999)
	backend = Backend.new()
	add_child(backend)
	friends = Friends.new(backend)
	account = Account.new(backend)
	save.app_version = VERSION
	save.load_local()
	_apply_picks()
	# ?mode=trickshot opens Daily Trick Shot, once: its Back button comes here.
	if _read_url_params().get("mode", "") == "trickshot" and not _mode_redirected:
		_mode_redirected = true
		set_process(false)
		get_tree().change_scene_to_file.call_deferred("res://game/trick_shot.tscn")
		return
	_load_profile()
	arena = ArenaView.new()
	add_child(arena)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_install_share_listener()
	print("BOOT_OK build=", _build_stamp())
	_build_shell()
	if pve_param != "":
		_start_url_stage()
	elif auto_start:
		_start_fight()
	else:
		_show_menu()
		# Shared fight links open straight on their menu; everyone else starts at home.
		if mode == Mode.NORMAL and link_error == "":
			_show_home()
			if link_friend != "":
				shell.go("friends")
	friends.changed.connect(func(): if state == State.RESULT: _label_result_buttons())
	if link_friend != "":
		friends.set_invite(link_friend)
	if link_error != "":
		info_label.text = link_error
	_go_online()


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
	if mode == Mode.CAMPAIGN:
		var cfg: Dictionary = pve.config.duplicate()
		cfg.angles = [aim, null]
		return cfg
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
	new_seed_button.disabled = mode == Mode.CHALLENGE
	seed_label.text = "Seed %d" % seed_value
	var def := BallDefs.get_def(player_type)
	info_label.text = "%s: %s" % [def.display_name, def.description]
	for id in player_buttons:
		player_buttons[id].text = BallDefs.get_def(id).display_name + (" · loan" if _is_loan(id) else "")
	if _is_loan(player_type):
		info_label.text = "%s is on loan today. Practice only: loaner fights don't count for Ghost Arena or your record." % def.display_name
	if mode == Mode.RIVAL:
		info_label.text = "RIVAL! %s's %s is waiting. Pick a ball and beat it (just for fun)." % \
			[rival.name, BallDefs.get_def(opponent_type).display_name]
	elif mode == Mode.CHALLENGE:
		info_label.text = "CHALLENGE! Your friend's %s has its shot lined up. Pick a ball and beat it." % \
			BallDefs.get_def(opponent_type).display_name
	arena.preview_types = [player_type, _pick_opponent()]
	arena.queue_redraw()
	_report_menu.call_deferred()


## Logs where the menu buttons are so the smoke test can tap them ("UI_AT name x y").
func _report_menu() -> void:
	await get_tree().process_frame
	var marks := {"menu_fight": fight_button, "aim_launch": launch_button}
	for id in player_buttons:
		marks["pick_" + id] = player_buttons[id]
	for k in marks:
		var c: Control = marks[k]
		if c.is_visible_in_tree():
			var p := c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])


func _begin_aim() -> void:
	if mode != Mode.CAMPAIGN:
		opponent_type = _pick_opponent()
	if mode == Mode.RIVAL:
		foe_aim = GhostLineup.ghost_angle(rival.lineup, seed_value, 1)
	state = State.AIM
	aim = MatchSim.AIM_AT_CENTRE[0]
	arena.clear_effects()
	_set_aim_preview()
	info_label.text = "Drag on the arena to aim your %s, then let go to launch." % BallDefs.get_def(player_type).display_name
	_show_only(aim_box)
	_report_menu.call_deferred()


func _pick_opponent() -> String:
	if opponent_choice != OPPONENT_RANDOM:
		return opponent_choice
	# Derived from the seed so a seed always means the same matchup.
	return BallDefs.PLAYABLE[seed_value % BallDefs.PLAYABLE.size()]


func _launch() -> void:
	sfx.play("launch")
	_start_fight()
	_count_fight = true


## Starts (or replays) the fight described by the current config.
func _start_fight() -> void:
	_count_fight = false
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
		info_label.text = ("Fight of the Day: " if _board_pick >= 0 else "Shared fight: ") + info_label.text
	sfx.on_fight_start(sim)
	print("FIGHT_START ", _report_code())


func _show_result() -> void:
	state = State.RESULT
	var you := sim.balls[0]
	var replay := mode == Mode.REPLAY
	var names := [sim.balls[0].def.display_name, sim.balls[1].def.display_name] if replay else ["You", "The foe"]
	var result := ResultText.describe(sim, names, replay)
	result_label.text = result.headline
	result_label.modulate = result.color
	_label_result_buttons()
	info_label.text = "%.1fs. %s dealt %d damage%s." % [sim.time(), "P1" if replay else "You",
		roundi(you.damage_dealt), (" and healed %d" % roundi(you.healed)) if you.healed > 0.0 else ""]
	if result.detail != "":
		info_label.text = "%.1fs. %s" % [sim.time(), result.detail]
	report_label.text = "Report code: " + _report_code()
	if _board_pick >= 0:
		info_label.text = ("You called it! " if sim.winner == _board_pick else "Not your call this time. ") + info_label.text
	if mode == Mode.RIVAL and _count_fight:
		_record_rival()
	if mode == Mode.CAMPAIGN:
		_finish_stage()
	if _count_fight:
		_count_fight = false
		_record_fight()
	print("MATCH_END winner=%d reason=%s ticks=%d hash=%s" % [sim.winner, sim.end_reason, sim.tick, sim.state_hash()])
	_show_only(result_box)
	sfx.on_result(sim.winner)


func _report_code() -> String:
	return "BB1.%s.%s.%d.%d.%s" % [player_type, opponent_type, seed_value, aim, _build_stamp().replace(" ", "")]


# --- Campaign -------------------------------------------------------------------

func _load_profile() -> void:
	var now := int(Time.get_unix_time_from_system())
	var d = save.data.get("profile")
	if demo_profile:
		profile = preload("res://game/ui/ui_profile.gd").sample()
		profile_unsaved = true
	else:
		profile = Profile.from_dict(d, now) if d is Dictionary else Profile.new_game(now)
	profile.changed.connect(_save_profile)


func _save_profile() -> void:
	if profile_unsaved:
		return
	save.data.profile = profile.to_dict()
	save.commit()


## A stage from the campaign screen: aim, then fight it in the arena.
func _start_stage(config: Dictionary, zone_index: int, stage_index: int, fighter: String) -> void:
	pve = {"config": config, "zone": zone_index, "stage": stage_index, "fighter": fighter}
	mode = Mode.CAMPAIGN
	player_type = config.p1
	opponent_type = config.p2
	seed_value = config.seed
	foe_aim = null
	shell_layer.visible = false
	sfx.toggle_lift = 0.0
	_begin_aim()
	var st := Zones.stage(zone_index, stage_index)
	info_label.text = "%s %s. Drag on the arena to aim, then let go to launch." % [
		Zones.stage_key(zone_index, stage_index), st.get("name", BallDefs.get_def(st.enemy).display_name)]


## ?pve=1-3: a fresh, unsaved profile fights that stage (for smoke tests).
func _start_url_stage() -> void:
	var parts := pve_param.split("-")
	var z := clampi(int(parts[0]) - 1, 0, Zones.ZONES.size() - 1)
	var i := clampi(int(parts[1]) - 1, 0, Zones.zone(z).stages.size() - 1)
	var now := int(Time.get_unix_time_from_system())
	profile = Profile.new_game(now)
	profile_unsaved = true
	shell.use_profile(profile)
	for k in i:
		profile.stars[Zones.stage_key(z, k)] = 1
	var cfg := Campaign.start(profile, z, i, Profile.STARTER, now)
	_start_stage(cfg, z, i, Profile.STARTER)
	if auto_start:
		_start_fight()


func _finish_stage() -> void:
	var fight := sim.summary()
	fight.max_hp = sim.balls[0].max_hp
	var r := Campaign.finish(profile, pve.zone, pve.stage, pve.fighter, fight)
	pve.result = CampaignScreen.result_text(r)
	report_label.text = pve.result
	print("STAGE_END stage=%s won=%s stars=%d drops=%d" % [Zones.stage_key(pve.zone, pve.stage), r.won, r.stars, r.drops.size()])


## Backing out of aiming. A campaign stage has already spent its energy, so
## leaving before launch refunds it.
func _aim_back() -> void:
	if mode != Mode.CAMPAIGN:
		_show_menu()
		return
	profile.refund_energy(Zones.cost(Zones.stage(pve.zone, pve.stage)))
	_back_to_campaign()


func _back_to_campaign() -> void:
	var params := {"zone": pve.get("zone", 0)}
	if pve.has("result"):
		params.notice = "%s: %s" % [Zones.stage_key(pve.zone, pve.stage), pve.result]
	mode = Mode.NORMAL
	_board_pick = -1
	pve = {}
	_show_menu()
	_show_home()
	shell.show_tab("play")
	shell.go("campaign", params)


# --- Save and online ----------------------------------------------------------

func _apply_picks() -> void:
	var picks: Dictionary = save.data.picks
	if str(picks.player) in BallDefs.PLAYABLE:
		player_type = picks.player
	speed_index = clampi(int(picks.speed), 0, SPEEDS.size() - 1)


## Today's Try-a-Critter loaner, for a player who doesn't own it.
func _is_loan(id: String) -> bool:
	return shell != null and Loaner.is_loan(shell.profile, id)


func _record_fight() -> void:
	# A loaner is practice: no stats, no aim history, never your ghost.
	if _is_loan(player_type):
		return
	if mode != Mode.CAMPAIGN:
		save.data.picks = {"player": player_type, "opponent": opponent_choice, "speed": speed_index}
	save.record_fight(sim.winner, GhostLineup.aim_offset(aim))
	_sync_online()


## Signs in (a guest the first time), syncs the save and refreshes the menu.
## Offline or unconfigured, this does nothing and the game plays as before.
func _go_online() -> void:
	if not backend.enabled():
		return
	# Back from an emailed link or an Apple/Google sign-in: take that session.
	var from_page := backend.take_session_from_page()
	if from_page != "" and from_page != "ok":
		shell.toast("Sign-in didn't finish: " + from_page)
	save.changed.connect(_on_save_changed)
	backend.signed_out.connect(save.reset_for_sign_out)
	_retry_timer = Timer.new()
	_retry_timer.wait_time = 60.0
	_retry_timer.timeout.connect(func(): if save.dirty: _sync_online())
	add_child(_retry_timer)
	_retry_timer.start()
	await save.sync(backend)
	var online := await backend.ensure_session()
	# Connected after the first sign-in so booting doesn't do everything twice.
	backend.account_changed.connect(_on_account_changed)
	if not online:
		return
	await _publish_lineup()
	await _refresh_account()
	await account.refresh()
	if from_page == "ok":
		shell.toast("Signed in. Your progress is on your account." if not account.is_guest() else "Signed in.")
	await friends.refresh()
	if state == State.RESULT:
		_label_result_buttons()


func _sync_online() -> void:
	if not backend.enabled():
		return
	await save.sync(backend)
	await _publish_lineup()


## The save was replaced (a newer cloud copy, another account): show it.
func _on_save_changed() -> void:
	if not url_picks:
		_apply_picks()
	# A newer cloud copy or another account: its profile replaces this one.
	if not profile_unsaved:
		_load_profile()
		shell.use_profile(profile)
	if state == State.MENU:
		_refresh_menu()


## Signed in, out, or as a new guest: bring everything over to that account.
func _on_account_changed() -> void:
	await save.sync(backend)
	await _publish_lineup()
	await _refresh_account()
	await account.refresh()
	await friends.refresh()


func _notification(what: int) -> void:
	# Coming back to the tab or app: pick up anything another device saved.
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and backend != null and backend.enabled() and _retry_timer != null:
		_sync_online()


## Keeps this player's Ghost Arena defence in step with their current ball.
## Nobody becomes a ghost before their first fight (so test runs and
## drive-by visits don't fill the opponent pool with idle lineups).
func _publish_lineup() -> void:
	if int(save.data.stats.fights) == 0:
		return
	var lineup := GhostLineup.make([player_type], save.data.aim_offsets)
	var key := JSON.stringify(lineup, "", true)
	if key == str(save.data.published_lineup):
		return
	if await GhostLineup.publish(backend, lineup):
		save.data.published_lineup = key
		save.save_local()


func _refresh_account() -> void:
	var res: Dictionary = await backend.rest("GET", "/rest/v1/profiles?select=display_name,trophies&id=eq." + backend.user_id())
	if res.ok and res.data is Array and not res.data.is_empty():
		print("ONLINE_OK user=", backend.user_id().left(8))
		account_text = "%s · %d trophies" % [res.data[0].display_name, int(res.data[0].trophies)]
		stamp_label.text = _stamp_text()


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
	stamp_label = _label(_stamp_text(), 18)
	stamp_label.modulate = Color(1, 1, 1, 0.45)
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 14)
	menu_box.add_child(_label("Your critter (opponent is random)", 26))
	menu_box.add_child(_pick_grid(BallDefs.PLAYABLE, _pick_player))
	var seed_row := HBoxContainer.new()
	seed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	seed_row.add_theme_constant_override("separation", 20)
	seed_label = _label("", 26)
	seed_row.add_child(seed_label)
	new_seed_button = _button("New seed", func(): seed_value = _rng.randi_range(1, 99999); _refresh_menu())
	seed_row.add_child(new_seed_button)
	seed_row.add_child(_button("Home", _show_home))
	menu_box.add_child(seed_row)
	fight_button = _button("FIGHT!", _begin_aim, 40)
	menu_box.add_child(fight_button)

	launch_button = _button("Launch", _launch)
	aim_box = _row([
		launch_button,
		_button("Back", _aim_back),
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
		_button("Change critter", _play_normal),
	])
	result_box.add_child(report_row)
	friend_button = _button("Add as a friend", _add_link_friend, 26)
	friend_row = _row([friend_button])
	friend_row.visible = false
	result_box.add_child(friend_row)
	campaign_row = _row([_button("Back to the map", _back_to_campaign)])
	result_box.add_child(campaign_row)


	for c in [title_label, hud_label, info_label, stamp_label, menu_box, aim_box, fight_box, result_box]:
		ui.add_child(c)


func _build_shell() -> void:
	shell_layer = CanvasLayer.new()
	shell_layer.layer = 5
	shell_layer.visible = false
	add_child(shell_layer)
	shell = Shell.new()
	shell.friends = friends
	shell.profile = profile
	shell.set_account(account)
	shell.link_base = _link_base()
	shell.play_requested.connect(func():
		shell_layer.visible = false
		sfx.toggle_lift = 0.0
		_use_lineup()
		# A loaner (Try-a-Critter) wins over your own fighter for this fight.
		if shell.play_with in BallDefs.PLAYABLE:
			player_type = shell.play_with
		shell.play_with = ""
		_play_normal())
	shell.watch_requested.connect(_watch_board_fight)
	shell.rival_requested.connect(_start_rival)
	shell.stage_requested.connect(_start_stage)
	shell.share_tapped.connect(_on_shell_share)
	shell.share_layout_changed.connect(_sync_share_targets)
	shell_layer.add_child(shell)
	LiveOps.fetch(self, func(): if shell.current in ["play", "week"]: shell.refresh())


## Quick fight starts on the fighter chosen in the home screen (Use in lineup).
func _use_lineup() -> void:
	var id := str(shell.profile.lineup)
	if id in BallDefs.PLAYABLE:
		player_type = id


## Picking on Quick fight also makes that critter your fighter, when you own it.
func _pick_player(id: String) -> void:
	player_type = id
	if mode == Mode.NORMAL and shell != null:
		shell.profile.set_lineup(id)
	_refresh_menu()


func _show_home() -> void:
	shell_layer.visible = true
	sfx.toggle_lift = Shell.TAB_HEIGHT
	_sync_share_targets()


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
static func _neon_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = A11y.font(30)
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
		Mode.RIVAL:
			seed_value = _rng.randi_range(1, 99999)
			_begin_aim()
		Mode.REPLAY:
			_take_challenge(player_type, seed_value, sim.launch_angles[0])


func _on_challenge_button() -> void:
	if _board_pick >= 0:
		_back_to_board()
	elif mode == Mode.REPLAY:
		_play_normal()
	elif mode == Mode.RIVAL:
		_show_home()
		if shell.current != "friends":
			shell.go("friends")
	else:
		_share("c")


func _label_result_buttons() -> void:
	again_button.text = {Mode.NORMAL: "Rematch", Mode.CHALLENGE: "Try again", Mode.REPLAY: "Beat this shot", Mode.RIVAL: "Rematch", Mode.CAMPAIGN: ""}[mode]
	challenge_button.text = {Mode.REPLAY: "Play my own", Mode.RIVAL: "Friends"}.get(mode, "Challenge friend")
	if _board_pick >= 0:
		challenge_button.text = "This Week"
	share_button.text = "Send result" if mode == Mode.CHALLENGE else "Share fight"
	# A link from someone who isn't a friend yet offers to add them, in place
	# of the report row (there's only room for one).
	friend_row.visible = _can_add_link_friend()
	report_row.visible = mode != Mode.REPLAY and mode != Mode.CAMPAIGN and not friend_row.visible
	for row in [again_button.get_parent(), share_button.get_parent()]:
		row.visible = mode != Mode.CAMPAIGN
	campaign_row.visible = mode == Mode.CAMPAIGN
	if friend_row.visible and not friend_button.disabled:
		var who: String = friends.invite.get("name", "")
		friend_button.text = "Add %s as a friend" % who if who != "" else "Add them as a friend"
	_sync_share_targets()


func _can_add_link_friend() -> bool:
	if link_friend == "" or mode not in [Mode.CHALLENGE, Mode.REPLAY] or _board_pick >= 0 or friends.status != "ready":
		return false
	return friend_button.disabled or (link_friend != str(friends.me.get("code", "")) and not friends.is_friend_code(link_friend))


func _add_link_friend() -> void:
	friend_button.disabled = true
	friend_button.text = "Adding…"
	var res: Dictionary = await friends.add_by_code(link_friend)
	friend_button.text = {"requested": "Request sent!", "friends": "Friends now!", "already": "Already added"}.get(res.get("status", ""), "Couldn't add them")


## Rematch a friend's saved team: their lead critter, aimed the way they
## usually aim. Unranked; the result only updates your record against them.
func _start_rival(f: Dictionary) -> void:
	var lead := Friends.lead_critter(f)
	if lead == "":
		return
	mode = Mode.RIVAL
	_board_pick = -1
	rival = f
	opponent_choice = lead
	opponent_type = lead
	seed_value = _rng.randi_range(1, 99999)
	shell_layer.visible = false
	sfx.toggle_lift = 0.0
	_show_menu()
	print("RIVAL_MENU vs=%s ball=%s" % [str(f.name), lead])


func _record_rival() -> void:
	var rec: Dictionary = await friends.record_rival(str(rival.id), sim.winner)
	if not rec.is_empty() and state == State.RESULT and mode == Mode.RIVAL:
		info_label.text = "Vs %s: %s." % [rival.name, Friends.record_text(rec).trim_prefix("Rematches: ")]


## Fight the given ball and shot from the opponent corner, on the same seed.
func _take_challenge(ball: String, challenge_seed: int, challenge_aim: int) -> void:
	mode = Mode.CHALLENGE
	_board_pick = -1
	opponent_choice = ball
	opponent_type = ball
	seed_value = challenge_seed
	foe_aim = FightLink.mirror_angle(challenge_aim)
	_show_menu()


## Back to picking your ball against a random foe, dropping any link the page was opened with.
func _play_normal() -> void:
	_board_pick = -1
	opponent_choice = OPPONENT_RANDOM
	mode = Mode.NORMAL
	foe_aim = null
	rival = {}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("history.replaceState(null, '', location.pathname)")
	_show_menu()


## Watch the Fight of the Day from the This Week board, as a replay.
func _watch_board_fight(f: Dictionary) -> void:
	shell_layer.visible = false
	sfx.toggle_lift = 0.0
	mode = Mode.REPLAY
	player_type = f.p1
	opponent_choice = f.p2
	opponent_type = f.p2
	seed_value = f.seed
	aim = f.angles[0]
	foe_aim = f.angles[1]
	_board_pick = f.pick
	_start_fight()


func _back_to_board() -> void:
	_play_normal()
	_show_home()
	shell.show_tab("play")
	shell.go("week")


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", A11y.font(font_size))
	l.set_meta("base_font", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, on_press: Callable, font_size := 30) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override("font_size", A11y.font(font_size))
	b.set_meta("base_font", font_size)
	b.pressed.connect(on_press)
	return b


func _row(children: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for c in children:
		row.add_child(c)
	return row


## Every fightable critter as a tile (icon + name), three across. Past two
## rows the grid scrolls, so new critters just appear.
func _pick_grid(ids: Array, on_pick: Callable) -> ScrollContainer:
	var group := ButtonGroup.new()
	var grid := GridContainer.new()
	grid.columns = PICK_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for id in ids:
		var b := _button("", on_pick.bind(id), 20)
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(0, PICK_TILE_HEIGHT)
		b.size_flags_vertical = Control.SIZE_FILL
		# PASS lets a drag that starts on a tile scroll the grid.
		b.mouse_filter = Control.MOUSE_FILTER_PASS
		var icon := CritterIcon.make(id, 1, 64.0)
		icon.anchor_left = 0.5
		icon.anchor_right = 0.5
		icon.offset_left = -32.0
		icon.offset_right = 32.0
		icon.offset_top = 6.0
		icon.offset_bottom = 70.0
		b.add_child(icon)
		var name_label := _label(BallDefs.get_def(id).display_name, 20)
		name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_label.offset_top = -38.0
		name_label.offset_bottom = -8.0
		name_label.clip_text = true
		b.add_child(name_label)
		b.toggled.connect(func(on): name_label.add_theme_color_override("font_color", Color("0b0a1f") if on else Color("f0eeff")))
		player_buttons[id] = b
		grid.add_child(b)
	pick_scroll = ScrollContainer.new()
	pick_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pick_scroll.scroll_deadzone = 12
	pick_scroll.add_child(grid)
	var rows := mini(PICK_ROWS_SHOWN, ceili(float(ids.size()) / PICK_COLUMNS))
	pick_scroll.custom_minimum_size = Vector2(0, rows * PICK_TILE_HEIGHT + (rows - 1) * 12)
	return pick_scroll


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


func _link_base() -> String:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("location.origin + location.pathname", true))
	return FightLink.HOME


## Signed-in players' links carry their friend code (&f=), so whoever opens
## one can add them as a friend.
func _share_url(kind: String) -> String:
	var angles := sim.launch_angles
	var code := FightLink.challenge_code(player_type, seed_value, angles[0]) if kind == "c" \
		else FightLink.replay_code(player_type, opponent_type, seed_value, angles[0], angles[1])
	var url := FightLink.url(_link_base(), kind, code)
	var mine := str(friends.me.get("code", ""))
	return url + "&f=" + mine if mine != "" else url


func _share_text(kind: String) -> String:
	var mine: String = BallDefs.get_def(player_type).display_name
	var theirs: String = BallDefs.get_def(opponent_type).display_name
	if kind == "c":
		return "Can your ball beat my %s's shot in Battle Balls?" % mine
	if mode == Mode.CHALLENGE:
		if sim.winner == -1:
			return "My %s drew with your %s challenge. Watch:" % [mine, theirs]
		return ("I beat your %s challenge with my %s!" if sim.winner == 0 else "Your %s beat my %s. Watch:") % [theirs, mine]
	return "Watch %s vs %s in Battle Balls!" % [mine, theirs]


## Tells the page where the share buttons are, once their layout has settled.
func _sync_share_targets() -> void:
	if not OS.has_feature("web"):
		return
	await get_tree().process_frame
	var targets := []
	var view := get_viewport().get_visible_rect().size
	var add := func(kind: String, url: String, text: String, r: Rect2):
		targets.append({"kind": kind, "url": url, "text": text,
			"x": r.position.x / view.x, "y": r.position.y / view.y, "w": r.size.x / view.x, "h": r.size.y / view.y})
	if shell_layer != null and shell_layer.visible:
		for t in shell.share_targets():
			add.call(t.kind, t.url, t.text, t.rect)
	elif state == State.RESULT and result_box.visible and sim != null and mode != Mode.CAMPAIGN:
		var buttons := {"r": share_button}
		if mode not in [Mode.REPLAY, Mode.RIVAL]:
			buttons["c"] = challenge_button
		for kind in buttons:
			add.call(kind, _share_url(kind), _share_text(kind), buttons[kind].get_global_rect())
	JavaScriptBridge.eval("window.bbShare && (window.bbShare.targets = %s)" % JSON.stringify(targets), true)


func _share(kind: String) -> void:
	if OS.has_feature("web"):
		# The page already started sharing on this tap; just watch how it went.
		_share_pending = true
		return
	DisplayServer.clipboard_set(_share_url(kind))
	report_label.text = "Link copied: " + _share_url(kind)


## A share button on the home screens (e.g. the friend invite link).
func _on_shell_share(kind: String) -> void:
	if OS.has_feature("web"):
		_share_pending = true
		return
	for t in shell.share_targets():
		if t.kind == kind:
			DisplayServer.clipboard_set(t.url)
			shell.toast("Link copied: " + t.url)


func _poll_share_status() -> void:
	var status := str(JavaScriptBridge.eval("window.bbShare ? window.bbShare.status : ''", true))
	var messages := {"shared": "Shared!", "copied": "Link copied. Paste it to a friend!", "shown": "", "cancelled": ""}
	if status in messages:
		_share_pending = false
		JavaScriptBridge.eval("window.bbShare.status = ''", true)
		if messages[status] != "" and shell_layer.visible:
			shell.toast(messages[status])
		elif messages[status] != "":
			report_label.text = messages[status]


# --- Build info and URL params ---------------------------------------------

func _build_stamp() -> String:
	var commit := "dev"
	if FileAccess.file_exists("res://build_info.txt"):
		commit = FileAccess.get_file_as_string("res://build_info.txt").strip_edges()
	return "v%s %s" % [VERSION, commit]


func _stamp_text() -> String:
	return _build_stamp() + (" · " + account_text if account_text != "" else "")


func _read_url_params() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var query: String = str(JavaScriptBridge.eval("window.location.search", true))
	var params := {}
	for pair in query.trim_prefix("?").split("&", false):
		var kv := pair.split("=")
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	if params.get("p1", "") in BallDefs.PLAYABLE:
		player_type = params.p1
		url_picks = true
	if params.get("p2", "") in BallDefs.PLAYABLE:
		opponent_choice = params.p2
		opponent_type = params.p2
		url_picks = true
	backend.disabled = params.get("offline", "") == "1"
	if params.has("seed") and params.seed.is_valid_int():
		seed_value = int(params.seed)
	if params.has("aim") and params.aim.is_valid_int():
		aim = int(params.aim)
	if params.has("speed"):
		var i := SPEEDS.find(float(params.speed))
		speed_index = maxi(0, i)
	auto_start = params.get("auto", "") == "1"
	# ?today=2026-10-17 pins the live-ops clock to that day's noon (UTC).
	if LiveOps.date_unix(params.get("today", "")) >= 0:
		LiveOps.now_override = LiveOps.date_unix(params.today) + 12 * 3600
	if params.get("demo", "") == "friends":
		friends.show_demo()
	if Friends.is_code(params.get("f", "")):
		link_friend = Friends.normalize_code(params.f)
	if params.get("pve", "").count("-") == 1:
		pve_param = params.pve
	demo_profile = params.get("demo", "") == "1"
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
	if mode != Mode.NORMAL:
		url_picks = true
	if auto_start and opponent_choice == OPPONENT_RANDOM:
		opponent_type = _pick_opponent()
	return params
