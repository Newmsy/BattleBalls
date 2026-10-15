## Fight configs whose outcomes are pinned in golden_replays.json.
extends RefCounted

const CASES := [
	{"seed": 42, "p1": "vampire", "p2": "laser", "angles": [null, null]},
	{"seed": 42, "p1": "laser", "p2": "vampire", "angles": [null, null]},
	{"seed": 7, "p1": "vampire", "p2": "vampire", "angles": [null, null]},
	{"seed": 7, "p1": "laser", "p2": "laser", "angles": [null, null]},
	{"seed": 123, "p1": "vampire", "p2": "laser", "angles": [-450, null]},
	{"seed": 2026, "p1": "laser", "p2": "plain", "angles": [-200, 1500]},
	{"seed": 42, "p1": "magnet", "p2": "vampire", "angles": [null, null]},
	{"seed": 9, "p1": "laser", "p2": "magnet", "angles": [null, null]},
	{"seed": 7, "p1": "magnet", "p2": "magnet", "angles": [null, null]},
	{"seed": 11, "p1": "bomber", "p2": "vampire", "angles": [null, null]},
	{"seed": 12, "p1": "frost", "p2": "laser", "angles": [null, null]},
	{"seed": 13, "p1": "thorns", "p2": "magnet", "angles": [null, null]},
	{"seed": 14, "p1": "ghost", "p2": "vampire", "angles": [null, null]},
	{"seed": 15, "p1": "gravity", "p2": "laser", "angles": [null, null]},
	{"seed": 16, "p1": "mirror", "p2": "magnet", "angles": [null, null]},
	{"seed": 17, "p1": "phoenix", "p2": "vampire", "angles": [null, null]},
	{"seed": 18, "p1": "prism", "p2": "laser", "angles": [null, null]},
	{"seed": 19, "p1": "blackhole", "p2": "magnet", "angles": [null, null]},
	{"seed": 20, "p1": "mirror", "p2": "phoenix", "angles": [300, -700]},
]
