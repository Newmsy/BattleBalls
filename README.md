# Battle Balls

A mobile auto-battler: balls with abilities bounce around a square arena and
fight. Built with Godot 4.3 (GDScript, Compatibility renderer) so it runs in
mobile Safari as a web build and later ships to iOS / Google Play.

## Layout

| Path | What lives there |
|---|---|
| `sim/` | The deterministic fight simulation. Pure GDScript, no nodes or engine physics. Same config, same fight. |
| `game/` | The playable scene: menu, aim, fight rendering, result. Reads the sim; never changes its rules. |
| `game/online/` | Offline-first online layer: Supabase guest accounts, local + cloud save, Ghost Arena lineups. |
| `supabase/` | Database migrations (tables, row-level security, RPCs). CI applies them to the live project from `main`. |
| `tests/` | Headless test suite: unit tests, determinism, golden replays. `tests/db/` tests the migrations on plain Postgres. |
| `tools/` | Headless utilities: `balance.gd` (win-rate matrix), `record_golden.gd`. |
| `smoke/` | Playwright smoke test that plays the web build in a phone-sized browser. |

## Commands

```sh
godot --headless --import                                   # once, after cloning
GODOT=godot tests/run.sh                                    # all tests
godot --headless --script res://tools/balance.gd -- --fights=200 --power-step
godot --headless --script res://tools/record_golden.gd      # only for intended sim changes
godot --headless --export-release "Web" build/web/index.html
cd smoke && npm ci && node smoke.mjs ../build/web
DATABASE_URL=postgresql://... tests/db/run.sh               # migrations + RLS tests on an empty Postgres
```

## Previews

CI builds every PR for the web and deploys it to Vercel (project
`battleballs`, token in the `VERCEL` repo secret). Each PR gets a comment
with its preview URL; `main` deploys to production. Smoke-test screenshots
are served at `<preview>/smoke/`.

URL params jump straight to a fight: `?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2`
(`aim` is the launch angle in tenths of a degree, screen space, y down).

## Online backend (Supabase)

The game plays fully offline; the backend adds guest accounts, cloud save and
Ghost Arena (async PvP) storage. CI writes `backend_config.json` (URL + public
key) into the web build from repo secrets; without them the build is offline.

| Repo secret | What | Used by |
|---|---|---|
| `SUPABASE_URL` | `https://<ref>.supabase.co` | web build, migrations |
| `SUPABASE_ANON_KEY` | publishable (`sb_publishable_...`) or legacy anon key | web build (public by design) |
| `SUPABASE_ACCESS_TOKEN` | personal access token for the Supabase CLI | migrations only |
| `SUPABASE_DB_PASSWORD` | database password | migrations only |

- Never put a secret / `service_role` key in the game or a `SUPABASE_*` var the
  web job reads; CI refuses to build with one. All access control is
  row-level security plus `SECURITY DEFINER` functions in `supabase/migrations`.
- Schema changes are new migration files (never edit an applied one), with
  tests in `tests/db/`. They reach the live project when merged to `main`.
- `?offline=1` runs the web build without touching the backend.

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
