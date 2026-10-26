## The Glow Pass (design/monetisation.md §4): season progress, today's
## quests and the weekly chest, then all 50 levels with the free and premium
## rewards side by side. Levels come from play only and are never sold.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const GearArt := preload("res://game/ui/gear_art.gd")
const A11y := preload("res://game/a11y.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const CosmeticIcon := preload("res://game/glow/cosmetic_icon.gd")
const Roster := preload("res://game/ui/roster.gd")
const LiveOps := preload("res://game/liveops.gd")
const ShopScreen := preload("res://game/ui/screens/shop_screen.gd")
const BagScreen := preload("res://game/ui/screens/bag_screen.gd")

## Cards claimed by the last tap (their marks): they flip over when the list is rebuilt.
static var _just_claimed: Array = []
const Gear := preload("res://sim/gear.gd")
const Quests := preload("res://meta/quests.gd")

const GLOW := Color("ffd36b")
const PREMIUM := Color("b366ff")


static func build(shell, _params: Dictionary) -> Control:
	var glow = shell.glow
	var t := LiveOps.now()
	var root := Kit.vbox(24)
	root.add_child(shell.title_row("Glow Pass", {"back_mark": "pass_back", "info_mark": "pass_info", "info": [
		"Pass XP comes from play: fights give 10-30 XP, solving the Daily Trick Shot gives %d, and each daily quest gives %d." % [GlowPass.TRICK_XP, Quests.PASS_XP],
		"Finish %d daily quests in a week to open the weekly chest (+%s XP)." % [GlowPass.CHEST_AFTER, Kit.commas(GlowPass.CHEST_XP)],
		"Premium adds looks and gems. Unlock any time to claim past levels.",
		"Past level 50: a bonus box every %s XP (Coins and a few gems), up to %d." % [Kit.commas(GlowPass.BONUS_XP), GlowPass.BONUS_MAX],
	]}))
	var season: Dictionary = glow.season(t)
	if season.is_empty():
		root.add_child(Kit.panel(Kit.label("The next season's pass opens soon. Everything you earned stays yours.", 26, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true),
			Kit.box(Kit.PANEL, Kit.LINE, 36, 2, 28)))
		return root
	var ps: Dictionary = glow.pass_state(t)
	var level: int = glow.pass_level(t)
	var prog := GlowPass.progress(int(ps.xp))

	# Header: season, level and XP.
	var lvl := _Medal.new()
	lvl.level = level
	lvl.custom_minimum_size = Vector2(104, 112)
	lvl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_text := ("Bonus box: %d / %d XP" if level >= GlowPass.LEVELS else "%d / %d XP to level %d") % ([prog.x, prog.y] if level >= GlowPass.LEVELS else [prog.x, prog.y, level + 1])
	var info := Kit.vbox(6, [Kit.label("%s · week %d of %d" % [season.name, season.week, season.weeks], 24, GLOW),
		Kit.bar(float(prog.x) / prog.y, GLOW, 22), Kit.label(bar_text, 22, Kit.MUTED),
		Kit.label("Ends in " + LiveOps.countdown(t, season.ends), 20, Kit.MUTED)])
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if GlowPass.xp_multiplier(season, t) > 1:
		info.add_child(Kit.label("Finale weekend: double pass XP!", 22, Kit.GOOD))
	root.add_child(Kit.panel(Kit.hbox(18, [lvl, info], BoxContainer.ALIGNMENT_CENTER), Kit.box(Color("221a3a"), Color("6b5520"), 40, 2, 26)))

	# Premium unlock.
	if not ps.premium:
		var store = glow.store
		var buttons := []
		if store.available():
			var buy := Kit.button("Unlock · " + store.price("glow_pass"), func(): store.purchase("glow_pass"), "primary", 28, 88)
			shell.mark("pass_buy", buy)
			buttons.append(buy)
		var with_gems := Kit.cost_button("", Catalog.PASS_GEMS, "gem", func():
			var err: String = glow.buy_pass_with_gems(t)
			if err == "Not enough Glow Gems.":
				ShopScreen.gem_sheet(shell)
			else:
				shell.toast(err if err != "" else "Glow Pass unlocked!")
				shell.refresh(), "ghost", 26, 88)
		shell.mark("pass_gems", with_gems)
		buttons.append(with_gems)
		var n_cos := 0
		var n_gems := 0
		for l in range(1, GlowPass.LEVELS + 1):
			var r := GlowPass.premium_reward(l)
			if r.get("kind") == "cosmetic":
				n_cos += 1
			elif r.get("kind") == "gems":
				n_gems += int(r.n)
		root.add_child(Kit.panel(Kit.vbox(12, [Kit.caption("Premium track", PREMIUM),
			Kit.hbox(8, [Kit.label("%d looks + %s" % [n_cos, Kit.commas(n_gems)], 24), Kit.glyph("gem", 26, Kit.FG)], BoxContainer.ALIGNMENT_CENTER),
			Kit.hbox(12, buttons)]), Kit.box(Color("1f1440"), Color(PREMIUM, .6), 36, 2, 24)))

	# Today's quests (each daily one pays pass XP) and the weekly chest.
	var q: Dictionary = glow.quests(t)
	var see := Kit.button("Quests", func(): shell.go("quests"), "ghost", 22, 64)
	see.custom_minimum_size.x = 150
	shell.mark("pass_quests", see)
	var today := Kit.label("%d/%d today · +%d XP each" % [q.chest.done, maxi(3, int(q.chest.of)), Quests.PASS_XP], 22, Kit.FG)
	today.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bv := Kit.vbox(12, [Kit.hbox(0, [Kit.caption("Quests"), Kit.spacer(),
		Kit.label("New in " + LiveOps.countdown(t, LiveOps.day_start(t) + LiveOps.DAY), 20, Kit.MUTED)]),
		Kit.hbox(12, [today, see], BoxContainer.ALIGNMENT_CENTER)])
	var w: Dictionary = glow.week_state(t)
	var chest_text := Kit.label("Chest %d/%d · +%s XP" % [mini(int(w.count), GlowPass.CHEST_AFTER), GlowPass.CHEST_AFTER, Kit.commas(GlowPass.CHEST_XP)], 22,
		Kit.GOOD if glow.chest_ready(t) else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)
	chest_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var chest_row := Kit.hbox(12, [chest_text], BoxContainer.ALIGNMENT_CENTER)
	if glow.chest_ready(t):
		var open := Kit.button("Open", func(): glow.open_chest(t); shell.toast("+%s pass XP from the weekly chest!" % Kit.commas(GlowPass.CHEST_XP)); shell.refresh(), "go", 24, 70)
		open.custom_minimum_size.x = 150
		open.size_flags_horizontal = Control.SIZE_SHRINK_END
		shell.mark("open_chest", open)
		chest_row.add_child(open)
	elif w.chest:
		chest_row.add_child(Kit.chip("Opened", Kit.GOOD))
	bv.add_child(chest_row)
	root.add_child(Kit.panel(bv, Kit.box(Kit.PANEL, Kit.LINE, 36, 2, 24)))

	# Claim all.
	var n: int = glow.claimable_count(t)
	if n > 0:
		var all := Kit.button("Claim all (%d)" % n, func(): _claim_all(shell, t), "go", 30, 92)
		shell.mark("claim_all", all)
		root.add_child(all)

	# The levels.
	var head := Kit.hbox(12, [_head("Lv", 70), _head("Free", 0), _head("Premium", 0, PREMIUM)])
	var list := Kit.vbox(10, [head])
	for l in range(1, GlowPass.LEVELS + 1):
		list.add_child(_level_row(shell, l, level, t))
	if level >= GlowPass.LEVELS:
		list.add_child(Kit.label("Bonus boxes opened: %d of %d." % [ps.boxes, GlowPass.BONUS_MAX], 22, Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true))
	root.add_child(list)
	return root


static func _head(text: String, width: float, color := Kit.MUTED) -> Control:
	var l := Kit.caption(text, color)
	if width > 0:
		l.custom_minimum_size.x = width
	else:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func _level_row(shell, l: int, level: int, t: int) -> Control:
	var reached := l <= level
	var num := Kit.panel(Kit.label(str(l), 26, Kit.BG if reached else Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER),
		Kit.box(GLOW if reached else Kit.PANEL2, Color(0, 0, 0, 0), 999, 0, 0))
	num.custom_minimum_size = Vector2(70, 70)
	(num.get_child(0) as Label).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# The track's spine: a bar through the level badges, lit up to your level.
	var spine := Control.new()
	spine.custom_minimum_size = Vector2(70, 70)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := ColorRect.new()
	bar.color = GLOW if l <= level else Kit.PANEL2
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = .5
	bar.anchor_right = .5
	bar.anchor_bottom = 1.0
	bar.offset_left = -4
	bar.offset_right = 4
	bar.offset_top = -10.0 if l > 1 else 35.0 # Up through the gap to the row above.
	bar.offset_bottom = 0.0 if l < GlowPass.LEVELS else -35.0
	spine.add_child(bar)
	var mid := CenterContainer.new()
	mid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(num)
	spine.add_child(mid)
	return Kit.hbox(12, [spine, _cell(shell, l, "free", t), _cell(shell, l, "premium", t)])


static func _cell(shell, l: int, track: String, t: int) -> Control:
	var glow = shell.glow
	var r: Dictionary = glow.reward(l, track, t)
	var accent := GLOW if track == "free" else PREMIUM
	if r.is_empty():
		var empty := Control.new()
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return empty
	var state := ""
	if glow.claimed(l, track, t):
		state = "Claimed"
	elif glow.can_claim(l, track, t):
		state = "Claim"
	elif track == "premium" and not glow.pass_state(t).premium:
		state = "locked"
	var icon := reward_icon(shell, r, 64)
	var text := Kit.vbox(2, [Kit.label(reward_text(r, true), 22, Kit.FG if state != "Claimed" else Kit.MUTED, HORIZONTAL_ALIGNMENT_LEFT, true)])
	var badge: Control = null
	if state == "Claim":
		badge = Kit.chip("Claim", Kit.GOOD, 16)
		_pulse_once(badge)
	elif state == "Claimed":
		badge = Kit.chip("Claimed", Kit.MUTED, 16)
	elif state == "locked":
		badge = Glyph.make("lock", 22, Kit.MUTED)
	if badge:
		badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		text.add_child(badge)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	var row := Kit.hbox(8, [icon, text], BoxContainer.ALIGNMENT_CENTER)
	# Premium cards wear a gold frame; anything you can claim is green.
	var frame: Color = Color(Glyph.GOLD, .55) if track == "premium" else Kit.LINE
	var border := Kit.GOOD if state == "Claim" else (Color(accent, .35) if l <= glow.pass_level(t) and track == "free" else frame)
	var card := Kit.card_button(row, func():
		if state == "Claim":
			_just_claimed = ["claim_%s_%d" % [track, l]]
			shell.reward_from(shell._marks.get("claim_%s_%d" % [track, l], shell))
			glow.claim(l, track, t)
			shell.toast("Got %s!" % reward_text(r))
			shell.refresh()
		elif r.kind == "cosmetic":
			ShopScreen.item_sheet(shell, r.id)
		elif state == "locked":
			shell.toast("Premium: unlock the pass.")
		elif state == "":
			shell.toast("Reach level %d to claim this." % l), border, Kit.PANEL, 24, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = Color(1, 1, 1, .55) if state == "locked" else Color.WHITE
	shell.mark("claim_%s_%d" % [track, l], card)
	var k := _just_claimed.find("claim_%s_%d" % [track, l])
	if k >= 0:
		# Just claimed: it flips over to its claimed side, a ripple down the list on Claim all.
		_flip(card, .06 * k)
		_just_claimed[k] = ""
	return card


static var _claiming := false

## Claim all: glide down to the first prize, claim everything (the cards flip
## in a ripple) and each prize flies up: coins, eggs and energy into their
## top-bar pills, everything else into the Bag.
static func _claim_all(shell, t: int) -> void:
	if _claiming:
		return
	var glow = shell.glow
	var marks := _claimable_marks(glow, t)
	var first: Control = shell._marks.get(marks[0]) if not marks.is_empty() else null
	if first != null:
		_claiming = true
		await shell.glide_to(first)
		_claiming = false
		if not is_instance_valid(first) or shell.current != "pass":
			return
	var rewards := {}
	for m in marks:
		var p: PackedStringArray = m.split("_")
		rewards[m] = glow.reward(int(p[2]), p[1], t)
	_just_claimed = marks.duplicate()
	shell.reward_from(first if first != null else shell._marks.get("claim_all", shell))
	var got: Array = glow.claim_all(t)
	shell.toast("Claimed %d reward%s!" % [got.size(), "" if got.size() == 1 else "s"])
	shell.refresh()
	await shell.get_tree().process_frame
	await shell.get_tree().process_frame
	var k := 0
	for m in marks:
		var r: Dictionary = rewards[m]
		var card = shell._marks.get(m)
		if r.is_empty() or r.kind in ["coins", "orbs", "energy"] or not is_instance_valid(card) or not card.is_visible_in_tree():
			continue
		var at: Vector2 = card.get_global_rect().position + Vector2(44, card.size.y / 2.0)
		if at.y < 0.0 or at.y > shell.size.y:
			continue # Scrolled out of sight: only the prizes you can see take off.
		shell.fly_to_tab(func(): return reward_icon(shell, r, 56), at, "bag", .25 + .08 * k)
		k += 1
		if k >= 6:
			break


## The cards a Claim all is about to claim (their marks), top to bottom.
static func _claimable_marks(glow, t: int) -> Array:
	var out: Array = []
	for l in range(1, GlowPass.LEVELS + 1):
		for track in ["free", "premium"]:
			if glow.can_claim(l, track, t):
				out.append("claim_%s_%d" % [track, l])
	return out


## A card turning over: squashed flat, then opening out on its new face.
static func _flip(c: Control, delay: float) -> void:
	if A11y.reduced_motion:
		return
	c.ready.connect(func():
		c.pivot_offset = c.size / 2.0
		c.scale = Vector2(0.0, 1.0)
		var tw := c.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(c, "scale", Vector2(1.08, 1.0), .16).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "scale", Vector2.ONE, .14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


## `beside_icon`: the currency's icon is right there, so show just the number.
static func reward_text(r: Dictionary, beside_icon := false) -> String:
	var n := int(r.get("n", 1))
	if beside_icon and r.kind in ["gems", "orbs", "coins", "energy"]:
		return Kit.commas(n)
	match r.kind:
		"cosmetic":
			return Catalog.item(r.id).get("name", r.id)
		"gems":
			return "%d Glow Gems" % n
		"orbs":
			return "%d Summon Egg%s" % [n, "" if n == 1 else "s"]
		"coins":
			return "%s Coins" % Kit.commas(n)
		"energy":
			return "%d Energy" % n
		"xp_chip":
			return "%d XP Chip%s" % [n, "" if n == 1 else "s"]
		"hammers":
			return "%d Hammer%s" % [n, "" if n == 1 else "s"]
		"copies":
			return "%s copy" % Roster.get_critter(r.id).name
		"gear":
			return "%d-star %s" % [int(r.tier), Gear.PIECES[r.type].name]
		"rift_key":
			return "%d Rift Key%s" % [n, "" if n == 1 else "s"]
		"dye":
			return "%d Spark Dye drop%s" % [n, "" if n == 1 else "s"]
	return r.kind


static func reward_icon(shell, r: Dictionary, side: float) -> Control:
	var g: Control
	match r.kind:
		"cosmetic":
			g = CosmeticIcon.make(r.id, shell.profile.lineup, side)
		"gems":
			g = Glyph.make("gem", side * .7)
		"orbs":
			g = Glyph.make("orb", side * .7)
		"coins":
			g = Glyph.make("coin", side * .7)
		"energy":
			g = Glyph.make("energy", side * .7)
		"hammers":
			g = Glyph.make("hammer", side * .7)
		"copies":
			var CritterIcon = load("res://game/ui/critter_icon.gd")
			g = CritterIcon.make(r.id, 1, side)
		"gear":
			g = GearArt.piece(r.type, int(r.tier), side * .8, BagScreen.tier_color(int(r.tier)))
		"rift_key":
			g = Glyph.make("key", side * .7, Color("5ce1ff"))
		"dye":
			g = Glyph.make("dye", side * .7, Color("ff6fd0"))
		_:
			g = Glyph.make("bolt", side * .7, Kit.GOOD)
	var cc := CenterContainer.new()
	cc.custom_minimum_size = Vector2(side, side)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(g)
	return cc


## A claim chip swells once when it appears, then sits still (no per-frame cost).
static func _pulse_once(c: Control) -> void:
	if A11y.reduced_motion:
		return
	c.ready.connect(func():
		c.pivot_offset = c.size / 2.0
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector2(1.18, 1.18), .25).set_trans(Tween.TRANS_SINE)
		tw.tween_property(c, "scale", Vector2.ONE, .3).set_trans(Tween.TRANS_SINE))


## The pass level as a medal: ribbon tails behind a scalloped gold rosette,
## an inner disc and the level number. Drawn once.
class _Medal extends Control:
	const Dot := preload("res://game/dot.gd")
	const Kit := preload("res://game/ui/ui_kit.gd")
	const A11y := preload("res://game/a11y.gd")
	const GLOW := Color("ffd36b")
	var level := 0

	func _draw() -> void:
		var c := Vector2(size.x / 2.0, 46.0)
		var r := 42.0
		# Ribbon tails.
		for sgn in [-1.0, 1.0]:
			var x: float = c.x + sgn * 14.0
			Dot.poly(self, PackedVector2Array([Vector2(x - 11, c.y + 20), Vector2(x + 11, c.y + 20), Vector2(x + 11 + sgn * 6, size.y), Vector2(x + sgn * 3, size.y - 10), Vector2(x - 11 + sgn * 6, size.y)]),
				Color("b366ff") if sgn < 0 else Color("8f4fe0"))
		# Scalloped rosette.
		var ros := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48
			ros.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * .88))
		Dot.poly(self, ros, GLOW.darkened(.25))
		Dot.circle(self, c, r * .8, GLOW)
		Dot.circle(self, c, r * .66, Color("fff2b0"))
		Dot.circle(self, c + Vector2(0, 2), r * .6, GLOW.darkened(.08))
		draw_arc(c, r * .66, PI * 1.1, PI * 1.6, 12, Color(1, 1, 1, .7), 3.0, true)
		var text := str(level)
		var fs := A11y.font(36)
		var sz := Kit.FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(Kit.FONT, c + Vector2(-sz.x / 2.0, sz.y * .32), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Kit.BG)
