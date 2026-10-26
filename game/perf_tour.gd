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


## Dev: ?perfidle=1 (or =play,summon) opens each home screen, lets it settle,
## then sits idle for `secs` and logs what an untouched screen costs:
## "PERF_IDLE <name> drawn <frames/s> process <ms/s>". Battery on an idle
## menu is mostly frames drawn and script time per second.
## smoke/perf_idle.mjs adds WebGL calls and browser CPU around the same marks.
static func idle(shell, only: Array = [], secs := 4.0) -> void:
	var tree: SceneTree = shell.get_tree()
	OS.low_processor_usage_mode = true # Native runs too: only draw on change, like the web build.
	for i in 30:
		await tree.process_frame
	var names: Array = ["home"]
	for entry in TOUR:
		if entry[0] not in names:
			names.append(entry[0])
	for name in names:
		if not only.is_empty() and name not in only:
			continue
		if name != "home":
			var params := {}
			for entry in TOUR:
				if entry[0] == name:
					params = entry[1].duplicate()
					break
			if name in ["arena", "boosts", "bazaar", "defence"]:
				params.store = preload("res://game/pvp/arena_store.gd").sample()
			shell.go(name, params)
		await tree.create_timer(1.5).timeout
		var drawn := Engine.get_frames_drawn()
		var frames := 0
		var us := 0.0
		print("PERF_IDLE_BEGIN ", name)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < secs * 1000.0:
			await tree.process_frame
			frames += 1
			us += Performance.get_monitor(Performance.TIME_PROCESS) * 1e6
		var el := (Time.get_ticks_msec() - t0) / 1000.0
		var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		print("PERF_IDLE %s drawn %.1f ticks %.1f process %.1f draws %d" % [name, (Engine.get_frames_drawn() - drawn) / el, frames / el, us / 1000.0 / el, draws])
		if name != "home":
			shell.back()
	print("PERF_IDLE_DONE")


## Dev: ?perfblame=home (native: godot -- demo=1 perfblame=home) opens a
## screen and finds which nodes cost the most draw calls per frame, by hiding
## each one for a frame. "PERF_BLAME <calls> <path>".
static func blame(shell, name: String) -> void:
	var tree: SceneTree = shell.get_tree()
	for i in 30:
		await tree.process_frame
	if name != "home":
		var params := {}
		if name in ["arena", "boosts", "bazaar", "defence"]:
			params.store = preload("res://game/pvp/arena_store.gd").sample()
		shell.go(name, params)
	await tree.create_timer(1.0).timeout
	var total := await _draws(tree)
	var seen := []
	for i in 10:
		seen.append(await _draws(tree))
	print("PERF_BLAME_TOTAL %d %s %s" % [total, name, seen])
	await _blame(tree, tree.root, total, maxi(6, total / 60))
	print("PERF_BLAME_DONE")
	if not OS.has_feature("web"):
		tree.quit()


static func _draws(tree: SceneTree) -> int:
	for i in 2:
		await RenderingServer.frame_post_draw
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)


static func _blame(tree: SceneTree, node: Node, total: int, floor_calls: int) -> void:
	for c in node.get_children():
		if not (c is CanvasItem) or not c.visible:
			if not (c is CanvasItem):
				await _blame(tree, c, total, floor_calls)
			continue
		var keep: Color = c.modulate # Fade instead of hide, so layout and culling stay put.
		c.modulate.a = 0.0
		var without := await _draws(tree)
		c.modulate = keep
		var cost := total - without
		if node == tree.root:
			print("PERF_BLAME_TOP %d %s" % [cost, c.name])
		if cost < floor_calls and not c.find_children("*", "CanvasLayer", true, false).is_empty():
			await _blame(tree, c, total, floor_calls)
		elif cost >= floor_calls:
			print("PERF_BLAME %d %s (%s)" % [cost, c.get_path(), (c.get_script().resource_path.get_file() if c.get_script() else c.get_class()) + (" " + JSON.stringify([c.text, c.material, c.clip_contents, c.get_theme_font_size("font_size"), c.label_settings]) if c is Label else "")])
			await _blame(tree, c, total, floor_calls)
