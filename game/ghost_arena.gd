## Ghost Arena fight: your trio against an opponent's saved trio as a relay
## (sim/relay.gd), on the shared relay fight screen (game/relay_fight.gd).
## Each of your balls is aimed by you when it first comes out; the ghost
## fires its saved shots. Opened from the Arena screen with an attack already
## started in ArenaStore; the result goes back to it.
extends "res://game/relay_fight.gd"

const Intro := preload("res://game/ui/intro.gd")
const Lineup := preload("res://sim/lineup.gd")
const ArenaStore := preload("res://game/pvp/arena_store.gd")
const ArenaGhosts := preload("res://game/pvp/arena_ghosts.gd")
const Ladder := preload("res://game/pvp/ladder.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const FighterTag := preload("res://game/ui/fighter_tag.gd")

var store
var bot: Dictionary
var result_delta := 0
var slots := [[], []] ## Both trios as lineup slots, for the tier and power on show.

var _last_slots: Array = []


func _ready() -> void:
	store = ArenaStore.open()
	bot = store.pending_bot()
	if bot.is_empty():
		_back_to_arena.call_deferred()
		return
	marks = {"launch": "arena_launch", "out": "arena_forfeit", "skip": "arena_skip"}
	var ghost_aims: Array = []
	for i in bot.lineup.slots.size():
		ghost_aims.append(ArenaGhosts.slot_angle(bot.lineup, i, 1))
	# Both trios fight at their known tier, level and gear (sim/lineup.gd).
	slots = [store.pending.get("slots", store.slots()), bot.lineup.slots]
	var mine := Lineup.side(slots[0])
	var theirs := Lineup.side(slots[1])
	print("ARENA_READY bot=%s card=%s seed=%d" % [bot.id, store.pending.card, int(store.pending.seed)])
	start(Relay.new({
		"seed": int(store.pending.seed),
		"arena": store.pending.get("arena", "square"),
		"sides": [mine.sides, theirs.sides],
		"aims": [mine.sides.map(func(_c): return null), ghost_aims],
		"tiers": [mine.tiers, theirs.tiers],
		"powers": [mine.powers, theirs.powers],
		"gear": [mine.gear, theirs.gear],
		"talents": [mine.talents, theirs.talents],
		"tie_to": 0, # Both out together goes to the attacker: you.
	}), ["YOU", "GHOST"])


## Each ball starts aimed where you last shot it from.
func _first_aim(slot: int) -> int:
	var shot = store.shots[slot]
	return MatchSim.AIM_AT_CENTRE[0] + (int(shot) if shot != null else 0)


## Under the first aim: who you're attacking, the trophy stakes and a small
## Forfeit. An attack can't be left for free once it's started.
func _aim_extras() -> Array:
	if not unlaunched():
		return []
	var stake: Dictionary = store.pending_stake()
	return [Kit.hbox(8, [
		Kit.label("vs " + str(bot.name), 22, Kit.MUTED),
		Kit.glyph("trophy", 22, Color("ffc23d")),
		Kit.label("%+d / %d" % [int(stake.win), int(stake.loss)], 22, Kit.FG),
		Kit.spacer(),
		_forfeit_link(),
	], BoxContainer.ALIGNMENT_CENTER)]


## "T2 · Lv14 · 1,250 power" under the health bar of the ball `side` has out.
func _stats_text(side: int) -> String:
	var s := Lineup.clean(slots[side][relay.slot[side]])
	var parts := ["T%d" % int(s.tier)]
	if int(s.get("level", 0)) > 0:
		parts.append("Lv%d" % int(s.level))
	parts.append("%s power" % Kit.commas(FighterTag.rating(s)))
	return " · ".join(parts)


func _show_result() -> void:
	var won := relay.winner == 0
	var used: Array = []
	for i in 3:
		var a = relay.aims[0][i]
		used.append(null if a == null or not aimed[i] else int(a) - MatchSim.AIM_AT_CENTRE[0])
	_last_slots = store.pending.get("slots", [])
	result_delta = store.finish_attack(won, used)
	GlowState.note_fight(relay.winner, 0.0)
	if won:
		GlowState.note("arena_win")
	Intro.arena_fought = true
	sfx.on_result(relay.winner)
	var got: int = store.history[0].get("coins", 0) if not store.history.is_empty() else 0
	print("ARENA_RESULT won=%s delta=%d trophies=%d hash=%s" % [won, result_delta, store.trophies, relay.state_hash()])
	sfx.toggle_hidden = true # The popup covers the bottom row of pills.
	sfx.hold_victory(ResultPopup.show_over(ui_root, _result_card(got)))


## The result popup every fight ends on (ResultPopup): the trophy change,
## the league bar filling (or emptying) from where it was, what the fight
## earned as icons and numbers, then Back and Next fight.
func _result_card(got: int) -> Control:
	var delta_col: Color = Kit.GOOD if result_delta > 0 else (Kit.BAD if result_delta < 0 else Kit.MUTED)
	var headline := Kit.hbox(12, [Kit.glyph("trophy", 64, Color("ffc23d")), Kit.label("%+d" % result_delta, 72, delta_col)], BoxContainer.ALIGNMENT_CENTER)
	# League bar, animated from before the fight to now.
	var after: int = store.trophies
	var before: int = after - result_delta
	var lg: Dictionary = Ladder.league(after)
	var bar := Kit.bar(_league_frac(before), lg.color, 22)
	var tw := create_tween()
	tw.tween_interval(.35)
	tw.tween_property(bar, "value", _league_frac(after), .9).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var count := Kit.label(Kit.commas(before), 26)
	tw.parallel().tween_method(func(v: float): count.text = Kit.commas(roundi(v)), float(before), float(after), .9)
	var league := Kit.vbox(6, [
		Kit.hbox(8, [Kit.label(Ladder.league_label(after), 26, lg.color), Kit.spacer(), Kit.glyph("trophy", 24, Color("ffc23d")), count], BoxContainer.ALIGNMENT_CENTER),
		bar,
	])
	var rewards := Kit.hbox(28, [], BoxContainer.ALIGNMENT_CENTER)
	if got > 0:
		rewards.add_child(Kit.hbox(6, [Kit.glyph("token", 34, Color.WHITE), Kit.label("+%d" % got, 30)], BoxContainer.ALIGNMENT_CENTER))
	if result_delta > 0:
		# Every trophy won is also a Trophy Room point.
		rewards.add_child(Kit.hbox(6, [Kit.glyph("points", 30, Kit.WARN), Kit.label("+%d" % result_delta, 26, Kit.WARN)], BoxContainer.ALIGNMENT_CENTER))
	var next := Kit.button("Next fight", _next_fight, "go", 26, 84)
	var back := Kit.button("Back", _back_to_arena, "ghost", 26, 84)
	_mark("arena_next", next, ResultPopup.SLIDE_SECS) # Where the popup stops.
	_mark("arena_back", back, ResultPopup.SLIDE_SECS)
	var outcome := ResultPopup.outcome_of(relay.winner)
	var body: Array = [headline, league]
	if rewards.get_child_count() > 0:
		body.append(rewards)
	var card := ResultPopup.content("Ghost Arena · vs " + str(bot.name), outcome, body, [back, next])
	next.size_flags_stretch_ratio = 1.5
	return card


## How far through its league `trophies` sits (1 in the top league).
static func _league_frac(trophies: int) -> float:
	var idx := Ladder.league_index(trophies)
	if idx >= Ladder.LEAGUES.size() - 1:
		return 1.0
	var lo: int = Ladder.LEAGUES[idx].min
	return float(trophies - lo) / float(Ladder.LEAGUES[idx + 1].min - lo)


## Straight into another attack: a fresh seeded team near your new trophies,
## with the same trio as this fight.
func _next_fight() -> void:
	var offers: Array = store.offers()
	if offers.is_empty() or _last_slots.is_empty():
		_back_to_arena()
		return
	var offer: Dictionary = offers[randi_range(0, offers.size() - 1)]
	store.start_attack(offer.card, offer.bot, randi_range(1, 0x7FFFFFFF), _last_slots)
	get_tree().reload_current_scene()


## A small red "Forfeit" under the lineups; it asks before it costs anything.
func _forfeit_link() -> Control:
	var b := Button.new()
	b.text = "Forfeit"
	b.flat = true
	b.custom_minimum_size = Vector2(140, 56)
	b.add_theme_font_size_override("font_size", 26)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Kit.BAD)
	b.pressed.connect(_confirm_forfeit)
	return b


func _confirm_forfeit() -> void:
	var loss: int = int(store.pending_stake().loss)
	var yes := _button("Forfeit (%d)" % loss, _forfeit, 28)
	yes.add_theme_color_override("font_color", Kit.BAD)
	hold_aim = true # No aiming behind the question.
	_set_panel([_label("Forfeit this attack? It counts as a loss.", 28), _row([yes, _button("Keep going", _next_leg, 28)])])


func _forfeit() -> void:
	store.settle_abandoned()
	_back_to_arena()


## Back (or a swipe from the edge) mid-attack asks first: leaving is a loss.
func _back() -> void:
	if state == State.RESULT:
		_back_to_arena()
	elif unlaunched():
		_confirm_forfeit()


func _back_to_arena() -> void:
	ArenaStore.reopen = true
	get_tree().change_scene_to_file("res://game/main.tscn")
