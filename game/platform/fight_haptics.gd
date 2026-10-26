## Buzzes for a fight, read from the same sim events the sounds come from
## (game/audio/sfx.gd calls consume). Render-only: it reads the events and
## never touches the sim. Hard bumps and big hits buzz; a KO buzzes hardest.
## Platform.haptic merges buzzes that crowd together, so a skipped fight
## can't machine-gun the phone.
extends RefCounted

const Platform := preload("res://game/platform/platform.gd")

const BUMP_SPEED := 700.0 ## Closing speed (px/s) a bump needs to buzz.
const BIG_HIT_SHARE := 0.18 ## Matches sfx.gd: a hit this share of max HP is big.


## The haptic kind for one event, or "" for none.
static func kind_for(e: Dictionary, sim) -> String:
	match e.get("type", ""):
		"collide":
			var a = sim.balls[e.a]
			var b = sim.balls[e.b]
			return "hit" if (a.vel - b.vel).length() >= BUMP_SPEED else ""
		"damage":
			var target = sim.balls[e.target]
			return "big_hit" if float(e.get("amount", 0)) >= target.max_hp * BIG_HIT_SHARE else ""
		"end":
			return "ko" if e.get("reason", "") != "time_limit" else ""
	return ""


static func consume(events: Array[Dictionary], sim, platform = null) -> void:
	var p = platform if platform != null else Platform.get_current()
	if not p.can_vibrate():
		return
	var best := ""
	var order := ["", "hit", "big_hit", "ko"]
	for e in events:
		var k := kind_for(e, sim)
		if order.find(k) > order.find(best):
			best = k
	if best != "":
		p.haptic(best)
