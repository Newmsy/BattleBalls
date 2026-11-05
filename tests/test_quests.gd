## Daily and weekly Quests (meta/quests.gd, game/glow/glow_state.gd): the
## rolls, progress from play, claims, the chests, the swap, and that finished
## quests are never lost when the day ends.
extends "res://tests/test_case.gd"

const Quests := preload("res://meta/quests.gd")
const GlowPass := preload("res://game/glow/glow_pass.gd")
const GlowState := preload("res://game/glow/glow_state.gd")
const Catalog := preload("res://game/glow/catalog.gd")
const SaveGame := preload("res://game/online/save_game.gd")
const UiProfile := preload("res://game/ui/ui_profile.gd")
const LiveOps := preload("res://game/liveops.gd")
const Families := preload("res://sim/families.gd")
const BallDefs := preload("res://sim/ball_defs.gd")
const Shell := preload("res://game/ui/shell.gd")
const QuestsScreen := preload("res://game/ui/screens/quests_screen.gd")

var TEST_SAVE := "user://test_quests_save_%d.json" % OS.get_process_id()

const ALL := {"bosses": true, "families": ["frost", "fire"], "rare": true, "t3": true, "fuse": true, "egg": true}


func _t(date: String, hour := 12) -> int:
	return LiveOps.date_unix(date) + hour * 3600


func _fresh(p = null):
	LiveOps.use({"version": 1, "revision": 1, "fights": [], "seasons": [{"name": "Season A", "start": "2026-10-12", "weeks": 7}]})
	return GlowState.new(SaveGame.new(TEST_SAVE), p if p != null else UiProfile.sample())


func _done() -> void:
	LiveOps.use(LiveOps._read(LiveOps.BUNDLED))
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _find(list: Array, id: String) -> Dictionary:
	for q in list:
		if q.id == id:
			return q
	return {}


func test_every_day_rolls_one_quest_per_slot_and_everyone_gets_the_same() -> void:
	for day in 200:
		var a := Quests.roll_day(day, ALL)
		check_eq(a.size(), 3, "three dailies")
		for i in 3:
			check_eq(a[i].slot, Quests.DAILY_SLOTS[i], "slot order")
			check(not a[i].rewards.is_empty(), "pays something")
		check_eq(a, Quests.roll_day(day, ALL), "same day, same quests")
		var w := Quests.roll_week(day, ALL)
		check_eq(w.size(), 3, "three weeklies")


func test_quests_only_roll_for_what_the_player_has() -> void:
	var none := {"bosses": false, "families": [], "rare": false, "t3": false, "fuse": false, "egg": false}
	for day in 200:
		for q in Quests.roll_day(day, none) + Quests.roll_week(day, none):
			check(not q.is_empty(), "something always rolls")
			check(not str(q.id) in ["boss1", "fam3", "rare2", "tier3", "fuse1", "hatch1", "w_boss3"], "day %d: %s needs something" % [day, q.id])
	var seen := {}
	for day in 60:
		var q: Dictionary = Quests.roll_day(day, ALL)[2]
		if q.id == "fam3":
			check(q.family in ["frost", "fire"], "a family the player owns")
			check(str(q.text).contains(Families.info(q.family).name), "names the family")
			seen[q.family] = true
	check(seen.size() == 2, "both owned families come up")


func test_rewards_are_earned_power_and_never_gems_or_cosmetics() -> void:
	var rewards: Array = Quests.DAILY_CHEST + Quests.WEEKLY_CHEST
	for day in 14:
		for slot in Quests.DAILY_SLOTS:
			rewards += Quests.daily_reward(slot, day)
		for slot in Quests.WEEKLY_SLOTS:
			rewards += Quests.weekly_reward(slot, day)
	for r in rewards:
		check(r.kind in Catalog.POWER_KINDS + ["hammers"], "%s is an earned power reward" % r.kind)


func test_a_full_week_pays_the_planned_egg_income() -> void:
	var eggs := 0
	for day in 7:
		for slot in Quests.DAILY_SLOTS:
			for r in Quests.daily_reward(slot, day):
				eggs += int(r.n) if r.kind == "orbs" else 0
		for r in Quests.DAILY_CHEST:
			eggs += int(r.n) if r.kind == "orbs" else 0
	for r in Quests.WEEKLY_CHEST:
		eggs += int(r.n) if r.kind == "orbs" else 0
	check_eq(eggs, 26, "2 a day plus 12 a week, as meta/economy.gd plans")


func test_play_fills_quests_claims_pay_and_the_chest_opens() -> void:
	var p = UiProfile.sample()
	var g = _fresh(p)
	var t := _t("2026-10-14")
	var q: Dictionary = g.quests(t)
	check_eq(q.daily.size(), 3, "rolled with a profile")
	check(not q.chest.ready, "chest shut")
	# Finish every daily by force-filling each quest's own counter.
	for v in q.daily:
		g.record(v.kind, int(v.goal), t)
	q = g.quests(t)
	check(q.daily.all(func(v): return v.done), "all done")
	check(q.chest.ready, "chest ready once all three are done")
	check_eq(g.quests_ready(t), 4, "three claims and the chest")
	var energy: int = p.energy
	var orbs: int = p.orbs
	var xp: int = g.pass_xp(t)
	for v in q.daily:
		check(not g.claim_quest(v.id, t).is_empty(), "claimed " + v.id)
		check(g.claim_quest(v.id, t).is_empty(), "only once")
	check_eq(g.pass_xp(t), xp + 3 * Quests.PASS_XP, "pass XP per daily quest")
	check_eq(g.week_state(t).count, 3, "counts toward the pass's weekly chest")
	check(p.energy >= energy + 15 and p.orbs >= orbs + 1, "energy and an egg arrived")
	check(not g.claim_quest_chest(false, t).is_empty(), "chest opened")
	check(g.claim_quest_chest(false, t).is_empty(), "once")
	check_eq(int(g.g().quest_week.progress.get("chest", 0)), 1, "counts for Clear 5 daily chests")
	_done()


func test_fights_count_wins_families_and_different_critters() -> void:
	var g = _fresh()
	var t := _t("2026-10-14")
	var id: String = "vampire"
	g.record_fight(0, 300.0, t, {"critter": id, "tier": 3})
	g.record_fight(1, 120.0, t, {"critter": id})
	g.record_fight(0, 80.0, t, {"critter": "laser"})
	var d: Dictionary = g.g().quest_day.progress
	check_eq(int(d.fight), 3, "fights")
	check_eq(int(d.win), 2, "wins")
	check_eq(int(d.damage), 500, "damage")
	check_eq(int(d.get("win_fam:" + Families.of(id), 0)) >= 1, true, "family win")
	check_eq(int(d.get("win_t3", 0)), 1, "T3 win")
	check_eq(int(g.g().quest_week.progress.critters), 2, "two different critters won")
	g.record("bounce_floor", 4, t)
	g.record("bounce_floor", 7, t)
	g.record("bounce_floor", 5, t)
	check_eq(int(g.g().quest_day.progress.bounce_floor), 7, "best floor, not a sum")
	_done()


func test_relay_wins_count_each_quest_once_for_the_team() -> void:
	# Arena and Spire wins name the whole team: a frost trio with one T3
	# counts one family win, one T3 win and three different critters.
	var g = _fresh()
	var t := _t("2026-10-14")
	var frost: Array = []
	for id in BallDefs.PLAYABLE:
		if Families.of(id) == "frost" and frost.size() < 3:
			frost.append(id)
	g.record_fight(0, 450.0, t, {"critters": frost, "tiers": [1, 3, 1]})
	var d: Dictionary = g.g().quest_day.progress
	check_eq(int(d.get("win_fam:frost", 0)), 1, "one family win for the whole team")
	check_eq(int(d.get("win_t3", 0)), 1, "a T3 on the team counts once")
	check_eq(int(d.damage), 450, "relay damage counts")
	check_eq(int(g.g().quest_week.progress.critters), 3, "every critter that fought counts as won with")
	g.record_fight(1, 50.0, t, {"critters": frost, "tiers": [3, 3, 3]})
	check_eq(int(g.g().quest_day.progress.get("win_t3", 0)), 1, "a loss counts nothing")
	_done()


func test_one_free_swap_a_day() -> void:
	var g = _fresh()
	var t := _t("2026-10-14")
	var q: Dictionary = g.quests(t)
	var old: Dictionary = q.daily[1]
	var next: Dictionary = g.swap_quest(old.id, t)
	check(not next.is_empty() and next.id != old.id, "a different quest")
	check_eq(next.slot, old.slot, "same slot")
	check(g.swap_quest(q.daily[0].id, t).is_empty(), "only one swap")
	check(not g.quests(t).swap, "swap used")
	check(g.quests(t + 86400).swap, "a new swap tomorrow")
	_done()


func test_finished_quests_are_paid_after_the_day_ends() -> void:
	var p = UiProfile.sample()
	var g = _fresh(p)
	var t := _t("2026-10-14")
	var q: Dictionary = g.quests(t)
	for v in q.daily:
		g.record(v.kind, int(v.goal), t)
	var energy: int = p.energy
	var orbs: int = p.orbs
	var tomorrow: Dictionary = g.quests(t + 86400)
	check(tomorrow.daily.all(func(v): return int(v.progress) == 0 and not v.claimed), "fresh quests")
	check(p.orbs >= orbs + 1 + 2, "the egg quest and the chest's eggs were paid")
	check(p.energy >= energy + 15 + 20, "and the energy")
	check(g.g().quest_carry.is_empty(), "nothing left waiting")
	_done()


func test_progress_without_a_profile_waits_for_the_roll() -> void:
	var save := SaveGame.new(TEST_SAVE)
	LiveOps.use({"version": 1, "revision": 1, "fights": [], "seasons": []})
	var t := _t("2026-10-14")
	var bare = GlowState.new(save)
	bare.record_trick(t)
	check(bare.quests(t).daily.is_empty(), "no roll without a profile")
	var g = GlowState.new(save, UiProfile.sample())
	check_eq(int(g.g().quest_day.progress.trick), 1, "the solve is kept")
	check_eq(g.quests(t).daily.size(), 3, "rolled once a profile is here")
	_done()


func test_the_quests_screen_opens_from_home() -> void:
	var shell = Shell.new()
	shell.glow = _fresh(shell.profile)
	shell.build()
	shell.show_tab("play")
	check(shell._marks.has("daily_quests"), "the Quests spot on Home")
	check(not "week" in Shell.SCREENS and not shell._marks.has("thisweek"), "no Daily board")
	shell._marks.daily_quests.pressed.emit()
	check_eq(shell.current, "quests", "opens the Quests screen")
	check(shell._marks.has("quest_swap_" + str(shell.glow.quests().daily[0].id)), "a swap button")
	shell.free()
	_done()


func test_retired_quests_are_swapped_out() -> void:
	var old := {"id": "w_fotd5", "kind": "fotd", "goal": 5, "slot": "habit", "rewards": [{"kind": "coins", "n": 1}], "text": "Call 5 Fights of the Day"}
	var list := [old]
	check(Quests.refresh_retired(list, true, 100, {}), "a Fight of the Day quest is replaced")
	check(str(list[0].kind) != "fotd" and list[0].slot == "habit", "by another habit quest")
	check_eq(list[0].rewards, old.rewards, "with the same rewards")
	check(not Quests.refresh_retired(list, true, 100, {}), "nothing left to replace")
	for pool in Quests.DAILY.values() + Quests.WEEKLY.values():
		for q in pool:
			check(not str(q.kind) in Quests.RETIRED, "%s isn't retired" % q.id)
