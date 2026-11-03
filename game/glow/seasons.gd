## Each season's Glow Pass looks: which cosmetics sit at which level on the
## free and premium tracks. A season in liveops/liveops.json names its set
## with `"pass": "<id>"`; a season without one (the Preseason) uses the
## original tables in game/glow/glow_pass.gd.
##
## The plan for the next five seasons lives in the project's
## design/glow-pass-seasons.md. Rules (tests/test_glow.gd checks them):
## - PREMIUM_LEVELS hold the season's looks (the other premium levels give
##   gems, Summon Eggs and energy: game/glow/glow_pass.gd); free levels hold
##   the power rewards plus a few looks. Every cosmetic here is a pass exclusive in
##   game/glow/catalog.gd (where pass_premium / pass_free) and never sold.
## - Old pass cosmetics never come back as they were: each set is new.
## - Premium cosmetics sit on the levels in PREMIUM_LEVELS, so the premium
##   track's gems (every other even level) stay the same every season.
extends RefCounted

## Levels that carry a premium cosmetic: the headline at 1, the showpiece at 50.
const PREMIUM_LEVELS := [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]
## Levels that carry a free-track cosmetic.
const FREE_LEVELS := [5, 15, 30]

## id -> {name, accent (hex, the pass header and medal), premium: {level: id}, free: {level: id}}
const SETS := {
	"s1_neon_nights": {
		"name": "Neon Nights", "accent": "ff3df0",
		"premium": {1: "hat_s1_shades", 5: "spark_s1_tube", 10: "trail_s1_streak", 15: "hat_s1_antenna", 20: "ko_s1_sign",
			25: "trail_s1_grid", 30: "hat_s1_visor", 35: "spark_s1_notes", 40: "hat_s1_mohawk", 45: "ko_s1_fireworks", 50: "ko_s1_eq"},
		"free": {5: "hat_s1_cap", 15: "trail_s1_comet", 30: "spark_s1_rings"},
	},
	"s2_frost_fest": {
		"name": "Frost Fest", "accent": "8fe6ff",
		"premium": {1: "hat_s2_antlers", 5: "spark_s2_sparks", 10: "trail_s2_trail", 15: "hat_s2_earmuffs", 20: "ko_s2_shatter", 25: "trail_s2_ribbon", 30: "hat_s2_scarf", 35: "spark_s2_stars", 40: "hat_s2_crown", 45: "ko_s2_hailstorm", 50: "ko_s2_globe"},
		"free": {5: "hat_s2_beanie", 15: "trail_s2_breath", 30: "spark_s2_rings"},
	},
	"s3_glow_garden": {
		"name": "Glow Garden", "accent": "c9a0ff",
		"premium": {1: "hat_s3_crown", 5: "spark_s3_pops", 10: "trail_s3_drift", 15: "hat_s3_sprout", 20: "ko_s3_burst", 25: "trail_s3_trail", 30: "hat_s3_halo", 35: "spark_s3_stars", 40: "hat_s3_antennae", 45: "ko_s3_shower", 50: "ko_s3_bloom"},
		"free": {5: "hat_s3_cap", 15: "trail_s3_breeze", 30: "spark_s3_rings"},
	},
	"s4_abyss_lights": {
		"name": "Abyss Lights", "accent": "2fd6ff",
		"premium": {1: "hat_s4_lure", 5: "spark_s4_pops", 10: "trail_s4_cloud", 15: "hat_s4_cap", 20: "ko_s4_whirlpool", 25: "trail_s4_ribbon", 30: "hat_s4_crown", 35: "spark_s4_pings", 40: "hat_s4_horns", 45: "ko_s4_burst", 50: "ko_s4_school"},
		"free": {5: "hat_s4_mask", 15: "trail_s4_bubbles", 30: "spark_s4_sparks"},
	},
	"s5_summer_splash": {
		"name": "Summer Splash", "accent": "ffc23d",
		"premium": {1: "hat_s5_hat", 5: "spark_s5_sparks", 10: "trail_s5_wake", 15: "hat_s5_ring", 20: "ko_s5_crash", 25: "trail_s5_ribbon", 30: "hat_s5_shades", 35: "spark_s5_jams", 40: "hat_s5_mohawk", 45: "ko_s5_bonfire", 50: "ko_s5_sun"},
		"free": {5: "hat_s5_cap", 15: "trail_s5_breeze", 30: "spark_s5_rings"},
	},
}


static func has(id: String) -> bool:
	return SETS.has(id)


## The cosmetic at `level` on `track` ("free" or "premium") of set `id`, or "".
static func cosmetic(id: String, track: String, level: int) -> String:
	return str(SETS.get(id, {}).get(track, {}).get(level, ""))


## Every cosmetic in set `id`, premium first, by level.
static func cosmetic_ids(id: String) -> Array:
	var s: Dictionary = SETS.get(id, {})
	var out := []
	for track in ["premium", "free"]:
		var levels: Array = s.get(track, {}).keys()
		levels.sort()
		for l in levels:
			out.append(s[track][l])
	return out


static func accent(id: String, fallback: Color) -> Color:
	return Color(str(SETS[id].accent)) if SETS.has(id) else fallback
