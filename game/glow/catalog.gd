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
]

## Featured bundles: fixed contents, separate prices shown, honest saving.
const BUNDLES := [
	{"id": "bundle_party", "name": "Party Starter", "items": ["hat_party", "trail_sparkle", "ko_confetti"], "gems": 950},
	{"id": "bundle_glitch", "name": "Glitch Mode", "items": ["hat_phones", "trail_pixel", "spark_glitch", "ko_pixel"], "gems": 1350},
	{"id": "bundle_royal", "name": "Royal Court", "items": ["hat_crown", "spark_hearts", "ko_disco"], "gems": 1050},
	{"id": "bundle_comic", "name": "Comic Book", "items": ["hat_tophat", "spark_pow", "trail_rainbow"], "gems": 1100},
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
## purchase; the rest are earned (pass free track, bounties).
const POWER_KINDS := ["orbs", "coins", "energy", "xp_chip", "copies"]


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


static func color(it: Dictionary, i := 0) -> Color:
	var cols: Array = it.get("colors", ["ffffff"])
	return Color(cols[mini(i, cols.size() - 1)])
