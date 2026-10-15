## Puppeteer, the Puppeteer (Epic Disruptor). Planned: see design/roster.md.
extends RefCounted

const CRITTER := {
	"no": 73,
	"name": "Puppeteer",
	"type": "Puppeteer",
	"rarity": "epic",
	"role": "Disruptor",
	"status": "planned",
	"color": "6d2e46",
	"vibe": "A theatrical little puppet-master who wants you in its show.",
	"description": "Puppeteer. When it hits, it ties a string to the foe and drags it along its path for a second.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	"ability": [],
	"params": {},
	"tiers": [
		{"text": "Hits tie a string and drag the foe 1s"},
		{"text": "Strings every 4s"},
		{"text": "A dragged foe hitting a wall takes +6"},
		{"text": "Drags for 1.3s"},
		{"text": "A snapping string leaves the foe dizzy"},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "grin"}, "back": ["controlbar", "tophat"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.0},
}
