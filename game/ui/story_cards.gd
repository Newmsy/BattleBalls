## A chapter's story (meta/story.gd) as cards: the speaking critter's portrait,
## its name and one line at a time. Tap anywhere for the next line; Skip ends
## it. `on_done` runs once, when the last line is tapped or on Skip. Used by
## the campaign screen (as a shell overlay) and by the tutorial.
extends Control

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const GlitchArt := preload("res://game/ui/glitch_art.gd")

const GLITCH_PINK := Color("ff2bd6")

var story := {}
var on_done := Callable()
var next_button: Button
var skip_button: Button
var _at := 0
var _card: Control
var _ended := false


static func make(story_: Dictionary, on_done_: Callable) -> Control:
	var s = load("res://game/ui/story_cards.gd").new()
	s.story = story_
	s.on_done = on_done_
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	s.theme = Kit.theme()
	s._build()
	return s


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(.02, .015, .06, .9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	# The whole screen is the Next button; the card sits on top but lets taps through.
	next_button = Button.new()
	next_button.flat = true
	next_button.focus_mode = Control.FOCUS_NONE
	next_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var clear := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		next_button.add_theme_stylebox_override(st, clear)
	next_button.pressed.connect(advance)
	add_child(next_button)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_card = Control.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(_card)
	skip_button = Kit.button("Skip", finish, "ghost", 20, 56)
	skip_button.custom_minimum_size.x = 120
	skip_button.anchor_left = 1.0
	skip_button.anchor_right = 1.0
	skip_button.offset_left = -140
	skip_button.offset_right = -20
	skip_button.offset_top = 30
	skip_button.offset_bottom = 86
	add_child(skip_button)


func _ready() -> void:
	_show_line()


## The next line, or the end after the last one.
func advance() -> void:
	if _ended:
		return
	_at += 1
	if _at >= story.lines.size():
		finish()
		return
	_show_line()


func finish() -> void:
	if _ended:
		return
	_ended = true
	print("STORY_DONE %s" % story.get("title", ""))
	if on_done.is_valid():
		on_done.call()


func _show_line() -> void:
	for c in _card.get_children():
		c.queue_free()
	var line: Array = story.lines[_at]
	var who: String = line[0]
	var name := ""
	var color := Kit.ACCENT
	var portrait: Control
	match who:
		"":
			portrait = null
		"glitch":
			name = "The Glitch"
			color = GLITCH_PINK
			portrait = GlitchArt.make(220)
		"boss":
			name = "%s · Glitched" % story.get("boss_name", "Boss")
			color = GLITCH_PINK
			portrait = glitched_portrait(story.get("boss", "juggernaut"), 240)
		_:
			var c := Roster.get_critter(who)
			name = c.name
			color = c.color
			portrait = CritterIcon.make(who, 1, 220)
			portrait.info = false # A tap moves the story on.
	var width := minf(640.0, get_viewport_rect().size.x - 48.0) if is_inside_tree() else 640.0
	var v := Kit.vbox(18)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.custom_minimum_size.x = width
	var head := Kit.vbox(2, [Kit.caption(story.get("caption", "Prologue"), Color("9be89a")),
		Kit.label(story.get("title", ""), 38, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER, true)])
	head.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	if portrait != null:
		var pc := CenterContainer.new()
		pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pc.add_child(portrait)
		v.add_child(pc)
	var text := Kit.label(line[1], 28, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER if who == "" else HORIZONTAL_ALIGNMENT_LEFT, true)
	text.custom_minimum_size.x = width - 56.0
	var bubble := Kit.vbox(8, [Kit.label(name, 24, color), text] if name != "" else [text])
	var panel := Kit.panel(bubble, Kit.box(Kit.PANEL2, Color(color, .8), 32, 3, 26))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(panel)
	# Progress dots and the hint.
	var dots := Kit.hbox(10, [], BoxContainer.ALIGNMENT_CENTER)
	for k in story.lines.size():
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(14, 14)
		d.color = Kit.FG if k == _at else Kit.LINE
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots.add_child(d)
	v.add_child(dots)
	v.add_child(Kit.label("Tap to continue" if _at + 1 < story.lines.size() else "Tap to start", 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	_card.custom_minimum_size = v.get_combined_minimum_size()
	_card.add_child(v)
	_pass_taps(v)
	if not A11y.reduced_motion and is_inside_tree():
		v.modulate.a = 0.0
		v.position.y = 24
		var tw := create_tween().set_parallel()
		tw.tween_property(v, "modulate:a", 1.0, .2)
		tw.tween_property(v, "position:y", 0.0, .25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	print("STORY_LINE %d %s" % [_at, who])


## A boss as the Glitch left it: tinted magenta with the Glitch riding on top.
static func glitched_portrait(id: String, side: float) -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(side, side)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := CritterIcon.make(id, 3, side)
	icon.info = false
	icon.modulate = Color(1.7, .5, 1.4) # Pushes any colour towards the Glitch's magenta.
	box.add_child(icon)
	var g := GlitchArt.make(side * .4)
	g.position = Vector2(side * .62, 0)
	box.add_child(g)
	return box


## Containers catch taps by default; the card lets every tap reach Next.
static func _pass_taps(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for k in c.get_children():
		if k is Control:
			_pass_taps(k)
