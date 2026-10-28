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
##   kind "heal" / "shield" makes it a heal or shield pickup instead
##   (MatchSim.HEAL_PICKUP, SHIELD_PICKUP), on the same clock.
## Moving parts (on an obstacle), driven by fight time only so replays match:
##   orbit: circles its pivot (default the centre) at this many rad/s from pos.
##   slide + period: swings back and forth by the `slide` offset (a sine).
##   bar + angle: a long bar instead of a circle: `bar` units either side of
##   pos along `angle` degrees, `radius` thick, built from overlapping circles
##   (expand_bars). With orbit and no pivot it spins round its own middle.
##   Keep a gap of 200+ to walls and other obstacles everywhere a part goes,
##   and moving surfaces under ~250 units/s (balls run at ~400), so a part
##   bats balls around but never pins one.
## Floors and wells take orbit / slide + period too (circles only), so a
##   portal or a well can drift. A conveyor with `flip` reverses every `flip`
##   seconds. A spike obstacle with `retract` pulls its thorns in for every
##   other `retract` seconds (a plain post meanwhile).
## start_scale: starts sit this much closer to the centre (same aim lines),
##   so round and hexagonal maps keep the corners' room.
## sides: {n, inradius, rot}: n straight walls (n even, so point-symmetric),
##   each `inradius` from the centre, the first facing `rot` degrees. They cut
##   the square into a hexagon (6), a rounded ring (12+) or, with n 2, a lane
##   along one diagonal.
## shrink_start / shrink_speed: the walls start closing in early, slower.
extends RefCounted

const DMath := preload("res://sim/dmath.gd")

const DEFS := {
	"square": {
		"display_name": "The Box",
		"description": "The plain square.",
		"corner_cut": 0.0,
		"obstacles": [],
	},
	"rink": {
		"display_name": "Neon Rink",
		"description": "An octagon with no corners to get pinned in. Zambonis sweep each end of the ice.",
		"corner_cut": 200.0,
		"obstacles": [
			{"pos": Vector2(500, 215), "radius": 26.0, "kind": "pillar", "bar": 60.0, "angle": 0.0, "slide": Vector2(90, 0), "period": 7.0},
			{"pos": Vector2(500, 785), "radius": 26.0, "kind": "pillar", "bar": 60.0, "angle": 0.0, "slide": Vector2(-90, 0), "period": 7.0},
		],
	},
	# The first fights (game/onboarding.gd): Neon Rink as it was before the
	# Zambonis, so the tutorial's fixed aims and cold open play out as tuned.
	# Not in the picker or the random pool.
	"first_rink": {
		"display_name": "Neon Rink",
		"description": "An octagon: no corners to get pinned in.",
		"corner_cut": 200.0,
		"obstacles": [],
	},
	"pillars": {
		"display_name": "Pillar Hall",
		"description": "Two pillars glide up and down the hall. Time your bounces.",
		"corner_cut": 0.0,
		# Two pillars on the centre line: four at 320/680 gave Laser so many
		# extra bounces it beat Vampire 68% (tilt -14 points).
		"obstacles": [
			{"pos": Vector2(300, 500), "radius": 60.0, "kind": "pillar", "slide": Vector2(0, 130), "period": 5.0},
			{"pos": Vector2(700, 500), "radius": 60.0, "kind": "pillar", "slide": Vector2(0, -130), "period": 5.0},
		],
	},
	"bumpers": {
		"display_name": "Bumper Lab",
		"description": "Bumpers kick balls off faster for a moment. Two of them circle the big one.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 500), "radius": 72.0, "kind": "bumper"},
			{"pos": Vector2(316, 316), "radius": 40.0, "kind": "bumper", "orbit": 0.45},
			{"pos": Vector2(684, 684), "radius": 40.0, "kind": "bumper", "orbit": 0.45},
		],
	},
	"wells": {
		"display_name": "Gravity Wells",
		"description": "Two wells drift round the arena bending every path. Light critters get dragged hardest.",
		"corner_cut": 0.0,
		"obstacles": [],
		# They start on the empty diagonal so neither start sits in one, then
		# swing a quarter turn either way (never reaching a start).
		"wells": [
			{"pos": Vector2(320, 320), "reach": 250.0, "accel": 1100.0, "core": 26.0, "slide": Vector2(-90, 90), "period": 9.0},
			{"pos": Vector2(680, 680), "reach": 250.0, "accel": 1100.0, "core": 26.0, "slide": Vector2(90, -90), "period": 9.0},
		],
	},
	"spikes": {
		"display_name": "Spike Yard",
		"description": "Spiked posts roll round the yard and spiked walls nick whoever bounces off them.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 290), "radius": 44.0, "kind": "spike", "orbit": 0.35},
			{"pos": Vector2(500, 710), "radius": 44.0, "kind": "spike", "orbit": 0.35},
		],
		"spike_walls": {"half": 150.0},
	},
	"frost": {
		"display_name": "Ice Pond",
		"description": "A frozen lake in the middle: balls skate 30% faster on the ice. Ice crystals round the shore crack open.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(330, 330), "radius": 36.0, "kind": "crystal"},
			{"pos": Vector2(670, 670), "radius": 36.0, "kind": "crystal"},
			{"pos": Vector2(500, 255), "radius": 36.0, "kind": "crystal"},
			{"pos": Vector2(500, 745), "radius": 36.0, "kind": "crystal"},
		],
		"floors": [{"kind": "ice", "pos": Vector2(500, 500), "radius": 230.0}],
	},
	"magma": {
		"display_name": "Magma Core",
		"description": "Lava pools in the two empty corners burn whoever rolls through. Rolling boulders knock you toward them.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 240), "radius": 38.0, "kind": "pillar", "orbit": 0.4},
			{"pos": Vector2(500, 760), "radius": 38.0, "kind": "pillar", "orbit": 0.4},
		],
		"floors": [
			{"kind": "lava", "pos": Vector2(160, 160), "radius": 150.0},
			{"kind": "lava", "pos": Vector2(840, 840), "radius": 150.0},
		],
	},
	"arcade": {
		"display_name": "Portal Hall",
		"description": "Two portals drift up and down the walls: roll into one, pop out of the other. Sliding targets bat you about.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 300), "radius": 30.0, "kind": "pillar", "slide": Vector2(150, 0), "period": 5.5},
			{"pos": Vector2(500, 700), "radius": 30.0, "kind": "pillar", "slide": Vector2(-150, 0), "period": 5.5},
		],
		"floors": [
			{"kind": "portal", "pos": Vector2(150, 500), "radius": 70.0, "to": 1, "slide": Vector2(0, 160), "period": 8.0},
			{"kind": "portal", "pos": Vector2(850, 500), "radius": 70.0, "to": 0, "slide": Vector2(0, -160), "period": 8.0},
		],
	},
	"starfall": {
		"display_name": "Starfall Rim",
		"description": "The rim starts closing in at 15 seconds and two comets circle inside. Fights end up close.",
		"corner_cut": 120.0,
		"obstacles": [
			{"pos": Vector2(500, 260), "radius": 32.0, "kind": "pillar", "orbit": 0.7},
			{"pos": Vector2(500, 740), "radius": 32.0, "kind": "pillar", "orbit": 0.7},
		],
		"shrink_start": 15.0,
		"shrink_speed": 6.0,
	},
	"factory": {
		"display_name": "Conveyor Factory",
		"description": "Two belts run opposite ways and flip every 10 seconds. Crates at the belt ends crack open.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(130, 320), "radius": 34.0, "kind": "crystal"},
			{"pos": Vector2(870, 680), "radius": 34.0, "kind": "crystal"},
		],
		"floors": [
			{"kind": "conveyor", "rect": Rect2(80, 260, 840, 120), "dir": Vector2.RIGHT, "accel": 520.0, "flip": 10.0},
			{"kind": "conveyor", "rect": Rect2(80, 620, 840, 120), "dir": Vector2.LEFT, "accel": 520.0, "flip": 10.0},
		],
	},
	"orbit": {
		"display_name": "Orbit Station",
		"description": "Two moons circle the middle. Time your bounces.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 280), "radius": 62.0, "kind": "pillar", "orbit": 0.55},
			{"pos": Vector2(500, 720), "radius": 62.0, "kind": "pillar", "orbit": 0.55},
		],
	},
	"hive": {
		"display_name": "Honey Hive",
		"description": "Sticky honey slows anyone rolling through it. Two bees buzz round a honey pot that heals.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 280), "radius": 30.0, "kind": "pillar", "orbit": 0.6},
			{"pos": Vector2(500, 720), "radius": 30.0, "kind": "pillar", "orbit": 0.6},
		],
		"floors": [
			{"kind": "goo", "pos": Vector2(300, 300), "radius": 140.0, "slow": 0.35},
			{"kind": "goo", "pos": Vector2(700, 700), "radius": 140.0, "slow": 0.35},
		],
		"cores": [{"pos": Vector2(500, 500), "radius": 40.0, "kind": "heal"}],
	},
	"horizon": {
		"display_name": "Event Horizon",
		"description": "One huge well drags every fight together and a spinning beam bats balls out. Power cores sit at the edge of its pull.",
		"corner_cut": 0.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 24.0, "kind": "pillar", "bar": 150.0, "angle": 0.0, "orbit": 0.5}],
		"cores": [
			{"pos": Vector2(250, 250), "radius": 40.0},
			{"pos": Vector2(750, 750), "radius": 40.0},
		],
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
		"description": "Coral to bank off, shells that crack open, a whirlpool in the middle.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 250), "radius": 40.0, "kind": "crystal"},
			{"pos": Vector2(500, 750), "radius": 40.0, "kind": "crystal"},
			{"pos": Vector2(250, 500), "radius": 40.0, "kind": "pillar"},
			{"pos": Vector2(750, 500), "radius": 40.0, "kind": "pillar"},
		],
		"wells": [{"pos": Vector2(500, 500), "reach": 150.0, "accel": 700.0, "core": 20.0}],
	},
	"glitch": {
		"display_name": "Glitch Grid",
		"description": "Two pairs of portals swap you across the grid. A glitch bar spins in the middle.",
		"corner_cut": 160.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 24.0, "kind": "pillar", "bar": 110.0, "angle": 45.0, "orbit": -0.8}],
		"floors": [
			{"kind": "portal", "pos": Vector2(300, 300), "radius": 60.0, "to": 1},
			{"kind": "portal", "pos": Vector2(700, 700), "radius": 60.0, "to": 0},
			{"kind": "portal", "pos": Vector2(700, 300), "radius": 60.0, "to": 3},
			{"kind": "portal", "pos": Vector2(300, 700), "radius": 60.0, "to": 2},
		],
	},
	"inferno": {
		"display_name": "Inferno Ring",
		"description": "Lava runs along the side walls and rock pistons shove you toward it. Stay off the edges.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(250, 500), "radius": 30.0, "kind": "pillar", "bar": 70.0, "angle": 90.0, "slide": Vector2(70, 0), "period": 4.0},
			{"pos": Vector2(750, 500), "radius": 30.0, "kind": "pillar", "bar": 70.0, "angle": 90.0, "slide": Vector2(-70, 0), "period": 4.0},
		],
		"floors": [
			{"kind": "lava", "rect": Rect2(0, 220, 60, 560)},
			{"kind": "lava", "rect": Rect2(940, 220, 60, 560)},
		],
	},
	"thorn": {
		"display_name": "Thorn Garden",
		"description": "Thorny walls and two hedges whose thorns spring out every few seconds.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(330, 500), "radius": 50.0, "kind": "spike", "retract": 3.0},
			{"pos": Vector2(670, 500), "radius": 50.0, "kind": "spike", "retract": 3.0},
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
		"description": "Sticky syrup slows you down. Swaying lollipops to bounce off.",
		"corner_cut": 100.0,
		"obstacles": [
			{"pos": Vector2(640, 360), "radius": 44.0, "kind": "pillar", "slide": Vector2(35, 35), "period": 3.6},
			{"pos": Vector2(360, 640), "radius": 44.0, "kind": "pillar", "slide": Vector2(-35, -35), "period": 3.6},
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
		"description": "A round pocket of space. Two gravity wells swirl the paths round a power core, with asteroids drifting through.",
		"corner_cut": 0.0,
		"sides": {"n": 12, "inradius": 470.0, "rot": 15.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 290), "radius": 28.0, "kind": "pillar", "orbit": 0.45},
			{"pos": Vector2(500, 710), "radius": 28.0, "kind": "pillar", "orbit": 0.45},
		],
		"wells": [
			{"pos": Vector2(330, 330), "reach": 210.0, "accel": 950.0, "core": 26.0},
			{"pos": Vector2(670, 670), "reach": 210.0, "accel": 950.0, "core": 26.0},
		],
		"cores": [{"pos": Vector2(500, 500), "radius": 44.0}],
	},
	"asteroid": {
		"display_name": "Asteroid Belt",
		"description": "Rocks orbit the middle, an inner pair one way and an outer pair the other. Mind the gaps.",
		"corner_cut": 150.0,
		"obstacles": [
			# A big inner pair one way, a small outer pair the other.
			{"pos": Vector2(500, 380), "radius": 30.0, "kind": "pillar", "orbit": 0.6},
			{"pos": Vector2(500, 620), "radius": 30.0, "kind": "pillar", "orbit": 0.6},
			{"pos": Vector2(180, 500), "radius": 22.0, "kind": "pillar", "orbit": -0.4},
			{"pos": Vector2(820, 500), "radius": 22.0, "kind": "pillar", "orbit": -0.4},
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
		"description": "Six tall kelp stalks sway in the current. A healing spring bubbles in the middle.",
		"corner_cut": 0.0,
		# Each stalk sways across the current; mirrored stalks sway opposite ways.
		# Six, not eight, and none on the start diagonal or in the middle: eight stalks walled
		# big critters into pockets and fights ran ~50% long (tools/map_length.gd).
		"obstacles": [
			{"pos": Vector2(210, 210), "radius": 34.0, "kind": "pillar", "slide": Vector2(20, -20), "period": 3.6},
			{"pos": Vector2(790, 790), "radius": 34.0, "kind": "pillar", "slide": Vector2(-20, 20), "period": 3.6},
			{"pos": Vector2(500, 210), "radius": 34.0, "kind": "pillar", "slide": Vector2(30, 0), "period": 3.2},
			{"pos": Vector2(500, 790), "radius": 34.0, "kind": "pillar", "slide": Vector2(-30, 0), "period": 3.2},
			{"pos": Vector2(210, 500), "radius": 34.0, "kind": "pillar", "slide": Vector2(0, 30), "period": 3.2},
			{"pos": Vector2(790, 500), "radius": 34.0, "kind": "pillar", "slide": Vector2(0, -30), "period": 3.2},
		],
		"cores": [{"pos": Vector2(500, 500), "radius": 40.0, "kind": "heal"}],
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
		"description": "Ride the belts into the sunset, or cut through the middle for the power core. Neon pylons slide across the grid.",
		"corner_cut": 0.0,
		"sides": {"n": 10, "inradius": 470.0, "rot": 18.0},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(300, 500), "radius": 26.0, "kind": "pillar", "slide": Vector2(0, 110), "period": 5.0},
			{"pos": Vector2(700, 500), "radius": 26.0, "kind": "pillar", "slide": Vector2(0, -110), "period": 5.0},
		],
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
		"description": "A wide desert pass with cacti and a sinkhole of quicksand in the middle.",
		"corner_cut": 0.0,
		"sides": {"n": 2, "inradius": 330.0, "rot": 45.0},
		"obstacles": [
			{"pos": Vector2(380, 380), "radius": 30.0, "kind": "spike"},
			{"pos": Vector2(620, 620), "radius": 30.0, "kind": "spike"},
		],
		"floors": [{"kind": "goo", "pos": Vector2(500, 500), "radius": 100.0, "slow": 0.35}],
		# A sinkhole: a small well under the quicksand.
		"wells": [{"pos": Vector2(500, 500), "reach": 120.0, "accel": 500.0, "core": 20.0}],
	},
	"oasis": {
		"display_name": "Desert Oasis",
		"description": "A round oasis. Wading through the pool slows you, but springs by the palms heal.",
		"corner_cut": 0.0,
		"sides": {"n": 16, "inradius": 470.0, "rot": 11.25},
		"start_scale": 0.8,
		"obstacles": [
			{"pos": Vector2(500, 290), "radius": 32.0, "kind": "pillar"},
			{"pos": Vector2(500, 710), "radius": 32.0, "kind": "pillar"},
		],
		"floors": [{"kind": "goo", "pos": Vector2(500, 500), "radius": 125.0, "slow": 0.25}],
		"cores": [
			{"pos": Vector2(290, 500), "radius": 36.0, "kind": "heal"},
			{"pos": Vector2(710, 500), "radius": 36.0, "kind": "heal"},
		],
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
		"description": "Four haunted mirrors: roll into one, come out of the one across the hall. Ghostly wards shield you.",
		"corner_cut": 0.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 48.0, "kind": "pillar"}],
		"cores": [
			{"pos": Vector2(320, 320), "radius": 36.0, "kind": "shield"},
			{"pos": Vector2(680, 680), "radius": 36.0, "kind": "shield"},
		],
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
		"description": "Belts sweep the track into the two empty corners and a turnstile spins in the middle.",
		# The belts meet in the empty corners: running round in a loop they
		# carried both balls the same way and fights ran ~40% long (tools/map_length.gd).
		"corner_cut": 180.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 30.0, "kind": "pillar", "bar": 150.0, "angle": 45.0, "orbit": -0.7}],
		"floors": [
			{"kind": "conveyor", "rect": Rect2(270, 120, 460, 90), "dir": Vector2.LEFT, "accel": 450.0},
			{"kind": "conveyor", "rect": Rect2(270, 790, 460, 90), "dir": Vector2.RIGHT, "accel": 450.0},
			{"kind": "conveyor", "rect": Rect2(120, 270, 90, 460), "dir": Vector2.UP, "accel": 450.0},
			{"kind": "conveyor", "rect": Rect2(790, 270, 90, 460), "dir": Vector2.DOWN, "accel": 450.0},
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
	"windmill": {
		"display_name": "Windmill Hill",
		"description": "A giant sail sweeps the whole middle. Grab a heal on the edges.",
		"corner_cut": 0.0,
		"obstacles": [{"pos": Vector2(500, 500), "radius": 28.0, "kind": "pillar", "bar": 240.0, "angle": 0.0, "orbit": 0.6}],
		"cores": [
			{"pos": Vector2(140, 500), "radius": 36.0, "kind": "heal"},
			{"pos": Vector2(860, 500), "radius": 36.0, "kind": "heal"},
		],
	},
	"pistons": {
		"display_name": "Piston Press",
		"description": "Two steel pistons slide across the floor. A heal waits between them.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(500, 340), "radius": 30.0, "kind": "pillar", "bar": 120.0, "angle": 0.0, "slide": Vector2(160, 0), "period": 6.0},
			{"pos": Vector2(500, 660), "radius": 30.0, "kind": "pillar", "bar": 120.0, "angle": 0.0, "slide": Vector2(-160, 0), "period": 6.0},
		],
		"cores": [
			{"pos": Vector2(500, 500), "radius": 40.0, "kind": "heal"},
		],
	},
	"cogs": {
		"display_name": "Cog Works",
		"description": "Two turnstiles spin in the empty corners round a power core.",
		"corner_cut": 0.0,
		"obstacles": [
			{"pos": Vector2(300, 300), "radius": 28.0, "kind": "pillar", "bar": 100.0, "angle": 0.0, "orbit": 0.9},
			{"pos": Vector2(700, 700), "radius": 28.0, "kind": "pillar", "bar": 100.0, "angle": 0.0, "orbit": 0.9},
		],
		"cores": [
			{"pos": Vector2(500, 500), "radius": 44.0},
			{"pos": Vector2(380, 620), "radius": 36.0, "kind": "heal"},
			{"pos": Vector2(620, 380), "radius": 36.0, "kind": "heal"},
		],
	},
}

## Arenas offered in the in-game picker and checked by the balance sim.
const PLAYABLE := ["square", "rink", "pillars", "bumpers", "wells", "spikes", "frost", "magma", "arcade",
	"starfall", "factory", "orbit", "hive", "horizon", "pinball", "reef", "glitch", "inferno", "thorn",
	"candy", "syrup", "temple", "ruins", "nebula", "asteroid", "trench", "kelp", "storm", "cloud",
	"sunset", "alley", "dunes", "oasis", "graveyard", "manor", "toybox", "speedway", "arcane", "prism",
	"windmill", "pistons", "cogs"]

## Maps a random fight can land on: every playable map but The Box, which
## stays as the plain baseline (tutorial, balance runs, picked by hand).
const RANDOM_POOL := ["rink", "pillars", "bumpers", "wells", "spikes", "frost", "magma", "arcade",
	"starfall", "factory", "orbit", "hive", "horizon", "pinball", "reef", "glitch", "inferno", "thorn",
	"candy", "syrup", "temple", "ruins", "nebula", "asteroid", "trench", "kelp", "storm", "cloud",
	"sunset", "alley", "dunes", "oasis", "graveyard", "manor", "toybox", "speedway", "arcane", "prism",
	"windmill", "pistons", "cogs"]


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
	return RANDOM_POOL[posmod(("arena:%d" % seed_value).hash(), RANDOM_POOL.size())]


## `obstacles` with each bar turned into a row of overlapping circles (at
## most `radius` apart) sharing a `bar` group id, so every obstacle check in
## the sim (bounces, shots, beams, open spots) treats it like pillars.
static func expand_bars(obstacles: Array) -> Array:
	var out := []
	for i in obstacles.size():
		var o: Dictionary = obstacles[i]
		if not o.has("bar"):
			out.append(o)
			continue
		var dir := DMath.rotated(Vector2.RIGHT, deg_to_rad(o.get("angle", 0.0)))
		var n := int(ceil(o.bar * 2.0 / o.radius)) + 1
		for j in n:
			var c: Dictionary = o.duplicate()
			c.erase("angle")
			c.pos = o.pos + dir * (-o.bar + o.bar * 2.0 * j / (n - 1))
			c.bar = i
			if o.has("orbit") and not o.has("pivot"):
				c.pivot = o.pos
			out.append(c)
	return out


static func get_def(id: String) -> Dictionary:
	if BOSS_ARENAS.has(id):
		return BOSS_ARENAS[id]
	assert(DEFS.has(id), "Unknown arena id: %s" % id)
	return DEFS[id]
