## Jackpot, the Slot machine (Legendary Zoner). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 80,
	"name": "Jackpot",
	"type": "Slot machine",
	"rarity": "legendary",
	"rarity_power": 0.969, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"role": "Zoner",
	"status": "live",
	"color": "e0115f",
	"vibe": "A flashy arcade slot machine who's sure the next spin is the big one.",
	"description": "Slot machine. Every 6s it spins a prize: a ring of mines where the foe is heading, a cross of beams through it or a spray of coins at it.",
	"stats": {"hp": 106.0, "radius": 64.0, "speed": 440.0, "contact_damage": 15.5},
	"ability": [{"on": "every", "secs": "spin_every", "do": "spin"}, {"on": "always", "do": "spin_tick"}],
	"params": {
		"spin_every": 6.0,
		"spin_prizes": 3, ## Mines, laser cross, coins (+ shield at 4).
		"spin_delay": 0.5, ## Seconds from the spin to the payout.
		"spin_jackpot_every": 0, ## Every Nth spin pays out every prize, when above 0.
		"prize_mult": 1.0,
		"prize_mine_damage": 6.0,
		"prize_mine_radius": 70.0,
		"prize_beam_damage": 7.0, ## A second, per beam.
		"prize_coin_count": 5,
		"prize_coin_damage": 3.0,
		"prize_coin_reach": 350.0,
		"prize_coin_hits": 3, ## Coins from one spray that can hit the same foe.
		"prize_shield": 20.0,
		"beam_max": 6,
	},
	"tiers": [
		{"text": "Every 6s spins a prize: mines, beams or coins", "now": "Every {spin_every}s spins a prize: mines, beams or coins"},
		{"text": "Prize dmg +20%", "prize_mult": 1.2},
		{"text": "+ A 4th prize: a {prize_shield} shield", "now": "Every {spin_every}s spins a prize: mines, beams, coins or shield", "spin_prizes": 4},
		{"text": "Spin every 6 → 5s", "spin_every": 5.0},
		{"text": "+ Every 4th spin pays out every prize", "now": "Every {spin_every}s spins: mines, beams, coins or shield; 4th: all", "spin_jackpot_every": 4},
	],
	"art": {"eyes": {"none": true, "mouth": "grin"}, "back": ["lever"], "front": ["reels"]},
	"sound": {"ouch": "ouch_toybox", "pitch": 1.1},
	"chaos": {"rink": {"hp": 1.07}}, ## Quick and light: the cut corners of the rink catch it more.
}
