## Quests: today's three quests and the daily chest under the painted quest
## board, then this week's three and the weekly chest (design: meta/quests.gd,
## state in game/glow/glow_state.gd). Opened from the Quests door on the Daily
## board and the Home Daily door. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const A11y := preload("res://game/a11y.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const LiveOps := preload("res://game/liveops.gd")
const Quests := preload("res://meta/quests.gd")
const FamilyIcon := preload("res://game/ui/family_icon.gd")
const WeekScreen := preload("res://game/ui/screens/week_screen.gd")
const PassScreen := preload("res://game/ui/screens/pass_screen.gd")

const DAILY := WeekScreen.QUESTS
const WEEKLY := Color("ff8fc8")
const ART_H := 112
const ART_H_TALL := 230 ## Tall phones have the room to show the quest board big.
const ICON := 34.0


static func build(shell, _params: Dictionary) -> Control:
	var t := LiveOps.now()
	var q: Dictionary = shell.glow.quests(t)
	var root := Kit.vbox(14)
	root.add_child(shell.title_row("Quests", {"back_mark": "quests_back", "info_mark": "quests_info", "info": [
		"Three quests a day and three a week. Tap Claim when one is done.",
		"Finish all three to open that day's or week's chest.",
		"Each daily quest also gives %d pass XP." % Quests.PASS_XP,
		"One free swap a day: tap the arrows on a quest to get a different one.",
		"Finished quests you forget to claim are paid out the next day.",
	]}))
	var today := Kit.vbox(8, [])
	for v in q.daily:
		today.add_child(_row(shell, v, DAILY, q.swap))
	today.add_child(_chest(shell, "Daily chest", q.chest, DAILY, false))
	var clock := Kit.label("New in " + LiveOps.countdown(t, q.day_ends), 18, Kit.MUTED)
	var art_h := ART_H_TALL if shell.size.y >= 1400.0 else ART_H
	var tile := WeekScreen.tile("Today", DAILY, Kit.LINE, Kit.PANEL, [today], null, clock, "daily_quests", null, art_h)
	# The quest board painting soaks up any spare height, so tall phones get a
	# bigger painting instead of empty bands above and below the cards.
	tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var parts: Node = tile.get_child(0)
	parts.get_child(0).size_flags_vertical = Control.SIZE_EXPAND_FILL
	parts.get_child(1).size_flags_vertical = Control.SIZE_FILL
	root.add_child(tile)
	var week := Kit.vbox(8, [Kit.hbox(0, [WeekScreen.line("THIS WEEK", 18, WEEKLY),
		Kit.label("New in " + LiveOps.countdown(t, q.week_ends), 18, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)])
	for v in q.weekly:
		week.add_child(_row(shell, v, WEEKLY, false))
	week.add_child(_chest(shell, "Weekly chest", q.week_chest, WEEKLY, true))
	var wp := Kit.panel(week, Kit.box(Kit.PANEL, Kit.LINE, 30, 2, 16))
	root.add_child(wp)
	return root


## Every quest and chest row shares these right-hand columns, so bars end
## together and reward icons, amounts and Claim / Done line up row to row.
const COUNT_W := 100
const ITEM_ICON := 40
const ITEM_NUM := 48
const STATUS_W := 104
const GAP := 10


## One quest: its line, a bar with the count just after it, what it pays, then
## Claim, a Done tick or the swap button.
static func _row(shell, v: Dictionary, accent: Color, can_swap: bool) -> Control:
	var name := Kit.hbox(6, [], BoxContainer.ALIGNMENT_BEGIN)
	if v.has("family") and str(v.family) != "":
		name.add_child(FamilyIcon.make(str(v.family), 26))
	var words := WeekScreen.line(v.text, 21, Kit.MUTED if v.claimed else Kit.FG)
	name.add_child(words)
	var goal := int(v.goal)
	var count := Kit.label("%s/%s" % [Kit.commas(int(v.progress)), Kit.commas(goal)], 16, Kit.MUTED)
	count.custom_minimum_size.x = _w(COUNT_W)
	var bar := Kit.bar(float(v.progress) / maxf(1.0, goal), Kit.GOOD if v.done else accent, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var left := Kit.vbox(4, [name, Kit.hbox(8, [bar, count], BoxContainer.ALIGNMENT_CENTER)])
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pay := _rewards(shell, v.rewards)
	pay.custom_minimum_size.x = _item_w()
	var row := Kit.hbox(GAP, [left, pay], BoxContainer.ALIGNMENT_CENTER)
	var status: Control = null
	if v.claimed:
		status = _tick()
	elif v.done:
		var claim := Kit.button("Claim", func(): _claim(shell, v.id), "go", 20, 52)
		shell.mark("quest_claim_" + str(v.id), claim)
		status = claim
	elif can_swap:
		var swap := Kit.card_button(Kit.glyph("replay", 26, Kit.MUTED), func(): _swap(shell, v.id), Kit.LINE, Kit.PANEL, 18, 8)
		swap.custom_minimum_size = Vector2(52, 52)
		swap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		shell.mark("quest_swap_" + str(v.id), swap)
		status = swap
	row.add_child(_status(status))
	var st := Kit.box(Color(Kit.PANEL.lightened(.04)), Kit.GOOD if v.done and not v.claimed else Kit.LINE, 20, 2, 8)
	return Kit.panel(row, st)


## A chest row: three pips for the quests done, what it holds, and Open. Its
## last reward sits in the quests' reward column; any others reach left into
## the count column above.
static func _chest(shell, title: String, c: Dictionary, accent: Color, weekly: bool) -> Control:
	var pips := Kit.hbox(4, [], BoxContainer.ALIGNMENT_CENTER)
	for i in maxi(3, int(c.of)):
		pips.add_child(_pip(i < int(c.done), accent))
	var name := Kit.label(title, 20, accent)
	var head := Kit.hbox(10, [name, pips], BoxContainer.ALIGNMENT_BEGIN)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pay := _rewards(shell, c.rewards)
	pay.alignment = BoxContainer.ALIGNMENT_END
	pay.custom_minimum_size.x = _item_w()
	var row := Kit.hbox(GAP, [head, pay], BoxContainer.ALIGNMENT_CENTER)
	var status: Control = null
	if c.claimed:
		status = _tick()
	elif c.ready:
		var open := Kit.button("Open", func(): _open_chest(shell, weekly), "go", 20, 52)
		shell.mark("quest_chest_" + ("week" if weekly else "day"), open)
		status = open
	row.add_child(_status(status))
	var st := Kit.box(Color(0, 0, 0, 0), Color(accent, .7), 20, 2, 8)
	return Kit.panel(row, st)


## The status column: always the same width, empty or not, so the columns to
## its left stay put.
static func _status(c: Control) -> Control:
	var cell := CenterContainer.new()
	cell.custom_minimum_size.x = STATUS_W
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if c != null:
		if c is Button:
			c.custom_minimum_size.x = STATUS_W
		cell.add_child(c)
	return cell


## Each reward is an icon and an amount in fixed-width slots, so icons and
## numbers line up down the screen. Gear says 1 like anything else.
static func _rewards(shell, rewards: Array) -> HBoxContainer:
	var h := Kit.hbox(8, [], BoxContainer.ALIGNMENT_BEGIN)
	for r in rewards:
		var icon: Control = PassScreen.reward_icon(shell, r, ITEM_ICON if r.kind == "gear" else ICON)
		icon.custom_minimum_size = Vector2(ITEM_ICON, ICON)
		var n := Kit.label(Kit.commas(int(r.get("n", 1))), 20)
		n.custom_minimum_size.x = _w(ITEM_NUM)
		h.add_child(Kit.hbox(2, [icon, n], BoxContainer.ALIGNMENT_CENTER))
	return h


static func _item_w() -> float:
	return ITEM_ICON + 2 + _w(ITEM_NUM)


## A column width that grows with Larger text like the words in it.
static func _w(px: int) -> float:
	return float(A11y.font(px))


static func _pip(on: bool, accent: Color) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(14, 14)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", Kit.box(accent if on else Color(0, 0, 0, .35), accent, 7, 2, 0))
	return p


static func _tick() -> Control:
	var c := Kit.chip("Done", Kit.GOOD, 16)
	c.custom_minimum_size.x = STATUS_W
	c.get_child(0).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return c


static func _claim(shell, id: String) -> void:
	var got: Array = shell.glow.claim_quest(id)
	if not got.is_empty():
		if shell.sfx != null:
			shell.sfx.play("coins")
		PassScreen.fly_rewards(shell, got, shell._marks.get("quest_claim_" + id))
	shell.refresh()


static func _open_chest(shell, weekly: bool) -> void:
	var got: Array = shell.glow.claim_quest_chest(weekly)
	if not got.is_empty():
		if shell.sfx != null:
			shell.sfx.play("coins")
		PassScreen.fly_rewards(shell, got, shell._marks.get("quest_chest_" + ("week" if weekly else "day")))
	shell.refresh()


static func _swap(shell, id: String) -> void:
	shell.glow.swap_quest(id)
	shell.refresh()
