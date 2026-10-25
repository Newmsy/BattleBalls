## Quests: today's three quests and the daily chest under the painted quest
## board, then this week's three and the weekly chest (design: meta/quests.gd,
## state in game/glow/glow_state.gd). Opened from the Quests door on the Daily
## board and the Home Daily door. Fits one phone screen.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
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
	root.add_child(WeekScreen.tile("Today", DAILY, Kit.LINE, Kit.PANEL, [today], null, clock, "daily_quests", null, art_h))
	var week := Kit.vbox(8, [Kit.hbox(0, [WeekScreen.line("THIS WEEK", 18, WEEKLY),
		Kit.label("New in " + LiveOps.countdown(t, q.week_ends), 18, Kit.MUTED)], BoxContainer.ALIGNMENT_CENTER)])
	for v in q.weekly:
		week.add_child(_row(shell, v, WEEKLY, false))
	week.add_child(_chest(shell, "Weekly chest", q.week_chest, WEEKLY, true))
	var wp := Kit.panel(week, Kit.box(Kit.PANEL, Kit.LINE, 30, 2, 16))
	root.add_child(wp)
	return root


## One quest: its line and progress bar, what it pays, then Claim, a Done
## tick or the swap button.
static func _row(shell, v: Dictionary, accent: Color, can_swap: bool) -> Control:
	var name := Kit.hbox(6, [], BoxContainer.ALIGNMENT_BEGIN)
	if v.has("family") and str(v.family) != "":
		name.add_child(FamilyIcon.make(str(v.family), 26))
	var words := WeekScreen.line(v.text, 21, Kit.MUTED if v.claimed else Kit.FG)
	name.add_child(words)
	var goal := int(v.goal)
	var count := Kit.label("%s/%s" % [Kit.commas(int(v.progress)), Kit.commas(goal)], 16, Kit.MUTED)
	var bar := Kit.bar(float(v.progress) / maxf(1.0, goal), Kit.GOOD if v.done else accent, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var left := Kit.vbox(4, [name, Kit.hbox(8, [bar, count], BoxContainer.ALIGNMENT_CENTER)])
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(10, [left, _rewards(shell, v.rewards)], BoxContainer.ALIGNMENT_CENTER)
	if v.claimed:
		row.add_child(_tick())
	elif v.done:
		var claim := Kit.button("Claim", func(): _claim(shell, v.id), "go", 20, 52)
		claim.custom_minimum_size.x = 104
		shell.mark("quest_claim_" + str(v.id), claim)
		row.add_child(claim)
	elif can_swap:
		var swap := Kit.card_button(Kit.glyph("replay", 26, Kit.MUTED), func(): _swap(shell, v.id), Kit.LINE, Kit.PANEL, 18, 8)
		swap.custom_minimum_size = Vector2(52, 52)
		shell.mark("quest_swap_" + str(v.id), swap)
		row.add_child(swap)
	var st := Kit.box(Color(Kit.PANEL.lightened(.04)), Kit.GOOD if v.done and not v.claimed else Kit.LINE, 20, 2, 8)
	return Kit.panel(row, st)


## A chest row: three pips for the quests done, what it holds, and Claim.
static func _chest(shell, title: String, c: Dictionary, accent: Color, weekly: bool) -> Control:
	var pips := Kit.hbox(4, [], BoxContainer.ALIGNMENT_CENTER)
	for i in maxi(3, int(c.of)):
		pips.add_child(_pip(i < int(c.done), accent))
	var name := Kit.label(title, 20, accent)
	var head := Kit.hbox(10, [name, pips], BoxContainer.ALIGNMENT_BEGIN)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := Kit.hbox(10, [head, _rewards(shell, c.rewards)], BoxContainer.ALIGNMENT_CENTER)
	if c.claimed:
		row.add_child(_tick())
	elif c.ready:
		var open := Kit.button("Open", func(): _open_chest(shell, weekly), "go", 20, 52)
		open.custom_minimum_size.x = 104
		shell.mark("quest_chest_" + ("week" if weekly else "day"), open)
		row.add_child(open)
	var st := Kit.box(Color(0, 0, 0, 0), Color(accent, .7), 20, 2, 8)
	return Kit.panel(row, st)


static func _rewards(shell, rewards: Array) -> Control:
	var h := Kit.hbox(8, [], BoxContainer.ALIGNMENT_END)
	for r in rewards:
		var icon: Control = PassScreen.reward_icon(shell, r, ICON * (1.5 if r.kind == "gear" else 1.0))
		var n := int(r.get("n", 1))
		if r.kind == "gear":
			h.add_child(icon)
		else:
			h.add_child(Kit.hbox(2, [icon, Kit.label(Kit.commas(n), 20)], BoxContainer.ALIGNMENT_CENTER))
	return h


static func _pip(on: bool, accent: Color) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(14, 14)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", Kit.box(accent if on else Color(0, 0, 0, .35), accent, 7, 2, 0))
	return p


static func _tick() -> Control:
	var c := Kit.chip("Done", Kit.GOOD, 16)
	c.custom_minimum_size.x = 104
	return c


static func _claim(shell, id: String) -> void:
	var got: Array = shell.glow.claim_quest(id)
	if not got.is_empty():
		if shell.sfx != null:
			shell.sfx.play("coins")
	shell.refresh()


static func _open_chest(shell, weekly: bool) -> void:
	var got: Array = shell.glow.claim_quest_chest(weekly)
	if not got.is_empty():
		if shell.sfx != null:
			shell.sfx.play("coins")
	shell.refresh()


static func _swap(shell, id: String) -> void:
	shell.glow.swap_quest(id)
	shell.refresh()
