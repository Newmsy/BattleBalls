## Game flow: pick balls -> aim -> watch the fight -> result.
## URL params on the web build skip straight to a fight, e.g.
## ?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2&arena=rink&mod=big_head
## Share links (see fight_link.gd) open a replay (?r=) or a challenge (?c=).
## ?pve=1-3 plays campaign stage 1-3 on a fresh, unsaved profile (with auto=1, unaimed).
## A first visit with no params plays the onboarding (game/onboarding.gd);
## ?tutorial=1 forces it, ?tutorial=0 skips it.
extends Node2D

const MatchSim := preload("res://sim/match_sim.gd")
const Bosses := preload("res://sim/bosses.gd")
const Power := preload("res://sim/power.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Modifiers := preload("res://sim/modifiers.gd")
const Arenas := preload("res://sim/arenas.gd")
const ArenaView := preload("res://game/arena_view.gd")
const FightHud := preload("res://game/fight_hud.gd")
const Backend := preload("res://game/online/backend.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const TestUser := preload("res://game/online/test_user.gd")
const GhostLineup := preload("res://game/online/ghost_lineup.gd")
const FightLink := preload("res://game/fight_link.gd")
const Sfx := preload("res://game/audio/sfx.gd")
const A11y := preload("res://game/a11y.gd")
const Shell := preload("res://game/ui/shell.gd")
const LiveOps := preload("res://game/liveops.gd")
const Onboarding := preload("res://game/onboarding.gd")
const Intro := preload("res://game/ui/intro.gd")
const Story := preload("res://meta/story.gd")
const Loaner := preload("res://game/loaner.gd")
const Friends := preload("res://game/online/friends.gd")
const Profile := preload("res://meta/profile.gd")
const Campaign := preload("res://meta/campaign.gd")
const GearVault := preload("res://meta/gear_vault.gd")
const VaultScreen := preload("res://game/ui/screens/vault_screen.gd")
const BroodNest := preload("res://meta/brood_nest.gd")
const NestScreen := preload("res://game/ui/screens/nest_screen.gd")
## Farming bosses by their screen: the rules (start/finish/cancel) and the screen (result_text).
const BOSS_MODES := {"vault": [GearVault, VaultScreen], "nest": [BroodNest, NestScreen],
	"pinata": [preload("res://meta/pinata_party.gd"), preload("res://game/ui/screens/pinata_screen.gd")],
	"totem": [preload("res://meta/totem_shrine.gd"), preload("res://game/ui/screens/totem_screen.gd")],
	"wyrm": [preload("res://meta/wyrm_rift.gd"), preload("res://game/ui/screens/wyrm_screen.gd")],
	"glitch": [preload("res://meta/glitch_core.gd"), preload("res://game/ui/screens/glitch_screen.gd")]}
const FighterTag := preload("res://game/ui/fighter_tag.gd")
const Roster := preload("res://game/ui/roster.gd")
const Zones := preload("res://meta/zones.gd")
const CampaignScreen := preload("res://game/ui/screens/campaign_screen.gd")
const SpireScreen := preload("res://game/ui/screens/spire_screen.gd")
const Analytics := preload("res://game/online/analytics.gd")
const Account := preload("res://game/online/account.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const ResultText := preload("res://game/result_text.gd")
const FinisherCam := preload("res://game/finisher_cam.gd")
const ClipExport := preload("res://game/clip/clip_export.gd")
const ClipCard := preload("res://game/clip/clip_card.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const Kit := preload("res://game/ui/ui_kit.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const Store := preload("res://game/glow/store.gd")
const Lineup := preload("res://sim/lineup.gd")
const FightSpeed := preload("res://game/fight_speed.gd")
const Dev := preload("res://game/dev.gd")
const LiveClient := preload("res://game/online/live_client.gd")
const LiveMatch := preload("res://sim/live_match.gd")
const SimVersion := preload("res://sim/sim_version.gd")

## CLIP plays the finished fight again in the vertical clip layout.
enum State { MENU, AIM, FIGHT, RESULT, CLIP }
## NORMAL: pick your ball, the opponent is random. REPLAY: watching a shared fight. CHALLENGE: beating
## a friend's ball and shot. RIVAL: an unranked rematch against a friend's
## saved team (their Ghost Arena lineup, aimed the way they usually aim).
## TUTORIAL: onboarding drives the arena. CAMPAIGN: a campaign stage (energy
## already spent). LIVE: a Quick fight against a real player, refereed by the
## live server (Settings > Testing for now; design/live-quick-fight.md).
enum Mode { NORMAL, REPLAY, CHALLENGE, RIVAL, TUTORIAL, CAMPAIGN, LIVE }

## Onboarding fights report here instead of showing the result panel.
signal tutorial_fight_ended(winner: int)

const FONT := preload("res://game/fonts/ChakraPetch-Bold.ttf")
const ACCENT := Color("8f7bff")
const MUTED := Color("a29fc9")

const VERSION := "0.2.0"
const ARENA_PIXELS := 680.0
const INFO_HEIGHT := 100.0 ## Two lines of the info text.
const CONTROLS_HEIGHT := 452.0 ## Tallest control panel (the menu).
const TOP := 124.0 ## Title and HUD above the arena.
const OPPONENT_RANDOM := "random"
const MODE_SCENES := {"trickshot": "res://game/trick_shot.tscn", "bouncerun": "res://game/bounce_run.tscn"}
const PICK_COLUMNS := 3
const PICK_TILE_HEIGHT := 104.0
const PICK_ROWS_SHOWN := 2 ## More rows than this scroll.

var state := State.MENU
var mode := Mode.NORMAL
var sim: MatchSim
var player_type := "vampire"
var opponent_choice := OPPONENT_RANDOM
var opponent_type := "laser"
var seed_value := 1
## Arena forced by a share link, a board fight or ?arena= (url_arena);
## empty means the seed picks it, like the opponent.
var arena_override := ""
var url_arena := ""
var aim := -450 ## Player launch angle, tenths of a degree.
var foe_aim = null ## Opponent launch angle, or null to let the seed pick it.
var link_error := ""
var auto_start := false
## Chaos Weekend rule twist. Starts on this weekend's modifier (Normal on
## weekdays); the menu's Rules button cycles through all of them for testing.
var modifier := Modifiers.NONE
var auto_clip := false ## ?clip=1: make a clip as soon as the fight ends (smoke test).
var url_picks := false ## URL params chose the balls: don't overwrite them from the save.
## Quick fight tiers for testing: [yours, the foe's]. Yours 0 is equal stats
## (no tiers, the old practice fight); the foe's 0 is "same as mine".
var pick_tiers := [0, 0]
## Tiers a shared fight link (&t=) was played at, for REPLAY; [0, 0] is none.
var link_tiers := [0, 0]
var tier_buttons: Array = []
## Quick fight 2v2: all four balls fight at once. Your pair is
## [player_type, mate_type]; you aim player_type, the seed aims the rest.
var duo := false
var mate_type := ""
var duo_button: Button

var backend: Backend
var save := SaveGame.new()
var account_text := "" ## Guest name and trophies once signed in.
var friends: Friends
var account: Account
var _retry_timer: Timer ## Retries the cloud save while it has unsynced changes.
var _watch_timer: Timer ## Notices save changes (side files too) and syncs them.
var _synced_edits := -1 ## save.edits when the last sync started.
var rival := {} ## The friend entry a RIVAL fight is against.
var link_friend := "" ## Friend code from the link the page was opened with (&f=).
var _count_fight := false ## The running fight came from the menu, not a replay or URL.
var _last_logged_fight := "" ## Report code of the last replay sent to analytics.

var _accumulator := 0.0
var finisher: FinisherCam
var _hold := -1.0 ## Real seconds since the finishing blow, or -1 before it.
var _skipped := false ## "Skip to end" also skips the finisher.
var _dragging := false
var _rng := RandomNumberGenerator.new() ## UI-only randomness (new seeds), never used by the sim.

var arena: ArenaView
var fight_hud: FightHud ## Both health bars, above the arena.
var arena_clip: Control ## Holds the arena; clips it while the finisher cam zooms.
var ui_layer: CanvasLayer
var clip_card: ClipCard
var clip_button: Button
var copy_button: Button
var change_button: Button
var _clip_speed := 1.0
var _clip_recording := false
var _clip_wait := false ## Waiting for the page to finish encoding.
var _clip_ready := false ## A video is ready to save.
var _clip_hint := false ## Told the player to screen-record instead.
var sfx: Sfx
var ui: Control
var title_label: Label
var hud_label: Label
var info_label: Label
var stamp_label: Label
var menu_box: VBoxContainer
var player_buttons := {}
var player_loan_tags := {} ## id -> the LOAN tag on its pick tile.
var pick_scroll: ScrollContainer
var fight_button: Button
var launch_button: Button
var seed_label: Label
var rules_button: Button
var fight_box: HBoxContainer
var speed_picker: FightSpeed.Picker
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
## The campaign stage being fought: {config, zone, stage, fighter, result?},
## or a Gear Vault run: {config, vault (difficulty), fighter, result?}.
var pve := {}
var _stats_for: MatchSim ## The fight fight_hud.stats were worked out for.
var pve_param := ""
## ?demo=1 (smoke tests, previews): a filled-in sample profile that is never saved.
var demo_profile := false
var demo_stars := 0 ## ?demo=1&stars=3: every Zone 1 stage starred (UI screenshots).
var profile_unsaved := false
## The board fight being watched (Fight of the Day, a Bracket of Legends game):
## its title and the screen to go back to. Empty otherwise.
var _board := {}
var aim_back_button: Button
var tutorial_tags: Array = [] ## HUD names during onboarding fights.
var tutorial_side := 0 ## The ball the player is rooting for, for the result jingle.
var url_params := {}
## Live fights: the server connection while finding a foe or in a match, the
## server's "matched" message (plus "go" once both have aimed), and the sim
## side you're on there (the fight is the server's, so you can be side 1).
var live_client: LiveClient
var live := {}
var you_side := 0
var _live_aim_left := 0.0
var live_box: HBoxContainer
## Where the info line and controls sit (under or beside the arena).
var controls_rect := Rect2()

static var _mode_redirected := false


func _ready() -> void:
	# Only draw a frame when something on screen changed: menus sit idle
	# instead of redrawing at 60 fps (battery). The desktop loop would also
	# sleep between frames, which the headless tests don't want.
	OS.low_processor_usage_mode = OS.has_feature("web")
	_rng.randomize()
	seed_value = _rng.randi_range(1, 99999)
	modifier = _weekend_modifier()
	backend = Backend.new()
	add_child(backend)
	friends = Friends.new(backend)
	account = Account.new(backend)
	save.app_version = VERSION
	save.mirrored = SaveGame.MIRRORED
	save.test_mode = TestUser.slot() > 0
	backend.test_user = TestUser.slot()
	save.load_local()
	save.capture_files()
	_sync_settings(true)
	FightSpeed.on_pick = func(i: int):
		save.data["settings"] = {"fight_speed": i}
		save.commit()
	_apply_picks()
	url_params = _read_url_params()
	if url_params.has("perf"): # ?perf=1 logs frame cost to the console every 2s.
		_perf_log()
	# ?stats opens the owner's stats screen (game/stats/), which isn't play.
	if url_params.has("stats"):
		get_tree().change_scene_to_file.call_deferred("res://game/stats/stats.tscn")
		return
	# ?probe=1 runs the determinism probe (sim/probe.gd) and shows its hash,
	# which must match headless Godot's (tools/probe.gd) on every platform.
	if url_params.has("probe"):
		_run_probe.call_deferred()
		return
	Analytics.start(get_tree(), backend, VERSION, url_params)
	# ?mode=trickshot / ?mode=bouncerun open that daily mode, once: its Back button comes here.
	var redirect: String = MODE_SCENES.get(url_params.get("mode", ""), "")
	if redirect != "" and not _mode_redirected:
		_mode_redirected = true
		set_process(false)
		get_tree().change_scene_to_file.call_deferred(redirect)
		return
	_load_profile()
	arena_clip = Control.new()
	arena_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arena_clip)
	arena = ArenaView.new()
	arena_clip.add_child(arena)
	clip_card = ClipCard.new()
	clip_card.visible = false
	add_child(clip_card)
	sfx = Sfx.new()
	add_child(sfx)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_install_share_listener()
	ClipExport.install()
	print("BOOT_OK build=", _build_stamp(), " reduced_motion=", A11y.reduced_motion)
	_build_shell()
	TouchInput.ensure(self)
	TouchInput.set_back(self, _swipe_back)
	if pve_param != "":
		_start_url_stage()
	elif _wants_tutorial():
		_start_tutorial()
	elif auto_start and Dev.live_url_override != "":
		_find_live() # ?live=ws://...&auto=1: straight into a live match (smoke test).
	elif auto_start:
		_start_fight()
	else:
		_show_menu()
		# Shared fight links open straight on their menu; everyone else starts at home.
		if mode == Mode.NORMAL and link_error == "" and not duo:
			_show_home()
			if link_friend != "":
				shell.go("friends")
			elif not load("res://game/campaign_relay.gd").done.is_empty():
				_settle_relay_stage()
			elif SpireScreen.should_open(url_params):
				shell.go("spire")
			elif url_params.get("screen", "") in Shell.TAB_IDS:
				shell.show_tab(url_params.screen) # ?screen=fuse
			elif url_params.get("screen", "") in Shell.SCREENS and (url_params.screen not in ["detail", "dex_entry"] or url_params.has("id")):
				# ?screen=shop, ?screen=pass, ?screen=detail&id=vampire...
				var screen_params := {"id": url_params.id} if url_params.has("id") else {}
				if url_params.has("zone"):
					screen_params.zone = clampi(int(url_params.zone) - 1, 0, Zones.ZONES.size() - 1) # ?screen=campaign&zone=2
				if demo_profile and url_params.screen in ["arena", "boosts", "bazaar", "defence"]:
					screen_params.store = preload("res://game/pvp/arena_store.gd").sample()
				shell.go(url_params.screen, screen_params)
			# ?mode=bracket opens Bracket of Legends (try ?mode=bracket&today=2026-10-24).
			if url_params.get("mode", "") == "bracket":
				shell.go("week")
				shell.go("bracket")
	friends.changed.connect(func(): if state == State.RESULT: _label_result_buttons())
	if link_friend != "":
		friends.set_invite(link_friend)
	if link_error != "":
		info_label.text = link_error
	_go_online()


func _process(delta: float) -> void:
	var covered := _sync_cover()
	if mode == Mode.LIVE and state == State.AIM and not live.has("aimed"):
		_tick_live_aim(delta)
	if state == State.FIGHT:
		if _advance_fight(delta, FightSpeed.current()):
			_show_result()
	elif state == State.CLIP:
		_advance_clip(delta)
	elif not covered:
		arena.advance_effects(delta)
	if _clip_wait:
		_poll_clip()
	if _share_pending:
		_poll_share_status()
	if not covered:
		_update_hud()


## The home shell is opaque and full screen: while it's up, the Quick fight
## menu (90 animated critter icons) and the arena under it are hidden, so
## they neither update nor make the screen redraw. True while covered.
func _sync_cover() -> bool:
	var covered := shell_layer != null and shell_layer.visible
	if ui.visible == covered:
		ui.visible = not covered
		arena_clip.visible = not covered
	return covered


func _unhandled_input(event: InputEvent) -> void:
	if state == State.CLIP and event is InputEventMouseButton and event.pressed:
		_cancel_clip()
		return
	if state != State.AIM or live.has("aimed"):
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
	var dir := arena.to_world(screen_pos) - sim.balls[you_side].pos
	if dir.length() < 10.0:
		return
	aim = roundi(rad_to_deg(dir.angle()) * 10.0)
	sfx.on_aim_drag(dir.length() / 600.0)
	_set_aim_preview()


func _set_aim_preview() -> void:
	sim = MatchSim.new(_config())
	arena.sim = sim
	arena.aim_dir = Vector2.from_angle(deg_to_rad(aim / 10.0))
	_apply_cosmetics()


## Your equipped cosmetics on your ball. Render-only: they never reach the
## sim config, so every fight still replays from angles + seed. Shared
## replays show plain balls (P1/P2 aren't you).
func _apply_cosmetics() -> void:
	var mine: Dictionary = shell.glow.loadout() if shell and mode != Mode.REPLAY else {}
	arena.loadouts = [mine, {}]


# --- Flow -------------------------------------------------------------------

func _config() -> Dictionary:
	if mode == Mode.LIVE:
		var angles: Array = live.get("angles", [null, null]).duplicate()
		if not live.has("angles"):
			angles[you_side] = aim
		return LiveMatch.config(int(live.seed), live.sides, angles)
	if mode == Mode.CAMPAIGN:
		var cfg: Dictionary = pve.config.duplicate()
		cfg.angles = [aim, null]
		return cfg
	var cfg := {"seed": seed_value, "p1": player_type, "p2": opponent_type, "angles": [aim, foe_aim], "arena": _pick_arena(), "modifier": modifier}
	if _is_duo():
		cfg.p3 = _mate()
		cfg.p4 = _foe_mate(opponent_type)
	var t := _fight_tiers()
	if t[0] > 0:
		# Same path as the progression modes: tier ability upgrades and power.
		Lineup.apply(cfg, 0, Lineup.make(player_type, t[0]))
		Lineup.apply(cfg, 1, Lineup.make(opponent_type, t[1]))
		if _is_duo():
			Lineup.apply(cfg, 2, Lineup.make(cfg.p3, t[0]))
			Lineup.apply(cfg, 3, Lineup.make(cfg.p4, t[1]))
	return cfg


## A 2v2 is a Quick fight option only.
func _is_duo() -> bool:
	return duo and mode == Mode.NORMAL


## Your second critter: never the same as the first.
func _mate() -> String:
	if mate_type in BallDefs.PLAYABLE and mate_type != player_type:
		return mate_type
	for id in BallDefs.PLAYABLE:
		if id != player_type:
			return id
	return player_type


## The foe's second critter, from the seed like the first, never a copy of it.
func _foe_mate(first: String) -> String:
	var ids: Array = BallDefs.PLAYABLE
	var k := posmod(seed_value * 7 + 3, ids.size())
	if ids[k] == first:
		k = (k + 1) % ids.size()
	return ids[k]


func _toggle_duo() -> void:
	duo = not duo
	if duo:
		mate_type = _mate()
	_refresh_menu()


## [yours, the foe's] tiers this fight plays at, or [0, 0] for equal stats.
## Only Quick fight (and a replay of a tiered Quick fight) has tiers.
func _fight_tiers() -> Array:
	if mode == Mode.REPLAY:
		return link_tiers
	if mode != Mode.NORMAL or pick_tiers[0] == 0:
		return [0, 0]
	return [pick_tiers[0], pick_tiers[1] if pick_tiers[1] > 0 else pick_tiers[0]]


## Taps cycle Equal (or Same), then one to five stars.
func _cycle_tier(i: int) -> void:
	pick_tiers[i] = (pick_tiers[i] + 1) % (Lineup.MAX_TIER + 1)
	_refresh_menu()


## "You" / "Foe" and gold stars out of five, or the word when tiers are off.
func _tier_button(i: int) -> Button:
	var b := _button("", _cycle_tier.bind(i), 22, "ghost", 68)
	var row := Kit.hbox(8, [], BoxContainer.ALIGNMENT_CENTER)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(row)
	return b


func _refresh_tier_buttons() -> void:
	for b in tier_buttons:
		b.visible = mode == Mode.NORMAL
	for i in 2:
		var b: Button = tier_buttons[i]
		var row: HBoxContainer = b.get_child(0)
		for c in row.get_children():
			row.remove_child(c)
			c.queue_free()
		var n: int = pick_tiers[i]
		var off: bool = pick_tiers[0] == 0
		b.disabled = i == 1 and off
		row.add_child(Kit.label("You" if i == 0 else "Foe", 22, Kit.FG if not b.disabled else Kit.MUTED))
		if n > 0 and not (i == 1 and off):
			row.add_child(Kit.glyph("stars", 22, Kit.FG, n))
		else:
			row.add_child(Kit.label("equal stats" if off else "same tier", 20, Kit.MUTED))


func _show_menu() -> void:
	state = State.MENU
	_set_side(0)
	sim = null
	arena.sim = null
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	arena.reset_camera()
	_apply_cosmetics()
	sfx.on_menu()
	_refresh_menu()
	_show_only(menu_box)


func _refresh_menu() -> void:
	for id in player_buttons:
		player_buttons[id].button_pressed = id == player_type or (_is_duo() and id == _mate())
	new_seed_button.disabled = mode == Mode.CHALLENGE
	seed_label.text = ("Your critter · seed %d · %s" % [seed_value, Arenas.get_def(_pick_arena()).display_name]).to_upper()
	duo_button.visible = mode == Mode.NORMAL
	duo_button.text = "2v2" if _is_duo() else "1v1"
	fight_button.text = "LIVE FIGHT" if _live_on() else "FIGHT!"
	if _is_duo():
		seed_label.text = ("Your pair: %s + %s · %s" % [BallDefs.get_def(player_type).display_name,
			BallDefs.get_def(_mate()).display_name, Arenas.get_def(_pick_arena()).display_name]).to_upper()
	rules_button.text = Modifiers.display_name(modifier)
	_refresh_tier_buttons()
	var def := BallDefs.get_def(player_type)
	info_label.text = "%s: %s" % [def.display_name, def.description]
	if _is_duo():
		info_label.text = "2v2: all four fight at once. Tap two critters for your pair; you aim %s." % def.display_name
	for id in player_loan_tags:
		player_loan_tags[id].visible = _is_loan(id)
	if _is_loan(player_type):
		info_label.text = "%s is on loan today. Practice only." % def.display_name
	if mode == Mode.RIVAL:
		info_label.text = "RIVAL! %s's %s is waiting. Pick a ball and beat it (just for fun)." % \
			[rival.name, BallDefs.get_def(opponent_type).display_name]
	elif mode == Mode.CHALLENGE:
		info_label.text = "CHALLENGE! Your friend's %s has its shot lined up. Pick a ball and beat it." % \
			BallDefs.get_def(opponent_type).display_name
	if modifier != Modifiers.NONE:
		info_label.text = "%s: %s" % [Modifiers.display_name(modifier), Modifiers.get_def(modifier).description]
	arena.preview_types = _fight_types(player_type, _pick_opponent())
	if _is_duo():
		arena.preview_types = arena.preview_types + [_mate(), _foe_mate(_pick_opponent())]
	arena.preview_modifier = modifier
	arena.preview_arena = _pick_arena()
	arena.queue_redraw()
	_report_menu.call_deferred()


## Logs where the menu buttons are so the smoke test can tap them ("UI_AT name x y").
func _report_menu() -> void:
	await get_tree().process_frame
	_sync_cover()
	var marks := {"menu_fight": fight_button, "aim_launch": launch_button, "tier_you": tier_buttons[0], "tier_foe": tier_buttons[1], "menu_duo": duo_button}
	for id in player_buttons:
		marks["pick_" + id] = player_buttons[id]
	for k in marks:
		var c: Control = marks[k]
		if c.is_visible_in_tree():
			var p := c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])


func _begin_aim() -> void:
	if mode != Mode.LIVE:
		_set_side(0)
	if mode != Mode.CAMPAIGN and mode != Mode.LIVE:
		opponent_type = _pick_opponent()
	if mode == Mode.RIVAL:
		foe_aim = GhostLineup.ghost_angle(rival.lineup, seed_value, 1)
	state = State.AIM
	aim = MatchSim.aim_at_centre(you_side, 4 if _is_duo() or live.get("sides", [[]])[0].size() > 1 or pve.get("config", {}).has("p3") else 2)
	arena.clear_effects()
	arena.reset_camera()
	_set_aim_preview()
	info_label.text = "Drag on the arena to aim your %s, then let go to launch." % sim.balls[you_side].def.display_name
	_show_only(aim_box)
	_report_menu.call_deferred()


func _pick_opponent() -> String:
	if opponent_choice != OPPONENT_RANDOM:
		return opponent_choice
	# Derived from the seed so a seed always means the same matchup.
	return BallDefs.PLAYABLE[seed_value % BallDefs.PLAYABLE.size()]


## The balls that will actually fight: Mirror Match overrides both picks.
func _fight_types(p1: String, p2: String) -> Array:
	if Modifiers.get_def(modifier).get("mirror", false):
		var m := Modifiers.mirror_ball(seed_value)
		return [m, m]
	return [p1, p2]


## This weekend's Chaos twist from the live-ops schedule, or NONE off-weekend.
func _weekend_modifier() -> String:
	var c := LiveOps.chaos(LiveOps.now())
	return c.modifier if c.live else Modifiers.NONE


func _cycle_rules() -> void:
	var ids: Array = [Modifiers.NONE] + Modifiers.DEFS.keys()
	modifier = ids[(ids.find(modifier) + 1) % ids.size()]
	_refresh_menu()


func _launch() -> void:
	if mode == Mode.LIVE:
		_live_launch()
		return
	arena.ghost_dir = Vector2.ZERO
	sfx.play("launch")
	_start_fight()
	_count_fight = true


## Starts (or replays) the fight described by the current config.
func _start_fight() -> void:
	_count_fight = false
	_set_side(you_side if mode == Mode.LIVE else 0)
	sim = MatchSim.new(_config())
	_prepare_fight(sim.config)
	_apply_cosmetics()
	state = State.FIGHT
	info_label.text = "" # 1v1: the names, tiers and power are on the health bars.
	if sim.starters == 4:
		info_label.text = "%s + %s vs %s + %s" % [sim.balls[0].def.display_name, sim.balls[2].def.display_name,
			sim.balls[1].def.display_name, sim.balls[3].def.display_name]
	if mode == Mode.CAMPAIGN: # Tier, level and power sit under the health bars.
		info_label.text = "" if sim.starters == 2 else _pair_power_text()
	if sim.config.get("modifier", Modifiers.NONE) != Modifiers.NONE: # Campaign stages fight without the week's twist.
		info_label.text += (" · " if info_label.text != "" else "") + Modifiers.display_name(sim.config.modifier)
	speed_picker.refresh()
	_show_only(fight_box)
	arena.team_tags = ["P1", "P2"] if mode == Mode.REPLAY else ArenaView.TEAM_TAGS
	if mode == Mode.REPLAY:
		info_label.text = (_board.title + ": " if not _board.is_empty() else "Shared fight: ") + info_label.text
	sfx.on_fight_start(sim)
	print("FIGHT_START ", _report_code())


## Steps the fight in real time at `speed`, slowing into the finisher cam
## and holding on the KO face. True once the fight and its finisher are over.
## With Reduced motion there's no slow motion or zoom, just the KO face.
func _advance_fight(delta: float, speed: float) -> bool:
	var finishing := finisher.ko_tick >= 0 and not _skipped
	var cinematic := finishing and not A11y.reduced_motion
	var rate := speed
	_accumulator += delta
	# Cap catch-up so a slow frame can't freeze the page.
	var steps := 0
	while not sim.finished and steps < 32:
		rate = finisher.time_scale(sim.tick, speed) if cinematic else speed
		if _accumulator < MatchSim.DT / rate:
			break
		_accumulator -= MatchSim.DT / rate
		arena.snapshot_positions()
		sim.step()
		arena.consume_events(sim.events)
		sfx.consume_events(sim.events, sim)
		steps += 1
	# Draw between the last two steps; a finished fight shows its final frame.
	arena.render_alpha = 1.0 if sim.finished else clampf(_accumulator / (MatchSim.DT / rate), 0.0, 1.0)
	if not finishing:
		arena.advance_effects(delta * speed)
		return sim.finished
	if sim.finished:
		if _hold < 0.0:
			_hold = 0.0
			arena.ko_ball = finisher.loser
			print("FINISHER_KO loser=%d tick=%d" % [finisher.loser, sim.tick])
		else:
			_hold += delta
		rate = 0.5
	if cinematic and finisher.active(sim.tick):
		# Fractional tick: zoom and bars move every frame, not only on sim steps.
		var t := sim.tick - 1.0 + arena.render_alpha
		var z := finisher.zoom(t, maxf(0.0, _hold))
		var target := finisher.focus(arena.ball_pos(sim.balls[finisher.loser]), arena.ball_pos(sim.balls[finisher.winner]), z)
		var start := not arena_clip.clip_contents
		arena.set_camera(z, target if start else FinisherCam.follow(arena.cam_focus, target, delta))
		arena.finisher_amount = clampf(finisher.progress(t) / 0.25, 0.0, 1.0)
		arena_clip.clip_contents = true
	arena.advance_effects(delta * rate)
	return _hold >= FinisherCam.HOLD


## Fresh effects, camera and finisher plan for a fight about to play.
func _prepare_fight(config: Dictionary) -> void:
	arena.sim = sim
	arena.aim_dir = Vector2.ZERO
	arena.clear_effects()
	arena.reset_camera()
	arena_clip.clip_contents = false
	finisher = FinisherCam.plan(config)
	_accumulator = 0.0
	_hold = -1.0
	_skipped = false


## Back to the whole arena, keeping the KO face on the critter that fell.
func _unzoom() -> void:
	arena.finisher_amount = 0.0
	arena.set_camera(1.0, Vector2.ONE * MatchSim.ARENA_SIZE / 2.0)
	arena_clip.clip_contents = false


func _show_result() -> void:
	state = State.RESULT
	_unzoom()
	_reset_clip()
	if mode == Mode.TUTORIAL:
		print("MATCH_END winner=%d reason=%s ticks=%d hash=%s" % [sim.winner, sim.end_reason, sim.tick, sim.state_hash()])
		_show_only(null)
		sfx.on_result(0 if sim.winner == tutorial_side else 1)
		tutorial_fight_ended.emit(sim.winner)
		return
	var you := sim.balls[you_side]
	var replay := mode == Mode.REPLAY
	var names := [sim.balls[0].def.display_name, sim.balls[1].def.display_name] if replay else ["You", "The foe"]
	if you_side == 1:
		names.reverse()
	var result := ResultText.describe(sim, names, replay, you_side)
	result_label.text = result.headline
	result_label.modulate = result.color
	_label_result_buttons()
	var dealt := you.damage_dealt
	var healed := you.healed
	if sim.starters == 4: # A 2v2 counts the whole pair (and any split-offs).
		dealt = 0.0
		healed = 0.0
		for b in sim.balls:
			if b.team == you_side:
				dealt += b.damage_dealt
				healed += b.healed
	info_label.text = "%.1fs. %s dealt %d damage%s." % [sim.time(), "P1" if replay else ("Your pair" if sim.starters == 4 else "You"),
		roundi(dealt), (" and healed %d" % roundi(healed)) if healed > 0.0 else ""]
	if result.detail != "":
		info_label.text = "%.1fs. %s" % [sim.time(), result.detail]
	report_label.text = "Report code: " + _report_code()
	if _board_pick >= 0:
		info_label.text = ("You called it! " if sim.winner == _board_pick else "Not your call this time. ") + info_label.text
	if mode == Mode.RIVAL and _count_fight:
		_record_rival()
	if mode == Mode.CAMPAIGN:
		_finish_stage()
	if mode == Mode.LIVE:
		_finish_live()
	# A replay counts once, not again for every Replay tap.
	if _count_fight or (mode == Mode.REPLAY and _report_code() != _last_logged_fight):
		_last_logged_fight = _report_code()
		Analytics.track("fight_end", {"mode": "fight_of_day" if _board_pick >= 0 else Mode.keys()[mode].to_lower(),
			"picked": mode != Mode.REPLAY, "team": [player_type, sim.balls[2].type_id] if sim.starters == 4 else [player_type],
			"foe": [opponent_type, sim.balls[3].type_id] if sim.starters == 4 else [opponent_type],
			"result": Analytics.result_of(sim.winner), "secs": snappedf(sim.time(), 0.1)})
	if _count_fight:
		_count_fight = false
		_record_fight()
	print("MATCH_END winner=%d reason=%s ticks=%d hash=%s" % [sim.winner, sim.end_reason, sim.tick, sim.state_hash()])
	_show_only(result_box)
	sfx.on_result(sim.winner if sim.winner < 0 else int(sim.winner != you_side))
	if mode == Mode.CAMPAIGN:
		_return_with_result()
		return
	if auto_clip:
		auto_clip = false
		_on_clip_button()


func _report_code() -> String:
	var code := "BB1.%s.%s.%d.%d.%s" % [player_type, opponent_type, seed_value, aim, _build_stamp().replace(" ", "")]
	if _pick_arena() != "square":
		code += "." + _pick_arena()
	code += "." + modifier if modifier != Modifiers.NONE else ""
	var t := _fight_tiers()
	return code + (".t%d%d" % t if t[0] > 0 else "")


# --- Live fights ------------------------------------------------------------
# FIGHT! with live fights on (Settings > Testing, or ?live=ws://...): the
# server pairs you with a real player near your power, both aim, the server
# runs the fight and sends both angles; this phone replays it and reports its
# end hash. No trophies or rewards: just for fun. design/live-quick-fight.md.

func _live_on() -> bool:
	return Dev.live_fights() and mode == Mode.NORMAL


## The sim side you're on, for the rings, health bars, sounds and result.
func _set_side(side: int) -> void:
	you_side = side
	arena.you_side = side
	fight_hud.you_side = side
	sfx.you_side = side


## What you bring: your best copy (tier, level, gear, talents), or the Quick
## fight tier you picked for testing.
func _live_slot(id: String) -> Dictionary:
	if pick_tiers[0] > 0 or profile == null or not profile.owns(id):
		return Lineup.make(id, maxi(1, pick_tiers[0]))
	return profile.slot_of(id)


func _find_live() -> void:
	_close_live()
	live = {}
	mode = Mode.NORMAL
	state = State.MENU
	info_label.text = "Connecting to the live server..."
	_show_only(live_box)
	var token := "guest-%d" % _rng.randi()
	if backend.enabled() and await backend.ensure_session():
		token = str(backend.session.get("access_token", token))
	if not live_box.visible or live_client != null: # Cancelled while signing in.
		return
	live_client = LiveClient.new()
	add_child(live_client)
	live_client.message.connect(_on_live)
	live_client.closed.connect(_on_live_closed)
	live_client.start(Dev.live_url(), {"t": "hello", "token": token, "sim_version": SimVersion.get_version()})
	print("LIVE_CONNECT ", Dev.live_url())


func _on_live(msg: Dictionary) -> void:
	match str(msg.get("t", "")):
		"welcome":
			var slots := [_live_slot(player_type)]
			if duo:
				slots.append(_live_slot(_mate()))
			live_client.send({"t": "queue", "mode": "2v2" if duo else "1v1", "slots": slots})
		"queued":
			info_label.text = "Looking for a live foe near your power..."
			print("LIVE_QUEUED rating=%d" % int(msg.get("rating", 0)))
		"matched":
			live = msg
			mode = Mode.LIVE
			_set_side(int(msg.get("side", 0)))
			_live_aim_left = float(msg.get("aim_seconds", 12.0)) - 1.0 # Lock in before the server's deadline.
			print("LIVE_MATCHED match=%d side=%d" % [int(msg.get("match", 0)), you_side])
			_begin_aim()
			_tick_live_aim(0.0)
		"go":
			if mode != Mode.LIVE or int(msg.get("match", -1)) != int(live.get("match", -2)):
				return
			live.angles = msg.angles
			live.go = msg
			sfx.play("launch")
			_start_fight()
		"ghost":
			_close_live()
			_begin_aim()
			info_label.text = "No live foe right now, so here's a practice fight. Drag to aim!"
		"error":
			var code := str(msg.get("code", ""))
			_cancel_live()
			info_label.text = "Live fights need the latest version: reload the game." if code == "update" \
				else "The live server turned us away (%s)." % code
			print("LIVE_ERROR ", code)


func _on_live_closed(reason: String) -> void:
	live_client = null
	print("LIVE_CLOSED ", reason)
	if state == State.FIGHT or state == State.RESULT:
		return # The fight's already in: nothing is lost.
	_cancel_live()
	info_label.text = "Lost the live server (%s). Try again in a bit." % reason


## The aim clock: launches whatever you've aimed when it runs out.
func _tick_live_aim(delta: float) -> void:
	_live_aim_left -= delta
	var text := "LIVE vs %s! Aim and launch: %ds" % [sim.balls[1 - you_side].def.display_name, ceili(maxf(0.0, _live_aim_left))]
	if info_label.text != text:
		info_label.text = text
	if _live_aim_left <= 0.0 or auto_start:
		_launch()


func _live_launch() -> void:
	if live.has("aimed") or live_client == null:
		return
	live.aimed = true
	_dragging = false
	live_client.send({"t": "aim", "match": int(live.match), "angle": aim})
	info_label.text = "Locked in! Waiting for your foe's shot..."
	_show_only(null)


## Tells the server this phone's end hash (it only compares) and shows
## whether the two agreed.
func _finish_live() -> void:
	var go: Dictionary = live.get("go", {})
	var mine := sim.state_hash()
	var same := mine == str(go.get("hash", ""))
	if live_client != null:
		live_client.send({"t": "hash", "match": int(live.match), "hash": mine})
		_close_live()
	print("LIVE_END %s winner=%d server_winner=%d side=%d hash=%s" % ["ok" if same else "MISMATCH",
		sim.winner, int(go.get("winner", -1)), you_side, mine])
	report_label.text = "Live match: the server's fight matched yours." if same \
		else "Live match: your fight differed from the server's. Its result counts."


func _cancel_live() -> void:
	_close_live()
	live = {}
	if mode == Mode.LIVE:
		mode = Mode.NORMAL
	_show_menu()


func _close_live() -> void:
	if live_client != null:
		live_client.stop()
		live_client = null


# --- Campaign -------------------------------------------------------------------

func _load_profile() -> void:
	var now := int(Time.get_unix_time_from_system())
	var d = save.data.get("profile")
	if profile != null and profile.changed.is_connected(_save_profile):
		profile.changed.disconnect(_save_profile)
	if demo_profile:
		profile = preload("res://game/ui/ui_profile.gd").sample()
		profile_unsaved = true
		for k in Zones.zone(0).stages.size() if demo_stars > 0 else 0:
			profile.stars[Zones.stage_key(0, k)] = demo_stars
		# &zones=2: the first N zones fully starred (opens later bosses).
		for z in clampi(int(url_params.get("zones", "0")), 0, Zones.ZONES.size()):
			for k in Zones.zone(z).stages.size():
				profile.stars[Zones.stage_key(z, k)] = maxi(1, demo_stars)
	else:
		profile = Profile.from_dict(d, now) if d is Dictionary else Profile.new_game(now)
		# A new save opened from a link or a test URL skips the guided first
		# fights, like it skips the tutorial (game/ui/intro.gd).
		if not d is Dictionary and not url_params.is_empty():
			profile.intro = Profile.INTRO_DONE
			Story.skip_all(profile)
	if demo_profile:
		Story.skip_all(profile)
		# ?demo=1&copies=N adds N more owned copies (a big collection, for perf checks).
		var extra := int(url_params.get("copies", "0"))
		for i in extra:
			var id: String = Roster.CRITTERS[i % Roster.CRITTERS.size()].id
			profile.stacks.append({"id": id, "tier": 1 + i % 3, "count": 1, "level": 1 + i % 20})
			profile.seen[id] = true
	# ?story=1 plays every chapter's story again (screenshots, playtests).
	if url_params.get("story", "") == "1":
		profile.story.clear()
	# ?intro=N jumps the guided first fights to step N (0 = just out of the tutorial).
	if str(url_params.get("intro", "")).is_valid_int():
		profile.intro = clampi(int(url_params.intro), 0, Profile.INTRO_DONE)
	profile.changed.connect(_save_profile)
	FightSpeed.account_level = profile.account_level


func _save_profile() -> void:
	if profile_unsaved:
		return
	FightSpeed.account_level = profile.account_level
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
	sfx.toggle_hidden = false
	_begin_aim()
	info_label.text = "%s: %s. Drag to aim, then let go." % [Zones.stage_key(zone_index, stage_index), _pve_matchup_text()]


## A farming boss run from its screen ("vault" for the Anvil King, "nest" for
## the Brood Queen): aim, then fight it in the arena.
func _start_boss(config: Dictionary, difficulty: int, fighter: String, screen: String) -> void:
	pve = {"config": config, "vault": difficulty, "fighter": fighter, "boss": screen}
	mode = Mode.CAMPAIGN
	player_type = config.p1
	opponent_type = config.p2
	seed_value = config.seed
	foe_aim = null
	shell_layer.visible = false
	sfx.toggle_hidden = false
	_begin_aim()
	info_label.text = "%s %s: %s. Drag to aim, then let go." % [Bosses.DEFS[config.p2].display_name, _boss_rules().DIFFICULTIES[difficulty].name, _pve_matchup_text()]


## "Power 2,250 vs 3,100" for a 2v2 pairs stage, short enough for one line.
func _pair_power_text() -> String:
	var mine := 0
	for id in [pve.config.p1, pve.config.p3]:
		mine += profile.power_of(id)
	var st := Zones.stage(pve.zone, pve.stage)
	return "Power %s vs %s" % [Kit.commas(mine), Kit.commas(Campaign.enemy_rating(pve.zone, pve.stage) * Zones.enemies(st).size())]


## The rules script of the boss being fought (meta/gear_vault.gd, meta/brood_nest.gd).
func _boss_rules():
	return BOSS_MODES[pve.get("boss", "vault")][0]


## "T2 Optic · 1,250 power vs T1 Chomp · 1,400 power" for the stage or Vault run being fought.
func _pve_matchup_text() -> String:
	if pve.config.has("p3"):
		return CampaignScreen.pair_text(profile, pve.zone, pve.stage, [pve.config.p1, pve.config.p3])
	if not pve.has("vault"):
		return CampaignScreen.matchup_text(profile, pve.zone, pve.stage, pve.fighter)
	var b: Dictionary = profile.best(pve.fighter)
	return "%s vs %s" % [FighterTag.text(Roster.get_critter(pve.fighter).name, b.get("tier", 1), profile.power_of(pve.fighter), b.get("level", 0)),
		FighterTag.text(Bosses.DEFS[pve.config.p2].display_name, 1, Power.rating(pve.config.powers[1]))]


## ?pve=1-3: a fresh, unsaved profile fights that stage (for smoke tests).
func _start_url_stage() -> void:
	var parts := pve_param.split("-")
	var z := clampi(int(parts[0]) - 1, 0, Zones.ZONES.size() - 1)
	var i := clampi(int(parts[1]) - 1, 0, Zones.zone(z).stages.size() - 1)
	var now := int(Time.get_unix_time_from_system())
	profile = Profile.new_game(now)
	profile.intro = Profile.INTRO_DONE
	Story.skip_all(profile)
	profile_unsaved = true
	shell.set_profile(profile)
	for zk in z:
		for k in Zones.zone(zk).stages.size():
			profile.stars[Zones.stage_key(zk, k)] = 1
	for k in i:
		profile.stars[Zones.stage_key(z, k)] = 1
	if Zones.zone(z).lineup == 2:
		# A pairs stage (?pve=2-1) is a 2v2: lend the starter a mate.
		profile.add_copies(["laser" if Profile.STARTER != "laser" else "vampire"])
		var picks := Campaign.team_for(profile, 2)
		_start_stage(Campaign.pair_config(profile, Campaign.start_team(profile, z, i, picks, now)), z, i, picks[0])
	else:
		_start_stage(Campaign.start(profile, z, i, Profile.STARTER, now), z, i, Profile.STARTER)
	if auto_start:
		_start_fight()


func _finish_stage() -> void:
	var fight := sim.summary()
	fight.max_hp = sim.balls[0].max_hp
	if pve.has("vault"):
		fight.cracked = int(sim.boss.state.get("cracked", 0)) if sim.boss != null else 0
		fight.boss_dealt = sim.boss.max_hp - maxf(0.0, sim.boss.hp) if sim.boss != null else 0.0
		fight.boss_max = sim.boss.max_hp if sim.boss != null else 1.0
		var v: Dictionary = _boss_rules().finish(profile, pve.vault, pve.fighter, fight, int(Time.get_unix_time_from_system()))
		pve.result = BOSS_MODES[pve.boss][1].result_text(v)
		pve.xp = v
		report_label.text = pve.result
		print("BOSS_END boss=%s difficulty=%d won=%s" % [pve.boss, pve.vault, v.won])
		return
	var r := Campaign.finish(profile, pve.zone, pve.stage, pve.fighter, fight) if sim.starters == 2 \
		else Campaign.finish_team(profile, pve.zone, pve.stage, [pve.config.p1, pve.config.p3], Campaign.pair_fight(sim))
	Intro.after_stage(profile, pve.zone, pve.stage, r)
	pve.result = CampaignScreen.result_text(r)
	pve.r = r
	report_label.text = pve.result
	print("STAGE_END stage=%s won=%s stars=%d drops=%d" % [Zones.stage_key(pve.zone, pve.stage), r.won, r.stars, r.drops.size()])


## A campaign stage or Vault run has one results popup (stars, drops, XP) on
## the screen it came from, so the arena only flashes the headline and then
## goes straight back to it with the popup up.
func _return_with_result() -> void:
	report_label.text = ""
	campaign_row.visible = false
	var fight_sim := sim
	await get_tree().create_timer(1.1).timeout
	if state == State.RESULT and mode == Mode.CAMPAIGN and sim == fight_sim:
		_back_to_campaign()


## Backing out of aiming. A campaign stage has already spent its energy, so
## leaving before launch refunds it.
func _aim_back() -> void:
	if mode == Mode.LIVE:
		_cancel_live()
		return
	if mode != Mode.CAMPAIGN:
		_show_menu()
		return
	if pve.has("vault"):
		_boss_rules().cancel(profile, int(Time.get_unix_time_from_system()))
	else:
		profile.refund_energy(Zones.cost(Zones.stage(pve.zone, pve.stage)))
	_back_to_campaign()


## Back from a pairs or trios stage (game/campaign_relay.gd): settle it and
## open the stage list on it, with the results popup.
func _settle_relay_stage() -> void:
	var relay_scene = load("res://game/campaign_relay.gd")
	var d: Dictionary = relay_scene.done
	relay_scene.done = {}
	var params := {"zone": d.zone, "focus": d.stage}
	if d.get("refund", false):
		profile.refund_energy(Zones.cost(Zones.stage(d.zone, d.stage)))
	else:
		var r := Campaign.finish_team(profile, d.zone, d.stage, d.picks, d.fight)
		Intro.after_stage(profile, d.zone, d.stage, r)
		params.result = {"stage": d.stage, "r": r, "kind": "fight"}
	shell.show_tab("play")
	shell.go("world")
	shell.go("campaign", params)


func _back_to_campaign() -> void:
	var params := {"zone": pve.get("zone", 0)}
	var vault := pve.has("vault")
	var screen: String = pve.get("boss", "vault")
	if vault and pve.has("result"):
		params.notice = pve.result
		params.xp = pve.get("xp", {})
		# Back on the level just fought, or the next one after a win (boss_level_grid.gd).
		params.level = int(pve.vault) + (1 if params.xp.get("won", false) else 0)
	if pve.has("r"):
		params.result = {"stage": pve.stage, "r": pve.r, "kind": "fight"}
	if pve.has("stage") and not vault:
		params.focus = pve.stage
	mode = Mode.NORMAL
	_board_pick = -1
	pve = {}
	_show_menu()
	_show_home()
	shell.show_tab("play")
	if vault:
		shell.go(screen, params)
	else:
		shell.go("world") # Back from the stage list lands on the world map.
		shell.go("campaign", params)


# --- Save and online ----------------------------------------------------------

func _apply_picks() -> void:
	var picks: Dictionary = save.data.picks
	if str(picks.player) in BallDefs.PLAYABLE:
		player_type = picks.player


## Settings that follow the player across devices (just fight speed; sound
## and accessibility stay per device). A save from before they were synced
## takes this device's choice.
func _sync_settings(boot: bool) -> void:
	var s = save.data.get("settings")
	if s is Dictionary and s.has("fight_speed"):
		FightSpeed.restore(int(s.fight_speed))
	elif boot and FightSpeed.pick() != 0:
		save.data["settings"] = {"fight_speed": FightSpeed.pick()}
		save.commit()


## Today's Try-a-Critter loaner, for a player who doesn't own it.
func _is_loan(id: String) -> bool:
	return shell != null and Loaner.is_loan(shell.profile, id)


func _record_fight() -> void:
	# A loaner is practice: no stats, no aim history, never your ghost.
	if _is_loan(player_type):
		return
	if mode != Mode.CAMPAIGN:
		save.data.picks = {"player": player_type, "opponent": opponent_choice, "speed": FightSpeed.index()}
	save.record_fight(sim.winner, GhostLineup.aim_offset(aim))
	var xp: int = shell.glow.record_fight(sim.winner, sim.balls[0].damage_dealt)
	if xp > 0:
		info_label.text += " +%d pass XP." % xp
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
	_watch_timer = Timer.new()
	_watch_timer.wait_time = 3.0
	_watch_timer.timeout.connect(_watch_save)
	add_child(_watch_timer)
	_watch_timer.start()
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
	_synced_edits = save.edits
	await save.sync(backend)
	await _publish_lineup()


## Syncs as soon as anything in the save changed (the 60 s retry timer
## covers changes that couldn't go up, e.g. offline).
func _watch_save() -> void:
	save.capture_files()
	if save.dirty and save.edits != _synced_edits:
		_sync_online()


## The save was replaced (a newer cloud copy, another account): show it.
func _on_save_changed() -> void:
	_sync_settings(false)
	# Onboarding owns the arena until it ends; tutorial_end applies the picks.
	# Still take the new profile, so tutorial_end sees its progress and keeps
	# it instead of the onboarding's fresh one.
	if mode == Mode.TUTORIAL:
		if not profile_unsaved:
			_load_profile()
		# A new device whose cloud copy already finished the onboarding
		# (another device, the shared test account) goes straight to the game.
		if Onboarding.is_done() and not url_params.has("tutorial"):
			for c in get_children():
				if c.get_script() == Onboarding:
					c.leave()
		return
	if not url_picks:
		_apply_picks()
	# A newer cloud copy or another account: its profile replaces this one.
	if not profile_unsaved:
		_load_profile()
		shell.set_profile(profile)
		if shell.glow != null:
			shell.glow.profile = profile
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
	# Leaving it: send this device's changes before the phone suspends the tab.
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_FOCUS_OUT] \
			and backend != null and backend.enabled() and _retry_timer != null:
		_sync_online()


## Keeps this player's Ghost Arena defence in step with their lineup critter,
## as they own it (tier, level, gear). Nobody becomes a ghost before their
## first fight (so test runs and drive-by visits don't fill the opponent pool
## with idle lineups).
func _publish_lineup() -> void:
	if int(save.data.stats.fights) == 0 or profile == null:
		return
	var mine: Dictionary = profile.slot_of(profile.lineup)
	if mine.is_empty():
		return
	var lineup := GhostLineup.make([mine], save.data.aim_offsets)
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
	ui_layer = layer
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = _neon_theme()
	layer.add_child(ui)

	title_label = _label("BATTLE BALLS", 40)
	title_label.add_theme_color_override("font_outline_color", Color(ACCENT, 0.45))
	title_label.add_theme_constant_override("outline_size", 12)
	hud_label = _label("", 30)
	fight_hud = FightHud.new()
	fight_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fight_hud)
	info_label = _label("", 26)
	info_label.add_theme_color_override("font_color", MUTED)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stamp_label = _label(_stamp_text(), 18)
	stamp_label.modulate = Color(1, 1, 1, 0.45)
	stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Quick fight: pick a critter, then the seed/arena line and its buttons,
	# then one big FIGHT!. Every row fits the panel width at any text size.
	menu_box = VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 14)
	# The caption carries the seed and arena, so the arena above gets the room.
	seed_label = Kit.caption("")
	seed_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	menu_box.add_child(seed_label)
	menu_box.add_child(_pick_grid(BallDefs.PLAYABLE, _pick_player))
	new_seed_button = _button("New seed", func(): seed_value = _rng.randi_range(1, 99999); _refresh_menu(), 22, "ghost", 96)
	# Debug toggle for Chaos Weekend modifiers until the event screen exists.
	rules_button = _button("", _cycle_rules, 22, "ghost", 68)
	# Tiers to test with: tap to cycle equal stats, then one to five stars.
	tier_buttons = [_tier_button(0), _tier_button(1)]
	duo_button = _button("1v1", _toggle_duo, 22, "ghost", 68)
	menu_box.add_child(_row(tier_buttons + [duo_button, rules_button]))
	fight_button = _button("FIGHT!", func(): _find_live() if _live_on() else _begin_aim(), 40, "go", 96)
	fight_button.size_flags_stretch_ratio = 2.0
	menu_box.add_child(_row([_button("Home", _show_home, 22, "ghost", 96), new_seed_button, fight_button]))

	launch_button = _button("Launch", _launch, 34, "go", 96)
	aim_back_button = _button("Back", _aim_back, 26, "ghost", 96)
	aim_box = _row([launch_button, aim_back_button])
	live_box = _row([_button("Cancel", _cancel_live, 26, "ghost", 96)])

	speed_picker = FightSpeed.picker()
	fight_box = _row([speed_picker, _button("Skip", _skip_to_end)])

	result_box = VBoxContainer.new()
	result_box.add_theme_constant_override("separation", 14)
	result_label = _label("", 56)
	result_box.add_child(result_label)
	report_label = _label("", 20)
	report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_box.add_child(report_label)
	again_button = _button("Rematch", _again, 30, "primary")
	result_box.add_child(_row([_button("Replay", func(): _start_fight()), again_button]))
	share_button = _button("Share fight", _share.bind("r"))
	challenge_button = _button("Challenge", _on_challenge_button)
	result_box.add_child(_row([share_button, challenge_button]))
	clip_button = _button("Save clip", _on_clip_button, 22, "ghost", 72)
	copy_button = _button("Copy report", func(): DisplayServer.clipboard_set(_report_code()); report_label.text = "Copied: " + _report_code(), 22, "ghost", 72)
	change_button = _button("Change critter", _play_normal, 22, "ghost", 72)
	report_row = _row([clip_button, copy_button, change_button])
	result_box.add_child(report_row)
	friend_button = _button("Add as a friend", _add_link_friend, 22, "ghost", 72)
	friend_row = _row([friend_button])
	friend_row.visible = false
	result_box.add_child(friend_row)
	campaign_row = _row([_button("Back to the map", _back_to_campaign)])
	result_box.add_child(campaign_row)


	for c in [title_label, hud_label, info_label, stamp_label, menu_box, aim_box, fight_box, result_box, live_box]:
		ui.add_child(c)


func _build_shell() -> void:
	shell_layer = CanvasLayer.new()
	shell_layer.layer = 5
	shell_layer.visible = false
	add_child(shell_layer)
	shell = Shell.new()
	shell.glow = GlowState.new(save, shell.profile, Store.new())
	shell.friends = friends
	shell.profile = profile
	shell.set_account(account)
	shell.link_base = _link_base()
	shell.sfx = sfx
	shell.play_requested.connect(func():
		shell_layer.visible = false
		sfx.toggle_hidden = false
		_use_lineup()
		# A loaner (Try-a-Critter) wins over your own fighter for this fight.
		if shell.play_with in BallDefs.PLAYABLE:
			player_type = shell.play_with
		shell.play_with = ""
		_play_normal())
	shell.watch_requested.connect(_watch_board_fight)
	shell.backend = backend
	shell.rival_requested.connect(_start_rival)
	shell.stage_requested.connect(_start_stage)
	shell.boss_requested.connect(_start_boss)
	shell.share_tapped.connect(_on_shell_share)
	shell.share_layout_changed.connect(_sync_share_targets)
	shell_layer.add_child(shell)
	LiveOps.fetch(self, func(): if shell.current in ["play", "week", "bracket"]: shell.refresh())


## Quick fight starts on the fighter chosen in the home screen (Use in lineup).
func _use_lineup() -> void:
	var id := str(shell.profile.lineup)
	if id in BallDefs.PLAYABLE:
		player_type = id


## Picking on Quick fight also makes that critter your fighter, when you own it.
func _pick_player(id: String) -> void:
	if _is_duo():
		# Your pair is the last two critters tapped; tapping one already in it keeps the pair.
		if id != player_type and id != _mate():
			mate_type = player_type
			player_type = id
		_refresh_menu()
		return
	player_type = id
	if mode == Mode.NORMAL and shell != null:
		shell.profile.set_lineup(id)
	_refresh_menu()


func _show_home() -> void:
	shell_layer.visible = true
	sfx.toggle_hidden = true # Home has the sound switch in Settings.
	_sync_share_targets()


## What a swipe in from the left edge does: the shell's Back on the home
## screens, Home from the Quick fight menu, the menu from a result. Not while
## aiming or fighting (the arena owns those drags).
func _swipe_back() -> Callable:
	if shell_layer != null and shell_layer.visible:
		return shell.back_action()
	if mode == Mode.TUTORIAL:
		return Callable()
	if live_client != null and state != State.FIGHT:
		return _cancel_live
	if mode == Mode.CAMPAIGN:
		return _back_to_campaign if state == State.RESULT else Callable()
	match state:
		State.MENU:
			return _show_home
		State.RESULT:
			return _back_to_board if not _board.is_empty() else _show_menu
	return Callable()


## Portrait stacks arena over controls; wide screens put controls beside the
## arena. Either way the arena shrinks before the controls are pushed off screen.
func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var top := TOP
	var bottom_margin := 90.0 ## Clears the build stamp and the sound toggle.
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
		panel_pos = Vector2((size.x - panel_width) / 2.0, top + side + 12.0)
	var arena_pos := Vector2(left, top)
	if state == State.CLIP:
		clip_card.position = ((size - ClipCard.SIZE) / 2.0).floor()
		arena_pos = clip_card.position + ClipCard.ARENA_POS
		side = ClipCard.ARENA_SIDE
	arena.view_scale = side / MatchSim.ARENA_SIZE
	arena_clip.position = arena_pos
	arena_clip.size = Vector2(side, side)
	arena.set_camera(arena.cam_zoom, arena.cam_focus)
	_place(title_label, Vector2(0, 14), Vector2(size.x, 56))
	_place(hud_label, Vector2(left, 72), Vector2(side, 48))
	_place(fight_hud, Vector2(left, 60), Vector2(side, 62))
	_place(info_label, panel_pos, Vector2(panel_width, INFO_HEIGHT - 6.0))
	controls_rect = Rect2(panel_pos, Vector2(panel_width, maxf(INFO_HEIGHT + CONTROLS_HEIGHT, size.y - panel_pos.y - bottom_margin)))
	var controls_top := panel_pos.y + INFO_HEIGHT
	for box in [menu_box, aim_box, fight_box, result_box, live_box]:
		_place(box, Vector2(panel_pos.x, controls_top), Vector2(panel_width, maxf(CONTROLS_HEIGHT, size.y - controls_top - bottom_margin)))
	# The build stamp stops short of the sound toggle in the other corner.
	_place(stamp_label, Vector2(16, size.y - 40), Vector2(maxf(100.0, size.x - Sfx.TOGGLE_SIZE.x - 48.0), 30))
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
	_sync_cover()
	for b in [menu_box, aim_box, fight_box, result_box, live_box]:
		b.visible = b == box
	aim_back_button.visible = mode != Mode.TUTORIAL
	_sync_share_targets()


func _update_hud() -> void:
	hud_label.text = ""
	if sim == null:
		fight_hud.show_fight(null)
		title_label.visible = true
		return
	var clock := "%.0fs" % sim.time()
	if sim.in_overtime():
		clock = "OVERTIME x%.1f" % sim.damage_multiplier()
	var tags: Array = ["P1", "P2"] if mode == Mode.REPLAY else ["YOU", "FOE"]
	if mode == Mode.LIVE:
		tags = ["YOU", "LIVE FOE"]
	if mode == Mode.TUTORIAL and not tutorial_tags.is_empty():
		tags = tutorial_tags
	fight_hud.tags = tags.map(func(t): return str(t).to_upper())
	if _stats_for != sim:
		_stats_for = sim
		fight_hud.stats = ["", ""] if sim.starters == 4 else [_side_stats(0), _side_stats(1)]
	fight_hud.show_fight(sim, clock)
	# The bars (four in a 2v2, or two with their tier and power lines) take
	# the title's room above the arena.
	var tall := sim.starters == 4
	title_label.visible = false
	fight_hud.position.y = 8.0 if tall else 24.0
	fight_hud.size.y = TOP - 10.0 if tall else TOP - 30.0


## Under a side's health bar: "T5 · Lv25 · 5,481 power", or just "T3" where
## level and power aren't known (only campaign and boss fights carry them).
func _side_stats(side: int) -> String:
	var ts: Array = sim.config.get("tiers", [])
	var parts := ["T%d" % (int(ts[side]) if side < ts.size() else 1)]
	if mode != Mode.CAMPAIGN or pve.is_empty():
		return parts[0]
	if side == 0 and sim.balls[0].type_id == pve.fighter:
		var b: Dictionary = profile.best(pve.fighter)
		if int(b.get("level", 0)) > 0:
			parts.append("Lv%d" % int(b.level))
		parts.append("%s power" % Kit.commas(profile.power_of(pve.fighter)))
	elif side == 1:
		var rating := Power.rating(pve.config.powers[1]) if pve.has("vault") else Campaign.enemy_rating(pve.zone, pve.stage)
		parts.append("%s power" % Kit.commas(rating))
	return " · ".join(parts)


## The seed picks the arena too, independently of the opponent it picks.
func _pick_arena() -> String:
	if arena_override != "":
		return arena_override
	return Arenas.pick(seed_value)


func _skip_to_end() -> void:
	_skipped = true
	while not sim.finished:
		sim.step()
	arena.clear_effects()
	arena.reset_camera()
	arena_clip.clip_contents = false


func _again() -> void:
	match mode:
		Mode.LIVE:
			mode = Mode.NORMAL
			_find_live()
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
	if not _board.is_empty():
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
	again_button.text = {Mode.NORMAL: "Rematch", Mode.CHALLENGE: "Try again", Mode.REPLAY: "Beat this shot", Mode.RIVAL: "Rematch", Mode.CAMPAIGN: "", Mode.LIVE: "Fight again"}[mode]
	challenge_button.text = {Mode.REPLAY: "Play my own", Mode.RIVAL: "Friends"}.get(mode, "Challenge friend")
	if not _board.is_empty():
		challenge_button.text = "Bracket" if _board.return_to == "bracket" else "This Week"
	share_button.text = "Send result" if mode == Mode.CHALLENGE else "Share fight"
	# A link from someone who isn't a friend yet offers to add them, in place
	# of the report row (there's only room for one).
	friend_row.visible = _can_add_link_friend()
	report_row.visible = mode != Mode.CAMPAIGN and not friend_row.visible
	copy_button.visible = mode != Mode.REPLAY and mode != Mode.LIVE
	change_button.visible = mode != Mode.REPLAY
	# Save clip rides in whichever of the two rows is showing.
	var row := friend_row if friend_row.visible else report_row
	if clip_button.get_parent() != row:
		clip_button.reparent(row)
		row.move_child(clip_button, 0)
	for r in [again_button.get_parent(), share_button.get_parent()]:
		r.visible = mode != Mode.CAMPAIGN
	# Fight links and clips are 1v1 only for now.
	# Live fights aren't shareable yet: a link replays from the seed, not the server's sides.
	share_button.get_parent().visible = share_button.get_parent().visible and not _is_duo() and mode != Mode.LIVE
	clip_button.visible = not _is_duo() and mode != Mode.LIVE
	copy_button.visible = copy_button.visible and not _is_duo()
	campaign_row.visible = mode == Mode.CAMPAIGN
	(campaign_row.get_child(0) as Button).text = ("Back to the " + Bosses.DEFS[pve.config.p2].display_name) if pve.has("vault") else "Back to the map"
	if friend_row.visible and not friend_button.disabled:
		var who: String = friends.invite.get("name", "")
		friend_button.text = "Add %s as a friend" % who if who != "" else "Add them as a friend"
	_sync_share_targets()


func _can_add_link_friend() -> bool:
	if link_friend == "" or mode not in [Mode.CHALLENGE, Mode.REPLAY] or not _board.is_empty() or friends.status != "ready":
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
	_board = {}
	rival = f
	opponent_choice = lead
	opponent_type = lead
	seed_value = _rng.randi_range(1, 99999)
	shell_layer.visible = false
	sfx.toggle_hidden = false
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
	_board = {}
	opponent_choice = ball
	opponent_type = ball
	seed_value = challenge_seed
	foe_aim = FightLink.mirror_angle(challenge_aim)
	_show_menu()


## Back to picking your ball against a random foe, dropping any link the page was opened with.
func _play_normal() -> void:
	_board_pick = -1
	_board = {}
	opponent_choice = OPPONENT_RANDOM
	mode = Mode.NORMAL
	foe_aim = null
	modifier = _weekend_modifier()
	arena_override = url_arena
	rival = {}
	if OS.has_feature("web"):
		JavaScriptBridge.eval("history.replaceState(null, '', location.pathname)")
	_show_menu()


## Watch the Fight of the Day from the This Week board, as a replay.
func _watch_board_fight(f: Dictionary) -> void:
	shell_layer.visible = false
	sfx.toggle_hidden = false
	mode = Mode.REPLAY
	player_type = f.p1
	opponent_choice = f.p2
	opponent_type = f.p2
	seed_value = f.seed
	aim = f.angles[0]
	foe_aim = f.angles[1]
	modifier = Modifiers.NONE ## The Fight of the Day's known result is on normal rules.
	link_tiers = [0, 0]
	arena_override = f.get("arena", "square")
	_board_pick = f.pick
	_board = {"title": f.get("board_title", "Fight of the Day"), "return_to": f.get("return_to", "week"), "return_params": f.get("return_params", {})}
	_start_fight()


func _back_to_board() -> void:
	var from := _board
	_play_normal()
	_show_home()
	shell.show_tab("play")
	shell.go("week")
	if from.return_to != "week":
		shell.go(from.return_to, from.return_params)


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", A11y.font(font_size))
	l.set_meta("base_font", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A Neon Critters kit button (game/ui/ui_kit.gd) in the arena's own words:
## kept in the case it's written, sharing its row equally with its neighbours
## and trimming its text rather than pushing the row off screen.
func _button(text: String, on_press: Callable, font_size := 26, kind := "ghost", height := 84) -> Button:
	var b := Kit.button(text, on_press, kind, font_size, height)
	b.text = text
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return b


func _row(children: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for c in children:
		row.add_child(c)
	return row


## A pick tile in its rarity's colour: Common stays plain, the rest get a
## tinted background and a border in the colour the critter list uses.
func _rarity_style(b: Button, id: String) -> void:
	var rarity := str(Roster.get_critter(id).get("rarity", "common"))
	if rarity == "common":
		return
	for st in ["normal", "hover"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Roster.rarity_bg(rarity, Color("1b1842"), .22 if st == "normal" else .3)
		box.border_color = Roster.rarity_border(rarity, Color("1b1842"))
		box.set_border_width_all(3)
		box.set_corner_radius_all(22)
		b.add_theme_stylebox_override(st, box)


## Every fightable critter as a tile (icon + name), three across. Past two
## rows the grid scrolls, so new critters just appear. No button group:
## _refresh_menu presses the picked tile (two of them in a 2v2).
func _pick_grid(ids: Array, on_pick: Callable) -> ScrollContainer:
	var grid := GridContainer.new()
	grid.columns = PICK_COLUMNS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for id in ids:
		var b := Button.new()
		b.pressed.connect(on_pick.bind(id))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, PICK_TILE_HEIGHT)
		b.size_flags_vertical = Control.SIZE_FILL
		_rarity_style(b, id)
		# Icon on top, the name once underneath (trimmed with … if it's long).
		var icon := CritterIcon.make(id, 1, 76.0)
		icon.anchor_left = 0.5
		icon.anchor_right = 0.5
		icon.offset_left = -38.0
		icon.offset_right = 38.0
		icon.offset_top = -2.0
		icon.offset_bottom = 74.0
		icon.radius_frac = .36
		b.add_child(icon)
		var name_label := _label(BallDefs.get_def(id).display_name, 20)
		name_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_label.offset_left = 8.0
		name_label.offset_right = -8.0
		name_label.offset_top = -36.0
		name_label.offset_bottom = -6.0
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.add_child(name_label)
		var loan := Kit.chip("Loan", Kit.WARN, 16)
		loan.anchor_left = 1.0
		loan.anchor_right = 1.0
		loan.offset_right = -8.0
		loan.offset_top = 8.0
		loan.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		loan.visible = false
		b.add_child(loan)
		player_loan_tags[id] = loan
		b.toggled.connect(func(on): name_label.add_theme_color_override("font_color", Color("0b0a1f") if on else Color("f0eeff")))
		player_buttons[id] = b
		grid.add_child(b)
	pick_scroll = ScrollContainer.new()
	pick_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pick_scroll.add_child(grid)
	var rows := mini(PICK_ROWS_SHOWN, ceili(float(ids.size()) / PICK_COLUMNS))
	pick_scroll.custom_minimum_size = Vector2(0, rows * PICK_TILE_HEIGHT + (rows - 1) * 12)
	return pick_scroll


# --- Clips -------------------------------------------------------------------
# Save clip replays the fight in a 720x1280 "Who wins?" layout and records it
# (clip/clip_export.gd). Where the browser can't record, the same layout
# plays for the phone's own screen recorder.

func _on_clip_button() -> void:
	if _clip_ready:
		if OS.has_feature("web"):
			# The page already started saving on this tap; just watch how it went.
			_share_pending = true
		return
	if _clip_wait or sim == null:
		return
	if OS.has_feature("web") and not ClipExport.can_record() and not _clip_hint:
		_clip_hint = true
		clip_button.text = "Play clip"
		report_label.text = "This browser can't save video. Start your phone's screen recorder, then tap Play clip."
		return
	_start_clip()


func _start_clip() -> void:
	var config: Dictionary = sim.config
	state = State.CLIP
	ui_layer.visible = false
	sim = MatchSim.new(config)
	_prepare_fight(config)
	_clip_speed = ClipExport.fight_speed(finisher.ticks * MatchSim.DT)
	var names := [sim.balls[0].def.display_name, sim.balls[1].def.display_name]
	arena.team_tags = ["P1", "P2"] if names[0] == names[1] else [names[0].to_upper(), names[1].to_upper()]
	clip_card.names = names
	clip_card.sim = sim
	clip_card.visible = true
	clip_card.set_phase("title")
	_layout()
	_sync_share_targets() # No share buttons on screen while the clip plays.
	_clip_recording = false
	if ClipExport.can_record():
		var view := get_viewport().get_visible_rect().size
		var rect := Rect2(clip_card.position / view, ClipCard.SIZE / view)
		_clip_recording = ClipExport.start(rect, ClipExport.file_name(sim.balls[0].type_id, sim.balls[1].type_id))
	sfx.on_menu()
	print("CLIP_START record=%s speed=%.2f" % [_clip_recording, _clip_speed])


func _advance_clip(delta: float) -> void:
	match clip_card.phase:
		"title":
			arena.advance_effects(delta)
			if clip_card.t >= ClipCard.TITLE_TIME:
				clip_card.set_phase("fight")
				sfx.on_fight_start(sim)
		"fight":
			if _advance_fight(delta, _clip_speed):
				_unzoom()
				clip_card.set_phase("end")
				sfx.on_result(0)
		"end":
			arena.advance_effects(delta)
			if clip_card.t >= ClipCard.END_TIME:
				_end_clip(false)


## Back to the result screen. A recorded take goes off to be encoded.
func _end_clip(cancelled: bool) -> void:
	state = State.RESULT
	clip_card.visible = false
	ui_layer.visible = true
	if not sim.finished:
		# Cancelled part way: show the fight's end, as the result screen did.
		sim.run_to_end()
		arena.clear_effects()
		arena.ko_ball = finisher.loser
	_unzoom()
	arena.team_tags = ["P1", "P2"] if mode == Mode.REPLAY else ArenaView.TEAM_TAGS
	_layout()
	_show_only(result_box)
	if _clip_recording:
		_clip_recording = false
		ClipExport.stop(cancelled)
		if not cancelled:
			_clip_wait = true
			clip_button.disabled = true
			clip_button.text = "Making…"
			report_label.text = "Making your clip…"
	elif not cancelled:
		report_label.text = "That's the clip! Share fight sends the link."
	print("CLIP_END cancelled=%s" % cancelled)


func _cancel_clip() -> void:
	sfx.on_menu()
	_end_clip(true)


func _poll_clip() -> void:
	var status := ClipExport.status()
	if status in ["recording", "encoding"]:
		return
	_clip_wait = false
	clip_button.disabled = false
	if status == "ready":
		_clip_ready = true
		clip_button.text = "Save video"
		report_label.text = "Clip ready! Tap Save video, then post it."
		_sync_share_targets()
	else:
		clip_button.text = "Save clip"
		report_label.text = "Couldn't make the video this time. Tap Save clip to try again."
	print("CLIP_", status.to_upper() if status != "" else "FAILED")


## A new fight or result starts with a fresh Save clip button.
func _reset_clip() -> void:
	_clip_ready = false
	_clip_hint = false
	_clip_wait = false
	clip_button.disabled = false
	clip_button.text = "Save clip"


# --- Onboarding ----------------------------------------------------------------
# game/onboarding.gd calls these to drive the arena; see design/onboarding.md.

func _wants_tutorial() -> bool:
	var forced: String = url_params.get("tutorial", "")
	if forced != "":
		return forced == "1"
	return url_params.is_empty() and OS.has_feature("web") and not Onboarding.is_done()


func _start_tutorial() -> void:
	mode = Mode.TUTORIAL
	shell_layer.visible = false
	var ob := Onboarding.new()
	ob.main = self
	add_child(ob)


## The two balls in their corners, no sim yet, no controls.
func tutorial_preview(types: Array, tags: Array) -> void:
	_show_menu()
	_show_only(null)
	arena.preview_types = types
	arena.team_tags = tags
	arena.queue_redraw()
	info_label.text = ""


## Watch a fight with both launches picked by the seed. `tags` go under the
## balls, `hud_names` in the HP line; `side` is the ball the player backs.
func tutorial_watch(p1: String, p2: String, fight_seed: int, tags: Array, hud_names: Array, side: int) -> void:
	player_type = p1
	opponent_type = p2
	seed_value = fight_seed
	aim = MatchSim.new({"seed": fight_seed, "p1": p1, "p2": p2}).launch_angles[0]
	foe_aim = null
	tutorial_tags = hud_names
	tutorial_side = side
	_start_fight()
	arena.team_tags = tags


## Aim and launch the player's ball against a fixed foe shot, with a ghost
## arrow suggesting a launch.
func tutorial_aim(p1: String, p2: String, fight_seed: int, foe_angle: int, ghost_angle: int, text: String) -> void:
	player_type = p1
	opponent_type = p2
	seed_value = fight_seed
	foe_aim = foe_angle
	tutorial_tags = ["You", BallDefs.get_def(p2).display_name]
	tutorial_side = 0
	state = State.AIM
	aim = ghost_angle
	arena.clear_effects()
	arena.team_tags = ArenaView.TEAM_TAGS
	_set_aim_preview()
	arena.ghost_dir = Vector2.from_angle(deg_to_rad(ghost_angle / 10.0))
	info_label.text = text
	_show_only(aim_box)


## Opens the home shell with the onboarding's profile and returns the shell.
func tutorial_home(profile) -> Shell:
	sim = null
	arena.sim = null
	arena.ghost_dir = Vector2.ZERO
	_show_only(null)
	_adopt_profile(profile)
	_show_home()
	return shell


## Onboarding finished or skipped: normal play from the Play tab, or the
## Glow Garden map when `to_campaign` (the boss teaser's "Let's go!").
func tutorial_end(new_profile, to_campaign := false) -> void:
	mode = Mode.NORMAL
	tutorial_tags = []
	arena.ghost_dir = Vector2.ZERO
	arena.team_tags = ArenaView.TEAM_TAGS
	_apply_picks()
	if new_profile != null:
		_adopt_profile(new_profile)
		# Quick fight starts on the new starter.
		player_type = profile.lineup
		save.data.picks.player = player_type
		save.commit()
	_show_menu()
	shell.show_tab("play")
	_show_home()
	if to_campaign:
		shell.go("world")
		shell.go("campaign", {"zone": 0})


## The onboarding's new player becomes the saved profile, unless this save
## already has progress of its own (onboarding replayed with ?tutorial=1).
func _adopt_profile(p) -> void:
	if p == profile or profile_unsaved or profile.runs > 0 or profile.account_level > 1:
		if shell.profile != profile:
			shell.set_profile(profile)
		return
	profile.changed.disconnect(_save_profile)
	profile = p
	profile.changed.connect(_save_profile)
	FightSpeed.account_level = profile.account_level
	shell.set_profile(profile)
	_save_profile()


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
			if (t.kind === "clip") {
				if (window.bbClip) window.bbClip.save(done); else done("failed");
				return;
			}
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
	var code := FightLink.challenge_code(player_type, seed_value, angles[0], _pick_arena()) if kind == "c" \
		else FightLink.replay_code(player_type, opponent_type, seed_value, angles[0], angles[1], _pick_arena())
	var url := FightLink.url(_link_base(), kind, code)
	var mine := str(friends.me.get("code", ""))
	if mine != "":
		url += "&f=" + mine
	# The fight's Chaos Weekend twist rides along, so it replays the same any day.
	url += "&mod=" + modifier if modifier != Modifiers.NONE else ""
	# A tiered Quick fight replays at its tiers; a challenge is taken at equal stats.
	var t := _fight_tiers()
	return url + ("&t=%d%d" % t if kind == "r" and t[0] > 0 else "")


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
		if _clip_ready and clip_button.is_visible_in_tree():
			add.call("clip", "", "", clip_button.get_global_rect())
	JavaScriptBridge.eval("window.bbShare && (window.bbShare.targets = %s)" % JSON.stringify(targets), true)


func _share(kind: String) -> void:
	Analytics.track("share", {"kind": kind})
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
	var messages := {"shared": "Shared!", "copied": "Link copied. Paste it to a friend!", "shown": "", "cancelled": "",
		"saved": "Clip saved! Post it and ask: who wins?", "downloaded": "Clip downloaded. Post it and ask: who wins?",
		"failed": "Couldn't save the clip. Try Save clip again."}
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
	var text := _build_stamp() + (" · " + account_text if account_text != "" else "")
	return text + (" · test user %d" % backend.test_user if backend.test_user > 0 else "")


## Dev: a PERF line every 2s (frames drawn, fps, worst frame, draw calls).
## Menus should draw few frames; fights should keep draw calls low.
func _perf_log() -> void:
	var drawn := Engine.get_frames_drawn()
	while is_inside_tree():
		await get_tree().create_timer(2.0).timeout
		print("PERF drawn %d/2s fps %.0f process %.1fms draws %d objects %d" % [Engine.get_frames_drawn() - drawn,
			Performance.get_monitor(Performance.TIME_FPS), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
		drawn = Engine.get_frames_drawn()


func _run_probe() -> void:
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.position = Vector2(40, 200)
	label.text = "Checking fights..."
	layer.add_child(label)
	add_child(layer)
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	var r := preload("res://sim/probe.gd").run()
	var version := preload("res://sim/sim_version.gd").get_version()
	print("PROBE %s %d %dms" % [r.hash, r.fights, Time.get_ticks_msec() - t0])
	print("SIM_VERSION ", version)
	label.text = "Fight check: %s\n%d fights, sim %s" % [String(r.hash).substr(0, 16), r.fights, version]


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
	if params.get("duo", "") == "1": # ?duo=1 opens Quick fight in 2v2 (&p3= picks your second critter).
		duo = true
		url_picks = true
		if params.get("p3", "") in BallDefs.PLAYABLE:
			mate_type = params.p3
	backend.disabled = params.get("offline", "") == "1"
	# ?live=ws://127.0.0.1:8080 points this visit's live fights at that server (and turns them on).
	if params.get("live", "").begins_with("ws"):
		Dev.live_url_override = params.live
	# ?text=large turns on Larger text for this visit only (screenshots, testing).
	if params.get("text", "") == "large":
		A11y.ensure_loaded()
		A11y.large_text = true
	if params.get("arena", "") in Arenas.PLAYABLE:
		url_arena = params.arena
		arena_override = url_arena
	if params.has("seed") and params.seed.is_valid_int():
		seed_value = int(params.seed)
	if params.has("aim") and params.aim.is_valid_int():
		aim = int(params.aim)
	if params.has("speed"):
		FightSpeed.url_speed = maxf(0.0, float(params.speed))
	auto_start = params.get("auto", "") == "1"
	auto_clip = params.get("clip", "") == "1"
	# ?today=2026-10-17 pins the live-ops clock to that day's noon (UTC).
	if LiveOps.date_unix(params.get("today", "")) >= 0:
		LiveOps.now_override = LiveOps.date_unix(params.today) + 12 * 3600
	if Modifiers.has(params.get("mod", "-")):
		modifier = params.mod
	elif params.has("r") or params.has("c"):
		modifier = Modifiers.NONE ## A shared fight without a twist was played on normal rules.
	else:
		modifier = _weekend_modifier()
	if params.get("demo", "") == "friends":
		friends.show_demo()
	if Friends.is_code(params.get("f", "")):
		link_friend = Friends.normalize_code(params.f)
	if params.get("pve", "").count("-") == 1:
		pve_param = params.pve
	demo_profile = params.get("demo", "") == "1"
	demo_stars = clampi(int(params.get("stars", "0")), 0, 3)
	var t := str(params.get("t", ""))
	if t.length() == 2 and t.is_valid_int():
		link_tiers = [clampi(int(t[0]), 1, Lineup.MAX_TIER), clampi(int(t[1]), 1, Lineup.MAX_TIER)]
		pick_tiers = link_tiers.duplicate() # Without &r= too: ?p1=..&t=51 starts a quick fight at those tiers.
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
			arena_override = r.arena
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
			arena_override = c.arena
			auto_start = false
	if mode != Mode.NORMAL:
		url_picks = true
	if auto_start and opponent_choice == OPPONENT_RANDOM:
		opponent_type = _pick_opponent()
	return params
