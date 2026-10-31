## Beans, the Jelly bean (Rare Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 98,
	"name": "Beans",
	"type": "Jelly bean",
	"rarity": "rare",
	"role": "Disruptor",
	"status": "live",
	"color": "ff6fae",
	"vibe": "A jelly bean that never stops offering you a flavour.",
	"description": "Jelly bean. Every wall bounce drops a jelly bean (up to {bean_max}). A foe that eats one gets its flavour: hot burns, sour makes it take {bean_sour%}% more for {bean_secs}s, fizzy bounces it away ({bean_fizz_damage} dmg). Beans eating its own heals {bean_heal}.",
	"tier_power": [1.00, 1.06, 1.12, 1.20, 1.30], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"stats": {"hp": 118.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "wall", "do": "bean_drop"}, {"on": "always", "do": "bean_tick"}],
	"params": {
		"bean_max": 3,
		"bean_life": 8.0,
		"bean_rainbow": 0, ## T5: every Nth bean has all three flavours.
		"bean_heal": 8.0, ## Beans eating its own bean.
		"bean_burn": 4.0, ## Hot: burn per second...
		"bean_secs": 3.0, ## ...and how long hot and sour last.
		"bean_sour": 0.2, ## Sour: takes this much more.
		"bean_fizz_damage": 6.0, ## Fizzy: a pop that bounces it away.
	},
	"tiers": [
		{"text": "Wall bounces drop flavour beans (x3)", "card": "Its wall bounces drop jelly beans; a foe that eats one gets a hot, sour or fizzy flavour.", "now": "Wall bounces drop flavour beans (x{bean_max})"},
		{"text": "Sour {^bean_sour%} → {bean_sour%}% more taken", "bean_sour": 0.25},
		{"text": "Up to 4 beans", "bean_max": 4},
		{"text": "Flavours last {^bean_secs} → {bean_secs}s", "bean_secs": 4.0},
		{"text": "+ Every 4th bean is a rainbow (all flavours)", "special": "Bean Boozled", "card": "Its wall bounces drop jelly beans; every few is a rainbow bean with every flavour at once.", "now": "Wall bounces drop beans (x{bean_max}); every 4th: all flavours", "bean_rainbow": 4},
	],
	"art": {"body": "bean", "eyes": {"sep": .3, "w": .19, "h": .23, "p": .1, "sparkle": true, "mouth": "smile"}, "back": ["beanbuddies"], "front": ["beanspecks"]},
	"sound": {"ouch": "ouch_sweet", "pitch": 1.3},
}
