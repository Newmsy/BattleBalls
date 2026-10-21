## The mini Critterpedia card: tap a critter almost anywhere (a lineup, a
## foe team, a picker with a long press, a ball in a running fight) and this
## pops up over everything with its name, rarity, family, tier and what its
## ability does at every tier, the tapped tier lit up. Built only when opened,
## so it costs nothing until then; a fight keeps running underneath.
## Render/UI only: never touches the sim.
extends CanvasLayer

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Roster := preload("res://game/ui/roster.gd")
const CritterDb := preload("res://sim/critter_db.gd")
const Families := preload("res://sim/families.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")
const TouchInput := preload("res://game/ui/touch_input.gd")

const LAYER := 90 ## Over every screen and fight, under the edge-swipe hint.

static var _current: CanvasLayer
static var last_asked := "" ## The critter the last open() was for (tests read it).

var card: Control ## The card itself, for tests and the fit check.


## Opens the card for `id` at `tier` from any node in the tree. `level` and
## `power` are shown when known (0 leaves them out).
static func open(from: Node, id: String, tier := 1, level := 0, power := 0) -> void:
	last_asked = id
	if from == null or not from.is_inside_tree() or not CritterDb.has(id) or not Roster.ids().has(id):
		return
	close()
	var popup = load("res://game/ui/critter_popup.gd").new()
	popup.layer = LAYER
	popup.name = "CritterPopup"
	from.get_tree().root.add_child(popup)
	var width := minf(660.0, popup.get_viewport().get_visible_rect().size.x - 40.0)
	popup.build(id, clampi(tier, 1, Roster.MAX_TIER), level, power, _shell_of(from), width)
	_current = popup
	print("UI_POPUP critter ", id, " T", tier) # Smoke tests wait for this.


static func current() -> CanvasLayer:
	return _current if is_instance_valid(_current) else null


static func close() -> void:
	if is_instance_valid(_current):
		_current.queue_free()
	_current = null


## The home shell that `from` sits in, while it's on screen (it can open the full
## Critterpedia page); null in a fight.
static func _shell_of(from: Node) -> Node:
	var n := from
	while n != null:
		if n.has_method("go") and n.has_method("overlay_open"):
			return n if n.is_visible_in_tree() else null
		n = n.get_parent()
	return null


## Fills the card in; `width` is the card's width in design pixels.
func build(id: String, tier: int, level: int, power: int, shell: Node, width: float) -> void:
	var c := Roster.get_critter(id)
	var d := CritterDb.get_critter(id)
	var rcol: Color = Roster.RARITY_COLORS[c.rarity]

	var root := Control.new()
	root.theme = Kit.theme() # Its own layer, so it doesn't inherit the screens' font.
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := Button.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim_style := Kit.box(Color(.02, .015, .06, .7), Color(0, 0, 0, 0), 0, 0, 0)
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		dim.add_theme_stylebox_override(st, dim_style)
	dim.pressed.connect(close)
	root.add_child(dim)

	# Head: the critter, then its name, number, type and tags.
	var tags := Kit.hbox(8, [Kit.chip(Roster.RARITY_NAMES[c.rarity], rcol)])
	var fam := Families.of(id)
	if fam != "":
		var fi: Dictionary = Families.info(fam)
		tags.add_child(Kit.chip(fi.name, Color(fi.color)))
	tags.add_child(Kit.chip(c.role, Kit.MUTED))
	var stand := Kit.hbox(10, [Kit.glyph("stars", 26, Kit.FG, tier)])
	if level > 0:
		stand.add_child(Kit.label("Lv%d" % level, 22, Kit.MUTED))
	if power > 0:
		stand.add_child(Kit.power(power, 22))
	var name_l := Kit.label(c.name, 34, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
	var side := Kit.vbox(6, [name_l, Kit.label("#%03d · %s" % [d.no, c.type], 21, Kit.MUTED), tags, stand])
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	var art: Control = load("res://game/ui/critter_icon.gd").make(id, tier, 150)
	art.info = false
	var head := Kit.hbox(14, [art, side], BoxContainer.ALIGNMENT_CENTER)

	# The ability as it is at this tier, with its numbers, then what each tier
	# adds (the tiers it has in full colour, this one lit gold).
	var text_w := width - 56.0 - 12.0 - 64.0
	var now := Kit.label(AbilityText.now(id, tier), 23, Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
	now.custom_minimum_size.x = width - 64.0 # Wrapped text measures before layout.
	# At T1 the T1 row already says it all.
	var ladder := Kit.vbox(6, [Kit.caption("Ability at T%d" % tier, Glyph.GOLD), now, Kit.caption("Each tier")] if tier > 1 else [Kit.caption("Ability by tier")])
	for i in Roster.MAX_TIER:
		var here := i == tier - 1
		var has := i < tier
		var tag := Kit.panel(Kit.label("T%d" % (i + 1), 19, Kit.BG, HORIZONTAL_ALIGNMENT_CENTER),
			Kit.box(Glyph.GOLD if here else (Kit.ACCENT if has else Kit.LINE), Color(0, 0, 0, 0), 10, 0, 2))
		tag.custom_minimum_size = Vector2(52, 0)
		tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var l := Kit.label(AbilityText.change(id, i + 1), 20, Kit.FG if has else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
		l.custom_minimum_size.x = text_w
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ladder.add_child(Kit.hbox(12, [tag, l]))

	var buttons := Kit.hbox(14)
	var full: Button = null
	if shell != null:
		full = Kit.button("Critterpedia", func():
			close()
			shell.go("dex_entry", {"id": id}), "ghost", 24, 76)
		buttons.add_child(full)
	var ok := Kit.button("Got it", close, "go", 24, 76)
	buttons.add_child(ok)

	var body := Kit.vbox(16, [head, Kit.panel(ladder, Kit.box(Kit.PANEL, Kit.LINE, 22, 2, 14)), buttons])
	card = Kit.panel(body, Kit.box(Roster.rarity_bg(c.rarity, Color("16133a"), .14), Roster.rarity_border(c.rarity, Kit.ACCENT), 36, 3, 22))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.custom_minimum_size.x = width
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(card)
	root.add_child(centre)
	TouchInput.set_back(self, func(): return Callable(close) if is_inside_tree() else Callable())
	if is_inside_tree():
		_report.call_deferred(card, ok, full)


## Smoke test hooks: where the card and its buttons ended up, and whether it fits.
func _report(card: Control, ok: Control, full: Control) -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	for b in [[ok, "popup_close"], [full, "popup_full"]]:
		if b[0] != null:
			var at: Vector2 = b[0].get_global_rect().get_center()
			print("UI_AT %s %d %d" % [b[1], roundi(at.x), roundi(at.y)])
	var view := get_viewport().get_visible_rect().size
	var cr := card.get_global_rect()
	if cr.position.y < 0.0 or cr.end.y > view.y + 1.0 or cr.position.x < 0.0 or cr.end.x > view.x + 1.0:
		print("UI_OVERFLOW critter_popup %d" % roundi(cr.size.y))


func _exit_tree() -> void:
	TouchInput.clear_back(self)
