## Dev: ?perftour=1 opens every home screen in turn and logs how long each
## takes, from shell.go() to the end of its first drawn frame:
## "PERF_SCREEN <name> build <ms> frame <ms>". Each screen opens twice (cold,
## then warm) so first-use costs (fonts, shaders, caches) show apart.
## Read the numbers with smoke/perf_screens.mjs.
extends RefCounted

const TOUR := [
	["play", {}], ["critters", {}], ["detail", {"id": "vampire"}], ["dex", {}],
	["dex_entry", {"id": "vampire"}], ["bag", {}], ["fuse", {}], ["summon", {}],
	["week", {}], ["arena", {}], ["boosts", {}], ["bazaar", {}], ["defence", {}],
	["spire", {}], ["bracket", {}], ["friends", {}], ["account", {}], ["shop", {}],
	["pass", {}], ["world", {}], ["campaign", {}], ["campaign", {"zone": 2}], ["campaign", {"zone": 3}], ["campaign", {"zone": 6}],
	["bosses", {}], ["factions", {}], ["faction", {"id": "spooky"}], ["vault", {}],
	["nest", {}], ["pinata", {}], ["totem", {}], ["wyrm", {}], ["glitch", {}],
]


static func run(shell, only: Array = []) -> void:
	var tree: SceneTree = shell.get_tree()
	for i in 10: # let boot settle
		await tree.process_frame
	for pass_name in ["cold", "warm"]:
		for entry in TOUR:
			if not only.is_empty() and entry[0] not in only:
				continue
			var params: Dictionary = entry[1].duplicate()
			if entry[0] in ["arena", "boosts", "bazaar", "defence"]:
				params.store = preload("res://game/pvp/arena_store.gd").sample()
			var t0 := Time.get_ticks_usec()
			shell.go(entry[0], params)
			var t1 := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			var t2 := Time.get_ticks_usec()
			var label: String = entry[0] + ("" if not params.has("zone") else str(params.zone))
			print("PERF_SCREEN %s %s build %.0f frame %.0f" % [pass_name, label, (t1 - t0) / 1000.0, (t2 - t0) / 1000.0])
			for k in 3:
				await tree.process_frame
			shell.back()
			await RenderingServer.frame_post_draw
	print("PERF_TOUR_DONE")
	if not OS.has_feature("web"):
		tree.quit()
