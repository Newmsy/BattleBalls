## A filled-in sample profile for building and testing screens. The real save
## and every rule live in meta/profile.gd; this only adds sample().
extends "res://meta/profile.gd"


static func sample():
	var p = load("res://game/ui/ui_profile.gd").new()
	p.account_level = 7
	p.energy = 42
	p.coins = 2480
	p.orbs = 14
	p.legendary_pity = 112
	p.seen = {}
	for s in [["vampire", 2, 1, 14], ["vampire", 1, 3, 6], ["juggernaut", 1, 2, 7], ["spiker", 2, 1, 12],
			["spiker", 1, 1, 3], ["speedster", 1, 3, 9], ["bomber", 1, 1, 3],
			["thorns", 1, 1, 2], ["splitter", 1, 1, 5]]:
		p.stacks.append({"id": s[0], "tier": s[1], "count": s[2], "level": s[3]})
		p.seen[s[0]] = true
	p.gear.assign([
		{"uid": 1, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "text": "Take 2 less damage per hit", "on": "vampire"},
		{"uid": 2, "name": "Leech Core", "slot": "Core", "rarity": "rare", "text": "Heal 5% of damage dealt", "on": "vampire"},
		{"uid": 3, "name": "Rubber Shell", "slot": "Shell", "rarity": "rare", "text": "+8% bounce speed", "on": "speedster"},
		{"uid": 4, "name": "Overclock Core", "slot": "Core", "rarity": "epic", "text": "Ability triggers 15% sooner", "on": ""},
		{"uid": 5, "name": "Iron Shell", "slot": "Shell", "rarity": "common", "text": "Take 2 less damage per hit", "on": ""},
		{"uid": 6, "name": "Spiked Shell", "slot": "Shell", "rarity": "rare", "text": "Take 1 less damage; attackers take 2", "on": ""},
		{"uid": 7, "name": "Echo Core", "slot": "Core", "rarity": "legendary", "text": "8% chance the ability fires twice", "on": ""},
	])
	p.items.assign([
		{"name": "Energy Pack", "count": 3, "text": "+30 energy. Can go over the max.", "color": Color("5ce1ff")},
		{"name": "XP Chip", "count": 12, "text": "+200 XP to one critter.", "color": Color("45f5a6")},
		{"name": "Summon Orb", "count": 14, "text": "Spend at the Summon Portal. Earned by playing, never sold.", "color": Color("c86bff")},
	])
	return p

