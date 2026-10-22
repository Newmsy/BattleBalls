## Foxfire, the Fox spirit (Legendary Skirmisher). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 84,
	"name": "Foxfire",
	"type": "Fox spirit",
	"rarity": "legendary",
	"rarity_power": 0.944, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Skirmisher",
	"status": "live",
	"color": "ffb4a2",
	"vibe": "A mischievous fox spirit who loves a good trick.",
	"description": "Fox spirit. Every 6s it splits off 2 fox-fire illusions, and an illusion that's touched bursts into flame for 8 and a burn.",
	"stats": {"hp": 104.0, "radius": 64.0, "speed": 400.0, "contact_damage": 13.0},
	"ability": [{"on": "every", "secs": 6.0, "do": "illusions"}, {"on": "always", "do": "illusion_tick"}],
	"params": {
		"illusion_count": 2,
		"illusion_life": 4.0,
		"illusion_size": 0.8, ## Of its radius.
		"illusion_damage": 8.0,
		"illusion_radius": 100.0,
		"illusion_burn_damage": 2.0, ## A second, for 2s.
		"illusion_trail_damage": 0.0, ## Flame trail damage a second.
		"illusion_swap": 0, ## 1: Foxfire blinks to a bursting illusion.
	},
	"tiers": [
		{"text": "Every 6s splits off 2 illusions that burst for 8", "now": "Every 6s splits off {illusion_count} illusions that burst for {illusion_damage}"},
		{"text": "Burst 8 → 10", "illusion_damage": 10.0},
		{"text": "+ Illusions leave flame trails (4/s)", "now": "Every 6s {illusion_count} trailing illusions that burst for {illusion_damage}", "illusion_trail_damage": 4.0},
		{"text": "Illusions 2 → 3", "illusion_count": 3},
		{"text": "+ A touched illusion swaps with Foxfire", "now": "Every 6s {illusion_count} trailing illusions burst for {illusion_damage} + swap", "illusion_swap": 1},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .13, "p": .1, "lid": .3, "mouth": "smirk"}, "back": ["ears", "foxtail"], "front": ["mask"]},
	"sound": {"ouch": "ouch_vampire", "pitch": 1.2},
}
