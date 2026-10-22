## Fusion Lab: pick a ready critter, see exactly what improves, press Fuse.
## The three copies spiral into the middle, flash, and the next tier pops out.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const CritterIcon := preload("res://game/ui/critter_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const Analytics := preload("res://game/online/analytics.gd")
const A11y := preload("res://game/a11y.gd")
const AbilityText := preload("res://game/ui/ability_text.gd")

const LAB_HEIGHT := 330.0
const SLOT := 116.0


static func build(shell, params: Dictionary) -> Control:
	var p = shell.profile
	var ready := sorted(p.ready_to_fuse())
	var sel: Dictionary = {}
	var at := find(ready, params.get("id", ""), params.get("tier", 0))
	if at >= 0:
		sel = ready[at]
	elif not ready.is_empty():
		sel = ready[0]

	var root := Kit.vbox(18)
	root.add_child(shell.title_row("Fusion Lab", {"back": false, "eyebrow": "3 of a kind → next tier", "info_title": "How fusing works", "info_mark": "fuse_info", "info": [
		"3 of a kind → 1 of the next tier, up to T5.",
		"The new copy keeps the highest level of the three, and its level cap goes up.",
		"Gear goes back to your Bag."]}))

	var list := Kit.vbox(12, [Kit.caption("Ready to fuse")])
	if ready.is_empty():
		list.add_child(Kit.panel(Kit.label("Nothing to fuse. Get 3 of a kind.", 23, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)))
	else:
		var scroll := ScrollContainer.new()
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		var row := Kit.hbox(12)
		var sel_card: Control = null
		for s in ready:
			var on: bool = s == sel
			var v := Kit.vbox(2, [CritterIcon.make(s.id, s.tier, 96), Kit.label(Roster.get_critter(s.id).name, 21, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
				_center(Glyph.make("stars", 20, Kit.FG, s.tier)), Kit.label("x%d" % s.count, 19, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER)])
			var rarity: String = Roster.get_critter(s.id).rarity
			var card := Kit.card_button(v, func(): shell.refresh_with({"id": s.id, "tier": s.tier, "x": scroll.scroll_horizontal}),
				Kit.GOOD if on else Roster.rarity_border(rarity, Kit.LINE), Roster.rarity_bg(rarity, Kit.PANEL), 28, 8)
			if on:
				sel_card = card
			card.custom_minimum_size.x = 160
			shell.mark("ready_%s_%d" % [s.id, s.tier], card)
			row.add_child(card)
		scroll.add_child(row)
		scroll.custom_minimum_size.y = row.get_combined_minimum_size().y
		list.add_child(scroll)
		# Keep your place in a long list: same scroll as before, selected card in view.
		scroll.ready.connect(func(): _restore_x(scroll, int(params.get("x", 0)), sel_card))
	root.add_child(list)

	var lab := _lab(sel)
	lab.set_meta("ready", ready)
	if list.get_child_count() > 1 and list.get_child(1) is ScrollContainer:
		lab.set_meta("scroll", list.get_child(1))
	root.add_child(lab)

	if not sel.is_empty():
		var c := Roster.get_critter(sel.id)
		var pv: Dictionary = p.fuse_preview(sel.id, sel.tier)
		# The two things that change most up front; the rest behind the "i".
		var lines := ["Max level %d → %d" % [pv.cap_before, pv.cap_after]]
		if pv.level > 1:
			lines.append("Keeps Lv %d" % pv.level)
		lines.append("T%d adds: %s" % [pv.tier, AbilityText.change(sel.id, pv.tier)])
		var more: Control = shell.info_button("%s T%d" % [c.name, pv.tier], lines, "fuse_result_info")
		var rows := Kit.vbox(8, [Kit.hbox(8, [Kit.caption("Result: %s T%d" % [c.name, pv.tier]), Kit.spacer(), more], BoxContainer.ALIGNMENT_CENTER)])
		rows.add_child(_kv("Power", "%s → %s" % [Kit.commas(pv.power_before), Kit.commas(pv.power_after)], true))
		rows.add_child(_kv("New", AbilityText.change(sel.id, pv.tier), true))
		root.add_child(Kit.panel(rows, Kit.box(Kit.PANEL, Kit.LINE, 32, 2, 20)))
		var btn := Kit.button("Fuse", func(): pass, "go", 34, 96)
		btn.pressed.connect(func(): _do_fuse(shell, lab, btn, sel))
		shell.mark("fuse", btn)
		shell.pin(btn)
	return root


static func _lab(sel: Dictionary) -> Control:
	var lab := Control.new()
	lab.custom_minimum_size = Vector2(0, LAB_HEIGHT)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", Kit.box(Kit.PANEL, Kit.LINE, 44, 2, 0))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_child(bg)
	for layer in [_Forge.new(), _Ring.new()]:
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lab.add_child(layer)
	var slots: Array = []
	for k in 3:
		var slot: Control
		if sel.is_empty():
			slot = Kit.panel(Kit.label("+", 40, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER), Kit.box(Kit.PANEL2, Kit.LINE, 999, 2, 0))
			(slot.get_child(0) as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		else:
			slot = CritterIcon.make(sel.id, sel.tier, SLOT)
		slot.size = Vector2(SLOT, SLOT)
		slot.set_meta("angle", -PI / 2 + k * TAU / 3)
		lab.add_child(slot)
		slots.append(slot)
	lab.set_meta("slots", slots)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_child(flash)
	lab.set_meta("flash", flash)
	lab.resized.connect(func(): _place_slots(lab))
	return lab


static func _place_slots(lab: Control) -> void:
	if lab.get_meta("fusing", false):
		return
	var centre := Vector2(lab.size.x / 2.0, LAB_HEIGHT / 2.0)
	for s in lab.get_meta("slots"):
		var a: float = s.get_meta("angle")
		s.position = centre + Vector2(cos(a) * 150.0, sin(a) * 100.0) - s.size / 2.0


static func _do_fuse(shell, lab: Control, btn: Button, sel: Dictionary) -> void:
	btn.disabled = true
	lab.set_meta("fusing", true)
	var centre := Vector2(lab.size.x / 2.0, LAB_HEIGHT / 2.0)
	var tw := lab.create_tween().set_parallel(true)
	for s in lab.get_meta("slots"):
		s.pivot_offset = s.size / 2.0
		tw.tween_property(s, "position", centre - s.size / 2.0, .6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "rotation", TAU, .6).set_ease(Tween.EASE_IN)
		tw.tween_property(s, "scale", Vector2(.5, .5), .6).set_ease(Tween.EASE_IN)
	var pv: Dictionary = shell.profile.fuse_preview(sel.id, sel.tier)
	tw.chain().tween_callback(func():
		var result: Dictionary = shell.profile.fuse(sel.id, sel.tier)
		for s in lab.get_meta("slots"):
			s.visible = false
		var flash: ColorRect = lab.get_meta("flash")
		flash.color.a = .95
		lab.create_tween().tween_property(flash, "color:a", 0.0, .55)
		# The payoff: the new power counts up from the old one, in green.
		var pow := Kit.power(pv.power_before, 28, Kit.GOOD)
		pow.alignment = BoxContainer.ALIGNMENT_CENTER
		var num: Label = pow.get_child(1)
		var out := Kit.vbox(4, [CritterIcon.make(sel.id, result.tier, 170, true), Kit.label("%s T%d" % [Roster.get_critter(sel.id).name, result.tier], 30, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
			_center(Glyph.make("stars", 30, Kit.FG, result.tier)), pow])
		if A11y.reduced_motion:
			num.text = Kit.commas(pv.power_after)
		else:
			lab.create_tween().tween_method(func(v: float): num.text = Kit.commas(roundi(v)), float(pv.power_before), float(pv.power_after), .8).set_delay(.3).set_ease(Tween.EASE_OUT)
		lab.add_child(out)
		lab.move_child(out, lab.get_child_count() - 2)
		out.reset_size()
		out.position = centre - out.size / 2.0
		out.pivot_offset = out.size / 2.0
		out.scale = Vector2(.2, .2)
		lab.create_tween().tween_property(out, "scale", Vector2.ONE, .45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		print("UI_FUSED %s T%d" % [sel.id, result.tier])
		Analytics.track("fuse", {"critter": sel.id, "tier": result.tier})
		btn.text = "CONTINUE"
		btn.disabled = false
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		var old: Array = lab.get_meta("ready", [])
		btn.pressed.connect(func():
			var sc: ScrollContainer = lab.get_meta("scroll", null)
			var next := pick_after_fuse(old, sorted(shell.profile.ready_to_fuse()), sel)
			next["x"] = sc.scroll_horizontal if is_instance_valid(sc) else 0
			shell.refresh_with(next)))


## Rarest first, then the highest tier (a fuse to T3 before the same critter's fuse to T2), then by name.
static func sorted(ready: Array) -> Array:
	var out := ready.duplicate()
	out.sort_custom(func(a, b):
		var ra := Roster.RARITIES.find(Roster.get_critter(a.id).rarity)
		var rb := Roster.RARITIES.find(Roster.get_critter(b.id).rarity)
		if ra != rb:
			return ra > rb
		if a.tier != b.tier:
			return a.tier > b.tier
		return Roster.get_critter(a.id).name < Roster.get_critter(b.id).name)
	return out


## Index of the id/tier stack in a ready list, or -1.
static func find(ready: Array, id: String, tier: int) -> int:
	for i in ready.size():
		if ready[i].id == id and ready[i].tier == tier:
			return i
	return -1


## Which stack to select after fusing `sel`: the same one while it still has
## 3+ copies, else the one that came after it in the list, else the one now at
## its old place (the end of the list if it was last).
static func pick_after_fuse(old: Array, now: Array, sel: Dictionary) -> Dictionary:
	if now.is_empty():
		return {}
	if find(now, sel.id, sel.tier) >= 0:
		return {"id": sel.id, "tier": sel.tier}
	var i := find(old, sel.id, sel.tier)
	for j in range(i + 1, old.size()):
		var k := find(now, old[j].id, old[j].tier)
		if k >= 0:
			return {"id": now[k].id, "tier": now[k].tier}
	var s: Dictionary = now[clampi(i, 0, now.size() - 1)]
	return {"id": s.id, "tier": s.tier}


static func _restore_x(scroll: ScrollContainer, at: int, card: Control) -> void:
	await scroll.get_tree().process_frame
	await scroll.get_tree().process_frame
	if not is_instance_valid(scroll):
		return
	scroll.scroll_horizontal = at
	if is_instance_valid(card):
		scroll.ensure_control_visible(card)


static func _kv(k: String, v: String, good := false) -> Control:
	var key := Kit.label(k, 23, Kit.MUTED)
	key.custom_minimum_size.x = 120
	var val := Kit.label(v, 23, Kit.GOOD if good else Kit.FG, HORIZONTAL_ALIGNMENT_LEFT, true)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return Kit.hbox(12, [key, val])


static func _center(c: Control) -> Control:
	var cc := CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(c)
	return cc


## The fusion platform under the slots: a round steel deck seen at an angle,
## an engraved inner ring, a socket pad under each slot and grooves running
## from the sockets into the core. Drawn once.
class _Forge extends Control:
	const Dot := preload("res://game/dot.gd")
	const DECK := Color("1f1b4a")
	const RIM := Color("3a3480")
	const GROOVE := Color("0f0d2a")
	const LAB_H := 330.0 ## The lab's LAB_HEIGHT and SLOT.
	const SLOT_SIDE := 116.0

	## Where slot k's critter stands and where the three meet, in the lab's space.
	static func socket(sz: Vector2, k: int) -> Vector2:
		var a := -PI / 2 + k * TAU / 3
		return Vector2(sz.x / 2.0, LAB_H / 2.0) + Vector2(cos(a) * 150.0, sin(a) * 100.0 + SLOT_SIDE * .32)

	static func core(sz: Vector2) -> Vector2:
		return Vector2(sz.x / 2.0, LAB_H / 2.0 + 18.0)

	func _draw() -> void:
		var mid: Vector2 = core(size)
		_ellipse(mid + Vector2(0, 10), Vector2(222, 132), Color(0, 0, 0, .3))
		_ellipse(mid, Vector2(218, 128), RIM)
		_ellipse(mid, Vector2(210, 121), DECK)
		_ring(mid, Vector2(168, 96), Color(RIM, .8), 2.0)
		_ring(mid, Vector2(120, 68), Color(RIM, .5), 2.0)
		for k in 3:
			var p: Vector2 = _Forge.socket(size, k)
			draw_line(p, mid, GROOVE, 12.0, true)
			draw_line(p, mid, Color(RIM, .7), 2.0, true)
		for k in 3:
			var p: Vector2 = socket(size, k)
			_ellipse(p, Vector2(56, 19), GROOVE)
			_ring(p, Vector2(56, 19), RIM, 3.0)
			_ring(p, Vector2(42, 13), Color(.56, .48, 1.0, .35), 2.0)
		_ellipse(mid, Vector2(34, 16), GROOVE)
		_ring(mid, Vector2(34, 16), RIM, 3.0)

	func _ellipse(c: Vector2, r: Vector2, col: Color) -> void:
		draw_set_transform(c, 0.0, Vector2(1.0, r.y / r.x))
		Dot.circle(self, Vector2.ZERO, r.x, col)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	func _ring(c: Vector2, r: Vector2, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * i / 48
			pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
		draw_polyline(pts, col, w, true)


## The moving part of the lab: dashes turning slowly round the deck's rim,
## light running down the grooves into the core and the core's glow. Slow,
## so it redraws on the shared idle clock and only while it shows.
class _Ring extends Control:
	const CritterIcon := preload("res://game/ui/critter_icon.gd")
	const Dot := preload("res://game/dot.gd")
	const A11y := preload("res://game/a11y.gd")
	const LIGHT := Color(.62, .54, 1.0)
	var _tick := -1

	func _process(_delta: float) -> void:
		if not is_visible_in_tree():
			return
		var tick := CritterIcon.clock()
		if tick != _tick:
			_tick = tick
			queue_redraw()

	func _draw() -> void:
		var t := 0.0 if A11y.reduced_motion else Time.get_ticks_msec() / 1000.0
		var core: Vector2 = _Forge.core(size)
		var segs := PackedVector2Array()
		for i in 28:
			var a := t * .25 + i * TAU / 28
			segs.append(core + Vector2(cos(a) * 214.0, sin(a) * 124.5))
			segs.append(core + Vector2(cos(a + .1) * 214.0, sin(a + .1) * 124.5))
		draw_multiline(segs, Color(LIGHT, .55), 3.0, true)
		for k in 3:
			var p: Vector2 = _Forge.socket(size, k)
			var u := fmod(t * .45 + k / 3.0, 1.0)
			var at := p.lerp(core, u)
			Dot.circle(self, at, 9.0, Color(LIGHT, .18 * sin(u * PI)))
			Dot.circle(self, at, 4.0, Color(1, 1, 1, .7 * sin(u * PI)))
		var pulse := .5 + .5 * sin(t * 2.2)
		draw_set_transform(core, 0.0, Vector2(1.0, .5))
		Dot.circle(self, Vector2.ZERO, 44.0 + 6.0 * pulse, Color(LIGHT, .12))
		Dot.circle(self, Vector2.ZERO, 26.0, Color(LIGHT, .35 + .2 * pulse))
		Dot.circle(self, Vector2.ZERO, 11.0, Color(1, 1, 1, .8))
		draw_set_transform_matrix(Transform2D.IDENTITY)
