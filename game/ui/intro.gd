## The new player's first fights after the tutorial: each one reveals the
## next part of the game, so nothing arrives all at once (Newms, 2026-10-16).
##   win 1-1 (an orb) -> Summon -> pick a fighter in Critters -> win 1-2 (gear)
##   -> equip it from the Bag -> win 1-3 -> Ghost Arena -> one Arena fight
##   -> Trophy Room -> everything else.
## The step lives in the profile (`intro`, saved and synced). Saves from before
## this existed load as DONE, and so does any new save started with URL params
## (smoke tests, links), the same rule as the tutorial. ?intro=1 forces it.
## Settings > Testing can restart or finish it.
## Past the guided fights the other two main modes open with zone 1 stages,
## spaced evenly with the rest (Newms, 2026-11-01):
##   1-3 Arena -> 1-5 Bosses -> 1-7 Bounce Run -> 1-9 Critter Plunge
##   -> 1-11 Gear Vault and Rift.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Gear := preload("res://sim/gear.gd")
const A11y := preload("res://game/a11y.gd")
const Motion := preload("res://game/ui/motion.gd")
const Zones := preload("res://meta/zones.gd")

## Set when a Ghost Arena fight finishes this session; the Arena screen
## then opens the Trophy Room for a new player.
static var arena_fought := false

enum { FIGHT_1, SUMMON, FIGHTER, FIGHT_2, EQUIP, FIGHT_3, ARENA, TROPHY, DONE }

## Feature -> the step that reveals it. Anything not listed opens at DONE;
## Play, Fuse (the tutorial teaches it) and the campaign are always open.
const OPENS_AT := {"play": FIGHT_1, "fuse": FIGHT_1, "campaign": FIGHT_1, "summon": SUMMON,
	"critters": FIGHTER, "bag": EQUIP, "arena": ARENA, "trophy": TROPHY}

## What each reveal says: [title, line, glyph, screen to open].
const MOMENTS := {
	SUMMON: ["Summon", "You won a Summon Egg! Hatch a new critter.", "summon", "summon"],
	FIGHTER: ["Critters", "Your collection lives here. Pick who fights for you.", "critters", "critters"],
	EQUIP: ["Bag", "You found gear! Equip it to make a critter stronger.", "bag", "bag"],
	ARENA: ["Arena", "Take your trio up against other players' teams.", "ghost", "arena"],
	TROPHY: ["Trophy Room", "Your Arena win earned points. Spend them on stat boosts.", "trophy", "boosts"],
	DONE: ["Daily Quests", "Daily quests, friends and the Glow Pass are open. More opens as you clear Glow Garden.", "play", ""],
	BOUNCE_RUN: ["Bounce Run", "Draft a trio and climb the floors. Your best floor each day opens a chest.", "bounce", "bouncerun"],
	PLUNGE: ["Critter Plunge", "Race your critters down a marble run, abilities flying. Medals for the podium.", "medal_gold", "plunge"],
	TRICK_SHOT: ["Trick Shot", "A new bank shot every day. Three tries to find the angle.", "target", "trickshot"],
	BOSSES: ["Bosses", "Giant bosses with big prizes. A few tries a day.", "hammer", "bosses"],
	SPIRE: ["The Spire", "Fifty floors, one fight each. How high can you climb?", "tower", "spire"],
	RIFTS: ["Rifts", "Spend a Rift Key to dive into one family's rift for dyes and rewards.", "key", "rift"],
}

## The main modes that open with a zone 1 stage (0-based) for a paced player,
## and the moment each shows. The stage's first win opens it.
const BOUNCE_RUN := 100
const PLUNGE := 101
const MODE_STAGE := {"bouncerun": 6, "plunge": 8}
const MODE_MOMENT := {"bouncerun": BOUNCE_RUN, "plunge": PLUNGE}
## The side features on Home's "More to play" strip that open with a zone 1
## stage for a paced player, so they arrive one at a time after the guided
## fights (Quests opens with the guided fights' end). Bosses (1-5) and Rifts
## (1-11) have their own gates; they only get the moment here.
const TRICK_SHOT := 102
const BOSSES := 103
const SPIRE := 104
const RIFTS := 105
const SIDE_STAGE := {"trickshot": 3, "spire": 5}
const STAGE_MOMENT := {3: TRICK_SHOT, 4: BOSSES, 5: SPIRE, 10: RIFTS}


static func step(p) -> int:
	return int(p.get("intro")) if p != null and p.get("intro") != null else DONE


static func done(p) -> bool:
	return step(p) >= DONE


## True when `feature` (a tab, a Play tile, an Arena room) is open for this player.
static func shows(p, feature: String) -> bool:
	return step(p) >= OPENS_AT.get(feature, DONE)


## True when main mode `mode` ("bouncerun" or "plunge") is open: after the
## guided fights, and for a paced player once its zone 1 stage is won.
static func mode_open(p, mode: String) -> bool:
	if not done(p):
		return false
	return p == null or not p.get("paced") or int(p.stars.get(Zones.stage_key(0, MODE_STAGE[mode]), 0)) > 0


## True when side feature `key` ("trickshot" or "spire") is open: after the
## guided fights, and for a paced player once its zone 1 stage is won.
static func side_open(p, key: String) -> bool:
	if not done(p):
		return false
	return p == null or not p.get("paced") or int(p.stars.get(Zones.stage_key(0, SIDE_STAGE[key]), 0)) > 0


## What a closed main mode says: the stage that opens it.
static func mode_line(mode: String) -> String:
	return "Opens after stage 1-%d" % (int(MODE_STAGE[mode]) + 1)


## The one-line hint for this screen at this step, or "". `params` are the
## screen's (the critter page's critter).
static func coach(p, screen: String, params := {}) -> String:
	match step(p):
		FIGHT_1:
			return "Win stage 1-1." if screen in ["world", "campaign"] else ("Tap Continue and win stage 1-1." if screen == "play" else "")
		SUMMON:
			return "Tap Free x1 to summon a critter." if screen == "summon" else "Open the Summon tab."
		FIGHTER:
			if screen == "detail":
				if p.lineup == str(params.get("id", "")):
					return "Tap Your fighter to fight with it."
				return "Tap Pick to make it your fighter."
			return "Tap a critter to see it." if screen == "critters" else "Open the Critters tab and pick your fighter."
		FIGHT_2:
			return "Win stage 1-2." if screen in ["world", "campaign", "play"] else ""
		EQUIP:
			if screen == "detail":
				return "Tap the gear slot to equip it."
			return "Tap your new gear, then pick who wears it." if screen == "bag" else "Open the Bag to equip your gear."
		FIGHT_3:
			return "Win stage 1-3." if screen in ["world", "campaign", "play"] else ""
		ARENA:
			return "Pick an opponent and fight!" if screen == "arena" else ("Tap Fight on the Arena door." if screen == "play" else "")
		TROPHY:
			if screen == "boosts":
				return "Tap a boost to make your trio stronger."
			return "Tap the Trophy Room." if screen == "versus" else ""
	return ""


## The control the spotlight lights for this screen at this step (a shell
## mark, or "tab_<id>" for a tab), or "" for none.
static func target(p, screen: String, params := {}) -> String:
	var stage := {FIGHT_1: 1, FIGHT_2: 2, FIGHT_3: 3}
	var at := step(p)
	if at in stage:
		match screen:
			"play":
				return "campaign"
			"world":
				return "enter_zone"
			"campaign":
				return "stage_1_%d" % stage[at] if int(params.get("zone", 0)) == 0 else ""
		return ""
	match at:
		SUMMON:
			return "pull1" if screen == "summon" else "tab_summon"
		FIGHTER:
			if screen == "detail":
				return "detail_fighter"
			return "tile_" + str(p.lineup) if screen == "critters" else "tab_critters"
		EQUIP:
			var g := newest_gear(p)
			if screen == "detail":
				return "slot_" + str(g.get("slot", "")).to_lower() if not g.is_empty() else ""
			if screen == "bag":
				return "gear_%d" % int(g.uid) if not g.is_empty() else ""
			return "tab_bag"
		ARENA:
			if screen == "play":
				return "arena"
			return "arena_card_0" if screen == "arena" else ""
		TROPHY:
			if screen == "boosts":
				return "boost_trophy_pick"
			return "arena_boosts" if screen == "versus" else ""
	return ""


## The piece of gear a new player last won and hasn't put on, or {}.
static func newest_gear(p) -> Dictionary:
	var best := {}
	for g in p.gear:
		if str(g.get("on", "")) == "" and (best.is_empty() or int(g.uid) > int(best.uid)):
			best = g
	return best


## Moves the player on to `to` if they're before it; returns true if they moved.
static func reach(p, to: int) -> bool:
	if step(p) >= to:
		return false
	p.intro = to
	p.changed.emit()
	print("INTRO step=%d" % to)
	return true


## A campaign win: 1-1 reveals Summon (with a guaranteed orb), 1-2 the Bag
## (with a guaranteed piece of gear), 1-3 the Ghost Arena. Adds what it gave
## to the result `r` and sets r.intro to the step reached, for the popup.
static func after_stage(p, zone: int, stage: int, r: Dictionary) -> void:
	if zone != 0 or not r.get("won", false):
		return
	if done(p):
		# A paced player's first win of a mode's stage opens that mode.
		for mode in MODE_STAGE:
			if p.paced and stage == MODE_STAGE[mode] and r.get("first_clear", false):
				r.intro = MODE_MOMENT[mode]
				print("INTRO_MODE %s" % mode)
		# And the side features, one stage at a time.
		if p.paced and r.get("first_clear", false) and STAGE_MOMENT.has(stage):
			r.intro = STAGE_MOMENT[stage]
			print("INTRO_SIDE %d" % stage)
		return
	if stage == 0 and step(p) < SUMMON:
		if int(r.get("orbs", 0)) == 0:
			p.orbs += 1
			r.orbs = 1
		reach(p, SUMMON)
		r.intro = SUMMON
	elif stage == 1 and step(p) < EQUIP:
		if r.get("gear", []).is_empty():
			r.gear = [p.add_gear("bubble_shell", 1)]
		reach(p, EQUIP)
		r.intro = EQUIP
	elif stage == 2 and step(p) < ARENA:
		reach(p, ARENA)
		r.intro = ARENA


## A new player's next guided step is a campaign fight: open the stage list.
static func to_campaign(shell) -> void:
	shell.show_tab("play")
	shell.go("world")
	shell.go("campaign", {"zone": 0})


## The "New: X unlocked" moment: a sheet with the feature's badge and one
## line, and a button that takes you there.
static func moment(shell, at: int) -> void:
	if not MOMENTS.has(at) or not is_instance_valid(shell):
		return
	var m: Array = MOMENTS[at]
	var badge := Kit.panel(Glyph.make(m[2], 96, Kit.ACCENT), Kit.box(Color("221e55"), Kit.ACCENT, 999, 3, 26))
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var go := Kit.button("Nice!" if at == DONE else "Show me", func():
		shell.close_overlay()
		var screen: String = m[3]
		if screen == "":
			return
		if screen == "bouncerun":
			shell.get_tree().change_scene_to_file("res://game/bounce_run.tscn")
		elif screen == "trickshot":
			shell.get_tree().change_scene_to_file("res://game/trick_shot.tscn")
		elif screen in shell.TAB_IDS:
			shell.show_tab(screen)
			shell.spotlight_tab(screen)
		elif screen == "boosts":
			shell.show_tab("play")
			shell.go("versus")
			shell.go("boosts")
		else:
			shell.show_tab("play")
			shell.go(screen), "go", 30, 92)
	shell.mark("intro_go", go)
	var line := Kit.label(m[1], 25, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	line.custom_minimum_size.x = ResultPopup.inner_width(shell.size.x)
	shell.sheet(Kit.vbox(16, [
		Kit.caption("Unlocked", Kit.GOOD),
		_burst_behind(badge),
		Kit.label(m[0], 44, Kit.FG, HORIZONTAL_ALIGNMENT_CENTER),
		line,
		go,
	]))
	print("INTRO_UNLOCK %s" % m[3])


## The badge bursts in over a gold flash, like Bounce Run's TIER UP.
static func _burst_behind(badge: Control) -> Control:
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if A11y.reduced_motion:
		holder.add_child(badge)
		return holder
	var burst := Panel.new()
	burst.add_theme_stylebox_override("panel", Kit.box(Color("ffd166", .5), Color(0, 0, 0, 0), 999, 0, 0))
	burst.custom_minimum_size = Vector2(150, 150)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(burst)
	holder.add_child(badge)
	var tw := burst.create_tween().set_parallel()
	tw.tween_interval(.15)
	tw.chain().tween_method(func(t: float) -> void:
		burst.pivot_offset = burst.size / 2.0
		burst.scale = Vector2.ONE * lerpf(.5, 4.0, t)
		burst.modulate.a = 1.0 - t, 0.0, 1.0, .7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	Motion.pop(badge, 0.0, .45, .15)
	return holder
