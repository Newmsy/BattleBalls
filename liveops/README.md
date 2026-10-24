# Live-ops schedule

`liveops.json` plans the season ahead: the season and its week number, any
hand-picked Fight of the Day and the Bracket of Legends. The Daily board and
the Home Daily door read it through `game/liveops.gd`.

The file ships inside every build and is also served next to the web build
(`/liveops.json`, copied by CI). At boot the game downloads it, and a valid
download is cached on the device and wins over the bundled copy, so a store
build can pick up a new schedule without an update. A download that fails
`LiveOps.validate()` is ignored.

Anything the file leaves out falls back to a rotation worked out from the
clock (week 0 is Monday 2026-01-05), so offline play
and unplanned weeks still show something sensible.

## Format

All dates are `YYYY-MM-DD`, UTC. Weeks start Monday 00:00 UTC.

| Key | Entry | Notes |
|---|---|---|
| `version` | number | The format version. Bump it only if the format changes. |
| `revision` | number | **Bump it on every edit.** A cached or downloaded schedule is only used if its revision is at least the bundled one, so an old cache never hides a newer build's plan. |
| `seasons` | `{name, start, weeks, debut?}` | `start` is a Monday. Seven weeks per season (design/monetisation.md). Each season gets a fresh Glow Pass; `debut` (a roster id) is the critter whose 3 copies sit on the pass's free track. |
| `fights` | `{date, p1, p2, seed, angles?, title?}` | Optional showcase fights; `p1`/`p2` must be playable in the sim. Days without one get a close fight generated from the date. |
| `brackets` | `{week, seed, name?, entrants?}` | Bracket of Legends (`game/legends.gd`, `sim/bracket.gd`). `week` is the Monday of the week its rounds come out; picks open the Monday before. `entrants` (2 to 64 playable ids) defaults to every playable critter in the build. A season with no entry gets one in its last week. |

## Planning a season

1. Add the season.
2. Optionally schedule the season's Bracket of Legends (otherwise it runs in
   the last week). Once store builds exist, list `entrants` before picks open
   so an old build can't run a different field.
3. Optionally pin showcase fights (find a good seed with `?p1=..&p2=..&seed=..&auto=1`).
4. `tests/run.sh` checks the file (`test_liveops.gd`). Merge; the next deploy
   serves it.
5. Preview any day on the board with `?today=2026-11-20`.

Older schedules may still carry `chaos` and `loaners` lists (Chaos Weekends
and Try-a-Critter were removed on 2026-10-24); the game ignores them.
