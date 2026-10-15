## Static arena definitions. Pure data, in full-size arena units (1000 x 1000,
## centre 500,500); the sim scales everything toward the centre in overtime.
## Every arena must be point-symmetric through the centre so neither start
## corner has an edge (design/arenas.md).
##
## corner_cut: cuts each corner of the square by this many units, making an
##   octagon. 0 keeps the square.
## obstacles: solid circles balls bounce off. Bounces off them count as wall
##   bounces for abilities. kind "bumper" also kicks the ball off faster;
##   kind "spike" also deals spike damage (see MatchSim.SPIKE_*).
## wells: gravity wells on the floor. Balls pass over them; each bends every
##   ball's path toward its centre (accel, units/s^2, fading to 0 at reach),
##   scaled by the ball's weight (sim/weight.gd). Inside core it lets go, so a
##   ball can't be pinned on the centre.
## spike_walls: the middle of the left and right walls (`half` units either
##   side of the centre line) is spiked: bouncing there deals spike damage.
extends RefCounted

const DEFS := {
	"square": {
		"display_name": "Glow Garden",
		"description": "The plain square.",
		"corner_cut": 0.0,
		"obstacles": [],
	},
	"rink": {
		"display_name": "Neon Rink",
		"description": "An octagon: no corners to get pinned in.",
		"corner_cut": 200.0,
		"obstacles": [],
	},
	"pillars": {
		"display_name": "Pillar Hall",
		"description": "Two pillars to bounce off.",
		"corner_cut": 0.0,
		# Two pillars on the centre line: four at 320/680 gave Laser so many
		# extra bounces it beat Vampire 68% (tilt -14 points).
		"obstacles": [
			{"pos": Vector2(300, 500), "radius": 60.0, "kind": "pillar"},
			{"pos": Vector2(700, 500), "radius": 60.0, "kind": "pillar"},
		],
	},
	"bumpers": {
		"display_name": "Circuit Lab",
		"description": "Bumpers kick balls off faster for a moment.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 500), "radius": 72.0, "kind": "bumper"},
			{"pos": Vector2(285, 285), "radius": 48.0, "kind": "bumper"},
			{"pos": Vector2(715, 715), "radius": 48.0, "kind": "bumper"},
		],
	},
	"wells": {
		"display_name": "Gravity Wells",
		"description": "Two wells bend every path. Light critters get dragged hardest.",
		"corner_cut": 0.0,
		"obstacles": [],
		# On the empty diagonal so neither start sits in one.
		"wells": [
			{"pos": Vector2(320, 320), "reach": 250.0, "accel": 1100.0, "core": 26.0},
			{"pos": Vector2(680, 680), "reach": 250.0, "accel": 1100.0, "core": 26.0},
		],
	},
	"spikes": {
		"display_name": "Spike Yard",
		"description": "Spiked posts and spiked walls nick whoever bounces off them.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 290), "radius": 44.0, "kind": "spike"},
			{"pos": Vector2(500, 710), "radius": 44.0, "kind": "spike"},
		],
		"spike_walls": {"half": 150.0},
	},
}

## Arenas offered in the in-game picker and checked by the balance sim.
const PLAYABLE := ["square", "rink", "pillars", "bumpers", "wells", "spikes"]


static func get_def(id: String) -> Dictionary:
	assert(DEFS.has(id), "Unknown arena id: %s" % id)
	return DEFS[id]
