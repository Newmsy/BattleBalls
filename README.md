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
| `tools/` | Headless utilities: `balance.gd` (win-rate matrix), `record_golden.gd`. `tools/sfx/make_sfx.py` renders every sound into `game/audio/`. |
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
