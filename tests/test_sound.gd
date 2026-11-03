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
	check_eq(sfx._music_out.bus, &"Master", "fading music player bus")
	sfx.free()


## One track per session: with no mode track, the menu loop on screens and
## the fight track in fights, and a result never switches the music (the win
## or loss is a jingle). A mode track (Spire) runs through aiming, fights,
## results and the next fight with no switch.
func test_music_flow() -> void:
	var sfx := _sfx()
	sfx.mode = "all"
	Sfx._audio_unlocked = true
	sfx.on_menu()
	check_eq(sfx._music_track, "menu", "first music is the menu loop")
	var sim := MatchSim.new({"seed": 3, "p1": "vampire", "p2": "laser", "angles": [null, null]})
	sfx.on_fight_start(sim)
	check_eq(sfx._music_track, "fight", "fight music")
	sfx.on_result(0)
	check_eq(sfx._music_track, "fight", "a win doesn't switch the music")
	sfx.on_menu()
	check_eq(sfx._music_track, "menu", "back to the menu loop on the screens")
	sfx.set_theme("spire")
	check_eq(sfx._music_track, "spire", "the Spire screen")
	sfx.on_fight_start(sim)
	check_eq(sfx._music_track, "spire", "its fights keep it")
	sfx.set_theme("spire")
	check_eq(sfx._music_track, "spire", "no change mid-fight")
	sfx.on_result(1)
	sfx.on_menu()
	check_eq(sfx._music_track, "spire", "aiming the next leg keeps it")
	sfx.set_theme("")
	check_eq(sfx._music_track, "menu", "leaving the mode goes back to the menu loop")
	sfx.free()


## A new Plunge race (or fight, leg, scene) carries the music on from where
## it last stopped; overtime variants start from the top.
func test_plunge_music_carries_on() -> void:
	var sfx := _sfx()
	Sfx._track_pos = {"plunge": 37.5}
	check_eq(sfx._start_pos("plunge", 138.0), 37.5, "picks up where the last race left it")
	check_eq(sfx._start_pos("plunge", 30.0), 0.0, "a stale spot past the end starts over")
	Sfx._track_pos = {"plunge": 37.5, "boss": 20.0, "boss_overtime": 9.0}
	check_eq(sfx._start_pos("boss", 116.0), 20.0, "every mode track carries on")
	check_eq(sfx._start_pos("boss_overtime", 60.0), 0.0, "overtime always starts fresh")
	Sfx._track_pos = {}
	sfx.free()


## A mode with its own fight music (Arena) uses it for the fight and its
## overtime; a theme with no tracks falls back to the shared ones.
func test_fight_theme_picks_mode_music() -> void:
	var sfx := _sfx()
	check_eq(sfx._fight_track(""), "fight", "no theme: shared fight")
	check_eq(sfx._fight_track("overtime"), "overtime", "no theme: shared overtime")
	check_eq(sfx._menu_track(), "menu", "no theme: the menu loop on screens")
	sfx.theme = "arena"
	check_eq(sfx._fight_track(""), "arena", "arena fight")
	check_eq(sfx._fight_track("overtime"), "arena_overtime", "arena overtime")
	check_eq(sfx._menu_track(), "arena", "arena screens and aiming")
	sfx.theme = "boss"
	check_eq(sfx._fight_track("overtime"), "boss_overtime", "boss overtime")
	sfx.theme = "bounce"
	check_eq(sfx._fight_track(""), "bounce", "Bounce Run fights keep the run's music")
	check_eq(sfx._fight_track("overtime"), "bounce", "and overtime with no faster version")
	sfx.theme = "fight"
	check_eq(sfx._menu_track(), "fight", "a relay with no mode track keeps the fight track between legs")
	check_eq(sfx._fight_track("overtime"), "overtime", "and its overtime")
	sfx.theme = "nothing_here"
	check_eq(sfx._fight_track(""), "fight", "unknown theme falls back")
	check_eq(sfx._menu_track(), "menu", "and on screens")
	sfx.free()


## The menu loop carries on where it was: on through a scene change (the new
## screen's Sfx counts the load time), and paused through a fight.
func test_menu_music_resumes() -> void:
	Sfx._menu_pos = 30.0
	Sfx._menu_left_at = 100.0
	check_eq(Sfx._menu_resume(100.5, 160.0), 30.5, "a scene change keeps counting")
	check_eq(Sfx._menu_resume(250.0, 160.0), 20.0, "and wraps round the loop")
	check_eq(Sfx._menu_resume(250.0, 160.0, 100.0), 120.0, "past the end it wraps to the loop start, not the intro")
	check_eq(Sfx._menu_resume(150.0, 160.0, 100.0), 80.0, "still in the first play-through it just counts on")
	var sfx := _sfx()
	sfx._save_menu_pos(false) # A fight opened right after the scene change.
	check_eq(Sfx._menu_left_at, -1.0, "a fight stops the clock")
	check(Sfx._menu_pos > 30.0, "at the time the fight started")
	Sfx._menu_pos = 30.0
	check_eq(Sfx._menu_resume(999.0, 160.0), 30.0, "after the fight it picks up where it paused")
	Sfx._menu_pos = 0.0
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
