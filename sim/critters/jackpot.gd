## Jackpot, the Slot machine (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 80,
	"name": "Jackpot",
	"type": "Slot machine",
	"rarity": "legendary",
	"role": "Zoner",
	"status": "live",
	"color": "e0115f",
	"vibe": "A flashy arcade slot machine who's sure the next spin is the big one.",
	"description": "Slot machine. Every 6 seconds it spins its reels and fires a seeded prize: a ring of mines, a cross of beams or a burst of coins.",
	"stats": {"hp": 113.0, "radius": 64.0, "speed": 400.0, "contact_damage": 15.0},
	"ability": [{"on": "every", "secs": "spin_every", "do": "spin"}, {"on": "always", "do": "spin_tick"}],
	"params": {
		"spin_every": 6.0,
		"spin_prizes": 3, ## Mines, laser cross, coins (+ shield at 4).
		"spin_delay": 0.5, ## Seconds from the spin to the payout.
		"spin_jackpot_every": 0, ## Every Nth spin pays out every prize, when above 0.
		"prize_mult": 1.0,
		"prize_mine_damage": 10.0,
		"prize_mine_radius": 70.0,
		"prize_beam_damage": 12.0, ## A second, per beam.
		"prize_coin_count": 8,
		"prize_coin_damage": 5.0,
		"prize_coin_reach": 300.0,
		"prize_shield": 20.0,
		"beam_max": 6,
	},
	"tiers": [
		{"text": "Every 6s spins for one of 3 prizes"},
		{"text": "Prizes hit 20% harder", "prize_mult": 1.2},
		{"text": "A fourth prize: a 20 shield", "spin_prizes": 4},
		{"text": "Spins every 5s", "spin_every": 5.0},
		{"text": "Every 4th spin pays out every prize", "spin_jackpot_every": 4},
	],
	"art": {"eyes": {"none": true, "mouth": "grin"}, "back": ["lever"], "front": ["reels"]},
	"sound": {"ouch": "ouch_magnet", "pitch": 1.1},
}
