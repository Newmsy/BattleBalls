## Ivy, the Vine spirit (Legendary Disruptor). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 87,
	"name": "Ivy",
	"type": "Vine spirit",
	"rarity": "legendary",
	"rarity_power": 0.962, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Disruptor",
	"status": "live",
	"color": "0b8a5f",
	"vibe": "A graceful vine spirit who decides where everyone stands.",
	"description": "Vine spirit. Every 6s it raises a vine pillar beside the foe and lashes the foe to it for 1s, then the vine snaps in a burst for 6.",
	"stats": {"hp": 115.0, "radius": 64.0, "speed": 400.0, "contact_damage": 16.0},
	"ability": [{"on": "every", "secs": "vine_every", "do": "vine"}, {"on": "always", "do": "vine_tick"}],
	"params": {
		"vine_every": 6.0,
		"vine_offset": 120.0, ## Vine pillar's distance from the foe.
		"vine_radius": 30.0,
		"vine_life": 3.0,
		"vine_lash": 1.0, ## Seconds the foe is lashed before the vine snaps.
		"vine_slack": 120.0, ## Give in the vine beyond where the foe stood.
		"vine_pairs": 1, ## 2: two pillars on opposite sides.
		"vine_damage": 6.0,
		"vine_burst_radius": 100.0,
		"vine_thorn_damage": 0.0, ## Thorn patch damage a second after the snap.
		"overgrow_max": 3, ## Snapped vines stay as vine walls (this many at most)...
		"overgrow_damage": 3.0, ## ...until a foe bounces off one for this.
	},
	"tiers": [
		{"text": "Every 6s lashes foe to a vine 1s, snap 6; vines stay", "now": "Every {vine_every}s lashes foe to a vine {vine_lash}s, snap {vine_damage}; vines stay"},
		{"text": "Snap 6 → 8", "vine_damage": 8.0},
		{"text": "+ The snap leaves thorns (4/s)", "now": "Every {vine_every}s lashes foe to a vine {vine_lash}s, snap {vine_damage} + thorns", "vine_thorn_damage": 4.0},
		{"text": "Lash every 6 → 5s", "vine_every": 5.0},
		{"text": "+ Two pillars at once", "now": "Every {vine_every}s lashes foe to 2 vines {vine_lash}s, snap {vine_damage} + thorns", "vine_pairs": 2},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "smile"}, "back": ["flowercrown"], "front": ["vinewrap"]},
	"sound": {"ouch": "ouch_nature", "pitch": 1.1},
}
