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
	{"seed": 11, "p1": "juggernaut", "p2": "speedster", "angles": [null, null]},
	{"seed": 12, "p1": "spiker", "p2": "vampire", "angles": [null, null]},
	{"seed": 13, "p1": "speedster", "p2": "laser", "angles": [null, null], "powers": [1.25, 1.0]},
	{"seed": 14, "p1": "vampire", "p2": "juggernaut", "angles": [null, null], "powers": [1.0, 1.75], "sizes": [1.0, 1.35]},
]
