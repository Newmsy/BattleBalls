## Economy tuning: summon odds, drop tables and Summon Egg income, plus the
## pacing targets they have to hit (design/pve.md section 6). One place for the
## numbers so the campaign, the Summon Portal and the economy model agree.
##
## Rules this file must keep (design/monetisation.md): money never buys power,
## Summon Eggs are earned only, spare copies never turn into XP.
##
## meta/economy_model.gd plays simulated casual, regular and heavy players
## through these numbers; tools/economy_sim.gd prints the report and
## tests/test_economy.gd fails if the pacing drifts out of its targets.
extends RefCounted

const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]

## The launch set (design/roster.md: 35 critters), by rarity as the critter
## files in sim/critters/ have it (Chill and Bramble are Rare there, Uncommon
## in roster.md).
const LAUNCH := {
	"common": ["vampire", "juggernaut", "spiker", "speedster", "crumb", "pip", "gumdrop"],
	"uncommon": ["shelly", "fin", "static", "cogs", "bolt", "drum", "frost", "thorns"],
	"rare": ["magmo", "clam", "laser", "bomber", "comet", "zing", "gust"],
	"epic": ["wrecker", "brewster", "splitter", "ghost", "gravity", "mirror", "magnet"],
	"legendary": ["phoenix", "megabot", "prism", "quasar", "frostfang", "blackhole"],
}

## One rarity step is a whole tier of power: x1.25 (BALANCE.md rule 5).
const RARITY_STEP := 1.25
const TIER_STEP := 1.25
const LEVEL_STEP := 0.025
const MAX_TIER := 5

## Summon Portal and campaign drop rolls, percent per rarity. A x10 always
## holds a Rare or better; every Rare-or-better roll counts down the shared
## Legendary pity.
const SUMMON_ODDS := {"common": 50.0, "uncommon": 28.0, "rare": 15.0, "epic": 5.5, "legendary": 1.5}
const PITY_RESET := 50

## Summon Egg income. All earned by playing (never sold): a x10 costs 10.
## Steady and small, so the first Legendary lands in week 2 and summons stay
## a treat next to campaign drops.
const STARTER_ORBS := 10
const ORBS_DAILY_LOGIN := 2 ## Includes the Daily Trick Shot reward.
const ORBS_PER_WEEK_STREAK := 12 ## On every 7th day played in a row.
const ORBS_BOSS_FIRST_CLEAR := 5
const ORBS_PER_ACCOUNT_LEVEL := 0 ## Account levels already refill energy.

## Campaign drops (Newms 2026-10-15: "heavier on orbs, 25% for a specific
## critter"): a win drops a copy of one of the zone's featured critters with
## this chance. That copy is the zone's next-rarity-up critter instead with the
## bonus chance. First clears always add the beaten enemy; a boss's first clear
## adds its guaranteed reward.
const CAMPAIGN_DROP_CHANCE := 0.25
## Summon Eggs from campaign wins (Newms 2026-10-25, progression check): any
## win, watched or swept, pays ORBS_CAMPAIGN_WIN on this chance (it was 75% of
## wins, which made sweeping an egg tap), and a stage's first clear always
## pays ORBS_FIRST_CLEAR on top.
const CAMPAIGN_EGG_CHANCE := 0.3
const ORBS_CAMPAIGN_WIN := 1
const ORBS_FIRST_CLEAR := 1
const CAMPAIGN_RARE_BONUS := 0.08

## Campaign drop pools per zone: six featured critters (what a win drops), the
## next-rarity-up bonus pool and the boss's guaranteed first-clear reward. A
## stage's enemy (dropped on its first clear) is `enemies[N]`, or
## featured[N % 6] when a zone has no list. Every launch critter drops
## somewhere (Megabot and Frostfang are summon-only). Zone 1 is meta/zones.gd
## plus Crumb and Pip, the launch Commons; zones 2-7 follow pve.md's zone
## themes and are the plan until they are built.
const ZONE_DROPS := [
	{"featured": ["vampire", "spiker", "speedster", "juggernaut", "crumb", "pip"], "bonus": ["laser"], "boss": "laser",
		"enemies": ["spiker", "speedster", "vampire", "juggernaut", "spiker", "speedster", "juggernaut", "vampire", "spiker", "speedster", "juggernaut"]},
	{"featured": ["gumdrop", "crumb", "static", "cogs", "bolt", "shelly"], "bonus": ["laser", "mirror"], "boss": "mirror"},
	{"featured": ["pip", "frost", "fin", "shelly", "drum", "static"], "bonus": ["bomber", "comet"], "boss": "bomber"},
	{"featured": ["thorns", "drum", "cogs", "fin", "magmo", "clam"], "bonus": ["splitter", "wrecker"], "boss": "splitter"},
	{"featured": ["bolt", "frost", "thorns", "zing", "gust", "comet"], "bonus": ["ghost", "gravity"], "boss": "ghost"},
	{"featured": ["cogs", "shelly", "magmo", "zing", "laser", "gravity"], "bonus": ["blackhole", "prism"], "boss": "brewster"},
	{"featured": ["fin", "bolt", "gust", "clam", "wrecker", "brewster"], "bonus": ["phoenix", "quasar"], "boss": "magnet"},
]

## Zone 1 as built before this check: the four Commons in the sim, every win
## drops one, 5% Optic instead.
const ZONE1_AS_BUILT := {"featured": ["spiker", "speedster", "vampire", "juggernaut"], "bonus": ["laser"], "boss": "laser",
	"enemies": ["spiker", "speedster", "vampire", "juggernaut", "spiker", "speedster", "juggernaut", "vampire", "spiker", "speedster", "juggernaut"]}

## Gear (design/gear.md, design/bosses.md). Hammers to merge three pieces of
## a tier into one of the next (index 0 is 1 star, which is never merged into).
## Hammers come from the Anvil King (meta/gear_vault.gd), earned only, never sold.
const GEAR_MERGE_COST := [0, 2, 4, 8, 16]
## The Forge stall beside the Anvil King (Newms 2026-10-25, progression
## check): coins had almost nothing to buy, so they buy a few Hammers a day.
## Coins are earned only, so this stays earned-only too.
const FORGE_HAMMER_COINS := 200
const FORGE_DAILY := 5
## Every save starts with these (and older saves get them once), so the first
## merges from campaign gear don't wait for the Anvil King.
const STARTER_HAMMERS := 10
## A campaign win drops a piece this often (Newms 2026-10-15: 20%), better on
## later stages and zones (gear_tier); a boss's first clear always drops one
## at GEAR_BOSS_TIER, plus one more star per zone.
const GEAR_CAMPAIGN_CHANCE := 0.2
const GEAR_BOSS_TIER := 2
## Stages from this one on (0-based) in a zone drop gear one star better.
const GEAR_STEP_STAGE := 6


## The star tier of a campaign win's gear drop: 1 star in Glow Garden's first
## stages, +1 from GEAR_STEP_STAGE on, +1 per zone after the first, up to 5.
static func gear_tier(zone_index: int, stage_index: int) -> int:
	return clampi(1 + zone_index + (1 if stage_index >= GEAR_STEP_STAGE else 0), 1, 5)
## The Spire's boss-floor gear is in sim/spire.gd (BOSS_GEAR).

## Pacing targets for a ~15-20 minute a day player (pve.md section 6), as
## [earliest, latest] day; day 1 is install day. The regular player's median
## must land inside each window. First T4 was "week 3-4"; it is "week 2-4"
## now because onboarding hands out a T2 starter, a head start the 15-critter
## targets didn't have.
## Orb-heavy campaign drops (2026-10-15) bring Rare+, Legendary and T4
## earlier through summons, so those windows open sooner (Newms' drop ask
## wins over the old windows).
const TARGETS := {
	"first_fusion": [1, 1],
	"t2_uncommon": [1, 3],
	"t3_common": [1, 4],
	"t2_rare": [1, 6],
	"legendary": [2, 16],
	"t4": [10, 30],
	"t5_common": [45, 90],
}
## Casual players may take up to this many times the target's latest day;
## heavy players must not reach a week-scale goal sooner than this share of
## its earliest day.
const CASUAL_SLACK := 2.0
const HEAVY_FLOOR := 0.4


## The live tuning as a config for meta/economy_model.gd.
static func tuned() -> Dictionary:
	return {
		"name": "tuned",
		"odds": SUMMON_ODDS, "pity": PITY_RESET,
		"starter_orbs": STARTER_ORBS, "orbs_daily": ORBS_DAILY_LOGIN,
		"orbs_level": ORBS_PER_ACCOUNT_LEVEL, "orbs_boss": ORBS_BOSS_FIRST_CLEAR, "orbs_win": ORBS_CAMPAIGN_WIN,
		"orbs_streak": ORBS_PER_WEEK_STREAK,
		"campaign_drop": CAMPAIGN_DROP_CHANCE, "zone_drops": ZONE_DROPS, "campaign_bonus": CAMPAIGN_RARE_BONUS,
	}


## The numbers before this check: zone 1's four-Common pool with a copy on
## every win (5% Optic), the Uncommon-era summon odds and starter orbs only
## (no orb income existed in code). Zones 2-7 use the same plan as tuned().
static func as_built() -> Dictionary:
	var c := tuned()
	c.name = "as built"
	c.orbs_daily = 0
	c.orbs_level = 0
	c.orbs_boss = 0
	c.orbs_win = 0
	c.orbs_streak = 0
	c.campaign_drop = 1.0
	c.campaign_bonus = 0.05
	c.zone_drops = ZONE_DROPS.duplicate()
	c.zone_drops[0] = ZONE1_AS_BUILT
	return c


static func rarity_of(id: String) -> String:
	for r in LAUNCH:
		if id in LAUNCH[r]:
			return r
	return ""


static func rarity_multiplier(rarity: String) -> float:
	return pow(RARITY_STEP, RARITIES.find(rarity))


## Power multiplier of a critter, 1.0 for a T1 level 1 Common (sim/power.gd).
static func power(rarity: String, tier: int, level: int) -> float:
	return rarity_multiplier(rarity) * pow(TIER_STEP, tier - 1) * (1.0 + LEVEL_STEP * (level - 1))

## Lures (from the Prism Wyrm) a guaranteed copy of a wishlisted critter costs, by rarity.
const LURE_COST := {"common": 1, "uncommon": 2, "rare": 4, "epic": 8, "legendary": 16}
