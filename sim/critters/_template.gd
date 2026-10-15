## TEMPLATE (files starting with "_" are skipped). Copy to sim/critters/<id>.gd,
## where <id> is the lowercase snake_case id used in saves, links and tests.
## One file is the whole critter: the sim, art, menus, summons, sound and the
## balance sim all read it. See "Adding a critter" in README.md.
extends RefCounted

const CRITTER := {
	"no": 999, ## Critterpedia number: unique, never reused, sets list order.
	"name": "Name", ## What players see.
	"type": "Type", ## One word for what it is (Vampire, Laser).
	"rarity": "common", ## common, uncommon, rare, epic or legendary.
	"role": "Bruiser", ## Bruiser, Zoner, Skirmisher or Disruptor.
	"status": "planned", ## planned (collection only) until its ability is built, then live.
	"color": "8a94a8", ## Body colour, hex.
	"vibe": "One-line personality.",
	"description": "Type. The ability in one sentence: a trigger and an effect.",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	## Trigger + effect pairs from sim/abilities.gd (TRIGGERS and EFFECTS).
	## "every" takes "secs"; "hp_below" takes "hp" (0-1).
	"ability": [{"on": "hit", "do": "heal"}],
	## Every param the effects need (EFFECTS lists them), at T1.
	"params": {"heal_ratio": 0.3},
	## T1 to T5: the text players see, plus any params that change at that tier
	## (they carry over to higher tiers).
	"tiers": [
		{"text": "Heal 30% of damage dealt"},
		{"text": "Heal 35%", "heal_ratio": 0.35},
		{"text": "Heal 40%", "heal_ratio": 0.4},
		{"text": "Heal 45%", "heal_ratio": 0.45},
		{"text": "Heal 50%", "heal_ratio": 0.5},
	],
	## Look, from the kit in game/ui/critter_art.gd: body (BODIES), eyes (keys
	## listed on _face), and features (FEATURES) drawn behind or in front.
	## Optional: scale (draw size), badge_top (HP badge height over the ball).
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": [], "front": []},
	## ouch: a sound from game/audio/sfx.gd RULES; pitch makes it this critter's voice.
	"sound": {"ouch": "ouch_vampire", "pitch": 1.1},
}
