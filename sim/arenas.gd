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
## floors: pads balls pass over, each a circle (pos, radius) or a rect. A ball
##   is on one when it overlaps it by half its radius (portals: its centre
##   reaches the inner 60%). kind "ice" speeds it up, "goo" slows it by `slow`,
##   "lava" burns (capped with spikes), "conveyor" pushes it along `dir` at
##   `accel` (by weight), "portal" sends it to floor `to` keeping its velocity.
## orbit (on an obstacle): circles the centre at this many rad/s from pos.
## shrink_start / shrink_speed: the walls start closing in early, slower.
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
	"frost": {
		"display_name": "Frostbite Lake",
		"description": "A frozen lake in the middle: balls skate 30% faster on the ice.",
		"corner_cut": 0.0,
		"obstacles": [],
		"floors": [{"kind": "ice", "pos": Vector2(500, 500), "radius": 230.0}],
	},
	"magma": {
		"display_name": "Magma Core",
		"description": "Lava pools in the two empty corners burn whoever rolls through.",
		"corner_cut": 0.0,
		"obstacles": [],
		"floors": [
			{"kind": "lava", "pos": Vector2(160, 160), "radius": 150.0},
			{"kind": "lava", "pos": Vector2(840, 840), "radius": 150.0},
		],
	},
	"arcade": {
		"display_name": "Haunted Arcade",
		"description": "Two portals: roll into one, pop out of the other.",
		"corner_cut": 0.0,
		"obstacles": [],
		"floors": [
			{"kind": "portal", "pos": Vector2(150, 500), "radius": 70.0, "to": 1},
			{"kind": "portal", "pos": Vector2(850, 500), "radius": 70.0, "to": 0},
		],
	},
	"starfall": {
		"display_name": "Starfall Rim",
		"description": "The rim starts closing in at 15 seconds. Fights end up close.",
		"corner_cut": 120.0,
		"obstacles": [],
		"shrink_start": 15.0,
		"shrink_speed": 6.0,
	},
	"factory": {
		"display_name": "Conveyor Factory",
		"description": "Two belts run opposite ways. Light critters get carried furthest.",
		"corner_cut": 0.0,
		"obstacles": [],
		"floors": [
			{"kind": "conveyor", "rect": Rect2(80, 260, 840, 120), "dir": Vector2.RIGHT, "accel": 520.0},
			{"kind": "conveyor", "rect": Rect2(80, 620, 840, 120), "dir": Vector2.LEFT, "accel": 520.0},
		],
	},
	"orbit": {
		"display_name": "Orbit Station",
		"description": "Two moons circle the middle. Time your bounces.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 280), "radius": 52.0, "kind": "pillar", "orbit": 0.55},
			{"pos": Vector2(500, 720), "radius": 52.0, "kind": "pillar", "orbit": 0.55},
		],
	},
	"hive": {
		"display_name": "Honey Hive",
		"description": "Sticky honey slows anyone rolling through it.",
		"corner_cut": 0.0,
		"obstacles": [],
		"floors": [
			{"kind": "goo", "pos": Vector2(300, 300), "radius": 140.0, "slow": 0.35},
			{"kind": "goo", "pos": Vector2(700, 700), "radius": 140.0, "slow": 0.35},
			{"kind": "goo", "pos": Vector2(500, 500), "radius": 80.0, "slow": 0.35},
		],
	},
	"horizon": {
		"display_name": "Event Horizon",
		"description": "One huge well in the middle drags every fight together.",
		"corner_cut": 0.0,
		"obstacles": [],
		"wells": [{"pos": Vector2(500, 500), "reach": 380.0, "accel": 900.0, "core": 34.0}],
	},
	"pinball": {
		"display_name": "Pinball Palace",
		"description": "Bumpers fling you, spiked side walls bite.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 500), "radius": 60.0, "kind": "bumper"},
			{"pos": Vector2(300, 300), "radius": 44.0, "kind": "bumper"},
			{"pos": Vector2(700, 700), "radius": 44.0, "kind": "bumper"},
		],
		"spike_walls": {"half": 120.0},
	},
	"reef": {
		"display_name": "Coral Reef",
		"description": "Four coral heads to bank off, and a whirlpool current in the middle.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 250), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(500, 750), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(250, 500), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(750, 500), "radius": 40.0, "kind": "pillar"},
		],
		"wells": [{"pos": Vector2(500, 500), "reach": 150.0, "accel": 700.0, "core": 20.0}],
	},
	"glitch": {
		"display_name": "Glitch Grid",
		"description": "Two pairs of portals swap you across the grid.",
		"corner_cut": 160.0,
		"obstacles": [],
		"floors": [
			{"kind": "portal", "pos": Vector2(300, 300), "radius": 60.0, "to": 1},
			{"kind": "portal", "pos": Vector2(700, 700), "radius": 60.0, "to": 0},
			{"kind": "portal", "pos": Vector2(700, 300), "radius": 60.0, "to": 3},
			{"kind": "portal", "pos": Vector2(300, 700), "radius": 60.0, "to": 2},
		],
	},
	"inferno": {
		"display_name": "Inferno Ring",
		"description": "Lava runs along the side walls. Stay off the edges.",
		"corner_cut": 0.0,
		"obstacles": [],
		"floors": [
			{"kind": "lava", "rect": Rect2(0, 220, 60, 560)},
			{"kind": "lava", "rect": Rect2(940, 220, 60, 560)},
		],
	},
	"thorn": {
		"display_name": "Thorn Garden",
		"description": "Thorny walls and two hedges in the middle.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(330, 500), "radius": 50.0, "kind": "spike"},
			{"pos": Vector2(670, 500), "radius": 50.0, "kind": "spike"},
		],
		"spike_walls": {"half": 200.0},
	},
}

## Arenas offered in the in-game picker and checked by the balance sim.
const PLAYABLE := ["square", "rink", "pillars", "bumpers", "wells", "spikes", "frost", "magma", "arcade",
	"starfall", "factory", "orbit", "hive", "horizon", "pinball", "reef", "glitch", "inferno", "thorn"]


## Boss maps (sim/bosses.gd, design/bosses.md): one per boss, never in the
## picker. A boss fight isn't a mirror match, so these needn't be
## point-symmetric. min_half: overtime stops squeezing here, so a critter
## always fits between the walls and a boss in the middle.
const BOSS_ARENAS := {
	"forge": {
		"display_name": "The Forge",
		"description": "Molten pools in two corners and belts running up and down the sides.",
		"corner_cut": 0.0,
		"obstacles": [],
		"min_half": 420.0,
		"floors": [
			{"kind": "lava", "pos": Vector2(80, 80), "radius": 70.0},
			{"kind": "lava", "pos": Vector2(920, 920), "radius": 70.0},
			{"kind": "conveyor", "rect": Rect2(20, 260, 90, 480), "dir": Vector2.UP, "accel": 420.0},
			{"kind": "conveyor", "rect": Rect2(890, 260, 90, 480), "dir": Vector2.DOWN, "accel": 420.0},
		],
	},
	"nest": {
		"display_name": "The Nest",
		"description": "A twig nest with a golden egg in the middle and soft moss patches that slow you down.",
		"corner_cut": 140.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 70.0, "kind": "pillar"}],
		"min_half": 480.0,
		"floors": [
			{"kind": "goo", "pos": Vector2(500, 160), "radius": 80.0, "slow": 0.3},
			{"kind": "goo", "pos": Vector2(840, 500), "radius": 80.0, "slow": 0.3},
		],
	},
	"plaza": {
		"display_name": "Fiesta Plaza",
		"description": "A party square under the piñata, with balloon bumpers that kick you back up into it.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(330, 720), "radius": 46.0, "kind": "bumper"},
			{"pos": Vector2(670, 720), "radius": 46.0, "kind": "bumper"},
			{"pos": Vector2(500, 900), "radius": 38.0, "kind": "bumper"},
		],
		"min_half": 480.0,
		"floors": [],
	},
	"shrine": {
		"display_name": "Spirit Shrine",
		"description": "A moonlit shrine with four stone lanterns round the totem.",
		"corner_cut": 90.0,
		"obstacles": [
			{"pos": Vector2(500, 150), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(150, 500), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(850, 500), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(500, 850), "radius": 40.0, "kind": "pillar"},
		],
		"min_half": 440.0,
		"floors": [],
	},
	"rift": {
		"display_name": "Crystal Rift",
		"description": "A cavern of cut crystal corners, wide open for the wyrm to snake through.",
		"corner_cut": 120.0,
		"obstacles": [],
		"min_half": 470.0,
		"floors": [],
	},
}


## The map a fight with this seed is played on: every mode that rolls a map
## stores the result in its fight config, so later pool changes never move it.
static func pick(seed_value: int) -> String:
	return PLAYABLE[posmod(("arena:%d" % seed_value).hash(), PLAYABLE.size())]


static func get_def(id: String) -> Dictionary:
	if BOSS_ARENAS.has(id):
		return BOSS_ARENAS[id]
	assert(DEFS.has(id), "Unknown arena id: %s" % id)
	return DEFS[id]
