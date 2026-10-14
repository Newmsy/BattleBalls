## The game's home: top bar (level, energy, coins, orbs), the current screen,
## and the five-tab bar (Critters, Bag, Play, Fuse, Summon). See design/ui.md.
## Screens live in game/ui/screens/ and are rebuilt each time they're shown.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const Friends := preload("res://game/online/friends.gd")
const FightLink := preload("res://game/fight_link.gd")

const SCREENS := {
	"play": preload("res://game/ui/screens/play_screen.gd"),
	"critters": preload("res://game/ui/screens/critters_screen.gd"),
	"detail": preload("res://game/ui/screens/detail_screen.gd"),
	"fuse": preload("res://game/ui/screens/fuse_screen.gd"),
	"bag": preload("res://game/ui/screens/bag_screen.gd"),
	"summon": preload("res://game/ui/screens/summon_screen.gd"),
	"week": preload("res://game/ui/screens/week_screen.gd"),
	"friends": preload("res://game/ui/screens/friends_screen.gd"),
}
const TABS := [["critters", "Critters"], ["bag", "Bag"], ["play", "Play"], ["fuse", "Fuse"], ["summon", "Summon"]]
const TOP_PAD := 28.0
const TAB_HEIGHT := 128.0

## Emitted when the player starts a quick fight from the Play tab.
signal play_requested
## Emitted to watch a fight in the arena, e.g. the Fight of the Day. `fight`
## has p1, p2, seed, angles and pick (the side the player called).
signal watch_requested(fight: Dictionary)
## A friend's Rematch button: fight their saved team (unranked).
signal rival_requested(friend: Dictionary)
## A share button was tapped (kind as registered with share_link).
signal share_tapped(kind: String)
## The current screen's share buttons moved (see share_targets).
signal share_layout_changed

## Friends state (game/online/friends.gd). main.gd swaps in one with the backend.
var friends = Friends.new()
## Where invite links point: main.gd sets the page's own address on the web.
var link_base := FightLink.HOME

var profile = UiProfile.sample()
var play_with := "" ## Ball to pick in the arena menu on the next request_play().
var current := ""
var current_params := {}
var _stack: Array = []
var _tab := "play"
var _holder: Control
var _scroll: ScrollContainer
var _tab_buttons := {}
var _dots := {}
var _top_labels := {}
var _toast: Label
var _toast_tween: Tween
var _marks := {}
var _built := false
var _overlay: Control
var _share := {} ## kind -> {button, url, text} on the current screen.


func _ready() -> void:
	build()


## Builds the shell once; called from _ready, or directly by tests.
func build() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Kit.theme()
	var bg := ColorRect.new()
	bg.color = Kit.BG
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
	col.add_child(_tab_bar())
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_toast = Kit.label("", 24, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	_toast.add_theme_stylebox_override("normal", Kit.box(Color("221e55"), Kit.ACCENT, 24, 2, 18))
	_toast.modulate.a = 0.0
	add_child(_toast)
	profile.changed.connect(_refresh_top)
	set_friends(friends)
	resized.connect(func(): if current != "": refresh())
	show_tab("play")


func show_tab(t: String) -> void:
	open_tab(t, {})


## Switch tab straight to a screen with parameters, e.g. Fuse with a critter picked.
func open_tab(t: String, params: Dictionary) -> void:
	_tab = t
	_stack = [[t, params]]
	_show(t, params)


## Open a screen on top of the current one (Back returns to it).
func go(name: String, params := {}) -> void:
	_stack.append([name, params])
	_show(name, params)


func back() -> void:
	_stack.pop_back()
	if _stack.is_empty():
		show_tab(_tab)
		return
	var top: Array = _stack[-1]
	_show(top[0], top[1])


## Rebuild the current screen in place, e.g. after the data changed.
func refresh() -> void:
	_show(current, current_params)


## Rebuild the current screen with new parameters, replacing it in the history.
func refresh_with(params: Dictionary) -> void:
	_stack[-1] = [current, params]
	_show(current, params)


func toast(text: String) -> void:
	_toast.text = text
	var w := minf(620.0, size.x - 60.0)
	_toast.size = Vector2(w, 0)
	_toast.size.y = _toast.get_line_count() * 34.0 + 40.0
	_toast.position = Vector2((size.x - _toast.size.x) / 2.0, size.y - TAB_HEIGHT - _toast.size.y - 40.0)
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast.modulate.a = 1.0
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, .3)


## Cover the whole shell (tabs included) with `c`, e.g. the summon reveal.
func overlay(c: Control, tag := "overlay") -> void:
	close_overlay()
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(c)
	_report.call_deferred(tag)


func overlay_open() -> bool:
	return _overlay.mouse_filter == Control.MOUSE_FILTER_STOP


func close_overlay() -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in _overlay.get_children():
		c.queue_free()
	share_layout_changed.emit()


## A bottom sheet over a dimmed screen; tapping the dim area closes it.
func sheet(content: Control) -> void:
	var root := Control.new()
	var dim := Button.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_style := Kit.box(Color(.02, .015, .06, .65), Color(0, 0, 0, 0), 0, 0, 0)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		dim.add_theme_stylebox_override(st, dim_style)
	dim.pressed.connect(close_overlay)
	root.add_child(dim)
	var st := Kit.box(Color("16133a"), Kit.ACCENT, 0, 0, 32)
	st.border_width_top = 3
	st.corner_radius_top_left = 44
	st.corner_radius_top_right = 44
	st.content_margin_bottom = 60
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", st)
	panel.add_child(content)
	root.add_child(panel)
	overlay(root, "sheet")
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.position.y = size.y
	var h := panel.get_combined_minimum_size().y
	create_tween().tween_property(panel, "position:y", size.y - h, .22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func set_friends(f) -> void:
	if friends.changed.is_connected(_on_friends_changed):
		friends.changed.disconnect(_on_friends_changed)
	friends = f
	friends.changed.connect(_on_friends_changed)


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
## picked as yours (the Try-a-Critter card does).
func request_play(ball := "") -> void:
	play_with = ball
	play_requested.emit()


func watch(fight: Dictionary) -> void:
	watch_requested.emit(fight)


func _show(name: String, params: Dictionary) -> void:
	close_overlay()
	current = name
	current_params = params
	_marks.clear()
	_share.clear()
	for c in _holder.get_children():
		c.queue_free()
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_holder.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Phones fill the width; wide screens keep a phone-width column in the middle.
	var side_margin := maxi(28, int((size.x - 720.0) / 2.0) + 28)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, side_margin)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 40)
	_scroll.add_child(margin)
	var screen: Control = SCREENS[name].build(self, params)
	margin.add_child(screen)
	for t in _tab_buttons:
		_tab_buttons[t].modulate = Color.WHITE if t == _tab else Color(Kit.MUTED, 1.0)
	_refresh_top()
	_report.call_deferred(name)


func _report(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if name != current and name not in ["overlay", "sheet", "reveal"]:
		return
	print("UI_SCREEN ", name)
	share_layout_changed.emit()
	var all := _marks.duplicate()
	for t in _tab_buttons:
		all["tab_" + t] = _tab_buttons[t]
	for k in all:
		var c: Control = all[k]
		if is_instance_valid(c) and c.is_visible_in_tree():
			var p := c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])


# --- Top bar -------------------------------------------------------------------

func _top_bar() -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 22)
	m.add_theme_constant_override("margin_right", 22)
	m.add_theme_constant_override("margin_top", int(TOP_PAD))
	m.add_theme_constant_override("margin_bottom", 12)
	var lvl := Kit.panel(Kit.label("", 28, Kit.BG, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.ACCENT, Color("b9abff"), 999, 3, 0))
	lvl.custom_minimum_size = Vector2(64, 64)
	_top_labels["level"] = lvl.get_child(0)
	(lvl.get_child(0) as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var row := Kit.hbox(10, [lvl, _pill("energy"), Kit.spacer(), _pill("coin"), _pill("orb")])
	m.add_child(row)
	return m


func _pill(kind: String) -> Control:
	var l := Kit.label("", 26)
	_top_labels[kind] = l
	var p := Kit.panel(Kit.hbox(8, [Glyph.make(kind, 34), l]), Kit.box(Kit.PANEL, Kit.LINE, 999, 2, 0))
	var st: StyleBoxFlat = p.get_theme_stylebox("panel")
	st.content_margin_left = 6
	st.content_margin_right = 16
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


func _refresh_top() -> void:
	_top_labels.level.text = str(profile.account_level)
	_top_labels.energy.text = "%d/%d" % [profile.energy, profile.energy_max]
	_top_labels.coin.text = Kit.commas(profile.coins)
	_top_labels.orb.text = str(profile.orbs)
	_dots.fuse.visible = not profile.ready_to_fuse().is_empty()
	_dots.play.visible = friends.attention() > 0


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
	for tab in TABS:
		var id: String = tab[0]
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(show_tab.bind(id))
		var content := Kit.vbox(4)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.alignment = BoxContainer.ALIGNMENT_END
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon_box := CenterContainer.new()
		icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if id == "play":
			var disc := Kit.panel(Glyph.make("play", 50, Kit.BG), Kit.box(Kit.ACCENT, Kit.BG, 999, 6, 22))
			disc.get_theme_stylebox("panel").shadow_color = Color(Kit.ACCENT, .5)
			disc.get_theme_stylebox("panel").shadow_size = 18
			icon_box.add_child(disc)
		else:
			icon_box.add_child(Glyph.make(id, 50, Kit.FG))
		content.add_child(icon_box)
		content.add_child(Kit.label(tab[1].to_upper(), 19, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER))
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
	return bar
