## The campaign story (design/glitch.md): a few lines of chat between critters
## that play the first time you open each chapter (a campaign zone), plus the
## prologue that opens the tutorial. Presentation only; no numbers change.
## Each line is [speaker, text]. A speaker is a critter id, "glitch" (the
## Glitch), "boss" (this chapter's boss, Glitched) or "" (the narrator).
## Which chapters a player has seen is the profile's `story` list.
extends RefCounted

const Zones := preload("res://meta/zones.gd")

const PROLOGUE := {
	"title": "The Neon Circuit",
	"lines": [
		["", "The Neon Circuit: seven glowing arenas where critters bounce and battle for fun."],
		["vampire", "Another perfect day for a bounce. And a snack."],
		["laser", "Hold on. Did the static just... giggle?"],
		["glitch", "Hee hee! #?!& Your shiny little Circuit would look SO much better scrambled."],
		["laser", "Weird. Never mind! Nibbles, sparring match? Let's see who wins."],
	],
}

## Zone id -> its chapter. The boss speaks last but one, as the Glitch left it.
const CHAPTERS := {
	"glow_garden": {
		"title": "Something's wrong in the Garden",
		"lines": [
			["spiker", "Psst! Boulder fell asleep in the middle of the Garden again."],
			["glitch", "A big sleepy ball? Perfect. Let's make it MEGA!"],
			["boss", "BOULDER... SMASH... zzz... SMASH!"],
			["speedster", "Beat us on the way to the end of the Garden, then snap Boulder out of it!"],
		],
	},
	"circuit_lab": {
		"title": "Overclocked",
		"lines": [
			["juggernaut", "Thanks for waking me up! The Glitch ran off to Circuit Lab."],
			["glitch", "Plug in, crank it up... MAXIMUM Optic! Hee hee!"],
			["boss", "BEAMS. EVERYWHERE. CAN'T. STOP. ZIGZAGGING."],
			["cogs", "We fight in pairs in the Lab. Bring a buddy: two critters this time."],
		],
	},
	"frostbite_caves": {
		"title": "Paused",
		"lines": [
			["glitch", "New plan! Find the pause button. Press. Hold. Forever."],
			["yeti", "Chill was mid-yawn when the Glitch froze it. Now it's a glacier!"],
			["boss", "...yaaaaaaaa..."],
			["laser", "Teams of three in the Caves. Mind the ice, and the spikes!"],
		],
	},
	"bramble_hollow": {
		"title": "The Thorn King",
		"lines": [
			["mole", "Bramble found a shiny pixel crown and now it's bossing the whole forest around."],
			["glitch", "Bow before the Thorn King! The crown was MY idea. Mine!"],
			["boss", "KNEEL, SMALL BALLS! THE THORNS OBEY ME!"],
			["frost", "Watch out for the old trees and sinkholes. Let's knock that crown off."],
		],
	},
	"haunted_arcade": {
		"title": "Copy, paste, paste",
		"lines": [
			["pixel", "My pixels are tingling. The Glitch is close. This arcade is its home turf."],
			["glitch", "Copy. Paste. Paste. PASTE! One Wisp was boring anyway."],
			["boss", "We are Wisp. We are Wisp. We are... how many are we?"],
			["puppeteer", "Mind the portals. Nothing in here is quite where it seems."],
		],
	},
	"starfall_rim": {
		"title": "Zoom 300%",
		"lines": [
			["glitch", "You fixed FIVE of my pranks?! Fine. Time to think BIG."],
			["prism", "It zoomed Void in to 300%! The whole rim is shrinking around it."],
			["boss", "EVERYTHING... FALLS... TOWARDS... ME."],
			["thorns", "The Cheer Squad's right behind you. Show it how small it really is!"],
		],
	},
	"magma_core": {
		"title": "The last stand",
		"lines": [
			["drako", "Ember is the brightest flame in the Circuit. But its eyes look... pixelly."],
			["glitch", "No more pranks from the outside. This time I'M driving. Hee hee!"],
			["boss", "I AM EMBER REBORN! (Hee hee, it's me in here!)"],
			["juggernaut", "The whole Cheer Squad is here. One last push and the Circuit is fixed!"],
		],
	},
}


## The chapter for zone `z`, with its number, zone name and boss filled in.
static func chapter(z: int) -> Dictionary:
	var zone := Zones.zone(z)
	var c: Dictionary = CHAPTERS.get(zone.id, {}).duplicate()
	if c.is_empty():
		return c
	c.caption = "Chapter %d · %s" % [z + 1, zone.name]
	c.boss = zone.get("icon", "juggernaut")
	c.boss_name = zone.get("boss", "")
	return c


static func seen(p, key: String) -> bool:
	return p == null or key in p.story


## Records a chapter (zone id, or "prologue") as seen and saves.
static func mark_seen(p, key: String) -> void:
	if p == null or key in p.story:
		return
	p.story.append(key)
	p.changed.emit()


## Every chapter counts as seen, so nothing pops up (test URLs, demo profiles).
static func skip_all(p) -> void:
	p.story.assign(["prologue"] + CHAPTERS.keys())
