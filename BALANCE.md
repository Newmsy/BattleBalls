# Balance mantra

Every new critter, ability change, stat tweak and progression feature is held to
these rules. They come from Newms's design calls in the project design docs
(`combat-foundation.md`, `power-progression.md`, `critters.md`); if a rule here
and a design doc disagree, the design doc wins and this file gets fixed.

## The rules

1. **Power beats counters.** A ball one real progression step ahead (about one
   tier, +25% power) wins **70%+** even into its counter. This is not
   rock-paper-scissors.
2. **Counters are a tilt, not a verdict.** At equal power a favourable matchup
   is worth **55-60%**. Anything **over 65%** at equal power is a bug to fix.
3. **No hard counters.** Every ball can beat every other ball. No immunity, no
   ability that switches off another ability entirely (Ghost can't be immune
   to Laser).
4. **Tiers change the ability, not just the numbers.** Higher tiers feel
   different (longer beams, chained mines), and the T5 step is spectacular.
5. **One rarity step is worth about half a tier** (Newms, 2026-10-14), so
   about +12% power. There are five rarities (Common, Uncommon, Rare, Epic,
   Legendary), so a Legendary sits about **two tiers** above a Common of the
   same tier (Newms confirmed the full gap, 2026-10-14): a T1 Legendary
   roughly matches a T3 Common, a T1 Rare a T2 Common, and a T4 Common beats a
   T1 Legendary. A ball one rarity up against a same-tier ball one rarity down
   should win about **60%**, between equal power (50%) and a full tier (70%+).
   "Equal power" in rule 2 means same tier and same rarity.
6. **Fights stay watchable.** Median fight 20-60s, overtime ends stalls, and
   no build wins by running out the clock.
7. **The sim decides, not intuition.** Numbers come from the headless balance
   sim on fixed seeds, never from a few watched fights.

## Designing a new critter

Before the stats:
- One-sentence ability built from a trigger + effect (combat-foundation.md §2).
- Its role, the role it should edge, and what should beat it. Name the
  counter-play: how does a ball with no answer still win?
- Its rarity, and its T1 to T5 ladder, where T5 adds new behaviour. Complexity
  grows with rarity: Common a simple twist, Uncommon one clear trigger + effect,
  Rare a spatial effect, Epic a dynamic or two-part effect, Legendary a set piece.
  The full roster plan is `design/roster.md` in the project folder.
- Short player text: T1 <= 60 chars, tier lines as "Label old → new" or
  "+ New thing", a "now" line per tier that changes the ability (format in
  `sim/critters/_template.gd`).

In the PR that adds or changes it:
- Optional: a quick `godot --headless --script res://tools/balance.gd -- --fights=50 --power-step --only=<id>`
  sanity check. Balance never blocks a PR; misses get fixed in the next balance tune.
- Set `"status": "live"` in its file (`sim/critters/<id>.gd`) so the game, CI and the audit include it.
- Golden replays and unit tests for the ability, as for any sim change.

## Chaos Weekend modifiers

Weekend rule twists (`sim/modifiers.gd`) apply to both balls, but they still
shift matchups, so the same 65% limit and 20-60s median hold under every
modifier. Aim for 60% or less so new critters have headroom. A new critter
is checked under every modifier as well as base rules.

## What checks it

**Balance is not checked in CI** (Newms, 2026-10-15: "turn off the balance
checks for now and we can just periodically run them when we want to do a
balance tune"; "as little friction as possible from idea, implementation then
testing"). Only unit, determinism and golden replay tests, the web build and
the smoke test block a merge. Balance is tuned in batches: run the checks,
then fix every miss in one tuning PR.

| Check | How |
|---|---|
| Full audit: every pairing on every arena and Chaos Weekend modifier, power step and gear lines, 20 machines, one merged report | Actions > `Balance audit` > Run workflow (`.github/workflows/balance-audit.yml`) |
| One critter against the field | `balance.gd -- --fights=200 --power-step --arena=all --modifiers --only=<id>` |
| Gear lines: one 5-star piece of each stat line vs the same ball bare | `balance.gd -- --fights=300 --gear` |
| Rarity = half a tier: T1 Legendary vs T3 Common, T2 Rare and neighbours, real tiers (target ~50%) | `rarity_check.gd -- --pairs=150` |
| Bounce Run boons | `GODOT=<godot> tools/ci/boons.sh --fights=40` |

`balance.gd` options for big rosters: `--only=<ids|@sample>` limits the run to
pairings involving those critters, `--shard=k/n` splits it across machines,
`--out` / `--from` save and merge shard results, `--variant-fights=N` sets the
seeds for non-square arenas and modifiers, and past 16 critters the report
prints one row per critter instead of a matrix. `--strict` exits 1 on a `FAIL`
(`--edge-warn` softens arena and modifier misses to `WARN (audit FAIL)`).

`balance.gd` reports `FAIL` only when a miss is clear of sampling noise (95%
Wilson interval) and `WARN` when it might be noise; rerun a `WARN` with more
fights before acting on it. The `plain` ball is a reference baseline and is
excluded from the checks.

Progression power lives in `sim/power.gd`: rarity, tier and level combine into
one multiplier, passed to a fight as `powers`, which scales HP and every damage
stat by its square root (so HP x damage scales by the multiplier). The
power-step check fights at x1.25, one tier. Tier-specific ability upgrades
(longer beams, T5 behaviour) are still to come and will add on top. Add a
rarity-step check (target ~60%, rule 5) once there are same-role balls of
different rarity to compare.

## Arenas

Every arena in `Arenas.PLAYABLE` (`sim/arenas.gd`) is held to the same rules as
the square, plus two more (design/arenas.md):

- **Point-symmetric through the centre**, so neither start corner has an edge
  (`tests/test_arenas.gd` checks the layout and that mirror fights split evenly).
- **A tilt, not a verdict:** no playable matchup moves more than 10 points from
  its square result (`WARN`), and over 15 points clear of noise is a `FAIL`.

Audit reports are kept in the project's shared folder under
`balance/audits/`, one file per run, so trends are visible over time.

## Bounce Run boons

Boons are run-only perks (`sim/boons.gd`), so permanent balance is untouched,
but they still follow rule 2: one ball holding a boon against the same matchup
without it should win **52-62%** (a boon worth picking, never a verdict);
**over 65%** is a miss for the next balance tune (`tools/boon_balance.gd`, or
`tools/ci/boons.sh` for one boon per core; not run in CI).
The sim amplifies stat edges: +14% HP alone won 63%, so boon numbers stay
small. A new boon or a change to one pastes `boon_balance.gd -- --fights=200`
output into its PR.
