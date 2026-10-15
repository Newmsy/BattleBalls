# Battle Balls

A mobile auto-battler: balls with abilities bounce around a square arena and
fight. Built with Godot 4.3 (GDScript, Compatibility renderer) so it runs in
mobile Safari as a web build and later ships to iOS / Google Play.

## Layout

| Path | What lives there |
|---|---|
| `sim/` | The deterministic fight simulation. Pure GDScript, no nodes or engine physics. Same config, same fight. |
| `meta/` | Progression outside a fight: the player profile (collection, fusion, energy, account level, campaign stars), campaign zones, drops. Pure logic, clock passed in. Saved in the SaveGame as `data.profile`. |
| `sim/critters/` | One file per critter: everything about it (see Adding a critter). |
| `game/` | The playable scene: menu, aim, fight rendering, result. Reads the sim and meta; never changes their rules. |
| `liveops/` | The live-ops schedule (`liveops.json`): seasons, Spotlight weeks, Chaos Weekends, Fight of the Day. See its README. |
| `game/online/` | Offline-first online layer: Supabase guest accounts, local + cloud save, Ghost Arena lineups. |
| `supabase/` | Database migrations (tables, row-level security, RPCs). CI applies them to the live project from `main`. |
| `game/glow/` | Glow Gems, cosmetics, the shop's store layer and the Glow Pass. Render-only: never read by `sim/`. |
| `tests/` | Headless test suite: unit tests, determinism, golden replays. `tests/db/` tests the migrations on plain Postgres. |
| `tools/` | Headless utilities: `balance.gd` (win-rate matrix), `pve_difficulty.gd` (campaign stage win rates by player power), `boon_balance.gd` (Bounce Run boons), `record_golden.gd`. `tools/sfx/make_sfx.py` renders every sound into `game/audio/`. |
| `smoke/` | Playwright smoke test that plays the web build in a phone-sized browser. |

## Commands

```sh
godot --headless --import                                   # once, after cloning
GODOT=godot tests/run.sh                                    # all tests
godot --headless --script res://tools/balance.gd -- --fights=200 --power-step [--arena=all] [--only=<id>]
godot --headless --script res://tools/record_golden.gd      # only for intended sim changes
godot --headless --script res://tools/spire_curve.gd        # The Spire's floor power curve
godot --headless --export-release "Web" build/web/index.html
cd smoke && npm ci && node smoke.mjs ../build/web
DATABASE_URL=postgresql://... tests/db/run.sh               # migrations + RLS tests on an empty Postgres
```

## Previews

CI builds every ready (non-draft) PR for the web and deploys it to Vercel
(project `battleballs`, token in the `VERCEL` repo secret). Each PR gets a
comment with its preview URL; `main` deploys to production. Smoke-test
screenshots are served at `<preview>/smoke/`.

URL params jump straight to a fight: `?p1=vampire&p2=laser&seed=42&aim=-450&auto=1&speed=2&arena=rink&mod=big_head`
(`aim` is the launch angle in tenths of a degree, screen space, y down;
`arena` is an id from `sim/arenas.gd`; `mod` is an optional Chaos Weekend
modifier id from `sim/modifiers.gd`).

A first visit with no URL params plays the onboarding
(`game/onboarding.gd`; the design lives in the project's design/onboarding.md).
`?tutorial=1` replays it, `?tutorial=0` skips it.

Add `&clip=1` to make a "Save clip" video as soon as the fight ends.

## Finisher cam and clips

The finisher cam (`game/finisher_cam.gd`) slows and zooms into the knockout
blow. It is render-only: it plans from its own copy of the fight and only
changes playback speed and the camera. **Save clip** on the result screen
replays the fight in a 720x1280 "Who wins?" layout (`game/clip/`) and records
it in the browser (MP4 on iPhone Safari); browsers without MediaRecorder get
the same layout to screen-record. The export preset's `head_include` turns on
`preserveDrawingBuffer` and taps the game's audio so the page can record both.
`?sounds=1` opens the sound board: every sound with a play button.
`?pve=1-3&auto=1` plays campaign stage 1-3 on a fresh, unsaved profile.
`?demo=1` loads the filled-in sample profile (unsaved), for previews and the smoke test.

## Icon and loading screen

All brand art is drawn in code in `tools/brand/designs.mjs` (Neon Critters
style) and rendered by `node tools/brand/render.mjs` (needs `smoke/`'s
Playwright and ImageMagick) into `game/brand/`:

- `icon.png` is the project icon: Godot turns it into the web favicon and the
  iPhone home-screen icon (`index.apple-touch-icon.png`).
- `splash.png` is the boot splash and the logo on the web loading screen,
  `game/web/shell.html` (the custom HTML shell with the progress bar and tips).
- `store/` holds the iOS and Android icon sizes (wired into the iOS and
  Android export presets), the Play Store 512 icon and feature graphic. It is
  excluded from the game pack.

designs.mjs also keeps the two runner-up icon options (`OPTIONS`); switch
`icon` to one of them and re-render to swap.

## Touch: scrolling and swipe back

`game/ui/touch_input.gd` handles touch for every screen before the GUI sees it
(added once by `TouchInput.ensure`). A drag past a small dead zone scrolls
the innermost `ScrollContainer` under the finger that can move that way, even
when it starts on a button or card, and the button is let go untapped; a
swipe in from the left edge runs the screen's Back. Screens say what Back
means with `TouchInput.set_back(self, func(): return <action or Callable()>)`;
the shell's is `Shell.back_action()` (close a sheet, or pop the screen stack).
New scroll areas need nothing extra: plain `ScrollContainer`s just work.

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

## Ghost Arena (PvP)

Async PvP from design/pvp.md in the project files. `sim/relay.gd` runs a
lineup relay: each side brings 1-3 balls, legs are ordinary 1v1 MatchSim
fights, and a leg's winner stays in with the HP it has left (`hp` in the
MatchSim config). `game/pvp/ladder.gd` holds leagues, divisions and the
trophy rules per opponent card; `game/pvp/arena_ghosts.gd` generates the
labelled bot defences and the three daily opponent cards from fixed seeds.

Play tab -> Ghost Arena (`game/ui/screens/arena_screen.gd`) shows your league,
your trio (tap a slot to swap it) and the three cards; picking one opens
`game/ghost_arena.tscn`, which plays the relay: you aim each of your balls as
it first comes out, the ghost fires its saved shots. Trophies, your trio and
its last shots live in `user://ghost_arena.cfg` (`game/pvp/arena_store.gd`)
until the online ladder takes over trophies. An attack that is started but
not finished counts as a loss.

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

### Accounts and cloud save

Everyone starts as a guest (an anonymous Supabase user). Tapping the level
badge opens **Account** (`game/online/account.gd`, `game/ui/screens/account_screen.gd`):
a guest saves their progress by email code, which links the email to the same
user id, so nothing moves. "Sign in instead" switches a device to an existing
account (the guest's local progress goes to a backup). Apple and Google
buttons appear on their own once those providers are switched on.

Cloud save (`game/online/save_game.gd`, `*_save_sync.sql`) is compare-and-swap:
the client sends the cloud revision its edits grew from, the server only
writes if that still matches and numbers revisions itself. Offline, changes
stay `dirty` on the device and go up on the next sync (boot, after fights,
when the app regains focus, every 60 s while dirty). When two devices
collide, the save with more progress (`SaveGame.progress`) wins and the other
is written to `user://save_backups` (newest 8 kept). Widen `progress` as more
of the game is saved (account level, critters).

Auth settings live in code: CI's migrate job runs `tools/supabase_auth_config.mjs`
on every merge to `main` (guest linking, allowed return URLs, email codes) and
switches on Apple, Google and custom email when their secrets exist. The code
email templates go up with the `SMTP_*` secrets: Supabase's free built-in
mailer refuses custom templates, so until then its default emails carry a
sign-in link but no typed code:

| Repo secret | What |
|---|---|
| `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SERVICES_ID`, `APPLE_PRIVATE_KEY` (the .p8 text), `APPLE_BUNDLE_ID` | Sign in with Apple. The client secret Apple needs expires within 6 months, so CI makes a new one from the key each run. |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | Google sign-in (web OAuth client). |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_SENDER` | Email from our own domain. Supabase's built-in email only reaches the project's team (a few an hour). |

**Before soft launch (iOS + Android):**
1. Custom email: a domain plus a sender such as Resend (free tier); add the `SMTP_*` secrets.
2. Apple, once the Apple Developer account exists: App ID with Sign in with
   Apple; a Services ID with domain `<ref>.supabase.co` and return URL
   `https://<ref>.supabase.co/auth/v1/callback`; a Sign in with Apple key
   (.p8, downloadable once); add the `APPLE_*` secrets. App Store rule 4.8:
   if Google sign-in is offered on iOS, Apple must be too.
3. Google (optional on the web, expected on Android): OAuth client with the
   same callback URL; add the `GOOGLE_*` secrets.
4. Store builds: the web build uses redirects; native iOS/Android builds need a
   sign-in plugin that passes Apple's/Google's id token to
   `/auth/v1/token?grant_type=id_token` (not built yet).

### Friends

`game/online/friends.gd` + `game/ui/screens/friends_screen.gd`, tables and
RPCs in `supabase/migrations/*_friends.sql`. Every player has an 8-character
friend code; invite links are `?f=<code>`, and signed-in players' replay and
challenge links carry `&f=<code>` so the receiver can add them. Friends can
rematch each other's saved Ghost Arena lineup (unranked, only a head-to-head
record moves), send one energy gift a day (2 energy; up to 10 gifts claimed a
day; the server sets the amount) and send **preset phrases only**, never free
text (Newms, 2026-10-14). `?demo=friends` shows sample friends with no server.

## Economy pacing

`meta/economy.gd` holds the economy numbers (summon odds, campaign drop
chance and zone drop pools, Summon Orb income) and the pacing targets from
design/pve.md section 6. `meta/economy_model.gd` plays simulated casual,
regular (~20 minutes a day) and heavy players through them, day by day, and
`tests/test_economy.gd` fails if the regular player's first fusion, T3, Rare
at T2, Legendary, T4 or T5 drifts out of its window.

```sh
godot --headless --script res://tools/economy_sim.gd -- --players=200 --as-built   # report, with the old numbers for comparison
godot --headless --script res://tools/economy_sim.gd -- --wishlist                 # players wishlist their top Rare+ critters
```

Changing drops, orb income, energy or the launch roster: re-run the report and
paste it in the PR.

## Analytics

`game/online/analytics.gd` queues anonymous play events (`Analytics.track(name, props)`)
and sends them in batches to `log_events()` as the signed-in guest. No names,
free text or device ids; players can turn it off in Settings (the gear) (which also
deletes what was sent), and browsers with Global Privacy Control or Do Not
Track start opted out. Smoke tests and debug builds are flagged as test
traffic. The owner's stats screen is `?stats#k=<dashboard key>` (`game/stats/`);
mint or revoke keys in the Supabase SQL editor (see the analytics migration).
`?stats&demo=1` shows it with sample numbers.

## Adding a critter

A critter is one file: `sim/critters/<id>.gd` (copy `sim/critters/_template.gd`).
It holds the name, rarity, role, stats, ability, T1-T5 ladder, look and voice.
`sim/critter_db.gd` finds every file, so the critter shows up in the fight sim,
the collection, summons, art, sound, the balance sim and the tests with no
other code.

- **Ability** = trigger + effect pairs from `sim/abilities.gd`, e.g.
  `{"on": "wall", "do": "beam"}`, with numbers in `params`. If the effect you
  need doesn't exist, add one `fx_<name>` method and its `EFFECTS` entry there.
- **Tiers** list the ladder text and any `params` that change at each tier.
- **Look** comes from the kit in `game/ui/critter_art.gd`: a body style, a face
  and named features. A new feature is one branch in `_feature()`.
- **Status**: `planned` critters appear in the collection only; set `live` once
  the ability is built and the balance check passes (BALANCE.md).
- `tests/test_critters.gd` checks every file; `CritterDb.validate` explains
  what's wrong.

## Damage rolls, crits, backstabs and gear

Every hit's damage is rolled within +-10% and can crit (5% base chance, x1.5),
from a roll stream seeded by the fight seed (`MatchSim.rolls`), so fights still
replay from the seed and the launch angles. A contact hit from behind (both
balls heading within 45 degrees of each other, the striker catching the other
up) is a backstab for x1.3. Damage events carry `crit` and `backstab` flags;
the arena shows gold CRIT pops and a BACKSTAB! call-out, with their own sounds.

Gear is known fight setup like tiers: `MatchSim` takes `gear: [g1, g2]` and
relays take `gear[side][slot]`, each a list of pieces or summed stat lines.
`sim/gear.gd` holds the seven lines (attack, health, defense, speed, crit
chance, crit damage, cooldown speed), their per-rarity values and caps.
`balance.gd --gear` checks the lines stay worth about the same.

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

Actions minutes are limited (private repo), so CI spends them where they gate a
merge. Draft pushes run only the unit and database tests; the balance matrix,
web build and smoke test run once a PR is ready; `main` runs the unit and
database tests, then builds, deploys and migrates without repeating the smoke
test. Run the full checks locally before pushing (see CLAUDE.md), and push a
draft in a few larger steps rather than many small ones.

The balance gate is its own set of `Balance` jobs: `tools/ci/balance_plan.sh`
picks which pairings a PR needs and how many parallel shards to spread them
over, so it stays inside the time limit as the roster grows (BALANCE.md, "What
checks it"). The `Balance audit` workflow fights every pairing weekly on `main`.

## Cosmetics, the shop and the Glow Pass

Design: `design/monetisation.md`. Money never buys power: real money buys only
Glow Gems, the season's premium pass track and the Founder Pack; gems buy only
cosmetics and the pass. Every power reward sits on the pass's free track.

- `game/glow/catalog.gd` is all the data: cosmetics (hat, trail, hit spark, KO
  effect), bundles, store products. A new cosmetic is one entry there plus, if
  it needs a new look, one `style` branch in `cosmetic_art.gd`.
- Cosmetics are drawn by `arena_view.gd`, never passed to the sim, so fights
  still replay from angles + seed. The YOU/FOE rings, tags and HP badges are
  drawn last, over every cosmetic.
- `game/glow/store.gd` is the store interface and, for now, a fake store
  (purchases are free and labelled "Test store"). Real StoreKit / Play
  Billing goes in a subclass; nothing else changes.
- Pass levels come from play (fights, daily bounties, the weekly chest, Trick
  Shot); a new season in `liveops/liveops.json` starts a fresh pass.
- `tests/test_glow.gd` guards the rules: no power for money, fixed prices,
  cosmetics don't change a fight, rings draw last, colours stay clear of the
  team rings. `?screen=shop` and `?screen=pass` open the screens directly.
