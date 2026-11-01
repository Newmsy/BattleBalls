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
	# Rock Belt
	"rk_crater": true, "rk_gravel": false, "rk_ledges": false, "rk_geode": false,
	"rk_carts": true, "rk_crusher": true, "rk_drill": true,
	# Kelp Forest
	"kp_bubbles": false, "kp_currents": false, "kp_anchors": false, "kp_seagrass": false,
	"kp_clams": true, "kp_jellies": true, "kp_wreck": true,
	# Deep Trench
	"tr_bell": true, "tr_vents": false, "tr_ribs": false, "tr_pearls": false,
	"tr_angler": true, "tr_sonar": true, "tr_sub": true,
	# Cloud Hop
	"cl_rainbow": false, "cl_pads": false, "cl_ledges": false, "cl_balloons": false,
	"cl_kites": true, "cl_thunder": true, "cl_windmill": true,
	# Storm Front
	"st_drain": true, "st_rods": false, "st_gusts": false, "st_lines": false,
	"st_tornado": true, "st_hail": true, "st_vanes": true,
	# Icicle Run
	"ic_cave": false, "ic_skijump": false, "ic_crevasse": false, "ic_drifts": false,
	"ic_rink": true, "ic_avalanche": true, "ic_gears": true,
	# Crystal Cave
	"cr_geode": true, "cr_lanes": false, "cr_shards": false, "cr_spiral": false,
	"cr_prisms": true, "cr_bridge": true, "cr_orbit": true,
	# Lava Tubes
	"lv_volcano": false, "lv_lavafall": false, "lv_chimneys": false, "lv_crust": false,
	"lv_obsidian": true, "lv_wheel": true, "lv_pumice": true,
	# Sunset Strip
	"su_onramp": false, "su_billboards": false, "su_skyline": false, "su_surf": false,
	"su_signs": true, "su_carwash": true, "su_tolls": true,
	# Glitch Grid
	"gl_boot": true, "gl_lag": false, "gl_copy": false, "gl_circuit": false,
	"gl_firewall": true, "gl_bitflip": true, "gl_cursor": true,
	# Dune Slide
	"dn_hourglass": true, "dn_ridges": false, "dn_pyramid": false, "dn_oasis": false,
	"dn_tumbleweeds": true, "dn_scarabs": true, "dn_caravan": true,
	# Grave Drop
	"gv_gate": true, "gv_headstones": false, "gv_fog": false, "gv_crosses": false,
	"gv_lanterns": true, "gv_bones": true, "gv_bats": true,
	# Haunted Stairs
	"mn_doors": true, "mn_portraits": false, "mn_passage": false, "mn_banister": false,
	"mn_chandelier": true, "mn_furniture": true, "mn_clock": true,
	# Toy Chest
	"ty_chest": true, "ty_marblerun": false, "ty_abc": false, "ty_crayons": false,
	"ty_train": true, "ty_dominoes": true, "ty_jacks": true,
	# Pinball Plunge
	"pb_bumpers": false, "pb_inlanes": false, "pb_slings": false, "pb_lanes": false,
	"pb_pops": true, "pb_targets": true, "pb_multiball": true,
}

## Own sections whose still parts meet the walls (no wall half-bumpers).
const WALLED := ["gd_chute", "gd_wafers", "hn_hive", "hn_pollen", "ss_steps", "ss_boulder", "ss_darts",
	"vn_waterfall", "vn_roots", "vn_logroll", "nb_warp", "rk_crater", "rk_ledges", "rk_drill", "kp_currents",
	"kp_clams", "kp_wreck", "tr_bell", "tr_ribs", "cl_rainbow", "cl_ledges", "st_drain", "st_gusts", "ic_cave",
	"ic_skijump", "ic_crevasse", "ic_drifts", "cr_geode", "lv_volcano", "lv_lavafall", "su_onramp", "su_surf",
	"gl_boot", "gl_lag", "gl_circuit", "gl_firewall", "dn_hourglass", "dn_ridges", "dn_scarabs", "gv_gate", "gv_fog",
	"mn_doors", "mn_banister", "ty_chest", "ty_marblerun", "ty_jacks", "pb_bumpers", "pb_inlanes"]


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
		# --- Rock Belt ---------------------------------------------------------------
		"rk_crater":
			# The crater: the hopper drops the field onto two tipped rock
			# floors sliding together and apart over the crater's hole.
			c._hopper(y0 + 20.0, 500.0, 560.0, 160.0, SET)
			var period: float = c._jit(crng, 4.4, 4.8)
			for s in [-1.0, 1.0]:
				c._rod_at(Vector2(500.0 + s * 200.0, y0 + 320.0), 110.0, s * -12.0, 18.0, c._sliding(Vector2(-s * 100.0, 0.0), period))
			return 480.0
		"rk_gravel":
			# Gravel slides: slopes of loose rocks racers rattle down.
			for k in 3:
				var y := y0 + 70.0 + k * 260.0
				var left := k % 2 == 0
				for j in 12:
					var x := 90.0 + j * 42.0
					c._peg(x if left else W - x, y + j * 26.0, 19.0)
			c._pickup(crng, Vector2(820.0, y0 + 200.0))
			return 3 * 260.0 + 300.0
		"rk_ledges":
			# Rock shelves jutting from alternate walls, racers tumbling off
			# their tips.
			for k in 4:
				var y := y0 + 60.0 + k * 210.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._seg(Vector2(wx, y), Vector2(wx + s * 330.0, y + 150.0), SET)
				c._seg(Vector2(wx + s * 330.0, y + 150.0), Vector2(wx, y + 210.0), SET)
			return 4 * 210.0 + 140.0
		"rk_geode":
			# A great hollow geode, open top and bottom: drop in, rattle
			# round the crystal in the middle and out the bottom.
			var hub := Vector2(500.0, y0 + 330.0)
			var pts := []
			for q in 8:
				var a := deg_to_rad(22.5 + q * 45.0)
				pts.append(hub + Vector2(DMath.cos(a), DMath.sin(a)) * 240.0)
			for q in 8:
				if q == 1 or q == 5: # The bottom and top faces are open.
					continue
				c._seg(pts[q], pts[(q + 1) % 8], SET)
			c._peg(500.0, y0 + 330.0, 30.0, true)
			return 680.0
		"rk_carts":
			# Mining carts racing along: a tipped floor with a back wall at the
			# high end, so racers ride a little way and tip off the front.
			var period: float = c._jit(crng, 5.4, 5.8)
			for k in 3:
				var y := y0 + 120.0 + k * 250.0
				var s := 1.0 if k % 2 == 0 else -1.0
				var at := Vector2(500.0, y)
				var back := at + Vector2(-s * 110.0, -20.0)
				var front := at + Vector2(s * 110.0, 20.0)
				c._chain([back + Vector2(0.0, -70.0), back, front], 15.0, c._sliding(Vector2(s * 260.0, 0.0), period, k * 0.33))
			return 3 * 250.0 + 60.0
		"rk_crusher":
			# Rock crushers: heavy blocks slamming together from both sides
			# and pulling back.
			var period: float = c._jit(crng, 3.6, 4.0)
			for k in 2:
				var y := y0 + 180.0 + k * 340.0
				for s in [-1.0, 1.0]:
					var x: float = 500.0 + s * 250.0
					c._rod(Vector2(x, y - 80.0), Vector2(x, y + 80.0), 40.0, c._sliding(Vector2(-s * 130.0, 0.0), period, k * 0.5))
			return 340.0 + 360.0
		"rk_drill":
			# The drill: a funnel feeds the field into two spinning drill
			# heads, one under the other.
			c._hopper(y0 + 20.0, 500.0, 240.0, 180.0, SET)
			for k in 2:
				var hub := Vector2(500.0, y0 + 400.0 + k * 300.0)
				var s := 1.6 if k == 0 else -1.6
				var turn: float = c._jit(crng, 0.0, 120.0)
				for b in 3:
					var a := deg_to_rad(turn + b * 120.0)
					c._rod(hub, hub + Vector2(DMath.cos(a), DMath.sin(a)) * 150.0, 16.0, c._turning(hub, s))
			return 900.0
		# --- Kelp Forest ------------------------------------------------------------
		"kp_bubbles":
			# Bubble columns rising under the gate slow the drop; coral fans
			# between them spread the field.
			for x in [200.0, 500.0, 800.0]:
				c._wind(Rect2(x - 60.0, y0 + 20.0, 120.0, 460.0), Vector2.UP, 560.0)
			for x in [350.0, 650.0]:
				c._curve(Vector2(x - 80.0, y0 + 250.0), Vector2(x, y0 + 170.0), Vector2(x + 80.0, y0 + 250.0), SET, 4)
			return 560.0
		"kp_currents":
			# Ocean currents: bands sweeping racers left, then right, round
			# starfish bumpers.
			for k in 4:
				var y := y0 + 60.0 + k * 190.0
				c._wind(Rect2(0.0, y, W, 90.0), Vector2.RIGHT if k % 2 == 0 else Vector2.LEFT, 520.0)
				var x := 300.0 if k % 2 == 0 else 700.0
				c._peg(x, y + 150.0, 30.0, true)
			c._pickup(crng, Vector2(500.0, y0 + 300.0))
			return 4 * 190.0 + 80.0
		"kp_anchors":
			# Sunken anchors: land on the ring, slide down the shank and off
			# the arms.
			var rows := [[260.0, 740.0], [500.0]]
			for row in rows.size():
				var y := y0 + 60.0 + row * 330.0
				for x in rows[row]:
					c._peg(x, y, 24.0, true)
					c._seg(Vector2(x, y + 50.0), Vector2(x, y + 190.0), SET)
					c._curve(Vector2(x - 120.0, y + 260.0), Vector2(x, y + 120.0), Vector2(x + 120.0, y + 260.0), SET)
			return 330.0 + 340.0
		"kp_seagrass":
			# Seagrass: tall stems in staggered rows; racers glance off the tips
			# and slip between.
			for row in 4:
				var y := y0 + 60.0 + row * 190.0
				var xs := [200.0, 500.0, 800.0] if row % 2 == 0 else [350.0, 650.0]
				for x in xs:
					c._seg(Vector2(x, y), Vector2(x + 14.0, y + 110.0), SET)
			return 4 * 190.0 + 60.0
		"kp_clams":
			# Giant clams on the walls snapping their shells: racers that
			# drop in get clapped back out.
			var period: float = c._jit(crng, 2.4, 2.8)
			for k in 3:
				var y := y0 + 80.0 + k * 250.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._seg(Vector2(wx, y + 140.0), Vector2(wx + s * 270.0, y + 210.0), SET)
				# The top shell always tips toward the middle, so nothing rolls
				# back into the hinge; it claps down onto the bottom one.
				var hinge := Vector2(wx + s * 40.0, y + 50.0)
				var a := deg_to_rad(12.0)
				c._rod(hinge, hinge + Vector2(DMath.cos(a) * s, DMath.sin(a)) * 240.0, 14.0, c._swinging(hinge, s * 0.15, period, k * 0.3))
			return 3 * 250.0 + 120.0
		"kp_jellies":
			# Jellyfish bobbing up and down, trailing tentacles that sweep
			# racers along with them.
			var period: float = c._jit(crng, 2.4, 2.8)
			var at := [Vector2(260.0, 120.0), Vector2(740.0, 200.0), Vector2(500.0, 430.0), Vector2(260.0, 620.0), Vector2(740.0, 680.0)]
			for k in at.size():
				var top := Vector2(at[k].x, y0 + at[k].y)
				var move: Dictionary = c._sliding(Vector2(0.0, 60.0), period, k * 0.2)
				c.movers.append({"pos": top, "radius": 44.0, "kind": "bumper"}.merged(move))
				for s in [-1.0, 1.0]:
					c._rod(top + Vector2(s * 26.0, 60.0), top + Vector2(s * 40.0, 150.0), 8.0, move)
			return 860.0
		"kp_wreck":
			# A shipwreck: the hull's broken side, and its ship's wheel still
			# turning.
			c._curve(Vector2(0.0, y0 + 80.0), Vector2(260.0, y0 + 300.0), Vector2(560.0, y0 + 330.0), SET)
			var hub := Vector2(620.0, y0 + 560.0)
			var turn: float = c._jit(crng, 0.0, 45.0)
			for b in 4:
				var a := deg_to_rad(turn + b * 45.0)
				c._rod_at(hub, 170.0, rad_to_deg(a), 13.0, c._turning(hub, 1.2))
			c._curve(Vector2(W, y0 + 760.0), Vector2(700.0, y0 + 840.0), Vector2(380.0, y0 + 880.0), SET)
			return 960.0
		# --- Deep Trench ------------------------------------------------------------
		"tr_bell":
			# The diving bell: the field gathers in the bell till its floor
			# plate slides away and drops them.
			c._hopper(y0 + 10.0, 500.0, 200.0, 220.0, SET)
			var period: float = c._jit(crng, 3.8, 4.2)
			c._rod_at(Vector2(500.0, y0 + 330.0), 120.0, 8.0, 16.0, c._sliding(Vector2(200.0, 0.0), period))
			return 480.0
		"tr_vents":
			# Hot vents: jets puffing up and down, each on its own beat.
			for k in 3:
				var x := 200.0 + k * 300.0
				c._wind(Rect2(x - 70.0, y0 + 60.0, 140.0, 560.0), Vector2.UP, 820.0, 1.2 + k * 0.3)
			for x in [350.0, 650.0]:
				c._peg(x, y0 + 340.0, 28.0, true)
			c._pickup(crng, Vector2(500.0, y0 + 200.0))
			return 700.0
		"tr_ribs":
			# A whale's ribcage: ribs curving in from both walls, racers
			# rolling off their tips down the middle.
			for k in 3:
				var y := y0 + 60.0 + k * 250.0
				for s in [-1.0, 1.0]:
					var wx := 0.0 if s > 0.0 else W
					var off := 0.0 if s > 0.0 else 125.0
					c._curve(Vector2(wx, y + off), Vector2(wx + s * 300.0, y + off + 20.0), Vector2(wx + s * 380.0, y + off + 200.0), SET)
			return 3 * 250.0 + 250.0
		"tr_pearls":
			# Pearls and lanterns: big round pearls racers glance off, lit
			# lantern bumpers between.
			var rows := [[260.0, 740.0], [500.0], [260.0, 740.0]]
			for row in rows.size():
				for x in rows[row]:
					c._peg(x, y0 + 120.0 + row * 240.0, 64.0)
			for at in [Vector2(120.0, 360.0), Vector2(880.0, 360.0), Vector2(500.0, 600.0)]:
				c._peg(at.x, y0 + at.y, 26.0, true)
			return 2 * 240.0 + 240.0
		"tr_angler":
			# Anglerfish: a lure dangling from each head swings across the
			# racers; the jaw's teeth snap out under it.
			var period: float = c._jit(crng, 2.8, 3.2)
			for k in 2:
				var left := k == 0
				var head := Vector2(0.0 if left else W, y0 + 160.0 + k * 360.0)
				c.movers.append({"pos": head, "radius": 90.0, "kind": "pillar", "tint": "2a3b70"})
				var pivot := head + Vector2(60.0 if left else -60.0, -60.0)
				var move: Dictionary = c._swinging(pivot, 0.55 if left else -0.55, period, k * 0.5)
				var lure := pivot + Vector2(240.0 if left else -240.0, 120.0)
				c._rod(pivot, lure, 8.0, move)
				c.movers.append({"pos": lure, "radius": 30.0, "kind": "bumper"}.merged(move))
				c.movers.append({"pos": head + Vector2(150.0 if left else -150.0, 110.0), "radius": 24.0, "kind": "spike", "retract": 1.4})
			return 360.0 + 360.0
		"tr_sonar":
			# Sonar sweeps: long arms turning round hubs by the walls.
			for k in 2:
				var left := k == 0
				var hub := Vector2(100.0 if left else W - 100.0, y0 + 300.0 + k * 420.0)
				var a: float = c._jit(crng, 0.0, TAU)
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				c._rod(hub, hub + d * 380.0, 16.0, c._turning(hub, 0.7 if left else -0.7))
				c.movers.append({"pos": hub, "radius": 36.0, "kind": "pillar", "tint": tint})
			return 420.0 + 720.0
		"tr_sub":
			# Submarines cruising across, nose down.
			var period: float = c._jit(crng, 6.4, 6.8)
			for k in 2:
				var y := y0 + 180.0 + k * 360.0
				var s := 1.0 if k == 0 else -1.0
				var move: Dictionary = c._sliding(Vector2(s * 240.0, 0.0), period, k * 0.5)
				c._rod(Vector2(380.0, y - s * 25.0), Vector2(620.0, y + s * 25.0), 44.0, move) # Nose down: nobody rides it.
			return 360.0 + 340.0
		# --- Cloud Hop --------------------------------------------------------------
		"cl_rainbow":
			# A rainbow arching wall to wall: the field rolls off both ends
			# and down the walls onto cloud ledges.
			c._curve(Vector2(110.0, y0 + 330.0), Vector2(500.0, y0 - 60.0), Vector2(890.0, y0 + 330.0), {"look": "cloud"}, 10)
			for s in [-1.0, 1.0]:
				var wx := 0.0 if s > 0.0 else W
				c._curve(Vector2(wx, y0 + 430.0), Vector2(wx + s * 200.0, y0 + 450.0), Vector2(wx + s * 360.0, y0 + 560.0), SET)
			return 640.0
		"cl_pads":
			# Bounce pads: puffy pads throwing racers up and across, from one
			# to the next.
			var at := [Vector2(220.0, 220.0), Vector2(780.0, 440.0), Vector2(220.0, 660.0)]
			for k in at.size():
				var s := 1.0 if k % 2 == 0 else -1.0
				c.floors.append({"kind": "launch", "pos": Vector2(at[k].x, y0 + at[k].y), "radius": 80.0, "kick": Vector2(s * 520.0, -420.0)})
				c._curve(Vector2(500.0 - s * 40.0, y0 + at[k].y - 150.0), Vector2(500.0 - s * 160.0, y0 + at[k].y - 140.0), Vector2(500.0 - s * 200.0, y0 + at[k].y - 60.0), {"look": "cloud"})
			c._pickup(crng, Vector2(500.0, y0 + 560.0))
			return 820.0
		"cl_ledges":
			# Cloud ledges: puffy shelves stepping down from side to side.
			for k in 4:
				var y := y0 + 60.0 + k * 240.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._curve(Vector2(wx, y), Vector2(wx + s * 380.0, y + 20.0), Vector2(wx + s * 560.0, y + 150.0), {"look": "cloud"})
			return 4 * 240.0 + 120.0
		"cl_balloons":
			# Balloon bunches: balloons bobbing on their strings, racers
			# bouncing off the balloons and sliding down the strings.
			for b in [[260.0, 120.0], [740.0, 120.0], [500.0, 420.0]]:
				var x: float = b[0]
				var y: float = y0 + b[1]
				for q in [[-50.0, 0.0], [50.0, 0.0], [0.0, -60.0]]:
					c._peg(x + q[0], y + q[1], 38.0, true)
				c._seg(Vector2(x, y + 60.0), Vector2(x + 30.0, y + 230.0), {"look": "cloud"})
			return 420.0 + 300.0
		"cl_kites":
			# Kites on long strings swinging wide across the sky.
			var period: float = c._jit(crng, 3.2, 3.6)
			var at := [Vector2(260.0, 30.0), Vector2(740.0, 30.0), Vector2(500.0, 420.0)]
			for k in at.size():
				var pivot := Vector2(at[k].x, y0 + at[k].y)
				var move: Dictionary = c._swinging(pivot, 0.5 if k != 1 else -0.5, period, k * 0.3)
				var kite := pivot + Vector2(0.0, 250.0)
				c._rod(pivot, kite - Vector2(0.0, 60.0), 6.0, move)
				c._chain([kite + Vector2(0.0, -60.0), kite + Vector2(50.0, 0.0), kite + Vector2(0.0, 80.0), kite + Vector2(-50.0, 0.0), kite + Vector2(0.0, -60.0)], 12.0, move)
			return 420.0 + 380.0
		"cl_thunder":
			# Thunderclouds drifting over, lightning thorns flashing out under
			# them.
			var period: float = c._jit(crng, 6.0, 6.4)
			for k in 2:
				var y := y0 + 150.0 + k * 380.0
				var s := 1.0 if k == 0 else -1.0
				var move: Dictionary = c._sliding(Vector2(s * 230.0, 0.0), period, k * 0.5)
				for q in [[-70.0, 0.0, 46.0], [0.0, -25.0, 56.0], [70.0, 0.0, 46.0]]:
					c.movers.append({"pos": Vector2(500.0 + q[0], y + q[1]), "radius": q[2], "kind": "pillar", "tint": "7c86a8"}.merged(move))
				c.movers.append({"pos": Vector2(500.0, y + 120.0), "radius": 22.0, "kind": "spike", "retract": 1.2}.merged(move))
			return 380.0 + 360.0
		"cl_windmill":
			# Windmills turning at the edge of the sky, sails sweeping the
			# shaft.
			for k in 2:
				var left := k == 0
				var hub := Vector2(170.0 if left else W - 170.0, y0 + 300.0 + k * 400.0)
				var turn: float = c._jit(crng, 0.0, 90.0)
				for b in 2:
					c._rod_at(hub, 270.0, turn + b * 90.0, 15.0, c._turning(hub, 0.9 if left else -0.9))
				c.movers.append({"pos": hub, "radius": 30.0, "kind": "pillar", "tint": "c9a27a"})
			return 400.0 + 620.0
		# --- Storm Front ------------------------------------------------------------
		"st_drain":
			# The storm drain: the funnel pours the field into a whirlpool,
			# debris circling it.
			c._hopper(y0 + 10.0, 500.0, 240.0, 200.0, SET)
			var hub := Vector2(500.0, y0 + 420.0)
			c.wells.append({"pos": hub, "reach": 200.0, "accel": c.WELL_ACCEL, "core": 40.0})
			var start: float = c._jit(crng, 0.0, TAU)
			for b in 3:
				var a := start + b * TAU / 3.0
				c.movers.append({"pos": hub + Vector2(DMath.cos(a), DMath.sin(a)) * 160.0, "radius": 30.0, "kind": "pillar",
					"pivot": hub, "orbit": 1.5, "tint": tint})
			return 640.0
		"st_rods":
			# Lightning rods: posts whose thorns spark out on their own beats,
			# a goo cloud to wade through.
			var at := [Vector2(250.0, 120.0), Vector2(750.0, 120.0), Vector2(500.0, 300.0), Vector2(250.0, 480.0), Vector2(750.0, 480.0), Vector2(500.0, 660.0)]
			for k in at.size():
				c.movers.append({"pos": Vector2(at[k].x, y0 + at[k].y), "radius": 30.0, "kind": "spike", "retract": 0.8 + 0.2 * (k % 3)})
			c.floors.append({"kind": "goo", "pos": Vector2(500.0, y0 + 480.0), "radius": 100.0, "slow": 0.0})
			c._pickup(crng, Vector2(500.0, y0 + 120.0), "shield")
			return 760.0
		"st_gusts":
			# Gust fronts: winds blowing up and across, flipping side every
			# few seconds, under awnings racers shelter beneath.
			for k in 3:
				var y := y0 + 60.0 + k * 230.0
				var s := 1.0 if k % 2 == 0 else -1.0
				c._wind(Rect2(0.0, y + 90.0, W, 110.0), Vector2(s * 0.9, -0.44), 640.0, 1.8 + k * 0.4)
				var x := 300.0 if k % 2 == 0 else 700.0
				c._seg(Vector2(x - 110.0, y + 50.0), Vector2(x, y), SET)
				c._seg(Vector2(x, y), Vector2(x + 110.0, y + 50.0), SET)
			return 3 * 230.0 + 120.0
		"st_lines":
			# Power lines strung between poles, sagging down across the
			# shaft; the poles kick.
			var poles := [Vector2(110.0, 60.0), Vector2(560.0, 230.0), Vector2(150.0, 440.0), Vector2(620.0, 610.0)]
			for k in poles.size():
				c._peg(poles[k].x, y0 + poles[k].y, 30.0, true)
			for k in poles.size() - 1:
				var a: Vector2 = poles[k] + Vector2(0.0, y0)
				var b: Vector2 = poles[k + 1] + Vector2(0.0, y0)
				var d := (b - a).normalized()
				var from := a + d * 60.0
				var to := a.lerp(b, 0.65)
				c._curve(from, from.lerp(to, 0.5) + Vector2(0.0, 30.0), to, {"look": "pipe"}, 6)
			for x in [880.0]:
				c._peg(x, y0 + 360.0, 30.0, true)
			return 760.0
		"st_tornado":
			# A tornado: debris whirling round a rising core, wider at the
			# top.
			c._wind(Rect2(440.0, y0 + 60.0, 120.0, 700.0), Vector2.UP, 520.0)
			for row in 4:
				var y := y0 + 140.0 + row * 170.0
				var rad := 150.0 - row * 25.0
				var start: float = c._jit(crng, 0.0, TAU)
				for b in 2:
					var a := start + b * PI
					var p := Vector2(500.0, y)
					c.movers.append({"pos": p + Vector2(DMath.cos(a), DMath.sin(a)) * rad, "radius": 26.0, "kind": "pillar", "pivot": p,
						"orbit": 1.5 if row % 2 == 0 else -1.5, "tint": tint})
			return 840.0
		"st_hail":
			# Hail: stones pelting down in three columns, out of step.
			var period: float = c._jit(crng, 2.8, 3.2)
			for col in 3:
				var x := 220.0 + col * 280.0
				for k in 3:
					c.movers.append({"pos": Vector2(x, y0 + 140.0 + k * 220.0), "radius": 30.0, "kind": "pillar", "tint": "dfe8ff",
						"slide": Vector2(0.0, 140.0), "period": period, "phase": col * 0.33 + k * 0.1})
			return 3 * 220.0 + 200.0
		"st_vanes":
			# Weather vanes: arrows swinging round on their posts with every
			# gust.
			var period: float = c._jit(crng, 3.8, 4.2)
			var at := [Vector2(270.0, 160.0), Vector2(730.0, 160.0), Vector2(500.0, 470.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				var move: Dictionary = c._swinging(hub, 1.1, period, k * 0.3)
				c._rod(hub - Vector2(150.0, 0.0), hub + Vector2(150.0, 0.0), 14.0, move)
				c._chain([hub + Vector2(110.0, -40.0), hub + Vector2(150.0, 0.0), hub + Vector2(110.0, 40.0)], 12.0, move)
			return 470.0 + 260.0
		# --- Icicle Run -------------------------------------------------------------
		"ic_cave":
			# The ice cave mouth: an icy hopper, then an ice peak splitting the
			# field to both walls.
			c._hopper(y0 + 20.0, 500.0, 220.0, 200.0, {"ice": true, "look": "ice"})
			c._seg(Vector2(500.0, y0 + 330.0), Vector2(330.0, y0 + 420.0), SET)
			c._seg(Vector2(500.0, y0 + 330.0), Vector2(670.0, y0 + 420.0), SET)
			return 540.0
		"ic_skijump":
			# Ski jumps: an icy run hurls racers off its end across the shaft
			# onto the landing slope, then back the other way.
			for k in 2:
				var y := y0 + 60.0 + k * 420.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._curve(Vector2(wx, y), Vector2(wx + s * 300.0, y + 260.0), Vector2(wx + s * 560.0, y + 280.0), {"ice": true, "look": "ice"})
				c._seg(Vector2(W - wx, y + 315.0), Vector2(W - wx - s * 340.0, y + 455.0), SET)
			c._pickup(crng, Vector2(500.0, y0 + 160.0))
			return 420.0 + 580.0
		"ic_crevasse":
			# A crevasse: icy cliffs narrowing to a crack, a snow bumper at the
			# bottom of it.
			for k in 2:
				var y := y0 + 40.0 + k * 360.0
				var mouth := 260.0 if k == 0 else 180.0
				c._curve(Vector2(0.0, y), Vector2(260.0, y + 40.0), Vector2(500.0 - mouth / 2.0, y + 230.0), {"ice": true, "look": "ice"})
				c._curve(Vector2(W, y), Vector2(W - 260.0, y + 40.0), Vector2(500.0 + mouth / 2.0, y + 230.0), {"ice": true, "look": "ice"})
				c._peg(500.0 + (150.0 if k == 0 else -150.0), y + 330.0, 32.0, true) # Beside the crack, not under it.
			return 360.0 + 380.0
		"ic_drifts":
			# Icy snowdrifts banked against alternate walls, racers sliding
			# off their crests.
			for k in 4:
				var y := y0 + 50.0 + k * 240.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._curve(Vector2(wx, y), Vector2(wx + s * 260.0, y + 80.0), Vector2(wx + s * 520.0, y + 240.0), {"ice": true, "look": "ice"})
			return 4 * 240.0 + 100.0
		"ic_rink":
			# Ice rinks tipping slowly side to side: the field slides off one
			# end, then the other.
			var period: float = c._jit(crng, 3.4, 3.8)
			for k in 2:
				var hub := Vector2(500.0, y0 + 160.0 + k * 360.0)
				c._rod_at(hub, 300.0, 0.0, 16.0, c._swinging(hub, 0.3 if k == 0 else -0.3, period, k * 0.25))
				c.movers.append({"pos": hub + Vector2(0.0, 1.0), "radius": 30.0, "kind": "pillar", "tint": "e8f6ff"})
			return 360.0 + 340.0
		"ic_avalanche":
			# An avalanche: snowballs tumbling across and down the slope at
			# their own speeds.
			var balls := [[300.0, 100.0, 46.0, 5.0], [700.0, 180.0, 40.0, 5.6], [420.0, 330.0, 52.0, 6.2],
				[760.0, 460.0, 42.0, 5.2], [280.0, 560.0, 48.0, 5.8], [600.0, 690.0, 44.0, 6.0]]
			for k in balls.size():
				var b: Array = balls[k]
				var s := 1.0 if k % 2 == 0 else -1.0
				c.movers.append({"pos": Vector2(b[0], y0 + b[1]), "radius": b[2], "kind": "pillar", "tint": "f4fbff",
					"slide": Vector2(s * 200.0, 60.0), "period": b[3], "phase": c._jit(crng, 0.0, 1.0)})
			return 820.0
		"ic_gears":
			# Frozen gears grinding round, opposite ways, teeth sweeping the
			# shaft.
			var at := [Vector2(270.0, 200.0), Vector2(730.0, 200.0), Vector2(500.0, 560.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				var s := 1.0 if k != 1 else -1.0
				c.movers.append({"pos": hub, "radius": 56.0, "kind": "pillar", "tint": "cfeeff"})
				var turn: float = c._jit(crng, 0.0, 60.0)
				for b in 6:
					var a := deg_to_rad(turn + b * 60.0)
					var d := Vector2(DMath.cos(a), DMath.sin(a))
					c._rod(hub + d * 70.0, hub + d * 160.0, 15.0, c._turning(hub, s * 1.1))
			return 780.0
		# --- Crystal Cave ------------------------------------------------------------
		"cr_geode":
			# A geode cracking open: two crystal halves slide apart under the
			# hopper and drop the field through.
			c._hopper(y0 + 10.0, 500.0, 240.0, 180.0, SET)
			var period: float = c._jit(crng, 3.6, 4.0)
			for s in [-1.0, 1.0]:
				var at := Vector2(500.0 + s * 110.0, y0 + 320.0)
				var move: Dictionary = c._sliding(Vector2(s * 120.0, 0.0), period)
				c._chain([at + Vector2(-s * 100.0, -40.0), at + Vector2(s * 90.0, -60.0), at + Vector2(s * 20.0, 80.0), at + Vector2(-s * 100.0, -40.0)], 16.0, move)
			return 520.0
		"cr_lanes":
			# Refraction lanes: slanted crystal walls split the field into
			# lanes that run it across the shaft.
			for k in 4:
				var x := 160.0 + k * 200.0
				c._seg(Vector2(x, y0 + 80.0), Vector2(x + 140.0, y0 + 460.0), {"thick": 16.0, "look": "set"})
			for k in 3:
				c._peg(260.0 + k * 200.0, y0 + 560.0, 28.0, true)
			return 680.0
		"cr_shards":
			# Crystal shards standing on end: land on a point and slip off
			# one side or the other.
			var rows := [[250.0, 750.0], [500.0], [250.0, 750.0]]
			for row in rows.size():
				var y := y0 + 60.0 + row * 240.0
				for x in rows[row]:
					var pts := [Vector2(x, y), Vector2(x + 80.0, y + 170.0), Vector2(x - 80.0, y + 170.0)]
					for q in 3:
						c._seg(pts[q], pts[(q + 1) % 3], SET)
			c._pickup(crng, Vector2(500.0, y0 + 120.0))
			return 2 * 240.0 + 280.0
		"cr_spiral":
			# Crystal curls: C-shaped crystal shells racers drop into and spin
			# out of, one each way.
			for k in 2:
				var y := y0 + 60.0 + k * 520.0
				var s := 1.0 if k == 0 else -1.0
				var x := 500.0 - s * 60.0
				c._curve(Vector2(x + s * 140.0, y), Vector2(x - s * 220.0, y + 20.0), Vector2(x - s * 200.0, y + 170.0), SET)
				c._curve(Vector2(x - s * 200.0, y + 170.0), Vector2(x - s * 180.0, y + 330.0), Vector2(x + s * 160.0, y + 360.0), SET)
			return 520.0 + 440.0
		"cr_prisms":
			# Prisms: triangles of crystal turning on their centres, flicking
			# racers off their faces.
			var at := [Vector2(270.0, 180.0), Vector2(730.0, 180.0), Vector2(500.0, 500.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				var turn: float = c._jit(crng, 0.0, 120.0)
				var pts := []
				for q in 4:
					var a := deg_to_rad(turn + q * 120.0)
					pts.append(hub + Vector2(DMath.cos(a), DMath.sin(a)) * 130.0)
				c._chain(pts, 15.0, c._turning(hub, 0.9 if k != 1 else -0.9))
			return 700.0
		"cr_bridge":
			# Crystal bridges: tiles that shatter out of the floor one after
			# another, then grow back.
			for row in 3:
				var y := y0 + 100.0 + row * 230.0
				for k in 4:
					var x := 125.0 + k * 250.0
					var tilt := 10.0 if (row + k) % 2 == 0 else -10.0
					var d := Vector2(DMath.cos(deg_to_rad(tilt)), DMath.sin(deg_to_rad(tilt))) * 95.0
					c._gid += 1
					var step: float = 18.0 * c.BEAD
					var n := int(ceil(190.0 / step))
					for j in n + 1:
						c.movers.append({"pos": Vector2(x, y) - d + d * (2.0 * j / n), "radius": 18.0, "kind": "pillar", "group": c._gid,
							"tint": tint, "blink": 1.6, "blink_at": k * 0.4 + row * 0.3})
			return 3 * 230.0 + 60.0
		"cr_orbit":
			# A crystal crown: shards circling a great gem.
			var hub := Vector2(500.0, y0 + 380.0)
			c._peg(500.0, y0 + 380.0, 60.0, true)
			var start: float = c._jit(crng, 0.0, TAU)
			for b in 5:
				var a := start + b * TAU / 5.0
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				var n := Vector2(-d.y, d.x)
				var p := hub + d * 250.0
				c._rod(p - n * 55.0, p + n * 55.0, 15.0, c._turning(hub, 0.85))
			return 760.0
		# --- Lava Tubes --------------------------------------------------------------
		"lv_volcano":
			# The volcano: lava pools round the crater rim, the crater mouth
			# erupting racers out across the shaft.
			for x in [90.0, 910.0]:
				c.floors.append({"kind": "lava", "pos": Vector2(x, y0 + 420.0), "radius": 80.0})
			c._hopper(y0 + 20.0, 500.0, 220.0, 200.0, SET)
			c.floors.append({"kind": "launch", "pos": Vector2(500.0, y0 + 330.0), "radius": 90.0, "kick": Vector2(420.0, -320.0)})
			return 560.0
		"lv_lavafall":
			# A lavafall pours down the middle; the dark obsidian steps down
			# the sides are safe but slow.
			for k in 3:
				c.floors.append({"kind": "lava", "pos": Vector2(500.0, y0 + 160.0 + k * 200.0), "radius": 70.0})
			for k in 4:
				var y := y0 + 60.0 + k * 170.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._seg(Vector2(wx, y), Vector2(wx + s * 300.0, y + 110.0), SET)
			c._pickup(crng, Vector2(500.0, y0 + 760.0), "heal")
			return 840.0
		"lv_chimneys":
			# Two chimneys with hot air roaring up them, the open shaft between
			# them a quicker drop.
			for s in [-1.0, 1.0]:
				var x: float = 500.0 + s * 260.0
				c._seg(Vector2(x - 110.0, y0 + 120.0), Vector2(x - 110.0, y0 + 520.0), SET)
				c._seg(Vector2(x + 110.0, y0 + 120.0), Vector2(x + 110.0, y0 + 520.0), SET)
				c._wind(Rect2(x - 94.0, y0 + 120.0, 188.0, 400.0), Vector2.UP, 450.0)
			c._seg(Vector2(500.0, y0 + 30.0), Vector2(440.0, y0 + 70.0), SET)
			c._seg(Vector2(500.0, y0 + 30.0), Vector2(560.0, y0 + 70.0), SET)
			return 620.0
		"lv_crust":
			# A cracked crust: tipped plates of cooled rock over lava cracks.
			for row in 3:
				var y := y0 + 80.0 + row * 220.0
				var xs := [180.0, 500.0, 820.0] if row % 2 == 0 else [340.0, 660.0]
				for j in xs.size():
					var tilt := 14.0 if (row + j) % 2 == 0 else -14.0
					var d := Vector2(DMath.cos(deg_to_rad(tilt)), DMath.sin(deg_to_rad(tilt))) * 100.0
					c._seg(Vector2(xs[j], y) - d, Vector2(xs[j], y) + d, SET)
				if row % 2 == 0:
					for x in [340.0, 660.0]:
						c.floors.append({"kind": "lava", "pos": Vector2(x, y + 120.0), "radius": 50.0})
			return 2 * 220.0 + 200.0
		"lv_obsidian":
			# Obsidian rafts drifting across the lava, racers riding them off
			# the end.
			var period: float = c._jit(crng, 6.0, 6.4)
			for k in 3:
				var y := y0 + 120.0 + k * 230.0
				var s := 1.0 if k % 2 == 0 else -1.0
				c._rod_at(Vector2(500.0, y), 130.0, s * 10.0, 20.0, c._sliding(Vector2(s * 250.0, 0.0), period, k * 0.3))
			for x in [130.0, 870.0]:
				c.floors.append({"kind": "lava", "pos": Vector2(x, y0 + 360.0), "radius": 90.0})
			return 3 * 230.0 + 80.0
		"lv_wheel":
			# A magma wheel turning in a lava pool, paddles scooping racers
			# round.
			var hub := Vector2(500.0, y0 + 400.0)
			c.floors.append({"kind": "lava", "pos": Vector2(500.0, y0 + 660.0), "radius": 90.0})
			c.movers.append({"pos": hub, "radius": 44.0, "kind": "pillar", "tint": "6b2a14"})
			var turn: float = c._jit(crng, 0.0, 60.0)
			for b in 6:
				var a := deg_to_rad(turn + b * 60.0)
				var d := Vector2(DMath.cos(a), DMath.sin(a))
				c._rod(hub + d * 60.0, hub + d * 240.0, 14.0, c._turning(hub, 0.8))
			return 760.0
		"lv_pumice":
			# Pumice rocks bobbing in the lava, rising and sinking out of step.
			var period: float = c._jit(crng, 2.8, 3.2)
			var at := [Vector2(200.0, 160.0), Vector2(500.0, 120.0), Vector2(800.0, 160.0), Vector2(350.0, 430.0), Vector2(650.0, 430.0)]
			for k in at.size():
				c.movers.append({"pos": Vector2(at[k].x, y0 + at[k].y), "radius": 56.0, "kind": "pillar", "tint": "8a6a5a",
					"slide": Vector2(0.0, 90.0), "period": period, "phase": k * 0.2})
			for x in [350.0, 650.0]:
				c.floors.append({"kind": "lava", "pos": Vector2(x, y0 + 250.0), "radius": 60.0})
			return 620.0
		# --- Sunset Strip -------------------------------------------------------------
		"su_onramp":
			# The on-ramp: curving slip roads from both walls merging the
			# field into the strip.
			c._curve(Vector2(0.0, y0 + 30.0), Vector2(300.0, y0 + 40.0), Vector2(410.0, y0 + 230.0), SET)
			c._curve(Vector2(W, y0 + 30.0), Vector2(W - 300.0, y0 + 40.0), Vector2(590.0, y0 + 230.0), SET)
			c._seg(Vector2(500.0, y0 + 340.0), Vector2(360.0, y0 + 420.0), SET)
			c._seg(Vector2(500.0, y0 + 340.0), Vector2(640.0, y0 + 420.0), SET)
			return 520.0
		"su_billboards":
			# Billboards: tipped boards racers slide off one end or the
			# other.
			var at := [[260.0, 120.0, 12.0], [740.0, 120.0, -12.0], [500.0, 420.0, 12.0]]
			for b in at:
				var hub := Vector2(b[0], y0 + b[1])
				var d := Vector2(DMath.cos(deg_to_rad(b[2])), DMath.sin(deg_to_rad(b[2])))
				var n := Vector2(-d.y, d.x)
				var pts := [hub - d * 150.0 - n * 40.0, hub + d * 150.0 - n * 40.0, hub + d * 150.0 + n * 40.0, hub - d * 150.0 + n * 40.0]
				for q in 4:
					c._seg(pts[q], pts[(q + 1) % 4], SET)
			c._pickup(crng, Vector2(500.0, y0 + 160.0))
			return 420.0 + 260.0
		"su_skyline":
			# The skyline: rooftops of every height, racers hopping roof to
			# roof down the strip.
			var roofs := [[160.0, 80.0, 1.0], [450.0, 200.0, -1.0], [800.0, 120.0, 1.0], [300.0, 430.0, 1.0], [680.0, 520.0, -1.0]]
			for r in roofs:
				var x: float = r[0]
				var y: float = y0 + r[1]
				c._seg(Vector2(x - 110.0, y - 30.0 * r[2]), Vector2(x + 110.0, y + 30.0 * r[2]), SET)
			return 680.0
		"su_surf":
			# Surf: a long rolling wave racers ride down across the shaft and
			# back.
			for k in 2:
				var y := y0 + 60.0 + k * 360.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._curve(Vector2(wx, y), Vector2(wx + s * 200.0, y + 60.0), Vector2(wx + s * 380.0, y + 130.0), {"look": "pipe"})
				c._curve(Vector2(wx + s * 380.0, y + 130.0), Vector2(wx + s * 560.0, y + 160.0), Vector2(wx + s * 720.0, y + 260.0), {"look": "pipe"})
			return 360.0 + 380.0
		"su_signs":
			# Neon signs flashing on and off in turn: a racer on a sign drops
			# when it blinks out.
			for row in 3:
				var y := y0 + 110.0 + row * 220.0
				for j in 2:
					var x := 300.0 if j == 0 else 700.0
					var tilt := 14.0 if j == 0 else -14.0
					var d := Vector2(DMath.cos(deg_to_rad(tilt)), DMath.sin(deg_to_rad(tilt))) * 130.0
					c._gid += 1
					var step: float = 20.0 * c.BEAD
					var n := int(ceil(260.0 / step))
					for q in n + 1:
						c.movers.append({"pos": Vector2(x, y) - d + d * (2.0 * q / n), "radius": 20.0, "kind": "pillar", "group": c._gid,
							"tint": "ff5fd2" if j == 0 else "5cf2ff", "blink": 1.4, "blink_at": (j + row) % 2 * 1.4})
			return 3 * 220.0 + 80.0
		"su_carwash":
			# The car wash: big spinning brushes, two then one.
			var at := [Vector2(270.0, 200.0), Vector2(730.0, 200.0), Vector2(500.0, 550.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				var turn: float = c._jit(crng, 0.0, 60.0)
				for b in 3:
					c._rod_at(hub, 150.0, turn + b * 60.0, 12.0, c._turning(hub, 1.4 if k != 1 else -1.4))
			return 760.0
		"su_tolls":
			# Toll gates: barrier arms lifting and dropping across the road
			# from both sides.
			var period: float = c._jit(crng, 3.4, 3.8)
			for k in 3:
				var y := y0 + 100.0 + k * 230.0
				var left := k % 2 == 0
				var hinge := Vector2(70.0 if left else W - 70.0, y)
				var s := 1.0 if left else -1.0
				c.movers.append({"pos": hinge, "radius": 30.0, "kind": "pillar", "tint": "ffd23a"})
				c._rod(hinge, hinge + Vector2(s * 380.0, 160.0), 16.0, c._swinging(hinge, -s * 0.3, period, k * 0.3)) # Always tipped to the middle.
			return 3 * 230.0 + 140.0
		# --- Glitch Grid --------------------------------------------------------------
		"gl_boot":
			# The boot screen: the field waits on a loading bar until its
			# blocks drop out one after another.
			c._hopper(y0 + 10.0, 500.0, 520.0, 160.0, SET)
			for k in 6:
				var x := 270.0 + k * 92.0
				c.movers.append({"pos": Vector2(x, y0 + 260.0 + (k % 2) * 20.0), "radius": 40.0, "kind": "pillar", "tint": tint,
					"blink": 1.2, "blink_at": k * 0.2})
			return 440.0
		"gl_lag":
			# Lag spikes: freeze in the goo, then the wind catches up.
			for k in 2:
				var y := y0 + 120.0 + k * 330.0
				for x in [250.0, 750.0] if k == 0 else [500.0]:
					c.floors.append({"kind": "goo", "pos": Vector2(x, y), "radius": 110.0, "slow": 0.0})
				c._wind(Rect2(0.0, y + 140.0, W, 90.0), Vector2.DOWN, 800.0)
			for x in [120.0, 880.0]:
				c._peg(x, y0 + 300.0, 28.0, true)
			c._pickup(crng, Vector2(500.0, y0 + 120.0))
			return 330.0 + 320.0
		"gl_copy":
			# Copy-paste: one little roof-and-bumper motif pasted over and
			# over, each paste shifted.
			for row in 3:
				var y := y0 + 70.0 + row * 210.0
				var xs := [180.0, 500.0, 820.0] if row % 2 == 0 else [340.0, 660.0]
				for x in xs:
					c._seg(Vector2(x, y), Vector2(x - 90.0, y + 70.0), {"look": "block"})
					c._seg(Vector2(x, y), Vector2(x + 90.0, y + 70.0), {"look": "block"})
					c._peg(x, y + 140.0, 22.0, true)
			return 3 * 210.0 + 80.0
		"gl_circuit":
			# A circuit board: traces running across and dropping down, via
			# bumpers at the corners.
			var traces := [[Vector2(0.0, 60.0), Vector2(420.0, 160.0), Vector2(420.0, 300.0)],
				[Vector2(W, 260.0), Vector2(600.0, 360.0), Vector2(600.0, 520.0)],
				[Vector2(0.0, 480.0), Vector2(320.0, 560.0), Vector2(320.0, 700.0)]]
			for t in traces:
				for k in t.size() - 1:
					c._seg(t[k] + Vector2(0.0, y0), t[k + 1] + Vector2(0.0, y0), {"look": "block"})
			for at in [Vector2(820.0, 120.0), Vector2(180.0, 330.0), Vector2(800.0, 620.0)]:
				c._peg(at.x, y0 + at.y, 30.0, true)
			return 780.0
		"gl_firewall":
			# The firewall: rows of blocks with one gap that runs along them.
			var period: float = c._jit(crng, 5.2, 5.6)
			for row in 3:
				var y := y0 + 160.0 + row * 260.0
				var gap := 500.0
				var move: Dictionary = c._sliding(Vector2(260.0 if row % 2 == 0 else -260.0, 0.0), period, row * 0.3)
				# Tipped toward the gap, so nobody waits on the wall for it.
				c._chain([Vector2(gap - 640.0, y - 130.0), Vector2(gap - 110.0, y + 30.0)], 22.0, move)
				c._chain([Vector2(gap + 110.0, y + 30.0), Vector2(gap + 640.0, y - 130.0)], 22.0, move)
			return 3 * 260.0 + 80.0
		"gl_bitflip":
			# Bit flips: each ramp flips its slope back and forth on the beat.
			for row in 3:
				var y := y0 + 110.0 + row * 220.0
				var xs := [270.0, 730.0] if row % 2 == 0 else [500.0]
				for x in xs:
					for layout in 2:
						var tilt := 18.0 if layout == 0 else -18.0
						var d := Vector2(DMath.cos(deg_to_rad(tilt)), DMath.sin(deg_to_rad(tilt))) * 140.0
						c._gid += 1
						var step: float = 16.0 * c.BEAD
						var n := int(ceil(280.0 / step))
						for q in n + 1:
							c.movers.append({"pos": Vector2(x, y) - d + d * (2.0 * q / n), "radius": 16.0, "kind": "pillar", "group": c._gid,
								"tint": tint, "blink": 1.5, "blink_at": layout * 1.5})
			return 3 * 220.0 + 60.0
		"gl_cursor":
			# A giant cursor gliding round the screen, clicking racers away.
			var period: float = c._jit(crng, 6.0, 6.4)
			for k in 2:
				var at := Vector2(500.0, y0 + 200.0 + k * 360.0)
				var s := 1.0 if k == 0 else -1.0
				var move: Dictionary = c._sliding(Vector2(s * 240.0, 90.0), period, k * 0.5)
				c._chain([at, at + Vector2(0.0, 170.0), at + Vector2(45.0, 125.0), at + Vector2(110.0, 120.0), at], 14.0, move)
			return 360.0 + 520.0
		# --- Dune Slide --------------------------------------------------------------
		"dn_hourglass":
			# The hourglass: sand pours the field through a neck that opens
			# and pinches shut.
			c._hopper(y0 + 10.0, 500.0, 380.0, 170.0, {"thick": 16.0, "look": "set"})
			var period: float = c._jit(crng, 3.4, 3.8)
			for s in [-1.0, 1.0]:
				var at := Vector2(500.0 + s * 170.0, y0 + 300.0)
				c._rod_at(at, 110.0, -s * 30.0, 16.0, c._sliding(Vector2(-s * 70.0, 0.0), period))
			return 480.0
		"dn_ridges":
			# Dune ridges: rolling sand slopes down alternate sides, quicksand
			# in the hollows.
			for k in 3:
				var y := y0 + 60.0 + k * 280.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._curve(Vector2(wx, y), Vector2(wx + s * 200.0, y + 70.0), Vector2(wx + s * 360.0, y + 140.0), {"look": "sand"})
				c._curve(Vector2(wx + s * 360.0, y + 140.0), Vector2(wx + s * 430.0, y + 170.0), Vector2(wx + s * 500.0, y + 250.0), {"look": "sand"})
				c.floors.append({"kind": "goo", "pos": Vector2(wx + s * 760.0, y + 230.0), "radius": 80.0, "slow": 0.0})
			return 3 * 280.0 + 160.0
		"dn_pyramid":
			# A pyramid: racers slide off its faces; a small one either side.
			c._seg(Vector2(500.0, y0 + 80.0), Vector2(250.0, y0 + 400.0), {"look": "sand", "thick": 16.0})
			c._seg(Vector2(500.0, y0 + 80.0), Vector2(750.0, y0 + 400.0), {"look": "sand", "thick": 16.0})
			for x in [200.0, 800.0]:
				c._seg(Vector2(x, y0 + 520.0), Vector2(x - 90.0, y0 + 640.0), {"look": "sand", "thick": 16.0})
				c._seg(Vector2(x, y0 + 520.0), Vector2(x + 90.0, y0 + 640.0), {"look": "sand", "thick": 16.0})
			c._pickup(crng, Vector2(500.0, y0 + 560.0))
			return 720.0
		"dn_oasis":
			# An oasis: palms leaning over a pool; the water slows you, the
			# fruit heals you.
			for s in [-1.0, 1.0]:
				var wx := 0.0 if s > 0.0 else W
				c._curve(Vector2(wx + s * 120.0, y0 + 420.0), Vector2(wx + s * 200.0, y0 + 330.0), Vector2(wx + s * 330.0, y0 + 120.0), {"look": "sand", "thick": 16.0})
			c.floors.append({"kind": "goo", "pos": Vector2(500.0, y0 + 420.0), "radius": 120.0, "slow": 0.0})
			c._pickup(crng, Vector2(500.0, y0 + 200.0), "heal")
			return 600.0
		"dn_tumbleweeds":
			# Tumbleweeds rolling round and round in big loops.
			var at := [Vector2(300.0, 260.0), Vector2(700.0, 520.0), Vector2(320.0, 760.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				var start: float = c._jit(crng, 0.0, TAU)
				for b in 2:
					var a := start + b * PI
					c.movers.append({"pos": hub + Vector2(DMath.cos(a), DMath.sin(a)) * 170.0, "radius": 38.0, "kind": "bumper",
						"pivot": hub, "orbit": 1.4 if k % 2 == 0 else -1.4})
			return 960.0
		"dn_scarabs":
			# Sandstone ledges, scarabs scuttling round where racers drop off
			# them.
			var period: float = c._jit(crng, 3.4, 3.8)
			for k in 3:
				var y := y0 + 80.0 + k * 240.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._seg(Vector2(wx, y), Vector2(wx + s * 440.0, y + 150.0), {"look": "sand", "thick": 16.0})
				c.movers.append({"pos": Vector2(wx + s * 620.0, y + 190.0), "radius": 28.0, "kind": "bumper",
					"slide": Vector2(s * 70.0, 50.0), "period": period, "phase": k * 0.3})
			return 3 * 240.0 + 200.0
		"dn_caravan":
			# A camel caravan crossing the dunes, humps and all.
			var period: float = c._jit(crng, 6.2, 6.6)
			for k in 2:
				var y := y0 + 200.0 + k * 380.0
				var s := 1.0 if k == 0 else -1.0
				var move: Dictionary = c._sliding(Vector2(s * 230.0, 0.0), period, k * 0.5)
				c._chain([Vector2(330.0, y + 30.0), Vector2(400.0, y - 50.0), Vector2(470.0, y + 10.0), Vector2(540.0, y - 50.0), Vector2(620.0, y + 40.0)], 18.0, move)
			return 380.0 + 340.0
		# --- Grave Drop --------------------------------------------------------------
		"gv_gate":
			# The cemetery gate: iron bars rising and dropping in the gateway
			# under the arch.
			c._hopper(y0 + 10.0, 500.0, 360.0, 180.0, SET)
			var period: float = c._jit(crng, 2.8, 3.2)
			for k in 3:
				var x := 380.0 + k * 120.0
				c._rod(Vector2(x, y0 + 250.0), Vector2(x, y0 + 360.0), 13.0, c._sliding(Vector2(0.0, 70.0), period, k * 0.33))
			return 500.0
		"gv_headstones":
			# Rows of tipped headstones racers ricochet between.
			var rows := [[220.0, 500.0, 780.0], [360.0, 640.0], [220.0, 500.0, 780.0]]
			for row in rows.size():
				var y := y0 + 100.0 + row * 230.0
				for j in rows[row].size():
					var x: float = rows[row][j]
					var tilt := 14.0 if (row + j) % 2 == 0 else -14.0
					var d := Vector2(DMath.cos(deg_to_rad(tilt)), DMath.sin(deg_to_rad(tilt)))
					var n := Vector2(-d.y, d.x)
					var pts := [Vector2(x, y) - d * 50.0 - n * 70.0, Vector2(x, y) + d * 50.0 - n * 70.0, Vector2(x, y) + d * 50.0 + n * 70.0, Vector2(x, y) - d * 50.0 + n * 70.0]
					for q in 4:
						c._seg(pts[q], pts[(q + 1) % 4], {"look": "stone"})
			return 2 * 230.0 + 240.0
		"gv_fog":
			# Graveyard fog: slow drifts of mist behind crooked fences.
			for k in 3:
				var y := y0 + 80.0 + k * 230.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._seg(Vector2(wx, y), Vector2(wx + s * 420.0, y + 120.0), {"look": "stone"})
				c.floors.append({"kind": "goo", "pos": Vector2(W - wx - s * 230.0, y + 120.0), "radius": 100.0, "slow": 0.0})
			c._pickup(crng, Vector2(500.0, y0 + 400.0), "shield")
			return 3 * 230.0 + 150.0
		"gv_crosses":
			# Grave crosses with drooping arms: hit the post or roll off an arm.
			var rows := [[260.0, 740.0], [500.0]]
			for row in rows.size():
				var y := y0 + 60.0 + row * 330.0
				for j in rows[row].size():
					var x: float = rows[row][j]
					var mid := Vector2(x, y + 70.0)
					c._seg(Vector2(x, y), mid, {"look": "stone"})
					c._seg(mid, Vector2(x, y + 260.0), {"look": "stone"})
					c._seg(mid, mid + Vector2(-120.0, 30.0), {"look": "stone"}) # Arms droop: nothing rests in the corners.
					c._seg(mid, mid + Vector2(120.0, 30.0), {"look": "stone"})
			return 330.0 + 320.0
		"gv_lanterns":
			# Ghost lanterns weaving loops round the graves.
			var period: float = c._jit(crng, 2.8, 3.2)
			var at := [Vector2(280.0, 220.0), Vector2(720.0, 320.0), Vector2(400.0, 600.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				c.movers.append({"pos": hub + Vector2(110.0, 0.0), "radius": 34.0, "kind": "bumper", "pivot": hub,
					"orbit": 0.6 if k % 2 == 0 else -0.6, "slide": Vector2(0.0, 60.0), "period": period, "phase": k * 0.3})
			return 820.0
		"gv_bones":
			# Bone bridges rattling: rows of bones rocking on their joints.
			var period: float = c._jit(crng, 2.2, 2.6)
			for row in 3:
				var y := y0 + 100.0 + row * 220.0
				var xs := [170.0, 500.0, 830.0] if row % 2 == 0 else [330.0, 670.0]
				for j in xs.size():
					var hub := Vector2(xs[j], y)
					c._rod_at(hub, 85.0, 10.0 if j % 2 == 0 else -10.0, 15.0, c._swinging(hub, 0.3, period, j * 0.25 + row * 0.15))
			return 3 * 220.0 + 60.0
		"gv_bats":
			# Bat flocks whirling in tight circles.
			for k in 2:
				var hub := Vector2(300.0 if k == 0 else 700.0, y0 + 220.0 + k * 300.0)
				var start: float = c._jit(crng, 0.0, TAU)
				for b in 6:
					var a := start + b * TAU / 6.0
					c.movers.append({"pos": hub + Vector2(DMath.cos(a), DMath.sin(a)) * 90.0, "radius": 18.0, "kind": "pillar",
						"pivot": hub, "orbit": 2.4 if k == 0 else -2.4, "tint": "3a2f4a"})
			return 300.0 + 440.0
		# --- Haunted Stairs ------------------------------------------------------------
		"mn_doors":
			# The front doors swing open under the porch, then shut again.
			c._hopper(y0 + 10.0, 500.0, 300.0, 180.0, SET)
			var period: float = c._jit(crng, 3.0, 3.4)
			for s in [-1.0, 1.0]:
				var hinge := Vector2(500.0 + s * 150.0, y0 + 210.0)
				var a := deg_to_rad(90.0 + s * 45.0)
				c._rod(hinge, hinge + Vector2(DMath.cos(a), DMath.sin(a)) * 120.0, 13.0, c._swinging(hinge, s * 0.45, period, 0.0))
			return 460.0
		"mn_portraits":
			# Haunted portraits: step into the painting on one side and out
			# of another lower down.
			for k in 2:
				var y := y0 + 140.0 + k * 340.0
				for s in [-1.0, 1.0]:
					var x: float = 500.0 + s * 290.0
					c._seg(Vector2(x - 75.0, y - 90.0), Vector2(x - 75.0, y + 50.0), {"look": "stone"})
					c._seg(Vector2(x + 75.0, y - 90.0), Vector2(x + 75.0, y + 50.0), {"look": "stone"})
				c._portal(Vector2(210.0, y0 + 140.0 + k * 340.0), Vector2(790.0, y0 + 300.0 + k * 340.0))
			c._peg(500.0, y0 + 300.0, 30.0, true)
			return 2 * 340.0 + 160.0
		"mn_passage":
			# A secret passage: a wall splits the hall, and one side has a
			# hidden door that skips a floor.
			c._seg(Vector2(500.0, y0 + 100.0), Vector2(500.0, y0 + 620.0), {"look": "stone", "thick": 16.0})
			c._seg(Vector2(500.0, y0 + 100.0), Vector2(390.0, y0 + 170.0), {"look": "stone", "thick": 16.0})
			c._seg(Vector2(500.0, y0 + 100.0), Vector2(610.0, y0 + 170.0), {"look": "stone", "thick": 16.0})
			c._portal(Vector2(250.0, y0 + 300.0), Vector2(750.0, y0 + 640.0))
			for y in [y0 + 260.0, y0 + 480.0]:
				c._peg(800.0, y, 28.0, true)
			c._pickup(crng, Vector2(250.0, y0 + 520.0))
			return 760.0
		"mn_banister":
			# Banisters: long polished rails curling down from alternate
			# walls.
			for k in 3:
				var y := y0 + 60.0 + k * 300.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._curve(Vector2(wx, y), Vector2(wx + s * 300.0, y + 100.0), Vector2(wx + s * 640.0, y + 260.0), {"look": "stone"})
			return 3 * 300.0 + 160.0
		"mn_chandelier":
			# A great chandelier swinging over the hall, crystals hanging off
			# its arms.
			var period: float = c._jit(crng, 3.4, 3.8)
			var pivot := Vector2(500.0, y0 + 20.0)
			var move: Dictionary = c._swinging(pivot, 0.35, period, 0.0)
			var low := pivot + Vector2(0.0, 300.0)
			c._rod(pivot, low, 9.0, move)
			c._rod(low - Vector2(200.0, 0.0), low + Vector2(200.0, 0.0), 13.0, move)
			for x in [-200.0, 0.0, 200.0]:
				c.movers.append({"pos": low + Vector2(x, 50.0), "radius": 24.0, "kind": "bumper"}.merged(move))
			for x in [150.0, 850.0]:
				c._peg(x, y0 + 560.0, 30.0, true)
			return 700.0
		"mn_furniture":
			# Furniture gliding round the room on its own: tables and chairs
			# sliding across.
			var period: float = c._jit(crng, 5.6, 6.0)
			for k in 3:
				var y := y0 + 120.0 + k * 250.0
				var s := 1.0 if k % 2 == 0 else -1.0
				var move: Dictionary = c._sliding(Vector2(s * 230.0, 0.0), period, k * 0.3)
				var top := Vector2(500.0, y)
				c._rod(top + Vector2(-110.0, -30.0 * s), top + Vector2(110.0, 30.0 * s), 15.0, move)
				c._rod(top + Vector2(0.0, 20.0), top + Vector2(0.0, 110.0), 12.0, move)
			return 3 * 250.0 + 100.0
		"mn_clock":
			# The grandfather clock: its hands sweep round the face, its
			# pendulum swings below.
			var hub := Vector2(500.0, y0 + 260.0)
			c.movers.append({"pos": hub, "radius": 30.0, "kind": "pillar", "tint": "e8d9a8"})
			var a: float = c._jit(crng, 0.0, TAU)
			c._rod(hub, hub + Vector2(DMath.cos(a), DMath.sin(a)) * 230.0, 14.0, c._turning(hub, 0.5))
			c._rod(hub, hub + Vector2(DMath.cos(a + 2.0), DMath.sin(a + 2.0)) * 160.0, 16.0, c._turning(hub, 1.4))
			var pivot := Vector2(500.0, y0 + 560.0)
			var swing: Dictionary = c._swinging(pivot, 0.45, c._jit(crng, 2.6, 3.0), 0.0)
			c._rod(pivot, pivot + Vector2(0.0, 200.0), 10.0, swing)
			c.movers.append({"pos": pivot + Vector2(0.0, 220.0), "radius": 42.0, "kind": "pillar", "tint": "e8c36a"}.merged(swing))
			return 880.0
		# --- Toy Chest --------------------------------------------------------------
		"ty_chest":
			# The toy chest lid flaps open and dumps the field out.
			c._hopper(y0 + 10.0, 500.0, 260.0, 180.0, SET)
			var period: float = c._jit(crng, 2.8, 3.2)
			var hinge := Vector2(370.0, y0 + 200.0)
			c._rod(hinge, hinge + Vector2(DMath.cos(0.5), DMath.sin(0.5)) * 220.0, 14.0, c._swinging(hinge, 0.5, period, 0.0))
			return 480.0
		"ty_marblerun":
			# A toy marble run: switchback conveyor tracks whizzing racers from
			# side to side.
			for k in 3:
				var y := y0 + 60.0 + k * 220.0
				var left := k % 2 == 0
				var wx := 0.0 if left else W
				var s := 1.0 if left else -1.0
				c._seg(Vector2(wx, y), Vector2(wx + s * 480.0, y + 150.0), {"look": "belt", "belt": 380.0})
			return 3 * 220.0 + 130.0
		"ty_abc":
			# ABC blocks tumbled in a heap: tipped cubes racers bounce down.
			var blocks := [[250.0, 140.0, 12.0], [560.0, 200.0, -18.0], [820.0, 120.0, 20.0], [380.0, 440.0, -10.0], [700.0, 470.0, 15.0]]
			for b in blocks:
				var hub := Vector2(b[0], y0 + b[1])
				var pts := []
				for q in 4:
					var a := deg_to_rad(b[2] + 45.0 + q * 90.0)
					pts.append(hub + Vector2(DMath.cos(a), DMath.sin(a)) * 85.0)
				for q in 4:
					c._seg(pts[q], pts[(q + 1) % 4], SET)
			c._pickup(crng, Vector2(500.0, y0 + 330.0))
			return 640.0
		"ty_crayons":
			# Giant crayons leaning every which way, puddles of paint between.
			var at := [[230.0, 150.0, 60.0], [770.0, 150.0, 120.0], [500.0, 400.0, 70.0], [230.0, 620.0, 110.0], [770.0, 620.0, 65.0]]
			for cr in at:
				var hub := Vector2(cr[0], y0 + cr[1])
				var d := Vector2(DMath.cos(deg_to_rad(cr[2])), DMath.sin(deg_to_rad(cr[2]))) * 110.0
				c._seg(hub - d, hub + d, {"thick": 16.0, "look": "set"})
			for x in [500.0]:
				c.floors.append({"kind": "goo", "pos": Vector2(x, y0 + 170.0), "radius": 80.0, "slow": 0.0})
			return 800.0
		"ty_train":
			# A toy train running round its loop of track.
			var hub := Vector2(500.0, y0 + 380.0)
			var start: float = c._jit(crng, 0.0, TAU)
			for b in 4:
				var a := start + b * 0.42
				c.movers.append({"pos": hub + Vector2(DMath.cos(a), DMath.sin(a)) * 240.0, "radius": 34.0, "kind": "pillar",
					"pivot": hub, "orbit": 1.0, "tint": "ff5f5f" if b == 0 else tint})
			c._peg(500.0, y0 + 380.0, 60.0, true)
			return 760.0
		"ty_dominoes":
			# Dominoes toppling in a wave and standing back up.
			var period: float = c._jit(crng, 2.6, 3.0)
			for row in 2:
				var y := y0 + 260.0 + row * 360.0
				for k in 5:
					var base := Vector2(140.0 + k * 180.0, y)
					var s := 1.0 if row == 0 else -1.0
					c._rod(base, base - Vector2(0.0, 170.0), 15.0, c._swinging(base, s * 0.35, period, k * 0.1))
			return 360.0 + 340.0
		"ty_jacks":
			# Jack-in-the-boxes: springs popping up out of the boxes and
			# back.
			var period: float = c._jit(crng, 2.2, 2.6)
			for k in 3:
				var x := 220.0 + k * 280.0
				var y := y0 + 300.0 + (k % 2) * 160.0
				var box := [Vector2(x - 80.0, y - 20.0), Vector2(x + 80.0, y + 20.0), Vector2(x + 80.0, y + 140.0), Vector2(x - 80.0, y + 120.0)]
				for q in 4:
					c._seg(box[q], box[(q + 1) % 4], SET)
				# A soft clown head, not a bumper: a bumper here juggled racers on the lid.
				c.movers.append({"pos": Vector2(x, y - 130.0), "radius": 40.0, "kind": "pillar", "tint": "ff6f6f", "slide": Vector2(0.0, 60.0), "period": period, "phase": k * 0.33})
			return 640.0
		# --- Pinball Plunge -----------------------------------------------------------
		"pb_bumpers":
			# The top of the table: the field drains through the hopper into
			# three pop bumpers.
			c._hopper(y0 + 10.0, 500.0, 300.0, 170.0, SET)
			for at in [Vector2(380.0, 330.0), Vector2(620.0, 330.0), Vector2(500.0, 470.0)]:
				c._peg(at.x, y0 + at.y, 44.0, true)
			return 580.0
		"pb_inlanes":
			# Inlanes and outlanes: guide rails from the walls, posts between
			# the lanes.
			for k in 2:
				var y := y0 + 60.0 + k * 360.0
				c._seg(Vector2(0.0, y), Vector2(320.0, y + 200.0), SET)
				c._seg(Vector2(W, y), Vector2(680.0, y + 200.0), SET)
				for x in [140.0, 860.0]:
					c._seg(Vector2(x, y + 220.0), Vector2(x, y + 310.0), SET)
			c._pickup(crng, Vector2(500.0, y0 + 260.0))
			return 360.0 + 360.0
		"pb_slings":
			# Slingshots: kicking walls of bumpers on both sides fire racers
			# across the table.
			for k in 2:
				var y := y0 + 80.0 + k * 330.0
				for s in [-1.0, 1.0]:
					var top := Vector2(500.0 + s * 200.0, y)
					for j in 5:
						c._peg(top.x + s * j * 22.0, top.y + j * 44.0, 22.0, true)
			return 330.0 + 330.0
		"pb_lanes":
			# Rollover lanes: posts split the table into lanes, a target bumper
			# under each.
			for k in 4:
				var x := 200.0 + k * 200.0
				c._seg(Vector2(x, y0 + 80.0), Vector2(x, y0 + 260.0), SET)
			for k in 5:
				c._peg(100.0 + k * 200.0, y0 + 380.0 + (k % 2) * 60.0, 26.0, true)
			return 560.0
		"pb_pops":
			# A pop bumper triangle with a spinner turning in its middle.
			for at in [Vector2(330.0, 160.0), Vector2(670.0, 160.0), Vector2(500.0, 440.0)]:
				c._peg(at.x, y0 + at.y, 50.0, true)
			var hub := Vector2(500.0, y0 + 250.0)
			c._rod_at(hub, 70.0, c._jit(crng, 0.0, 180.0), 13.0, c._turning(hub, 2.6))
			for x in [150.0, 850.0]:
				var cc := Vector2(x, y0 + 560.0)
				c._rod_at(cc, 80.0, c._jit(crng, 0.0, 180.0), 13.0, c._turning(cc, 2.4))
			return 700.0
		"pb_targets":
			# Drop targets: banks of targets that drop away when hit, and pop
			# back up.
			for row in 2:
				var y := y0 + 140.0 + row * 300.0
				for k in 4:
					var x := 200.0 + k * 200.0 + (100.0 if row == 1 else 0.0)
					if x > 850.0:
						continue
					c.movers.append({"pos": Vector2(x, y), "radius": 36.0, "kind": "pillar", "tint": "ffe14d" if k % 2 == 0 else tint,
						"blink": 1.3, "blink_at": k * 0.33 + row * 0.6})
			return 300.0 + 280.0
		"pb_multiball":
			# Multiball: decoy balls loose on the table, circling the bumpers.
			var at := [Vector2(300.0, 220.0), Vector2(700.0, 460.0)]
			for k in at.size():
				var hub := Vector2(at[k].x, y0 + at[k].y)
				c._peg(hub.x, hub.y, 30.0, true)
				var start: float = c._jit(crng, 0.0, TAU)
				for b in 3:
					var a := start + b * TAU / 3.0
					c.movers.append({"pos": hub + Vector2(DMath.cos(a), DMath.sin(a)) * 150.0, "radius": 30.0, "kind": "pillar",
						"pivot": hub, "orbit": 1.6 if k == 0 else -1.6, "tint": "e6e6f0"})
			return 720.0
	push_error("Unknown Plunge section %s" % kind)
	return 0.0
