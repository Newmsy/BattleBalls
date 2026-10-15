## A filled-in sample profile for building and testing screens. The real save
## and every rule live in meta/profile.gd; this only adds sample()
## and starter() (onboarding).
extends "res://meta/profile.gd"


static func sample():
	var p = load("res://game/ui/ui_profile.gd").new()
	p.account_level = 7
	p.energy = 42
	p.coins = 2480
	p.orbs = 14
	p.legendary_pity = 37
	p.seen = {}
	for s in [["vampire", 2, 1, 14], ["vampire", 1, 3, 6], ["juggernaut", 1, 2, 7], ["spiker", 2, 1, 12],
			["spiker", 1, 1, 3], ["speedster", 1, 3, 9], ["bomber", 1, 1, 3],
			["thorns", 1, 1, 2], ["splitter", 1, 1, 5]]:
		p.stacks.append({"id": s[0], "tier": s[1], "count": s[2], "level": s[3]})
		p.seen[s[0]] = true
	p.gear.assign([
		{"uid": 1, "type": "iron_shell", "tier": 2, "on": "vampire"},
		{"uid": 2, "type": "spike_core", "tier": 3, "on": "vampire"},
		{"uid": 3, "type": "bubble_shell", "tier": 1, "on": "speedster"},
		{"uid": 4, "type": "echo_core", "tier": 4, "on": ""},
		{"uid": 5, "type": "bubble_shell", "tier": 1, "on": ""},
		{"uid": 6, "type": "bubble_shell", "tier": 1, "on": ""},
		{"uid": 7, "type": "jet_charm", "tier": 2, "on": ""},
		{"uid": 8, "type": "overclock_charm", "tier": 1, "on": ""},
	].map(func(g): return gear_piece(g)))
	p.items.assign([
		{"name": "Energy Pack", "count": 3, "text": "+30 energy. Can go over the max.", "color": Color("5ce1ff")},
		{"name": "XP Chip", "count": 12, "text": "+200 XP to one critter.", "color": Color("45f5a6")},
		{"name": "Summon Orb", "count": 14, "text": "Spend at the Summon Portal. Earned by playing, never sold.", "color": Color("c86bff")},
	])
	return p



## A brand-new player straight out of onboarding: one T1 copy of the starter
## (the tutorial fights drop two more), a free summon and a few orbs.
static func starter(id: String):
	var p = load("res://game/ui/ui_profile.gd").new()
	p.setup_new_game(int(Time.get_unix_time_from_system()), id)
	return p
