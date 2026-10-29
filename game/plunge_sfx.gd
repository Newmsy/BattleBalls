## The race's sound (game/audio/sfx.gd) with your racer up front: its
## ability sounds play at full volume and everyone else's are ducked, so
## you can hear what your critter is doing in a pack of eight.
extends "res://game/audio/sfx.gd"

const DUCK_DB := -6.0

var you := 0 ## Your racer (-1 in a race you only watch: nobody is ducked).
var _sim


func consume_events(events: Array[Dictionary], sim) -> void:
	_sim = sim
	super.consume_events(events, sim)


func _critter_cues(e: Dictionary, owner):
	var cues = super._critter_cues(e, owner)
	if cues == null or you < 0 or _sim == null or owner.team == _sim.balls[you].team:
		return cues
	return cues.map(func(c):
		var quiet: Array = c.duplicate()
		quiet[1] = float(c[1]) + DUCK_DB
		return quiet)
