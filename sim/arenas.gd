## Static arena definitions. Pure data, in full-size arena units (1000 x 1000,
## centre 500,500); the sim scales everything toward the centre in overtime.
## Every arena must be point-symmetric through the centre so neither start
## corner has an edge (design/arenas.md).
##
## corner_cut: cuts each corner of the square by this many units, making an
##   octagon. 0 keeps the square.
## obstacles: solid circles balls bounce off. Bounces off them count as wall
##   bounces for abilities. kind "bumper" also kicks the ball off faster;
##   kind "spike" also deals spike damage (see MatchSim.SPIKE_*); kind
##   "crystal" cracks on hits and shatters, then grows back (MatchSim.CRYSTAL_*).
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
##   `accel` (by weight), "portal" sends it to floor `to` keeping its velocity,
##   "launch" throws it into the air over everything (MatchSim.LAUNCH_*).
## cores: power cores {pos, radius}: the first ball through a lit one is
##   Overcharged, then it goes dark for a while (MatchSim.CORE_*).
## orbit (on an obstacle): circles the centre at this many rad/s from pos.
## start_scale: starts sit this much closer to the centre (same aim lines),
##   so round and hexagonal maps keep the corners' room.
## sides: {n, inradius, rot}: n straight walls (n even, so point-symmetric),
##   each `inradius` from the centre, the first facing `rot` degrees. They cut
##   the square into a hexagon (6), a rounded ring (12+) or, with n 2, a lane
##   along one diagonal.
## shrink_start / shrink_speed: the walls start closing in early, slower.
extends RefCounted

const DEFS := {
	"square": {
		"display_name": "The Box",
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
		"display_name": "Bumper Lab",
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
		"display_name": "Ice Pond",
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
		"display_name": "Portal Hall",
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
		"description": "Coral to bank off, whirlpool in the middle.",
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
	# --- Map pack 2 (2026-10-21): new shapes and looks. ----------------------
	"candy": {
		"display_name": "Candy Carousel",
		"description": "A round sweet shop. Gumdrop bumpers kick balls off faster.",
		"corner_cut": 0.0,
		"sides": {"n": 16, "inradius": 470.0, "rot": 0.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 500), "radius": 58.0, "kind": "bumper"},
			{"pos": Vector2(500, 290), "radius": 32.0, "kind": "bumper"},
			{"pos": Vector2(500, 710), "radius": 32.0, "kind": "bumper"},
			{"pos": Vector2(290, 500), "radius": 32.0, "kind": "bumper"},
			{"pos": Vector2(710, 500), "radius": 32.0, "kind": "bumper"},
		],
	},
	"syrup": {
		"display_name": "Syrup Swamp",
		"description": "Sticky syrup slows you down. Lollipops to bounce off.",
		"corner_cut": 100.0,
		"obstacles": [
			{"pos": Vector2(640, 360), "radius": 44.0, "kind": "pillar"},
			{"pos": Vector2(360, 640), "radius": 44.0, "kind": "pillar"},
		],
		"floors": [
			{"kind": "goo", "pos": Vector2(320, 320), "radius": 105.0, "slow": 0.3},
			{"kind": "goo", "pos": Vector2(680, 680), "radius": 105.0, "slow": 0.3},
		],
	},
	"temple": {
		"display_name": "Sun Temple",
		"description": "A six-sided temple floor with a spiked altar in the middle.",
		"corner_cut": 0.0,
		"sides": {"n": 6, "inradius": 460.0, "rot": 0.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 500), "radius": 46.0, "kind": "spike"},
			{"pos": Vector2(330, 330), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(670, 670), "radius": 40.0, "kind": "pillar"},
		],
	},
	"ruins": {
		"display_name": "Jungle Ruins",
		"description": "Old columns and shining crystals that crack and shatter, then grow back.",
		"corner_cut": 0.0,
		"sides": {"n": 8, "inradius": 470.0, "rot": 22.5},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(680, 500), "radius": 34.0, "kind": "pillar"},
			{"pos": Vector2(320, 500), "radius": 34.0, "kind": "pillar"},
			{"pos": Vector2(590, 655.88), "radius": 40.0, "kind": "crystal"},
			{"pos": Vector2(410, 344.12), "radius": 40.0, "kind": "crystal"},
			{"pos": Vector2(410, 655.88), "radius": 40.0, "kind": "crystal"},
			{"pos": Vector2(590, 344.12), "radius": 40.0, "kind": "crystal"},
		],
	},
	"nebula": {
		"display_name": "Nebula Drift",
		"description": "A round pocket of space. Two gravity wells swirl the paths round a power core.",
		"corner_cut": 0.0,
		"sides": {"n": 12, "inradius": 470.0, "rot": 15.0},
		"start_scale": 0.8,
		"obstacles": [],
		"wells": [
			{"pos": Vector2(330, 330), "reach": 210.0, "accel": 950.0, "core": 26.0},
			{"pos": Vector2(670, 670), "reach": 210.0, "accel": 950.0, "core": 26.0},
		],
		"cores": [{"pos": Vector2(500, 500), "radius": 44.0}],
	},
	"asteroid": {
		"display_name": "Asteroid Belt",
		"description": "Four rocks orbit the middle. Mind the gaps.",
		"corner_cut": 150.0,
		"obstacles": [
			{"pos": Vector2(500, 280), "radius": 36.0, "kind": "pillar", "orbit": 0.5},
			{"pos": Vector2(500, 720), "radius": 36.0, "kind": "pillar", "orbit": 0.5},
			{"pos": Vector2(280, 500), "radius": 36.0, "kind": "pillar", "orbit": 0.5},
			{"pos": Vector2(720, 500), "radius": 36.0, "kind": "pillar", "orbit": 0.5},
		],
	},
	"trench": {
		"display_name": "Abyssal Trench",
		"description": "A narrow trench from corner to corner, with coral in the way.",
		"corner_cut": 0.0,
		"sides": {"n": 2, "inradius": 260.0, "rot": 45.0},
		"obstacles": [
			{"pos": Vector2(360, 640), "radius": 38.0, "kind": "pillar"},
			{"pos": Vector2(640, 360), "radius": 38.0, "kind": "pillar"},
		],
	},
	"kelp": {
		"display_name": "Kelp Forest",
		"description": "Swaying kelp stalks everywhere to ricochet off.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(300, 300), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(700, 700), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(320, 680), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(680, 320), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(500, 170), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(500, 830), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(170, 500), "radius": 26.0, "kind": "pillar"},
			{"pos": Vector2(830, 500), "radius": 26.0, "kind": "pillar"},
		],
	},
	"storm": {
		"display_name": "Thunder Peak",
		"description": "A hexagonal peak. Lightning rods kick, spiked crags bite.",
		"corner_cut": 0.0,
		"sides": {"n": 6, "inradius": 460.0, "rot": 30.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 320), "radius": 40.0, "kind": "bumper"},
			{"pos": Vector2(500, 680), "radius": 40.0, "kind": "bumper"},
			{"pos": Vector2(300, 500), "radius": 30.0, "kind": "spike"},
			{"pos": Vector2(700, 500), "radius": 30.0, "kind": "spike"},
		],
	},
	"cloud": {
		"display_name": "Cloud Kingdom",
		"description": "A round sky island. Slick clouds speed you up; jump pads throw you over it all.",
		"corner_cut": 0.0,
		"sides": {"n": 12, "inradius": 470.0, "rot": 0.0},
		"start_scale": 0.8,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 50.0, "kind": "pillar"}],
		"floors": [
			{"kind": "ice", "pos": Vector2(320, 320), "radius": 110.0},
			{"kind": "ice", "pos": Vector2(680, 680), "radius": 110.0},
			{"kind": "launch", "pos": Vector2(500, 230), "radius": 65.0},
			{"kind": "launch", "pos": Vector2(500, 770), "radius": 65.0},
		],
	},
	"sunset": {
		"display_name": "Sunset Grid",
		"description": "Ride the belts into the sunset, or cut through the middle for the power core.",
		"corner_cut": 0.0,
		"sides": {"n": 10, "inradius": 470.0, "rot": 18.0},
		"start_scale": 0.8,
		"obstacles": [],
		"floors": [
			{"kind": "conveyor", "rect": Rect2(300, 300, 400, 90), "dir": Vector2.RIGHT, "accel": 480.0},
			{"kind": "conveyor", "rect": Rect2(300, 610, 400, 90), "dir": Vector2.LEFT, "accel": 480.0},
		],
		"cores": [{"pos": Vector2(500, 500), "radius": 44.0}],
	},
	"alley": {
		"display_name": "Neon Alley",
		"description": "Signposts down the middle and bumpers on the corners of the block.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 240), "radius": 34.0, "kind": "pillar"},
			{"pos": Vector2(500, 760), "radius": 34.0, "kind": "pillar"},
			{"pos": Vector2(500, 500), "radius": 34.0, "kind": "pillar"},
			{"pos": Vector2(330, 330), "radius": 30.0, "kind": "bumper"},
			{"pos": Vector2(670, 670), "radius": 30.0, "kind": "bumper"},
		],
	},
	"dunes": {
		"display_name": "Sand Dunes",
		"description": "A wide desert pass with quicksand in the middle and cacti.",
		"corner_cut": 0.0,
		"sides": {"n": 2, "inradius": 330.0, "rot": 45.0},
		"obstacles": [
			{"pos": Vector2(380, 380), "radius": 30.0, "kind": "spike"},
			{"pos": Vector2(620, 620), "radius": 30.0, "kind": "spike"},
		],
		"floors": [{"kind": "goo", "pos": Vector2(500, 500), "radius": 100.0, "slow": 0.35}],
	},
	"oasis": {
		"display_name": "Desert Oasis",
		"description": "A round oasis. Wading through the pool slows you; palms to bounce off.",
		"corner_cut": 0.0,
		"sides": {"n": 16, "inradius": 470.0, "rot": 11.25},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 290), "radius": 32.0, "kind": "pillar"},
			{"pos": Vector2(500, 710), "radius": 32.0, "kind": "pillar"},
		],
		"floors": [{"kind": "goo", "pos": Vector2(500, 500), "radius": 125.0, "slow": 0.25}],
	},
	"graveyard": {
		"display_name": "Moonlit Graveyard",
		"description": "Iron railings bite and tombstones block the way.",
		"corner_cut": 140.0,
		"obstacles": [
			{"pos": Vector2(380, 380), "radius": 32.0, "kind": "spike"},
			{"pos": Vector2(620, 620), "radius": 32.0, "kind": "spike"},
			{"pos": Vector2(640, 360), "radius": 36.0, "kind": "pillar"},
			{"pos": Vector2(360, 640), "radius": 36.0, "kind": "pillar"},
		],
	},
	"manor": {
		"display_name": "Haunted Manor",
		"description": "Four haunted mirrors: roll into one, come out of the one across the hall.",
		"corner_cut": 0.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 48.0, "kind": "pillar"}],
		"floors": [
			{"kind": "portal", "pos": Vector2(500, 170), "radius": 60.0, "to": 1},
			{"kind": "portal", "pos": Vector2(500, 830), "radius": 60.0, "to": 0},
			{"kind": "portal", "pos": Vector2(170, 500), "radius": 60.0, "to": 3},
			{"kind": "portal", "pos": Vector2(830, 500), "radius": 60.0, "to": 2},
		],
	},
	"toybox": {
		"display_name": "Toy Chest",
		"description": "Bouncy blocks, a big ball in the middle and two springboards to fly off.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 500), "radius": 56.0, "kind": "pillar"},
			{"pos": Vector2(320, 320), "radius": 36.0, "kind": "bumper"},
			{"pos": Vector2(680, 680), "radius": 36.0, "kind": "bumper"},
			{"pos": Vector2(700, 300), "radius": 36.0, "kind": "bumper"},
			{"pos": Vector2(300, 700), "radius": 36.0, "kind": "bumper"},
		],
		"floors": [
			{"kind": "launch", "pos": Vector2(500, 180), "radius": 70.0},
			{"kind": "launch", "pos": Vector2(500, 820), "radius": 70.0},
		],
	},
	"speedway": {
		"display_name": "Slot Car Speedway",
		"description": "Belts run round the track. Ride the loop or fight across it.",
		"corner_cut": 180.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 60.0, "kind": "pillar"}],
		"floors": [
			{"kind": "conveyor", "rect": Rect2(270, 120, 460, 90), "dir": Vector2.LEFT, "accel": 450.0},
			{"kind": "conveyor", "rect": Rect2(270, 790, 460, 90), "dir": Vector2.RIGHT, "accel": 450.0},
			{"kind": "conveyor", "rect": Rect2(120, 270, 90, 460), "dir": Vector2.DOWN, "accel": 450.0},
			{"kind": "conveyor", "rect": Rect2(790, 270, 90, 460), "dir": Vector2.UP, "accel": 450.0},
		],
	},
	"arcane": {
		"display_name": "Arcane Circle",
		"description": "A summoning circle: rune portals, crystal pylons and a power core in the middle.",
		"corner_cut": 0.0,
		"sides": {"n": 20, "inradius": 470.0, "rot": 0.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(330, 500), "radius": 34.0, "kind": "pillar"},
			{"pos": Vector2(670, 500), "radius": 34.0, "kind": "pillar"},
		],
		"floors": [
			{"kind": "portal", "pos": Vector2(500, 260), "radius": 60.0, "to": 1},
			{"kind": "portal", "pos": Vector2(500, 740), "radius": 60.0, "to": 0},
		],
		"cores": [{"pos": Vector2(500, 500), "radius": 44.0}],
	},
	"prism": {
		"display_name": "Prism Mines",
		"description": "A tight mine shaft. Crystal spikes, breakable crystals and a slick crystal floor.",
		"corner_cut": 0.0,
		"sides": {"n": 4, "inradius": 400.0, "rot": 0.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 330), "radius": 30.0, "kind": "spike"},
			{"pos": Vector2(500, 670), "radius": 30.0, "kind": "spike"},
			{"pos": Vector2(320, 500), "radius": 40.0, "kind": "crystal"},
			{"pos": Vector2(680, 500), "radius": 40.0, "kind": "crystal"},
		],
		"floors": [{"kind": "ice", "pos": Vector2(500, 500), "radius": 120.0}],
	},
}

## Arenas offered in the in-game picker and checked by the balance sim.
const PLAYABLE := ["square", "rink", "pillars", "bumpers", "wells", "spikes", "frost", "magma", "arcade",
	"starfall", "factory", "orbit", "hive", "horizon", "pinball", "reef", "glitch", "inferno", "thorn",
	"candy", "syrup", "temple", "ruins", "nebula", "asteroid", "trench", "kelp", "storm", "cloud",
	"sunset", "alley", "dunes", "oasis", "graveyard", "manor", "toybox", "speedway", "arcane", "prism"]


## Boss maps (sim/bosses.gd, design/bosses.md): one per boss, never in the
## picker. A boss fight isn't a mirror match, so these needn't be
## point-symmetric. min_half: overtime stops squeezing here, so a critter
## always fits between the walls and a boss in the middle.
const BOSS_ARENAS := {
	"forge": {
		"display_name": "The Forge",
		"description": "Lava corners, side belts.",
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
		"description": "Moss slows you; egg in the middle.",
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
		"description": "Balloon bumpers kick you back up.",
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
		"description": "Cut corners, wide open.",
		"corner_cut": 120.0,
		"obstacles": [],
		"min_half": 470.0,
		"floors": [],
	},
	"core": {
		"display_name": "Corrupted Core",
		"description": "Side portals throw you across.",
		"corner_cut": 0.0,
		"obstacles": [],
		"min_half": 470.0,
		"floors": [
			{"kind": "portal", "pos": Vector2(110, 500), "radius": 60.0, "to": 1},
			{"kind": "portal", "pos": Vector2(890, 500), "radius": 60.0, "to": 0},
		],
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
