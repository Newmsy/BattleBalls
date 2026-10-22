## How family edges (sim/families.gd, design/type-advantage.md) look in a
## fight: the kick-off matchup line and the ▲ chevrons by the health bars.
## Render-only: reads the sim, never changes it.
extends RefCounted

const Families := preload("res://sim/families.gd")

## The kick-off line for the side with the edge, keyed "attacker>target".
const LINES := {
	# The very good loop.
	"fire>nature": "Fire burns Nature!",
	"nature>sweet": "Nature's bugs swarm Sweet!",
	"sweet>spooky": "Sweet treats tame Spooky!",
	"spooky>toybox": "Spooky haunts Toybox!",
	"toybox>frost": "Toybox snow-globes Frost!",
	"frost>sea": "Frost freezes Sea!",
	"sea>tech": "Sea shorts out Tech!",
	"tech>cosmic": "Tech rockets conquer Cosmic!",
	"cosmic>fire": "Cosmic black holes swallow Fire!",
	# Good.
	"nature>sea": "Nature's roots drink the Sea!",
	"nature>tech": "Nature's vines choke Tech!",
	"sea>sweet": "Sea water melts Sweet!",
	"sea>fire": "Sea waves douse Fire!",
	"tech>toybox": "Tech hacks the Toybox!",
	"tech>spooky": "Tech gadgets bust Spooky!",
	"sweet>tech": "Sweet syrup gums up Tech!",
	"sweet>toybox": "Sweet goo jams the Toybox!",
	"frost>nature": "Frost wilts Nature!",
	"frost>sweet": "Frost gives Sweet brain freeze!",
	"toybox>fire": "Toybox squirt guns douse Fire!",
	"toybox>cosmic": "Toybox kites snag Cosmic!",
	"spooky>nature": "Spooky withers Nature!",
	"spooky>cosmic": "Spooky eclipses Cosmic!",
	"fire>frost": "Fire melts Frost!",
	"fire>spooky": "Fire banishes Spooky!",
	"cosmic>sea": "Cosmic moons pull the Sea!",
	"cosmic>frost": "Cosmic comets blaze through Frost!",
}


## The 1v1 matchup in `sim` from side 0's view: {edge (-2..2), "adv" and
## "other" (the families with and without the edge), "line"}. Empty for a
## neutral matchup, a team fight, or a critter outside every family.
static func matchup(sim) -> Dictionary:
	if sim == null or sim.balls.size() < 2 or int(sim.get("starters") if sim.get("starters") != null else 2) != 2:
		return {}
	var a: String = sim.balls[0].type_id
	var b: String = sim.balls[1].type_id
	var edge := Families.edge(a, b)
	if edge == 0:
		return {}
	var adv := Families.of(a if edge > 0 else b)
	var other := Families.of(b if edge > 0 else a)
	return {"edge": edge, "adv": adv, "other": other, "line": LINES.get(adv + ">" + other, "")}


## `n` chevrons (▲) side by side, centred on `c`, each `w` wide.
static func draw_chevrons(ci: CanvasItem, c: Vector2, n: int, w: float, col: Color) -> void:
	var h := w * 0.62
	var x0 := c.x - (n * w + (n - 1) * w * 0.2) / 2.0
	for i in n:
		var x := x0 + i * w * 1.2
		var pts := PackedVector2Array([Vector2(x, c.y + h / 2.0), Vector2(x + w / 2.0, c.y - h / 2.0), Vector2(x + w, c.y + h / 2.0)])
		ci.draw_polyline(pts, Color(0, 0, 0, 0.7), w * 0.36, true)
		ci.draw_polyline(pts, col, w * 0.2, true)
