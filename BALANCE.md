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
5. **Rarity is a small edge.** One rarity step is about +5-10% base power, so a
   T2 Common beats a T1 Legendary more often than not.
6. **Fights stay watchable.** Median fight 20-60s, overtime ends stalls, and
   no build wins by running out the clock.
7. **The sim decides, not intuition.** Numbers come from the headless balance
   sim on fixed seeds, never from a few watched fights.

## Designing a new critter

Before the stats:
- One-sentence ability built from a trigger + effect (combat-foundation.md §2).
- Its role, the role it should edge, and what should beat it. Name the
  counter-play: how does a ball with no answer still win?
- Its rarity, and its T1 to T5 ladder, where T5 adds new behaviour.

In the PR that adds or changes it:
- Run `godot --headless --script res://tools/balance.gd -- --fights=200 --power-step`
  and paste the output (both tables) into the PR.
- No `FAIL` lines. Every `WARN` is either fixed or explained in the PR.
- Add it to `BallDefs.PLAYABLE` so CI and the audit include it.
- Golden replays and unit tests for the ability, as for any sim change.

## Chaos Weekend modifiers

Weekend rule twists (`sim/modifiers.gd`) apply to both balls, but they still
shift matchups, so the same 65% limit and 20-60s median hold under every
modifier. Aim for 60% or less so new critters have headroom. A new critter
is checked under every modifier as well as base rules.

## What checks it

| Check | When | Command |
|---|---|---|
| Equal-power matrix, base rules and every Chaos Weekend modifier, `FAIL` blocks merge | Every PR (CI `Sim tests` job) | `balance.gd -- --fights=100 --modifiers --strict` |
| Full audit: equal power and power step at higher sample size | Weekly scheduled balance audit on `main`, plus any PR touching ball stats | `balance.gd -- --fights=500 --power-step` |

`balance.gd` reports `FAIL` only when a miss is clear of sampling noise (95%
Wilson interval) and `WARN` when it might be noise; rerun a `WARN` with more
fights before acting on it. The `plain` ball is a reference baseline and is
excluded from the checks.

Until tiers exist in the sim, the power-step check stands in for a tier by
scaling HP and every damage stat by sqrt(1.25), so HP x damage is +25%. Replace
`_boost` in `tools/balance.gd` with the real tier system when it lands.

Audit reports are kept in the project's shared folder under
`balance/audits/`, one file per run, so trends are visible over time.
