## Course-only Plunge sections: each course's own opener and six sections
## round its machine (sim/plunge_course.gd), so most of every course is its
## own (Newms 2026-11-01: "75% minimum for uniqueness"). Each is built from
## the course's parts (ramps, pegs, floors, wells, movers) by build(), at
## `y0`, returning its height; PlungeCourse mirrors it on a coin flip.
##
## The same course rules hold: a racer-wide gap between still parts, flat
## parts tilted or moving, moving parts under PlungeCourse.MOVER_SPEED.
##
## Only +, *, sqrt, DMath and sim/rng.gd, so every platform agrees.
extends RefCounted

const DMath := preload("res://sim/dmath.gd")

const W := 1000.0
const SET := {"thick": 16.0, "look": "set"}

## Every own section: true when it moves (the course test keeps each course
## about half moving).
const MOVING := {
	# Gumdrop Drop
	"gd_chute": false, "gd_canes": false, "gd_hills": false, "gd_wafers": false,
	"gd_lollipops": true, "gd_taffy": true, "gd_licorice": true,
	# Honey Chute
	"hn_hive": true, "hn_comb": false, "hn_pollen": false, "hn_jars": false,
	"hn_swarm": true, "hn_smoker": true, "hn_spoons": true,
	# Sunstone Steps
	"ss_steps": false, "ss_plates": false, "ss_sandpits": false, "ss_altars": false,
	"ss_boulder": true, "ss_darts": true, "ss_mirrors": true,
	# Vine Ruins
	"vn_canopy": false, "vn_arches": false, "vn_waterfall": false, "vn_roots": false,
	"vn_logroll": true, "vn_flytraps": true, "vn_trapeze": true,
	# Nebula Fall
	"nb_warp": false, "nb_stars": false, "nb_wormholes": false, "nb_saturn": false,
	"nb_asteroids": true, "nb_comets": true, "nb_pulsar": true,
}

## Own sections whose still parts meet the walls (no wall half-bumpers).
const WALLED := ["gd_chute", "gd_wafers", "hn_hive", "hn_pollen", "ss_steps", "ss_boulder", "ss_darts",
	"vn_waterfall", "vn_roots", "vn_logroll", "nb_warp"]


## Adds own section `kind` to course `c` at `y0`; returns its height.
static func build(c, crng, kind: String, y0: float) -> float:
	var tint: String = c.info.get("tint", "")
	match kind:
		# --- Gumdrop Drop ------------------------------------------------------------
		"gd_chute":
			# A gumball dispenser: the hopper drops the field on a big bumper
			# that splits it onto two candy canes curling out to the walls.
			c._hopper(y0 + 20.0, 500.0, 170.0, 200.0, SET)
			c._peg(500.0, y0 + 340.0, 46.0, true)
			for s in [-1.0, 1.0]:
				c._curve(Vector2(500.0 + s * 130.0, y0 + 430.0), Vector2(500.0 + s * 260.0, y0 + 440.0), Vector2(500.0 + s * 380.0, y0 + 560.0), {"look": "cane"})
			return 640.0
		"gd_canes":
			# Candy canes standing in the shaft, crooks curling alternate
			# ways: land on a crook and roll off its tip or down its stick.
			var rows := [[250.0, 750.0], [500.0], [250.0, 750.0]]
			for row in rows.size():
				var y := y0 + 80.0 + row * 280.0
				for j in rows[row].size():
					var x: float = rows[row][j]
					var s := 1.0 if (row + j) % 2 == 0 else -1.0
					if rows[row].size() == 2:
						s = 1.0 if j == 0 else -1.0
					c._seg(Vector2(x, y + 60.0), Vector2(x, y + 230.0), SET)
					c._curve(Vector2(x, y + 60.0), Vector2(x + s * 50.0, y - 50.0), Vector2(x + s * 110.0, y + 50.0), SET, 6)
			return 3 * 280.0 + 60.0
		"gd_hills":
			# Gumdrop hills: round domes in staggered rows, a sugar bumper
			# between each pair.
			for row in 4:
				var y := y0 + 120.0 + row * 200.0
				var xs := [250.0, 750.0] if row % 2 == 0 else [500.0]
				for x in xs:
					c._curve(Vector2(x - 120.0, y + 70.0), Vector2(x, y - 70.0), Vector2(x + 120.0, y + 70.0), SET, 8)
				if row % 2 == 1:
					for x in [150.0, 850.0]:
						c._peg(x, y + 10.0, 26.0, true)
			c._pickup(crng, Vector2(500.0, y0 + 130.0))
			return 4 * 200.0 + 100.0
		"gd_wafers":
			# Wafer shelves: two from the walls tipping to a middle gap, a
			# peaked one, then two more.
			for k in 2:
				var y := y0 + 80.0 + k * 440.0
				c._seg(Vector2(0.0, y), Vector2(410.0, y + 120.0), SET)
				c._seg(Vector2(W, y), Vector2(590.0, y + 120.0), SET)
			var py := y0 + 330.0
			c._seg(Vector2(250.0, py + 90.0), Vector2(500.0, py), SET)
			c._seg(Vector2(500.0, py), Vector2(750.0, py + 90.0), SET)
			return 440.0 + 260.0
		"gd_lollipops":
			# Lollipops: a candy bumper with four spokes turning round it,
			# two then one, opposite ways.
			var spin: float = c._jit(crng, 1.0, 1.2)
			var at := [Vector2(270.0, 210.0), Vector2(730.0, 210.0), Vector2(500.0, 620.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				var s: float = spin if k != 1 else -spin
				c.movers.append({"pos": hub, "radius": 50.0, "kind": "bumper"})
				var turn: float = c._jit(crng, 0.0, 90.0)
				for b in 4:
					var a := deg_to_rad(turn + b * 90.0)
					var d := Vector2(DMath.cos(a), DMath.sin(a))
					c._rod(hub + d * 70.0, hub + d * 175.0, 15.0, c._turning(hub, s))
			return 840.0
		"gd_taffy":
			# A taffy puller: one long hooked arm turning slowly, two little
			# twisters under it.
			var hub := Vector2(500.0, y0 + 320.0)
			var a: float = c._jit(crng, 0.0, TAU)
			var d := Vector2(DMath.cos(a), DMath.sin(a))
			var n := Vector2(-d.y, d.x)
			c._chain([hub - d * 270.0 + n * 90.0, hub - d * 270.0, hub + d * 270.0, hub + d * 270.0 - n * 90.0], 16.0, c._turning(hub, 0.75))
			c.movers.append({"pos": hub, "radius": 40.0, "kind": "pillar", "tint": tint})
			for x in [140.0, 860.0]:
				var cc := Vector2(x, y0 + 740.0)
				c._rod_at(cc, 85.0, c._jit(crng, 0.0, 180.0), 15.0, c._turning(cc, 1.6 if x < 500.0 else -1.6))
			return 880.0
		"gd_licorice":
			# Licorice ropes hanging from the top, swaying as one wave; a
			# shorter row below, the other way.
			var period: float = c._jit(crng, 2.8, 3.2)
			for row in 2:
				var xs := [200.0, 400.0, 600.0, 800.0] if row == 0 else [300.0, 500.0, 700.0]
				var top := y0 + 40.0 + row * 400.0
				var long := 300.0 if row == 0 else 260.0
				for k in xs.size():
					var pivot := Vector2(xs[k], top)
					c._rod(pivot, pivot + Vector2(0.0, long), 14.0, c._swinging(pivot, 0.3 if row == 0 else -0.3, period, k * 0.12))
			return 400.0 + 260.0 + 100.0
		# --- Honey Chute -------------------------------------------------------------
		"hn_hive":
			# The hive door: the hopper drops the field into a turning
			# hexagon with one open side; ride round and drop out of it.
			c._hopper(y0, 500.0, 180.0, 190.0, SET)
			var hub := Vector2(500.0, y0 + 470.0)
			var start: float = c._jit(crng, 0.0, TAU)
			for k in 5:
				var a0 := start + k * TAU / 6.0
				var a1 := a0 + TAU / 6.0
				c._rod(hub + Vector2(DMath.cos(a0), DMath.sin(a0)) * 170.0, hub + Vector2(DMath.cos(a1), DMath.sin(a1)) * 170.0, 16.0, c._turning(hub, 0.6))
			return 700.0
		"hn_comb":
			# Honeycomb: closed hexagon cells racers glance off, honey goo
			# dripping down the walls.
			for row in 3:
				var y := y0 + 130.0 + row * 250.0
				var xs := [250.0, 750.0] if row % 2 == 0 else [500.0]
				for x in xs:
					var hub := Vector2(x, y)
					for k in 6:
						var a0 := deg_to_rad(30.0 + k * 60.0)
						var a1 := deg_to_rad(90.0 + k * 60.0)
						c._seg(hub + Vector2(DMath.cos(a0), DMath.sin(a0)) * 90.0, hub + Vector2(DMath.cos(a1), DMath.sin(a1)) * 90.0, SET)
			for k in 2:
				c.floors.append({"kind": "goo", "pos": Vector2(90.0 if k == 0 else 910.0, y0 + 260.0 + k * 250.0), "radius": 80.0, "slow": 0.0})
			return 3 * 250.0 + 40.0
		"hn_pollen":
			# Flowers: a leaf rolls racers onto a flower pad that flings them
			# up and across to the next one.
			for k in 3:
				var y := y0 + 210.0 + k * 270.0
				var s := 1.0 if k % 2 == 0 else -1.0
				var px := 500.0 - s * 290.0
				c._seg(Vector2(500.0 + s * 140.0, y - 170.0), Vector2(500.0 - s * 160.0, y - 70.0), SET)
				c.floors.append({"kind": "launch", "pos": Vector2(px, y), "radius": 80.0, "kick": Vector2(s * 560.0, -200.0)})
			return 3 * 270.0 + 160.0
		"hn_jars":
			# Honey jars: racers drop in, wade through the honey and out of
			# the hole in the bottom.
			var rows := [[[280.0, 260.0], [720.0, 260.0]], [[500.0, 300.0]]]
			for row in rows.size():
				var y := y0 + 80.0 + row * 360.0
				for jar in rows[row]:
					var x: float = jar[0]
					var half: float = jar[1] / 2.0
					c._seg(Vector2(x - half, y), Vector2(x - 50.0, y + 210.0), SET)
					c._seg(Vector2(x + half, y), Vector2(x + 50.0, y + 210.0), SET)
					c.floors.append({"kind": "goo", "pos": Vector2(x, y + 130.0), "radius": 75.0, "slow": 0.0})
			c._pickup(crng, Vector2(500.0, y0 + 200.0), "heal")
			return 360.0 + 320.0
		"hn_swarm":
			# Bee swarms: rings of little bees circling three queens.
			var at := [Vector2(290.0, 200.0), Vector2(710.0, 420.0), Vector2(290.0, 640.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				c.movers.append({"pos": hub, "radius": 32.0, "kind": "bumper"})
				var s := 1.5 if k % 2 == 0 else -1.5
				var start: float = c._jit(crng, 0.0, TAU)
				for b in 5:
					var a := start + b * TAU / 5.0
					c.movers.append({"pos": hub + Vector2(DMath.cos(a), DMath.sin(a)) * 105.0, "radius": 20.0, "kind": "pillar",
						"pivot": hub, "orbit": s, "tint": "ffd23a"})
			return 820.0
		"hn_smoker":
			# The beekeeper's smoker: gusts puffing back and forth across the
			# shaft, a bee bumper darting between each.
			var period: float = c._jit(crng, 3.8, 4.2)
			for k in 3:
				var y := y0 + 90.0 + k * 220.0
				c._wind(Rect2(0.0, y, W, 80.0), Vector2.RIGHT if k % 2 == 0 else Vector2.LEFT, 620.0, 1.6 + k * 0.3)
				c.movers.append({"pos": Vector2(500.0, y + 150.0), "radius": 36.0, "kind": "bumper",
					"slide": Vector2(200.0 if k % 2 == 0 else -200.0, 0.0), "period": period, "phase": k * 0.2})
			return 3 * 220.0 + 80.0
		"hn_spoons":
			# Honey spoons swinging on long handles: land on a spoon and get
			# flung off the top of the swing.
			var period: float = c._jit(crng, 3.0, 3.4)
			var at := [Vector2(300.0, 40.0), Vector2(700.0, 40.0), Vector2(500.0, 470.0)]
			for k in at.size():
				var pivot := Vector2(at[k].x, y0 + at[k].y)
				var move: Dictionary = c._swinging(pivot, 0.5 if k != 1 else -0.5, period, k * 0.33)
				var tip := pivot + Vector2(0.0, 250.0)
				c._rod(pivot, tip, 12.0, move)
				c._rod(tip + Vector2(-75.0, 0.0), tip + Vector2(75.0, 0.0), 15.0, move)
			return 470.0 + 330.0
		# --- Sunstone Steps ----------------------------------------------------------
		"ss_steps":
			# Temple steps: a stepped pyramid racers tumble down both ways,
			# then side stairs back to the middle.
			for s in [-1.0, 1.0]:
				var pts := [Vector2(500.0, y0 + 90.0), Vector2(500.0 + s * 100.0, y0 + 130.0), Vector2(500.0 + s * 100.0, y0 + 190.0),
					Vector2(500.0 + s * 230.0, y0 + 220.0), Vector2(500.0 + s * 230.0, y0 + 280.0), Vector2(500.0 + s * 360.0, y0 + 310.0)]
				for k in pts.size() - 1:
					c._seg(pts[k], pts[k + 1], SET)
				var low := [Vector2(500.0 + s * 500.0, y0 + 430.0), Vector2(500.0 + s * 380.0, y0 + 460.0), Vector2(500.0 + s * 380.0, y0 + 520.0),
					Vector2(500.0 + s * 250.0, y0 + 550.0)]
				for k in low.size() - 1:
					c._seg(low[k], low[k + 1], SET)
			return 640.0
		"ss_plates":
			# Pressure plates: stone trays drop racers onto plates that shoot
			# them sideways into the next tray.
			for k in 3:
				var y := y0 + 60.0 + k * 260.0
				var x := 300.0 if k % 2 == 0 else 700.0
				var s := 1.0 if k % 2 == 0 else -1.0
				c._seg(Vector2(x - 190.0, y), Vector2(x - 55.0, y + 140.0), SET)
				c._seg(Vector2(x + 190.0, y), Vector2(x + 55.0, y + 140.0), SET)
				c.floors.append({"kind": "launch", "pos": Vector2(x, y + 230.0), "radius": 60.0, "kick": Vector2(s * 520.0, -380.0)})
			return 3 * 260.0 + 220.0
		"ss_sandpits":
			# Altar blocks tipped over sand pits, and a hidden passage in the
			# floor that drops a lucky racer past the lot.
			var blocks := [[250.0, 220.0, 12.0], [750.0, 220.0, -12.0], [500.0, 500.0, 12.0]]
			for b in blocks:
				var hub := Vector2(b[0], y0 + b[1])
				var pts := []
				for q in 4:
					var a := deg_to_rad(b[2] + 45.0 + q * 90.0)
					pts.append(hub + Vector2(DMath.cos(a), DMath.sin(a)) * 105.0)
				for q in 4:
					c._seg(pts[q], pts[(q + 1) % 4], SET)
			for f in [[500.0, 230.0, 100.0], [190.0, 520.0, 90.0], [810.0, 520.0, 90.0]]:
				c.floors.append({"kind": "goo", "pos": Vector2(f[0], y0 + f[1]), "radius": f[2], "slow": 0.0})
			c._portal(Vector2(500.0, y0 + 90.0), Vector2(500.0, y0 + 700.0))
			c._pickup(crng, Vector2(500.0, y0 + 330.0))
			return 780.0
		"ss_altars":
			# Sun altars: two great stone bowls with a sun gem in each, the
			# floor of each bowl split down the middle.
			for k in 2:
				var y := y0 + 80.0 + k * 380.0
				var x := 330.0 if k == 0 else 670.0
				c._curve(Vector2(x - 250.0, y), Vector2(x - 230.0, y + 190.0), Vector2(x - 60.0, y + 250.0), SET, 6)
				c._curve(Vector2(x + 250.0, y), Vector2(x + 230.0, y + 190.0), Vector2(x + 60.0, y + 250.0), SET, 6)
				c._peg(x, y + 120.0, 30.0, true)
			return 380.0 + 340.0
		"ss_boulder":
			# Rolling boulders: a stone ball rolls back and forth along each
			# ledge, bulldozing racers to the gap.
			var period: float = c._jit(crng, 6.6, 7.0)
			for k in 2:
				var y := y0 + 120.0 + k * 370.0
				c._seg(Vector2(0.0, y + 140.0), Vector2(410.0, y + 190.0), SET)
				c._seg(Vector2(W, y + 140.0), Vector2(590.0, y + 190.0), SET)
				c.movers.append({"pos": Vector2(500.0, y + 20.0), "radius": 90.0, "kind": "pillar", "tint": "c7a26a",
					"slide": Vector2(320.0 if k == 0 else -320.0, 0.0), "period": period, "phase": k * 0.5})
			return 370.0 + 380.0
		"ss_darts":
			# Dart traps: stone darts shooting out of alternate walls, thorn
			# posts snapping out in the middle.
			var period: float = c._jit(crng, 4.4, 4.8)
			for k in 5:
				var y := y0 + 80.0 + k * 140.0
				var left := k % 2 == 0
				var base := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._rod(Vector2(base - s * 60.0, y), Vector2(base + s * 140.0, y), 14.0, c._sliding(Vector2(s * 220.0, 0.0), period, k * 0.25))
			for y in [y0 + 220.0, y0 + 500.0]:
				c.movers.append({"pos": Vector2(500.0, y), "radius": 26.0, "kind": "spike", "retract": 1.5})
			return 5 * 140.0 + 80.0
		"ss_mirrors":
			# Sun mirrors: slabs that turn a quarter turn and back, shutting
			# and opening the way down in turn.
			var period: float = c._jit(crng, 2.8, 3.2)
			for row in 3:
				var y := y0 + 130.0 + row * 260.0
				var xs := [250.0, 750.0] if row % 2 == 0 else [500.0]
				for j in xs.size():
					var hub := Vector2(xs[j], y)
					c._rod_at(hub, 140.0, 45.0, 16.0, c._swinging(hub, PI / 4.0, period, row * 0.25 + j * 0.5))
			return 3 * 260.0 + 60.0
		# --- Vine Ruins --------------------------------------------------------------
		"vn_canopy":
			# The canopy: leaves tipped this way and that spread the field
			# out of the gate.
			var rows := [[200.0, 500.0, 800.0], [350.0, 650.0], [200.0, 500.0, 800.0]]
			for row in rows.size():
				var y := y0 + 60.0 + row * 170.0
				for j in rows[row].size():
					var x: float = rows[row][j]
					var tilt := 20.0 if (row + j) % 2 == 0 else -20.0
					var d := Vector2(DMath.cos(deg_to_rad(tilt)), DMath.sin(deg_to_rad(tilt))) * 75.0
					c._curve(Vector2(x, y) - d, Vector2(x, y + 30.0), Vector2(x, y) + d, SET, 4)
			return 3 * 170.0 + 60.0
		"vn_arches":
			# Ruined arches, cracked at the top: roll down the outside or drop
			# through the crack and out between the legs.
			var rows := [[280.0, 720.0], [500.0]]
			for row in rows.size():
				var y := y0 + 160.0 + row * 330.0
				for x in rows[row]:
					for s in [-1.0, 1.0]:
						c._curve(Vector2(x + s * 170.0, y + 160.0), Vector2(x + s * 170.0, y), Vector2(x + s * 52.0, y - 10.0), SET, 6)
			c._pickup(crng, Vector2(500.0, y0 + 200.0))
			return 330.0 + 360.0
		"vn_waterfall":
			# A waterfall down the middle hurls racers down fast into a pool
			# that holds them; the rock ledges down the sides are slow but dry.
			c._wind(Rect2(390.0, y0 + 20.0, 220.0, 660.0), Vector2.DOWN, 700.0)
			for k in 4:
				var y := y0 + 90.0 + k * 160.0
				var left := k % 2 == 0
				c._seg(Vector2(0.0 if left else W, y), Vector2(290.0 if left else W - 290.0, y + 90.0), SET)
			c.floors.append({"kind": "goo", "pos": Vector2(500.0, y0 + 760.0), "radius": 120.0, "slow": 0.0})
			return 860.0
		"vn_roots":
			# A root tangle bending in from both walls at odd angles.
			c._curve(Vector2(0.0, y0 + 60.0), Vector2(300.0, y0 + 60.0), Vector2(520.0, y0 + 220.0), SET)
			c._curve(Vector2(W, y0 + 230.0), Vector2(780.0, y0 + 280.0), Vector2(620.0, y0 + 450.0), SET)
			c._curve(Vector2(0.0, y0 + 430.0), Vector2(220.0, y0 + 560.0), Vector2(440.0, y0 + 560.0), SET)
			c._curve(Vector2(W, y0 + 600.0), Vector2(820.0, y0 + 700.0), Vector2(610.0, y0 + 760.0), SET)
			return 860.0
		"vn_logroll":
			# Log rolls: logs bowling up and down over the slopes, knocking
			# whoever drops onto them.
			var period: float = c._jit(crng, 6.4, 6.8)
			for k in 2:
				var y := y0 + 100.0 + k * 360.0
				var left := k % 2 == 0
				var a := Vector2(0.0 if left else W, y)
				var b := Vector2(760.0 if left else W - 760.0, y + 200.0)
				c._seg(a, b, SET)
				var along := (b - a).normalized()
				var mid := a.lerp(b, 0.5) + Vector2(along.y, -along.x) * (1.0 if left else -1.0) * 130.0
				c._rod(mid - along * 50.0, mid + along * 50.0, 30.0, c._sliding(along * 260.0, period, k * 0.5))
			return 360.0 + 360.0
		"vn_flytraps":
			# Snapping flytraps: jaws snapping shut over the hole between them.
			var period: float = c._jit(crng, 2.2, 2.6)
			var at := [Vector2(260.0, 260.0), Vector2(740.0, 260.0), Vector2(500.0, 600.0)]
			for k in at.size():
				var base := Vector2(at[k].x, y0 + at[k].y)
				for s in [-1.0, 1.0]:
					var hinge := base + Vector2(s * 60.0, 0.0)
					var a := deg_to_rad(-90.0 + s * 40.0)
					c._rod(hinge, hinge + Vector2(DMath.cos(a), DMath.sin(a)) * 160.0, 14.0, c._swinging(hinge, -s * 0.4, period, k * 0.3))
			return 760.0
		"vn_trapeze":
			# Vine trapezes: swinging bars that catch racers and fling them
			# off the end of the swing.
			var period: float = c._jit(crng, 2.8, 3.2)
			var at := [Vector2(250.0, 40.0), Vector2(750.0, 40.0), Vector2(500.0, 400.0)]
			for k in at.size():
				var pivot := Vector2(at[k].x, y0 + at[k].y)
				var move: Dictionary = c._swinging(pivot, 0.6 if k != 1 else -0.6, period, k * 0.3)
				var tip := pivot + Vector2(0.0, 220.0)
				c._rod(pivot, tip, 10.0, move)
				c._rod(tip - Vector2(80.0, 0.0), tip + Vector2(80.0, 0.0), 15.0, move)
			return 400.0 + 340.0
		# --- Nebula Fall -------------------------------------------------------------
		"nb_warp":
			# The warp gate: two mouths, each a portal that throws its racers
			# to the far side.
			var y := y0 + 30.0
			c._seg(Vector2(0.0, y), Vector2(240.0, y + 180.0), SET)
			c._seg(Vector2(W, y), Vector2(760.0, y + 180.0), SET)
			c._seg(Vector2(360.0, y + 180.0), Vector2(500.0, y + 60.0), SET)
			c._seg(Vector2(500.0, y + 60.0), Vector2(640.0, y + 180.0), SET)
			c._portal(Vector2(300.0, y + 290.0), Vector2(760.0, y + 480.0))
			c._portal(Vector2(700.0, y + 290.0), Vector2(240.0, y + 480.0))
			return 620.0
		"nb_stars":
			# Constellations: star bumpers joined by thin star lines racers
			# slide along from star to star.
			var shapes := [[Vector2(150.0, 90.0), Vector2(400.0, 190.0), Vector2(330.0, 400.0), Vector2(560.0, 470.0)],
				[Vector2(860.0, 260.0), Vector2(700.0, 330.0), Vector2(800.0, 560.0), Vector2(560.0, 740.0)]]
			for pts in shapes:
				for k in pts.size():
					c._peg(pts[k].x, y0 + pts[k].y, 26.0, true)
				for k in pts.size() - 1:
					var a: Vector2 = pts[k] + Vector2(0.0, y0)
					var b: Vector2 = pts[k + 1] + Vector2(0.0, y0)
					var d := (b - a).normalized()
					# Short of the next star, so it can't bat a racer back up the line.
					c._seg(a + d * 60.0, a.lerp(b, 0.6), {"look": "crystal"})
			return 840.0
		"nb_wormholes":
			# Wormholes: a roof sends racers to three portals that each throw
			# them across and down; nebula clouds slow the rest.
			c._seg(Vector2(500.0, y0 + 80.0), Vector2(330.0, y0 + 180.0), SET)
			c._seg(Vector2(500.0, y0 + 80.0), Vector2(670.0, y0 + 180.0), SET)
			c._portal(Vector2(190.0, y0 + 260.0), Vector2(780.0, y0 + 560.0))
			c._portal(Vector2(810.0, y0 + 260.0), Vector2(220.0, y0 + 560.0))
			c._portal(Vector2(500.0, y0 + 400.0), Vector2(500.0, y0 + 740.0))
			for x in [300.0, 700.0]:
				c.floors.append({"kind": "goo", "pos": Vector2(x, y0 + 420.0), "radius": 90.0, "slow": 0.0})
			c._pickup(crng, Vector2(500.0, y0 + 250.0))
			return 820.0
		"nb_saturn":
			# A ringed planet: racers land on the planet or its ring and roll
			# off.
			var hub := Vector2(500.0, y0 + 330.0)
			var pts := []
			for q in 8:
				var a := deg_to_rad(22.5 + q * 45.0)
				pts.append(hub + Vector2(DMath.cos(a), DMath.sin(a)) * 140.0)
			for q in 8:
				c._seg(pts[q], pts[(q + 1) % 8], SET)
			c._seg(Vector2(270.0, y0 + 300.0), Vector2(90.0, y0 + 380.0), {"look": "crystal"})
			c._seg(Vector2(730.0, y0 + 300.0), Vector2(910.0, y0 + 380.0), {"look": "crystal"})
			for x in [150.0, 850.0]:
				c._peg(x, y0 + 620.0, 32.0, true)
			return 740.0
		"nb_asteroids":
			# An asteroid field: rocks drifting across at their own speeds.
			var rocks := [[260.0, 120.0, 40.0, 200.0, 5.0], [720.0, 180.0, 46.0, -220.0, 6.0], [500.0, 330.0, 34.0, 260.0, 5.4],
				[230.0, 470.0, 44.0, -180.0, 6.4], [760.0, 520.0, 38.0, 200.0, 5.2], [500.0, 680.0, 46.0, -240.0, 6.0]]
			for k in rocks.size():
				var r: Array = rocks[k]
				c.movers.append({"pos": Vector2(r[0], y0 + r[1]), "radius": r[2], "kind": "pillar", "tint": tint,
					"slide": Vector2(r[3], 0.0), "period": r[4], "phase": c._jit(crng, 0.0, 1.0)})
			return 800.0
		"nb_comets":
			# Comets: a bright head and a long tail sweeping across the shaft
			# corner to corner.
			var period: float = c._jit(crng, 6.6, 7.0)
			for k in 2:
				var y := y0 + 230.0 + k * 360.0
				var s := 1.0 if k == 0 else -1.0
				var sweep := Vector2(s * 280.0, 120.0)
				var head := Vector2(500.0, y)
				var back := -sweep.normalized() * 240.0
				c._rod(head + back, head, 12.0, c._sliding(sweep, period, k * 0.5))
				c.movers.append({"pos": head, "radius": 34.0, "kind": "bumper", "slide": sweep, "period": period, "phase": k * 0.5})
			return 360.0 + 420.0
		"nb_pulsar":
			# A pulsar: a star that swells and shrinks on a beat, its two
			# beams swinging under it.
			var hub := Vector2(500.0, y0 + 380.0)
			c.movers.append({"pos": hub, "radius": 40.0, "kind": "bumper"})
			c.movers.append({"pos": hub, "radius": 80.0, "kind": "bumper", "blink": 0.8, "blink_at": 0.0})
			var period: float = c._jit(crng, 3.0, 3.4)
			# Only the lower beams: a V of beams over the star would juggle
			# a racer between them and the star for good.
			for deg in [40.0, 140.0]:
				var a := deg_to_rad(deg)
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				c._rod(hub + d * 120.0, hub + d * 300.0, 14.0, c._swinging(hub, 0.4, period, 0.0))
			return 780.0
	push_error("Unknown Plunge section %s" % kind)
	return 0.0
