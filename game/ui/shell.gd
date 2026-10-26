## The game's home: top bar (level, energy, coins, orbs), the current screen,
## and the five-tab bar (Critters, Bag, Play, Fuse, Summon). See design/ui.md.
## Screens live in game/ui/screens/ and are rebuilt each time they're shown.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const TabIcon := preload("res://game/ui/tab_icon.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const Friends := preload("res://game/online/friends.gd")
const FightLink := preload("res://game/fight_link.gd")
const Analytics := preload("res://game/online/analytics.gd")
const SettingsSheet := preload("res://game/ui/screens/settings_sheet.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const Store := preload("res://game/glow/store.gd")
const Intro := preload("res://game/ui/intro.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const Motion := preload("res://game/ui/motion.gd")
const LevelUp := preload("res://game/ui/level_up.gd")

const SCREENS := {
	"play": preload("res://game/ui/screens/play_screen.gd"),
	"critters": preload("res://game/ui/screens/critters_screen.gd"),
	"detail": preload("res://game/ui/screens/detail_screen.gd"),
	"dex": preload("res://game/ui/screens/dex_screen.gd"),
	"dex_entry": preload("res://game/ui/screens/dex_entry_screen.gd"),
	"fuse": preload("res://game/ui/screens/fuse_screen.gd"),
	"bag": preload("res://game/ui/screens/bag_screen.gd"),
	"summon": preload("res://game/ui/screens/summon_screen.gd"),
	"arena": preload("res://game/ui/screens/arena_screen.gd"),
	"boosts": preload("res://game/ui/screens/boosts_screen.gd"),
	"bazaar": preload("res://game/ui/screens/bazaar_screen.gd"),
	"defence": preload("res://game/ui/screens/defence_screen.gd"),
	"week": preload("res://game/ui/screens/week_screen.gd"),
	"adventure": preload("res://game/ui/screens/adventure_screen.gd"),
	"versus": preload("res://game/ui/screens/versus_screen.gd"),
	"bracket": preload("res://game/ui/screens/bracket_screen.gd"),
	"friends": preload("res://game/ui/screens/friends_screen.gd"),
	"world": preload("res://game/ui/screens/world_screen.gd"),
	"campaign": preload("res://game/ui/screens/campaign_screen.gd"),
	"spire": preload("res://game/ui/screens/spire_screen.gd"),
	"vault": preload("res://game/ui/screens/vault_screen.gd"),
	"nest": preload("res://game/ui/screens/nest_screen.gd"),
	"pinata": preload("res://game/ui/screens/pinata_screen.gd"),
	"totem": preload("res://game/ui/screens/totem_screen.gd"),
	"wyrm": preload("res://game/ui/screens/wyrm_screen.gd"),
	"rift": preload("res://game/ui/screens/rift_screen.gd"),
	"glitch": preload("res://game/ui/screens/glitch_screen.gd"),
	"bosses": preload("res://game/ui/screens/bosses_screen.gd"),
	"factions": preload("res://game/ui/screens/factions_screen.gd"),
	"faction": preload("res://game/ui/screens/faction_screen.gd"),
	"account": preload("res://game/ui/screens/account_screen.gd"),
	"shop": preload("res://game/ui/screens/shop_screen.gd"),
	"pass": preload("res://game/ui/screens/pass_screen.gd"),
	"quests": preload("res://game/ui/screens/quests_screen.gd"),
}
const TABS := [["critters", "Critters"], ["bag", "Bag"], ["play", "Play"], ["fuse", "Fuse"], ["summon", "Summon"]]
const TAB_IDS := ["critters", "bag", "play", "fuse", "summon"]
## Screens that hold a list which keeps growing (collection, Critterpedia, gear, the shop,
## the pass track, friends, the stage map, the Spire's critter picker, the
## week's events and the bracket). Every other screen must fit a
## 720x1280 phone without scrolling: put detail behind an "i" (info()) and
## the main action in pin(). See design/ui.md, "No scrolling".
## Play fits one screen (its doors); it scrolls only with Larger text.
## Growing lists read top-down, so they never get centred (see _show).
const TOP_ALIGNED := ["critters", "dex", "bag", "shop", "pass", "campaign", "bracket", "world"]
const SCROLLS := ["play", "week", "critters", "dex", "bag", "shop", "pass", "friends", "campaign", "spire", "bracket", "boosts"]
const TOP_PAD := 28.0
const TAB_HEIGHT := 128.0
## Tablets and desktop: the top bar and tab buttons stay this wide in the middle
## instead of spreading to the window's edges (the screens keep a phone column).
const WIDE_BARS := 900.0
const TOAST_FACE := 52.0

## Emitted when the player starts a quick fight from the Play tab.
signal play_requested
## Emitted to watch a fight in the arena, e.g. the Fight of the Day. `fight`
## has p1, p2, seed, angles and pick (the side the player called, or -1), and
## optionally board_title, return_to (the screen to come back to, default "week")
## and return_params.
signal watch_requested(fight: Dictionary)
## A friend's Rematch button: fight their saved team (unranked).
signal rival_requested(friend: Dictionary)
## A share button was tapped (kind as registered with share_link).
signal share_tapped(kind: String)
## The current screen's share buttons moved (see share_targets).
signal share_layout_changed
## A popup or sheet over the screen has just closed.
signal overlay_closed

## Friends state (game/online/friends.gd). main.gd swaps in one with the backend.
var friends = Friends.new()
## Account state (game/online/account.gd); null until main.gd sets it.
var account = null
## Where invite links point: main.gd sets the page's own address on the web.
var link_base := FightLink.HOME
var build_stamp := "" ## "v0.2.0 abc1234 · account": shown at the foot of Settings, never in a fight.
## Emitted when a campaign stage starts; energy is already spent.
signal stage_requested(config: Dictionary, zone_index: int, stage_index: int, fighter: String)
## Emitted when a farming boss run starts from its screen ("vault" Anvil King,
## "nest" Brood Queen, "pinata" Piñata Titan, "totem" Totem of Nine, "wyrm" Prism Wyrm, "glitch" The Glitch, "rift" a Rift round); energy and the run (or the Rift Key) are already spent.
signal boss_requested(config: Dictionary, difficulty: int, fighter: String, screen: String)

var profile = UiProfile.sample()
## The online backend (game/online/backend.gd), or null in tests.
var backend = null
var play_with := "" ## Ball to pick in the arena menu on the next request_play().
var play_duo := false ## The next request_play() opens the 2v2 pick-a-pair menu.
## Glow Gems, cosmetics and the Glow Pass (game/glow/glow_state.gd). main.gd
## sets one backed by the real save; tests get a throwaway one.
var glow
var current := ""
var current_params := {}
var _stack: Array = []
## Pictures of the screens under the current one (one per _stack entry below
## the top, null when not taken), for the swipe back (TouchInput).
var _snaps: Array = []
var _shown_at := 0 ## Frame the current screen was built on.
var _tabs: Control ## The tab bar.
const SNAP_DEPTH := 4 ## Only the nearest few are kept; deeper ones go back without a picture.
var _tab := "play"
var _holder: Control
var _column := 664.0 ## Width the current screen gets: the phone column inside its side margins.
var _footer: MarginContainer ## Pinned actions (pin()), above the tab bar.
var _scroll: ScrollContainer
var _tab_buttons := {}
var _dots := {}
var _top_labels := {}
var _toast: Label
var _toast_tween: Tween
var _toast_face ## The critter a toast is about, at its left edge.
var _marks := {}
var _badge: Control ## The level badge (opens the account screen).
var _built := false
var _overlay: Control
var _gear: Control ## Settings button in the top bar.
var _share := {} ## kind -> {button, url, text} on the current screen.
var _overlay_tag := "" ## What the open overlay is ("sheet", "reveal", ...).
## The game's sound (game/audio/sfx.gd); main.gd sets it. The settings sheet
## has its switch, since the corner toggle is hidden on home screens.
var sfx = null
var _scroll_settle := 0.0 ## Seconds left before a scroll counts as settled.
var _settling := false
var _coach: Label ## A new player's next step (game/ui/intro.gd), above the footer.
var _level_ring: Control ## Account XP around the level badge.
var _tab_icons := {} ## Tab id -> TabIcon; PLAY's disc is lit only on Play's home.
var _tab_labels := {}
var _tab_mark: Panel ## The gold bar under the open tab; it glides to a tapped tab.
var _pills := {} ## Currency kind -> its top bar pill (where gains fly to).
## What each top bar pill shows. Gains made while a popup is up or the menus
## are hidden (a fight) wait here and fly in once you're back.
var _shown := {}
var _fly_from := Vector2(-1, -1) ## Where the next gain flies from (reward_from).
var _fx: Control ## Over everything: flying coins and eggs.
var _report_after := 0 ## Msec tick a screen's slide ends: marks are logged after it.
## The current screen's big critter (the critter page's hero), which a
## tapped card's face grows into (go_from). Screens set it in build().
var hero: Control
var _pop_next: Array = [] ## Marks to pop once the next screen is built (pop_after).
var _top_margin: MarginContainer
var _tab_row: HBoxContainer
var _light := {} ## The door the next go() opens through (light_from): rect, color.

## Red dots are for something to do, and go once you've looked: the Fuse dot
## only for sets that turned fusable since your last visit to Fuse (per device).
const BADGES_PATH := "user://ui_badges.cfg"


func _ready() -> void:
	build()


## Builds the shell once; called from _ready, or directly by tests.
func build() -> void:
	if _built:
		return
	_built = true
	if glow == null:
		glow = GlowState.new(SaveGame.new("user://shell_preview_save.json"), profile, Store.new())
	glow.purchase_finished.connect(_on_purchase)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Kit.theme()
	var bg := _Backdrop.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var col := Kit.vbox(0)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(col)
	col.add_child(_top_bar())
	_holder = Control.new()
	_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_holder.clip_contents = true
	col.add_child(_holder)
	_coach = Kit.label("", 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
	var cst := Kit.box(Color("1c3a2e"), Kit.GOOD, 999, 2, 12)
	cst.content_margin_left = 24
	cst.content_margin_right = 24
	_coach.add_theme_stylebox_override("normal", cst)
	_coach.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_coach.visible = false
	col.add_child(_coach)
	_footer = MarginContainer.new()
	_footer.add_theme_constant_override("margin_top", 10)
	_footer.add_theme_constant_override("margin_bottom", 14)
	_footer.visible = false
	col.add_child(_footer)
	_tabs = _tab_bar()
	col.add_child(_tabs)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_toast = Kit.label("", 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	_toast.add_theme_stylebox_override("normal", Kit.box(Color("221e55"), Kit.ACCENT, 24, 2, 18))
	_toast.modulate.a = 0.0
	add_child(_toast)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	profile.changed.connect(_refresh_top)
	set_friends(friends)
	resized.connect(func(): _fit_wide(); if current != "": refresh())
	_fit_wide()
	show_tab("play")
	# Coming back from a Ghost Arena fight lands on the Arena again.
	if ArenaStore.reopen:
		ArenaStore.reopen = false
		go("arena")


## Swap in another profile (the new player from onboarding, or a newer cloud save).
func set_profile(p) -> void:
	if profile.changed.is_connected(_refresh_top):
		profile.changed.disconnect(_refresh_top)
	profile = p
	if glow != null:
		glow.profile = p # Pass and quest rewards land on the profile on screen.
	_shown = {} # Another save's coins land as they are, not flying in.
	if _built:
		profile.changed.connect(_refresh_top)
		if current != "":
			refresh()


func show_tab(t: String) -> void:
	open_tab(t, {})


## Switch tab straight to a screen with parameters, e.g. Fuse with a critter picked.
func open_tab(t: String, params: Dictionary) -> void:
	_tab = t
	_stack = [[t, params]]
	_snaps = []
	_show(t, params)


## Open a screen from a tapped critter card: the card's face `from` grows
## into the new screen's hero (the critter page) while the page fades in.
func go_from(name: String, params: Dictionary, from: Control) -> void:
	if Motion.calm() or not is_instance_valid(from) or overlay_open():
		go(name, params)
		return
	var rect := from.get_global_rect()
	_snaps.append(null) # No slide to take a picture for.
	if _snaps.size() > SNAP_DEPTH:
		_snaps[_snaps.size() - SNAP_DEPTH - 1] = null
	_stack.append([name, params])
	_show(name, params)
	_arrive(Vector2.ZERO, .2)
	_grow_hero(rect)


func _grow_hero(from: Rect2) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var h := hero
	if not is_instance_valid(h) or not h.is_visible_in_tree():
		return
	var to := h.get_global_rect()
	var base := _fx.get_global_rect().position
	var ghost := CritterIcon.make(h.critter_id, h.tier, to.size.x)
	ghost.info = false
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.position = from.position - base
	ghost.size = from.size
	_fx.add_child(ghost)
	h.modulate.a = 0.0
	var tw := ghost.create_tween().set_parallel()
	tw.tween_property(ghost, "position", to.position - base, .28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(ghost, "size", to.size, .28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_callback(func():
		if is_instance_valid(h):
			h.modulate.a = 1.0
		ghost.queue_free())
	_hold_report(.3)


## After the next rebuild (refresh), pop the controls marked `marks`, e.g.
## the wishlist chip just toggled or a gear slot just filled.
func pop_after(marks: Array) -> void:
	_pop_next = marks.duplicate()


## A tab that has just opened up: its icon rises into the bar with a flash.
func spotlight_tab(t: String) -> void:
	if not t in _tab_icons:
		return
	Motion.pop(_tab_icons[t], 0.0, .5, .1)
	Motion.flash(_tab_icons[t], Color(1.8, 1.7, 1.2), .9)


## Open a screen on top of the current one (Back returns to it).
func go(name: String, params := {}) -> void:
	# Only a screen that has been on screen for a frame (not one built this
	# frame, with the last scene's picture still in the viewport).
	var shown := not overlay_open() and Engine.get_frames_drawn() > _shown_at + 1
	_snaps.append(TouchInput.snapshot(self) if shown else null)
	if _snaps.size() > SNAP_DEPTH:
		_snaps[_snaps.size() - SNAP_DEPTH - 1] = null
	_stack.append([name, params])
	var light := _light
	_light = {}
	_show(name, params)
	if not light.is_empty() and _snaps[-1] != null and not Motion.calm():
		_light_in(_snaps[-1], light.rect, light.color)
	else:
		_slide_in(_snaps[-1])


## The next go() opens through `door` (a Home door) instead of sliding: a
## wash of its colour spills out of it and fills the screen, then fades off
## the new one. The paintings themselves never stretch.
func light_from(door: Control, col: Color) -> void:
	_light = {"rect": door.get_global_rect(), "color": col}


func _light_in(old: Texture2D, rect: Rect2, col: Color) -> void:
	var screen := get_viewport().get_visible_rect().size
	var room := _holder.get_global_rect()
	var base := _fx.get_global_rect().position
	# The screen we're leaving stays up while the light grows over it.
	var under := Motion.picture(old, room, screen)
	under.position = room.position - base
	_fx.add_child(under)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, .35, .6, 1.0])
	g.colors = PackedColorArray([Color.WHITE, col, col, Color(col, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(.5, .5)
	tex.fill_to = Vector2(.5, 0.0)
	tex.width = 64
	tex.height = 64
	var glow := TextureRect.new()
	glow.texture = tex
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.size = Vector2(80, 80)
	glow.pivot_offset = glow.size / 2.0
	glow.position = rect.get_center() - base - glow.size / 2.0
	glow.scale = Vector2(.6, .6)
	glow.modulate.a = .7
	_fx.add_child(glow)
	var reach := room.size.length() * 2.3 / glow.size.x
	var tw := glow.create_tween()
	tw.tween_property(glow, "scale", Vector2(reach, reach), .23).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(glow, "modulate:a", 1.0, .23)
	tw.tween_callback(under.queue_free)
	tw.tween_property(glow, "modulate:a", 0.0, .26).set_ease(Tween.EASE_OUT)
	tw.tween_callback(glow.queue_free)
	# The new screen comes up once the light covers the old one.
	var sc := _scroll
	sc.modulate.a = 0.0
	_hold_report(.5)
	get_tree().create_timer(.23).timeout.connect(func():
		if is_instance_valid(sc) and sc == _scroll:
			_arrive(Vector2.ZERO, .26))


## The picture of the screen Back would return to, for the swipe back to slide
## the current screen off (empty when there isn't one: a sheet is open, or
## it's a tab's own screen).
## With the part of the screen that slides: between the top bar and the tab
## bar, which stay put, as on iOS.
func back_preview() -> Dictionary:
	if overlay_open() or _stack.size() < 2 or _snaps.size() != _stack.size() - 1 or _snaps[-1] == null:
		return {}
	var top := _holder.get_global_rect().position.y
	return {"texture": _snaps[-1], "rect": Rect2(0.0, top, size.x, _tabs.get_global_rect().position.y - top)}


## What Back (or a swipe in from the left edge) does now: close a sheet, or
## return to the screen underneath. Empty at a tab's own screen.
func back_action() -> Callable:
	if overlay_open():
		return close_overlay if _overlay_tag == "sheet" else Callable()
	return back if _stack.size() > 1 else Callable()


func back() -> void:
	# A picture of the screen leaving, to slide off the rebuilt one (not when
	# the edge swipe has already slid it away).
	var leaving: Texture2D = null
	if not Motion.calm() and not TouchInput.sliding() and not overlay_open() and Engine.get_frames_drawn() > _shown_at + 1:
		leaving = TouchInput.snapshot(self)
	_stack.pop_back()
	if not _snaps.is_empty():
		_snaps.pop_back()
	if _stack.is_empty():
		show_tab(_tab)
		return
	var top: Array = _stack[-1]
	_show(top[0], top[1])
	_slide_out(leaving)


## Rebuild the current screen in place, e.g. after the data changed. Keeps
## the scroll position.
func refresh() -> void:
	var at := _scroll.scroll_vertical
	# A results popup (stars, XP bars) shows once: a re-render never replays it.
	var params := current_params.duplicate()
	params.erase("result")
	_show(current, params)
	_restore_scroll(at)


## Rebuild the current screen with new parameters, replacing it in the history.
func refresh_with(params: Dictionary) -> void:
	var at := _scroll.scroll_vertical
	_stack[-1] = [current, params]
	_show(current, params)
	if not params.has("focus"):
		_restore_scroll(at)


## Scroll the current screen so `c` is in view once it has been laid out.
func scroll_to(c: Control) -> void:
	var sc := _scroll
	if not is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(sc) and is_instance_valid(c) and sc == _scroll:
		# A little of the card above stays in view, so it's clear where you are.
		sc.scroll_vertical = int(c.global_position.y - sc.global_position.y + sc.scroll_vertical - 160.0)


func _restore_scroll(at: int) -> void:
	var sc := _scroll
	if not is_inside_tree() or at <= 0:
		return
	# Set it as soon as the new content's scroll range is known, in the same
	# frame the screen is rebuilt: waiting for a frame drew the rebuilt screen
	# scrolled to the top for one frame (a flash on every pick in The Spire).
	var bar := sc.get_v_scroll_bar()
	var hold := func():
		if is_instance_valid(sc) and sc == _scroll and sc.scroll_vertical != at:
			sc.scroll_vertical = at
	bar.changed.connect(hold)
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(bar) and bar.changed.is_connected(hold):
		bar.changed.disconnect(hold)
	await get_tree().process_frame
	if is_instance_valid(sc) and sc == _scroll:
		sc.scroll_vertical = at


## A short note above the tab bar. `critter` puts that critter's face at its left.
func toast(text: String, critter := "") -> void:
	_toast.text = text
	if is_instance_valid(_toast_face):
		_toast_face.queue_free()
		_toast_face = null
	var style := Kit.box(Color("221e55"), Kit.ACCENT, 24, 2, 18)
	if critter != "":
		style.content_margin_left = 18.0 + TOAST_FACE + 10.0
		_toast_face = CritterIcon.face(critter, TOAST_FACE)
		_toast_face.info = false
		_toast_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_toast.add_child(_toast_face)
	_toast.add_theme_stylebox_override("normal", style)
	var w := minf(620.0, size.x - 60.0)
	_toast.size = Vector2(w, 0)
	_toast.size.y = maxf(_toast.get_line_count() * 34.0 + 40.0, TOAST_FACE + 24.0 if critter != "" else 0.0)
	if _toast_face != null:
		_toast_face.position = Vector2(16.0, (_toast.size.y - TOAST_FACE) / 2.0)
		_toast_face.size = Vector2(TOAST_FACE, TOAST_FACE)
	var lift := TAB_HEIGHT + (_footer.size.y if _footer.visible else 0.0)
	_toast.position = Vector2((size.x - _toast.size.x) / 2.0, size.y - lift - _toast.size.y - 40.0)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast.modulate.a = 1.0
	if not Motion.calm():
		# Slides up into place with a little pop; the face in it hops.
		var rest := _toast.position.y
		_toast.position.y = rest + 20.0
		_toast.pivot_offset = _toast.size / 2.0
		_toast.scale = Vector2(.92, .92)
		_toast_tween.set_parallel()
		_toast_tween.tween_property(_toast, "position:y", rest, .22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_toast_tween.tween_property(_toast, "scale", Vector2.ONE, .26).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_toast_tween.set_parallel(false)
		if _toast_face != null:
			Motion.bump(_toast_face, 1.25, .3, true)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, .3)


## Cover the whole shell (tabs included) with `c`, e.g. the summon reveal.
func overlay(c: Control, tag := "overlay") -> void:
	close_overlay()
	_overlay_tag = tag
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(c)
	_report.call_deferred(tag)


func overlay_open() -> bool:
	return _overlay.mouse_filter == Control.MOUSE_FILTER_STOP


func close_overlay() -> void:
	var was_open := overlay_open()
	var was_sheet := _overlay_tag == "sheet" and was_open
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_tag = ""
	for c in _overlay.get_children():
		if was_sheet and not Motion.calm() and c is Control:
			# The sheet shrinks away on top while the screen under it is live.
			_overlay.remove_child(c)
			_fx.add_child(c)
			ResultPopup.pop_out(c)
		else:
			c.queue_free()
	share_layout_changed.emit()
	if was_open:
		overlay_closed.emit()
	if is_inside_tree() and profile != null:
		_refresh_top.call_deferred() # Coins won while it was up fly in now.


## Pin a screen's main action (Fuse, Summon, Climb...) under the screen,
## above the tab bar, so it never ends up below the fold. Cleared on every
## screen change.
func pin(c: Control) -> void:
	_footer.add_child(c)
	_footer.visible = true


## A sheet with a title and a few short paragraphs: the detail behind a
## screen's "i" button, so the screen itself can stay short.
func info(title: String, paragraphs: Array) -> void:
	var v := Kit.vbox(18, [Kit.label(title, 36)])
	for t in paragraphs:
		var l := Kit.label(t, 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		# The sheet measures itself before layout, so wrapped text needs a real width.
		l.custom_minimum_size.x = minf(640.0, size.x - 80.0)
		v.add_child(l)
	var ok := Kit.button("Got it", close_overlay, "ghost", 26, 80)
	mark("info_close", ok)
	v.add_child(ok)
	sheet(v)


## The round Back button every pushed screen puts at the start of its title row.
func back_button(mark_as := "back") -> Control:
	var b := Kit.card_button(Glyph.make("back", 30, Kit.FG), back, Kit.LINE, Kit.PANEL, 999, 16)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mark(mark_as, b)
	TouchInput.mark_back(b)
	return b


## A round "i" button that opens info(title, paragraphs).
func info_button(title: String, paragraphs: Array, mark_as := "info") -> Control:
	var b := Kit.card_button(Glyph.make("info", 34, Kit.FG), info.bind(title, paragraphs), Kit.LINE, Kit.PANEL, 999, 12)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	mark(mark_as, b)
	return b


## The title row every screen starts with: Back (on pushed screens), the
## title with an optional eyebrow caption over it, any extra controls, then
## the "i" button. opts: back (default true), back_mark ("back"), eyebrow
## (caption text), eyebrow_color (MUTED), eyebrow_glyphs (glyph kinds after
## the eyebrow, in its colour), extra ([Control], between title and "i"),
## info ([paragraphs]: adds the "i"), info_title (the title), info_mark ("info").
func title_row(title: String, opts := {}) -> HBoxContainer:
	var head: Control = Kit.label(title, 40)
	var eyebrow: String = opts.get("eyebrow", "")
	var glyphs: Array = opts.get("eyebrow_glyphs", [])
	if eyebrow != "" or not glyphs.is_empty():
		var col: Color = opts.get("eyebrow_color", Kit.MUTED)
		var cap := Kit.hbox(6, [Kit.caption(eyebrow, col)], BoxContainer.ALIGNMENT_BEGIN)
		for g in glyphs:
			cap.add_child(Kit.glyph(g, 22, col))
		head = Kit.vbox(2, [cap, head])
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(16, [head], BoxContainer.ALIGNMENT_CENTER)
	if opts.get("back", true):
		var b := back_button(opts.get("back_mark", "back"))
		row.add_child(b)
		row.move_child(b, 0)
	for c in opts.get("extra", []):
		if c != null: # Optional chips (Account's Guest/Saved, Friends' count) can be absent.
			row.add_child(c)
	if opts.has("info"):
		row.add_child(info_button(opts.get("info_title", title), opts.info, opts.get("info_mark", "info")))
	return row


## A modal card in the middle of a dimmed screen; tapping the dim area closes it.
func sheet(content: Control) -> void:
	# The same sheet every fight's result pops up in (ResultPopup).
	var root := ResultPopup.frame(self, content, size.y, close_overlay, func(): _report("sheet"))
	overlay(root, "-") # Reported once it has popped in, so taps land where it stops.
	_overlay_tag = "sheet" # Back and the edge swipe close it.


func _on_purchase(_id: String, _ok: bool, message: String) -> void:
	if current in ["shop", "pass"]:
		close_overlay()
		refresh()
	toast(message)


func set_friends(f) -> void:
	if friends.changed.is_connected(_on_friends_changed):
		friends.changed.disconnect(_on_friends_changed)
	friends = f
	friends.changed.connect(_on_friends_changed)


func set_account(a) -> void:
	account = a
	account.changed.connect(func():
		if current == "account" and not overlay_open():
			refresh())


func _on_friends_changed() -> void:
	if current in ["friends", "play"] and not overlay_open():
		refresh()
	elif current != "":
		_refresh_top()


## Register a button as a share target. On the web the page shares `url` from
## inside the tap itself (browsers require that); see main.gd's share links.
func share_link(kind: String, button: Control, url: String, text: String) -> void:
	_share[kind] = {"button": button, "url": url, "text": text}


## [{kind, url, text, rect}] for the visible share buttons, in screen pixels.
func share_targets() -> Array:
	var out := []
	if overlay_open():
		return out
	for kind in _share:
		var t: Dictionary = _share[kind]
		if is_instance_valid(t.button) and t.button.is_visible_in_tree():
			out.append({"kind": kind, "url": t.url, "text": t.text, "rect": t.button.get_global_rect()})
	return out


## Register a control so the smoke test can find and tap it ("UI_AT name x y").
func mark(name: String, c: Control) -> void:
	_marks[name] = c


## Screens call this to get back to the arena menu, optionally with `ball`
## picked as yours.
func request_play(ball := "", duo := false) -> void:
	play_with = ball
	play_duo = duo
	play_requested.emit()


func watch(fight: Dictionary) -> void:
	watch_requested.emit(fight)


func _show(name: String, params: Dictionary) -> void:
	close_overlay()
	if name != current:
		Analytics.track("screen", {"name": name})
	current = name
	current_params = params
	_shown_at = Engine.get_frames_drawn()
	hero = null
	_marks.clear()
	_share.clear()
	for c in _holder.get_children():
		c.queue_free()
	for c in _footer.get_children():
		_footer.remove_child(c)
		c.queue_free()
	_footer.visible = false
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_holder.add_child(_scroll)
	# Re-log control positions once a scroll settles so the smoke test can tap
	# below the fold. Not on every scroll step: logging every mark each frame
	# made long lists stutter.
	_scroll.get_v_scroll_bar().value_changed.connect(func(_v): _report_after_scroll(name))
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Phones fill the width; wide screens keep a phone-width column in the middle.
	var side_margin := maxi(28, int((size.x - 720.0) / 2.0) + 28)
	_column = size.x - 2.0 * side_margin
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, side_margin)
		_footer.add_theme_constant_override("margin_" + side, side_margin)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 24)
	_scroll.add_child(margin)
	var screen: Control = SCREENS[name].build(self, params)
	margin.add_child(screen)
	# Short screens sit in the middle of the room under their title row
	# instead of leaving a gap at the bottom; growing lists stay top-aligned.
	if name not in TOP_ALIGNED and screen is VBoxContainer:
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		Kit.centre_column(screen, 1)
	for t in _tab_buttons:
		_tab_labels[t].add_theme_color_override("font_color", Kit.FG if t == _tab else Kit.MUTED)
		if t != "play":
			_tab_icons[t].set_active(t == _tab)
	_refresh_top()
	_place_tab_mark.call_deferred()
	for m in _pop_next:
		if _marks.has(m) and is_instance_valid(_marks[m]):
			Motion.pop(_marks[m], .6, .32)
			Motion.flash(_marks[m], Color(1.4, 1.5, 1.2), .5)
	_pop_next = []
	_report.call_deferred(name)


# --- Screen changes --------------------------------------------------------------

## A tab tapped in the tab bar: the new screen slides in from the side the
## tab is on and its cards cascade in; the tab's icon hops.
func _on_tab(t: String) -> void:
	var dir := signf(TAB_IDS.find(t) - TAB_IDS.find(_tab))
	show_tab(t)
	if t in _tab_icons:
		Motion.bump(_tab_icons[t], 1.16, .3, true)
	_arrive(Vector2(Motion.TAB_SHIFT * dir, 0.0), Motion.TAB_SECS)


## The current screen eases in from `offset` and fades up, then its cards
## cascade in. Taps work on it straight away.
func _arrive(offset: Vector2, secs: float) -> void:
	var sc := _scroll
	if Motion.calm():
		offset = Vector2.ZERO
	sc.modulate.a = 0.0
	sc.position += offset
	var tw := sc.create_tween().set_parallel()
	tw.tween_property(sc, "modulate:a", 1.0, secs * .9)
	if offset != Vector2.ZERO:
		tw.tween_property(sc, "position", sc.position - offset, secs).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_hold_report(maxf(secs, _cascade()))


## The screen's own cards, one after another.
func _cascade() -> float:
	var margin := _scroll.get_child(0) if _scroll.get_child_count() > 0 else null
	var screen: Node = margin.get_child(0) if margin != null and margin.get_child_count() > 0 else null
	if not screen is BoxContainer:
		return 0.0
	return Motion.cascade(screen.get_children())


## A pushed screen (go) slides in from the right over a picture of the last
## one, which drifts left under a shade: iOS's push. The real screen is built
## and live from the first frame.
func _slide_in(old: Texture2D) -> void:
	if old == null or Motion.calm():
		_arrive(Vector2.ZERO, .12)
		return
	var rect := _holder.get_global_rect()
	var w := rect.size.x
	var under := Motion.picture(old, rect, get_viewport().get_visible_rect().size)
	var shade := _shade(rect.size)
	var ground := _ground(rect)
	for c in [under, shade, ground]:
		_holder.add_child(c)
		_holder.move_child(c, _holder.get_child_count() - 2) # Under the screen.
	var sc := _scroll
	var move := func(t: float) -> void:
		var x := w * (1.0 - t)
		sc.position.x = x
		ground.position.x = x
		under.position.x = -w * Motion.PARALLAX * t
		shade.color.a = Motion.SHADE * t
	move.call(0.0)
	var tw := sc.create_tween()
	tw.tween_method(move, 0.0, 1.0, Motion.SLIDE_SECS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		for c in [under, shade, ground]:
			c.queue_free())
	_hold_report(Motion.SLIDE_SECS)


## Back: a picture of the screen you left slides off to the right, showing
## the one underneath (already rebuilt) coming back from the left.
func _slide_out(leaving: Texture2D) -> void:
	if leaving == null:
		if Motion.calm():
			_arrive(Vector2.ZERO, .12)
		return
	var rect := _holder.get_global_rect()
	var w := rect.size.x
	var top := Motion.picture(leaving, rect, get_viewport().get_visible_rect().size)
	var shade := _shade(rect.size)
	var ground := _ground(rect)
	_holder.add_child(ground)
	_holder.move_child(ground, _holder.get_child_count() - 2)
	_holder.add_child(shade)
	_holder.add_child(top)
	var sc := _scroll
	var move := func(t: float) -> void:
		var x := -w * Motion.PARALLAX * (1.0 - t)
		sc.position.x = x
		ground.position.x = x
		top.position.x = w * t
		shade.color.a = Motion.SHADE * (1.0 - t)
	move.call(0.0)
	var tw := sc.create_tween()
	tw.tween_method(move, 0.0, 1.0, Motion.SLIDE_SECS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(func():
		for c in [top, shade, ground]:
			c.queue_free())
	_hold_report(Motion.SLIDE_SECS)


func _shade(sz: Vector2) -> ColorRect:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.size = sz
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shade


## The backdrop behind a sliding screen (screens are see-through), lined up
## with the real one. Drawn once.
func _ground(rect: Rect2) -> Control:
	var clip := Control.new()
	clip.clip_contents = true
	clip.size = rect.size
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := _Backdrop.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.size = size
	bg.position = -(rect.position - get_global_rect().position)
	clip.add_child(bg)
	return clip


## Smoke tests tap what _report logs: log it once the screen has stopped.
func _hold_report(secs: float) -> void:
	_report_after = Time.get_ticks_msec() + int(secs * 1000.0) + 20


## The gold bar glides under the open tab.
func _place_tab_mark() -> void:
	if not is_instance_valid(_tab_mark) or not _tab in _tab_buttons:
		return
	var b: Control = _tab_buttons[_tab]
	_tab_mark.visible = b.visible and _tabs.visible
	var to := _tab_row.position.x + b.position.x + (b.size.x - _tab_mark.size.x) / 2.0
	if _tab_mark.position.x < 0.0 or Motion.calm():
		_tab_mark.position.x = to
		return
	_tab_mark.create_tween().tween_property(_tab_mark, "position:x", to, .22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _report_after_scroll(name: String) -> void:
	_scroll_settle = 0.25
	if _settling:
		return
	_settling = true
	while _scroll_settle > 0.0:
		await get_tree().process_frame
		_scroll_settle -= get_process_delta_time()
	_settling = false
	if name == current and _overlay.get_child_count() == 0:
		_report(name)


func _report(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	while Time.get_ticks_msec() < _report_after:
		await get_tree().process_frame
	if name != current and name not in ["overlay", "sheet", "reveal", "story", "bounce_chest"]:
		return
	print("UI_SCREEN ", name)
	if name == current:
		_report_fit()
	share_layout_changed.emit()
	var all := _marks.duplicate()
	for t in _tab_buttons:
		all["tab_" + t] = _tab_buttons[t]
	all["account"] = _badge
	all["settings"] = _gear
	for k in all:
		var c: Control = all[k]
		if is_instance_valid(c) and c.is_visible_in_tree():
			var p := c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])


## Logs how big the screen is against the room it has; a screen outside
## SCROLLS that needs scrolling logs UI_OVERFLOW, and any screen wider than
## the phone logs UI_OVERFLOW_X (smoke.mjs fails on both).
func _report_fit() -> void:
	if not is_instance_valid(_scroll) or _scroll.get_child_count() == 0:
		return
	var need: Vector2 = _scroll.get_child(0).get_combined_minimum_size()
	var room: Vector2 = _scroll.size
	# The scroll grows with too-wide content, so measure the screen itself
	# against the phone-width column it gets (side margins of 28 each).
	var margin := _scroll.get_child(0) as MarginContainer
	if margin != null and margin.get_child_count() > 0:
		need.x = margin.get_child(0).get_combined_minimum_size().x
		room.x = _column
	print("UI_FIT %s %d %d width %d %d" % [current, roundi(need.y), roundi(room.y), roundi(need.x), roundi(room.x)])
	if need.y > room.y + 1.0 and current not in SCROLLS:
		print("UI_OVERFLOW %s %d" % [current, roundi(need.y - room.y)])
	# No screen may be wider than the phone: cards would run off the right edge.
	if need.x > room.x + 1.0:
		print("UI_OVERFLOW_X %s %d" % [current, roundi(need.x - room.x)])


# --- Top bar -------------------------------------------------------------------

func _top_bar() -> Control:
	var m := MarginContainer.new()
	_top_margin = m
	m.add_theme_constant_override("margin_top", int(TOP_PAD))
	m.add_theme_constant_override("margin_bottom", 12)
	var lvl := Kit.panel(Kit.label("", 28, Kit.BG, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.ACCENT, Color("b9abff"), 999, 3, 0))
	lvl.custom_minimum_size = Vector2(64, 64)
	_top_labels["level"] = lvl.get_child(0)
	(lvl.get_child(0) as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Account XP to the next level, as a ring just outside the badge.
	_level_ring = _Ring.new()
	_level_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lvl.add_child(_level_ring)
	# The level badge opens the account screen (save progress, sign in).
	lvl.mouse_filter = Control.MOUSE_FILTER_STOP
	lvl.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and current != "account":
			go("account"))
	_badge = lvl
	var gear := Kit.card_button(Glyph.make("gear", 40, Kit.FG), func(): SettingsSheet.open(self), Kit.LINE, Kit.PANEL, 999, 12)
	gear.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_gear = gear
	var row := Kit.hbox(10, [lvl, _pill("energy"), Kit.spacer(), _pill("coin"), _pill("orb"), gear])
	m.add_child(row)
	return m


const PILL_HELP := {
	"energy": "Energy: for stages and bosses. Refills over time, and on level up.",
	"coin": "Coins: from the campaign and Piñata Titan. Buy looks.",
	"orb": "Summon Eggs: hatch them on Summon.",
}


func _pill(kind: String) -> Control:
	var l := Kit.label("", 26)
	_top_labels[kind] = l
	var row := Kit.hbox(8, [Glyph.make(kind, 34), l])
	if kind == "energy":
		# Time to the next point while it refills, ticked once a second.
		var next := Kit.label("", 20, Kit.MUTED)
		next.visible = false
		_top_labels["energy_next"] = next
		row.add_child(next)
		var tick := Timer.new()
		tick.wait_time = 1.0
		tick.autostart = true
		tick.timeout.connect(_tick_energy)
		row.add_child(tick)
	var p := Kit.panel(row, Kit.box(Kit.PANEL, Kit.LINE, 999, 2, 0))
	_pills[kind] = p
	# Tap a currency to learn where it comes from.
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			toast(PILL_HELP[kind]))
	var st: StyleBoxFlat = p.get_theme_stylebox("panel")
	st.content_margin_left = 6
	st.content_margin_right = 16
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## The energy pill's "4:59" to the next point; hidden when full. A new
## point lands in the pill without waiting for a screen change.
func _tick_energy() -> void:
	var next: Label = _top_labels.get("energy_next")
	if next == null:
		return
	var now := int(Time.get_unix_time_from_system())
	var before: int = profile.energy
	profile.update_energy(now)
	if profile.energy != before:
		_set_top("energy", profile.energy, true)
	var wait: int = profile.seconds_to_next_energy(now)
	next.visible = wait > 0
	if wait > 0:
		next.text = "%d:%02d" % [wait / 60, wait % 60]


func _refresh_top() -> void:
	_set_level()
	_tick_energy()
	_set_top("energy", profile.energy)
	_set_top("coin", profile.coins)
	_set_top("orb", profile.orbs)
	_fly_from = Vector2(-1, -1)
	var fusable := _fuse_signature()
	if current == "fuse":
		_set_badge("fuse_seen", fusable)
	var was_lit := {}
	for t in _dots:
		was_lit[t] = _dots[t].visible
	_dots.fuse.visible = fusable != "" and _new_since(fusable, _badge_value("fuse_seen"))
	_dots.summon.visible = profile.free_summon and Intro.done(profile)
	var pass_claims: int = glow.claimable_count() if glow != null and not glow.season().is_empty() else 0
	_dots.play.visible = (friends.attention() > 0 or pass_claims > 0) and Intro.done(profile)
	for t in _dots:
		if _dots[t].visible and not was_lit[t] and is_visible_in_tree():
			Motion.pop(_dots[t], 0.0, .35)
	# Play's disc is the big call to action only on Play's own home screen.
	_tab_icons.play.set_active(current == "play")
	# A new player sees only the tabs their first fights have opened.
	for t in _tab_buttons:
		_tab_buttons[t].visible = Intro.shows(profile, t)
	var hint := Intro.coach(profile, current)
	_coach.text = hint
	_coach.visible = hint != ""


## The next coins, eggs or energy you gain fly into the top bar from `c`
## (e.g. a Glow Pass card you claimed) instead of from the middle.
func reward_from(c: Control) -> void:
	_fly_from = c.get_global_rect().get_center()


func _pill_text(kind: String, v: int) -> String:
	match kind:
		"energy":
			return "%d/%d" % [v, profile.energy_max]
		"coin":
			return Kit.commas(v)
	return str(v)


## Show a pill's new value. A spend counts down at once; a gain counts up
## with a green pulse, or flies in as icons when it was made out of sight
## (under a popup, during a fight) or from a known place (reward_from).
## `quiet`: just set it (the energy refill tick).
func _set_top(kind: String, value: int, quiet := false) -> void:
	var l: Label = _top_labels[kind]
	var was = _shown.get(kind)
	if was == null or quiet or not is_inside_tree():
		_shown[kind] = value
		l.text = _pill_text(kind, value)
		if quiet and was != null and value > int(was):
			Motion.flash(_pills[kind], Color(1.0, 1.5, 1.2))
		return
	var from: int = was
	if value == from:
		l.text = _pill_text(kind, value) # The energy cap may have moved.
		return
	if value < from:
		_shown[kind] = value
		Motion.count(l, from, value, .35, _pill_text.bind(kind))
		return
	if not is_visible_in_tree() or overlay_open():
		return # Held: it flies in once the popup closes or the menus come back.
	_shown[kind] = value
	var pill: Control = _pills[kind]
	var start := _fly_from if _fly_from.x >= 0.0 else get_global_rect().get_center()
	if Motion.calm():
		l.text = _pill_text(kind, value)
		return
	var gain := value - from
	var n: int = clampi(gain if kind == "orb" else 3 + gain / 40, 3, 10)
	var target := pill.get_global_rect().position + Vector2(pill.size.y / 2.0, pill.size.y / 2.0)
	Motion.fly(_fx, Glyph.make.bind(kind, 46), start, target, n, func(k: int) -> void:
		var v := value if k == n - 1 else from + gain * (k + 1) / n
		l.text = _pill_text(kind, v)
		Motion.bump(pill, 1.14, .18)
		if sfx != null:
			sfx.play("click", -8.0, 1.2 + .05 * k)
		if k == n - 1:
			Motion.flash(pill, Color(1.0, 1.5, 1.2), .5))


## The level badge and its XP ring. A level reached out of sight waits like
## a coin does; then the ring fills, the badge pops and LevelUp celebrates.
func _set_level() -> void:
	var lv: int = profile.account_level
	var frac := float(profile.account_xp) / maxf(1.0, profile.account_xp_to_next())
	var seen = _shown.get("level")
	var ring_from: float = _level_ring.get("frac")
	if seen != null and lv > int(seen) and (not is_visible_in_tree() or overlay_open()):
		return # Held until you're back on a screen.
	_shown["level"] = lv
	_top_labels.level.text = str(lv)
	if seen == null or lv < int(seen) or Motion.calm() or not is_inside_tree():
		_level_ring.set("frac", frac)
		_level_ring.queue_redraw()
		if seen != null and lv > int(seen):
			LevelUp.show_on(_fx, lv, sfx)
		return
	var ring := func(f: float) -> void:
		_level_ring.set("frac", f)
		_level_ring.queue_redraw()
	var tw := _level_ring.create_tween()
	if lv > int(seen):
		_top_labels.level.text = str(seen)
		tw.tween_method(ring, ring_from, 1.0, .4).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func():
			_top_labels.level.text = str(lv)
			Motion.bump(_badge, 1.35, .32)
			Motion.flash(_badge, Color(1.8, 1.7, 1.2), .5)
			LevelUp.show_on(_fx, lv, sfx))
		ring_from = 0.0
	tw.tween_method(ring, ring_from, frac, .35).set_ease(Tween.EASE_OUT)


func _notification(what: int) -> void:
	# Back from a fight: what it won flies in.
	if what == NOTIFICATION_VISIBILITY_CHANGED and _built and is_visible_in_tree() and profile != null:
		_refresh_top.call_deferred()


## On a window wider than WIDE_BARS the top bar's pills and the tab buttons
## gather in the middle, over the phone column, rather than at far corners.
func _fit_wide() -> void:
	var inset := maxf(0.0, (size.x - WIDE_BARS) / 2.0)
	for side in ["left", "right"]:
		_top_margin.add_theme_constant_override("margin_" + side, 22 + int(inset))
	_tab_row.offset_left = inset
	_tab_row.offset_right = -inset


# --- Tab bar -------------------------------------------------------------------

func _tab_bar() -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, TAB_HEIGHT)
	var bg := Panel.new()
	var st := Kit.box(Color("0e0c26"), Color(0, 0, 0, 0), 0, 0, 0)
	st.border_width_top = 2
	st.border_color = Kit.LINE
	bg.add_theme_stylebox_override("panel", st)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	bar.add_child(row)
	_tab_row = row
	for tab in TABS:
		var id: String = tab[0]
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_tab.bind(id))
		var content := Kit.vbox(4)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.alignment = BoxContainer.ALIGNMENT_END
		# PLAY's big disc is taller than the bar: let it rise above the bar
		# instead of pushing its label off the bottom of the screen.
		content.grow_vertical = Control.GROW_DIRECTION_BEGIN
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_box := CenterContainer.new()
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TabIcon.make(id, 106 if id == "play" else 64)
		_tab_icons[id] = icon
		icon_box.add_child(icon)
		content.add_child(icon_box)
		var label := Kit.label(tab[1].to_upper(), 19, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER)
		_tab_labels[id] = label
		content.add_child(label)
		var pad := Control.new()
		pad.custom_minimum_size = Vector2(0, 14)
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(pad)
		b.add_child(content)
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", Kit.box(Kit.BAD, Color(0, 0, 0, 0), 999, 0, 0))
		dot.size = Vector2(18, 18)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.visible = false
		dot.set_anchors_preset(Control.PRESET_CENTER_TOP)
		dot.position = Vector2(20, 16)
		b.add_child(dot)
		_dots[id] = dot
		_tab_buttons[id] = b
		row.add_child(b)
	_tab_mark = Panel.new()
	_tab_mark.add_theme_stylebox_override("panel", Kit.box(Color("ffd166"), Color(0, 0, 0, 0), 999, 0, 0))
	_tab_mark.size = Vector2(34, 5)
	_tab_mark.position = Vector2(-100, TAB_HEIGHT - 10)
	_tab_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_tab_mark)
	bar.resized.connect(func(): _tab_mark.position.x = -100; _place_tab_mark.call_deferred())
	return bar


# --- Red dots ------------------------------------------------------------------

## The fusable sets right now, e.g. "laser:1,vampire:2" ("" when none).
func _fuse_signature() -> String:
	var keys: Array = profile.ready_to_fuse().map(func(st): return "%s:%d" % [st.id, st.tier])
	keys.sort()
	return ",".join(keys)


## True if `now` has an entry `seen` didn't.
static func _new_since(now: String, seen: String) -> bool:
	var old := seen.split(",")
	for k in now.split(","):
		if k not in old:
			return true
	return false


static func _badge_value(key: String) -> String:
	var cfg := ConfigFile.new()
	cfg.load(BADGES_PATH)
	return str(cfg.get_value("seen", key, ""))


static func _set_badge(key: String, value: String) -> void:
	if _badge_value(key) == value:
		return
	var cfg := ConfigFile.new()
	cfg.load(BADGES_PATH)
	cfg.set_value("seen", key, value)
	cfg.save(BADGES_PATH)


## A thin progress ring drawn around its parent (the level badge).
class _Ring extends Control:
	var frac := 0.0

	func _draw() -> void:
		var r := minf(size.x, size.y) / 2.0 + 5.0
		var c := size / 2.0
		draw_arc(c, r, 0, TAU, 40, Color("2b2760"), 5.0, true)
		if frac > 0.0:
			draw_arc(c, r, -PI / 2, -PI / 2 + TAU * clampf(frac, 0.0, 1.0), 40, Color("45f5a6"), 5.0, true)


## Behind every screen: a deep indigo wash, lighter toward the top, a soft
## glow under the top bar and a faint dot grid fading out down the screen.
## Drawn once (it only redraws when the window resizes).
class _Backdrop extends Control:
	const Kit := preload("res://game/ui/ui_kit.gd")
	const Dot := preload("res://game/dot.gd")
	const TOP := Color("17143a")
	const GAP := 48.0

	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Kit.BG)
		# The wash: one quad, lighter at the top, into the base colour by mid-screen.
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * .55), Vector2(0, h * .55)]),
			PackedColorArray([TOP, TOP, Kit.BG, Kit.BG]))
		# The glow stays phone-sized over the middle on a wide window.
		Dot.glow(self, Vector2(w * .5, -h * .05), minf(w, 1100.0) * .8, Color(.45, .35, 1.0, .12), .4)
		# The dot grid, offset every other row, brightest near the top.
		var rows := int(h * .6 / GAP)
		for j in rows:
			var fade := 1.0 - float(j) / rows
			var off := GAP * .5 if j % 2 else 0.0
			var x := GAP * .5 + off
			while x < w:
				Dot.circle(self, Vector2(x, GAP * (j + .5)), 1.6, Color(.7, .65, 1.0, .1 * fade))
				x += GAP
		# Tablets and desktop: the sides fall into shadow so the middle reads as
		# the stage, framed by a faint rim of light.
		var side := (w - 1000.0) / 2.0
		if side > 24.0:
			var dark := Color(0.0, 0.0, 0.03, .55)
			var clear := Color(0.0, 0.0, 0.03, 0.0)
			draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(side, 0), Vector2(side, h), Vector2(0, h)]),
				PackedColorArray([dark, clear, clear, dark]))
			draw_polygon(PackedVector2Array([Vector2(w - side, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - side, h)]),
				PackedColorArray([clear, dark, dark, clear]))
			var rim := Color(.55, .45, 1.0, .10)
			draw_line(Vector2(side, 0), Vector2(side, h), rim, 2.0)
			draw_line(Vector2(w - side, 0), Vector2(w - side, h), rim, 2.0)
