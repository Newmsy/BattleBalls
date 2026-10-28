## First-session onboarding (design/onboarding.md): a "which ball wins?" cold
## open, a starter pick, two tutorial fights that teach aiming and drop copies,
## a guided first fusion, and a teaser of the zone 1 boss. Drives main.gd's
## arena through its tutorial_* calls and draws its own cards on a layer above
## the home shell. Every step logs "ONBOARD step=<name>" for the funnel.
extends Node

const Kit := preload("res://game/ui/ui_kit.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Analytics := preload("res://game/online/analytics.gd")
const Story := preload("res://meta/story.gd")
const StoryCards := preload("res://game/ui/story_cards.gd")

const SAVE_PATH := "user://onboarding.cfg"
const STARTERS := ["vampire", "laser"]
## Every onboarding fight plays on this arena. The map is part of a fight's
## config, so without it the seed's random map decides how the fights go.
## first_rink is Neon Rink without its moving parts (sim/arenas.gd).
const ARENA := "first_rink"
## Cold open: a close fight with four lead changes that Count Nibbles wins at
## the death. Fixed so everyone sees the same opener.
const COLD_OPEN := {"seed": 139, "p1": "vampire", "p2": "laser", "arena": ARENA}
## Tutorial fights: the foe's fixed launch, and the ghost arrow's suggested aim
## (tenths of a degree). tests/test_onboarding.gd checks every aim wins.
const TUTORIAL_SEED := 3
const FIGHTS := [
	{"foe": "dummy", "foe_aim": 1350, "ghost": -450, "step": "fight1"},
	{"foe": "sparring", "foe_aim": 1350, "ghost": -800, "step": "fight2"},
]
const HOOKS := {
	"vampire": "Count Nibbles heals every time it hits.",
	"laser": "Optic fires a beam back along every bounce.",
}

var main: Node
var profile
var starter := ""
var _start_ms := 0
var _layer: CanvasLayer
var _root: Control
var _content: Control
var _coach: Label
var _skip: Button
var _marks := {}
var _fight := 0
var _cold_pick := ""


## True once this device has finished or skipped the onboarding.
static func is_done() -> bool:
	var cfg := ConfigFile.new()
	return cfg.load(SAVE_PATH) == OK and cfg.get_value("onboarding", "done", false)


static func _save(step: String, done: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	var steps: Array = cfg.get_value("onboarding", "steps", [])
	steps.append(step)
	cfg.set_value("onboarding", "steps", steps)
	if done:
		cfg.set_value("onboarding", "done", true)
	cfg.save(SAVE_PATH)


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	_layer = CanvasLayer.new()
	_layer.layer = 6
	add_child(_layer)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = Kit.theme()
	_layer.add_child(_root)
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_content)
	_coach = Kit.label("", 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)
	_coach.add_theme_stylebox_override("normal", Kit.box(Color("221e55"), Kit.GOOD, 24, 2, 18))
	_coach.visible = false
	_root.add_child(_coach)
	_skip = Kit.button("Skip", _on_skip, "ghost", 20, 56)
	_skip.size_flags_horizontal = Control.SIZE_SHRINK_END
	_root.add_child(_skip)
	main.tutorial_fight_ended.connect(_on_fight_ended)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_prologue()


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	_skip.size = Vector2(120, 56)
	_skip.position = Vector2(view.x - 140, 30)
	if _coach.visible:
		var w := minf(640.0, view.x - 40.0)
		_coach.size = Vector2(w, 0)
		_coach.size.y = _coach.get_line_count() * 34.0 + 40.0
		_coach.position = Vector2((view.x - w) / 2.0, 120)
	for c in _content.get_children():
		if c.has_meta("place"):
			_place(c, c.get_meta("place"))


func _log(step: String, done := false) -> void:
	print("ONBOARD step=%s ms=%d" % [step, Time.get_ticks_msec() - _start_ms])
	Analytics.track("onboarding_step", {"step": step, "ms": Time.get_ticks_msec() - _start_ms})
	_save(step, done)


# --- Steps ---------------------------------------------------------------------

## The story opens the game: the Neon Circuit, Nibbles and Optic, and the
## first giggle from the Glitch. Its own Skip only skips the story.
func _prologue() -> void:
	_log("prologue")
	# The game's first screen: the story on the plain night sky, not over the
	# arena and menu that the cold open will use.
	var sky := ColorRect.new()
	sky.color = Kit.BG
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_story(Story.PROLOGUE, _cold_open)
	_content.add_child(sky)
	_content.move_child(sky, 0)


func _cold_open() -> void:
	_skip.visible = true
	_log("cold_open")
	main.tutorial_preview([COLD_OPEN.p1, COLD_OPEN.p2], _names(COLD_OPEN.p1, COLD_OPEN.p2))
	var row := Kit.hbox(16)
	for id in [COLD_OPEN.p1, COLD_OPEN.p2]:
		# The critter's face beside its name, so you know which ball you bet on.
		var b := Kit.button("", _on_cold_pick.bind(id), "primary", 30, 100)
		var face = CritterIcon.face(id, 64)
		face.info = false # The tap is the bet.
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var words := Kit.label(BallDefs.get_def(id).display_name.to_upper(), 26, Kit.BG)
		words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var inside := Kit.hbox(10, [face, words], BoxContainer.ALIGNMENT_CENTER)
		inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(inside)
		_mark("pick_" + id, b)
		row.add_child(b)
	_show(Kit.vbox(18, [
		Kit.label("WHICH BALL WINS?", 46, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("Tap the one you'd bet on.", 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
		row,
	]), "controls", "onboard_cold_open")


func _on_cold_pick(id: String) -> void:
	_cold_pick = id
	_log("cold_open_pick")
	_clear()
	var side := 0 if id == COLD_OPEN.p1 else 1
	var tags := _names(COLD_OPEN.p1, COLD_OPEN.p2)
	tags[side] = "YOUR PICK"
	main.tutorial_watch(COLD_OPEN.p1, COLD_OPEN.p2, COLD_OPEN.seed, tags, _names(COLD_OPEN.p1, COLD_OPEN.p2), side)


func _cold_open_result(winner: int) -> void:
	var won_id: String = [COLD_OPEN.p1, COLD_OPEN.p2][winner] if winner >= 0 else ""
	var title := "DRAW!"
	var sub := "Nobody saw that coming."
	if won_id != "":
		title = "%s WINS!" % BallDefs.get_def(won_id).display_name.to_upper()
		sub = "You called it!" if won_id == _cold_pick else "Not this time!"
	var next := Kit.button("Next", _starter_pick, "go", 32, 96)
	_mark("next", next)
	_show(Kit.vbox(16, [
		Kit.label(title, 44, Kit.GOOD if won_id == _cold_pick else Kit.WARN, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label(sub, 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true),
		next,
	]), "controls", "onboard_cold_result")


func _starter_pick() -> void:
	_log("starter")
	var cards := Kit.vbox(18)
	for id in STARTERS:
		var c := Roster.get_critter(id)
		var info := Kit.vbox(6, [
			Kit.hbox(10, [Kit.label(c.name, 34), Kit.chip(Roster.RARITY_NAMES[c.rarity], Roster.RARITY_COLORS[c.rarity])]),
			Kit.label(c.vibe, 23, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true),
			Kit.label(HOOKS[id], 22, Kit.GOOD, HORIZONTAL_ALIGNMENT_LEFT, true),
		])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card := Kit.card_button(Kit.hbox(18, [CritterIcon.make(id, 1, 170), info]), _on_starter.bind(id), c.color, Kit.PANEL, 36, 18)
		_mark("starter_" + id, card)
		cards.add_child(card)
	_show(Kit.vbox(22, [
		Kit.label("PICK YOUR PARTNER", 44, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("Yours to keep.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true),
		cards,
	]), "full", "onboard_starter")


func _on_starter(id: String) -> void:
	starter = id
	profile = UiProfile.starter(id)
	profile.story.append("prologue")
	_log("starter_" + id)
	_fight = 0
	_start_fight(Roster.get_critter(id).name + " joins you! ")


func _start_fight(prefix := "") -> void:
	var f: Dictionary = FIGHTS[_fight]
	_log(f.step)
	_clear()
	var text := "Drag to aim, let go to launch."
	if _fight == 1:
		text = "Bank off a wall!"
	main.tutorial_aim(starter, f.foe, TUTORIAL_SEED, f.foe_aim, f.ghost, prefix + text)


func _fight_result(winner: int) -> void:
	if winner != 0:
		var retry := Kit.button("Try again", _start_fight, "go", 32, 96)
		_mark("retry", retry)
		_show(Kit.vbox(16, [
			Kit.label("SO CLOSE!", 44, Kit.WARN, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.label("Try another angle.", 24, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true),
			retry,
		]), "controls", "onboard_retry")
		return
	_log(FIGHTS[_fight].step + "_won")
	profile.add_copies([starter])
	var have: int = profile.total_copies(starter)
	var c := Roster.get_critter(starter)
	var slots := Kit.hbox(14, [], BoxContainer.ALIGNMENT_CENTER)
	for k in 3:
		slots.add_child(CritterIcon.make(starter, 1, 130, false, k >= have))
	var ready := have >= 3
	var next := Kit.button("Fuse them!" if ready else "Next fight", _fusion if ready else _next_fight, "go", 32, 96)
	_mark("next", next)
	_show(Kit.vbox(18, [
		Kit.label("VICTORY!", 52, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("+1 %s!" % c.name, 26, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true),
		slots,
		Kit.label("FUSION READY!" if ready else "3 of a kind fuse!",
			26, Kit.WARN if ready else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true),
		next,
	]), "full", "onboard_reward")


func _next_fight() -> void:
	_fight += 1
	_start_fight()


func _fusion() -> void:
	_log("fusion")
	_clear()
	_skip.visible = false
	var shell = main.tutorial_home(profile)
	shell.open_tab("fuse", {"id": starter, "tier": 1})
	_coach_say("Tap FUSE!")
	profile.changed.connect(_on_profile_changed)


func _on_profile_changed() -> void:
	if profile.best(starter).get("tier", 1) < 2:
		return
	profile.changed.disconnect(_on_profile_changed)
	_coach_say("Tier 2! A stronger ability and more power.")
	get_tree().create_timer(2.2).timeout.connect(_chapter_one)


## Chapter 1's story, then the boss it leaves behind. The campaign won't
## play it again.
func _chapter_one() -> void:
	_log("chapter_1")
	_coach.visible = false
	profile.story.append("glow_garden")
	_play_story(Story.chapter(0), _boss_teaser)


func _boss_teaser() -> void:
	_log("boss_teaser")
	_coach.visible = false
	var go := Kit.button("Let's go!", _finish, "go", 34, 100)
	_mark("lets_go", go)
	var boss := StoryCards.glitched_portrait("juggernaut", 300)
	_show(Kit.vbox(18, [
		Kit.caption("Zone 1 · Glow Garden", Color("9be89a")),
		_centered(boss),
		Kit.label("MEGA BOULDER", 48, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.label("waits at stage 10.", 25, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true),
		Kit.label("Your T2 %s is ready." % Roster.get_critter(starter).name, 26, Kit.GOOD, HORIZONTAL_ALIGNMENT_CENTER, true),
		go,
	]), "full", "onboard_boss")


func _finish() -> void:
	_log("done", true)
	main.tutorial_end(profile, true)
	queue_free()


## The cloud save already finished the onboarding on another device.
func leave() -> void:
	main.tutorial_end(profile)
	queue_free()


func _on_skip() -> void:
	_log("skipped", true)
	main.tutorial_end(profile)
	queue_free()


func _on_fight_ended(winner: int) -> void:
	if starter == "":
		_cold_open_result(winner)
	else:
		_fight_result(winner)


# --- Drawing -------------------------------------------------------------------

func _names(a: String, b: String) -> Array:
	return [BallDefs.get_def(a).display_name.to_upper(), BallDefs.get_def(b).display_name.to_upper()]


## Shows one card: "controls" sits over main's control panel under the arena;
## "full" dims the whole screen and centres the card.
func _show(content: Control, place: String, screen: String) -> void:
	var marks := _marks.duplicate()
	_clear()
	_marks = marks
	var holder: Control
	if place == "full":
		holder = ColorRect.new()
		(holder as ColorRect).color = Color(.02, .015, .06, .82)
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
		var centre := CenterContainer.new()
		centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(centre)
		var card := Kit.panel(content, Kit.box(Color("16133a"), Kit.ACCENT, 44, 3, 32))
		card.name = "Card"
		centre.add_child(card)
	else:
		holder = Kit.panel(content, Kit.box(Kit.BG, Color(0, 0, 0, 0), 0, 0, 0))
		holder.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.set_meta("place", place)
	_content.add_child(holder)
	_place(holder, place)
	_report.call_deferred(screen)


func _place(holder: Control, place: String) -> void:
	var view := get_viewport().get_visible_rect().size
	if place == "full":
		holder.position = Vector2.ZERO
		holder.size = view
		holder.get_child(0).get_node("Card").custom_minimum_size.x = minf(660.0, view.x - 40.0)
	else:
		var r: Rect2 = main.controls_rect
		holder.position = r.position
		holder.size = r.size


func _clear() -> void:
	_marks.clear()
	for c in _content.get_children():
		c.queue_free()


## Story cards over everything; `then` runs when they end or are skipped.
func _play_story(story: Dictionary, then: Callable) -> void:
	_clear()
	_skip.visible = false
	var cards: Control = StoryCards.make(story, then)
	_content.add_child(cards)
	_mark("story_next", cards.next_button)
	_mark("story_skip", cards.skip_button)
	_report.call_deferred("onboard_story")


func _coach_say(text: String) -> void:
	_coach.text = text
	_coach.visible = true
	_layout()


func _centered(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


## Same "UI_AT name x y" lines the shell prints, so the smoke test can tap them.
func _mark(name: String, c: Control) -> void:
	_marks[name] = c


func _report(screen: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	print("UI_SCREEN ", screen)
	_marks["skip"] = _skip
	for k in _marks:
		var c: Control = _marks[k]
		if is_instance_valid(c) and c.is_visible_in_tree():
			var p := c.get_global_rect().get_center()
			print("UI_AT %s %d %d" % [k, roundi(p.x), roundi(p.y)])
