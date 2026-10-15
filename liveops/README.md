# Live-ops schedule

`liveops.json` plans the season ahead: the season and its week number, the
weekly Critter Spotlight, each Chaos Weekend's twist, any hand-picked Fight
of the Day and each day's Try-a-Critter loaner. The This Week board (Play
tab), the Summon Portal's featured critter, the Fight of the Day and the
loaner all read it through `game/liveops.gd`.

The file ships inside every build and is also served next to the web build
(`/liveops.json`, copied by CI). At boot the game downloads it, and a valid
download is cached on the device and wins over the bundled copy, so a store
build can pick up a new schedule without an update. A download that fails
`LiveOps.validate()` is ignored.

Anything the file leaves out falls back to a rotation worked out from the
clock (same week 0 as the Chaos rotation, Monday 2026-01-05), so offline play
and unplanned weeks still show something sensible.

## Format

All dates are `YYYY-MM-DD`, UTC. Weeks start Monday 00:00 UTC.

| Key | Entry | Notes |
|---|---|---|
| `version` | number | The format version. Bump it only if the format changes. |
| `revision` | number | **Bump it on every edit.** A cached or downloaded schedule is only used if its revision is at least the bundled one, so an old cache never hides a newer build's plan. |
| `seasons` | `{name, start, weeks}` | `start` is a Monday. Seven weeks per season (design/monetisation.md). |
| `spotlight` | `{week, critter, blurb}` | `week` is a Monday; `critter` is any roster id (`game/ui/roster.gd`). It takes half the rolls of its rarity in the Summon Portal. |
| `chaos` | `{weekend, modifier}` | `weekend` is the Friday; `modifier` is an id from `sim/modifiers.gd` (design/events.md). |
| `fights` | `{date, p1, p2, seed, angles?, title?}` | Optional showcase fights; `p1`/`p2` must be playable in the sim. Days without one get a close fight generated from the date. |
| `loaners` | `{date, critter, blurb?}` | Try-a-Critter: the critter lent for the day (UTC) to everyone who doesn't own it (`game/loaner.gd`). Any roster id passes validation, but the bundled file may only name critters the sim can play; a build that can't play a downloaded pick uses the rotation instead. Days without one rotate through the playable critters, rarest first. |

## Planning a season

1. Add the season, its seven Spotlight weeks and seven Chaos weekends.
2. Optionally pin showcase fights (find a good seed with `?p1=..&p2=..&seed=..&auto=1`).
3. `tests/run.sh` checks the file (`test_liveops.gd`). Merge; the next deploy
   serves it.
4. Preview any day on the board with `?today=2026-11-20`.
