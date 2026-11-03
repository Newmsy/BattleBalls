## Every cosmetic, store product and Glow Pass reward, as data.
##
## Cosmetics are render-only (design/monetisation.md §1): nothing here is read
## by sim/, so a replay plays the same with or without them. A new cosmetic is
## one entry in ITEMS; its look is a style from game/glow/cosmetic_art.gd plus
## colours. Hats are built from the same shape kit as critter features.
##
## Rules this file must keep (tests/test_glow.gd checks them):
## - Money only buys Glow Gems, the premium pass and the Founder pack. Gems
##   only buy cosmetics and the premium pass. No power item has a price.
## - Nothing sold is random: every product says exactly what it gives.
## - No cosmetic colour is close to the YOU green or FOE pink rings.
extends RefCounted

const Dyes := preload("res://game/glow/dyes.gd")
const LiveOps := preload("res://game/liveops.gd")

const SLOTS := ["hat", "trail", "spark", "ko"]
const SLOT_NAMES := {"hat": "Hat", "trail": "Trail", "spark": "Hit spark", "ko": "KO effect"}

## where: shop (gems), basic (coins, basic colours only), pass_free,
## pass_premium, founder. Pass cosmetics are never sold in the shop.
## Prices from design/monetisation.md §3.
const ITEMS := [
	# Hats.
	{"id": "hat_party", "slot": "hat", "name": "Party Hat", "style": "cone", "colors": ["ff9e3d", "ffe066"], "where": "shop", "gems": 250},
	{"id": "hat_crown", "slot": "hat", "name": "Tiny Crown", "style": "crown", "colors": ["ffc23d", "fff2b0"], "where": "shop", "gems": 450},
	{"id": "hat_phones", "slot": "hat", "name": "Headphones", "style": "phones", "colors": ["3d9bff", "c9d3e0"], "where": "shop", "gems": 400},
	{"id": "hat_tophat", "slot": "hat", "name": "Top Hat", "style": "tophat", "colors": ["2a2550", "b366ff"], "where": "shop", "gems": 600},
	{"id": "hat_beanie", "slot": "hat", "name": "Neon Beanie", "style": "beanie", "colors": ["b366ff", "f0eeff"], "where": "basic", "coins": 1500},
	{"id": "hat_halo", "slot": "hat", "name": "Glow Halo", "style": "halo", "colors": ["fff2b0", "ffc23d"], "where": "pass_premium"},
	{"id": "hat_visor", "slot": "hat", "name": "Synth Visor", "style": "visor", "colors": ["5ce1ff", "8f7bff"], "where": "pass_premium"},
	{"id": "hat_horns", "slot": "hat", "name": "Neon Horns", "style": "horns", "colors": ["b366ff", "f0eeff"], "where": "pass_premium"},
	{"id": "hat_cap", "slot": "hat", "name": "Rookie Cap", "style": "cap", "colors": ["3d9bff", "f0eeff"], "where": "pass_free"},
	{"id": "hat_founder", "slot": "hat", "name": "Founder Crown", "style": "crown", "colors": ["c9d3e0", "8f7bff"], "where": "founder"},
	# Trails.
	{"id": "trail_sparkle", "slot": "trail", "name": "Sparkle Trail", "style": "sparkle", "colors": ["fff2b0", "ffc23d"], "where": "shop", "gems": 400},
	{"id": "trail_rainbow", "slot": "trail", "name": "Rainbow Trail", "style": "rainbow", "colors": ["ffffff", "ffffff"], "where": "shop", "gems": 400},
	{"id": "trail_pixel", "slot": "trail", "name": "Pixel Trail", "style": "pixel", "colors": ["5ce1ff", "8f7bff"], "where": "shop", "gems": 400},
	{"id": "trail_bubbles", "slot": "trail", "name": "Bubble Trail", "style": "bubbles", "colors": ["9fe8ff", "ffffff"], "where": "basic", "coins": 1200},
	{"id": "trail_comet", "slot": "trail", "name": "Comet Trail", "style": "comet", "colors": ["8f7bff", "f0eeff"], "where": "pass_free"},
	{"id": "trail_synth", "slot": "trail", "name": "Synthwave Trail", "style": "rainbow", "colors": ["ff8a3d", "b366ff"], "where": "pass_premium"},
	# Hit sparks.
	{"id": "spark_hearts", "slot": "spark", "name": "Heart Sparks", "style": "hearts", "colors": ["ff9ec7", "ffd6e8"], "where": "shop", "gems": 350},
	{"id": "spark_glitch", "slot": "spark", "name": "Glitch Sparks", "style": "glitch", "colors": ["5ce1ff", "b366ff"], "where": "shop", "gems": 350},
	{"id": "spark_pow", "slot": "spark", "name": "Comic POW", "style": "pow", "colors": ["ffe066", "ff9e3d"], "where": "shop", "gems": 350},
	{"id": "spark_stars", "slot": "spark", "name": "Star Sparks", "style": "stars", "colors": ["c9d3e0", "fff2b0"], "where": "basic", "coins": 1000},
	{"id": "spark_neon", "slot": "spark", "name": "Neon Rings", "style": "rings", "colors": ["8f7bff", "5ce1ff"], "where": "pass_premium"},
	# KO effects.
	{"id": "ko_confetti", "slot": "ko", "name": "Confetti Pop", "style": "confetti", "colors": ["ffe066", "5ce1ff"], "where": "shop", "gems": 500},
	{"id": "ko_disco", "slot": "ko", "name": "Disco Ball", "style": "disco", "colors": ["c9d3e0", "b366ff"], "where": "shop", "gems": 500},
	{"id": "ko_pixel", "slot": "ko", "name": "Pixel Shatter", "style": "shatter", "colors": ["8f7bff", "5ce1ff"], "where": "shop", "gems": 500},
	{"id": "ko_fireworks", "slot": "ko", "name": "Fireworks", "style": "fireworks", "colors": ["ffc23d", "b366ff"], "where": "pass_premium"},
	{"id": "ko_stars", "slot": "ko", "name": "Starburst", "style": "confetti", "colors": ["fff2b0", "c9d3e0"], "where": "pass_free"},
	# Neon Nights shop set: in the shop from its season on (game/glow/seasons.gd).
	{"id": "hat_s1_hoodie_shop", "slot": "hat", "name": "Night Hoodie", "style": "hoodie", "colors": ["5b3fd0", "ff3df0"], "where": "shop", "gems": 450, "capsule": "s1_neon_nights"},
	{"id": "spark_s1_surge_shop", "slot": "spark", "name": "Power Surge", "style": "zap", "colors": ["5ce1ff", "fff2b0"], "where": "shop", "gems": 350, "capsule": "s1_neon_nights"},
	{"id": "ko_s1_disco_shop", "slot": "ko", "name": "Afterparty Disco", "style": "disco", "colors": ["ff3df0", "5ce1ff"], "where": "shop", "gems": 500, "capsule": "s1_neon_nights"},
	# Frost Fest shop set: in the shop from its season on (game/glow/seasons.gd).
	{"id": "hat_s2_hat_shop", "slot": "hat", "name": "Ski Hat", "style": "pompom", "colors": ["e0402a", "f0fcff"], "where": "shop", "gems": 450, "capsule": "s2_frost_fest"},
	{"id": "spark_s2_splat_shop", "slot": "spark", "name": "Snowball Splat", "style": "snowball", "colors": ["f0fcff", "8fe6ff"], "where": "shop", "gems": 350, "capsule": "s2_frost_fest"},
	{"id": "ko_s2_confetti_shop", "slot": "ko", "name": "Snow Confetti", "style": "confetti", "colors": ["f0fcff", "8fb8ff"], "where": "shop", "gems": 500, "capsule": "s2_frost_fest"},
	# Glow Garden shop set: in the shop from its season on (game/glow/seasons.gd).
	{"id": "hat_s3_ears_shop", "slot": "hat", "name": "Bunny Ears", "style": "bunny", "colors": ["f0eeff", "ffb3e6"], "where": "shop", "gems": 450, "capsule": "s3_glow_garden"},
	{"id": "trail_s3_trail_shop", "slot": "trail", "name": "Vine Trail", "style": "vines", "colors": ["b8e05a", "ffe066"], "where": "shop", "gems": 400, "capsule": "s3_glow_garden"},
	{"id": "ko_s3_pop_shop", "slot": "ko", "name": "Pollen Pop", "style": "shatter", "colors": ["ffe066", "c9a0ff"], "where": "shop", "gems": 500, "capsule": "s3_glow_garden"},
	# Abyss Lights shop set: in the shop from its season on (game/glow/seasons.gd).
	{"id": "hat_s4_hat_shop", "slot": "hat", "name": "Pirate Hat", "style": "pirate", "colors": ["2a2550", "ffc23d"], "where": "shop", "gems": 450, "capsule": "s4_abyss_lights"},
	{"id": "spark_s4_sparks_shop", "slot": "spark", "name": "Pearl Sparks", "style": "pearl", "colors": ["f6f0ff", "c9c6ff"], "where": "shop", "gems": 350, "capsule": "s4_abyss_lights"},
	{"id": "ko_s4_confetti_shop", "slot": "ko", "name": "Treasure Confetti", "style": "confetti", "colors": ["ffc23d", "fff2b0"], "where": "shop", "gems": 500, "capsule": "s4_abyss_lights"},
	# Summer Splash shop set: in the shop from its season on (game/glow/seasons.gd).
	{"id": "hat_s5_cap_shop", "slot": "hat", "name": "Propeller Cap", "style": "propeller", "colors": ["3d9bff", "ffc23d"], "where": "shop", "gems": 450, "capsule": "s5_summer_splash"},
	{"id": "trail_s5_tail_shop", "slot": "trail", "name": "Kite Tail", "style": "kite", "colors": ["ff8a3d", "3d9bff"], "where": "shop", "gems": 400, "capsule": "s5_summer_splash"},
	{"id": "ko_s5_confetti_shop", "slot": "ko", "name": "Beach Confetti", "style": "confetti", "colors": ["ffc23d", "3fa9f5"], "where": "shop", "gems": 500, "capsule": "s5_summer_splash"},
	# Season 1: Neon Nights pass (game/glow/seasons.gd). Never sold.
	{"id": "hat_s1_shades", "slot": "hat", "name": "Night Drive Shades", "style": "shades", "colors": ["ff3df0", "5ce1ff"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "spark_s1_tube", "slot": "spark", "name": "Neon Tubes", "style": "tube", "colors": ["5ce1ff", "ff3df0"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "trail_s1_streak", "slot": "trail", "name": "Taillights", "style": "streak", "colors": ["ff8a3d", "b366ff"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "hat_s1_antenna", "slot": "hat", "name": "Glow Antennae", "style": "antenna", "colors": ["c9d3e0", "ffc23d"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "ko_s1_sign", "slot": "ko", "name": "Neon KO Sign", "style": "sign", "colors": ["ff3df0", "5ce1ff"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "trail_s1_grid", "slot": "trail", "name": "Synth Grid", "style": "grid", "colors": ["b366ff", "5ce1ff"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "hat_s1_visor", "slot": "hat", "name": "Midnight Visor", "style": "visor", "colors": ["ff3df0", "ffc23d"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "spark_s1_notes", "slot": "spark", "name": "Bass Notes", "style": "notes", "colors": ["ffc23d", "b366ff"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "hat_s1_mohawk", "slot": "hat", "name": "Neon Mohawk", "style": "mohawk", "colors": ["ff3df0", "5ce1ff"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "ko_s1_fireworks", "slot": "ko", "name": "Skyline Fireworks", "style": "fireworks", "colors": ["5ce1ff", "ff8a3d"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "ko_s1_eq", "slot": "ko", "name": "Bass Drop", "style": "eq", "colors": ["5ce1ff", "ff3df0"], "where": "pass_premium", "season": "s1_neon_nights"},
	{"id": "hat_s1_cap", "slot": "hat", "name": "Night Shift Cap", "style": "cap", "colors": ["8f7bff", "fff2b0"], "where": "pass_free", "season": "s1_neon_nights"},
	{"id": "trail_s1_comet", "slot": "trail", "name": "Neon Comet", "style": "comet", "colors": ["ff3df0", "fff2b0"], "where": "pass_free", "season": "s1_neon_nights"},
	{"id": "spark_s1_rings", "slot": "spark", "name": "Bassline Rings", "style": "rings", "colors": ["ffc23d", "ff3df0"], "where": "pass_free", "season": "s1_neon_nights"},
	# Season 2: Frost Fest pass (game/glow/seasons.gd). Never sold.
	{"id": "hat_s2_antlers", "slot": "hat", "name": "Frost Antlers", "style": "antlers", "colors": ["c9a27a", "dff6ff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "spark_s2_sparks", "slot": "spark", "name": "Snowflake Sparks", "style": "flake", "colors": ["dff6ff", "8fe6ff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "trail_s2_trail", "slot": "trail", "name": "Flurry Trail", "style": "snow", "colors": ["f0fcff", "8fb8ff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "hat_s2_earmuffs", "slot": "hat", "name": "Cosy Earmuffs", "style": "earmuffs", "colors": ["b07cff", "f0eeff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "ko_s2_shatter", "slot": "ko", "name": "Ice Shatter", "style": "shards", "colors": ["8fe6ff", "f0fcff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "trail_s2_ribbon", "slot": "trail", "name": "Aurora Ribbon", "style": "ribbon", "colors": ["5ce1ff", "b07cff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "hat_s2_scarf", "slot": "hat", "name": "Knitted Scarf", "style": "scarf", "colors": ["e0402a", "fff2b0"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "spark_s2_stars", "slot": "spark", "name": "Frost Stars", "style": "stars", "colors": ["8fe6ff", "f0fcff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "hat_s2_crown", "slot": "hat", "name": "Ice Crown", "style": "crown", "colors": ["9fe8ff", "f0fcff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "ko_s2_hailstorm", "slot": "ko", "name": "Hailstorm", "style": "shatter", "colors": ["dff6ff", "8f7bff"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "ko_s2_globe", "slot": "ko", "name": "Snow Globe", "style": "globe", "colors": ["dff6ff", "3d3bb0"], "where": "pass_premium", "season": "s2_frost_fest"},
	{"id": "hat_s2_beanie", "slot": "hat", "name": "Frost Beanie", "style": "beanie", "colors": ["3d9bff", "f0fcff"], "where": "pass_free", "season": "s2_frost_fest"},
	{"id": "trail_s2_breath", "slot": "trail", "name": "Frosty Breath", "style": "bubbles", "colors": ["dff6ff", "ffffff"], "where": "pass_free", "season": "s2_frost_fest"},
	{"id": "spark_s2_rings", "slot": "spark", "name": "Chill Rings", "style": "rings", "colors": ["8fe6ff", "8f7bff"], "where": "pass_free", "season": "s2_frost_fest"},
	# Season 3: Glow Garden pass (game/glow/seasons.gd). Never sold.
	{"id": "hat_s3_crown", "slot": "hat", "name": "Blossom Crown", "style": "flowercrown", "colors": ["ffc23d", "ffb3e6"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "spark_s3_pops", "slot": "spark", "name": "Blossom Pops", "style": "bloom", "colors": ["ffc23d", "f0eeff"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "trail_s3_drift", "slot": "trail", "name": "Petal Drift", "style": "petals", "colors": ["ffb3e6", "fff2b0"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "hat_s3_sprout", "slot": "hat", "name": "Little Sprout", "style": "sprout", "colors": ["b8e05a", "ffe066"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "ko_s3_burst", "slot": "ko", "name": "Butterfly Burst", "style": "butterflies", "colors": ["c9a0ff", "ffc23d"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "trail_s3_trail", "slot": "trail", "name": "Firefly Trail", "style": "fireflies", "colors": ["ffe066", "f0ffb0"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "hat_s3_halo", "slot": "hat", "name": "Daisy Halo", "style": "halo", "colors": ["ffffff", "ffe066"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "spark_s3_stars", "slot": "spark", "name": "Pollen Stars", "style": "stars", "colors": ["ffe066", "ff9e3d"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "hat_s3_antennae", "slot": "hat", "name": "Bumble Antennae", "style": "antenna", "colors": ["2a2550", "ffc23d"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "ko_s3_shower", "slot": "ko", "name": "Petal Shower", "style": "confetti", "colors": ["ffb3e6", "f0eeff"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "ko_s3_bloom", "slot": "ko", "name": "Giant Bloom", "style": "bigbloom", "colors": ["c9a0ff", "ffe066"], "where": "pass_premium", "season": "s3_glow_garden"},
	{"id": "hat_s3_cap", "slot": "hat", "name": "Gardener's Cap", "style": "cap", "colors": ["c9a27a", "fff2b0"], "where": "pass_free", "season": "s3_glow_garden"},
	{"id": "trail_s3_breeze", "slot": "trail", "name": "Spring Breeze", "style": "comet", "colors": ["fff2b0", "c9a0ff"], "where": "pass_free", "season": "s3_glow_garden"},
	{"id": "spark_s3_rings", "slot": "spark", "name": "Ripple Rings", "style": "rings", "colors": ["ffb3e6", "fff2b0"], "where": "pass_free", "season": "s3_glow_garden"},
	# Season 4: Abyss Lights pass (game/glow/seasons.gd). Never sold.
	{"id": "hat_s4_lure", "slot": "hat", "name": "Angler Lure", "style": "lure", "colors": ["3d3bb0", "a6fff0"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "spark_s4_pops", "slot": "spark", "name": "Bubble Pops", "style": "bubblepop", "colors": ["9fe8ff", "ffffff"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "trail_s4_cloud", "slot": "trail", "name": "Ink Cloud", "style": "ink", "colors": ["6f4cc0", "c9c6ff"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "hat_s4_cap", "slot": "hat", "name": "Jelly Cap", "style": "jelly", "colors": ["b07cff", "a6fff0"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "ko_s4_whirlpool", "slot": "ko", "name": "Whirlpool", "style": "whirlpool", "colors": ["2fb6e8", "c9c6ff"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "trail_s4_ribbon", "slot": "trail", "name": "Kelp Ribbon", "style": "ribbon", "colors": ["2fb6e8", "6f6bff"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "hat_s4_crown", "slot": "hat", "name": "Coral Crown", "style": "crown", "colors": ["ff8a3d", "ffd6a0"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "spark_s4_pings", "slot": "spark", "name": "Sonar Pings", "style": "rings", "colors": ["2fd6ff", "a6fff0"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "hat_s4_horns", "slot": "hat", "name": "Reef Horns", "style": "horns", "colors": ["ff9e3d", "fff2b0"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "ko_s4_burst", "slot": "ko", "name": "Plankton Burst", "style": "shatter", "colors": ["a6fff0", "3d9bff"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "ko_s4_school", "slot": "ko", "name": "Fish School", "style": "school", "colors": ["2fd6ff", "ffc23d"], "where": "pass_premium", "season": "s4_abyss_lights"},
	{"id": "hat_s4_mask", "slot": "hat", "name": "Diving Mask", "style": "visor", "colors": ["2fb6e8", "f0fcff"], "where": "pass_free", "season": "s4_abyss_lights"},
	{"id": "trail_s4_bubbles", "slot": "trail", "name": "Deep Bubbles", "style": "bubbles", "colors": ["2fd6ff", "c9c6ff"], "where": "pass_free", "season": "s4_abyss_lights"},
	{"id": "spark_s4_sparks", "slot": "spark", "name": "Starfish Sparks", "style": "stars", "colors": ["ff9e3d", "ffd6a0"], "where": "pass_free", "season": "s4_abyss_lights"},
	# Season 5: Summer Splash pass (game/glow/seasons.gd). Never sold.
	{"id": "hat_s5_hat", "slot": "hat", "name": "Straw Sun Hat", "style": "sunhat", "colors": ["e8c47a", "3d9bff"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "spark_s5_sparks", "slot": "spark", "name": "Splash Sparks", "style": "splash", "colors": ["3fa9f5", "dff6ff"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "trail_s5_wake", "slot": "trail", "name": "Jet Ski Wake", "style": "wake", "colors": ["dff6ff", "ffffff"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "hat_s5_ring", "slot": "hat", "name": "Rubber Ring", "style": "float", "colors": ["ff9e3d", "ffffff"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "ko_s5_crash", "slot": "ko", "name": "Wave Crash", "style": "wave", "colors": ["3fa9f5", "dff6ff"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "trail_s5_ribbon", "slot": "trail", "name": "Sunset Ribbon", "style": "ribbon", "colors": ["ff8a3d", "b366ff"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "hat_s5_shades", "slot": "hat", "name": "Beach Shades", "style": "shades", "colors": ["ffc23d", "3d3bb0"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "spark_s5_jams", "slot": "spark", "name": "Summer Jams", "style": "notes", "colors": ["ffe066", "3fa9f5"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "hat_s5_mohawk", "slot": "hat", "name": "Palm Mohawk", "style": "mohawk", "colors": ["e8c47a", "ffe066"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "ko_s5_bonfire", "slot": "ko", "name": "Beach Bonfire", "style": "fireworks", "colors": ["ff8a3d", "ffe066"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "ko_s5_sun", "slot": "ko", "name": "Midsummer Sun", "style": "sunburst", "colors": ["ffd23f", "ff8a3d"], "where": "pass_premium", "season": "s5_summer_splash"},
	{"id": "hat_s5_cap", "slot": "hat", "name": "Lifeguard Cap", "style": "cap", "colors": ["e0402a", "ffffff"], "where": "pass_free", "season": "s5_summer_splash"},
	{"id": "trail_s5_breeze", "slot": "trail", "name": "Sea Breeze", "style": "comet", "colors": ["9fe8ff", "ffffff"], "where": "pass_free", "season": "s5_summer_splash"},
	{"id": "spark_s5_rings", "slot": "spark", "name": "Splash Rings", "style": "rings", "colors": ["3fa9f5", "fff2b0"], "where": "pass_free", "season": "s5_summer_splash"},
]

## Featured bundles: fixed contents, separate prices shown, honest saving.
## A `capsule` bundle is a season's shop set (see `released`).
const BUNDLES := [
	{"id": "bundle_party", "name": "Party Starter", "items": ["hat_party", "trail_sparkle", "ko_confetti"], "gems": 950},
	{"id": "bundle_glitch", "name": "Glitch Mode", "items": ["hat_phones", "trail_pixel", "spark_glitch", "ko_pixel"], "gems": 1350},
	{"id": "bundle_royal", "name": "Royal Court", "items": ["hat_crown", "spark_hearts", "ko_disco"], "gems": 1050},
	{"id": "bundle_comic", "name": "Comic Book", "items": ["hat_tophat", "spark_pow", "trail_rainbow"], "gems": 1100},
	# Season sets: featured first while their season runs.
	{"id": "bundle_s1", "name": "Neon Nights Set", "items": ["hat_s1_hoodie_shop", "spark_s1_surge_shop", "ko_s1_disco_shop"], "gems": 1100, "capsule": "s1_neon_nights"},
	{"id": "bundle_s2", "name": "Frost Fest Set", "items": ["hat_s2_hat_shop", "spark_s2_splat_shop", "ko_s2_confetti_shop"], "gems": 1100, "capsule": "s2_frost_fest"},
	{"id": "bundle_s3", "name": "Glow Garden Set", "items": ["hat_s3_ears_shop", "trail_s3_trail_shop", "ko_s3_pop_shop"], "gems": 1150, "capsule": "s3_glow_garden"},
	{"id": "bundle_s4", "name": "Abyss Lights Set", "items": ["hat_s4_hat_shop", "spark_s4_sparks_shop", "ko_s4_confetti_shop"], "gems": 1100, "capsule": "s4_abyss_lights"},
	{"id": "bundle_s5", "name": "Summer Splash Set", "items": ["hat_s5_cap_shop", "trail_s5_tail_shop", "ko_s5_confetti_shop"], "gems": 1150, "capsule": "s5_summer_splash"},
]

## Real-money products, bought through game/glow/store.gd. kind: gems
## (consumable), pass (premium track for the season running at purchase) or
## unlock (non-consumable, restorable). USD; stores convert.
const PRODUCTS := [
	{"id": "gems_80", "kind": "gems", "gems": 80, "usd": "0.99"},
	{"id": "gems_450", "kind": "gems", "gems": 450, "usd": "4.99"},
	{"id": "gems_950", "kind": "gems", "gems": 950, "usd": "9.99"},
	{"id": "gems_2000", "kind": "gems", "gems": 2000, "usd": "19.99"},
	{"id": "gems_5300", "kind": "gems", "gems": 5300, "usd": "49.99"},
	{"id": "gems_11000", "kind": "gems", "gems": 11000, "usd": "99.99"},
	{"id": "glow_pass", "kind": "pass", "usd": "4.99", "name": "Glow Pass (this season)"},
	{"id": "founder", "kind": "unlock", "usd": "4.99", "name": "Founder Pack", "gems": 600, "items": ["hat_founder"]},
]

## Premium pass price in gems, as an alternative to the real-money product.
const PASS_GEMS := 500

## Things a grant can carry. Only "gems" and "cosmetic" may ever come from a
## purchase; the rest are earned (pass free track, quests).
const POWER_KINDS := ["orbs", "coins", "energy", "xp_chip", "copies", "gear"]


static func item(id: String) -> Dictionary:
	for it in ITEMS:
		if it.id == id:
			return it
	return {}


static func bundle(id: String) -> Dictionary:
	for b in BUNDLES:
		if b.id == id:
			return b
	return {}


static func product(id: String) -> Dictionary:
	for p in PRODUCTS:
		if p.id == id:
			return p
	return {}


## Whether a shop look or bundle is on sale at `t`: a season's shop set
## (`capsule`) opens when its season starts and then stays.
static func released(it: Dictionary, t: int) -> bool:
	return not it.has("capsule") or LiveOps.pass_started(str(it.capsule), t)


static func items_in(slot: String) -> Array:
	return ITEMS.filter(func(it): return it.slot == slot)


## Items you can buy in the shop at any time (gems or coins).
static func for_sale() -> Array:
	return ITEMS.filter(func(it): return it.where in ["shop", "basic"])


static func bundle_full_price(b: Dictionary) -> int:
	var n := 0
	for id in b.items:
		n += int(item(id).get("gems", 0))
	return n


## The cosmetic worn in `slot` of a loadout ({slot: id, "dye_<slot>": dye
## id}), with its Spark Dye on (game/glow/dyes.gd), or {}.
static func worn(loadout: Dictionary, slot: String) -> Dictionary:
	return Dyes.apply(item(str(loadout.get(slot, ""))), str(loadout.get("dye_" + slot, "")))


static func color(it: Dictionary, i := 0) -> Color:
	var cols: Array = it.get("colors", ["ffffff"])
	return Color(cols[mini(i, cols.size() - 1)])
