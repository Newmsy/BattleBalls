## UI catalogue of the Neon Critters (design/critters.md): names, rarity,
## colours and the per-tier ability text shown on the detail and fuse screens.
## The sim only knows the critters in sim/ball_defs.gd; this file is display data.
extends RefCounted

const RARITIES := ["common", "rare", "epic", "legendary"]
const RARITY_NAMES := {"common": "Common", "rare": "Rare", "epic": "Epic", "legendary": "Legendary"}
const RARITY_COLORS := {"common": Color("c9d3e0"), "rare": Color("3d9bff"), "epic": Color("b366ff"), "legendary": Color("ffc23d")}
## Base Power Rating per rarity step (power-progression.md section 5).
const RARITY_BASE := {"common": 100.0, "rare": 108.0, "epic": 115.0, "legendary": 122.0}
const MAX_TIER := 5

const CRITTERS := [
	{"id": "vampire", "name": "Count Nibbles", "type": "Vampire", "rarity": "common", "role": "Bruiser", "color": Color("c2264a"),
		"vibe": "A smug little aristocrat who thinks every fight is dinner.",
		"ladder": ["Heal 50% of damage dealt", "Heal 60%", "Heal 70%", "Heal 80%", "Overheal becomes a shield"]},
	{"id": "juggernaut", "name": "Boulder", "type": "Juggernaut", "rarity": "common", "role": "Bruiser", "color": Color("7d8799"),
		"vibe": "Big, slow and completely unbothered.",
		"ladder": ["Takes 20% less damage", "25% less", "30% less, hits stun briefly", "35% less", "Shockwave on every hit"]},
	{"id": "spiker", "name": "Prickles", "type": "Spiker", "rarity": "common", "role": "Bruiser", "color": Color("5cc95a"),
		"vibe": "Overexcited cactus pup that gets pointier the more it fights.",
		"ladder": ["+1 contact damage per hit landed, max 5", "Max 6", "Max 8", "Max 10", "Spikes fire off at full stacks"]},
	{"id": "speedster", "name": "Zip", "type": "Speedster", "rarity": "common", "role": "Skirmisher", "color": Color("ffb020"),
		"vibe": "A cocky sprinter who never stops moving.",
		"ladder": ["+4% speed per wall bounce, max 5", "Max 6", "+5% per bounce", "Max 8", "Leaves a damaging afterimage"]},
	{"id": "laser", "name": "Optic", "type": "Laser", "rarity": "rare", "role": "Zoner", "color": Color("27c8ff"),
		"vibe": "A calm, calculating little robot with one big eye.",
		"ladder": ["Beams last 2s", "Beams last 2.5s", "3s, thicker beams", "Beams last 3.5s", "Beams also link the 2 previous bounces"]},
	{"id": "bomber", "name": "Fuse", "type": "Bomber", "rarity": "rare", "role": "Zoner", "color": Color("2b3a67"),
		"vibe": "Chaotic gremlin who laughs at its own explosions.",
		"ladder": ["1 mine per bounce, max 3", "Max 4 mines", "Bigger blast", "Max 6 mines", "Mines chain-detonate"]},
	{"id": "frost", "name": "Chill", "type": "Frost", "rarity": "rare", "role": "Zoner", "color": Color("bfe9ff"),
		"vibe": "Sleepy and unhurried; everything near it slows down to its pace.",
		"ladder": ["Icy trail slows foes 20%", "Slows 25%", "Trail lasts longer", "Slows 30%", "Frozen foes shatter for bonus damage"]},
	{"id": "thorns", "name": "Bramble", "type": "Thorns", "rarity": "rare", "role": "Disruptor", "color": Color("4f7a3a"),
		"vibe": "Grumpy hedge that just wants to be left alone.",
		"ladder": ["Reflect 20% of damage taken", "Reflect 25%", "30%, plus a thorn burst", "Reflect 35%", "Thorn burst on every hit taken"]},
	{"id": "splitter", "name": "Dupe", "type": "Splitter", "rarity": "epic", "role": "Skirmisher", "color": Color("ff6fae"),
		"vibe": "Two personalities sharing one jelly body, never quite agreeing.",
		"ladder": ["Splits once at 50% HP", "Children hit harder", "Splits at 50% and 25%", "Children hit harder still", "Children also split"]},
	{"id": "ghost", "name": "Wisp", "type": "Ghost", "rarity": "epic", "role": "Skirmisher", "color": Color("e3d6ff"),
		"vibe": "Shy and spooky, giggles when you miss it.",
		"ladder": ["Phases out 1s every 6s", "Every 5s", "Phases for 1.5s", "Every 4s", "Counters the hits it dodges"]},
	{"id": "gravity", "name": "Orbit", "type": "Gravity", "rarity": "epic", "role": "Disruptor", "color": Color("5b4bd6"),
		"vibe": "Serene little planet; everything comes to it eventually.",
		"ladder": ["Weak pull field", "Stronger pull", "Pull also slows", "Bigger field", "Pull pulse slams foes into walls"]},
	{"id": "mirror", "name": "Echo", "type": "Mirror", "rarity": "epic", "role": "Disruptor", "color": Color("cfd8e6"),
		"vibe": "A copycat show-off that mimics whoever just hit it.",
		"ladder": ["Copies the last ability that hit it", "Copy lasts longer", "Copies at full strength", "Keeps 2 copies", "Reflects the copy back"]},
	{"id": "magnet", "name": "Flux", "type": "Magnet", "rarity": "epic", "role": "Disruptor", "color": Color("ff3b5c"), "pole_color": Color("2f7bff"),
		"vibe": "A buzzing little horseshoe that can't decide if it loves you or hates you.",
		"ladder": ["Field flips every 3s; first Pull hit snaps for 2.5x", "Stronger field", "Snaps for 3x", "Flips every 2.5s", "Every flip fires a pulse ring"]},
	{"id": "blackhole", "name": "Void", "type": "Black Hole", "rarity": "legendary", "role": "Legendary", "color": Color("0d0b17"),
		"vibe": "Ancient, silent and a little terrifying.",
		"ladder": ["Collapses every 10s", "Every 9s", "Stronger pull", "Every 8s", "Leaves a mini black hole"]},
	{"id": "phoenix", "name": "Ember", "type": "Phoenix", "rarity": "legendary", "role": "Legendary", "color": Color("ff6a2a"),
		"vibe": "Proud and fiery; refuses to stay down.",
		"ladder": ["Revives once at 30% HP", "Revives at 40%", "Revive burns nearby foes", "Revives at 50%", "Revives twice"]},
	{"id": "prism", "name": "Spectra", "type": "Prism", "rarity": "legendary", "role": "Legendary", "color": Color("9ad8ff"),
		"vibe": "Dazzling and a bit vain about it.",
		"ladder": ["Splits projectiles into 2 beams", "3 beams", "Beams home in", "4 beams", "Reflects lasers back"]},
]


static func ids() -> Array:
	return CRITTERS.map(func(c): return c.id)


static func get_critter(id: String) -> Dictionary:
	for c in CRITTERS:
		if c.id == id:
			return c
	assert(false, "Unknown critter: %s" % id)
	return {}


static func level_cap(tier: int) -> int:
	return tier * 10


## Power Rating: rarity base, +25% per tier, +2.5% per level, +4% per gear piece.
static func power(id: String, tier: int, level: int, gear_count := 0) -> int:
	var p: float = RARITY_BASE[get_critter(id).rarity] * pow(1.25, tier - 1) * (1.0 + 0.025 * (level - 1))
	p *= 1.0 + 0.04 * gear_count
	return roundi(p * 10.0)
