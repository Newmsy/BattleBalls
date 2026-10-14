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
]
