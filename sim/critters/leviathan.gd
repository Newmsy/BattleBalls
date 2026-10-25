## Leviathan, the Sea serpent (Legendary Bruiser). One file is the whole critter:
## see "Adding a critter" in README.md for what each key does.
extends RefCounted

const CRITTER := {
	"no": 74,
	"name": "Leviathan",
	"type": "Sea serpent",
	"rarity": "legendary",
	"rarity_power": 0.971, ## Per rarity step: its kit gains more than most from rarity (tools/rarity_critters.gd).
	"tier_power": [0.93, 0.97, 1.00, 0.98, 0.97], ## Power per tier vs its own rarity (tools/round_robin.gd --same).
	"role": "Bruiser",
	"status": "live",
	"color": "0f7173",
	"vibe": "A grand old sea serpent who rules the deep and knows it.",
	"description": "Sea serpent. Its {tail_count} glowing tail segments sting foes that touch them ({tail_damage} dmg) and coil the first one (stun {coil_secs}s, {coil_damage} dmg, every {coil_cooldown}s at most); every {dive_every}s it dives and bursts up under the foe in a huge wave ({wave_damage} dmg).",
	"stats": {"hp": 105.0, "radius": 64.0, "speed": 400.0, "contact_damage": 14.0},
	"ability": [{"on": "always", "do": "tail"}, {"on": "always", "do": "dive_tick"}, {"on": "every", "secs": "dive_every", "do": "dive"}, {"on": "guard", "do": "dive_guard"}],
	"params": {
		"tail_count": 3,
		"tail_size": 22.0,
		"tail_damage": 3.0,
		"tail_cooldown": 0.6,
		"tail_slow": 0.0, ## T3: segments slow foes they touch.
		"dive_every": 7.0,
		"coil_damage": 6.0, ## A foe its tail touches gets coiled: this much...
		"coil_secs": 0.5, ## ...held this long...
		"coil_cooldown": 5.0, ## ...at most this often.
		"dive_secs": 1.2,
		"dive_lock": 0.5, ## The splash point stops following the foe this long before it erupts.
		"dive_guard": 0.4, ## Damage taken while diving.
		"wave_radius": 220.0,
		"wave_damage": 8.0,
		"pool_radius": 150.0, ## T5 whirlpool.
		"pool_life": 3.0,
		"pool_dps": 0.0,
		"pool_slow": 0.3,
	},
	"tiers": [
		{"text": "Tail stings 3 and coils (6 dmg); every 7s a wave for 8", "card": "Its glowing tail stings and coils foes, and it dives to burst up under the foe in a huge wave.", "now": "Tail stings {tail_damage} and coils ({coil_damage} dmg); every {dive_every}s a wave for {wave_damage}"},
		{"text": "Wave {^wave_damage} → {wave_damage}", "wave_damage": 10.0},
		{"text": "Segments 3 → 4 + slow 20%", "card": "Its long tail stings, slows and coils foes, and it dives to burst up under the foe in a huge wave.", "now": "Slowing tail coils ({coil_damage} dmg); every {dive_every}s a wave for {wave_damage}", "tail_count": 4, "tail_slow": 0.2},
		{"text": "Wave every 7 → 6s", "dive_every": 6.0},
		{"text": "+ The eruption leaves a whirlpool ({pool_dps}/sec)", "card": "Its tail stings, slows and coils foes. It dives to erupt under the foe in a wave and a whirlpool.", "now": "Slowing tail coils; every {dive_every}s wave {wave_damage} + whirlpool", "pool_dps": 4.0},
	],
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "lid": .43, "mouth": "none"}, "back": ["segments", "frill"], "front": ["gills"]},
	"sound": {"ouch": "ouch_sea", "pitch": 0.7},
}
