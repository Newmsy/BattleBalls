# Battle Balls

A mobile auto-battler: balls with abilities bounce around a square arena and
fight. Built with Godot 4.3 (GDScript, Compatibility renderer) so it runs in
mobile Safari as a web build and later ships to iOS / Google Play.

## Layout

| Path | What lives there |
|---|---|
| `sim/` | The deterministic fight simulation. Pure GDScript, no nodes or engine physics. Same config, same fight. |
| `game/` | The playable scene: menu, aim, fight rendering, result. Reads the sim; never changes its rules. |
| `tests/` | Headless test suite: unit tests, determinism, golden replays. |
| `tools/` | Headless utilities: `balance.gd` (win-rate matrix), `boon_balance.gd` (Bounce Run boons), `record_golden.gd`. `tools/sfx/make_sfx.py` renders every sound into `game/audio/`. |
| `smoke/` | Playwright smoke test that plays the web build in a phone-sized browser. |

## Commands

```sh
godot --headless --import                                   # once, after cloning
GODOT=godot tests/run.sh                                    # all tests
godot --headless --script res://tools/balance.gd -- --fights=200 --power-step
godot --headless --script res://tools/record_golden.gd      # only for intended sim changes
godot --headless --export-release "Web" build/web/index.html
cd smoke && npm ci && node smoke.mjs ../build/web
```

## Previews

CI builds every PR for the web and deploys it to Vercel (project
`battleballs`, token in the `VERCEL` repo secret). Each PR gets a comment
with its preview URL; `main` deploys to production. Smoke-test screenshots
are served at `<preview>/smoke/`.

URL params jump straight to a fight: `?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2`
(`aim` is the launch angle in tenths of a degree, screen space, y down).
`?sounds=1` opens the sound board: every sound with a play button.

## Sound

All sounds are generated from recipes in `tools/sfx/make_sfx.py`
(`python3 tools/sfx/make_sfx.py`, needs numpy and ffmpeg) and the rendered
files are committed. `game/audio/sfx.gd` plays them from sim events only and
uses its own random generator, so sound can never change a fight.

Share links (`game/fight_link.gd`) need no server because fights are
deterministic: `?r=1.laser.vampire.11.-300.1066` replays one exact fight, and
`?c=1.laser.11.-300` challenges a friend to beat that ball and shot. Result
screens make both links (Share fight, Challenge friend).

## Daily Trick Shot

A daily called bank shot (`sim/trick_shot.gd`, `game/trick_shot.gd`): your
ball and a resting foe are placed, and you get three tries to find the launch
angle that banks off the called walls in order and then hits the foe. The
puzzle comes from the local date alone (#1 is 2026-10-14), so every device
gets the same one with no server. The generator tries setups until 4-12 of
the 360 whole-degree aims solve it; a test checks every day of the first year.
Progress and streaks are saved to `user://trick_shot.cfg`.

Open it from the menu's Trick Shot button or with
`?mode=trickshot` (`&day=12` for another day, `&aim=166&auto=1` to shoot at once).

Changing ball radius or speed, or adding playable balls, reshapes the
puzzles. That is fine; `tests/test_trick_shot.gd` only fails if days stop
being solvable or fair.

## Bounce Run

A daily roguelite (`sim/bounce_run.gd`, `sim/boons.gd`, `game/bounce_run.gd`;
design in the project's `design/bounce-run.md`). Draft 3 of 5 critter cards
(each with its own starter boon), climb 8 floors, and pick 1 of 3 boons for
the whole trio after every win. A loss knocks that critter out; lose all three
and the run ends. Each floor's foe carries as many boons as you can hold there,
so every fight stays at equal power. The run comes from the UTC day (#1 is
2026-10-14) and is saved after every step to `user://bounce_run.cfg`.

The first run of the day is ranked and posts to the daily leaderboard
(`game/online/bounce_board.gd`, `supabase/migrations/*_bounce_run.sql`);
offline it plays the same and posts later. Open it from the Play tab or with
`?mode=bouncerun` (`&day=3` plays another day's run, unranked).

Boons are balanced by `tools/boon_balance.gd`: each one held at equal power
must win 52-62%, and CI fails one over 65%. `--runs=300` plays whole random
runs to check every floor stays near 50%.

## Rules for changes

- Fights must stay deterministic: no `randf()`, `Time`, engine physics or
  frame-rate-dependent logic in `sim/`. Use `sim/rng.gd`.
- If a change alters the outcome of a golden replay, re-record it with
  `tools/record_golden.gd` and say so in the PR as an intended balance change.
- Balance follows [BALANCE.md](BALANCE.md): power beats counters, no equal-power
  matchup over 65%, no hard counters. PRs that add a critter or touch ball stats
  paste the `balance.gd --power-step` output.

## Merging

When every CI job passes on a PR that is **not a draft**, the `Auto-merge` job
squash-merges it and rebuilds `main`. Keep a PR in draft until its code review
is done; marking it ready re-runs CI and merges it once green.
