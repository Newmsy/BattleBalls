## How each arena looks: floor colour, grid, border, pillar colour, soft
## background glows and an ambient effect. Render-only: the sim never reads it.
extends RefCounted

## ambient: "none", "fireflies", "snow", "embers", "wisps", "stars", "sparks",
## "bubbles", "petals", "glitch", "pollen".
## glows: [[pos (arena units), radius, colour]] soft light pools on the floor.
const THEMES := {
	"square": {"fill": "120f33", "grid": "786eff", "border": "8f7bff", "pillar": "6d79b8", "ambient": "fireflies",
		"glows": [[Vector2(250, 250), 260.0, "45f5a6"], [Vector2(750, 750), 260.0, "45f5a6"]]},
	"rink": {"fill": "0f1436", "grid": "6ec8ff", "border": "5fd4ff", "pillar": "6d79b8", "ambient": "sparks",
		"glows": [[Vector2(500, 500), 380.0, "27c8ff"]]},
	"pillars": {"fill": "141030", "grid": "a08cff", "border": "b39bff", "pillar": "8a7fd0", "ambient": "fireflies",
		"glows": [[Vector2(300, 500), 200.0, "b39bff"], [Vector2(700, 500), 200.0, "b39bff"]]},
	"bumpers": {"fill": "160f2e", "grid": "ff6fae", "border": "ff6fae", "pillar": "6d79b8", "ambient": "sparks",
		"glows": [[Vector2(500, 500), 300.0, "ff6fae"]]},
	"wells": {"fill": "0c0822", "grid": "b36bff", "border": "b36bff", "pillar": "6d79b8", "ambient": "stars",
		"glows": [[Vector2(320, 320), 260.0, "7a3cff"], [Vector2(680, 680), 260.0, "7a3cff"]]},
	"spikes": {"fill": "1a0c22", "grid": "ff3d7f", "border": "ff5a9a", "pillar": "6d79b8", "ambient": "embers",
		"glows": [[Vector2(500, 500), 360.0, "ff3d7f"]]},
	"frost": {"fill": "0d1a33", "grid": "bfe9ff", "border": "9fd8ff", "pillar": "9fc4e8", "ambient": "snow",
		"glows": [[Vector2(500, 500), 360.0, "bfe9ff"]]},
	"magma": {"fill": "1f0b0b", "grid": "ff7a1f", "border": "ff6a2a", "pillar": "8a4a3a", "ambient": "embers",
		"glows": [[Vector2(110, 110), 320.0, "ff4500"], [Vector2(890, 890), 320.0, "ff4500"]]},
	"arcade": {"fill": "120a24", "grid": "9b7bff", "border": "7cff9b", "pillar": "6d79b8", "ambient": "wisps",
		"glows": [[Vector2(150, 500), 220.0, "7cff9b"], [Vector2(850, 500), 220.0, "c77dff"]]},
	"starfall": {"fill": "070a24", "grid": "8ab4ff", "border": "ffd166", "pillar": "6d79b8", "ambient": "stars",
		"glows": [[Vector2(500, 500), 420.0, "ffd166"]]},
	"factory": {"fill": "10141c", "grid": "ffd23f", "border": "ffd23f", "pillar": "7a8494", "ambient": "sparks",
		"glows": [[Vector2(500, 320), 260.0, "ffd23f"], [Vector2(500, 680), 260.0, "ffd23f"]]},
	"orbit": {"fill": "08081f", "grid": "7aa7ff", "border": "a8c8ff", "pillar": "c9a6ff", "ambient": "stars",
		"glows": [[Vector2(500, 500), 300.0, "5a7dff"]]},
	"hive": {"fill": "1c1408", "grid": "ffb627", "border": "ffc94d", "pillar": "a07a2a", "ambient": "pollen",
		"glows": [[Vector2(300, 300), 220.0, "ffb627"], [Vector2(700, 700), 220.0, "ffb627"]]},
	"horizon": {"fill": "06041a", "grid": "e0b3ff", "border": "e0b3ff", "pillar": "6d79b8", "ambient": "stars",
		"glows": [[Vector2(500, 500), 440.0, "9b4dff"]]},
	"pinball": {"fill": "180a26", "grid": "4dd6ff", "border": "ff9de2", "pillar": "6d79b8", "ambient": "sparks",
		"glows": [[Vector2(300, 300), 200.0, "ff9de2"], [Vector2(700, 700), 200.0, "4dd6ff"]]},
	"reef": {"fill": "06192a", "grid": "5ff0e6", "border": "5ff0e6", "pillar": "ff8a8a", "ambient": "bubbles",
		"glows": [[Vector2(500, 500), 360.0, "3fd0c9"]]},
	"glitch": {"fill": "060f0a", "grid": "7cff4f", "border": "7cff4f", "pillar": "6d79b8", "ambient": "glitch",
		"glows": [[Vector2(300, 300), 200.0, "7cff4f"], [Vector2(700, 700), 200.0, "ff4fd8"]]},
	"inferno": {"fill": "1a0808", "grid": "ff5a1f", "border": "ffb347", "pillar": "8a4a3a", "ambient": "embers",
		"glows": [[Vector2(30, 500), 300.0, "ff4500"], [Vector2(970, 500), 300.0, "ff4500"]]},
	"thorn": {"fill": "0b1a10", "grid": "3fbf6a", "border": "6be38f", "pillar": "6d79b8", "ambient": "petals",
		"glows": [[Vector2(500, 500), 360.0, "3fbf6a"]]},
	# Boss maps (sim/arenas.gd BOSS_ARENAS).
	"forge": {"fill": "16100c", "grid": "ff8a3d", "border": "ffb347", "pillar": "5d6478", "ambient": "embers",
		"glows": [[Vector2(500, 500), 300.0, "ff6a1f"], [Vector2(80, 80), 200.0, "ff4500"], [Vector2(920, 920), 200.0, "ff4500"]]},
	"nest": {"fill": "1a1210", "grid": "c08a4a", "border": "e0a95f", "pillar": "ffd166", "ambient": "petals",
		"glows": [[Vector2(500, 500), 320.0, "ff6fae"]]},
	"plaza": {"fill": "1a0f24", "grid": "ffb627", "border": "ff6fae", "pillar": "6d79b8", "ambient": "sparks",
		"glows": [[Vector2(500, 380), 320.0, "ffb627"], [Vector2(330, 720), 160.0, "5ce1ff"], [Vector2(670, 720), 160.0, "ff6fae"]]},
	"shrine": {"fill": "0b0a1f", "grid": "8f86c9", "border": "c9a6ff", "pillar": "6a6488", "ambient": "wisps",
		"glows": [[Vector2(500, 500), 340.0, "8f6bff"], [Vector2(500, 150), 110.0, "ffd166"], [Vector2(150, 500), 110.0, "ffd166"], [Vector2(850, 500), 110.0, "ffd166"], [Vector2(500, 850), 110.0, "ffd166"]]},
	"rift": {"fill": "06101e", "grid": "4fd8ff", "border": "7af0ff", "pillar": "8ab4ff", "ambient": "sparks",
		"glows": [[Vector2(500, 500), 360.0, "2fa8ff"], [Vector2(120, 120), 160.0, "b366ff"], [Vector2(880, 880), 160.0, "b366ff"]]},
	"core": {"fill": "040a06", "grid": "7cff4f", "border": "ff4fd8", "pillar": "6d79b8", "ambient": "glitch",
		"glows": [[Vector2(500, 500), 380.0, "1f8f2f"], [Vector2(110, 500), 140.0, "ff4fd8"], [Vector2(890, 500), 140.0, "ff4fd8"]]},
}


static func get_theme(id: String) -> Dictionary:
	return THEMES.get(id, THEMES.square)
