## The new player's first fights after the tutorial: each one reveals the
## next part of the game, so nothing arrives all at once (Newms, 2026-10-16).
##   win 1-1 (an orb) -> Summon -> pick a fighter in Critters -> win 1-2 (gear)
##   -> equip it from the Bag -> win 1-3 -> Ghost Arena -> one Arena fight
##   -> Trophy Room -> everything else.
## The step lives in the profile (`intro`, saved and synced). Saves from before
## this existed load as DONE, and so does any new save started with URL params
## (smoke tests, links), the same rule as the tutorial. ?intro=1 forces it.
## Settings > Testing can restart or finish it.
extends RefCounted

const Kit := preload("res://game/ui/ui_kit.gd")
const ResultPopup := preload("res://game/ui/result_popup.gd")
const Glyph := preload("res://game/ui/glyph.gd")
const Gear := preload("res://sim/gear.gd")
const A11y := preload("res://game/a11y.gd")
const Motion := preload("res://game/ui/motion.gd")

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
	ARENA: ["Ghost Arena", "Take your trio up against other players' teams.", "ghost", "arena"],
	TROPHY: ["Trophy Room", "Your Arena win earned points. Spend them on stat boosts.", "trophy", "boosts"],
	DONE: ["Everything!", "Daily runs, the Spire, Quick fight, friends and more are all open now.", "play", ""],
}


static func step(p) -> int:
	return int(p.get("intro")) if p != null and p.get("intro") != null else DONE


static func done(p) -> bool:
	return step(p) >= DONE


## True when `feature` (a tab, a Play tile, an Arena room) is open for this player.
static func shows(p, feature: String) -> bool:
	return step(p) >= OPENS_AT.get(feature, DONE)


## The one-line hint for this screen at this step, or "".
static func coach(p, screen: String) -> String:
	match step(p):
		FIGHT_1:
			return "Win stage 1-1." if screen in ["world", "campaign"] else ("Tap Continue and win stage 1-1." if screen == "play" else "")
		SUMMON:
			return "Tap Free x1 to summon a critter." if screen == "summon" else "Open the Summon tab."
		FIGHTER:
			if screen == "detail":
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
			return "Pick an opponent and fight!" if screen == "arena" else ("Tap Ghost Arena." if screen == "play" else "")
		TROPHY:
			return "Tap the Trophy Room." if screen == "arena" else ""
	return ""


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
	if done(p) or zone != 0 or not r.get("won", false):
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
	if not MOMENTS.has(at):
		return
	var m: Array = MOMENTS[at]
	var badge := Kit.panel(Glyph.make(m[2], 96, Kit.ACCENT), Kit.box(Color("221e55"), Kit.ACCENT, 999, 3, 26))
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var go := Kit.button("Show me" if at != DONE else "Nice!", func():
		shell.close_overlay()
		var screen: String = m[3]
		if screen == "":
			return
		if screen in shell.TAB_IDS:
			shell.show_tab(screen)
			shell.spotlight_tab(screen)
		elif screen == "boosts":
			shell.show_tab("play")
			shell.go("arena")
			shell.go("boosts")
		else:
			shell.show_tab("play")
			shell.go(screen), "go", 30, 92)
	shell.mark("intro_go", go)
	var line := Kit.label(m[1], 25, Kit.MUTED, HORIZONTAL_ALIGNMENT_CENTER, true)
	line.custom_minimum_size.x = ResultPopup.inner_width(shell.size.x)
	shell.sheet(Kit.vbox(16, [
		Kit.caption("Unlocked" if at != DONE else "All unlocked", Kit.GOOD),
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
