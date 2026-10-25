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
	"description": "Type. The whole ability in one sentence, with the side effects and durations T1 leaves out. Damage-type numbers as {param} (see tiers).",
	"stats": {"hp": 100.0, "radius": 64.0, "speed": 400.0, "contact_damage": 10.0},
	## Trigger + effect pairs from sim/abilities.gd (TRIGGERS and EFFECTS).
	## "every" takes "secs"; "hp_below" takes "hp" (0-1).
	"ability": [{"on": "hit", "do": "heal"}],
	## Every param the effects need (EFFECTS lists them), at T1.
	"params": {"heal_ratio": 0.3},
	## T1 to T5: the text players see, plus any params that change at that tier
	## (they carry over to higher tiers). T1 "text" is the ability (<= 60 chars;
	## side effects and durations go in description). T2-T5 "text" says what
	## the tier adds (<= 50): "Label old → new" or "+ New thing". "now" is the
	## whole ability from that tier up in one line (<= 60); the T1 "now" must
	## fill in to the T1 text with the params as written. Give a tier a "now"
	## when it adds something the line should show. Optional T5 "special": the
	## signature's name. "card" (T1 required, <= 105) is the whole ability from
	## that tier up in plain words with no numbers, for fight cards; give a tier
	## a "card" when the ability changes in kind (a new move or effect), not
	## for bigger numbers.
	## Numbers: write any param the sim grows (CritterDb.sim_def: *_damage,
	## *_dps, *_burn, *_shield, *_hps, hit multipliers, *_radius) as a
	## placeholder, never a literal, because screens show it as it fights at
	## that tier, rarity and level: {key} (its value), {key%} (0.2 → 20),
	## {^key} / {^key%} (the tier before, for "old → new") and {+key} (growth
	## since the tier before, in %, for "size +{+mine_radius}%").
	## Units, the same on every screen: damage "12" or "(12 dmg)", rates
	## "4/sec" and heals "3 HP/sec" (never "/s": players read it as "per
	## stack"), durations "3s", cooldowns "every 4s", "every 3rd hit", "x2",
	## "slow 30%", "+20% dmg taken", "per hit" / "each" for stacks.
	"tiers": [
		{"text": "Heals 30% of dmg dealt", "card": "Heals for part of the damage it deals.", "now": "Heals {heal_ratio%}% of dmg dealt"},
		{"text": "Heal {^heal_ratio%} → {heal_ratio%}%", "heal_ratio": 0.35},
		{"text": "Heal {^heal_ratio%} → {heal_ratio%}%", "heal_ratio": 0.4},
		{"text": "Heal {^heal_ratio%} → {heal_ratio%}%", "heal_ratio": 0.45},
		{"text": "Heal {^heal_ratio%} → {heal_ratio%}%", "heal_ratio": 0.5},
	],
	## Look, from the kit in game/ui/critter_art.gd: body (BODIES), eyes (keys
	## listed on _face), and features (FEATURES) drawn behind or in front.
	## Optional: scale (draw size), badge_top (HP badge height over the ball).
	"art": {"eyes": {"sep": .3, "w": .2, "h": .24, "p": .1, "mouth": "smile"}, "back": [], "front": []},
	## ouch: a sound from game/audio/sfx.gd RULES, normally its family's voice
	## (ouch_nature, ouch_sea...); pitch makes it this critter's own voice.
	"sound": {"ouch": "ouch_nature", "pitch": 1.1},
}
