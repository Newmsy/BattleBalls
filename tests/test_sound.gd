extends "res://tests/test_case.gd"

const MatchSim := preload("res://sim/match_sim.gd")
const Sfx := preload("res://game/audio/sfx.gd")


func _sfx() -> Sfx:
	var sfx := Sfx.new()
	runner.root.add_child(sfx)
	return sfx


func test_every_sound_and_music_track_loads() -> void:
	var sfx := _sfx()
	for name in sfx.sound_names():
		check(not sfx._variants[name].is_empty(), "no audio file for sound '%s'" % name)
	for track in Sfx.MUSIC:
		var path: String = Sfx.AUDIO_DIR + Sfx.MUSIC[track][0] + ".ogg"
		check(load(path) is AudioStreamOggVorbis, "music track missing: %s" % path)
	sfx.free()


## Sound only reads the sim: a fight with sound must end exactly like one without.
func test_sound_does_not_change_the_fight() -> void:
	var cfg := {"seed": 11, "p1": "vampire", "p2": "laser", "angles": [null, null]}
	var quiet := MatchSim.new(cfg)
	quiet.run_to_end()
	var sfx := _sfx()
	var loud := MatchSim.new(cfg)
	sfx.on_fight_start(loud)
	var events_seen := 0
	while not loud.finished:
		loud.step()
		events_seen += loud.events.size()
		sfx.consume_events(loud.events, loud)
		sfx._process(MatchSim.DT)
	sfx.on_result(loud.winner)
	check(events_seen > 0, "fight produced no events to play")
	check_eq(loud.state_hash(), quiet.state_hash(), "state hash with sound")
	sfx.free()


func test_caps_limit_simultaneous_copies_of_a_sound() -> void:
	var sfx := _sfx()
	sfx.mode = "all" ## Settings saved by other runs must not mute the test.
	for i in 10:
		sfx._clock += Sfx.RULES["hit"][1] + 0.001 ## Past the min gap, so only the cap can stop it.
		sfx.play("hit")
	var playing := sfx.playing_count("hit")
	check_eq(playing, Sfx.RULES["hit"][0], "copies of hit playing")
	sfx.free()


## Godot 4.3's web build drops the route to the speakers when buses are added
## at runtime, so every sound must stay on the Master bus.
func test_sounds_stay_on_the_master_bus() -> void:
	var buses_before := AudioServer.bus_count
	var sfx := _sfx()
	check_eq(AudioServer.bus_count, buses_before, "bus count after creating Sfx")
	for p in sfx._players:
		check_eq(p.bus, &"Master", "sound player bus")
	check_eq(sfx._music.bus, &"Master", "music player bus")
	sfx.free()


## Every critter cue names a real sound, and every family member speaks with
## its family's voice.
func test_critter_cues_and_family_voices() -> void:
	const CritterDb := preload("res://sim/critter_db.gd")
	const Families := preload("res://sim/families.gd")
	for id in Sfx.CRITTER_CUES:
		check(CritterDb.get_critter(id).size() > 0, "cues for unknown critter %s" % id)
		for key in Sfx.CRITTER_CUES[id]:
			for cue in Sfx.CRITTER_CUES[id][key]:
				check(Sfx.RULES.has(cue[0]), "%s %s: unknown sound %s" % [id, key, cue[0]])
	for fam in Families.MEMBERS:
		check(Sfx.RULES.has("knock_" + fam), "no knock for family %s" % fam)
		for id in Families.MEMBERS[fam]:
			var ouch: String = CritterDb.sim_def(id).ouch
			check(ouch == "" or ouch == "ouch_" + fam, "%s speaks with %s, not its family's voice" % [id, ouch])


## Fuse's mines plunk down as they land: zone cues fire once per new zone.
func test_zone_cues_play_once_per_zone() -> void:
	var sfx := _sfx()
	sfx.mode = "all"
	sfx.record = []
	var sim := MatchSim.new({"seed": 3, "p1": "bomber", "p2": "juggernaut", "angles": [null, null]})
	sfx.on_fight_start(sim)
	var mines := {}
	while not sim.finished and sim.time() < 20.0:
		sim.step()
		for z in sim.zones:
			if z.kind == "mine":
				mines[z.get_instance_id()] = true
		sfx.consume_events(sim.events, sim)
		sfx._process(MatchSim.DT)
	var drops: int = sfx.record.filter(func(c): return c[0] == "mine_drop").size()
	check(mines.size() > 0, "Fuse dropped no mines")
	check(drops > 0 and drops <= mines.size(), "mine drops heard %d for %d mines" % [drops, mines.size()])
	sfx.free()
