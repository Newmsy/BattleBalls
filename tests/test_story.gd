## The campaign story (meta/story.gd): every chapter is castable, plays once
## per save and old saves pick it up.
extends "res://tests/test_case.gd"

const Profile := preload("res://meta/profile.gd")
const Story := preload("res://meta/story.gd")
const Zones := preload("res://meta/zones.gd")
const Roster := preload("res://game/ui/roster.gd")
const StoryCards := preload("res://game/ui/story_cards.gd")
const Shell := preload("res://game/ui/shell.gd")


func test_every_zone_has_a_chapter_with_real_speakers() -> void:
	var all: Array = [Story.PROLOGUE]
	for z in Zones.ZONES.size():
		var c := Story.chapter(z)
		check(not c.is_empty(), "zone %d has a chapter" % (z + 1))
		check(c.boss_name != "", "zone %d names its boss" % (z + 1))
		all.append(c)
	for c in all:
		check(c.lines.size() >= 3 and c.lines.size() <= 6, "%s is short" % c.title)
		for line in c.lines:
			var who: String = line[0]
			if who not in ["", "glitch", "boss"]:
				check(Roster.CRITTERS.any(func(r): return r.id == who), "%s: %s is a critter" % [c.title, who])
			check(line[1].length() <= 100, "%s: a line fits the card" % c.title)


func test_seen_chapters_survive_a_save_and_old_saves_get_the_story() -> void:
	var p = Profile.new_game(1_800_000_000)
	check(not Story.seen(p, "glow_garden"), "a new player hasn't seen chapter 1")
	Story.mark_seen(p, "glow_garden")
	Story.mark_seen(p, "glow_garden")
	check_eq(p.story, ["glow_garden"] as Array[String], "seen once")
	var d: Dictionary = p.to_dict()
	check(Story.seen(Profile.from_dict(d, 1_800_000_000), "glow_garden"), "seen survives a save")
	d.erase("story")
	check(not Story.seen(Profile.from_dict(d, 1_800_000_000), "glow_garden"), "a save from before the story plays it")
	Story.skip_all(p)
	for z in Zones.ZONES.size():
		check(Story.seen(p, Zones.zone(z).id), "skip_all covers zone %d" % (z + 1))


func test_cards_step_through_every_line_then_finish_once() -> void:
	var done := [0]
	var cards = StoryCards.make(Story.chapter(1), func(): done[0] += 1)
	get_root().add_child(cards)
	for k in Story.chapter(1).lines.size():
		check_eq(done[0], 0, "still playing at line %d" % k)
		cards.advance()
	check_eq(done[0], 1, "finished after the last line")
	cards.advance()
	cards.finish()
	check_eq(done[0], 1, "finishes only once")
	cards.free()


func test_the_campaign_plays_a_new_chapter_once() -> void:
	var shell = Shell.new()
	shell.profile = Profile.new_game(1_800_000_000)
	shell.build()
	shell.go("campaign", {"zone": 0})
	check_eq(shell._overlay_tag, "story", "chapter 1 plays on the first visit")
	shell._overlay.get_child(0).finish()
	check(Story.seen(shell.profile, "glow_garden"), "finishing it counts as seen")
	shell.refresh()
	check(not shell.overlay_open(), "it doesn't play again")
	check(shell._marks.has("story"), "the Story button replays it")
	shell.free()


func get_root() -> Window:
	return runner.root
